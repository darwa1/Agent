#!/bin/bash

set -e

function download_and_move() {
    local team=$1
    VAULT_DIR="$HOME/${team}TeamVault"

    read -p "Enter the IP address of the file share (e.g., 192.168.200.153): " SHARE_IP

    echo "[*] Downloading files from http://$SHARE_IP:8000/ directly to $HOME ..."

    cd "$HOME"

    # Download folders and file directly into home directory
    wget -r -nH --cut-dirs=0 --no-parent --reject "index.html*" \
        "http://$SHARE_IP:8000/apt-vault/" \
        "http://$SHARE_IP:8000/tools/" \
        "http://$SHARE_IP:8000/sliver/" \
        "http://$SHARE_IP:8000/nc_host_oneliner.sh"

    # Set up vault directory
    VAULT_SOURCE="$HOME/apt-vault"
    if [ -d "$VAULT_SOURCE" ]; then
        echo "[*] Setting up vault in $VAULT_DIR ..."
        rm -rf "$VAULT_DIR"
        mkdir -p "$VAULT_DIR"
        cp -r "$VAULT_SOURCE/"* "$VAULT_DIR/"
    else
        echo "[!] Vault not found at apt-vault/"
    fi

    echo "[+] Vault ready at $VAULT_DIR"

    if command -v obsidian &>/dev/null; then
        obsidian "$VAULT_DIR" &
    else
        echo "[!] Obsidian not found in PATH. Please open the vault manually."
    fi
}

function connect_sliver() {
    local team=$1

    echo "Choose Sliver Server:"
    echo "1) 192.168.200.151"
    echo "2) 192.168.200.152"
    read -p "Enter your choice (1/2): " SLIVER_OPT

    if [[ "$SLIVER_OPT" == "1" ]]; then
        SLIVER_IP="192.168.200.151"
    elif [[ "$SLIVER_OPT" == "2" ]]; then
        SLIVER_IP="192.168.200.152"
    else
        echo "Invalid Sliver option"
        return
    fi

    echo "Choose User:"
    if [[ "$team" == "Purple" ]]; then
        USERS=("JG" "NL" "KH" "AD")
    else
        USERS=("LH" "JK" "JS" "BW" "TM" "ER")
    fi

    select USERNAME in "${USERS[@]}"; do
        if [[ -n "$USERNAME" ]]; then
            echo "[*] Connecting to Sliver at $SLIVER_IP with cert $USERNAME..."
            sliver --connect $SLIVER_IP --cert ~/.sliver/certs/$USERNAME.crt --key ~/.sliver/certs/$USERNAME.key
            break
        else
            echo "Invalid selection."
        fi
    done
}

function connect_cobalt_strike() {
    echo "Choose Cobalt Strike Teamserver:"
    echo "1) Russia (208.88.129.178)"
    echo "2) Germany (62.157.140.168)"
    read -p "Enter your choice (1/2): " C2_CHOICE

    case $C2_CHOICE in
        1)
            C2_IP="208.88.129.178"
            LOCATION="Russia"
            ;;
        2)
            C2_IP="62.157.140.168"
            LOCATION="Germany"
            ;;
        *)
            echo "[!] Invalid selection."
            return
            ;;
    esac

    echo "[*] Cobalt Strike Teamserver selected: $LOCATION"
    echo ">> Connect using the following command:"
    echo "teamserver $C2_IP P@55w0rd!"
}

### === MAIN MENU === ###
clear
echo "==== TEAM MENU ===="
echo "1) Purple Team"
echo "2) Red Team"
read -p "Choose a team: " TEAM_OPT

case $TEAM_OPT in
    1)
        TEAM="Purple"
        ;;
    2)
        TEAM="Red
