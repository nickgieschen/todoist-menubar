# Todoist Menubar

A macOS menu bar app that shows how many Todoist tasks are due today and lists them in a dropdown.

## Build and run

```sh
./build-app.sh
open "build/Todoist Menubar.app"
```

Requires macOS 14+ and Xcode command line tools.

## Setup

1. Click the checkmark icon in the menu bar → **Settings…**
2. Paste your Todoist API token (Todoist → Settings → Integrations → Developer) and click **Save**.
3. Optionally enable **Count overdue tasks too** to include overdue tasks in the badge and list.

The token is stored in the login Keychain. Because the app is ad-hoc signed, macOS may ask for Keychain
access again after each rebuild.

## Behaviour

- The badge shows the number of matching tasks (hidden when zero).
- Clicking a task opens it in the Todoist app if installed, otherwise in the browser.
- Tasks refresh every 5 minutes, whenever the menu is opened, and via **Refresh**.
