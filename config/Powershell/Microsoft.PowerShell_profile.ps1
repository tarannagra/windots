<#
            - https://github.com/ChrisTitusTech/powershell-profile

    Credit where credit is due within the file.

    Abbreviations:
        - CTT_L     = Chris Titus Tech Github Link
        - CL        = Command Line
#>

# Import-Module -Name Terminal-Icons;
Import-Module PSReadLine

# Set-PSReadLineOption -PredictionSource History `
    # -PredictionViewStyle ListView `
    # -HistoryNoDuplicates `
    # -EditMode Windows `
    # -Colors @{ InlinePrediction = "#9CA3AF" }

# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -HistorySearchCursorMovesToEnd:$true
Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -Function HistorySearchForward

## Functions

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function screenshot() {
        ~/.tools/screenshot/screenshot.exe
    }

### Python easy stuff

function activate() {
    # simple enough, don't want to type this out all the time
    .\.venv\Scripts\activate
}

function pinit() {
    # initalise a Python project folder
    
    ## create "main.py"
    [void](New-Item -Name "main.py" -ItemType File)
    
    ## create "requirements.txt"
    [void](New-Item -Name "requirements.txt" -ItemType File)

    create-venv;
    .\.venv\Scripts\activate

    Write-Host "Created main.py & requirements.txt" -ForegroundColor Green;
    Write-Host "You are already activated in the venv!" -ForegroundColor Green;

}

function create-venv() {
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

function new-ls {
    eza --icons --header -l
}

function .. {
    Set-Location ..;
}

function pwd {
    Get-Location | grep "C:\\"
}

function pwdc {
    Get-Location | grep "C:\\" | clip
}

## Aliases
# Set-Alias -Name cat -Value bat
# Set-Alias -Name ls -Value lsd

# omp is slow, it's really slow. so changing to using starship instead
# $omp_config = "C:\Users\Taran\Documents\Powershell\OMP\zash.omp.json"

# oh-my-posh init pwsh --config $omp_config | Invoke-Expression
# set a window title so that it at least looks more appealing

Set-Alias -Name ls -Value new-ls


Invoke-Expression (&starship init powershell)

$Env:KOMOREBI_CONFIG_HOME = "C:\Users\subwa\.config\komorebi"

$Host.UI.RawUI.WindowTitle = "Terminal";

# =============================================================================
#
# Utility functions for zoxide.
#

# Call zoxide binary, returning the output as UTF-8.
function global:__zoxide_bin {
    $encoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
        $result = zoxide @args
        return $result
    } finally {
        [Console]::OutputEncoding = $encoding
    }
}

# pwd based on zoxide's format.
function global:__zoxide_pwd {
    $cwd = Get-Location
    if ($cwd.Provider.Name -eq "FileSystem") {
        $cwd.ProviderPath
    }
}

# cd + custom logic based on the value of _ZO_ECHO.
function global:__zoxide_cd($dir, $literal) {
    $dir = if ($literal) {
        Set-Location -LiteralPath $dir -Passthru -ErrorAction Stop
    } else {
        if ($dir -eq '-' -and ($PSVersionTable.PSVersion -lt 6.1)) {
            Write-Error "cd - is not supported below PowerShell 6.1. Please upgrade your version of PowerShell."
        }
        elseif ($dir -eq '+' -and ($PSVersionTable.PSVersion -lt 6.2)) {
            Write-Error "cd + is not supported below PowerShell 6.2. Please upgrade your version of PowerShell."
        }
        else {
            Set-Location -Path $dir -Passthru -ErrorAction Stop
        }
    }
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
$global:__zoxide_oldpwd = __zoxide_pwd
function global:__zoxide_hook {
    $result = __zoxide_pwd
    if ($result -ne $global:__zoxide_oldpwd) {
        if ($null -ne $result) {
            zoxide add "--" $result
        }
        $global:__zoxide_oldpwd = $result
    }
}

# Initialize hook.
$global:__zoxide_hooked = (Get-Variable __zoxide_hooked -ErrorAction SilentlyContinue -ValueOnly)
if ($global:__zoxide_hooked -ne 1) {
    $global:__zoxide_hooked = 1
    $global:__zoxide_prompt_old = $function:prompt

    function global:prompt {
        if ($null -ne $__zoxide_prompt_old) {
            & $__zoxide_prompt_old
        }
        $null = __zoxide_hook
    }
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function global:__zoxide_z {
    if ($args.Length -eq 0) {
        __zoxide_cd ~ $true
    }
    elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
        __zoxide_cd $args[0] $false
    }
    elseif ($args.Length -eq 1 -and (Test-Path $args[0] -PathType Container)) {
        __zoxide_cd $args[0] $true
    }
    else {
        $result = __zoxide_pwd
        if ($null -ne $result) {
            $result = __zoxide_bin query --exclude $result "--" @args
        }
        else {
            $result = __zoxide_bin query "--" @args
        }
        if ($LASTEXITCODE -eq 0) {
            __zoxide_cd $result $true
        }
    }
}

# Jump to a directory using interactive search.
function global:__zoxide_zi {
    $result = __zoxide_bin query -i "--" @args
    if ($LASTEXITCODE -eq 0) {
        __zoxide_cd $result $true
    }
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# =============================================================================
#
# To initialize zoxide, add this to your configuration (find it by running
# `echo $profile` in PowerShell):
#
Invoke-Expression (& { (zoxide init powershell | Out-String) })
