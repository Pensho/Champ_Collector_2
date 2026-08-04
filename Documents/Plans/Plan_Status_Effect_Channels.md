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

## Phase 2 — Zone factors keyed by zone, not by turn-bar section

`damage_effect.gd:_SkillKey` returns `StringName("Zone %d" % p_context.zone_ID)` in
zone-trigger mode, and `zone_ID` is the turn-bar section index — `ZoneResolver._zones` is
keyed by section, five of them (`GameBalance.NUMBER_OF_TURN_BAR_ZONES`). The grouping is
therefore backwards on both counts: two different zone kinds placed in the same section
over a fight share one bucket and add, while one zone kind placed in two sections yields
two independent factors that multiply.

`Zone._placing_skill_name` already carries the mechanic identity, populated from
`zone_effect.gd:17`. Route it into the key. Two callers place zones without a skill —
`living_bloom_graft.gd:35` and `calibration_trait.gd:109` pass no name and would fall back
to the empty string, sharing a bucket with each other; give each an identity.

This is the whole of what "a zone is a natural factor source and is currently not treated
as one" means mechanically. Zones also reach channel 2 through their `on_trigger` effects,
which resolve through the ordinary `SkillEffect` path and need no separate work.

Tests: `Tests/unit/test_zone_skills.gd` and `test_zone_knowledge_scaling.gd` are the
nearest homes; a new case covering two zone kinds in one section is the point of the phase.

## Phase 3 — Classification pass

Design-only. The ledger below is the starting position, grouped by
`StatusEffectData.MagnitudeKind` (`Scripts/Battle/status_effect_data.gd`) because the kind
already determines which pipeline a status reaches. Verdicts: **conforms** (no work),
**decide** (a judgement this plan owes), **rework** (fails the rejection test as written).

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

* **Daunting_Strength** (kind 2, 2.0x next attack) — conforms. A clean factor, consumed
  per resolution, already keyed through `_damage_multiplier`.
* **Opportunist** (kind 6, +10% damage per debuff on target) — **rework**.
  `_OpportunistDamageMultiplier` returns `1 + 0.10 × debuff_count` from one summed bucket:
  linear in debuff count, where the structurally identical `bonus_per_debuff_on_target`
  gets one bucket per debuff type and compounds. Five debuffs give 1.5x instead of 1.61x,
  and the gap widens exactly where the pillar wants it to. This is failure mode two
  verbatim. Rework to contribute one bucket per debuff type present, which also makes it
  compose with `bonus_per_debuff_on_target` correctly instead of double-counting under a
  different key.

### Enablers (21, run against the collapse test)

Kind 0 with no attributes, plus kinds 10 and 12. Aegis, Deathward, Premonition, Rehearsed,
Mirror_Coat, Luck, Hexed, Steadfast, Slipstream, Resonance, Catalyst, Barrier (12), Blight
(10), Stun, Fatigue, Refracted, Warped, Signed_Writ, Severance, Sequence_Lock, Anchor.

Most pass on sight — 1.1.3 names Blight, Aegis, Premonition, Stun, and Anchor as its own
examples of the class, and Deathward and Barrier are the same shape. Four owe an argument:

* **Luck / Hexed** (roll twice, take better/worse) — shifts a distribution. They currently
  reroll three things through `_RollFavoring`: the 0.95–1.05 damage spread
  (`battle_resolver.gd:673`), the crit roll (`:695`), and both sides of the debuff resist
  check (`status_effect_resolver.gd:185-186`). The collapse test asks whether removing the
  mechanic makes the fight go materially differently; the damage spread does not qualify,
  the resist check plausibly does when a setup depends on one debuff landing. **Decide**:
  narrow the reroll to the checks a setup hangs on, or accept them as variance reducers and
  say so.
* **Rehearsed** (next non-basic skill skips cooldown) — an extra use of a setup skill can
  be the difference between assembling a burst and not. Likely passes; state which.
* **Catalyst** (+50% next reagent) — passes only if reagents gate a burst, which is
  Phase 6's question. **Decide**, or defer to `Plan_Itemization_Channels.md` explicitly.
* **Warped** (all damage scaling forced to Mysticism) — currently a debuff that can *help*
  a Mysticism caster. 3.2.3 also records an open question about whether non-damage
  calculations are forced through Mysticism. **Decide**.

### The residue — statuses in no bucket cleanly (12)

These are where the real work is.

| Status | Kind | As written | Verdict |
| --- | --- | --- | --- |
| Burning | 1 | 4% of target max Health per stack, per tick | **rework** — scales off the target, never off anything the player builds, so it cannot join a burst and cannot be composed with |
| Regeneration | 1 | heals 4% max Health per tick | **decide** — enabler (survive to the trigger) if it passes collapse; a flat trickle if it does not |
| Bleed | 9 | 40% of caster Attack, snapshotted | **rework** — a snapshot cannot read the modifier that is assembled at burst time, so it is linear by construction |
| Plague | 9 | 30% of caster Mysticism, snapshotted, spreads on expiry | **decide** — the spread is a cascade shape and belongs to Phase 3 of the master plan; the snapshot has Bleed's problem |
| Temporal_Leak | 11 | 5% of own Speed per 10% bar moved | **rework** — scales off the victim's Speed; a linear tax |
| Mana_Burn | 0 | damage when the target uses a non-basic skill | **decide** — denial with damage attached; classify as enabler and let the damage be incidental, or give it a factor |
| Overflow | 0 | Mysticism AoE on expiry | **decide** — a real damage source that resolves through `ResolveTraitDamage` and so misses the assembled modifier (see Findings) |
| Dead_Weight | 14 | −3% own turn bar on damage taken | **rework** — 3% of a bar is a linear tempo bump; fails the collapse test |
| Battle_Orders | 15 | +5% bar to all allies on damage taken | **decide** — tempo generation that scales with hit count is closer to a cascade than to a bump; likely passes as an enabler |
| Spotlight | 16 | 1.5x targeting weight, −10% damage taken | **decide** — the targeting pull is a genuine enabler (it protects the setup pieces); the −10% is a linear bump riding along. Consider dropping the reduction rather than growing it |
| Exposed_Facet / Cracked_Facet | 7 / 8 | +15 crit chance / +25 crit damage against the holder | **decide** — see Phase 4 |

Rework does not mean "give it a damage factor". Burning, Bleed, and Temporal_Leak may
equally become enablers, or become factor *conditions* other mechanics key off, which is
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

## Phase 6 — Documentation

* `Concept_Document.md` 3.2.3 gains a short lead paragraph stating the classification rule,
  and **each of the 58 entries is tagged with its bucket inline**. That tagging is the
  durable record of this plan; the ledger above dies with the file.
* Every status the ledger marks **rework** has its 3.2.3 description rewritten to the new
  mechanic. Opportunist's current wording ("+10% damage per debuff on the target") states
  the linear form and will contradict the reworked behaviour until it is replaced; 1.1
  outranks 3.2.3, so 3.2.3 is the section that changes.
* `Concept_Document.md` 1.1.4 gains the modifier-boundary sentence from Phase 4 and the
  cap decision from Phase 5. 3.2.3 currently refers to "the status-effect cap" without
  ever stating a number — the Phase 5 decision lands there, not only in
  `GameBalance.MAX_STATUS_EFFECTS`.
* `Technical_Design_Document.md` 7.4 records the keying changes from Phases 1 and 2.
* `Plan_Blowout_Alignment.md` Phase 2 is marked done in the style its Phase 1 entry uses.

## Findings

* **`ResolveTraitDamage` passes an unseeded modifier** — Concern, resolved in Phase 3 of
  `Plan_Blowout_Alignment.md`. `battle_resolver.gd:392-393` constructs a bare
  `CombinedDamageModifier.new()`, so trait-sourced damage — including Overflow's expiry
  burst and every graft that deals damage directly — sees only the four contributions
  `_ResolveDamage` adds internally and none of the skill-side ones. Left to the cascade
  phase because trait-triggered damage is exactly what that phase re-homes; noted here
  because the Overflow verdict above depends on the answer.
* **Daunting_Strength can bank its fraction more than once** — Concern, for Phase 3.
  `_TriggerExistingCasterBuffs` decrements every active buff's duration each turn regardless
  of `applies_on_self_tick`, but only banks the `DamageMultiplier` fraction into
  `_damage_multiplier` while doing so; that dictionary is cleared only inside
  `_ResolveDamage`, which returns early when a skill deals no damage. A caster who is
  stunned or casts a non-damaging skill while Daunting_Strength (duration 2) is active
  banks its +100% on both ticks before the buff expires, landing 3x (additive across two
  banked instances) instead of the intended 2x "next attack". Phase 1's keying fix reduced
  the error (the old code compounded the same state to 4x) but did not remove it. Phase 3's
  ledger calls Daunting_Strength "a clean factor, consumed per resolution, already keyed
  through `_damage_multiplier`" — that description holds only when the buff's one active
  turn also lands the attack; decide there whether to bank at resolution time instead, or
  narrow the ledger's claim.
* **`CombinedDamageModifier.TRAIT_RESOURCE_KEY` still groups by category** — Nit, for
  Phase 2 or Phase 6's Technical Design Document write-up. `damage_effect.gd` and
  `clear_zone_effect.gd` both contribute `TraitSkillResult._damage_multiplier` under the
  shared `&"trait_resource"` key, the same shape Phase 1 removed from the trait
  outgoing-damage bonus one line away in `battle_resolver.gd`. Harmless today — only one
  trait can be equipped — but the Technical Design Document write-up should not claim every
  resolver-owned key is now mechanic-identity-keyed without naming this one exception.

## Watch for

* **Do not convert enablers into damage factors.** The target is not a roster where every
  status touches damage. An enabler that passes the collapse test needs no rework.
* **Dual classification is a valid result**, not an unresolved one — a status can be
  channel 1 by mechanism and enabler by role.
* **Do not uncap Momentum, Arcane Instability, or Steel and Sea stacks.** 1.1.4 states they
  are correct as written because they accrue automatically. They are outside this plan.
* **Rework is not always upward.** Removing a linear bump (Spotlight's −10%) is as valid an
  outcome as replacing it with a factor, and cheaper.
* Statuses are reached by roughly twelve trait and graft scripts under
  `Scripts/Character/character_traits/` and by hardcoded checks in `battle_resolver.gd`,
  `zone_resolver.gd`, `battle.gd`, and `skills.gd`. A rework that changes a status's
  mechanism has to sweep those call sites, not only its `.tres`.
* Per `CLAUDE.md`, no code or data-file comment written by this plan may name the plan, a
  phase, or a batch — plans are deleted on completion and the reference would dangle.
