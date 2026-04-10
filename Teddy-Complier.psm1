##### START FILE #####

# NAME: Teddy-Complier.psm1

### START SCRIPT ###

Start-Transcript -Path "./logs/import.log" -IncludeInvocationHeader

Write-Verbose "[ ] - Initializing module 'Teddy-Complier'..."

# Root Directory
$ModulePath = $PSScriptRoot

# Global Settings
$config = @{
    # Directory Mapping
    DefaultSettingsPath = Join-Path -Path $ModulePath -ChildPath "config/default.settings.json"
    UserSettingsPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Teddy-Complier/config/user.settings.json"
    UserSettingsROOTPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Teddy-Complier/config"
    # Initialize Settings Objects
    DefaultSettings = @{}
    UserSettings = @{}
}

# Load Default Settings
if (Test-Path -Path $config.DefaultSettingsPath) {
    try {
        Write-Verbose "[ ] - Loading default settings from '$($config.DefaultSettingsPath)'..."
        $config.DefaultSettings = Get-Content -Path $config.DefaultSettingsPath -Raw | ConvertFrom-Json
        Write-Verbose "[#] - Loaded default settings from '$($config.DefaultSettingsPath)'."
        Write-Debug "DEBUG: Loaded default settings from '$($config.DefaultSettingsPath)'. VAR:config.DefaultSettings = '$($config.DefaultSettings)'."
    } catch {
        ####Write-Error "[X] - Failed to load default settings from '$($config.DefaultSettingsPath)'. Error: $_"
        throw [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]"CRITICAL: Failed to load default settings from '$($config.DefaultSettingsPath)'. 'Teddy-Complier' PowerShell module cannot load.",
            "ST_DefaultSettingsLoadFailure", # Error_Codes.md
            [System.Management.Automation.ErrorCategory]::InvalidData,
            $config.DefaultSettingsPath
        )
    }
} else {
    ###########Write-Error "[X] - Failed to find default settings from '$($config.DefaultSettingsPath)'. Error: $_"
    throw [System.Management.Automation.ErrorRecord]::new(
        [System.Exception]"CRITICAL: Failed to find default settings from '$($config.DefaultSettingsPath)'. 'Teddy-Complier' PowerShell module cannot load.",
        "ST_DefaultSettingsFindFailure", # Error_Codes.md
        [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
        $config.DefaultSettingsPath
    )
}

# Load User Settings
if (Test-Path -Path $config.UserSettingsPath) {
    try {
        Write-Verbose "[ ] - Loading user settings from '$($config.UserSettingsPath)'..."
        $userContent = Get-Content -Path $config.UserSettingsPath -Raw | ConvertFrom-Json
        if ($null -ne $userContent) {
            $config.UserSettings = $userContent
            Write-Verbose "[#] - Loaded user settings from '$($config.UserSettingsPath)'."
            Write-Debug "DEBUG: Loaded user settings from '$($config.UserSettingsPath)'. VAR:config.UserSetttings = '$($config.UserSettings)'."
        } else {
            Write-Verbose "[i] - No user settings found from '$($config.UserSettingsPath)'."
        }
    } catch {
        Write-Warning "[X] - Failed to load user settings from '$($config.UserSettingsPath)'."
    }
} else {
    Write-Verbose "[i] - Failed to find user settings from '$($config.UserSettingsPath)'."
    New-Item -ItemType Directory -Path $config.UserSettingsROOTPath -Force -ErrorAction SilentlyContinue
    try {
        Copy-Item -Path $config.DefaultSettingsPath -Destination $config.UserSettingsPath -Force -ErrorAction Stop
        Write-Verbose "[#] - Created user settings at '$($config.UserSettingsPath)'."
    } catch {
        #########Write-Error "Failed to create user settings at '$($config.UserSettingsPath)'. Error: $_"
        throw [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]"CRITICAL: Failed to create user settings at '$($config.DefaultSettingsPath)'. 'Teddy-Complier' PowerShell module cannot load.",
            "TC_UserSettingsCreateFailure", # Error_Codes.md
            [System.Management.Automation.ErrorCategory]::PermissionDenied,
            $config.UserSettingsPath
        )
    }
}

# Merge Settings
$script:STSettings = $config.DefaultSettings.psobject.Copy() # Copies Default Settings
foreach ($key in $config.UserSettings.Keys) {
    Write-Verbose "[ ] - Applying settings..."
    $script:STSettings[$key] = $config.UserSettings[$key]
}
Write-Verbose "[#] - Loaded settings."

# Function Directories
$publicPath = Join-Path -Path $ModulePath -ChildPath "Public"
$privatePath = Join-Path -Path $ModulePath -ChildPath "Private"

# Load Private Functions (FIRST)
$privateFunc = Get-ChildItem -Path $privatePath -Filter "*.ps1" -ErrorAction SilentlyContinue
if ($privateFunc) {
    Write-Verbose "[ ] - Loading private functions from '$privatePath'..."
    foreach ($funcFile in $privateFunc) {
        try {
            . $funcFile.FullName
            Write-Debug "DEBUG: Loaded private function from '$privatePath'. FUNC: '$($funcFile.FullName)'."
        } catch {
            Write-Error "[X] - Failed to load private function from '$privatePath'. FUNC: '$($funcFile.FullName)'. Error: $_"
        }
    }
    Write-Verbose "[#] - Loaded private functions from '$privatePath'."
}

# Load and Export Public Functions (SECOND)
$publicFunc = Get-ChildItem -Path $publicPath -Filter "*.ps1" -ErrorAction SilentlyContinue
$exportFunc = @() # Initialize Export List
if ($publicFunc) {
    Write-Verbose "[ ] - Loading public functions from '$publicPath'."
    foreach ($funcFile in $publicFunc) {
        try {
            . $funcFile.FullName
            $exportFunc += $funcFile.BaseName
            Write-Debug "DEBUG: Loaded public function from '$publicPath'. FUNC: '$($funcFile.FullName)'."
        } catch {
            Write-Error "[X] - Failed to load public function from '$publicPath'. FUNC: '$($funcFile.FullName)'. Error: $_"
        }
    }
    Write-Verbose "[#] - Loaded public functions from '$publicPath'."
} else {
    Write-Warning "[!] - Failed to find public functions from '$publicPath'."
}

# Module Export
if ($exportFunc.Count -gt 0) {
    Write-Verbose "[ ] - Exporting public functions..."
    Write-Debug "DEBUG: Exporting public functions. VAR: exportFunc = '$exportFunc'."
    foreach ($func in $exportFunc) {
        Export-ModuleMember -Function $func
    }
    Write-Verbose "[#] - Exported public functions."
} else {
    Write-Warning "[!] - Failed to find public functions to export."
}

# Complete 
Write-Verbose "[#] - Initialized module 'Teddy-Complier'."

### END SCRIPT ###

##### END FILE #####
