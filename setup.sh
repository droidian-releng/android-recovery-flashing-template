# hybris-mobian GSI installer Script
# https://hybris-mobian.org

OUTFD=/proc/self/fd/$1;
VENDOR_DEVICE_PROP=`grep ro.product.vendor.device /vendor/build.prop | cut -d "=" -f 2 | awk '{print tolower($0)}'`;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

## GSI install
cp -fpr /data/hybris-mobian/data/* /data/;

mkdir /s;
mkdir /r;

# mount hybris-mobian rootfs
mount /data/rootfs.img /r;

# mount android gsi
mount /r/var/lib/lxc/android/android-rootfs.img /s

# Set udev rules
ui_print "Setting udev rules";
cat /s/ueventd*.rc /vendor/ueventd*.rc | grep ^/dev | sed -e 's/^\/dev\///' | awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | sed -e 's/\r//' > /data/70-hybris-mobian.rules;

# umount android gsi
umount /s;

# move udev rules inside rootfs
mv /data/70-hybris-mobian.rules /r/etc/udev/rules.d/70-$VENDOR_DEVICE_PROP.rules;

# umount rootfs
umount /r;

# resize rootfs
ui_print "Resizing rootfs to 8GB";
e2fsck -fy /data/rootfs.img
resize2fs /data/rootfs.img 8G

# halium initramfs workaround,
# create symlink to android-rootfs inside /data
if [ ! -f /data/android-rootfs.img ]; then
	ln -s /var/lib/lxc/android/android-rootfs.img /data/android-rootfs.img
fi
## end install
