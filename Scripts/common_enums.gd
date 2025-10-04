extends Node

# TODO: Move into a constants file maybe
const HEALTH_MULTIPLIER: int = 7

enum Rarity
{
	Common,
	Uncommon,
	Rare,
	Epic,
	Legendary,
	Relic, # Items only
}

enum Faction
{
	Kingdom1,
	Kingdom2,
	Renegades,
	Outcasts,
	Generic_Enemy,
}

enum Role
{
	Emissary,
	Cleric,
	Thief,
	Knight,
	Alchemist,
	Sorcerer,
	Scholar,
	Diviner,
	Appraiser,
	Tactician,
	Symbiote,
	Jester,
	Cultist,
	Generic_Enemy,
	Bar_Brawler,
	Bloodmage,
	Herald_of_the_loom,
}

enum Slot
{
	Helmet,
	Weapon,
	Shield,
	Chest,
	Pants,
	Boots,
	Gloves,
	Ring,
	Amulet,
	Trinket,
}

enum Skill_Target
{
	Single_Enemy,
	All_Enemies,
	Random_Enemy,
	
	Single_Ally,
	All_Allies,
	Random_Ally,
	
	Ally_Not_Self,
	Random_One,
	All,
}

enum Attribute
{
	Health,
	Speed,
	Attack,
	Defence,
	Accuracy,
	Resistance,
	Mysticism,
	Knowledge,
	Pressence,
	CritChance,
	CritDamage,
}

enum Skill_Type
{
	Stab,
	Heap_On,
}

enum Buff_Type
{
	Invalid,
}

enum Debuff_Type
{
	Invalid,
}
