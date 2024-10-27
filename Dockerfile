FROM debian:bullseye-20220801-slim

# Build Args
# ARG PHOENIX_VERSION=1.7.12
# ARG NODE_VERSION=20.10.0

# Dependencies
RUN apt update \
  && apt upgrade -y \
  && apt install -y bash curl git build-essential inotify-tools unzip

SHELL ["/bin/bash", "-lc"]

# asdf
# https://github.com/asdf-community/asdf-ubuntu/blob/master/Dockerfile
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.profile

# test asdf
RUN asdf --version

# App Directory
ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# Copy .tool-versions file into the image
COPY ./app/.tool-versions $APP_HOME/.tool-versions

# install required plugins

# Erlang
RUN asdf plugin-add erlang
# install asdf plugin erlang dependencies -> https://github.com/asdf-vm/asdf-erlang?tab=readme-ov-file#debian-12-bookworm
RUN apt-get update -y && apt-get install -y build-essential autoconf m4 libncurses-dev xsltproc fop libxml2-utils libssh-dev \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN asdf plugin-add elixir
RUN asdf plugin-add nodejs

# direnv
# https://github.com/asdf-community/asdf-direnv
RUN asdf plugin-add direnv
RUN asdf direnv setup --shell bash --version latest

RUN asdf plugin-add pnpm

# install tools
RUN asdf install

# allow direnv
# RUN direnv allow

ENV LANG C.UTF-8

# Phoenix
RUN mix local.hex --force
RUN mix archive.install --force hex phx_new ${PHOENIX_VERSION}
RUN mix local.rebar --force

# App Port
EXPOSE 1337

# Default Command
CMD ["mix", "phx.server"]
