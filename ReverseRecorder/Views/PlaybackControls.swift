//
//  PlaybackControls.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

struct PlaybackControls: View {
    @ObservedObject var viewModel: RecorderViewModel
    var isStatic: Bool = false
    var staticHasRecording: Bool? = nil
    @State private var showDeleteConfirmation = false

    private var hasRecording: Bool {
        staticHasRecording ?? (viewModel.currentRecording != nil)
    }

    private var isPlaying: Bool {
        isStatic ? false : viewModel.isPlaying
    }

    var body: some View {
        HStack(spacing: 40) {
            // Play/Pause button
            Button(action: {
                guard !isStatic else { return }
                if viewModel.isPlaying {
                    viewModel.pausePlayback()
                } else {
                    viewModel.playRecording()
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 5)
            }
            .disabled(!hasRecording || isStatic)

            // Stop button
            Button(action: {
                guard !isStatic else { return }
                viewModel.stopPlayback()
            }) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.gray, .gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .gray.opacity(0.3), radius: 5)
            }
            .disabled(!hasRecording || isStatic)

            // Delete button
            Button(action: {
                guard !isStatic else { return }
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .red.opacity(0.3), radius: 5)
            }
            .disabled(!hasRecording || isStatic)
        }
        .opacity(hasRecording ? 1.0 : 0.3)
        .alert(String(localized: "delete_recording_title"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "cancel"), role: .cancel) { }
            Button(String(localized: "delete"), role: .destructive) {
                viewModel.deleteRecording()
            }
        } message: {
            Text(String(localized: "delete_recording_message"))
        }
    }
}

#Preview {
    PlaybackControls(viewModel: RecorderViewModel())
}
