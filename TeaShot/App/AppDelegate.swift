import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: StatusItemController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // NSApplication holds its delegate weakly; optimized builds may otherwise release it after the assignment.
        withExtendedLifetime(delegate) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(model: model)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // macOS keeps pending notifications after the app quits; a reminder for a dead session would mislead.
        model.stop()
    }
}
