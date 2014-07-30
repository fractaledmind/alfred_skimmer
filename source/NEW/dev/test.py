#!/usr/bin/python
# encoding: utf-8
import sys
import os
import subprocess
from workflow import Workflow

from dependencies import html2text

GET_EN_DATA = """
    tell application id "com.evernote.Evernote"
		set _sel to selection
		if _sel is {} then error "Please select a note."
		
		repeat with i from 1 to the count of _sel
			--get note title and notebook name
			set _title to title of item i of _sel
			set _notebook to name of notebook of item i of _sel
			
			--get list of tags into comma-separated string
			set _tags to tags of item i of _sel
			set tags_lst to {}
			repeat with j from 1 to count of _tags
				copy (name of item j of _tags) to the end of tags_lst
			end repeat
			set _tags to my join_list(tags_lst, ", ")
			
			--get note HTML
			set note_html to HTML content of item i of _sel
		end repeat
	end tell

	set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, return & "||" & return}
	set l to {_title, _notebook, _tags, note_html} as string
	set AppleScript's text item delimiters to tid
	return l

	to join_list(aList, delimiter)
		set retVal to ""
		set prevDelimiter to AppleScript's text item delimiters
		set AppleScript's text item delimiters to delimiter
		set retVal to aList as string
		set AppleScript's text item delimiters to prevDelimiter
		return retVal
	end join_list
"""

def _unify(obj, encoding='utf-8'):
    """Ensure passed text is Unicode"""
    if isinstance(obj, basestring):
        if not isinstance(obj, unicode):
            obj = unicode(obj, encoding)
    return obj

##################################################
### AppleScript Functions
##################################################

def _applescriptify_str(text):
    """Replace double quotes in text for Applescript string"""
    text = _unify(text)
    return text.replace('"', '" & quote & "')

def _applescriptify_list(_list):
    """Convert Python list to Applescript list"""
    quoted_list = []
    for item in _list:
        if type(item) is unicode:   # unicode string to AS string
            _new = '"' + item + '"'
            quoted_list.append(_new)    
        elif type(item) is str:     # string to AS string
            _new = '"' + item + '"'
            quoted_list.append(_new)    
        elif type(item) is int:     # int to AS number
            _new = str(item)
            quoted_list.append(_new)
        elif type(item) is bool:    # bool to AS Boolean
            _new = str(item).lower()
            quoted_list.append(_new)
    quoted_str = ', '.join(quoted_list)
    return '{' + quoted_str + '}'

def as_run(ascript):
    """Run the given AppleScript and return the standard output and error."""
    ascript = _unify(ascript)
    osa = subprocess.Popen(['osascript', '-'],
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE)
    return osa.communicate(ascript.encode('utf-8'))[0].strip()

def main(wf):
    """"""
    en_data = as_run(GET_EN_DATA)
    (en_title, en_notebook, en_tags, en_html) = en_data.split('\r||\r')
    print html2text.html2text(en_html)


    
if __name__ == '__main__':
    wf = Workflow()
    sys.exit(wf.run(main))
