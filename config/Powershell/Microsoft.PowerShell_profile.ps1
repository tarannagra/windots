<#
    PowerShell config rewrite -- by Taran Nagra
        Inspired from:
            - https://github.com/ChrisTitusTech/powershell-profile

    Credit where credit is due within the file.

    Abbreviations:
        - CTT_L     = Chris Titus Tech Github Link
        - CL        = Command Line
#>

# Importing Terminal Icons
Import-Module -Name Terminal-Icons;
# Import PSReadLine
Import-Module PSReadLine

# Removing preset aliases
Remove-Alias pwd;

## Module config
### PSReadLine

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -Colors @{ InlinePrediction = '#9CA3AF'} # grey

# Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
# Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'


## Functions

function Update-PowerShell {
    # Refactor of CTT_L... kinda
    Write-Host "Checking for updates.." -ForegroundColor Green;
    $current_version = $PSVersionTable.PSVersion.ToString();
    $url = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest";
    $release_info = Invoke-RestMethod -Uri $url;
    $release_version = $release_info.tag_name.Trim('v');
    if ($current_version -lt $release_version) {
        Write-Host "PowerShell requires an update. Updating..." -ForegroundColor Yellow;
        winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements;
        Write-Host "PowerShell updated! Restart your shell to confirm changes.";
    } else {
        Write-Host "PowerShell is up to date :)" -ForegroundColor Green;
    };
};
Update-PowerShell

### CL Utils

function reload {
    & $PROFILE;
};

function ff($filename) {
    # Rip from CTT_L
    # TODO:
    # - make it faster
    Write-Host "Searching for all instances of ${filename}..." -ForegroundColor Yellow
    Get-ChildItem -Recurse -Filter "*${filename}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.Directory)\$($_)"
    }
};

function pkill($process_name) {
    Get-Process $process_name -ErrorAction SilentlyContinue | Stop-Process
    Write-Host "${process_name} has been killed!" -ForegroundColor Red;
};

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function ls($optional) {
    if (!($optional)) {
        lsd # run default lsd
    } else {
        lsd $optional
    }
}

function ll() {
    lsd -l
}

### Git time :)
#### Most of the time I'm too lazy to write them

function gs {
    git status;
};

function ga($param) {
    git add $param;
};

function gcom($message) {
    git commit -m $message;
}

function gpom {
    git push origin main
}

### Navigation

function .. {
    # surprised this is a valid function name
    # but man it's good and useful
    Set-Location ..;
}

function pwd {
    Get-Location | grep "C:\\"
}

function pwdc {
    Get-Location | grep "C:\\" | clip
}

## Aliases
Set-Alias -Name cat -Value bat
Set-Alias -Name ls -Value lsd


## import and set the name to the respective script in:
### ../Scripts/*.ps1
Set-Alias -Name wp -Value 'C:\Users\Taran\Documents\Powershell\Scripts\SetWallpaper.exe'
# Set-Alias -Name lvim -Value 'C:\Users\Taran\.local\bin\lvim.ps1'

$omp_config = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/zash.omp.json"

oh-my-posh init pwsh --config $omp_config | Invoke-Expression
# set a window title so that it at least looks more appealing
$Host.UI.RawUI.WindowTitle = "Terminal";
