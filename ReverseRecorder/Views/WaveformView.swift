//
//  WaveformView.swift
//  ReverseRecorder
//
//  Created by Claude on 11/25/25.
//

import SwiftUI

struct WaveformView: View {
    let waveformData: [Float]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let barWidth = width / CGFloat(waveformData.count)
                let spacing: CGFloat = 1

                for (index, amplitude) in waveformData.enumerated() {
                    let x = CGFloat(index) * barWidth
                    let barHeight = height * CGFloat(amplitude)

                    // 위쪽으로만 그리기 (아래 기준점에서 위로)
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
                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}

#Preview {
    WaveformView(waveformData: (0..<100).map { _ in Float.random(in: 0.1...1.0) })
        .frame(height: 30)
        .padding()
}
