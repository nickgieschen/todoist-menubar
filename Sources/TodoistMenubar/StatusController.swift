import AppKit
import SwiftUI

@MainActor
final class StatusController: NSObject, NSMenuDelegate {
    private struct Section {
        let title: String?
        let tasks: [TodoistTask]
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var sections: [Section] = []
    private var errorMessage: String?
    private var settingsWindow: NSWindow?
    private var timer: Timer?

    override init() {
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Todoist")
        statusItem.button?.imagePosition = .imageLeading
        statusItem.menu = menu
        menu.delegate = self
        rebuildMenu()

        NotificationCenter.default.addObserver(forName: Settings.changed, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    // MARK: - Data

    func refresh() {
        guard let token = Keychain.readToken(), !token.isEmpty else {
            sections = []
            errorMessage = TodoistError.missingToken.localizedDescription
            rebuildMenu()
            return
        }
        let client = TodoistClient(token: token)
        let includeOverdue = Settings.includeOverdue
        Task {
            do {
                if includeOverdue {
                    async let overdue = client.tasks(matching: "overdue")
                    async let today = client.tasks(matching: "today")
                    sections = [Section(title: "Overdue", tasks: try await overdue),
                                Section(title: "Today", tasks: try await today)]
                } else {
                    sections = [Section(title: nil, tasks: try await client.tasks(matching: "today"))]
                }
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            rebuildMenu()
        }
    }

    // MARK: - Menu

    private func rebuildMenu() {
        let count = sections.reduce(0) { $0 + $1.tasks.count }
        statusItem.button?.title = count == 0 ? "" : " \(count)"

        menu.removeAllItems()
        if let errorMessage {
            menu.addItem(withTitle: errorMessage, action: nil, keyEquivalent: "")
        } else if count == 0 {
            menu.addItem(withTitle: "No tasks due today", action: nil, keyEquivalent: "")
        } else {
            for section in sections where !section.tasks.isEmpty {
                if let title = section.title {
                    menu.addItem(NSMenuItem.sectionHeader(title: title))
                }
                for task in section.tasks {
                    let item = menu.addItem(withTitle: task.content, action: #selector(openTask(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = task.id
                }
            }
        }
        menu.addItem(.separator())
        add("Open Todoist…", #selector(openTodoist), "o")
        menu.addItem(.separator())
        add("Refresh", #selector(refreshClicked), "r")
        add("Settings…", #selector(showSettings), ",")
        add("Quit", #selector(NSApplication.terminate(_:)), "q").target = NSApp
    }

    @discardableResult
    private func add(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    // MARK: - Actions

    private var todoistAppInstalled: Bool {
        NSWorkspace.shared.urlForApplication(toOpen: URL(string: "todoist://")!) != nil
    }

    @objc private func openTask(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let url = todoistAppInstalled
            ? URL(string: "todoist://task?id=\(id)")!
            : URL(string: "https://app.todoist.com/app/task/\(id)")!
        NSWorkspace.shared.open(url)
    }

    @objc private func openTodoist() {
        let url = todoistAppInstalled
            ? URL(string: "todoist://")!
            : URL(string: "https://app.todoist.com")!
        NSWorkspace.shared.open(url)
    }

    @objc private func refreshClicked() {
        refresh()
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.setContentSize(hosting.view.fittingSize)
            window.title = "Todoist Menubar"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
