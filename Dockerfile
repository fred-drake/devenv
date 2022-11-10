FROM ubuntu:jammy as neovim
WORKDIR /work
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y curl git nodejs python3 \
    python3-pip fzf ripgrep tree npm tzdata ninja-build gettext libtool libtool-bin autoconf automake \
    cmake g++ pkg-config zip unzip \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --branch stable --depth 1 https://github.com/neovim/neovim \
    && make -C neovim -j4 \
    && make -C neovim install \
    && rm -rf neovim

FROM ubuntu:jammy as tree-sitter
WORKDIR /work
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y wget gcc \
    && rm -rf /var/lib/apt/lists/*
RUN wget -O installer https://sh.rustup.rs \
    && chmod 755 installer \
    && ./installer -y
RUN /root/.cargo/bin/cargo install tree-sitter-cli

FROM ubuntu:jammy
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y git gcc fzf ripgrep \
    tree xclip python3 python3-pip nodejs npm curl fzf ripgrep tzdata ninja-build gettext libtool \
    libtool-bin autoconf automake cmake g++ pkg-config zip unzip \
    && rm -rf /var/lib/apt/lists/*

# Import Neovim 
COPY --from=neovim /usr/local/share/man/man1/nvim.1 /usr/local/share/man/man1/nvim.1
COPY --from=neovim /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim /usr/local/lib/nvim/ /usr/local/lib/nvim/
COPY --from=neovim /usr/local/share/nvim/ /usr/local/share/nvim/
COPY --from=neovim /usr/local/share/applications/nvim.desktop /usr/local/share/applications/nvim.desktop
COPY --from=neovim /usr/local/share/icons/hicolor/128x128/apps/nvim.png /usr/local/share/icons/hicolor/128x128/apps/nvim.png

# Import Tree Sitter CLI -- needed by plugin
# COPY --from=tree-sitter /root/.cargo/bin/tree-sitter /usr/local/bin/tree-sitter

WORKDIR /root/.config
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
RUN git config --global user.email "fred.drake@gmail.com" \
  && git config --global user.name "Fred Drake"

# Bust cache if nvim env has changed
ADD https://api.github.com/repos/fred-drake/nvim-env/branches/master /tmp/version.json
RUN git clone --depth 1 https://github.com/fred-drake/nvim-env.git nvim

COPY nvim-init.sh /root/nvim-init.sh
RUN /root/nvim-init.sh
WORKDIR /workspace
