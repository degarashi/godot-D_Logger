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
	else:
		# If it exists, open it in READ_WRITE mode and seek to the end
		_file = FileAccess.open(_file_path, FileAccess.READ_WRITE)
		if _file:
			_file.seek_end()

	# Common process if the file is successfully opened
	if _file:
		var session_msg := "=== New Session Started: {0} ==="
		_write_line(
			session_msg.format([Time.get_datetime_string_from_system()])
		)
		# Ensure the data is written to the disk
		_file.flush()
	else:
		# Safety fallback if the file could not be opened
		var error_msg := "DLoggerFile: Failed to open file for appending: {0}"
		push_error(error_msg.format([_file_path]))


# ------------- [Private Method] -------------
func _write_line(line: String) -> void:
	if _file:
		if _file.get_length() > DLoggerConstants.MAX_LOG_FILE_SIZE:
			_rotate_log_file()
		if _file:
			_file.store_line(line)


## Rotates the current log file to <path><LOG_FILE_BACKUP_SUFFIX> and starts
## a fresh file. Keeps at most one backup generation, so disk usage is
## bounded to roughly 2x MAX_LOG_FILE_SIZE.
func _rotate_log_file() -> void:
	if _file == null:
		return
	_file.flush()
	_file.close()
	_file = null

	var backup_path := (
		_file_path + DLoggerConstants.LOG_FILE_BACKUP_SUFFIX
	)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if DirAccess.rename_absolute(_file_path, backup_path) != OK:
		# Keep appending to the current file if rotation fails; the size
		# check will retry on the next write.
		push_error(
			"DLoggerFile: Failed to rotate log file to %s" % backup_path
		)
		_file = FileAccess.open(_file_path, FileAccess.READ_WRITE)
		if _file:
			_file.seek_end()
		else:
			push_error(
				"DLoggerFile: Failed to reopen log file: %s" % _file_path
			)
		return

	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	if _file:
		var rotation_msg := "=== Log Rotated: {0} ==="
		_write_line(
			rotation_msg.format([Time.get_datetime_string_from_system()])
		)
		_file.flush()
	else:
		push_error(
			"DLoggerFile: Failed to reopen log file after rotation: %s"
			% _file_path
		)


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
	_write_line(
		DLoggerFunc.format_log(
			msg, category, level, context, prefix, p_caller_info
		)
	)

	# Flush immediately for warnings and errors
	if level == "WARN" or level == "ERROR":
		if _file:
			_file.flush()
