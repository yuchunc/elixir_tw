FROM ubuntu:trusty

# Build with
# optional arg: HOST=<host address>
# docker build --build-arg APP_VERSION=<release version> --build-arg SSH_KEY="$(< ~/.ssh/id_rsa)" -t elixir_tw .

# Elixir requires UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl wget make ssh

# change version can force rebuild image layers from here
ENV PHOENIX_VERSION 1.2.0

# Get app version during docker build
ARG APP_VERSION

# Get ssh key from build-arg
ARG SSH_KEY

# Set the host to scp the release to
ARG HOST=139.59.242.62

# download and install Erlang package
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
  && dpkg -i erlang-solutions_1.0_all.deb

# install Node.js (>= 5.0.0) and NPM in order to satisfy brunch.io dependencies
# See http://www.phoenixframework.org/docs/installation#section-node-js-5-0-0-
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

RUN apt-get update
RUN apt-get install -y nodejs build-essential esl-erlang elixir python

# install the Phoenix Mix archive
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new-$PHOENIX_VERSION.ez

RUN mix local.hex --force
RUN mix local.rebar
#RUN yarn global add brunch

# Fix bug https://github.com/npm/npm/issues/9863
RUN cd $(npm root -g)/npm \
  && npm install fs-extra \
  && sed -i -e s/graceful-fs/fs-extra/ -e s/fs\.rename/fs.move/ ./lib/utils/rename.js

RUN sudo chown -R root /usr/local

WORKDIR /app
COPY . .

RUN npm rebuild --unsafe-perm
RUN ./node_modules/brunch/bin/brunch b -p \
  && MIX_ENV=prod mix do phoenix.digest, release --env=prod

RUN eval `ssh-agent -s` > /dev/null \
    && echo $SSH_KEY | ssh-add - \
    && scp /app/rel/elixir_tw/releases/$APP_VERSION/elixir_tw.tar.gz elixir_tw@$HOST:~

# Clean up SSH key
RUN rm -r /tmp/*
