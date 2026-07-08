# Camera Diagnostic Script for Acer Aspire ES1-571
# Run this as Administrator in PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CAMERA DIAGNOSTIC REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. PRIVACY SETTINGS
Write-Host "[1/6] Checking Camera Privacy Settings..." -ForegroundColor Yellow
$privacyKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
if (Test-Path $privacyKey) {
    $value = (Get-ItemProperty -Path $privacyKey -Name "Value" -ErrorAction SilentlyContinue).Value
    if ($value -eq "Deny") {
        Write-Host "  WARNING: Camera access is DENIED in privacy settings!" -ForegroundColor Red
        Write-Host "  Fix: Run 'reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam`" /v Value /t REG_SZ /d Allow /f' as Admin" -ForegroundColor Yellow
    } elseif ($value -eq "Allow") {
        Write-Host "  OK: Camera access is ALLOWED" -ForegroundColor Green
    } else {
        Write-Host "  INFO: Privacy value = $value" -ForegroundColor Gray
    }
} else {
    Write-Host "  INFO: Privacy registry key not found (may use different path)" -ForegroundColor Gray
}

# Check UWP privacy
$uwpPrivacy = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ByApp"
if (Test-Path $uwpPrivacy) {
    Write-Host "  INFO: UWP privacy settings exist" -ForegroundColor Gray
} else {
    Write-Host "  INFO: UWP privacy settings not found" -ForegroundColor Gray
}
Write-Host ""

# 2. DEVICE MANAGER - ALL DEVICES (including hidden)
Write-Host "[2/6] Checking Device Manager (including hidden devices)..." -ForegroundColor Yellow
$allDevices = Get-PnpDevice -PresentOnly $false
$cameraDevices = $allDevices | Where-Object {
    $_.FriendlyName -match 'camera|webcam|imaging|video|uvc|integrated|lenovo|acer|chicony|sony|realtek' -or
    $_.Class -match 'Image|Camera' -or
    $_.InstanceId -match 'USBVID|USBVIDEO'
}

if ($cameraDevices.Count -gt 0) {
    Write-Host "  FOUND $($cameraDevices.Count) camera-related device(s):" -ForegroundColor Green
    $cameraDevices | ForEach-Object {
        $color = if ($_.Status -eq 'OK') { 'Green' } elseif ($_.Status -eq 'Error') { 'Red' } else { 'Yellow' }
        Write-Host "    - $($_.FriendlyName)" -ForegroundColor $color
        Write-Host "      Class: $($_.Class) | Status: $($_.Status) | Present: $($_.Present)" -ForegroundColor Gray
        Write-Host "      Instance: $($_.InstanceId)" -ForegroundColor Gray
    }
} else {
    Write-Host "  NO camera devices found in Device Manager (including hidden)" -ForegroundColor Red
    Write-Host "  This suggests the camera is either disabled, disconnected, or not detected by Windows." -ForegroundColor Red
}
Write-Host ""

# 3. USB DEVICES (internal cameras often appear on USB bus)
Write-Host "[3/6] Checking USB Devices (cameras often appear as USB devices)..." -ForegroundColor Yellow
$usbDevices = Get-PnpDevice -Class USB
$usbCameras = $usbDevices | Where-Object {
    $_.FriendlyName -match 'camera|webcam|video|uvc|lenovo|acer|chicony|sony|realtek|integrated' -or
    $_.InstanceId -match 'USBVID'
}

if ($usbCameras.Count -gt 0) {
    Write-Host "  FOUND $($usbCameras.Count) USB camera-related device(s):" -ForegroundColor Green
    $usbCameras | ForEach-Object {
        Write-Host "    - $($_.FriendlyName)" -ForegroundColor Green
        Write-Host "      Status: $($_.Status) | Present: $($_.Present)" -ForegroundColor Gray
    }
} else {
    Write-Host "  NO camera-related USB devices found" -ForegroundColor Red
    Write-Host "  Checking ALL USB devices for anything unusual..." -ForegroundColor Yellow
    $usbDevices | Where-Object { $_.Status -eq 'Error' -or $_.Status -eq 'Warning' } | ForEach-Object {
        Write-Host "    - $($_.FriendlyName) [Status: $($_.Status)]" -ForegroundColor Red
    }
}
Write-Host ""

# 4. CAMERA SERVICES
Write-Host "[4/6] Checking Camera-Related Services..." -ForegroundColor Yellow
$services = Get-Service | Where-Object { $_.DisplayName -match 'camera|frame|media' }
if ($services.Count -gt 0) {
    Write-Host "  Found $($services.Count) camera-related service(s):" -ForegroundColor Green
    $services | ForEach-Object {
        $color = if ($_.Status -eq 'Running') { 'Green' } else { 'Yellow' }
        Write-Host "    - $($_.DisplayName) [Status: $($_.Status) | Startup: $($_.StartType)]" -ForegroundColor $color
    }
} else {
    Write-Host "  NO camera-related services found" -ForegroundColor Red
}

# Check specific services
$frameServer = Get-Service -Name "FrameServer" -ErrorAction SilentlyContinue
if ($frameServer) {
    Write-Host "  FrameServer service: Status=$($frameServer.Status) | StartType=$($frameServer.StartType)" -ForegroundColor Gray
} else {
    Write-Host "  FrameServer service: NOT FOUND" -ForegroundColor Red
}
Write-Host ""

# 5. EVENT LOG ERRORS
Write-Host "[5/6] Checking Event Log for Camera Errors..." -ForegroundColor Yellow
$events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 20 -ErrorAction SilentlyContinue | Where-Object {
    $_.Message -match 'camera|webcam|video|uvc|hid|usb' -or
    $_.ProviderName -match 'DriverFrameworks|USB|Camera'
}
if ($events.Count -gt 0) {
    Write-Host "  Found $($events.Count) recent error(s) related to camera/USB:" -ForegroundColor Yellow
    $events | Select-Object -First 5 | ForEach-Object {
        Write-Host "    - $($_.Message.Substring(0, [Math]::Min(150, $_.Message.Length)))..." -ForegroundColor Gray
    }
} else {
    Write-Host "  NO recent camera-related errors in Event Log" -ForegroundColor Green
}
Write-Host ""

# 6. DRIVER STORE
Write-Host "[6/6] Checking Driver Store for Camera Drivers..." -ForegroundColor Yellow
$driverPackages = Get-WindowsDriver -Online | Where-Object {
    $_.OriginalFileName -match 'usbvideo|uvc|camera|webcam' -or
    $_.ClassName -match 'Camera|Image'
}
if ($driverPackages.Count -gt 0) {
    Write-Host "  Found $($driverPackages.Count) camera driver package(s) in driver store:" -ForegroundColor Green
    $driverPackages | Select-Object -First 5 | ForEach-Object {
        Write-Host "    - $($_.ClassName)\$($_.DriverName)" -ForegroundColor Gray
    }
} else {
    Write-Host "  NO camera drivers found in driver store" -ForegroundColor Red
}

# Check INF files for camera drivers
$infFiles = Get-ChildItem -Path "C:\Windows\INF" -Filter "*.inf" -ErrorAction SilentlyContinue | Where-Object {
    Select-String -Path $_.FullName -Pattern 'camera|webcam|uvc|usbvideo' -Quiet
}
if ($infFiles.Count -gt 0) {
    Write-Host "  Found $($infFiles.Count) INF files referencing camera drivers" -ForegroundColor Gray
}
Write-Host ""

# SUMMARY
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY & RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($cameraDevices.Count -eq 0 -and $usbCameras.Count -eq 0) {
    Write-Host ""
    Write-Host "RESULT: Camera is NOT detected by Windows at all." -ForegroundColor Red
    Write-Host ""
    Write-Host "POSSIBLE CAUSES:" -ForegroundColor Yellow
    Write-Host "  1. Camera disabled in BIOS/UEFI" -ForegroundColor White
    Write-Host "  2. Physical camera switch/privacy shutter is ON" -ForegroundColor White
    Write-Host "  3. Camera ribbon cable disconnected or loose" -ForegroundColor White
    Write-Host "  4. Camera hardware has failed" -ForegroundColor White
    Write-Host "  5. Motherboard issue" -ForegroundColor White
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Reboot and enter BIOS (press F2 repeatedly at startup on Acer)" -ForegroundColor White
    Write-Host "  2. Look for 'Camera', 'Webcam', 'Integrated Camera' and enable it" -ForegroundColor White
    Write-Host "  3. Check for a physical switch or Fn+F7 (or Fn+F10) camera toggle" -ForegroundColor White
    Write-Host "  4. If enabled in BIOS but still not showing, hardware failure is likely" -ForegroundColor White
    Write-Host "  5. Consider USB webcam as alternative" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "RESULT: Camera device(s) found. Check their Status." -ForegroundColor Yellow
    Write-Host "If status shows Error/Warning, reinstall the driver." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
