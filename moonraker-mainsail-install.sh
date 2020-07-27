#!/bin/bash
# This script installs Mainsail for Klipper on an debian image
#

PYTHONDIR="${HOME}/klippy-env"
SYSTEMDDIR="/etc/systemd/system"
MOONRAKER_USER=$USER
KLIPPER_USER=$USER
KLIPPER_GROUP=$KLIPPER_USER
KWC="https://github.com/meteyou/mainsail/releases/download/v0.1.0/mainsail-beta-0.1.0.zip"

# Step 1: Install system packages
install_packages()
{
    # Packages for wget
    PKGLIST="${PKGLIST} wget"
    # Packages for gzip
    PKGLIST="${PKGLIST} gzip"
    # Packages for tar
    PKGLIST="${PKGLIST} tar"
    # Packages for unzip
    PKGLIST="${PKGLIST} unzip"
    
    # Update system package info
    report_status "Running apt-get update..."
    sudo apt-get update

    # Install desired packages
    report_status "Installing packages..."
    sudo apt-get install --yes ${PKGLIST}
}

# Step 2: stop klipper
stop_klipper()
{
    report_status "stopping klipper..."
    sudo systemctl stop klipper
}

#step 3: run blackstump script
blkstump()
{
  ${SRCDIR}/mainsail-install/blackstump.sh
}

#step 4: install moonraker
install_moonraker()
{
  ${SRCDIR}/moonraker/scripts/install-debianmoonraker.sh
  cd ~/
}

#step 5: install nginx config
install-nginxcfg()
{
  report_status "Installing symbolic link..."
    FILE=/etc/nginx/sites-available/mainsail
    if [ -e "$FILE" ];
    then
        echo "$FILE exist"
    else
        echo "$FILE does not exist"
        
NGINXDIR="/etc/nginx/sites-available"
sudo /bin/sh -c "cp ~/mainsail-install/mainsail $NGINXDIR/" 

        sudo ln -s /etc/nginx/sites-available/mainsail /etc/nginx/sites-enabled/
        sudo rm /etc/nginx/sites-enabled/default
        sudo systemctl restart nginx
    fi
}

# Step 5: clone mainsail git
install_mainsail()
{
    report_status "installing mainsail "
    FILE=~/mainsail
    if [ -d "$FILE" ]; then
        echo "$FILE exist"
    else
        echo "$FILE does not exist"
        mkdir ~/mainsail ~/sdcard
        cd ~/mainsail
        wget -q -O mainsail.zip ${KWC} && unzip mainsail.zip && rm mainsail.zip
        cd ~/
     fi
}


# Step 5 add mainsail to printer.cfg
add_mainsail()
{
  if
  FILE="${SRCDIR}/printer.cfg"
  LINE="trusted_clients:"
    grep -q -- "$LINE" "$FILE"
      then
        echo "moonraker exist"
  else
      sed -i '/#*# <---------------------- SAVE_CONFIG ---------------------->/i[virtual_sdcard]\npath: ~/sdcard\n' ~/printer.cfg
      sed -i '/#*# <---------------------- SAVE_CONFIG ---------------------->/i[moonraker]\ntrusted_clients:\n  192.168.2.0/24\n  127.0.0.0/24\nenable_cors:  True\n' ~/printer.cfg
      sleep 1
      LINE1="#*# <---------------------- SAVE_CONFIG ---------------------->"
      grep -xqFs -- "$LINE1" "$FILE" || sed -i '$a[virtual_sdcard]\npath: ~/sdcard\n[moonraker]\ntrusted_clients:\n  192.168.2.0/24\n  127.0.0.0/24\nenable_cors:  True\n' ~/printer.cfg
  fi
}
# Step 10: start klipper
start_klipper()
{
    report_status "starting klipper..."
    sudo systemctl start klipper
}

# Helper functions
report_status()
{
    echo -e "\n\n###### $1"
}

verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "This script must not run as root"
        exit -1
    fi
}

# Force script to exit if an error occurs
#set -e

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Run installation steps defined above
verify_ready
stop_klipper
install_packages
blkstump
install_moonraker
install-nginxcfg
install_mainsail
add_mainsail
start_klipper