class_name SoundPlaybackRules extends RefCounted

static func ShouldPlay(p_cue: SoundCue, p_active_count: int, p_seconds_since_last_start: float) -> bool:
	if p_cue.maximum_simultaneous > 0 and p_active_count >= p_cue.maximum_simultaneous:
		return false
	return p_seconds_since_last_start >= p_cue.minimum_interval

## Returns the first idle player; with none idle, the oldest non-looping one; -1 if every player loops.
static func ChoosePlayer(p_busy: Array[bool], p_looping: Array[bool], p_start_times: Array[float]) -> int:
	for index: int in p_busy.size():
		if not p_busy[index]:
			return index
	var oldest_index: int = -1
	for index: int in p_busy.size():
		if p_looping[index]:
			continue
		if oldest_index < 0 or p_start_times[index] < p_start_times[oldest_index]:
			oldest_index = index
	return oldest_index
