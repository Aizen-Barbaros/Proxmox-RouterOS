#!/bin/bash

#vars
version="nil"
vmID="nil"

echo "############## Start of Script ##############

## Checking if CHR temp dir is available..."
if [ -d /root/chr ]
then
    echo "-- Directory exists!"
else
    echo "-- Creating temp dir!"
    mkdir /root/chr
fi
# Ask user for version
echo "## Preparing for image download and VM creation!"
read -p "Please input CHR version to deploy (6.38.2, 6.40.1, 7.1.2 etc):" version
# Check if image is available and download if needed
if [ -f /root/chr/chr-$version.img ]
then
    echo "-- CHR image is available."
else
    echo "-- Downloading CHR $version image file."
    cd  /root/chr
    echo "---------------------------------------------------------------------------"
        if ! [ -x "$(command -v unzip)" ]; then
        echo "unzip is not installed. Installing now..."
        # Install unzip
        apt-get update
        apt-get install unzip -y
        fi
    wget https://download.mikrotik.com/routeros/$version/chr-$version.img.zip
    unzip chr-$version.img.zip
    echo "---------------------------------------------------------------------------"
fi
# List already existing VM's and ask for vmID
echo "== Printing list of VM's on this hypervisor!"
qm list
echo ""
read -p "Please Enter free vm ID to use:" vmID
echo ""
# Creating qcow2 image for CHR.
echo "-- Converting image to qcow2 format "
qemu-img convert \
    -f raw \
    -O qcow2 \
    chr-$version.img \
    vm-$vmID-disk-1.qcow2


# Creating VM
echo "-- Creating new CHR VM"
qm create $vmID \
  --name chr-$version \
  --net0 virtio,bridge=vmbr0 \
  --net1 virtio,bridge=vmbr1 \
  --bootdisk virtio0 \
  --ostype l26 \
  --memory 256 \
  --onboot yes \
  --sockets 1 \
  --cores 2 \

# Importing disk to local vm
qm importdisk $vmID vm-$vmID-disk-1.qcow2 local-lvm
qm set $vmID --ide0 local-lvm:vm-$vmID-disk-0,discard=on
qm set $vmID --boot order='ide0' 
#echo "############## End of Script ##############"
