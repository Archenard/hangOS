#!/usr/bin/env/python3

f = open("keyboards.txt", "r")
files_to_read = f.read()
f.close()

files_to_read = files_to_read.split("\n")
while "" in files_to_read:
	del files_to_read[files_to_read.index("")]

offsets = []
where = len(files_to_read)*2
text_out = ""

for file_name in files_to_read:
	f = open(file_name, "r")
	file_to_extract = f.read()
	f.close()
	
	offsets.append(where)

	file_to_extract = file_to_extract.split("\n")
	while "" in file_to_extract:
		del file_to_extract[file_to_extract.index("")]
	
	for line_to_extract in file_to_extract:
		line_to_extract = line_to_extract.split(" ")
		letter = line_to_extract[0]
		letter = letter.upper()
		scan_code = line_to_extract[1]
		#scan_code = int(scan_code, 16)
		
		#print(letter, scan_code)
		
		text_out += "db 0x"+scan_code+"\n"
		where += 1
	text_out += "\n"

header = "keyboards:\n"
for offset in offsets:
	header += "dw "+str(offset)+"\n"

text_out = header+"\n\n"+text_out

f = open("keyboarded.asm", "w")
f.write(text_out)
f.close()
