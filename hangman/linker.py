#!/usr/bin/env python3

from os import system

def read_file(file_path, binary=False):
    if binary:
        param = "rb"
    else:
        param = "r"
    f = open(file_path, param)
    content = f.read()
    f.close()
    return content


## extract files to link

try:
    files = read_file("links.txt").split("\n")
except:
    print("Error, exiting")
    print("You need to have a file named 'links.txt' in this directory")
    print("which contains one file name per line")
    exit()
while "" in files:
    del files[files.index("")]


## get the data to write the file

"""
try:
    linked_file = read_file("bootloader.asm")+"\n\n"

    where_write_sectors = linked_file.index("__sectors__")
    linked_file = linked_file.replace("__sectors__", "0")
except:
    print("Error, exiting")
    print("You need to have a file named 'bootloader.asm' in this directory")
    exit()
"""

for file in files:
    linked_file += read_file(file)+"\n\n"

where_write_sectors = []
while "__sectors__" in linked_file:
    where_write_sectors.append(linked_file.index("__sectors__"))
    linked_file = linked_file[:where_write_sectors[-1]] + "0" + linked_file[where_write_sectors[-1]+len("__sectors__"):]

if "__numberofwords__" in linked_file:
    words = read_file("words.txt").split("\n")
    while "" in words:
        del words[words.index("")]
    linked_file = linked_file.replace("__numberofwords__", str(len(words)))


## write file

file_out = open("linked.asm", "w")
file_out.write(linked_file)
file_out.close()


## assemble a first time (no padding)

system("nasm linked.asm -o linked.bin")


## determine size of the binary

binary_file = read_file("linked.bin", binary=True)
size_no_padding = len(binary_file)

print("Size of the boot file before padding: ", size_no_padding, "B", sep="")


## padding

sectors_used = (size_no_padding//512)+1
space_used = sectors_used*512
bytes_to_add = space_used-size_no_padding

linked_file += "times "+str(bytes_to_add)+" db 0"

for where_write in where_write_sectors:
    linked_file = linked_file[:where_write] + str(sectors_used-1) + linked_file[where_write+len("0"):]

#linked_file = list(linked_file)
#linked_file[where_write_sectors] = str(sectors_used-1)
#linked_file = "".join(linked_file)

file_out = open("linked.asm", "w")
file_out.write(linked_file)
file_out.close()

system("nasm linked.asm -o linked.bin")

print("Size of the boot file after padding: ", space_used, "B", sep="",end=" ")
print("in", sectors_used, "sectors")
