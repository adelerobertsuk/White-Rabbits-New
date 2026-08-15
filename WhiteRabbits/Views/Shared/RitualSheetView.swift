//
//  RitualSheetView.swift
//  WhiteRabbits
//
//  The first-of-the-month ritual. Tap to say the words, watch the
//  month's charm arrive, then (optionally) set an intention.
//

import SwiftUI

struct RitualSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var didCelebrate = false
    @State private var showIntentionEditor = false
    @State private var dustPhase = false

    private var bunny: Bunny { store.currentBunny() }

    var body: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(palette.line)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Spacer(minLength: 4)

            Text(String(format: String(localized: "ritual.header", defaultValue: "The first of %@"), store.monthName()))
                .font(.system(size: 13, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(palette.muted)

            ZStack {
                Circle()
                    .fill(Color(hex: bunny.fillHex))
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: bunny.accentHex).opacity(didCelebrate ? 0.7 : 0.3), radius: didCelebrate ? 30 : 14)

                BunnyMarkView(bunny: bunny, style: .charm)
                    .frame(width: 92, height: 92)

                if didCelebrate {
                    ForEach(0..<14, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat.random(in: 8...14)))
                            .foregroundStyle(palette.accent)
                            .offset(x: cos(Double(i)) * 90 * (dustPhase ? 1 : 0.4),
                                    y: sin(Double(i) * 1.3) * 90 * (dustPhase ? 1 : 0.4) - (dustPhase ? 30 : 0))
                            .opacity(dustPhase ? 0 : 1)
                    }
                }
            }
            .padding(.vertical, 8)

            if didCelebrate {
                VStack(spacing: 8) {
                    Text(store.firstName.isEmpty
                         ? String(format: String(localized: "ritual.celebrate.unnamed", defaultValue: "%@ is yours."), store.monthName())
                         : String(format: String(localized: "ritual.celebrate.named", defaultValue: "%@ is yours, %@."), store.monthName(), store.firstName))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(palette.ink)
                    Text(String(format: String(localized: "ritual.celebrate.caption", defaultValue: "%@ is this month's charm. A little luck for the days ahead."), bunny.name))
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 8) {
                    Text(store.firstName.isEmpty ? String(localized: "ritual.welcome.unnamed", defaultValue: "Welcome.") : String(format: String(localized: "ritual.welcome.named", defaultValue: "Welcome, %@."), store.firstName))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(palette.ink)
                    Text(bunny.line)
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            Spacer(minLength: 4)

            VStack(spacing: 12) {
                if didCelebrate {
                    Button {
                        showIntentionEditor = true
                    } label: {
                        Text(String(localized: "ritual.setIntention", defaultValue: "Set this month's intention"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle())

                    Button(String(localized: "action.close", defaultValue: "Close")) { dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                } else {
                    Button {
                        sayTheWords()
                    } label: {
                        Text(String(localized: "ritual.sayIt", defaultValue: "Say White Rabbits"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle())

                    Button(String(localized: "ritual.later", defaultValue: "I'll begin later")) { dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sanctuaryBackground()
        .sheet(isPresented: $showIntentionEditor) {
            IntentionEditorView()
        }
    }

    private func sayTheWords() {
        Haptics.success()
        store.completeRitual()
        withAnimation(.easeOut(duration: 0.5)) {
            didCelebrate = true
        }
        withAnimation(.easeOut(duration: 1.1).delay(0.15)) {
            dustPhase = true
        }
    }
}

#Preview {
    RitualSheetView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
