# Maintainer: x1b6e6 <ftdabcde@gmail.com>

pkgname=linux-sign
pkgver=0.1.1
pkgrel=1
pkgdesc="sign linux kernel"
arch=('any')
depends=('sbsigntools' 'openssl' 'efitools')

INSTALL_MS_THIRDPARTY=1 # for thirdparty devices and software signed with Microsoft (such as VeraCrypt)
INSTALL_MS_ROOT=1       # for booting official Windows

source=(
	"linux-sign.sh"
	"msRoot.esl"
	"msThirdParty.esl"
)
sha1sums=('5188e19e13d38e2e88ee769ba9c80e6a6f14c267'
          'db7ef2c3bcb35979607abad0c6f415546b7da003'
          '22594e7c709142c790bf56925c203544e433c148')

prepare(){
	# clean file
	echo "" > $srcdir/third_party.esl

	# install additional certs
	((INSTALL_MS_ROOT)) && cat $srcdir/msRoot.esl >> third_party.esl
	((INSTALL_MS_THIRDPARTY)) && cat $srcdir/msThirdParty.esl >> third_party.esl
}

install=install.sh

package() {
	cd "$srcdir"

	install -Dm755 "$srcdir"/linux-sign.sh "$pkgdir"/usr/bin/linux-sign
	install -Dm644 "$srcdir"/third_party.esl "$pkgdir"/etc/efikeys/third_party.esl
}
# vim: set ts=4 sw=0 noexpandtab autoindent :
