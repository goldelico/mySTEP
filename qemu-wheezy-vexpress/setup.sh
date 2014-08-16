#!/bin/bash

# run this as root within the virtual machine

echo "deb http://download.goldelico.com/gta04/debian stable main" >/etc/apt/sources.list.d/gta04.list
echo "deb http://download.goldelico.com/quantumstep/debian stable main" >/etc/apt/sources.list.d/quantumstep.list

USEFUL="ntp"    # update clock from network
USEFUL+=" sudo"                 # always nice to have...
USEFUL+=" file"                 # same
USEFUL+=" bzip2"                # needed for tar xjf 
USEFUL+=" udev"                 # very important
USEFUL+=" alsa-utils"   # alsamixer, aplay etc.
USEFUL+=" usbmount usbutils eject"
USEFUL+=" fbcat"
USEFUL+=" dosfstools parted"    # to make bootable SD cards
USEFUL+=" man-db"               # some tools install a manual anyways - so why not make them readable
USEFUL+=" libc6-dev linux-libc-dev gcc make"            # so that we can cc some (simple) binaries from source (big!)
USEFUL+=" xorg"
USEFUL+=" quantumstep-displaymanager"

apt-get update && apt-get upgrade && apt-get install --no-install-recommends -y --force-yes $USEFUL

apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean
