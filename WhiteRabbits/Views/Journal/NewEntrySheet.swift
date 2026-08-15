//
//  NewEntrySheet.swift
//  WhiteRabbits
//
//  Write, add a photo, or just pick a mood. Nothing is required.
//  Saving here is always called "Save Entry", never anything else.
//

import SwiftUI
import PhotosUI

private let moods = ["Calm", "Clear", "Tender", "Tired", "Lucky"]

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(dateLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(palette.muted)

                    Text(String(localized: "journal.new.subtitle", defaultValue: "Whenever it feels right, write a few lines or add a photo."))
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)

                    TextField(String(localized: "journal.new.placeholder", defaultValue: "Write here..."), text: $text, axis: .vertical)
                        .font(.system(size: 17))
                        .lineLimit(6...12)
                        .padding(14)
                        .background(palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .focused($textFieldFocused)

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
                    }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 10) {
                            #if canImport(UIKit)
                            if let photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                photoIcon
                            }
                            #else
                            photoIcon
                            #endif
                            Text(photo == nil ? String(localized: "journal.new.addPhoto", defaultValue: "Add a photo") : String(localized: "journal.new.changePhoto", defaultValue: "Change photo"))
                                .font(.system(size: 14))
                                .foregroundStyle(palette.ink)
                            Spacer()
                            if photo != nil {
                                Button {
                                    photo = nil
                                    removePhoto = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(palette.faint)
                                }
                            }
                        }
                        .padding(12)
                        .cardBackground(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)

                    Button {
                        save()
                    } label: {
                        Text(String(localized: "journal.new.save", defaultValue: "Save Entry"))
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
                    Button(String(localized: "action.cancel", defaultValue: "Cancel")) { dismiss() }
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
            case .write, .voice:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { textFieldFocused = true }
            case .photo:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { autoShowPhotoPicker = true }
            }
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
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: date)
    }

    private var photoIcon: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(palette.card)
            .frame(width: 48, height: 48)
            .overlay(Image(systemName: "camera").foregroundStyle(palette.muted))
    }

    private func save() {
        Haptics.success()
        store.saveJournalEntry(date: date, text: text, mood: mood, photo: photo, removePhoto: removePhoto)
        dismiss()
    }
}

#Preview {
    NewEntrySheet(date: Date())
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
