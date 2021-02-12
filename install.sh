
TMP=/tmp/efikeys
EFIKEYS=/etc/efikeys

pre_upgrade() {
	mkdir $TMP
}
post_upgrade() {
	rm -rf $TMP
}

pre_install() {
	pre_upgrade
}

post_install() {
	[[ -e /etc/efi.key.pem && -e /etc/efi.pub.pem ]] && 
		echo "warn: keys already generated. skip generating new keys" || 
		keys_gen_install

	# TODO: check enable SecureBoot, and try install certs to it

	post_upgrade
}

keys_gen_install() {
	(
	local ERR_MSG=
	err() {
		echo error $* >&2
		echo $ERR_MSG >&2
		post_upgrade
		exit 1
	}
	check() {
		local MSG=$1
		shift
		ERR_MSG=$($* 2>&1)
		(( $? )) && err $MSG
	}
	# generate keys
	check "in openssl" openssl req -newkey rsa:4096 -nodes -keyout $TMP/key.pem -new -x509 -sha256 -days 3650 -subj /CN=myPlatformKey/ -out $TMP/pub.pem
	
    # convert public key to efi sign list
	check "converting pub key to efi sign list" cert-to-efi-sig-list $TMP/pub.pem $TMP/efi.esl

	# add to list Microsoft keys for supporting dualboot
	cat $EFIKEYS/third_party.esl $TMP/efi.esl > $TMP/db.esl

	# signing keys for using secureboot
	check "signing PK"  sign-efi-sig-list -k $TMP/key.pem -c $TMP/pub.pem PK  $TMP/efi.esl $TMP/PK.auth
	check "signing KEK" sign-efi-sig-list -k $TMP/key.pem -c $TMP/pub.pem KEK $TMP/efi.esl $TMP/KEK.auth
	check "signing db"  sign-efi-sig-list -k $TMP/key.pem -c $TMP/pub.pem db  $TMP/db.esl  $TMP/db.auth

	# install keys
	install -Dm400 $TMP/key.pem /etc/efi.key.pem
	install -Dm444 $TMP/pub.pem /etc/efi.pub.pem

	# install keys to $EFIKEYS
	install -Dm444 $TMP/PK.auth $EFIKEYS/
	install -Dm444 $TMP/KEK.auth $EFIKEYS/
	install -Dm444 $TMP/db.auth $EFIKEYS/
	)
}

# detect running from shell
# https://stackoverflow.com/a/28776166
sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
	case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
	[ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
	(return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames
	# Detects `sh` and `dash`; add additional shell filenames as needed.
	case ${0##*/} in sh|dash) sourced=1;; esac
fi

if (( !sourced )); then
	echo "This script for automate running while installation" >&2
	echo "Please run 'makepkg -si' for build and install this package and dependencies" >&2
	exit 1
fi

# vim: set ts=4 sw=0 noexpandtab autoindent :
