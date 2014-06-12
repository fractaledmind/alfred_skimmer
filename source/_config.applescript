on run
	--get path to workflow root folder
	set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ":"}
	set base_path to (((text items 1 thru -2 of ((path to me) as string)) as string) & ":") as string
	set AppleScript's text item delimiters to tid
	
	--load UI and Workflow helper scripts
	set ui to load script ((base_path & "_ui-helpers.scpt") as alias)
	set wf to load script ((base_path & "_wf-helpers.scpt") as alias)
	
	-- Ensure storage and cache folders are created
	wf's init_paths()
	
	set _icon to base_path & "icon.png"
	
	set _bundle to wf's get_bundle()
	set settings_path to (path to "cusr" as text) & "Library:Application Support:Alfred 2:Workflow Data:" & _bundle & ":settings.json" as text
	
	try
		--- try to open the file and read it
		set the file_ to open for access file settings_path
		set json_ to (read file_)
		close access file_
		
		set rec to wf's read_json(json_, {"style", "destination"})
		set export_style to rec's _style
		set export_destination to rec's _destination
	on error
		set export_style to "Markdown"
		set export_destination to "Clipboard"
	end try
	
	-- Get user preferences
	set style_dialog to (ui's display_dialog({z_text:"Export notes as Markdown or HTML?", z_buttons:{"Markdown", "HTML", "Cancel"}, z_ok:export_style, z_cancel:"Cancel", z_title:"Skimmer", z_icon:_icon}))
	try
		set export_style to button returned of style_dialog
	on error msg
		return msg
	end try
	
	set dest_dialog to (ui's display_dialog({z_text:"Send exported notes to Evernote or copy to Clipboard?", z_buttons:{"Evernote", "Clipboard", "Cancel"}, z_ok:export_destination, z_cancel:"Cancel", z_title:"Skimmer", z_icon:_icon}))
	try
		set export_destination to button returned of dest_dialog
	on error msg
		return msg
	end try
	
	-- Prepare JSON
	set json to "{" & return & tab & "\"style\": \"" & export_style & "\"," & return & tab & "\"destination\": \"" & export_destination & "\"" & return & "}"
	
	try
		-- Write the data to the settings file
		set the file_ to open for access file settings_path with write permission
		set eof of file_ to 0
		write json to file_
		close access the file_
		return "Configuration Success!"
	on error msg
		return "Failed... " & msg
	end try
end run