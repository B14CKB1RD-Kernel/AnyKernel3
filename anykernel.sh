# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Caesium Kernel by msfjarvis
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=walleye
device.name2=taimen
device.name3=wahoo
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
# set_perm_recursive 0 0 755 644 $ramdisk/*;
# set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;


## AnyKernel install
dump_boot;

# begin ramdisk changes

# init.rc
# backup_file init.rc;
# replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";

# init.tuna.rc
# backup_file init.tuna.rc;
# insert_line init.tuna.rc "nodiratime barrier=0" after "mount_all /fstab.tuna" "\tmount ext4 /dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data remount nosuid nodev noatime nodiratime barrier=0";
# append_file init.tuna.rc "bootscript" init.tuna;

# fstab.tuna
# backup_file fstab.tuna;
# patch_fstab fstab.tuna /system ext4 options "noatime,barrier=1" "noatime,nodiratime,barrier=0";
# patch_fstab fstab.tuna /cache ext4 options "barrier=1" "barrier=0,nomblk_io_submit";
# patch_fstab fstab.tuna /data ext4 options "data=ordered" "nomblk_io_submit,data=writeback";
# append_file fstab.tuna "usbdisk" fstab;

# end ramdisk changes

# Warn user of their support status
android_version="$(file_getprop /system/build.prop "ro.build.version.release")";
security_patch="$(file_getprop /system/build.prop "ro.build.version.security_patch")";
case "$android_version:$security_patch" in
  "9:2019-07-05"|"10:2019-07-05") support_status="a supported";;
  "8.1.0"*|"P"*|"9"*|"Q"*|"10"*) support_status="an unsupported";;
  *) abort "Completely unsupported OS configuration!";;
esac;
ui_print " "; ui_print "You are on $android_version with the $security_patch security patch level! This is $support_status configuration...";

# If the kernel image and dtbs are separated in the zip
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.lz4
if [ -f $compressed_image ]; then
  # Hexpatch the kernel if Magisk is installed ('skip_initramfs' -> 'want_initramfs')
  if [ -d $ramdisk/.backup ]; then
    ui_print " "; ui_print "Magisk detected! Patching kernel so reflashing Magisk is not necessary...";
    $bin/magiskboot decompress $compressed_image $decompressed_image;
    $bin/magiskboot hexpatch $decompressed_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
    $bin/magiskboot compress=lz4 $decompressed_image $compressed_image;
  fi;

  # Concatenate all of the dtbs to the kernel
  cat $compressed_image /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.lz4-dtb;
fi;

write_boot;
## end install
