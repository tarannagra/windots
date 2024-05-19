
using namespace System.Management.Automation
using namespace System.Collections.ObjectModel
function Add-Theme {
    [cmdletbinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath,

        [switch]$Force,

        [ValidateSet('Color', 'Icon')]
        [Parameter(Mandatory)]
        [string]$Type
    )

    process {
        # Resolve path(s)
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }

        foreach ($resolvedPath in $paths) {
            if (Test-Path $resolvedPath) {
                $item = Get-Item -LiteralPath $resolvedPath

                $statusMsg  = "Adding $($type.ToLower()) theme [$($item.BaseName)]"
                $confirmMsg = "Are you sure you want to add file [$resolvedPath]?"
                $operation  = "Add $($Type.ToLower())"
                if ($PSCmdlet.ShouldProcess($statusMsg, $confirmMsg, $operation) -or $Force.IsPresent) {
                    if (-not $script:userThemeData.Themes.$Type.ContainsKey($item.BaseName) -or $Force.IsPresent) {

                        $theme = Import-PowerShellDataFile $item.FullName

                        # Convert color theme into escape sequences for lookup later
                        if ($Type -eq 'Color') {
                            # Add empty color theme
                            if (-not $script:colorSequences.ContainsKey($theme.Name)) {
                                $script:colorSequences[$theme.Name] = New-EmptyColorTheme
                            }

                            # Directories
                            $theme.Types.Directories.WellKnown.GetEnumerator().ForEach({
                                $script:colorSequences[$theme.Name].Types.Directories[$_.Name] = ConvertFrom-RGBColor -RGB $_.Value
                            })
                            # Wellknown files
                            $theme.Types.Files.WellKnown.GetEnumerator().ForEach({
                                $script:colorSequences[$theme.Name].Types.Files.WellKnown[$_.Name] = ConvertFrom-RGBColor -RGB $_.Value
                            })
                            # File extensions
                            $theme.Types.Files.GetEnumerator().Where({$_.Name -ne 'WellKnown'}).ForEach({
                                $script:colorSequences[$theme.Name].Types.Files[$_.Name] = ConvertFrom-RGBColor -RGB $_.Value
                            })
                        }

                        $script:userThemeData.Themes.$Type[$theme.Name] = $theme
                        Save-Theme -Theme $theme -Type $Type
                    } else {
                        Write-Error "$Type theme [$($theme.Name)] already exists. Use the -Force switch to overwrite."
                    }
                }
            } else {
                Write-Error "Path [$resolvedPath] is not valid."
            }
        }
    }
}
function ConvertFrom-ColorEscapeSequence {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Sequence
    )

    process {
        # Example input sequence: 'e[38;2;135;206;250m'
        $arr = $Sequence.Split(';')
        $r   = '{0:x}' -f [int]$arr[2]
        $g   = '{0:x}' -f [int]$arr[3]
        $b   = '{0:x}' -f [int]$arr[4].TrimEnd('m')

        ($r + $g + $b).ToUpper()
    }
}
function ConvertFrom-RGBColor {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$RGB
    )

    process {
        $RGB = $RGB.Replace('#', '')
        $r   = [convert]::ToInt32($RGB.SubString(0,2), 16)
        $g   = [convert]::ToInt32($RGB.SubString(2,2), 16)
        $b   = [convert]::ToInt32($RGB.SubString(4,2), 16)

        "${script:escape}[38;2;$r;$g;$b`m"
    }
}
function ConvertTo-ColorSequence {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [hashtable]$ColorData
    )

    process {
        $cs      = New-EmptyColorTheme
        $cs.Name = $ColorData.Name

        # Directories
        if ($ColorData.Types.Directories['symlink']) {
            $cs.Types.Directories['symlink']  = ConvertFrom-RGBColor -RGB $ColorData.Types.Directories['symlink']
        }
        if ($ColorData.Types.Directories['junction']) {
            $cs.Types.Directories['junction'] = ConvertFrom-RGBColor -RGB $ColorData.Types.Directories['junction']
        }
        $ColorData.Types.Directories.WellKnown.GetEnumerator().ForEach({
            $cs.Types.Directories[$_.Name] = ConvertFrom-RGBColor -RGB $_.Value
        })

        # Wellknown files
        if ($ColorData.Types.Files['symlink']) {
            $cs.Types.Files['symlink']  = ConvertFrom-RGBColor -RGB $ColorData.Types.Files['symlink']
        }
        if ($ColorData.Types.Files['junction']) {
            $cs.Types.Files['junction'] = ConvertFrom-RGBColor -RGB $ColorData.Types.Files['junction']
        }
        $ColorData.Types.Files.WellKnown.GetEnumerator().ForEach({
            $cs.Types.Files.WellKnown[$_.Name] = ConvertFrom-RGBColor -RGB $_.Value
        })

        # File extensions
        $ColorData.Types.Files.GetEnumerator().Where({$_.Name -ne 'WellKnown' -and $_.Name -ne ''}).ForEach({
            $cs.Types.Files[$_.Name] = ConvertFrom-RGBColor -RGB $_.Value
        })

        $cs
    }
}
function Get-ThemeStoragePath {
    [OutputType([string])]
    [CmdletBinding()]
    param()

    if ($IsLinux -or $IsMacOs) {
        if (-not ($basePath = $env:XDG_CONFIG_HOME)) {
            $basePath = [IO.Path]::Combine($HOME, '.local', 'share')
        }
    } else {
        if (-not ($basePath = $env:APPDATA)) {
            $basePath = [Environment]::GetFolderPath('ApplicationData')
        }
    }

    if ($basePath) {
        $storagePath = [IO.Path]::Combine($basePath, 'powershell', 'Community', 'Terminal-Icons')
        if (-not (Test-Path $storagePath)) {
            New-Item -Path $storagePath -ItemType Directory -Force > $null
        }
        $storagePath
    }
}
function Import-ColorTheme {
    [OutputType([hashtable])]
    [cmdletbinding()]
    param()

    $hash = @{}
    (Get-ChildItem -Path $moduleRoot/Data/colorThemes).ForEach({
        $colorData = Import-PowerShellDataFile $_.FullName
        $hash[$colorData.Name] = $colorData
        $hash[$colorData.Name].Types.Directories[''] = $colorReset
        $hash[$colorData.Name].Types.Files['']       = $colorReset
    })
    $hash
}
function Import-IconTheme {
    [OutputType([hashtable])]
    [cmdletbinding()]
    param()

    $hash = @{}
    (Get-ChildItem -Path $moduleRoot/Data/iconThemes).ForEach({
        $hash.Add($_.Basename, (Import-PowerShellDataFile $_.FullName))
    })
    $hash
}
function Import-Preferences {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([hashtable])]
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)]
        [string]$Path = (Join-Path (Get-ThemeStoragePath) 'prefs.xml'),

        [string]$DefaultThemeName = $script:defaultTheme
    )

    begin {
        $defaultPrefs = @{
            CurrentColorTheme = $DefaultThemeName
            CurrentIconTheme  = $DefaultThemeName
        }
    }

    process {
        if (Test-Path $Path) {
            try {
                Import-Clixml -Path $Path -ErrorAction Stop
            } catch {
                Write-Warning "Unable to parse [$Path]. Setting default preferences."
                $defaultPrefs
            }
        } else {
            $defaultPrefs
        }
    }
}
function New-EmptyColorTheme {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([hashtable])]
    [cmdletbinding()]
    param()

    @{
        Name = ''
        Types = @{
            Directories = @{
                #''        = "`e[0m"
                symlink  = ''
                junction = ''
                WellKnown = @{}
            }
            Files = @{
                #''        = "`e[0m"
                symlink  = ''
                junction = ''
                WellKnown = @{}
            }
        }
    }
}
function Resolve-Icon {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [IO.FileSystemInfo]$FileInfo,

        [string]$IconTheme = $script:userThemeData.CurrentIconTheme,

        [string]$ColorTheme = $script:userThemeData.CurrentColorTheme
    )

    begin {
        $icons  = $script:userThemeData.Themes.Icon[$IconTheme]
        $colors = $script:colorSequences[$ColorTheme]
    }

    process {
        $displayInfo = @{
            Icon     = $null
            Color    = $null
            Target   = ''
        }

        if ($FileInfo.PSIsContainer) {
            $type = 'Directories'
        } else {
            $type = 'Files'
        }

        switch ($FileInfo.LinkType) {
            # Determine symlink or junction icon and color
            'Junction' {
                if ($icons) {
                    $iconName = $icons.Types.($type)['junction']
                } else {
                    $iconName = $null
                }
                if ($colors) {
                    $colorSeq = $colors.Types.($type)['junction']
                } else {
                    $colorSet = $script:colorReset
                }
                $displayInfo['Target'] = ' ' + $glyphs['nf-mdi-arrow_right_thick'] + ' ' + $FileInfo.Target
                break
            }
            'SymbolicLink' {
                if ($icons) {
                    $iconName = $icons.Types.($type)['symlink']
                } else {
                    $iconName = $null
                }
                if ($colors) {
                    $colorSeq = $colors.Types.($type)['symlink']
                } else {
                    $colorSet = $script:colorReset
                }
                $displayInfo['Target'] = ' ' + $glyphs['nf-mdi-arrow_right_thick'] + ' ' + $FileInfo.Target
                break
            } default {
                if ($icons) {
                    # Determine normal directory icon and color
                    $iconName = $icons.Types.$type.WellKnown[$FileInfo.Name]
                    if (-not $iconName) {
                        if ($FileInfo.PSIsContainer) {
                            $iconName = $icons.Types.$type[$FileInfo.Name]
                        } elseif ($icons.Types.$type.ContainsKey($FileInfo.Extension)) {
                            $iconName = $icons.Types.$type[$FileInfo.Extension]
                        } else {
                            # File probably has multiple extensions
                            # Fallback to computing the full extension
                            $firstDot = $FileInfo.Name.IndexOf('.')
                            if ($firstDot -ne -1) {
                                $fullExtension = $FileInfo.Name.Substring($firstDot)
                                $iconName = $icons.Types.$type[$fullExtension]
                            }
                        }
                        if (-not $iconName) {
                            $iconName = $icons.Types.$type['']
                        }

                        # Fallback if everything has gone horribly wrong
                        if (-not $iconName) {
                            if ($FileInfo.PSIsContainer) {
                                $iconName = 'nf-oct-file_directory'
                            } else {
                                $iconName = 'nf-fa-file'
                            }
                        }
                    }
                } else {
                    $iconName = $null
                }
                if ($colors) {
                    $colorSeq = $colors.Types.$type.WellKnown[$FileInfo.Name]
                    if (-not $colorSeq) {
                        if ($FileInfo.PSIsContainer) {
                            $colorSeq = $colors.Types.$type[$FileInfo.Name]
                        } elseif ($colors.Types.$type.ContainsKey($FileInfo.Extension)) {
                            $colorSeq = $colors.Types.$type[$FileInfo.Extension]
                        } else {
                            # File probably has multiple extensions
                            # Fallback to computing the full extension
                            $firstDot = $FileInfo.Name.IndexOf('.')
                            if ($firstDot -ne -1) {
                                $fullExtension = $FileInfo.Name.Substring($firstDot)
                                $colorSeq = $colors.Types.$type[$fullExtension]
                            }
                        }
                        if (-not $colorSeq) {
                            $colorSeq = $colors.Types.$type['']
                        }

                        # Fallback if everything has gone horribly wrong
                        if (-not $colorSeq) {
                            $colorSeq = $script:colorReset
                        }
                    }
                } else {
                    $colorSeq = $script:colorReset
                }
            }
        }
        if ($iconName) {
            $displayInfo['Icon'] = $glyphs[$iconName]
        } else {
            $displayInfo['Icon'] = $null
        }
        $displayInfo['Color'] = $colorSeq
        $displayInfo
    }
}
function Save-Preferences {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [hashtable]$Preferences,

        [string]$Path = (Join-Path (Get-ThemeStoragePath) 'prefs.xml')
    )

    process {
        Write-Debug ('Saving preferendces to [{0}]' -f $Path)
        $Preferences | Export-CliXml -Path $Path -Force
    }
}
function Save-Theme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable]$Theme,

        [ValidateSet('color', 'icon')]
        [string]$Type,

        [string]$Path = (Get-ThemeStoragePath)
    )

    process {
        $themePath = Join-Path $Path "$($Theme.Name)_$($Type.ToLower()).xml"
        Write-Debug ('Saving [{0}] theme [{1}] to [{2}]' -f $type, $theme.Name, $themePath)
        $Theme | Export-CliXml -Path $themePath -Force
    }
}
function Set-Theme {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Name,

        [ValidateSet('Color', 'Icon')]
        [Parameter(Mandatory)]
        [string]$Type
    )

    if ([string]::IsNullOrEmpty($Name)) {
        $script:userThemeData."Current$($Type)Theme" = $null
        $script:prefs."Current$($Type)Theme" = ''
        Save-Preferences $script:prefs
    } else {
        if (-not $script:userThemeData.Themes.$Type.ContainsKey($Name)) {
            Write-Error "$Type theme [$Name] not found."
        } else {
            $script:userThemeData."Current$($Type)Theme" = $Name
            $script:prefs."Current$($Type)Theme" = $Name
            Save-Theme -Theme $userThemeData.Themes.$Type[$Name] -Type $type
            Save-Preferences $script:prefs
        }
    }
}
function Add-TerminalIconsColorTheme {
    <#
    .SYNOPSIS
        Add a Terminal-Icons color theme for the current user.
    .DESCRIPTION
        Add a Terminal-Icons color theme for the current user. The theme data
        is stored in the user's profile
    .PARAMETER Path
        The path to the Terminal-Icons color theme file.
    .PARAMETER LiteralPath
        The literal path to the Terminal-Icons color theme file.
    .PARAMETER Force
        Overwrite the color theme if it already exists in the profile.
    .EXAMPLE
        PS> Add-TerminalIconsColorTheme -Path ./my_color_theme.psd1

        Add the color theme contained in ./my_color_theme.psd1.
    .EXAMPLE
        PS> Get-ChildItem ./path/to/colorthemes | Add-TerminalIconsColorTheme -Force

        Add all color themes contained in the folder ./path/to/colorthemes and add them,
        overwriting existing ones if needed.
    .INPUTS
        System.String

        You can pipe a string that contains a path to 'Add-TerminalIconsColorTheme'.
    .OUTPUTS
        None.
    .NOTES
        'Add-TerminalIconsColorTheme' will not overwrite an existing theme by default.
        Add the -Force switch to overwrite.
    .LINK
        Add-TerminalIconsIconTheme
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification='Implemented in private function')]
    [CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath,

        [switch]$Force
    )

    process {
        Add-Theme @PSBoundParameters -Type Color
    }
}
function Add-TerminalIconsIconTheme {
    <#
    .SYNOPSIS
        Add a Terminal-Icons icon theme for the current user.
    .DESCRIPTION
        Add a Terminal-Icons icon theme for the current user. The theme data
        is stored in the user's profile
    .PARAMETER Path
        The path to the Terminal-Icons icon theme file.
    .PARAMETER LiteralPath
        The literal path to the Terminal-Icons icon theme file.
    .PARAMETER Force
        Overwrite the icon theme if it already exists in the profile.
    .EXAMPLE
        PS> Add-Terminal-IconsIconTHeme -Path ./my_icon_theme.psd1

        Add the icon theme contained in ./my_icon_theme.psd1.
    .EXAMPLE
        PS> Get-ChildItem ./path/to/iconthemes | Add-TerminalIconsIconTheme -Force

        Add all icon themes contained in the folder ./path/to/iconthemes and add them,
        overwriting existing ones if needed.
    .INPUTS
        System.String

        You can pipe a string that contains a path to 'Add-TerminalIconsIconTheme'.
    .OUTPUTS
        None.
    .NOTES
        'Add-TerminalIconsIconTheme' will not overwrite an existing theme by default.
        Add the -Force switch to overwrite.
    .LINK
        Add-TerminalIconsColorTheme
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification='Implemented in private function')]
    [CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath,

        [switch]$Force
    )

    process {
        Add-Theme @PSBoundParameters -Type Icon
    }
}
function Format-TerminalIcons {
    <#
    .SYNOPSIS
        Prepend a custom icon (with color) to the provided file or folder object when displayed.
    .DESCRIPTION
        Take the provided file or folder object and look up the appropriate icon and color to display.
    .PARAMETER FileInfo
        The file or folder to display
    .EXAMPLE
        Get-ChildItem

        List a directory. Terminal-Icons will be invoked automatically for display.
    .EXAMPLE
        Get-Item ./README.md | Format-TerminalIcons

        Get a file object and pass directly to Format-TerminalIcons.
    .INPUTS
        System.IO.FileSystemInfo

        You can pipe an objects that derive from System.IO.FileSystemInfo (System.IO.DIrectoryInfo and System.IO.FileInfo) to 'Format-TerminalIcons'.
    .OUTPUTS
        System.String

        Outputs a colorized string with an icon prepended.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [IO.FileSystemInfo]$FileInfo
    )

    process {
        $displayInfo = Resolve-Icon $FileInfo
        if ($displayInfo.Icon) {
            "$($displayInfo.Color)$($displayInfo.Icon)  $($FileInfo.Name)$($displayInfo.Target)$($script:colorReset)"
        } else {
            "$($displayInfo.Color)$($FileInfo.Name)$($displayInfo.Target)$($script:colorReset)"
        }
    }
}
function Get-TerminalIconsColorTheme {
    <#
    .SYNOPSIS
        List the available color themes.
    .DESCRIPTION
        List the available color themes.
    .Example
        PS> Get-TerminalIconsColorTheme

        Get the list of available color themes.
    .INPUTS
        None.
    .OUTPUTS
        System.Collections.Hashtable

        An array of hashtables representing available color themes.
    .LINK
        Get-TerminalIconsIconTheme
    .LINK
        Get-TerminalIconsTheme
    #>
    $script:userThemeData.Themes.Color
}
function Get-TerminalIconsGlyphs {
    <#
    .SYNOPSIS
        Gets the list of glyphs known to Terminal-Icons.
    .DESCRIPTION
        Gets a hashtable with the available glyph names and icons. Useful in creating a custom theme.
    .EXAMPLE
        PS> Get-TerminalIconsGlyphs

        Gets the table of glyph names and icons.
    .INPUTS
        None.
    .OUTPUTS
        None.
    .LINK
        Get-TerminalIconsIconTheme
    .LINK
        Set-TerminalIconsIcon
    #>
    [cmdletbinding()]
    param()

    # This is also helpful for argument completers needing glyphs -
    # ArgumentCompleterAttribute isn't able to access script variables but it
    # CAN call commands.
    $script:glyphs.GetEnumerator() | Sort-Object Name
}
function Get-TerminalIconsIconTheme {
    <#
    .SYNOPSIS
        List the available icon themes.
    .DESCRIPTION
        List the available icon themes.
    .Example
        PS> Get-TerminalIconsIconTheme

        Get the list of available icon themes.
    .INPUTS
        None.
    .OUTPUTS
        System.Collections.Hashtable

        An array of hashtables representing available icon themes.
    .LINK
        Get-TerminalIconsColorTheme
    .LINK
        Get-TerminalIconsTheme
    #>
    $script:userThemeData.Themes.Icon
}
function Get-TerminalIconsTheme {
    <#
    .SYNOPSIS
        Get the currently applied color and icon theme.
    .DESCRIPTION
        Get the currently applied color and icon theme.
    .EXAMPLE
        PS> Get-TerminalIconsTheme

        Get the currently applied Terminal-Icons color and icon theme.
    .INPUTS
        None.
    .OUTPUTS
        System.Management.Automation.PSCustomObject

        An object representing the currently applied color and icon theme.
    .LINK
        Get-TerminalIconsColorTheme
    .LINK
        Get-TerminalIconsIconTheme
    #>
    [CmdletBinding()]
    param()

    $iconTheme = if ($script:userThemeData.CurrentIconTheme) {
        [pscustomobject]$script:userThemeData.Themes.Icon[$script:userThemeData.CurrentIconTheme]
    } else {
        $null
    }

    $colorTheme = if ($script:userThemeData.CurrentColorTheme) {
        [pscustomobject]$script:userThemeData.Themes.Color[$script:userThemeData.CurrentColorTheme]
    } else {
        $null
    }

    [pscustomobject]@{
        PSTypeName = 'TerminalIconsTheme'
        Color      = $colorTheme
        Icon       = $iconTheme
    }
}
function Remove-TerminalIconsTheme {
    <#
    .SYNOPSIS
        Removes a color or icon theme
    .DESCRIPTION
        Removes a given icon or color theme. In order to be removed, a theme must not be active.
    .PARAMETER IconTheme
        The icon theme to remove.
    .PARAMETER ColorTheme
        The color theme to remove.
    .PARAMETER Force
        Bypass confirmation messages.
    .EXAMPLE
        PS> Remove-TerminalIconsTheme -IconTheme MyAwesomeTheme

        Removes the icon theme 'MyAwesomeTheme'
    .EXAMPLE
        PS> Remove-TerminalIconsTheme -ColorTheme MyAwesomeTheme

        Removes the color theme 'MyAwesomeTheme'
    .INPUTS
        System.String

        The name of the color or icon theme to remove.
    .OUTPUTS
        None.
    .LINK
        Set-TerminalIconsTheme
    .LINK
        Add-TerminalIconsColorTheme
    .LINK
        Add-TerminalIconsIconTheme
    .LINK
        Get-TerminalIconsTheme
    .NOTES
        A theme must not be active in order to be removed.
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [ArgumentCompleter({
            (Get-TerminalIconsIconTheme).Keys | Sort-Object
        })]
        [string]$IconTheme,

        [ArgumentCompleter({
            (Get-TerminalIconsColorTheme).Keys | Sort-Object
        })]
        [string]$ColorTheme,

        [switch]$Force
    )

    $currentTheme     = Get-TerminalIconsTheme
    $themeStoragePath = Get-ThemeStoragePath

    if ($ColorTheme) {
        if ($currentTheme.Color.Name -ne $ColorTheme) {
            $themePath = Join-Path $themeStoragePath "$($ColorTheme)_color.xml"
            if (-not (Test-Path $themePath)) {
                Write-Error "Could not find theme file [$themePath]"
            } else {
                if ($Force -or $PSCmdlet.ShouldProcess($ColorTheme, 'Remove color theme')) {
                    if ($userThemeData.Themes.Color.ContainsKey($ColorTheme)) {
                        $userThemeData.Themes.Color.Remove($ColorTheme)
                    } else {
                        # We shouldn't be here
                        Write-Error "Color theme [$ColorTheme] is not registered."
                    }
                    Remove-Item $themePath -Force
                }
            }
        } else {
            Write-Error ("Color theme [{0}] is active. Please select another theme before removing this it." -f $ColorTheme)
        }
    }

    if ($IconTheme) {
        if ($currentTheme.Icon.Name -ne $IconTheme) {
            $themePath = Join-Path $themeStoragePath "$($IconTheme)_icon.xml"
            if (-not (Test-Path $themePath)) {
                Write-Error "Could not find theme file [$themePath]"
            } else {
                if ($Force -or $PSCmdlet.ShouldProcess($ColorTheme, 'Remove icon theme')) {
                    if ($userThemeData.Themes.Icon.ContainsKey($IconTheme)) {
                        $userThemeData.Themes.Icon.Remove($IconTheme)
                    } else {
                        # We shouldn't be here
                        Write-Error "Icon theme [$IconTheme] is not registered."
                    }
                    Remove-Item $themePath -Force
                }
            }
        } else {
            Write-Error ("Icon theme [{0}] is active. Please select another theme before removing this it." -f $IconTheme)
        }
    }
}
function Set-TerminalIconsIcon {
    <#
    .SYNOPSIS
        Set a specific icon in the current Terminal-Icons icon theme or allows
        swapping one glyph for another.
    .DESCRIPTION
        Set the Terminal-Icons icon for a specific file/directory or glyph to a
        named glyph.

        Also allows all uses of a specific glyph to be replaced with a different
        glyph.
    .PARAMETER Directory
        The well-known directory name to match for the icon.
    .PARAMETER FileName
        The well-known file name to match for the icon.
    .PARAMETER FileExtension
        The file extension to match for the icon.
    .PARAMETER NewGlyph
        The name of the new glyph to use when swapping.
    .PARAMETER Glyph
        The name of the glyph to use; or, when swapping glyphs, the name of the
        glyph you want to change.
    .PARAMETER Force
        Bypass confirmation messages.
    .EXAMPLE
        PS> Set-TerminalIconsIcon -FileName "README.md" -Glyph "nf-fa-file_text"

        Set README.md files to display a text file icon.
    .EXAMPLE
        PS> Set-TerminalIconsIcon -FileExtension ".xml" -Glyph "nf-mdi-file_xml"

        Set XML files to display an XML file icon.
    .EXAMPLE
        PS> Set-TerminalIconsIcon -Directory ".github" -Glyph "nf-mdi-github_face"

        Set directories named ".github" to display an Octocat face icon.
    .EXAMPLE
        PS> Set-TerminalIconsIcon -Glyph "nf-mdi-xml" -NewGlyph "nf-mdi-file_xml"

        Changes all uses of the "nf-mdi-xml" double-wide glyph to be the "nf-mdi-file_xml"
        single-width XML file glyph.
    .INPUTS
        None.

        The command does not accept pipeline input.
    .OUTPUTS
        None.
    .LINK
        Get-TerminalIconsIconTheme
    .LINK
        Get-TerminalIconsTheme
    .LINK
        Get-TerminalIconsGlyphs
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = "ArgumentCompleter parameters don't all get used.")]
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "FileExtension")]
    param(
        [Parameter(ParameterSetName = "Directory", Mandatory)]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                (Get-TerminalIconsIconTheme).Values.Types.Directories.WellKnown.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object
            })]
        [ValidateNotNullOrEmpty()]
        [string]$Directory,

        [Parameter(ParameterSetName = "FileName", Mandatory)]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                (Get-TerminalIconsIconTheme).Values.Types.Files.WellKnown.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object
            })]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(ParameterSetName = "FileExtension", Mandatory)]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                (Get-TerminalIconsIconTheme).Values.Types.Files.Keys | Where-Object { $_.StartsWith(".") -and $_ -like "$wordToComplete*" } | Sort-Object
            })]
        [ValidatePattern("^\.")]
        [string]$FileExtension,

        [Parameter(ParameterSetName = "SwapGlyph", Mandatory)]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                (Get-TerminalIconsGlyphs).Keys | Where-Object { $_ -like "*$wordToComplete*" } | Sort-Object
            })]
        [ValidateNotNullOrEmpty()]
        [string]$NewGlyph,

        [Parameter(Mandatory)]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                (Get-TerminalIconsGlyphs).Keys | Where-Object { $_ -like "*$wordToComplete*" } | Sort-Object
            })]
        [ValidateNotNullOrEmpty()]
        [string]$Glyph,

        [switch]$Force
    )

    If($PSCmdlet.ParameterSetName -eq "Directory") {
        If ($Force -or $PSCmdlet.ShouldProcess("$Directory = $Glyph", 'Set well-known directory icon')) {
            (Get-TerminalIconsIconTheme).Values.Types.Directories.WellKnown[$Directory] = $Glyph
        }
    }
    ElseIf ($PSCmdlet.ParameterSetName -eq "FileName") {
        If ($Force -or $PSCmdlet.ShouldProcess("$FileName = $Glyph", 'Set well-known file name icon')) {
            (Get-TerminalIconsIconTheme).Values.Types.Files.WellKnown[$FileName] = $Glyph
        }
    }
    ElseIf ($PSCmdlet.ParameterSetName -eq "FileExtension") {
        If ($Force -or $PSCmdlet.ShouldProcess("$FileExtension = $Glyph", 'Set file extension icon')) {
            (Get-TerminalIconsIconTheme).Values.Types.Files[$FileExtension] = $Glyph
        }
    }
    ElseIf ($PSCmdlet.ParameterSetName -eq "SwapGlyph") {
        If ($Force -or $PSCmdlet.ShouldProcess("$Glyph to $NewGlyph", 'Swap glyph usage')) {
            # Directories
            $toModify = (Get-TerminalIconsTheme).Icon.Types.Directories.WellKnown
            $keys = $toModify.Keys | Where-Object { $toModify[$_] -eq $Glyph }
            $keys | ForEach-Object { $toModify[$_] = $NewGlyph }

            # Files
            $toModify = (Get-TerminalIconsTheme).Icon.Types.Files.WellKnown
            $keys = $toModify.Keys | Where-Object { $toModify[$_] -eq $Glyph }
            $keys | ForEach-Object { $toModify[$_] = $NewGlyph }

            # Extensions
            $toModify = (Get-TerminalIconsTheme).Icon.Types.Files
            $keys = $toModify.Keys | Where-Object { $_.StartsWith(".") -and $toModify[$_] -eq $Glyph }
            $keys | ForEach-Object { $toModify[$_] = $NewGlyph }
        }
    }
}
function Set-TerminalIconsTheme {
    <#
    .SYNOPSIS
        Set the Terminal-Icons color or icon theme
    .DESCRIPTION
        Set the Terminal-Icons color or icon theme to the given name.
    .PARAMETER ColorTheme
        The name of a registered color theme to use.
    .PARAMETER IconTheme
        The name of a registered icon theme to use.
    .PARAMETER DisableColorTheme
        Disables custom colors and uses default terminal color.
    .PARAMETER DisableIconTheme
        Disables custom icons and shows only shows the directory or file name.
    .PARAMETER Force
        Bypass confirmation messages.
    .EXAMPLE
        PS> Set-TerminalIconsTheme -ColorTheme devblackops

        Set the color theme to 'devblackops'.
    .EXAMPLE
        PS> Set-TerminalIconsTheme -IconTheme devblackops

        Set the icon theme to 'devblackops'.
    .EXAMPLE
        PS> Set-TerminalIconsTheme -DisableIconTheme

        Disable Terminal-Icons custom icons and only show custom colors.
    .EXAMPLE
        PS> Set-TerminalIconsTheme -DisableColorTheme

        Disable Terminal-Icons custom colors and only show custom icons.
    .INPUTS
        System.String

        The name of the color or icon theme to use.
    .OUTPUTS
        None.
    .LINK
        Get-TerminalIconsColorTheme
    .LINK
        Get-TerminalIconsIconTheme
    .LINK
        Get-TerminalIconsTheme
    .NOTES
        This function supercedes Set-TerminalIconsColorTheme and Set-TerminalIconsIconTheme. They have been deprecated.
    #>
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = 'theme')]
    param(
        [Parameter(ParameterSetName = 'theme')]
        [ArgumentCompleter({
            (Get-TerminalIconsIconTheme).Keys | Sort-Object
        })]
        [string]$IconTheme,

        [Parameter(ParameterSetName = 'theme')]
        [ArgumentCompleter({
            (Get-TerminalIconsColorTheme).Keys | Sort-Object
        })]
        [string]$ColorTheme,

        [Parameter(ParameterSetName = 'notheme')]
        [switch]$DisableColorTheme,

        [Parameter(ParameterSetName = 'notheme')]
        [switch]$DisableIconTheme,

        [switch]$Force
    )

    if ($DisableIconTheme.IsPresent) {
        Set-Theme -Name $null -Type Icon
    }

    if ($DisableColorTheme.IsPresent) {
        Set-Theme -Name $null -Type Color
    }

    if ($ColorTheme) {
        if ($Force -or $PSCmdlet.ShouldProcess($ColorTheme, 'Set color theme')) {
            Set-Theme -Name $ColorTheme -Type Color
        }
    }

    if ($IconTheme) {
        if ($Force -or $PSCmdlet.ShouldProcess($IconTheme, 'Set icon theme')) {
            Set-Theme -Name $IconTheme -Type Icon
        }
    }
}

function Show-TerminalIconsTheme {
    <#
    .SYNOPSIS
        List example directories and files to show the currently applied color and icon themes.
    .DESCRIPTION
        List example directories and files to show the currently applied color and icon themes.
        The directory/file objects show are in memory only, they are not written to the filesystem.
    .PARAMETER ColorTheme
        The color theme to use for examples
    .PARAMETER IconTheme
        The icon theme to use for examples
    .EXAMPLE
        Show-TerminalIconsTheme

        List example directories and files to show the currently applied color and icon themes.
    .INPUTS
        None.
    .OUTPUTS
        System.IO.DirectoryInfo
    .OUTPUTS
        System.IO.FileInfo
    .NOTES
        Example directory and file objects only exist in memory. They are not written to the filesystem.
    .LINK
        Get-TerminalIconsColorTheme
    .LINK
        Get-TerminalIconsIconTheme
    .LINK
        Get-TerminalIconsTheme
    #>
    [CmdletBinding()]
    param()

    $theme = Get-TerminalIconsTheme

    # Use the default theme if the icon theme has been disabled
    if ($theme.Icon) {
        $themeName = $theme.Icon.Name
    } else {
        $themeName = $script:defaultTheme
    }

    $directories = @(
        [IO.DirectoryInfo]::new('ExampleFolder')
        $script:userThemeData.Themes.Icon[$themeName].Types.Directories.WellKnown.Keys.ForEach({
            [IO.DirectoryInfo]::new($_)
        })
    )
    $wellKnownFiles = @(
        [IO.FileInfo]::new('ExampleFile')
        $script:userThemeData.Themes.Icon[$themeName].Types.Files.WellKnown.Keys.ForEach({
            [IO.FileInfo]::new($_)
        })
    )

    $extensions = $script:userThemeData.Themes.Icon[$themeName].Types.Files.Keys.Where({$_ -ne 'WellKnown'}).ForEach({
        [IO.FileInfo]::new("example$_")
    })

    $directories + $wellKnownFiles + $extensions | Sort-Object | Format-TerminalIcons
}
# Dot source public/private functions
# $public  = @(Get-ChildItem -Path ([IO.Path]::Combine($PSScriptRoot, 'Public/*.ps1'))  -Recurse -ErrorAction Stop)
# $private = @(Get-ChildItem -Path ([IO.Path]::Combine($PSScriptRoot, 'Private/*.ps1')) -Recurse -ErrorAction Stop)
# @($public + $private).ForEach({
#     try {
#         . $_.FullName
#     } catch {
#         throw $_
#         $PSCmdlet.ThrowTerminatingError("Unable to dot source [$($import.FullName)]")
#     }
# })

$moduleRoot    = $PSScriptRoot
$glyphs        = . $moduleRoot/Data/glyphs.ps1
$escape        = [char]27
$colorReset    = "${escape}[0m"
$defaultTheme  = 'devblackops'
$userThemePath = Get-ThemeStoragePath
$userThemeData = @{
    CurrentIconTheme  = $null
    CurrentColorTheme = $null
    Themes = @{
        Color = @{}
        Icon  = @{}
    }
}

# Import builtin icon/color themes and convert colors to escape sequences
$colorSequences = @{}
$iconThemes     = Import-IconTheme
$colorThemes    = Import-ColorTheme
$colorThemes.GetEnumerator().ForEach({
    $colorSequences[$_.Name] = ConvertTo-ColorSequence -ColorData $_.Value
})

# Load or create default prefs
$prefs = Import-Preferences

# Set current theme
$userThemeData.CurrentIconTheme  = $prefs.CurrentIconTheme
$userThemeData.CurrentColorTheme = $prefs.CurrentColorTheme

# Load user icon and color themes
# We're ignoring the old 'theme.xml' from Terimal-Icons v0.3.1 and earlier
(Get-ChildItem $userThemePath -Filter '*_icon.xml').ForEach({
    $userIconTheme = Import-CliXml -Path $_.FullName
    $userThemeData.Themes.Icon[$userIconTheme.Name] = $userIconTheme
})
(Get-ChildItem $userThemePath -Filter '*_color.xml').ForEach({
    $userColorTheme = Import-CliXml -Path $_.FullName
    $userThemeData.Themes.Color[$userColorTheme.Name] = $userColorTheme
    $colorSequences[$userColorTheme.Name] = ConvertTo-ColorSequence -ColorData $userThemeData.Themes.Color[$userColorTheme.Name]
})

# Update the builtin themes
$colorThemes.GetEnumerator().ForEach({
    $userThemeData.Themes.Color[$_.Name] = $_.Value
})
$iconThemes.GetEnumerator().ForEach({
    $userThemeData.Themes.Icon[$_.Name] = $_.Value
})

# Save all themes to theme path
$userThemeData.Themes.Color.GetEnumerator().ForEach({
    $colorThemePath = Join-Path $userThemePath "$($_.Name)_color.xml"
    $_.Value | Export-Clixml -Path $colorThemePath -Force
})
$userThemeData.Themes.Icon.GetEnumerator().ForEach({
    $iconThemePath = Join-Path $userThemePath "$($_.Name)_icon.xml"
    $_.Value | Export-Clixml -Path $iconThemePath -Force
})

Save-Preferences -Preferences $prefs

# Export-ModuleMember -Function $public.Basename

Update-FormatData -Prepend ([IO.Path]::Combine($moduleRoot, 'Terminal-Icons.format.ps1xml'))

