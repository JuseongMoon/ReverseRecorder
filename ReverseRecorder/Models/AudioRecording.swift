//
//  AudioRecording.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import Foundation

struct AudioRecording: Identifiable, Codable {
    let id: UUID
    let originalFileURL: URL
    let reversedFileURL: URL
    let duration: TimeInterval
    let createdAt: Date

    init(id: UUID = UUID(), originalFileURL: URL, reversedFileURL: URL, duration: TimeInterval, createdAt: Date = Date()) {
        self.id = id
        self.originalFileURL = originalFileURL
        self.reversedFileURL = reversedFileURL
        self.duration = duration
        self.createdAt = createdAt
    }
}
