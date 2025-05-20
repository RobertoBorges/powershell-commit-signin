param (
    [Parameter(Mandatory=$false)][string]$RepositoryName = "powershell-commit-signin",
    [Parameter(Mandatory=$false)][string]$BranchName = "main",
    [Parameter(Mandatory=$false)][string]$Token
)

# Load the GitHub Sign Commit script
. .\Set-GitHubSignCommit.ps1

# Check if token was provided as parameter or environment variable
if (-not $Token -and -not $env:GITHUB_TOKEN) {
    Write-Host "ERROR: GitHub token not found. Please provide a token using one of these methods:"
    Write-Host "1. Run this script with -Token parameter: .\test-sign.ps1 -Token 'your-github-token'"
    Write-Host "2. Set the GITHUB_TOKEN environment variable: `$env:GITHUB_TOKEN = 'your-github-token'"
    Write-Host "3. Use the set-token.ps1 script: .\set-token.ps1 'your-github-token'"
    exit 1
}

# Use provided token or fallback to environment variable
$tokenToUse = if ($Token) { $Token } else { $env:GITHUB_TOKEN }

# Set up the GitHub token instance
$GitHubTokenInstance = [PSCustomObject]@{
    token = $tokenToUse
}

Write-Host "Signing commit using GitHub API..."
Write-Host "Repository: $RepositoryName"
Write-Host "Branch: $BranchName"

# Run the updated signing process using GitHub API
$results = Set-GitHubSignLatestCommit -RepositoryName $RepositoryName `
                                      -BranchName $BranchName `
                                      -GitHubTokenInstance $GitHubTokenInstance `
                                      -OwnerName "RobertoBorges"

# Display the result
$results | Format-List