#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:${PATH}"

if [[ $# -lt 1 ]]; then
    echo "Usage: ./release.sh <version> [build-number]"
    echo "Example: ./release.sh 1.2.0 3"
    exit 1
fi

VERSION="$1"
BUILD_NUMBER="${2:-$(date -u +%Y%m%d%H%M)}"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${PROJECT_ROOT}/dist"
UPDATES_DIR="${DIST_DIR}/updates"
ZIP_FILE="${UPDATES_DIR}/NetSpeed.zip"
APPCAST_FILE="${UPDATES_DIR}/appcast.xml"
REPOSITORY="rahul230892/macSpeed"
SPARKLE_ACCOUNT="com.rahul.NetSpeed"
TAP_DIR="/opt/homebrew/Library/Taps/rahul230892/homebrew-tap"
CASK_FILE="${TAP_DIR}/Casks/netspeed.rb"

for command_name in gh xcodebuild; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "Missing required command: ${command_name}"
        exit 1
    fi
done

if ! gh auth status >/dev/null 2>&1; then
    echo "Authenticate first with: gh auth login"
    exit 1
fi

if [[ -n "$(git -C "${PROJECT_ROOT}" status --porcelain --untracked-files=all)" ]]; then
    echo "Commit or stash repository changes before creating a release."
    exit 1
fi

if gh release view "v${VERSION}" --repo "${REPOSITORY}" >/dev/null 2>&1; then
    echo "Release v${VERSION} already exists."
    exit 1
fi

"${PROJECT_ROOT}/build.sh" "${VERSION}" "${BUILD_NUMBER}"

mkdir -p "${UPDATES_DIR}"
mv "${DIST_DIR}/NetSpeed.zip" "${ZIP_FILE}"

SPARKLE_BIN="${SPARKLE_BIN:-}"
if [[ -z "${SPARKLE_BIN}" ]]; then
    SPARKLE_TOOL="$(find "${PROJECT_ROOT}/.build/SourcePackages" -type f -name generate_appcast -perm -111 -print -quit)"
    SPARKLE_BIN="$(dirname "${SPARKLE_TOOL}")"
fi

if [[ ! -x "${SPARKLE_BIN}/generate_appcast" ]]; then
    echo "Sparkle release tools were not found. Set SPARKLE_BIN to their bin directory."
    exit 1
fi

PUBLIC_KEY="$("${SPARKLE_BIN}/generate_keys" --account "${SPARKLE_ACCOUNT}" -p)"
EMBEDDED_KEY="$(plutil -extract SUPublicEDKey raw "${DIST_DIR}/NetSpeed.app/Contents/Info.plist")"
if [[ "${PUBLIC_KEY}" != "${EMBEDDED_KEY}" ]]; then
    echo "The app's Sparkle public key does not match the release signing key."
    exit 1
fi

"${SPARKLE_BIN}/generate_appcast" \
    --account "${SPARKLE_ACCOUNT}" \
    --download-url-prefix "https://github.com/${REPOSITORY}/releases/download/v${VERSION}/" \
    --link "https://github.com/${REPOSITORY}/releases/latest" \
    --maximum-versions 1 \
    --maximum-deltas 0 \
    "${UPDATES_DIR}"

gh release create "v${VERSION}" \
    "${ZIP_FILE}" \
    "${APPCAST_FILE}" \
    --repo "${REPOSITORY}" \
    --title "NetSpeed v${VERSION}" \
    --generate-notes \
    --target "$(git -C "${PROJECT_ROOT}" rev-parse HEAD)"

if [[ ! -d "${TAP_DIR}/.git" ]]; then
    echo "Release published, but the Homebrew tap was not found at ${TAP_DIR}."
    echo "Update the cask manually with SHA256: $(shasum -a 256 "${ZIP_FILE}" | awk '{print $1}')"
    exit 0
fi

SHA256="$(shasum -a 256 "${ZIP_FILE}" | awk '{print $1}')"
mkdir -p "$(dirname "${CASK_FILE}")"

cat >"${CASK_FILE}" <<EOF
cask "netspeed" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/${REPOSITORY}/releases/download/v#{version}/NetSpeed.zip"
  name "NetSpeed"
  desc "Live network speed monitor for the macOS menu bar"
  homepage "https://github.com/${REPOSITORY}"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "NetSpeed.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/NetSpeed.app"]
  end

  uninstall quit: "com.rahul.NetSpeed"

  zap trash: [
    "~/Library/Caches/com.rahul.NetSpeed",
    "~/Library/Preferences/com.rahul.NetSpeed.plist",
    "~/Library/Saved Application State/com.rahul.NetSpeed.savedState",
  ]
end
EOF

git -C "${TAP_DIR}" add "Casks/netspeed.rb"
if ! git -C "${TAP_DIR}" diff --cached --quiet; then
    git -C "${TAP_DIR}" commit -m "Update netspeed to v${VERSION}"
    git -C "${TAP_DIR}" push
fi

echo "Released NetSpeed v${VERSION}."
echo "Install: brew install --cask rahul230892/tap/netspeed"
echo "Uninstall: brew uninstall --cask netspeed"
