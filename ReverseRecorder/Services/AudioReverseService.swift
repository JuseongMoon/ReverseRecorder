//
//  AudioReverseService.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import AVFoundation
import Combine
import Foundation

class AudioReverseService {
    static let shared = AudioReverseService()

    // MARK: - Progress Publisher

    struct ReverseProgress {
        let progress: Float          // 0.0 ~ 1.0
        let waveformSample: Float    // 해당 청크의 파형 데이터 (최대값)
        let chunkIndex: Int          // 청크 인덱스 (0부터 시작)
        let totalChunks: Int         // 전체 청크 수
    }

    private let progressSubject = PassthroughSubject<ReverseProgress, Never>()
    var progressPublisher: AnyPublisher<ReverseProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    private init() {}

    // MARK: - Reverse Audio

    func reverseAudio(sourceURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let reversedURL = try self.performReverse(sourceURL: sourceURL)
                DispatchQueue.main.async {
                    completion(.success(reversedURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func performReverse(sourceURL: URL) throws -> URL {
        // Load audio file
        let audioFile = try AVAudioFile(forReading: sourceURL)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)

        // Read audio data
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioReverseError.bufferCreationFailed
        }

        try audioFile.read(into: buffer)

        // Reverse audio samples
        guard let floatChannelData = buffer.floatChannelData else {
            throw AudioReverseError.noChannelData
        }

        let channelCount = Int(format.channelCount)
        let frameLength = Int(buffer.frameLength)

        for channel in 0..<channelCount {
            var samples = Array(UnsafeBufferPointer(start: floatChannelData[channel], count: frameLength))
            samples.reverse()
            floatChannelData[channel].update(from: samples, count: frameLength)
        }

        // Create output file
        let outputURL = FileManagerService.shared.generateUniqueFileURL(fileName: "reversed")

        // Write reversed audio to file
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        try outputFile.write(from: buffer)

        return outputURL
    }

    // MARK: - Reverse Audio with Progress

    func reverseAudioWithProgress(
        sourceURL: URL,
        totalWaveformSamples: Int = 100,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let reversedURL = try self.performReverseWithProgress(
                    sourceURL: sourceURL,
                    totalWaveformSamples: totalWaveformSamples
                )
                DispatchQueue.main.async {
                    completion(.success(reversedURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func performReverseWithProgress(
        sourceURL: URL,
        totalWaveformSamples: Int
    ) throws -> URL {
        // 1. 오디오 파일 로드
        let audioFile = try AVAudioFile(forReading: sourceURL)
        let format = audioFile.processingFormat
        let totalFrames = UInt32(audioFile.length)

        // 2. 전체 버퍼 읽기
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            throw AudioReverseError.bufferCreationFailed
        }
        try audioFile.read(into: buffer)

        guard let floatChannelData = buffer.floatChannelData else {
            throw AudioReverseError.noChannelData
        }

        let channelCount = Int(format.channelCount)
        let frameLength = Int(buffer.frameLength)

        // 3. 청크 크기 계산
        let chunkCount = totalWaveformSamples
        let framesPerChunk = frameLength / chunkCount
        let remainder = frameLength % chunkCount

        // 4. 출력 파일 준비
        let outputURL = FileManagerService.shared.generateUniqueFileURL(fileName: "reversed")
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)

        // 5. 청크 단위로 역재생 처리 (뒤에서부터 앞으로)
        for chunkIndex in 0..<chunkCount {
            // 역순 처리: 원본의 마지막 청크부터 처리하여 출력 파일의 앞부분에 쓰기
            let reverseChunkIndex = chunkCount - 1 - chunkIndex

            // 마지막 청크에 나머지 프레임 포함
            let chunkFrameCount: Int
            let startFrame: Int
            if reverseChunkIndex == chunkCount - 1 {
                chunkFrameCount = framesPerChunk + remainder
                startFrame = reverseChunkIndex * framesPerChunk
            } else {
                chunkFrameCount = framesPerChunk
                startFrame = reverseChunkIndex * framesPerChunk
            }

            // 청크 버퍼 생성
            guard let chunkBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(chunkFrameCount)
            ) else { continue }

            chunkBuffer.frameLength = AVAudioFrameCount(chunkFrameCount)

            // 청크 데이터 복사 및 역순 처리
            for channel in 0..<channelCount {
                let sourcePtr = floatChannelData[channel]
                guard let destPtr = chunkBuffer.floatChannelData?[channel] else { continue }

                for i in 0..<chunkFrameCount {
                    // 청크 내에서도 역순으로 복사
                    let sourceIndex = startFrame + chunkFrameCount - 1 - i
                    // 경계 검사로 크래시 방지
                    guard sourceIndex >= 0, sourceIndex < frameLength else { continue }
                    destPtr[i] = sourcePtr[sourceIndex]
                }
            }

            // 파일에 쓰기
            try outputFile.write(from: chunkBuffer)

            // 파형 데이터 추출 (현재 청크에서 최대값)
            let waveformSample = extractWaveformFromChunk(
                floatChannelData: floatChannelData[0],
                startFrame: startFrame,
                frameCount: chunkFrameCount,
                totalFrameLength: frameLength
            )

            // 진행률 발행
            let progress = ReverseProgress(
                progress: Float(chunkIndex + 1) / Float(chunkCount),
                waveformSample: waveformSample,
                chunkIndex: chunkIndex,
                totalChunks: chunkCount
            )

            DispatchQueue.main.async { [weak self] in
                self?.progressSubject.send(progress)
            }
        }

        return outputURL
    }

    private func extractWaveformFromChunk(
        floatChannelData: UnsafeMutablePointer<Float>,
        startFrame: Int,
        frameCount: Int,
        totalFrameLength: Int
    ) -> Float {
        var maxAbs: Float = 0
        for i in 0..<frameCount {
            let index = startFrame + i
            // 경계 검사로 크래시 방지
            guard index >= 0, index < totalFrameLength else { continue }
            let absValue = abs(floatChannelData[index])
            if absValue > maxAbs {
                maxAbs = absValue
            }
        }
        return maxAbs
    }
}

// MARK: - Errors

enum AudioReverseError: LocalizedError {
    case bufferCreationFailed
    case noChannelData

    var errorDescription: String? {
        switch self {
        case .bufferCreationFailed:
            return String(localized: "audio_buffer_creation_failed")
        case .noChannelData:
            return String(localized: "audio_channel_data_not_found")
        }
    }
}
