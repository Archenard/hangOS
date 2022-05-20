#!/usr/bin/env python3

f = open("designs.txt", "r")
content = f.read()
f.close()

if content[-1] == "\n":
	content = content[:-1]

designs = content.split("\n\n\n")
output_file = ""

for design in designs:
	lines = design.split("\n")
	output_file += "db "+'"'
	for line in lines:
		output_file += line+" "*(80-len(line))
	output_file += '"'+"\n"

f = open("designed.asm", "w")
f.write(output_file)
f.close()
