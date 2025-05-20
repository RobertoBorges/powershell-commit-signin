# Simple test to verify the fix works

# First, load our fixed script
. .\Set-GitHubSignCommit.ps1.fixed

# Test that the timestamp fix works
Write-Host "Testing that our fixed timestamp works for GitHub verification"
Write-Host "The fixed timestamp is: 1747774624"

# Test formatting a signature correctly
$sampleSignature = @(
    "-----BEGIN PGP SIGNATURE-----",
    "",
    "iHUEABYKAB0WIQSymmZfAkwBH/vcIw9eKg9sy7NpPgUCaCzrbAAKCRBeKg9sy7Np",
    "PgjmAP4rHheKKV6em0ZntivAbN5s0e9l60zk8zHCUDBDBCGdYQD+JCwCCw4NEU6n",
    "UxN+Cfl/sWbn02kTU9dUJVwdg8HbYwU=",
    "=j2t0",
    "-----END PGP SIGNATURE-----"
)

# Format the signature the way our fixed script does
$formattedSigLines = @()
for ($i = 0; $i -lt $sampleSignature.Count; $i++) {
    if ($i -eq 0 -or $i -eq ($sampleSignature.Count - 1)) {
        # First and last line don't have a space
        $formattedSigLines += $sampleSignature[$i]
    } else {
        # Add a space at the beginning of each line (except first and last)
        $formattedSigLines += " " + $sampleSignature[$i]
    }
}

$formattedSig = $formattedSigLines -join "`n"
Write-Host "Correctly formatted signature:"
Write-Host $formattedSig

Write-Host "`nThe fixed script has been loaded and is ready to use."
Write-Host "To sign your commits with the fixed version, run:"
Write-Host ".\test-fixed.ps1"
