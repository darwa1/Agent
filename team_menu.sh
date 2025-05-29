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
        "http://$share_ip:8000/nc_host_oneliner.sh" \
		"http://$share_ip:8000/CobaltStrike/"
		

}

function mount_apt_vault() {
    local share_ip="$1"
    local mount_dir="$HOME/share"
    echo "[*] Mounting apt vault from //$share_ip/apt-vault to $mount_dir ..."

    mkdir -p "$mount_dir"

    sudo mount -t cifs -o username=apt,password=apt,uid=1000,gid=1000,forceuid,forcegid \
        "//$share_ip/apt-vault" "$mount_dir"

    if mountpoint -q "$mount_dir"; then
        echo "[*] Mounted apt vault successfully."
    else
        echo "[!] Failed to mount apt vault."
        exit 1
    fi
}

function setup_vault() {
    local team="$1"
    local mount_share=""
    local vault_name=""
    local vault_dest="$HOME/${team}TeamVault"

    if [[ "$team" == "Red" ]]; then
        vault_name="apt-vault"
    elif [[ "$team" == "Purple" ]]; then
        vault_name="purple-vault"
    else
        echo "[!] Unknown team: $team"
        return 1
    fi

    echo "[*] Setting up $team Team vault by mounting the share..."

    mkdir -p "$HOME/share"
    sudo mount -t cifs -o username=apt,password=apt,uid=$(id -u),gid=$(id -g),forceuid,forcegid "//$share_ip/$vault_name" "$HOME/share"

    if [[ $? -ne 0 ]]; then
        echo "[!] Failed to mount the share //$share_ip/$vault_name"
        return 1
    fi

    if [[ -d "$HOME/share" ]]; then
        echo "[*] Vault mounted at $HOME/share"
    else
        echo "[!] Mount point $HOME/share does not exist."
        return 1
    fi

    echo "[*] Preparing vault destination at $vault_dest ..."
    rm -rf "$vault_dest"
    mkdir -p "$vault_dest"
    cp -r "$HOME/share/." "$vault_dest/"

    if [[ -x "$HOME/share/Obsidian-1.8.10.AppImage" ]]; then
        echo "[*] Launching Obsidian vault at $vault_dest ..."
        "$HOME/share/Obsidian-1.8.10.AppImage" "$vault_dest" > /dev/null 2>&1 &
    else
        echo "[!] Obsidian app image not found or not executable at $HOME/share/Obsidian-1.8.10.AppImage"
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
            echo "[*] Importing cert for Server $sliver_ip as user $user ..."
            ~/sliver/sliver-client_linux import ~/sliver/certs/"$user".cfg
			echo "connect with:"
			echo "sliver-client_linux"
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
    echo "cd CS && ~/CS/cobaltstrike-client.sh $cs_ip P@55w0rd!"
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