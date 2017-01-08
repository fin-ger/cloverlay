# Copyright 2017 Fin Christensen
# Distributed under the terms of the GNU General Public License v3
# $Id$

EAPI=6

DESCRIPTION="Boot OS X, Windows, and Linux on Mac or PC with UEFI firmware"
HOMEPAGE="http://cloverefiboot.sourceforge.net/"
SRC_URI="https://sourceforge.net/projects/cloverefiboot/files/Bootable_ISO/CloverISO-${PR:1}.tar.lzma"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="boot-entry first-entry"
REQUIRED_USE="first-entry? ( boot-entry )"

DEPEND="sys-apps/grep
		sys-apps/util-linux
		>=app-arch/libarchive-3.2.2
		boot-entry? ( >=sys-boot/efibootmgr-0.12 )"
RDEPEND="${DEPEND}"

BOOT_ENTRY="Clover"

pkg_setup()
{
	ebegin "${PN}: Checking for a mounted EFI partition..."

	# c12a7328-f81f-11d2-ba4b-00a0c93ec93b is the partition type uuid for UEFI partitions
	export EFI_DEV=$(
		lsblk -lpno MOUNTPOINT,FSTYPE,PARTTYPE,NAME |
		grep -m 1 -oP '/.+\svfat\s+c12a7328-f81f-11d2-ba4b-00a0c93ec93b\s+\K.+'
	)

	eend $? || die "No mounted EFI partition found - cannot proceed with install!"

	# get the disk path for the device (device without partition)
	export EFI_DISK=$(lsblk -lpno TYPE,NAME | grep -Poz "disk.+?\\npart\\s+${EFI_DEV}" | grep -m 1 -Poz 'disk\s+\K.+')

	# get the partition number for the device
	export EFI_PART=$(lsblk -no MAJ:MIN "${EFI_DEV}" | grep -oP '\d+:\K\d+')

	# get the mount point for the device
	export EFI_MNT=$(lsblk -no MOUNTPOINT "${EFI_DEV}")

	einfo "${PN}: Using ${EFI_MNT} for clover install."

	if use boot-entry; then
		ebegin "${PN}: Checking if system is booted in EFI mode..."
		test -d /sys/firmware/efi
		if ! eend $?; then
			eerror "${PN}: System is NOT booted in EFI mode!"
			eerror
			eerror "Note: This ebuild currently has no support for BIOS booted systems."
			eerror "      To install clover in BIOS mode either install clover manually or submit"
			eerror "      a pull request on github adding BIOS support to this ebuild."
			eerror
			eerror "      GitHub: https://github.com/fin-ger/cloverlay"
			die "System is NOT booted in EFI mode!"
		fi
	fi
}

src_unpack()
{
	if [ "${A}" != "" ]; then
		unpack "${A}"
		mkdir "${S}"
		bsdtar xCp "${S}" -f "${WORKDIR}/Clover-v${PV}k-${PR:1}-X64.iso"
	fi
}

src_install()
{
	mkdir -p "${D}/${EFI_MNT}/EFI"
	cp -r "${S}/EFI/CLOVER" "${D}/${EFI_MNT}/EFI"
}

try_get_bootnum()
{
	efibootmgr | grep -oP "\\w{4}.\\s${BOOT_ENTRY}\$" | grep -oP '^\w{4}'
}

try_remove_boot_entry()
{
	bootnum=$(try_get_bootnum)

	# if bootnum not available return
	[ $? -ne 0 ] && return

	# delete old boot entry
	efibootmgr -b ${bootnum} -B > /dev/null
}

get_boot_order()
{
	efibootmgr | grep -oP "BootOrder: \K.+"
}

set_boot_order()
{
	efibootmgr -o "$1" > /dev/null
}

add_boot_entry()
{
	efibootmgr -d "${EFI_DISK}" -p "${EFI_PART}" -c -L "${BOOT_ENTRY}" -l /EFI/CLOVER/CLOVERX64.efi > /dev/null
}

eficonfig_fail()
{
	eerror "An error occured while configuring your EFI setup!"
	eerror "Please check your EFI configuration manually with"
	eerror
	eerror "    efibootmgr"
	eerror
	eerror "This error might have damaged existing boot configurations!"
	die "FATAL: error while configuring EFI boot!"
}

pkg_postinst()
{
	if use boot-entry; then
		ebegin "Removing old clover boot entry if existing..."
		try_remove_boot_entry
		eend $? || eficonfig_fail

		if use first-entry; then
			boot_order=$(get_boot_order)
		fi

		ebegin "Adding new clover boot entry..."
		add_boot_entry
		eend $? || eficonfig_fail

		if use first-entry; then
			bootnum=$(try_get_bootnum)
			ebegin "Setting clover as first boot entry..."
			set_boot_order "${bootnum},${boot_order}"
			eend $? || eficonfig_fail
		fi
	fi
}

pkg_postrm()
{
	ebegin "Removing old clover boot entry if existing..."
	try_remove_boot_entry
	eend $? || eficonfig_fail
}
