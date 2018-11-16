import csv
import sys
import re


# GLOBALS
MAP_OFFSET = 32768			# ROM start address
PROG_SIZE = 4096			# ROM size
fin = sys.argv[1]			# input file
fout = fin[:-4] + '.mif'	# output file
code = []					# generated machine code


# GREET
print('**** Lazy Forth Assembler ****')
print('in: %s' % fin)
print('out: %s\n' % fout)

# START
with open('./ISA.csv', 'r') as isa_file, open(fin, 'r') as asm_file:

	print('Fetching instruction set...')
	isa = []

	isa_reader = csv.DictReader(isa_file)
	for i, row in enumerate(isa_reader):
		isa.append( (row['Assembly'], row['Machine Code']) )
		# print(isa[i])	# @debug instruction set


	print('\nParsing assembly program...')
	asm = []

	# sanitizing
	for s in asm_file.read().split('\n'):
		s = re.sub(r'\(.*\)', '', s)	# ignore comments
		s = s.strip()					# clear whitespace
		if s != '':						# ignore empty lines
			# print(s)	# @debug sanitized assembly
			asm.append(s)

	# parsing directives
	for i, line in enumerate(asm):
		if line[0] == '&':		# address relative to current line
			raddr = i + int(line[1:])
			asm[i] = str(raddr + MAP_OFFSET)

		elif line[0] == '$':	# label definition
			words = line.split()
			addr = i + MAP_OFFSET

			if addr % 2 != 0:
				print('\nWARNING: \"%s\" label at odd address %s, it better not be a subroutine!' % (words[0][1:-1], hex(addr)))
				if input('Continue? (y/n): ').casefold() != 'y':
					print('\nleaving... ')
					exit()

			isa.append( (words[0][1:-1], str(hex(addr))) )
			asm[i] = words[1]

		elif line[0] == '#':	# constant define
			words = line.split()
			isa.append( (words[0][1:], words[1]) )
			asm[i] = "NOP"


	# ASSEMBLE
	print('\nAssembling machine code...')
	for addr, word in enumerate(asm):
		for inst in isa:
			if str(word).casefold() == str(inst[0]).casefold():
				code.append(hex(int(inst[1], base=16)))
				break
		else:
			code.append(hex(int(word)))


# BUILD 16-bit MIF
def make_mif_16b(filename:str, code:list, depth:int):
	with open(filename, 'w+') as mif_file:
		mif_file.write('WIDTH=16;\n')
		mif_file.write('DEPTH=%d;\n\n' % depth)
		mif_file.write('ADDRESS_RADIX=HEX;\n')
		mif_file.write('DATA_RADIX=HEX;\n\n')
		mif_file.write('CONTENT BEGIN\n')

		for i, line in enumerate(code):
			wstr = '\t%04x\t:\t%04x;\n' % (i, int(line, base=16))
			mif_file.write(wstr)
			# print(wstr, end='')	# @debug machine memory

		mif_file.write('\t[%04x..%04x]\t:\t0000;\n' % (len(code), depth-1) )
		mif_file.write('END;\n')
		return


# OUTPUT
print('\nWriting memory file...')
make_mif_16b(fout, code, PROG_SIZE)

print('...done!\n')
