@tool
extends DLoggerBase

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

	# If the file does not exist, create it in WRITE mode and start the session
	if not FileAccess.file_exists(_file_path):
		_file = FileAccess.open(_file_path, FileAccess.WRITE)
		if _file:
			var init_msg := "--- Log Created: {0} ---"
			_file.store_line(init_msg.format([Time.get_datetime_string_from_system()]))
			# Do not close it here, let it flow directly to the session process
	else:
		# If it exists, open it in READ_WRITE mode and seek to the end
		_file = FileAccess.open(_file_path, FileAccess.READ_WRITE)
		if _file:
			_file.seek_end()

	# Common process if the file is successfully opened
	if _file:
		var session_msg := "=== New Session Started: {0} ==="
		_write_line(session_msg.format([Time.get_datetime_string_from_system()]))
		# Ensure the data is written to the disk
		_file.flush()
	else:
		# Safety fallback if the file could not be opened
		var error_msg := "DLoggerFile: Failed to open file for appending: {0}"
		push_error(error_msg.format([_file_path]))


# ------------- [Private Method] -------------
func _write_line(line: String) -> void:
	if _file:
		_file.store_line(line)


# ------------- [Output] -------------
func _output(
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant,
	level: String
) -> void:
	_write_line(DLoggerFunc.format_log(msg, category, level, context, prefix, p_caller_info))

	# Flush immediately for warnings and errors
	if level == "WARN" or level == "ERROR":
		if _file:
			_file.flush()
