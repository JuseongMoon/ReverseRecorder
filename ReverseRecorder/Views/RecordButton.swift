//
//  RecordButton.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

// 펄스 테두리 컴포넌트
struct PulsingBorder: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .strokeBorder(lineWidth: 8)
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 280, height: 280)
            .opacity(isPulsing ? 1.0 : 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct RecordButton: View {
    @ObservedObject var viewModel: RecorderViewModel
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Outer circle (with pulsing effect when recording)
            if viewModel.isRecording {
                PulsingBorder()
            } else {
                Circle()
                    .strokeBorder(lineWidth: 8)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
            }

            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: viewModel.isRecording ? [.red, .orange] : [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .shadow(color: viewModel.isRecording ? .red.opacity(0.5) : .blue.opacity(0.3), radius: viewModel.isRecording ? 30 : 15)

            // Icon
            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isRecording)
        .onTapGesture {
            isPressed = true

            if viewModel.isRecording {
                viewModel.stopRecording()
            } else {
                viewModel.startRecording()
            }

            // Reset pressed state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }
    }
}

#Preview {
    RecordButton(viewModel: RecorderViewModel())
}
