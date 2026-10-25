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
	# A tap is a press and release: selecting on release lets the LevelCamera
	# turn a press into a pan instead (it then consumes the release). Touches
	# arrive as emulated mouse events, so they are not handled twice. Occupied
	# pads still report taps, so the level can open the tower's panel.
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
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
