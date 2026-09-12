#!/bin/bash
set -euo pipefail

APP_NAME="NetSpeed"
VERSION="${1:-1.2.0}"
BUILD_NUMBER="${2:-$(date -u +%Y%m%d%H%M)}"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DERIVED_DATA="${PROJECT_ROOT}/.build/DerivedData"
PACKAGE_CACHE="${PROJECT_ROOT}/.build/SourcePackages"
DIST_DIR="${PROJECT_ROOT}/dist"
BUILT_APP="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app"
OUTPUT_APP="${DIST_DIR}/${APP_NAME}.app"

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Invalid version '${VERSION}'. Expected a value such as 1.2.0."
    exit 1
fi

if [[ ! "${BUILD_NUMBER}" =~ ^[0-9]+$ ]]; then
    echo "Invalid build number '${BUILD_NUMBER}'. It must contain only digits."
    exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode is required. Install Xcode and select it with xcode-select."
    exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Full Xcode is not selected. Install Xcode, then run:"
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

rm -rf "${DERIVED_DATA}" "${DIST_DIR}"
mkdir -p "${DERIVED_DATA}" "${PACKAGE_CACHE}" "${DIST_DIR}"

echo "Building ${APP_NAME} ${VERSION} (${BUILD_NUMBER}) for Apple silicon and Intel…"
xcodebuild \
    -project "${PROJECT_ROOT}/NetSpeed.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "${DERIVED_DATA}" \
    -clonedSourcePackagesDirPath "${PACKAGE_CACHE}" \
    MARKETING_VERSION="${VERSION}" \
    CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
    PRODUCT_BUNDLE_IDENTIFIER="com.rahul.NetSpeed" \
    MACOSX_DEPLOYMENT_TARGET="14.0" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="-" \
    DEVELOPMENT_TEAM="" \
    build

if [[ ! -d "${BUILT_APP}" ]]; then
    echo "Build succeeded but ${BUILT_APP} was not produced."
    exit 1
fi

ditto "${BUILT_APP}" "${OUTPUT_APP}"
codesign --verify --deep --strict --verbose=2 "${OUTPUT_APP}"

ARCHITECTURES="$(lipo -archs "${OUTPUT_APP}/Contents/MacOS/${APP_NAME}")"
if [[ " ${ARCHITECTURES} " != *" arm64 "* || " ${ARCHITECTURES} " != *" x86_64 "* ]]; then
    echo "Expected a universal binary, found: ${ARCHITECTURES}"
    exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "${OUTPUT_APP}" "${DIST_DIR}/${APP_NAME}.zip"

echo "Built ${OUTPUT_APP}"
echo "Update archive: ${DIST_DIR}/${APP_NAME}.zip"
