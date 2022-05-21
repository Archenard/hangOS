#!/usr/bin/env python3

f = open("editable/langs.lst", "r")
langs = f.read()
f.close()
langs = langs.split("\n")
while "" in langs:
    del langs[langs.index("")]


langs_offsets = [(len(langs)+1)*2]
for lang in langs:
	f = open(lang, "r")
	words = f.read()
	f.close()
	words = words.split("\n")
	while "" in words:
		del words[words.index("")]

	langs_offsets.append(langs_offsets[-1]+(len(words)*2))

words_offsets = [0]*len(langs)


longest_word = 0
where = langs_offsets[-1]
for i, lang in enumerate(langs):
	f = open(lang, "r")
	words = f.read()
	f.close()
	words = words.split("\n")
	while "" in words:
		del words[words.index("")]
	
	words_offsets[i] = []
	for word in words:
		words_offsets[i].append(where)
		where += len(word)+1
		if len(word) > longest_word:
			longest_word = len(word)


content_out = "words_langs:\n"
for lang_offset in langs_offsets:
	content_out += "dw "+str(lang_offset)+"\n"
content_out += "\n\n\n\n\n"

for word_offsets in words_offsets:
	for word_offset in word_offsets:
		content_out += "dw "+str(word_offset)+"\n"
	content_out += "\n\n\n"
content_out += "\n\n\n\n\n"


for lang in langs:
	f = open(lang, "r")
	words = f.read()
	f.close()
	words = words.split("\n")
	while "" in words:
		del words[words.index("")]

	for word in words:
		content_out += "db "+'"'+word.upper()+'"'+", 0\n"
	content_out += "\n\n\n"

content_out += "max_word_length: db "+str(longest_word)+"\n"
content_out += 'word_found: db "'+('_'*longest_word)+'", 0'

file_out = open("../worded.asm", "w")
file_out.write(content_out)
file_out.close()
