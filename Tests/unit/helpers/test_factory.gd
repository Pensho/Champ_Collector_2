extends RefCounted

static func make_character() -> Character:
	var c: Character = Character.new()
	c._name = "TestCharacter"
	c._level = 1
	c._experience = 0
	c._attributes[Types.Attribute.Health] = 10
	c._attributes[Types.Attribute.Speed] = 5
	c._attributes[Types.Attribute.Attack] = 8
	c._attributes[Types.Attribute.Defence] = 6
	c._attributes[Types.Attribute.Accuracy] = 7
	c._attributes[Types.Attribute.Resistance] = 6
	c._attributes[Types.Attribute.Mysticism] = 4
	c._attributes[Types.Attribute.Knowledge] = 4
	c._attributes[Types.Attribute.CritChance] = 5
	c._attributes[Types.Attribute.CritDamage] = 150
	return c

## Builds a full 6-slot battle roster (players 0-2, monsters 3-5), all alive.
## Handy for exercising FindSkillTargets, which now filters on existence and health.
static func make_full_roster() -> Dictionary:
	var roster: Dictionary[int, Character] = {}
	for id in range(6):
		var c: Character = make_character()
		c._current_health = c._attributes[Types.Attribute.Health]
		roster[id] = c
	return roster

static func make_loot_table() -> LootTable:
	return LootTable.new()

static func make_adventure_state() -> AdventureState:
	return AdventureState.new()
