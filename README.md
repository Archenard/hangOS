# hangOS
A fully open source operating system to play hangman.

## Features:
- Hangman.
- 16-bit.
- Fully custom bootloader.
- Easy to add languages and keyboard layouts.

## Building:
### Prerequisites:
- Python3
- QEMU (has to have qemu-system-x86_64)
- Above average IQ
#### Debian-based distros:
```
$ sudo apt install qemu-system-x86 python3
```
#### Arch-based distros:
```
$ sudo pacman -S qemu-system-x86 python3
```
After installing the required packages run `python3 src/linker.py` and the bin file will be located at  `linked.bin` 
## Running the OS:
### Running the OS on QEMU:
```
$ qemu-system-x86_64 linked.bin
```
### Running the OS on real hardware:
#### Linux
After inserting your pen drive, run
```
lsblk -S -p -o name,model,size
```
and find the name of your device (probably `/dev/sdb`).
Then run
```
sudo dd if=linked.bin of=<your device name>
```
#### Windows
You need a software like rufus to copy the file `linked.bin`.
If the software don't recognize the file, you can rename it into `linked.iso`.
