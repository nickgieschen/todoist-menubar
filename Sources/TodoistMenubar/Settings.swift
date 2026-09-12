import SwiftUI

enum Settings {
    static let includeOverdueKey = "includeOverdue"
    static var includeOverdue: Bool { UserDefaults.standard.bool(forKey: includeOverdueKey) }
    static let changed = Notification.Name("SettingsChanged")
}

struct SettingsView: View {
    @State private var token = Keychain.readToken() ?? ""
    @AppStorage(Settings.includeOverdueKey) private var includeOverdue = false

    var body: some View {
        Form {
            Section("Todoist API token") {
                SecureField("Paste token", text: $token)
                Text("Found in Todoist → Settings → Integrations → Developer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Save") {
                        Keychain.writeToken(token)
                        NotificationCenter.default.post(name: Settings.changed, object: nil)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            Section("Badge") {
                Toggle("Count overdue tasks too, not just today", isOn: $includeOverdue)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .onChange(of: includeOverdue) {
            NotificationCenter.default.post(name: Settings.changed, object: nil)
        }
    }
}
