#!/bin/bash
# =============================================================
#  install.sh — разворачивает райс после переустановки Arch
#  Запусти сразу после базовой установки Arch + рабочего интернета:
#  bash install.sh
# =============================================================
set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔══════════════════════════════════════╗"
echo "║       INSTALL RICE + DRIVERS         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Текущий пользователь: $(whoami)"
echo "Домашняя папка:       $HOME"
echo ""
read -rp "Всё верно? Продолжить установку? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Отменено. Залогинься под нужным пользователем и запусти снова."
    exit 1
fi

# ── 1. Базовые зависимости ───────────────────────────────────
echo ""
echo "==> [1/5] Базовые пакеты..."
sudo pacman -Sy --needed --noconfirm git base-devel

# ── 2. NVIDIA драйверы (КРИТИЧНО — в первую очередь) ─────────
echo ""
echo "==> [2/5] NVIDIA драйверы (nvidia-580xx-dkms)..."
echo "    Это AUR пакет, сначала ставим yay..."

if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm && cd "$DOTDIR"
    echo "    ✓ yay установлен"
fi

echo "    Устанавливаем nvidia-580xx-dkms + утилиты..."
yay -S --needed --noconfirm \
    nvidia-580xx-dkms \
    nvidia-580xx-utils \
    lib32-nvidia-580xx-utils

echo "    ✓ NVIDIA драйверы установлены"
echo ""
echo "    ⚠ Не забудь после установки:"
echo "      - Добавить nvidia_drm.modeset=1 в параметры ядра (grub)"
echo "      - Добавить nvidia nvidia_modeset nvidia_uvm nvidia_drm в initramfs"

# ── 3. Ядро Hyprland и зависимости райса ─────────────────────
echo ""
echo "==> [3/5] Hyprland + зависимости райса..."
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
    wlogout \
    rofi \
    kitty \
    sddm \
    pipewire-alsa \
    pipewire-pulse \
    wireplumber \
    fish \
    neovim \
    btop \
    fastfetch \
    cava \
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
    matugen \
    python-pip \
    python-pipx \
    ttf-jetbrains-mono \
    ttf-jetbrains-mono-nerd \
    ttf-iosevka-nerd \
    noto-fonts-emoji \
    noto-fonts-cjk \
    flatpak \
    cpupower \
    gamemode

echo "    ✓ Основные пакеты установлены"

# ── 4. AUR пакеты райса ──────────────────────────────────────
echo ""
echo "==> [4/5] AUR пакеты райса..."
yay -S --needed --noconfirm \
    awww \
    walrs \
    bibata-cursor-theme-bin \
    wlogout \
    ttf-all-the-icons \
    ttf-material-design-icons-desktop-git \
    ttf-material-design-icons-git \
    ttf-monocraft-git \
    mullvad-vpn-bin \
    pfetch \
    peaclock \
    pipes.sh \
    apple-fonts

echo "    ✓ AUR пакеты установлены"

# ── 5. Раскладываем конфиги ──────────────────────────────────
echo ""
echo "==> [5/5] Раскладываем конфиги..."
mkdir -p "$HOME/.config"

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
    matugen
    fastfetch
    btop
    cava
    eww
    quickshell
    wofi
    sxhkd
    nwg-look
    gtk-3.0
    gtk-4.0
)

for cfg in "${RICE_CONFIGS[@]}"; do
    src="$DOTDIR/configs/$cfg"
    dst="$HOME/.config/$cfg"
    if [ -d "$src" ]; then
        if [ -d "$dst" ]; then
            echo "    ! $cfg уже существует — пропускаем"
        else
            cp -r "$src" "$dst"
            echo "    ✓ $cfg"
        fi
    fi
done

# starship.toml
if [ -f "$DOTDIR/configs/starship.toml" ]; then
    cp "$DOTDIR/configs/starship.toml" "$HOME/.config/starship.toml"
    echo "    ✓ starship.toml"
fi

# Обои
if [ -d "$DOTDIR/wallpapers" ]; then
    cp -r "$DOTDIR/wallpapers" "$HOME/wallpapers"
    echo "    ✓ wallpapers"
fi

# ── Shell → fish ─────────────────────────────────────────────
echo ""
echo "==> Меняем shell на fish..."
chsh -s "$(which fish)"

# ── Включаем сервисы ─────────────────────────────────────────
echo ""
echo "==> Включаем сервисы..."
sudo systemctl enable NetworkManager
sudo systemctl enable sddm
sudo systemctl enable cpupower
echo "    ✓ Сервисы включены"

# ── Итог ────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ВСЁ ГОТОВО!                                         ║"
echo "║                                                      ║"
echo "║  Что сделать вручную после перезагрузки:             ║"
echo "║  1. Настроить GRUB: nvidia_drm.modeset=1             ║"
echo "║  2. pywal: pip install pywal (или walrs настроить)   ║"
echo "║  3. Flatpak: flatpak install flathub ...             ║"
echo "║  4. Проверить walrs / wal-smart функцию в fish       ║"
echo "╚══════════════════════════════════════════════════════╝"
