//
//  SettingsView.swift
//  WhiteRabbits
//
//  Quiet on-device settings, opened from the bunny mark.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var intention: String = ""
    @State private var showImporter = false
    @State private var exportURL: URL?
    @State private var showResetConfirm = false
    @State private var importFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.stackSpacing) {
                    header
                    youCard
                    AlarmCardView()
                    LuckyHourCardView()
                    phoneCard
                    aboutCard
                    supportCard
                    footer
                }
                .padding(Layout.screenInset)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.muted)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(palette.track))
                    }
                    .accessibilityLabel(String(localized: "settings.close", defaultValue: "Close"))
                }
            }
        }
        .onAppear {
            name = store.firstName
            intention = store.intention
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result,
                  let data = try? Data(contentsOf: url),
                  store.importSnapshot(from: data) else {
                importFailed = true
                return
            }
            Haptics.success()
        }
        .alert(String(localized: "settings.importFailed", defaultValue: "That file couldn't be read."), isPresented: $importFailed) {
            Button(String(localized: "settings.ok", defaultValue: "OK"), role: .cancel) {}
        }
        .confirmationDialog(
            String(localized: "settings.resetConfirm.title", defaultValue: "Clear everything on this device?"),
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.resetConfirm.action", defaultValue: "Clear this device"), role: .destructive) {
                store.resetDevice()
                dismiss()
            }
            Button(String(localized: "settings.cancel", defaultValue: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.resetConfirm.body", defaultValue: "Stamps and settings will be gone for good."))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "settings.kicker", defaultValue: "Preferences"))
                .kickerStyle()
            Text(title)
                .displayTitleStyle()
            Text(String(localized: "settings.lede", defaultValue: "Quiet settings. Everything stays on this device."))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.muted)
        }
        .padding(.top, 4)
    }

    private var title: String {
        store.firstName.isEmpty
            ? String(localized: "settings.title.unnamed", defaultValue: "Keep it yours.")
            : String(format: String(localized: "settings.title.named", defaultValue: "This is yours, %@."), store.firstName)
    }

    private var youCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            field(
                label: String(localized: "settings.name.label", defaultValue: "Your name"),
                caption: String(localized: "settings.name.caption", defaultValue: "How White Rabbits greets you")
            ) {
                TextField(String(localized: "settings.name.placeholder", defaultValue: "Your name"), text: $name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .onSubmit { store.setName(name) }
                    .onChange(of: name) { _, newValue in
                        store.setName(newValue)
                    }
            }

            Rectangle().fill(palette.line).frame(height: 1)

            field(
                label: String(localized: "settings.intention.label", defaultValue: "This month's intention"),
                caption: String(localized: "settings.intention.caption", defaultValue: "Your good intention for the month ahead. Optional, and it will find you again.")
            ) {
                TextField(
                    String(localized: "settings.intention.placeholder", defaultValue: "What are you carrying into this month?"),
                    text: $intention,
                    axis: .vertical
                )
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(palette.ink)
                .lineLimit(1...3)
                .onSubmit { store.setIntention(intention) }
                .onChange(of: intention) { _, newValue in
                    store.setIntention(newValue)
                }
            }
        }
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private var phoneCard: some View {
        VStack(spacing: 0) {
            settingRow(
                title: String(localized: "settings.haptics.title", defaultValue: "Haptics"),
                caption: String(localized: "settings.haptics.caption", defaultValue: "A small pulse when luck arrives"),
                isOn: Binding(get: { store.hapticsEnabled }, set: { store.setHapticsEnabled($0) }),
                isFirst: true
            )
            settingRow(
                title: String(localized: "settings.darkEvening.title", defaultValue: "Dark evening"),
                caption: String(localized: "settings.darkEvening.caption", defaultValue: "Softer light after dusk"),
                isOn: Binding(get: { store.forceDarkMode }, set: { store.setForceDarkMode($0) })
            )
            settingRow(
                title: String(localized: "settings.previewFirst.title", defaultValue: "Preview the first of the month"),
                caption: String(localized: "settings.previewFirst.caption", defaultValue: "Open today’s greeting as if it were the 1st"),
                isOn: Binding(get: { store.previewFirstOfMonth }, set: { store.setPreviewFirstOfMonth($0) })
            )
        }
        .padding(.horizontal, Layout.cardPadding)
        .cardBackground()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "settings.about.kicker", defaultValue: "Why White Rabbits"))
                .kickerStyle()
            Text(String(
                localized: "settings.about.body",
                defaultValue: """
                Okay, so this is actually a thing.

                On the first morning of every month, you say “White Rabbits” before you say anything else. Good luck for the month ahead. Then set a little intention, and start with a positive spin.

                That’s basically it. Cute, slightly random, and very easy to forget.

                So White Rabbits remembers for you.

                And if you’re an 11:11 person, there’s a little daily nod too.
                """
            ))
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(palette.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "settings.support.kicker", defaultValue: "Support"))
                .kickerStyle()
            Text(String(
                localized: "settings.support.body",
                defaultValue: "Need a hand, found something odd, or just want to say hello?"
            ))
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(palette.muted)
            .fixedSize(horizontal: false, vertical: true)

            Link(destination: StudioContact.supportMailtoURL) {
                Text(String(localized: "settings.support.email", defaultValue: "Email AKA Studio"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Link(String(localized: "settings.footer.privacy", defaultValue: "Privacy"), destination: StudioContact.privacyURL)
                Text("·")
                    .foregroundStyle(palette.faint)
                Link(String(localized: "settings.footer.studio", defaultValue: "AKA Studio"), destination: StudioContact.studioURL)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(palette.muted)

            HStack(spacing: 16) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Text(String(localized: "settings.data.export", defaultValue: "Export"))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(palette.muted)
                } else {
                    Button {
                        exportURL = writeSnapshotToTempFile()
                    } label: {
                        Text(String(localized: "settings.data.export", defaultValue: "Export"))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(palette.muted)
                }

                Button {
                    showImporter = true
                } label: {
                    Text(String(localized: "settings.data.import", defaultValue: "Import"))
                }
                .font(.system(size: 12))
                .foregroundStyle(palette.muted)
            }

            Button {
                showResetConfirm = true
            } label: {
                Text(String(localized: "settings.reset", defaultValue: "Clear all White Rabbits data"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.danger)
            }
        }
        .padding(.top, 4)
        .buttonStyle(.plain)
    }

    private func field<Content: View>(label: String, caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .kickerStyle()
            content()
            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(palette.muted)
        }
    }

    private func settingRow(title: String, caption: String, isOn: Binding<Bool>, isFirst: Bool = false) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.ink)
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.muted)
            }
            Spacer()
            SanctuaryToggle(isOn: isOn)
        }
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            if !isFirst {
                Rectangle().fill(palette.line).frame(height: 1)
            }
        }
    }

    private func writeSnapshotToTempFile() -> URL? {
        guard let data = store.exportSnapshot() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("white-rabbits-data.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
