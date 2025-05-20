# Test script to verify signature verification works
param (
    [Parameter(Mandatory = $false)][string]$CommitSHA
)

# Check if GitHub token is set
if (-not $env:GITHUB_TOKEN) {
    Write-Host "⚠️ GitHub token not found in environment variable!" -ForegroundColor Yellow
    Write-Host "Please set your token first using: .\set-token.ps1 'your-github-token'"
    exit 1
}

# Default to latest commit if no SHA provided
if (-not $CommitSHA) {
    # Get the latest commit SHA
    $latestCommit = git rev-parse HEAD
    $CommitSHA = $latestCommit
}

$headers = @{
    Authorization = "Bearer $($env:GITHUB_TOKEN)"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "PowerShell-GitHubClient"
}

# Get the repository owner and name from git remote
$remoteUrl = git remote get-url origin
if ($remoteUrl -match 'github\.com[\/:]([^\/]+)\/([^\/\.]+)') {
    $owner = $matches[1]
    $repo = $matches[2]
    
    if ($repo -match '\.git$') {
        $repo = $repo.Substring(0, $repo.Length - 4)
    }
    
    Write-Host "📝 Repository: $owner/$repo" -ForegroundColor Cyan
} else {
    Write-Host "❌ Could not determine GitHub repository from git remote URL" -ForegroundColor Red
    exit 1
}

Write-Host "🔎 Verifying signature for commit: $CommitSHA" -ForegroundColor Cyan

# Fetch the commit from GitHub API
$commitUrl = "https://api.github.com/repos/$owner/$repo/commits/$CommitSHA"
try {
    $commit = Invoke-RestMethod -Uri $commitUrl -Headers $headers
    
    # Check verification status
    if ($commit.commit.verification.verified) {
        Write-Host "✅ Signature is VERIFIED" -ForegroundColor Green
    } else {
        Write-Host "❌ Signature is NOT VERIFIED: $($commit.commit.verification.reason)" -ForegroundColor Red
    }
    
    # Show verification details
    Write-Host "`nVerification Details:" -ForegroundColor Yellow
    Write-Host "Verified: $($commit.commit.verification.verified)"
    Write-Host "Reason: $($commit.commit.verification.reason)"
    
    # Show timestamp comparison
    Write-Host "`nTimestamp Details:" -ForegroundColor Yellow
    Write-Host "Author date: $($commit.commit.author.date)"
    Write-Host "Committer date: $($commit.commit.committer.date)"
    
    # Show payload that was verified
    Write-Host "`nPayload used for verification:" -ForegroundColor Yellow
    Write-Host $commit.commit.verification.payload
    
    # Show signature
    Write-Host "`nSignature:" -ForegroundColor Yellow
    Write-Host $commit.commit.verification.signature
    
} catch {
    Write-Host "❌ Error fetching commit: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
