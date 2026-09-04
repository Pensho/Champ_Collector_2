class_name ReagentRegistry extends Node

## Preload-based lookup from a stable identifier string (matching the .tres base file
## name, e.g. "Sigil_Speed_Uncommon") to its ReagentData, mirroring
## StatusEffectRegistry (DirAccess-based discovery is unsafe on Android export).

const REAGENTS: Dictionary[String, ReagentData] = {
	"Lesser_Restorative_Brew": preload("res://Data/Reagents/Alchemist_Brews/Lesser_Restorative_Brew.tres"),
	"Lesser_Tincture": preload("res://Data/Reagents/Alchemist_Brews/Lesser_Tincture.tres"),
	"Lesser_Barrier_Brew": preload("res://Data/Reagents/Alchemist_Brews/Lesser_Barrier_Brew.tres"),
	"Lesser_Purging_Brew": preload("res://Data/Reagents/Alchemist_Brews/Lesser_Purging_Brew.tres"),
	"Chaotic_Blessing_Epic": preload("res://Data/Reagents/Chaotic_Blessing/Chaotic_Blessing_Epic.tres"),
	"Chaotic_Blessing_Legendary": preload("res://Data/Reagents/Chaotic_Blessing/Chaotic_Blessing_Legendary.tres"),
	"Chaotic_Blessing_Rare": preload("res://Data/Reagents/Chaotic_Blessing/Chaotic_Blessing_Rare.tres"),
	"Chaotic_Blessing_Uncommon": preload("res://Data/Reagents/Chaotic_Blessing/Chaotic_Blessing_Uncommon.tres"),
	"Fractured_Idol_Epic": preload("res://Data/Reagents/Fractured_Idol/Fractured_Idol_Epic.tres"),
	"Fractured_Idol_Legendary": preload("res://Data/Reagents/Fractured_Idol/Fractured_Idol_Legendary.tres"),
	"Fractured_Idol_Rare": preload("res://Data/Reagents/Fractured_Idol/Fractured_Idol_Rare.tres"),
	"Fractured_Idol_Uncommon": preload("res://Data/Reagents/Fractured_Idol/Fractured_Idol_Uncommon.tres"),
	"Absolving_Tablet_Epic": preload("res://Data/Reagents/Absolving_Tablet/Absolving_Tablet_Epic.tres"),
	"Absolving_Tablet_Legendary": preload("res://Data/Reagents/Absolving_Tablet/Absolving_Tablet_Legendary.tres"),
	"Absolving_Tablet_Rare": preload("res://Data/Reagents/Absolving_Tablet/Absolving_Tablet_Rare.tres"),
	"Absolving_Tablet_Uncommon": preload("res://Data/Reagents/Absolving_Tablet/Absolving_Tablet_Uncommon.tres"),
	"Mending_Icon_Epic": preload("res://Data/Reagents/Mending_Icon/Mending_Icon_Epic.tres"),
	"Mending_Icon_Legendary": preload("res://Data/Reagents/Mending_Icon/Mending_Icon_Legendary.tres"),
	"Mending_Icon_Rare": preload("res://Data/Reagents/Mending_Icon/Mending_Icon_Rare.tres"),
	"Mending_Icon_Uncommon": preload("res://Data/Reagents/Mending_Icon/Mending_Icon_Uncommon.tres"),
	"Rewinding_Cog_Epic": preload("res://Data/Reagents/Rewinding_Cog/Rewinding_Cog_Epic.tres"),
	"Rewinding_Cog_Legendary": preload("res://Data/Reagents/Rewinding_Cog/Rewinding_Cog_Legendary.tres"),
	"Rewinding_Cog_Rare": preload("res://Data/Reagents/Rewinding_Cog/Rewinding_Cog_Rare.tres"),
	"Rewinding_Cog_Uncommon": preload("res://Data/Reagents/Rewinding_Cog/Rewinding_Cog_Uncommon.tres"),
	"Second_Wind_Chime_Epic": preload("res://Data/Reagents/Second_Wind_Chime/Second_Wind_Chime_Epic.tres"),
	"Second_Wind_Chime_Legendary": preload("res://Data/Reagents/Second_Wind_Chime/Second_Wind_Chime_Legendary.tres"),
	"Second_Wind_Chime_Rare": preload("res://Data/Reagents/Second_Wind_Chime/Second_Wind_Chime_Rare.tres"),
	"Second_Wind_Chime_Uncommon": preload("res://Data/Reagents/Second_Wind_Chime/Second_Wind_Chime_Uncommon.tres"),
	"Thiefs_Regret_Epic": preload("res://Data/Reagents/Thiefs_Regret/Thiefs_Regret_Epic.tres"),
	"Thiefs_Regret_Legendary": preload("res://Data/Reagents/Thiefs_Regret/Thiefs_Regret_Legendary.tres"),
	"Thiefs_Regret_Rare": preload("res://Data/Reagents/Thiefs_Regret/Thiefs_Regret_Rare.tres"),
	"Thiefs_Regret_Uncommon": preload("res://Data/Reagents/Thiefs_Regret/Thiefs_Regret_Uncommon.tres"),
	"Sigil_Accuracy_Epic": preload("res://Data/Reagents/Sigil_Accuracy/Sigil_Accuracy_Epic.tres"),
	"Sigil_Accuracy_Legendary": preload("res://Data/Reagents/Sigil_Accuracy/Sigil_Accuracy_Legendary.tres"),
	"Sigil_Accuracy_Rare": preload("res://Data/Reagents/Sigil_Accuracy/Sigil_Accuracy_Rare.tres"),
	"Sigil_Accuracy_Uncommon": preload("res://Data/Reagents/Sigil_Accuracy/Sigil_Accuracy_Uncommon.tres"),
	"Sigil_Attack_Epic": preload("res://Data/Reagents/Sigil_Attack/Sigil_Attack_Epic.tres"),
	"Sigil_Attack_Legendary": preload("res://Data/Reagents/Sigil_Attack/Sigil_Attack_Legendary.tres"),
	"Sigil_Attack_Rare": preload("res://Data/Reagents/Sigil_Attack/Sigil_Attack_Rare.tres"),
	"Sigil_Attack_Uncommon": preload("res://Data/Reagents/Sigil_Attack/Sigil_Attack_Uncommon.tres"),
	"Sigil_CritChance_Epic": preload("res://Data/Reagents/Sigil_CritChance/Sigil_CritChance_Epic.tres"),
	"Sigil_CritChance_Legendary": preload("res://Data/Reagents/Sigil_CritChance/Sigil_CritChance_Legendary.tres"),
	"Sigil_CritChance_Rare": preload("res://Data/Reagents/Sigil_CritChance/Sigil_CritChance_Rare.tres"),
	"Sigil_CritChance_Uncommon": preload("res://Data/Reagents/Sigil_CritChance/Sigil_CritChance_Uncommon.tres"),
	"Sigil_CritDamage_Epic": preload("res://Data/Reagents/Sigil_CritDamage/Sigil_CritDamage_Epic.tres"),
	"Sigil_CritDamage_Legendary": preload("res://Data/Reagents/Sigil_CritDamage/Sigil_CritDamage_Legendary.tres"),
	"Sigil_CritDamage_Rare": preload("res://Data/Reagents/Sigil_CritDamage/Sigil_CritDamage_Rare.tres"),
	"Sigil_CritDamage_Uncommon": preload("res://Data/Reagents/Sigil_CritDamage/Sigil_CritDamage_Uncommon.tres"),
	"Sigil_Defence_Epic": preload("res://Data/Reagents/Sigil_Defence/Sigil_Defence_Epic.tres"),
	"Sigil_Defence_Legendary": preload("res://Data/Reagents/Sigil_Defence/Sigil_Defence_Legendary.tres"),
	"Sigil_Defence_Rare": preload("res://Data/Reagents/Sigil_Defence/Sigil_Defence_Rare.tres"),
	"Sigil_Defence_Uncommon": preload("res://Data/Reagents/Sigil_Defence/Sigil_Defence_Uncommon.tres"),
	"Sigil_Knowledge_Epic": preload("res://Data/Reagents/Sigil_Knowledge/Sigil_Knowledge_Epic.tres"),
	"Sigil_Knowledge_Legendary": preload("res://Data/Reagents/Sigil_Knowledge/Sigil_Knowledge_Legendary.tres"),
	"Sigil_Knowledge_Rare": preload("res://Data/Reagents/Sigil_Knowledge/Sigil_Knowledge_Rare.tres"),
	"Sigil_Knowledge_Uncommon": preload("res://Data/Reagents/Sigil_Knowledge/Sigil_Knowledge_Uncommon.tres"),
	"Sigil_Mysticism_Epic": preload("res://Data/Reagents/Sigil_Mysticism/Sigil_Mysticism_Epic.tres"),
	"Sigil_Mysticism_Legendary": preload("res://Data/Reagents/Sigil_Mysticism/Sigil_Mysticism_Legendary.tres"),
	"Sigil_Mysticism_Rare": preload("res://Data/Reagents/Sigil_Mysticism/Sigil_Mysticism_Rare.tres"),
	"Sigil_Mysticism_Uncommon": preload("res://Data/Reagents/Sigil_Mysticism/Sigil_Mysticism_Uncommon.tres"),
	"Sigil_Resistance_Epic": preload("res://Data/Reagents/Sigil_Resistance/Sigil_Resistance_Epic.tres"),
	"Sigil_Resistance_Legendary": preload("res://Data/Reagents/Sigil_Resistance/Sigil_Resistance_Legendary.tres"),
	"Sigil_Resistance_Rare": preload("res://Data/Reagents/Sigil_Resistance/Sigil_Resistance_Rare.tres"),
	"Sigil_Resistance_Uncommon": preload("res://Data/Reagents/Sigil_Resistance/Sigil_Resistance_Uncommon.tres"),
	"Sigil_Speed_Epic": preload("res://Data/Reagents/Sigil_Speed/Sigil_Speed_Epic.tres"),
	"Sigil_Speed_Legendary": preload("res://Data/Reagents/Sigil_Speed/Sigil_Speed_Legendary.tres"),
	"Sigil_Speed_Rare": preload("res://Data/Reagents/Sigil_Speed/Sigil_Speed_Rare.tres"),
	"Sigil_Speed_Uncommon": preload("res://Data/Reagents/Sigil_Speed/Sigil_Speed_Uncommon.tres"),
	"Unbinding_Shard_Epic": preload("res://Data/Reagents/Unbinding_Shard/Unbinding_Shard_Epic.tres"),
	"Unbinding_Shard_Legendary": preload(
			"res://Data/Reagents/Unbinding_Shard/Unbinding_Shard_Legendary.tres"),
	"Unbinding_Shard_Rare": preload("res://Data/Reagents/Unbinding_Shard/Unbinding_Shard_Rare.tres"),
	"Unbinding_Shard_Uncommon": preload(
			"res://Data/Reagents/Unbinding_Shard/Unbinding_Shard_Uncommon.tres"),
}

static func Get(p_id: String) -> ReagentData:
	return REAGENTS.get(p_id)

static func GetRandomKeyForRarity(p_rarity: Types.Rarity) -> String:
	var matching_keys: Array[String] = []
	for reagent_key in REAGENTS.keys():
		if(REAGENTS[reagent_key].rarity == p_rarity and not REAGENTS[reagent_key].brew_only):
			matching_keys.append(reagent_key)
	return matching_keys[randi_range(0, matching_keys.size() - 1)]
