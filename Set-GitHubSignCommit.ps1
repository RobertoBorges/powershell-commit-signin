function Set-GitHubSignCommit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName,
        
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $true)]
        [string]$PathName,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$GitHubTokenInstance,
        
        [Parameter(Mandatory = $false)]
        [string]$OwnerName = "your-github-username",

        [Parameter(Mandatory = $false)]
        [string]$CommitBodyPathName = "$HOME\Documents\CommitBody.txt"
    )

    $eol = "`n"
    $uriFormat = "repos/{0}/{1}/git/commits"
    $isFailed = $false
    $writeOutput = @()
    $results = [PSCustomObject]@{
        Commit = [PSCustomObject]@{};
        Raw = $null;
        StatusCode = 200;
    }

    try {
        $userEmail = git config --global user.email
        $gpg = git config --global gpg.program
        Write-Host "user.email: $userEmail"
        Write-Host "gpg: $gpg"

        $commitSha = git rev-parse HEAD
        $commitInfo = git show --format=raw --no-patch $commitSha

        $commitBody = @{
            message   = git log -1 --pretty=%B
            author    = @{
                name  = git log -1 --pretty=%an
                email = $userEmail
                date  = git log -1 --pretty=%aI
            }
            committer = @{
                name  = git log -1 --pretty=%cn
                email = $userEmail
                date  = git log -1 --pretty=%cI
            }
            tree     = git rev-parse HEAD^{tree}
            parents  = @(git log -1 --pretty=%P)
        }

        [System.IO.File]::WriteAllLines($CommitBodyPathName, @(
            "tree $($commitBody.tree)"
            "parent $($commitBody.parents -join ' ')"
            "author $($commitBody.author.name) <$($commitBody.author.email)> $([int][double]::Parse((Get-Date $commitBody.author.date -UFormat %s))) -0000"
            "committer $($commitBody.committer.name) <$($commitBody.committer.email)> $([int][double]::Parse((Get-Date $commitBody.committer.date -UFormat %s))) -0000"
            ""
            "$($commitBody.message)"
        ))

        $signature = & $gpg --armor --sign --default-key $userEmail -o - $CommitBodyPathName
        $signatureJoined = ($signature -join $eol) + $eol
        Remove-Item -Path $CommitBodyPathName -Force

        $commitBody.signature = $signatureJoined

        $uriFragment = $uriFormat -f $OwnerName, $RepositoryName

        $bodyJson = $commitBody | ConvertTo-Json -Depth 10
        $apiUrl = "https://api.github.com/$uriFragment"
        $headers = @{
            Authorization = "Bearer $($GitHubTokenInstance.token)"
            Accept        = "application/vnd.github+json"
        }

        $response = Invoke-RestMethod -Method Post -Uri $apiUrl -Body $bodyJson -Headers $headers -ContentType "application/json"
        $results.Raw = $response
        $results.Commit = $response
    }
    catch {
        Write-Error $_.Exception.Message
        $isFailed = $true
    }

    return $results
}
