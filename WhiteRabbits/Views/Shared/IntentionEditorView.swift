//
//  IntentionEditorView.swift
//  WhiteRabbits
//
//  One true sentence for the month, plus an optional photo. Used from
//  the ritual sheet and from the "My Intention" card in Circle.
//

import SwiftUI
import PhotosUI

private let quickIntentions = [
    "Begin with softness",
    "Protect the quiet hours",
    "Make one true thing",
    "Leave room for luck",
    "Keep the mornings slow",
]

struct IntentionEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: PlatformImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(String(format: String(localized: "intention.title", defaultValue: "%@'s intention"), store.monthName()))
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(palette.ink)

                    Text(store.firstName.isEmpty
                         ? String(localized: "intention.subtitle.unnamed", defaultValue: "One true sentence for this month.")
                         : String(format: String(localized: "intention.subtitle.named", defaultValue: "%@, one true sentence for this month."), store.firstName))
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(palette.card)
                                .frame(height: 160)
                            #if canImport(UIKit)
                            if let photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            } else {
                                photoPlaceholder
                            }
                            #else
                            photoPlaceholder
                            #endif
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(palette.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .trailing, spacing: 6) {
                        TextField(String(localized: "intention.placeholder", defaultValue: "Write it here"), text: $text, axis: .vertical)
                            .font(.system(size: 17))
                            .padding(14)
                            .background(palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onChange(of: text) { _, newValue in
                                if newValue.count > 80 { text = String(newValue.prefix(80)) }
                            }
                        Text("\(text.count)/80")
                            .font(.system(size: 12))
                            .foregroundStyle(palette.faint)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickIntentions, id: \.self) { item in
                                Button {
                                    Haptics.light()
                                    text = item
                                } label: {
                                    Text(item)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().strokeBorder(palette.line, lineWidth: 1))
                                        .foregroundStyle(palette.muted)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text(String(localized: "intention.save", defaultValue: "Save intention"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle())
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(20)
            }
            .sanctuaryBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "Close")) { dismiss() }
                }
            }
        }
        .onAppear {
            text = store.monthRecord()?.intention ?? ""
            photo = store.intentionPhoto()
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                #if canImport(UIKit)
                if let image = UIImage(data: data) { photo = image }
                #endif
            }
        }
    }

    private var photoPlaceholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24))
                .foregroundStyle(palette.muted)
            Text(String(localized: "intention.addPhoto", defaultValue: "Add a photograph"))
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
        }
    }

    private func save() {
        Haptics.success()
        store.setIntention(text, photo: photo)
        dismiss()
    }
}

#Preview {
    IntentionEditorView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
