class_name DLoggerFileTest
extends GdUnitTestSuite

const _FILE_LOGGER = preload("res://addons/d_logger/logger/d_logger_file.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")

var _temp_dir: String = ""


func before() -> void:
	_temp_dir = create_temp_dir("dlogger_test")


func after() -> void:
	if _temp_dir.is_empty():
		return
	_remove_tree(_temp_dir)


## Recursively removes a directory tree (DirAccess.remove_absolute only
## removes empty directories).
func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir():
			_remove_tree(path.path_join(entry))
		else:
			dir.remove(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	dir.remove_absolute(path)


# ------------- [Constructor] -------------
func test_init_creates_file() -> void:
	var path := _temp_dir.path_join("test.log")
	var logger := _FILE_LOGGER.new(path)
	assert_object(logger).is_not_null()
	assert_file(path).exists()


func test_init_creates_directory() -> void:
	var path := _temp_dir.path_join("subdir").path_join("test.log")
	var logger := _FILE_LOGGER.new(path)
	assert_file(path).exists()


# ------------- [Write] -------------
func test_write_line() -> void:
	var path := _temp_dir.path_join("write_test.log")
	var logger := _FILE_LOGGER.new(path)
	logger.warn("Test warning")
	# Flush and re-read
	var file := FileAccess.open(path, FileAccess.READ)
	assert_object(file).is_not_null()
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("Test warning")


func test_write_multiple_lines() -> void:
	var path := _temp_dir.path_join("multi_test.log")
	var logger := _FILE_LOGGER.new(path)
	logger.info("Line 1")
	logger.warn("Line 2")
	logger.error("Line 3")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("Line 1")
	assert_str(content).contains("Line 2")
	assert_str(content).contains("Line 3")


# ------------- [Session Header] -------------
func test_session_header_written() -> void:
	var path := _temp_dir.path_join("session_test.log")
	var logger := _FILE_LOGGER.new(path)
	var file := FileAccess.open(path, FileAccess.READ)
	var first_line := file.get_line()
	file.close()
	assert_str(first_line).contains("New Session Started")


# ------------- [Flush on Warn/Error] -------------
func test_flush_on_warn() -> void:
	var path := _temp_dir.path_join("flush_warn.log")
	var logger := _FILE_LOGGER.new(path)
	logger.warn("Warning message")
	# After warn, data should be flushed to disk
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("Warning message")


func test_flush_on_error() -> void:
	var path := _temp_dir.path_join("flush_error.log")
	var logger := _FILE_LOGGER.new(path)
	logger.error("Error message")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("Error message")


# ------------- [Append Mode] -------------
func test_append_existing_file() -> void:
	var path := _temp_dir.path_join("append_test.log")
	# Create initial file
	var logger1 := _FILE_LOGGER.new(path)
	logger1.warn("First warning")
	# Create second logger (should append)
	var logger2 := _FILE_LOGGER.new(path)
	logger2.warn("Second warning")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("First warning")
	assert_str(content).contains("Second warning")


func test_two_instances_same_path_do_not_overwrite() -> void:
	var path := _temp_dir.path_join("multi_instance.log")
	# Both loggers stay alive with interleaved writes; each write must seek
	# to the current end of file instead of relying on a stale handle.
	var logger1 := _FILE_LOGGER.new(path)
	var logger2 := _FILE_LOGGER.new(path)
	logger1.warn("from logger1")
	logger2.warn("from logger2")
	logger1.warn("again logger1")
	logger2.warn("again logger2")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("from logger1")
	assert_str(content).contains("from logger2")
	assert_str(content).contains("again logger1")
	assert_str(content).contains("again logger2")


# ------------- [Level Checks] -------------
func test_file_logger_level_checks() -> void:
	var path := _temp_dir.path_join("levels.log")
	var logger := _FILE_LOGGER.new(path)
	# DLoggerBase defaults: all enabled
	assert_bool(logger.is_debug_enabled()).is_true()
	assert_bool(logger.is_info_enabled()).is_true()
	assert_bool(logger.is_warn_enabled()).is_true()
	assert_bool(logger.is_error_enabled()).is_true()


# ------------- [Error Path] -------------
func test_init_invalid_path_does_not_crash() -> void:
	var logger := _FILE_LOGGER.new("")
	assert_object(logger).is_not_null()


func test_debug_writes_no_flush() -> void:
	var path := _temp_dir.path_join("debug_noflush.log")
	var logger := _FILE_LOGGER.new(path)
	logger.debug("debug without flush")
	# Force a flush via warn so buffered content is written to disk
	logger.warn("flush_trigger")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("debug without flush")


func test_info_writes_no_flush() -> void:
	var path := _temp_dir.path_join("info_noflush.log")
	var logger := _FILE_LOGGER.new(path)
	logger.info("info without flush")
	# Force a flush via warn so buffered content is written to disk
	logger.warn("flush_trigger")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("info without flush")


# ------------- [Append Session Header] -------------
func test_append_creates_second_session_header() -> void:
	var path := _temp_dir.path_join("session_header.log")

	# First session
	var logger1 := _FILE_LOGGER.new(path)
	logger1.warn("first message")
	logger1 = null

	# Second session - should append new header
	var logger2 := _FILE_LOGGER.new(path)
	logger2.warn("second message")
	logger2 = null

	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	# Count session headers: 1 for each logger session
	var lines := content.split("\n")
	var session_count := 0
	for line in lines:
		if line.contains("New Session Started"):
			session_count += 1
	assert_int(session_count).is_equal(2)
	assert_str(content).contains("first message")
	assert_str(content).contains("second message")


func test_append_preserves_first_session_content() -> void:
	var path := _temp_dir.path_join("preserve.log")

	var logger1 := _FILE_LOGGER.new(path)
	logger1.warn("session1 data")
	logger1 = null

	var logger2 := _FILE_LOGGER.new(path)
	logger2.warn("session2 data")
	logger2 = null

	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	assert_str(content).contains("session1 data")
	assert_str(content).contains("session2 data")


func test_append_with_multiple_flushes() -> void:
	var path := _temp_dir.path_join("multi_flush.log")

	var logger1 := _FILE_LOGGER.new(path)
	logger1.warn("warn1")
	logger1.debug("debug1")
	logger1.error("error1")
	logger1 = null

	var logger2 := _FILE_LOGGER.new(path)
	logger2.info("info2")
	logger2.warn("warn2")
	logger2 = null

	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	assert_str(content).contains("warn1")
	assert_str(content).contains("warn2")
	assert_str(content).contains("error1")
	assert_str(content).contains("info2")
	assert_str(content).contains("debug1")


# ------------- [Rotation] -------------
func test_rotate_log_file_creates_backup() -> void:
	var path := _temp_dir.path_join("rotate_test.log")
	var logger := _FILE_LOGGER.new(path)
	logger._write_line("first line")
	logger._rotate_log_file()
	assert_file(path).exists()
	assert_file(path + _CONST.LOG_FILE_BACKUP_SUFFIX).exists()
	# The fresh file starts with a rotation header and accepts new writes
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("Log Rotated")


func test_rotate_log_file_keeps_single_backup_generation() -> void:
	var path := _temp_dir.path_join("rotate_gen.log")
	var logger := _FILE_LOGGER.new(path)
	logger._write_line("first content")
	logger._rotate_log_file()
	logger._write_line("second content")
	logger._rotate_log_file()

	var backup_path := path + _CONST.LOG_FILE_BACKUP_SUFFIX
	assert_file(backup_path).exists()
	# No second generation is created (single backup, overwritten in place)
	assert_bool(FileAccess.file_exists(backup_path + _CONST.LOG_FILE_BACKUP_SUFFIX)).is_false()

	var backup := FileAccess.open(backup_path, FileAccess.READ)
	var backup_content := backup.get_as_text()
	backup.close()
	assert_str(backup_content).contains("second content")
	assert_bool(backup_content.contains("first content")).is_false()


func test_write_line_triggers_rotation_at_size_limit() -> void:
	var path := _temp_dir.path_join("rotate_limit.log")
	var logger := _FILE_LOGGER.new(path)
	var big := "x".repeat(_CONST.MAX_LOG_FILE_SIZE)
	logger._write_line(big)
	# The file now exceeds the limit; the next write triggers rotation.
	# warn() is used so the new content is flushed to disk before reading.
	logger.warn("after limit")
	assert_file(path + _CONST.LOG_FILE_BACKUP_SUFFIX).exists()
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("after limit")


func test_rotate_failure_falls_back_to_append() -> void:
	var path := _temp_dir.path_join("rotate_fail.log")
	var logger := _FILE_LOGGER.new(path)
	logger._write_line("before rotate")
	# Block the backup path with a directory so the rename fails
	var backup_path := path + _CONST.LOG_FILE_BACKUP_SUFFIX
	DirAccess.make_dir_recursive_absolute(backup_path)
	logger._rotate_log_file()
	# Fallback keeps appending to the original file (warn flushes to disk)
	logger.warn("after failed rotate")
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert_str(content).contains("before rotate")
	assert_str(content).contains("after failed rotate")
	DirAccess.remove_absolute(backup_path)
