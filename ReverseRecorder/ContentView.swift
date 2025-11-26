//
//  ContentView.swift
//  ReverseRecorder
//
//  Created by 문주성 on 11/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecorderViewModel()
    @StateObject private var snapshotService = ThemeSnapshotService.shared
    @AppStorage("isDarkModeOverride") private var isDarkModeOverride: Bool?
    @Environment(\.colorScheme) private var systemColorScheme

    // 트랜지션 관련 상태
    @State private var isTransitioning: Bool = false
    @State private var transitionRadius: CGFloat = 0
    @State private var transitionTargetDarkMode: Bool = false
    @State private var toggleButtonCenter: CGPoint = .zero

    private var isDarkMode: Bool {
        isDarkModeOverride ?? (systemColorScheme == .dark)
    }

    private var isDarkModeBinding: Binding<Bool> {
        Binding(
            get: { self.isDarkMode },
            set: { self.isDarkModeOverride = $0 }
        )
    }

    // 버튼에서 가장 먼 화면 모서리까지의 거리 계산 (픽셀 단위)
    private func calculateMaxRadius() -> CGFloat {
        let screenSize = UIScreen.main.bounds.size
        let distances = [
            distance(from: toggleButtonCenter, to: .zero),
            distance(from: toggleButtonCenter, to: CGPoint(x: screenSize.width, y: 0)),
            distance(from: toggleButtonCenter, to: CGPoint(x: 0, y: screenSize.height)),
            distance(from: toggleButtonCenter, to: CGPoint(x: screenSize.width, y: screenSize.height))
        ]
        return (distances.max() ?? 0) + 50
    }

    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
    }

    /// 다크/라이트 테마 스냅샷 캡처 (현재 UI 상태 반영)
    private func prepareThemeSnapshots() {
        let recording = viewModel.currentRecording
        let waveform = viewModel.waveformData

        // 라이트 테마 스냅샷 (현재 상태 반영)
        snapshotService.captureLightSnapshot(
            contentView: snapshotContent(isDark: false, recording: recording, waveformData: waveform)
        )

        // 약간의 딜레이 후 다크 테마 스냅샷 캡처 (동시 캡처 시 부하 분산)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            snapshotService.captureDarkSnapshot(
                contentView: snapshotContent(isDark: true, recording: recording, waveformData: waveform)
            )
        }
    }

    private func startTransition(to newDarkMode: Bool) {
        transitionTargetDarkMode = newDarkMode
        isTransitioning = true
        transitionRadius = 0

        withAnimation(.timingCurve(0.6, 0.05, 0.9, 0.3, duration: 0.4)) {  // 부드러운 시작 → 극적인 가속
            transitionRadius = calculateMaxRadius()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isDarkModeOverride = newDarkMode

            // 테마 변경이 완전히 반영된 후 오버레이 제거 (렌더링 완료 대기)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isTransitioning = false
                transitionRadius = 0
            }
        }
    }

    /// 스냅샷 캡처용 콘텐츠 (실제 컴포넌트 재사용, 정적 모드)
    @ViewBuilder
    private func snapshotContent(isDark: Bool, recording: AudioRecording?, waveformData: [Float]) -> some View {
        let hasRecording = recording != nil

        ZStack {
            // 배경 - 전체 화면 강제 채우기 (off-screen 렌더링용)
            GeometryReader { _ in
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()

            // 녹음 버튼 (중앙) - 정적 모드
            RecordButton(viewModel: viewModel, isStatic: true)

            // 하단 컨트롤 - 정적 모드
            VStack {
                Spacer()

                ProgressSlider(viewModel: viewModel, isStatic: true, staticWaveformData: waveformData)
                    .frame(height: 90)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                PlaybackControls(viewModel: viewModel, isStatic: true, staticHasRecording: hasRecording)
                    .padding(.bottom, 50)
            }

            // 상단 컨트롤
            VStack {
                HStack {
                    // 다크모드 토글 (정적 모드)
                    DarkModeToggle(
                        isDarkMode: isDarkModeBinding,
                        isTransitioning: .constant(false),
                        onTransitionStart: nil,
                        onButtonCenterChanged: nil,
                        isStatic: true,
                        staticIsDark: isDark
                    )
                    .padding(.leading, 20)
                    .padding(.top, 20)

                    Spacer()

                    // 공유 버튼 - 실제 상태 반영
                    ShareButton(fileURL: recording?.reversedFileURL, createdAt: recording?.createdAt)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                }

                Spacer()
            }
        }
    }

    // 메인 콘텐츠 뷰 (인터랙티브 버전)
    @ViewBuilder
    private func mainContent() -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Record button (perfect center)
            RecordButton(viewModel: viewModel)

            // Bottom controls
            VStack {
                Spacer()

                // Progress slider with waveform
                ProgressSlider(viewModel: viewModel)
                    .frame(height: 90)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                // Playback controls
                PlaybackControls(viewModel: viewModel)
                    .padding(.bottom, 50)
            }

            // Top controls (dark mode toggle & share button)
            VStack {
                HStack {
                    DarkModeToggle(
                        isDarkMode: isDarkModeBinding,
                        isTransitioning: $isTransitioning,
                        onTransitionStart: { newDarkMode in
                            startTransition(to: newDarkMode)
                        },
                        onButtonCenterChanged: { center in
                            toggleButtonCenter = center
                        }
                    )
                    .disabled(viewModel.isRecording)
                    .opacity(viewModel.isRecording ? 0.5 : 1.0)
                    .padding(.leading, 20)
                    .padding(.top, 20)

                    Spacer()

                    ShareButton(fileURL: viewModel.currentRecording?.reversedFileURL, createdAt: viewModel.currentRecording?.createdAt)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                }

                Spacer()
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            // 디바이스별 safe area에 비례한 오프셋 계산 (선형 보간)
            // iPhone 12 (safeArea 47pt) → 8.75, iPhone 16 Pro Max (safeArea 59pt) → 13.75
            let yOffset = (geometry.safeAreaInsets.top - 47) * 5 / 12 + 8.75

            ZStack {
                // 현재 테마의 메인 콘텐츠
                mainContent()

                // 트랜지션 오버레이 (스냅샷 이미지 기반)
                if isTransitioning, let snapshot = snapshotService.snapshot(for: transitionTargetDarkMode) {
                    Image(uiImage: snapshot)
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                        .ignoresSafeArea()
                        .mask(
                            Circle()
                                .frame(width: transitionRadius * 2, height: transitionRadius * 2)
                                .position(x: toggleButtonCenter.x, y: toggleButtonCenter.y - yOffset)
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(isDarkModeOverride == nil ? nil : (isDarkModeOverride! ? .dark : .light))
        .toast(isShowing: $viewModel.showToast, message: viewModel.toastMessage ?? "")
        .onAppear {
            viewModel.requestMicrophonePermission()

            // 스냅샷 업데이트 콜백 먼저 연결 (loadLastRecording에서 파형 추출 시 호출됨)
            viewModel.onSnapshotUpdateNeeded = { [self] in
                prepareThemeSnapshots()
            }

            // 초기 스냅샷 캡처 (저장된 녹음 없는 경우 대비)
            // 저장된 녹음이 있으면 파형 추출 완료 후 콜백에서 다시 캡처됨
            prepareThemeSnapshots()
        }
    }
}

#Preview {
    ContentView()
}
