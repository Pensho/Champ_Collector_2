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
	Emissary = 0,
	Thief = 2,
	Lancer = 3,
	Alchemist = 4,
	Sorcerer = 5,
	Scholar = 6,
	Diviner = 7,
	Appraiser = 8,
	Tactician = 9,
	Symbiote = 10,
	Jester = 11,
	Cultist = 12,
	Generic_Enemy = 13,
	Bar_Brawler = 14,
	Bloodmage = 15,
	Herald_of_the_loom = 16,
	Chronophage = 17,
	Architect = 18,
	Tidal_Corsair = 19,
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
	All_Other_Allies,
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
	Status_Effect,
}

enum Buff_Type
{
	Invalid,
	Empower,
	Fortify,
	Daunting_Strength,
	Phalanx_Guard,
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
	Defend,
}

func RarityName(p_rarity: Types.Rarity) -> String:
	return Types.Rarity.keys()[p_rarity - 1]
