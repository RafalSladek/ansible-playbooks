#!/bin/bash
set -e
VM_NAME=Ubuntu20.04LTS
SNAPSHOT_NAME=basic_root_ssh

test -n "$VM_NAME"
test -n "$SNAPSHOT_NAME"

# first parameter can override debug mode 1=on, 0=off, default is 0
DEBUG=${1:-0}

function silent() {
    if [[ $DEBUG == "1" ]] ; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

function main(){
    if [[ "$DEBUG" == "1" ]]; then
        echo "press power button for $VM_NAME"
    fi
    silent VBoxManage controlvm $VM_NAME acpipowerbutton
    until $(VBoxManage showvminfo --machinereadable $VM_NAME | grep -q ^VMState=.poweroff.)
    do
        if [[ "$DEBUG" == "1" ]]; then
            echo "waiting for poweroff the  $VM_NAME..."
        fi
        sleep 1
    done
    
    #VBoxManage list vms
    #VBoxManage snapshot $VM_NAME list
    silent VBoxManage snapshot $VM_NAME restore $SNAPSHOT_NAME
    silent VBoxManage startvm $VM_NAME --type headless
    #VBoxManage list vms
    #VBoxManage showvminfo $VM_NAME
    #VBoxManage guestproperty enumerate $VM_NAME
    VM_IP=$(VBoxManage guestproperty get $VM_NAME "/VirtualBox/GuestInfo/Net/0/V4/IP" | sed -e 's/Value: //g')
    echo $VM_IP
}

function duration(){
    start_ms=$(ruby -e 'puts (Time.now.to_f * 1000).to_i')
    func_name=$1
    func_output=$($func_name)
    end_ms=$(ruby -e 'puts (Time.now.to_f * 1000).to_i')
    elapsed_ms=$((end_ms - start_ms))
    silent echo "execution duration: $elapsed_ms ms"
    echo "$func_output"
}

duration main