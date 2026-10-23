class_name BattleEffectLayer extends Node2D

## The battle's pooled effect scene instances. Reserved at Battle.Init, hidden until played,
## reused once finished, and never freed during the battle.

var _pool: Dictionary[PackedScene, Array] = {}


## Instances p_archetype until p_count copies exist.
func Reserve(p_archetype: PackedScene, p_count: int) -> void:
	if(null == p_archetype):
		return
	var instances: Array = _pool.get_or_add(p_archetype, [])
	while(instances.size() < p_count):
		var instance: SkillEffectScene = p_archetype.instantiate() as SkillEffectScene
		if(null == instance):
			push_warning("Effect scene %s does not have a SkillEffectScene root." % p_archetype.resource_path)
			return
		instance.hide()
		add_child(instance)
		instances.append(instance)


## Enough copies of an echo archetype to cover echoes overlapping at the fastest echo pace.
func ReserveForEchoes(p_archetype: PackedScene) -> void:
	Reserve(p_archetype, 1)
	var sample: SkillEffectScene = Peek(p_archetype)
	if(null == sample):
		return
	var overlapping: int = ceili(sample.Length() / BurstPacing.MINIMUM_DELAY)
	Reserve(p_archetype, clampi(overlapping, 1, CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION))


## An idle instance of p_archetype, or null when every reserved one is playing. Playing it
## marks it busy.
func Peek(p_archetype: PackedScene) -> SkillEffectScene:
	for instance: SkillEffectScene in _pool.get(p_archetype, []):
		if(not instance.visible):
			return instance
	return null
