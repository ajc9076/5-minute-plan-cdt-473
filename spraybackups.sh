#!/bin/bash
# Spread backups out into multiple locations
# Alex Collom: Hibobjr#3245
mkdir -p /home/localguard/Documents/dankmemes
cp /var/backups /home/localguard/Documents/dankmemes -r

mkdir -p /var/tmp/backups
cp /var/backups /var/tmp/backups -r

mkdir -p /backups
cp /var/backups /backups -r

mkdir -p /home/root/default/system/reserved/systemctl-misc/cache
cp /var/backups /home/root/default/system/reserved/systemctl-misc/cache -r

mkdir -p /root/tmp/files
cp /var/backups /root/tmp/files -r
