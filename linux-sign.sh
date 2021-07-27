#!/bin/sh

PROGNAME=$0

[[ -z ${OBJCOPY} ]] && OBJCOPY=$(which objcopy)
[[ -z ${SBSIGN} ]] && SBSIGN=$(which sbsign)

print_help() {
	(
	echo "Usage: "
	echo "    $PROGNAME [options] PKGNAME /path/to/output"
	echo
	echo "Options:"
	echo "    -i, --initrd      Use specified initrd (by default"
	echo "    --initramfs       ucodes and '/boot/vmlinuz-PKGNAME')"
	echo
	echo "    -a, --append      Use specified cmdline (by default '/etc/cmdline-PKGNAME')"
	echo
	echo "    -s, --stub        Use specified stub binary (by default"
	echo "                      '/usr/lib/systemd/boot/efi/linuxx64.efi.stub)"
	echo
	echo "    -k, --key         Use specified sign key (by default '/etc/efi.key.pem')"
	echo
	echo "    -p, --pub         Use specified sign cert (by default '/etc/efi.pub.pem')"
	echo
	) >&2
}

INITRD=()
CMDLINE=
EFI_STUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub
EFI_KEY=/etc/efi.key.pem
EFI_CERT=/etc/efi.pub.pem

FILES=()

while [[ $# -gt 0 ]]
do
	key="$1"

	case $key in
	-i|--initrd|--initramfs)
		INITRD+=("$2")
		shift
		;;
	-a|--append)
		CMDLINE="$CMD $2"
		shift
		;;
	-s|--stub)
		EFI_STUB="$2"
		shift
		;;
	-k|--key)
		EFI_KEY="$2"
		shift
		;;
	-p|--pub)
		EFI_CERT="$2"
		shift
		;;

	-h|--help)
		print_help
		exit 0
		;;
	-*)
		echo "unknown option $key" >&2
		print_help
		exit 1
		;;
	*)
		FILES+=("$1")
		;;
	esac
	shift
done

if [[ -z ${FILES[0]} || -z ${FILES[1]} ]]
then
	print_help
	exit 1
fi

KERNEL_NAME=${FILES[0]}
EFI_APP=${FILES[1]}
KERNEL=/boot/vmlinuz-${KERNEL_NAME}
DEFAULT_INITRD=/boot/initramfs-${KERNEL_NAME}.img
DEFAULT_CMDLINE=/etc/cmdline-${KERNEL_NAME}

TMP_DIR=$(mktemp -d linux-sign.XXXX)

TMP_EFI_APP=${TMP_DIR}/app.efi
TMP_INITRD=${TMP_DIR}/initrd.img
TMP_CMDLINE=${TMP_DIR}/cmdline

cleanup() {
	rm -f ${TMP_EFI_APP}
	rm -f ${TMP_INITRD}
	rm -f ${TMP_CMDLINE}
	rm -rf ${TMP_DIR}
}

trap cleanup EXIT SIGINT SIGTERM SIGQUIT

ERR_MSG=
err() {
	echo error $* >&2
	echo $ERR_MSG >&2
	exit 1
}

check() {
	MSG=$0
	shift
	ERR_MSG=$($* 2>&1)
	(($?)) && err $MSG
}

[[ -z "${INITRD[@]}" ]] && \
	INITRD=(
		"/boot/amd-ucode.img"
		"/boot/intel-ucode.img"
		"${DEFAULT_INITRD}"
	)

for file in "${INITRD[@]}" "$EFI_KEY" "$EFI_CERT" "$KERNEL" "$EFI_STUB"
do
	if [[ ! -r "$file" ]]
	then
		err "\"$file\" file not found or permission denied"
	fi
done

if [[ -z $CMDLINE ]]
then
	[[ -f $DEFAULT_CMDLINE ]] && \
		cat $DEFAULT_CMDLINE > $TMP_CMDLINE ||\
		cat /proc/cmdline > $TMP_CMDLINE
else
	echo $CMDLINE > $TMP_CMDLINE
fi


cat "${INITRD[@]}" > $TMP_INITRD

check "in objcopy" ${OBJCOPY} \
	--add-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
	--add-section .cmdline=${TMP_CMDLINE} --change-section-vma .cmdline=0x30000 \
	--add-section .linux=${KERNEL} --change-section-vma .linux=0x40000 \
	--add-section .initrd=${TMP_INITRD} --change-section-vma .initrd=0x3000000 \
	${EFI_STUB} ${TMP_EFI_APP}

check "while signing" ${SBSIGN} \
	--key ${EFI_KEY} \
	--cert ${EFI_CERT} \
	--output ${EFI_APP} \
	${TMP_EFI_APP}
