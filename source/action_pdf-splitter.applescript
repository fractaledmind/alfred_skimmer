(* SKIM PAGE SPLITTER
 
-- Stephen Margheim
-- open source
 
VERSION 6.0
 
This little program uses the Mac app Skim to crop and split PDFs that have two pages layed out on a single PDF page in landscape mode:
 
 ----------
|	|	|
|	|	|
 ----------
 
USAGE NOTES:
	* Ensure the PDF is in Landscape View.
	
*)

(* ///
PRELIMINARIES
/// *)

--get path to workflow root folder
set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
set base_path to (((text items 1 thru -2 of ((path to me) as string)) as string) & ":") as string
set AppleScript's text item delimiters to tid

--load UI and Workflow helper scripts
set ui to load script ((base_path & "_ui-helpers.scpt") as alias)
set wf to load script ((base_path & "_wf-helpers.scpt") as alias)

--ensure cache and storage directory exist
wf's init_paths()
set wf_cache to wf's get_cache()
set wf_cache to ((POSIX file wf_cache) as alias) as string
set temp_folder to wf_cache & "temp:"


tell application "Skim"
	
	(* ///
	PART ONE: Get Preliminary Data
	/// *)
	
	--save id of current document to var
	set _doc to front document
	
	--get path to doc's folder
	set full_path to ((file of _doc) as string)
	set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
	set save_path to (((text items 1 thru -2 of (full_path as string)) as string) & ":") as string
	set AppleScript's text item delimiters to tid
	
	--get doc's title (with file type extension)
	set _title to (name of _doc) as string
	if _title does not contain ".pdf" then
		set title_ext to _title & ".pdf"
		set title_clean to _title
	else
		if (text items -4 thru -1 of _title as string) = ".pdf" then set title_clean to text items 1 thru -5 of _title as string
		set title_ext to _title
	end if
	
	--get list of notes and pages
	set _page to (index of current page of _doc)
	set {_notes, _note_types, _pages} to {every note of page _page of _doc, type of every note of page _page of _doc, index of every page of _doc}
	
	--get length of digits of final count of split pages
	set pad to length of (((count _pages) * 2) as string)
	
	--save original version of pdf
	set org_title to "original_" & title_ext
	save _doc as "PDF" in (save_path & org_title)
	
	(* ///
	PART TWO: Determine how best to crop the PDF (if necessary)
	/// *)
	
	if _note_types contains line note then
		
		-- get bounds of every line note on current page
		set _borders to {}
		repeat with i from 1 to count of _notes
			set n to item i of _notes
			if type of n = line note then copy (bounds of n) to end of _borders
		end repeat
		
		if (count _borders) = 0 then
			--do nothing, move on
			
		else if (count _borders) = 1 then
			--if only one line note on current page
			set nleft to (item 1 of item 1 of _borders) as integer
			
			--get bounds of current page with lines for cropping
			set {xleft, ytop, xright, ybottom} to get bounds for page _page of _doc
			set mid to my _abs(((xright - xleft) / 2) as integer)
			
			--prepare distance between crop-line and margins
			set left_dif to my _abs((nleft - xleft))
			set right_dif to my _abs((nleft - xright))
			set mid_dif to my _abs((nleft - mid))
			
			if left_dif < right_dif and left_dif < mid_dif then
				-- if line = desired left margin
				repeat with i from 1 to (count _pages)
					set bounds of page i of _doc to {nleft, ytop, xright, ybottom}
				end repeat
				
			else if right_dif < left_dif and right_dif < mid_dif then
				-- if line = desired right margin
				repeat with i from 1 to (count _pages)
					set bounds of page i of _doc to {xleft, ytop, nleft, ybottom}
				end repeat
				(*	
				BUGGY, NOT USEFUL
			else if mid_dif < right_dif and mid_dif < left_dif then
				-- if line = desired mid point
				set page_width to (xright - xleft)
				set _left to (nleft - page_width)
				
				repeat with i from 1 to (count _pages)
					set bounds of page i of _doc to {_left, ytop, xright, ybottom}
				end repeat
			*)
			end if
			
		else if (count _borders) = 2 then
			-- if two line notes on current page
			
			--get bounds of current page with lines for cropping
			set {xleft, ytop, xright, ybottom} to get bounds for page _page of _doc
			
			--get left and right margins for cropping
			set left_margins to my _sortlist({item 1 of item 1 of _borders, item 1 of item 2 of _borders})
			set left_margin to item 1 of left_margins
			set right_margins to my _sortlist({item 3 of item 1 of _borders, item 3 of item 2 of _borders})
			set right_margin to item 2 of right_margins
			
			--crop pages
			repeat with i from 1 to (count _pages)
				set bounds of page i of _doc to {left_margin, ytop, right_margin, ybottom}
			end repeat
		else if (count _borders) > 2 then
			-- if 3 or more line notes on current page
			beep
			set _icon to (base_path & "icon.png") as string
			ui's display_dialog({z_text:"You can only have at most 2 line notes on the current page.", z_title:"Skim Splitter", z_icon:_icon, z_wait:5})
		end if
	end if
	
	(* ///
	PART THREE: Split test to determine orientation of PDF
	 /// *)
	
	--get the rectangular bounds for the full, double page PDF
	set {xleft, ytop, xright, ybottom} to get bounds for page 1 of front document
	
	--crop a trial page to determine PDF rotation
	set new_pos to (ybottom + ((ytop - ybottom) / (2 as integer)))
	
	--save page section to temporary file
	set _data to grab page 1 of front document for {xleft, new_pos, xright, ybottom}
	set _target to wf_cache & title_clean & "_temp.pdf"
	set _write to my write_to_file(_data, _target, false)
	
	if _write = true then
		tell application "Skim"
			activate
			open alias (_target)
		end tell
	end if
	
	--determine pdf orientation from page section
	set _section to ui's choose_from_list({z_list:{"Bottom-Half", "Top-Half", "Left-Hand", "Right-Hand"}, z_title:"Skimmer", z_prompt:"What part of the page is this?", z_def:{"Bottom-Half"}, z_multiple:false, z_empty:false})
	
	if not _section = false then
		set _section to _section as string
		close front document without saving
		
		(* ///
		PART FOUR: Split and Save all Left-Hand Pages
		 /// *)
		
		repeat with i from 1 to (count _pages)
			--get the rectangular bounds for the full, double page pdf
			set bounds_dict to get bounds for page i of _doc
			
			--get bounds of left-hand page
			set crop_dict to my split_page(bounds_dict, _section, "left")
			set _data to grab page i of _doc for crop_dict
			
			--ensure only odd numbers in titles for left-hand pages
			if i = 1 then
				set n to my zero_pad(i, pad)
			else
				set n to (i + (item (i - 1) of _pages))
				set n to my zero_pad(n, pad)
			end if
			
			--save left-hand page to temporary file
			set _target to temp_folder & n & "_left" & ".pdf"
			set _write_ to my write_to_file(_data, _target, false)
			if _write_ = false then return "Error! Split left-hand page not written to file"
		end repeat
		
		(* ///
		PART FIVE: Split and Save all Right-Hand Pages
		 /// *)
		
		repeat with i from 1 to (count _pages)
			-- get the rectangular bounds for the full, double page pdf
			set bounds_dict to get bounds for page i of _doc
			
			--get bounds of right-hand page
			set crop_dict to my split_page(bounds_dict, _section, "right")
			set _data to grab page i of _doc for crop_dict
			
			--ensure only even numbers in titles for right-hand pages
			set n to (i * 2)
			set n to my zero_pad(n, pad)
			
			--save right-hand page to temporary file
			set _target to temp_folder & n & "_right" & ".pdf"
			set _write_ to my write_to_file(_data, _target, false)
			if _write_ = false then return "Error! Split right-hand page not written to file"
		end repeat
		
		--combine all temporary page files into single pdf
		my combinePDFPages(title_clean, wf_cache, temp_folder, save_path)
		
		(* ///
		PART SIX: Save and then close old PDF
		 /// *)
		
		save _doc
		close _doc
		(*
		tell application "Finder"
			delete ((full_path) as alias)
		end tell
		*)
	end if
end tell


(* HANDLERS *)

on combinePDFPages(_title, cache_path, temp_path, orig_path)
	--convert AS paths to POSIX paths
	set orig_posix to (POSIX path of (orig_path as alias)) as string
	set temp_posix to (POSIX path of (temp_path as alias)) as string
	
	--prepare final PDF file path
	set _file to orig_posix & _title & "_split.pdf"
	
	--combine ALL individual PDF pages into new, single PDF
	do shell script "\"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py\" -o " & (quoted form of POSIX path of _file) & space & (quoted form of temp_posix) & "*.pdf"
	
	--delete the individual page PDFs
	tell application "Finder" to delete (every item of (cache_path as alias))
	
	--open new PDF
	set _file_ to ((POSIX file _file) as alias)
	tell application "Skim"
		open _file_
		go front document to page 1 of front document
	end tell
end combinePDFPages

on split_page(_dict, _section, _page)
	set {xleft, ytop, xright, ybottom} to _dict
	
	set new_y to (ybottom + ((ytop - ybottom) / 2)) as integer
	set new_x to (xleft + ((xright - xleft) / 2)) as integer
	
	if _page = "left" then
		--GET LEFT-HAND PAGE
		if _section = "Right-Hand" then
			return {xleft, ytop, xright, new_y}
		else if _section = "Left-Hand" then
			return {xleft, new_y, xright, ybottom}
		else if _section = "Bottom-Half" then
			return {xleft, ytop, new_x, ybottom}
		else if _section = "Top-Half" then
			return {new_x, ytop, xright, ybottom}
		end if
	else if _page = "right" then
		--GET RIGHT-HAND PAGE
		if _section = "Right-Hand" then
			return {xleft, new_y, xright, ybottom}
		else if _section = "Left-Hand" then
			return {xleft, ytop, xright, new_y}
		else if _section = "Bottom-Half" then
			return {new_x, ytop, xright, ybottom}
		else if _section = "Top-Half" then
			return {xleft, ytop, new_x, ybottom}
		end if
	end if
end split_page

on write_to_file(this_data, target_file, append_data)
	try
		set the target_file to the target_file as string
		set the open_target_file to open for access file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
		write this_data to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error
		try
			close access file target_file
		end try
		return false
	end try
end write_to_file

on _abs(n)
	if n < 0 then set n to -n
	return n
end _abs

on get_text_bounds(l)
	set {_left, _top, _right, _bottom} to {(item 1 of item 1 of l), (item 2 of item 1 of l), (item 3 of item 1 of l), (item 4 of item 1 of l)}
	repeat with i from 1 to count of l
		set x to item i of l
		--Get lowest left-margin
		set n_left to item 1 of x
		if n_left < _left then set _left to n_left
		--Get highest top-margin
		set n_top to item 2 of x
		if n_top > _top then set _top to n_top
		--Get hightest right-margin
		set n_right to item 3 of x
		if n_right > _right then set _right to n_right
		--Get lowest bottom-margin
		set n_bottom to item 4 of x
		if n_bottom < _bottom then set _bottom to n_bottom
	end repeat
	return {_left, _top, _right, _bottom}
end get_text_bounds


(* SUB-ROUTINES *)

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

on zero_pad(value, string_length)
	set string_zeroes to ""
	set digits_to_pad to string_length - (length of (value as string))
	if digits_to_pad > 0 then
		repeat digits_to_pad times
			set string_zeroes to string_zeroes & "0" as string
		end repeat
	end if
	set padded_value to string_zeroes & value as string
	return padded_value
end zero_pad