class_name TeamSweep extends RefCounted

## Shared roster-enumeration helper for the Tests/manual/ sweep scripts
## (team_corpus_sweep.gd, prescription_sweep.gd): given a roster and an optional manifest
## override, scores every 3-preset combination through BurstReachability.ScoreTeam and
## returns one row per team. Lives outside Scripts/Debug/burst_reachability.gd because it
## enumerates a roster, not a single team — BurstReachability.ScoreTeam's own contract stays
## "given three presets and nothing else".

const Manifest = preload("res://Scripts/Debug/kit_contribution_manifest.gd")


## Reduces p_presets to one entry per distinct Role, keeping whichever occurrence comes first.
## Several presets can field the same Role — same trait, same three skills
## (kit_contribution_manifest.gd's header note: the Lancer Role is fielded by both
## Centaur_Lancer.tres and Knight.tres) — and burst reachability is a property of the Role's
## kit, not of the preset. Scoring more than one preset per Role only adds duplicate-kit teams
## to a sweep, never new information. Callers pass their full known-preset list through this
## rather than hand-curating it, so a future preset sharing an existing Role is excluded
## automatically instead of requiring the list to be edited again.
static func DedupeByRole(p_presets: Array[CharacterPreset]) -> Array[CharacterPreset]:
	var seen_roles: Dictionary = {}
	var deduped: Array[CharacterPreset] = []
	for preset in p_presets:
		if(not seen_roles.has(preset._role)):
			seen_roles[preset._role] = true
			deduped.append(preset)
	return deduped


## p_manifest defaults to the real Manifest.MANIFEST; pass a modified copy to sweep the
## roster against a hypothetical kit change instead. p_enabler_floor defaults to the real
## BurstReachability.ENABLER_FLOOR rather than hardcoding 0, so a sweep honors the same
## viability exclusion ScoreTeam itself enforces — no behavior change at the current floor of
## 0, but the contract holds true the day the floor is raised.
static func ScoreAllTeams(
		p_presets: Array[CharacterPreset], p_manifest: Dictionary = Manifest.MANIFEST,
		p_enabler_floor: int = BurstReachability.ENABLER_FLOOR) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in p_presets.size():
		for j in range(i + 1, p_presets.size()):
			for k in range(j + 1, p_presets.size()):
				var team: Array[CharacterPreset] = [p_presets[i], p_presets[j], p_presets[k]]
				var best: BurstReachability.CandidateResult = (
						BurstReachability.ScoreTeam(team, p_enabler_floor, p_manifest).Best())
				if(null != best):
					rows.append({
						"names": [p_presets[i].resource_path.get_file(), p_presets[j].resource_path.get_file(),
								p_presets[k].resource_path.get_file()],
						"caster_index": best.caster_index,
						"skill_name": best.skill_name,
						"product": best.product,
						"contrast_ratio": best.contrast_ratio,
						"distinct_key_count": best.distinct_key_count,
						"enabler_count": best.enabler_count,
						"buckets": best.buckets,
					})
	return rows


## Nearest-rank percentile over an ascending-sorted array.
static func Percentile(p_sorted_ascending: Array[float], p_fraction: float) -> float:
	var index: int = int(ceil(p_fraction * float(p_sorted_ascending.size()))) - 1
	index = clampi(index, 0, p_sorted_ascending.size() - 1)
	return p_sorted_ascending[index]
