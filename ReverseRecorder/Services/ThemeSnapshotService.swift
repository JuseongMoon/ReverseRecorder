//
//  ThemeSnapshotService.swift
//  ReverseRecorder
//
//  Created by Claude on 11/25/25.
//

import SwiftUI
import UIKit
import Combine

/// 테마 전환 시 스냅샷 기반 circular reveal 트랜지션을 위한 서비스
/// 앱 시작 시 다크/라이트 테마의 디폴트 UI 스냅샷을 미리 캡처하여 저장
class ThemeSnapshotService: ObservableObject {
    static let shared = ThemeSnapshotService()

    // 미리 캡처된 스냅샷 저장
    @Published var lightSnapshot: UIImage?
    @Published var darkSnapshot: UIImage?
    @Published var isReady: Bool = false

    // 현재 스냅샷의 화면 크기 저장 (방향 변경 감지용)
    private var lastSnapshotSize: CGSize = .zero

    private init() {}

    /// 현재 화면 크기와 스냅샷 크기가 일치하는지 확인
    func needsSnapshotUpdate() -> Bool {
        let currentSize = UIScreen.main.bounds.size
        return lastSnapshotSize != currentSize
    }

    /// 앱 시작 시 호출 - 두 테마의 스냅샷 미리 캡처 (같은 뷰 사용)
    @MainActor
    func prepareSnapshots<Content: View>(contentView: Content) {
        // 라이트 테마 스냅샷
        captureSnapshot(for: contentView, isDarkMode: false) { [weak self] image in
            self?.lightSnapshot = image
            self?.checkReady()
        }

        // 다크 테마 스냅샷
        captureSnapshot(for: contentView, isDarkMode: true) { [weak self] image in
            self?.darkSnapshot = image
            self?.checkReady()
        }
    }

    /// 라이트 테마 스냅샷만 캡처
    @MainActor
    func captureLightSnapshot<Content: View>(contentView: Content) {
        captureSnapshot(for: contentView, isDarkMode: false) { [weak self] image in
            self?.lightSnapshot = image
            self?.checkReady()
        }
    }

    /// 다크 테마 스냅샷만 캡처
    @MainActor
    func captureDarkSnapshot<Content: View>(contentView: Content) {
        captureSnapshot(for: contentView, isDarkMode: true) { [weak self] image in
            self?.darkSnapshot = image
            self?.checkReady()
        }
    }

    private func checkReady() {
        isReady = (lightSnapshot != nil && darkSnapshot != nil)
    }

    /// 특정 테마의 스냅샷 반환
    func snapshot(for isDarkMode: Bool) -> UIImage? {
        isDarkMode ? darkSnapshot : lightSnapshot
    }

    /// 스냅샷 정리 (메모리 해제)
    func clearSnapshots() {
        lightSnapshot = nil
        darkSnapshot = nil
        isReady = false
    }

    /// SwiftUI View를 UIImage로 캡처
    @MainActor
    private func captureSnapshot<Content: View>(for view: Content, isDarkMode: Bool, completion: @escaping (UIImage?) -> Void) {
        let wrappedView = view
            .environment(\.colorScheme, isDarkMode ? .dark : .light)

        let hostingController = UIHostingController(rootView: wrappedView)
        hostingController.view.frame = UIScreen.main.bounds
        hostingController.view.backgroundColor = .systemBackground

        // 레이아웃 강제 업데이트
        hostingController.view.layoutIfNeeded()

        // 다음 런루프에서 스냅샷 캡처 (레이아웃 완료 보장)
        DispatchQueue.main.async { [weak self] in
            let bounds = UIScreen.main.bounds
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { _ in
                hostingController.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
            }
            // 캡처 완료 시 화면 크기 저장
            self?.lastSnapshotSize = bounds.size
            completion(image)
        }
    }
}
