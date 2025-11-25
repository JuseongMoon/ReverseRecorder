//
//  AppIconManager.swift
//  ReverseRecorder
//
//  Created by Claude on 11/25/25.
//

import UIKit

class AppIconManager {
    static let shared = AppIconManager()

    private init() {}

    enum AppIcon: String {
        case light = "AppIcon-Light"
        case dark = "AppIcon-Dark"
    }

    var currentIconName: String? {
        UIApplication.shared.alternateIconName
    }

    func setIcon(isDarkMode: Bool, completion: (() -> Void)? = nil) {
        let targetIconName = isDarkMode ? AppIcon.dark.rawValue : AppIcon.light.rawValue

        guard UIApplication.shared.supportsAlternateIcons else {
            DispatchQueue.main.async { completion?() }
            return
        }

        // 현재 아이콘과 같으면 변경하지 않음 (불필요한 알림 방지)
        if currentIconName == targetIconName {
            DispatchQueue.main.async { completion?() }
            return
        }

        // 메인 스레드에서 실행 보장 (iOS 18 크래시 방지)
        DispatchQueue.main.async {
            UIApplication.shared.setAlternateIconName(targetIconName) { error in
                if let error = error {
                    print("Failed to change app icon: \(error.localizedDescription)")
                }
                DispatchQueue.main.async { completion?() }
            }
        }
    }
}
