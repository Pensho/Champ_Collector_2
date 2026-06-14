class_name RecruitmentMenu extends Control

const BONE_TIER: FortuneFavorTier = preload("res://Data/Recruitment/Bone_Tier.tres")

@export var _favor_count_label: Label

var _info_option: ButtonWithOptions
var _confirm_option: ButtonWithOptions
var _result_option: ButtonWithOptions

func Init(_p_context_container: ContextContainer) -> void:
	_info_option = load("uid://c7smqpmfvs0ih").instantiate()
	add_child(_info_option)
	_info_option.position = Vector2i((get_window().size * 0.5) - (_info_option.GetSize() * 0.5))
	_info_option.hide()

	_confirm_option = load("uid://c7smqpmfvs0ih").instantiate()
	add_child(_confirm_option)
	_confirm_option.SetLeftButton("Recruit", _on_confirm_recruit)
	_confirm_option.position = Vector2i((get_window().size * 0.5) - (_confirm_option.GetSize() * 0.5))
	_confirm_option.hide()

	_result_option = load("uid://c7smqpmfvs0ih").instantiate()
	add_child(_result_option)
	_result_option.position = Vector2i((get_window().size * 0.5) - (_result_option.GetSize() * 0.5))
	_result_option.hide()

func _ready() -> void:
	Refresh()
	main.GetInstance()._resources.resources_changed.connect(Refresh)

func Refresh() -> void:
	_favor_count_label.text = str(main.GetInstance()._resources._fortunes_favor)

func _on_back_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://bx1wl65s4cu0j"
	main.GetInstance().change_scene(context_container)

func _on_favor_button_up() -> void:
	var resources: ResourceHandler = main.GetInstance()._resources

	if(main.GetInstance()._character_collection.IsTheCollectionFull()):
		_info_option.SetText("Roster Full", "Your roster is full. Make room before recruiting.")
		_info_option.show()
		return

	if(resources._fortunes_favor < 1):
		_info_option.SetText("No Fortune's Favor", "You don't have any Fortune's Favors.")
		_info_option.show()
		return

	_confirm_option.SetText("Recruit", "Spend 1 Fortune's Favor to recruit?")
	_confirm_option.show()

func _on_confirm_recruit() -> void:
	_confirm_option.hide()
	if(not main.GetInstance()._resources.SpendFortunesFavor(1)):
		return

	var rewards: Array[Dictionary] = RecruitmentManager.ResolveUse(BONE_TIER)
	var reward_descriptions: Array[String] = []
	for reward in rewards:
		match reward["type"]:
			RecruitmentManager.RewardType.CHAMPION:
				reward_descriptions.append("Recruited the " + reward["champion"]._name)
			RecruitmentManager.RewardType.SILVER:
				reward_descriptions.append("+" + str(reward["amount"]) + " Silver")
			RecruitmentManager.RewardType.SUPPLIES:
				reward_descriptions.append("+" + str(reward["amount"]) + " Supplies")

	_result_option.SetText("Recruitment Result", "You received: " + ", ".join(reward_descriptions) + ".")
	_result_option.show()
