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

prs = gh_client.pull_requests(ENV['GITHUB_REPO'], state: :open)

# Get labels for issues

label_counts = prs.each_with_object(Hash.new(0)) do |pr, hash|
  issue = gh_client.issue(ENV['GITHUB_REPO'], pr.number)
  labels = issue.labels.map(&:name)
  labels.each { |label| hash[label] += 1 }
end

output = ""

output << "Open PRs: #{prs.count}\n"
label_counts.to_a.map(&:reverse).sort.reverse.each do |count, label|
  output << "#{count} have label \"#{label}\"\n"
end

puts output
