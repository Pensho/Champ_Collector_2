extends Node

enum Rarity
{
	Common,
	Uncommon,
	Rare,
	Unique,
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
	Strategist,
	Symbiote,
	Jester,
	Cultist,
	Generic_Enemy,
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
