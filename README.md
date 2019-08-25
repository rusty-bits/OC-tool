# OC-tool
command line tool for building OpenCore EFI folder

Builds a working EFI folder based on the list of drivers, kexts and options that your config.plist specifies.
  
  
  
Note: This tool makes certain assumptions, such as:
xcode, nasm, mtoc etc. required to build EFI files are correctly installed and configured to run from the command line

---

**Build Process the tool goes through**

When run, the tool will create a log.txt file, git clone any needed packages, update any existing packages, and build the base files

Next, it will git clone or update any required driver packages, build the additional drivers specified in the `driver.list` file and copy them to the new `EFI-xxxxx/OC/Drivers` directory  
*this is being updated to read the drivers from config.plist automatically, but it's not done yet*

It will then do the same for the kests in the `kext.list` file and copy them to the new `EFI-xxxxx/OC/Kexts` directory  
*also being made automatic from the config.plist, but not done yet*

The appropriate config.plist will be copied to `EFI-xxxx/OC/config.plist`

If the config.plist file has RequireVault set then `vault.plist` and `vault.sig` will be created automatically, and `OpenCore.efi` will be updated

Lastly, if any git updates were pulled it will list them.

---

**Installation**:

`git clone https://github.com/rusty-bits/OC-tool`

`cd OC-tool`

`cp config/SampleFull.plist config-RELEASE/config.plist` for making a release version

`cp config/SampleFull.plist config-DEBUG/config.plist` for making a debug version

---

**Usage**: (*release*)

edit `config-RELEASE/config.plist` as appropriate.  
edit `config-RELEASE/driver.list` with the drivers you want included.  
edit `config-RELEASE/kext.list` with the kexts you want included, then

`./OpenCore-tool build release`

This will create an `EFI-release` directory with all the required files, this can be copied to an EFI partition and renamed `EFI` if desired

---

**Usage**: (*debug*)

to create a debug version...

create the `config-DEBUG/config.plist` if it doesn't already exist, edit as needed.  
edit `config-DEBUG/driver.list` with the drivers you want included.  
edit `config-DEBUG/kext.list` with the kexts you want included, then

`./OpenCore-tool build debug`

This will create an `EFI-debug` directory with all the required files, this can be copied to an EFI partition and renamed `EFI` if desired

---

**Vault files:**

The tool will automatically build the required vault files based on the setting of the `RequireVault` field in `config.plist` or `debug-config.plist` and place them in the `EFI/OC` directory

---

**Description of files in `Docs` directory:**
`Sample.plist` and `SampleFull.plist` are from acidanthera/OpenCorePkg/Docs and will also be found locally in `OC-tool/UDK/OpenCorePkg/Docs` they are updated when the tool is run, there is a notification if they have been updated, check the `OpenCorePkg/Docs/Configuration.pdf` document and update `config-RELEASE/config.plist` or `config-DEBUG/config.plist` when needed

`base/driver.list` are the base files needed for OpenCore.efi to be built

**Descriprion if files in `config-DEBUG` and `config-RELEASE` directories:**

`driver.list` are the drivers that will be built and copied into the `EFI/OC/Drivers` directory

`kext.list` are the kexts that will be built and copied into the `EFI/OC/Kexts` directory

`config.plist` is the edited config file that gets copied to `EFI/OC/config.plist`

---

**Notes:**

These are the drivers and kexts that work for my build, you will likely need to edit `driver.list` and `kext.list` for your specific hardware

It is important to keep the format of the .list files as

`https://github.com/<github-user>/<repository>/<driver-name>.efi`

`https://github.com/<github-user>/<repository>/<kext-name>.kext`

since the tool parses this for what to build and copy to the new EFI
