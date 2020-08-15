GITHUB_EVENT_PATH=$1
pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
echo "$pull_number"
if [[ -n $pull_number && $pull_number != null ]]
then
  suffix="review-$pull_number"
else
  suffix="main"
fi
echo "$suffix"

echo "::set-env name=suffix::$suffix"