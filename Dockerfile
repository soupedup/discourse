# syntax = docker/dockerfile:experimental

ARG RUBY_VERSION=3.0.1-jemalloc
FROM quay.io/evl.ms/fullstaq-ruby:${RUBY_VERSION}-slim as build

ARG RAILS_ENV=production
ARG RAILS_MASTER_KEY

ARG DISCOURSE_REDIS_HOST
ENV DISCOURSE_REDIS_HOST=${DISCOURSE_REDIS_HOST}
ARG DISCOURSE_DB_HOST
ENV DISCOURSE_DB_HOST=${DISCOURSE_DB_HOST}
ARG DISCOURSE_DB_NAME
ENV DISCOURSE_DB_NAME=${DISCOURSE_DB_NAME}
ARG DISCOURSE_DB_PASSWORD
ENV DISCOURSE_DB_PASSWORD=${DISCOURSE_DB_PASSWORD}
ARG DISCOURSE_DB_USERNAME
ENV DISCOURSE_DB_USERNAME=${DISCOURSE_DB_USERNAME}
ENV RAILS_ENV=${RAILS_ENV}
ENV BUNDLE_PATH vendor/bundle
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
ENV SECRET_KEY_BASE 1
RUN mkdir /app
WORKDIR /app

# Reinstall runtime dependencies that need to be installed as packages


RUN apt -y install --no-install-recommends git rsyslog logrotate cron ssh-client less
RUN apt -y install build-essential rsync \

RUN --mount=type=cache,id=apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    postgresql-client file rsync git build-essential libpq-dev wget vim curl gzip xz-utils \
    libxslt-dev libcurl4-openssl-dev \
    libssl-dev libyaml-dev libtool \
    libxml2-dev gawk parallel \
    libreadline-dev \
    psmisc whois brotli libunwind-dev \
    libtcmalloc-minimal4 cmake \
    pngcrush pngquant \

    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN curl -sO https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.xz && cd /usr/local && tar --strip-components 1 -xvf /app/node*xz && rm /app/node*xz && cd ~

RUN gem install -N bundler -v 2.2.19
RUN npm install -g yarn terser uglify-js

ENV PATH $PATH:/usr/local/bin

COPY bin/rsync-cache bin/rsync-cache

# Install rubygems
COPY Gemfile* ./

ENV BUNDLE_WITHOUT development:test

RUN --mount=type=cache,target=/cache,id=bundle bin/rsync-cache /cache vendor/bundle "bundle install"

ENV NODE_ENV production

COPY . .

RUN --mount=type=cache,target=/cache,id=node \
    bin/rsync-cache /cache node_modules "yarn"

RUN bin/rails assets:precompile

RUN rm -rf node_modules vendor/bundle/ruby/*/cache

FROM quay.io/evl.ms/fullstaq-ruby:${RUBY_VERSION}-slim

ARG RAILS_ENV=production

RUN --mount=type=cache,id=apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    postgresql-client file git wget vim curl gzip imagemagick \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=${RAILS_ENV}
ENV RAILS_SERVE_STATIC_FILES true
ENV BUNDLE_PATH vendor/bundle
ENV BUNDLE_WITHOUT development:test
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

COPY --from=build /app /app

WORKDIR /app

RUN mkdir -p tmp/pids

EXPOSE 8080

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
