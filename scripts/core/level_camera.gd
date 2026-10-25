extends Camera2D
class_name LevelCamera

## Scrolls and zooms a level. Drag with a finger (or the mouse) to pan; pinch
## with two fingers (or use the mouse wheel or a trackpad pinch) to zoom about
## the point between them. The view never leaves the level, and on an axis
## where the level is no bigger than the screen it stays centred. A press that
## barely moves is a tap, so build pads still respond to it; one that becomes a
## pan or pinch is consumed so its release doesn't select a pad. The first
## finger also arrives as emulated mouse events
## (input_devices/pointing/emulate_mouse_from_touch, on by default), which pan.

## How far (viewport px) a press must move before it pans instead of tapping.
const DRAG_THRESHOLD: float = 18.0
## Furthest zoom out: a whole MAX_LEVEL_SIZE level on one screen. Zooming out
## also stops once the level fills the screen, and never goes below 1 on a
## level that only fills the screen at 1.
const MIN_ZOOM: float = 0.5
## Furthest zoom in.
const MAX_ZOOM: float = 2.0
## Zoom change per mouse wheel notch.
const WHEEL_ZOOM_STEP: float = 1.1

var level_size: Vector2 = Vector2.ZERO

var _is_pressed: bool = false
var _is_dragging: bool = false
var _press_position: Vector2
## Fingers on the screen by touch index: viewport position now, and before the
## latest event, so a pinch can compare the two.
var _touches: Dictionary = {}
var _previous_touches: Dictionary = {}


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)


## Sets the scrollable area and centres the view on [param focus] (as far as
## the level's edges allow).
func setup(size: Vector2, focus: Vector2) -> void:
	level_size = size
	zoom = Vector2.ONE * clampf(get_zoom_level(), get_min_zoom(), MAX_ZOOM)
	pan_to(focus)


func pan_to(centre: Vector2) -> void:
	position = clamp_centre(centre, get_view_size(), level_size)


## Moves the view with a drag of [param screen_delta] viewport pixels, so the
## level follows the finger.
func pan_by(screen_delta: Vector2) -> void:
	pan_to(position - screen_delta / zoom)


## Zooms to [param zoom_level] (kept within the zoom limits), keeping the level
## point under [param screen_point] where it is on screen.
func zoom_at(zoom_level: float, screen_point: Vector2) -> void:
	var from_centre: Vector2 = screen_point - get_viewport_rect().size / 2.0
	var anchor: Vector2 = position + from_centre / get_zoom_level()
	var clamped: float = clampf(zoom_level, get_min_zoom(), MAX_ZOOM)
	zoom = Vector2(clamped, clamped)
	pan_to(anchor - from_centre / clamped)


func get_zoom_level() -> float:
	return zoom.x


## The furthest this level can zoom out on the current screen.
func get_min_zoom() -> float:
	return min_zoom_for(get_viewport_rect().size, level_size)


## The furthest a level of [param size] can zoom out on [param screen]: until
## it just fills the screen, but not below MIN_ZOOM, and not below 1 for a
## level no bigger than the screen.
static func min_zoom_for(screen: Vector2, size: Vector2) -> float:
	if size.x <= 0.0 or size.y <= 0.0:
		return 1.0
	var fill: float = maxf(screen.x / size.x, screen.y / size.y)
	return clampf(fill, MIN_ZOOM, 1.0)


## The size of the level area on screen.
func get_view_size() -> Vector2:
	return get_viewport_rect().size / zoom


func is_dragging() -> bool:
	return _is_dragging


func is_pinching() -> bool:
	return _touches.size() >= 2


## The camera centre nearest [param centre] that keeps a view of
## [param view_size] inside a level of [param size].
static func clamp_centre(centre: Vector2, view_size: Vector2, size: Vector2) -> Vector2:
	return Vector2(
		_clamp_axis(centre.x, view_size.x, size.x), _clamp_axis(centre.y, view_size.y, size.y)
	)


static func _clamp_axis(centre: float, view: float, size: float) -> float:
	if view >= size:
		return size / 2.0
	return clampf(centre, view / 2.0, size - view / 2.0)


## Tracks every finger, even over the UI, so a release the UI takes can't
## leave a finger stuck down. Zooming itself happens in _unhandled_input.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
		else:
			_touches.erase(touch.index)
		_previous_touches = _touches.duplicate()
		if is_pinching():
			# A pinch is never a tap: consume the first finger's release.
			_is_dragging = true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_previous_touches = _touches.duplicate()
		_touches[drag.index] = drag.position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _is_pressed:
		_on_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventScreenDrag and is_pinching():
		_pinch()
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		var gesture := event as InputEventMagnifyGesture
		zoom_at(get_zoom_level() * gesture.factor, gesture.position)
		get_viewport().set_input_as_handled()


func _on_mouse_button(button: InputEventMouseButton) -> void:
	if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_at(get_zoom_level() * WHEEL_ZOOM_STEP, button.position)
		get_viewport().set_input_as_handled()
		return
	if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_at(get_zoom_level() / WHEEL_ZOOM_STEP, button.position)
		get_viewport().set_input_as_handled()
		return
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_is_pressed = true
		_is_dragging = is_pinching()
		_press_position = button.position
		return
	_is_pressed = false
	if _is_dragging:
		_is_dragging = false
		get_viewport().set_input_as_handled()


func _on_mouse_motion(motion: InputEventMouseMotion) -> void:
	if not motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		# The release went to the UI, so this press is over.
		_is_pressed = false
		_is_dragging = false
		return
	if is_pinching():
		# The first finger's emulated motion; the pinch moves the view.
		get_viewport().set_input_as_handled()
		return
	if _is_dragging:
		pan_by(motion.relative)
	elif motion.position.distance_to(_press_position) >= DRAG_THRESHOLD:
		_is_dragging = true
		pan_by(motion.position - _press_position)
	if _is_dragging:
		get_viewport().set_input_as_handled()


## Zooms by how much the first two fingers spread or closed since the last
## event, about the point between them, and pans with that point.
func _pinch() -> void:
	var indices: Array = _touches.keys()
	indices.sort()
	var first: Vector2 = _touches[indices[0]]
	var second: Vector2 = _touches[indices[1]]
	var first_before: Vector2 = _previous_touches.get(indices[0], first)
	var second_before: Vector2 = _previous_touches.get(indices[1], second)
	var distance_before: float = first_before.distance_to(second_before)
	if distance_before <= 0.0:
		return
	var midpoint: Vector2 = (first + second) / 2.0
	pan_by(midpoint - (first_before + second_before) / 2.0)
	zoom_at(get_zoom_level() * first.distance_to(second) / distance_before, midpoint)


func _on_viewport_size_changed() -> void:
	zoom_at(get_zoom_level(), get_viewport_rect().size / 2.0)
