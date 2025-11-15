extends Node

enum Rarity
{
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Relic = 0, # Items only
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
	Chronophage,
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
	Zone,
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
	CritChance,
	CritDamage,
}

enum Skill_Type
{
	Stab,
	Heap_On,
	Pierce_Weakness,
	Burning_Bolas,
	Flicker_Zone,
	None,
}

enum Buff_Type
{
	Invalid,
}

enum Debuff_Type
{
	Burning,
	Invalid,
}
