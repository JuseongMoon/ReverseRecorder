//
//  AudioRecorderService.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import AVFoundation
import Combine
import Foundation

class AudioRecorderService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var meteringTimer: Timer?

    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws -> URL {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)

        let fileURL = FileManagerService.shared.generateUniqueFileURL(fileName: "original")
        recordingURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true
        recordingTime = 0
        audioLevel = 0
        startMeteringTimer()

        return fileURL
    }

    // MARK: - Metering

    private func startMeteringTimer() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, self.isRecording else { return }

            recorder.updateMeters()
            let currentRecordingTime = recorder.currentTime

            // 평균 파워를 0~1 범위로 정규화 (-50dB ~ 0dB 범위 사용)
            let averagePower = recorder.averagePower(forChannel: 0)
            let normalizedLevel = max(0, min(1, (averagePower + 50) / 50))

            // @Published 프로퍼티는 메인 스레드에서 업데이트
            DispatchQueue.main.async { [weak self] in
                self?.recordingTime = currentRecordingTime
                self?.audioLevel = normalizedLevel
            }
        }
    }

    private func stopMeteringTimer() {
        meteringTimer?.invalidate()
        meteringTimer = nil
    }

    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard let recorder = audioRecorder, isRecording else { return nil }

        stopMeteringTimer()
        recorder.stop()
        isRecording = false

        // 오디오 세션 비활성화 (다른 앱의 오디오 재생 복원)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let duration = recorder.currentTime
        guard let url = recordingURL else { return nil }

        return (url, duration)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            isRecording = false
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
    }
}
