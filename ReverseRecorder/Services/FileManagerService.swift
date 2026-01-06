//
//  FileManagerService.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import Foundation

class FileManagerService {
    static let shared = FileManagerService()

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Directory URLs

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var recordingsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
        createDirectoryIfNeeded(at: url)
        return url
    }

    // MARK: - File Operations

    func createDirectoryIfNeeded(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func generateUniqueFileURL(fileName: String = "recording", fileExtension: String = "m4a") -> URL {
        let timestamp = Date().timeIntervalSince1970
        let uniqueFileName = "\(fileName)_\(timestamp).\(fileExtension)"
        return recordingsDirectory.appendingPathComponent(uniqueFileName)
    }

    func deleteFile(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Recording Persistence

    private var recordingsFileURL: URL {
        documentsDirectory.appendingPathComponent("recordings.json")
    }

    func saveRecordings(_ recordings: [AudioRecording]) throws {
        let data = try JSONEncoder().encode(recordings)
        try data.write(to: recordingsFileURL)
    }

    func loadRecordings() -> [AudioRecording] {
        guard fileExists(at: recordingsFileURL) else {
            return []
        }

        do {
            let data = try Data(contentsOf: recordingsFileURL)
            let recordings = try JSONDecoder().decode([AudioRecording].self, from: data)
            return recordings
        } catch {
            // 데이터 로드 또는 디코딩 실패 시 로깅
            print("녹음 데이터 로드 실패: \(error.localizedDescription)")
            return []
        }
    }
}
