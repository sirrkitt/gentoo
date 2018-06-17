
# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit golang-vcs-snapshot
inherit systemd
inherit autotools
inherit bash-completion-r1
EGO_PN=github.com/snapcore/snapd
EGO_SRC=github,com/snapcore/snapd/...

DESCRIPTION="Snap"

HOMEPAGE="https://snapcraft.io/"

SRC_URI="https://github.com/snapcore/${PN}/archive/${PV}.tar.gz -> ${PF}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="mirror"

RDEPEND="
	sys-fs/squashfs-tools
"

IUSE="apparmor selinux"

src_compile() {
	cp -sR "$(go env GOROOT)" "${T}/goroot" || die
	export GOROOT="${T}/goroot"
	export GOPATH="${WORKDIR}/${P}"
	export CGO_ENABLED="1"
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	cd src/${EGO_PN} && XDG_CONFIG_HOME="${WORKDIR}/" ./get-deps.sh && ./mkversion.sh ${PN}-${PV}
	go install -x -v -buildmode=pie "${EGO_PN}/cmd/snapd"
	go install -x -v -buildmode=pie "${EGO_PN}/cmd/snap"
	go install -x -v -buildmode=pie "${EGO_PN}/cmd/snapctl"
	go install -x -v -buildmode=pie "${EGO_PN}/cmd/snap-seccomp"

	go install -x -v -buildmode=pie -ldflags=-extldflags=-static "${EGO_PN}/cmd/snap-update-ns"
	go install -x -v -buildmode=pie -ldflags=-extldflags=-static "${EGO_PN}/cmd/snap-exec"

	emake -C ${GOPATH}/src/${EGO_PN}/data \
		BINDIR=/bin \
		LIBEXECDIR=/usr/lib \
		SYSTEMDSYSTEMUNITDIR=/usr/lib/systemd/system \
		SNAPD_ENVIRONMENT_FILE=/etc/default/snapd
	cd cmd
	eautoreconf -i -f -v
	econf -C ${GOPATH}/src/${EGO_PN}/cmd \
		--prefix=/usr \
		--libexecdir=/usr/lib/snapd \
		--disable-apparmor \
		--enable-merged-usr
	emake -C ${GOPATH}/src/${EGO_PN}/cmd
}
src_install() {
	dobin ${GOPATH}/bin/snap
	exeinto /usr/lib/snapd/
	doexe ${GOPATH}/bin/{snapctl,snapd,snap-exec,snap-seccomp,snap-update-ns}
	cd ${GOPATH}/src/${EGO_PN} && emake -C data/ install DESTDIR=${D}
	cd ${GOPATH}/src/${EGO_PN} && emake -C cmd/ install DESTDIR=${D}

	insinto /usr/share/polkit-1/actions
	doins ${GOPATH}/src/${EGO_PN}/data/polkit/io.snapcraft.snapd.policy
	insinto /lib/udev/rules.d
	doins ${GOPATH}/src/${EGO_PN}/data/udev/rules.d/66-snapd-autoimport.rules
	newbashcomp ${GOPATH}/src/${EGO_PN}/data/completion/snap snap
}
