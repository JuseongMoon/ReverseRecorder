//
//  ShareButton.swift
//  ReverseRecorder
//
//  Created by Claude on 11/25/25.
//

import SwiftUI

struct ShareButton: View {
    let fileURL: URL?
    let createdAt: Date?
    @State private var showShareSheet = false
    @State private var tempFileURL: URL?
    @State private var isLoading = false

    private var isEnabled: Bool {
        fileURL != nil
    }

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                isLoading = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let url = createTempFileForSharing()
                    DispatchQueue.main.async {
                        tempFileURL = url
                        isLoading = false
                        showShareSheet = true
                    }
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? [.blue, .cyan] : [.gray, .gray.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: isEnabled ? .blue.opacity(0.5) : .gray.opacity(0.3), radius: 8)

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .offset(y: -1)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.spring(response: 0.3), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .sheet(isPresented: $showShareSheet, onDismiss: {
            cleanupTempFile()
        }) {
            if let url = tempFileURL ?? fileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private func generateShareFileName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "Reversed_\(formatter.string(from: date)).m4a"
    }

    private func createTempFileForSharing() -> URL? {
        guard let sourceURL = fileURL else { return nil }
        let date = createdAt ?? Date()
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = generateShareFileName(date: date)
        let destURL = tempDir.appendingPathComponent(fileName)

        // 기존 파일이 있으면 삭제
        try? FileManager.default.removeItem(at: destURL)
        // 새 파일 복사
        try? FileManager.default.copyItem(at: sourceURL, to: destURL)
        return destURL
    }

    private func cleanupTempFile() {
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    VStack(spacing: 20) {
        ShareButton(fileURL: URL(string: "file://test.m4a"), createdAt: Date())
        ShareButton(fileURL: nil, createdAt: nil)
    }
}
