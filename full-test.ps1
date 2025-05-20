# Complete test script that sets up token and runs the fixed signing process

param (
    [Parameter(Mandatory = $true)][string]$GitHubToken,
    [string]$RepositoryName = "powershell-commit-signin",
    [string]$BranchName = "main",
    [string]$OwnerName = "RobertoBorges",
    [switch]$MakeNewCommit
)

Write-Host "Setting GitHub token..." -ForegroundColor Cyan
$env:GITHUB_TOKEN = $GitHubToken

# Load the fixed GitHub Sign Commit script
. .\Set-GitHubSignCommit.ps1.fixed

# Create token object
$GitHubTokenInstance = [PSCustomObject]@{
    token = $env:GITHUB_TOKEN
}

# Optionally create a new commit to test with
if ($MakeNewCommit) {
    $testFilePath = "$PSScriptRoot\Test2.txt"
    $testContent = "script test $(Get-Random)"
    $testContent | Out-File -FilePath $testFilePath -Encoding utf8
    
    Write-Host "📝 Creating a new test commit..." -ForegroundColor Cyan
    git add $testFilePath
    git commit -m "Test commit for signature verification: $testContent"
    git push
    
    Write-Host "✅ Commit created and pushed to GitHub" -ForegroundColor Green
}

# Run the signing process using GitHub API
Write-Host "🔏 Signing the latest commit on branch '$BranchName' with FIXED script..." -ForegroundColor Cyan

try {
    $results = Set-GitHubSignLatestCommit -RepositoryName $RepositoryName `
                                         -BranchName $BranchName `
                                         -GitHubTokenInstance $GitHubTokenInstance `
                                         -OwnerName $OwnerName
    
    Write-Host "✅ Signing successful!" -ForegroundColor Green
    Write-Host "New commit SHA: $($results.sha)" 
    Write-Host "Visit https://github.com/$OwnerName/$RepositoryName/commit/$($results.sha) to verify the signature"
    
    # Wait a moment for GitHub to process the commit
    Write-Host "Waiting 3 seconds for GitHub to process the commit..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    
    # Check verification status using curl directly instead of our PowerShell script
    Write-Host "Checking verification status with curl..." -ForegroundColor Cyan
    $apiUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/commits/$($results.sha)"
    $curlCmd = "curl -s -H 'Authorization: Bearer $GitHubToken' $apiUrl | findstr verification"
    
    Write-Host "Executing: $curlCmd"
    Invoke-Expression $curlCmd
    
    return $results.sha
} 
catch {
    Write-Host "❌ Error signing commit: $_" -ForegroundColor Red
}
