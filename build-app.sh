#!/bin/sh
# Builds a release binary and assembles build/Todoist Menubar.app
set -e
cd "$(dirname "$0")"
swift build -c release
APP="build/Todoist Menubar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/TodoistMenubar "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"
