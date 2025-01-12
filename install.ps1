
Clear-Host

# As global as I can get
$title = "Taran's Windots"
$winget_repo = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"


function check_app([string]$app_name) {
    $out = Get-Command $app_name -ErrorAction SilentlyContinue
    return $null -ne $out
}

function winstall([string]$package_id) {
    # package ID instead of names since ID will not change!
    Write-Host "Installing $package_id" -ForegroundColor Green
    winget.exe install -e --id $package_id --silent --accept-package-agreements --accept-source-agreements
    Write-Host ""
}

function install_apps() {
    # * Komorebi (& hotkey daemon)
    if (-not (check_app("komorebi"))) {
        Write-Host "Install komorebi? " -ForegroundColor Yellow -NoNewline
        $choose_komo = Read-Host
        if ($choose_komo.ToLower() -eq "y") {
            winstall LGUG2Z.komorebi
            winstall LGUG2Z.whkd
        }
    }
    
    # * Visual Studio Code
    if (-not (check_app("code"))) {
        Write-Host "Install Visual Studio Code? " -ForegroundColor Yellow -NoNewline
        $choose_vsc = Read-Host
        if ($choose_vsc.ToLower() -eq "y") { 
            winstall Microsoft.VisualStudioCode
        }
    }

    # * Windows Terminal
    if (-not (check_app("wt"))) {
        Write-Host "Install Windows Terminal? " -ForegroundColor Yellow -NoNewline
        $choose_wt = Read-Host
        if ($choose_wt.ToLower() -eq "y") { 
            winstall Microsoft.WindowsTerminal
        }
    }
    
    # * Obsidian (best note taking app... imo  :])
    if (-not (check_app("wt"))) {
        Write-Host "Install Obsidian? " -ForegroundColor Magenta -NoNewline
        $choose_wt = Read-Host
        if ($choose_wt.ToLower() -eq "y") { 
            winstall Obsidian.Obsidian
        }
    }

    # * OneCommander (File Explorer alternative)
    if (-not (check_app("onecommander"))) {
        Write-Host "Install OneCommander? " -ForegroundColor Magenta -NoNewline
        $choose_oc = Read-Host
        if ($choose_oc.ToLower() -eq "y") { 
            winstall MilosParipovic.OneCommander
        }
    }

    # * YASB Reborn status bar
    if (-not (check_app("yasbc"))) {
        Write-Host "Install YASB Reborn? " -ForegroundColor Yellow -NoNewline
        $choose_yb = Read-Host
        if ($choose_yb.ToLower() -eq "y") {
            winstall AmN.yasb
        }
    }
}

function apply_config() {
    Write-Host "Nothing yet :p"
}

function main() {
    Write-Host "Installer made for $title" -ForegroundColor Green
    Write-Host "Simplying the app installation and applying customisations!"
    Write-Host ""

    Write-Host "Checking current WinGet version..." -ForegroundColor Yellow
    $current_wg = (winget --version)
    $latest_wg_online = Invoke-RestMethod -Uri $winget_repo
    $latest_wg = $latest_wg_online.tag_name

    if ($current_wg -lt $latest_wg) {
        Write-Host "Updating WinGet..." -ForegroundColor Yellow
        Add-AppxPackage -Path "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ForceApplicationShutdown
        Write-Host "Updated." -ForegroundColor Green
    } else {
        Write-Host "WinGet version OK" -ForegroundColor Green
    }

    $apps_download = Read-Host "Install apps? [y/n]"
    if ($apps_download.ToLower() -eq "y" -or $apps_download -eq "") {
        install_apps
    }
    $apply_settings = Read-Host "Apply config? [y/n]"
    if ($apply_settings.ToLower() -eq "y" -or $apply_settings -eq "") {
        apply_config
    }
}


Clear-Host
main