# PopOs

## On 21.04 a few lessons learned so far:
- For your AC68 Wifi Adapter; [drivers](https://github.com/aircrack-ng/rtl8814au/pull/73). Yes, kernel version matters.
  - Since that isn't working on kenel 5.15 as of now, issue (https://github.com/aircrack-ng/rtl8814au/issues/85#issuecomment-982399647) lead me here: https://github.com/morrownr/8814au. 
    - If you want to remove it, run the `sudo ./remove-driver.sh` script`
    - It's still using DKMS to load it
- Lutris can run wine via Proton: Just pik a custom wine executable, and make it the one in .steam/compatiblity.d/files.../wine64
- Rockstar games work pretty well, but you'll need an earlier rockstar launcher version at the moment
  - Screen recording bug is annoying (due to controller behaving as mouse input?)
  
## Notes for 21.10:

Apparently your boot data was "incorrectly" setup (oopsies) and you didn't make the (expected/assumed) /boot/efi partition that PopOs expects. Instead all the data went into the root partition (`df /boot -> /dev/sdb1`). `lsblk` shows this to be true (no boot parition/mount); and the `fstab` omits it entirely. If you want to get in on 21.10, you'll need to either re-install or split the boot partition out (it might be good to make a /recovery partition too).

### Moving the boot data:

Boot your live disk & run gparted:
- Create a new partition on `/dev/sdb` (eg the linux drive) that's `fat32`, `512mb` (ensure boot/esp flag set).
  - You may need to then format it if gparted does not already `mkfs.fat -F 32 /dev/sdxY`
- Mount the partitions (root, boot); for each run:
  - `mkdir /mnt/<foldername, like root>`
  - `mount -t auto -v /dev/<paritionname, like sdb1> /mnt/<foldername>`
  - (Do your things)
  - `unmount /dev/<partitionname> -l`
- Copy everything from `/boot` to the new partition, then rename it from `/boot` to something else.
  - USE THE `cp -a` flag to preserve all permissions.
- Get the UUID of the partition: `blkid /dev/<partitionname>`
- Add a boot entry into `fstab`: `PARTUUID=<UUID> /boot/efi vfat umask=0077 0 0`
- Boot and freaking pray I guess (and revert the above worst scenario from your live disk)
