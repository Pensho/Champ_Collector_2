class_name BurstPacing extends RefCounted

## Presentation-only escalation curve for cascade floating text (Concept_Document.md 1.1.5,
## Technical_Design_Document.md 7.9). Pure static functions: no state, no game-rule effect.
## p_step is the cascade instance ordinal within the current action; step 0 means "not part
## of a cascade" and every function returns its unescalated base value in that case, so
## existing non-cascade text is unaffected. Bounded by CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION
## by construction of the callers, not enforced here.

const BASE_DELAY: float = 0.25
const MINIMUM_DELAY: float = 0.06
const DELAY_FALLOFF: float = 0.82
const BASE_SCALE: float = 1.0
const SCALE_GROWTH: float = 0.25
const MAXIMUM_SCALE: float = 3.0
const FULL_RED_STEP: int = 5
const BASE_OVERSHOOT: float = 1.4
const OVERSHOOT_GROWTH: float = 0.15
const MAXIMUM_OVERSHOOT: float = 5.0


static func DelayForStep(p_step: int) -> float:
	if p_step <= 0:
		return BASE_DELAY
	var delay: float = BASE_DELAY * pow(DELAY_FALLOFF, p_step)
	return maxf(delay, MINIMUM_DELAY)


static func ScaleForStep(p_step: int) -> float:
	if p_step <= 0:
		return BASE_SCALE
	var scale: float = BASE_SCALE + SCALE_GROWTH * p_step
	return minf(scale, MAXIMUM_SCALE)


static func OvershootForStep(p_step: int) -> float:
	if p_step <= 0:
		return BASE_OVERSHOOT
	var overshoot: float = BASE_OVERSHOOT + OVERSHOOT_GROWTH * p_step
	return minf(overshoot, MAXIMUM_OVERSHOOT)


static func ColorForStep(p_base_color: Color, p_step: int) -> Color:
	if p_step <= 0:
		return p_base_color
	var weight: float = clampf(float(p_step) / float(FULL_RED_STEP), 0.0, 1.0)
	return p_base_color.lerp(Color.RED, weight)
