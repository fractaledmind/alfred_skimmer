on run
	--load Workflow helper scripts
	set wf to load script ((get_path() & "_wf-helpers.scpt") as alias)
	
	-- Ensure storage and cache folders are created
	wf's init_paths()
	
	set annotations_path to wf's get_storage() & "annotations_config.json"
	
	--Prepare dictionaries for each possible highlight color
	set one to {}
	set two to {}
	set three to {}
	set four to {}
	set five to {}
	set six to {}
	
	tell application "Skim"
		set all_notes to every note of page 2 of front document
		
		repeat with i from 1 to count of all_notes
			set _note to item i of all_notes
			
			if type of _note is text note then
				set note_text to text of _note
				set note_title to (text items 4 thru -1 of note_text) as string
				
				--Save each highlight title 
				if (text of _note) contains "1." then
					set end of one to "_title:" & "\"" & note_title & "\""
				else if (text of _note) contains "2." then
					set end of two to "_title:" & "\"" & note_title & "\""
				else if (text of _note) contains "3." then
					set end of three to "_title:" & "\"" & note_title & "\""
				else if (text of _note) contains "4." then
					set end of four to "_title:" & "\"" & note_title & "\""
				else if (text of _note) contains "5." then
					set end of five to "_title:" & "\"" & note_title & "\""
				else if (text of _note) contains "6." then
					set end of six to "_title:" & "\"" & note_title & "\""
				end if
				
			else if type of _note is highlight note then
				set rgba to color of _note
				set colour to wf's as_string(rgba)
				
				--Save each highlight color 
				if (text of _note) contains "One" then
					set end of one to "_color:" & colour
				else if (text of _note) contains "Two" then
					set end of two to "_color:" & colour
				else if (text of _note) contains "Three" then
					set end of three to "_color:" & colour
				else if (text of _note) contains "Four" then
					set end of four to "_color:" & colour
				else if (text of _note) contains "Five" then
					set end of five to "_color:" & colour
				else if (text of _note) contains "Six" then
					set end of six to "_color:" & colour
				end if
				
			end if
		end repeat
	end tell
	
	set one to "{" & my implode(", ", one) & "}"
	set two to "{" & my implode(", ", two) & "}"
	set three to "{" & my implode(", ", three) & "}"
	set four to "{" & my implode(", ", four) & "}"
	set five to "{" & my implode(", ", five) & "}"
	set six to "{" & my implode(", ", six) & "}"
	
	set {one_rec, two_rec, three_rec, four_rec, five_rec, six_rec} to {(run script one), (run script two), (run script three), (run script four), (run script five), (run script six)}
	--Group dicts into one list
	set json_list to {one_rec, two_rec, three_rec, four_rec, five_rec, six_rec}
	
	--Create JSON string
	set json to wf's make_json(json_list)
	
	--Write JSON to file
	set annotations_file to (POSIX file annotations_path) as string
	write_to_file(json, annotations_file, false)
	return "true"
end run

(* HANDLERS *)

on write_to_file(this_data, target_file, append_data)
	try
		set the target_file to the target_file as string
		set the open_target_file to open for access file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
		write this_data to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error msg
		try
			close access file target_file
		end try
		return msg
	end try
end write_to_file

on get_path()
	set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
	set base_path to (((text items 1 thru -2 of ((path to me) as string)) as string) & ":") as string
	set AppleScript's text item delimiters to tid
	return base_path
end get_path

on implode(delimiter, pieces)
	local delimiter, pieces, ASTID
	set ASTID to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to delimiter
		set pieces to "" & pieces
		set AppleScript's text item delimiters to ASTID
		return pieces --> text
	on error eMsg number eNum
		set AppleScript's text item delimiters to ASTID
		error "Can't implode: " & eMsg number eNum
	end try
end implode