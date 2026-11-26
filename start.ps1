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

# 带 no-store 的静态服务器：默认的 http.server 会让浏览器缓存 index.html，
# 改完代码刷新看不到效果，很容易误判成"改动无效"
$serverCode = @"
import http.server
import socketserver

PORT = $port


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def log_message(self, fmt, *args):
        pass


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('0.0.0.0', PORT), Handler) as httpd:
    httpd.serve_forever()
"@

$pyFile = Join-Path $env:TEMP 'gct_dev_server.py'
[IO.File]::WriteAllText($pyFile, $serverCode, (New-Object Text.UTF8Encoding $false))

Start-Process $localUrl
python $pyFile
