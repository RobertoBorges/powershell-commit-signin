param (
    [string]$RepositoryName = "powershell-signin",
    [string]$BranchName = "main",
    [string]$PathName = "test.txt"
)

. .\Set-GitHubSignCommit.ps1

# Replace with your actual GitHub token securely
$GitHubTokenInstance = [PSCustomObject]@{
    token = "ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

$results = Set-GitHubSignCommit -RepositoryName $RepositoryName `
                                 -BranchName $BranchName `
                                 -PathName $PathName `
                                 -GitHubTokenInstance $GitHubTokenInstance

$results | Format-List
