extends Node

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 4
const VERSION_KEY: String = "save_version"
const LEVELS_KEY: String = "levels"
const ENCOUNTERED_ENEMIES_KEY: String = "encountered_enemies"
const RESEARCH_KEY: String = "research"
## Version 1 kept a plain list of completed level ids under this key.
const V1_COMPLETED_LEVELS_KEY: String = "completed_levels"

## Where the game is saved. Tests point this elsewhere so they never touch the
## player's real save.
var save_path: String = SAVE_PATH
var progress: LevelProgress = LevelProgress.new()
var codex: EnemyCodex = EnemyCodex.new()
var research: ResearchProgress = ResearchProgress.new()


func _ready() -> void:
	load_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Saves when this is the level's first completion or beats its best stars.
func record_level_result(level_id: String, stars: int) -> void:
	if progress.record_completion(level_id, stars):
		save_game()


## Not saved straight away: saving happens on the next level result, or when
## the app is backgrounded or closed.
func record_enemy_encounter(enemy_id: String) -> void:
	codex.record_encounter(enemy_id)


## Stars earned on levels (plus debug bonus stars) not yet spent on research.
func get_available_stars(tree: ResearchTree) -> int:
	return tree.get_available_stars(progress.get_total_stars(), research)


## Researches [param tower_id] and saves, if its requirements are met and the
## player has the stars. Returns true when it was researched.
func research_tower(tree: ResearchTree, tower_id: String) -> bool:
	var status: ResearchTree.Status = tree.get_status(
		tower_id, research, get_available_stars(tree)
	)
	if status != ResearchTree.Status.AVAILABLE:
		return false
	research.record_research(tower_id)
	save_game()
	return true


## Debug: clears every level's stars (which also locks every level but the
## first again) and all research, so no spent stars are left over, and saves.
func reset_stars() -> void:
	progress = LevelProgress.new()
	research = ResearchProgress.new()
	save_game()


## Debug: grants [param amount] stars to spend on research, and saves.
func add_debug_stars(amount: int) -> void:
	research.bonus_stars += maxi(0, amount)
	save_game()


func load_game() -> void:
	progress = LevelProgress.new()
	codex = EnemyCodex.new()
	research = ResearchProgress.new()
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("Could not open save file: %s" % error_string(FileAccess.get_open_error()))
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		push_error("Save file is not a JSON object; starting with fresh progress.")
		return

	var save_data: Dictionary = migrate(data)
	var levels: Variant = save_data.get(LEVELS_KEY, {})
	if levels is Dictionary:
		progress = LevelProgress.from_dict(levels)
	codex = EnemyCodex.from_array(save_data.get(ENCOUNTERED_ENEMIES_KEY, []))
	research = ResearchProgress.from_dict(save_data.get(RESEARCH_KEY, {}))


func save_game() -> void:
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % error_string(FileAccess.get_open_error()))
		return
	var data: Dictionary = {
		VERSION_KEY: SAVE_VERSION,
		LEVELS_KEY: progress.to_dict(),
		ENCOUNTERED_ENEMIES_KEY: codex.to_array(),
		RESEARCH_KEY: research.to_dict(),
	}
	file.store_string(JSON.stringify(data, "  "))


## Upgrades older save data to SAVE_VERSION. Data with no version is version 1.
static func migrate(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	var version: int = int(migrated.get(VERSION_KEY, 1))
	if version < 2:
		_migrate_v1_to_v2(migrated)
	if version < 3:
		_migrate_v2_to_v3(migrated)
	if version < 4:
		_migrate_v3_to_v4(migrated)
	migrated[VERSION_KEY] = SAVE_VERSION
	return migrated


## Version 2 replaced the completed level list with best stars per level.
## Version 1 only completed a level when no enemy escaped, which is full
## health, so each completed level becomes a 3-star completion.
static func _migrate_v1_to_v2(data: Dictionary) -> void:
	var levels: Variant = data.get(LEVELS_KEY, {})
	if not levels is Dictionary:
		return
	var completed: Variant = levels.get(V1_COMPLETED_LEVELS_KEY, [])
	var level_stars: Dictionary = {}
	if completed is Array:
		for level_id: Variant in completed:
			if level_id is String and not (level_id as String).is_empty():
				level_stars[level_id] = LevelStars.MAX_STARS
	levels.erase(V1_COMPLETED_LEVELS_KEY)
	levels[LevelProgress.LEVEL_STARS_KEY] = level_stars


## Version 3 added the encountered enemy list. Older saves did not track
## encounters, so they start with none.
static func _migrate_v2_to_v3(data: Dictionary) -> void:
	if not data.has(ENCOUNTERED_ENEMIES_KEY):
		data[ENCOUNTERED_ENEMIES_KEY] = []


## Version 4 added research. Older saves had every tower available, so they
## start with nothing researched and their earned stars to spend.
static func _migrate_v3_to_v4(data: Dictionary) -> void:
	if not data.has(RESEARCH_KEY):
		data[RESEARCH_KEY] = {}
