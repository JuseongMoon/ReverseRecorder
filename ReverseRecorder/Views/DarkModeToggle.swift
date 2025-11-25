//
//  DarkModeToggle.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

// 버튼 중심 좌표를 전달하기 위한 PreferenceKey
struct ButtonCenterPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct DarkModeToggle: View {
    @Binding var isDarkMode: Bool
    @Binding var isTransitioning: Bool
    var onTransitionStart: ((Bool) -> Void)?

    var body: some View {
        Button(action: {
            guard !isTransitioning else { return }
            let newDarkMode = !isDarkMode
            // 바로 트랜지션 시작 (아이콘 변경은 트랜지션 완료 후 ContentView에서 처리)
            onTransitionStart?(newDarkMode)
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isDarkMode ? [.purple, .indigo] : [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: isDarkMode ? .purple.opacity(0.5) : .orange.opacity(0.5), radius: 8)

                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ButtonCenterPreferenceKey.self,
                        value: CGPoint(
                            x: geometry.frame(in: .global).midX,
                            y: geometry.frame(in: .global).midY
                        )
                    )
            }
        )
        .animation(.spring(response: 0.3), value: isDarkMode)
    }
}

#Preview {
    VStack {
        DarkModeToggle(isDarkMode: .constant(false), isTransitioning: .constant(false))
        DarkModeToggle(isDarkMode: .constant(true), isTransitioning: .constant(false))
    }
}
