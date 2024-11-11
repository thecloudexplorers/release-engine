#Requires -PSEdition Core

<#
    .SYNOPSIS
    Replaces tokens in a target file with corresponding values from a
    metadata collection.

    .DESCRIPTION
    This function reads a target file and replaces tokens, defined by
    start and end token patterns, with values from a provided metadata
    collection. If a custom output file path is specified, the processed
    file is saved there; otherwise, the original file is overwritten.

    .PARAMETER MetadataCollection
    A hashtable containing metadata key-value pairs used to replace
    tokens in the target file.

    .PARAMETER TargetFilePath
    The path to the file where tokens need to be replaced.

    .PARAMETER CustomOutputFilePath
    An optional parameter specifying the path to save the processed
    file. If not specified, the original file will be overwritten.

    .PARAMETER StartTokenPattern
    The pattern indicating the start of a token in the target file.

    .PARAMETER EndTokenPattern
    The pattern indicating the end of a token in the target file.

    .EXAMPLE
    $convertTokensParams = @{
        MetadataCollection    = @{
            "Token1" = "Value1"
            "Token2" = "Value2"
        }
        TargetFilePath        = "C:\path\to\file.txt"
        CustomOutputFilePath  = "C:\path\to\output\file.txt" # Optional
        StartTokenPattern     = "{{"
        EndTokenPattern       = "}}"
    }
    Convert-TokensToValues @convertTokensParams

    .NOTES
    Version     : 1.1.0
    Author      : Jev - @devjevnl | https://www.devjev.nl
    Source      : https://github.com/thecloudexplorers/simply-scripted
#>
function Convert-TokensToValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $MetadataCollection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $TargetFilePath,

        [ValidateNotNullOrEmpty()]
        [System.String] $CustomOutputFilePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $StartTokenPattern,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $EndTokenPattern
    )

    try {
        $targetFile = Get-Item -Path $TargetFilePath
        Write-Host "##[group]Replacing tokens in file [$($targetFile.Name)]"
        $targetFileContent = Get-Content -Path $TargetFilePath -Raw

        # Loop trough all keys to check if they match with possible tokens in the current line
        $MetadataCollection.Keys.ForEach{
            $currentMetadataKey = $_
            $constructedToken = "{0}{1}{2}" -f $StartTokenPattern, $currentMetadataKey, $EndTokenPattern

            # If a match is found replace the token with the value of the hashtable
            if ($targetFileContent -match $constructedToken) {
                $value = $MetadataCollection[$currentMetadataKey]
                Write-Host "  ##[command]$currentMetadataKey=$value"
                $targetFileContent = $targetFileContent.Replace($constructedToken, $value)
            }
        }
        Write-Host "##[endgroup]"


        # Verify if all tokens have been replaced
        if ($targetFileContent.Contains($StartTokenPattern) -or $targetFileContent.Contains($EndTokenPattern)) {
            # Create a regex pattern from the StartTokenPattern
            foreach ($char in $StartTokenPattern.ToCharArray()) {
                # Add a backslash followed by the character to the output string
                $startTokenPatternOutput += "\" + $char
            }

            $regExLeft = [regex] $startTokenPatternOutput
            $matchForLeft = $targetFileContent | Select-String -Pattern $regExLeft -AllMatches

            # Create a regex pattern for the EndTokenPattern
            foreach ($char in $EndTokenPattern.ToCharArray()) {
                # Add a backslash followed by the character to the output string
                $endTokenPatternOutput += "\" + $char
            }

            $regExRight = [regex] $endTokenPatternOutput
            $matchForRight = $targetFileContent | Select-String -Pattern $regExRight -AllMatches

            # Check for tokens which are missing an start or an end pattern, meaning they are not closed
            if ($matchForLeft.Matches.Count -ne $matchForRight.Matches.Count) {
                if ($matchForLeft.Matches.Count -gt $matchForRight.Matches.Count) {

                    $missingEndTokenIndex = $matchForLeft.Matches.Index -join ', '
                    Write-Warning "  One or more closing tokens [$EndTokenPattern] are missing!"
                    Write-Warning "  Character index locations of the placeholder values with missing tokens: $missingEndTokenIndex"
                }
                elseif ($matchForLeft.Matches.Count -lt $matchForRight.Matches.Count) {

                    $missingStartTokenIndex = $matchForRight.Matches.Index -join ', '
                    Write-Host "  One or more open tokens [$StartTokenPattern] are missing!"
                    Write-Host "  Character index locations of the placeholder values with missing tokens: $missingStartTokenIndex"
                }
            }
            else {
                # Not all tokens have been replaces, show a warning

                # Create a regex pattern for the tokens based on the StartTokenPattern and EndTokenPattern
                $formattedRegEx = "{0}(.+?){1}" -f $startTokenPatternOutput, $endTokenPatternOutput
                $regEx = [regex] $formattedRegEx

                $matchInfo = $targetFileContent | Select-String -Pattern $regEx -AllMatches

                # Get the unique match values
                $matchValues = $matchInfo | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Get-Unique

                # Create a string from the match values
                $warningValues = $matchValues -join ', '

                Write-Warning "  Unreplaced tokens detected, make sure the MetadataCollection parameter contains all tokens"
                Write-Warning "  Unreplaced tokens: $warningValues"
            }
        }

        # If the CustomOutputFilePath parameter has not been provided the original file will be replaced
        if ($CustomOutputFilePath.Length -eq 0) {
            $outputFilePath = $TargetFilePath
            Write-Debug -Message "  Custom output filepath is empty, overwriting original file"
        }
        else {
            $outputFilePath = $CustomOutputFilePath
            Write-Debug -Message "  Custom output filepath is [$CustomOutputFilePath], original file will remain intact"
        }

        # save file to disk, since filetype is json UTF8 encoding is applied
        $targetFileContent | Out-File -FilePath $outputFilePath -Encoding UTF8
        Write-Host " All tokens have been processed"

    }
    catch {
        Write-Error "An unexpected error with the following message occurred while converting tokens to values"
        Write-Error "Exception message: [$($_.Exception.Message)]" -ErrorAction Stop
    }
}
