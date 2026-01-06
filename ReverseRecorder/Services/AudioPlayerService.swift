//
//  AudioPlayerService.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import AVFoundation
import Combine
import Foundation

class AudioPlayerService: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var timer: Timer?
    private var loadedURL: URL?

    // MARK: - Playback Control

    func loadAudio(url: URL) throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()

        duration = audioPlayer?.duration ?? 0
        currentTime = 0
        loadedURL = url
    }

    func isLoaded(url: URL) -> Bool {
        return loadedURL == url && audioPlayer != nil
    }

    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    func unload() {
        stop()
        audioPlayer = nil
        loadedURL = nil
        duration = 0

        // 오디오 세션 비활성화 (다른 앱의 오디오 재생 복원)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            let time = player.currentTime

            // @Published 프로퍼티는 메인 스레드에서 업데이트
            DispatchQueue.main.async { [weak self] in
                self?.currentTime = time
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        player.currentTime = 0
        stopTimer()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        stopTimer()
    }
}
