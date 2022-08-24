FROM ruby:2.6.6

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN gem install bundler:2.1.4
RUN bundle install


EXPOSE 3000

# Configure the main process to run when running the image
CMD ["bash"]