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

    /// 앱 시작 시 다크/라이트 테마 스냅샷 미리 캡처
    private func prepareThemeSnapshots() {
        // 라이트 테마 스냅샷 (라이트 테마용 토글 버튼 포함)
        snapshotService.captureLightSnapshot(contentView: snapshotContent(isDark: false))

        // 약간의 딜레이 후 다크 테마 스냅샷 캡처 (동시 캡처 시 부하 분산)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            // 다크 테마 스냅샷 (다크 테마용 토글 버튼 포함)
            snapshotService.captureDarkSnapshot(contentView: snapshotContent(isDark: true))
        }
    }

    private func startTransition(to newDarkMode: Bool) {
        transitionTargetDarkMode = newDarkMode
        isTransitioning = true
        transitionRadius = 0

        withAnimation(.easeIn(duration: 0.4)) {  // 처음 느리게 → 점점 빨라짐
            transitionRadius = calculateMaxRadius()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isDarkModeOverride = newDarkMode
            isTransitioning = false
            transitionRadius = 0

            // 트랜지션 완료 후 앱 아이콘 변경 (iOS 18 크래시 방지)
            AppIconManager.shared.setIcon(isDarkMode: newDarkMode, completion: nil)
        }
    }

    // 정적 토글 버튼 (트랜지션 오버레이용, 콜백 없음)
    @ViewBuilder
    private func staticToggleButton(isDark: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isDark ? [.purple, .indigo] : [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: isDark ? .purple.opacity(0.5) : .orange.opacity(0.5), radius: 8)

            Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }

    /// 스냅샷 캡처용 디폴트 콘텐츠 (녹음 파일 없는 상태)
    /// 실제 컴포넌트를 빈 ViewModel로 재사용하여 레이아웃 일치 보장
    @ViewBuilder
    private func snapshotContent(isDark: Bool) -> some View {
        let emptyViewModel = RecorderViewModel()  // 빈 ViewModel (녹음 없음)

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

            // 녹음 버튼 (중앙) - 실제 컴포넌트 사용
            RecordButton(viewModel: emptyViewModel)

            // 하단 컨트롤 - 실제 컴포넌트 사용
            VStack {
                Spacer()

                ProgressSlider(viewModel: emptyViewModel)
                    .frame(height: 90)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                PlaybackControls(viewModel: emptyViewModel)
                    .padding(.bottom, 50)
            }

            // 상단 컨트롤
            VStack {
                HStack {
                    // 다크모드 토글 (정적 버튼 - 테마별 색상 필요)
                    staticToggleButton(isDark: isDark)
                        .padding(.leading, 20)
                        .padding(.top, 20)

                    Spacer()

                    // 공유 버튼 - 실제 컴포넌트 사용
                    ShareButton(fileURL: nil, createdAt: nil)
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
                        }
                    )
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
            // 전역 좌표를 로컬 좌표로 변환
            let localButtonCenter = CGPoint(
                x: toggleButtonCenter.x - geometry.frame(in: .global).minX,
                y: toggleButtonCenter.y - geometry.frame(in: .global).minY
            )

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
                                .position(x: toggleButtonCenter.x, y: toggleButtonCenter.y - 15)
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(ButtonCenterPreferenceKey.self) { center in
            toggleButtonCenter = center
        }
        .preferredColorScheme(isDarkModeOverride == nil ? nil : (isDarkModeOverride! ? .dark : .light))
        .toast(isShowing: $viewModel.showToast, message: viewModel.toastMessage ?? "")
        .onAppear {
            viewModel.requestMicrophonePermission()
            AppIconManager.shared.setIcon(isDarkMode: isDarkMode)

            // 스냅샷 미리 캡처 (디폴트 UI 상태)
            prepareThemeSnapshots()
        }
    }
}

#Preview {
    ContentView()
}
