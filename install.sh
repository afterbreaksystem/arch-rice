#!/bin/bash
# =============================================================
#  install.sh — deploy rice after a fresh Arch Linux install
#  Run right after base install with working internet:
#  bash install.sh
# =============================================================
set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_USER="$(whoami)"
CURRENT_HOME="$HOME"

echo "╔══════════════════════════════════════╗"
echo "║       INSTALL RICE + DRIVERS         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Current user: $CURRENT_USER"
echo "Home folder:  $CURRENT_HOME"
echo ""
read -rp "Is this correct? Continue installation? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled. Log in as the correct user and run again."
    exit 1
fi

# ── 1. Base dependencies + multilib ──────────────────────────
echo ""
echo "==> [1/6] Base packages..."
sudo pacman -Sy --needed --noconfirm git base-devel

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
    sudo sed -i '/^\[multilib\]/{n;s/^#//}' /etc/pacman.conf
    sudo pacman -Sy
    echo "    ✓ multilib enabled"
fi

# ── 2. Install yay ───────────────────────────────────────────
echo ""
echo "==> [2/6] Installing yay..."
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm && cd "$DOTDIR"
    echo "    ✓ yay installed"
else
    echo "    ✓ yay already installed"
fi

# ── 3. NVIDIA drivers ────────────────────────────────────────
echo ""
echo "==> [3/6] NVIDIA drivers (nvidia-580xx-dkms)..."
yay -S --needed --noconfirm \
    nvidia-580xx-dkms \
    nvidia-580xx-utils \
    lib32-nvidia-580xx-utils

echo "    ✓ NVIDIA drivers installed"
echo "    ⚠ Remember: add nvidia_drm.modeset=1 to GRUB and nvidia modules to mkinitcpio"

# ── 4. Hyprland + rice dependencies ─────────────────────────
echo ""
echo "==> [4/6] Hyprland + rice dependencies..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprlock \
    hyprpicker \
    hyprshot \
    hyprpolkitagent \
    xdg-desktop-portal-hyprland \
    qt5-wayland \
    qt6-wayland \
    uwsm \
    waybar \
    swaync \
    rofi \
    kitty \
    sddm \
    pipewire-alsa \
    pipewire-pulse \
    wireplumber \
    fish \
    neovim \
    fastfetch \
    grim \
    slurp \
    satty \
    cliphist \
    wlsunset \
    swaybg \
    pamixer \
    pavucontrol \
    networkmanager \
    nm-connection-editor \
    thunar \
    gvfs \
    gvfs-mtp \
    udisks2 \
    polkit-kde-agent \
    nwg-look \
    python-pip \
    imagemagick \
    starship \
    ttf-jetbrains-mono \
    ttf-jetbrains-mono-nerd \
    ttf-iosevka-nerd \
    noto-fonts-emoji \
    noto-fonts-cjk \
    noto-fonts \
    flatpak \
    cpupower \
    gamemode \
    linux-headers

echo "    ✓ Main packages installed"

# ── 5. AUR packages ──────────────────────────────────────────
echo ""
echo "==> [5/6] AUR packages..."
yay -S --needed --noconfirm \
    awww \
    walrs \
    bibata-cursor-theme-bin \
    wlogout \
    nvibrant-cli \
    ttf-all-the-icons \
    ttf-material-design-icons-desktop-git \
    ttf-material-design-icons-git \
    ttf-monocraft-git \
    mullvad-vpn-bin \
    pfetch \
    peaclock \
    pipes.sh \
    apple-fonts

echo "    ✓ AUR packages installed"

echo ""
echo "==> Building hyprselect from GitHub..."
sudo pacman -S --needed --noconfirm cmake
git clone https://github.com/jmanc3/hyprselect "$CURRENT_HOME/hyprselect"
cd "$CURRENT_HOME/hyprselect"
make
cd "$DOTDIR"
echo "    ✓ hyprselect built (source kept in $CURRENT_HOME/hyprselect)"

echo ""
echo "==> Installing pywal16..."
pip install pywal16 --break-system-packages
export PATH="$CURRENT_HOME/.local/bin:$PATH"
echo "    ✓ pywal16 installed"

# ── 6. Deploy configs ────────────────────────────────────────
echo ""
echo "==> [6/6] Deploying configs..."
mkdir -p "$CURRENT_HOME/.config"

RICE_CONFIGS=(
    hypr
    waybar
    swaync
    rofi
    kitty
    nvim
    fish
    wlogout
    walrs
    fastfetch
    nwg-look
    gtk-3.0
    gtk-4.0
    sxhkd
    wal
)

for cfg in "${RICE_CONFIGS[@]}"; do
    src="$DOTDIR/configs/$cfg"
    dst="$CURRENT_HOME/.config/$cfg"
    if [ -d "$src" ]; then
        if [ -d "$dst" ]; then
            echo "    ! $cfg already exists — skipping"
        else
            cp -r "$src" "$dst"
            echo "    ✓ $cfg"
        fi
    fi
done

if [ -f "$DOTDIR/configs/starship.toml" ]; then
    cp "$DOTDIR/configs/starship.toml" "$CURRENT_HOME/.config/starship.toml"
    echo "    ✓ starship.toml"
fi

if [ -d "$DOTDIR/wallpapers" ]; then
    cp -r "$DOTDIR/wallpapers" "$CURRENT_HOME/wallpapers"
    echo "    ✓ wallpapers"
fi

# ── Fix username paths ───────────────────────────────────────
echo ""
echo "==> Fixing username paths in configs..."
bash "$DOTDIR/fix-username.sh"

# ── Rofi theme ───────────────────────────────────────────────
echo ""
echo "==> Setting up rofi theme..."
git clone https://github.com/newmanls/rofi-themes-collection.git /tmp/rofi-themes
sudo mkdir -p /usr/share/rofi/themes/template
sudo cp -r /tmp/rofi-themes/themes/. /usr/share/rofi/themes/

curl -s https://raw.githubusercontent.com/newmanls/rofi-themes-collection/master/themes/template/rounded-template.rasi \
    -o /tmp/rounded-template-orig.rasi

sudo bash -c "{ echo '@import \"$CURRENT_HOME/.cache/wal/colors-rofi-dark.rasi\"'
echo '* {'
echo '    bg0: @background;'
echo '    bg1: @color0;'
echo '    bg2: @color1;'
echo '    bg3: @color2;'
echo '    fg0: @foreground;'
echo '    fg1: @color7;'
echo '    fg2: @color8;'
echo '    fg3: @color1;'
echo '}'
cat /tmp/rounded-template-orig.rasi; } > /usr/share/rofi/themes/template/rounded-template.rasi"

sudo cp /usr/share/rofi/themes/template/rounded-template.rasi /usr/share/rofi/themes/rounded-template.rasi
sudo mkdir -p /root/.config/rofi
sudo cp -r "$CURRENT_HOME/.config/rofi/." /root/.config/rofi/
echo "    ✓ rofi theme installed"

# ── Shell + services ─────────────────────────────────────────
echo ""
echo "==> Changing shell to fish..."
chsh -s "$(which fish)"

echo ""
echo "==> Enabling services..."
sudo systemctl enable NetworkManager
sudo systemctl enable sddm
sudo systemctl enable cpupower
echo "    ✓ Services enabled"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ALL DONE!                                               ║"
echo "║                                                          ║"
echo "║  Manual steps after reboot:                             ║"
echo "║  1. GRUB: add nvidia_drm.modeset=1                      ║"
echo "║  2. mkinitcpio.conf: add nvidia modules, run mkinitcpio  ║"
echo "║  3. Run: wal -i ~/wallpapers/yourwallpaper.png           ║"
echo "║  4. Set saturation: nvibrant DVI-D-1 200                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
