param (
    [string]$RepositoryName = "powershell-commit-signin",
    [string]$BranchName = "main"
)

# Load the GitHub Sign Commit script (the new one)
. .\Set-GitHubSignCommit.ps1

# Set the GitHub token
$GitHubTokenInstance = [PSCustomObject]@{
    token = $env:GITHUB_TOKEN
}

# Run the updated signing process using GitHub API
$results = Set-GitHubSignLatestCommit -RepositoryName $RepositoryName `
                                      -BranchName $BranchName `
                                      -GitHubTokenInstance $GitHubTokenInstance `
                                      -OwnerName "RobertoBorges"

# Display the result
$results | Format-List