#!/bin/bash

#This scipt makes the host have a static IP, updates /etc/hosts, installs
#apache2 and squid unless they are already present
#and creates user accounts with SSH keys. 


set -e #this stops if there's any error

log() {
    echo -e "\e[32m[INFO]\e[0m $1" #print messages in green
}

if [ "$EUID" -ne 0 ]; then
    echo "Run as root" #make sure script is run as root
    exit 1
fi

setupnetplan() {
    config=$(find /etc/netplan -type f | head -n 1) #netplan config file
    ip="192.168.16.21/24" #ip to set

    if grep -q "$ip" "$config"; then
        log "IP already set"
    else
        log "Setting static IP"

        sed -i '/addresses:/d' "$config" #remove old address
        sed -i "/dhcp4:/a \ \ \ \ addresses: [$ip]" "$config" #add new IP
        netplan apply #apply the config

        log "Static IP applied"
    fi
}

fixetchosts() {
    entry="192.168.16.21 server1" #line to add

    if grep -q "$entry" /etc/hosts; then
        log "hosts file already ok"
    else
        sed -i '/server1/d' /etc/hosts #remove any old server1 line
        echo "$entry" >> /etc/hosts #add correct line
        log "hosts file updated"
    fi
}

installsoftware() {
    for pkg in apache2 squid; do
        if dpkg -s "$pkg" &>/dev/null; then
            log "$pkg already installed"
        else
            log "Installing $pkg"
            apt-get update -qq #quiet update
            apt-get install -y "$pkg" #install package
            log "$pkg installed"
        fi
    done
}

createusers() {
    users=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
    sharedkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user" #create user with bash shell
            log "Created $user"
        else
            log "$user already exists"
        fi

        sshfolder="/home/$user/.ssh" #user's ssh folder
        mkdir -p "$sshfolder" #make .ssh folder if missing
        chmod 700 "$sshfolder" #only owner can enter
        chown "$user:$user" "$sshfolder" #set owner of folder

        su - "$user" -c '[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -q' #make RSA key if missing
        su - "$user" -c '[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q' #make ed25519 key if missing

        #add public keys to authorized_keys
        cat "$sshfolder/id_rsa.pub" "$sshfolder/id_ed25519.pub" > "$sshfolder/authorized_keys" #combine both keys
        chmod 600 "$sshfolder/authorized_keys" #only user can read/write file
        chown -R "$user:$user" "$sshfolder" #set owner for whole ssh folder

        if [ "$user" = "dennis" ]; then
            usermod -aG sudo "$user" #add to sudo group
            echo "$sharedkey" >> "$sshfolder/authorized_keys" #add shared key
            log "Gave sudo and extra key to dennis"
        fi
    done

    log "All users set up"
}

main() {
    log "Starting setup"

    setupnetplan
    fixetchosts
    installsoftware
    createusers

    log "Done"
}

main

