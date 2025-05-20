# Test script for the direct GitHub commit signing approach

param (
    [Parameter(Mandatory=$true)][string]$GitHubToken,
    [string]$RepositoryName = "powershell-commit-signin",
    [string]$BranchName = "main",
    [string]$OwnerName = "RobertoBorges",
    [switch]$MakeNewCommit
)

# First, check if we need to make a new test commit
if ($MakeNewCommit) {
    $testFilePath = "$PSScriptRoot\Test2.txt"
    $testContent = "Test commit $(Get-Date) - $(Get-Random)"
    
    Write-Host "📝 Creating a new test commit..." -ForegroundColor Cyan
    $testContent | Out-File -FilePath $testFilePath -Encoding utf8
    
    git add $testFilePath
    git commit -m "Test commit for signature verification: $testContent"
    git push
    
    Write-Host "✅ Test commit created and pushed" -ForegroundColor Green
}

# Load our direct signing function
. .\Direct-GitHubSignCommit.ps1

Write-Host "`n🔐 Signing the latest commit on branch '$BranchName'..." -ForegroundColor Cyan

try {
    # Call our signing function
    $result = Sign-GitHubCommit -RepositoryName $RepositoryName `
                              -BranchName $BranchName `
                              -GithubToken $GitHubToken `
                              -OwnerName $OwnerName `
                              -Debug
    
    if ($result) {
        Write-Host "`n✅ Commit signing successful!" -ForegroundColor Green
        Write-Host "New commit SHA: $($result.sha)" -ForegroundColor Cyan
        Write-Host "View on GitHub: https://github.com/$OwnerName/$RepositoryName/commit/$($result.sha)" -ForegroundColor Cyan
        
        # Wait a moment for GitHub to process
        Write-Host "`n⏳ Waiting 3 seconds for GitHub to process the verification..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        
        # Check verification status
        Write-Host "`n🔍 Checking verification status..." -ForegroundColor Cyan
        $checkUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/commits/$($result.sha)"
        $headers = @{
            Authorization = "Bearer $GitHubToken"
            Accept = "application/vnd.github+json"
        }
        
        $checkResult = Invoke-RestMethod -Uri $checkUrl -Headers $headers
        
        $verified = $checkResult.commit.verification.verified
        $reason = $checkResult.commit.verification.reason
        
        if ($verified) {
            Write-Host "✅ Signature is VERIFIED!" -ForegroundColor Green
        } else {
            Write-Host "❌ Signature is NOT VERIFIED: $reason" -ForegroundColor Red
            
            # Show the verification payload to help debug
            Write-Host "`nVerification Payload:" -ForegroundColor Yellow
            Write-Host $checkResult.commit.verification.payload -ForegroundColor Gray
            
            # Show our signed text for comparison
            Write-Host "`nOur Signed Text:" -ForegroundColor Yellow
            Sign-GitHubCommit -RepositoryName $RepositoryName `
                             -BranchName $BranchName `
                             -GithubToken $GitHubToken `
                             -OwnerName $OwnerName `
                             -Debug | Out-Null
        }
    }
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
