#!/usr/bin/python
# encoding: utf-8
import sys
import os.path
from workflow import Workflow

def main(wf):
	import subprocess

	query = 'hippocrates'
	pdf_query = """mdfind "(kMDItemKind == 'PDF') && (kMDItemTitle == '*{0}*'c)"
	""".format(query)
	output = subprocess.check_output(pdf_query, shell=True)
	returnList = output.split("\n")
	if returnList[-1] == "":
		returnList = returnList[:-1]
	print returnList
if __name__ == '__main__':
	wf = Workflow()
	sys.exit(wf.run(main))

