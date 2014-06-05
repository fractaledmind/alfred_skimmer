#!/usr/bin/python
# encoding: utf-8
import sys
from workflow import Workflow

TEXT = """This is some sample text. Pucci_1.3

That is all
"""


SKIMMER = """skimmer://{path}?page=0"""

def main(wf):
    import subprocess
    import urllib

    pdf_query = """mdfind "(kMDItemKind == 'PDF')" \
        -onlyin '/Users/smargheim/Documents/PDFs'"""
    output = subprocess.check_output(pdf_query, shell=True)
    pdf_list = output.split("\n")
    
    if pdf_list[-1] == "":
        pdf_list = pdf_list[:-1]
    
    _str = TEXT
    for item in pdf_list:
        pdf_title = item.split("/")[-1]
        clean_title = pdf_title.replace('.pdf', '')
        if clean_title in _str:
            html_path = urllib.quote(item)
            _url = SKIMMER.format(path=html_path)
            html_ref = '[' + clean_title + '](' + _url + ')'
            _str = _str.replace(clean_title, html_ref)
    print _str

    
    
if __name__ == '__main__':
    wf = Workflow()
    sys.exit(wf.run(main))
