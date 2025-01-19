FROM debian:bullseye-20250113-slim

# Build Args
# ARG PHOENIX_VERSION=1.7.12
# ARG NODE_VERSION=20.10.0

# https://github.com/elixir-lsp/elixir-ls-devcontainer-example/blob/main/.devcontainer/Dockerfile#L9C1-L15C23
# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Dependencies
# including asdf plugin erlang dependencies -> https://github.com/asdf-vm/asdf-erlang?tab=readme-ov-file#debian-12-bookworm
RUN apt-get update -qq && \
  apt-get install -qq -y \
  bash \
  curl \
  git \
  dirmngr \
  gpg \
  gawk \
  unzip \
  build-essential \
  autoconf \
  libssl-dev \
  libncurses5-dev \
  m4 \
  libssh-dev \
  inotify-tools \
  ca-certificates

SHELL ["/bin/bash", "-lc"]

RUN groupadd --gid $USER_GID $USERNAME 
RUN useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME
USER vscode

# asdf
# https://github.com/asdf-community/asdf-ubuntu/blob/master/Dockerfile
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc && \
    echo '. $HOME/.asdf/asdf.sh' >> $HOME/.profile

# test asdf
RUN asdf --version

# App Directory
ENV APP_HOME /home/$USERNAME/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# Copy .tool-versions file into the image
COPY ./app/.tool-versions $APP_HOME/.tool-versions

# install required plugins

# Erlang
RUN asdf plugin-add erlang

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
CMD ["direnv", "allow"]

ENV LANG C.UTF-8

# Phoenix
RUN mix local.hex --force
RUN mix archive.install --force hex phx_new ${PHOENIX_VERSION}
RUN mix local.rebar --force

# App Port
EXPOSE 1337

# SSL
# RUN git config --global http.sslVerify false
# RUN git config --global --unset http.https://partner.bdr.de.sslkey \
#     && git config --global --unset http.https://partner.bdr.de.sslcert \
#     && git config --global --unset http.sslcert \
#     && git config --global --unset http.sslkey

# Default Command
CMD ["mix", "phx.server"]
