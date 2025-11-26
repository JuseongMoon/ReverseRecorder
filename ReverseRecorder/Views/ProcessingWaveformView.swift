//
//  ProcessingWaveformView.swift
//  ReverseRecorder
//
//  Created by Claude on 11/26/25.
//

import SwiftUI

struct ProcessingWaveformView: View {
    let waveformData: [Float]
    let maxSamples: Int = 100

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                guard !waveformData.isEmpty else { return }

                // 고정된 barWidth (전체 너비 / 100)
                let barWidth = width / CGFloat(maxSamples)
                let spacing: CGFloat = 1

                // 현재 최대값으로 실시간 정규화
                let maxValue = waveformData.max() ?? 1.0
                let normalizer: Float = maxValue > 0 ? maxValue : 1.0

                for (index, amplitude) in waveformData.enumerated() {
                    let x = CGFloat(index) * barWidth
                    let normalizedAmplitude = amplitude / normalizer
                    let barHeight = max(height * CGFloat(normalizedAmplitude), 2)

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
                    colors: [.gray.opacity(0.5), .gray.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .animation(.easeOut(duration: 0.05), value: waveformData.count)
        }
    }
}

#Preview {
    ProcessingWaveformView(
        waveformData: (0..<50).map { _ in Float.random(in: 0.1...1.0) }
    )
    .frame(height: 30)
    .padding()
}
