class_name ImpactIntensity extends RefCounted

const MINIMUM_SHAKE_INTENSITY: float = 0.12

const MINIMUM_SQUASH: float = 0.02
const MAXIMUM_SQUASH: float = 0.14

const MINIMUM_SHAKE_AMPLITUDE: float = 2.0
const MAXIMUM_SHAKE_AMPLITUDE: float = 14.0
const MINIMUM_SHAKE_SECONDS: float = 0.08
const MAXIMUM_SHAKE_SECONDS: float = 0.22

const MINIMUM_FLASH_SECONDS: float = 0.03
const MAXIMUM_FLASH_SECONDS: float = 0.07


static func Normalize(p_amount: int, p_max_health: int) -> float:
	if p_max_health <= 0:
		return 0.0
	return clampf(float(p_amount) / float(p_max_health), 0.0, 1.0)


static func SquashForIntensity(p_intensity: float) -> float:
	return lerpf(MINIMUM_SQUASH, MAXIMUM_SQUASH, clampf(p_intensity, 0.0, 1.0))


static func ShakeAmplitudeForIntensity(p_intensity: float) -> float:
	if p_intensity < MINIMUM_SHAKE_INTENSITY:
		return 0.0
	return lerpf(MINIMUM_SHAKE_AMPLITUDE, MAXIMUM_SHAKE_AMPLITUDE, clampf(p_intensity, 0.0, 1.0))


static func ShakeSecondsForIntensity(p_intensity: float) -> float:
	if p_intensity < MINIMUM_SHAKE_INTENSITY:
		return 0.0
	return lerpf(MINIMUM_SHAKE_SECONDS, MAXIMUM_SHAKE_SECONDS, clampf(p_intensity, 0.0, 1.0))


static func FlashSecondsForIntensity(p_intensity: float) -> float:
	return lerpf(MINIMUM_FLASH_SECONDS, MAXIMUM_FLASH_SECONDS, clampf(p_intensity, 0.0, 1.0))
