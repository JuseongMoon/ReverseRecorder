//
//  AudioWaveformService.swift
//  ReverseRecorder
//
//  Created by Claude on 11/25/25.
//

import AVFoundation
import Foundation

class AudioWaveformService {
    static let shared = AudioWaveformService()

    private init() {}

    // MARK: - Extract Waveform

    func extractWaveform(from url: URL, samplesCount: Int = 100,
                         completion: @escaping (Result<[Float], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let waveform = try self.performExtraction(url: url, samplesCount: samplesCount)
                DispatchQueue.main.async {
                    completion(.success(waveform))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func performExtraction(url: URL, samplesCount: Int) throws -> [Float] {
        // Load audio file
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)

        // Read audio data into buffer
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw WaveformError.bufferCreationFailed
        }

        try audioFile.read(into: buffer)

        // Get float channel data
        guard let floatChannelData = buffer.floatChannelData else {
            throw WaveformError.noChannelData
        }

        // Extract samples from first channel
        let samples = Array(UnsafeBufferPointer(
            start: floatChannelData[0],
            count: Int(buffer.frameLength)
        ))

        // Downsample and normalize
        let downsampled = downsample(samples, to: samplesCount)
        return normalize(downsampled)
    }

    private func downsample(_ samples: [Float], to targetCount: Int) -> [Float] {
        guard samples.count > targetCount else {
            return samples.map { abs($0) }
        }

        let binSize = samples.count / targetCount
        var result = [Float]()

        for i in 0..<targetCount {
            let start = i * binSize
            let end = min(start + binSize, samples.count)
            let maxAbs = samples[start..<end].map { abs($0) }.max() ?? 0
            result.append(maxAbs)
        }

        return result
    }

    private func normalize(_ samples: [Float]) -> [Float] {
        guard let maxValue = samples.max(), maxValue > 0 else {
            return samples
        }
        return samples.map { $0 / maxValue }
    }
}

// MARK: - Errors

enum WaveformError: LocalizedError {
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
