@tool
extends DLoggerBase

# ------------- [Private Variable] -------------
# How often (in writes) to verify the file still exists on disk.
# External deletion is abnormal, so the per-write stat is amortized:
# most writes skip file_exists, recovery lags by at most INTERVAL lines.
const _EXIST_CHECK_INTERVAL := 30
var _file_path: String
# Persistent append handle. Reused across writes so a log flood pays
# seek + store + flush per line instead of an open/close handshake per
# line. Repositioned with seek_end() before every write (see _write_line).
var _handle: FileAccess = null
# Latched to true after the first failed open. Without this, a
# misconfigured path (e.g. a res:// file in an exported PCK where
# DirAccess.make_dir_recursive_absolute silently no-ops) would emit
# one push_error per attempted log line — flooding the editor
# Output at the exact moment the user is trying to capture errors.
var _init_failed: bool = false
# Latched to true after the first failed rotation. Without this, a
# permanently unrenamable file would emit one push_error per write
# once over the size limit — the same flood pattern as _init_failed.
# Cleared on the next successful rotation so a transient failure
# warns once per failure episode rather than once per session.
var _rotate_failed: bool = false
var _writes_since_exist_check: int = 0


# ------------- [Callbacks] -------------
func _init(path: String) -> void:
	assert(DLoggerFunc.is_logger(self))
	_file_path = path

	# Check directory existence (automatically created if it does not exist)
	var dir_path := _file_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	_open_handle()

	# Write the session start marker
	var session_msg := "=== New Session Started: {0} ==="
	_write_line(session_msg.format([Time.get_datetime_string_from_system()]))


# ------------- [Private Method] -------------
## Opens (or reopens) the persistent append handle. The file is created
## when missing, otherwise the cursor is positioned at the end. Returns
## false on failure, warning only once per session via _init_failed.
func _open_handle() -> bool:
	_close_handle()
	if not FileAccess.file_exists(_file_path):
		_handle = FileAccess.open(_file_path, FileAccess.WRITE)
	else:
		_handle = FileAccess.open(_file_path, FileAccess.READ_WRITE)
		if _handle:
			_handle.seek_end()
	if _handle == null:
		# Only push once. The latch avoids per-line push_error spam
		# when the path is permanently bad (e.g. a res:// target in
		# an exported PCK, where the parent dir cannot be created).
		if not _init_failed:
			var error_msg := "DLoggerFile: Failed to open file for appending: {0}"
			push_error(error_msg.format([_file_path]))
			_init_failed = true
		return false
	_writes_since_exist_check = 0
	return true


## Closes the persistent handle without dropping it on failure paths:
## callers reopen right away so later writes are not silently lost.
func _close_handle() -> void:
	if _handle:
		_handle.close()
		_handle = null


func _write_line(line: String) -> void:
	# Reopen when the handle is missing (first open failed or a rotation
	# closed it): transient failures recover on the next write, while the
	# latch in _open_handle keeps the warning to once per session.
	if _handle == null and not _open_handle():
		return

	# Amortized existence check: a persistent handle keeps writing to
	# an unlinked inode after external deletion, but stat per line
	# costs a syscall on the hot path. Checking every INTERVAL writes
	# bounds overhead to 1/INTERVAL while delaying recovery by at most
	# INTERVAL lines (acceptable for an abnormal case).
	_writes_since_exist_check += 1
	if _writes_since_exist_check >= _EXIST_CHECK_INTERVAL:
		_writes_since_exist_check = 0
		if not FileAccess.file_exists(_file_path):
			if not _open_handle():
				return

	if _handle.get_length() > DLoggerConstants.MAX_LOG_FILE_SIZE:
		_rotate_log_file()
		if _handle == null:
			return

	# Re-seek on every write: sibling DLoggerFile instances on the same
	# path append concurrently, so a cached end position would overwrite
	# their data.
	_handle.seek_end()
	_handle.store_line(line)
	# Flush per line: same process-crash durability as the previous
	# open/close-per-write (OS buffers survive a process crash) without
	# the open/close handshake. Throttle floods with the minimum-level
	# setting instead.
	_handle.flush()
	# Reopen on I/O failure so a transient error recovers on next write.
	if _handle.get_error() != OK:
		_open_handle()


## Rotates the current log file to <path><LOG_FILE_BACKUP_SUFFIX> and starts
## a fresh file. Keeps at most one backup generation, so disk usage is
## bounded to roughly 2x MAX_LOG_FILE_SIZE.
func _rotate_log_file() -> void:
	var backup_path := _file_path + DLoggerConstants.LOG_FILE_BACKUP_SUFFIX
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	# The handle must be closed before renaming: the OS may lock the
	# open file, and its position belongs to the pre-rotation generation.
	_close_handle()
	if DirAccess.rename_absolute(_file_path, backup_path) != OK:
		# Keep appending to the current file if rotation fails; the size
		# check will retry on the next write.
		if not _rotate_failed:
			push_error(
				"DLoggerFile: Failed to rotate log file to %s" % backup_path
			)
			_rotate_failed = true
		# Resume appending so later writes are not silently dropped.
		_open_handle()
		return

	# Rename succeeded: a previous failure episode is over.
	_rotate_failed = false

	# Start a fresh log file and write the rotation marker directly:
	# _write_line() would re-check size and recurse, so store + flush here.
	_handle = FileAccess.open(_file_path, FileAccess.WRITE)
	if _handle:
		var rotation_msg := "=== Log Rotated: {0} ==="
		_handle.store_line(
			rotation_msg.format([Time.get_datetime_string_from_system()])
		)
		_handle.flush()
		_writes_since_exist_check = 0
	else:
		if not _rotate_failed:
			push_error(
				(
					"DLoggerFile: Failed to reopen log file after rotation: %s"
					% _file_path
				)
			)
			_rotate_failed = true


# ------------- [Output] -------------
func _output(
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant,
	level: String,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> void:
	_write_line(
		DLoggerFunc.format_log(
			msg,
			category,
			level,
			context,
			prefix,
			p_caller_info,
			p_seconds,
			p_frames
		)
	)
