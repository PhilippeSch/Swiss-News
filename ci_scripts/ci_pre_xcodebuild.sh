#!/bin/sh

# Generate timestamp in desired format (customize as needed)
# Example: YYMMDDHHMM (e.g., 2512251430 for Dec 25, 2025 at 14:30)
TIMESTAMP=$(date "+%Y%m%d%H%M")

# Path to Info.plist (works in Xcode Cloud environment)
PLIST="$$ {CI_WORKSPACE}/ $${INFOPLIST_FILE}"

# Set CFBundleVersion using PlistBuddy
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $$ {TIMESTAMP}" " $${PLIST}"

echo "Set build number (CFBundleVersion) to ${TIMESTAMP}"