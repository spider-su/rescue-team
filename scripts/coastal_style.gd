extends RefCounted
## Shared presentation resources; puzzle rules never depend on this module.
const INK = Color("#173f53")
const NAVY = Color("#19516a")
const PAPER = Color("#faf1df")
const LINE = Color("#d9ccb6")
const MUTED = Color("#657f86")
const TEAL = Color("#218a90")
const ORANGE = Color("#e97d28")
const BLUE = Color("#367fa6")
const GREEN = Color("#508764")
const VIOLET = Color("#72518e")
const FONT = preload("res://assets/fonts/Barlow-Regular.ttf")
const HEADING = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const HARBOR = preload("res://assets/coastal/harbor.png")
const BACKDROP = preload("res://assets/coastal/board-backdrop.png")
const VICTORY = preload("res://assets/coastal/victory.png")
const CREW = preload("res://assets/coastal/crew-atlas.png")
const PROPS = preload("res://assets/coastal/props-atlas.png")
const OLD_TOWN = preload("res://assets/old-town/location.png")
const RANGER_ART = preload("res://assets/old-town/ranger-atlas.png")

static func box(color: Color, border: Color = LINE, radius: int = 16, padding: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func button(control: Button, color: Color = PAPER, selected: bool = false) -> void:
	var border := ORANGE if selected else LINE
	control.add_theme_stylebox_override("normal", box(color, border, 15, 12))
	control.add_theme_stylebox_override("hover", box(color.lightened(0.06), TEAL, 15, 12))
	control.add_theme_stylebox_override("pressed", box(color.darkened(0.08), NAVY, 15, 12))
	control.add_theme_stylebox_override("disabled", box(Color("#eee6d7"), LINE, 15, 12))
	var focus := box(Color.TRANSPARENT, Color("#e8ac34"), 15, 0)
	focus.set_border_width_all(4)
	control.add_theme_stylebox_override("focus", focus)
	var text := Color.WHITE if color in [NAVY, TEAL, BLUE, VIOLET] else INK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		control.add_theme_color_override(state, text)
	control.add_theme_color_override("font_disabled_color", MUTED)
	control.add_theme_color_override("icon_disabled_color", MUTED)
	control.add_theme_font_override("font", HEADING)
	control.add_theme_font_size_override("font_size", 27)
	control.add_theme_constant_override("h_separation", 10)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func label(text: String, font_size: int = 25, heading: bool = false, color: Color = INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", HEADING if heading else FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func portrait(role: String) -> AtlasTexture:
	if role in ["ranger", "infected"]:
		return _ranger_region(role, false)
	var index: int = ["firefighter", "engineer", "civilian"].find(role)
	var texture := AtlasTexture.new()
	texture.atlas = CREW
	texture.region = Rect2(index * 512 + 48, 12, 448, 448)
	return texture

static func sprite(role: String) -> AtlasTexture:
	if role in ["ranger", "infected"]:
		return _ranger_region(role, true)
	var index: int = ["firefighter", "engineer", "civilian"].find(role)
	var texture := AtlasTexture.new()
	texture.atlas = CREW
	texture.region = Rect2(index * 512 + 112, 560, 320, 448)
	return texture

static func _ranger_region(role: String, full_body: bool) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RANGER_ART
	var cell := RANGER_ART.get_width() / 2
	var column := 0 if role == "ranger" else 1
	texture.region = Rect2(column * cell + 96, cell, cell - 160, cell) if full_body else Rect2(column * cell + 80, 0, cell - 160, cell - 160)
	return texture

static func prop(kind: String) -> AtlasTexture:
	var index: int = ["crate", "fire", "switch", "gate", "open_gate", "exit"].find(kind)
	var texture := AtlasTexture.new()
	texture.atlas = PROPS
	texture.region = Rect2((index % 3) * 512, (index / 3) * 512, 512, 512)
	return texture

static func picture(texture: Texture2D, height: float = 0.0) -> TextureRect:
	var result := TextureRect.new()
	result.texture = texture
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	result.custom_minimum_size.y = height
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.clip_contents = true
	return result
