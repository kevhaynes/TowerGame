# Combat

Damage calculation, damage types, targeting and status effects. Keep these as
plain classes so they can be unit-tested without scenes.

- `path_enemy.gd`: enemy movement, damage pipeline (PHASED and BRITTLE scaling,
  then shield, then armour; STASIS storage), status effects, knockback and position prediction.
- `status_effect.gd` / `status_effects.gd`: the status effects and their
  stacking rules (strongest wins and the duration refreshes; DoTs from
  different sources add; shred stacks to a cap; bosses take half-duration crowd control).
- `combat_math.gd`: armour (10% per point, max 75%), splash falloff, chain
  damage, graviton pull direction, drone zone movement.
- `tower_targeting.gd`: first/ordered targeting, radius, line, cone and chain selection.
- `trait_affinity.gd`: strong/weak trait multipliers and trait list parsing.
- `stat_reader.gd`: validated reading of tower stats from JSON.
- `base_tower.gd`: shared tower plumbing (configure, cooldowns, damage, splash,
  projectiles, Overcharge buffs). Tower behaviours live in `towers/`.
- `tower_projectile.gd`, `blast_effect.gd`: generic projectile and explosion visuals.
- `enemy_health_bar.gd` draws a health bar for each path-following enemy and
  smoothly interpolates its fill from green at full health, through yellow at
  50%, to red at 10% health.
