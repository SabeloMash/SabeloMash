#!/bin/bash
# Copyright PC-Doctor, Inc. All rights reserved.
# WARNING : Do not modify the contents of this file without specific instruction from PC-Doctor
######INSERT STORE NAME HERE ONLY#################
STORENAME="STORENAME"
WIFISSID="CCT-PCD"
WIFIPASSWD="AGxU48XBB9"
SHARELOCATION="//10.10.15.150/pcdreports"
SHAREUSER="pcdreports"
SHAREPASSWD="qp9BCmML4w"
SCRIPTVERSION="3.0"

SCRIPT=' '
AUTOSCRIPT="automate.xml"
HDDLONGSCRIPT="storageLong.xml"
HDDSHORTSCRIPT="storageShort.xml"
BURNINSCRIPT="burnin.xml"
MEMORYSCRIPT="memoryStressTest.xml"
SYSTEMSCRIPT="system.xml"
FULLSCRIPT="fullscript.xml"

# Configuration for Gitea
GITEA_URL="http://git.truenorth.co.za:10880"
REPO_OWNER="CCTECH"
REPO_NAME="REPO_NAME"
BRANCH_NAME="main"
ACCESS_TOKEN="3fb853ab54c80dbcc8f68fad6d097e6640c2c949"

# Configuration for the GITEA Logserver
GITEA_LOGSERVER_URL="https://cctech-gitea.truenorth.co.za"
GITEA_LOGSERVER_REPO_OWNER="CCTECHLOGS"
GITEA_LOGSERVER_REPO_NAME="REPO_NAME"
GITEA_LOGSERVER_BRANCH_NAME="main"
GITEA_LOGSERVER_TOKEN="df6f5baa62b4b6ddc9c8d146c6ed3f4e1fd1c303"

LOGDIR="/run/live/medium/data/logs"
LOGFILE="$LOGDIR/script.log"
TIMESTAMP2=$(date '+%Y%m%d_%H%M%S')

echo "__| |____________________________________________________________| |__"
echo "__   ____________________________________________________________   __"
echo "  | |                                                            | |  "
echo "  | |============================================================| |  "
echo "  | |===     =====     ===        ==        ====     ===  ====  =| |  "
echo "  | |==  ===  ===  ===  =====  =====  =========  ===  ==  ====  =| |  "
echo "  | |=  ========  ===========  =====  ========  ========  ====  =| |  "
echo "  | |=  ========  ===========  =====  ========  ========  ====  =| |  "
echo "  | |=  ========  ===========  =====      ====  ========        =| |  "
echo "  | |=  ========  ===========  =====  ========  ========  ====  =| |  "
echo "  | |=  ========  ===========  =====  ========  ========  ====  =| |  "
echo "  | |==  ===  ===  ===  =====  =====  =========  ===  ==  ====  =| |  "
echo "  | |===     =====     ======  =====        ====     ===  ====  =| |  "
echo "  | |============================================================| |  "
echo "__| |____________________________________________________________| |__"
echo "__   ____________________________________________________________   __"
echo "  | |                                                            | |  "
echo "SCRIPT VERSION: $SCRIPTVERSION"
echo "***********************************************************************"
echo "******************** WELCOME $STORENAME TO PC DOC *********************"
echo "***********************************************************************"

# Loop until a valid selection is made
while true; do
    echo "Please select the test you would like to run"
    echo ""
    echo "Please note that the test time may vary due to the hardware configuration"
    echo ""
    echo "1. Normal PC Doc test         (Approx 5   mins)"
    echo "2. Long Hard Drive test       (Approx 15  mins)"
    echo "3. Short Hard Drive test      (Approx 10  mins)"
    echo "4. Memory Stress test         (Approx 15  mins)"
    echo "5. Burn in test               (Approx 30  mins)"
    echo "6. System test                (Approx 5   mins)"
    echo "7. Full test                  (Approx 30+ mins)"
    echo ""
    
    # Read input with a 20-second timeout
    read -t 20 -p "Please enter your selection (The default is option 1 after 20 seconds): " read_response

    # If timeout occurs (no input), default to 1
    if [[ -z "$read_response" ]]; then
        echo "No selection made. Defaulting to Normal PC Doc test (1)."
        read_response=1
    fi

    case "$read_response" in
        1) SCRIPT=$AUTOSCRIPT ;;
        2) SCRIPT=$HDDLONGSCRIPT ;;
        3) SCRIPT=$HDDSHORTSCRIPT ;;
        4) SCRIPT=$MEMORYSCRIPT ;;
        5) SCRIPT=$BURNINSCRIPT ;;
        6) SCRIPT=$SYSTEMSCRIPT ;;
        7) SCRIPT=$FULLSCRIPT ;;
        *) 
            echo "Invalid Input. Please try again."
            continue
            ;;
    esac
    break
done

# Proceed with running the selected script
echo "Running selected test..."

# Create the log directory if it doesn't exist
if [ ! -d "$LOGDIR" ]; then
    mkdir -p "$LOGDIR"
fi

echo "Script started at $(date)" > "$LOGFILE"

log_and_run() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOGFILE"
    eval "$1"
    if [ $? -eq 0 ]; then
        echo "[$timestamp] Success: $1" | tee -a "$LOGFILE"
    else
        echo "[$timestamp] Failed: $1" | tee -a "$LOGFILE"
    fi
}

echo "Please wait for the application to load" | tee -a "$LOGFILE"

# Set the timezone to Africa/Johannesburg
log_and_run "timedatectl set-timezone Africa/Johannesburg"

# Ensure LAN or Wi-Fi connection is active and functional before proceeding.
test_connection() {
    ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1
    return $?
}

connect_wifi() {
    local attempt

    echo "Attempting to connect to Wi-Fi SSID: $WIFISSID" | tee -a "$LOGFILE"

    if ! command -v nmcli >/dev/null 2>&1; then
        echo "nmcli is not available on this USB image." | tee -a "$LOGFILE"
        return 1
    fi

    echo "=== Wi-Fi Diagnostic Information ===" | tee -a "$LOGFILE"
    echo "Wi-Fi radio status:" | tee -a "$LOGFILE"
    nmcli radio all | tee -a "$LOGFILE" || true
    echo "Wireless device status:" | tee -a "$LOGFILE"
    nmcli -f DEVICE,STATE,CONNECTION dev status | tee -a "$LOGFILE" || true
    echo "Available Wi-Fi networks:" | tee -a "$LOGFILE"
    nmcli device wifi list | tee -a "$LOGFILE" || true

    if command -v rfkill >/dev/null 2>&1; then
        echo "rfkill status:" | tee -a "$LOGFILE"
        rfkill list | tee -a "$LOGFILE" || true
    fi

    nmcli networking on >/dev/null 2>&1 || true
    nmcli radio wifi on >/dev/null 2>&1 || true

    # Auto-detect wireless interface name (could be wlan0, wlp2s0, etc.)
    WIRELESS_IFACE=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | grep '^w.*:wifi$' | head -1 | cut -d: -f1)
    if [ -z "$WIRELESS_IFACE" ]; then
        WIRELESS_IFACE="wlan0"
        echo "Warning: Could not auto-detect wireless interface, defaulting to $WIRELESS_IFACE" | tee -a "$LOGFILE"
    fi
    echo "Detected wireless interface: $WIRELESS_IFACE" | tee -a "$LOGFILE"

    for attempt in 1 2 3 4; do
        echo "Wi-Fi connect attempt $attempt/4..." | tee -a "$LOGFILE"

        # Delete any existing profile for this SSID to force a fresh connection
        nmcli connection delete "$WIFISSID" >/dev/null 2>&1 || true

        # Create a new connection profile with the SSID and password
        echo "Creating connection profile for $WIFISSID..." | tee -a "$LOGFILE"
        nmcli device wifi connect "$WIFISSID" password "$WIFIPASSWD" ifname "$WIRELESS_IFACE" 2>&1 | tee -a "$LOGFILE"
        local connect_result=$?

        if [ $connect_result -ne 0 ]; then
            echo "nmcli connect command failed with exit code: $connect_result" | tee -a "$LOGFILE"
        fi

        # Wait for the device to finish connecting - poll the state
        echo "Waiting for connection to establish (up to 45 seconds)..." | tee -a "$LOGFILE"
        local wait_count=0
        local max_wait=45
        while [ $wait_count -lt $max_wait ]; do
            sleep 3
            wait_count=$((wait_count + 3))

            # Check the device state
            local dev_state
            dev_state=$(nmcli -t -f DEVICE,STATE dev status 2>/dev/null | grep "^${WIRELESS_IFACE}:" | cut -d: -f2)
            echo "  [${wait_count}s] Device state: $dev_state" | tee -a "$LOGFILE"

            if [ "$dev_state" = "connected" ]; then
                echo "Device is connected after ${wait_count}s!" | tee -a "$LOGFILE"
                break
            elif [ "$dev_state" = "failed" ] || [ "$dev_state" = "unavailable" ]; then
                echo "Device state is '$dev_state' - connection failed." | tee -a "$LOGFILE"
                break
            fi
        done

        # Check if we have an IP address
        local ip_addr
        ip_addr=$(ip -4 addr show "$WIRELESS_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
        if [ -n "$ip_addr" ]; then
            echo "Got IP address: $ip_addr" | tee -a "$LOGFILE"
        else
            echo "No IP address assigned yet." | tee -a "$LOGFILE"
            # Try to explicitly trigger DHCP
            echo "Attempting to trigger DHCP..." | tee -a "$LOGFILE"
            dhclient -v "$WIRELESS_IFACE" 2>&1 | tee -a "$LOGFILE" || true
            sleep 5
            ip_addr=$(ip -4 addr show "$WIRELESS_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
            if [ -n "$ip_addr" ]; then
                echo "Got IP address after dhclient: $ip_addr" | tee -a "$LOGFILE"
            else
                echo "Still no IP address after dhclient." | tee -a "$LOGFILE"
            fi
        fi

        # Test actual connectivity
        if test_connection; then
            echo "Wi-Fi connection is functional after ${wait_count}s." | tee -a "$LOGFILE"
            return 0
        fi

        echo "Wi-Fi attempt $attempt failed connectivity test. Retrying..." | tee -a "$LOGFILE"
        echo "Connection detail after failure:" | tee -a "$LOGFILE"
        nmcli -t -f DEVICE,STATE,CONNECTION dev status | tee -a "$LOGFILE" || true
        nmcli -t -f ACTIVE,SSID,DEVICE dev wifi | tee -a "$LOGFILE" || true
    done

    echo "=== Wi-Fi Final Diagnostic State ===" | tee -a "$LOGFILE"
    nmcli -f DEVICE,STATE,CONNECTION dev status | tee -a "$LOGFILE" || true
    nmcli -f ACTIVE,SSID,DEVICE dev wifi | tee -a "$LOGFILE" || true
    ip -4 addr show "$WIRELESS_IFACE" 2>/dev/null | tee -a "$LOGFILE" || true
    nmcli -t -f IP4.ADDRESS dev show "$WIRELESS_IFACE" 2>/dev/null | tee -a "$LOGFILE" || true
    return 1
}

# Initialize a flag to track network connection status
network_connected=false

# Check if LAN is available
if nmcli device status | grep -q 'ethernet'; then
    echo "LAN connection is available. Testing connectivity..." | tee -a "$LOGFILE"
    if test_connection; then
        echo "LAN connection is functional." | tee -a "$LOGFILE"
        network_connected=true
    else
        echo "LAN is available but cannot reach 8.8.8.8." | tee -a "$LOGFILE"
    fi
else
    echo "No LAN connection available." | tee -a "$LOGFILE"
fi

# If LAN test failed or LAN is not available, try Wi-Fi
if ! $network_connected; then
    echo "LAN connection failed or not available. Attempting to connect to $WIFISSID..." | tee -a "$LOGFILE"
    if connect_wifi; then
        echo "Wi-Fi connection has been activated and is functional." | tee -a "$LOGFILE"
        network_connected=true
    else
        echo "Failed to connect to $WIFISSID or cannot reach 8.8.8.8." | tee -a "$LOGFILE"
    fi
fi

# Check if network connection is established and functional
if $network_connected; then
    current_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
    echo "Network connection is established and functional. IP address: ${current_ip}. Continuing with the script..." | tee -a "$LOGFILE"
else
    echo "No network connection is possible. Please check your connections." | tee -a "$LOGFILE"
    while true; do
        sleep 60
    done
fi

# Create the directory to mount the network share to.
log_and_run "mkdir -p /media/sc_reports"

# Deletes the contents in the sessions folder
log_and_run "rm -r /run/live/medium/data/sessions/*"

# Mount the network share to the local filesystem
log_and_run "mount -t cifs -o username=${SHAREUSER},password=${SHAREPASSWD} ${SHARELOCATION} /media/sc_reports"
tput cuu 1 && tput el

# Extract the hostname from GITEA_URL (removes http:// and port)
DOMAIN_NAME=$(echo "$GITEA_URL" | sed -E 's~http://([^:/]+).*~\1~')

# DNS test for the extracted domain using getent
DNS_TEST_RESULT=$(getent hosts "$DOMAIN_NAME" | awk '{ print $1 }')

if [ -n "$DNS_TEST_RESULT" ]; then
    echo "DNS resolution successful for $DOMAIN_NAME. IP(s): $DNS_TEST_RESULT" | tee -a "$LOGFILE"
else
    echo "DNS resolution failed for $DOMAIN_NAME. Please check DNS settings." | tee -a "$LOGFILE"
fi

# Fetch the date from Gitea API using GET and capture the headers
API_RESPONSE=$(curl -sS -m 15 -H "Authorization: token $ACCESS_TOKEN" "${GITEA_URL}/api/v1/version" -I 2>&1)
tput cuu 1 && tput el

# Extract the Date header and parse it
DATE_STRING=$(echo "$API_RESPONSE" | grep -i "^Date:" | cut -d' ' -f2-)
if [[ $(uname) == "Darwin" ]]; then
    # BSD/macOS date parsing
    API_DATE=$(date -j -f "%a, %d %b %Y %H:%M:%S %Z" "$DATE_STRING" "+%d-%m-%Y" 2>/dev/null)
else
    # GNU/Linux date parsing
    API_DATE=$(date -d "$DATE_STRING" "+%d-%m-%Y" 2>/dev/null)
fi
tput cuu 1 && tput el

# Check if API_DATE is empty
if [ -z "$API_DATE" ]; then
    echo "Failed to retrieve date from Gitea API. Full response:" | tee -a "$LOGFILE"
    echo "$API_RESPONSE" | tee -a "$LOGFILE"
    tput cuu 1 && tput el
    echo "Using system date instead." | tee -a "$LOGFILE"
    API_DATE=$(date +%d-%m-%Y)
else
    echo "Successfully retrieved date from Gitea API: $API_DATE" | tee -a "$LOGFILE"
fi

# Convert API_DATE to a format that the date command can understand
FORMATTED_DATE=$(echo "$API_DATE" | sed 's/\(..\)-\(..\)-\(....\)/\3-\2-\1/')

# Extract YEAR, MONTH, and DAY
YEAR=$(date -d "$FORMATTED_DATE" +%Y 2>/dev/null || date -j -f "%Y-%m-%d" "$FORMATTED_DATE" +%Y)
MONTH=$(date -d "$FORMATTED_DATE" +%B 2>/dev/null || date -j -f "%Y-%m-%d" "$FORMATTED_DATE" +%B)
DAY=$(date -d "$FORMATTED_DATE" +%d 2>/dev/null || date -j -f "%Y-%m-%d" "$FORMATTED_DATE" +%d)

# Create the date-based directory structure with full month name
DATE_DIR="/media/sc_reports/${STORENAME}/${YEAR}/${MONTH}/${DAY}"

# Create the directory if it does not exist
log_and_run "mkdir -p \"$DATE_DIR\""
log_and_run "chmod -R u+w \"$DATE_DIR\""

# Launch Service Center to begin diagnostics.
SERIAL=$(sudo dmidecode -s system-serial-number | cut -c -9)
MODEL=$(sudo dmidecode -s system-product-name | cut -c -9)
MANF=$(sudo dmidecode -s system-manufacturer | cut -c -9)

if [ -z "$SERIAL" ]; then
    SERIAL="NOSERIAL"
fi
if [ -z "$MODEL" ]; then 
    MODEL="NOMODEL"
fi
if [ -z "$MANF" ]; then
    MANF="NOMANF"
fi
SYSTEM_NAME=$(echo "${MANF}-${MODEL}-${SERIAL}" | tr -cd '[:alnum:]-')

SESSIONNAME="${SYSTEM_NAME}"
SCRIPTNAME="${SCRIPT::-4}"
SCRIPTNAME="${SCRIPTNAME^^}"

# Prevent system from shutting down before the script completes
log_and_run "sed -i \"s/ShutdownOnExit=.*/ShutdownOnExit=false/\" \"/etc/sc.conf\""

echo "***************************************************************************"
echo "************************LOADING PLEASE WAIT********************************"
echo "***************************************************************************"

log_and_run "cd /usr/local/pcdoctor/bin; ./scui.sh -f scripts/$SCRIPT -ticketid ${STORENAME}-$SCRIPTNAME -sessionname $SESSIONNAME -deviceid $MANF -exit"

# Copy files into the appropriate folder in /media/sc_reports/
log_and_run "cp /run/live/medium/data/sessions/${STORENAME}-${SCRIPTNAME}__${SESSIONNAME}/testlogs/*.html $DATE_DIR/ >& /dev/null"
log_and_run "cp /run/live/medium/data/sessions/${STORENAME}-${SCRIPTNAME}__${SESSIONNAME}/sysinfo/sysinfo_detailed-*.html $DATE_DIR/ >& /dev/null"

TESTLOGSRCFOLDER="/run/live/medium/data/sessions/${STORENAME}-${SCRIPTNAME}__${SESSIONNAME}/testlogs/"
SYSINFOSRCFOLDER="/run/live/medium/data/sessions/${STORENAME}-${SCRIPTNAME}__${SESSIONNAME}/sysinfo/"

# Function to determine writable temporary directory
get_temp_dir() {
    # Try /tmp first
    if [ -d "/tmp" ] && [ -w "/tmp" ] && touch "/tmp/test_$$" 2>/dev/null; then
        rm -f "/tmp/test_$$"
        echo "/tmp"
        return 0
    fi
    # Fallback to LOGDIR
    if [ -d "$LOGDIR" ] && [ -w "$LOGDIR" ] && touch "$LOGDIR/test_$$" 2>/dev/null; then
        rm -f "$LOGDIR/test_$$"
        echo "$LOGDIR"
        return 0
    fi
    # No writable directory found
    echo ""
    return 1
}

# Get temporary directory
TEMP_DIR=$(get_temp_dir)
if [ -z "$TEMP_DIR" ]; then
    echo "Error: No writable temporary directory found (/tmp or $LOGDIR)" | tee -a "$LOGFILE"
    exit 1
fi
echo "Using temporary directory: $TEMP_DIR" | tee -a "$LOGFILE"

# Upload TESTLOGSRCFOLDER HTML files to Gitea
for file in "$TESTLOGSRCFOLDER"/*.html; do
    if [ -f "$file" ]; then
        # Encode file content in base64
        FILE_CONTENT=$(base64 -w 0 "$file")
        if [ -z "$FILE_CONTENT" ]; then
            echo "Error: Failed to encode $(basename "$file") in base64" | tee -a "$LOGFILE"
            continue
        fi

        # Check if the file already exists in the repository
        echo "Checking if $(basename "$file") exists in Gitea..." | tee -a "$LOGFILE"
        FILE_CHECK=$(/usr/bin/curl -s -H "Authorization: token $ACCESS_TOKEN" \
            "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$YEAR/$MONTH/$DAY/$(basename "$file")?branch=$BRANCH_NAME" 2>&1)
        if echo "$FILE_CHECK" | grep -q '"sha":'; then
            # File exists, extract SHA for update
            FILE_SHA=$(echo "$FILE_CHECK" | grep -o '"sha":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "File exists with SHA: $FILE_SHA, updating..." | tee -a "$LOGFILE"
            METHOD="PUT"
            JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "author": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "committer": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "message": "Updated report for: $SESSIONNAME",
  "content": "$FILE_CONTENT",
  "sha": "$FILE_SHA"
}
EOF
            )
        else
            echo "File does not exist, creating..." | tee -a "$LOGFILE"
            METHOD="POST"
            JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "author": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "committer": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "message": "Report uploaded for: $SESSIONNAME",
  "content": "$FILE_CONTENT"
}
EOF
            )
        fi

        # Save JSON payload to a temporary file
        TEMP_JSON="$TEMP_DIR/gitea_payload_$$_$(basename "$file").json"
        echo "$JSON_PAYLOAD" > "$TEMP_JSON"

        # Validate JSON payload
        if ! grep -q "^{" "$TEMP_JSON"; then
            echo "Error: Invalid JSON payload for $(basename "$file")" | tee -a "$LOGFILE"
            rm -f "$TEMP_JSON"
            continue
        fi

        # Log the action
        echo "Uploading $(basename "$file") to Gitea..." | tee -a "$LOGFILE"
        
        # Upload the file using the Gitea API with curl
        RESPONSE=$(/usr/bin/curl -sS -m 15 -X "$METHOD" -H "Authorization: token $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            --data-binary "@$TEMP_JSON" \
            "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$YEAR/$MONTH/$DAY/$(basename "$file")" 2>&1)
        
        # Clean up
        rm -f "$TEMP_JSON"

        # Check curl exit status
        CURL_EXIT_CODE=$?
        if [ $CURL_EXIT_CODE -ne 0 ]; then
            echo "Failed to upload $(basename "$file") (curl error $CURL_EXIT_CODE)" | tee -a "$LOGFILE"
        elif echo "$RESPONSE" | grep -q '"content":'; then
            echo "Successfully uploaded $(basename "$file")" | tee -a "$LOGFILE"
        else
            echo "Error uploading $(basename "$file")" | tee -a "$LOGFILE"
            ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message": *"[^"]*"' | head -1)
            [ -n "$ERROR_MSG" ] && echo "Details: $ERROR_MSG" | tee -a "$LOGFILE"
        fi
    fi
done

# Upload SYSINFOSRCFOLDER HTML files to Gitea
for file in "$SYSINFOSRCFOLDER"/sysinfo_detailed-*.html; do
    if [ -f "$file" ]; then
        # Encode file content in base64
        FILE_CONTENT=$(base64 -w 0 "$file")
        if [ -z "$FILE_CONTENT" ]; then
            echo "Error: Failed to encode $(basename "$file") in base64" | tee -a "$LOGFILE"
            continue
        fi

        # Check if the file already exists in the repository
        echo "Checking if $(basename "$file") exists in Gitea..." | tee -a "$LOGFILE"
        FILE_CHECK=$(/usr/bin/curl -s -H "Authorization: token $ACCESS_TOKEN" \
            "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$YEAR/$MONTH/$DAY/$(basename "$file")?branch=$BRANCH_NAME" 2>&1)
        if echo "$FILE_CHECK" | grep -q '"sha":'; then
            # File exists, extract SHA for update
            FILE_SHA=$(echo "$FILE_CHECK" | grep -o '"sha":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "File exists with SHA: $FILE_SHA, updating..." | tee -a "$LOGFILE"
            METHOD="PUT"
            JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "author": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "committer": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "message": "Updated report for: $SESSIONNAME",
  "content": "$FILE_CONTENT",
  "sha": "$FILE_SHA"
}
EOF
            )
        else
            echo "File does not exist, creating..." | tee -a "$LOGFILE"
            METHOD="POST"
            JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "author": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "committer": {
    "email": "$REPO_NAME@cashconverters.co.za",
    "name": "$REPO_NAME"
  },
  "message": "Report uploaded for: $SESSIONNAME",
  "content": "$FILE_CONTENT"
}
EOF
            )
        fi

        # Save JSON payload to a temporary file
        TEMP_JSON="$TEMP_DIR/gitea_payload_$$_$(basename "$file").json"
        echo "$JSON_PAYLOAD" > "$TEMP_JSON"

        # Validate JSON payload
        if ! grep -q "^{" "$TEMP_JSON"; then
            echo "Error: Invalid JSON payload for $(basename "$file")" | tee -a "$LOGFILE"
            rm -f "$TEMP_JSON"
            continue
        fi

        # Log the action
        echo "Uploading $(basename "$file") to Gitea..." | tee -a "$LOGFILE"
        
        # Upload the file using the Gitea API with curl
        RESPONSE=$(/usr/bin/curl -sS -m 15 -X "$METHOD" -H "Authorization: token $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            --data-binary "@$TEMP_JSON" \
            "$GITEA_URL/api/v1/repos/$REPO_OWNER/$REPO_NAME/contents/$YEAR/$MONTH/$DAY/$(basename "$file")" 2>&1)
        
        # Clean up
        rm -f "$TEMP_JSON"

        # Check curl exit status
        CURL_EXIT_CODE=$?
        if [ $CURL_EXIT_CODE -ne 0 ]; then
            echo "Failed to upload $(basename "$file") (curl error $CURL_EXIT_CODE)" | tee -a "$LOGFILE"
        elif echo "$RESPONSE" | grep -q '"content":'; then
            echo "Successfully uploaded $(basename "$file")" | tee -a "$LOGFILE"
        else
            echo "Error uploading $(basename "$file")" | tee -a "$LOGFILE"
            ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message": *"[^"]*"' | head -1)
            [ -n "$ERROR_MSG" ] && echo "Details: $ERROR_MSG" | tee -a "$LOGFILE"
        fi
    fi
done

# Log file copy and upload
NEW_LOGFILE="$LOGDIR/${SYSTEM_NAME}_${TIMESTAMP2}.log"

# Copy the original log file to new filename with timestamp
cp "$LOGFILE" "$NEW_LOGFILE"
if [ $? -eq 0 ]; then
    echo "Log file copied successfully to $NEW_LOGFILE" | tee -a "$LOGFILE"
else
    echo "Failed to copy log file to $NEW_LOGFILE" | tee -a "$LOGFILE"
    exit 1
fi

# Encode the new log file content in base64
LOG_CONTENT=$(base64 -w 0 "$NEW_LOGFILE")
if [ -z "$LOG_CONTENT" ]; then
    echo "Error: Failed to encode $(basename "$NEW_LOGFILE") in base64" | tee -a "$LOGFILE"
    exit 1
fi

# Check if the log file already exists in the repository
echo "Checking if $(basename "$NEW_LOGFILE") exists in Log Server..." | tee -a "$LOGFILE"
FILE_CHECK=$(/usr/bin/curl -s -H "Authorization: token $GITEA_LOGSERVER_TOKEN" \
    "$GITEA_LOGSERVER_URL/api/v1/repos/$GITEA_LOGSERVER_REPO_OWNER/$GITEA_LOGSERVER_REPO_NAME/contents/PCDOC/$YEAR/$MONTH/$DAY/$(basename "$NEW_LOGFILE")?branch=$GITEA_LOGSERVER_BRANCH_NAME" 2>&1)
if echo "$FILE_CHECK" | grep -q '"sha":'; then
    # File exists, extract SHA for update
    FILE_SHA=$(echo "$FILE_CHECK" | grep -o '"sha":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "File exists with SHA: $FILE_SHA, updating..." | tee -a "$LOGFILE"
    METHOD="PUT"
    LOG_JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$GITEA_LOGSERVER_BRANCH_NAME",
  "author": {
    "email": "$GITEA_LOGSERVER_REPO_NAME@cashconverters.co.za",
    "name": "$GITEA_LOGSERVER_REPO_NAME"
  },
  "committer": {
    "email": "$GITEA_LOGSERVER_REPO_NAME@cashconverters.co.za",
    "name": "$GITEA_LOGSERVER_REPO_NAME"
  },
  "message": "Updated log file for: $SESSIONNAME",
  "content": "$LOG_CONTENT",
  "sha": "$FILE_SHA"
}
EOF
    )
else
    echo "File does not exist, creating..." | tee -a "$LOGFILE"
    METHOD="POST"
    LOG_JSON_PAYLOAD=$(cat <<EOF
{
  "branch": "$GITEA_LOGSERVER_BRANCH_NAME",
  "author": {
    "email": "$GITEA_LOGSERVER_REPO_NAME@cashconverters.co.za",
    "name": "$GITEA_LOGSERVER_REPO_NAME"
  },
  "committer": {
    "email": "$GITEA_LOGSERVER_REPO_NAME@cashconverters.co.za",
    "name": "$GITEA_LOGSERVER_REPO_NAME"
  },
  "message": "Log file uploaded for: $SESSIONNAME",
  "content": "$LOG_CONTENT"
}
EOF
    )
fi

# Save JSON payload to a temporary file
TEMP_JSON="$TEMP_DIR/gitea_log_payload_$$.json"
echo "$LOG_JSON_PAYLOAD" > "$TEMP_JSON"

# Validate JSON payload
if ! grep -q "^{" "$TEMP_JSON"; then
    echo "Error: Invalid JSON payload for $(basename "$NEW_LOGFILE")" | tee -a "$LOGFILE"
    rm -f "$TEMP_JSON"
    exit 1
fi

# Upload to Log Server
echo "Uploading log file $(basename "$NEW_LOGFILE") to Log Server..." | tee -a "$LOGFILE"

RESPONSE=$(/usr/bin/curl -sS -m 15 -X "$METHOD" \
    -H "Authorization: token $GITEA_LOGSERVER_TOKEN" \
    -H "Content-Type: application/json" \
    --data-binary "@$TEMP_JSON" \
    "$GITEA_LOGSERVER_URL/api/v1/repos/$GITEA_LOGSERVER_REPO_OWNER/$GITEA_LOGSERVER_REPO_NAME/contents/PCDOC/$YEAR/$MONTH/$DAY/$(basename "$NEW_LOGFILE")" 2>&1)

# Clean up
rm -f "$TEMP_JSON"

# Check upload status
CURL_EXIT_CODE=$?
if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Failed to upload $(basename "$NEW_LOGFILE") (curl error $CURL_EXIT_CODE)" | tee -a "$LOGFILE"
elif echo "$RESPONSE" | grep -q '"content":'; then
    echo "Log file $(basename "$NEW_LOGFILE") uploaded successfully!" | tee -a "$LOGFILE"
else
    echo "Error uploading $(basename "$NEW_LOGFILE")" | tee -a "$LOGFILE"
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message": *"[^"]*"' | head -1)
    [ -n "$ERROR_MSG" ] && echo "Details: $ERROR_MSG" | tee -a "$LOGFILE"
fi


# Power off the system
log_and_run "poweroff"

# Exit with the last command's status
exit $?