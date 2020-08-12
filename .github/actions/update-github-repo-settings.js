const octokit = new Octokit();
const [owner, repo] = process.env.GITHUB_REPOSITORY.split("/");

await octokit.request("PATCH /repos/:owner/:repo", {
    owner,
    repo,
    delete_branch_on_merge: true
})