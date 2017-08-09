# Github review reminder

Checks all open PRs and review requests for a given Github repository and send a summary message to Slack.

At [Silverfin](https://github.com/GetSilverfin), this is run each morning to remind us of the PR's we need to review.

## USAGE

Run it as a docker image:

```shell
docker run --rm -e GITHUB_TOKEN=<your-gh-token> -e REPO=<your-gh-repo> GetSilverfin/github_review_reminder
```

## Configuration

Configuration is done through environment variables. There variables are available:

* GITHUB_TOKEN: an oauth token for the github api. Either set this or GITHUB_USER and GITHUB_PASSWORD
* GITHUB_USER: the github username used for the github api
* GITHUB_PASSWORD: the password for GITHUB_USER
* GITHUB_REPO: the github repository name this should run against, eg: "GetSilverfin/github_review_reminder"
* SLACK_CHANNEL: (optional) the slack channel name to post the message
* SLACK_TOKEN: (optional) the api token for posting to Slack
