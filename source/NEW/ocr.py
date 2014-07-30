#!/usr/bin/python
# encoding: utf-8
import sys
import subprocess
from workflow import Workflow

def needs_ocr(pdf_path):
    """Check if PDF at `path` has searchable text.
    """
    exe = wf.workflowfile('dep_pdftotext')
    cmd = [exe, "-q", "-l", '5', pdf_path, "-"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    pdf_txt = proc.communicate()[0]

    if pdf_txt == '\x0c':
        return True
    else:
        return False

def main(wf):
    pdf_path = '/Users/smargheim/Downloads/sublime-productivity.pdf'
    pdf_path = '/Users/smargheim/Downloads/test.pdf'
    if needs_ocr(pdf_path):
        print 'yes'
    

if __name__ == '__main__':
    wf = Workflow()
    sys.exit(wf.run(main))
