# Droidian rootfs installer script
# https://droidian.org

OUTFD=/proc/self/fd/$1;
VENDOR_DEVICE_PROP=`grep ro.product.vendor.device /vendor/build.prop | cut -d "=" -f 2 | awk '{print tolower($0)}'`;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

## rootfs install
mv /data/droidian/data/* /data/;

mkdir /s;
mkdir /r;

# mount droidian rootfs
mount /data/rootfs.img /r;

# mount android gsi
mount /r/var/lib/lxc/android/android-rootfs.img /s

# Set udev rules
ui_print "Setting udev rules";
cat /s/ueventd*.rc /vendor/ueventd*.rc | grep ^/dev | sed -e 's/^\/dev\///' | awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | sed -e 's/\r//' > /r/etc/udev/rules.d/70-$VENDOR_DEVICE_PROP.rules;

# umount android gsi
umount /s;

# function to get the partitions where to flash imgs to.
get_partitions() {
	current_slot=$(grep -o 'androidboot\.slot_suffix=_[a-b]' /proc/cmdline)
	case "${current_slot}" in
		"androidboot.slot_suffix=_a")
			target_boot_partition="boot_a"
			target_dtbo_partition="dtbo_a"
			target_vbmeta_partition="vbmeta_a"
			;;
		"androidboot.slot_suffix=_b")
			target_boot_partition="boot_b"
			target_dtbo_partition="dtbo_b"
			target_vbmeta_partition="vbmeta_b"
			;;
		"")
			# No A/B
			target_boot_partition="boot"
			target_dtbo_partition="dtbo"
			target_vbmeta_partition="vbmeta"
			;;
		*)
			error "Unknown error while searching for a partition, exiting"
			;;
	esac
}

# If we should flash the kernel, do it
if [ -e "$(ls /r/boot/boot.img*)" ]; then
    ui_print "Kernel found, flashing"
    get_partitions
    partition=$(find /dev/block/platform -name "$target_boot_partition" | head -n 1)
    if [ -n "${partition}" ]; then
		ui_print "Found boot partition for current slot ${partition}"
		dd if=/r/boot/boot.img* of="${partition}" || error "Unable to flash kernel"
		ui_print "Kernel flashed"
	fi
fi

# If we should flash the dtbo, do it
if [ -e "$(ls /r/boot/dtbo.img*)" ]; then
    ui_print "DTBO found, flashing"
    get_partitions
    partition=$(find /dev/block/platform -name "$target_dtbo_partition" | head -n 1)
    if [ -n "${partition}" ]; then
        ui_print "Found DTBO partition for current slot ${partition}"
        dd if=/r/boot/dtbo.img* of="${partition}" || error "Unable to flash DTBO"
        ui_print "DTBO flashed"
    fi
fi

# If we should flash the vbmeta, do it
if [ -e "$(ls /r/boot/vbmeta.img*)" ]; then
    ui_print "VBMETA found, flashing"
    partition=$(find /dev/block/platform -name "$target_vbmeta_partition" | head -n 1)
    if [ -n "${partition}" ]; then
        ui_print "Found VBMETA partition ${partition}"
        dd if=/r/boot/vbmeta.img* of="${partition}" || error "Unable to flash VBMETA"
        ui_print "VBMETA flashed"
    fi
fi

if [ -f /r/.full_resize ]; then
    umount /r;

    # resize rootfs
    # first get the remaining space on the partition
    AVAILABLE_SPACE=$(df /data | awk '/dev\/block\/sda/ {print $4}')
    PRETTY_SIZE=$(df -h /data | awk '/dev\/block\/sda/ {print $4}')

    # then remove 100MB (102400KB) from the size
    # later on in case of kernel updates this storage might come in handy.
    # about the same amount is preserved for LVM images in the droidian--persistent and droidian--reserved partitions.
    IMG_SIZE=$((AVAILABLE_SPACE - 102400))
    ui_print "Resizing rootfs to $PRETTY_SIZE";
    e2fsck -fy /data/rootfs.img
    resize2fs /data/rootfs.img "$IMG_SIZE"K
else
    umount /r;

    ui_print "Resizing rootfs to 8GB";
    e2fsck -fy /data/rootfs.img
    resize2fs -f /data/rootfs.img 8G
fi

# halium initramfs workaround,
# create symlink to android-rootfs inside /data
if [ ! -e /data/android-rootfs.img ]; then
	ln -s /halium-system/var/lib/lxc/android/android-rootfs.img /data/android-rootfs.img || true
fi
## end install
