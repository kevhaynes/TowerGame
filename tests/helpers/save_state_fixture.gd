extends RefCounted
class_name SaveStateFixture

## Test helper: gives SaveManager fresh progress, codex and research, and
## points its save path at a test file, so tests never touch the player's real
## progress or save. Call restore() in after_each.

const TEST_SAVE_PATH: String = "user://test_save.json"

var _progress: LevelProgress
var _codex: EnemyCodex
var _research: ResearchProgress


func _init() -> void:
	_progress = SaveManager.progress
	_codex = SaveManager.codex
	_research = SaveManager.research
	SaveManager.progress = LevelProgress.new()
	SaveManager.codex = EnemyCodex.new()
	SaveManager.research = ResearchProgress.new()
	SaveManager.save_path = TEST_SAVE_PATH


## Researches every tower in the tree, so levels offer and accept them all.
func unlock_all_towers() -> void:
	for tower_id: String in ResearchTree.load_tree().get_tower_ids():
		SaveManager.research.record_research(tower_id)


func restore() -> void:
	SaveManager.progress = _progress
	SaveManager.codex = _codex
	SaveManager.research = _research
	SaveManager.save_path = SaveManager.SAVE_PATH
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
