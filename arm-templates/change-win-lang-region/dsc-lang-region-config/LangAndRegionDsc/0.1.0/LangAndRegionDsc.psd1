@{
# Version number of this module.
moduleVersion = '0.1.0'

# ID used to uniquely identify this module
GUID = 'c4394742-a225-4dc2-89f0-daa33e0f766e'

# Author of this module
Author = 'Takeshi Katano'

# Company or vendor of this module
CompanyName = 'Takeshi Katano'

# Copyright statement for this module
Copyright = 'Copyright Takeshi Katano. All rights reserved.'

# Description of the functionality provided by this module
Description = ''

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = @()

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# Dsc Resources to export from this module
DscResourcesToExport = @(
    'InternationalSettings'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/tksh164/azure-demo-scripts-templates/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/tksh164/azure-demo-scripts-templates'

        # A URL to an icon representing this module.
        IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = ''

        # Set to a prerelease string value if the release should be a prerelease.
        Prerelease = ''

        } # End of PSData hashtable
} # End of PrivateData hashtable
}
