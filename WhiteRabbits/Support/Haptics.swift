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
    /// Mirrors the "Haptics" toggle in Settings. Kept as a plain static
    /// flag so every `Haptics.light()` call site doesn't need access
    /// to the store.
    static var isEnabled = true

    static func light() {
        #if os(iOS)
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func medium() {
        #if os(iOS)
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func success() {
        #if os(iOS)
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
