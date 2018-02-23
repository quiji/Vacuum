extends CanvasLayer


func _ready():
	
#Given a version number MAJOR.MINOR.PATCH, increment the:
#MAJOR version when you make incompatible API changes,
#MINOR version when you add functionality in a backwards-compatible manner, and
#PATCH version when you make backwards-compatible bug fixes.
#Additional labels for pre-release and build metadata are available as extensions to the MAJOR.MINOR.PATCH format.

	var major = 0
	var minor = 0
	var patch = 0
	
	if ProjectSettings.has_setting("Project/major"):
		major = ProjectSettings.get_setting("Project/major")

	if ProjectSettings.has_setting("Project/minor"):
		minor = ProjectSettings.get_setting("Project/minor")


	if ProjectSettings.has_setting("Project/patch"):
		patch = ProjectSettings.get_setting("Project/patch")

	get_node("version").set_text(str(major) + "." + str(minor) + "." + str(patch))

