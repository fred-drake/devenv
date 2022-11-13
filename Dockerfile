FROM ghcr.io/fred-drake/neovim:latest as neovim

FROM ubuntu:jammy
ENV GID 1000
ENV UID 1000
ENV USER user
ENV GROUP user
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y git gcc fzf ripgrep \
    tree xclip python3 python3-pip nodejs npm curl fzf ripgrep tzdata ninja-build gettext libtool \
    libtool-bin autoconf automake cmake g++ pkg-config zip unzip tmux zsh git-core curl fonts-powerline \
    ca-certificates apt-transport-https direnv locales locales-all\
    && rm -rf /var/lib/apt/lists/*

# Import Neovim 
COPY --from=neovim /usr/local/share/man/man1/nvim.1 /usr/local/share/man/man1/nvim.1
COPY --from=neovim /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim /usr/local/lib/nvim/ /usr/local/lib/nvim/
COPY --from=neovim /usr/local/share/nvim/ /usr/local/share/nvim/
COPY --from=neovim /usr/local/share/applications/nvim.desktop /usr/local/share/applications/nvim.desktop
COPY --from=neovim /usr/local/share/icons/hicolor/128x128/apps/nvim.png /usr/local/share/icons/hicolor/128x128/apps/nvim.png

# Install Kubectl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
    | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ \
    all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update && apt-get install helm

# Run as generic user instead of root
RUN groupadd --gid ${GID} -r ${GROUP} && useradd -r --uid ${UID} -g ${GROUP} --home /home/${USER} --shell /bin/zsh ${USER}
COPY nvim-init.sh /home/${USER}/nvim-init.sh
RUN chown -R ${USER}:${GROUP} /home/${USER}
USER ${USER}
WORKDIR /home/${USER}

# Install Oh My Zsh and plugins
ADD https://api.github.com/repos/ohmyzsh/ohmyzsh/branches/master /tmp/version.json
RUN curl -o install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
    && chmod 755 install.sh \
    && ./install.sh --unattended \
    && rm -f ~/.zshrc \
    && rm -f install.sh
ADD https://api.github.com/repos/zsh-users/zsh-autosuggestions/branches/master /tmp/version.json
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
ADD https://api.github.com/repos/zsh-users/zsh-syntax-highlighting/branches/master /tmp/version.json
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
ADD https://api.github.com/repos/romkatv/powerlevel10k/branches/master /tmp/version.json
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Apply dotfiles repo
ADD https://api.github.com/repos/fred-drake/dotfiles/branches/master /tmp/version.json
RUN git clone https://github.com/fred-drake/dotfiles /home/user/dotfiles
ADD https://api.github.com/repos/wbthomason/packer.nvim/branches/master /tmp/version.json
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    /home/${USER}/.local/share/nvim/site/pack/packer/start/packer.nvim
ADD https://api.github.com/repos/tmux-plugins/tpm/branches/master /tmp/version.json
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Initialize 
RUN /home/${USER}/dotfiles/dotscripts/from_repo.sh
RUN /home/${USER}/nvim-init.sh
RUN /home/${USER}/.tmux/plugins/tpm/scripts/install_plugins.sh
RUN echo exit | script -qec zsh /dev/null >/dev/null
