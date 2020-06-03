#!/usr/bin/python

import getopt
import sys

def main():
	options, remaining = getopt.getopt(sys.argv[1:], 'b:o:', ['bucket=', 'output-dir='])

	bucket=''
	outputDir=''

	print(options)

	if len(options) != 0:
		for opt, arg in options:
				if opt in ('-b', '--bucket'):
						bucket = arg
				elif opt in ('-o', '--output-dir'):
						outputDir = arg

	print ('BUCKET = ', bucket)
	print ('OUTPUT DIR = ', outputDir)



if __name__ == '__main__':
	main()
