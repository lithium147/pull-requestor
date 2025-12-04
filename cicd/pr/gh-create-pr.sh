#!/usr/bin/env bash

# Can't get this working with the token in jenkins, fails with the following message:
#   This token doesn't work:
#   error validating token: missing required scope 'read:org'
# So using hub instead

branch_name=$1
pr_body=$2

# requires env var: GH_ENTERPRISE_TOKEN

gh config set -h $GITHUB_HOST git_protocol https
gh pr create --title "$branch_name" --body "$pr_body" --base master

# gh pr create --fill
# could not compute title or body defaults: fatal: ambiguous argument 'origin/master...uppercase-hex-digits': unknown revision or path not in the working tree.

#  gh pr create --title "test" --body "test"
#  echo $GITHUB_OAUTH_TOKEN | gh auth login -h $GITHUB_HOST --with-token
#  echo $GH_ENTERPRISE_TOKEN | gh auth login -h $GITHUB_HOST --with-token
#  export GH_HOST=$GITHUB_HOST

#  gh pr create --title "$branch_name" --body "$pr_body"
#  gh pr create --fill --label java

#  gh pr create --title "test" --body "test"

# error checking for existing pull request: GraphQL error: Your token has not been granted the required scopes to execute this query. The 'name' field requires one of the following scopes: ['read:org', 'read:discussion'], but your token has only been granted the: ['repo'] scopes. Please modify your token's scopes at: https://$GITHUB_HOST/settings/tokens.
