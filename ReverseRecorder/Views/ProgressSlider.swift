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

    private let maxRecordingDuration: TimeInterval = 60.0

    private var progress: Double {
        if viewModel.isRecording {
            // 녹음 중: 60초 기준, 1분 초과 시 1.0 고정
            return min(1.0, viewModel.recordingTime / maxRecordingDuration)
        } else if viewModel.isProcessingReverse {
            // 역재생 처리 중: 진행률 표시
            return Double(viewModel.reverseProgress)
        } else {
            // 재생 중: 기존 로직
            guard viewModel.duration > 0 else { return 0 }
            return isDragging ? tempValue : viewModel.currentTime / viewModel.duration
        }
    }

    private var progressTrackColors: [Color] {
        if viewModel.isRecording {
            return [.red, .orange]
        } else if viewModel.isProcessingReverse {
            return [.gray.opacity(0.5), .gray.opacity(0.7)]
        } else {
            return [.blue, .purple]
        }
    }

    private var thumbProgress: Double {
        // 프로세싱 중에는 플레이헤드 위치 0 고정
        if viewModel.isProcessingReverse {
            return 0
        }
        return progress
    }

    var body: some View {
        VStack(spacing: 0) {
            // Waveform + Custom slider (위쪽)
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Waveform 영역 (항상 30pt 공간 확보)
                    VStack {
                        if viewModel.isRecording {
                            // 녹음 중: 실시간 파형 (고정 barWidth로 자연스럽게 확장)
                            RecordingWaveformView(waveformData: viewModel.recordingWaveformData)
                                .frame(width: geometry.size.width)
                        } else if viewModel.isProcessingReverse {
                            // 역재생 처리 중: 순차적으로 나타나는 회색 파형
                            ProcessingWaveformView(waveformData: viewModel.processingWaveformData)
                                .frame(width: geometry.size.width)
                        } else if !viewModel.waveformData.isEmpty {
                            // 재생 중: 정적 파형
                            WaveformView(waveformData: viewModel.waveformData)
                                .frame(width: geometry.size.width)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(height: 30)
                    .offset(y: -14)

                    // Slider (하단)
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)

                        // Progress track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: progressTrackColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)

                        // Thumb (중심 기준으로 이동, 프로세싱 중에는 숨김)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(radius: 4)
                            .offset(x: geometry.size.width * thumbProgress - 10)
                            .opacity(viewModel.isProcessingReverse ? 0 : 1)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // 녹음 중 또는 처리 중에는 드래그 불가
                                        guard !viewModel.isRecording && !viewModel.isProcessingReverse else { return }
                                        isDragging = true
                                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                        tempValue = newProgress
                                    }
                                    .onEnded { value in
                                        guard !viewModel.isRecording && !viewModel.isProcessingReverse else { return }
                                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                        let newTime = newProgress * viewModel.duration
                                        viewModel.seek(to: newTime)
                                        isDragging = false
                                    }
                            )
                    }
                    .frame(height: 20)
                }
            }
            .frame(height: 50)

            // Time labels (아래쪽, 간격 줄임)
            HStack {
                // 왼쪽: 녹음 중에는 00:00 고정, 재생 중에는 현재 시간
                Text(formatTime(viewModel.isRecording ? 0 : viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // 오른쪽: 녹음 중에는 녹음 시간, 재생 중에는 전체 길이
                Text(formatTime(viewModel.isRecording ? viewModel.recordingTime : viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
