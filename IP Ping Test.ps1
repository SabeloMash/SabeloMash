$ips = @(
    "172.20.1.160",
    "172.20.2.160",
    "172.20.10.160",
    "172.20.51.160"
)

foreach ($ip in $ips) {
    Write-Host "Pinging $ip..."

    if (Test-Connection -ComputerName $ip -Count 2 -Quiet) {
        Write-Host "$ip is UP"
    } else {
        Write-Host "$ip is DOWN"
    }

    Write-Host "----------------------"
}