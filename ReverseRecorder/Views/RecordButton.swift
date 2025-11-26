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
    var isStatic: Bool = false
    @State private var isPressed = false

    private var isRecording: Bool {
        isStatic ? false : viewModel.isRecording
    }

    var body: some View {
        ZStack {
            // Outer circle (with pulsing effect when recording)
            if isRecording {
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
                        colors: isRecording ? [.red, .orange] : [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .shadow(color: isRecording ? .red.opacity(0.5) : .blue.opacity(0.3), radius: isRecording ? 30 : 15)

            // Icon
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
        .onTapGesture {
            guard !isStatic else { return }
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
