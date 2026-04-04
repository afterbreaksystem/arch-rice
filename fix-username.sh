#!/bin/bash
# =============================================================
#  fix-username.sh — replaces old hardcoded username paths
#  with the current user in all config files
#  Run: bash fix-username.sh
# =============================================================

CURRENT_USER="$(whoami)"
CURRENT_HOME="$HOME"

echo "╔══════════════════════════════════════════╗"
echo "║          FIX USERNAME IN CONFIGS         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Current user: $CURRENT_USER"
echo "Current home: $CURRENT_HOME"
echo ""

OLD_USERS=("vdaseuu" "iwannabedead")

for old_user in "${OLD_USERS[@]}"; do
    if [ "$old_user" = "$CURRENT_USER" ]; then
        echo "    - Skipping $old_user (that's you)"
        continue
    fi

    echo "==> Replacing /home/$old_user → $CURRENT_HOME ..."

    found=$(grep -rl "/home/$old_user" "$CURRENT_HOME/.config/" 2>/dev/null || true)

    if [ -z "$found" ]; then
        echo "    - Nothing found with /home/$old_user"
    else
        echo "$found" | while read -r file; do
            sed -i "s|/home/$old_user|$CURRENT_HOME|g" "$file"
            echo "    ✓ $file"
        done
    fi

    # System rofi themes
    if sudo grep -rl "/home/$old_user" /usr/share/rofi/themes/ 2>/dev/null | grep -q .; then
        sudo grep -rl "/home/$old_user" /usr/share/rofi/themes/ 2>/dev/null | \
            xargs sudo sed -i "s|/home/$old_user|$CURRENT_HOME|g"
        echo "    ✓ Fixed system rofi themes"
    fi

    # Root rofi config
    if sudo test -d /root/.config/rofi 2>/dev/null; then
        sudo grep -rl "/home/$old_user" /root/.config/rofi/ 2>/dev/null | \
            xargs -r sudo sed -i "s|/home/$old_user|$CURRENT_HOME|g"
        echo "    ✓ Fixed root rofi config"
    fi
done

echo ""
echo "==> Verifying — remaining old paths:"
for old_user in "${OLD_USERS[@]}"; do
    if [ "$old_user" = "$CURRENT_USER" ]; then continue; fi
    remaining=$(grep -rl "/home/$old_user" "$CURRENT_HOME/.config/" 2>/dev/null || true)
    if [ -n "$remaining" ]; then
        echo "    ⚠ Still found /home/$old_user in:"
        echo "$remaining" | sed 's/^/      /'
    else
        echo "    ✓ No more /home/$old_user found"
    fi
done

echo ""
echo "Done! Restart Hyprland or reboot to apply."
