#!/bin/bash
# Password Changing Script
# Alex Collom: Hibobjr#3245
echo "This script changes passwords and locks the account (since the accounts we need were already used)"
echo "Usage: ./chngpasswd.sh <username> <password>"
echo -e "$2\n$2" | passwd $1 
passwd -l $1
usermod -s /sbin/no-login $1
history -c