extends Node

const RAKIBEI_MODMENU_DIR := "Rakibei-ModMenu"
const RAKIBEI_MODMENU_LOG_NAME := "Rakibei-ModMenu:Main"

var mod_dir_path := ""
var extensions_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(RAKIBEI_MODMENU_DIR)
	install_script_extensions()

func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("Scenes/main_menu.gd"))

func _ready() -> void:
	ModLoaderLog.info("Ready!", RAKIBEI_MODMENU_LOG_NAME)
