# human-approval gate hook (Windows)
# Called by omne-cli after the review node completes.
# Non-zero exit blocks the pipe.

Write-Host "Review complete. Manual approval required."
Write-Host "Run: omne signal $env:OMNE_RUN_ID human-approval"
exit 1
