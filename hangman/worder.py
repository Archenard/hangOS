#!/usr/bin/env python3

def read_file(file_path):
    f = open(file_path, "r")
    content = f.read()
    f.close()
    return content

try:
    words = read_file("words.txt").split("\n")
except:
    print("Error, exiting")
    print("You need to have a file named 'words.txt' in this directory")
    print("which contains one word per line")
    exit()
while "" in words:
    del words[words.index("")]

fetched = []
where_word = len(words)*2
offsets = []
for i, word in enumerate(words):
    line = "db "+'"'+word.upper()+'"'+", "+"0"
    offsets.append(hex(where_word))
    where_word += len(word)+1
    fetched.append(line)

file_out_content = "words_offsets: dw "+", ".join(offsets)+"\n"
file_out_content += "\n".join(fetched)

file_out = open("worded.asm", "w")
file_out.write(file_out_content)
file_out.close()
