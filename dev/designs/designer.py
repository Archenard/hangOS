#!/usr/bin/env python3

f = open("designs.txt", "r")
content = f.read()
f.close()

if content[-1] == "\n":
	content = content[:-1]

designs = content.split("\n\n\n")
output_file = ""

where = len(designs)*2
offsets = []

for design in designs:
	offsets.append(where)
	lines = design.split("\n")
	for line in lines:
		output_file += 'db "'+line+'", 10\n'
		where += len(line)+1
	output_file += "db 0\n\n"
	where += 1

header = "designs:\n"
for offset in offsets:
	header += "dw "+str(offset)+"\n"

output_file = header+"\n\n\n"+output_file

f = open("../designed.asm", "w")
f.write(output_file)
f.close()
