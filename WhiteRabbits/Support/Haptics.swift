//
//  Haptics.swift
//  WhiteRabbits
//
//  Tiny taps of feedback so the app feels alive. Safe to call on any
//  platform; it simply does nothing where haptics don't exist.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    static func light() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func medium() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
