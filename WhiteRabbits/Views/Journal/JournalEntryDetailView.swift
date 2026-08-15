//
//  JournalEntryDetailView.swift
//  WhiteRabbits
//
//  View, edit, or share a single day's page. Reading mode uses the same
//  editorial hierarchy as the compose sheet (title, lede, a soft card
//  around the words) so a kept page feels just as considered as writing
//  a new one, not like a stripped-down afterthought.
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
                VStack(alignment: .leading, spacing: 10) {
                    Text(dateLabel)
                        .sectionHeaderStyle()

                    Text(isToday ? String(localized: "journal.new.title.today", defaultValue: "Today’s page") : String(localized: "journal.new.title.kept", defaultValue: "A kept page"))
                        .displayTitleStyle()
                        .padding(.bottom, 6)

                    if isEditing {
                        editingContent
                    } else {
                        photoView
                        viewingContent
                    }
                }
                .padding(20)
            }
            .sanctuaryBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "Close")) { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if !isEditing {
                        shareButton
                        Button(String(localized: "action.edit", defaultValue: "Edit")) {
                            Haptics.light()
                            isEditing = true
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

    private var isToday: Bool {
        Calendar.current.isDateInToday(entry.date)
    }

    @ViewBuilder
    private var shareButton: some View {
        #if canImport(UIKit)
        if let cardImage {
            ShareLink(
                item: Image(uiImage: cardImage),
                preview: SharePreview(dateLabel, image: Image(uiImage: cardImage))
            ) {
                Image(systemName: "square.and.arrow.up")
            }
        } else {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(palette.faint)
        }
        #else
        ShareLink(item: shareText) {
            Image(systemName: "square.and.arrow.up")
        }
        #endif
    }

    private func renderCard() {
        #if canImport(UIKit)
        cardImage = ShareCardRenderer.render(
            kicker: dateLabel,
            bodyText: text.isEmpty ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.") : text,
            photo: photo,
            bunny: store.currentBunny(entry.date),
            footer: "White Rabbits"
        )
        #endif
    }

    @ViewBuilder
    private var photoView: some View {
        #if canImport(UIKit)
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Layout.mediaRadiusLarge, style: .continuous))
        }
        #endif
    }

    private var viewingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !mood.isEmpty {
                Text(mood)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(palette.accentGlow))
                    .foregroundStyle(palette.ink)
            }

            Text(text.isEmpty ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.") : text)
                .font(.system(size: 16, weight: .medium))
                .lineSpacing(5)
                .foregroundStyle(palette.ink)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(palette.line, lineWidth: 1)
                )

            Button(role: .destructive) {
                Haptics.light()
                showDeleteConfirm = true
            } label: {
                Text(String(localized: "journal.delete.action", defaultValue: "Delete Entry"))
                    .font(.system(size: 14))
            }
            .padding(.top, 4)
        }
    }

    private var editingContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            JournalPhotoPickerView(photoItem: $photoItem, photo: $photo, removePhoto: $removePhoto, height: 200)

            ZStack(alignment: .bottomTrailing) {
                TextField(String(localized: "journal.new.placeholder", defaultValue: "A few honest lines, whenever you like..."), text: $text, axis: .vertical)
                    .font(.system(size: 16, weight: .medium))
                    .lineSpacing(4)
                    .lineLimit(7...14)
                    .padding(.trailing, 40)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }

                Text("\(text.count)/\(maxLength)")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.faint)
            }
            .padding(14)
            .frame(minHeight: 88)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 1)
            )

            voiceButton

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moods, id: \.self) { item in
                        Button {
                            Haptics.light()
                            mood = (mood == item) ? "" : item
                        } label: {
                            Text(item)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(mood == item ? palette.accent : Color.clear))
                                .overlay(Capsule().strokeBorder(mood == item ? Color.clear : palette.line, lineWidth: 1))
                                .foregroundStyle(mood == item ? palette.bg : palette.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                Haptics.success()
                dictation.stop()
                store.saveJournalEntry(date: entry.date, text: text, mood: mood, photo: photo, removePhoto: removePhoto)
                isEditing = false
            } label: {
                Text(String(localized: "journal.new.save", defaultValue: "Keep this page"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle())
            .padding(.top, 6)
        }
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
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 13))
                Text(dictation.isListening
                    ? String(localized: "journal.new.listening", defaultValue: "Listening…")
                    : String(localized: "journal.new.voiceToText", defaultValue: "Voice to text"))
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(dictation.isListening ? palette.ink : palette.accentGlow))
            .foregroundStyle(dictation.isListening ? palette.bg : palette.accent)
        }
        .buttonStyle(.plain)
        .alert(String(localized: "journal.new.micDenied", defaultValue: "Microphone access is off"), isPresented: $dictation.authorizationDenied) {
            Button(String(localized: "action.ok", defaultValue: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "journal.new.micDenied.body", defaultValue: "Turn it on in Settings to use Voice to text."))
        }
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
