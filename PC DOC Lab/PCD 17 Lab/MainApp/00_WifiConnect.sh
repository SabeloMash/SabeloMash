#!/bin/bash

response=$(osascript <<EOF
display dialog "This is the first step of the testing process.

Please connect this MacBook to the PCD Wi-Fi network before continuing.

Click 'Open Wi-Fi Settings' to connect to the PCD network, then click 'Continue' when ready." buttons {"Open Wi-Fi Settings", "Continue"} default button "Continue" with title "Connect to PCD Wi-Fi" with icon note
EOF
)

if [[ "$response" == *"Open Wi-Fi Settings"* ]]; then
    log "🔔 Opening Wi-Fi settings..."
    open "x-apple.systempreferences:com.apple.preference.network?WiFi"

    # Re-prompt user after they finish in System Settings
    osascript -e 'display dialog "Once connected to the PCD Wi-Fi network, click Continue to proceed with the testing process." buttons {"Continue"} default button "Continue" with title "✅ Connected to PCD Wi-Fi?" with icon note'

    # Now force quit System Settings to close the Wi-Fi window
    osascript -e 'tell application "System Settings" to quit'
fi

log "✅ Step 1 complete: Proceeding to the next step of the test..."

# === Copy 01_Main.sh to Desktop & run it from there ===

#cp "/Volumes/PC_DOCTOR/MacCheckProV1.app/Contents/Resources/MainApp/01_Main.sh" ~/Desktop



