extends GutTest

## LevelCamera's clamping and drag handling. Input events are fed straight to
## the camera, so these tests don't depend on what else is on screen.

const VIEW: Vector2 = Vector2(1920, 1080)
const LARGE_LEVEL: Vector2 = Vector2(3840, 2160)

var _camera: LevelCamera


func before_each() -> void:
	_camera = add_child_autofree(LevelCamera.new())
	_camera.setup(LARGE_LEVEL, LARGE_LEVEL / 2.0)


func _press(at: Vector2, pressed: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	_camera._unhandled_input(event)


func _move(from: Vector2, to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.relative = to - from
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_camera._unhandled_input(event)


func test_clamp_keeps_the_view_inside_the_level() -> void:
	var inside := Vector2(2000, 1000)
	assert_eq(LevelCamera.clamp_centre(inside, VIEW, LARGE_LEVEL), inside)
	assert_eq(LevelCamera.clamp_centre(Vector2.ZERO, VIEW, LARGE_LEVEL), VIEW / 2.0)
	var beyond := Vector2(9999, 9999)
	assert_eq(LevelCamera.clamp_centre(beyond, VIEW, LARGE_LEVEL), LARGE_LEVEL - VIEW / 2.0)


func test_clamp_centres_an_axis_no_bigger_than_the_view() -> void:
	var wide_level := Vector2(3840, 1080)
	assert_eq(LevelCamera.clamp_centre(Vector2(100, 900), VIEW, wide_level), Vector2(960, 540))
	var wide_view := Vector2(2400, 1080)
	assert_eq(LevelCamera.clamp_centre(Vector2.ZERO, wide_view, VIEW), VIEW / 2.0, "wider phone")


func test_dragging_pans_the_level_with_the_finger() -> void:
	var start: Vector2 = _camera.position
	_press(Vector2(1000, 500))
	_move(Vector2(1000, 500), Vector2(900, 450))
	assert_true(_camera.is_dragging())
	assert_eq(_camera.position, start + Vector2(100, 50), "dragging left shows more to the right")
	_move(Vector2(900, 450), Vector2(800, 450))
	assert_eq(_camera.position, start + Vector2(200, 50))
	_press(Vector2(800, 450), false)
	assert_false(_camera.is_dragging())


func test_small_movement_stays_a_tap() -> void:
	var start: Vector2 = _camera.position
	_press(Vector2(1000, 500))
	_move(Vector2(1000, 500), Vector2(1000 + LevelCamera.DRAG_THRESHOLD - 1.0, 500))
	assert_false(_camera.is_dragging())
	assert_eq(_camera.position, start)


func test_panning_stops_at_the_level_edge() -> void:
	_press(Vector2.ZERO)
	_move(Vector2.ZERO, Vector2(10000, 10000))
	assert_eq(_camera.position, _camera.get_view_size() / 2.0)


func test_motion_without_a_held_button_ends_the_press() -> void:
	var start: Vector2 = _camera.position
	_press(Vector2(1000, 500))
	var event := InputEventMouseMotion.new()
	event.position = Vector2(500, 500)
	event.relative = Vector2(-500, 0)
	_camera._unhandled_input(event)
	assert_false(_camera.is_dragging())
	assert_eq(_camera.position, start)


func _send(event: InputEvent) -> void:
	_camera._input(event)
	_camera._unhandled_input(event)


func _touch(index: int, at: Vector2, pressed: bool = true) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	_send(event)


func _drag(index: int, from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.relative = to - from
	_send(event)


func _wheel(button: MouseButton, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	_camera._unhandled_input(event)


func _screen_centre() -> Vector2:
	return _camera.get_viewport_rect().size / 2.0


## The level point shown at [param screen_point].
func _level_point_at(screen_point: Vector2) -> Vector2:
	return _camera.position + (screen_point - _screen_centre()) / _camera.get_zoom_level()


func test_zoom_out_limit_fills_the_screen() -> void:
	assert_eq(LevelCamera.min_zoom_for(VIEW, LARGE_LEVEL), 0.5, "whole 3840x2160 level fits")
	assert_eq(LevelCamera.min_zoom_for(VIEW, VIEW), 1.0, "one-screen level can't zoom out")
	assert_almost_eq(LevelCamera.min_zoom_for(VIEW, Vector2(2880, 1620)), 0.6667, 0.001)
	assert_eq(
		LevelCamera.min_zoom_for(VIEW, Vector2(3840, 1080)), 1.0, "level only one screen tall"
	)
	assert_eq(LevelCamera.min_zoom_for(Vector2(2400, 1080), VIEW), 1.0, "never forced to zoom in")
	assert_eq(LevelCamera.min_zoom_for(VIEW, Vector2(7680, 4320)), LevelCamera.MIN_ZOOM)


func test_zoom_keeps_the_point_under_the_fingers_in_place() -> void:
	var screen_point: Vector2 = _screen_centre() + Vector2(200, 100)
	var before: Vector2 = _level_point_at(screen_point)
	_camera.zoom_at(1.5, screen_point)
	assert_eq(_camera.get_zoom_level(), 1.5)
	assert_almost_eq(_level_point_at(screen_point).x, before.x, 0.01)
	assert_almost_eq(_level_point_at(screen_point).y, before.y, 0.01)


func test_zoom_stays_within_its_limits() -> void:
	_camera.zoom_at(100.0, _screen_centre())
	assert_eq(_camera.get_zoom_level(), LevelCamera.MAX_ZOOM)
	_camera.zoom_at(0.01, _screen_centre())
	assert_almost_eq(_camera.get_zoom_level(), _camera.get_min_zoom(), 0.0001)
	assert_eq(
		_camera.position,
		LevelCamera.clamp_centre(_camera.position, _camera.get_view_size(), LARGE_LEVEL),
		"zoomed-out view stays inside the level"
	)


func test_mouse_wheel_zooms_in_and_out() -> void:
	_wheel(MOUSE_BUTTON_WHEEL_UP, _screen_centre())
	assert_almost_eq(_camera.get_zoom_level(), LevelCamera.WHEEL_ZOOM_STEP, 0.0001)
	_wheel(MOUSE_BUTTON_WHEEL_DOWN, _screen_centre())
	assert_almost_eq(_camera.get_zoom_level(), 1.0, 0.0001)


func test_pinch_zooms_by_the_change_in_finger_spread() -> void:
	var centre: Vector2 = _screen_centre()
	_touch(0, centre + Vector2(-200, 0))
	_touch(1, centre + Vector2(200, 0))
	assert_true(_camera.is_pinching())
	assert_true(_camera.is_dragging(), "a pinch is never a tap")
	_drag(1, centre + Vector2(200, 0), centre + Vector2(300, 0))
	_drag(0, centre + Vector2(-200, 0), centre + Vector2(-300, 0))
	assert_almost_eq(_camera.get_zoom_level(), 1.5, 0.0001, "400 px apart to 600 px")
	_drag(0, centre + Vector2(-300, 0), centre + Vector2(-150, 0))
	assert_almost_eq(_camera.get_zoom_level(), 1.125, 0.0001, "600 px apart to 450 px")
	_touch(1, centre + Vector2(300, 0), false)
	_touch(0, centre + Vector2(-150, 0), false)
	assert_false(_camera.is_pinching())


func test_pinch_zooms_about_the_point_between_the_fingers() -> void:
	var centre: Vector2 = _screen_centre()
	var first: Vector2 = centre + Vector2(0, -100)
	var second: Vector2 = centre + Vector2(200, -100)
	var midpoint: Vector2 = (first + second) / 2.0
	var before: Vector2 = _level_point_at(midpoint)
	_touch(0, first)
	_touch(1, second)
	_drag(1, second, second + Vector2(100, 0))
	_drag(0, first, first - Vector2(100, 0))
	assert_almost_eq(_camera.get_zoom_level(), 2.0, 0.0001)
	assert_almost_eq(_level_point_at(midpoint).x, before.x, 0.01)
	assert_almost_eq(_level_point_at(midpoint).y, before.y, 0.01)


func test_first_finger_mouse_emulation_does_not_pan_during_a_pinch() -> void:
	var centre: Vector2 = _screen_centre()
	_touch(0, centre)
	_press(centre)
	_touch(1, centre + Vector2(300, 0))
	var start: Vector2 = _camera.position
	_move(centre, centre + Vector2(-100, 0))
	assert_eq(_camera.position, start)
