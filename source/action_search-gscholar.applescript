--get path to workflow root folder
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
set base_path to (((text items 1 thru -2 of ((path to me) as string)) as string) & ":") as string
set AppleScript's text item delimiters to tid

--load UI and Workflow helper scripts
set ui to load script ((base_path & "_ui-helpers.scpt") as alias)

tell application "Skim"
	set _path to path of front document
	set _page to index of current page of front document
	
	set python_path to (POSIX path of base_path) & "dep_extract-data.py"
	set pdf2text_path to (POSIX path of base_path) & "dep_pdftotext"
	
	set input to _path & "zzz" & (_page as string) & "zzz" & pdf2text_path
	
	set python_path to quoted form of python_path
	set command to "python " & python_path & " " & quoted form of input
	set command to command as «class utf8»
	set _res to do shell script command
	
	if not _res = "[]" then
		if _res contains "[" and _res contains "]" then
			set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {"[", "]", "'", ","}}
			set l to text items of _res
			set AppleScript's text item delimiters to tid
			set final to {}
			repeat with i from 1 to count of l
				if not item i of l = "" then
					if not item i of l = " " then
						copy item i of l to end of final
					end if
				end if
			end repeat
			set query_list to ui's choose_from_list({z_list:final, z_title:"Skim Splitter", z_prompt:"Choose keywords to search", z_def:1, z_multiple:true})
			set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, " "}
			set _res to query_list as string
			set AppleScript's text item delimiters to tid
		end if
		
		--encode query
		set query to my encode_text(_res, true, true)
		
		set base_url to "http://scholar.google.com/scholar?hl=en&q=" & query
		tell application id "sevs" to open location base_url
		
	else
		set _icon to base_path & "icon.png"
		ui's display_dialog({z_text:"PDF isn't OCR'd. So Skimer cannot extract data.", z_title:"Skim Splitter", z_icon:_icon})
	end if
end tell

(* HANDLERS *)

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