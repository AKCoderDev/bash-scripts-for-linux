#secure-ssh-setup.sh
Give the script execution permissions:

chmod +x secure-ssh-setup.sh

Run the script with root privileges:

sudo ./secure-ssh-setup.sh

If you plan to load your SSH key from a USB stick:
Edit the script and uncomment the USB-related section near the top.
Make sure to update:
The USB device path (e.g. /dev/sdb1)
The key file path (e.g. /mnt/usb/id_ed25519.pub)
Check Line Endings (If Edited on Windows)
If you edited the file on Windows, convert line endings to Unix format to avoid errors:

sudo apt install dos2unix
dos2unix secure-ssh-setup.sh
