#!/bin/sh

if [[ -z $1 || -z $2 ]]; then 
	echo "Usage: "
	echo "    $0 [linux package in] [signed efi application out]"
	exit 1
fi

EFI_STUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub
EFI_KEY=/etc/efi.key.pem
EFI_CERT=/etc/efi.pub.pem

KERNEL_NAME=$1
EFI_APP=$2
KERNEL=/boot/vmlinuz-${KERNEL_NAME}
INITRD=/boot/initramfs-${KERNEL_NAME}.img
CMDLIN=/etc/cmdline-${KERNEL_NAME}

TMP_EFI_APP=/tmp/linux-efi-${KERNEL_NAME}.img

cleanup() {
	rm -f ${TMP_EFI_APP}
}

ERR_MSG=
err() {
	echo error $* >&2
	echo $ERR_MSG >&2
	cleanup
	exit 1
}

[[ -f $CMDLIN ]] || /usr/bin/cp /proc/cmdline $CMDLIN

ERR_MSG=$(/usr/bin/objcopy \
	--add-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
	--add-section .cmdline=${CMDLIN} --change-section-vma .cmdline=0x30000 \
	--add-section .linux=${KERNEL} --change-section-vma .linux=0x40000 \
	--add-section .initrd=${INITRD} --change-section-vma .initrd=0x3000000 \
	${EFI_STUB} ${TMP_EFI_APP} 2>&1)
(($?)) && err while joining kernel initrd and efi stub

ERR_MSG=$(/usr/bin/sbsign \
	--key ${EFI_KEY} \
	--cert ${EFI_CERT} \
	--output ${EFI_APP} \
	${TMP_EFI_APP} 2>&1)
(($?)) && err while signing

cleanup
