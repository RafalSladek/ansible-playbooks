#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

unattended-templates-dir() {
  local dir=
  local dirs=(
    $HOME/Applications/VirtualBox.app/Contents/MacOS/UnattendedTemplates
    /Applications/VirtualBox.app/Contents/MacOS/UnattendedTemplates
    /usr/etc/virtualbox/UnattendedTemplates
    /usr/lib/virtualbox/UnattendedTemplates
    /usr/local/etc/virtualbox/UnattendedTemplates
    /usr/local/lib/virtualbox/UnattendedTemplates
  )
  for dir in "${dirs[@]}"; do
    if test -d "$dir"; then
      echo "$dir"
      return 0
    fi
  done
  return 1
} # unattended-templates-dir()
start() {
  local vm=ubuntu-bionic-server
  local ostype=Ubuntu_64
  local os_iso_url=http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.1-server-amd64.iso
  local os_iso=/tmp/$(basename $os_iso_url)

  if ! test -e $os_iso; then
    curl --fail --location --create-dirs --output $os_iso-$$ $os_iso_url
    mv $os_iso-$$ $os_iso # this only happens if previous cmds succeeds (because of errexit)
  fi

  local base_dir=/tmp/vms
  local aux_base_path=/tmp/$vm/$vm-unattended-install-

  VBoxManage unregistervm $vm --delete > /dev/null || true

  rm -fr   $base_dir/$vm
  mkdir -p $base_dir/$vm

  rm -fr   $(dirname $aux_base_path)
  mkdir -p $(dirname $aux_base_path)

  VBoxManage createvm \
    --name       $vm       \
    --basefolder $base_dir \
    --ostype     $ostype   \
    --register             \

  VBoxManage modifyvm $vm \
    --memory 1024 \
    --vram   16   \

  VBoxManage storagectl $vm \
    --name        SAS \
    --add         sas \
    --portcount   1   \
    --bootable    on  \

  VBoxManage createmedium disk \
    --filename $base_dir/$vm/$vm.vdi \
    --size     8192                  \
    --format   VDI                   \

  # SAS-0-0
  VBoxManage storageattach $vm \
    --medium     $base_dir/$vm/$vm.vdi \
    --storagectl SAS                   \
    --port       0                     \
    --device     0                     \
    --type       hdd                   \

  VBoxManage storagectl $vm \
    --name        SATA \
    --add         sata \
    --portcount   1    \
    --bootable    on   \

  # SATA-0-0
  VBoxManage storageattach $vm \
    --medium     emptydrive \
    --storagectl SATA       \
    --port       0          \
    --device     0          \
    --type       dvddrive   \
    --mtype      readonly   \

  local aux_base_path=/tmp/$vm/$vm-unattended-install-
  local vbox_script_template=$(unattended-templates-dir)/ubuntu_preseed.cfg
  local script_template; script_template="$(dirname $aux_base_path)/$(basename "$vbox_script_template")"
  mkdir -p $(dirname $script_template)
  cp "$vbox_script_template" $script_template

  if test ${fix:-0} -ne 0; then # fix ubuntu_preseed.cfg
    echo "fixing $script_template"
    cp $script_template $script_template.orig

    patch $script_template < fix.patch

    diff $script_template.orig $script_template || true
  fi

  VBoxManage unattended install $vm \
    --auxiliary-base-path $aux_base_path   \
    --script-template     $script_template \
    --iso                 $os_iso          \

  VBoxManage startvm $vm
}
start
