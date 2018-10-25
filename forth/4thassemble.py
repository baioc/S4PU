import csv
import sys


# GLOBALS
MAP_OFFSET = 32768
PROG_SIZE = 4096

code = []
fin = sys.argv[1]
fout = fin[:-4] + ".mif"


# START
print("**** Lazy Forth Assembler ****", "in: %s" % fin, "out: %s\n" % fout, sep="\n")

with open("./ISA.csv", "r") as isa_file, open(fin, "r") as asm_file:
	# ISA
	print("Fetching instruction set...")
	isa = []
	isa_reader = csv.DictReader(isa_file)
	for i, row in enumerate(isa_reader):
		isa.append((row["Assembly"],row["Machine Code"]))
		# print(isa[i])				# @debug instruction set

	# PARSE ASM
	print("\nParsing assembly program...")
	asm = asm_file.read().split("\n")
	for i, word in enumerate(asm):
		# print(word)					# @debug assembly program
		if word[0] == '&':	# get relative address for call/jump
			raddr = i + int(word[1:])
			asm[i] = str(raddr+MAP_OFFSET)

	# ASSEMBLE
	print("\nAssembling machine code...")
	for addr, word in enumerate(asm):
		for inst in isa:
			if str(word) == str(inst[0]):
				code.append(hex(int(inst[1], base=16)))
				break
		else:
			code.append(hex(int(word)))


# BUILD 16-bit MIF
def make_mif_16b(filename:str, code:list, depth:int):
	with open(filename, "w+") as mif_file:
		mif_file.write("WIDTH=16;\n")
		mif_file.write("DEPTH=%d;\n\n" % depth)
		mif_file.write("ADDRESS_RADIX=HEX;\n")
		mif_file.write("DATA_RADIX=HEX;\n\n")
		mif_file.write("CONTENT BEGIN\n")

		for i, line in enumerate(code):
			wstr = "\t%04x\t:\t%04x;\n" % (i, int(line, base=16))
			mif_file.write(wstr)
			# print(wstr, end="")		# @debug machine memory

		mif_file.write("\t[%04x..%04x]\t:\t0000;\n" % (len(code), depth-1) )
		mif_file.write("END;\n")
		return


# OUTPUT
print("\nWriting memory file...")
make_mif_16b(fout, code, PROG_SIZE)

print("...done\n")
