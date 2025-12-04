#!/usr/bin/env bash

branch="$1"
comment="$2"

echo "deleting branch $branch"

#if [ "$comment" != "" ]; then
#  gh pr comment "$branch" --body "$comment"
#fi
# normally deleting the branch closes the pr, but didn't on this occurrence
if ! gh pr close "$branch" --comment "$comment" --delete-branch; then
  echo "WARNING::failed to close pr"
  # X Pull request #59 (mvn-versions raven-commons:1.2.2) can't be closed because it was already merged
  # this pr was merged and branch deleted a long time ago it seem
fi

#  ! Pull request #457 (mvn-versions protobuf:4.26.1) is already closed
# pr maybe closed already but branch remains, or the close failed
# so force deletion of the branch just in case
if ! git push -d origin "$branch"; then
  echo "WARNING::failed to delete remote branch"
fi
if ! git branch -D "$branch"; then
  echo "WARNING::failed to delete local branch"
fi
