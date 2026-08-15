//
//  MyIntentionCardView.swift
//  WhiteRabbits
//
//  The prominent card at the top of Circle: a profile photo (or a
//  fallback to this month's bunny), the month's intention, and the
//  toggle that pins it to the Today page.
//

import SwiftUI
import PhotosUI

struct MyIntentionCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var showEditor = false
    @State private var profileItem: PhotosPickerItem?

    private var bunny: Bunny { store.currentBunny() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                profilePhoto

                Text(kickerText)
                    .kickerStyle()

                Spacer()
            }

            Button {
                showEditor = true
            } label: {
                Group {
                    if let intention = store.monthRecord()?.intention, !intention.isEmpty {
                        Text(intention)
                            .readingStyle()
                    } else {
                        Text(String(localized: "intention.card.empty", defaultValue: "Set it when you are ready. The circle can wait. Your journal is never asked for."))
                            .readingStyle(muted: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if store.monthRecord()?.intention != nil {
                Toggle(isOn: pinBinding) {
                    Text(String(localized: "intention.card.pin", defaultValue: "Pin to Today Page"))
                        .bodyStyle(weight: .medium)
                }
                .tint(palette.accent)
            }
        }
        .padding(Layout.cardPadding)
        .cardBackground()
        .sheet(isPresented: $showEditor) { IntentionEditorView() }
        .onChange(of: profileItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                #if canImport(UIKit)
                if let image = UIImage(data: data) { store.setProfilePhoto(image) }
                #endif
            }
        }
    }

    private var kickerText: String {
        String(format: String(localized: "intention.card.kicker", defaultValue: "%@ intention"), store.monthName())
    }

    private var pinBinding: Binding<Bool> {
        Binding(
            get: { store.isCurrentMonthPinned },
            set: { isOn in
                if isOn {
                    store.pinIntention(monthKey: store.monthKey())
                } else {
                    store.unpinIntention()
                }
                Haptics.light()
            }
        )
    }

    @ViewBuilder
    private var profilePhoto: some View {
        PhotosPicker(selection: $profileItem, matching: .images) {
            ZStack {
                #if canImport(UIKit)
                if let profile = store.profileImage() {
                    Image(uiImage: profile)
                        .resizable()
                        .scaledToFill()
                } else {
                    fallbackPhoto
                }
                #else
                fallbackPhoto
                #endif
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var fallbackPhoto: some View {
        ZStack {
            Color(hex: bunny.fillHex)
            BunnyMarkView(bunny: bunny, style: .charm)
                .padding(8)
        }
    }
}

#Preview {
    MyIntentionCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
