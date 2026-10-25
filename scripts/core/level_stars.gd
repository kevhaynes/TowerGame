extends RefCounted
class_name LevelStars

## Star rating for a completed level, from the health left at the end. Stars
## are saved per level (best run) and will be spent on tower research.

const MAX_STARS: int = 3
## Finishing below this fraction of max health earns a single star.
const ONE_STAR_HEALTH_FRACTION: float = 0.5


## 3 stars at full health, 1 below half health, 2 otherwise; 0 when no health
## is left (the level was lost).
static func for_health(health: float, max_health: float) -> int:
	if max_health <= 0.0 or health <= 0.0:
		return 0
	if health >= max_health:
		return MAX_STARS
	if health < max_health * ONE_STAR_HEALTH_FRACTION:
		return 1
	return 2
