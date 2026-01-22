FROM ubuntu:rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Denver
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---- Base OS packages (a pragmatic 2026 dev baseline) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget bash adduser unzip htop git zsh byobu neovim \
    ca-certificates gnupg locales tzdata \
    build-essential pkg-config \
    openssh-client \
    ripgrep fd-find fzf jq \
    less man-db file \
    netcat-openbsd iputils-ping dnsutils \
    fluxbox tigervnc-standalone-server \
    && locale-gen en_US.UTF-8 \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*
RUN COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack enable && corepack prepare pnpm@latest --activate

# ---- Create a non-root dev user with passwordless sudo ----
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

RUN if getent group ${USER_GID} >/dev/null; then \
    groupmod -n ${USERNAME} $(getent group ${USER_GID} | cut -d: -f1); \
    else \
    groupadd --gid ${USER_GID} ${USERNAME}; \
    fi \
    && if getent passwd ${USER_UID} >/dev/null; then \
    usermod -l ${USERNAME} -d /home/${USERNAME} -m $(getent passwd ${USER_UID} | cut -d: -f1); \
    else \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}; \
    fi \
    && usermod -s /usr/bin/zsh ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" > /etc/sudoers.d/99-${USERNAME} \
    && chmod 0440 /etc/sudoers.d/99-${USERNAME}

# Workspace
RUN mkdir -p /workspace && chown -R ${USERNAME}:${USERNAME} /workspace
WORKDIR /workspace

# ---- Switch to dev user for user-level installs (bun/uv/oh-my-zsh/etc.) ----
USER ${USERNAME}
# ENV HOME=/home/${USERNAME}
RUN corepack prepare pnpm@latest --activate
RUN bash -lc 'curl -LsSf https://astral.sh/uv/install.sh | sh'
RUN bash -lc 'curl -fsSL https://bun.com/install | bash'

ADD https://api.github.com/repos/anomalyco/opencode/releases /tmp/cache-bust.json
RUN sudo rm /tmp/cache-bust.json && ~/.bun/bin/bun install -g opencode-ai
ADD https://registry.npmjs.org/@anthropic-ai/claude-code/latest /tmp/cache-bust.json
RUN sudo rm /tmp/cache-bust.json && ~/.bun/bin/bun install -g @anthropic-ai/claude-code
ADD https://api.github.com/repos/subsy/ralph-tui/releases /tmp/cache-bust.json
RUN sudo rm /tmp/cache-bust.json && ~/.bun/bin/bun install -g ralph-tui

# Common PATH defaults for this dev image
# (bun: ~/.bun/bin, uv & claude typically: ~/.local/bin)
ENV PATH="${HOME}/.local/bin:${HOME}/.bun/bin:${PATH}"
ENV EDITOR=nvim
ENV VISUAL=nvim

# Claude onboarding marker
RUN bash -lc 'echo '\''{"hasCompletedOnboarding": true}'\'' > ~/.claude.json'

# ---- oh-my-zsh (unattended) ----
RUN bash -lc 'export RUNZSH=no CHSH=no KEEP_ZSHRC=no; \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# ---- powerlevel10k theme ----
RUN bash -lc 'P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"; \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"; \
    target_uname=$(uname -sm | tr "[A-Z]" "[a-z]"); \
    GITSTATUS_CACHE_DIR="$P10K_DIR/gitstatus/usrbin" "$P10K_DIR/gitstatus/install" -f -s "${target_uname% *}" -m "${target_uname#* }"'

# ---- plugins ----
RUN bash -lc 'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" \
    && git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"'

# ---- p10k config ----
ADD .p10k.zsh /home/${USERNAME}/.p10k.zsh

# ---- Configure ~/.zshrc (theme, plugins, env loader, PATH, alias) ----
RUN bash -lc '\
    ZSHRC="$HOME/.zshrc"; \
    sed -i \
    -e '\''s/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/'\'' \
    -e '\''s/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/'\'' \
    "$ZSHRC"; \
    { \
    echo ""; \
    echo "# --- devcontainer additions ---"; \
    echo "export PATH=\"\$HOME/.local/bin:\$HOME/.bun/bin:\$PATH\""; \
    echo "[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh"; \
    echo "alias code=code-insiders"; \
    } >> "$ZSHRC"'

# Also enable env autoload for bash users (optional but helpful)
RUN bash -lc '\
    { \
    echo ""; \
    echo "# --- devcontainer additions ---"; \
    echo "export PATH=\"\$HOME/.local/bin:\$HOME/.bun/bin:\$PATH\""; \
    } >> "$HOME/.bashrc"'

# Default shell in container sessions
ENV TERM=xterm-256color
CMD ["zsh"]
