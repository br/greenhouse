FROM ruby:2.1
RUN apt-get update && apt-get install -y postgresql postgresql-server-dev-all

ADD ./Gemfile Gemfile
ADD ./Gemfile.lock Gemfile.lock
RUN bundle install

WORKDIR /usr/src/app
ADD . /usr/src/app
RUN chmod +x docker_start.sh

EXPOSE 80
CMD ./docker_start.sh
