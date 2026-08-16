//
//  StampCardView.swift
//  WhiteRabbits
//
//  Twelve seasonal stamps. Locked ones wait in dashed boxes.
//  Collected ones ink in, with a little tilt, like a real stamp book.
//

import SwiftUI

struct StampCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
    private var current: Bunny { store.currentBunny() }

    /// A passport-stamp tilt per month, so collected ones never sit in a perfect grid.
    private let tilts: [Double] = [-3.2, 2.6, -1.8, 3.8, -2.4, 1.6, -3.6, 2.2, -1.4, 3.2, -2.8, 1.9]

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
        let unlocked = store.unlockedCharmIds.contains(bunny.id)
        let isCurrent = bunny.id == current.id

        return VStack(spacing: 5) {
            BunnyMarkView(bunny: bunny, unlocked: unlocked, style: .charm)
                .padding(unlocked ? 4 : 7)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(unlocked ? Color(hex: bunny.fillHex).opacity(0.78) : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            unlocked
                                ? Color(hex: bunny.strokeHex).opacity(0.55)
                                : (isCurrent ? palette.accent : palette.line),
                            style: StrokeStyle(lineWidth: unlocked ? 1.6 : 1.4, dash: unlocked ? [] : [4, 3])
                        )
                }
                .rotationEffect(.degrees(unlocked ? tilts[(bunny.month - 1) % 12] : 0))
                .shadow(
                    color: unlocked ? Color(hex: bunny.accentHex).opacity(0.38) : .clear,
                    radius: unlocked ? 7 : 0,
                    y: unlocked ? 3 : 0
                )
                .opacity(unlocked ? 1 : (isCurrent ? 1 : 0.78))
                .animation(.spring(response: 0.55, dampingFraction: 0.78), value: unlocked)

            Text(monthAbbrev(bunny.month))
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.12)
                .textCase(.uppercase)
                .foregroundStyle(unlocked ? palette.ink : palette.faint)
        }
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
