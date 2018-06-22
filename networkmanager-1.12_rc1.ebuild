# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
GNOME_ORG_MODULE="NetworkManager"
GNOME2_LA_PUNT="yes"
VALA_USE_DEPEND="vapigen"
PYTHON_COMPAT=( python{2_7,3_4,3_5,3_6} )

inherit bash-completion-r1 linux-info multilib python-any-r1 systemd \
	user readme.gentoo-r1 toolchain-funcs vala versionator virtualx udev meson ninja-utils git-r3

DESCRIPTION="A set of co-operative tools that make networking simple and straightforward"
HOMEPAGE="https://wiki.gnome.org/Projects/NetworkManager"
SRC_URI=""

EGIT_REPO_URI="https://anongit.freedesktop.org/git/NetworkManager/NetworkManager.git"
#EGIT_COMMIT="1.12-rc1"
EGIT_COMMIT="${PV}"

LICENSE="GPL-3"
SLOT="0" # add subslot if libnm-util.so.2 or libnm-glib.so.4 bumps soname version

IUSE="audit bluetooth connection-sharing consolekit debug +dhclient dhcpcd dnsmasq -docs elogind gnutls +introspection +json kernel_linux +libpsl +nss +modemmanager ncurses ofono +ovs policykit +ppp resolvconf selinux systemd teamd test vala +wifi iwd"

REQUIRED_USE="
	modemmanager? ( ppp )
	vala? ( introspection )
	^^ ( nss gnutls )
	?? ( consolekit elogind systemd )
"

KEYWORDS="~amd64"

COMMON_DEPEND="
	>=sys-apps/dbus-1.2
	>=dev-libs/dbus-glib-0.100
	>=dev-libs/glib-2.37.6:2
	>=dev-libs/libnl-3.2.8:3

	policykit? ( >=sys-auth/polkit-0.106 )

	net-libs/libndp
	>=net-misc/curl-7.24
	net-misc/iputils
	sys-apps/util-linux
	sys-libs/readline:0=
	>=virtual/libudev-175:=
	audit? ( sys-process/audit )
	bluetooth? ( >=net-wireless/bluez-5 )
	connection-sharing? (
		net-dns/dnsmasq[dbus,dhcp]
		net-firewall/iptables )
	dhclient? ( >=net-misc/dhcp-4[client] )
	elogind? ( >=sys-auth/elogind-219 )
	gnutls? (
		dev-libs/libgcrypt:0=
		>=net-libs/gnutls-2.12:= )
	introspection? ( >=dev-libs/gobject-introspection-0.10.3:= )
	json? ( dev-libs/jansson )
	modemmanager? ( >=net-misc/modemmanager-0.7.991:0= )
	ncurses? ( >=dev-libs/newt-0.52.12 )
	nss? ( >=dev-libs/nss-3.11:= )
	ovs? ( dev-libs/jansson )
	ppp? ( >=net-dialup/ppp-2.4.5:=[ipv6] )
	resolvconf? ( net-dns/openresolv )
	selinux? ( sys-libs/libselinux )
	systemd? ( >=sys-apps/systemd-209:0= )
	teamd? (
		dev-libs/jansson
		>=net-misc/libteam-1.9 )
	libpsl? ( net-libs/libpsl )
"
DEPEND="${COMMON_DEPEND}
	dev-util/gdbus-codegen
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40
	>=sys-devel/gettext-0.17
	dev-python/dbus-python
	dev-python/pygobject
"

RDEPEND="${COMMON_DEPEND}"
python_check_deps() {
	if use introspection; then
		has_version "dev-python/pygobject:3[${PYTHON_USEDEP}]" || return
	fi
	if use test; then
		has_version "dev-python/dbus-python[${PYTHON_USEDEP}]" &&
		has_version "dev-python/pygobject:3[${PYTHON_USEDEP}]"
	fi
}

sysfs_deprecated_check() {
	ebegin "Checking for SYSFS_DEPRECATED support"

	if { linux_chkconfig_present SYSFS_DEPRECATED_V2; }; then
		eerror "Please disable SYSFS_DEPRECATED_V2 support in your kernel config and recompile your kernel"
		eerror "or NetworkManager will not work correctly."
		eerror "See https://bugs.gentoo.org/333639 for more info."
		die "CONFIG_SYSFS_DEPRECATED_V2 support detected!"
	fi
	eend $?
}

pkg_pretend() {
	if use kernel_linux; then
		get_version
		if linux_config_exists; then
			sysfs_deprecated_check
		else
			ewarn "Was unable to determine your kernel .config"
			ewarn "Please note that if CONFIG_SYSFS_DEPRECATED_V2 is set in your kernel .config, NetworkManager will not work correctly."
			ewarn "See https://bugs.gentoo.org/333639 for more info."
		fi

	fi
}

pkg_setup() {
	if use connection-sharing; then
		CONFIG_CHECK="~NF_NAT_IPV4 ~NF_NAT_MASQUERADE_IPV4"
		linux-info_pkg_setup
	fi
	enewgroup plugdev
	if use introspection || use test; then
		python-any-r1_pkg_setup
	fi
}

src_prepare() {
	default
}
src_configure() {
	local emesonargs=(
		-Ddist_version=${PV}

		-Dqt=false
		-Dlibnm_glib=true

		-Dlibaudit=$(usex audit yes no)
		-Dselinux=$(usex selinux true false)
		-Dvapi=$(usex vala true false)
		-Diwd=$(usex iwd true false)
		-Ddnsmasq=$(usex dnsmasq true false)
		-Dwext=false
		-Dwifi=$(usex wifi true false)
		-Dcheck_settings_docs=true
		-Dmodem_manager=$(usex modemmanager true false)
		-Dovs=$(usex ovs true false)
		-Dbluez5_dun=$(usex bluetooth true false)
		-Dppp=$(usex ppp true false)
		-Dofono=$(usex ofono true false)
		-Dteamdctl=$(usex teamd true false)
		-Dpolkit=$(usex policykit yes no)
		-Dpolkit_agent=$(usex policykit true false)
		-Dselinux=$(usex selinux true false)
		-Dsystemd_journal=$(usex systemd true false)


		-Dsession_tracking=$(usex systemd systemd $(usex elogind elogind $(usex consolekit consolekit no) ) )
		-Dresolvconf=$(usex resolvconf '/usr/bin/resolvconf' '')
		-Dsuspend_resume=$(usex systemd true $(usex elogind true $(usex consolekit true false) ) )

		-Ddhclient=$(usex dhclient '/sbin/dhclient' '')
		-Ddhcpcd=$(usex dhcpcd '/sbin/dhcpcd' '')

		-Dsystemdsystemunitdir="$(systemd_get_systemunitdir)"
		-Dudev_dir="$(get_udevdir)"
		-Ddbus_ifaces_dir='/usr/share/dbus-1/interfaces'
		-Ddbus_sys_dir='/etc/dbus-1/system.d'
		-Dpolkit_dir='/usr/share/polkit-1'
		-Diptables='/sbin/iptables'

		-Dconsolekit=$(usex consolekit true false)
		-Dhostname_persist='gentoo'
		# misc
		-Dintrospection=$(usex introspection true false)
		-Dvapi=$(usex vala true false)
		-Ddocs=$(usex docs true false)
		-Dtests=$(usex test yes no)
		-Dmore_asserts=$(usex debug 100 0)
		-Dmore_logging=$(usex debug true false)
		-Dlibpsl=$(usex libpsl true false)
		-Djson_validation=$(usex json true false)
		-Dcrypto=$(usex nss nss gnutls)
	)
	if use ppp ; then
		local PPPD_VER=`best_version net-dialup/ppp`
		PPPD_VER=${PPPD_VER#*/*-}
		PPPD_VER=${PPPD_VER%%[_-]*}
		emesonargs+=(-Dpppd=/usr/sbin/pppd)
		emesonargs+=(-Dpppd_plugin_dir=/usr/$(get_libdir)/pppd/${PPPD_VER})
	fi
	meson_src_configure
}
