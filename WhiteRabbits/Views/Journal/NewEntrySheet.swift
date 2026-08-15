//
//  NewEntrySheet.swift
//  WhiteRabbits
//
//  "Today's page" / "A kept page": write, add a photo, or dictate a few
//  lines, then pick a mood. Nothing is required. Matches the reference
//  build's compose sheet: big photograph up top, a lined text card with
//  a live character count, then Voice to text, moods, and "Keep this
//  page" to finish.
//

import SwiftUI
import PhotosUI

private let moods = ["Calm", "Clear", "Tender", "Tired", "Lucky"]
private let maxLength = 2000

/// Which of the journal invite's three buttons (Write / Photo / Voice)
/// opened this sheet, so it can jump straight to the right control.
enum JournalEntryFocus {
    case write, photo, voice
}

struct NewEntrySheet: View {
    let date: Date
    var focus: JournalEntryFocus = .write
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var mood: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: PlatformImage?
    @State private var removePhoto = false
    @State private var autoShowPhotoPicker = false
    @FocusState private var textFieldFocused: Bool
    @StateObject private var dictation = DictationManager()
    @State private var dictationPrefix = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(dateLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(palette.muted)

                    Text(isToday ? String(localized: "journal.new.title.today", defaultValue: "Today’s page") : String(localized: "journal.new.title.kept", defaultValue: "A kept page"))
                        .font(.system(size: 28, weight: .light))
                        .tracking(-0.3)
                        .foregroundStyle(palette.ink)
                        .padding(.bottom, 2)

                    Text(lede)
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                        .padding(.bottom, 4)

                    photoButton

                    textField

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
                                        .background(
                                            Capsule().fill(mood == item ? palette.accent : Color.clear)
                                        )
                                        .overlay(
                                            Capsule().strokeBorder(mood == item ? Color.clear : palette.line, lineWidth: 1)
                                        )
                                        .foregroundStyle(mood == item ? palette.bg : palette.muted)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.bottom, 6)

                    Button {
                        save()
                    } label: {
                        Text(String(localized: "journal.new.save", defaultValue: "Keep this page"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle())
                }
                .padding(20)
            }
            .sanctuaryBackground()
            .photosPicker(isPresented: $autoShowPhotoPicker, selection: $photoItem, matching: .images)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "Close")) { dismiss() }
                }
            }
        }
        .onAppear {
            if let existing = store.journalEntry(date) {
                text = existing.text
                mood = existing.mood
                photo = store.entryPhoto(existing)
            }
            switch focus {
            case .write:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { textFieldFocused = true }
            case .photo:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { autoShowPhotoPicker = true }
            case .voice:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { startDictation() }
            }
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
                }
                #endif
            }
        }
        .onChange(of: dictation.transcript) { _, newValue in
            guard dictation.isListening else { return }
            text = dictationPrefix.isEmpty ? newValue : "\(dictationPrefix) \(newValue)"
        }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var lede: String {
        if store.firstName.isEmpty {
            return isToday
                ? String(localized: "journal.new.lede.today.unnamed", defaultValue: "This page stays on this phone, in your journal.")
                : String(localized: "journal.new.lede.kept.unnamed", defaultValue: "This page stays on this phone, in your journal.")
        }
        let format = isToday
            ? String(localized: "journal.new.lede.today.named", defaultValue: "%@, this page stays on this phone, in your journal.")
            : String(localized: "journal.new.lede.kept.named", defaultValue: "%@, this page stays on this phone, in your journal.")
        return String(format: format, store.firstName)
    }

    private var photoButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(palette.card)
                #if canImport(UIKit)
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    photoEmptyLabel
                }
                #else
                photoEmptyLabel
                #endif
            }
            .frame(height: 170)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(palette.line, style: StrokeStyle(lineWidth: 1, dash: photo == nil ? [5, 5] : []))
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if photo != nil {
                Button {
                    Haptics.light()
                    photo = nil
                    removePhoto = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(palette.ink)
                        .background(Circle().fill(palette.bg))
                }
                .padding(8)
            }
        }
    }

    private var photoEmptyLabel: some View {
        VStack(spacing: 6) {
            Image(systemName: "camera")
                .font(.system(size: 18))
            Text(String(localized: "journal.new.addPhotograph", defaultValue: "Add a photograph"))
                .font(.system(size: 14))
        }
        .foregroundStyle(palette.muted)
    }

    private var textField: some View {
        ZStack(alignment: .bottomTrailing) {
            TextField(String(localized: "journal.new.placeholder", defaultValue: "A few honest lines, whenever you like..."), text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .medium))
                .lineSpacing(4)
                .lineLimit(7...14)
                .focused($textFieldFocused)
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
    }

    private var voiceButton: some View {
        Button {
            Haptics.light()
            dictation.toggle()
            if dictation.isListening {
                dictationPrefix = text
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
            .background(
                Capsule().fill(dictation.isListening ? palette.ink : palette.accentGlow)
            )
            .foregroundStyle(dictation.isListening ? palette.bg : palette.accent)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 4)
        .alert(String(localized: "journal.new.micDenied", defaultValue: "Microphone access is off"), isPresented: $dictation.authorizationDenied) {
            Button(String(localized: "action.ok", defaultValue: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "journal.new.micDenied.body", defaultValue: "Turn it on in Settings to use Voice to text."))
        }
    }

    private func startDictation() {
        dictationPrefix = text
        dictation.start()
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: date)
    }

    private func save() {
        Haptics.success()
        dictation.stop()
        store.saveJournalEntry(date: date, text: text, mood: mood, photo: photo, removePhoto: removePhoto)
        dismiss()
    }
}

#Preview {
    NewEntrySheet(date: Date())
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
