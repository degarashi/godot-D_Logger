class_name DLoggerFileTest
extends GdUnitTestSuite

const _FILE_LOGGER = preload("res://addons/d_logger/logger/d_logger_file.gd")

var _temp_dir: String = ""


func before() -> void:
	_temp_dir = create_temp_dir("dlogger_test")


func after() -> void:
	if not _temp_dir.is_empty():
		DirAccess.remove_absolute(_temp_dir)


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
