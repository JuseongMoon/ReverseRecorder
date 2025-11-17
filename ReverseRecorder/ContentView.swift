//
//  ContentView.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecorderViewModel()
    @AppStorage("isDarkModeOverride") private var isDarkModeOverride: Bool?
    @Environment(\.colorScheme) private var systemColorScheme

    private var isDarkMode: Bool {
        isDarkModeOverride ?? (systemColorScheme == .dark)
    }

    private var isDarkModeBinding: Binding<Bool> {
        Binding(
            get: { self.isDarkMode },
            set: { self.isDarkModeOverride = $0 }
        )
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: isDarkMode ?
                    [Color(.systemBackground), Color(.systemGray6)] :
                    [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Record button (perfect center)
            RecordButton(viewModel: viewModel)

            // Bottom controls
            VStack {
                Spacer()

                // Progress slider
                ProgressSlider(viewModel: viewModel)
                    .frame(height: 60)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                // Playback controls
                PlaybackControls(viewModel: viewModel)
                    .padding(.bottom, 50)
            }

            // Dark mode toggle (top left)
            VStack {
                HStack {
                    DarkModeToggle(isDarkMode: isDarkModeBinding)
                        .padding(.leading, 20)
                        .padding(.top, 20)

                    Spacer()
                }

                Spacer()
            }
        }
        .preferredColorScheme(isDarkModeOverride == nil ? nil : (isDarkModeOverride! ? .dark : .light))
        .toast(isShowing: $viewModel.showToast, message: viewModel.toastMessage ?? "")
        .onAppear {
            viewModel.requestMicrophonePermission()
        }
    }
}

#Preview {
    ContentView()
}
