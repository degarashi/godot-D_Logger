# D-Logger for Godot 4.x

A simple yet powerful custom logging plugin for Godot 4.3+.  
It utilizes the **Factory Pattern** and **Multicast** approach to support multiple output targets (Console, File) while providing flexible per-instance configuration.

---

## ✨ Features

* **Multicast Logging**: Simultaneously output to the **Console** and a **File** (`user://debug.log` by default).
* **Per-Instance Overrides**: Customize the prefix, log level, and console visibility for specific logger instances via `_init()`.
* **Project Settings Integration**: Manage global defaults (Prefix, Log Level, File Path, Enable/Disable) directly from Godot's Project Settings.
* **Rich Text Output**: Color-coded console logs for quick visual identification.
* **Automated Stack Tracing**: Displays the **filename** and **line number** of the caller for effortless debugging.
* **Category & Context Support**: Pass optional categories or object contexts to trace logs back to specific systems or nodes.

## 📁 Directory Structure

```text
res://addons/d_logger/
├── plugin.cfg          # Plugin definition
├── plugin.gd           # Lifecycle and ProjectSettings registration
├── constants.gd        # Shared constants and LogLevel enums
├── d_logger.gd         # Singleton entry point & Factory logic
├── d_logger_base.gd    # Base interface
├── d_logger_full.gd    # Console rich text implementation
├── d_logger_file.gd    # File system output implementation
└── d_logger_quiet.gd   # Fallback silent implementation
## Usage

1. Installation
- Place the "addons/d_logger/" folder into your project.
- Go to Project Settings > Plugins and enable "D-Logger".
- A singleton named "DLogger" will be registered automatically.

2. Basic Commands
You can call the following methods from any script in your project:

DLogger.debug("Debug information")
DLogger.info("General information")
DLogger.warn("Something looks suspicious")
DLogger.error("Fatal error!")

3. Toggling Output
You can globally control the log output via custom project settings (if implemented) or by modifying the d_logger.gd initialization logic.

## Extension
To add new output methods (e.g., logging to a file or sending to a server), create a new class inheriting from DLoggerBase and update the instantiation logic in d_logger.gd.
