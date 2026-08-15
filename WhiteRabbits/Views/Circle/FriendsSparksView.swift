//
//  FriendsSparksView.swift
//  WhiteRabbits
//
//  Friends and gentle reference cards, each with a one-tap "Send a
//  Spark" that gives a small animation and haptic buzz. No scores,
//  no streaks, no comparison.
//

import SwiftUI

struct FriendsSparksView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var showAddFriend = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.stackSpacing) {
            if store.circleJoined {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(String(localized: "circle.members.title", defaultValue: "In your circle"))
                            .sectionHeaderStyle()
                        Spacer()
                        if store.isSyncingCircle {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }

                    if store.circleMembers.isEmpty {
                        Text(String(localized: "circle.members.empty", defaultValue: "As soon as someone else in the circle sets an intention this month, their card appears here."))
                            .bodyStyle(muted: true)
                    } else {
                        ForEach(store.circleMembers) { card in
                            SparkCardView(card: card, canRemove: false)
                        }
                    }

                    if let error = store.circleSyncError {
                        Text(error)
                            .captionStyle()
                            .foregroundStyle(palette.faint)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "circle.friends.title", defaultValue: "Friends"))
                        .sectionHeaderStyle()
                    Spacer()
                    Button {
                        showAddFriend = true
                    } label: {
                        Label(String(localized: "circle.friends.add", defaultValue: "Add"), systemImage: "plus")
                            .bodyStyle(weight: .medium)
                    }
                }

                if store.friends.isEmpty {
                    Text(String(localized: "circle.friends.empty", defaultValue: "Add a friend's name and their intention. You'll see their intention and stamp, nothing else."))
                        .bodyStyle(muted: true)
                } else {
                    ForEach(store.friends) { card in
                        SparkCardView(card: card, canRemove: true)
                    }
                }
            }

            if showFellows {
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "circle.fellows.title", defaultValue: "Fellow intentions"))
                        .sectionHeaderStyle()

                    ForEach(fellowCards) { card in
                        SparkCardView(card: card, canRemove: false)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFriend) { AddFriendSheet() }
    }

    /// Real connections: circle members plus friends Adele has added.
    private var realConnectionCount: Int {
        store.circleMembers.count + store.friends.count
    }

    /// Once there are 2 or more real connections, the fictional "fellow"
    /// cards step aside entirely so the screen reflects Adele's actual
    /// circle rather than always padding it out with 4 placeholder cards.
    private var showFellows: Bool {
        realConnectionCount < 2
    }

    private var fellowCards: [SanctuaryCard] {
        Array(store.fellows().prefix(2))
    }
}

private struct SparkCardView: View {
    let card: SanctuaryCard
    let canRemove: Bool

    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @State private var motes: [CGFloat] = []

    private var bunny: Bunny { BunnyData.bunny(id: card.charmId) }
    private var sent: Bool {
        if let remoteID = card.remoteUserID { return store.hasSparked(remoteUserID: remoteID) }
        return store.hasSparked(card.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            cardIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .bodyStyle(weight: .medium)
                Text(card.intention)
                    .bodyStyle(muted: true)
                    .lineLimit(2)
            }

            Spacer()

            ZStack {
                Button {
                    guard !sent else { return }
                    Haptics.success()
                    if let remoteID = card.remoteUserID {
                        store.sendSpark(remoteUserID: remoteID)
                    } else {
                        store.sendSpark(card.id)
                    }
                    burst()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: sent ? "checkmark" : "sparkle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(sent ? palette.muted : palette.accent)
                        Text(sent
                             ? String(localized: "circle.spark.sent", defaultValue: "Sent")
                             : String(localized: "circle.spark.send", defaultValue: "Send a spark"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(sent ? palette.muted : palette.ink)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(Capsule().strokeBorder(palette.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(sent)

                ForEach(motes, id: \.self) { seed in
                    Image(systemName: "sparkle")
                        .font(.system(size: 9))
                        .foregroundStyle(palette.accent)
                        .offset(x: cos(seed) * 30, y: sin(seed) * 22 - 16)
                        .opacity(0)
                        .animation(.easeOut(duration: 0.6), value: motes)
                }
            }

            if canRemove {
                Button {
                    store.removeFriend(card.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(palette.faint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .cardBackground(cornerRadius: Layout.cardRadius)
    }

    @ViewBuilder
    private var cardIcon: some View {
        if let url = card.photoURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    CharmView(bunny: bunny, unlocked: true, size: 44)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(palette.line, lineWidth: 1))
        } else {
            CharmView(bunny: bunny, unlocked: true, size: 44)
        }
    }

    private func burst() {
        motes = (0..<8).map { _ in CGFloat.random(in: 0...(2 * .pi)) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            motes = []
        }
    }
}

private struct AddFriendSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var intention = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "circle.addFriend.name", defaultValue: "Their name"), text: $name)
                    TextField(String(localized: "circle.addFriend.intention", defaultValue: "Their intention"), text: $intention)
                } footer: {
                    Text(String(localized: "circle.addFriend.footer", defaultValue: "This stays on your phone only. It's just a nice reminder of what they're working towards."))
                }
            }
            .navigationTitle(String(localized: "circle.addFriend.title", defaultValue: "Add a friend"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save", defaultValue: "Save")) {
                        store.addFriend(name: name, intention: intention)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || intention.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    FriendsSparksView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
