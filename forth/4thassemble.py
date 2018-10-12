import csv
import sys


# GLOBALS
OFFSET = 32768
PROG_SIZE = 4608

isa = {}
asm = []
code = {}

fin = sys.argv[1]
fout = fin[:-4] + ".mif"


# GREET
print("**** Simple Forth Assembler ****", "in: %s" % fin, "out: %s\n" % fout, sep="\n")


# ISA
with open("./ISA.csv", "r") as isa_file:
	isa_reader = csv.DictReader(isa_file)

	print("Fetching instruction set...")
	for i, row in enumerate(isa_reader):
		isa[i] = (row["Assembly"],row["Machine Code"])

		# print(isa[i])	# @debug instruction set

	isa = isa.values()


# INPUT
with open(fin, "r") as asm_file:
	print("\nParsing assembly program...")
	asm = asm_file.read().split("\n")

	for i, word in enumerate(asm):
		# print(word)	# @debug assembly program

		if word[0] is '&':	# get relative address for call/jump
			raddr = i + int(word[1:])
			asm[i] = str(raddr+OFFSET)


# ASSEMBLE
print("\nAssembling machine code...")
for addr, word in enumerate(asm):
	for inst in isa:
		if str(word) == str(inst[0]):
			code[addr] = hex(int(inst[1], base=16))
			break
	else:
		code[addr] = hex(int(word))


# OUTPUT
with open(fout, "w+") as mif_file:
	print("\nWriting memory file...")

	mif_file.write("WIDTH=16;\n")
	mif_file.write("DEPTH=%d;\n\n" % PROG_SIZE)
	mif_file.write("ADDRESS_RADIX=HEX;\n")
	mif_file.write("DATA_RADIX=HEX;\n\n")
	mif_file.write("CONTENT BEGIN\n")

	for i, line in enumerate(code.values()):
		wstr = "\t%04x\t:\t%04x;\n" % (i, int(line, base=16))
		mif_file.write(wstr)
		# print(wstr, end="")	# @debug machine memory

	mif_file.write("\t[%04x..%04x]\t:\t0000;\n" % (len(code), PROG_SIZE-1) )
	mif_file.write("END;\n")


# BYE
print("...done\n")
