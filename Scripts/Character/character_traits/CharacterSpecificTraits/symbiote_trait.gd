class_name SymbioteTrait extends CharacterTrait

## Placeholder for the Symbiote's passive slot before it grafts: shows the "Graft" icon
## and explains the passive the same way every other role's trait icon does. Character.
## ApplyGraft() overwrites _trait with the acquired GraftEffect once grafting happens.
func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Hemoclarity/Hemoclarity.png")
	_title = "Graft"
	_body = ("Target a living enemy and graft onto it. " +
			"This grants an effect, scaling with " +
			"this Symbiote's own rarity. Grafting is permanent and can " +
			"never be undone or replaced.")
