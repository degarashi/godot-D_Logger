# D-Logger for Godot 4.x

A simple yet powerful custom logging plugin for Godot 4.3+.
It utilizes the **Factory Pattern** to switch between detailed logging during development and a high-performance "quiet" mode for release builds.

---

## ✨ Features

* **Real-time Customization**: Change your log prefix and toggle logging on/off directly from **Project Settings**.
* **Rich Text Output**: Uses `print_rich` for color-coded logs by level (Debug, Info, Warn, Error).
* **Automated Stack Tracing**: Automatically appends the **filename** and **line number** of the caller for faster debugging.
* **Factory Pattern**: Minimizes performance overhead by swapping the logger instance entirely when disabled.

## 📁 Directory Structure

```text
res://addons/d_logger/
├── plugin.cfg          # Plugin definition
├── plugin.gd           # Plugin lifecycle and settings registration
├── d_logger.gd         # Singleton entry point (Autoload)
├── d_logger_base.gd    # Base class for logging implementations
├── d_logger_full.gd    # Implementation for detailed logging
└── d_logger_quiet.gd   # Implementation for minimal/silent logging

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
