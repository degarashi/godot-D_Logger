@tool
extends DLoggerBase

# ------------- [Private Variable] -------------
var _file_path: String


# ------------- [Callbacks] -------------
func _init(path: String) -> void:
	assert(DLoggerFunc.is_logger(self))
	_file_path = path

	# Check directory existence (automatically created if it does not exist)
	var dir_path := _file_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Write the session start marker (opens/closes the file itself)
	var session_msg := "=== New Session Started: {0} ==="
	_write_line(session_msg.format([Time.get_datetime_string_from_system()]))


# ------------- [Private Method] -------------
## Opens the log file for appending. The file is created if it does not
## exist yet, and the cursor is positioned at the end. Returns null on
## failure. Opening and closing the file on every write keeps multiple
## DLoggerFile instances on the same path safe: no stale handle position
## can overwrite another instance's data. Closing also flushes, so every
## line reaches disk immediately (stronger than the previous
## flush-on-WARN/ERROR behavior).
func _open_for_append() -> FileAccess:
	var file: FileAccess
	if not FileAccess.file_exists(_file_path):
		file = FileAccess.open(_file_path, FileAccess.WRITE)
	else:
		file = FileAccess.open(_file_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	if file == null:
		var error_msg := "DLoggerFile: Failed to open file for appending: {0}"
		push_error(error_msg.format([_file_path]))
	return file


func _write_line(line: String) -> void:
	var file := _open_for_append()
	if file == null:
		return

	if file.get_length() > DLoggerConstants.MAX_LOG_FILE_SIZE:
		file.close()
		_rotate_log_file()
		file = _open_for_append()
		if file == null:
			return

	file.store_line(line)
	file.close()


## Rotates the current log file to <path><LOG_FILE_BACKUP_SUFFIX> and starts
## a fresh file. Keeps at most one backup generation, so disk usage is
## bounded to roughly 2x MAX_LOG_FILE_SIZE.
func _rotate_log_file() -> void:
	var backup_path := _file_path + DLoggerConstants.LOG_FILE_BACKUP_SUFFIX
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if DirAccess.rename_absolute(_file_path, backup_path) != OK:
		# Keep appending to the current file if rotation fails; the size
		# check will retry on the next write.
		push_error("DLoggerFile: Failed to rotate log file to %s" % backup_path)
		return

	# Start a fresh log file and write the rotation marker
	var file := FileAccess.open(_file_path, FileAccess.WRITE)
	if file:
		var rotation_msg := "=== Log Rotated: {0} ==="
		file.store_line(rotation_msg.format([Time.get_datetime_string_from_system()]))
		file.close()
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
	# Every write opens and closes the file, which flushes to disk
	_write_line(
		DLoggerFunc.format_log(
			msg, category, level, context, prefix, p_caller_info
		)
	)
