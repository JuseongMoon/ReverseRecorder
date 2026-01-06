//
//  RecorderViewModel.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import Foundation
import Combine

class RecorderViewModel: ObservableObject {
    // Services
    private let recorderService = AudioRecorderService()
    private let playerService = AudioPlayerService()
    private let reverseService = AudioReverseService.shared
    private let fileService = FileManagerService.shared
    private let waveformService = AudioWaveformService.shared

    // Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentRecording: AudioRecording?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var toastMessage: String?
    @Published var showToast = false
    @Published var waveformData: [Float] = []

    // Recording Progress Properties
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingWaveformData: [Float] = []
    private let maxRecordingDuration: TimeInterval = 60.0
    private let maxWaveformSamples = 100

    // Reverse Processing Properties
    @Published var isProcessingReverse = false
    @Published var reverseProgress: Float = 0
    @Published var processingWaveformData: [Float] = []
    private var reverseProgressCancellable: AnyCancellable?

    /// 스냅샷 업데이트가 필요할 때 호출되는 콜백
    var onSnapshotUpdateNeeded: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
        loadLastRecording()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Bind recorder state
        recorderService.$isRecording
            .assign(to: &$isRecording)

        // Bind player state
        playerService.$isPlaying
            .assign(to: &$isPlaying)

        playerService.$currentTime
            .assign(to: &$currentTime)

        playerService.$duration
            .assign(to: &$duration)

        // Bind recording time
        recorderService.$recordingTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingTime)

        // Bind audio level to waveform data
        recorderService.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self = self, self.isRecording else { return }
                self.appendToRecordingWaveform(level: level)
            }
            .store(in: &cancellables)
    }

    // MARK: - Recording Waveform

    private func appendToRecordingWaveform(level: Float) {
        // 1분(60초) 이후에는 더 이상 파형 추가하지 않음
        guard recordingTime <= maxRecordingDuration else { return }

        // 60초 동안 100개 샘플이 균등하게 채워지도록 (0.6초마다 1개)
        let samplesPerSecond = Double(maxWaveformSamples) / maxRecordingDuration
        let expectedSamples = Int(recordingTime * samplesPerSecond)

        // 현재 샘플 수가 목표보다 적으면 추가
        if recordingWaveformData.count < expectedSamples && recordingWaveformData.count < maxWaveformSamples {
            recordingWaveformData.append(level)
        }
    }

    // MARK: - Recording

    func requestMicrophonePermission() {
        recorderService.requestPermission { [weak self] granted in
            if !granted {
                self?.showToastMessage(String(localized: "microphone_permission_required"))
            }
        }
    }

    func startRecording() {
        // 기존 녹음 파일 삭제
        if let recording = currentRecording {
            do {
                try fileService.deleteFile(at: recording.originalFileURL)
                try fileService.deleteFile(at: recording.reversedFileURL)
            } catch {
                // 파일 삭제 실패해도 녹음은 계속 진행하지만 로깅
                print("이전 녹음 파일 삭제 실패: \(error.localizedDescription)")
            }
            currentRecording = nil
        }

        // 녹음 시작 시 파형 데이터 초기화
        recordingWaveformData = []
        recordingTime = 0
        waveformData = []

        do {
            _ = try recorderService.startRecording()
        } catch {
            showToastMessage(String(format: String(localized: "recording_start_failed"), error.localizedDescription))
        }
    }

    func stopRecording() {
        guard let result = recorderService.stopRecording() else {
            showToastMessage(String(localized: "recording_save_failed"))
            return
        }

        let originalURL = result.url
        let duration = result.duration

        // 즉시 역재생 처리 시작
        reverseAndPlay(originalURL: originalURL, duration: duration)
    }

    private func reverseAndPlay(originalURL: URL, duration: TimeInterval) {
        // 처리 시작 상태 설정
        isProcessingReverse = true
        reverseProgress = 0
        processingWaveformData = []

        // 진행률 구독
        reverseProgressCancellable = reverseService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }

                self.reverseProgress = progress.progress
                // 파형 데이터 순차 추가
                self.processingWaveformData.append(progress.waveformSample)
            }

        // 진행률 포함 역재생 처리 시작
        reverseService.reverseAudioWithProgress(sourceURL: originalURL) { [weak self] result in
            guard let self = self else { return }

            // 구독 해제
            self.reverseProgressCancellable?.cancel()
            self.reverseProgressCancellable = nil
            self.isProcessingReverse = false

            switch result {
            case .success(let reversedURL):
                let recording = AudioRecording(
                    originalFileURL: originalURL,
                    reversedFileURL: reversedURL,
                    duration: duration
                )

                self.currentRecording = recording
                self.saveRecording(recording)

                // 처리 중 파형을 정규화하여 최종 파형으로 전환
                self.waveformData = self.normalizeWaveform(self.processingWaveformData)
                self.processingWaveformData = []

                self.playRecording()

                // 스냅샷 업데이트 요청
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.onSnapshotUpdateNeeded?()
                }

            case .failure(let error):
                self.processingWaveformData = []
                self.showToastMessage(String(format: String(localized: "reverse_failed"), error.localizedDescription))
            }
        }
    }

    // MARK: - Waveform Normalization

    private func normalizeWaveform(_ samples: [Float]) -> [Float] {
        guard let maxValue = samples.max(), maxValue > 0 else {
            return samples
        }
        return samples.map { $0 / maxValue }
    }

    // MARK: - Playback

    func playRecording() {
        guard let recording = currentRecording else { return }

        do {
            // 이미 로드된 오디오면 현재 위치에서 재생
            if !playerService.isLoaded(url: recording.reversedFileURL) {
                try playerService.loadAudio(url: recording.reversedFileURL)
            }
            playerService.play()
        } catch {
            showToastMessage(String(format: String(localized: "playback_failed"), error.localizedDescription))
        }
    }

    func pausePlayback() {
        playerService.pause()
    }

    func stopPlayback() {
        playerService.stop()
    }

    func seek(to time: TimeInterval) {
        playerService.seek(to: time)
    }

    // MARK: - File Management

    func deleteRecording() {
        guard let recording = currentRecording else { return }

        do {
            try fileService.deleteFile(at: recording.originalFileURL)
            try fileService.deleteFile(at: recording.reversedFileURL)

            currentRecording = nil
            waveformData = []
            try fileService.saveRecordings([])

            playerService.unload()

            // 삭제 완료 후 스냅샷 업데이트 요청
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.onSnapshotUpdateNeeded?()
            }
        } catch {
            showToastMessage(String(format: String(localized: "delete_failed"), error.localizedDescription))
        }
    }

    private func saveRecording(_ recording: AudioRecording) {
        do {
            try fileService.saveRecordings([recording])
        } catch {
            showToastMessage(String(format: String(localized: "save_failed"), error.localizedDescription))
        }
    }

    private func loadLastRecording() {
        let recordings = fileService.loadRecordings()
        currentRecording = recordings.last

        // 저장된 녹음이 있으면 파형도 로드
        if let recording = currentRecording {
            extractWaveform(from: recording.reversedFileURL)
        }
    }

    // MARK: - Waveform

    private func extractWaveform(from url: URL) {
        waveformService.extractWaveform(from: url, samplesCount: 100) { [weak self] result in
            switch result {
            case .success(let data):
                self?.waveformData = data
                // 파형 추출 완료 후 스냅샷 업데이트 요청
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.onSnapshotUpdateNeeded?()
                }
            case .failure(let error):
                print("파형 추출 실패: \(error.localizedDescription)")
                self?.waveformData = []
            }
        }
    }

    // MARK: - Toast

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showToast = false
        }
    }
}
