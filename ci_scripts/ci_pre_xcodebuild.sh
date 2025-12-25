#!/bin/sh

echo "=== Updating build number to timestamp ==="

# Use Unix timestamp for safety (pure integer, always increasing, App Store-compliant)
# Current date is December 25, 2025 → this will generate something like 1735157520 (exact seconds since 1970)
TIMESTAMP=$(date "+%Y%m%d%H%M")

# Change to the workspace/root directory (works in both Xcode Cloud and locally)
cd "${CI_WORKSPACE:-$PROJECT_DIR}"

# Update Current Project Version using agvtool
xcrun agvtool new-version -all "$TIMESTAMP"

echo "Successfully set Current Project Version to $TIMESTAMP"

# Verify
CURRENT=$(xcrun agvtool what-version | grep "Current version" | awk '{print $NF}')
echo "Verified build number (Current Project Version): $CURRENT"

echo "=== Done ==="