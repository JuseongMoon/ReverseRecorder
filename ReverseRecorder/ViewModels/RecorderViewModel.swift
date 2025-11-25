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
    }

    // MARK: - Recording

    func requestMicrophonePermission() {
        recorderService.requestPermission { [weak self] granted in
            if !granted {
                self?.showToastMessage("마이크 권한이 필요합니다.")
            }
        }
    }

    func startRecording() {
        // 기존 녹음 파일 삭제
        if let recording = currentRecording {
            try? fileService.deleteFile(at: recording.originalFileURL)
            try? fileService.deleteFile(at: recording.reversedFileURL)
            currentRecording = nil
        }

        do {
            _ = try recorderService.startRecording()
        } catch {
            showToastMessage("녹음 시작에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard let result = recorderService.stopRecording() else {
            showToastMessage("녹음 저장에 실패했습니다.")
            return
        }

        let originalURL = result.url
        let duration = result.duration

        // Wait 1 second, then reverse and play
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.reverseAndPlay(originalURL: originalURL, duration: duration)
        }
    }

    private func reverseAndPlay(originalURL: URL, duration: TimeInterval) {
        reverseService.reverseAudio(sourceURL: originalURL) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let reversedURL):
                let recording = AudioRecording(
                    originalFileURL: originalURL,
                    reversedFileURL: reversedURL,
                    duration: duration
                )

                self.currentRecording = recording
                self.saveRecording(recording)
                self.playRecording()
                self.extractWaveform(from: reversedURL)

            case .failure(let error):
                self.showToastMessage("역재생 변환에 실패했습니다: \(error.localizedDescription)")
            }
        }
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
            showToastMessage("재생에 실패했습니다: \(error.localizedDescription)")
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

            stopPlayback()
        } catch {
            showToastMessage("삭제에 실패했습니다: \(error.localizedDescription)")
        }
    }

    private func saveRecording(_ recording: AudioRecording) {
        do {
            try fileService.saveRecordings([recording])
        } catch {
            showToastMessage("저장에 실패했습니다: \(error.localizedDescription)")
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
