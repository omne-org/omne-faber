#!/bin/bash
# human-approval gate hook
# Called by omne-cli after the review node completes.
# Non-zero exit blocks the pipe.

echo "Review complete. Manual approval required."
echo "Run: omne signal $OMNE_RUN_ID human-approval"
exit 1
