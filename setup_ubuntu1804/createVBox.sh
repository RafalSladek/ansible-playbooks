#!/bin/bash
set -x

VM=Ubuntu16LTS
USERNAME=rsladek
PASSWORD=${1:-DefaultPassW0rd}

VM_DISK="$HOME/VirtualBox VMs/$VM/$VM.vdi"
ISO_URL_UBUNTU20="https://releases.ubuntu.com/20.04/ubuntu-20.04-live-server-amd64.iso"
ISO_URL_UBUNTU18="https://releases.ubuntu.com/18.04/ubuntu-18.04.4-live-server-amd64.iso"
ISO_URL_UBUNTU16="https://releases.ubuntu.com/16.04/ubuntu-16.04.6-server-amd64.iso"
os_iso_url=$ISO_URL_UBUNTU16
os_iso=$HOME/Downloads/$(basename $os_iso_url)

if ! test -e $os_iso; then
    curl --fail --location --create-dirs --output $os_iso-$$ $os_iso_url
    mv $os_iso-$$ $os_iso # this only happens if previous cmds succeeds (because of errexit)
fi

VM_ISO="$os_iso"

count=$(VBoxManage list vms | grep $VM | wc -l| tr -d ' ')
if [[ "$count" != 0 ]]; then
    VBoxManage controlvm $VM acpipowerbutton
    until $(VBoxManage showvminfo --machinereadable $VM | grep -q ^VMState=.poweroff.)
    do
        sleep 1
    done
    VBoxManage unregistervm $VM --delete
fi

VBoxManage createvm \
--name $VM \
--ostype "Ubuntu_64" \
--register

VBoxManage createhd \
--filename "$VM_DISK" \
--size 2000000 \
--format VDI \
--variant Standard

# Disc
VBoxManage storagectl $VM \
--name "SATA Controller" \
--add sata \
--controller IntelAHCI

VBoxManage storageattach $VM \
--storagectl "SATA Controller" \
--port 0 \
--device 0 \
--type hdd --medium "$VM_DISK"


# DVDrom
VBoxManage storagectl $VM \
--name "IDE Controller" \
--add ide

VBoxManage storageattach $VM \
--storagectl "IDE Controller" \
--port 0 \
--device 0 \
--type dvddrive \
--medium "$VM_ISO"


VBoxManage modifyvm $VM --ioapic on
VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none

#--bridgeadapter1 en0
#--pae on \
#--nested-hw-virt on \

VBoxManage modifyvm $VM \
--description "Ubuntu Server" \
--memory 4096 \
--vram 64 \
--cpus 2 \
--chipset piix3 \
--ioapic on \
--nic1 bridged \
--bridgeadapter1 en5 \
--nictype1 82540EM \
--nicpromisc1 allow-all \
--cableconnected1 on
#--hwvirtex on \
#--pae off \
#--nested-hw-virt off \
#--paravirtprovider default \
#--largepages off \
#--rtcuseutc on \
#--firmware bios \
#--graphicscontroller vmsvga \
#--clipboard-mode bidirectional \
#--audio none \
#--vrde off \
#--usb off \
#--usbehci off \
#--usbxhci off \
#--boot1 dvd \
#--boot2 disk \
#--boot3 none \
#--boot4 none

#VBoxManage unattended detect --iso="$VM_ISO"

VBoxManage unattended install $VM \
--iso="$VM_ISO" \
--user=$USERNAME \
--full-user-name=$USERNAME \
--password=$PASSWORD\
--country=US \
--locale=en_US \
--no-install-additions \
--time-zone=CET \
--start-vm=gui

#VBoxManage startvm $VM

#VBoxManage guestproperty enumerate $VM

#VBoxManage modifyvm $VM --boot1 disk --boot2 none --boot3 none --boot4 none

