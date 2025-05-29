#!/bin/bash
set -euo pipefail

HOME_DIR="$HOME"

function download_files() {
    local share_ip="$1"
    echo "[*] Downloading folders and files from http://$share_ip:8000/ into $HOME_DIR ..."

    cd "$HOME_DIR"

    # Download directories and file, preserving directory structure in $HOME
    wget -r -nH --cut-dirs=0 --no-parent --reject "index.html*" \
        "http://$share_ip:8000/apt-vault/" \
        "http://$share_ip:8000/tools/" \
        "http://$share_ip:8000/sliver/" \
        "http://$share_ip:8000/nc_host_oneliner.sh"
		

}

function setup_vault() {
    local team="$1"
    local vault_src="$HOME_DIR/apt-vault"
    local vault_dest="$HOME_DIR/${team}TeamVault"

    if [[ -d "$vault_src" ]]; then
        echo "[*] Copying vault from $vault_src to $vault_dest ..."
        rm -rf "$vault_dest"
        mkdir -p "$vault_dest"
        cp -r "${vault_src}/." "$vault_dest/"
    else
        echo "[!] Vault directory $vault_src not found."
    fi

    if command -v obsidian &>/dev/null; then
        echo "[*] Launching Obsidian vault at $vault_dest ..."
        Obsidian-1.8.10.AppImage "$vault_dest" &
    else
        echo "[!] Obsidian not found. Please open $vault_dest manually."
    fi
}

function connect_sliver() {
    local team="$1"

    echo "Choose Sliver Server:"
    echo "1) 192.168.200.150"
    echo "2) 192.168.200.151"
    read -rp "Enter choice (1/2): " sliver_choice

    case "$sliver_choice" in
        1) sliver_ip="192.168.200.151" ;;
        2) sliver_ip="192.168.200.152" ;;
        *) echo "[!] Invalid Sliver server choice"; return ;;
    esac

    if [[ "$team" == "Purple" ]]; then
        users=(JG NL KH AD)
    else
        users=(LH JK JS BW TM ER)
    fi

    echo "Choose Sliver user:"
    select user in "${users[@]}"; do
        if [[ -n "$user" ]]; then
            echo "[*] Connecting to Sliver $sliver_ip as user $user ..."
            ~/sliver/sliver-client_linux import ~/sliver/certs/"$user".cfg
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
    read -rp "Enter choice (1/2): " cs_choice

    case "$cs_choice" in
        1)
            cs_ip="208.88.129.178"
            location="Russia"
            ;;
        2)
            cs_ip="62.157.140.168"
            location="Germany"
            ;;
        *)
            echo "[!] Invalid Cobalt Strike choice"
            return
            ;;
    esac

    echo "[*] Cobalt Strike server selected: $location"
    echo "Connect with:"
    echo "teamserver $cs_ip P@55w0rd!"
}

function main_menu() {
    echo "===== TEAM MENU ====="
    echo "1) Purple Team"
    echo "2) Red Team"
    read -rp "Select team (1/2): " team_choice

    case "$team_choice" in
        1) team="Purple" ;;
        2) team="Red" ;;
        2) team="Red" ;;
        *) echo "[!] Invalid choice"; exit 1 ;;
    esac

    read -rp "Enter share IP address (e.g. 192.168.200.153): " share_ip

    download_files "$share_ip"
    setup_vault "$team"
    connect_sliver "$team"

    if [[ "$team" == "Red" ]]; then
        connect_cobalt_strike
    fi
	
	
	SLIVER_PATH="$HOME/sliver"

	if ! grep -q "export PATH=\"$SLIVER_PATH:\$PATH\"" "$HOME/.bashrc"; then
		echo "export PATH=\"$SLIVER_PATH:\$PATH\"" >> "$HOME/.bashrc"
		echo "[+] Added Sliver to PATH in .bashrc"
	fi
	
	# Apply to current session
	if ! grep -q "export PATH=\"$SLIVER_PATH:\$PATH\"" "$HOME/.profile"; then
		echo "export PATH=\"$SLIVER_PATH:\$PATH\"" >> "$HOME/.profile"
		echo "[+] Added $SLIVER_PATH to PATH in .profile"
	fi

}

main_menu