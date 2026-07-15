#!/bin/bash

# === Eject all external USB drives safely ===
eject_usb_drives() {
  USB_DISKS=$(diskutil list external physical | grep "/dev/disk" | awk '{print $1}')

  for disk in $USB_DISKS; do
    echo "📦 Attempting to unmount: $disk"
    
    # Force unmount the entire disk (all volumes)
    diskutil unmountDisk force "$disk" >/dev/null 2>&1

    # Eject the disk
    if diskutil eject "$disk" >/dev/null 2>&1; then
      echo "✅ Successfully ejected $disk"
    else
      echo "❌ Failed to eject $disk"
    fi
  done
}

# === Run the function ===
eject_usb_drives

exit 0

