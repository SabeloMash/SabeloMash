# Windows 10 AutoUnattend Answer Files - UEFI vs Legacy Guide

## Overview
This directory contains multiple `autounattend.xml` files optimized for different Boot Modes and architectures.

---

## Files and Usage

### 1. **autounattend.xml** (Current/UEFI Default)
- **Boot Mode**: UEFI (GPT)
- **Architectures**: 64-bit (amd64)
- **Partitioning**: GPT with EFI System Partition (ESP), MSR, Recovery, and Windows partitions
- **Use When**: Installing on modern UEFI systems with 64-bit Windows 10
- **Target Hardware**: Modern PCs/VMs (Hyper-V Gen 2, VM generation 2+, modern bios)

**Partition Layout:**
```
- WINRE (300 MB, Recovery)
- System (100 MB, EFI/FAT32)
- MSR (128 MB, Reserved)
- Windows (Remaining space, NTFS)
```

### 2. **autounattend_Legacy_MBR.xml** (New/Legacy BIOS)
- **Boot Mode**: Legacy BIOS (MBR)
- **Architectures**: Both 32-bit and 64-bit Windows 10
- **Partitioning**: MBR with single Primary partition
- **Use When**: Installing on older hardware with Legacy BIOS only
- **Target Hardware**: Legacy/older PCs, Hyper-V Gen 1 VMs, systems without EFI

**Partition Layout:**
```
- Windows (Full disk, NTFS, marked as Active/Bootable)
```

### 3. **New_autounattend.xml** (32-bit x86 Reference)
- **Architecture**: 32-bit (x86)
- **Boot Mode**: UEFI (GPT)
- **Use When**: Reference for 32-bit UEFI installations
- **Note**: Windows 10 32-bit is rarely deployed on modern hardware

### 4. **autounattend (1).xml** (Backup/Alternative)
- Same as main `autounattend.xml`
- Can be deleted or kept as backup

---

## Quick Decision Matrix

| Scenario | Use This File |
|----------|---------------|
| Modern PC/VM with UEFI, 64-bit Win10 | `autounattend.xml` |
| Old PC/VM with Legacy BIOS, 32 or 64-bit | `autounattend_Legacy_MBR.xml` |
| Mixed environment (both UEFI and Legacy) | See "Multi-Boot Strategy" below |

---

## Multi-Boot Strategy (Supporting Both UEFI & Legacy)

If you need to deploy to **both UEFI and Legacy BIOS** machines, use one of these approaches:

### **Option A: Two Separate ISO Images (RECOMMENDED)**
Create two bootable Windows 10 installation media with different answer files:
- **ISO 1**: Uses `autounattend.xml` (UEFI/GPT)
- **ISO 2**: Uses `autounattend_Legacy_MBR.xml` (Legacy/MBR)

**How to Apply:**
1. Place the respective answer file on the root of the Windows 10 installation media as `autounattend.xml`
2. Boot the target machine (it will automatically detect boot mode)
3. Installation proceeds automatically using the appropriate partitioning scheme

**Tools to Create Media:**
- Windows Media Creation Tool (manual, then add answer file)
- MDT (Microsoft Deployment Toolkit) – supports multiple configurations
- Ventoy – allows multi-boot scenarios

---

### **Option B: Dynamic Boot Mode Detection (Advanced)**
Add a PowerShell script in the `windowsPE` pass to detect boot mode and partition accordingly.

**Concept:**
```powershell
# Check if booted in UEFI or Legacy
$isFirm = $null
$isFirm = Test-Path -Path Variable:\efibootmgr
if ($isFirm) {
    # UEFI detected – use GPT partitioning
} else {
    # Legacy BIOS detected – use MBR partitioning
}
```

**Limitations:**
- More complex XML configuration
- Limited testing in some scenarios
- Not recommended for simple deployments

---

### **Option C: Universal GPT with Legacy Fallback (HYBRID MBR)**
Some organizations create a hybrid partition scheme that works with both:
- Uses GPT partitioning (UEFI compatible)
- Includes MBR boot record for Legacy BIOS compatibility
- Works on most modern systems, but older Legacy-only systems may fail

**Trade-offs:**
- ✅ Single ISO for both scenarios
- ❌ May not work on very old hardware
- ❌ Recovery partitions may be less reliable

---

## Implementation Steps

### **Using autounattend_Legacy_MBR.xml for Legacy Systems**

1. **Download Windows 10 32-bit or 64-bit ISO**
2. **Create bootable USB/DVD** using Rufus, UNetbootin, or Windows Media Creation Tool
3. **Mount/Extract the ISO** (optional, if modifying)
4. **Place answer file**:
   - Copy `autounattend_Legacy_MBR.xml` to the root of the installation media
   - Rename it to `autounattend.xml` (Windows setup looks for this name automatically)
5. **Boot target machine in Legacy BIOS mode**:
   - Enable Legacy/Compatibility mode in BIOS
   - Disable Secure Boot and UEFI (if required)
6. **Boot from USB/DVD** – Setup will run automatically

### **For UEFI Systems** (Current autounattend.xml)
- Same steps, but machine must be in UEFI mode
- Secure Boot can be enabled/disabled (handled by registry bypass in answer file)

---

## Customization Notes

Both answer files include:
- **Bypass settings**: TPM, Secure Boot, and RAM checks (useful for testing)
- **CCTECH script**: Customizes Control Panel and sets user permissions
- **User accounts**: Default "User" account with no password expiration
- **Timezone**: South Africa Standard Time (customize as needed)
- **OOBE automation**: Skips license agreement, online accounts, etc.

### **To Modify Product Key**
Edit this section in either XML file:
```xml
<ProductKey>
  <Key>YOUR-PRODUCT-KEY-HERE</Key>
  <WillShowUI>Never</WillShowUI>
</ProductKey>
```

### **To Change Computer Name**
```xml
<ComputerName>YOUR-COMPUTER-NAME</ComputerName>
```

### **To Change Timezone**
```xml
<TimeZone>South Africa Standard Time</TimeZone>
```

---

## Ansible Automation Integration

Your existing Ansible playbooks (e.g., `prepforsysprep.yml`) can be adapted:

```yaml
- name: Run Sysprep with MBR answer file
  win_shell: C:\windows\system32\sysprep\sysprep.exe /generalize /oobe /unattend:C:\windows\autounattend_Legacy_MBR.xml /shutdown
```

Or dynamically choose based on hardware:

```yaml
- name: Copy appropriate answer file
  win_copy:
    src: "autounattend_{{ boot_mode }}.xml"
    dest: C:\windows\autounattend.xml
  vars:
    boot_mode: "{% if firmware_type == 'UEFI' %}UEFI{% else %}Legacy_MBR{% endif %}"
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Invalid partition structure" error | Ensure answer file matches boot mode (UEFI→GPT, Legacy→MBR) |
| System won't boot after install | Check BIOS boot order and firmware mode (UEFI/Legacy) |
| Diskpart errors in setup log | Look in `C:\Windows\Panther\setuperr.log` for details |
| Setup loops back to language selection | Answer file not found; verify `autounattend.xml` is on media root |
| Can only boot with USB plugged in | Boot flag (`ACTIVE`) not set on MBR partition – rerun `autounattend_Legacy_MBR.xml` |

---

## Testing Checklist

- [ ] Test with 64-bit UEFI VM (Hyper-V Gen 2)
- [ ] Test with 32-bit or 64-bit Legacy VM (Hyper-V Gen 1)
- [ ] Verify partitioning with `diskpart` after install:
  - UEFI: Should show GPT partitions
  - Legacy: Should show MBR partition marked `*` (Active)
- [ ] Verify timezone and user account created
- [ ] Verify SysPrep runs cleanly before deployment
- [ ] Test image deployment to multiple machines

---

## References

- [Microsoft Unattend.xml Documentation](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [Windows 10 System Image Manager (SIM)](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/windows-system-image-manager-technical-reference)
- [DISM Image Capture & Deploy](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/capture-images-of-hard-disk-partitions--full-flash-update--ffus)
- [Hyper-V VM Generations](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/plan/should-i-create-a-generation-1-or-2-virtual-machine-in-hyper-v)
