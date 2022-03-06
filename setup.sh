# Droidian GSI installer Script
# https://droidian.org

OUTFD=/proc/self/fd/$1;
VENDOR_DEVICE_PROP=`grep ro.product.vendor.device /vendor/build.prop | cut -d "=" -f 2 | awk '{print tolower($0)}'`;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

## GSI install
mv /data/droidian/data/* /data/;

# resize rootfs
ui_print "Resizing rootfs to 8GB";
e2fsck -fy /data/rootfs.img
resize2fs -f /data/rootfs.img 8G

mkdir /s;
mkdir /r;

# mount droidian rootfs
mount /data/rootfs.img /r;

# mount android gsi
mount /r/var/lib/lxc/android/android-rootfs.img /s

# Set udev rules
ui_print "Setting udev rules";
cat /s/ueventd*.rc /vendor/ueventd*.rc | grep ^/dev | sed -e 's/^\/dev\///' | awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | sed -e 's/\r//' > /data/70-droidian.rules;

# umount android gsi
umount /s;

# move udev rules inside rootfs
mv /data/70-droidian.rules /r/etc/udev/rules.d/70-$VENDOR_DEVICE_PROP.rules;

# umount rootfs
umount /r;

# halium initramfs workaround,
# create symlink to android-rootfs inside /data
if [ ! -e /data/android-rootfs.img ]; then
	ln -s /halium-system/var/lib/lxc/android/android-rootfs.img /data/android-rootfs.img || true
fi
## end install
