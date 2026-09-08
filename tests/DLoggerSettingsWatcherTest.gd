class_name DLoggerSettingsWatcherTest
extends GdUnitTestSuite

const _WATCHER = preload(
	"res://addons/d_logger/d_logger_settings_watcher.gd"
)
const _CONST = preload("res://addons/d_logger/constants.gd")


# ------------- [poll] -------------
func test_poll_false_without_change() -> void:
	var watcher := _WATCHER.new()
	assert_bool(watcher.poll()).is_false()


func test_poll_true_once_per_change() -> void:
	# Prefix key is used so level filtering is unaffected while changed
	var prev: String = ProjectSettings.get_setting(
		_CONST.SETTING_PREFIX, _CONST.DEFAULT_PREFIX
	)
	var watcher := _WATCHER.new()
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, "__watcher_test__")
	assert_bool(watcher.poll()).is_true()
	assert_bool(watcher.poll()).is_false()
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, prev)


func test_refresh_adopts_baseline() -> void:
	var prev: String = ProjectSettings.get_setting(
		_CONST.SETTING_PREFIX, _CONST.DEFAULT_PREFIX
	)
	var watcher := _WATCHER.new()
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, "__watcher_test__")
	watcher.refresh()
	assert_bool(watcher.poll()).is_false()
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, prev)
