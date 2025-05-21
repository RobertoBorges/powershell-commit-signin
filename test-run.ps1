Write-Host "Signing most recent commit on branch main"

# For testing purposes only (GitHub token should be managed securely)
# You can replace this with your actual token for testing
$env:GITHUB_TOKEN = "your-github-token-goes-here"

# Load the GitHub Sign Commit script
. .\Set-GitHubSignCommit.ps1

# Set up the GitHub token instance
$GitHubTokenInstance = [PSCustomObject]@{
    token = $env:GITHUB_TOKEN
}

# Run the signing process using GitHub API
try {
    $results = Set-GitHubSignLatestCommit -RepositoryName "powershell-commit-signin" `
                                         -BranchName "main" `
                                         -GitHubTokenInstance $GitHubTokenInstance `
                                         -OwnerName "RobertoBorges"
    Write-Host "Signing successful"
} 
catch {
    Write-Host "Error signing commit: $_"
    Write-Host $_.Exception
}
