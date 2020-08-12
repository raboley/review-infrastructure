curl \
  -X PATCH \
  -u raboley \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/raboley/review-infrastructure \
  -d '{"delete_branch_on_merge":"true"}'