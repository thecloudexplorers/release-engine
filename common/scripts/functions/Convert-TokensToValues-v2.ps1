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
        Write-Host "##[group]Replacing tokens in file [$($targetFile.Name)]" -ForegroundColor Cyan
        $targetFileContent = Get-Content -Path $TargetFilePath -Raw

        # Extract all tokens from the content using regex
        $escapedStart = [Regex]::Escape($StartTokenPattern)
        $escapedEnd = [Regex]::Escape($EndTokenPattern)
        $tokenRegex = "{0}(.*?){1}" -f $escapedStart, $escapedEnd
        $matchingTokens = [regex]::Matches($targetFileContent, $tokenRegex)

        $unmatchedTokens = @()

        foreach ($match in $matchingTokens) {
            $token = $match.Groups[1].Value

            # Check in MetadataCollection
            if ($MetadataCollection.ContainsKey($token)) {
                $value = $MetadataCollection[$token]
                Write-Host "##[command][metadata]$token=$value" -ForegroundColor Green
                $targetFileContent = $targetFileContent.Replace($match.Value, $value)
            }
            elseif ([Environment]::GetEnvironmentVariable($token)) {
                # Check in environment variables
                $value = [Environment]::GetEnvironmentVariable($token)
                Write-Host "##[command][envvar]$token=$value" -ForegroundColor Green
                $targetFileContent = $targetFileContent.Replace($match.Value, $value)
            }
            else {
                Write-Warning "Unmatched token: $($match.Value)"
                $unmatchedTokens += $match.Value
            }
        }

        Write-Host "##[endgroup]" -ForegroundColor Cyan

        # Log summary of unmatched tokens
        if ($unmatchedTokens.Count -gt 0) {            
            Write-Warning "##vso[task.logissue type=error]Unreplaced tokens detected in the file. Ensure MetadataCollection or environment variables contains matching values."
            Write-Host "##[error]Unreplaced tokens:" -ForegroundColor Yellow
            $unmatchedTokens | ForEach-Object { Write-Host "##[error]$_" -ForegroundColor Yellow }
            exit 1
        }

        # If the CustomOutputFilePath parameter has not been provided the original file will be replaced
        $outputFilePath = if ($CustomOutputFilePath) {
            $CustomOutputFilePath
        }
        else {
            $TargetFilePath
        }

        # Save file to disk, since filetype is JSON UTF8 encoding is applied
        $targetFileContent | Out-File -FilePath $outputFilePath -Encoding UTF8
        Write-Host "All tokens have been processed" -ForegroundColor Green

    }
    catch {
        Write-Error "##[error]An unexpected error occurred while converting tokens to values."
        Write-Error "##[error]Exception message: [$($_.Exception.Message)]" -ErrorAction Stop
    }
}
