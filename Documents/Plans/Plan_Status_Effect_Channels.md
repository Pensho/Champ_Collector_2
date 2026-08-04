# Plan: Status Effect Channels

Phase 2 of `Plan_Blowout_Alignment.md`. Every status effect and every zone is classified
into one of three buckets from `Concept_Document.md` 1.1.3 — channel 1 (scaled
attributes), channel 2 (its own factor in the combined modifier), or **enabler** (creates
or protects the burst window, produces no damage, held to the collapse test in 1.1.6).

A status is broken in one of two ways, and only these two:

* It sits in no bucket — it neither moves an attribute, nor supplies a factor, nor passes
  the collapse test.
* It is filed as a damage factor but delivers a linear bump.

The roster is 58 statuses: 32 `Buff_Type` and 26 `Debuff_Type` entries in
`Scripts/common_enums.gd`, one `.tres` each in `Data/Status_Effects/`, all 58 described in
`Concept_Document.md` 3.2.3. Phase 1 landed `CombinedDamageModifier`, so channel 2 has a
home to file into; this plan is the first pass that puts content in it deliberately.

## Ordering principle

The structural fixes come before the content pass. `CombinedDamageModifier` currently
groups several sources by *category* rather than by mechanic identity, which is invisible
while each category holds one status and becomes wrong the moment this plan files a second
one. Classifying content against keying that is known to be wrong would bake the error in.

## Phase 1 — Bucket keys by mechanic identity — done

**Shipped:** `_TRAIT_OUTGOING_BONUS_KEY`, `_DAMAGE_MULTIPLIER_BUFF_KEY`, and
`_OPPORTUNIST_BUFF_KEY` are gone. Trait outgoing-damage bonus now keys to the trait's own
class identity; the self-tick damage-multiplier buff and Opportunist each key per buff type,
accumulating additively within a key (`battle_resolver.gd`'s `_ResolveDamage`,
`status_effect_resolver.gd`'s `_TriggerExistingCasterBuffs` and the renamed
`_OpportunistDamageFactors`). `_REAGENT_DAMAGE_BONUS_KEY` was kept as one mechanic — decided,
not deferred; see its doc comment. Tests landed in `test_combined_damage_modifier_resolution.gd`,
reading `CombatResult.combined_damage_modifier.Product()` directly rather than final damage
(`Skills.MitigatedDamage` is nonlinear, so a damage ratio does not equal a modifier ratio);
the unit-level composition law was already covered in `test_combined_damage_modifier.gd`, so
that file needed no change. See `## Findings` for two items a fresh-context review raised.

`Scripts/Battle/battle_resolver.gd:21-24` declares four keys — `trait_outgoing_bonus`,
`reagent_damage_bonus`, `damage_multiplier_buff`, `opportunist_buff` — contributed at
`battle_resolver.gd:707-712`. Each names a *class* of source, so every member of that
class adds into one bucket instead of multiplying. That contradicts the composition law in
1.1.3 and is the same defect Technical Design Document 15.12 records as resolved for
`bonus_per_debuff_on_target`.

`_DAMAGE_MULTIPLIER_BUFF_KEY` and `_OPPORTUNIST_BUFF_KEY` are the two this plan will
break: both are gathered by scanning for a `MagnitudeKind`
(`status_effect_resolver.gd:284`, `:532`), so a second buff of that kind shares the bucket.
Key them by buff type instead, following the pattern already in
`damage_effect.gd:_ContributeDebuffFactors` (`StringName(Types.Debuff_Type.keys()[type])`).
`_TRAIT_OUTGOING_BONUS_KEY` gets the same treatment keyed to the trait resource; only
`BloodscentGraft` overrides `GetOutgoingDamageBonus` today, so this is pre-emptive.

`_REAGENT_DAMAGE_BONUS_KEY` reads a single battle-persistent running total
(`_damage_dealt_bonus`, `AggregateDamageMultipliers` at `battle_resolver.gd:310`), so its
sources are already summed before the modifier sees them and cannot be separated without
changing that storage. Decide here whether reagent and graft bonuses are one mechanic (keep
as is, and say so) or distinct ones (Phase 6's problem, `Plan_Itemization_Channels.md`).

Tests extend `Tests/unit/test_combined_damage_modifier.gd` and
`test_combined_damage_modifier_resolution.gd`: two distinct channel-2 buffs on one caster
must multiply, two instances of the same mechanic must add.

## Phase 2 — Zone factors keyed by zone, not by turn-bar section — done

**Shipped:** `Zone._placing_skill_name` is renamed `_source_name` (its meaning widened to
"the placing skill's name, or the graft/trait that placed it") and threaded onto
`SkillCastContext.zone_source_name` at `zone_resolver.gd`'s `_ResolveZoneEffect`.
`damage_effect.gd:_SkillKey` now returns `StringName("Zone: %s" % p_context.zone_source_name)`
in zone-trigger mode (falling back to the bare `&"Zone"` only when a zone has no name, which
no production placement site does after this phase); `zone_ID`/turn-bar section keeps its
existing meaning everywhere else and is simply no longer read for keying. Of the two callers
that construct a `ZoneEffect` directly, `living_bloom_graft.gd` placed its zone with no name and
now passes `"Living Bloom"`; `calibration_trait.gd` already passed `"Raise the Frame"`. `ClearZoneEffect`'s Refutation
lookup (`_ReduceZoneSkillCooldown`) still matches the source name against the owner's skill
names and still no-ops for a graft-placed zone, unchanged in behaviour.

One correction to this phase's stated defect: the "share one bucket and add" half never
happens today, because `DamageEffect.Resolve` builds a fresh `CombinedDamageModifier` per
target per effect, so only one zone key is ever contributed into a given modifier instance.
The fix is still real — it corrects the bucket *names* surfaced through
`CombinedDamageModifier.Buckets()` (which Phase 4 of the master plan,
`Plan_Burst_Presentation.md`, consumes) and restores the mechanic-identity invariant for
any later phase that lets zone factors reach a shared modifier — but the tests assert on
bucket keys, not on damage totals, since two zone kinds never actually compounded.

Tests landed in `Tests/unit/test_zone_skills.gd` (bucket named for the zone's source, two
zone kinds in one section getting distinct keys, the same zone kind across two sections
sharing one key) and `test_zone_knowledge_scaling.gd` (`Zone.CreateNew` stores and defaults
`_source_name`). A planned fourth case for the ramp key (`bonus_per[Uses_This_Battle]`) was
dropped: zone-trigger contexts always construct with `use_count = 0`
(`zone_resolver.gd`'s `_ResolveZoneEffect`), so that ramp bonus can never produce a nonzero
multiplier in zone mode regardless of this phase's keying — pre-existing dead code, not
something this phase should paper over with an unreachable assertion.

`CombinedDamageModifier.TRAIT_RESOURCE_KEY`'s category-keyed nit (both `DamageEffect` and
`ClearZoneEffect` still contribute under the shared key) was left as-is; Phase 6's Technical
Design Document write-up owns naming it as the known exception.

## Phase 3 — Classification pass — done

**Shipped:** every one of the 58 statuses carries a settled verdict below; no `decide` rows
remain. The ledger is grouped by `StatusEffectData.MagnitudeKind`
(`Scripts/Battle/status_effect_data.gd`) because the kind already determines which pipeline a
status reaches. Verdicts: **conforms** (no work), **rework** (fails the rejection test as
written; specified precisely enough to implement), **provisional** (the verdict depends on a
question owned by a later phase, named where it is settled).

Every `rework` this pass specifies is a code change, and no phase of this plan previously
owned implementing them — Phase 4 is prose, Phase 5 is the cap, the old Phase 6 was
documentation. Phase 6 below is new and exists to carry that work; documentation is renumbered
Phase 7.

### Channel 1 — attribute movers (23, all conform)

Kind 0 with `attribute_modifiers`, plus kinds 4, 5, 13. Buffs: Empower, Fortify, Attune,
Haste, True_Aim, Clarity, Insight, Frenzy, Rush, Exhert, Phalanx_Guard, Sanction, Vigor,
Keen_Edge, Lethal_Precision, Wanderlust. Debuffs: Enfeeble, Expose_Weakness, Suppress,
Slow, Blind, Unravel, Confound.

Channel 1 is additive by definition, so a linear attribute bump is not a defect here.
Three notes carry into the write-up rather than into rework:

* **Defence debuffs cannot participate in a burst.** 1.1.4 states Defence stops mattering
  at burst scale — varying `Defense_Ignore_Factor` across its full range moves a burst by
  under 2%. Expose_Weakness is therefore a channel-1 effect whose real role is pressure
  during the build-up. Record the role; do not rework it toward damage.
* **Denial-role statuses are dual-classified.** Blind moves Accuracy (channel 1) but is
  picked to stop an application (enabler). Both entries, per the master plan.
* **Wanderlust is random.** A random attribute does not compose — the player cannot
  assemble around it. Flag as a Phase 5 kit question (`Plan_Kit_Blowout_Audit.md`), not a
  status rework.

### Channel 2 — damage factors (2)

* **Daunting_Strength** (kind 2, 2.0x next attack) — conforms, **with a narrowed claim**.
  It is a clean factor keyed through `_damage_multiplier` only when the buff's one active
  turn also lands an attack. The banking defect in `## Findings` below (a caster who is
  stunned or casts a non-damaging skill while it is active can bank the fraction on both
  ticks before it expires, landing 3x instead of 2x) is real and unresolved by Phase 1's
  keying fix. Phase 6 below banks the fraction at resolution time — when `_ResolveDamage`
  actually contributes it — instead of at the self-tick, removing the double-bank
  opportunity entirely rather than only reducing it.
* **Opportunist** (kind 6, +10% damage per debuff on target) — **rework**.
  `_OpportunistDamageFactors` (`status_effect_resolver.gd:535-544`) returns `1 + 0.10 ×
  debuff_count` from one summed bucket: linear in debuff count, where the structurally
  identical `bonus_per_debuff_on_target` (`damage_effect.gd:_ContributeDebuffFactors`) gets
  one bucket per debuff type and compounds. Five debuffs give 1.5x instead of 1.61x, and the
  gap widens exactly where the pillar wants it to. This is failure mode two verbatim.
  Rework: change `_OpportunistDamageFactors` to iterate the target's active debuffs and
  contribute one bucket per **debuff type present**, keyed
  `StringName(Types.Debuff_Type.keys()[type])` — the same key `_ContributeDebuffFactors`
  already uses, so Opportunist composes with `bonus_per_debuff_on_target` instead of
  double-counting under a separate `Buff_Type` key. Test: Opportunist plus two distinct
  debuff types must multiply, not sum with a `bonus_per_debuff_on_target` factor on the same
  debuff type.

### Enablers (21, run against the collapse test)

Kind 0 with no attributes, plus kinds 10 and 12. Aegis, Deathward, Premonition, Rehearsed,
Mirror_Coat, Luck, Hexed, Steadfast, Slipstream, Resonance, Catalyst, Barrier (12), Blight
(10), Stun, Fatigue, Refracted, Warped, Signed_Writ, Severance, Sequence_Lock, Anchor.

Most pass on sight — 1.1.3 names Blight, Aegis, Premonition, Stun, and Anchor as its own
examples of the class, and Deathward and Barrier are the same shape. Four owed an argument;
all four are now settled:

* **Luck / Hexed** (roll twice, take better/worse) — **enabler, narrowed**. `_RollFavoring`
  currently rerolls three things: the 0.95–1.05 damage spread (`battle_resolver.gd:673`),
  the crit roll (`:695`), and both sides of the debuff resist check
  (`status_effect_resolver.gd:185-186`). Verdict: the damage spread fails the collapse test
  (a sub-1% variance reducer — removing it changes nothing material) and drops out; the crit
  roll and the resist check both gate whether a setup lands and pass. Rework (Phase 6 below):
  the damage-spread roll at `battle_resolver.gd:673` stops calling `_RollFavoring` and becomes
  a plain `randf_range`; keep `_RollFavoring` at `:695` and both call sites in
  `status_effect_resolver.gd:185-186`.
* **Rehearsed** (next non-basic skill skips cooldown) — **enabler, conforms**. An extra use
  of a setup skill inside the window is an assembly step, not a bump; it passes the collapse
  test because removing it can mean the setup skill simply isn't available again in time.
* **Catalyst** (+50% next reagent) — **provisional enabler**. It passes only if reagents
  gate a burst; that question belongs to `Plan_Itemization_Channels.md`
  (`Plan_Blowout_Alignment.md` Phase 6), named here explicitly as the ratifying phase rather
  than left open. Until that phase runs, treat Catalyst as an enabler by default — it is not
  a rework candidate either way, since a reagent-potency bump is not a damage factor.
* **Warped** (all damage scaling forced to Mysticism) — **dual-classified**, the same shape
  as Blind above: channel 1 by mechanism (it re-points which attribute channel 1 reads rather
  than adding a term of its own) and **enabler by role**. Cast on a boss that hits hard off
  Attack but is weak in Mysticism, it forces that boss's real damage through its weak stat —
  denial that protects the team's survival, not a passive attribute swap. Reworking it toward
  a damage factor would be wrong for the same reason it would be wrong for Blind. This
  settles 3.2.3's open question: **damage scaling only** — non-damage calculations (healing,
  absorb values, turn-bar effects) stay on their native attribute. Phase 7 rewrites 3.2.3's
  Warped entry to state both the mechanism and the enabler role, rather than leave either
  open.

### The residue — statuses in no bucket cleanly (12)

These are where the real work is.

| Status | Kind | As written | Verdict |
| --- | --- | --- | --- |
| Burning | 1 | 4% of target max Health per stack, per tick | **enabler / factor condition** — its tick stays build-up pressure; its composable value is as a debuff *type* other mechanics key off (`bonus_per_debuff_on_target`, the reworked Opportunist above), the cheap answer this ledger prefers over giving it a factor of its own. Stacking (`stackable = true`) is a Phase 5 cap question, not this phase's. |
| Regeneration | 1 | heals 4% max Health per tick | **enabler, conforms** — corrected verdict; see the fight-level collapse test note in `## Watch for` below. Sustained self-healing against a slow, hard-hitting matchup is "buying time to survive to the trigger," the same shape as Stun/Anchor buying a turn, only continuous instead of punctual and self-directed rather than requiring a target. No rework. |
| Bleed | 9 | 40% of caster Attack, snapshotted | **rework** — a snapshot cannot read the modifier assembled at burst time, so it is linear by construction. Phase 6 below routes the tick through `_ResolveDamage` (or an equivalent call that builds a `CombinedDamageModifier` at tick time) instead of reading the frozen `debuff.value`, so a caster's channel-2 state at tick time is what scales the hit. |
| Plague | 9 | 30% of caster Mysticism, snapshotted, spreads on expiry | Two verdicts: the snapshot has Bleed's problem — **rework**, same fix as Bleed. The expiry spread is **channel 3 (cascade)** — a triggered separate resolution — and is out of this plan's scope; it belongs to `Plan_Cascade_Resolution.md` (`Plan_Blowout_Alignment.md` Phase 3), named here as the owning phase. |
| Temporal_Leak | 11 | 5% of own Speed per 10% bar moved | **rework** — scales off the victim's own Speed, a linear tax with no player-built term. Phase 6 below turns it into tempo denial — a condition other mechanics (a cascade trigger, a factor keyed off "target has Temporal_Leak") can read — rather than a damage source in its own right. |
| Mana_Burn | 0 | damage when the target uses a non-basic skill | **enabler** — denial with damage attached; the damage stays incidental to the punish, and it is not given a factor. |
| Overflow | 0 | Mysticism AoE on expiry | **channel 3 (cascade)** — an expiry-triggered separate resolution, the same shape as Plague's spread. Its defect (the fresh, unseeded `CombinedDamageModifier` in `ResolveTraitDamage`) is real but is the master plan's Phase 3 cascade work to fix, not this plan's; the corresponding item in `## Findings` below is narrowed to point there instead of asking Phase 3 of *this* plan to resolve it. |
| Dead_Weight | 14 | −3% own turn bar on damage taken | **enabler, conforms** — corrected verdict. Filed as a debuff, it is placed on a threat and denies that threat's tempo every time it lands a hit — the same shape as Battle_Orders (already an enabler) aimed at an opponent instead of at allies. Slowing a hard hitter's next action is protecting the window exactly as Stun/Anchor do, just incrementally. No rework. |
| Battle_Orders | 15 | +5% bar to all allies on damage taken | **enabler, conforms** — tempo generation that scales with hit count is cascade-adjacent: the extra ally actions it buys are exactly what a burst window is assembled from. Passes the collapse test as written; no rework. |
| Spotlight | 16 | 1.5x targeting weight, −10% damage taken | **Enabler, conforms in full** — corrected verdict. Both halves are one survival tool, not a factor plus a bump riding along it: drawing focused fire away from the pieces the burst depends on, and taking less of what lands, are the two sides of the same tank kit. Judged only against "does this feed a burst," the reduction looked like an isolated bump; judged against the fight, a sustained 10% reduction across a matchup is exactly the kind of non-combo survival budget the collapse test is meant to protect. No rework. |
| Exposed_Facet / Cracked_Facet | 7 / 8 | +15 crit chance / +25 crit damage against the holder | **channel 2, via the crit path**. Crit already multiplies with everything else in `_ResolveDamage`, so these behave as factors without formally being inside `CombinedDamageModifier`. This ledger records the bucket; whether crit becomes a fourth multiplicative path in the modifier itself (as opposed to the separate crit-chance/crit-damage terms it is today) is Phase 4's boundary question, deferred there rather than settled here. |

Rework does not mean "give it a damage factor". Burning and Temporal_Leak become factor
*conditions* other mechanics key off rather than damage sources of their own, which is
the cheaper and more composable answer.

## Phase 4 — Where the modifier's boundary sits

Three damage-relevant status paths run outside `CombinedDamageModifier` today, and the
plan must state deliberately whether that is right rather than leaving it to accident:

* **Target-side reduction.** Spotlight's `IncomingDamageReduction` multiplies final damage
  at `battle_resolver.gd:599`, after mitigation. 1.1.4 says the modifier multiplies the
  *caster's* scaled aggregate; a defensive reduction is not a caster-side term, and moving
  it pre-mitigation would make it stronger than written. Position to argue: it stays out,
  and target-side reductions are their own path by design.
* **The crit term.** Exposed_Facet and Cracked_Facet feed `_AttackerCritChanceBonus` and
  `_AttackerCritDamageBonus` (`battle_resolver.gd:697-701`). Crit already multiplies with
  everything, so these behave as factors without being in the channel — but crit damage is
  reduced by target Knowledge, and crit chance saturates at 100. State whether crit is a
  fourth multiplicative path or should be folded in.
* **Barrier.** Absorbs after the fact (`_AbsorbWithBarrier`). Enabler; stays out.

Output is prose in `Concept_Document.md` 1.1.4 naming the modifier's boundary, so Phases 5
and 6 do not each re-litigate it.

## Phase 5 — The status effect cap

`GameBalance.MAX_STATUS_EFFECTS = 8` (`Scripts/game_balance.gd:76`), enforced by
`Skills.HasMaxStatusEffects` (`skills.gd:273`) as a **shared pool across buffs and
debuffs**, at six sites in `status_effect_resolver.gd` (`ApplyBuff`, `ApplyDebuff`,
`CastDebuff`, `_TriggerMirrorCoat`, `_TriggerRushStun`, `_SpreadPlague`). Overflow is
dropped silently — no `CombatResult` is emitted, which is why
`SkillCastContext.status_effect_attempted/landed` exists for zones to read.

Two problems the pillar creates:

* The composition law rewards assembling many *distinct* mechanics on one target. A shared
  eight-slot pool is a hard ceiling on how many factors a burst can carry, and stackable
  Burning and Haste spend slots on instances of one mechanic. 1.1.4 says cap what accrues
  automatically and leave uncapped what costs the player an action or a resource — a
  deliberately cast status is the second case, and the current cap does not distinguish.
* Silent drops are a legibility problem that Phase 4 of the master plan
  (`Plan_Burst_Presentation.md`) inherits: a player whose burst fails because the eighth
  slot was full is given no reason.

Pick one and write it down: raise the number, split the pool per category, exempt
deliberately cast statuses while capping self-accruing ones, or keep eight as a deliberate
ceiling and justify it against 1.1.4. Whichever way it goes, emit a result on the drop.

No test covers `MAX_STATUS_EFFECTS` today — grep finds no reference under `Tests/`. This
phase adds one.

## Phase 6 — Status effect reworks

Implements the **rework** verdicts from Phase 3. Each item names its mechanism change and the
call sites it touches; per `## Watch for` below, a mechanism change sweeps the trait/graft
scripts under `Scripts/Character/character_traits/` and the hardcoded status checks in
`battle_resolver.gd`, `zone_resolver.gd`, `battle.gd`, and `skills.gd`, not only the status's
`.tres`. Each item lands with its own test in `Tests/unit/`.

* **Opportunist** — key `_OpportunistDamageFactors` (`status_effect_resolver.gd:535-544`) per
  debuff type present on the target, matching `_ContributeDebuffFactors`'s keying
  (`damage_effect.gd:60-65`). Test: two distinct debuff types multiply; Opportunist and
  `bonus_per_debuff_on_target` on the same debuff type do not double-count.
* **Daunting_Strength** — bank the `DamageMultiplier` fraction into `_damage_multiplier` at
  the point `_ResolveDamage` contributes it, not at `_TriggerExistingCasterBuffs`'s self-tick,
  so a caster who is stunned or casts a non-damaging skill while it is active cannot bank it
  twice. Test: the banking scenario in `## Findings` below lands 2x, not 3x.
* **Luck / Hexed** — stop routing the damage-spread roll through `_RollFavoring` at
  `battle_resolver.gd:673`; replace with a plain `randf_range(0.95, 1.05)`. Keep
  `_RollFavoring` for the crit roll (`:695`) and both debuff-resist rolls
  (`status_effect_resolver.gd:185-186`). Test: holding Luck or Hexed no longer changes the
  damage-spread roll's distribution.
* **Bleed / Plague (snapshot)** — replace the frozen `debuff.value` tick read in
  `_TriggerExistingCasterDebuffs` (`status_effect_resolver.gd:217-268`,
  `CasterAttributeSnapshotPercent` case) with a tick-time resolution that builds and consults
  a `CombinedDamageModifier`, so the caster's channel-2 state at tick time scales the hit
  instead of the state at application time. Test: a channel-2 buff gained on the caster after
  Bleed/Plague is applied changes the tick's damage.
* **Temporal_Leak** — remove the Speed-scaled damage tick in `AccumulateTurnBarMovement`
  (`battle_resolver.gd:234-262`) and replace it with a readable condition (e.g. a flag or
  count other mechanics can key a factor or a cascade trigger off) rather than a damage
  source in its own right. Test: Temporal_Leak alone no longer deals damage; the new
  condition is readable by a test double mechanic.

Regeneration, Dead_Weight, and Spotlight's −10% were originally scoped here as reworks; the
fight-level collapse-test correction in `## Watch for` above reclassified all three as
enablers that already conform, so they carry no implementation item.

## Phase 7 — Documentation

* `Concept_Document.md` 3.2.3 gains a short lead paragraph stating the classification rule,
  and **each of the 58 entries is tagged with its bucket inline**. That tagging is the
  durable record of this plan; the ledger above dies with the file.
* Every status Phase 3 marks **rework** has its 3.2.3 description rewritten to the new
  mechanic, once Phase 6 has shipped it. Opportunist's current wording ("+10% damage per
  debuff on the target") states the linear form and will contradict the reworked behaviour
  until it is replaced; 1.1 outranks 3.2.3, so 3.2.3 is the section that changes. This
  includes Warped (state both the damage-scaling-only mechanism and its enabler role) and the
  reworked Bleed/Plague/Temporal_Leak entries. Regeneration, Dead_Weight, and Spotlight need
  no description change — their existing 3.2.3 wording already matches their (corrected)
  enabler verdict.
* `Concept_Document.md` 1.1.4 gains the modifier-boundary sentence from Phase 4 and the
  cap decision from Phase 5. 3.2.3 currently refers to "the status-effect cap" without
  ever stating a number — the Phase 5 decision lands there, not only in
  `GameBalance.MAX_STATUS_EFFECTS`.
* `Technical_Design_Document.md` 7.4 records the keying changes from Phases 1 and 2, and the
  Phase 6 rework mechanisms.
* `Plan_Blowout_Alignment.md` Phase 2 is marked done in the style its Phase 1 entry uses.

## Findings

* **`ResolveTraitDamage` passes an unseeded modifier** — Concern, resolved in Phase 3 of
  `Plan_Blowout_Alignment.md`. `battle_resolver.gd:392-393` constructs a bare
  `CombinedDamageModifier.new()`, so trait-sourced damage — including Overflow's expiry
  burst and every graft that deals damage directly — sees only the four contributions
  `_ResolveDamage` adds internally and none of the skill-side ones. Left to the master
  plan's cascade phase because trait-triggered damage is exactly what that phase re-homes;
  Phase 3 of this plan classifies Overflow as channel 3 (cascade) independent of this
  defect, so the classification no longer waits on the fix — only the correctness of
  Overflow's damage does.
* **Daunting_Strength can bank its fraction more than once** — Concern, for Phase 6 of this
  plan. `_TriggerExistingCasterBuffs` decrements every active buff's duration each turn
  regardless of `applies_on_self_tick`, but only banks the `DamageMultiplier` fraction into
  `_damage_multiplier` while doing so; that dictionary is cleared only inside
  `_ResolveDamage`, which returns early when a skill deals no damage. A caster who is
  stunned or casts a non-damaging skill while Daunting_Strength (duration 2) is active
  banks its +100% on both ticks before the buff expires, landing 3x (additive across two
  banked instances) instead of the intended 2x "next attack". Phase 1's keying fix reduced
  the error (the old code compounded the same state to 4x) but did not remove it. Phase 3's
  ledger narrows the "clean factor, consumed per resolution" claim to when the buff's one
  active turn also lands the attack; Phase 6 removes the gap by banking at resolution time
  instead of at the self-tick.
* **`CombinedDamageModifier.TRAIT_RESOURCE_KEY` still groups by category** — Nit, for
  Phase 2 or Phase 7's Technical Design Document write-up. `damage_effect.gd` and
  `clear_zone_effect.gd` both contribute `TraitSkillResult._damage_multiplier` under the
  shared `&"trait_resource"` key, the same shape Phase 1 removed from the trait
  outgoing-damage bonus one line away in `battle_resolver.gd`. Harmless today — only one
  trait can be equipped — but the Technical Design Document write-up should not claim every
  resolver-owned key is now mechanic-identity-keyed without naming this one exception.

## Watch for

* **Do not convert enablers into damage factors.** The target is not a roster where every
  status touches damage. An enabler that passes the collapse test needs no rework.
* **Dual classification is a valid result**, not an unresolved one — a status can be
  channel 1 by mechanism and enabler by role (Blind, Warped).
* **The collapse test is fight-level, not burst-narrow.** The first pass through this ledger
  read "protects the window" as "feeds a specific burst combo," and that misjudged three
  statuses — Regeneration, Dead_Weight, Spotlight — whose real value is a non-combo player
  decision: spend a turn (or a passive trickle) surviving sustained pressure rather than
  racing to assemble a burst. That decision is exactly what 1.1.1 calls out ("the tension is
  'can I survive to the trigger'"), so a status that only ever pays off by keeping the team
  alive against a hard matchup, never by multiplying a burst, still passes as an enabler. Ask
  "would removing this change how the fight actually goes, including matchups where the
  player chooses not to race a combo," not "does this feed my burst," before filing anything
  as a linear bump.
* **Do not uncap Momentum, Arcane Instability, or Steel and Sea stacks.** 1.1.4 states they
  are correct as written because they accrue automatically. They are outside this plan.
* **Rework is not always upward.** Removing a linear damage source (Temporal_Leak's Speed
  tax becoming a readable condition, not a stronger hit) is as valid an outcome as replacing
  it with a factor, and cheaper.
* Statuses are reached by roughly twelve trait and graft scripts under
  `Scripts/Character/character_traits/` and by hardcoded checks in `battle_resolver.gd`,
  `zone_resolver.gd`, `battle.gd`, and `skills.gd`. A rework that changes a status's
  mechanism has to sweep those call sites, not only its `.tres`.
* Per `CLAUDE.md`, no code or data-file comment written by this plan may name the plan, a
  phase, or a batch — plans are deleted on completion and the reference would dangle.
