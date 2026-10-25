extends Node2D

## Root script of every level scene. Level scenes inherit level.tscn and add
## their own layout: set level_size, draw the "Path" (a LevelPath) and add
## BuildPad instances under "BuildPads". Name, order, starting credits, health and enemy waves
## come from the data/levels JSON whose "scene" points at the level scene.

const PLAY_TEXT: String = "PLAY"
const PAUSE_TEXT: String = "PAUSE"
const PAUSED_AT_START_TEXT: String = "PAUSED - SURVEY THE MAP, THEN PRESS PLAY"
const PAUSED_TEXT: String = "PAUSED"
const WAVE_TEXT: String = "WAVE %d / %d"
const CREDITS_TEXT: String = "%d CR"
const HEALTH_TEXT: String = "%d / %d HP"
## The tower shown on a build pad while waiting for the second tap to build it.
const BUILD_PREVIEW_MODULATE: Color = Color(1, 1, 1, 0.5)
## Meta key on a built tower holding the credits paid for it, which its sell
## refund is based on.
const PURCHASE_COST_META: StringName = &"purchase_cost"

## The level's size in pixels: the area the ground covers and the camera
## scrolls over, from the top-left origin. At least one screen (the project
## viewport) and at most LevelLayout.MAX_LEVEL_SIZE.
@export var level_size: Vector2i = LevelLayout.DEFAULT_LEVEL_SIZE

@onready var level_path: Path2D = $Path
@onready var camera: LevelCamera = $Camera
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var towers_container: Node2D = $Towers
@onready var build_pads: Node2D = $BuildPads
@onready var enemies_container: Node2D = $Enemies
@onready var level_title: Label = $Hud/LevelTitle
@onready var levels_button: Button = $Hud/LevelsButton
@onready var pause_button: Button = $Hud/PauseButton
@onready var pause_banner: Label = $Hud/PauseBanner
@onready var wave_label: Label = $Hud/WaveLabel
@onready var credits_label: Label = $Hud/CreditsLabel
@onready var health_label: Label = $Hud/HealthLabel

var _levels: Array[Dictionary] = []
var _level: Dictionary = {}
var _tower_definitions: Array[Dictionary] = []
var _research_tree: ResearchTree
var _path_curve: Curve2D
var _selected_build_pad: BuildPad
var _build_menu: BuildMenu
## Opens when a built tower is tapped, to sell it.
var _tower_panel: TowerPanel
var _build_preview: Sprite2D
## Shared by the build preview and by tapping a built tower.
var _range_indicator: RangeIndicator
## The pad whose built tower's range and panel are showing, or null.
var _range_shown_pad: BuildPad
## Built towers by the BuildPad they stand on.
var _towers_by_pad: Dictionary = {}
var _result_panel: LevelResultPanel
## Remaining enemies and level health, started from the level's health.
var _outcome := LevelOutcomeTracker.new()
var _spawner: WaveSpawner
## Enemy definitions by id, loaded once when the level starts.
var _enemy_definitions: Dictionary = {}
var _spawned_count: int = 0
## This level's credits, created from starting_credits each time the level
## loads, so nothing carries over to the next level.
var _wallet: Wallet
var _is_paused: bool = false
var _has_started: bool = false
var _is_finished: bool = false


func _ready() -> void:
	levels_button.pressed.connect(_go_to_level_select)
	pause_button.pressed.connect(toggle_pause)
	_outcome.health_changed.connect(_on_health_changed)
	# Levels open paused so the player can survey the map and build first.
	set_paused(true)

	_levels = LevelCatalog.load_levels()
	_level = LevelCatalog.find_level_by_scene(_levels, scene_file_path)
	if _level.is_empty():
		push_error("No level definition in data/levels uses the scene %s." % scene_file_path)
		return
	GameState.current_level_id = str(_level["id"])
	level_title.text = str(_level["display_name"]).to_upper()

	if level_path.curve == null or level_path.curve.point_count < 2:
		push_error("Level %s has no path; draw one on its Path node." % _level["id"])
		return
	_path_curve = LevelLayout.world_curve(level_path, self)
	# Start on the entry, where the first enemies appear.
	camera.setup(Vector2(level_size), _path_curve.get_point_position(0))
	_connect_build_pads()

	_wallet = Wallet.new(int(_level["starting_credits"]))
	_wallet.credits_changed.connect(_on_credits_changed)
	_on_credits_changed(_wallet.credits)

	_tower_definitions = DefinitionCatalog.load_directory(DefinitionCatalog.TOWERS_DIRECTORY)
	_research_tree = ResearchTree.load_tree()
	_build_menu = BuildMenu.new()
	_build_menu.name = "BuildMenu"
	add_child(_build_menu)
	_build_menu.tower_selected.connect(_on_tower_selected)
	_build_menu.tower_previewed.connect(_on_tower_previewed)
	_build_menu.closed.connect(_hide_range_and_preview)
	_tower_panel = TowerPanel.new()
	_tower_panel.name = "TowerPanel"
	add_child(_tower_panel)
	_tower_panel.sell_requested.connect(_on_sell_requested)
	_tower_panel.closed.connect(_hide_range_and_preview)
	_create_build_preview()

	_result_panel = LevelResultPanel.new()
	_result_panel.name = "LevelResultPanel"
	add_child(_result_panel)
	_result_panel.next_level_requested.connect(_on_next_level_requested)
	_result_panel.retry_requested.connect(_on_retry_requested)
	_result_panel.level_select_requested.connect(_go_to_level_select)
	_result_panel.research_requested.connect(_on_research_requested)

	_spawner = WaveSpawner.new(_load_waves())
	if _spawner.get_total_spawn_count() == 0:
		push_error("Level %s has no valid enemies to spawn." % _level["id"])
		_spawner = null
		return
	_outcome.start(_spawner.get_total_spawn_count(), float(_level["health"]))
	_update_wave_label()


func _process(delta: float) -> void:
	if _spawner == null or _is_paused or _is_finished:
		return
	for enemy_id: String in _spawner.advance(delta):
		_spawn_enemy(enemy_id)
	_update_wave_label()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_node_ready():
		set_paused(true)


func is_paused() -> bool:
	return _is_paused


func toggle_pause() -> void:
	set_paused(not _is_paused)


## Freezes or resumes the level world (enemies, towers, projectiles and
## effects). The HUD, build menu and build pads keep working while paused, so
## towers can be placed; they start acting when play resumes.
func set_paused(paused: bool) -> void:
	if _is_finished:
		return
	_is_paused = paused
	_has_started = _has_started or not paused
	var mode: ProcessMode = PROCESS_MODE_DISABLED if paused else PROCESS_MODE_INHERIT
	for container: Node in [enemies_container, towers_container, projectile_container]:
		container.process_mode = mode
	pause_button.text = PLAY_TEXT if paused else PAUSE_TEXT
	pause_banner.visible = paused
	pause_banner.text = PAUSED_TEXT if _has_started else PAUSED_AT_START_TEXT


func _finish_level() -> void:
	set_paused(false)
	_is_finished = true
	pause_button.disabled = true
	_build_menu.close()
	_tower_panel.close()


func _connect_build_pads() -> void:
	for child: Node in build_pads.get_children():
		if child is BuildPad:
			(child as BuildPad).selected.connect(_on_build_pad_selected)


## The level's waves with any spawn of an unloadable enemy removed, so a bad
## enemy definition can't leave the level waiting for an enemy that never comes.
func _load_waves() -> Array:
	var waves: Array = []
	for wave: Dictionary in _level["waves"]:
		var spawns: Array = []
		for spawn: Dictionary in wave["spawns"]:
			var enemy_id: String = str(spawn["enemy"])
			if not _enemy_definitions.has(enemy_id):
				_enemy_definitions[enemy_id] = DefinitionCatalog.load_enemy(enemy_id)
			if not (_enemy_definitions[enemy_id] as Dictionary).is_empty():
				spawns.append(spawn)
		waves.append({WaveSpawner.SPAWNS_KEY: spawns})
	return waves


func _spawn_enemy(enemy_id: String) -> void:
	var definition: Dictionary = _enemy_definitions[enemy_id]
	var enemy := PathEnemy.new()
	enemy.name = "%sEnemy%d" % [enemy_id.to_pascal_case(), _spawned_count]
	enemy.texture = ResourceLoader.load(str(definition["sprite"])) as Texture2D
	enemy.set_meta("definition", definition)
	enemies_container.add_child(enemy)
	_spawned_count += 1
	SaveManager.record_enemy_encounter(enemy_id)
	if not enemy.configure(definition, _path_curve):
		# Count it as gone so the wave and the level can still finish.
		enemy.queue_free()
		_spawner.notify_enemy_resolved()
		_handle_outcome(_outcome.record_kill())
		return
	enemy.killed.connect(_on_enemy_killed)
	enemy.escaped.connect(_on_enemy_escaped)


func _on_credits_changed(credits: int) -> void:
	credits_label.text = CREDITS_TEXT % credits
	if _build_menu != null and _build_menu.visible:
		_build_menu.set_credits(credits)


func get_credits() -> int:
	return _wallet.credits if _wallet != null else 0


func _on_health_changed(health: float, max_health: float) -> void:
	health_label.text = HEALTH_TEXT % [ceili(health), ceili(max_health)]


func _update_wave_label() -> void:
	wave_label.text = WAVE_TEXT % [_spawner.get_wave_number(), _spawner.get_wave_count()]


func _on_enemy_killed(enemy: PathEnemy) -> void:
	_wallet.earn(enemy.bounty)
	_spawner.notify_enemy_resolved()
	_update_wave_label()
	_handle_outcome(_outcome.record_kill())


func _on_enemy_escaped(enemy: PathEnemy) -> void:
	_spawner.notify_enemy_resolved()
	_update_wave_label()
	_handle_outcome(_outcome.record_escape(enemy.base_damage))


func _handle_outcome(outcome: LevelOutcomeTracker.Outcome) -> void:
	if _is_finished:
		return
	match outcome:
		LevelOutcomeTracker.Outcome.COMPLETE:
			var level_id: String = str(_level["id"])
			var stars: int = _outcome.get_stars()
			SaveManager.record_level_result(level_id, stars)
			_finish_level()
			_result_panel.show_complete(
				not LevelCatalog.get_next_level_id(_levels, level_id).is_empty(),
				stars,
				_outcome.get_health(),
				_outcome.get_max_health()
			)
			_result_panel.set_research_stars(SaveManager.get_available_stars(_research_tree))
		LevelOutcomeTracker.Outcome.FAILED:
			_finish_level()
			# Everything stops where it is: enemies, towers, projectiles,
			# drones and effects.
			for container: Node in [enemies_container, towers_container, projectile_container]:
				container.process_mode = PROCESS_MODE_DISABLED
			_result_panel.show_failed()
			_result_panel.set_research_stars(SaveManager.get_available_stars(_research_tree))


func _on_next_level_requested() -> void:
	var next_level_id: String = LevelCatalog.get_next_level_id(_levels, str(_level["id"]))
	if next_level_id.is_empty():
		_go_to_level_select()
		return
	var next_level: Dictionary = LevelCatalog.find_level(_levels, next_level_id)
	GameState.current_level_id = next_level_id
	get_tree().change_scene_to_file(str(next_level["scene"]))


func _on_retry_requested() -> void:
	get_tree().reload_current_scene()


## Research returns to the level select, ready to pick the next level.
func _on_research_requested() -> void:
	GameState.research_return_scene = MenuWidgets.LEVEL_SELECT_SCENE
	get_tree().change_scene_to_file(MenuWidgets.RESEARCH_SCENE)


func _go_to_level_select() -> void:
	get_tree().change_scene_to_file(MenuWidgets.LEVEL_SELECT_SCENE)


func _on_build_pad_selected(pad: BuildPad) -> void:
	if pad.is_occupied:
		_toggle_tower_panel(pad)
		return
	_tower_panel.close()
	_hide_range_and_preview()
	_selected_build_pad = pad
	_build_menu.show_for_pad(_get_unlocked_tower_definitions(), _wallet.credits)


## Towers the player has researched (or started with), in file order.
func _get_unlocked_tower_definitions() -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = []
	for definition: Dictionary in _tower_definitions:
		if _research_tree.is_unlocked(str(definition.get("id", "")), SaveManager.research):
			unlocked.append(definition)
	return unlocked


func _on_tower_selected(definition_path: String) -> void:
	if _selected_build_pad == null or not is_instance_valid(_selected_build_pad):
		push_error("Cannot place a tower because the selected build pad is no longer available.")
		return
	if _selected_build_pad.is_occupied:
		push_warning("The selected build pad is already occupied.")
		return

	var definition: Dictionary = _find_tower_definition(definition_path)
	if definition.is_empty():
		push_error("The selected tower definition is not available: %s" % definition_path)
		return
	if not _research_tree.is_unlocked(str(definition.get("id", "")), SaveManager.research):
		push_warning("%s has not been researched." % definition["display_name"])
		return
	var cost: int = int((definition["stats"] as Dictionary).get("cost", 0))
	if not _wallet.can_afford(cost):
		push_warning("Not enough credits for %s." % definition["display_name"])
		return

	var sprite_resource: Resource = ResourceLoader.load(str(definition["sprite"]))
	if not sprite_resource is Texture2D:
		push_error("Tower sprite is not a texture: %s" % definition["sprite"])
		return
	var behaviour_path: String = str(definition.get("behaviour", ""))
	if not ResourceLoader.exists(behaviour_path):
		push_error("Tower behaviour script does not exist: %s" % behaviour_path)
		return

	var tower := Sprite2D.new()
	tower.set_script(ResourceLoader.load(behaviour_path) as Script)
	tower.texture = sprite_resource as Texture2D
	tower.set_meta("definition", definition)
	tower.set_meta(PURCHASE_COST_META, cost)
	var behaviour := tower as BaseTower
	if behaviour == null:
		push_error("Tower behaviour script does not extend BaseTower: %s" % behaviour_path)
		tower.free()
		return
	behaviour.path_curve = _path_curve
	if not behaviour.configure(definition, projectile_container):
		push_error("Could not initialize the %s tower." % definition["display_name"])
		tower.free()
		return

	_wallet.spend(cost)
	towers_container.add_child(tower)
	tower.global_position = _selected_build_pad.global_position
	_selected_build_pad.set_occupied()
	_towers_by_pad[_selected_build_pad] = tower
	_selected_build_pad = null
	_hide_range_and_preview()


## The range indicator sits above the road but below pads and towers; the
## preview sits above built towers.
func _create_build_preview() -> void:
	_range_indicator = RangeIndicator.new()
	_range_indicator.name = "RangeIndicator"
	_range_indicator.visible = false
	add_child(_range_indicator)
	move_child(_range_indicator, build_pads.get_index())

	_build_preview = Sprite2D.new()
	_build_preview.name = "BuildPreview"
	_build_preview.modulate = BUILD_PREVIEW_MODULATE
	_build_preview.visible = false
	add_child(_build_preview)
	move_child(_build_preview, towers_container.get_index() + 1)


## First tap on a tower in the build menu: shows it on the selected pad at half
## opacity with its range. A second tap builds it (_on_tower_selected).
func _on_tower_previewed(definition_path: String) -> void:
	var definition: Dictionary = _find_tower_definition(definition_path)
	if definition.is_empty() or _selected_build_pad == null:
		_hide_range_and_preview()
		return
	_build_preview.texture = ResourceLoader.load(str(definition["sprite"])) as Texture2D
	_build_preview.global_position = _selected_build_pad.global_position
	_build_preview.visible = true
	_show_range(definition, _selected_build_pad.global_position)


## Tapping a built tower shows its range and its panel; tapping it again
## hides them.
func _toggle_tower_panel(pad: BuildPad) -> void:
	var was_shown: bool = _range_shown_pad == pad and _tower_panel.visible
	_build_menu.close()
	_tower_panel.close()
	if was_shown or not _towers_by_pad.has(pad):
		return
	var tower: Node2D = _towers_by_pad[pad]
	var definition: Dictionary = tower.get_meta("definition")
	_show_range(definition, tower.global_position)
	_range_shown_pad = pad
	_tower_panel.show_for_tower(
		str(definition["display_name"]),
		Wallet.sell_refund(int(tower.get_meta(PURCHASE_COST_META, 0)))
	)


func _on_sell_requested() -> void:
	if _range_shown_pad != null and is_instance_valid(_range_shown_pad):
		sell_tower(_range_shown_pad)


## Sells the tower on [param pad]: pays Wallet.sell_refund of its price back
## into this level's wallet and frees the pad for another tower.
func sell_tower(pad: BuildPad) -> void:
	if _is_finished or not _towers_by_pad.has(pad):
		return
	var tower: Node2D = _towers_by_pad[pad]
	_towers_by_pad.erase(pad)
	_wallet.earn(Wallet.sell_refund(int(tower.get_meta(PURCHASE_COST_META, 0))))
	# Gone at once, so it stops acting (and cleans up its drones or buffs) this
	# frame. In-flight projectiles check their impact callback is still valid.
	towers_container.remove_child(tower)
	tower.free()
	pad.set_vacant()


func _show_range(definition: Dictionary, at: Vector2) -> void:
	var stats: Dictionary = definition.get("stats", {})
	_range_indicator.global_position = at
	_range_indicator.show_range(
		float(stats.get("range", 0.0)),
		float(stats.get("min_range", 0.0)),
		_path_curve.get_baked_points()
	)


func _hide_range_and_preview() -> void:
	_build_preview.visible = false
	_range_indicator.visible = false
	_range_shown_pad = null


func _find_tower_definition(definition_path: String) -> Dictionary:
	for definition: Dictionary in _tower_definitions:
		if str(definition.get(DefinitionCatalog.DEFINITION_PATH_KEY, "")) == definition_path:
			return definition
	return {}
