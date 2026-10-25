# Unit Tests

Pure logic tests, avoiding the scene tree where possible. Name files `test_<subject>.gd` and extend `GutTest`.

`test_tower_definitions.gd` validates every tower JSON in `data/towers/`.

Tower tests use `CombatFixture` (`tests/helpers/combat_fixture.gd`) to build
towers from their shipped JSON and place enemies on a straight test path.
