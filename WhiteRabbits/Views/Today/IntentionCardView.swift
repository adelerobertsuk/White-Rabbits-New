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
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var cardImage: PlatformImage?

    var body: some View {
        VStack(spacing: 8) {
            Text(kicker)
                .kickerStyle()

            Text(record.intention ?? "")
                .displayTitleStyle(weight: .regular)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            shareButton
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity)
        .cardBackground()
        .onAppear { renderCard() }
        .onChange(of: record.intention) { _, _ in renderCard() }
        .onChange(of: record.photoFileName) { _, _ in renderCard() }
    }

    @ViewBuilder
    private var shareButton: some View {
        #if canImport(UIKit)
        if let cardImage {
            ShareLink(
                item: Image(uiImage: cardImage),
                preview: SharePreview(kicker, image: Image(uiImage: cardImage))
            ) {
                Text(String(localized: "today.intention.share", defaultValue: "Share story card"))
            }
            .buttonStyle(PillButtonStyle(filled: false, compact: true))
            .id(cardImage)
        } else {
            Button {} label: {
                Text(String(localized: "today.intention.share", defaultValue: "Share story card"))
            }
            .buttonStyle(PillButtonStyle(filled: false, compact: true))
            .disabled(true)
            .opacity(0.5)
        }
        #else
        ShareLink(item: shareText) {
            Text(String(localized: "today.intention.share", defaultValue: "Share story card"))
        }
        .buttonStyle(PillButtonStyle(filled: false, compact: true))
        #endif
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

    private func renderCard() {
        #if canImport(UIKit)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        cardImage = ShareCardRenderer.render(
            monthYear: formatter.string(from: Date()),
            headline: record.intention ?? "",
            subtitle: InspirationData.signature().line,
            photo: store.intentionPhoto(),
            bunny: store.currentBunny()
        )
        #endif
    }
}

#Preview {
    IntentionCardView(record: MonthRecord(key: "2026-08", year: 2026, month: 8, intention: "Golden hour, gathered."))
        .environment(\.palette, .light)
        .padding()
}
