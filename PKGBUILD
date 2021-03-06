# Maintainer: x1b6e6 <ftdabcde@gmail.com>

pkgname=linux-sign
pkgver=0.1.0
pkgrel=1
pkgdesc="sign linux kernel"
arch=('any')
depends=('sbsigntools' 'openssl' 'efitools')

INSTALL_MS_THIRDPARTY=1 # for thirdparty devices and software signed with Microsoft (such as VeraCrypt)
INSTALL_MS_ROOT=1       # for booting official Windows

source=(
	"linux-sign.sh"
	"linux-sign@.path"
	"linux-sign@.service"
	"msRoot.esl"
	"msThirdParty.esl"
)
sha1sums=('03a3a546d044e3574f1266b4393138ef914107ce'
          'cdd4135d9c121f26e644b6dbb91493c0a2b27858'
          '901a01539462fc7d7d9920bea022799dc602d8e8'
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
	install -Dm644 "$srcdir"/linux-sign@.path "$pkgdir"/usr/lib/systemd/system/linux-sign@.path
	install -Dm644 "$srcdir"/linux-sign@.service "$pkgdir"/usr/lib/systemd/system/linux-sign@.service
}
# vim: set ts=4 sw=0 noexpandtab autoindent :
