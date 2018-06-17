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
EGIT_BRANCH="nm-1-12"

LICENSE="GPL-3"
SLOT="0" # add subslot if libnm-util.so.2 or libnm-glib.so.4 bumps soname version

IUSE="audit bluetooth connection-sharing consolekit +dhclient dhcpcd dnsmasq elogind gnutls +introspection json kernel_linux +nss +modemmanager ncurses ofono ovs policykit +ppp resolvconf selinux systemd teamd test vala +wext +wifi iwd"

REQUIRED_USE="
	modemmanager? ( ppp )
	vala? ( introspection )
	^^ ( nss gnutls )
	?? ( consolekit elogind systemd )
"

KEYWORDS="~amd64"

DEPEND="
	dev-util/gdbus-codegen
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40
	>=sys-devel/gettext-0.17
"

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
		-Dqt=false
		-Dlibpsl=false
		-Dlibaudit=$(usex audit yes no)
		-Dselinux=$(usex selinux true false)
		-Dvapi=$(usex vala true false)
		-Diwd=$(usex iwd true false)
		-Ddnsmasq=$(usex dnsmasq true false)
		-Dwext=$(usex wext true false)
		-Dwifi=$(usex wifi true false)
		-Ddocs=false
		-Dcheck_settings_docs=false
		-Dintrospection=false
		-Dmodem_manager=false
		-Dovs=false
		-Dlibnm_glib=false
		-Dbluez5_dun=true
	)
	meson_src_configure
}
