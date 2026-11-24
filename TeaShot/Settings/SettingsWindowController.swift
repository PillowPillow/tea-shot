import SwiftUI

/// The Réglages window: native toolbar tabs hosting the SwiftUI forms.
final class SettingsWindowController: NSWindowController {
    private let launchAtLogin: LaunchAtLogin

    init(model: AppModel) {
        launchAtLogin = model.launchAtLogin
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        tabs.addTabViewItem(
            Self.tab(
                GeneralSettings(settings: model.settings, launchAtLogin: model.launchAtLogin),
                label: "Général",
                symbol: "gearshape"
            ))
        tabs.addTabViewItem(Self.tab(AboutView(), label: "À propos", symbol: "info.circle"))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
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

    private static func tab(_ view: some View, label: String, symbol: String) -> NSTabViewItem {
        let host = NSHostingController(rootView: view.frame(width: 520))
        host.sizingOptions = .preferredContentSize
        host.title = label
        let item = NSTabViewItem(viewController: host)
        item.label = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }
}

private struct GeneralSettings: View {
    @Bindable var settings: AppSettings
    let launchAtLogin: LaunchAtLogin

    private static let reminderLeads: [Duration] = [60, 5 * 60, 10 * 60].map(Duration.seconds)

    var body: some View {
        Form {
            Section("Démarrage") {
                Toggle(
                    "Lancer à l'ouverture de session",
                    isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                Picker(selection: $settings.defaultDuration) {
                    Text("Sans limite").tag(Duration?.none)
                    ForEach(SleepGuard.presets, id: \.self) { preset in
                        Text(RemainingFormat.preset(preset)).tag(Duration?.some(preset))
                    }
                } label: {
                    Text("Durée de ⌘E")
                    Text("Ce que lance le raccourci et l'action principale du menu")
                }
            }

            Section("Barre des menus") {
                Toggle("Afficher le temps restant à côté de l'icône", isOn: $settings.showRemainingTime)
            }

            Section("Quand TeaShot est actif") {
                Toggle(isOn: $settings.keepDisplayAwake) {
                    Text("Garder l'écran allumé")
                    Text("caffeinate -d")
                }
                Toggle(isOn: $settings.keepDiskAwake) {
                    Text("Garder le disque actif")
                    Text("caffeinate -m")
                }
                Toggle(isOn: $settings.preventSystemSleep) {
                    Text("Bloquer la veille système sur secteur")
                    Text("caffeinate -s · ignoré par macOS sur batterie")
                }
            }

            Section("Fin du minuteur") {
                Picker("Prévenir avant la fin", selection: $settings.reminderLead) {
                    Text("Jamais").tag(Duration.zero)
                    ForEach(Self.reminderLeads, id: \.self) { lead in
                        Text("\(RemainingFormat.spoken(lead)) avant")
                            .accessibilityLabel("\(RemainingFormat.accessible(lead)) avant")
                            .tag(lead)
                    }
                }
                Toggle("Proposer « Prolonger de 30 min » dans la notification", isOn: $settings.offerExtendInReminder)
                    .disabled(settings.reminderLead == .zero)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var copyright: String? {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text("TeaShot")
                .font(.title2.weight(.semibold))
            Text("Version \(version)")
                .foregroundStyle(.secondary)
            Text("Garde le Mac éveillé pendant que vos agents travaillent.")
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
