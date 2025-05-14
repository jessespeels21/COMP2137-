#!/bin/bash

#ascript to display the hostname, ip address, and gateway ip

# find and display hostname 
echo -n "My hostname: "
hostname

#display ip address
echo -n "My ip: "
ip r s default | awk '{print $9}'

#display gateway ip
echo -n "My default: "
ip r s default | awk '{print $3}'
