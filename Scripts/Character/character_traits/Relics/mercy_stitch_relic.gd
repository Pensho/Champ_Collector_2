class_name MercyStitchRelic extends RelicEffect

const FLOOR_FRACTION: float = 0.25
const DAMAGE_DRAWBACK: float = 0.40
const DRAWBACK_THRESHOLD: float = 0.40

var _triggered_this_battle: bool = false

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Mercy_Stitch/Mercy_Stitch.png")
	_title = "Mercy Stitch"
	_magnitude_by_rarity = [0.20, 0.25, 0.30, 0.35, 0.45]
	_body = ("Once per battle, damage that would take the wearer below 25% Health " +
			"instead leaves them there, and heals them for " + str(roundi(Magnitude() * 100)) +
			"% of max Health.\n" +
			"While at or below 40% Health, the wearer's damaging skills deal " +
			"40% less damage.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_triggered_this_battle = false

func GetDamageTakenHealthFloor(_p_owner_ID: int, p_incoming_health: int, p_max_health: int) -> int:
	if(_triggered_this_battle):
		return -1
	var floor_health: int = int(ceil(p_max_health * FLOOR_FRACTION))
	if(p_incoming_health >= floor_health):
		return -1
	_triggered_this_battle = true
	return mini(floor_health + int(round(p_max_health * Magnitude())), p_max_health)

func GetOutgoingDamageBonus(p_owner_ID: int, _p_target_ID: int, p_resolver: BattleResolver) -> float:
	var owner: Character = p_resolver.GetCharacters().get(p_owner_ID)
	var max_health: int = p_resolver.GetMaxHealth(p_owner_ID)
	if(null == owner or max_health <= 0
			or float(owner._current_health) / float(max_health) > DRAWBACK_THRESHOLD):
		return 0.0
	return -DAMAGE_DRAWBACK
