class_name CombinedDamageModifier extends RefCounted

## The multiplicative damage channel (Concept_Document.md 1.1.3-1.1.4): a product
## assembled fresh for one damage resolution and discarded with it, never cached on a
## character, a skill, or the resolver. Contributions are grouped by mechanic identity
## (buff type, debuff type, trait resource, skill effect) — never by which character
## applied them. Contributions sharing a key add into one bucket; distinct keys multiply:
## Product() = Π over keys (1 + bucket[key]).

## Shared key for a caster's trait-resource damage multiplier (TraitSkillResult's
## _damage_multiplier), read by both DamageEffect and ClearZoneEffect.
const TRAIT_RESOURCE_KEY: StringName = &"trait_resource"

var _buckets: Dictionary[StringName, float] = {}

## Adds p_fraction into p_key's bucket. A bucket clamps at -1.0 so a damage-reducing
## contribution cannot invert the sign of its (1 + bucket) factor.
func Contribute(p_key: StringName, p_fraction: float) -> void:
	_buckets[p_key] = maxf(_buckets.get(p_key, 0.0) + p_fraction, -1.0)

func ContributeAll(p_contributions: Dictionary[StringName, float]) -> void:
	for key: StringName in p_contributions:
		Contribute(key, p_contributions[key])

func Product() -> float:
	var product: float = 1.0
	for key: StringName in _buckets:
		product *= 1.0 + _buckets[key]
	return product

## Read-only view of the assembled buckets, for per-source damage attribution.
func Buckets() -> Dictionary[StringName, float]:
	return _buckets
