$subnets = 1..110 # Change this range as needed

$ips = foreach ($subnet in $subnets) {
    "172.20.$subnet.160"
}

foreach ($ip in $ips) {
    Write-Host "Pinging $ip..."

    if (Test-Connection -ComputerName $ip -Count 2 -Quiet) {
        Write-Host "$ip is UP"
    } else {
        Write-Host "$ip is DOWN"
    }

    Write-Host "----------------------"
}