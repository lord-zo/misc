# Dual-boot Dell XPS 15 9570

This is a brief reference on what I did to dual-boot Debian with windows on my laptop.

## Options

To install I read about 2 options:
- The [Debian-Installer Loader](https://wiki.debian.org/DebianInstaller/Loader)
seemed convenient but ultimately didn't work for me.
First of all, the loader did not cause intercept the Windows boot sequence,
so I had to do that with the cmd.exe bootmgr.
When I did boot into the loader, it said it failed and went ahead into Windows.
- Installing from a bootable flash drive (this worked for me)

## Pre-partitioning

In Windows, I used the Disk Management tool to shrink the Windows partition to make
128 GB of space for the new OS.

## Installation

I installed the debian iso file for Debian bullseye from their website (supports Secure Boot).
I used Rufus to unpack the Debian iso file to the flash drive to use as a bootable drive.
I was able to boot from the flash drive by restarting and pressing <F12> for BIOS boot menu.

The two issues I had to work around during installation were:

### BIOS SATA protocol

By default, the BIOS SATA setting uses Intel RAID storage technology, which seems like a good thing.
However, this was the only setting I had to change for the installation to work.
Without it, the installer didn't recognize the SSD I wanted to install it on -- fatal!
I briefly tried to do what I could to the installer for it to work according to this
[manual](https://wiki.debian.org/DebianInstaller/SataRaid), but nothing changed.
So I had to change the SATA setting to ACHI protocol. Get the
[gist](https://gist.github.com/chenxiaolong/4beec93c464639a19ad82eeccc828c63).

### Wifi firmware

The XPS has a proprietary wifi card with a qualcomm chip.
The Debian firmware-atheros package is necessary to connect to wifi for installation.
I installed this package onto a flash drive from Debian's repositories,
which I plugged in when needed during the installation.
Find more instructions [here](https://wiki.debian.org/Firmware).

I went for the default installation of Debian, which works great!

## GRUB self-protection

To protect GRUB from the Windows Boot Manager, I used this
[solution](https://unix.stackexchange.com/a/242219).

## In progress

- While Debian's nvidia-driver package claims to support the linux kernel up to 5.10,
the kernel modules still don't work on my machine
- Aside: GNOME allows file integration from google drive and other online accounts, except onedrive
