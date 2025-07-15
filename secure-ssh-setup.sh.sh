#!/bin/bash

# === Configuration ===
NEW_USER="secureuser"                   # Name of the new user to create
SSH_PORT=22	                        # SSH port

# === [Optional] Load SSH public key from USB drive ===
# UNCOMMENT the lines below if you want to auto-mount a USB stick and read the key from it
#
# echo "[0/8] Attempting to mount USB and load SSH key"
# USB_DEVICE="/dev/sdb1"                     # Change this to match your USB device (check with lsblk)
# MOUNT_POINT="/mnt/usb"
# KEY_PATH="$MOUNT_POINT/id_ed25519.pub"    # Path to public key on USB
# mkdir -p "$MOUNT_POINT"
# mount "$USB_DEVICE" "$MOUNT_POINT"
# if [ -f "$KEY_PATH" ]; then
#     PUB_KEY=$(cat "$KEY_PATH")
#     echo "[0/8] SSH public key loaded from USB"
# else
#     echo "ERROR: SSH public key not found at $KEY_PATH"
#     exit 1
# fi

PUB_KEY="ssh-ed25519 AAAAC3NzaC1... your public SSH key ..."  # Replace with your actual public key

# === Add a new user ===
echo "[1/8] Creating user '$NEW_USER'"
adduser --disabled-password --gecos "" $NEW_USER
usermod -aG sudo $NEW_USER

# === Set up SSH key for the new user ===
echo "[2/8] Setting up SSH key for $NEW_USER"
mkdir -p /home/$NEW_USER/.ssh
echo "$PUB_KEY" > /home/$NEW_USER/.ssh/authorized_keys
chmod 700 /home/$NEW_USER/.ssh
chmod 600 /home/$NEW_USER/.ssh/authorized_keys
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

# === Configure sshd ===
echo "[3/8] Configuring SSH daemon (/etc/ssh/sshd_config)"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

sed -i "s/^#*Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/^#*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^#*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config

# Restrict login to specific user
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
  echo "AllowUsers $NEW_USER" >> /etc/ssh/sshd_config
else
  sed -i "s/^AllowUsers.*/AllowUsers $NEW_USER/" /etc/ssh/sshd_config
fi

# === Set up UFW firewall ===
echo "[4/8] Setting up UFW firewall"
apt-get update
apt-get install -y ufw
ufw allow $SSH_PORT/tcp
ufw --force enable

# === Install and configure Fail2Ban ===
echo "[5/8] Installing Fail2Ban"
apt-get install -y fail2ban

# Create Fail2Ban jail config for SSH
cat <<EOF > /etc/fail2ban/jail.d/sshd.conf
[sshd]
enabled = true
port = $SSH_PORT
maxretry = 3
bantime = 1h
EOF

# === Restart services ===
echo "[6/8] Restarting sshd and fail2ban"
systemctl restart sshd
systemctl restart fail2ban

# === Verify access and firewall rules ===
echo "[7/8] Checking SSH port and UFW status"
ufw status verbose
ss -tuln | grep ":$SSH_PORT"

# === Done ===
echo "[8/8] Secure SSH setup complete!"
echo "You can now connect with: ssh $NEW_USER@your_server_ip -p $SSH_PORT"
