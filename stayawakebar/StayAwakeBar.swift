import AppKit
import Foundation

private let appName = "StayAwakeBar"
private let caffeinatePath = "/usr/bin/caffeinate"
private let caffeinatePattern = "caffeinate -di$"

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Status: Off", action: nil, keyEquivalent: "")
    private lazy var toggleMenuItem = NSMenuItem(
        title: "Turn Stay Awake On",
        action: #selector(toggleStayAwake),
        keyEquivalent: ""
    )
    private lazy var quitMenuItem = NSMenuItem(
        title: "Quit",
        action: #selector(quitApp),
        keyEquivalent: "q"
    )
    private var refreshTimer: Timer?
    private let devNullHandle = FileHandle(forWritingAtPath: "/dev/null")

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        if !isStayAwakeRunning() {
            _ = startStayAwake()
        }
        refreshStatus()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "Toggle Keep Awake"
        statusItem.button?.image = statusImage(isOn: false)

        statusMenuItem.isEnabled = false
        toggleMenuItem.target = self
        quitMenuItem.target = self

        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(toggleMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)

        statusItem.menu = menu
    }

    private func statusImage(isOn: Bool) -> NSImage? {
        let symbolName = isOn ? "cup.and.saucer.fill" : "cup.and.saucer"
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: appName)?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }

    @objc
    private func toggleStayAwake() {
        if isStayAwakeRunning() {
            _ = stopStayAwake()
        } else {
            _ = startStayAwake()
        }
        refreshStatus()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func refreshStatus() {
        let isOn = isStayAwakeRunning()
        statusMenuItem.title = isOn ? "Status: On" : "Status: Off"
        toggleMenuItem.title = isOn ? "Turn Stay Awake Off" : "Turn Stay Awake On"
        statusItem.button?.image = statusImage(isOn: isOn)
        statusItem.button?.toolTip = isOn ? "Stay Awake is on" : "Stay Awake is off"
    }

    private func isStayAwakeRunning() -> Bool {
        let result = runCommand("/usr/bin/pgrep", arguments: ["-f", caffeinatePattern])
        return result.exitCode == 0 && !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startStayAwake() -> Bool {
        guard !isStayAwakeRunning() else {
            return true
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: caffeinatePath)
        process.arguments = ["-di"]
        process.standardOutput = devNullHandle
        process.standardError = devNullHandle

        do {
            try process.run()
            return true
        } catch {
            showError(message: "Unable to start caffeinate.", details: error.localizedDescription)
            return false
        }
    }

    private func stopStayAwake() -> Bool {
        let result = runCommand("/usr/bin/pkill", arguments: ["-f", caffeinatePattern])
        if result.exitCode == 0 || result.exitCode == 1 {
            return true
        }

        let details = result.errorOutput.isEmpty ? result.output : result.errorOutput
        showError(message: "Unable to stop caffeinate.", details: details)
        return false
    }

    private func showError(message: String, details: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = details.isEmpty ? "No additional details were provided." : details
        alert.runModal()
    }

    private func runCommand(_ path: String, arguments: [String]) -> (exitCode: Int32, output: String, errorOutput: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (1, "", error.localizedDescription)
        }

        let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errorOutput = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (process.terminationStatus, output, errorOutput)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
