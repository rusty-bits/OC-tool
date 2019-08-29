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

**Usage**: (*release*)

edit `RELEASE/config.plist` as appropriate.  

`./OpenCore-tool.sh build release`

This will create a `RELEASE/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Usage**: (*debug*)

to create a debug version...

edit `DEBUG/config.plist` as needed.  

`./OpenCore-tool.sh build debug`

This will create a `DEBUG/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Vault files:**

The tool will automatically build the required vault files based on the setting of the `RequireVault` field in `config.plist` and place them in the `EFI/OC` directory

---

**Description of files in `Docs` directory:**
`Sample.plist` and `SampleFull.plist` are from acidanthera/OpenCorePkg/Docs and will also be found locally in `OC-tool/resources/UDK/OpenCorePkg/Docs` they are updated when the update command is used, there is a notification if they have been updated, check the `OpenCorePkg/Docs/Configuration.pdf` document and update `RELEASE/config.plist` or `DEBUG/config.plist` when needed

`repo.plist` is a plist linking efi and kext files to their repositories

---

**Descriprion of files in `DEBUG` and `RELEASE` directories:**

`config.plist` is the config file that is used to see which drivers and kexts will be built, it is then copied to `EFI/OC/config.plist`  

---

**Notes:**

-still a work in progress, code needs cleaning, I'm working on it   
-basic Tools folder support it done for Shell.efi  
-planning on adding ACPI folder support when I get around to it
