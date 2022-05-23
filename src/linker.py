#!/usr/bin/env python3

from subprocess import run


## extract files to link

try:
    f = open("links.lst", "r")
    files_list = f.read()
    f.close()
except:
    print("Error, exiting")
    print("You need to have a file named 'links.lst' in this directory")
    print("which contains one file name per line")
    exit()
files_list = files_list.split("\n")
while "" in files_list:
    del files_list[files_list.index("")]


## get the data to write the file

linked_file = ""
for file_name in files_list:
    f = open(file_name, "r")
    file_content = f.read()
    f.close()
    linked_file += file_content+"\n\n"

## save where we need to write number of sectors used

where_write_sectors = []
while "__sectors__" in linked_file:
    where_write_sectors.append(linked_file.index("__sectors__"))
    linked_file = linked_file[:where_write_sectors[-1]] + "0" + linked_file[where_write_sectors[-1]+len("__sectors__"):]

## write file (no padding)

file_out = open("../hangOS.asm", "w")
file_out.write(linked_file)
file_out.close()


## assemble a first time (no padding)

run("nasm ../hangOS.asm -o ../hangOS.iso".split(" "))


## determine size of the binary

f = open("../hangOS.iso", "rb")
binary_file = f.read()
f.close()
size_no_padding = len(binary_file)

print("Size of the boot file before padding: ", size_no_padding, "B", sep="")


## padding

sectors_used = (size_no_padding//512)+1
space_used = sectors_used*512
bytes_to_add = space_used-size_no_padding

linked_file += "times "+str(bytes_to_add)+" db 0"

for where_write in where_write_sectors:
    linked_file = linked_file[:where_write] + str(sectors_used-1) + linked_file[where_write+len("0"):]


## re-write file (with padding)

file_out = open("../hangOS.asm", "w")
file_out.write(linked_file)
file_out.close()


## re-assemble (with padding)
run("nasm ../hangOS.asm -o ../hangOS.iso".split(" "))

print("Size of the boot file after padding: ", space_used, "B", sep="",end=" ")
print("in", sectors_used, "sectors")
