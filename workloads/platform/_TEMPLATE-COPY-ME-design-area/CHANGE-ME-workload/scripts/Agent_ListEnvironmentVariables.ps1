# Get all environment variables
$envVars = Get-ChildItem -Path Env:

# Display the environment variables
foreach ($envVar in $envVars) {
    Write-Output "$($envVar.Name) = $($envVar.Value)"
}
