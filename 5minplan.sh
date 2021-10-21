#!/bin/bash
# 5 minute plan time boiz
# Alex Collom: Hibobjr#3245
echo "Starting 5 minute plan script..."
mkdir /var/backups

# Passwords
echo "Disabling root"
passwd -l root
usermod -s /sbin/no-login root
echo "REMEMBER TO CHECK MANUALLY FOR OTHER USERS AND CHANGE ALL USER'S PASSWORDS"


# Firewall (basic setup)
echo "Stopping firewalld and installing persistant iptables"
systemctl stop firewalld
systemctl disable firewalld
yum -y install iptables-services
systemctl enable iptables
# save a copy of the original firewall
iptables-save > /var/backups/iptables-original
echo "Flushing and resetting firewall"
iptables -F INPUT
iptables -F FORWARD
iptables -F OUTPUT
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
# Firewall (specific rules)
echo "Adding firewall rules"
# ICMP
iptables -A INPUT -p ICMP --icmp-type 8 -j ACCEPT
iptables -A OUTPUT -p ICMP --icmp-type 0 -j ACCEPT
# SSH
iptables -A INPUT -p TCP --dport 22 -j ACCEPT
iptables -A OUTPUT -p TCP --dport 22 -j ACCEPT
# Minecraft
iptables -A INPUT -p TCP --dport 25565 -j ACCEPT
iptables -A OUTPUT -p TCP --dport 25565 -j ACCEPT
iptables -A INPUT -p UDP --dport 25565 -j ACCEPT
iptables -A OUTPUT -p UDP --dport 25565 -j ACCEPT
# Web acccess from inside (may wish to disable later)
iptables -A OUTPUT -p TCP --dport 80 -j ACCEPT
iptables -A OUTPUT -p TCP --dport 443 -j ACCEPT
# DNS access from inside
iptables -A OUTPUT -p UDP --dport 53 -j ACCEPT
# FTP access from inside (injects)
iptables -A OUTPUT -p TCP --dport 21 -d 10.10.3.200 -j ACCEPT
iptables -A OUTPUT -p TCP --dport 20 -d 10.10.3.200 -j ACCEPT
# backup and save
echo "Backing up iptables"
iptables-save > /etc/sysconfig/iptables
iptables-save > /var/backups/iptables


# SSH Hardening (recreate config from scratch)
echo "Hardening SSH"
# make backup
cp /etc/ssh/sshd_config /var/backups/sshd_config_original
# defaults
echo "HostKey /etc/ssh/ssh_host_rsa_key" > /etc/ssh/sshd_config
echo "HostKey /etc/ssh/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config
echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> /etc/ssh/sshd_config
echo "SyslogFacility AUTHPRIV" >> /etc/ssh/sshd_config
echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
echo "UsePAM yes" >> /etc/ssh/sshd_config
echo "AcceptEnv LANG LC_*" >> /etc/ssh/sshd_config
echo "Subsystem sftp /usr/libexec/openssh/sftp-server" >> /etc/ssh/sshd_config
# hardening
echo "X11Forwarding no" >> /etc/ssh/sshd_config
echo "ClientAliveInterval 180" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "LoginGraceTime 20" >> /etc/ssh/sshd_config
echo "KerberosAuthentication no" >> /etc/ssh/sshd_config
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
echo "PermitUserEnvironment no" >> /etc/ssh/sshd_config
echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config
echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
echo "PermitTunnel no" >> /etc/ssh/sshd_config
echo "PubkeyAuthentication no" >> /etc/ssh/sshd_config
# backup with changes
cp /etc/ssh/sshd_config /var/backups/sshd_config_hardened
# reload
echo "Restarting SSH"
systemctl restart sshd.service

# Reset and backup ICMP options
echo "Hardening ICMP"
echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_all
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo "0" > /proc/sys/net/ipv4/icmp_errors_use_inbound_ifaddr
echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
echo "50" > /proc/sys/net/ipv4/icmp_msgs_burst
# limit ALL ICMP messages to prevent DDoS
echo "100" > /proc/sys/net/ipv4/icmp_msgs_per_sec
echo "100" > /proc/sys/net/ipv4/icmp_ratelimit
echo "524287" > /proc/sys/net/ipv4/icmp_ratemask
# backup
echo "Backing up ICMP"
cp /proc/sys/net/ipv4/icmp_* /var/backups

echo "Script complete! Listing useful information..."
echo "/etc/passwd:"
cat /etc/passwd
echo "--------------------------------------------------------------------------"
echo "User crontabs:"
ls /var/spool/cron -l
echo "--------------------------------------------------------------------------"
echo "system crontab:"
cat /etc/crontab
echo "--------------------------------------------------------------------------"
echo "More system crontabs:"
ls /etc/cron.*
echo "--------------------------------------------------------------------------"
echo "sudoers file:"
cat /etc/sudoers
echo "--------------------------------------------------------------------------"
echo "wheel group:"
grep 'wheel' /etc/group
echo "--------------------------------------------------------------------------"
echo "Global bash profile:"
cat /etc/profile
cat /etc/bash.bashrc
echo "--------------------------------------------------------------------------"
echo "User bash profiles:"
cat /home/*/.bashrc
echo "--------------------------------------------------------------------------"

echo "Remember to check /etc/systemd, Minecraft configuration, ssh connections, check if we need to add AllowUsers for SSH"
echo "Use wireshark"
echo "top or ps aux, w or last ( | grep -i still), netstat -tnpa, pstree -p | grep sshd and kill -9 <PPID from pstree>"
echo "MAKE ALL THE BACKUPS RIGHT NOW: /var/backups"
echo "backup minecraft configs, home directories, etc."

echo "This script has also cleared bash history"
mkdir /var/backups/nope
history > /var/backups/nope/not-the-history-file-lol
history -c