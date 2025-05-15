#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 1. Pacotes base, fontes e dependências de temas -----------------------------
###############################################################################
sudo apt update
sudo apt install -y \
  git curl zip zsh fonts-powerline \
  gnome-tweaks gnome-software-plugin-flatpak # plugin Flatpak para a GUI :contentReference[oaicite:0]{index=0}

###############################################################################
# 2. Node.js LTS (repo oficial NodeSource) ------------------------------------
###############################################################################
if ! command -v node >/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

###############################################################################
# 3. Flatpak, Flathub e apps Flatpak ------------------------------------------
###############################################################################
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub \
     https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub com.mattjakeman.ExtensionManager   # Extension Manager GUI
# VsCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/code stable main"
sudo apt update && sudo apt install -y code

###############################################################################
# 4. Oh My Zsh, tema Powerlevel10k e plugins ----------------------------------
###############################################################################
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k"

for repo in \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions \
  MichaelAquilina/zsh-you-should-use \
  fdellwing/zsh-bat
do
  name=${repo##*/}
  [ -d "$ZSH_CUSTOM/plugins/$name" ] || \
    git clone --depth=1 https://github.com/$repo "$ZSH_CUSTOM/plugins/$name"
done

# Ajusta (ou cria) ~/.zshrc
ZSHRC="$HOME/.zshrc"
[ -f "$ZSHRC" ] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"

sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions you-should-use zsh-bat)/' "$ZSHRC"

###############################################################################
# 5. Tema WhiteSur GTK (com Flatpak) ------------------------------------------
###############################################################################
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
(
  cd WhiteSur-gtk-theme
  # Instala variantes pedidas
  ./install.sh -l -o normal \
               -t red -t orange -t blue         # acentos de cor :contentReference[oaicite:2]{index=2}

  # Conecta o tema aos apps Flatpak
  sudo flatpak override --filesystem=xdg-config/gtk-3.0 && sudo flatpak override --filesystem=xdg-config/gtk-4.0
  
  sudo ./tweaks.sh -F -o normal \
                   -t red -t orange -t blue     # var. flatpak :contentReference[oaicite:3]{index=3}
)
rm -rf WhiteSur-gtk-theme

###############################################################################
# 6. WhiteSur Icon Theme -------------------------------------------------------
###############################################################################
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
(
  cd WhiteSur-icon-theme
  ./install.sh -t red -t orange -t blue -a       # variantes + ícones alternativos :contentReference[oaicite:4]{index=4}
)
rm -rf WhiteSur-icon-theme

###############################################################################
# 7. Define o Zsh como shell padrão (uma única vez) ---------------------------
###############################################################################
if [ "$SHELL" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)"
  echo "⚠️  Faça logout/login para o Zsh tornar-se o shell padrão."
fi

echo -e "\n✅ Instalação concluída!"
echo "Instale a extensão User Themes e defina o tema desejado."
echo "Instale a fonte Fira code e defina como padrão do terminal."
echo "Abra um novo terminal, passe pelo assistente do Powerlevel10k se quiser"
echo "personalizar o prompt e, no GNOME Tweaks, selecione o tema WhiteSur"
echo "para Aplicativos, Shell e Ícones caso ele ainda não esteja ativo."
