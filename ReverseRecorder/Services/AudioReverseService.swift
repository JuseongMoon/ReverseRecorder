//
//  AudioReverseService.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import AVFoundation
import Foundation

class AudioReverseService {
    static let shared = AudioReverseService()

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
}

// MARK: - Errors

enum AudioReverseError: LocalizedError {
    case bufferCreationFailed
    case noChannelData

    var errorDescription: String? {
        switch self {
        case .bufferCreationFailed:
            return "오디오 버퍼 생성에 실패했습니다."
        case .noChannelData:
            return "오디오 채널 데이터를 찾을 수 없습니다."
        }
    }
}
