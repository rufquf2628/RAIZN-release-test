cd ./driver
make
modprobe raid456
insmod raizn.ko

backing=/dev/sda

dev1=/dev/nvme1n2
dev2=/dev/nvme2n2
dev3=/dev/nvme3n2

nvme zns reset-zone $dev1 -a
nvme zns reset-zone $dev2 -a
nvme zns reset-zone $dev3 -a

echo mq-deadline > /sys/block/nvme1n2/queue/scheduler
echo mq-deadline > /sys/block/nvme2n2/queue/scheduler
echo mq-deadline > /sys/block/nvme3n2/queue/scheduler

volume=raizn-vol

#chunk_sec=`cat /sys/block/nvme1n2/queue/chunk_sectors`
#num_zone=`cat /sys/block/nvme1n2/queue/nr_zones`
#sz=$(($chunk_sec * num_zone))

base16=`blkzone capacity $dev1`
sz=`printf "%d\n" $base16`

#sz=`blockdev --getsize $backing`

# Min dev = 3 (Parity 1, Data 2)
# Num of sectors in stripe in KiB, at least 4 
sec_num=4
# Num of IO workers
io_num=8
# Num of GC workers
gc_num=2
# Logical zone cap in KiB, 1077 MiB * 1024, 0 for auto
#zone_cap=1102848
zone_cap=0
# Devices list, Parity 1 & Data 2
devs="$dev1 $dev2 $dev3"

echo creating RAIZN volume ..

#dmsetup create $volume "raizn $sec_num $io_num $gc_num $zone_cap $devs"
dmsetup create $volume --table "0 $sz raizn $sec_num $io_num $gc_num $zone_cap $devs"

if test $? -ne 0; then
	echo initialization failed.
else
	echo RAIZN volume has been created.