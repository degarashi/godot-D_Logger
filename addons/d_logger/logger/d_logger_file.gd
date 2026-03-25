@tool
extends RefCounted

# ------------- [Constants] -------------
const _C := preload("uid://cwfe01280qmo7")

# ------------- [Private Variable] -------------
var _file_path: String


# ------------- [Callbacks] -------------
func _init(path: String) -> void:
	_file_path = path
	# Instead of WRITE, just create if it doesn't exist
	if not FileAccess.file_exists(_file_path):
		var f := FileAccess.open(_file_path, FileAccess.WRITE)
		if f:
			f.store_line("--- Log Created: %s ---" % Time.get_datetime_string_from_system())

	# Append the session separator line on startup using READ_WRITE
	_write_line("=== New Session Started: %s ===" % Time.get_datetime_string_from_system())


# ------------- [Private Method] -------------
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


# ------------- [Public Method] -------------
func is_debug_enabled() -> bool:
	return true


func is_info_enabled() -> bool:
	return true


func is_warn_enabled() -> bool:
	return true


func is_error_enabled() -> bool:
	return true


func debug(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	_write_line(_C.format_log(msg, category, "DEBUG", context, prefix))
	return true


func info(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	_write_line(_C.format_log(msg, category, "INFO", context, prefix))
	return true


func warn(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	_write_line(_C.format_log(msg, category, "WARN", context, prefix))
	return true


func error(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	_write_line(_C.format_log(msg, category, "ERROR", context, prefix))
	return true
