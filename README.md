# hangOS
A fully open source operating system to play hangman.

## Features:
- Hangman.
- 16-bit.
- Fully custom bootloader.
- Easy to add words.
- Usable with azerty keyboards (french words included).

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
After installing the required packages run `python3 src/linker.py` and the binary file will be located at  `hangOS.iso` 
## Running the OS:
### Running the OS on QEMU:
```
$ qemu-system-x86_64 hangOS.iso
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
sudo dd if=hangOS.iso of=<your device name>
```
#### Windows
You need a software like <a href="https://rufus.ie">rufus</a> to copy the file `hangOS.iso`.

