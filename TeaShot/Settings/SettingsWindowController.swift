import SwiftUI

/// The Settings window: native toolbar tabs hosting the SwiftUI forms.
final class SettingsWindowController: NSWindowController {
    private let settings: AppSettings
    private let launchAtLogin: LaunchAtLogin
    private let tabs = NSTabViewController()

    init(model: AppModel) {
        settings = model.settings
        launchAtLogin = model.launchAtLogin
        tabs.tabStyle = .toolbar
        tabs.addTabViewItem(
            Self.tab(GeneralSettings(settings: model.settings, launchAtLogin: model.launchAtLogin), symbol: "gearshape"))
        tabs.addTabViewItem(Self.tab(AboutView(settings: model.settings), symbol: "info.circle"))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        localizeTabs()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func present() {
        launchAtLogin.refresh()
        NSApp.activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func localizeTabs() {
        withObservationTracking {
            let localization = Localization(settings.language)
            let labels = [localization("General"), localization("About")]
            for (item, label) in zip(tabs.tabViewItems, labels) {
                item.label = label
                item.viewController?.title = label
            }
            window?.title = labels[max(0, tabs.selectedTabViewItemIndex)]
        } onChange: { [weak self] in
            Task { @MainActor in self?.localizeTabs() }
        }
    }

    private static func tab(_ view: some View, symbol: String) -> NSTabViewItem {
        let host = NSHostingController(rootView: view.frame(width: 520))
        host.sizingOptions = .preferredContentSize
        let item = NSTabViewItem(viewController: host)
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }
}

private struct GeneralSettings: View {
    @Bindable var settings: AppSettings
    let launchAtLogin: LaunchAtLogin

    private static let reminderLeads: [Duration] = [60, 5 * 60, 10 * 60].map(Duration.seconds)

    var body: some View {
        let localization = Localization(settings.language)
        Form {
            Section(localization("Startup")) {
                Toggle(
                    localization("Launch at login"),
                    isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                Picker(selection: $settings.defaultDuration) {
                    Text(localization("No Limit")).tag(Duration?.none)
                    ForEach(SleepGuard.presets, id: \.self) { preset in
                        Text(RemainingFormat.preset(preset, in: localization)).tag(Duration?.some(preset))
                    }
                } label: {
                    Text(localization("⌘E duration"))
                    Text(localization("What the shortcut and the main menu action start"))
                }
            }

            Section(localization("Menu bar")) {
                Toggle(localization("Show the remaining time next to the icon"), isOn: $settings.showRemainingTime)
            }

            Section(localization("While TeaShot is active")) {
                Toggle(isOn: $settings.keepDisplayAwake) {
                    Text(localization("Keep the display on"))
                    Text(verbatim: "caffeinate -d")
                }
                Toggle(isOn: $settings.keepDiskAwake) {
                    Text(localization("Keep the disk awake"))
                    Text(verbatim: "caffeinate -m")
                }
                Toggle(isOn: $settings.preventSystemSleep) {
                    Text(localization("Block system sleep on AC power"))
                    Text(localization("caffeinate -s · ignored by macOS on battery"))
                }
            }

            Section(localization("Timer end")) {
                Picker(localization("Notify before the end"), selection: $settings.reminderLead) {
                    Text(localization("Never")).tag(Duration.zero)
                    ForEach(Self.reminderLeads, id: \.self) { lead in
                        Text(localization("\(RemainingFormat.spoken(lead, in: localization)) before"))
                            .accessibilityLabel(localization("\(RemainingFormat.accessible(lead, in: localization)) before"))
                            .tag(lead)
                    }
                }
                Toggle(
                    localization("Offer “\(localization("Extend by 30 min"))” in the notification"),
                    isOn: $settings.offerExtendInReminder
                )
                .disabled(settings.reminderLead == .zero)
            }

            Section {
                Picker(localization("Language"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.nativeName ?? localization("System language")).tag(language)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.locale, localization.locale)
    }
}

private struct AboutView: View {
    let settings: AppSettings

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var copyright: String? {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
    }

    var body: some View {
        let localization = Localization(settings.language)
        VStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text(verbatim: "TeaShot")
                .font(.title2.weight(.semibold))
            Text(localization("Version \(version)"))
                .foregroundStyle(.secondary)
            Text(localization("Keeps your Mac awake while your agents work."))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let copyright {
                Text(copyright)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
