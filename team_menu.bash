#!/bin/bash
set -euo pipefail

HOME_DIR="$HOME"

function download_files() {
    local share_ip="$1"
    cd "$HOME"
    animated_download "$share_ip"
}

function animated_download() {
    local share_ip="$1"
    local urls=(
        "http://$share_ip:8000/apt-vault/"
        "http://$share_ip:8000/tools/"
        "http://$share_ip:8000/sliver/"
        "http://$share_ip:8000/nc_host_oneliner.sh"
        "http://$share_ip:8000/CS/"
    )

    echo -n "[*] Downloading files: "

    (
        wget -q -r -nH --cut-dirs=0 --no-parent --reject "index.html*" "${urls[@]}"
    ) &

    local pid=$!
    local chars=(D E F E N D E R)
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r[*] Downloading files: "
        for j in $(seq 0 $i); do
            printf "${chars[$j]}"
        done
        sleep 0.3
        i=$(( (i + 1) % ${#chars[@]} ))
    done

    wait "$pid"
    printf "\r[*] Download complete: DEFENDER\n"
}

function setup_vault() {
    local team="$1"
    local share_ip="$2"
    local vault_dest="$HOME/apt-vault"

    echo "[*] Setting up vault by mounting //$share_ip/apt-vault ..."
    mkdir -p "$HOME/share"
    sudo mount -t cifs -o username=apt,password=apt,uid=$(id -u),gid=$(id -g),forceuid,forcegid "//$share_ip/apt-vault" "$HOME/share"

    if mountpoint -q "$HOME/share"; then
        echo "[*] Vault mounted successfully."
    else
        echo "[!] Failed to mount vault."
        exit 1
    fi

    if [[ -x "$HOME/share/Obsidian-1.8.10.AppImage" ]]; then
        echo "[*] Launching Obsidian ..."
        if [[ $(id -u) -eq 0 ]]; then
            nohup "$HOME/share/Obsidian-1.8.10.AppImage" --no-sandbox "$vault_dest" >/dev/null 2>&1 &
        else
            nohup "$HOME/share/Obsidian-1.8.10.AppImage" "$vault_dest" >/dev/null 2>&1 &
        fi
    else
        echo "[!] Obsidian not executable. You can open it manually from ~/share"
    fi
}

function connect_sliver() {
    local team="$1"
    local sliver_ip=""
    local cert_suffix=""
    local users=()

    if [[ "$team" == "Purple" ]]; then
        echo "Choose Sliver Server:"
        echo "1) 10.200.200.100"
        echo "2) 10.200.200.103"
        read -rp "Enter choice (1/2): " sliver_choice

        case "$sliver_choice" in
            1) sliver_ip="10.200.200.100"; cert_suffix="0" ;;
            2) sliver_ip="10.200.200.103"; cert_suffix="1" ;;
            *) echo "[!] Invalid Sliver server choice"; return ;;
        esac

        users=(JG NL KH AD)

    elif [[ "$team" == "Red" ]]; then
        echo "Choose Sliver Server:"
        echo "1) 192.168.200.150"
        echo "2) 192.168.200.153"
        read -rp "Enter choice (1/2): " sliver_choice

        case "$sliver_choice" in
            1) sliver_ip="192.168.200.150"; cert_suffix="0" ;;
            2) sliver_ip="192.168.200.153"; cert_suffix="1" ;;
            *) echo "[!] Invalid Sliver server choice"; return ;;
        esac

        users=(LH JK JS BW TM ER)

    else
        echo "[!] Unknown team: $team"
        return
    fi

    echo "Choose Sliver user:"
    select user in "${users[@]}"; do
        if [[ -n "$user" ]]; then
            echo "[*] Importing cert for $user.$cert_suffix on $sliver_ip ..."
            ~/sliver/sliver-client_linux import ~/sliver/certs/"$user"."$cert_suffix".cfg
            echo ""
            echo "Connect with: sliver-client_linux"
            echo " +++++++++++++++++++++++++++++++++++++++++++++ "
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
        1) cs_ip="208.88.129.178"; location="Russia" ;;
        2) cs_ip="62.157.140.168"; location="Germany" ;;
        *) echo "[!] Invalid Cobalt Strike choice"; return ;;
    esac

    echo "[*] Cobalt Strike server selected: $location"
    echo " +++++++++++++++++++++++++++++++++++++++++++++ "
    echo "Connect with:"
    echo "cd CS && ~/CS/cobaltstrike-client.sh $cs_ip P@55w0rd!"
}

function setup_sliver_path() {
    SLIVER_PATH="$HOME/sliver"
    if [[ $EUID -eq 0 ]]; then
        BIN_DIR="/root/.local/bin"
    else
        BIN_DIR="$HOME/.local/bin"
    fi

    mkdir -p "$BIN_DIR"
    export PATH="$BIN_DIR:$PATH"

    if [[ ! -f "$BIN_DIR/sliver-client_linux" ]]; then
        ln -sf "$SLIVER_PATH/sliver-client_linux" "$BIN_DIR/sliver-client_linux"
        echo "[+] Symlinked sliver-client_linux to $BIN_DIR"
    fi
}

function main_menu() {
    echo "===== TEAM MENU ====="
    echo "1) Purple Team"
    echo "2) Red Team"
    read -rp "Select team (1/2): " team_choice

    case "$team_choice" in
        1) team="Purple" ;;
        2) team="Red" ;;
        *) echo "[!] Invalid choice"; exit 1 ;;
    esac

    read -rp "Enter file share IP (Red: 192.168.200.152 / Purple: 10.200.200.102): " share_ip

    download_files "$share_ip"
    setup_vault "$team" "$share_ip"
    connect_sliver "$team"

    if [[ "$team" == "Red" ]]; then
        connect_cobalt_strike
    fi

    setup_sliver_path
}

main_menu
