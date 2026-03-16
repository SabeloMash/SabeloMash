# macOS USB Installer Creation Guide

## Overview
This guide provides step-by-step instructions to create a bootable macOS USB installer on a Mac machine.

## Prerequisites
- Mac computer running macOS
- USB drive (16GB minimum recommended)
- Sufficient storage on the Mac to download the macOS installer (~12GB)
- Administrator access

## Manual Method

### Step 1: Download macOS Installer
1. Open **App Store** on your Mac
2. Search for the macOS version you want (e.g., "macOS Sonoma")
3. Click **Get** → **Install**
4. The installer will download to `/Applications/Install macOS [Version].app`
5. Once complete, close the installer (don't proceed with installation)

### Step 2: Prepare USB Drive
1. Connect the USB drive to your Mac
2. Open **Disk Utility** (Applications > Utilities > Disk Utility)
3. Select the USB drive from the sidebar
4. Click **Erase**
5. Configure:
   - **Name**: `MacOS_Installer` (or your preferred name)
   - **Format**: `Mac OS Extended (Journaled)`
   - **Scheme**: `GUID Partition Map`
6. Click **Erase**

### Step 3: Create Bootable Installer
Open Terminal and run:
```bash
sudo /Applications/Install\ macOS\ [Version].app/Contents/Resources/createinstallmedia --volume /Volumes/MacOS_Installer
```

Replace `[Version]` with your macOS version (e.g., `Sonoma`, `Ventura`)

**Examples:**
```bash
# macOS Sonoma
sudo /Applications/Install\ macOS\ Sonoma.app/Contents/Resources/createinstallmedia --volume /Volumes/MacOS_Installer

# macOS Ventura
sudo /Applications/Install\ macOS\ Ventura.app/Contents/Resources/createinstallmedia --volume /Volumes/MacOS_Installer

# macOS Monterey
sudo /Applications/Install\ macOS\ Monterey.app/Contents/Resources/createinstallmedia --volume /Volumes/MacOS_Installer
```

### Step 4: Wait for Completion
- The process will display progress and take 10-20 minutes
- Terminal will show "Done" when complete
- The USB will then be named `Install macOS [Version]`

### Step 5: Verify the Installer
1. Eject the USB drive safely
2. Connect to target Mac
3. Restart target Mac and hold **Command + Option + R** (or **Option** only for newer Macs)
4. Select the USB installer from startup disk options

## Automated Script Method

See `create_macos_installer.sh` for automated script to create the installer.

### Usage:
```bash
chmod +x create_macos_installer.sh
./create_macos_installer.sh
```

## Troubleshooting

### Issue: "Command not found"
- Verify macOS installer is installed: `ls -la /Applications/ | grep Install`
- Check exact version name matches

### Issue: "Volume not found"
- Verify USB is connected and formatted
- Check volume name in Disk Utility
- Ensure you used the correct volume path

### Issue: "Operation not permitted"
- Use `sudo` for the command
- Check you have administrator rights

### Issue: USB not bootable
- Verify formatting was `Mac OS Extended (Journaled)` with `GUID Partition Map`
- Try using a different USB drive
- Download a fresh macOS installer

## Supported macOS Versions

| Version | Name | Release Year | Command |
|---------|------|--------------|---------|
| 14.x | Sonoma | 2023 | `--volume /Volumes/MacOS_Installer` |
| 13.x | Ventura | 2022 | `--volume /Volumes/MacOS_Installer` |
| 12.x | Monterey | 2021 | `--volume /Volumes/MacOS_Installer` |
| 11.x | Big Sur | 2020 | `--volume /Volumes/MacOS_Installer` |
| 10.15 | Catalina | 2019 | `--asr --file /path/to/installer` |

## Using the Installer

### On Target Mac
1. Insert USB drive
2. Restart and hold **Command + Option + R** (recovery mode) or **Option** (startup selector)
3. Select the USB installer
4. Follow the macOS installation wizard

### Multiple Machines (Deployment)
- Create one installer and image/distribute to multiple USB drives
- Use Disk Utility's "Restore" tab to clone the created installer to other USB drives

## References
- [Apple Official Guide](https://support.apple.com/en-us/HT201372)
- [macOS Recovery Modes](https://support.apple.com/en-us/HT201255)
