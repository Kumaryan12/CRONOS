#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
source_app="${project_root}/dist/Chronos.app"
installed_app="/Applications/Chronos.app"

"${project_root}/scripts/build-app.sh"

if [[ -d "${installed_app}" ]]; then
    osascript -e 'tell application id "app.chronos.macos" to quit' >/dev/null 2>&1 || true
    for _ in {1..20}; do
        if ! pgrep -f "${installed_app}/Contents/MacOS/Chronos" >/dev/null; then
            break
        fi
        sleep 0.25
    done
    backup_name="Chronos-backup-$(date +%Y%m%d-%H%M%S).app"
    mv "${installed_app}" "${HOME}/.Trash/${backup_name}"
    echo "Moved the previous app to ~/.Trash/${backup_name}"
fi

ditto "${source_app}" "${installed_app}"
codesign --verify --deep --strict "${installed_app}"
open "${installed_app}"

echo "Installed and launched ${installed_app}"
echo "Activity data remains in ~/Library/Application Support/Chronos"
