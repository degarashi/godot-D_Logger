class_name DLoggerSearch
extends RefCounted

## Search state and matching logic for the log panel: query, case sensitivity
## and the compiled regex (when regex mode is active). Pure logic without UI
## dependencies so it can be unit-tested independently of the panel.

# ------------- [State] -------------
var query: String = ""
var case_sensitive: bool = false
var regex: RegEx = null


# ------------- [Public Method] -------------
func is_empty() -> bool:
	return query.is_empty()


## Resets all search state (used when clearing the log panel).
func reset() -> void:
	query = ""
	case_sensitive = false
	regex = null


## (Re)compiles the current query into a RegEx. Falls back to plain-text
## matching on compile failure (with a warning so the fallback is not silent).
func compile() -> void:
	regex = null
	var pattern := query
	if pattern.is_empty():
		return
	if not case_sensitive:
		pattern = "(?i)" + pattern
	var compiled := RegEx.new()
	var err := compiled.compile(pattern)
	if err == OK:
		regex = compiled
	else:
		# The engine already logs the PCRE2 error detail for the failed
		# compile; attribute it here so the fallback is not silent.
		push_warning(
			(
				'Invalid regex pattern "{0}" (error {1}). '.format([query, err])
				+ "Falling back to plain text search."
			)
		)


## Returns true when the log matches the search query. An empty query
## matches everything.
func matches(message: String, category: String, prefix: String) -> bool:
	if is_empty():
		return true

	if regex:
		return (
			regex.search(message) != null
			or regex.search(category) != null
			or regex.search(prefix) != null
		)

	var q := query
	if not case_sensitive:
		q = q.to_lower()
		message = message.to_lower()
		category = category.to_lower()
		prefix = prefix.to_lower()

	return q in message or q in category or q in prefix


## Highlights occurrences of the query in the given text using BBCode.
## Wraps each match with a yellow background and black text for visibility.
func highlight(text: String) -> String:
	if is_empty():
		return text

	if regex:
		var matches := regex.search_all(text)
		if matches.is_empty():
			return text
		var result: String = ""
		var last_end: int = 0
		for match: RegExMatch in matches:
			var start := match.get_start()
			var end := match.get_end()
			result += text.substr(last_end, start - last_end)
			result += (
				"[bgcolor=yellow][color=black]"
				+ text.substr(start, end - start)
				+ "[/color][/bgcolor]"
			)
			last_end = end
		result += text.substr(last_end)
		return result

	var q := query
	if case_sensitive:
		var result: String = ""
		var last_end: int = 0
		var pos: int = text.find(q, last_end)
		while pos >= 0:
			result += text.substr(last_end, pos - last_end)
			result += (
				"[bgcolor=yellow][color=black]"
				+ text.substr(pos, q.length())
				+ "[/color][/bgcolor]"
			)
			last_end = pos + q.length()
			pos = text.find(q, last_end)
		result += text.substr(last_end)
		return result

	# Offsets found in lower_text are reused to slice the ORIGINAL text.
	# This is safe because Godot's String.to_lower() maps every character
	# 1:1 (it does not apply full Unicode folding, e.g. U+0130 becomes
	# the single char "i"), so lower_text always has the same length as
	# text. Pinned by test_highlight_case_insensitive_unicode_offsets;
	# if the engine ever adopts expanding case mappings, these indices
	# would have to be remapped onto the original string instead.
	var lower_text := text.to_lower()
	var lower_query := q.to_lower()
	var result: String = ""
	var last_end: int = 0
	var pos: int = lower_text.find(lower_query, last_end)
	while pos >= 0:
		result += text.substr(last_end, pos - last_end)
		result += (
			"[bgcolor=yellow][color=black]"
			+ text.substr(pos, q.length())
			+ "[/color][/bgcolor]"
		)
		last_end = pos + q.length()
		pos = lower_text.find(lower_query, last_end)
	result += text.substr(last_end)
	return result
