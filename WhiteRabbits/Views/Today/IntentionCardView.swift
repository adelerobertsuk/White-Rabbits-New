//
//  IntentionCardView.swift
//  WhiteRabbits
//
//  The "{Month} intention" card on Today, matching the web app's
//  manifesto-card: this month's intention in full, with a "Share
//  story card" link. Only appears once an intention has been set.
//

import SwiftUI

struct IntentionCardView: View {
    let record: MonthRecord
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 10) {
            Text(kicker)
                .font(.system(size: 10, weight: .medium))
                .textCase(.uppercase)
                .tracking(2.2)
                .foregroundStyle(palette.muted)

            Text(record.intention ?? "")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ShareLink(item: shareText) {
                Text(String(localized: "today.intention.share", defaultValue: "Share story card"))
            }
            .buttonStyle(PillButtonStyle(filled: false, compact: true))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardBackground()
    }

    private var kicker: String {
        let month = DateFormatter()
        month.setLocalizedDateFormatFromTemplate("MMMM")
        let name = month.string(from: Date())
        return String(format: String(localized: "today.intention.kicker", defaultValue: "%@ intention"), name)
    }

    private var shareText: String {
        "\(kicker): \(record.intention ?? "")"
    }
}

#Preview {
    IntentionCardView(record: MonthRecord(key: "2026-08", year: 2026, month: 8, intention: "Golden hour, gathered."))
        .environment(\.palette, .light)
        .padding()
}
