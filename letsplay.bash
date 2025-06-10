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

    zenity --info --title="Download" --text="Starting download from $share_ip..."

    (
        wget -q -r -nH --cut-dirs=0 --no-parent --reject "index.html*" "${urls[@]}"
    ) &

    local pid=$!
    local chars=(D E F E N D E R)
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        sleep 0.3
        i=$(( (i + 1) % ${#chars[@]} ))
    done

    wait "$pid"
    zenity --info --title="Download" --text="Download complete."
}

function setup_vault() {
    local team="$1"
    local share_ip="$2"
    local vault_dest="$HOME/apt-vault"

    mkdir -p "$HOME/share"
    sudo mount -t cifs -o username=apt,password=apt,uid=$(id -u),gid=$(id -g),forceuid,forcegid "//$share_ip/apt-vault" "$HOME/share"

    if mountpoint -q "$HOME/share"; then
        zenity --info --title="Vault" --text="Vault mounted successfully."
    else
        zenity --error --title="Vault" --text="Failed to mount vault."
        exit 1
    fi

    if [[ -x "$HOME/share/Obsidian-1.8.10.AppImage" ]]; then
        if [[ $(id -u) -eq 0 ]]; then
            nohup "$HOME/share/Obsidian-1.8.10.AppImage" --no-sandbox "$vault_dest" >/dev/null 2>&1 &
        else
            nohup "$HOME/share/Obsidian-1.8.10.AppImage" "$vault_dest" >/dev/null 2>&1 &
        fi
    else
        zenity --warning --title="Obsidian" --text="Obsidian is not executable. Please launch it manually from ~/share."
    fi
}

function connect_sliver() {
    local team="$1"
    local sliver_ip=""
    local cert_suffix=""
    local users=()

    if [[ "$team" == "Purple" ]]; then
        sliver_ip=$(zenity --list --title="Select Sliver Server" --column="Option" --column="IP" 1 "10.200.200.100" 2 "10.200.200.103" | cut -d ' ' -f2)
        cert_suffix=$([[ "$sliver_ip" == "10.200.200.100" ]] && echo "0" || echo "1")
        users=(JG NL KH AD)
    elif [[ "$team" == "Red" ]]; then
        sliver_ip=$(zenity --list --title="Select Sliver Server" --column="Option" --column="IP" 1 "192.168.200.150" 2 "192.168.200.153" | cut -d ' ' -f2)
        cert_suffix=$([[ "$sliver_ip" == "192.168.200.150" ]] && echo "0" || echo "1")
        users=(LH JK JS BW TM ER)
    else
        zenity --error --title="Sliver" --text="Unknown team selected."
        return
    fi

    user=$(zenity --list --title="Select User Cert" --column="User" "${users[@]}")
    if [[ -n "$user" ]]; then
        ~/sliver/sliver-client_linux import ~/sliver/certs/"$user"."$cert_suffix".cfg
        zenity --info --title="Sliver" --text="Cert imported. Launch with: sliver-client_linux"
    else
        zenity --error --title="Sliver" --text="Invalid selection."
    fi
}

function connect_cobalt_strike() {
    cs_ip=$(zenity --list --title="Select Cobalt Strike Server" --column="Location" --column="IP" Russia "208.88.129.178" Germany "62.157.140.168" | cut -d ' ' -f2)
    if [[ -z "$cs_ip" ]]; then
        zenity --error --title="Cobalt Strike" --text="Invalid server selected."
        return
    fi
    zenity --info --title="Cobalt Strike" --text="Connect with:\ncd CS && ~/CS/cobaltstrike-client.sh $cs_ip P@55w0rd!"
}

function setup_sliver_path() {
    SLIVER_PATH="$HOME/sliver"
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    export PATH="$BIN_DIR:$PATH"

    if [[ ! -f "$BIN_DIR/sliver-client_linux" ]]; then
        ln -sf "$SLIVER_PATH/sliver-client_linux" "$BIN_DIR/sliver-client_linux"
        zenity --info --title="PATH Update" --text="sliver-client_linux added to PATH."
    fi
}

function main_menu() {
    team=$(zenity --list --title="Select Team" --column="Option" --column="Team" 1 "Purple" 2 "Red" | cut -d ' ' -f2)
    if [[ -z "$team" ]]; then
        zenity --error --title="Input" --text="No team selected."
        exit 1
    fi

    share_ip=$(zenity --entry --title="File Share" --text="Enter file share IP (Red: 192.168.200.152 / Purple: 10.200.200.102):")
    if [[ -z "$share_ip" ]]; then
        zenity --error --title="Input" --text="No IP provided."
        exit 1
    fi

    download_files "$share_ip"
    setup_vault "$team" "$share_ip"
    connect_sliver "$team"

    if [[ "$team" == "Red" ]]; then
        connect_cobalt_strike
    fi

    setup_sliver_path
}

main_menu
