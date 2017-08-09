require 'bundler'
Bundler.require

# Let the library traverse all pages, most querries won't fetch large lists anyway
Octokit.auto_paginate = true

gh_authentication =
  if ENV['GITHUB_TOKEN']
    {access_token: ENV['GITHUB_TOKEN']}
  else
    {login: ENV['GITHUB_USER'], password: ENV['GITHUB_PASSWORD']}
  end

gh_client = Octokit::Client.new(gh_authentication)

# Fetch all open PRs
prs = gh_client.pull_requests(ENV['GITHUB_REPO'], state: :open)

# Get labels via issues
label_counts = prs.each_with_object(Hash.new(0)) do |pr, hash|
  issue = gh_client.issue(ENV['GITHUB_REPO'], pr.number)
  labels = issue.labels.map(&:name)
  labels.each { |label| hash[label] += 1 }
end

# Get reviewers for each pr
reviews_requested = prs.each_with_object(Hash.new([])) do |pr, hash|
  usernames = gh_client.pull_request_review_requests(ENV['GITHUB_REPO'], pr.number).map(&:login)
  usernames.each { |username| hash[username] += [pr.number] }
end

# Get counts for easy sorting
reviews_requested_count = reviews_requested.map do |username, prs|
  [username, prs.count]
end.to_h

# Post message to Slack
def slack(text)
  puts "sending to slack"
  uri = URI(ENV['SLACK_WEBHOOK_URL'])
  payload = {"text" => text}
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, "Content-type" => "application/json")
  request.body = payload.to_json
  http.request(request)
end

def slack_format_github_pr_link(pr_number)
  "<https://github.com/#{ENV['GITHUB_REPO']}/pull/#{pr_number}|##{pr_number}>"
end

output = ""

output << "Open PRs: #{prs.count}\n"
label_counts.to_a.map(&:reverse).sort.reverse.each do |count, label|
  output << "#{count} with label *#{label}*\n"
end
output << "\n"
reviews_requested_count.to_a.map(&:reverse).sort.reverse.each do |count, username|
  output << "#{count} reviews requested of *#{username}*: #{reviews_requested[username].map { |pr_number| slack_format_github_pr_link(pr_number) }.join(", ")}\n"
end

puts output

if ENV['SLACK_WEBHOOK_URL']
  slack(output)
end
