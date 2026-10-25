extends Area2D
class_name BuildPad

signal selected(pad: BuildPad)

var is_occupied: bool = false

@onready var face: Polygon2D = $Face
@onready var mark: Path2D = $Mark
@onready var hint: Label = $Hint
@onready var _vacant_face_color: Color = face.color
@onready var _vacant_line_color: Color = mark.get("line_color")
@onready var _vacant_hint: String = hint.text


func _input_event(
	_viewport: Viewport, event: InputEvent, _shape_idx: int
) -> void:
	# Occupied pads still report taps, so the level can show the tower's range.
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected.emit(self)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			selected.emit(self)


func set_occupied() -> void:
	is_occupied = true
	face.color = Color(0.14, 0.25, 0.23, 1)
	mark.set("line_color", Color(0.45, 0.78, 0.62, 0.8))
	hint.text = ""


## Back to an empty pad, ready for another tower (after one is sold).
func set_vacant() -> void:
	is_occupied = false
	face.color = _vacant_face_color
	mark.set("line_color", _vacant_line_color)
	hint.text = _vacant_hint
