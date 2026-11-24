import AppKit
import Observation

/// Owns the menu bar item and its menu; NSStatusItem lets VoiceOver read the full state from the button's label.
final class StatusItemController: NSObject, NSMenuDelegate {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private lazy var settingsWindow = SettingsWindowController(model: model)

    init(model: AppModel) {
        self.model = model
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        renderButton()
    }

    private func renderButton() {
        withObservationTracking {
            updateButton()
        } onChange: { [weak self] in
            Task { @MainActor in self?.renderButton() }
        }
    }

    private func updateButton() {
        guard let button = statusItem.button else { return }
        button.image = CupGlyph.image(level: CupGlyph.level(for: model.sleepGuard.progress))
        button.title = timeText.map { " \($0)" } ?? ""
        button.setAccessibilityLabel("TeaShot, \(model.status.spoken)")
    }

    private var timeText: String? {
        guard model.settings.showRemainingTime, model.isTimed, let remaining = model.sleepGuard.remaining else { return nil }
        return RemainingFormat.compact(remaining)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let sleepGuard = model.sleepGuard
        let status = model.status

        menu.addItem(.sectionHeader(title: "TeaShot"))
        let statusLine = NSMenuItem(title: status.title, action: nil, keyEquivalent: "")
        if #available(macOS 14.4, *) { statusLine.subtitle = status.subtitle }
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        if let failure = sleepGuard.failure {
            let failureLine = NSMenuItem(title: failure.localizedDescription, action: nil, keyEquivalent: "")
            failureLine.isEnabled = false
            menu.addItem(failureLine)
        }

        menu.addItem(.separator())

        if model.isTimed {
            menu.addItem(actionItem("Prolonger de 30 min", symbol: "plus", key: "+") { [model] in model.extend() })
        }
        if sleepGuard.isActive {
            menu.addItem(actionItem("Arrêter", symbol: "stop", key: "e") { [model] in model.toggle() })
        } else {
            menu.addItem(actionItem("Garder éveillé", symbol: "cup.and.saucer", key: "e") { [model] in model.toggle() })
        }
        menu.addItem(durationMenu())

        menu.addItem(.separator())

        menu.addItem(actionItem("Réglages…", symbol: "gearshape", key: ",") { [weak self] in self?.settingsWindow.present() })
        menu.addItem(actionItem("Quitter TeaShot", symbol: "power", key: "q") { NSApp.terminate(nil) })
    }

    private func durationMenu() -> NSMenuItem {
        let title: String
        if model.isTimed {
            title = "Changer la durée"
        } else {
            title = model.sleepGuard.isActive ? "Limiter la durée" : "Garder éveillé pendant"
        }
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        parent.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)

        let submenu = NSMenu()
        for preset in SleepGuard.presets {
            let item = actionItem(RemainingFormat.preset(preset)) { [model] in model.start(preset) }
            item.state = model.isTimed && model.chosenPreset == preset ? .on : .off
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        let unlimited = actionItem("Sans limite") { [model] in model.start(nil) }
        unlimited.state = model.sleepGuard.isActive && !model.isTimed ? .on : .off
        submenu.addItem(unlimited)

        parent.submenu = submenu
        return parent
    }
}

private final class MenuAction: NSObject {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func fire() {
        handler()
    }
}

private func actionItem(_ title: String, symbol: String? = nil, key: String = "", handler: @escaping () -> Void) -> NSMenuItem {
    let action = MenuAction(handler)
    let item = NSMenuItem(title: title, action: #selector(MenuAction.fire), keyEquivalent: key)
    item.target = action
    // A menu item holds its target weakly; representedObject keeps the action alive.
    item.representedObject = action
    item.image = symbol.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }
    return item
}
