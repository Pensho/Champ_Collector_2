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
	Herald_Of_The_Loom = 16,
	Chronophage = 17,
	Architect = 18,
	Tidal_Corsair = 19,
	Plague_Doctor = 20,
	Warlord = 21,
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
	Self,
	Most_Injured_Ally,
	Left_Most_Enemy,
	Right_Most_Enemy,
	Most_Injured_Enemy,
	Most_Buffed_Ally,
	Skill_Default,
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

enum Buff_Type
{
	Invalid,
	Empower,
	Fortify,
	Daunting_Strength,
	Phalanx_Guard,
	Attune,
	Haste,
	True_Aim,
	Clarity,
	Insight,
	Vigor,
	Keen_Edge,
	Lethal_Precision,
	Frenzy,
	Opportunist,
	Regeneration,
	Exhert,
	Premonition,
	Deathward,
	Aegis,
	Mirror_Coat,
	Barrier,
	Luck,
	Rehearsed,
	Overflow,
	Wanderlust,
	Steadfast,
	Slipstream,
	Resonance,
	Battle_Orders,
	Rush,
	Spotlight,
	Catalyst,
	Volatile_Mixture,
}

enum Debuff_Type
{
	Burning,
	Enfeeble,
	Expose_Weakness,
	Suppress,
	Slow,
	Blind,
	Unravel,
	Confound,
	Exposed_Facet,
	Cracked_Facet,
	Sequence_Lock,
	Bleed,
	Plague,
	Blight,
	Temporal_Leak,
	Mana_Burn,
	Hexed,
	Dead_Weight,
	Stun,
	Fatigue,
	Refracted,
	Warped,
	Signed_Writ,
	Severance,
	Sanction,
	Anchor,
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
	Reagent_Consumed,
	Critical_Hit,
	Ally_Death,
	Ally_Damage_Taken,
	Ally_Reagent_Consumed,
	Buff_Applied,
	Debuff_Applied,
	Debuff_Received,
	Enemy_Turn_Bar_Reduced,
	Zone_Used,
	Zone_Constructed,
	Damage_Dealt,
	On_Kill,
	Zone_Affected,
	Resource_Depleted,
	Cascade_Instance_Resolved,
	Skill_Effects_Resolved,
}

## Source a DamageEffect's bonus_per fraction, or a SkillEffect's condition, scales
## against. Trait_Counter_On_Target is rate-multiplied; Trait_Counter_Raw_On_Target is
## the same counter un-multiplied.
enum Trait_Count_Source
{
	Buffs_On_Caster,
	Buffs_Consumed,
	Uses_This_Battle,
	Trait_Condition,
	Trait_Counter_On_Target,
	Trait_Counter_Raw_On_Target,
	Zones_On_Turn_Bar,
	Target_Debuff_Count,
}

## Always reads as the raw (un-multiplied) Trait_Count_Source, even where the member
## name matches a rate-multiplied one, so a threshold is always a plain count.
enum Skill_Condition
{
	None,
	Trait_Condition,
	Trait_Counter_Raw_On_Target,
}

enum Condition_Test
{
	At_Least,
	Below,
}

enum Cascade_Trigger
{
	Status_Expired,
	Status_Landed,
	Skill_Resolved,
}

func RarityName(p_rarity: Types.Rarity) -> String:
	return Types.Rarity.keys()[p_rarity - 1]

func BuffName(p_type: Types.Buff_Type) -> String:
	return Types.Buff_Type.keys()[p_type].replace("_", " ")

func DebuffName(p_type: Types.Debuff_Type) -> String:
	return Types.Debuff_Type.keys()[p_type].replace("_", " ")
