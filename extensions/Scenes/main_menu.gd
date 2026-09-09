extends "res://Scenes/main_menu.gd"

const MOD_MENU_CONFIG_NAME := "user_config"

var mod_menu_root: CenterContainer
var mod_menu_panel: PanelContainer
var mod_content: VBoxContainer
var mods_button: Button
var menu_title: Label
var menu_subtitle: Label
var back_button: Button
var reset_button: Button
var save_button: Button
var close_button: Button
var status_label: Label

var current_mod_id := ""
var current_mod_data: Variant = null
var current_schema: Dictionary = {}
var current_config: Variant = null
var pending_config_data: Dictionary = {}
var has_unsaved_changes := false


func _ready() -> void:
	super()
	_create_mod_menu()
	_add_mods_button()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and is_instance_valid(mod_menu_root) and mod_menu_root.visible:
		if not current_mod_id.is_empty():
			_show_mod_list_page()
		else:
			mod_menu_root.hide()
		get_viewport().set_input_as_handled()
		return

	super(event)


func _hide_all_menus() -> void:
	super()

	if is_instance_valid(mod_menu_root):
		mod_menu_root.hide()


func _add_mods_button() -> void:
	var button_container := get_node_or_null("VBoxButtons") as VBoxContainer
	var options_button := get_node_or_null("VBoxButtons/Options") as Button
	var exit_button := get_node_or_null("VBoxButtons/ExitGame") as Button

	if button_container == null:
		push_warning("[Rakibei-ModMenu] VBoxButtons was not found.")
		return

	mods_button = Button.new()
	mods_button.name = "Mods"
	mods_button.text = "Mods"
	mods_button.add_to_group("button_sound_default")
	_apply_main_button_style(mods_button, options_button)
	mods_button.pressed.connect(_on_mods_pressed)
	button_container.add_child(mods_button)

	# Put Mods directly above Exit Game.
	if exit_button != null:
		button_container.move_child(mods_button, exit_button.get_index())


func _create_mod_menu() -> void:
	mod_menu_root = CenterContainer.new()
	mod_menu_root.name = "ModMenu"
	mod_menu_root.z_index = 20
	mod_menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mod_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mod_menu_root)

	mod_menu_panel = PanelContainer.new()
	mod_menu_panel.name = "Panel"
	mod_menu_panel.custom_minimum_size = Vector2(820, 620)

	# Reuse one of the game's existing panel themes when available.
	if is_instance_valid(difficulty_selection_menu):
		mod_menu_panel.theme = difficulty_selection_menu.theme

	mod_menu_root.add_child(mod_menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	mod_menu_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var back_slot := Control.new()
	back_slot.custom_minimum_size = Vector2(100, 44)
	header.add_child(back_slot)

	back_button = Button.new()
	back_button.text = "Back"
	back_button.add_to_group("button_sound_default")
	back_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button.pressed.connect(_on_back_pressed)
	back_slot.add_child(back_button)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	menu_title = Label.new()
	menu_title.text = "Mods"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 34)
	title_box.add_child(menu_title)

	menu_subtitle = Label.new()
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.modulate = Color(1.0, 1.0, 1.0, 0.75)
	title_box.add_child(menu_subtitle)

	# Keep the title visually centered when Back is visible.
	var header_spacer := Control.new()
	header_spacer.custom_minimum_size = Vector2(100, 44)
	header.add_child(header_spacer)

	layout.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 440)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	mod_content = VBoxContainer.new()
	mod_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_content.add_theme_constant_override("separation", 3)
	scroll.add_child(mod_content)

	layout.add_child(HSeparator.new())

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	layout.add_child(footer)

	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(status_label)

	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.add_to_group("button_sound_default")
	reset_button.custom_minimum_size = Vector2(110, 44)
	reset_button.pressed.connect(_on_reset_pressed)
	footer.add_child(reset_button)

	save_button = Button.new()
	save_button.text = "Save"
	save_button.add_to_group("button_sound_default")
	save_button.custom_minimum_size = Vector2(110, 44)
	save_button.pressed.connect(_on_save_pressed)
	footer.add_child(save_button)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.add_to_group("button_sound_default")
	close_button.custom_minimum_size = Vector2(110, 44)
	close_button.pressed.connect(_on_close_mod_menu_pressed)
	footer.add_child(close_button)

	var options_button := get_node_or_null("VBoxButtons/Options") as Button
	_apply_secondary_button_style(back_button, options_button)
	_apply_secondary_button_style(reset_button, options_button)
	_apply_secondary_button_style(save_button, options_button)
	_apply_secondary_button_style(close_button, options_button)

	mod_menu_root.hide()
	_show_mod_list_page()


func _apply_main_button_style(button: Button, reference_button: Button) -> void:
	if reference_button != null:
		button.theme = reference_button.theme
		button.add_theme_font_size_override(
			"font_size",
			reference_button.get_theme_font_size("font_size")
		)
	else:
		button.add_theme_font_size_override("font_size", 36)


func _apply_secondary_button_style(button: Button, reference_button: Button) -> void:
	if reference_button != null:
		button.theme = reference_button.theme
	button.add_theme_font_size_override("font_size", 20)


func _on_mods_pressed() -> void:
	_hide_all_menus()
	_show_mod_list_page()
	mod_menu_root.show()


func _on_close_mod_menu_pressed() -> void:
	mod_menu_root.hide()


func _on_back_pressed() -> void:
	_show_mod_list_page()


func _show_mod_list_page() -> void:
	current_mod_id = ""
	current_mod_data = null
	current_schema = {}
	current_config = null
	pending_config_data = {}
	has_unsaved_changes = false

	menu_title.text = "Mods"
	menu_subtitle.text = "Active Godot Mod Loader mods"
	back_button.hide()
	reset_button.hide()
	save_button.hide()
	status_label.text = ""

	_clear_content()
	_refresh_mod_list()


func _refresh_mod_list() -> void:
	var mod_data_all := ModLoaderMod.get_mod_data_all()
	var mod_ids: Array = mod_data_all.keys()
	mod_ids.sort()

	var active_mod_count := 0

	for mod_id_variant in mod_ids:
		var mod_id := str(mod_id_variant)

		# get_mod_data_all() can contain inactive mods, so only show active ones.
		if not ModLoaderMod.is_mod_active(mod_id):
			continue

		# Config schemas produce an immutable default.json. Give every active,
		# configurable mod a writable config automatically so mod authors only
		# need to define their schema/default values.
		var mod_schema := ModLoaderConfig.get_config_schema(mod_id)
		if _schema_has_settings(mod_schema):
			_get_or_create_writable_config(mod_id)

		active_mod_count += 1
		var mod_data = mod_data_all[mod_id_variant]
		_add_mod_row(mod_id, mod_data)

	if active_mod_count == 0:
		var empty_label := Label.new()
		empty_label.text = "No active mods found."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 22)
		mod_content.add_child(empty_label)
	else:
		menu_subtitle.text = "%d active mod%s" % [
			active_mod_count,
			"" if active_mod_count == 1 else "s"
		]


func _add_mod_row(mod_id: String, mod_data: Variant) -> void:
	var display_name := _get_manifest_string(mod_data, "name", mod_id)
	var version := _get_manifest_string(mod_data, "version_number", "")
	var options_button := get_node_or_null("VBoxButtons/Options") as Button

	# Use one real vanilla main-menu Button for the entire row. The Labels are
	# only an overlay for left/right text and deliberately use an empty Theme so
	# they cannot inherit ButtonTheme's decorative Label styles.
	var row_button := Button.new()
	row_button.text = ""
	row_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row_button.add_to_group("button_sound_default")
	row_button.pressed.connect(_on_mod_row_pressed.bind(mod_id, mod_data))
	_apply_main_button_style(row_button, options_button)

	# Match the actual vanilla main-menu button dimensions. Anchored child
	# controls do not contribute to a Button's minimum height, so setting this
	# explicitly also prevents adjacent mod rows from overlapping.
	var row_width := 600.0
	var row_height := 64.0
	if options_button != null:
		var reference_height := maxf(
			options_button.size.y,
			options_button.get_combined_minimum_size().y
		)
		if reference_height > 0.0:
			row_height = reference_height
	row_button.custom_minimum_size = Vector2(row_width, row_height)

	var text_layer := Control.new()
	text_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_layer.clip_contents = true
	row_button.add_child(text_layer)

	var row_font_size := 24
	var row_font: Font = null
	var row_font_color := Color.WHITE
	if options_button != null:
		row_font = options_button.get_theme_font("font")
		row_font_color = options_button.get_theme_color("font_color")

	var name_label := Label.new()
	name_label.theme = Theme.new()
	name_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	name_label.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	name_label.text = display_name
	name_label.anchor_left = 0.0
	name_label.anchor_top = 0.0
	name_label.anchor_right = 0.78
	name_label.anchor_bottom = 1.0
	name_label.offset_left = 22.0
	name_label.offset_right = -10.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.focus_mode = Control.FOCUS_NONE
	name_label.add_theme_font_size_override("font_size", row_font_size)
	name_label.add_theme_color_override("font_color", row_font_color)
	if row_font != null:
		name_label.add_theme_font_override("font", row_font)
	text_layer.add_child(name_label)

	var version_label := Label.new()
	version_label.theme = Theme.new()
	version_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	version_label.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	version_label.text = "v%s" % version if not version.is_empty() else ""
	version_label.anchor_left = 0.78
	version_label.anchor_top = 0.0
	version_label.anchor_right = 1.0
	version_label.anchor_bottom = 1.0
	version_label.offset_left = 10.0
	version_label.offset_right = -22.0
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.add_theme_font_size_override("font_size", row_font_size)
	version_label.add_theme_color_override("font_color", row_font_color)
	if row_font != null:
		version_label.add_theme_font_override("font", row_font)
	text_layer.add_child(version_label)

	mod_content.add_child(row_button)


func _on_mod_row_pressed(mod_id: String, mod_data: Variant) -> void:
	current_mod_id = mod_id
	current_mod_data = mod_data
	current_schema = ModLoaderConfig.get_config_schema(mod_id)
	current_config = null
	pending_config_data = {}
	has_unsaved_changes = false

	# The Mod Loader's default config is intentionally read-only. If this mod is
	# still using default.json, create/select a writable user.json cloned from it.
	# Mods that already selected another non-default config are left untouched.
	if _schema_has_settings(current_schema):
		current_config = _get_or_create_writable_config(mod_id)
		if current_config != null:
			pending_config_data = current_config.data.duplicate(true)

	var display_name := _get_manifest_string(mod_data, "name", mod_id)
	var version := _get_manifest_string(mod_data, "version_number", "")
	var vnamespace := _get_manifest_string(mod_data, "namespace", "")

	menu_title.text = display_name
	var subtitle_parts: Array[String] = []
	if not version.is_empty():
		subtitle_parts.append("v%s" % version)
	if not vnamespace.is_empty():
		subtitle_parts.append("by %s" % vnamespace)
	menu_subtitle.text = "  |  ".join(subtitle_parts)

	back_button.show()
	status_label.text = ""

	_clear_content()
	_build_mod_details_page()


func _get_or_create_writable_config(mod_id: String) -> Variant:
	# Respect a mod/profile that is already using a writable named config.
	if ModLoaderConfig.has_current_config(mod_id):
		var active_config = ModLoaderConfig.get_current_config(mod_id)
		if active_config != null and str(active_config.name) != ModLoaderConfig.DEFAULT_CONFIG_NAME:
			return active_config

	var configs := ModLoaderConfig.get_configs(mod_id)
	if configs.is_empty():
		return null

	var writable_config: Variant = null

	# Reuse the menu-created config if it already exists. This preserves the
	# player's settings if their profile was temporarily switched back to default.
	if configs.has(MOD_MENU_CONFIG_NAME):
		writable_config = configs[MOD_MENU_CONFIG_NAME]
	else:
		var default_config = ModLoaderConfig.get_default_config(mod_id)
		if default_config == null:
			return null

		writable_config = ModLoaderConfig.create_config(
			mod_id,
			MOD_MENU_CONFIG_NAME,
			default_config.data.duplicate(true)
		)

	if writable_config == null:
		return null

	# Switch immediately for the running game...
	ModLoaderConfig.set_current_config(writable_config)

	# ...and persist the selection in the active Mod Loader user profile so the
	# mod receives this writable config on future launches as well.
	if ModLoaderUserProfile.is_initialized() and ModLoaderUserProfile.get_current() != null:
		if not ModLoaderUserProfile.set_mod_current_config(mod_id, writable_config):
			push_warning(
				"[Rakibei-ModMenu] Created config for %s, but could not save it as the profile's current config." % mod_id
			)

	return writable_config


func _build_mod_details_page() -> void:
	var description := _get_manifest_string(current_mod_data, "description", "")
	var website := _get_manifest_string(current_mod_data, "website_url", "")

	if not description.is_empty():
		var description_label := Label.new()
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.add_theme_font_size_override("font_size", 18)
		mod_content.add_child(description_label)

	if not website.is_empty():
		var website_button := LinkButton.new()
		website_button.text = website
		website_button.uri = website
		website_button.add_theme_font_size_override("font_size", 16)
		mod_content.add_child(website_button)

	if not description.is_empty() or not website.is_empty():
		mod_content.add_child(HSeparator.new())

	if not _schema_has_settings(current_schema):
		var no_settings := Label.new()
		no_settings.text = "This mod has no configurable settings."
		no_settings.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_settings.add_theme_font_size_override("font_size", 20)
		mod_content.add_child(no_settings)
		reset_button.hide()
		save_button.hide()
		return

	if current_config == null:
		var config_error := Label.new()
		config_error.text = "This mod has a config schema, but no current config could be loaded."
		config_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		config_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		config_error.add_theme_font_size_override("font_size", 20)
		mod_content.add_child(config_error)
		reset_button.hide()
		save_button.hide()
		return

	reset_button.show()
	save_button.show()

	var properties_variant = current_schema.get("properties", {})
	if properties_variant is Dictionary:
		_build_schema_properties(properties_variant, mod_content, [])


func _build_schema_properties(properties: Dictionary, parent: VBoxContainer, path_prefix: Array) -> void:
	for property_name_variant in properties.keys():
		var property_name := str(property_name_variant)
		var property_schema_variant = properties[property_name_variant]

		if not (property_schema_variant is Dictionary):
			continue

		var property_schema: Dictionary = property_schema_variant
		var property_path := path_prefix.duplicate()
		property_path.append(property_name)
		var property_type := _get_schema_type(property_schema)

		if property_type == "object":
			_add_object_section(property_name, property_schema, parent, property_path)
		else:
			_add_setting_row(property_name, property_schema, parent, property_path, property_type)


func _add_object_section(
	property_name: String,
	property_schema: Dictionary,
	parent: VBoxContainer,
	property_path: Array
) -> void:
	var title := Label.new()
	title.text = str(property_schema.get("title", _prettify_key(property_name)))
	title.add_theme_font_size_override("font_size", 22)
	parent.add_child(title)

	var description := str(property_schema.get("description", ""))
	if not description.is_empty():
		var description_label := Label.new()
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(1.0, 1.0, 1.0, 0.7)
		parent.add_child(description_label)

	var nested_margin := MarginContainer.new()
	nested_margin.add_theme_constant_override("margin_left", 18)
	parent.add_child(nested_margin)

	var nested_box := VBoxContainer.new()
	nested_box.add_theme_constant_override("separation", 10)
	nested_margin.add_child(nested_box)

	var nested_properties_variant = property_schema.get("properties", {})
	if nested_properties_variant is Dictionary and not nested_properties_variant.is_empty():
		_build_schema_properties(nested_properties_variant, nested_box, property_path)
	else:
		var empty_label := Label.new()
		empty_label.text = "No settings in this section."
		empty_label.modulate = Color(1.0, 1.0, 1.0, 0.7)
		nested_box.add_child(empty_label)

	parent.add_child(HSeparator.new())


func _add_setting_row(
	property_name: String,
	property_schema: Dictionary,
	parent: VBoxContainer,
	property_path: Array,
	property_type: String
) -> void:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)
	parent.add_child(block)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	block.add_child(row)

	var label := Label.new()
	label.text = str(property_schema.get("title", _prettify_key(property_name)))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	row.add_child(label)

	var current_value = _get_setting_value(property_path, property_schema)
	var control := _create_setting_control(property_schema, property_path, property_type, current_value)
	if control != null:
		row.add_child(control)
	else:
		var unsupported := Label.new()
		unsupported.text = "Unsupported: %s" % (property_type if not property_type.is_empty() else "unknown")
		unsupported.modulate = Color(1.0, 1.0, 1.0, 0.65)
		row.add_child(unsupported)

	var description := str(property_schema.get("description", ""))
	if not description.is_empty():
		var description_label := Label.new()
		description_label.text = description
		description_label.add_theme_font_size_override("font_size", 16)
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(1.0, 1.0, 1.0, 0.65)
		block.add_child(description_label)


func _create_setting_control(
	property_schema: Dictionary,
	property_path: Array,
	property_type: String,
	current_value: Variant
) -> Control:
	var enum_variant = property_schema.get("enum", null)
	if enum_variant is Array and not enum_variant.is_empty():
		return _create_enum_control(enum_variant, property_path, current_value)

	match property_type:
		"boolean":
			var toggle := CheckButton.new()
			toggle.button_pressed = bool(current_value)
			toggle.custom_minimum_size = Vector2(180, 40)
			toggle.toggled.connect(_on_bool_setting_changed.bind(property_path))
			return toggle

		"string":
			if str(property_schema.get("format", "")) == "color":
				var color_picker := ColorPickerButton.new()
				color_picker.custom_minimum_size = Vector2(220, 40)
				color_picker.color = _color_from_argb(str(current_value))
				color_picker.color_changed.connect(_on_color_setting_changed.bind(property_path))
				return color_picker

			var line_edit := LineEdit.new()
			line_edit.custom_minimum_size = Vector2(300, 40)
			line_edit.text = str(current_value)
			if property_schema.has("maxLength"):
				line_edit.max_length = int(property_schema["maxLength"])
			line_edit.text_changed.connect(_on_string_setting_changed.bind(property_path))
			return line_edit

		"integer", "number":
			var spin_box := SpinBox.new()
			spin_box.custom_minimum_size = Vector2(220, 40)
			spin_box.min_value = float(property_schema.get("minimum", -1000000000.0))
			spin_box.max_value = float(property_schema.get("maximum", 1000000000.0))
			spin_box.step = float(property_schema.get("multipleOf", 1.0 if property_type == "integer" else 0.01))
			spin_box.value = float(current_value)
			spin_box.value_changed.connect(
				_on_number_setting_changed.bind(property_path, property_type == "integer")
			)
			return spin_box

	return null


func _create_enum_control(enum_values: Array, property_path: Array, current_value: Variant) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(260, 40)

	var selected_index := 0
	for index in range(enum_values.size()):
		var enum_value = enum_values[index]
		option.add_item(str(enum_value))
		option.set_item_metadata(index, enum_value)
		if enum_value == current_value:
			selected_index = index

	option.select(selected_index)
	option.item_selected.connect(_on_enum_setting_changed.bind(option, property_path))
	return option


func _on_bool_setting_changed(value: bool, property_path: Array) -> void:
	_set_path_value(pending_config_data, property_path, value)
	_mark_unsaved()


func _on_string_setting_changed(value: String, property_path: Array) -> void:
	_set_path_value(pending_config_data, property_path, value)
	_mark_unsaved()


func _on_number_setting_changed(value: float, property_path: Array, is_integer: bool) -> void:
	_set_path_value(pending_config_data, property_path, int(round(value)) if is_integer else value)
	_mark_unsaved()


func _on_enum_setting_changed(index: int, option: OptionButton, property_path: Array) -> void:
	_set_path_value(pending_config_data, property_path, option.get_item_metadata(index))
	_mark_unsaved()


func _on_color_setting_changed(color: Color, property_path: Array) -> void:
	_set_path_value(pending_config_data, property_path, _color_to_argb(color))
	_mark_unsaved()


func _mark_unsaved() -> void:
	has_unsaved_changes = true
	status_label.text = "Unsaved changes"


func _on_reset_pressed() -> void:
	if current_config == null or current_schema.is_empty():
		return

	pending_config_data = current_config.data.duplicate(true)
	_apply_schema_defaults(current_schema, pending_config_data, [])
	has_unsaved_changes = true
	status_label.text = "Defaults loaded - press Save to apply"

	_clear_content()
	_build_mod_details_page()


func _on_save_pressed() -> void:
	if current_config == null:
		status_label.text = "No config is available to save."
		return

	current_config.data = pending_config_data.duplicate(true)
	var updated_config = ModLoaderConfig.update_config(current_config)

	if updated_config == null:
		status_label.text = "Could not save config. Check the Mod Loader log for validation errors."
		return

	# Reload the data that was actually written to disk before rebuilding
	# the editor. update_config() can leave the in-memory ModConfig stale.
	current_config = ModLoaderConfig.refresh_config_data(updated_config)
	pending_config_data = current_config.data.duplicate(true)
	has_unsaved_changes = false

	_clear_content()
	_build_mod_details_page()
	status_label.text = "Saved"


func _schema_has_settings(schema: Dictionary) -> bool:
	if schema.is_empty():
		return false

	var properties_variant = schema.get("properties", {})
	return properties_variant is Dictionary and not properties_variant.is_empty()


func _get_schema_type(schema: Dictionary) -> String:
	var type_variant = schema.get("type", "")

	if type_variant is String:
		return type_variant

	if type_variant is Array:
		for entry in type_variant:
			var entry_string := str(entry)
			if entry_string != "null":
				return entry_string

	return ""


func _get_setting_value(property_path: Array, property_schema: Dictionary) -> Variant:
	var lookup := _try_get_path_value(pending_config_data, property_path)

	if lookup[0]:
		return lookup[1]

	if property_schema.has("default"):
		return property_schema["default"]

	match _get_schema_type(property_schema):
		"boolean":
			return false
		"integer":
			return 0
		"number":
			return 0.0
		"string":
			return ""

	return null


func _try_get_path_value(root: Dictionary, property_path: Array) -> Array:
	var current: Variant = root

	for key_variant in property_path:
		if not (current is Dictionary):
			return [false, null]

		var key := str(key_variant)
		if not current.has(key):
			return [false, null]

		current = current[key]

	return [true, current]


func _set_path_value(root: Dictionary, property_path: Array, value: Variant) -> void:
	if property_path.is_empty():
		return

	var target: Dictionary = root

	for index in range(property_path.size() - 1):
		var key := str(property_path[index])
		if not target.has(key) or not (target[key] is Dictionary):
			target[key] = {}
		target = target[key]

	target[str(property_path[property_path.size() - 1])] = value


func _apply_schema_defaults(schema: Dictionary, target: Dictionary, path_prefix: Array) -> void:
	var properties_variant = schema.get("properties", {})
	if not (properties_variant is Dictionary):
		return

	for property_name_variant in properties_variant.keys():
		var property_name := str(property_name_variant)
		var property_schema_variant = properties_variant[property_name_variant]
		if not (property_schema_variant is Dictionary):
			continue

		var property_schema: Dictionary = property_schema_variant
		var property_path := path_prefix.duplicate()
		property_path.append(property_name)

		if property_schema.has("default"):
			_set_path_value(target, property_path, _duplicate_config_value(property_schema["default"]))
			continue

		if _get_schema_type(property_schema) == "object":
			_apply_schema_defaults(property_schema, target, property_path)


func _duplicate_config_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func _get_manifest_string(mod_data: Variant, property_name: String, fallback: String) -> String:
	if mod_data == null:
		return fallback

	var manifest = mod_data.get("manifest")
	if manifest == null:
		return fallback

	var value = manifest.get(property_name)
	if value == null:
		return fallback

	return str(value)


func _prettify_key(key: String) -> String:
	var words := key.replace("_", " ").replace("-", " ")
	return words.capitalize()


func _color_from_argb(value: String) -> Color:
	var hex := value.strip_edges().trim_prefix("#")

	if hex.length() == 8:
		var alpha := hex.substr(0, 2).hex_to_int() / 255.0
		var red := hex.substr(2, 2).hex_to_int() / 255.0
		var green := hex.substr(4, 2).hex_to_int() / 255.0
		var blue := hex.substr(6, 2).hex_to_int() / 255.0
		return Color(red, green, blue, alpha)

	if hex.length() == 6:
		var red := hex.substr(0, 2).hex_to_int() / 255.0
		var green := hex.substr(2, 2).hex_to_int() / 255.0
		var blue := hex.substr(4, 2).hex_to_int() / 255.0
		return Color(red, green, blue, 1.0)

	return Color.WHITE


func _color_to_argb(color: Color) -> String:
	return "#%02x%02x%02x%02x" % [
		int(round(clamp(color.a, 0.0, 1.0) * 255.0)),
		int(round(clamp(color.r, 0.0, 1.0) * 255.0)),
		int(round(clamp(color.g, 0.0, 1.0) * 255.0)),
		int(round(clamp(color.b, 0.0, 1.0) * 255.0))
	]


func _clear_content() -> void:
	for child in mod_content.get_children():
		# A menu row can call this from its own pressed signal. Detach it
		# immediately, but defer destruction until Godot has finished the
		# current signal/callback so locked Controls are never freed directly.
		mod_content.remove_child(child)
		child.queue_free()
