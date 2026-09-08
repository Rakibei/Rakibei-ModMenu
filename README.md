# Rakibei-ModMenu

Adds a **Mods** entry to the game's main menu and provides an in-game configuration editor for Godot Mod Loader mods.

## Features

* Adds a **Mods** button directly above **Exit Game**.
* Lists all currently active Godot Mod Loader mods with the mod name on the left and version on the right.
* Opens a detail page for each mod with its name, version, description, and website.
* Automatically detects `extra.godot.config_schema` from each mod's `manifest.json`.
* Generates controls for common schema types:
  * Boolean (`CheckButton`)
  * String (`LineEdit`)
  * String/number enums (`OptionButton`)
  * Integer/number (`SpinBox`)
  * Color strings using Mod Loader's `format: "color"` (`ColorPickerButton`)
  * Nested objects as grouped sections
* Saves changes through `ModLoaderConfig.update_config()`.
* Can reset schema-defined settings to their declared defaults before saving.
* Mods without configuration schemas still appear and have an information page.

## Notes

This mod edits only configuration values exposed through Godot Mod Loader config schemas. It does not enable, disable, install, or uninstall mods at runtime.
