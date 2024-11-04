param (
    [Parameter()]
    [string]$Directory
)

# Get all environment variables
Get-ChildItem -Path $Directory

