#!/bin/bash
[ -r vmlinuz-3.2.0-4-vexpress ] || curl -O http://download.goldelico.com/gta04/debian/qemu-wheezy-vexpress/vmlinuz-3.2.0-4-vexpress
[ -r initrd.img-3.2.0-4-vexpress ] || curl -O http://download.goldelico.com/gta04/debian/qemu-wheezy-vexpress/initrd.img-3.2.0-4-vexpress
[ -r wheezy.img -o -r wheezy.img.bz2 ] || curl -O http://download.goldelico.com/gta04/debian/qemu-wheezy-vexpress/wheezy.img.bz2
[ -r wheezy.img.bz2 ] && bunzip2 wheezy.img.bz2

qemu-system-arm -M vexpress-a9 -kernel vmlinuz-3.2.0-4-vexpress -initrd initrd.img-3.2.0-4-vexpress -sd wheezy.img -append "root=/dev/mmcblk0p2 console=ttyAMA0 console=ttyS0" -redir tcp:22222::22 -m 256 -serial stdio "$@"
