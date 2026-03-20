@tool

const _C = preload("uid://cwfe01280qmo7")
var _file_path: String


# DLoggerFile.gd's _init
func _init(path: String) -> void:
	_file_path = path
	# Instead of WRITE, just create if it doesn't exist
	if not FileAccess.file_exists(_file_path):
		var f := FileAccess.open(_file_path, FileAccess.WRITE)
		if f:
			f.store_line("--- Log Created: %s ---" % Time.get_datetime_string_from_system())

	# Append the session separator line on startup using READ_WRITE
	_write_line("=== New Session Started: %s ===" % Time.get_datetime_string_from_system())


func _write_line(line: String) -> void:
	# Open with READ_WRITE, seek to end and write
	# If this fails, first check if this mode is supported
	var f := FileAccess.open(_file_path, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(line)
		f.flush()
	else:
		# As a fallback if READ_WRITE fails (e.g., permissions)
		# If opening and writing each time is too heavy, consider a design that holds FileAccess
		push_error("DLoggerFile: Failed to open file for appending: " + _file_path)


# ------------- [Log Methods Overrides] -------------
func debug(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	_write_line(_C.format_log(msg, category, "DEBUG", context, prefix))


func info(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	_write_line(_C.format_log(msg, category, "INFO", context, prefix))


func warn(msg: Variant, category: String = "", context: Object = null, prefix: String = "") -> void:
	_write_line(_C.format_log(msg, category, "WARN", context, prefix))


func error(
	msg: Variant, category: String = "", context: Object = null, prefix: String = ""
) -> void:
	_write_line(_C.format_log(msg, category, "ERROR", context, prefix))
