#!/usr/bin/env bash
set -euo pipefail

log()   { printf '\e[1;34m[INFO]\e[0m  %s\n' "$*"; }
warn()  { printf '\e[1;33m[SKIP]\e[0m  %s\n' "$*"; }

###############################################################################
# 1. Pacotes base, fontes e plug-ins GNOME ------------------------------------
###############################################################################
log "Atualizando índice APT…"
sudo apt update -qq

PKGS=(
  git curl zip zsh fonts-powerline
  gnome-tweaks gnome-software-plugin-flatpak
)
log "Instalando pacotes base: ${PKGS[*]}"
sudo apt install -y "${PKGS[@]}" || warn "Alguns pacotes já estavam na versão mais recente"

###############################################################################
# 2. Node.js LTS --------------------------------------------------------------
###############################################################################
if ! command -v node &>/dev/null; then
  log "Adicionando repositório NodeSource…"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  log "Instalando Node.js LTS…"
  sudo apt install -y nodejs
else
  warn "Node.js já instalado → versão $(node -v)"
fi

###############################################################################
# 3. Flatpak, Flathub, Extension Manager, VS Code -----------------------------
###############################################################################
if ! command -v flatpak &>/dev/null; then
  log "Instalando Flatpak…"
  sudo apt install -y flatpak
fi

log "Configurando remote Flathub…"
sudo flatpak remote-add --if-not-exists flathub \
     https://flathub.org/repo/flathub.flatpakrepo

log "Instalando Extension Manager (Flatpak)…"
flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager || \
  warn "Extension Manager já presente"

# VS Code (.deb) — repositório Microsoft
if ! command -v code &>/dev/null; then
  log "Adicionando repositório VS Code…"
  if [ ! -f /etc/apt/trusted.gpg.d/microsoft.gpg ]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
      gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
  fi
  sudo add-apt-repository -u -y \
    "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/code stable main"
  log "Instalando VS Code…"
  sudo apt install -y code
else
  warn "VS Code já instalado"
fi

###############################################################################
# 4. Oh My Zsh, Powerlevel10k, plugins ----------------------------------------
###############################################################################
ZSH_CUSTOM=${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Instalando Oh My Zsh…"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  warn "Oh My Zsh já presente"
fi

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  log "Clonando tema Powerlevel10k…"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

PLUGINS=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
  MichaelAquilina/zsh-you-should-use
  fdellwing/zsh-bat
)
for repo in "${PLUGINS[@]}"; do
  name=${repo##*/}
  if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
    log "Clonando plugin $name…"
    git clone --depth=1 "https://github.com/$repo" "$ZSH_CUSTOM/plugins/$name"
  else
    warn "Plugin $name já existe"
  fi
done

ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
  log "Criando ~/.zshrc padrão…"
  cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
fi
log "Garantindo tema e plugins no ~/.zshrc…"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-bat)/' "$ZSHRC"

###############################################################################
# 5. WhiteSur GTK + integração Flatpak ----------------------------------------
###############################################################################
if [ ! -d /usr/share/themes/WhiteSur-Light ]; then
  log "Instalando tema WhiteSur GTK…"
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
  (
    cd WhiteSur-gtk-theme
    ./install.sh -l -o normal -t red -t orange -t blue
    sudo ./tweaks.sh -F -o normal -t red -t orange -t blue
  )
  rm -rf WhiteSur-gtk-theme
else
  warn "Tema WhiteSur já instalado"
fi

###############################################################################
# 6. WhiteSur Icon Theme ------------------------------------------------------
###############################################################################
if [ ! -d /usr/share/icons/WhiteSur-blue ]; then
  log "Instalando ícones WhiteSur…"
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
  (
    cd WhiteSur-icon-theme
    ./install.sh -t red -t orange          # blue é criado por padrão
  )
  rm -rf WhiteSur-icon-theme
else
  warn "Ícones WhiteSur já instalados"
fi

###############################################################################
# 7. Shell padrão -------------------------------------------------------------
###############################################################################
if [ "$SHELL" != "$(command -v zsh)" ]; then
  log "Alterando shell padrão para Zsh…"
  chsh -s "$(command -v zsh)"
else
  warn "Zsh já é o shell padrão"
fi

###############################################################################
log "✅ Instalação concluída (idempotente)!"
log "Caso ainda não tenha, instale a extensão User Themes, Fira Code Nerd Font"
log "e ative o tema WhiteSur no GNOME Tweaks quando quiser."
