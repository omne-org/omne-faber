# human-approval gate hook (Windows)
# Called by omne-cli after the approve node recaps the synthesis.
#
# v1 note: kernel v0.2.x has no `omne signal` verb (post-v1 deferred),
# so this hook exits 0 as a no-op checkpoint. The recap is in the
# events.jsonl and lib/docs/inter/review-synthesis-*. The human
# reviews the worktree outside omne and merges manually.

$feature = if ($env:OMNE_INPUT_FEATURE_NAME) { $env:OMNE_INPUT_FEATURE_NAME } else { $env:OMNE_NODE_ID }
Write-Host "Review complete. Recap at lib/docs/inter/review-synthesis-$feature.md"
Write-Host "run_id=$env:OMNE_RUN_ID  node_id=$env:OMNE_NODE_ID"
exit 0
