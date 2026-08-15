//
//  SuggestionsCardView.swift
//  WhiteRabbits
//
//  Up to 3 gentle, adaptive suggestions under the ring. Can be
//  collapsed if Adele would rather not see them.
//

import SwiftUI

struct SuggestionsCardView: View {
    let suggestions: [Suggestion]
    @Binding var isCollapsed: Bool
    var onTapSuggestion: (Suggestion) -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.25)) { isCollapsed.toggle() }
            } label: {
                HStack {
                    Text(String(localized: "suggestions.title", defaultValue: "Suggestions"))
                        .sectionHeaderStyle()
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.muted)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                if suggestions.isEmpty {
                    Text(String(localized: "suggestions.empty", defaultValue: "You're all caught up. Nothing waiting for you here."))
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 16)
                } else {
                    VStack(spacing: 10) {
                        ForEach(suggestions) { suggestion in
                            Button {
                                Haptics.light()
                                onTapSuggestion(suggestion)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: suggestion.systemImage)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(palette.muted)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(palette.track))
                                    Text(suggestion.title)
                                        .font(.system(size: 15))
                                        .foregroundStyle(palette.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(palette.faint)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
            }
        }
        .cardBackground()
    }
}

#Preview {
    SuggestionsCardView(
        suggestions: [
            Suggestion(id: "1", title: "Morning light", systemImage: "sun.max", action: .toggleHabit("light")),
            Suggestion(id: "2", title: "Write a few lines today", systemImage: "square.and.pencil", action: .openJournal),
        ],
        isCollapsed: .constant(false),
        onTapSuggestion: { _ in }
    )
    .environment(\.palette, .light)
    .padding()
}
