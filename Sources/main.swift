import AppKit
import Carbon

final class App: NSObject, NSApplicationDelegate {
    var history: [String] = []
    var lastCount = NSPasteboard.general.changeCount
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📋"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show History (⌘⇧C)", action: #selector(showHistory), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.poll() }
        registerHotKey()
    }

    func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastCount else { return }
        lastCount = pb.changeCount
        guard let s = pb.string(forType: .string), !s.isEmpty else { return }
        history.removeAll { $0 == s }
        history.insert(s, at: 0)
        if history.count > 10 { history.removeLast() }
    }

    @objc func showHistory() {
        let menu = NSMenu()
        if history.isEmpty {
            menu.addItem(withTitle: "No history", action: nil, keyEquivalent: "")
        }
        for (i, s) in history.enumerated() {
            let one = s.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
            let title = one.count > 60 ? String(one.prefix(60)) + "…" : one
            let item = NSMenuItem(title: title, action: #selector(pick(_:)), keyEquivalent: i < 9 ? "\(i + 1)" : "0")
            item.keyEquivalentModifierMask = []
            item.tag = i
            item.target = self
            menu.addItem(item)
        }
        NSApp.activate(ignoringOtherApps: true)
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc func pick(_ item: NSMenuItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(history[item.tag], forType: .string)
        lastCount = pb.changeCount
    }

    func registerHotKey() {
        var ref: EventHotKeyRef?
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ud in
            let app = Unmanaged<App>.fromOpaque(ud!).takeUnretainedValue()
            DispatchQueue.main.async { app.showHistory() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
        RegisterEventHotKey(UInt32(kVK_ANSI_C), UInt32(cmdKey | shiftKey),
                            EventHotKeyID(signature: OSType(0x434C4950), id: 1),
                            GetApplicationEventTarget(), 0, &ref)
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
