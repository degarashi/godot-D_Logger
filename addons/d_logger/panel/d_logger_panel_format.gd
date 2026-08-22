class_name DLoggerPanelFormat
extends Object

## Static formatting helpers for the log panel display. Kept free of panel
## state (search, relative-time and selection are passed in as arguments) so
## the logic is unit-testable without a panel instance.

# Depth-based bracket colors (vim rainbow-brackets style). Dracula-inspired
# hues chosen to stay distinguishable from the level colors
# (gray/cyan/yellow/red) used for the rest of the line.
const RAINBOW_PALETTE: PackedStringArray = [
	"#ff5555", "#ffb86c", "#f1fa8c", "#50fa7b", "#8be9fd", "#bd93f9", "#ff79c6"
]

# Hue of the background drawn behind a hovered bracket and its matching
# counterpart (same family as the selection row background used by the
# panel). Alpha comes from the panel_bracket_highlight_opacity editor
# setting, resolved through bracket_hover_bg().
const BRACKET_HOVER_BASE_RGB := "#446868"
# Opacity (%) used when a caller does not pass an explicit hover background.
const DEFAULT_BRACKET_HOVER_OPACITY := (
	DLoggerConstants.DEFAULT_BRACKET_HIGHLIGHT
)


## Builds the hover-highlight background hex (#rrggbbaa) from the base hue
## and an opacity percentage (0-100). 40% reproduces the originally
## hardcoded "#44686868" look; 0% renders the highlight invisible.
## Color.to_html() omits the "#" so it is re-added for BBCode use.
static func bracket_hover_bg(opacity_percent: int) -> String:
	var c := Color(BRACKET_HOVER_BASE_RGB)
	c.a = clampf(opacity_percent / 100.0, 0.0, 1.0)
	return "#" + c.to_html(true)


## Computes the filter tag list for a log: category segments when present,
## otherwise the prefix (unless it is the default "D-Logger"), otherwise
## "Default".
static func get_log_tags(log_data: Dictionary) -> Array[String]:
	var category: String = log_data.get("category", "")
	if not category.is_empty():
		var tags: Array[String] = []
		for tag in category.split("|"):
			var t := tag.strip_edges()
			if not t.is_empty():
				tags.append(t)
		if not tags.is_empty():
			return tags

	var prefix: String = log_data.get("prefix", "")
	if not prefix.is_empty() and prefix != DLoggerConstants.DEFAULT_PREFIX:
		return [prefix]

	return ["Default"]


## Formats a log as plain text (no BBCode) for clipboard/copy operations.
static func format_log_plain(log_data: Dictionary) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var level: String = log_data.get("level", "DEBUG")
	var prefix: String = log_data.get("prefix", "")
	var category: String = log_data.get("category", "")
	var context_str: String = log_data.get("context_str", "")
	var caller_info = log_data.get("caller_info", {})
	var message: String = log_data.get("message", "")

	var source_str := DLoggerFunc.get_source_string(prefix, category, false)
	var formatted_msg := DLoggerFunc.get_formatted_line(
		time, frame, source_str, caller_info, context_str, level, message, false
	)

	var count: int = log_data.get("count", 1)
	if count > 1:
		formatted_msg += " (x{0})".format([count])

	return formatted_msg


## Pairs (), [], {} by strict same-type nesting (vim bracket-matching): a
## closer only pairs when the innermost open bracket has the same kind; a
## mismatched closer stays unpaired without disturbing the stack, so "([)]"
## pairs [] while "(" remains unmatched. Returns a bidirectional map
## {open_idx: close_idx, close_idx: open_idx}; unmatched brackets have no
## entry and therefore no hover-highlight target.
static func match_brackets(text: String) -> Dictionary[int, int]:
	var matches: Dictionary[int, int] = {}
	const OPEN := "([{"
	const CLOSE := ")]}"
	# x = char index, y = bracket kind (index into OPEN/CLOSE)
	var stack: Array[Vector2i] = []
	for i in text.length():
		var c := text[i]
		var open_kind := OPEN.find(c)
		if open_kind >= 0:
			stack.append(Vector2i(i, open_kind))
			continue
		var close_kind := CLOSE.find(c)
		if (
			close_kind >= 0
			and not stack.is_empty()
			and stack[-1].y == close_kind
		):
			matches[stack[-1].x] = i
			matches[i] = stack[-1].x
			stack.pop_back()
	return matches


## Colorizes (), [], {} in the message by nesting depth (vim rainbow-brackets
## style). Single pass: an opening bracket takes the color at the current
## depth then increments; a closing bracket decrements first (clamped at 0 so
## mismatched input cannot go negative) and takes the resulting depth's color.
## [] must be escaped as [lb]/[rb] (they would otherwise inject BBCode);
## () and {} are BBCode-safe literals and keep their own glyph — emitting
## them through [lb]/[rb] would visually turn them into square brackets.
## Same injection guarantee as DLoggerFunc.escape_bbcode(). All other
## characters pass through unchanged.
##
## When meta_prefix is non-empty every bracket glyph is additionally wrapped
## in "[url=<meta_prefix><char_index>]" so the panel can resolve hovered
## brackets from meta_hover_started/ended (the prefix carries the log index:
## "brk:<log>:"). When char_index is listed in hover_indices the glyph gets
## a BRACKET_HOVER background behind its depth color — used to light up
## a bracket pair while one of them is hovered. hover_bg overrides that
## default color ("" = DEFAULT_BRACKET_HOVER_OPACITY applied to the base).
static func rainbow_brackets(
	text: String,
	meta_prefix: String = "",
	hover_indices: Array = [],
	hover_bg: String = ""
) -> String:
	if hover_bg.is_empty():
		hover_bg = bracket_hover_bg(DEFAULT_BRACKET_HOVER_OPACITY)
	var parts := PackedStringArray()
	var depth := 0
	for i in text.length():
		var c := text[i]
		match c:
			"(", "[", "{":
				parts.append(
					_format_bracket(
						"[lb]" if c == "[" else c,
						depth,
						meta_prefix,
						i,
						hover_indices,
						hover_bg
					)
				)
				depth += 1
			")", "]", "}":
				depth = maxi(depth - 1, 0)
				parts.append(
					_format_bracket(
						"[rb]" if c == "]" else c,
						depth,
						meta_prefix,
						i,
						hover_indices,
						hover_bg
					)
				)
			_:
				parts.append(c)
	return "".join(parts)


## Renders a single bracket glyph: depth palette color, optional hover
## background and optional [url] meta wrapper (outermost so the whole
## glyph stays clickable/hoverable regardless of highlight state).
static func _format_bracket(
	glyph: String,
	depth: int,
	meta_prefix: String,
	char_index: int,
	hover_indices: Array,
	hover_bg: String
) -> String:
	var color := RAINBOW_PALETTE[depth % RAINBOW_PALETTE.size()]
	var body := "[color=%s]%s[/color]" % [color, glyph]
	if char_index in hover_indices:
		body = "[bgcolor=%s]%s[/bgcolor]" % [hover_bg, body]
	if not meta_prefix.is_empty():
		body = "[url=%s%d]%s[/url]" % [meta_prefix, char_index, body]
	return body


## Formats a log for the RichTextLabel display with BBCode: clickable source
## links, level colors, selection color, optional search highlighting and
## optional relative timestamps.
##
## When log_index >= 0 message brackets are additionally wrapped in
## "brk:<log_index>:<char_index>" links (bracket-pair hover support) and any
## char indices listed in bracket_hover get the hover background applied.
## hover_bg overrides that background color ("" = default opacity).
static func format_log(
	log_data: Dictionary,
	search: DLoggerSearch,
	relative_time: bool,
	max_time: float,
	is_selected: bool = false,
	log_index: int = -1,
	bracket_hover: Array = [],
	hover_bg: String = ""
) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var level: String = log_data.get("level", "DEBUG")
	var prefix: String = log_data.get("prefix", "")
	var category: String = log_data.get("category", "")
	var context_str: String = log_data.get("context_str", "")
	var caller_info = log_data.get("caller_info", {})
	var message: String = log_data.get("message", "")

	# Rainbow-color message brackets instead of plain escaping: the output is
	# still escaped ([lb]/[rb]) so user-provided text cannot inject markup
	# (e.g. [url=filter:...] link spoofing), but bracket nesting additionally
	# gets depth-based colors for readability. With log_index >= 0 each
	# bracket also becomes a hover-resolvable link (see rainbow_brackets).
	var meta_prefix := ""
	if log_index >= 0:
		meta_prefix = "brk:%d:" % log_index
	message = rainbow_brackets(message, meta_prefix, bracket_hover, hover_bg)

	# Highlight search keyword in the message text
	if not search.is_empty():
		message = search.highlight(message)

	# Convert to relative timestamp when enabled.
	if relative_time:
		time = time - max_time

	# Generate source string with clickable filter URLs matching actual filter
	# button texts (from get_log_tags). Must handle the case where the
	# displayed text (prefix "D-Logger") differs from the tag ("Default")
	# for category-less logs with default prefix.
	var log_tags: Array = log_data.get("_log_tags", [])
	var source_str: String
	if log_tags.is_empty():
		source_str = DLoggerFunc.get_source_string(prefix, category, true)
	elif category.is_empty() and prefix == DLoggerConstants.DEFAULT_PREFIX:
		# Show [D-Logger] but URL target = "Default" (the actual filter tag).
		# Escape both segments so a bracket in the tag/prefix cannot break
		# out of the [url=...] tag and inject arbitrary BBCode.
		source_str = (
			"[[url=filter:{0}]{1}[/url]]"
			. format(
				[
					DLoggerFunc.escape_bbcode(log_tags[0]),
					DLoggerFunc.escape_bbcode(prefix),
				]
			)
		)
	else:
		source_str = DLoggerFunc.get_source_string(prefix, category, true)

	var formatted_msg := DLoggerFunc.get_formatted_line(
		time, frame, source_str, caller_info, context_str, level, message, true
	)

	var count: int = log_data.get("count", 1)
	if count > 1:
		formatted_msg += " [b](x{0})[/b]".format([count])

	var text_color := ""
	if is_selected:
		text_color = "#ffffff"
	else:
		match level:
			"DEBUG":
				text_color = "gray"
			"INFO":
				text_color = "cyan"
			"WARN":
				text_color = "yellow"
			"ERROR":
				text_color = "red"

	var result: String
	if is_selected:
		result = ("[b][color={0}]{1}[/color][/b]".format(
			[text_color, formatted_msg]
		))
	elif not text_color.is_empty():
		var is_bold := level in ["INFO", "WARN", "ERROR"]
		if is_bold:
			result = ("[b][color={0}]{1}[/color][/b]".format(
				[text_color, formatted_msg]
			))
		else:
			result = ("[color={0}]{1}[/color]".format(
				[text_color, formatted_msg]
			))
	else:
		result = formatted_msg

	return result
