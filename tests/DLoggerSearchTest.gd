class_name DLoggerSearchTest
extends GdUnitTestSuite


# ------------- [matches] -------------
func test_empty_query_matches_everything() -> void:
	var search := DLoggerSearch.new()
	assert_bool(search.matches("any message", "cat", "PREFIX")).is_true()
	assert_bool(search.matches("", "", "")).is_true()


func test_plain_match_case_insensitive_by_default() -> void:
	var search := DLoggerSearch.new()
	search.query = "hello"
	assert_bool(search.matches("say HELLO there", "", "")).is_true()
	assert_bool(search.matches("goodbye", "", "")).is_false()


func test_plain_match_case_sensitive() -> void:
	var search := DLoggerSearch.new()
	search.query = "Hello"
	search.case_sensitive = true
	assert_bool(search.matches("say Hello there", "", "")).is_true()
	assert_bool(search.matches("say hello there", "", "")).is_false()


func test_plain_match_in_category_or_prefix() -> void:
	var search := DLoggerSearch.new()
	search.query = "network"
	assert_bool(search.matches("payload", "NETWORK", "")).is_true()
	assert_bool(search.matches("payload", "", "NetworkModule")).is_true()
	assert_bool(search.matches("payload", "audio", "Renderer")).is_false()


func test_regex_match() -> void:
	var search := DLoggerSearch.new()
	search.query = "err.*\\d+"
	search.compile()
	assert_object(search.regex).is_not_null()
	assert_bool(search.matches("error 42 found", "", "")).is_true()
	assert_bool(search.matches("error none", "", "")).is_false()


func test_compile_empty_query_keeps_regex_null() -> void:
	var search := DLoggerSearch.new()
	search.query = ""
	search.compile()
	assert_object(search.regex).is_null()


func test_compile_invalid_pattern_falls_back_to_plain() -> void:
	var search := DLoggerSearch.new()
	search.query = "[invalid"
	search.compile()
	assert_object(search.regex).is_null()
	# Plain-text fallback still matches
	assert_bool(search.matches("[invalid pattern", "", "")).is_true()


# ------------- [highlight] -------------
func test_highlight_wraps_matches() -> void:
	var search := DLoggerSearch.new()
	search.query = "abc"
	var result: String = search.highlight("xxabcyy")
	assert_str(result).contains(
		"[bgcolor=yellow][color=black]abc[/color][/bgcolor]"
	)


func test_highlight_empty_query_unchanged() -> void:
	var search := DLoggerSearch.new()
	assert_str(search.highlight("hello")).is_equal("hello")


func test_highlight_multiple_matches() -> void:
	var search := DLoggerSearch.new()
	search.query = "ab"
	var result: String = search.highlight("ab ab ab")
	assert_int(result.count("[bgcolor=yellow]")).is_equal(3)


func test_highlight_case_insensitive_by_default() -> void:
	var search := DLoggerSearch.new()
	search.query = "ABC"
	var result: String = search.highlight("xxabcxx")
	assert_str(result).contains("[color=black]abc[/color]")


func test_highlight_case_sensitive() -> void:
	var search := DLoggerSearch.new()
	search.query = "ABC"
	search.case_sensitive = true
	assert_str(search.highlight("xxABCxx")).contains("[color=black]ABC[/color]")
	assert_str(search.highlight("xxabcxx")).is_equal("xxabcxx")


func test_highlight_regex() -> void:
	var search := DLoggerSearch.new()
	search.query = "a+b"
	search.compile()
	assert_str(search.highlight("xaabz")).contains("[color=black]aab[/color]")


func test_highlight_case_insensitive_unicode_offsets() -> void:
	# Godot's to_lower() is a 1:1 char mapping (U+0130 -> single "i"), so
	# offsets found in the lowercased text are valid slices of the
	# original. Exact equality pins that no misalignment creeps in for
	# characters whose case mapping differs under full Unicode folding.
	var search := DLoggerSearch.new()
	search.query = "abc"
	assert_str(search.highlight("\u0130ABC\u0130")).is_equal(
		"\u0130[bgcolor=yellow][color=black]ABC[/color][/bgcolor]\u0130"
	)


# ------------- [reset] -------------
func test_reset_clears_state() -> void:
	var search := DLoggerSearch.new()
	search.query = "abc"
	search.case_sensitive = true
	search.compile()
	search.reset()
	assert_str(search.query).is_equal("")
	assert_bool(search.case_sensitive).is_false()
	assert_object(search.regex).is_null()
	assert_bool(search.is_empty()).is_true()
