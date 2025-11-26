//
//  RecordingWaveformView.swift
//  ReverseRecorder
//
//  Created by Claude on 11/26/25.
//

import SwiftUI

struct RecordingWaveformView: View {
    let waveformData: [Float]
    let maxSamples: Int = 100  // 60초 동안 100개 샘플 (고정)

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                guard !waveformData.isEmpty else { return }

                // 고정된 barWidth (전체 너비 / 100)
                let barWidth = width / CGFloat(maxSamples)
                let spacing: CGFloat = 1

                for (index, amplitude) in waveformData.enumerated() {
                    let x = CGFloat(index) * barWidth
                    let barHeight = max(height * CGFloat(amplitude), 2)

                    path.addRect(CGRect(
                        x: x,
                        y: height - barHeight,
                        width: max(barWidth - spacing, 1),
                        height: barHeight
                    ))
                }
            }
            .fill(
                LinearGradient(
                    colors: [.red.opacity(0.7), .orange.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}

#Preview {
    RecordingWaveformView(
        waveformData: (0..<50).map { _ in Float.random(in: 0.1...1.0) }
    )
    .frame(height: 30)
    .padding()
}
