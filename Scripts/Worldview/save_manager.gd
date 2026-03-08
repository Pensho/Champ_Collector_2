class_name SaveManager extends Node



static func Save(p_slot: int, p_data: Dictionary) -> void:
	var save_file: FileAccess = FileAccess.open("user://profile_" + str(p_slot) + ".save", FileAccess.WRITE)
	
	var json_string: String = JSON.stringify(p_data)
	save_file.store_line(json_string)

static func Load(p_slot: int) -> void:
	if (not FileAccess.file_exists("user://profile_" + str(p_slot) + ".save")):
		print("There is no saved data for: ", "user://profile_" + str(p_slot) + ".save")
		return
	
	# Clear out all data that is loaded into the game already.
	
	var save_file: FileAccess = FileAccess.open("user://profile_" + str(p_slot) + ".save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string: String = save_file.get_line()
		var json = JSON.new()
		
		var parse_result: Error = json.parse(json_string)
		if (not parse_result == OK):
			print("JSON parse Error: ", json.get_error_message(), " in ", json_string, " at line: ", json.get_error_line())
			continue
		
		var data = json.data
		print (data)

static func DeleteSave(p_slot: int) -> void:
	pass
