#!/usr/bin/python
# encoding: utf-8
import sys
import os.path
from workflow import Workflow

def main(wf):
	args = wf.args

if __name__ == '__main__':
	wf = Workflow()
	sys.exit(wf.run(main))