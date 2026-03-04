# Connect-WiFi.ps1
# Automatically connects to a specified Wi-Fi network

# Wi-Fi SSID and password
$SSID = "CCTECH"
$Password = "CC@tech01!@"

# Check if profile already exists
$profileExists = netsh wlan show profiles | Select-String -Pattern $SSID

if (-not $profileExists) {
    # Create a Wi-Fi profile and add it
    $xmlProfile = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

    # Save XML temporarily
    $tempProfile = "$env:TEMP\$SSID.xml"
    $xmlProfile | Out-File -FilePath $tempProfile -Encoding UTF8

    # Add Wi-Fi profile
    netsh wlan add profile filename="$tempProfile"
    Remove-Item $tempProfile
}

# Connect to Wi-Fi
netsh wlan connect name=$SSID
