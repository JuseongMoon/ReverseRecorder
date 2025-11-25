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

    func setIcon(isDarkMode: Bool) {
        let targetIconName = isDarkMode ? AppIcon.dark.rawValue : AppIcon.light.rawValue

        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }

        // 현재 아이콘과 같으면 변경하지 않음 (불필요한 알림 방지)
        if currentIconName == targetIconName {
            return
        }

        UIApplication.shared.setAlternateIconName(targetIconName) { error in
            if let error = error {
                print("Failed to change app icon: \(error.localizedDescription)")
            }
        }
    }
}
