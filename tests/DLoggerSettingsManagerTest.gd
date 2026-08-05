class_name DLoggerSettingsManagerTest
extends GdUnitTestSuite

const _CONST = preload("res://addons/d_logger/constants.gd")
const _MANAGER = preload("res://addons/d_logger/d_logger_settings_manager.gd")

var _saved_settings: Dictionary = {}


func before_test() -> void:
	# Snapshot the runtime settings these tests mutate so other suites are
	# not affected by leftover values.
	var keys: Array[String] = [
		_CONST.SETTING_PREFIX,
		_CONST.SETTING_ENABLE_CONSOLE,
		_CONST.SETTING_MIN_LEVEL,
		_CONST.SETTING_ENABLE_FILE,
		_CONST.SETTING_FILE_PATH,
		_CONST.SETTING_PAUSE_ON_ERROR,
	]
	for key in keys:
		_saved_settings[key] = {
			"exists": ProjectSettings.has_setting(key),
			"value": ProjectSettings.get_setting(key, null),
		}
		ProjectSettings.clear(key)


func after_test() -> void:
	for key in _saved_settings:
		var snapshot: Dictionary = _saved_settings[key]
		ProjectSettings.clear(key)
		if snapshot["exists"]:
			ProjectSettings.set_setting(key, snapshot["value"])


# ------------- [Fake EditorSettings] -------------
class FakeEditorSettings:
	extends RefCounted

	var values: Dictionary = {}
	var property_infos: Array = []
	var initial_value_calls: Array[String] = []
	signal settings_changed

	func has_setting(name: String) -> bool:
		return values.has(name)

	func get_setting(name: String) -> Variant:
		return values.get(name, null)

	func set_setting(name: String, value: Variant) -> void:
		values[name] = value

	func add_property_info(_info: Dictionary) -> void:
		pass

	func set_initial_value(name: String, _value: Variant, _current: bool = false) -> void:
		initial_value_calls.append(name)


# ------------- [SettingsEntry] -------------
func test_settings_entry_stores_fields() -> void:
	var entry := _MANAGER.SettingsEntry.new(
		"sys_name", "runtime_name", TYPE_INT, 5, PROPERTY_HINT_ENUM, "A:0,B:1", false
	)
	assert_str(entry.sys_name).is_equal("sys_name")
	assert_str(entry.runtime_name).is_equal("runtime_name")
	assert_int(entry.type).is_equal(TYPE_INT)
	assert_int(entry.default_val).is_equal(5)
	assert_int(entry.prop_hint).is_equal(PROPERTY_HINT_ENUM)
	assert_str(entry.prop_hint_str).is_equal("A:0,B:1")
	assert_bool(entry.is_editor_setting).is_false()


func test_settings_entry_defaults() -> void:
	var entry := _MANAGER.SettingsEntry.new("sys_name", "", TYPE_STRING, "d")
	assert_int(entry.prop_hint).is_equal(PROPERTY_HINT_NONE)
	assert_str(entry.prop_hint_str).is_equal("")
	assert_bool(entry.is_editor_setting).is_true()


# ------------- [Settings Entries Configuration] -------------
func test_entries_count_and_kinds() -> void:
	var manager := _MANAGER.new()
	var editor_count := 0
	var project_count := 0
	for entry in manager._settings_entries:
		if entry.is_editor_setting:
			editor_count += 1
		else:
			project_count += 1
	assert_int(manager._settings_entries.size()).is_equal(8)
	assert_int(editor_count).is_equal(7)
	assert_int(project_count).is_equal(1)


func test_entries_editor_sys_names_match_constants() -> void:
	var manager := _MANAGER.new()
	var expected: Array[String] = [
		_CONST.EDITOR_SETTING_ENABLE_CONSOLE,
		_CONST.EDITOR_SETTING_MIN_LEVEL,
		_CONST.EDITOR_SETTING_ENABLE_FILE,
		_CONST.EDITOR_SETTING_FILE_PATH,
		_CONST.EDITOR_SETTING_AUTO_ACTIVATE_PANEL,
		_CONST.EDITOR_SETTING_AUTO_CLEAR_ON_START,
		_CONST.EDITOR_SETTING_PAUSE_ON_ERROR,
	]
	var mismatches: Array[String] = []
	for entry in manager._settings_entries:
		if entry.is_editor_setting and not expected.has(entry.sys_name):
			mismatches.append(entry.sys_name)
	assert_array(mismatches).is_empty()


func test_entries_runtime_names_match_constants() -> void:
	var manager := _MANAGER.new()
	var expected := {
		_CONST.EDITOR_SETTING_ENABLE_CONSOLE: _CONST.SETTING_ENABLE_CONSOLE,
		_CONST.EDITOR_SETTING_MIN_LEVEL: _CONST.SETTING_MIN_LEVEL,
		_CONST.EDITOR_SETTING_ENABLE_FILE: _CONST.SETTING_ENABLE_FILE,
		_CONST.EDITOR_SETTING_FILE_PATH: _CONST.SETTING_FILE_PATH,
		_CONST.EDITOR_SETTING_PAUSE_ON_ERROR: _CONST.SETTING_PAUSE_ON_ERROR,
	}
	var mismatches: Array[String] = []
	for entry in manager._settings_entries:
		if entry.is_editor_setting:
			if entry.runtime_name.is_empty():
				if expected.has(entry.sys_name):
					mismatches.append(entry.sys_name)
			elif entry.runtime_name != expected[entry.sys_name]:
				mismatches.append(entry.sys_name)
	assert_array(mismatches).is_empty()


func test_entries_defaults_match_constants() -> void:
	var manager := _MANAGER.new()
	var expected := {
		_CONST.SETTING_PREFIX: _CONST.DEFAULT_PREFIX,
		_CONST.EDITOR_SETTING_ENABLE_CONSOLE: false,
		_CONST.EDITOR_SETTING_MIN_LEVEL: _CONST.LogLevel.DEBUG,
		_CONST.EDITOR_SETTING_ENABLE_FILE: false,
		_CONST.EDITOR_SETTING_FILE_PATH: _CONST.DEFAULT_FILE_PATH,
		_CONST.EDITOR_SETTING_AUTO_ACTIVATE_PANEL: true,
		_CONST.EDITOR_SETTING_AUTO_CLEAR_ON_START: true,
		_CONST.EDITOR_SETTING_PAUSE_ON_ERROR: false,
	}
	var mismatches: Array[String] = []
	for entry in manager._settings_entries:
		if entry.default_val != expected[entry.sys_name]:
			mismatches.append(entry.sys_name)
	assert_array(mismatches).is_empty()


func test_entries_types_match_declared_types() -> void:
	var manager := _MANAGER.new()
	var expected := {
		_CONST.SETTING_PREFIX: TYPE_STRING,
		_CONST.EDITOR_SETTING_ENABLE_CONSOLE: TYPE_BOOL,
		_CONST.EDITOR_SETTING_MIN_LEVEL: TYPE_INT,
		_CONST.EDITOR_SETTING_ENABLE_FILE: TYPE_BOOL,
		_CONST.EDITOR_SETTING_FILE_PATH: TYPE_STRING,
		_CONST.EDITOR_SETTING_AUTO_ACTIVATE_PANEL: TYPE_BOOL,
		_CONST.EDITOR_SETTING_AUTO_CLEAR_ON_START: TYPE_BOOL,
		_CONST.EDITOR_SETTING_PAUSE_ON_ERROR: TYPE_BOOL,
	}
	var mismatches: Array[String] = []
	for entry in manager._settings_entries:
		if entry.type != expected[entry.sys_name]:
			mismatches.append(entry.sys_name)
	assert_array(mismatches).is_empty()


func test_min_level_entry_has_enum_hint() -> void:
	var manager := _MANAGER.new()
	for entry in manager._settings_entries:
		if entry.sys_name == _CONST.EDITOR_SETTING_MIN_LEVEL:
			assert_int(entry.prop_hint).is_equal(PROPERTY_HINT_ENUM)
			assert_str(entry.prop_hint_str).is_equal(_CONST.MIN_LEVEL_HINT_STRING)
			return
	fail("EDITOR_SETTING_MIN_LEVEL entry not found")


func test_file_path_entry_has_file_hint() -> void:
	var manager := _MANAGER.new()
	for entry in manager._settings_entries:
		if entry.sys_name == _CONST.EDITOR_SETTING_FILE_PATH:
			assert_int(entry.prop_hint).is_equal(PROPERTY_HINT_FILE)
			assert_str(entry.prop_hint_str).is_equal("*.log, *.txt;Log Files")
			return
	fail("EDITOR_SETTING_FILE_PATH entry not found")


func test_prefix_entry_is_project_setting_without_runtime_name() -> void:
	var manager := _MANAGER.new()
	for entry in manager._settings_entries:
		if entry.sys_name == _CONST.SETTING_PREFIX:
			assert_bool(entry.is_editor_setting).is_false()
			assert_str(entry.runtime_name).is_equal("")
			return
	fail("SETTING_PREFIX entry not found")


# ------------- [Initialize] -------------
func test_initialize_registers_missing_editor_settings() -> void:
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)

	var missing: Array[String] = []
	for entry in manager._settings_entries:
		if entry.is_editor_setting and not fake.has_setting(entry.sys_name):
			missing.append(entry.sys_name)
	assert_array(missing).is_empty()


func test_initialize_registers_defaults_for_missing_settings() -> void:
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)

	var wrong: Array[String] = []
	for entry in manager._settings_entries:
		if entry.is_editor_setting and fake.get_setting(entry.sys_name) != entry.default_val:
			wrong.append(entry.sys_name)
	assert_array(wrong).is_empty()


func test_initialize_does_not_overwrite_existing_editor_settings() -> void:
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, true)
	var manager := _MANAGER.new()
	manager.initialize(fake)
	assert_bool(fake.get_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE)).is_true()


func test_initialize_sets_initial_value_only_for_missing_settings() -> void:
	# Re-running set_initial_value on every startup would reset the
	# editor's "Reset to default" baseline, so it must only happen when
	# the setting is first created.
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, true)
	var manager := _MANAGER.new()
	manager.initialize(fake)

	# Existing setting: no initial value call
	assert_bool(
		fake.initial_value_calls.has(_CONST.EDITOR_SETTING_ENABLE_CONSOLE)
	).is_false()
	# Missing settings: initial value called once
	assert_bool(
		fake.initial_value_calls.has(_CONST.EDITOR_SETTING_MIN_LEVEL)
	).is_true()
	assert_int(
		fake.initial_value_calls.count(_CONST.EDITOR_SETTING_MIN_LEVEL)
	).is_equal(1)


func test_initialize_re_initialization_does_not_reset_initial_values() -> void:
	# A second initialize() (e.g. plugin re-enter) must not re-register
	# initial values for already-existing settings.
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)
	manager.initialize(fake)

	for entry in manager._settings_entries:
		if entry.is_editor_setting:
			assert_int(
				fake.initial_value_calls.count(entry.sys_name)
			).is_equal(1)


func test_initialize_registers_project_settings() -> void:
	var manager := _MANAGER.new()
	manager.initialize(FakeEditorSettings.new())
	assert_bool(ProjectSettings.has_setting(_CONST.SETTING_PREFIX)).is_true()
	assert_str(ProjectSettings.get_setting(_CONST.SETTING_PREFIX)).is_equal(
		_CONST.DEFAULT_PREFIX
	)


func test_initialize_connects_settings_changed() -> void:
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)
	assert_bool(fake.settings_changed.is_connected(manager._on_settings_changed)).is_true()


func test_initialize_does_not_connect_twice() -> void:
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)
	manager.initialize(fake)
	assert_int(fake.settings_changed.get_connections().size()).is_equal(1)


func test_initialize_syncs_editor_settings_to_runtime() -> void:
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, true)
	fake.set_setting(_CONST.EDITOR_SETTING_MIN_LEVEL, _CONST.LogLevel.WARN)
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_FILE, true)
	fake.set_setting(_CONST.EDITOR_SETTING_FILE_PATH, "user://custom.log")
	fake.set_setting(_CONST.EDITOR_SETTING_PAUSE_ON_ERROR, true)
	var manager := _MANAGER.new()
	manager.initialize(fake)

	assert_bool(ProjectSettings.get_setting(_CONST.SETTING_ENABLE_CONSOLE)).is_true()
	assert_int(ProjectSettings.get_setting(_CONST.SETTING_MIN_LEVEL)).is_equal(
		_CONST.LogLevel.WARN
	)
	assert_bool(ProjectSettings.get_setting(_CONST.SETTING_ENABLE_FILE)).is_true()
	assert_str(ProjectSettings.get_setting(_CONST.SETTING_FILE_PATH)).is_equal(
		"user://custom.log"
	)
	assert_bool(ProjectSettings.get_setting(_CONST.SETTING_PAUSE_ON_ERROR)).is_true()


func test_initialize_does_not_sync_entries_without_runtime_name() -> void:
	# auto_activate_panel and auto_clear_on_start are editor-only and have
	# no ProjectSettings counterpart.
	var manager := _MANAGER.new()
	manager.initialize(FakeEditorSettings.new())
	assert_bool(ProjectSettings.has_setting("debug/d_logger/auto_activate_panel")).is_false()
	assert_bool(ProjectSettings.has_setting("debug/d_logger/auto_clear_on_start")).is_false()


func test_sync_to_runtime_does_not_touch_project_prefix_setting() -> void:
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, "KEEP_ME")
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, false)
	var manager := _MANAGER.new()
	manager.initialize(fake)
	assert_str(ProjectSettings.get_setting(_CONST.SETTING_PREFIX)).is_equal("KEEP_ME")


# ------------- [Sync to Runtime] -------------
func test_sync_to_runtime_updates_changed_values() -> void:
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, true)
	var manager := _MANAGER.new()
	manager.initialize(fake)

	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, false)
	manager.sync_to_runtime()
	assert_bool(ProjectSettings.get_setting(_CONST.SETTING_ENABLE_CONSOLE)).is_false()


func test_sync_to_runtime_before_initialize_is_noop() -> void:
	var manager := _MANAGER.new()
	manager.sync_to_runtime()
	assert_bool(ProjectSettings.has_setting(_CONST.SETTING_ENABLE_CONSOLE)).is_false()


func test_settings_changed_signal_triggers_sync() -> void:
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_MIN_LEVEL, _CONST.LogLevel.WARN)
	var manager := _MANAGER.new()
	manager.initialize(fake)

	fake.set_setting(_CONST.EDITOR_SETTING_MIN_LEVEL, _CONST.LogLevel.ERROR)
	fake.settings_changed.emit()
	assert_int(ProjectSettings.get_setting(_CONST.SETTING_MIN_LEVEL)).is_equal(
		_CONST.LogLevel.ERROR
	)


# ------------- [Shutdown] -------------
func test_shutdown_disconnects_settings_changed() -> void:
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)
	manager.shutdown()
	assert_bool(fake.settings_changed.is_connected(manager._on_settings_changed)).is_false()


func test_shutdown_is_idempotent() -> void:
	var fake := FakeEditorSettings.new()
	var manager := _MANAGER.new()
	manager.initialize(fake)
	manager.shutdown()
	manager.shutdown()
	fake.settings_changed.emit()


func test_shutdown_stops_sync_on_signal() -> void:
	var fake := FakeEditorSettings.new()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, true)
	var manager := _MANAGER.new()
	manager.initialize(fake)
	assert_bool(ProjectSettings.get_setting(_CONST.SETTING_ENABLE_CONSOLE)).is_true()

	manager.shutdown()
	fake.set_setting(_CONST.EDITOR_SETTING_ENABLE_CONSOLE, false)
	fake.settings_changed.emit()
	assert_bool(ProjectSettings.get_setting(_CONST.SETTING_ENABLE_CONSOLE)).is_true()
