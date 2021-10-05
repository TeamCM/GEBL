Good Enough Bootloader
================================
Good Enough BootLoader is a Multi-boot Bootloader for OpenComputers.

## Features:
- Arguments system
- Quick boot (select the first option if detected 1 os)
- Init finder (search in root filesystem for a bootable file if config file and init.lua dosent exist)

## What GEBL do not have:
- Boot a unmanaged system
- Specify custom args (customize the default arguments)
- Recovery shell
- OS Selection Timeout (like the Zorya os selection timeout)

## WARNING:
MineOS is not suported because of their own native bootloader in their EFI, check [#396](https://github.com/IgorTimofeev/MineOS/issues/396).
