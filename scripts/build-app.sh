#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
output_root="${project_root}/dist"
app_bundle="${output_root}/Chronos.app"

cd "${project_root}"
swift build -c release --product ChronosApp
binary_dir="$(swift build -c release --show-bin-path)"

rm -rf "${app_bundle}"
mkdir -p "${app_bundle}/Contents/MacOS" "${app_bundle}/Contents/Resources"
cp "${binary_dir}/ChronosApp" "${app_bundle}/Contents/MacOS/Chronos"
cp "${project_root}/Resources/Info.plist" "${app_bundle}/Contents/Info.plist"
codesign --force --deep --sign - "${app_bundle}"

echo "Built ${app_bundle}"
