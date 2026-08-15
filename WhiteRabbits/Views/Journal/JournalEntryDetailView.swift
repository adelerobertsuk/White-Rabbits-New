//
//  JournalEntryDetailView.swift
//  WhiteRabbits
//
//  View, edit, or share a single day's page. Reading mode uses the same
//  editorial card as the story share: brand header, photo well with an
//  overlapping bunny badge, serif body, and the Pause / Reflect / Intend
//  / Begin footer.
//

import SwiftUI
import PhotosUI

private let moods = ["Calm", "Clear", "Tender", "Tired", "Lucky"]
private let maxLength = 2000

struct JournalEntryDetailView: View {
    let entry: JournalEntry

    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var text: String
    @State private var mood: String
    @State private var photo: PlatformImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var removePhoto = false
    @State private var showDeleteConfirm = false
    @StateObject private var dictation = DictationManager()
    @State private var dictationPrefix = ""
    @State private var cardImage: PlatformImage?

    init(entry: JournalEntry) {
        self.entry = entry
        _text = State(initialValue: entry.text)
        _mood = State(initialValue: entry.mood)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    editorialCard

                    if !isEditing {
                        Button(role: .destructive) {
                            Haptics.light()
                            showDeleteConfirm = true
                        } label: {
                            Text(String(localized: "journal.delete.action", defaultValue: "Delete Entry"))
                                .captionStyle()
                                .underline()
                        }
                    }
                }
                .padding(Layout.screenInset)
                .padding(.bottom, 28)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "action.close", defaultValue: "Close"))
                            .kickerStyle()
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button(action: saveEdits) {
                            Text(String(localized: "action.keep", defaultValue: "Keep"))
                                .kickerStyle()
                                .foregroundStyle(palette.ink)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 16) {
                            shareButton
                            Button {
                                Haptics.light()
                                isEditing = true
                            } label: {
                                Text(String(localized: "action.edit", defaultValue: "Edit"))
                                    .kickerStyle()
                                    .foregroundStyle(palette.ink)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .onAppear {
            photo = store.entryPhoto(entry)
            renderCard()
        }
        .onDisappear {
            dictation.stop()
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                #if canImport(UIKit)
                if let image = UIImage(data: data) {
                    photo = image
                    removePhoto = false
                    renderCard()
                }
                #endif
            }
        }
        .onChange(of: isEditing) { wasEditing, editing in
            if wasEditing && !editing { renderCard() }
        }
        .onChange(of: dictation.transcript) { _, newValue in
            guard dictation.isListening else { return }
            text = dictationPrefix.isEmpty ? newValue : "\(dictationPrefix) \(newValue)"
        }
        .confirmationDialog(
            String(localized: "journal.delete.confirm", defaultValue: "Delete this entry?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "journal.delete.action", defaultValue: "Delete Entry"), role: .destructive) {
                store.deleteJournalEntry(date: entry.date)
                dismiss()
            }
            Button(String(localized: "action.cancel", defaultValue: "Cancel"), role: .cancel) {}
        }
    }

    // MARK: - Editorial card

    private var editorialCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            photoWell
                .padding(.bottom, 36)

            if isEditing {
                editingBody
            } else {
                readingBody
            }

            Spacer(minLength: 24)

            footer
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(palette.accent.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: palette.ink.opacity(0.08), radius: 20, x: 0, y: 16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("WHITE RABBITS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(palette.accent)
            Text(monthYearLabel)
                .font(.system(size: 10, weight: .regular))
                .tracking(2)
                .foregroundStyle(palette.accent.opacity(0.8))
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var photoWell: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isEditing {
                    JournalPhotoPickerView(
                        photoItem: $photoItem,
                        photo: $photo,
                        removePhoto: $removePhoto,
                        height: 210
                    )
                } else {
                    readingPhoto
                }
            }
            .padding(.horizontal, 24)

            EditorialBunnyBadge(bunny: store.currentBunny(entry.date))
                .offset(y: 32)
        }
        .frame(maxWidth: .infinity)
    }

    private var readingPhoto: some View {
        Color.clear
            .frame(height: 210)
            .overlay {
                #if canImport(UIKit)
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    palette.accent.opacity(0.1)
                }
                #else
                palette.accent.opacity(0.1)
                #endif
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var readingBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(pageKicker)
                    .kickerStyle()
                if !mood.isEmpty {
                    Text(mood)
                        .font(.system(size: 9, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundStyle(palette.accent)
                }
            }

            Text(displayText)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .lineSpacing(2)
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(InspirationData.signature(for: entry.date).line)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(palette.muted)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
    }

    private var editingBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(pageKicker)
                .kickerStyle()

            ZStack(alignment: .bottomTrailing) {
                TextField(
                    String(localized: "journal.new.placeholder", defaultValue: "A few honest lines, whenever you like..."),
                    text: $text,
                    axis: .vertical
                )
                .font(.system(size: 18, weight: .regular, design: .serif))
                .lineSpacing(3)
                .foregroundStyle(palette.ink)
                .lineLimit(4...12)
                .padding(.trailing, 36)
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }

                Text("\(text.count)/\(maxLength)")
                    .captionStyle()
                    .foregroundStyle(palette.faint)
            }

            voiceButton

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moods, id: \.self) { item in
                        Button {
                            Haptics.light()
                            mood = (mood == item) ? "" : item
                        } label: {
                            Text(item)
                                .font(.system(size: 9, weight: .semibold))
                                .textCase(.uppercase)
                                .tracking(1.8)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            mood == item ? palette.accent : palette.line,
                                            lineWidth: 1
                                        )
                                )
                                .foregroundStyle(mood == item ? palette.accent : palette.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var footer: some View {
        HStack {
            Text("PAUSE")
            Spacer()
            Text("REFLECT")
            Spacer()
            Text("INTEND")
            Spacer()
            Text("BEGIN")
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(2)
        .foregroundStyle(palette.accent)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var voiceButton: some View {
        Button {
            Haptics.light()
            if dictation.isListening {
                dictation.stop()
            } else {
                dictationPrefix = text
                dictation.start()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(dictation.isListening
                    ? String(localized: "journal.new.listening", defaultValue: "Listening…")
                    : String(localized: "journal.new.voiceToText", defaultValue: "Voice to text"))
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.6)
                    .textCase(.uppercase)
            }
            .foregroundStyle(dictation.isListening ? palette.ink : palette.muted)
        }
        .buttonStyle(.plain)
        .alert(String(localized: "journal.new.micDenied", defaultValue: "Microphone access is off"), isPresented: $dictation.authorizationDenied) {
            Button(String(localized: "action.ok", defaultValue: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "journal.new.micDenied.body", defaultValue: "Turn it on in Settings to use Voice to text."))
        }
    }

    // MARK: - Actions

    private var isToday: Bool {
        Calendar.current.isDateInToday(entry.date)
    }

    private var pageKicker: String {
        isToday
            ? String(localized: "journal.new.title.today", defaultValue: "Today’s page")
            : String(localized: "journal.new.title.kept", defaultValue: "A kept page")
    }

    private var displayText: String {
        text.isEmpty
            ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.")
            : text
    }

    private var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter.string(from: entry.date).uppercased()
    }

    @ViewBuilder
    private var shareButton: some View {
        #if canImport(UIKit)
        if let cardImage {
            ShareLink(
                item: Image(uiImage: cardImage),
                preview: SharePreview(dateLabel, image: Image(uiImage: cardImage))
            ) {
                Text(String(localized: "action.share", defaultValue: "Share"))
                    .kickerStyle()
                    .foregroundStyle(palette.accent)
            }
        } else {
            Text(String(localized: "action.share", defaultValue: "Share"))
                .kickerStyle()
                .foregroundStyle(palette.faint)
        }
        #else
        ShareLink(item: shareText) {
            Text(String(localized: "action.share", defaultValue: "Share"))
                .kickerStyle()
                .foregroundStyle(palette.accent)
        }
        #endif
    }

    private func renderCard() {
        #if canImport(UIKit)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        cardImage = ShareCardRenderer.render(
            monthYear: formatter.string(from: entry.date),
            headline: text.isEmpty ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.") : text,
            subtitle: InspirationData.signature(for: entry.date).line,
            photo: photo,
            bunny: store.currentBunny(entry.date)
        )
        #endif
    }

    private func saveEdits() {
        Haptics.success()
        dictation.stop()
        store.saveJournalEntry(date: entry.date, text: text, mood: mood, photo: photo, removePhoto: removePhoto)
        isEditing = false
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMMyyyy")
        return formatter.string(from: entry.date)
    }

    private var shareText: String {
        "\(dateLabel)\n\n\(text)"
    }
}

private struct EditorialBunnyBadge: View {
    let bunny: Bunny
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Circle()
                .fill(palette.card)
                .frame(width: 64, height: 64)
                .shadow(color: palette.ink.opacity(0.08), radius: 6, x: 0, y: 3)
            BunnyMarkView(bunny: bunny, style: .mark)
                .frame(width: 32, height: 32)
        }
        .overlay(
            Circle()
                .strokeBorder(palette.accent.opacity(0.3), lineWidth: 1)
        )
    }
}
