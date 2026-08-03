# D-Logger for Godot 4.7+

[日本語版 (Japanese)](README.ja.md) | **English**

![D-Logger Preview](doc_images/d_logger_image.jpg)

A lightweight, powerful, and extensible logging system for Godot Engine. D-Logger provides a centralized way to manage logs with support for multiple outputs, interactive filtering, and seamless integration with the Godot Editor.

---

## ✨ Features

- 📢 **Multicast Logging**: Simultaneously output logs to the console, a file, and the dedicated editor panel.
- 📁 **File Output with Rotation**: Log files auto-rotate at 10 MB, keeping a single `.1` backup generation.
- 🔍 **Interactive Bottom Panel**: A custom editor panel for real-time log inspection.
  - **Category Filtering**: Toggle display for specific categories. `Alt + Click` to "Solo" a category.
  - **Time Filtering**: View logs from the last 30s, 1m, or 5m.
  - **Level Filtering**: Quickly switch between DEBUG, INFO+, WARN+, and ERROR views.
  - **Search & Regex**: Filter logs in real-time with text search or regex patterns, with case-sensitive option.
  - **Log Stacking**: Consecutive identical log entries are stacked with a `(xN)` counter.
  - **Selection & Drag-to-Select**: Click, Ctrl+Click, or drag to select log entries; copy selected or all visible logs.
  - **Word Wrap & Font Size**: Toggle word wrap, adjust font size with Ctrl+MouseWheel.
  - **Relative Timestamps**: Switch between absolute timestamps and relative (time since latest log).
  - **Stats Bar**: Per-level log counts (DEBUG/INFO/WARN/ERROR) with displayed vs total count.
- ⚙️ **Project & Editor Settings**: Configure prefixes, log levels, and file paths directly from Godot's settings menus.
- 🧩 **Instance-based Configuration**: Create dedicated logger instances for specific subsystems (e.g., Network, AI) with unique prefixes, levels, and file paths.
- 🧬 **Node-based Loggers**: Use `DLoggerNode` or `DLoggerFinder` nodes to integrate logging into scene trees.
- 🎨 **Rich Text Output**: BBCode-supported log display in the editor panel with clickable file:line links and category filters.
- ⚡ **Performance Optimized**: Automatically skips complex string formatting when the log level is disabled. Time/frame values are cached once per dispatch for all downstream loggers.
- ⏱️ **Performance Benchmarking**: Measure any callable with `benchmark()`; results log at INFO (category `PERF`) and automatically escalate to WARN when they exceed the spike threshold (16 ms by default).
- 🛠️ **Debug-Only by Design**: Console and file outputs are automatically disabled in release builds; warning and error logs still propagate via `push_warning()`/`push_error()`.

---

## 📦 Installation

1. Copy the `addons/d_logger/` folder into your project's `addons/` directory.
2. Go to **Project > Project Settings > Plugins** and enable **D-Logger**.
3. A singleton named `DLogger` will be automatically registered as an Autoload.

---

## 🚀 Quick Start

### Basic Usage
Use the `DLogger` singleton from any script:

```gdscript
DLogger.info("Game started!")
DLogger.warn("Low memory detected.", [], "system")
DLogger.error("Failed to load level: {0}", ["level_1"])
```

### Advanced Formatting
Supports `String.format()` placeholders. You can pass an Array, Dictionary, or a single value:

```gdscript
# Using an Array
DLogger.info("Player {0} joined at {1}", ["Alice", Vector2(100, 200)])

# Using a Dictionary
DLogger.debug("Stats: HP={hp}, MP={mp}", {"hp": 100, "mp": 50})

# Using a Single Value
DLogger.debug("Value: {0}", 42)
```

### Context and Categories
Add metadata to your logs for easier tracking:

```gdscript
# cat: Category (String)
# ctx: Context (Object, usually 'self')
DLogger.debug("Player jumped", [], "gameplay", self)
# Output: [  1.234s][F:123][gameplay] [Player] - [DEBUG] Player jumped
```

---

## ⚙️ Configuration

Settings are managed via **Editor > Editor Settings > D-Logger** (values sync to Project Settings at runtime when applicable). The `prefix` setting is configured in **Project > Project Settings > Debug > D-Logger**:

| Setting | Type | Default | Location | Description |
|---------|------|---------|----------|-------------|
| `prefix` | String | `"D-Logger"` | Project Setting | Global prefix for all logs. |
| `enable_console_log` | Boolean | `false` | Editor Setting | Enable console output (Debug builds only). |
| `min_log_level` | Enum | `DEBUG` | Editor Setting | Minimum level to display (DEBUG, INFO, WARN, ERROR). |
| `enable_file_log` | Boolean | `false` | Editor Setting | Enable logging to a local file. |
| `log_file_path` | String | `user://debug.log` | Editor Setting | Path where the log file is saved. |
| `auto_activate_panel` | Boolean | `true` | Editor Setting | Show the D-Logger panel when debugging starts. |
| `auto_clear_on_start` | Boolean | `true` | Editor Setting | Clear the log panel when a new debug session starts. |
| `pause_on_error` | Boolean | `false` | Editor Setting | Automatically pause the game when an error is logged. |
| `panel_font_size` | Integer | `14` | Editor Setting | Font size for the panel log display (adjusted via Ctrl+ScrollWheel). |

---

## 🔧 Custom Logger Instances

For specific systems like Networking or AI, you can create dedicated logger instances. The constructor accepts prefix, minimum log level, console override, and file path:

```gdscript
var network_log: DLoggerClass

func _init():
    # DLoggerClass.new(prefix, min_level, console_enabled, file_path)
    network_log = DLoggerClass.new("NETWORK", DLoggerConstants.LogLevel.INFO)

func _ready():
    network_log.info("Connecting to server...")
```

### DLoggerNode (Scene-based Logger)

The autoload `DLogger` is a `DLoggerNode` which listens to `ProjectSettings.settings_changed` and reconfigures automatically when d_logger-related settings change. You can also drop `DLoggerNode` in a scene and configure it via `DLoggerInitParam` resource exports:

```
DLoggerNode (in scene tree)
  └─ DLoggerInitParam (exported Resource)
       ├─ prefix_override
       ├─ min_level_override
       ├─ console_enabled_override
       └─ file_path_override
```

### DLoggerFinder (Ancestor Search)

`DLoggerFinder` searches ancestor nodes for a logger via `DLoggerFunc.find_logger_from_ancestor()` and emits `on_log_found(logger)` when found. Useful for inheriting a parent's logger configuration.

---

## 📖 API Reference

### Logging Methods

All methods return `true`, allowing them to be used inside `assert()` for debug-only execution.

| # | Parameter | Type | Default | Description |
|---|-----------|------|---------|-------------|
| 1 | `msg` | `String` | — | Log message with optional `{0}`, `{name}` placeholders |
| 2 | `v` | `Variant` | `[]` | Values for `String.format()`: Array, Dictionary, or single value |
| 3 | `cat` | `String` | `""` | Category for filtering (pipe-separated `"foo\|bar"` supported) |
| 4 | `ctx` | `Object` | `null` | Context object (usually `self`) |
| 5 | `p` | `String` | `""` | Override prefix for this call only |

```gdscript
debug(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
info(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
warn(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
error(msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = "") -> bool
```

These same signatures are available on `DLoggerNode`, `DLoggerNodeBase` (as forwarding methods), and all `DLoggerBase` subclasses. (The underlying implementations additionally accept an internal `p_caller_info: Variant = null` parameter used by the dispatch chain; callers normally omit it.)

### Level Checks
Useful for skipping heavy calculations when logging is disabled.

- `is_debug_enabled() -> bool`
- `is_info_enabled() -> bool`
- `is_warn_enabled() -> bool`
- `is_error_enabled() -> bool`

### Benchmarking

Measure the execution time of any callable. Normal results are logged at INFO (category `PERF`); results at or above the spike threshold are logged at WARN instead. The callable's return value is passed through unchanged.

```gdscript
# Basic usage
var result: Variant = DLogger.benchmark("collision_update", func():
    return _update_collisions()
)

# Custom spike threshold (default: 16 ms)
DLogger.benchmark("level_load", func(): _load_level(), 100.0)
```

`benchmark()` measures synchronous execution only — it returns as soon as the callable yields, so it does not cover `await` spans. Also available on `DLoggerNode` and `DLoggerNodeBase` (forwarding).

### DLoggerClass Constructor

```gdscript
DLoggerClass.new(
    p_prefix: Variant = null,                      # Override prefix (null = use ProjectSetting)
    p_min_lvl: int = NOT_SPECIFIED,                 # Override min level (-1 = use ProjectSetting)
    p_console_enabled: Variant = null,              # Override console (null = use ProjectSetting)
    p_file_path: String = ""                        # Override file path ("" = use ProjectSetting)
) -> DLoggerClass
```

### DLoggerInitParam Resource

Exportable resource for inspector configuration of `DLoggerNode`:

```gdscript
prefix_override: String
min_level_override: int
console_enabled_override: Variant  # null = use ProjectSettings
file_path_override: String
```

### Editor Panel Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl + L** | Clear logs |
| **Ctrl + C** | Copy selected (or all visible) logs to clipboard |
| **Ctrl + Alt + S** | Save logs to a timestamped file in `user://` |
| **Ctrl + F** | Focus the search box |
| **Ctrl + MouseWheel** | Adjust font size |
| **1 / 2 / 3 / 4** | Switch level filter: DEBUG / INFO+ / WARN+ / ERROR |
| **Alt + Click** (category) | Solo that category filter |
| **Escape** | Clear current selection |
| **Right-drag** | Scroll the log view |
| **Drag** (left click) | Select multiple log entries |

---

## 📝 Output Format

Logs follow this structure:
```
[   time ][F:frame][source] [file:line] [context] - [LEVEL] message
```

When no category is specified, the default prefix (`D-Logger`) is used as the source label:
```
[  1.234s][F:123][D-Logger] - [INFO] Game started
```

When a category is given, it replaces the source label (or appends after a custom prefix):
```
[  1.234s][F:123][gameplay] [Player] - [DEBUG] Character spawned
```

When using a custom logger prefix with a category:
```
[  1.234s][F:123][NETWORK:auth] [server.gd:42] - [WARN] Connection timeout
```

**Note:** `[file:line]` (caller info) is only included for **WARN** and **ERROR** levels for performance reasons — `get_stack()` is not called for DEBUG/INFO logs.

---

## 💡 Pro Tips

### Performance Tip
If a log message requires expensive calculations, wrap it in a level check:

```gdscript
if DLogger.is_debug_enabled():
    DLogger.debug("Complex result: {0}", [do_heavy_calc()])
```

### Using with `assert()`
Since logging methods return `true`, you can use them in `assert` to ensure they only run in debug builds and provide context on failure:

```gdscript
assert(DLogger.debug("This only runs in debug builds"))
```

### Benchmarking Hot Spots
Quickly measure any function and get automatic spike warnings:

```gdscript
var result := DLogger.benchmark("physics_step", func() -> float:
    return _run_physics()
)
```

### Pipe-Separated Categories
Categories can contain multiple tags separated by `|` for multi-faceted filtering:

```gdscript
DLogger.info("Match started", [], "match|player|combat", self)
```

Each tag becomes an individual toggle button in the editor panel filter bar.

---

## 🐛 Troubleshooting

### Logs not appearing in console?
- Ensure the plugin is enabled in **Project Settings**.
- Check if `enable_console_log` is `true` in **Editor Settings**.
- Verify your `min_log_level`.
- Remember: D-Logger defaults to **silence in Release builds** (console and file outputs disabled; WARN/ERROR still go through `push_warning()`/`push_error()`).

### Log file not found?
- Check your `log_file_path` in settings.
- Default path is `user://debug.log`. You can find the `user://` folder via **Project > Open User Data Folder**.
