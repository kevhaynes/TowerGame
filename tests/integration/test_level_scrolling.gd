extends GutTest

## Scrolling a real level: the camera starts on the path's entry, a level
## larger than the screen can be dragged around, and a tap still selects a
## build pad while a drag does not. Input goes through the viewport, so the
## camera and build pad picking see it as they would on a device.

## Keeps the level from finishing (and saving progress) during the test.
const NEVER_FINISH_ENEMY_COUNT: int = 1000000
const NEVER_FAIL_HEALTH: float = 1000000.0
const LARGE_LEVEL: Vector2i = Vector2i(3840, 2160)

var _save_state: SaveStateFixture


func before_each() -> void:
	_save_state = SaveStateFixture.new()


func after_each() -> void:
	_save_state.restore()


## A level exactly one screen in size (the smallest allowed), which levels may
## set even though the default is larger.
func _one_screen() -> Vector2i:
	return Vector2i(LevelLayout.viewport_size())


func _load_level(size: Vector2i) -> Node:
	var definition: Dictionary = LevelCatalog.load_levels()[0]
	var level: Node = load(str(definition["scene"])).instantiate()
	level.set("level_size", size)
	add_child_autofree(level)
	level.get("_outcome").call("start", NEVER_FINISH_ENEMY_COUNT, NEVER_FAIL_HEALTH)
	return level


func _camera(level: Node) -> LevelCamera:
	return level.get("camera") as LevelCamera


func _mouse_button(level: Node, at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	if pressed:
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	level.get_viewport().push_input(event, true)


func _mouse_move(level: Node, from: Vector2, to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.relative = to - from
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	level.get_viewport().push_input(event, true)


## Where [param world] is on screen with the current camera.
func _screen_position(level: Node, world: Vector2) -> Vector2:
	return level.get_viewport().get_canvas_transform() * world


func _first_pad(level: Node) -> BuildPad:
	return (level.get("build_pads") as Node).get_child(0) as BuildPad


func _menu(level: Node) -> BuildMenu:
	return level.get("_build_menu") as BuildMenu


func test_one_screen_level_fills_the_screen_and_cannot_scroll() -> void:
	var level: Node = _load_level(_one_screen())
	var camera: LevelCamera = _camera(level)
	var centre: Vector2 = LevelCamera.clamp_centre(
		Vector2.ZERO, camera.get_view_size(), Vector2(_one_screen())
	)
	assert_eq(camera.position, centre)
	camera.pan_by(Vector2(-500, -500))
	assert_eq(camera.position, centre, "nothing beyond the screen to scroll to")


func test_large_level_starts_on_the_path_entry() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	var camera: LevelCamera = _camera(level)
	var entry: Vector2 = (level.get("_path_curve") as Curve2D).get_point_position(0)
	assert_eq(
		camera.position,
		LevelCamera.clamp_centre(entry, camera.get_view_size(), Vector2(LARGE_LEVEL))
	)


func test_large_level_ground_covers_the_whole_level() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	var ground := level.get_node("Ground") as LevelGround
	assert_eq(LevelLayout.level_size_of(ground.get_parent()), Vector2(LARGE_LEVEL))


func test_dragging_scrolls_a_large_level() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	var camera: LevelCamera = _camera(level)
	camera.pan_to(Vector2(LARGE_LEVEL) / 2.0)
	var start: Vector2 = camera.position
	_mouse_button(level, Vector2(1200, 700), true)
	_mouse_move(level, Vector2(1200, 700), Vector2(900, 500))
	_mouse_button(level, Vector2(900, 500), false)
	var expected: Vector2 = LevelCamera.clamp_centre(
		start + Vector2(300, 200), camera.get_view_size(), Vector2(LARGE_LEVEL)
	)
	assert_ne(camera.position, start)
	assert_eq(camera.position, expected)


func test_tapping_a_pad_selects_it() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	await wait_physics_frames(2)
	var at: Vector2 = _screen_position(level, _first_pad(level).global_position)
	_mouse_button(level, at, true)
	_mouse_button(level, at, false)
	await wait_physics_frames(2)
	assert_true(_menu(level).visible, "tap opens the build menu")


func test_dragging_from_a_pad_scrolls_without_selecting_it() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	var camera: LevelCamera = _camera(level)
	camera.pan_to(Vector2(LARGE_LEVEL) / 2.0)
	await wait_physics_frames(2)
	var at: Vector2 = _screen_position(level, _first_pad(level).global_position)
	var start: Vector2 = camera.position
	_mouse_button(level, at, true)
	_mouse_move(level, at, at + Vector2(-200, 0))
	_mouse_button(level, at + Vector2(-200, 0), false)
	await wait_physics_frames(2)
	assert_false(_menu(level).visible, "a pan is not a tap")
	assert_eq(camera.position, start + Vector2(200, 0))


func _touch(level: Node, index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	level.get_viewport().push_input(event, true)


func _touch_drag(level: Node, index: int, from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.relative = to - from
	level.get_viewport().push_input(event, true)


func test_pinching_on_a_pad_zooms_without_selecting_it() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	var camera: LevelCamera = _camera(level)
	camera.pan_to(Vector2(LARGE_LEVEL) / 2.0)
	await wait_physics_frames(2)
	var first: Vector2 = _screen_position(level, _first_pad(level).global_position)
	var second: Vector2 = first + Vector2(200, 0)
	# As on Android: the first finger also arrives as emulated mouse events.
	_touch(level, 0, first, true)
	_mouse_button(level, first, true)
	_touch(level, 1, second, true)
	_touch_drag(level, 1, second, second + Vector2(100, 0))
	_touch(level, 1, second + Vector2(100, 0), false)
	_touch(level, 0, first, false)
	_mouse_button(level, first, false)
	await wait_physics_frames(2)
	assert_almost_eq(camera.get_zoom_level(), 1.5, 0.0001, "200 px apart to 300 px")
	assert_false(_menu(level).visible, "a pinch is not a tap")


func test_mouse_wheel_zooms_a_level() -> void:
	var level: Node = _load_level(LARGE_LEVEL)
	var camera: LevelCamera = _camera(level)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP
	event.pressed = true
	event.position = Vector2(960, 540)
	level.get_viewport().push_input(event, true)
	assert_almost_eq(camera.get_zoom_level(), LevelCamera.WHEEL_ZOOM_STEP, 0.0001)


func test_one_screen_level_cannot_zoom_out() -> void:
	var level: Node = _load_level(_one_screen())
	var camera: LevelCamera = _camera(level)
	camera.zoom_at(0.5, Vector2(960, 540))
	assert_eq(camera.get_zoom_level(), 1.0)
