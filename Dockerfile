FROM ruby:2.4-alpine
MAINTAINER andruby

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

COPY run.rb .

CMD ruby run.rb
