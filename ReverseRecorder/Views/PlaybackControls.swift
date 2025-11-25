//
//  PlaybackControls.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

struct PlaybackControls: View {
    @ObservedObject var viewModel: RecorderViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 40) {
            // Play/Pause button
            Button(action: {
                if viewModel.isPlaying {
                    viewModel.pausePlayback()
                } else {
                    viewModel.playRecording()
                }
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
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
            .disabled(viewModel.currentRecording == nil)

            // Stop button
            Button(action: {
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
            .disabled(viewModel.currentRecording == nil)

            // Delete button
            Button(action: {
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
            .disabled(viewModel.currentRecording == nil)
        }
        .opacity(viewModel.currentRecording == nil ? 0.3 : 1.0)
        .alert("녹음 삭제", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.deleteRecording()
            }
        } message: {
            Text("이 녹음을 삭제하시겠습니까?")
        }
    }
}

#Preview {
    PlaybackControls(viewModel: RecorderViewModel())
}
