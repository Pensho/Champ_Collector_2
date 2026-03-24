extends Node

enum Rarity
{
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Relic = 6, # Items only
}

enum Faction
{
	Kingdom1,
	The_Iron_Ledger,
	Renegades,
	Outcasts,
	Generic_Enemy,
	Centaur_Great_Caravan,
	Centaur_Regimes,
	Centaur_Rootless_Tribes,
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
	Architect,
	Tidal_Corsair,
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
	
	ZoneAll,
	ZoneAlly,
	ZoneEnemy,
	
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
	CritChance,
	CritDamage,
}

enum Skill_Type
{
	Simple_Attack,
	Heap_On,
	Flicker_Zone,
	Lava_Zone,
	None,
}

enum Buff_Type
{
	Invalid,
}

enum Debuff_Type
{
	Burning,
	Enfeeble,
	Expose_Weakness,
	Invalid,
}

enum Combat_Event
{
	Start_Combat,
	Start_Turn,
	End_Turn,
	Skill_Cast,
	Damage_Taken,
	On_Death,
}
