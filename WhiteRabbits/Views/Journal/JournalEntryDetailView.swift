//
//  JournalEntryDetailView.swift
//  WhiteRabbits
//
//  View, edit, or share a single day's page.
//

import SwiftUI
import PhotosUI

private let moods = ["Calm", "Clear", "Tender", "Tired", "Lucky"]

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

    init(entry: JournalEntry) {
        self.entry = entry
        _text = State(initialValue: entry.text)
        _mood = State(initialValue: entry.mood)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(dateLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(palette.muted)

                    photoView

                    if isEditing {
                        editingContent
                    } else {
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
                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button(String(localized: "action.edit", defaultValue: "Edit")) {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .onAppear {
            photo = store.entryPhoto(entry)
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

    @ViewBuilder
    private var photoView: some View {
        #if canImport(UIKit)
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        #endif
    }

    private var viewingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !mood.isEmpty {
                Text(mood)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(palette.accentGlow))
                    .foregroundStyle(palette.ink)
            }
            Text(text.isEmpty ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.") : text)
                .font(.system(size: 17))
                .foregroundStyle(palette.ink)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text(String(localized: "journal.delete.action", defaultValue: "Delete Entry"))
                    .font(.system(size: 14))
            }
            .padding(.top, 12)
        }
    }

    private var editingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField(String(localized: "journal.new.placeholder", defaultValue: "Write here..."), text: $text, axis: .vertical)
                .font(.system(size: 17))
                .lineLimit(6...12)
                .padding(14)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moods, id: \.self) { item in
                        Button {
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
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Text(photo == nil ? String(localized: "journal.new.addPhoto", defaultValue: "Add a photo") : String(localized: "journal.new.changePhoto", defaultValue: "Change photo"))
                    .font(.system(size: 14))
            }

            HStack(spacing: 12) {
                Button {
                    Haptics.success()
                    store.saveJournalEntry(date: entry.date, text: text, mood: mood, photo: photo, removePhoto: removePhoto)
                    isEditing = false
                } label: {
                    Text(String(localized: "journal.new.save", defaultValue: "Save Entry"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle())
            }
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
