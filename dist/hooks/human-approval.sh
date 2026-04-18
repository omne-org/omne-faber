#!/bin/bash
# human-approval gate hook
# Called by omne-cli after the approve node recaps the synthesis.
#
# v1 note: kernel v0.2.x has no `omne signal` verb (post-v1 deferred),
# so this hook exits 0 as a no-op checkpoint. The recap is in the
# events.jsonl and lib/docs/inter/review-synthesis-*. The human
# reviews the worktree outside omne and merges manually.

echo "Review complete. Recap at lib/docs/inter/review-synthesis-${OMNE_INPUT_FEATURE_NAME:-$OMNE_NODE_ID}.md"
echo "run_id=$OMNE_RUN_ID  node_id=$OMNE_NODE_ID"
exit 0
