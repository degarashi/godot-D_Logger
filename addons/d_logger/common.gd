class_name DLoggerFunc
extends Object

# Cache for time/frame to avoid redundant computation across logger chain.
# NOT thread-safe by design: _dispatch sets/clears the cache around the
# synchronous downstream formatting, assuming logging happens on the main
# thread. Concurrent logging from threads would race on these values
# (worst case: wrong timestamps), which is acceptable for a debug logger.
static var _cached_seconds: float = -1.0
static var _cached_frames: int = -1


static func set_time_cache(seconds: float, frames: int) -> void:
	_cached_seconds = seconds
	_cached_frames = frames


static func clear_time_cache() -> void:
	_cached_seconds = -1.0
	_cached_frames = -1


## @brief Checks if the given object meets the requirements of a logger interface
## @param logger The object to be checked
## @return True if it implements all required methods, false otherwise
static func has_logger_interface(logger: Object) -> bool:
	if not logger:
		return false

	const REQUIRED_METHODS: PackedStringArray = [
		"is_debug_enabled",
		"is_info_enabled",
		"is_warn_enabled",
		"is_error_enabled",
		"debug",
		"info",
		"warn",
		"error"
	]
	for method_name: String in REQUIRED_METHODS:
		if not logger.has_method(method_name):
			return false

	return true


## @brief Retrieves a logger from a node or an object
## @param logger The object to attempt to get the logger from
## @return The child object implementing the logger interface if found, null otherwise
static func get_logger(logger: Object) -> Object:
	if not logger:
		return null
	if has_logger_interface(logger):
		return logger

	if logger is Node:
		if logger.has_method("get_logger"):
			var internal_logger: Object = logger.get_logger()
			if has_logger_interface(internal_logger):
				return internal_logger

	return null


## @brief Validates if the object is an active logger
## @param logger The object to be checked
## @return True if it is a valid logger, false otherwise
static func is_logger(logger: Object) -> bool:
	return get_logger(logger) != null


## Searches for a logger by walking up the ancestor chain. At each
## ancestor, the node's other children (i.e. siblings of the requester
## at that level, also reachable as uncles of start_node) are also
## inspected. Closer ancestors are checked before their siblings,
## which are checked before the next ancestor up. The sibling scan
## supports shared-container layouts where a sibling hosts the
## logger; callers that need strict ancestor-only search must walk
## the parent chain themselves.
## @param start_node The node to start the search from
## @return The first logger found, or null if none.
static func find_logger_from_ancestor(start_node: Node) -> Object:
	if not start_node:
		return null

	var current := start_node.get_parent()
	while current:
		var ancestor_logger := get_logger(current)
		if ancestor_logger:
			return ancestor_logger

		for child: Node in current.get_children():
			if child == start_node:
				continue
			var logger := get_logger(child)
			if logger:
				return logger
		start_node = current
		current = current.get_parent()

	return null


static func get_object_string(obj: Object) -> String:
	if obj is Node:
		return "[{0}]".format([obj.name])
	return "[{0}:{1}]".format(
		[obj.get_class(), String.num_uint64(obj.get_instance_id())]
	)


static func get_caller_info(level: String) -> Dictionary:
	# Release builds cannot use get_stack(), so we skip it entirely
	# Also skip for high-frequency logs (DEBUG, INFO) to maintain performance
	if not OS.is_debug_build() or level == "DEBUG" or level == "INFO":
		return {}

	var stack := get_stack()

	# Loop through the stack to find the first file outside the logger addon
	for i in range(stack.size()):
		var entry: Dictionary = stack[i]
		var source: String = entry.get("source", "")

		if not source.begins_with("res://addons/d_logger/"):
			return {
				"file": source,
				"line": entry.get("line", 0),
				"display":
				"[{file}:{line}]".format(
					{"file": source.get_file(), "line": entry.get("line", 0)}
				)
			}

	return {}


## Replaces BBCode brackets in arbitrary text with their escaped equivalents
## ([lb] / [rb]) so user-provided content cannot inject BBCode markup
## (e.g. [url=...] link spoofing or color/bold injection).
## Uses a single pass: chained String.replace() calls would re-escape the
## [lb]/[rb] tokens inserted by the earlier pass.
static func escape_bbcode(text: String) -> String:
	var parts := PackedStringArray()
	for i in text.length():
		var c := text[i]
		if c == "[":
			parts.append("[lb]")
		elif c == "]":
			parts.append("[rb]")
		else:
			parts.append(c)
	return "".join(parts)


## Returns true if the given text still contains an unresolved format
## placeholder ({0} or {name} style). String.format() silently leaves
## placeholders untouched when the provided values do not match the
## placeholder key type (e.g. a Dictionary for {0} positional placeholders,
## or an Array for {name} named ones). Detecting leftovers lets the caller
## warn instead of logging a broken message silently.
static func has_unresolved_placeholder(text: String) -> bool:
	var start := text.find("{")
	while start >= 0:
		var end := text.find("}", start)
		if end < 0:
			# No closing brace anywhere ahead, so nothing further
			# can form a placeholder either
			return false
		var body := text.substr(start + 1, end - start - 1)
		var is_key := body.length() > 0
		for i in body.length():
			var c := body[i]
			if not (
				c == "_"
				or c.is_valid_int()
				or (c >= "a" and c <= "z")
				or (c >= "A" and c <= "Z")
			):
				is_key = false
				break
		if is_key:
			return true
		# Not a placeholder ({}, or a non-key body such as a JSON
		# snippet): resume from the NEXT '{' instead of past the '}',
		# so placeholders following an empty or nested brace pair are
		# still detected.
		start = text.find("{", start + 1)
	return false


static func get_source_string(
	prefix: String, category: String, use_bbcode: bool = false
) -> String:
	if category.is_empty() or category == prefix:
		if use_bbcode:
			# Escape both the URL target and the display label so a
			# bracket in prefix/category cannot break out of the [url=...]
			# tag and inject arbitrary BBCode (e.g. a category like
			# "][url=foo]bar" would otherwise produce broken markup
			# that the RichTextLabel parser would re-interpret).
			var safe_prefix := escape_bbcode(prefix)
			return "[[url=filter:%s]%s[/url]]" % [safe_prefix, safe_prefix]
		return "[%s]" % prefix

	var tags := category.split("|")
	if use_bbcode:
		var linked: Array[String] = []
		for t in tags:
			var tag := t.strip_edges()
			if not tag.is_empty():
				# Same escaping rationale as above: protect both the
				# URL meta value and the display text per category tag.
				var safe_tag := escape_bbcode(tag)
				linked.append("[url=filter:%s]%s[/url]" % [safe_tag, safe_tag])
		var body := "|".join(linked)
		if prefix == DLoggerConstants.DEFAULT_PREFIX:
			return "[" + body + "]"
		return "[%s:%s]" % [prefix, body]

	if prefix == DLoggerConstants.DEFAULT_PREFIX:
		return "[%s]" % category
	return "[%s:%s]" % [prefix, category]


static func get_formatted_line(
	time: float,
	frame: int,
	source_str: String,
	caller_info: Variant,  # Can be String (old format) or Dictionary
	ctx_str: String,
	level: String,
	msg: String,
	use_bbcode: bool = false
) -> String:
	var caller_display := ""
	var caller_url := ""

	if caller_info is Dictionary and not caller_info.is_empty():
		caller_display = caller_info.get("display", "")
		caller_url = (
			"%s:%d" % [caller_info.get("file", ""), caller_info.get("line", 0)]
		)
	elif caller_info is String and not caller_info.is_empty():
		caller_display = caller_info

	var caller_part := ""
	if not caller_display.is_empty():
		if use_bbcode and not caller_url.is_empty():
			# Escape both sides of the [url] tag: caller paths and node
			# names may contain brackets that would otherwise inject
			# BBCode (same rationale as get_source_string).
			caller_part = (
				" [url=%s]%s[/url]"
				% [escape_bbcode(caller_url), escape_bbcode(caller_display)]
			)
		else:
			caller_part = " " + caller_display

	# Escape the context string for BBCode output too: Godot node names
	# allow square brackets, which would otherwise break out of the markup.
	var safe_ctx := escape_bbcode(ctx_str) if use_bbcode else ctx_str
	var ctx_part := " " + safe_ctx if not safe_ctx.is_empty() else ""

	# [001.234s][F:123][D-Logger] [main.gd:10] [MyNode] - [WARN] Message
	return (
		"[%7.3fs][F:%d]%s%s%s - [%s] %s"
		% [
			time,
			frame,
			source_str,
			caller_part,
			ctx_part,
			level,
			msg,
		]
	)


static func format_log(
	msg: String,
	category: String,
	level: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant = null
) -> String:
	# Use cached time/frame if available, otherwise compute
	var seconds := (
		_cached_seconds
		if _cached_seconds >= 0.0
		else Time.get_ticks_msec() / 1000.0
	)
	var frames := (
		_cached_frames if _cached_frames >= 0 else Engine.get_frames_drawn()
	)

	var ctx_str := get_object_string(context) if context else ""
	var caller_info: Variant = (
		p_caller_info if p_caller_info != null else get_caller_info(level)
	)
	var source_str := get_source_string(prefix, category)

	# By default, use plain text for internal formatting (e.g. for console/file)
	return get_formatted_line(
		seconds, frames, source_str, caller_info, ctx_str, level, msg, false
	)


## Returns true when a ProjectSettings autoload entry (its raw string value)
## still points at the given expected path. Godot 4.4+ persists autoload
## paths as `*uid://...` references, so both the uid form and the res://
## path are accepted, with or without the leading `*` enabled marker. An
## entry the user repointed to another script is never considered ours.
static func is_autoload_ours(
	setting_value: String, expected_path: String
) -> bool:
	var current := setting_value.trim_prefix("*")
	if current == expected_path:
		return true
	var uid := ResourceLoader.get_resource_uid(expected_path)
	return uid != -1 and current == ResourceUID.id_to_text(uid)
