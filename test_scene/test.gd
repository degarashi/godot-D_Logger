extends Node

const DLOGGER = preload("res://addons/d_logger/d_logger.gd")
const _C = preload("uid://cwfe01280qmo7")

# クラスレベル変数として定義
var logger_custom_prefix: DLOGGER


# ------------- [Public Method] -------------
func _ready() -> void:
	# テストの初期化とデフォルト設定でのロギング
	_test_default_settings()
	_test_custom_prefix()
	_test_log_level_debug()
	_test_log_level_warn()
	_test_log_level_error()
	_test_console_disabled()
	_test_with_category()
	_test_with_multiple_tags()
	_test_log_stacking()
	_test_caller_info()


# ------------- [Private Method] -------------
func _test_default_settings() -> void:
	# デフォルト設定でのロギングテスト
	var logger_default := DLOGGER.new()
	logger_default.info("Default: Logging info")
	logger_default.warn("Default: Logging warning")


func _test_custom_prefix() -> void:
	# カスタムプレフィックス設定テスト
	logger_custom_prefix = DLOGGER.new("CUSTOM_APP")
	logger_custom_prefix.warn("Custom Prefix: Warning with new prefix")


func _test_log_level_debug() -> void:
	# ログレベルを DEBUG に設定（すべてのログが可視化）
	var logger_debug := DLOGGER.new("DEBUG_TEST", _C.LogLevel.DEBUG)
	logger_debug.debug("Debug: Visible")
	logger_debug.info("Info: Visible")
	logger_debug.warn("Warn: Visible")


func _test_log_level_warn() -> void:
	# ログレベルを WARN に設定（INFO 以下は非表示）
	var logger_warn_limit := DLOGGER.new("WARN_LIMIT", _C.LogLevel.WARN)
	logger_warn_limit.info("Warn Limit: Info should NOT be visible")
	logger_warn_limit.warn("Warn Limit: Warning should be visible")
	logger_warn_limit.error("Warn Limit: Error should be visible")


func _test_log_level_error() -> void:
	# ログレベルを ERROR に設定（WARN は非表示）
	var logger_error_only := DLOGGER.new("ERROR_ONLY", _C.LogLevel.ERROR)
	logger_error_only.warn("Error Only: Warning should NOT be visible")
	logger_error_only.error("Error Only: Error should be visible")


func _test_console_disabled() -> void:
	# コンソール出力を無効化（ログは出力されない）
	var logger_no_console := DLOGGER.new("SILENT", -1, false)
	logger_no_console.warn("Silent: Warning should NOT appear in console")


func _test_with_category() -> void:
	# カテゴリ付きの警告テスト
	var logger_cat := DLOGGER.new("CATEGORY_TEST")
	logger_cat.warn("Low memory detected!", [], "System")
	logger_cat.info("Player spawned at {0}", [Vector2(100, 200)], "Gameplay")
	logger_cat.error("Connection lost", [], "Network")
	logger_cat.debug("Internal AI state: IDLE", [], "Gameplay")


func _test_with_multiple_tags() -> void:
	# 複数のタグ付きテスト
	var logger_tags := DLOGGER.new("TAG_TEST")
	logger_tags.info("Multiple tags: AI and Combat", [], "AI|Combat")
	logger_tags.info("Multiple tags: Network and Player", [], "Network|Player")
	logger_tags.info("Single tag: Player", [], "Player")


func _test_log_stacking() -> void:
	# ログスタッキングテスト
	print("Testing Log Stacking (Check Editor Panel for (x10) indicator)...")
	var logger_stack := DLOGGER.new("STACK_TEST")
	for i in range(10):
		logger_stack.info("This is a repeated message")
	logger_stack.info("A different message")
	for i in range(5):
		logger_stack.info("This is a repeated message")  # 最後のメッセージが異なるため新しいスタックを開始


func _test_caller_info() -> void:
	# 呼び出し元情報の検証
	await get_tree().create_timer(0.5).timeout
	_check_caller_info(logger_custom_prefix)


func _check_caller_info(p_logger: DLOGGER) -> void:
	p_logger.warn("Checking line number/caller for warning from sub-function")
