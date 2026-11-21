$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$port = 8777

Write-Host ""
Write-Host "  Gesture Christmas Tree" -ForegroundColor Cyan
Write-Host "  ==================================================" -ForegroundColor DarkGray

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Host "  [!] Python not found in PATH." -ForegroundColor Red
    Write-Host "      Any static server works, for example:  npx serve ."
    Write-Host ""
    exit 1
}

$localUrl = "http://localhost:$port/index.html"
Write-Host "  This machine" -ForegroundColor DarkGray
Write-Host "    $localUrl" -ForegroundColor Green

try {
    # 只取「有默认路由」的网卡，天然排除 VMware / Hyper-V / 虚拟网卡
    $idx = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Sort-Object RouteMetric |
        Select-Object -ExpandProperty InterfaceIndex -Unique)

    $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
        Where-Object {
            $idx -contains $_.InterfaceIndex -and
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*'
        } |
        Select-Object -ExpandProperty IPAddress -Unique

    if ($ips.Count -gt 0) {
        Write-Host ""
        Write-Host "  Same Wi-Fi / LAN" -ForegroundColor DarkGray
        foreach ($ip in $ips) {
            Write-Host "    http://${ip}:${port}/index.html" -ForegroundColor Yellow
        }
    }
} catch {
}

Write-Host ""
Write-Host "  Camera requires https or localhost." -ForegroundColor DarkGray
Write-Host "  Over LAN http the scene runs in auto-animation mode." -ForegroundColor DarkGray
Write-Host "  Phone / other-device setup: see README, section 'LAN access'." -ForegroundColor DarkGray
Write-Host "  ==================================================" -ForegroundColor DarkGray
Write-Host "  Stop: press Ctrl+C in this window" -ForegroundColor DarkGray
Write-Host ""

Start-Process $localUrl
python -m http.server $port --bind 0.0.0.0
