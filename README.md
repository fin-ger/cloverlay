# Cloverlay

This repository contains a gentoo portage overlay for installing the clover efi bootloader.

# Setup the overlay

## With Layman

```
# layman -o https://raw.github.com/fin-ger/cloverlay/master/repositories.xml -f -a cloverlay
```

## With local overlays

To use [local overlays](https://wiki.gentoo.org/wiki/Overlay/Local_overlay) you need at least portage version `2.2.14`.

Create the file `/etc/portage/repos.conf/cloverlay.conf` containing

```
[cloverlay]
location = /usr/local/portage/cloverlay
sync-type = git
sync-uri = https://github.com/fin-ger/cloverlay.git
priority = 50
```

Run `emerge --sync` to collect the new ebuilds from the `cloverlay` overlay.

# Installation of clover

Then successfully setup the `cloverlay` overlay you can install the latest version of `clover` as follows

```
# emerge -va sys-boot/clover
```

> Note: Work in progress!
