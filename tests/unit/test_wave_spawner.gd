extends GutTest


func _waves(spawn_lists: Array) -> Array:
	var waves: Array = []
	for spawns: Array in spawn_lists:
		waves.append({"spawns": spawns})
	return waves


func test_first_spawn_counts_from_start_and_later_ones_from_previous_spawn() -> void:
	var spawner := WaveSpawner.new(
		_waves([[
			{"enemy": "a", "spawn_delay": 1.0},
			{"enemy": "b", "spawn_delay": 2.0},
			{"enemy": "c", "spawn_delay": 0.5},
		]])
	)
	assert_eq(spawner.advance(0.9), [] as Array[String])
	assert_eq(spawner.advance(0.1), ["a"] as Array[String], "1s after start")
	assert_eq(spawner.advance(1.9), [] as Array[String])
	assert_eq(spawner.advance(0.1), ["b"] as Array[String], "2s after a")
	assert_eq(spawner.advance(0.5), ["c"] as Array[String], "0.5s after b")


func test_missing_or_zero_delay_spawns_with_the_previous_enemy() -> void:
	var spawner := WaveSpawner.new(
		_waves([[{"enemy": "a"}, {"enemy": "b", "spawn_delay": 0.0}, {"enemy": "c"}]])
	)
	assert_eq(spawner.advance(0.0), ["a", "b", "c"] as Array[String])


func test_long_frame_spawns_everything_due() -> void:
	var spawner := WaveSpawner.new(
		_waves([
			[
				{"enemy": "a"},
				{"enemy": "b", "spawn_delay": 1.0},
				{"enemy": "c", "spawn_delay": 5.0},
			]
		])
	)
	assert_eq(spawner.advance(2.0), ["a", "b"] as Array[String])
	assert_eq(spawner.advance(3.9), [] as Array[String], "c is due 5s after b, at 6s")
	assert_eq(spawner.advance(0.1), ["c"] as Array[String])


func test_next_wave_waits_until_previous_wave_is_cleared() -> void:
	var spawner := WaveSpawner.new(
		_waves([
			[{"enemy": "a"}, {"enemy": "b", "spawn_delay": 1.0}],
			[{"enemy": "c", "spawn_delay": 2.0}],
		])
	)
	assert_eq(spawner.get_wave_number(), 1)
	spawner.advance(0.0)
	spawner.advance(1.0)
	assert_eq(spawner.advance(10.0), [] as Array[String], "wave 1 enemies still alive")
	spawner.notify_enemy_resolved()
	assert_eq(spawner.get_wave_number(), 1)
	spawner.notify_enemy_resolved()
	assert_eq(spawner.get_wave_number(), 2, "wave 2 starts when wave 1 is cleared")
	assert_eq(spawner.advance(1.9), [] as Array[String], "first spawn counts from wave start")
	assert_eq(spawner.advance(0.1), ["c"] as Array[String])


func test_clearing_early_enemies_does_not_skip_unspawned_ones() -> void:
	var spawner := WaveSpawner.new(
		_waves([[{"enemy": "a"}, {"enemy": "b", "spawn_delay": 3.0}], [{"enemy": "c"}]])
	)
	spawner.advance(0.0)
	spawner.notify_enemy_resolved()
	assert_eq(spawner.get_wave_number(), 1, "b has not spawned yet")
	assert_eq(spawner.advance(3.0), ["b"] as Array[String])


func test_finishes_after_last_wave_is_cleared() -> void:
	var spawner := WaveSpawner.new(_waves([[{"enemy": "a"}], [{"enemy": "b"}]]))
	spawner.advance(0.0)
	spawner.notify_enemy_resolved()
	spawner.advance(0.0)
	assert_false(spawner.is_finished())
	spawner.notify_enemy_resolved()
	assert_true(spawner.is_finished())
	assert_eq(spawner.get_wave_number(), 2)
	assert_eq(spawner.advance(10.0), [] as Array[String])


func test_counts_and_empty_waves() -> void:
	var spawner := WaveSpawner.new(_waves([[{"enemy": "a"}, {"enemy": "b"}], [], [{"enemy": "c"}]]))
	assert_eq(spawner.get_wave_count(), 2, "empty waves are skipped")
	assert_eq(spawner.get_total_spawn_count(), 3)
	assert_true(WaveSpawner.new([]).is_finished())


func test_group_spawns_its_count_at_its_interval() -> void:
	var spawner := WaveSpawner.new(
		_waves([[{"enemy": "scout", "count": 3, "spawn_delay": 1.0, "spawn_interval": 0.5}]])
	)
	assert_eq(spawner.get_total_spawn_count(), 3)
	assert_eq(spawner.advance(0.9), [] as Array[String])
	assert_eq(spawner.advance(0.1), ["scout"] as Array[String], "group delay from wave start")
	assert_eq(spawner.advance(0.4), [] as Array[String])
	assert_eq(spawner.advance(0.1), ["scout"] as Array[String], "interval after the first")
	assert_eq(spawner.advance(0.5), ["scout"] as Array[String])
	assert_eq(spawner.advance(10.0), [] as Array[String], "group is done")


func test_next_group_delay_counts_from_previous_groups_last_enemy() -> void:
	var spawner := WaveSpawner.new(
		_waves(
			[
				[
					{"enemy": "scout", "count": 2, "spawn_interval": 1.0},
					{"enemy": "heavy", "count": 2, "spawn_delay": 3.0, "spawn_interval": 2.0},
				]
			]
		)
	)
	assert_eq(spawner.advance(1.0), ["scout", "scout"] as Array[String])
	assert_eq(spawner.advance(2.9), [] as Array[String])
	assert_eq(spawner.advance(0.1), ["heavy"] as Array[String], "3s after the last scout")
	assert_eq(spawner.advance(2.0), ["heavy"] as Array[String])


func test_group_without_count_is_one_enemy() -> void:
	assert_eq(WaveSpawner.expand_group({"enemy": "scout", "spawn_delay": 2.0}).size(), 1)
	var spawner := WaveSpawner.new(_waves([[{"enemy": "a"}, {"enemy": "b", "count": 4}]]))
	assert_eq(spawner.get_total_spawn_count(), 5)
	assert_eq(spawner.advance(0.0), ["a", "b", "b", "b", "b"] as Array[String], "no interval")
