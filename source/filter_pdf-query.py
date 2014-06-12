#!/usr/bin/python
# encoding: utf-8
import sys
from workflow import Workflow

def main(wf):
	import subprocess

	query = wf.args[0]
	#query = 'galen'

	pdf_query = """mdfind "(kMDItemKind == 'PDF') && (kMDItemTitle == '*{0}*'c)"
	""".format(query)
	output = subprocess.check_output(pdf_query, shell=True)
	
	returnList = output.split("\n")
	if returnList[-1] == "":
		returnList = returnList[:-1]

	for item in returnList:
		title = item.split("/")[-1]
		sub = "/".join(item.split("/")[:-1])
		wf.add_item(title, sub, 
			arg=item, 
			valid=True,
			type='file',
			icon='icons/n_pdf.png')

	wf.send_feedback()
	
if __name__ == '__main__':
	wf = Workflow()
	sys.exit(wf.run(main))