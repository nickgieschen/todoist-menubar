import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Accessory apps have no main menu by default, so Cmd+X/C/V/A would not reach text fields.
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
let mainMenu = NSMenu()
let editItem = mainMenu.addItem(withTitle: "Edit", action: nil, keyEquivalent: "")
mainMenu.setSubmenu(editMenu, for: editItem)
app.mainMenu = mainMenu

let controller = MainActor.assumeIsolated { StatusController() }
app.run()
