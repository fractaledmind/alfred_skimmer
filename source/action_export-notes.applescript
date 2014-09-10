(* ///
PROPERTIES 
/// *)

--Formatting
(* DO NOT CHANGE *)
property line_break : {html:"<br></br>", md:(ASCII character 10) & (ASCII character 10)}
property as_delims : AppleScript's text item delimiters

--Evernote
(* CHANGE NAME OF EVERNOTE NOTEBOOK AND/OR TAG WHERE NOTES WILL RESIDE *)
property en_notebook : "PDF Notes"
--If you don't want to tag the notes, set `en_tag` to ""
property en_tag : "pdf_notes"
--If you don't want highlights grouped and sorted (but rather in timestamp order), set `highlights_sorted ` to false
property highlights_sorted : true

(* EXPORT OPTIONS *)
property export_style : item 1 of {"HTML", "Markdown"}
property export_destination : item 1 of {"Evernote", "Clipboard"}

(* CHANGE FOR FORMATTING OF VARIOUS NOTE KINDS *)
property prefix : {{annotation:"text note", formatting:{html:"<p>", md:""}}, {annotation:"anchored note", formatting:{html:"<p>", md:""}}, {annotation:"underline note", formatting:{html:"<p>", md:""}}, {annotation:"strike out note", formatting:{html:"<p>", md:""}}, {annotation:"highlight note", formatting:{html:"<p>", md:""}}}
property title_front : {{annotation:"text note", formatting:missing value}, {annotation:"anchored note", formatting:{html:"<strong>", md:"**"}}, {annotation:"underline note", formatting:missing value}, {annotation:"strike out note", formatting:missing value}, {annotation:"highlight note", formatting:{html:"<strong>", md:"**"}}}
property title_back : {{annotation:"text note", formatting:missing value}, {annotation:"anchored note", formatting:{html:":</strong>", md:":**"}}, {annotation:"underline note", formatting:missing value}, {annotation:"strike out note", formatting:missing value}, {annotation:"highlight note", formatting:{html:":</strong>", md:":**"}}}
property body_front : {{annotation:"text note", formatting:{html:"", md:""}}, {annotation:"anchored note", formatting:{html:"", md:""}}, {annotation:"underline note", formatting:{html:"\"", md:"\""}}, {annotation:"strike out note", formatting:{html:"\"", md:"\""}}, {annotation:"highlight note", formatting:{html:"", md:""}}}
property body_back : {{annotation:"text note", formatting:{html:"", md:""}}, {annotation:"anchored note", formatting:{html:"", md:""}}, {annotation:"underline note", formatting:{html:"\"", md:"\""}}, {annotation:"strike out note", formatting:{html:"\"", md:"\""}}, {annotation:"highlight note", formatting:{html:"", md:""}}}
property suffix : {{annotation:"text note", formatting:{html:"</p>", md:""}}, {annotation:"anchored note", formatting:{html:"</p>", md:""}}, {annotation:"underline note", formatting:{html:"</p>", md:""}}, {annotation:"strike out note", formatting:{html:"</p>", md:""}}, {annotation:"highlight note", formatting:{html:"</p>", md:""}}}

on run
	(* ///
	HELPER FUNCTION
	/// *)
	
	--Get path to current directory
	set base_path to my get_base_path()
	
	try
		--Load Workflow helper scripts
		set wf to load script (base_path & "_wf-helpers.scpt")
		
		--Get user's export Preferences
		set rec to my get_settings(wf)
		set export_style to rec's |style|
		set export_destination to rec's destination
		
		--Get user's Highlight Preferences
		set annotations_path to wf's get_storage() & "annotations_config.json"
		set json to read (POSIX file annotations_path)
		set clean to wf's replace(json, "\"", "\\\"")
		set highlight_rec to wf's read_json(clean)
	on error
		--If user hasn't configured, set defaults		
		set highlight_rec to {{_title:"Summary", _color:{65535, 65531, 2689, 65535}}, {_title:"Disagree", _color:{64634, 467, 1798, 65535}}, {_title:"Agree", _color:{64907, 32785, 2154, 65535}}, {_title:"Reference", _color:{8608, 65514, 1548, 65535}}, {_title:"Quotable", _color:{8372, 65519, 65472, 65535}}, {_title:"Technique", _color:{64587, 609, 65481, 65535}}}
	end try
	
	(* ///
	THE SCRIPT 
	/// *)
	
	tell application "Skim"
		
		(* ///
		PRE-PROCESSING: Check if annotated on iOS. If yes, convert annotations.
		Then save original document
		/// *)
		
		try
			convert notes front document
			save front document
		on error msg
			return msg & " in Pre-Processing."
		end try
		
		(* ///
		PART 1: Dialog Box
		/// *)
		
		try
			set _icon to base_path & "icon.png"
			set _icon to POSIX file _icon as alias
			set page_relation to text returned of (display dialog "Subtract printed page number from Skim's indexed page number." with title "Skimmer" default answer "0" with icon _icon) as number
		on error msg
			return msg & " in Part 1: Dialog Box"
		end try
		
		(* /// 
		PART 2: Get all necessary Information 
		/// *)
		
		--Set proper line break type
		if export_style = "HTML" then
			set line_break to html of line_break
		else if export_style = "Markdown" then
			set line_break to md of line_break
		end if
		
		--Get key PDF information
		set pdf_name to (name of front document)
		set _file to (path of front document)
		set file_url to my encode_text(_file, false, false)
		set skimmer_url to "skimmer://" & file_url & "?page="
		set all_notes to every note of front document
		
		--Prepare all annotation lists
		set notes_text to my get_header(export_style, "The ToC")
		set notes_anchor to my get_header(export_style, "All of my Text Notes")
		set notes_underline to my get_header(export_style, "All of the Underlined Text")
		set notes_strikethru to my get_header(export_style, "All of the Strike-Through Text")
		set notes_highlight to my get_header(export_style, "All of the Highlighted Text")
		
		--Prepare existence checks
		set {_text_, _anchor_, _underline_, _strikethru_, _highlight_} to {false, false, false, false, false}
		
		(* ///
		PART 3: The Meat-n-Potatoes of the Script 
		/// *)
		
		repeat with i from 1 to count of all_notes
			set _note to (item i of all_notes)
			set _page to index of page of _note
			set real_page to (_page + page_relation) as string
			set this_url to skimmer_url & _page
			
			if type of _note is text note then
				set note_text to text of _note
				copy (my get_annotation((type of _note) as string, "", note_text, this_url, real_page)) to end of notes_text
				set _text_ to true
				
			else if type of _note is anchored note then
				set title_text to text of _note
				set note_text to extended text of _note
				copy (my get_annotation((type of _note) as string, title_text, note_text, this_url, real_page)) to end of notes_anchor
				set _anchor_ to true
				
			else if type of _note is underline note then
				set note_text to text of _note
				copy (my get_annotation((type of _note) as string, "", note_text, this_url, real_page)) to end of notes_underline
				set _underline_ to true
				
			else if type of _note is strike out note then
				set note_text to text of _note
				copy (my get_annotation((type of _note) as string, "", note_text, this_url, real_page)) to end of notes_strikethru
				set _strikethru_ to true
				
			else if type of _note is highlight note then
				set note_text to text of _note
				set title_text to my color2text(highlight_rec, color of _note)
				copy (my get_annotation((type of _note) as string, title_text, note_text, this_url, real_page)) to end of notes_highlight
				set _highlight_ to true
			end if
		end repeat
		
		(* ///
		PART 4: Sort the Highlighted Text
		/// *)
		
		if highlights_sorted = true then
			set notes_highlight to my _sortlist(notes_highlight)
			set AppleScript's text item delimiters to line_break
			set notes_highlight to (notes_highlight as string)
			set AppleScript's text item delimiters to as_delims
		end if
		
		(* ///
		PART 5: Concatenate all Existing Annotation Sections
		/// *)
		
		set final_text to ""
		if _text_ = true then set final_text to final_text & notes_text
		if _anchor_ = true then set final_text to final_text & notes_anchor
		if _underline_ = true then set final_text to final_text & notes_underline
		if _strikethru_ = true then set final_text to final_text & notes_strikethru
		if _highlight_ = true then set final_text to final_text & notes_highlight
		
		(* ///
		PART 6: Export the Notes
		/// *)
		
		if export_destination = "Evernote" then
			set _evernote_ to false
			repeat until _evernote_ = true
				tell application "System Events"
					if not (exists process "Evernote") then
						tell application id "com.evernote.Evernote" to activate
						delay 1
						tell application id "com.evernote.Evernote" to activate
					end if
					if (exists process "Evernote") then set _evernote_ to true
				end tell
			end repeat
			
			tell application id "com.evernote.Evernote"
				if (not (notebook named en_notebook exists)) then
					make notebook with properties {name:en_notebook}
				end if
				
				if export_style = "HTML" then
					set newNote to create note title pdf_name with html final_text notebook en_notebook
				else if export_style = "Markdown" then
					set newNote to create note title pdf_name with text final_text notebook en_notebook
				end if
				
				if not en_tag = "" then
					if (not (tag named en_tag exists)) then
						set tg to make tag with properties {name:en_tag}
					else
						set tg to tag en_tag
					end if
					assign tg to newNote
				end if
				
				--synchronize Evernote
				repeat until isSynchronizing is false
					synchronize
				end repeat
				repeat until isSynchronizing is false
				end repeat
			end tell
			
		else if export_destination = "Clipboard" then
			set the clipboard to final_text
		end if
		
		return "Exported notes to " & export_destination & " as " & export_style
	end tell
end run

(* HANDLERS *)

on get_base_path()
	set {as_delims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, "/"}
	set _path to (text items 1 thru -2 of (POSIX path of (path to me)) as string) & "/"
	set AppleScript's text item delimiters to as_delims
	return _path
end get_base_path

on get_settings(wf)
	set _bundle to wf's get_bundle()
	set settings_path to (path to "cusr" as text) & "Library:Application Support:Alfred 2:Workflow Data:" & _bundle & ":settings.json" as text
	set the file_ to open for access file settings_path
	set json_ to (read file_)
	close access file_
	set clean to wf's replace(json_, "\"", "\\\"")
	set rec to wf's read_json(clean)
	return rec
end get_settings

on get_header(_style, _header)
	if _style = "HTML" then
		return {"<hr />" & line_break & "<h2>" & _header & "</h2>" & line_break}
	else if _style = "Markdown" then
		return {"- - -" & line_break & "## " & _header & " ##" & line_break}
	end if
end get_header

on get_sub_header(_style, _header)
	if _style = "HTML" then
		return line_break & "<h4>" & _header & "</h4>" & line_break
	else if _style = "Markdown" then
		return line_break & "#### " & _header & " ####" & line_break
	end if
end get_sub_header

on get_annotation(_type, _title, note_text, hyperlink, real_page)
	set _prefix to my get_prefix(_type, _title)
	set _body to my get_body(_type, note_text)
	set _link to my get_link(_type, real_page, hyperlink)
	set _suffix to my get_property_formatting(suffix, _type)
	return _prefix & space & _body & space & _link & _suffix
end get_annotation

on get_prefix(_type, _title)
	set _prefix to my get_property_formatting(prefix, _type)
	set _title_front to my get_property_formatting(title_front, _type)
	set _title_back to my get_property_formatting(title_back, _type)
	return _prefix & _title_front & _title & _title_back
end get_prefix

on get_body(_type, note_text)
	--{wrap}<note text>{/wrap}
	set _body_front to my get_property_formatting(body_front, _type)
	set _body_back to my get_property_formatting(body_back, _type)
	return _body_front & note_text & _body_back
end get_body

on get_link(_type, real_page, hyperlink)
	set link_front to {formatting:{html:"(", md:"("}}
	set link_back to {formatting:{html:")", md:")"}}
	set _link_front to my get_property_formatting(link_front, _type)
	set _link_back to my get_property_formatting(link_back, _type)
	
	set _page to my get_abbr(_type, real_page)
	set _url to my get_url(_type, hyperlink)
	
	if export_style = "HTML" then
		return _link_front & _url & _page & _link_back
	else if export_style = "Markdown" then
		return _link_front & _page & _url & _link_back
	end if
end get_link



on get_url(_type, hyperlink)
	set url_front to {formatting:{html:"<a href=\"", md:"("}}
	set url_back to {formatting:{html:"\">", md:")"}}
	set _url_front to my get_property_formatting(url_front, _type)
	set _url_back to my get_property_formatting(url_back, _type)
	return _url_front & hyperlink & _url_back
end get_url

on get_abbr(_type, real_page)
	set abbr_front to {formatting:{html:"p. ", md:"[p. "}}
	set abbr_back to {formatting:{html:"</a>", md:"]"}}
	set _abbr_front to my get_property_formatting(abbr_front, _type)
	set _abbr_back to my get_property_formatting(abbr_back, _type)
	return _abbr_front & real_page & _abbr_back
end get_abbr


on get_property_formatting(_property, _type)
	try
		if export_style = "HTML" then
			return html of formatting of _property
		else if export_style = "Markdown" then
			return md of formatting of _property
		end if
	on error
		repeat with _item in _property
			if annotation of _item = _type then
				if export_style = "HTML" then
					try
						return html of formatting of _item
					on error
						return ""
					end try
				else if export_style = "Markdown" then
					try
						return md of formatting of _item
					on error
						return ""
					end try
				end if
			end if
		end repeat
	end try
	return ""
end get_property_formatting

--convert highlights into text values
on color2text(rec, noteColor)
	set colorText to "[***]"
	repeat with i from 1 to count of rec
		set this to item i of rec
		if noteColor is this's _color then
			set colorText to this's _title
		end if
	end repeat
	return colorText
end color2text

--URL encode text
on encode_text(this_text, encode_URL_A, encode_URL_B)
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789"
	set the URL_A_chars to "$+!'/?;&@=#%><{}[]\"~`^\\|*"
	set the URL_B_chars to ".-_:"
	set the acceptable_characters to the standard_characters
	if encode_URL_A is false then set the acceptable_characters to the acceptable_characters & the URL_A_chars
	if encode_URL_B is false then set the acceptable_characters to the acceptable_characters & the URL_B_chars
	set the encoded_text to ""
	repeat with this_char in this_text
		if this_char is in the acceptable_characters then
			set the encoded_text to (the encoded_text & this_char)
		else
			set the encoded_text to (the encoded_text & encode_char(this_char)) as string
		end if
	end repeat
	return the encoded_text
end encode_text

on encode_char(this_char)
	set the ASCII_num to (the ASCII number this_char)
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set x to item ((ASCII_num div 16) + 1) of the hex_list
	set y to item ((ASCII_num mod 16) + 1) of the hex_list
	return ("%" & x & y) as string
end encode_char

on _sortlist(theList)
	-- a stack-based, non-recursive quicksort
	local theList, s, l, a, b, c, j, r, v, i, tmp
	try
		if theList's class is not list then error "not a list." number -1704
		if (count theList each number) > 0 and ¬
			((count theList each string) > 0) then
			error "can't sort a list containing both " & ¬
				"number and text values." number -1704
		end if
		script k -- list access speed kludge
			property lst : theList's items
		end script
		if k's lst's length < 2 then return k's lst
		set s to {a:1, b:count k's lst, c:missing value} -- unsorted slices stack
		repeat until s is missing value
			set l to s's a
			set r to s's b
			set s to get s's c
			set i to l
			set j to r
			set v to k's lst's item ((l + r) div 2)
			repeat while (j > i)
				repeat while (k's lst's item i < v)
					set i to i + 1
				end repeat
				repeat while (k's lst's item j > v)
					set j to j - 1
				end repeat
				if (i ≤ j) then
					set tmp to k's lst's item i
					set k's lst's item i to k's lst's item j
					set k's lst's item j to tmp
					set i to i + 1
					set j to j - 1
				end if
			end repeat
			if (l < j) then set s to {a:l, b:j, c:s}
			if (r > i) then set s to {a:i, b:r, c:s}
		end repeat
		return k's lst
	on error eMsg number eNum
		error "Can't sortList: " & eMsg number eNum
	end try
end _sortlist
