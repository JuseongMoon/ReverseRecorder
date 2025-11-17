//
//  ProgressSlider.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

struct ProgressSlider: View {
    @ObservedObject var viewModel: RecorderViewModel
    @State private var isDragging = false
    @State private var tempValue: Double = 0

    private var progress: Double {
        guard viewModel.duration > 0 else { return 0 }
        return isDragging ? tempValue : viewModel.currentTime / viewModel.duration
    }

    var body: some View {
        VStack(spacing: 8) {
            // Time labels
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Custom slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)

                    // Progress track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 4)
                        .offset(x: (geometry.size.width - 20) * progress)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                    tempValue = newProgress
                                }
                                .onEnded { value in
                                    let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                    let newTime = newProgress * viewModel.duration
                                    viewModel.seek(to: newTime)
                                    isDragging = false
                                }
                        )
                }
            }
            .frame(height: 20)
        }
        .padding(.horizontal)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ProgressSlider(viewModel: RecorderViewModel())
}
