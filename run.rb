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
reviews_requested_count = prs.each_with_object(Hash.new(0)) do |pr, hash|
  usernames = gh_client.pull_request_review_requests(ENV['GITHUB_REPO'], pr.number).map(&:login)
  usernames.each { |username| hash[username] += 1 }
end

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

def link_to_all_prs_with_label(label)
  query = "is:open is:pr label:#{label}"
  "<#{url_for_pr_list(query)}|#{label}>"
end

def link_to_all_prs_with_review_requested_for(username)
  url = "https://github.com/#{ENV['GITHUB_REPO']}/pulls/review-requested/#{username}"
  "<#{url}|#{username}>"
end

def url_for_pr_list(query)
  "https://github.com/#{ENV['GITHUB_REPO']}/pulls?q=#{URI.escape(query)}"
end

def pr_summary_message(prs, label_counts)
  output = "Open PRs: #{prs.count}\n"
  output << label_counts.to_a.map(&:reverse).sort.reverse.map do |count, label|
    "#{count} with label #{link_to_all_prs_with_label(label)}\n"
  end.join
end

def reviews_requested_message(reviews_requested_count)
  reviews_requested_count.to_a.map(&:reverse).sort.reverse.map do |count, username|
    "#{count} reviews requested of #{link_to_all_prs_with_review_requested_for(username)}\n"
  end.join
end

output = pr_summary_message(prs, label_counts) + reviews_requested_message(reviews_requested_count)
puts output

if ENV['SLACK_WEBHOOK_URL']
  slack pr_summary_message(prs, label_counts)
  slack reviews_requested_message(reviews_requested_count)
end
