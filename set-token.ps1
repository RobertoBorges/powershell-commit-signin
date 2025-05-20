# This script sets a GitHub token for the current session
# Usage: .\set-token.ps1 "your-github-token"

param (
    [Parameter(Mandatory = $true)][string]$Token
)

$env:GITHUB_TOKEN = $Token
Write-Host "GitHub token has been set for this session."
