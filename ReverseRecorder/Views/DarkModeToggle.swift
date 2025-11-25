//
//  DarkModeToggle.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

struct DarkModeToggle: View {
    @Binding var isDarkMode: Bool

    var body: some View {
        Button(action: {
            isDarkMode.toggle()
            AppIconManager.shared.setIcon(isDarkMode: isDarkMode)
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
        .animation(.spring(response: 0.3), value: isDarkMode)
    }
}

#Preview {
    VStack {
        DarkModeToggle(isDarkMode: .constant(false))
        DarkModeToggle(isDarkMode: .constant(true))
    }
}
