# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3
inherit autotools

DESCRIPTION="iwd - intel wireless daemon"
HOMEPAGE="kernel.org"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0/0"
KEYWORDS="~amd64 ~x86"

IUSE=""

DEPEND="
	sys-apps/systemd
	dev-libs/ell
"
RDEPEND="${DEPEND}"

EGIT_REPO_URI="https://git.kernel.org/pub/scm/network/wireless/iwd.git"
#EGIT_CHECKOUT_DIR="${WORKDIR}/${P}"
src_prepare(){
	eapply_user
	mkdir "build-aux"
	sh "bootstrap"
	git-r3_fetch https://kernel.googlesource.com/pub/scm/libs/ell/ell.git
	git-r3_checkout https://kernel.googlesource.com/pub/scm/libs/ell/ell.git "tmp"
}
src_configure(){
	eautoreconf -fi --symlink
	econf \
		--prefix=/usr \
		--localstatedir=/var \
		--sysconfdir=/etc 
	rm -rf ell/
	mv tmp/ell ell
}
src_compile() {
	emake
}
src_install() {
	emake DESTDIR="${D}" install
}
