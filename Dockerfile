FROM ruby:2.6.1-alpine
RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --jobs 4
ADD . /app
CMD while sleep 60; do ruby bin/cli; done
