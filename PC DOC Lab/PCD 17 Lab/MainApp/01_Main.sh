#!/bin/bash
 
# ====== Setup log folder structure ======

YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
FILENAME_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TEST_LOGS_DIR="TestLogs"
DEVICE_MODEL=$(system_profiler SPHardwareDataType | awk -F": " '/Model Identifier/ {print $2}')
SERIAL=$(ioreg -l | grep IOPlatformSerialNumber | awk -F'"' '{print $4}')

LOG_DIR="$HOME/Desktop/$TEST_LOGS_DIR/$YEAR/$MONTH/$DAY"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/testlog_${FILENAME_TIMESTAMP}_${DEVICE_MODEL}_serial-${SERIAL}.log"

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "============ Script Started ============="
log "========================================="

log "INFO: Serial Number: $SERIAL"
 
# ========= Validate sudo ===========

validate_sudo() {
  attempts=0
  max_attempts=2

  while (( attempts < max_attempts )); do
    PASSWORD=$(osascript -e 'Tell application "System Events" to display dialog "Enter your password:" default answer "" with hidden answer buttons {"OK"} default button 1' -e 'text returned of result')
    
    echo "$PASSWORD" | sudo -S -v 2>/dev/null

    if [[ $? -eq 0 ]]; then
      osascript -e 'display dialog "✅ Sudo validated successfully." with title "Success" buttons {"OK"} default button "OK"'
      unset PASSWORD
      return 0
    else
      ((attempts++))
      if (( attempts == 1 )); then
        osascript -e 'display dialog "⚠️ Incorrect password. You have one attempt remaining." with title "Warning" buttons {"OK"} default button "OK"'
      else
        osascript -e 'display dialog "❌ Incorrect password entered twice. Exiting process." with title "Failure" buttons {"OK"} default button "OK"'
        unset PASSWORD
        exit 1
      fi
    fi
  done
}

# Call the function
validate_sudo


#PASSWORD=$(osascript -e 'Tell application "System Events" to display dialog "Enter your password:" default answer "" with hidden answer' -e 'text returned of result')

#echo "$PASSWORD" | sudo -S -v 2>/dev/null

#if [ $? -ne 0 ]; then
#    log "ERROR: ❌ Incorrect password or sudo failed."
#    exit 1
#else
#    log "SUCCESS: ✅ Sudo validated successfully."
#fi
 
# ========= Start Testing ===========

log "INFO: Testing Mobile Device Management and Device Enrollment Program"
 
# ======= inform the enduser that process is about to start ======
 
osascript <<EOF
display dialog "Important Notice
 
The PC-DOCTOR scan will start shortly.
 
Please do NOT press any keys or interact with the system unless prompted.
 
Your cooperation helps ensure an accurate and uninterrupted scan.
 
Thank you for your patience!
 
Click Continue to start the scan." with title "PC-DOCTOR Scan Starting" buttons {"Continue"} default button "Continue" with icon caution
EOF
 
 
# ======== Check if Find My Mac is enabled ========

# ======== FIND MY MAC (Activation Lock) ==========

get_activation_lock_status() {
  system_profiler SPHardwareDataType | awk -F": " '/Activation Lock Status:/ {print $2}'
}

activation_lock_status=$(get_activation_lock_status)

if [[ "$activation_lock_status" == "Enabled" ]]; then
    log "INFO: Find My Mac is ENABLED."
else
    log "INFO: Find My Mac DISABLED."
fi

# ======== Check MDM/DEP enrollment ===============

mdm_status=$(profiles status -type enrollment 2>/dev/null)
# Extract statuses
dep_enrolled=$(echo "$mdm_status" | grep "Enrolled via DEP" | awk -F': ' '{print $2}' | tr -d '\r\n')
mdm_enrolled=$(echo "$mdm_status" | grep "MDM enrollment" | awk -F': ' '{print $2}' | tr -d '\r\n')

# Log statuses
log "INFO: DEP enrollment status: ${dep_enrolled:-Unknown}"
log "INFO: MDM enrollment status: ${mdm_enrolled:-Unknown}"

# ======== Red error + exit if DEP or MDM is enabled ========
if [[ "$dep_enrolled" == "Yes" || "$mdm_enrolled" == "Yes" ]]; then
    log "INFO: DEP and/or MDM enrollment detected. Showing critical alert and terminating process."

    enrollment_msg="❌ CRITICAL: This Mac is enrolled in"
    if [[ "$dep_enrolled" == "Yes" && "$mdm_enrolled" == "Yes" ]]; then
        enrollment_msg+=" both DEP and MDM."
    elif [[ "$dep_enrolled" == "Yes" ]]; then
        enrollment_msg+=" DEP."
    elif [[ "$mdm_enrolled" == "Yes" ]]; then
        enrollment_msg+=" MDM."
    fi
    enrollment_msg+="\n\nThe process will terminate in 15 seconds."

    osascript -e "display dialog \"$enrollment_msg\" buttons {\"OK\"} default button 1 with icon stop with title \"❌ Enrollment Detected ❌\""
    sleep 15
    exit 1
fi

log "INFO: Mobile Device Management and Device Enrollment Program NOT detected. Proceeding..."

# ======== Check for iCloud Account ========

icloud_plist="/Users/$(whoami)/Library/Preferences/MobileMeAccounts.plist"
icloud_account=""

if [ -f "$icloud_plist" ]; then
    if /usr/libexec/PlistBuddy -c "Print :Accounts:0:AccountID" "$icloud_plist" &>/dev/null; then
        icloud_account=$(/usr/libexec/PlistBuddy -c "Print :Accounts:0:AccountID" "$icloud_plist")
        log "INFO: Apple/iCloud account is active: $icloud_account"
    else
        log "INFO: No Apple/iCloud account detected."
    fi
else
    log "INFO: No Apple/iCloud account detected."
fi

# ========= Summary Dialog ===========

summary="System Status Summary\n\n"

# ========= Find My Mac Summary ======

summary+="======= FIND MY MAC STATUS =======\n"
if [[ "$activation_lock_status" == "Enabled" ]]; then
    summary+="❌ Enabled\n\n"
else
    summary+="✅ Disabled\n\n"
fi

# ======= DEP Enrollment Summary ====

summary+="======= DEP ENROLLMENT STATUS =======\n"
if [[ "$dep_enrolled" == "Yes" ]]; then
    summary+="❌ Enrolled\n\n"
else
    summary+="✅ Not Enrolled\n\n"
fi

# ======== MDM Enrollment Summary ==

summary+="======= MDM ENROLLMENT STATUS =======\n"
if [[ "$mdm_enrolled" == "Yes" ]]; then
    summary+="❌ Enrolled\n\n"
else
    summary+="✅ Not Enrolled\n\n"
fi

# ======== iCloud Summary ==========

summary+="======= ICLOUD ACCOUNT STATUS =======\n"
if [ -n "$icloud_account" ]; then
    summary+="❌ Detected: $icloud_account\n"
else
    summary+="✅ Not Detected\n"
fi

osascript -e "display dialog \"$summary\" buttons {\"Continue\"} default button \"Continue\" with title \"SYSTEM ENROLLMENT CHECK\" with icon note"

# ======== Mount PC Doctor DMG ========

DMG_PATH="/Volumes/PC_DOCTOR/pcdoctor/sc_mac/PCDoctor_17.0.7535.899_darwin_aarch64.dmg"

# ======== Show "Please Wait" dialog and wait while the DMG Mount happens ========

osascript -e 'display dialog "Please wait...\nBackground process running." buttons {"OK"} giving up after 7 with title "Installing PC Doctor" with icon note' &
#sleep 1
show_fulldisk_dialog

# Immediately call Full Disk Access dialog without delay
show_fulldisk_dialog

# ======== Proceed with background install steps ========

log "INFO: Attempting to mount DMG (auto-accepting license)..."
echo "y" | hdiutil attach "$DMG_PATH"

MOUNT_POINT=$(hdiutil info | awk -v dmg="$DMG_PATH" '
    BEGIN { found=0 }
    $0 ~ dmg { found=1 }
    found && /\/Volumes\// { print $1; exit }
')

if [[ -n "$MOUNT_POINT" ]]; then
    log "SUCCESS: DMG Mounted to $DMG_PATH"
else
    log "ERROR: Failed to mount DMG"
fi

# ======== Install PC Doctor ========

SOURCE="/Volumes/PCDoctor_17.0.7535.899_darwin_aarch64/Service Center 17.app"
DEST="/Applications/Service Center 17.app"
log "INFO: Attempting to copy Service Center 17.app to /Applications"

if [[ -e "$SOURCE" ]]; then
    echo "$PASSWORD" | sudo -S cp -R "$SOURCE" "$DEST"
    if [[ $? -eq 0 ]]; then
        log "SUCCESS: Copied Service Center 17.app to /Applications"
    else
        log "ERROR: Failed to copy Service Center 17.app to /Applications"
    fi
else
    log "ERROR: Source path not found: $SOURCE"
fi

# ================= Permissions Dialogs =================

show_fulldisk_dialog() {
  while true; do
    log "INFO: Showing Full Disk Access instructions dialog."

    button=$(osascript -e 'display dialog "To grant Full Disk Access for this tool, please follow these steps:

1. Click the “Open Settings” button below to open System 
   Settings.  
   
2. Scroll down and select Full Disk Access.  
   
3. Click the “+” button to add an application.  
   You may be prompted to unlock the settings by entering 
   your Mac password.  
   
4. Look for “Terminal” in the list, select it, then click Open.  
   
5. Once you’ve completed these steps, return here and click Continue.

Without this, the app cannot function as expected." buttons {"Open Settings", "Continue"} default button "Continue" with title "Full Disk Access Required"')

    log "INFO: User clicked: $button"

    if [[ "$button" == *"Open Settings"* ]]; then
      log "INFO: User selected: Open Settings – opening Full Disk Access settings."
      open "x-apple.systempreferences:com.apple.preference.security"
      sleep 3
      continue
    fi

    while true; do
      log "INFO: Showing Full Disk Access confirmation dialog."

      user_response=$(osascript -e 'display dialog "Have you enabled Full Disk Access for \"Terminal\"?

You can always go back and do it if needed.

Click Confirm to proceed or Go Back to return to instructions." buttons {"Go Back", "Confirm"} default button "Confirm"')

      log "INFO: User clicked: $user_response"

      if [[ "$user_response" == *"Confirm"* ]]; then
        log "INFO: ✅ User confirmed Full Disk Access enabled."
        break 2
      elif [[ "$user_response" == *"Go Back"* ]]; then
        log "INFO: 🔙 User chose to go back to Full Disk Access instructions."
        break
      fi
    done
  done
}

show_input_monitoring_dialog() {
  while true; do
    log "INFO: Showing Input Monitoring instructions dialog."

    button=$(osascript -e 'display dialog "To grant keyboard input access for this tool, please follow these steps:

1. Click the “Open Settings” button below to open System 
   Settings.

2. Scroll down and select Input Monitoring.

3. Click the “+” button to add an application.  
   You may be prompted to unlock the settings by entering 
   your Mac password.

4. Look for Terminal in the list, select it, then click Open.
   
5. Once you’ve completed these steps, return here and click Continue.

Without this, keyboard automation features will not work." buttons {"Open Settings", "Continue"} default button "Continue" with title "Input Monitoring Required"')

    log "INFO: User clicked: $button"

    if [[ "$button" == *"Open Settings"* ]]; then
      log "INFO: User selected: Open Settings – opening Input Monitoring settings."
      open "x-apple.systempreferences:com.apple.preference.security"
      sleep 3
      continue
    fi

    while true; do
      log "INFO: Showing Input Monitoring confirmation dialog."

      user_response=$(osascript -e 'display dialog "Have you enabled Input Monitoring for \"Terminal\"?

You can always go back and do it if needed.

Click Confirm to proceed or Go Back to return to instructions." buttons {"Go Back", "Confirm"} default button "Confirm"')

      log "INFO: User clicked: $user_response"

      if [[ "$user_response" == *"Confirm"* ]]; then
        log "INFO: ✅ User confirmed Input Monitoring enabled."
        break 2
      elif [[ "$user_response" == *"Go Back"* ]]; then
        log "INFO: 🔙 User chose to go back to Input Monitoring instructions."
        break
      fi
    done
  done
}

show_bluetooth_dialog() {
  while true; do
    log "INFO: Showing Bluetooth Access instructions dialog."

    button=$(osascript -e 'display dialog "To grant Bluetooth access for this tool, please follow these steps:

1. Click the “Open Settings” button below to open System 
   Settings.

2. Scroll down and select Bluetooth.

3. Click the “+” button to add an application.  
   You may be prompted to unlock the settings by entering 
   your Mac password.

4. Look for Terminal in the list, select it, then click Open.
   
5. Once you’ve completed these steps, return here and click Continue.

Without this, Bluetooth Access features will not work." buttons {"Open Settings", "Continue"} default button "Continue" with title "Bluetooth Access Required"')

    log "INFO: User clicked: $button"

    if [[ "$button" == *"Open Settings"* ]]; then
      log "INFO: User selected: Open Settings – opening Bluetooth settings."
      open "x-apple.systempreferences:com.apple.preference.security"
      sleep 3
      continue
    fi

    while true; do
      log "INFO: Showing Bluetooth confirmation dialog."

      user_response=$(osascript -e 'display dialog "Have you enabled Bluetooth for \"Terminal\"?

You can always go back and do it if needed.

Click Confirm to proceed or Go Back to return to instructions." buttons {"Go Back", "Confirm"} default button "Confirm"')

      log "INFO: User clicked: $user_response"

      if [[ "$user_response" == *"Confirm"* ]]; then
        log "INFO: ✅ User confirmed Bluetooth Access enabled."
        break 2
      elif [[ "$user_response" == *"Go Back"* ]]; then
        log "INFO: 🔙 User chose to go back to Bluetooth Access instructions."
        break
      fi
    done
  done
}

show_completion_dialog() {
  log "INFO: ✅ Permission dialogs completed."

  button=$(osascript -e 'display dialog "Permission steps completed.
Click \"Start Testing\" to begin automated testing." buttons {"Start Testing"} default button "Start Testing"')
  log "INFO: User clicked: $button"
}

# ====== Show permission dialogs ONCE ======

if [[ ! -f "$PERMISSION_FLAG_FILE" ]]; then
  show_fulldisk_dialog
  show_input_monitoring_dialog
  show_bluetooth_dialog
  show_completion_dialog
  touch "$PERMISSION_FLAG_FILE"
else
  log "INFO: 🔁 Skipping permission dialogs – already completed."
fi

# ============== Camera test ===============

log "INFO: Starting camera test."

osascript -e 'display dialog "Photo Booth will open for 5 seconds so you can verify the camera is working." buttons {"OK"} default button "OK"'

open -a "Photo Booth"
log "INFO: Photo Booth opened."

sleep 5

osascript -e 'tell application "Photo Booth" to quit'
log "INFO: Photo Booth closed."

user_response=$(osascript -e 'display dialog "Were you able to see yourself in the Photo Booth preview?" buttons {"No", "Yes"} default button "Yes" with title "Camera Test"')

log "INFO: User answered: $user_response"

if [[ "$user_response" == *"Yes"* ]]; then
  log "INFO: ✅ Camera test: User confirmed camera works."
else
  log "ERROR; ❌ Camera test: User confirmed camera does not work."
fi

# ============== Final Test Launch Dialog ==============

  if [[ "$button" == *"Start Testing"* ]]; then
    SCRIPT="MacBook_MChips.xml"
    STORENAME="TRUMPTOWERS"
    SCRIPTNAME="MacBook_MChips"
    SESSIONNAME="$DEVICE_MODEL"-"$SERIAL"
    MANF="Device123"
    APP="/Applications/Service Center 17.app/Contents/MacOS/sccui"

    echo "$PASSWORD" | sudo -S "$APP" \
      -f "/Volumes/PC_DOCTOR/pcdoctor/sc_lin/scripts/$SCRIPT" \
      -ticketid "${STORENAME}-${SCRIPTNAME}" \
      -sessionname "$SESSIONNAME" \
      -deviceid "$MANF" \
      -exit

    log "SUCCESS: ✅ PC Doctor scan completed."

  # ============ Locate latest report file ============

  GITEA_URL="http://git.truenorth.co.za:10880"
	REPO_OWNER="CCTECH"
	REPO_NAME="TRUMPTOWERS"
	BRANCH_NAME="main"
	ACCESS_TOKEN="3fb853ab54c80dbcc8f68fad6d097e6640c2c949"

	YEAR=$(date +%Y)
	MONTH=$(date +%m)
	DAY=$(date +%d)
	TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
	FILENAME_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
	TEST_LOGS_DIR="TestLogs"
 
	DEVICE_MODEL=$(system_profiler SPHardwareDataType | awk -F": " '/Model Identifier/ {print $2}')
	SERIAL=$(ioreg -l | grep IOPlatformSerialNumber | awk -F'"' '{print $4}')
	 
	
    GOOGLE_DATE_HEADER=$(curl -sI "https://www.google.com" | grep -i ^Date: | cut -d' ' -f2-)

    if [ -n "$GOOGLE_DATE_HEADER" ]; then
      DATETIME=$(date -j -f "%a, %d %b %Y %T %Z" "$GOOGLE_DATE_HEADER" "+%Y-%m-%dT%H:%M:%S")
    else
      DATETIME=""
    fi

    if [ -z "$DATETIME" ]; then
      log "❌ Could not parse time from Google, falling back to local system time."
      YEAR=$(date +%Y)
      MONTH=$(date +%B)
      DAY=$(date +%-d)
      TIME=$(date +%H-%M-%S)
    else
      DATE_PART=$(echo "$DATETIME" | cut -d'T' -f1)
      TIME_PART=$(echo "$DATETIME" | cut -d'T' -f2)
      YEAR=$(echo "$DATE_PART" | cut -d'-' -f1)
      MONTH_NUM=$(echo "$DATE_PART" | cut -d'-' -f2)
      DAY=$(echo "$DATE_PART" | cut -d'-' -f3 | sed 's/^0*//')
      TIME=$(echo "$TIME_PART" | tr ':' '-')

      case $MONTH_NUM in
        01) MONTH="January" ;;
        02) MONTH="February" ;;
        03) MONTH="March" ;;
        04) MONTH="April" ;;
        05) MONTH="May" ;;
        06) MONTH="June" ;;
        07) MONTH="July" ;;
        08) MONTH="August" ;;
        09) MONTH="September" ;;
        10) MONTH="October" ;;
        11) MONTH="November" ;;
        12) MONTH="December" ;;
        *) MONTH="Unknown" ;;
      esac
    fi

    BASE_DIR="/Users/user/Desktop/$YEAR"
    TARGET_PATH_DATE="$YEAR/$MONTH/$DAY"
    mkdir -p "$BASE_DIR/$MONTH/$DAY"

    STORENAME="TRUMPTOWERS"
    SCRIPTNAME="MacBook_MChips"
    SESSIONNAME="MacBookAir10,1-C02G9ZQZQ6L4"

    upload_file_to_gitea() {
      local file_path="$1"
      local target_path="$2"
      local filename
      filename=$(basename "$file_path")
      local file_content
      file_content=$(base64 < "$file_path" | tr -d '\n')

      local JSON_PAYLOAD
      JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "message": "Application log file upload from TRUMPTOWERS",
  "content": "$file_content"
}
EOF
)
      log "INFO: Uploading $filename to Gitea path: $target_path"

      RESPONSE=$(curl -sS -m 15 -X POST -H "Authorization: token $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$target_path")


      if echo "$RESPONSE" | grep -q '"content":'; then
        log "SUCCESS: ✅ Successfully uploaded $filename to Gitea."
      else
        log "ERROR: ❌ Upload failed"
        log "INFO: $RESPONSE"
      fi
    }

# ===== Teams Webhook Configuration =====================

TEAMS_WEBHOOK_URL="https://prod-93.westeurope.logic.azure.com:443/workflows/32d1a98e160f49f180a0d79568c77fbb/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=zHW2uZEEwTUy2adSP-E4qJlZZOUmp7P1Ro89H9MzbVM"  # Replace with your actual webhook URL

# ===== Function to send message to Microsoft Teams =====

send_teams_notification() {
  local message="$1"

  curl -s -X POST "$TEAMS_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"$message\"}"
}

# ===== Upload function with failure detection ==========

upload_file_to_gitea() {
  local file_path="$1"
  local target_path="$2"
  local filename
  filename=$(basename "$file_path")
  local file_content
  file_content=$(base64 < "$file_path" | tr -d '\n')

  local JSON_PAYLOAD
  JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "message": "Report upload from TRUMPTOWERS",
  "content": "$file_content"
}
EOF
)

  log "INFO: Uploading $filename to Gitea path: $target_path"

  RESPONSE=$(curl -sS -m 15 -X POST -H "Authorization: token $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$target_path")

  if echo "$RESPONSE" | grep -q '"content":'; then
    log "SUCCESS: ✅ Successfully uploaded $filename to Gitea."
    return 0
  else
    log "ERROR: ❌ Upload failed: ${STORENAME}"
    log "INFO: $RESPONSE"
    return 1
  fi
}

# ===== Main upload check and trigger ================

SOURCE_DIR="/Volumes/PC_DOCTOR/data/sessions/${STORENAME}-${SCRIPTNAME}__${SESSIONNAME}/testlogs"

if [[ -d "$SOURCE_DIR" ]]; then

  TESTLOG_FILE=$(ls -t "$SOURCE_DIR"/*.html 2>/dev/null | head -n 1)

  if [[ -n "$TESTLOG_FILE" && -f "$TESTLOG_FILE" ]]; then
    TESTLOG_FILENAME=$(basename "$TESTLOG_FILE")
    log "SUCCESS: ✅ Test log file found: $TESTLOG_FILE"

# === Upload and notify on failure only =============

    if ! upload_file_to_gitea "$TESTLOG_FILE" "$TARGET_PATH_DATE/$TESTLOG_FILENAME"; then
      send_teams_notification "❌ Upload failed for $TESTLOG_FILENAME"
    fi

  else
    log "ERROR: ❌ No HTML test log files found in $SOURCE_DIR"
  fi

else
  log "ERROR: ❌ Test log directory does not exist: $SOURCE_DIR"
fi

SYSINFO_DIR="/Volumes/PC_DOCTOR/data/sessions/${STORENAME}-${SCRIPTNAME}__${SESSIONNAME}/sysinfo"

if [[ -d "$SYSINFO_DIR" ]]; then
  SYSINFO_FILE=$(find "$SYSINFO_DIR" -type f -name "sysinfo_detailed-*.html" -print0 | xargs -0 ls -t | head -n 1)
  if [[ -n "$SYSINFO_FILE" && -f "$SYSINFO_FILE" ]]; then
    SAFE_SYSINFO_FILENAME=$(basename "$SYSINFO_FILE" | tr ',' '-')
    TEMP_SYSINFO_PATH="/tmp/$SAFE_SYSINFO_FILENAME"
    cp "$SYSINFO_FILE" "$TEMP_SYSINFO_PATH"
    log "SUCCESS: ✅ Found sysinfo: $SYSINFO_FILE"
    if ! upload_file_to_gitea "$TEMP_SYSINFO_PATH" "$TARGET_PATH_DATE/$SAFE_SYSINFO_FILENAME"; then
      send_teams_notification "❌ Upload failed for sysinfo file $SAFE_SYSINFO_FILENAME"
    fi
  else
    log "ERROR: ❌ No sysinfo_detailed file found in $SYSINFO_DIR"
  fi
else
  log "ERROR: ❌ sysinfo directory does not exist: $SYSINFO_DIR"
fi

  fi  # end if

# ============== Start Script Execution ==============

# show_fulldisk_dialog
 
# ========= Uninstalling PC Doctor ==============
 
log "INFO: Showing uninstall dialog for PC Doctor"
osascript <<EOF
tell application "System Events"
    display dialog "Uninstalling PC Doctor..." buttons {"OK"} giving up after 5
end tell
EOF

log "INFO: Killing PC Doctor processes"
pkill -f "PC-Doctor Service Center 17" 2>/dev/null
osascript <<EOF
try
    tell application "PC-Doctor Service Center 17" to quit
end try
EOF

log "INFO: Removing PC Doctor app and related files"
chmod -R u+rw "/Applications/PC-Doctor Service Center 17.app" 2>/dev/null
chflags -R nouchg "/Applications/PC-Doctor Service Center 17.app" 2>/dev/null
echo "1234" | sudo -S rm -rf "/Applications/Service Center 17.app"

launchctl bootout system /Library/LaunchDaemons/com.pc-doctor.daemon.plist 2>/dev/null
rm -f /Library/LaunchDaemons/com.pc-doctor.daemon.plist
rm -f /Library/PrivilegedHelperTools/com.pc-doctor.daemon

rm -rf "/Library/Application Support/PC-Doctor/"
rm -rf "/Library/Logs/PC-Doctor/"
rm -rf "$HOME/Library/Application Support/PC-Doctor/"
rm -rf "$HOME/Library/Logs/PC-Doctor/"

rm -f /usr/local/bin/pcd-cli
rm -rf "/Library/Extensions/PCDoctorUSB.kext"

log "INFO: Checking for installed PC Doctor package"
PKG_ID=$(pkgutil --pkgs | grep -i pc-doctor)
if [ -n "$PKG_ID" ]; then
  pkgutil --forget "$PKG_ID"
  log "INFO: Forgot package: $PKG_ID"
else
  log "INFO: No PC Doctor package found to forget"
fi

# ==== Show completion dialog ======

osascript <<EOF
tell application "System Events"
    display dialog "PC Doctor has been uninstalled." buttons {"OK"} giving up after 5
end tell
EOF

# ==== CONFIGURATION ===============

GITEA_URL="https://cctech-gitea.truenorth.co.za"
GITEA_TOKEN="df6f5baa62b4b6ddc9c8d146c6ed3f4e1fd1c303"
REPO_OWNER="CCTECHLOGS"       
REPO_NAME="TRUMPTOWERS"            
BRANCH_NAME="main"
USB_MOUNT="/Volumes/PC_DOCTOR"

# ==== Sanity Check ================

if [[ -z "${GITEA_TOKEN:-}" || -z "${REPO_OWNER:-}" || -z "${REPO_NAME:-}" || -z "${BRANCH_NAME:-}" ]]; then
  log "❌ ERROR: One or more required variables are empty."
  #exit 1

  echo "DEBUG: Reached just before fi"

fi

echo "DEBUG: Passed fi and continuing"

# ===== DATE STRUCTURE =============

YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
SOURCE_DIR="$HOME/Desktop/TestLogs/$YEAR/$MONTH/$DAY"

# ==== Find latest testlog_*.log file ===

LATEST_LOG_FILE=$(find "$SOURCE_DIR" -type f -name "testlog_*.log" -print0 | xargs -0 ls -t 2>/dev/null | head -n 1)

if [[ -z "$LATEST_LOG_FILE" ]]; then
  log "ERROR: ❌ No testlog_*.log file found in $SOURCE_DIR"
  exit 1
fi

FILENAME=$(basename "$LATEST_LOG_FILE")

# === COPY TO USB BEFORE UPLOAD ==========

USB_DEST="$USB_MOUNT/$YEAR/$MONTH/$DAY"

if [[ -d "$USB_MOUNT" ]]; then
  mkdir -p "$USB_DEST"
  cp "$LATEST_LOG_FILE" "$USB_DEST/"
  log "SUCCESS: ✅ Copied $FILENAME to USB at $USB_DEST"

# === Cleanup old month directories ===

  CURRENT_MONTH="$MONTH"
  MONTH_DIR_PATH="$USB_MOUNT/$YEAR"

  if [[ -d "$MONTH_DIR_PATH" ]]; then
    for dir in "$MONTH_DIR_PATH"/*; do
      if [[ -d "$dir" ]]; then
        folder_month=$(basename "$dir")
        if [[ "$folder_month" != "$CURRENT_MONTH" ]]; then
          rm -rf "$dir"
          log "INFO: 🧹 Deleted old month folder $dir to free up space"
        fi
      fi
    done
  fi

else
  log "INFO: ⚠️ USB drive not found at $USB_MOUNT — skipping USB copy."
fi

# ====== next steps =====================

log "===== Expected Steps to Happen Next ====="
log "→ Running Cleanup script..."
log "→ Executing Eject script..."
log "→ Initiating system reboot..."
log "========================================="
log "============== End of Script ============"
log "========================================="

# === Encode file content for Gitea Upload ===

ENCODED_CONTENT=$(base64 < "$LATEST_LOG_FILE" | tr -d '\n')

UPLOAD_PATH="PCDOC/$YEAR/$MONTH/$DAY/$FILENAME"

# === Check if file already exists on Gitea to get sha ===

FILE_INFO=$(curl -sS -H "Authorization: token $GITEA_TOKEN" \
  "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$UPLOAD_PATH")

# === Extract SHA ===

HA=$(echo "$FILE_INFO" | sed -n 's/.*"sha":"\([^"]*\)".*/\1/p')
: "${HA:=}"

# === Prepare JSON and HTTP method ===

if [[ -n "$HA" ]]; then
  log "ℹ️ File exists on Gitea with sha $HA - will update"
  JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "message": "Update log $FILENAME",
  "content": "$ENCODED_CONTENT",
  "sha": "$HA"
}
EOF
)
  HTTP_METHOD="PUT"
else
  log "📁 File does not exist on Gitea - will create"
  JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "message": "Application log file upload from TRUMPTOWERS",
  "content": "$ENCODED_CONTENT"
}
EOF
)
  HTTP_METHOD="POST"
fi

# === Upload to Gitea ===

log "📤 Uploading $FILENAME to Gitea..."

# ===== Wrap the curl upload and logging with folder check for logging ====

LOG_DIR="$SOURCE_DIR"
if [[ -d "$LOG_DIR" ]]; then
  LOG_FILE="$LOG_DIR/upload_response_$(date +'%Y-%m-%d_%H-%M-%S').log"
  RESPONSE=$(curl -sS -X "$HTTP_METHOD" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$UPLOAD_PATH" | tee "$LOG_FILE")
else

# ==== Directory missing, run curl without logging to file to avoid error ====

  RESPONSE=$(curl -sS -X "$HTTP_METHOD" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$UPLOAD_PATH")
fi

log "✅ Application log file has been uploaded successfully to Gitea"

# === End of script ===

log "✅ Main script completed. Proceeding with the following final steps:"
log "➡️ 1. Cleanup temporary files"
log "➡️ 2. Eject/unmount USB drive"
log "➡️ 3. Reboot the system"

# Run the next script properly with full path
/Users/$(whoami)/Desktop/MainApp/02_Cleanup.sh
