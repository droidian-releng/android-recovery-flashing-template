# Droidian Adaptation for the Xiaomi Pocophone F1 (beryllium)
# https://droidian.org

OUTFD=/proc/self/fd/$1;
VENDOR_DEVICE_PROP=`grep ro.product.vendor.device /vendor/build.prop | cut -d "=" -f 2 | awk '{print tolower($0)}'`;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

mkdir /r;

# mount droidian rootfs
mount /data/rootfs.img /r;

# Apply bluetooth fix
ui_print "Applying bluetooth fix..."
touch /r/var/lib/bluetooth/board-address

# Apply wifi fix
ui_print "Applying wifi fix..."
cat >> enable-ipa.service<< EOF
[Unit]
Description=Workaround
After=android-mount.service
Requires=android-mount.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 1 > /dev/ipa'

[Install]
WantedBy=local-fs.target
EOF

mv enable-ipa.service /r/etc/systemd/system/

# umount rootfs
umount /r;

# halium initramfs workaround,
# create symlink to android-rootfs inside /data
if [ ! -e /data/android-rootfs.img ]; then
	ln -s /halium-system/var/lib/lxc/android/android-rootfs.img /data/android-rootfs.img || true
fi
## end install
