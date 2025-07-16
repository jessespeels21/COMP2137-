#!/bin/bash

set -e #This will stop the script if an error occours


configure_netplan() { #function to configure the netplan 
    file="/etc/netplan/01-netcfg.yaml" #variable for netplan file
    ip="192.168.16.21/24" #varable for the set static ip

    if grep -q "ip" "$file"; then #if the file already has the ip then it doesnt change anything
        log "Netplan already configured with $ip"

    else #else the command will continue and change the file
        log "Updating Netplan configuration..."
        sed -i '/addresses:/d' "$file" # deletes the prevoious ip
        sed -i "/dhcp4:/a \ \ \ \ addresses: [$ip]" "$file" #sets the new ip after line dhcp4 as 
        netplan apply #applies the newly changed netplan
        log "Netplan updated and applied with static IP $ip"
    fi
}

fixetchosts() {
    grep -q "192.168.16.21 server1" /etc/hosts || {
        sed -i '/server1/d' /etc/hosts
        echo "192.168.16.21 server1" >> /etc/hosts
        log "/etc/hosts updated with server1"
    }
}

install_software() {
    for pkg in apache2 squid; do
        if dpkg -s $pkg &>/dev/null; then
            log "$pkg is already installed"
        else
            log "Installing $pkg..."
            apt-get update -qq && apt-get install -y $pkg
            log "$pkg installed"
        fi
    done
}





create_users() {
    users=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)

    for user in "${users[@]}"; do
        # Create user if they don't exist
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "Created user: $user"
        fi

        sshdir="/home/$user/.ssh"
        mkdir -p "$sshdir"
        chmod 700 "$sshdir"

        # Generate SSH keys if not already there
        su - "$user" -c '[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -q'
        su - "$user" -c '[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q'

        # Combine both keys into authorized_keys
        cat "$sshdir/id_rsa.pub" "$sshdir/id_ed25519.pub" > "$sshdir/authorized_keys"
        chmod 600 "$sshdir/authorized_keys"
        chown -R "$user:$user" "$sshdir"

        # Extra stuff for dennis
        if [ "$user" = "dennis" ]; then
            usermod -aG sudo dennis
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "$sshdir/authorized_keys"
            echo "Added sudo and extra key for dennis"
        fi
    done

    echo "All users set up"
}

main() {
    log "Starting assignment2 configuration..."

    configure_netplan
    fix_etchosts
    install_software
    create_users

    log "Configuration complete."
}

main
