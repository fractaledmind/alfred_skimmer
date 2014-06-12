#!/usr/bin/env python
# -*- coding: utf-8 -*-
import subprocess
import re
import sys

"""
This script extracts relevant metadata from PDF
"""

# Get user input
_input = sys.argv[1].split(u'zzz')
#_input = "/Users/smargheim/Documents/PDFs/Zotero/griffiths_1999_how epistemology matters to theology_journal article.pdfzzz3zzz/Users/smargheim/Desktop/test.scptd/Contents/Resources/pdftotext".split('zzz')
pdf_path = _input[0]
pdf_page = _input[1]
_path = _input[2]
	
# Extract text of PDF page
pdf_txt = subprocess.Popen([_path, "-q", "-f", str(pdf_page), "-l", str(pdf_page), pdf_path, "-"], stdout=subprocess.PIPE).communicate()[0]

def get_doi(pdf_txt):
	# DOI regex 
	# (http://stackoverflow.com/questions/27910/finding-a-doi-in-a-document-or-page)
	doi_re = re.compile(r'\b(10[.][0-9]{4,}(?:[.][0-9]+)*/(?:(?!["&\'<>])\S)+)\b')
	# try to get DOI
	doi = re.search(doi_re, pdf_txt)
	if doi != None:
		return doi.group(1).strip()
	else:
		return None

def get_isbn(pdf_txt):
	# ISBN regex
	isbn_re = re.compile(r"ISBN((-1(?:(0)|3))?:?\x20(\s)*[0-9]+[- ][0-9]+[- ][0-9]+[- ][0-9]*[- ]*[xX0-9])")
	# try to get ISBN
	isbn = re.search(isbn_re, pdf_txt)
	if isbn != None:
		return isbn.group(1).strip()
	else:
		return None

# Use this to have user select keywords
def cap2keywords(pdf_txt):
	cap_words = re.findall(r"\b[A-Z].*?\b", pdf_txt, re.M)
	cap_words = list(set(cap_words))
	poss_search_terms = [x for x in cap_words if len(x) >= 4]
	return poss_search_terms


# First, check if title page of JSTOR pdf
if 'JSTOR' in pdf_txt:
	jstor_regex = re.compile("^(.*?)Author\\(s\\):\\s(.*?)Source:\\s(.*?)Published by:\\s(.*?)Stable URL:\\s(.*?)Accessed:\\s(.*?)(?:\\n|\\r)", re.S)
	res = re.search(jstor_regex, pdf_txt)

	if res != None:
		try:
			title = re.search(r"^(.*?)(?=Author)", pdf_txt).group(1).strip()
		except:
			title = u'missing value'
		try:
			creator = re.search(r"Author\(s\):\s(.*?)(?=Reviewed|Source)", pdf_txt).group(1).strip()
		except:
			creator = u'missing value'
		
		final_res = title + u' ' + creator
	
	# If no JSTOR data
	else:
		# try DOI
		final_res = get_doi(pdf_txt)
		if final_res == None:
			# try ISBN
			final_res = get_isbn(pdf_txt)
			if final_res == None:
				final_res = cap2keywords(pdf_txt)

# If no JSTOR on page
else:
	# try DOI
	final_res = get_doi(pdf_txt)
	
	if final_res == None:
		# try ISBN
		final_res = get_isbn(pdf_txt)
		if final_res == None:
			final_res = cap2keywords(pdf_txt)

print final_res
