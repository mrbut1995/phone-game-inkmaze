extends TestCase
class_name GameTestCase
## TestCase with helpers to build real actors from actor.tscn (needs the scene tree).

const ACTOR_SCENE: String = "res://scenes/objects/world/actor.tscn"

func make_definition(faction: Enums.Faction = Enums.Faction.PLAYER, max_health: int = 100) -> ActorDefinition:
	var definition := ActorDefinition.new()
	definition.id = &"test_actor"
	definition.faction = faction
	definition.max_health = max_health
	definition.move_speed = 100.0
	definition.sight_range = 300.0
	definition.attack_range = 50.0
	definition.attack_damage = 10
	definition.attack_cooldown = 1.0
	definition.interact_cooldown = 0.5
	return definition

## Instantiates actor.tscn, adds it to the tree and sets it up (no brain).
func spawn_actor(faction: Enums.Faction = Enums.Faction.PLAYER, at: Vector2 = Vector2.ZERO, max_health: int = 100) -> Actor:
	var actor := instantiate_scene(ACTOR_SCENE) as Actor
	add_to_tree(actor)
	actor.global_position = at
	actor.setup(make_definition(faction, max_health))
	return actor
