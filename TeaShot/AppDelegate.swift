import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(model: AppModel())
    }
}
