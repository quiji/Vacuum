static func str_to_json(dict, spaces = 0):
	return beautify_json(to_json(dist), spaces)

static func beautify_json(json, spaces = 0):
	""" JSON beautifier. Takes valid JSON (if invalid, it will return a error
	according with Godot's 'validade_json' method) and a number of spaces for
	indentation (Default is '0', in which it will use tabs instead) """
	
	var error_message = validate_json(json)
	if not error_message.empty():
		return error_message
	
	# Remove pre-existing formating
	json = json.replace(" ", "")
	json = json.replace("\n", "")
	json = json.replace("\t", "")
	
	json = json.replace("{", "{\n")
	json = json.replace("}", "\n}")
	json = json.replace("{\n\n}", "{}") # Fix newlines in empty brackets
	json = json.replace("[", "[\n")
	json = json.replace("]", "\n]")
	json = json.replace("[\n\n]", "[]") # Same as above
	json = json.replace(":", ": ")
	json = json.replace(",", ",\n")
	
	var indentation = ""
	if spaces > 0:
		for i in spaces:
			indentation += " "
	else:
		indentation = "\t"
	
	var begin
	var end
	var bracket_count
	for i in [["{", "}"], ["[", "]"]]:
		begin = json.find(i[0])
		while begin != -1:
			end = json.find("\n", begin)
			bracket_count = 0
			while end != - 1:
				if json[end - 1] == i[0]:
					bracket_count += 1
				elif json[end + 1] == i[1]:
					bracket_count -= 1
				
				# Move through the indentation to see if there is a match
				while json[end + 1] == indentation:
					end += 1
					
					if json[end + 1] == i[1]:
						bracket_count -= 1
				
				if bracket_count <= 0:
					break
				
				end = json.find("\n", end + 1)
			
			# Skip one newline so the end bracket doesn't get indented
			end = json.rfind("\n", json.rfind("\n", end) - 1)
			while end > begin:
				json = json.insert(end + 1, indentation)
				end = json.rfind("\n", end - 1)
			
			begin = json.find(i[0], begin + 1)
	
	return json
