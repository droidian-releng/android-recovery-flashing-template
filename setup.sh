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
cp data/board-address /r/var/lib/bluetooth/

# Apply wifi fix
ui_print "Applying WiFi fix..."
cp data/enable-ipa.service /r/etc/systemd/system/

# Apply scaling fix
ui_print "Applying scaling fix..."
mkdir -p /r/etc/phosh/
cp data/rootston.ini /r/etc/phosh/

# umount rootfs
umount /r;

ui_print "All fixes applied."
