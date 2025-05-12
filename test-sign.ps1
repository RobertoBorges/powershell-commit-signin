param (
    [string]$RepositoryName = "powershell-signin",
    [string]$BranchName = "main",
    [string]$PathName = "test.txt"
)

# Load the GitHub Sign Commit script
. .\Set-GitHubSignCommit.ps1

# Ensure the GitHub token is set securely
$GitHubTokenInstance = [PSCustomObject]@{
    token = $env:GITHUB_TOKEN
}

# Run the commit signing test
$results = Set-GitHubSignCommit -RepositoryName $RepositoryName `
                                 -BranchName $BranchName `
                                 -PathName $PathName `
                                 -GitHubTokenInstance $GitHubTokenInstance

# Display the results
$results | Format-List
