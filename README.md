# OC-tool
command line tool for building OpenCore EFI folder

Builds a working EFI folder based on the list of drivers, kexts and options that your config.plist specifies.

Note: This tool makes certain assumptions, such as:
xcode, nasm, mtoc, git etc. required to build EFI files are correctly installed and configured to run from the command line

---

**Build Process the tool goes through**

When run the tool will first build the base files.

Next, it will clone or update any required driver packages based on the UEFI/Drivers section of `config.plist`, then build any new or changed packages. 

It then does the same for the kexts based on the Kernel/Add section of `config.plist`  

If `config.plist` has RequireVault set then `vault.plist` and `vault.sig` will be created automatically, and `OpenCore.efi` will be updated.  

The files are then copied to an EFI folder that can be dropped right into a boot partition.

---

**Installation**:

`git clone https://github.com/rusty-bits/OC-tool`   
`cd OC-tool`

then place your config.plist file in the appropriate directory, or copy and edit one of the sample plist files. eg.    
`cp Docs/SampleFull.plist RELEASE/config.plist` for making a release version

`cp Docs/SampleFull.plist DEBUG/config.plist` for making a debug version

---

**Usage**: (*for building release configuration*)

edit `RELEASE/config.plist` as appropriate.  

`./OpenCore-tool build release`

This will create a `RELEASE/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Usage**: (*for building debug configuration*)

to create a debug version...

edit `DEBUG/config.plist` as needed.  

`./OpenCore-tool build debug`

This will create a `DEBUG/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Vault files:**

The tool will automatically build the required vault files based on the setting of the `RequireVault` field in `config.plist` and place them in the `EFI/OC` directory

---

**Description of files in `Docs` directory:**
`Sample.plist` and `SampleFull.plist` are from acidanthera/OpenCorePkg/Docs and will also be found locally in `OC-tool/resources/UDK/OpenCorePkg/Docs` they are updated when the update command is used, there is a notification if they have been updated, check the `OpenCorePkg/Docs/Configuration.pdf` document and update `RELEASE/config.plist` or `DEBUG/config.plist` when needed  

---

**Descriprion of files in `DEBUG` and `RELEASE` directories:**

`config.plist` is the config file that is used to see which drivers and kexts will be built, it is then copied to `EFI/OC/config.plist`  

---

**Description of files in `tool-files` directory**  

`repo.plist` is a plist linking efi and kext files to their repositories  

`usage.txt` text file with formatted text to show tool help/usage with -h flag  

**Description of `extras` directory**  

Kexts and Drivers that OpenCore-tool can not build need to be placed in the `extras` directory.  
They will then be copied to the appropriate place in the new `EFI`  

**Notes:**

-unsure if macOS Catalina will support bash commands right out of the box  
....rewrote code to be POSIX compliant so it will run without issue in sh  
-still a work in progress, code needs cleaning, I'm working on it   
-basic Tools folder support is done for Shell.efi - needs improvement  
-planning on adding ACPI folder support if I get around to it  
