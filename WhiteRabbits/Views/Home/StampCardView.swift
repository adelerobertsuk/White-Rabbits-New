//
//  StampCardView.swift
//  WhiteRabbits
//
//  Twelve months. Months that have already happened show that month's
//  own bunny artwork — a quiet dashed-outline ghost, or, for the
//  current month, its own true seasonal colour. Months still to come
//  wait behind a closed door: a single embossed ✦, nothing more.
//

import SwiftUI

struct StampCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
    private var current: Bunny { store.currentBunny() }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentYear)
                        .kickerStyle()
                    Text(String(localized: "circle.stampCard.title", defaultValue: "Year of luck"))
                        .font(.system(size: 24, weight: .light))
                        .tracking(-0.96)
                        .foregroundStyle(palette.ink)
                }
                Spacer()
                Text(String(format: String(localized: "circle.stampCard.countShort", defaultValue: "%d OF 12"), store.unlockedCharmIds.count))
                    .kickerStyle()
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(BunnyData.all) { bunny in
                    stampCell(bunny)
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .cardBackground(dashed: true)
    }

    private func stampCell(_ bunny: Bunny) -> some View {
        let isCurrent = bunny.id == current.id
        let isFuture = bunny.month > current.month

        return VStack(spacing: 5) {
            Group {
                if isFuture {
                    closedDoor()
                } else {
                    monthTile(bunny, isCurrent: isCurrent)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

            Text(monthAbbrev(bunny.month))
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.12)
                .textCase(.uppercase)
                .foregroundStyle(isCurrent ? palette.ink : palette.faint)
        }
    }

    // MARK: - Months still to come: a quiet door, not a lock

    /// Bone-on-bone (or dark-on-dark), a single embossed ✦. No bunny,
    /// no padlock, no preview — just a tactile, gently raised mark.
    @ViewBuilder
    private func closedDoor() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(palette.card)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 0.75)
            }
            .materialEmboss(colorScheme, strength: 0.55)
            .overlay {
                Text("✦")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(palette.bg)
                    .materialEmboss(colorScheme, strength: 1)
            }
    }

    // MARK: - Months already here: the original artwork

    /// Nothing about a month that's already happened is hidden — it
    /// shows its own bunny and seasonal prop. Past months sit as a
    /// quiet dashed-outline ghost in the app's neutral ink; the current
    /// month fills in, in its own true seasonal colour.
    @ViewBuilder
    private func monthTile(_ bunny: Bunny, isCurrent: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCurrent ? Color(hex: bunny.fillHex).opacity(colorScheme == .dark ? 0.22 : 0.55) : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isCurrent ? palette.accent.opacity(0.5) : palette.line,
                            style: StrokeStyle(lineWidth: isCurrent ? 1 : 0.75, dash: isCurrent ? [] : [5, 4])
                        )
                }

            BunnyMarkView(bunny: bunny, unlocked: true, style: .charm, monochrome: !isCurrent)
                .padding(6)
        }
        .shadow(color: isCurrent ? palette.accentGlow : .clear, radius: isCurrent ? 10 : 0, y: isCurrent ? 2 : 0)
    }

    private func monthAbbrev(_ month: Int) -> String {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "LLL"
        return formatter.string(from: date)
    }
}

#Preview {
    StampCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
