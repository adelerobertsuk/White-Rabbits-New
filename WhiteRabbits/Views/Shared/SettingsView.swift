//
//  SettingsView.swift
//  WhiteRabbits
//
//  "Preferences": quiet, on-device settings, opened from the bunny mark
//  in the top-right corner of Today. Matches the web app's settings
//  sheet exactly: name, haptics, dark evening, preview-first toggle,
//  Shared Sanctuary, and this phone's data.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var showImporter = false
    @State private var exportURL: URL?
    @State private var showResetConfirm = false
    @State private var importFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(localized: "settings.kicker", defaultValue: "Preferences"))
                        .font(.system(size: 10, weight: .medium))
                        .textCase(.uppercase)
                        .tracking(2.2)
                        .foregroundStyle(palette.muted)

                    Text(title)
                        .font(.system(size: 28, weight: .light))
                        .tracking(-0.98)
                        .foregroundStyle(palette.ink)
                        .padding(.top, 6)

                    Text(String(localized: "settings.lede", defaultValue: "Quiet settings. Everything stays on this device."))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(palette.muted)
                        .padding(.top, 4)

                    nameField
                        .padding(.top, 14)

                    VStack(spacing: 0) {
                        settingRow(
                            title: String(localized: "settings.haptics.title", defaultValue: "Haptics"),
                            caption: String(localized: "settings.haptics.caption", defaultValue: "A small pulse when luck arrives"),
                            isOn: Binding(get: { store.hapticsEnabled }, set: { store.setHapticsEnabled($0) })
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
                        settingRow(
                            title: String(localized: "settings.sharedSanctuary.title", defaultValue: "Shared Sanctuary"),
                            caption: String(localized: "settings.sharedSanctuary.caption", defaultValue: "Intentions and stamps, never journal pages"),
                            isOn: Binding(
                                get: { store.circleJoined },
                                set: { $0 ? store.joinCircle() : store.leaveCircle() }
                            )
                        )

                        dataRow
                    }
                    .padding(.top, 4)

                    Button {
                        showResetConfirm = true
                    } label: {
                        Text(String(localized: "settings.reset", defaultValue: "Clear this device"))
                            .font(.system(size: 12))
                            .underline()
                            .foregroundStyle(palette.muted)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "settings.close", defaultValue: "Close")) { dismiss() }
                }
            }
        }
        .onAppear { name = store.firstName }
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
            Text(String(localized: "settings.resetConfirm.body", defaultValue: "Journal pages, stamps, and settings will be gone for good."))
        }
    }

    private var title: String {
        store.firstName.isEmpty
            ? String(localized: "settings.title.unnamed", defaultValue: "Keep it yours.")
            : String(format: String(localized: "settings.title.named", defaultValue: "This is yours, %@."), store.firstName)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(String(localized: "settings.name.placeholder", defaultValue: "Your name"), text: $name)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(palette.ink)
                .onSubmit { store.setName(name) }
            Text(String(localized: "settings.name.caption", defaultValue: "How the sanctuary greets you"))
                .font(.system(size: 11))
                .foregroundStyle(palette.faint)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(minHeight: 88, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.line, lineWidth: 1)
        )
        .onChange(of: name) { _, newValue in
            store.setName(newValue)
        }
    }

    private func settingRow(title: String, caption: String, isOn: Binding<Bool>) -> some View {
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
            Rectangle().fill(palette.line).frame(height: 1)
        }
    }

    private var dataRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "settings.data.title", defaultValue: "This phone’s data"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.ink)
                Text(String(localized: "settings.data.caption", defaultValue: "Journal pages, check-ins, and stamps as a JSON file"))
                    .font(.system(size: 12))
                    .foregroundStyle(palette.muted)
            }

            HStack(spacing: 8) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Text(String(localized: "settings.data.export", defaultValue: "Export Data"))
                    }
                    .buttonStyle(PillButtonStyle(filled: false, compact: true))
                } else {
                    Button {
                        exportURL = writeSnapshotToTempFile()
                    } label: {
                        Text(String(localized: "settings.data.export", defaultValue: "Export Data"))
                    }
                    .buttonStyle(PillButtonStyle(filled: false, compact: true))
                }

                Button {
                    showImporter = true
                } label: {
                    Text(String(localized: "settings.data.import", defaultValue: "Import"))
                }
                .buttonStyle(PillButtonStyle(filled: false, compact: true))
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.line).frame(height: 1)
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

/// A little switch matching the web app's `.toggle`: a 48x30 capsule
/// track that turns ink-colored when on, with a sliding card-colored knob.
private struct SanctuaryToggle: View {
    @Binding var isOn: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            Haptics.light()
            isOn.toggle()
        } label: {
            Capsule()
                .fill(isOn ? palette.ink : palette.track)
                .frame(width: 48, height: 30)
                .overlay(
                    Circle()
                        .fill(palette.card)
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .offset(x: isOn ? 18 : 0),
                    alignment: .leading
                )
                .animation(.easeOut(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
