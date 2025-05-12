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
        [string]$OwnerName = "DivyaGhai",  # GitHub username

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
        # Fetch Git config details
        $userEmail = git config --global user.email
        $gpg = git config --global gpg.program
        if (-not $userEmail -or -not $gpg) {
            throw "Git user email or GPG program is not configured correctly."
        }

        Write-Host "user.email: $userEmail"
        Write-Host "gpg: $gpg"

        # Get commit details
        $commitSha = git rev-parse HEAD
        $commitInfo = git log -1 --pretty=format:"%H%n%an%n%ae%n%ad%n%cn%n%ce%n%cI%n%s%n%b" $commitSha

        # Debug: Print the raw date strings
        Write-Host "Raw author date: $($commitInfo[3])"
        Write-Host "Raw committer date: $($commitInfo[6])"

        # Attempt to parse the raw date strings
        try {
            # Author date format
            $authorDate = [datetime]::ParseExact($commitInfo[3], "ddd MMM dd HH:mm:ss yyyy zzz", $null)

            # Commiter date format (modified to handle ISO 8601 format)
            $committerDate = [datetime]::ParseExact($commitInfo[6], "yyyy-MM-ddTHH:mm:sszzz", $null)
        }
        catch {
            Write-Host "Failed to parse dates:"
            Write-Host "Author date: $($commitInfo[3])"
            Write-Host "Committer date: $($commitInfo[6])"
            throw $_
        }

        # Use 'git cat-file' to get the commit tree
        $commitTree = git cat-file commit HEAD | Select-String "tree" | ForEach-Object { $_.Line.Split(" ")[1] }

        $commitBody = @{
            message   = $commitInfo[7]
            author    = @{
                name  = $commitInfo[1]
                email = $commitInfo[2]
                date  = $authorDate
            }
            committer = @{
                name  = $commitInfo[4]
                email = $commitInfo[5]
                date  = $committerDate
            }
            tree     = $commitTree
            parents  = @(git log -1 --pretty=%P)
        }

        # Save commit body for GPG signing
        [System.IO.File]::WriteAllLines($CommitBodyPathName, @(
            "tree $($commitBody.tree)"
            "parent $($commitBody.parents -join ' ')"
            "author $($commitBody.author.name) <$($commitBody.author.email)> $([int][double]::Parse((Get-Date $commitBody.author.date -UFormat %s))) -0000"
            "committer $($commitBody.committer.name) <$($commitBody.committer.email)> $([int][double]::Parse((Get-Date $commitBody.committer.date -UFormat %s))) -0000"
            ""
            "$($commitBody.message)"
        ))

        # Sign the commit using GPG
        $signature = & $gpg --armor --sign --default-key $userEmail -o - $CommitBodyPathName
        $signatureJoined = ($signature -join $eol) + $eol
        Remove-Item -Path $CommitBodyPathName -Force

        # Prepare commit body with signature
        $commitBody.signature = $signatureJoined

        # GitHub API URL
        $uriFragment = $uriFormat -f $OwnerName, $RepositoryName
        $bodyJson = $commitBody | ConvertTo-Json -Depth 10

        # Debug: Print the commit data that will be sent
        Write-Host "Sending commit to GitHub API:"
        Write-Host $bodyJson

        $apiUrl = "https://api.github.com/$uriFragment"
        $headers = @{
            Authorization = "Bearer $($GitHubTokenInstance.token)"
            Accept        = "application/vnd.github+json"
        }

        # Send commit data to GitHub API
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
