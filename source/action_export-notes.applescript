(* ///
PROPERTIES 
/// *)

--Formatting
(* DO NOT CHANGE *)
property line_feed : (ASCII character 10)
property md_line_feed : (ASCII character 32) & (ASCII character 32) & (ASCII character 10)
property as_delims : AppleScript's text item delimiters

--Evernote
(* CHANGE NAME OF EVERNOTE NOTEBOOK AND/OR TAG WHERE NOTES WILL RESIDE *)
--If you don't want to tag the notes, set `en_tag` to ""
property en_notebook : "PDF Notes"
property en_tag : "pdf_notes"

--Deprecated
property export_style : "HTML"
property export_destination : "Evernote"

(* CHANGE FOR FORMATTING OF VARIOUS NOTE KINDS *)
-- See the `get_annotation_hyperlink` handler for more formatting information

--Text Note HTML
property text_prefix : "<p>"
property text_body_wrap_front : ""
property text_body_wrap_back : ""
property text_page_wrap_front : " (<a href=\""
property text_page_abbr : "\">p."
property text_page_wrap_back : "</a>)"

--Anchor Note HTML
property anchored_prefix : "<p>"
property anchored_title_wrap_front : "<strong>"
property anchored_title_wrap_back : "</strong>"
property anchored_body_wrap_front : ""
property anchored_body_wrap_back : ""
property anchored_page_wrap_front : "(<a href=\""
property anchored_page_abbr : "\">p."
property anchored_page_wrap_back : "</a>)"

--Underline Note HTML
property underline_prefix : "<p>"
property underline_body_wrap_front : "\""
property underline_body_wrap_back : "\""
property underline_page_wrap_front : "(<a href=\""
property underline_page_abbr : "\">p."
property underline_page_wrap_back : "</a>)"

--Strike-Thru Note HTML
property strike_prefix : "<p>"
property strike_body_wrap_front : "\""
property strike_body_wrap_back : "\""
property strike_page_wrap_front : "(<a href=\""
property strike_page_abbr : "\">p."
property strike_page_wrap_back : "</a>)"

--Highlight Note HTML
property highlight_prefix : "<p>"
property highlight_title_wrap_front : "<strong>"
property highlight_title_wrap_back : ":</strong>"
property highlight_body_wrap_front : ""
property highlight_body_wrap_back : ""
property highlight_page_wrap_front : "(<a href=\""
property highlight_page_abbr : "\">p."
property highlight_page_wrap_back : "</a>)"

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
		--set rec to my get_settings(wf)
		--set export_style to rec's |style|
		--set export_destination to rec's destination
		
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
		
		set pdf_name to (name of front document)
		set _file to (path of front document)
		set file_url to my encode_text(_file, false, false)
		set skimmer_url to "skimmer://" & file_url & "?page="
		set all_notes to every note of front document
		
		set notes_text to my get_header(export_style, "The ToC")
		set notes_anchor to my get_header(export_style, "All of my Text Notes")
		set notes_underline to my get_header(export_style, "All of the Underlined Text")
		set notes_strikethru to my get_header(export_style, "All of the Strike-Through Text")
		set notes_highlight to my get_header(export_style, "All of the Highlighted Text")
		
		set {_text_, _anchor_, _underline_, _strikethru_, _highlight_} to {false, false, false, false, false}
		
		(* ///
		PART 3: The Meat-n-Potatoes of the Script 
		/// *)
		
		repeat with i from 1 to count of all_notes
			set _note to item i of all_notes
			set _page to index of page of _note
			set real_page to (_page + page_relation) as string
			set this_url to skimmer_url & _page
			
			if type of _note is text note then
				set note_text to text of _note
				set notes_text to notes_text & (my get_annotation_hyperlink((type of _note), "", note_text, this_url, real_page))
				set _text_ to true
				
			else if type of _note is anchored note then
				set title_text to text of _note
				set note_text to extended text of _note
				set notes_anchor to notes_anchor & (my get_annotation_hyperlink((type of _note), title_text, note_text, this_url, real_page))
				
				set _anchor_ to true
				
			else if type of _note is underline note then
				set note_text to text of _note
				set notes_underline to notes_underline & (my get_annotation_hyperlink((type of _note), "", note_text, this_url, real_page))
				set _underline_ to true
				
			else if type of _note is strike out note then
				set note_text to text of _note
				set notes_strikethru to notes_strikethru & (my get_annotation_hyperlink((type of _note), "", note_text, this_url, real_page))
				set _strikethru_ to true
				
			else if type of _note is highlight note then
				set note_text to text of _note
				set rgba to color of _note
				set title_text to my color2text(highlight_rec, rgba)
				set notes_highlight to notes_highlight & (my get_annotation_hyperlink((type of _note), title_text, note_text, this_url, real_page))
				set _highlight_ to true
				
			end if
		end repeat
		
		(* ///
		PART 4: Remove any Empty Annotation Sections
		/// *)
		
		set final_text to ""
		if _text_ = true then set final_text to final_text & notes_text
		if _anchor_ = true then set final_text to final_text & notes_anchor
		if _underline_ = true then set final_text to final_text & notes_underline
		if _strikethru_ = true then set final_text to final_text & notes_strikethru
		if _highlight_ = true then set final_text to final_text & notes_highlight
		
		(* ///
		PART 5: Export the Notes
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
	set settings_path to (path to "cusr" as text) & "Library:Application Support:Aline_feedred 2:Workflow Data:" & _bundle & ":settings.json" as text
	set the file_ to open for access file settings_path
	set json_ to (read file_)
	close access file_
	set clean to wf's replace(json_, "\"", "\\\"")
	set rec to wf's read_json(clean)
	return rec
end get_settings

on get_header(_style, _header)
	if _style = "HTML" then
		return "<hr />" & line_feed & line_feed & "<h2>" & _header & "</h2>" & md_line_feed & line_feed & line_feed
	else if _style = "Markdown" then
		return "- - -" & line_feed & line_feed & "## " & _header & " ##" & md_line_feed & line_feed & line_feed
	end if
end get_header

on get_annotation_hyperlink(_type, _title, note_text, hyperlink, real_page)
	(* 
	For the formulae below, properties are wrapped in {curlies} and passed parameters are wrapped in <carets>. Also, note where the spaces are.
	*)
	tell application "Skim"
		if _type = text note then
			--{prefix}{wrap}<note text>{/wrap}{wrap}<link>{p.} <#>{/wrap}
			set body to (text_prefix & text_body_wrap_front & note_text & text_body_wrap_back)
			set page_front to (text_page_wrap_front & hyperlink & text_page_abbr)
			set page_back to (real_page & text_page_wrap_back)
			
			return body & space & page_front & space & page_back & line_feed & line_feed
			
		else if _type = anchored note then
			--{prefix}{wrap}<title>{/wrap} {wrap}<note text>{/wrap} {wrap}<link>{p.} <#>{/wrap}
			set anchor to (anchored_prefix & anchored_title_wrap_front & _title & anchored_title_wrap_back)
			set body to (anchored_body_wrap_front & note_text & anchored_body_wrap_back)
			set page_front to (anchored_page_wrap_front & hyperlink & anchored_page_abbr)
			set page_back to (real_page & anchored_page_wrap_back)
			
			return anchor & space & body & space & page_front & space & page_back & line_feed & line_feed
			
		else if _type = underline note then
			--{prefix}{wrap}<note text>{/wrap} {wrap}<link>{p.} <#>{/wrap}
			set body to (underline_prefix & underline_body_wrap_front & note_text & underline_body_wrap_back)
			set page_front to (underline_page_wrap_front & hyperlink & underline_page_abbr)
			set page_back to (real_page & underline_page_wrap_back)
			
			return body & space & page_front & space & page_back & line_feed & line_feed
			
		else if _type = strike out note then
			--{prefix}{wrap}<note text>{/wrap} {wrap}<link>{p.} <#>{/wrap}
			set body to (strike_prefix & strike_body_wrap_front & note_text & strike_body_wrap_back)
			set page_front to (strike_page_wrap_front & hyperlink & strike_page_abbr)
			set page_back to (real_page & strike_page_wrap_back)
			
			return body & space & page_front & space & page_back & line_feed & line_feed
			
		else if _type = highlight note then
			--{prefix}{wrap}<title>{/wrap} {wrap}<note text>{/wrap} {wrap}<link>{p.} <#>{/wrap}
			set header to (highlight_prefix & highlight_title_wrap_front & _title & highlight_title_wrap_back)
			set body to (highlight_body_wrap_front & note_text & highlight_body_wrap_back)
			set page_front to (highlight_page_wrap_front & hyperlink & highlight_page_abbr)
			set page_back to (real_page & highlight_page_wrap_back)
			
			return header & space & body & space & page_front & space & page_back & line_feed & line_feed
		end if
	end tell
end get_annotation_hyperlink

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