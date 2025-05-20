# Test script to verify GitHub API signing works correctly with our fixed version

param (
    [string]$RepositoryName = "powershell-commit-signin",
    [string]$BranchName = "main",
    [string]$OwnerName = "RobertoBorges",
    [switch]$MakeNewCommit
)

# First check if GitHub token is set
if (-not $env:GITHUB_TOKEN) {
    Write-Host "⚠️ GitHub token not found in environment variable!" -ForegroundColor Yellow
    Write-Host "Please set your token first using: .\set-token.ps1 'your-github-token'"
    exit 1
}

# Load the GitHub Sign Commit Fixed script
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
    
    # Check verification status
    Write-Host "Checking verification status..." -ForegroundColor Cyan
    . .\check-verification.ps1 -CommitSHA $results.sha
} 
catch {
    Write-Host "❌ Error signing commit: $_" -ForegroundColor Red
}
