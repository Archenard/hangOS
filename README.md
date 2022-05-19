# hangOS
A fully open source operating system to play hangman.

## Features:
- Hangman.
- 32-bit.
- Fully custom bootloader.

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
After installing the required packages run `python3 hangman/linker.py` and the bin file will be located at  `hangman/linked.bin` 
## Running the OS:
### Running the OS on QEMU:
```
$ qemu-system-x86_64 hangman/linked.bin
```
### Running the OS on baremetal:
armand complete stp
