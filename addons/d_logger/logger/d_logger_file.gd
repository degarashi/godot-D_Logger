@tool
extends RefCounted

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")

# ------------- [Private Variable] -------------
var _file_path: String
var _file: FileAccess


# ------------- [Callbacks] -------------
func _init(path: String) -> void:
	assert(DLoggerFunc.is_logger(self))
	_file_path = path

	# Check directory existence (automatically created if it does not exist)
	var dir_path := _file_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Keep the file open in append mode (READ_WRITE)
	# If the file does not exist, create it with WRITE and close it immediately
	if not FileAccess.file_exists(_file_path):
		var f := FileAccess.open(_file_path, FileAccess.WRITE)
		if f:
			var init_msg := "--- Log Created: {0} ---"
			f.store_line(init_msg.format([Time.get_datetime_string_from_system()]))
			f.close()

	# Open again and seek to end
	_file = FileAccess.open(_file_path, FileAccess.READ_WRITE)

	if _file:
		_file.seek_end()
		# Write session separator line
		var session_msg := "=== New Session Started: {0} ==="
		_write_line(session_msg.format([Time.get_datetime_string_from_system()]))
	else:
		# Safety fallback if the file could not be opened
		var error_msg := "DLoggerFile: Failed to open file for appending: {0}"
		push_error(error_msg.format([_file_path]))


# ------------- [Private Method] -------------
func _write_line(line: String) -> void:
	if _file:
		_file.store_line(line)


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
