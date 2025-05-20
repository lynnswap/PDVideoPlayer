//
//  Extension.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/03/02.
//

import SwiftUI
public extension EnvironmentValues {
    private enum MediaPresentKey: EnvironmentKey {
        static let defaultValue = true
    }
    var isPresentedMedia: Bool {
        get { self[MediaPresentKey.self] }
        set { self[MediaPresentKey.self] = newValue }
    }
}
