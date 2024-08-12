#!/bin/bash

THEME='arch'
GRUB_DIR='grub'

# Pre-authorise sudo
sudo -v

# Colors
CDEF="\033[0m"
b_CCIN="\033[1;36m"
b_CGSC="\033[1;32m"
b_CRER="\033[1;31m"
b_CWAR="\033[1;33m"

# Print message with flag type to change message color
prompt() {
    case "$1" in
    "-s") color=$b_CGSC ;;
    "-e") color=$b_CRER ;;
    "-w") color=$b_CWAR ;;
    "-i") color=$b_CCIN ;;
    *) color="" ;;
    esac
    shift
    echo -e "${color}${*}${CDEF}"
}

# Check if theme directory exists
if [ ! -d "${THEME}" ]; then
    prompt -e "\nError: Directory ${b_CWAR}${THEME}${b_CRER} does not exist.\n"
    exit 1
fi

# Welcome message
prompt -s "\n\t\t*  GRUB Bootloader Theme Installation  *\n"

# Wait before installing
for ((i = 10; i > 0; i--)); do
    prompt -i "\rPress Enter to install ${b_CWAR}${THEME}${b_CCIN} theme (automatically install in ${b_CWAR}${i}${b_CCIN}s): \c"
    read -n 1 -s -t 1 && break
done

# Detect distro and set GRUB location and update method
if [ -e /etc/os-release ]; then
    source /etc/os-release
    case "$ID" in
    debian | ubuntu | solus | *debian | *ubuntu)
        UPDATE_GRUB='update-grub'
        ;;
    arch | manjaro | gentoo | *archlinux | *manjaro | *gentoo)
        UPDATE_GRUB='grub-mkconfig -o /boot/grub/grub.cfg'
        ;;
    centos | fedora | opensuse | *fedora | *rhel | *suse)
        GRUB_DIR='grub2'
        GRUB_CFG_PATH='/boot/grub2/grub.cfg'
        if [ -d /boot/efi/EFI/${ID} ]; then
            GRUB_CFG_PATH="/boot/efi/EFI/${ID}/grub.cfg"
        fi
        UPDATE_GRUB="grub2-mkconfig -o ${GRUB_CFG_PATH}"
        ;;
    *)
        prompt -e "\nCannot detect your distro.\n"
        prompt -e "You will need to run \`grub-mkconfig\` or \`grub2-mkconfig\` as root manually."
        prompt -e "For Debian/Ubuntu/Solus: \`update-grub\` or \`grub-mkconfig -o /boot/grub/grub.cfg\`"
        prompt -e "For RHEL/CentOS/Fedora/SUSE: \`grub2-mkconfig -o /boot/grub2/grub.cfg\`"
        prompt -e "For Arch/Gentoo: \`grub-mkconfig -o /boot/grub/grub.cfg\`"
        exit 1
        ;;
    esac
fi

prompt -i "\n\nRemoving previous version of ${b_CWAR}${THEME}${b_CCIN} theme if it exists"
sudo rm -rf "/boot/${GRUB_DIR}/themes/${THEME}" || true

prompt -i "\nCreating ${b_CWAR}${THEME}${b_CCIN} theme directory under /boot/${GRUB_DIR}/themes/"
sudo mkdir -p "/boot/${GRUB_DIR}/themes/${THEME}"

prompt -i "\nCopying ${b_CWAR}${THEME}${b_CCIN} theme to previously created directory"
sudo cp -r "${THEME}"/* "/boot/${GRUB_DIR}/themes/${THEME}"

if grep -q "GRUB_THEME=" /etc/default/grub; then
    # Replace GRUB_THEME
    sudo sed -i "s|.*GRUB_THEME=.*|GRUB_THEME=\"/boot/${GRUB_DIR}/themes/${THEME}/theme.txt\"|" /etc/default/grub
else
    # Append GRUB_THEME
    echo "GRUB_THEME=\"/boot/${GRUB_DIR}/themes/${THEME}/theme.txt\"" | sudo tee -a /etc/default/grub >/dev/null
fi

if grep -q "GRUB_BACKGROUND=" /etc/default/grub; then
    # Replace GRUB_BACKGROUND
    sudo sed -i "s|.*GRUB_BACKGROUND=.*|GRUB_BACKGROUND=\"/boot/${GRUB_DIR}/themes/${THEME}/background.png\"|" /etc/default/grub
else
    # Append GRUB_BACKGROUND
    echo "GRUB_BACKGROUND=\"/boot/${GRUB_DIR}/themes/${THEME}/background.png\"" | sudo tee -a /etc/default/grub >/dev/null
fi

prompt -i "\nUpdating GRUB"
if [ -n "$UPDATE_GRUB" ]; then
    sudo $UPDATE_GRUB
    prompt -s "\n\t\t*  Successfully installed  *"
else
    prompt -e ---------------------------------------------------------------------------------------
    prompt -e "Cannot detect your distro, you will need to run \`grub-mkconfig\` as root manually."
    prompt -e "For Debian/Ubuntu/Solus: \`update-grub\` or \`grub-mkconfig -o /boot/grub/grub.cfg\`"
    prompt -e "For RHEL/CentOS/Fedora/SUSE: \`grub2-mkconfig -o /boot/grub2/grub.cfg\`"
    prompt -e "For Arch/Gentoo: \`grub-mkconfig -o /boot/grub/grub.cfg\`"
    prompt -e ---------------------------------------------------------------------------------------
fi
