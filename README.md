# GitHub Commit Signing with PowerShell

This repository contains scripts for signing Git commits using the GitHub API. The main goal is to ensure that signed commits show as "verified" in the GitHub UI.

## Key Scripts

- **Direct-GitHubSignCommit.ps1** - The fixed, reliable implementation that ensures proper signature verification
- **test-direct.ps1** - Test script to validate signature verification
- **technical-deep-dive.md** - Detailed technical explanation of the signature verification issues and solutions

## The Problem

When signing commits using the GitHub API, signatures may show as "unverified" with the reason "invalid" in the GitHub UI. This happens due to subtle formatting differences between what's being signed and what GitHub expects for verification.

## Usage

### Prerequisites

1. GPG key properly set up in GitHub
2. GitHub Personal Access Token with appropriate permissions
3. PowerShell (Windows PowerShell or PowerShell Core)

### Setting Up Your Token

```powershell
$env:GITHUB_TOKEN = "your-github-token-here"
```

### Signing the Latest Commit

```powershell
# Load the script
. .\Direct-GitHubSignCommit.ps1

# Sign the latest commit on the main branch
Sign-GitHubCommit -RepositoryName "your-repo" `
                 -BranchName "main" `
                 -GithubToken $env:GITHUB_TOKEN `
                 -OwnerName "your-username"
```

### Running a Test

```powershell
# Create a test commit and sign it
.\test-direct.ps1 -GitHubToken $env:GITHUB_TOKEN -MakeNewCommit

# Or just sign an existing commit
.\test-direct.ps1 -GitHubToken $env:GITHUB_TOKEN
```

## How It Works

The script:

1. Fetches the latest commit data from GitHub API
2. Creates a commit object in exactly the same format Git would use
3. Signs it with GPG
4. Creates a new commit via GitHub API with the signature
5. Updates the branch pointer to the new commit

## Key Technical Challenges Solved

1. **Timestamp Format**: Using the exact timestamp format that GitHub's verification system expects
2. **Commit Object Format**: Ensuring the commit object format exactly matches what Git produces
3. **GPG Signature Format**: Formatting the signature with proper spaces and line endings
4. **API Payload Construction**: Using the correct date formats in API requests

## Troubleshooting

- **Signature still shows as unverified**: Double-check that your GPG key is properly set up in GitHub
- **GPG signing errors**: Ensure your email in the commit matches the email associated with your GPG key
- **API errors**: Verify your GitHub token has the appropriate permissions

## Additional Resources

For more detailed information:
- See `technical-deep-dive.md` for an in-depth explanation of the verification process
- Check `fixed-verification-summary.md` for a summary of the fixes implemented
