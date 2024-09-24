<#
    PowerShell config rewrite
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

Set-PSReadLineOption -PredictionSource History `
    # -PredictionViewStyle ListView `
    # -HistoryNoDuplicates `
    # -EditMode Windows `
    # -Colors @{ InlinePrediction = "#9CA3AF" }

# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'


## Functions

# function Update-PowerShell {
#     # Refactor of CTT_L... kinda
#     Write-Host "Checking for updates.." -ForegroundColor Green;
#     $current_version = $PSVersionTable.PSVersion.ToString();
#     $url = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest";
#     $release_info = Invoke-RestMethod -Uri $url;
#     $release_version = $release_info.tag_name.Trim('v');
#     if ($current_version -lt $release_version) {
#         Write-Host "PowerShell requires an update. Updating..." -ForegroundColor Yellow;
#         winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements;
#         Write-Host "PowerShell updated! Restart your shell to confirm changes.";
#     } else {
#         Write-Host "PowerShell is up to date :)" -ForegroundColor Green;
#     };
# };
# Update-PowerShell

### CL Utils

function rm-rf($path) {
    Remove-Item $path -r -Force
}

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

### Python easy stuff

# function activate() {
#     $dir = Get-Location | grep "C:\\"
#     $dir + ".\\.venv\\Scripts\\activate"
# }

function create-venv($venv_name) {
    uv venv
}

#### `pip` replacement -> uv

function pipi($package) {
    uv pip install $package
}

function pipl() {
    uv pip list
}

function pipr() {
    uv pip install -r requirements.txt
}

function pipf() {
    uv pip freeze
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
    # but man it's good and useful as fuck
    Set-Location ..;
}

function pwd {
    Get-Location | grep "C:\\"
}

function pwdc {
    Get-Location | grep "C:\\" | clip
}

## Filebot renamed Functions

function rename-mkv($db_mode) {
    if ($db_mode -eq 'tv') {
        $option = "TheMovieDB::TV"
    } else {
        $option = "TheMovieDB"
    }
    
    filebot -rename *.mkv --db $option -non-strict 
}

function rename-mp4($db_mode) {
    if ($db_mode -eq 'tv') {
        $option = "TheMovieDB::TV"
    } else {
        $option = "TheMovieDB"
    }
    
    filebot -rename *.mp4 --db $option -non-strict 
}

## Aliases
Set-Alias -Name cat -Value bat
Set-Alias -Name ls -Value lsd

# Filebot simple rename
# MKV
Set-Alias -Name mkvr -Value rename-mkv
Set-Alias -Name mp4r -Value rename-mp4


# omp is slow, it's really slow. so changing to using starship instead
# $omp_config = "C:\Users\Taran\Documents\Powershell\OMP\zash.omp.json"

# oh-my-posh init pwsh --config $omp_config | Invoke-Expression
# set a window title so that it at least looks more appealing

Invoke-Expression (&starship init powershell)


$Host.UI.RawUI.WindowTitle = "Terminal";
