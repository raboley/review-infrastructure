curl \
  -X PATCH \
  -H "Accept: application/vnd.github.v3+json" \
  -u raboley:$API_GITHUB_TOKEN \
  https://api.github.com/repos/$REPOSITORY \
  -d '{"delete_branch_on_merge":"true"}'

curl \
  -X POST \
  -H "Accept: application/vnd.github.switcheroo-preview+json" \
  -u raboley:$API_GITHUB_TOKEN \
  https://api.github.com/repos/$REPOSITORY/pages \
  -d '{"source":{"branch":"gh-pages","path":"/docs"}}'
