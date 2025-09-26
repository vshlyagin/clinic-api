FROM ruby:3.2.9 AS rails-toolbox
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH

RUN apt-get update -qq && apt-get install -y postgresql-client
RUN gem install rails bundler
WORKDIR /opt/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
CMD ["rails", "server", "-b", "0.0.0.0"]