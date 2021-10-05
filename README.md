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

Screenshot:

![image](https://user-images.githubusercontent.com/52385139/135964320-ad8f35c6-3557-41eb-88f2-2fa6f92a308d.png)

## WARNING:
MineOS is not suported because of their own native bootloader in their EFI, check [#396](https://github.com/IgorTimofeev/MineOS/issues/396).
