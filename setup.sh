# Ubport GSI installer Script
# erfanoabdi @ xda-developers
OUTFD=/proc/self/fd/$1;
VENDOR_DEVICE_PROP=`grep ro.product.vendor.device /vendor/build.prop | cut -d "=" -f 2 | awk '{print tolower($0)}'`;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

## GSI install

cp -fpr /data/ubports/data/* /data/;

mkdir /s;
mkdir /r;

mount /data/system.img /s;
ui_print "Setting udev rules";
cat /s/ueventd*.rc /vendor/ueventd*.rc | grep ^/dev | sed -e 's/^\/dev\///' | awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | sed -e 's/\r//' > /data/70-hybris-mobian.rules;
umount /s;

mount /data/rootfs.img /r;
mv /data/70-ubport.rules /r/etc/udev/rules.d/70-$VENDOR_DEVICE_PROP.rules;

umount /r;

mv /data/system.img /data/android-rootfs.img

ui_print "Resizing rootfs to 8GB";
e2fsck -fy /data/rootfs.img
resize2fs /data/rootfs.img 8G

## end install
