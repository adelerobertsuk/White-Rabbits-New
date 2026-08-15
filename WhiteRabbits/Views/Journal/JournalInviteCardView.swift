//
//  JournalInviteCardView.swift
//  WhiteRabbits
//
//  The "Write / Photo / Voice" invite, shared by Today and Journal
//  exactly as in the reference build. If today already has a page,
//  a small preview sits underneath, tapping into the full entry.
//

import SwiftUI

struct JournalInviteCardView: View {
    var date: Date = Date()
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var showEntrySheet = false
    @State private var entryFocus: JournalEntryFocus = .write
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(kickerText)
                .font(.system(size: 10, weight: .medium))
                .textCase(.uppercase)
                .tracking(2.2)
                .foregroundStyle(palette.muted)

            Text(String(localized: "journal.invite.copy", defaultValue: "Whenever it feels right... write, drop a photo, or voice-note your thoughts."))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(palette.muted)
                .padding(.top, 4)
                .padding(.bottom, 10)

            HStack(spacing: 6) {
                actionButton(.write, systemImage: "pencil.line", label: String(localized: "journal.invite.write", defaultValue: "Write"))
                actionButton(.photo, systemImage: "photo", label: String(localized: "journal.invite.photo", defaultValue: "Photo"))
                actionButton(.voice, systemImage: "mic", label: String(localized: "journal.invite.voice", defaultValue: "Voice"))
            }

            if let entry = store.journalEntry(date), entry.hasContent {
                Button {
                    Haptics.light()
                    showDetail = true
                } label: {
                    HStack(spacing: 10) {
                        #if canImport(UIKit)
                        if let image = store.entryPhoto(entry) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        #endif
                        Text(entry.text.isEmpty ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.") : entry.text)
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(palette.line, lineWidth: 1)
                )
                .padding(.top, 12)
            }
        }
        .padding(18)
        .cardBackground()
        .sheet(isPresented: $showEntrySheet) {
            NewEntrySheet(date: date, focus: entryFocus)
        }
        .sheet(isPresented: $showDetail) {
            if let entry = store.journalEntry(date) {
                JournalEntryDetailView(entry: entry)
            }
        }
    }

    private var kickerText: String {
        store.firstName.isEmpty
            ? String(localized: "journal.invite.kicker.unnamed", defaultValue: "Today’s page")
            : String(format: String(localized: "journal.invite.kicker.named", defaultValue: "Today’s page, %@"), store.firstName)
    }

    private func actionButton(_ focus: JournalEntryFocus, systemImage: String, label: String) -> some View {
        Button {
            Haptics.light()
            entryFocus = focus
            showEntrySheet = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.44)
            }
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    JournalInviteCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
