extends Node

## The level the level scene should load. Set by the level select menu and by
## the level result panel before changing or reloading the scene.
var current_level_id: String = ""

## Where the research menu's BACK button goes. Set by whoever opens research.
var research_return_scene: String = "res://scenes/ui/towers_menu.tscn"
