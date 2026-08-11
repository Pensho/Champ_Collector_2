# Role Kit Design

Living design document for the Blowout pillar's kit layer. Authored by `Plan_Role_Kit_Rework.md`
Phase 1; successor to the archived `Plan_Role_Skill_Kits.md` claims ledger. Settled kits are
promoted into `Concept_Document.md` 3.2.4.2, which stays the authority once a kit lands — this
document carries the allocation and the reasoning behind it, and the in-flight synergy ledger
before that promotion happens.

**Status:** Phase 1 draft — channel identity allocation and pairing web sketched, batches 2-4
proposed. Awaiting sign-off per the plan before Phase 2 authoring starts. Design only; no skill or
status `.tres` exists yet for anything below beyond what already ships (Concept_Document.md
3.2.4.2).

## 1. The per-Role kit contract

Each Role declares **one primary channel identity — Channel 1, Channel 2, or Channel 3** — and
must be able to put on the table by burst time:

* **at least one distinct `CombinedDamageModifier` bucket key** (Channel 2) or comparable channel
  contribution matching its declared identity, at a magnitude in the target band (section 4);
* **at least one composition hook** — something it reliably puts into the world that another
  kit's condition can read.

**Enabler is a skill-level tag, not a Role-level identity.** No Role's primary identity is
Enabler — every Role fields real channel contribution, starting with its basic skill (a
no-cooldown skill is Channel 1 by default, scaling an attribute) and its declared-identity skill
on top of that. A Role may additionally carry zero or more Enabler-tagged skills or riders — a
basic skill's secondary rider, a dedicated protection/denial skill, a heal — each held to the
**collapse test** (`Concept_Document.md` 1.1.6) on its own merits: removing it makes the burst not
happen, or not survive to happen. "Useful to have" fails. A Role whose flavor centers on
protection or denial (Scholar, Diviner, Symbiote, Bar Brawler, Warlord — section 5) still carries
a genuine Channel 1 or Channel 2 anchor; the protection/denial piece is one skill in its kit, not
the whole kit's identity.

## 2. Composition is indirect — never named coupling

**A skill must never reference another Role, champion, or skill.** Hooks read *world state*, and
any kit that can produce that state satisfies them. That is what makes a combination a discovery
rather than a scripted pair, and what keeps every future Role automatically compatible.

Legitimate condition surfaces (illustrative, not exhaustive — later batches' brainstorms may
extend this list):

* a named status effect being present on the target, or on the caster, or on an ally;
* the *absence* of a status, or the target's total status count;
* current or missing Health, on either side; the caster's own resource or stack count;
* turn-bar state — zone presence, section occupancy, relative position;
* whether the target acted, was hit, or crit since the caster's last turn;
* how many distinct debuff *types* are on the target (`bonus_per_debuff_on_target` gives each type
  its own bucket, so each further type multiplies).

## 3. The synergy grammar

"Synergy" has to be expressible in the `.tres` schema, so the design works from the mechanisms
that actually multiply (`Technical_Design_Document.md` 7.4):

| Mechanism | Schema | Why it multiplies |
|---|---|---|
| Per-debuff-type factor | `DamageEffect.bonus_per_debuff_on_target: {Debuff_Type: float}` | **One independent bucket per debuff type** — each further debuff on the target multiplies. The primary cross-kit hook, and the most under-used. |
| Trait-counter factor | `DamageEffect.bonus_per: {Trait_Count_Source: float}` | Reads a counter another kit can feed. |
| Granted modifier-bearing status | `ApplyBuffEffect` of a `DamageMultiplier` / `PerTargetDebuffDamagePercent` status | Lands the factor on whoever consumes it. |
| Cascade instance count | `Types.Cascade_Trigger` | Each instance re-reads channels 1 and 2, so count multiplies against them. |
| Zone `on_trigger` payload | `ZoneEffect.on_trigger: Array[SkillEffect]` | A separate resolution on a schedule the enemy walks into. |

Governed by the composition law (`Concept_Document.md` 1.1.3): **same bucket key adds, distinct
keys multiply, and keys are mechanic identity — never character identity.** Two Roles applying the
same debuff type produce one factor, not two.

**Channel 3's vocabulary is explicitly open.** `Types.Cascade_Trigger` currently holds only
`Status_Expired`, `Status_Landed`, and `Skill_Resolved`. The named gaps with no trigger at all:
threshold crossings (Health, status count), and cascade-on-cascade. Section 5 below proposes using
the threshold-crossing gap for two of the new Channel 3 anchors; the plan authors the enum value
and its `Post()` call site when a batch's design earns it.

## 4. Targets and current baseline

* Boss-tier burst target: **30-50x** a champion's own basic, preferring 50x
  (`Concept_Document.md` 1.1.2).
* Against a boss-tier Defence of 120 (Defence's mitigation ratio is taken against the fixed
  `GameBalance.DEFENCE_SCALE_CONSTANT = 100.0`, per `Concept_Document.md` 1.1.4, so it keeps its
  full percentage weight at burst scale), a 50x burst needs a **50x multiplier on the scaled
  attribute aggregate** — roughly two independent factors per champion across a three-champion
  team.
* Current roster baseline (`Tests/manual/team_corpus_sweep.gd`): combined-modifier-product median
  **1.62x**, 90th percentile **2.80x**, ceiling **7.22x**; contrast-ratio ceiling **9.39x**. Every
  batch is measured against this baseline, tracking the distribution's *shape* (median, 90th
  percentile, ceiling, count of distinct top-decile pairings), not only the maximum.
* Pairing web target: **at least four independent ceiling pairings**, each reaching a comparable
  product through a *different* gating mechanic, none of them routed through Tidal Corsair or
  Tactician's grants alone.

### Binding constraints

* **The 8-status cap is shared across buffs and debuffs.** A combination needing six debuffs on
  the boss is fighting the cap against the player's own stacks and the enemy's own debuffs.
  Debuff-density payoffs must land inside it.
* **Burst payload skills need a top-level `DamageEffect`.** Damage nested inside
  `ZoneEffect.on_trigger` is invisible to the Sorcerer's repeat and to `BurstReachability`'s
  scorer.
* **Do not uncap** Momentum, Arcane Instability, or Steel and Sea; magnitude-per-stack is the
  dial, not stack count.
* **Base attributes stay tame** — growth belongs in channels 2 and 3.
* Existing anti-overlap rules: identity effects to one Role, commodity buffs/debuffs to at most
  two, turn-bar effects to one, zones stay signature.

## 5. Channel identity allocation

Current shipped tags (`Concept_Document.md` 3.1.3 / 3.2.4.2) are a byproduct of one-note kits, not
a considered allocation — most Roles are tagged Channel 1 today simply because that's what a plain
damage or attribute-debuff skill defaults to. This section states the *intended* primary identity
for the reworked kit, chosen to fix the two shortfalls the current baseline exposes: Channel 3 is
nearly empty (3 real entries against 23 Channel-1 statuses) and Channel 2 has almost no cross-kit
hooks (one skill in 79 declares `bonus_per_debuff_on_target`).

Target shape: 4 Channel 3 anchors (up from ~1 real Role-driven anchor), 9 Channel 2 anchors, 7
Channel 1 anchors. No Role's primary identity is Enabler (section 1) — the five Roles whose
flavor leans hardest into protection or denial (Scholar, Diviner, Symbiote, Bar Brawler, Warlord)
each still anchor a genuine Channel 1 or Channel 2 skill; their protection/denial skill (Refutation,
Premonition, the graft's baseline, On the House, Shield Wall) is an Enabler-tagged skill within the
kit, not the kit's whole identity.

| Role | Purpose (unchanged) | Primary identity | Composition hook (sketch) |
|---|---|---|---|
| Plague Doctor | Debuffer | **Channel 3** | Debuff density on the target feeds cascade instance count — the deepest identity claim in the roster (Batch 1 anchor; absorbs the Comorbidity fix). |
| Sorcerer | Damage, Debuffer, Control | **Channel 3** | Reagent-triggered repeat re-resolves channels 1 and 2 as a fresh instance; the second, independently-gated cascade anchor (Batch 1). |
| Herald of the Loom | Debuffer, Buffer | **Channel 3** | No passive exists in code today — free design space. A stance-driven status-expiry cascade (reads `Status_Expired`, the trigger already wired for Plague/Overflow) gives the roster a third cascade source gated by duration management rather than reagents or debuff count (Batch 1; needs a passive authored from scratch). |
| Chronophage | Control | **Channel 3** | Turn-bar threshold crossing (pushing an enemy across a section boundary) is a named gap in the Channel 3 vocabulary — a new `Cascade_Trigger` value earned here, gated by turn-bar manipulation rather than any existing mechanic (Batch 2). |
| Emissary | Debuffer, Control | **Channel 2** | The Infraction tally is already a growing, target-side counter with nothing reading it as a `bonus_per` source; turning it into one gives debuff-density pairings a second, independently-fed debuff type (Batch 2). |
| Alchemist | Debuffer, Buffer | **Channel 2** | Fresh Batch's team damage buff on reagent consumption already fits — keep as the reagent-consumption anchor (Batch 4). |
| Appraiser | Debuffer | **Channel 2** | Strike the Flaw (crit applies Cracked Facet) is the crit-path anchor — independent of the debuff-density and cascade routes, since it multiplies through the crit-damage path outside the combined modifier (1.1.4) (Batch 1). |
| Cultist | Debuffer, Damage | **Channel 2** | Chosen Vessel's escalating per-cast power bonus is a growing modifier factor; Vessel death granting Attune ties it to the Health-threshold surface as a secondary hook (Batch 2). |
| Jester | Damage, Sustain | **Channel 2** | Pratfall Sting's avoided-hit bonus is a conditional factor keyed to "was I hit/did I dodge since my last turn" — the crit-path pairing's second half alongside Appraiser (Batch 2). |
| Architect | Buffer, Damage | **Channel 2** | Calibration's tiered finisher (Expose Weakness at 5-8 charges) is a self-contained stack-consumption payload, independent of Tidal Corsair's Steel/Sea (Batch 2). |
| Tidal Corsair | Damage | **Channel 2** | Wrangle the Sea — the existing, already-working ceiling pairing. Kept as-is; the plan's goal is added independent routes, not replacing this one (no batch change planned). |
| Thief | Damage | **Channel 1** | Pierce Weakness's Defence-ignore is a restored burst lever now that Defence keeps its full weight at burst scale; Pilfer's buff-steal is a secondary Enabler-tagged skill (denies a teammate condition to the enemy) (Batch 3). |
| Lancer | Damage | **Channel 1** | Momentum/Phalanx Guard, once the offensive/defensive skill-name bug is fixed, is the roster's second stack-consumption anchor, independently gated from Corsair's and Architect's (Batch 3). |
| Tactician | Buffer | **Channel 1** | Plan's attribute grant stays, but the rework should add a second hook beyond Daunting Strength so this Role is one of several Channel-2 feeds into a pairing, not the roster's sole one (Batch 3). |
| Bloodmage | Sustain, Damage | **Channel 1** | Hemoclarity's Health-threshold Mysticism surge is already Channel 1 by mechanism; its damage skill gains a `bonus_per` keyed to the caster's own missing-Health percentage as the Health-threshold composition hook (Batch 1 — currently a zero-contribution kit). |
| Scholar | Debuffer, Buffer | **Channel 2** | Expose Fallacy's Opportunist grant is the modifier-bucket anchor (feeds any per-debuff-type reader on the team). Refutation's zone removal stays an Enabler-tagged skill within the kit — denying the enemy's own zone setup, held to the collapse test on its own, not claimed as the Role's identity (Batch 3). |
| Diviner | Sustain, Debuffer | **Channel 1** | Foresight's pre-emptive Enfeeble is the attribute-channel anchor. Premonition (auto-miss protection) stays an Enabler-tagged skill within the kit (Batch 4). |
| Symbiote | Sustain, Buffer | **Channel 1** | Exhert's attribute buff is the baseline anchor, present from the ungrafted state on. Post-graft, a second hook may lean into whatever channel the bound graft effect supplies (pool-dependent, `Symbiote_Graft_Pool.md`), but the base kit always carries a genuine Channel 1 contribution on its own (Batch 4). |
| Bar Brawler | Sustain, Buffer | **Channel 2** | Heap On already grows stronger with every use — the basic skill itself is the modifier-bucket anchor. On the House's heal-on-buff stays an Enabler-tagged skill within the kit, not the Role's identity (Batch 4). |
| Warlord | Sustain | **Channel 1** | Shield Slam scales with Defence and Hold the Line grants Fortify — the attribute-channel anchor, meaningful now that Defence keeps its weight at burst scale. Shield Wall's damage redirection stays an Enabler-tagged skill within the kit (Batch 4). |

## 6. The pairing web

Tidal Corsair's Steel/Sea route already reaches the ceiling and stays as-is. The gap the current
baseline exposes is that it was the *only* route — the top decile was one repeated pairing. Five
new, independent routes are sketched below, each gated by a different mechanic and none dependent
on Tidal Corsair or Tactician's grant alone. "Independent" means: remove any one route's anchor
Roles from the roster and the other four still reach a comparable product through unrelated
mechanics.

| Route | Gating mechanic | Anchor Roles | Batch |
|---|---|---|---|
| **A — Debuff density** | Distinct debuff *types* on the target, each its own `bonus_per_debuff_on_target` bucket | Plague Doctor (Plague, Blight) + Emissary (Infraction-scaled Sanction, a further distinct type) | 1 → 2 |
| **B — Cascade count** | Repeat/expiry-triggered re-resolution compounding fan-out | Sorcerer (reagent repeat) + Herald of the Loom (status-expiry cascade) | 1 |
| **C — Crit path** | Crit chance/damage growth, outside the combined modifier (1.1.4) | Appraiser (Strike the Flaw) + Jester (avoided-hit conditional damage) | 1 → 2 |
| **D — Stack consumption (non-Corsair)** | Self-contained accumulate-then-spend payload | Architect (Calibration finisher) and, independently, Lancer (Momentum/Phalanx Guard once fixed) | 2, 3 |
| **E — Health threshold** | Missing-Health percentage as a `bonus_per` surface | Bloodmage (missing-Health hook) + Cultist (Vessel-death Health event) | 1 → 2 |

Each route is a candidate combination to validate during its batch's own 1.1.6 review, not a
scripted pair enforced in code — per section 2, no skill in any of these kits may name the other
Role. A team assembling route A's debuff types, for instance, is satisfied by *any* kit that
produces Plague, Blight, or an Infraction-scaled debuff, not specifically Plague Doctor and
Emissary.

## 7. Batch composition for Phases 2-5

Batch 1 (Phase 2) is fixed by the plan: Plague Doctor, Herald of the Loom, Sorcerer, Bloodmage,
Appraiser — chosen to open routes A (partial), B, C (partial), and E (partial) in one pass, plus
absorb the Comorbidity fix.

Batches 2-4 (Phases 3-5), proposed here per the plan's instruction that composition is fixed once
the pairing web exists:

* **Batch 2 — close every route batch 1 opened.** Emissary (closes A), Jester (closes C),
  Architect (opens D independently), Chronophage (new Channel 3 anchor, no route dependency yet),
  Cultist (closes E). By the end of this batch all five sketched routes have both anchors landed.
* **Batch 3 — the stack-consumption and Enabler pass.** Lancer (closes D's second anchor, absorbs
  the Reckless Momentum bug fix), Thief, Scholar, Tactician (add the second hook so it isn't the
  pairing web's sole Channel-2 source), Tidal Corsair (re-verify against the widened roster,
  confirm it's no longer the only ceiling pairing).
* **Batch 4 — remaining protection/denial kits and expansion-only kits.** Alchemist, Diviner,
  Symbiote, Bar Brawler, Warlord — sharpen each Role's Channel 1/2 anchor into a real bucket-key
  contribution and confirm its protection/denial skill (Premonition, the graft baseline, On the
  House, Shield Wall) earns its collapse-test claim as an Enabler-tagged skill within the kit,
  rather than being promoted into a bucket key itself; expected to be mostly "expand, don't
  replace" per the plan's default posture, since none of these were flagged as zero-contribution
  or one-note in the baseline findings.

This grouping favors closing routes early over leaving half-pairings scattered across three
batches — batch 2 alone completes the pairing web's every proposed route, leaving batches 3-4 to
fix known bugs (Lancer, Comorbidity already in batch 1) and give the remaining Enablers their
collapse-test payload without inventing new gating mechanics.

## 8. Open items for later batches

* Whether route D needs a third anchor beyond Architect and Lancer once Tidal Corsair is
  re-verified in batch 3 — not decided here.
* The exact `Trait_Count_Source` / debuff-type identifiers for Emissary's Infraction hook and
  Bloodmage's missing-Health hook are batch-time authoring decisions, not Phase 1 commitments.
* Whether Chronophage's new threshold-crossing `Cascade_Trigger` should also serve a future
  Health-threshold design (the other named gap in section 3) is worth revisiting once batch 2
  lands — not resolved here to avoid scope creep into code before sign-off.
* The contrast baseline (bursting champion's own basic vs. team's average per-action output)
  remains open per the plan; not touched by this document.
* **Whether Enabler may be a Role-level identity.** Section 1 forbids it and section 5 assigns
  Appraiser Channel 2, but Appraiser's settled kit (section 9.5) runs entirely through the crit
  path, which `Concept_Document.md` 1.1.4 places outside the `CombinedDamageModifier` — so it
  claims no bucket key and cannot meet section 1's contract as written. Either section 1 admits a
  crit-path contribution as satisfying the contract alongside a bucket key, or Enabler becomes a
  legitimate Role identity for Roles whose whole output lands on someone else. This governs all 20
  Roles, so it is not amended here on one kit's account; settle it before Batch 2's kits are
  designed against the same contract.

## 9. Settled kit designs

One entry per Role once its kit is **settled** (brainstormed, picked, and projected against the
target band) — recorded here *before* any `.tres`, trait script, or status effect is written, per
the plan's tier-3 loop. This is the record a coverage review reads: what every settled Role's
passive and three skills actually do and what it projects to, without having to reconstruct that
from trait scripts. An entry's **Status** line tracks whether it has been implemented yet; a
settled-but-unimplemented entry is expected and not a problem to fix. Rationale for *why* a kit
was shaped this way lives in the conversation/PR history that settled it, not here; claimed status
effects and bucket keys live in section 10's ledger, not duplicated here.

Format per entry: Status, Passive, Skills (name / effect / channel), Projected numbers.

### 9.1 Plague Doctor — debuff-density damage and cascade-breadth passive

**Status:** Implemented (`aca439b`). Batch 1.

**Passive: Comorbidity.** Debuffs placed by this Role's skills tick again once for every distinct
debuff type on the target (any source, uncapped).

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Septic Lance | Mysticism-scaled damage to one enemy. | 1 |
| Signature | Outbreak | Mysticism-scaled damage to one enemy, +8% per distinct debuff type on the target (uncapped); applies a stack of Plague for 3 turns (now stackable, no longer expiry-spread). | 2 |
| Signature | Miasma | Zone, 4 charges. On trigger, forces every active debuff on the caught enemy to tick again immediately without losing duration, and applies Blight for 2 turns. | 3 (Enabler-classed by the scorer today — see below) |

**Projected numbers:** not separately recorded before implementation (this kit predates section 9
being split out); see `Tests/manual/team_corpus_sweep.gd`'s post-batch sweep result in the plan's
own Status section for the roster-level delta this kit produced. Comorbidity's sustained,
multi-turn tick repetition is scored on Outbreak's own manifest entry via a `"sustained_ticks"`
`gated_bonus` (section 11), reported in `sustained_contrast_ratio` rather than folded into the
single-cast product — `bucket_key` stays empty on both entries, since the mechanism never lands in
a `CombinedDamageModifier` bucket. Miasma's own forced retick still carries no independent score
(no `DamageEffect` of its own to attach a `gated_bonus` to); its pressure is real and
resolver-tested in play, layered on top of whatever Comorbidity already scores.

### 9.2 Herald of the Loom — The Echo Loom

**Status:** Implemented. Batch 1.

**Passive: Weft and Warp.** The Herald always holds exactly one thread, starting on Silver at
battle start. Switching is a free action available any number of times during the Herald's own
turn (before or after using a skill, in any order) — not a once-per-turn cap, and not a status
effect with a duration: the active thread is ordinary persistent trait state that carries as-is
into the next turn until changed again. Max Tension is a constant 7 at every rarity.
* Golden Thread — gain 1 Tension when a cascade instance resolves on an enemy (Cut the Cloth's own
  instances excluded, to avoid a self-feed loop — enforced by construction, since Cut the Cloth's
  repeats never call `CascadeResolver.Post`).
* Silver Thread — the Herald's debuffs cannot be resisted and last 1 turn longer.
* Black Thread — the cascade instance produced by the Herald's own action resolves one additional
  time (not a double — a skill that would resolve once now resolves twice). Scoped to the Herald's
  own action only, since the Herald casts at most one skill per turn.
* Cascade instances cast by this champion deal bonus damage: +5% Uncommon, +10% Rare, +15% Epic,
  +20% Legendary. (Generic wording deliberately — applies to any cascade instance the Herald
  produces, names no skill, so the passive and the skills stay decoupled.)
* Starting Tension: 0 Uncommon/Rare, 1 Epic/Legendary. Tension does not persist between combats
  (matches Arcane Instability's precedent).

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Thread Snap | Mysticism-scaled damage to one enemy; applies Suppress for 1 turn. | 1 |
| Signature | Pull the Thread | Mysticism-scaled damage to one enemy, pushes them backward 15% on the turn bar, applies Temporal Leak for 3 turns, and grants the Herald 2 Tension (stance-independent). | 2 |
| Signature | Cut the Cloth | Damage to one enemy at 90% of a normal Mysticism-scaled hit, resolved once for the base cast plus once more per Tension held (minimum once, at zero Tension), then consumes all Tension. | 3 |

**Projected numbers.** Using `Skills.MitigatedDamageUnrounded`'s formula (`skills.gd:298-307`):
since mitigation depends only on defence and cancels identically between the basic-skill baseline
and the burst (no defense-ignore in this kit), contrast ratio reduces to `(skill aggregate ratio) ×
(combined modifier product) × (instance count)`, independent of which boss is used. At Legendary
(8 instances, 90% per-instance strength, +20% self bonus) against an illustrative team product of
5.5 (roughly matching section 4's "two independent factors per champion" shape), contrast ratio ≈
**47.5x** — inside the 30-50x target band. Against a more modest team (product ≈3.0), ≈25.9x. At
Uncommon (same 8-instance ceiling — rarity affects tempo via starting Tension and the smaller +5%
self bonus, not the ceiling itself, since max Tension is now rarity-flat) the same strong-team
scenario gives ≈41.6x. Cut the Cloth's 90% strength (rather than a Sorcerer-style 50% discount) is
load-bearing: the setup tax is Tension's multi-turn build time, not a second discount on the
payoff — discounting both would leave the kit short of the target band against any realistic team.

**Implemented as:** `weft_and_warp_trait.gd`, `Thread_Snap.tres` (reworked), `Pull_the_Thread.tres`,
`Cut_the_Cloth.tres` (new), `Herald_of_the_loom.tres` (rewired). Golden Thread hooks a new
`Combat_Event.Cascade_Instance_Resolved` broadcast, fired once per real cascade instance from
`CascadeResolver._ResolveEvent`'s own per-instance loop — narrower than "any indirect damage" (a
debuff tick still doesn't post to `CascadeResolver` at all; tracked as a gap in `FeatureIdeas.md`,
not closed here). Black Thread's extra instance is `CascadeResolver.SubscribeInstanceModifier`, new
plumbing that amplifies an already-matched listener's instance count rather than creating one from
nothing. Silver Thread's two clauses are `CharacterTrait.GetOutgoingDebuffDurationBonus` (new,
symmetric to the existing `GetIncomingDebuffDurationBonus`) and `DebuffsCannotBeResisted` (new),
both read directly by `status_effect_resolver.gd`. The thread switch is a single "Switch Stance"
toggle button (`ThreadSwitchButton`, `Thread_Switch_Button.tscn`) sharing the Symbiote graft
button's screen slot in `battle_ui.tscn` rather than adding new screen space or generalizing
`GraftButton`'s own confirm/target flow — the two are mutually exclusive by whose turn it is. Cut
the Cloth's repeats resolve as a local loop inside the trait (`_ResolveExtraCutTheClothInstances`)
that never calls `CascadeResolver.Post`, the deliberate choice that makes Golden Thread's
self-exclusion automatic rather than a predicate check. The manifest's `gated_bonus` entry uses
`fold: "separate_instance"`, `instances: 8`, `magnitude: 0.08` (Legendary, the 90% base strength
and +20% self-bonus folded into one net per-instance multiplier), verified against this section's
own 8*1.08=8.64 curve in `Tests/unit/test_burst_reachability.gd`.

### 9.3 Sorcerer — Echo charges and the Surge that feeds them

**Status:** Settled, not yet implemented. Batch 1.

**Passive: Arcane Instability.** Four clauses, each doing one job:

* Using any skill grants 1 Instability stack, maximum 5. Stacks do not persist between combats.
* Consuming a reagent grants 2 Instability stacks, amplifies the reagent's effect, and grants
  1 **Echo** charge.
* At maximum stacks the next skill also releases a **Surge**: damage to all characters, allies and
  the Sorcerer included, scaling 1.5x the Sorcerer's Mysticism, never a critical hit — then all
  stacks reset and the Sorcerer gains 1 Echo charge.
* Each Echo charge held makes the Sorcerer's next skill repeat one additional time; all charges are
  consumed when it does. The first Echo deals 50% of the skill's damage and each further Echo
  compounds on the previous. Each Echo is a fresh cascade instance assembling its own combined
  damage modifier; a repeated debuff or zone charge is not reapplied, only the damage.

Rarity scales only on the passive, never on the kit's skills: Echo compounding 1.30 Uncommon /
1.45 Rare / 1.60 Epic / 1.75 Legendary; reagent amplification 20 / 30 / 40 / 50% (unchanged).
Instability stacks carry no attribute scaling — they are purely the Surge's counter, so the
per-stack Mysticism ramp of the shipped passive is dropped and the Role's growth lives entirely in
the channel it anchors.

The Surge is the second Echo source, which is what makes the friendly fire load-bearing rather
than a flavor tax: the uncontrolled discharge is what widens the next chain. Echo is gated on
reagent scarcity (3 brought per battle, `Concept_Document.md` 3.3.3, consumable as free actions
with no per-turn limit) and on the Surge's 5-stack build — independent of Herald's Tension and
Plague Doctor's debuff count.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Arc Lash | Mysticism-scaled damage to one enemy; 25% chance to apply Warped for 1 turn. The rider is Enabler-weight and carries no bucket key — it seeds Cataclysm's condition occasionally, leaving Unstable Rift the reliable Warped source. | 1 |
| Signature | Cataclysm | Mysticism-scaled damage to all enemies; +30% against targets carrying Warped. Cooldown 4. Renamed from Cataclysmic Surge so "Surge" names only the passive's discharge. | 2 |
| Signature | Unstable Rift | Zone, 5 charges. On trigger, all affected characters gain Warped for 2 turns and take Mysticism-scaled damage (0.3 enemies / 0.15 allies). When Echoes resolve on a cast that placed a zone, each Echo instead multiplies that zone's on-trigger damage by x1.15, compounding, for the zone's remaining life. | 3 (Enabler-classed by the scorer — section 11) |

The Rift's Echo clause closes the shipped kit's documented no-op (the skill's damage lives in
`ZoneEffect.on_trigger`, so the repeat had no top-level `DamageEffect` to re-run) without
converting the zone into a direct cast — the turn-bar object stays a turn-bar object, and the Echo
makes it more dangerous to the Sorcerer's own team, the same identity clause as the Surge.

**Projected numbers.** Using `Skills.MitigatedDamageUnrounded` (`skills.gd:298-307`) per section
9.2's methodology: mitigation cancels between the basic-skill baseline and the burst (no
defence-ignore in this kit) and there is no attribute-ramp term, so contrast reduces to
`(combined modifier product) x (instance multiplier)`. Echo ceiling is **4**: three banked reagents
consumed as free actions in the burst turn, plus one charge carried in from the previous cast's
Surge. At Legendary the four Echoes deal 50 / 87.5 / 153 / 268% — 5.59x in repeats, **6.59x**
total including the original cast.

| Scenario | Contrast ratio |
|---|---|
| Legendary, 4 Echoes, strong team (product 5.5) | **36.2x** — inside the 30-50x band |
| Legendary, 4 Echoes, modest team (product 3.0) | 19.8x |
| Legendary, 1 Echo (steady state, no reagents banked) | 8.3x |
| Uncommon, 4 Echoes, strong team | 22.5x |

The 1.75 compounding factor is steeper than a flat-instance design would need precisely because
the per-stack Mysticism ramp was dropped: that ramp was worth a flat 1.5x on the aggregate, and
moving its weight into the compounding curve puts the ceiling in Channel 3 where the Role's
identity claims it. Peak 4 cascade instances plus the Surge in one action, well inside
`CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION = 16`.

**Implementation needs (not yet built):** per-instance `SkillCastContext.repeat_bonus`, set once
per Echo rather than once per cast as `sorcerer_trait.gd:113` does today; a persistent on-trigger
damage multiplier on `Zone` (`zone.gd` has no such field) plus a way for the Echo to reach the zone
the cast placed; and the `Cataclysmic_Surge.tres` rename to `Cataclysm.tres` with its inbound preset
and manifest references. The scorer's compounding curve (section 11's `gated_bonus`, `fold:
"separate_instance"`, `instances: 4`, `instance_compounding: 1.75`) is available once the reworked
kit is authored — verified against this section's own 5.59x/6.59x figures in
`Tests/unit/test_burst_reachability.gd`.

### 9.4 Bloodmage — the missing-Health surface, caster-side and exported

**Status:** Settled, not yet implemented. Batch 1.

**Passive: Hemoclarity.** Changed from a below-50% cliff to a continuous curve, and widened past
damage: for every 1% of max Health the Bloodmage is missing, gain +1% Mysticism (0.7/0.8/0.9/1.0%
per rarity, capped at 80% missing), and the same percentage increases all healing and Barrier
absorption the Bloodmage creates. This is the only place in the kit that reads the Bloodmage's own
missing Health — every skill below reads someone else's.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Blood Bolt | Kept as-is. Mysticism-scaled damage to one enemy; self-costs 3% max Health. | 1 |
| Signature | Transfusion | Kept: sacrifices 15% max Health, one ally gains a Barrier absorbing 200% of the Health sacrificed (2 turns). Added: the same ally also gains **Sanguine Pact** for 3 turns. Cooldown 4. | Enabler + 2 (granted) |
| Signature | Tithe of Vitality | Drains 10% max Health from each living ally (caster excluded). Mysticism-scaled damage to one enemy, +35% per living ally currently below half Health (`bonus_per Wounded_Allies`), applies **Hemorrhage** for 3 turns. Mana Burn dropped — nothing in the kit read it. Cooldown 4. | 2 |

**New statuses.**

* **Sanguine Pact** (buff, Channel 2, granted — lands in the holder's own bucket, not the
  Bloodmage's): the holder's damage is increased by 12% per 10% of *the holder's own* missing
  Health, and 30% of damage the holder takes is redirected to the Bloodmage instead. Two clauses,
  read off two different quantities (the holder's own missing Health for the damage bonus; the
  holder's incoming damage for the redirect) — the Bloodmage's own missing Health feeds nothing in
  this status, keeping the composition law's "distinct keys multiply" clean.
* **Hemorrhage** (debuff, Channel 2): attacks against the holder deal +6% damage per 10% of the
  *holder's own* (i.e. the target's) missing Health. Every teammate's damage reads it, not only the
  Bloodmage's, and it is a distinct debuff type, so it also feeds route A's density count.

**Composition hook (route E).** Sanguine Pact and Hemorrhage both name no Role, only a missing-
Health quantity — the caster's own (Hemoclarity), the buff holder's own (Sanguine Pact), or the
enemy's own (Hemorrhage). Anything that wounds an ally feeds Sanguine Pact (the Bloodmage's own
Tithe, the Sorcerer's Surge friendly fire per §9.3, Symbiote's Exhert); anything that damages the
boss feeds Hemorrhage automatically, since it is a standing debuff, not a triggered one.

**Projected numbers.** Using §9.2's methodology (mitigation cancels between the basic-skill
baseline and the burst; contrast reduces to aggregate ratio × combined modifier product) — with one
addition this kit needs that 9.1-9.3 didn't: Hemoclarity's missing-Health Mysticism bonus does
*not* cancel the way ordinary attribute scaling does, because the baseline "own basic" is cast at
full Health and the burst is deliberately cast at a deep wound, so it contributes to the aggregate
ratio rather than dropping out.

Bloodmage's own cast, Tithe of Vitality at Legendary, 80% missing Health, 2 allies below half:
aggregate ratio 1.5 (Tithe's Mysticism scaling vs. Blood Bolt's 1.0) × 1.80 (Hemoclarity's own-
missing-Health aggregate bonus) × 1.70 (Wounded_Allies bucket, 2 allies) ≈ 4.59x before team
factors. Against a strong team product of 5.5 (§4's illustrative shape), contrast ratio ≈ **25.2x**;
against a modest team (product 3.0), ≈13.8x. As a Channel 1/2 kit rather than a Channel 3 anchor,
this Role is not expected to clear the 30-50x band alone — §1's contract asks for a real bucket in
the target band and a composition hook, not a solo burst, and the exported factors below are where
this kit's actual weight lands:

* **Sanguine Pact**, on the carrier: 1.60x at 50% missing Health, up to 1.96x at 80% missing —
  handed to whichever teammate is bursting, independent of the Bloodmage's own cast.
* **Hemorrhage**, on the whole team: 1.30x with the boss at half Health, rising to 1.48x as the
  boss drops to 20% remaining — a standing multiplier every damage dealer on the team reads for
  free, plus a distinct debuff type for route A.

**Implementation needs (not yet built):**

* `Trait_Count_Source.Wounded_Allies` — one new enum value plus one `_Count` branch in
  `damage_effect.gd`, counting living allies (caster excluded) currently below 50% Health; same
  shape as Batch 1's `Target_Debuff_Count`.
* A continuous-missing-Health damage-multiplier shape, read off a *target's own* missing Health
  rather than a debuff-type presence — distinct from `bonus_per_debuff_on_target`, needed for both
  Hemorrhage (reads the enemy holding it) and Sanguine Pact's damage clause (reads the ally holding
  it). One computation, two status resources.
* Damage redirection to a *named applier*, not a trait owner — `shield_wall_trait.gd` already
  redirects damage, but that redirect target is the trait's own owner; Sanguine Pact needs the
  redirect target to be whoever applied the status, which no existing status carries a field for.
* `hemoclarity_trait.gd` rewritten for the continuous curve, and extended to reach
  `HealthChangeEffect`/`BarrierEffect` sizing so the healing/Barrier clause has something to scale.
* `kit_contribution_manifest.gd`: Tithe of Vitality gains a `bucket_key` (skill-name bucket,
  `bonus_per Wounded_Allies 0.35`); Sanguine Pact and Hemorrhage are recorded as granted-status /
  debuff-type bucket keys landing on whoever holds them, not on the Bloodmage's own entry.

### 9.5 Appraiser — overflow crit chance and consigned attributes

**Status:** Settled, not yet implemented. Batch 1.

**Identity note.** This kit's entire contribution runs through the crit path, which
`Concept_Document.md` 1.1.4 places outside the `CombinedDamageModifier` by design. It therefore
claims **no bucket key at all** and cannot satisfy section 1's "at least one distinct bucket key"
clause as that section is currently written. Section 5 lists this Role as Channel 2; the settled
kit is an Enabler. Resolving that tension is a framework-level decision left open here rather than
amended silently — see section 8.

**Passive: No Wasted Margin.** Team-wide. For every 1 percentage point of an ally's Critical Chance
above 100, that ally gains Critical Damage: 2 percentage points Uncommon, 3 Rare, 4 Epic, 5
Legendary. Excess Critical Chance converts instead of being discarded. This is the kit's only
rarity term — the skills below carry none, matching section 9.3's rule.

The passive needs no guaranteed-critical-hit mechanism: the resolver rolls
`random_integer(1, 100) <= chance` (`battle_resolver.gd:730`), so any total above 100 already
crits every time. Saturation is the guarantee, and the conversion is what makes overshooting it
worth building toward.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Sizing Cut | Knowledge-scaled damage to one enemy; applies Exposed Facet for 1 turn. The rider is Enabler-weight and carries no bucket key — the short duration and flat value are what keep a no-cooldown application tame. | 1 |
| Signature | Flaw Analysis | Applies Confound and Cracked Facet to one enemy for 3 turns. Cooldown 2. | Enabler |
| Signature | Full Appraisal | Consigns the Appraiser's own crit attributes to one ally (`Ally_Not_Self`) for 3 turns: Keen Edge grants the Appraiser's Critical Chance, Lethal Precision grants its Critical Damage. Both are zero in the Appraiser's own hands while loaned. Cooldown 4. | Enabler |

**Reworked statuses.** All four of this kit's statuses drop their flat magnitudes — the shipped
values (15 / 25 / 15 / 50) carry no rarity or attribute scaling at all, which is why the kit
cannot grow.

* **Keen Edge** (buff): Critical Chance increased by the applier's own Critical Chance
  (`CasterAttributeSnapshotPercent`). Sole claimant is this kit.
* **Lethal Precision** (buff): Critical Damage increased by the applier's own Critical Damage
  (same kind). Sole claimant is this kit.
* **Cracked Facet** (debuff): critical hits against the holder deal bonus Critical Damage equal to
  60% of the applier's Knowledge (same kind). Moved off the retired Strike the Flaw passive onto
  Flaw Analysis, so it keeps a source.
* **Exposed Facet** (debuff): unchanged in shape, a flat Critical Chance add to attackers of the
  holder. Deliberately the one flat value left, since it rides a no-cooldown basic.
* **Confound** (debuff): magnitude raised from -30% to -50% Knowledge, roster-wide. This is the
  term that blunts crit damage (`Critical_Multiplier` subtracts half the defender's Knowledge,
  `Concept_Document.md` 3.2.1 #4), and nothing in the roster attacked it before. Scholar's Expose
  Fallacy is the other claimant and gains the same increase.

**Composition hook.** Every piece reads world state and names no Role: Keen Edge and Lethal
Precision size off *the applier's* attributes, Cracked Facet off the applier's Knowledge, and the
passive off *any* ally's Critical Chance total, whatever produced it. Any future Role granting
Critical Chance feeds the conversion automatically. The passive is the roster's only reason to
build Critical Chance past 100, which is a build axis that currently has no payoff.

**Projected numbers.** Appraiser at Critical Chance 60, Critical Damage 250, Knowledge 200;
carrying ally at Critical Chance 50, Critical Damage 150; boss Knowledge 70, halved to 35 by
Confound. Legendary.

| Term | Value |
|---|---|
| Ally Critical Chance | 50 own + 60 Keen Edge + 15 Exposed Facet = **125** (always crits) |
| Overflow conversion | 25 above 100, times 5 = **+125 Critical Damage** |
| Lethal Precision | **+250** |
| Cracked Facet | 60% of 200 Knowledge = **+120** |
| Confound'd blunting | -17.5 rather than -35 |
| Critical multiplier | (150 + 125 + 250 + 120 - 17.5) / 100 = **6.28x** |
| Baseline without this kit | chance 50, damage floored at 125 → factor **1.125x** |
| Contribution | **≈5.58x** |

Against route C's roughly 4x target that overshoots, which is the comfortable direction to
discover in play. The first dial is the consigned fraction, the second the passive's conversion
rate. With a crit-poor carrier (Critical Chance 5) the same setup reaches 80 chance, converts
nothing, and contributes ≈4.17x — so consigning compresses the gap between a crit-geared and a
crit-poor carrier to about 1.34x rather than eliminating it. Lending sets the floor; only the
ally's own Critical Chance reaches the conversion.

**Implementation needs (not yet built):**

* Overflow conversion in the resolver's crit path, and the matching term in
  `BurstReachability._CritFactor` — which currently does `clampf(chance, 0.0, 100.0)`
  (`burst_reachability.gd:561-564`) and would score this passive as exactly zero. The rest of the
  scorer's crit model (expected-value factor, `MINIMUM_CRIT_DAMAGE` floor, boss-Knowledge
  blunting, crit-eligible aggregate share) already landed in `e3d39bd` and needs no further work.
* Attribute consignment: a granted status that zeroes the applier's own attribute for its
  duration. `CasterAttributeSnapshotPercent` already computes and snapshots an applier-scaled
  value (`status_effect_resolver.gd:556-570`); the reciprocal loss on the applier is the new part.
* Status tooltips render the static `description` string and never see the snapshotted value
  (`battle.gd:483`), so a consigned magnitude is invisible to the player. Passing the resolved
  value through and supporting a placeholder in the description text fixes every applier-scaled
  status at once — Temporal Leak has the same silent problem today.
* `Confound.tres` magnitude 0.3 → 0.5, and `Concept_Document.md` 3.2.3's Confound entry with it.
* `strike_the_flaw_trait.gd` retired and replaced by the new passive's trait; `Cracked_Facet.tres`,
  `Exposed_Facet.tres`, `Keen_Edge.tres`, `Lethal_Precision.tres` re-authored off their flat
  magnitudes.
* `kit_contribution_manifest.gd`: all four Appraiser entries rewritten. `bucket_key` stays empty on
  every one — the crit path never reaches a `CombinedDamageModifier` bucket, matching the field's
  existing convention.

**Judgment calls made while settling, listed so they can be overruled:** Cracked Facet was placed
on Flaw Analysis rather than left without a source when Strike the Flaw retired, and it scales off
Knowledge rather than Critical Damage so it does not double-dip the attribute Lethal Precision
already consigns.

## 10. Coverage ledger

Successor to the archived `Plan_Role_Skill_Kits.md`'s claims ledger (status effects only) —
carried forward here and updated as batches land, plus a second table for the mechanism this plan
actually cares about: **damage-channel bucket keys**, so a new kit doesn't accidentally reuse
another Role's key string (the composition law's "same bucket key adds" applies to accidental
collisions too, not only intentional ones). Update both tables at the end of each batch, in the
same edit that lands the batch's kits — a stale ledger is worse than none.

### 10.1 Status effect claims

Same rules as the archived pass: **identity effects** (a passive or signature zone's own effect) to
one Role; **commodity effects** (plain attribute buffs/debuffs) to at most two; **turn bar effects**
to one each. State as of Batch 1's Plague Doctor rework (`aca439b`); everything else reflects the
archived pass's final state and goes stale as each further batch lands — refresh the claiming
Role's rows in the same edit, not after.

**Turn bar effects** — Dead Weight (Bar Brawler), Battle Orders (Tactician), Temporal Leak (Herald
of the loom, Pull the Thread, claimed this batch); Anchor, Slipstream, Steadfast, Resonance
unclaimed.

**Debuffs** (rows that changed this batch; all others unchanged from the archived pass — see
`Plan_Role_Skill_Kits.md` Archive for the full table until the next batch refreshes it here)

| Effect | Claimed by |
|---|---|
| Plague | Plague Doctor (Outbreak) — moved from Miasma; now stackable, no longer expiry-spread |
| Blight | Plague Doctor (Miasma) — moved from Quarantine Breach (renamed Outbreak) |
| Suppress | Herald of the loom (Thread Snap) — moved off the retired Thread Lash, now 1 turn (was 2) |
| Temporal Leak | Herald of the loom (Pull the Thread) — newly claimed, retiring part of `FeatureIdeas.md`'s "Rework Orphaned Turn Bar Effects" item |
| Warped | Sorcerer (Unstable Rift reliably, Arc Lash's 25% rider) — **settled, not yet implemented** (section 9.3); both sources are the same Role, so the identity-effect rule still holds |
| Hemorrhage | Bloodmage (Tithe of Vitality) — **settled, not yet implemented** (section 9.4); new debuff, no prior claimant |
| Mana Burn | Unclaimed — dropped from Bloodmage's Tithe of Vitality (section 9.4); nothing in the reworked kit read it |
| Exposed Facet | Appraiser (Sizing Cut) — **settled, not yet implemented** (section 9.5); moved onto the basic skill's 1-turn rider |
| Cracked Facet | Appraiser (Flaw Analysis) — **settled, not yet implemented** (section 9.5); moved off the retired Strike the Flaw passive, now scaled by the applier's Knowledge |
| Confound | Scholar (Expose Fallacy), Appraiser (Flaw Analysis) — **settled, not yet implemented** (section 9.5). Second claimant, within the commodity-debuff limit of two. Magnitude rises -30% → -50% roster-wide, so Scholar's existing skill gains the same increase |

**Buffs** — Attune's second claim (Herald of the loom's Woven Blessing, alongside Cultist's Chosen
Vessel passive) has dropped: Woven Blessing is no longer part of the Herald's kit (section 9.2,
implemented) and nothing in the new kit applies Attune, so Attune is now solely Cultist's (Chosen
Vessel passive). One further pending change: Sanguine Pact is a new buff, claimed by Bloodmage (Transfusion) —
**settled, not yet implemented** (section 9.4). Keen Edge and Lethal Precision stay claimed solely
by Appraiser (Full Appraisal), re-authored as consigned applier-scaled grants — **settled, not yet
implemented** (section 9.5); no other skill in the corpus applies either.

### 10.2 Damage-channel bucket keys in use

Sourced from `Scripts/Debug/kit_contribution_manifest.gd`'s `bucket_key` field (the runtime's own
key, not a doc paraphrase) — the authority the burst-reachability scorer actually reads. A blank
`bucket_key` means the entry contributes Channel 1 only, or is a pure Enabler; it claims no key.

| Bucket key | Claimed by | Shape |
|---|---|---|
| `CombinedDamageModifier.TRAIT_RESOURCE_KEY` | Cultist (Chosen Vessel), Architect (Calibration), Tidal Corsair (Wrangle the Sea) | Shared resource-key identifier — each Role's own trait-resource meter, not a collision: the key names the *mechanism* (caster's own resource-driven bucket), and each caster only ever reads their own resource, so three Roles sharing it composes rather than colliding. |
| `Citation` | Emissary (Citation) | Skill-name bucket |
| `Warped` | Sorcerer (Cataclysm) | Debuff-type bucket — doubles as the debuff identity itself. Skill renamed from Cataclysmic Surge in section 9.3; the bucket key is the debuff name, so the rename does not move the key |
| `Zone: Unstable Rift` | Sorcerer (Unstable Rift) | Zone-name bucket |
| `Daunting_Strength` (granted status) | Tactician (Fatal Flaw) | Granted `DamageMultiplier` status — lands in whoever consumes it, not the caster's own bucket |
| `Pratfall Sting` | Jester (Pratfall Sting) | Skill-name bucket |
| `Devour Blessing` | Cultist (Devour Blessing) | Skill-name bucket |
| `Heap On (ramp)` | Bar Brawler (Heap On) | Skill-name bucket, per-instance ramp (not a stacking cap) |
| `Final Calculation` | Architect (Final Calculation) | Skill-name bucket |
| `Corsairs Reckoning` | Tidal Corsair (Corsairs Reckoning) | Skill-name bucket |
| `Outbreak` | Plague Doctor (Outbreak) | Skill-name bucket, `bonus_per` keyed to `Target_Debuff_Count` (Batch 1's new generic trait-count source) |
| `Tithe of Vitality` | Bloodmage (Tithe of Vitality) — **settled, not yet implemented** (section 9.4) | Skill-name bucket, `bonus_per` keyed to `Wounded_Allies` (new Batch 1 trait-count source) |
| `Sanguine Pact` (granted status) | Bloodmage (Transfusion) — **settled, not yet implemented** (section 9.4) | Granted holder-missing-Health damage multiplier; lands in whoever holds it, not the caster's own bucket |
| `Hemorrhage` (debuff on target) | Bloodmage (Tithe of Vitality) — **settled, not yet implemented** (section 9.4) | Debuff-type bucket, holder-missing-Health damage multiplier; readable by any teammate's damage, not only the applier's |

Every other Role/skill in the manifest carries `bucket_key = ""` today — either genuinely Channel 1
/ Enabler, or a Batch-1-and-later target whose kit hasn't yet earned a bucket key. Batch 1 adds no
further rows: Appraiser's settled kit (section 9.5) claims **no bucket key at all**, because the
crit path sits outside the `CombinedDamageModifier` by design (`Concept_Document.md` 1.1.4). Its
contribution is real and now scoreable — the scorer gained a crit model in `e3d39bd` — but it is
not a bucket, and recording an empty `bucket_key` on all four of its manifest entries is the
correct outcome rather than a gap to close.

### 10.3 Turn bar zones in use

Zones stay signature (one per Role, per the anti-overlap rules in section 4), so this table is the
check against a new kit accidentally claiming a second one. State as of Batch 1.

| Zone skill | Claimed by |
|---|---|
| Catalyst Cloud | Alchemist |
| Flicker Zone | Chronophage |
| Temporal Sinkhole | Chronophage |
| Miasma | Plague Doctor |
| Raise the Frame | Architect |
| Unstable Rift | Sorcerer |
| Lava Zone | Enemy only (Obsidian Stallion) |
| Inscribe | Enemy only (Glyphbound Archivist) |
| Weight of Law | **Orphaned — no player or enemy fields it** |

Six player-facing zones across five Roles, Chronophage holding two — the one existing exception to
the one-per-Role rule, and consistent with its turn-bar identity. Weight of Law having no owner at
all is a loose end this plan did not create and does not close; note it for whichever batch takes
Emissary, whose theme it matches.

## 11. Scorer plumbing for Channel 3 payloads

`Scripts/Debug/burst_reachability.gd` and `kit_contribution_manifest.gd` are the authority the
sweep reads. Batch 1's Channel 3 payloads (the reworked Sorcerer's Echo, Herald's Cut the Cloth,
Plague Doctor's Comorbidity/Miasma retick, Unstable Rift's zone damage) each needed a scorer
capability that did not exist; this section previously listed those as open gaps and now records
what landed. This was tier-1 plumbing under the plan's per-batch loop — fixed ahead of the kits
that need it, not deferred to a later batch.

The manifest's `reagent_gated_bonus` field is renamed **`gated_bonus`** and widened in place:

* **`fold`** now has three values: `"same_instance"` (default, unchanged), `"separate_instance"`
  (unchanged — the Sorcerer's repeat), and new **`"sustained_ticks"`** — damage spread across
  several of the boss's own future turns rather than the one action being scored, reported into a
  new `CandidateResult.sustained_contrast_ratio` and deliberately excluded from
  `total_contrast_ratio` (which stays a pure single-action figure, still what gets checked against
  `Concept_Document.md` 1.1.2's 30-50x burst-band target). A new **`combined_contrast_ratio`**
  (`total_contrast_ratio + sustained_contrast_ratio`) is what `TeamResult.Best()` and `TeamSweep`
  actually rank by — folding sustained payload out of the burst-band contract number but back into
  the ranking key is what lets a DoT/zone-charge combo (Plague Doctor, Unstable Rift) compete
  against a direct-damage combo (Tidal Corsair + Tactician) for "which team wins" at all, rather
  than being structurally invisible to that comparison.
* **`gate`** (`StringName`) replaces the reagent-specific `reagent_assumed_available` framing,
  naming the precondition axis itself (`&"reagent_consumed"`, `&"debuff_count"`,
  `&"zone_charges_consumed"`, ...). Every gate a candidate's score depended on is surfaced on
  `CandidateResult.assumed_gates`; `reagent_assumed` is now derived from it
  (`assumed_gates.has(&"reagent_consumed")`) rather than independently tracked, so existing
  regression fixtures naming it are unaffected.
* **`instances`** (int, default 1, clamped to `CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION`)
  and **`instance_compounding`** (float, default 1.0 — flat) replace the old fixed-at-1 assumption
  for `"separate_instance"`/`"sustained_ticks"` folds: each declared instance contributes
  `(1.0 + magnitude) * instance_compounding^i`, `i` 0-based
  (`BurstReachability._MultiInstanceContrastRatio`). Verified in
  `Tests/unit/test_burst_reachability.gd` against this document's own projections: Echo (4
  instances, −0.5, 1.75 compounding) reproduces section 9.3's 5.586x; Cut the Cloth (8 instances,
  +0.08 at Legendary — the 90% base strength and the passive's own self-bonus folded into one net
  per-instance multiplier — flat) reproduces section 9.2's 8.64 curve.
* **Zone-trigger damage** is no longer invisible: a skill with no top-level `DamageEffect` is now
  enumerated off its enemy-facing `ZoneEffect.on_trigger` `DamageEffect`s instead
  (`_ZoneTriggerEnemyDamageEffects`) — an ally-facing payload in the same zone (Unstable Rift's own
  0.15 Mysticism ally hit) is excluded, since this scorer measures damage against the boss. The
  zone's own first trigger lands in the candidate's ordinary `contrast_ratio`; its remaining
  charges are declared as a `"sustained_ticks"` `gated_bonus` (`gate: &"zone_charges_consumed"`).
* **Sustained tick repetition** (Comorbidity, section 9.1) is scored the same way: a
  `"sustained_ticks"` `gated_bonus` on Outbreak's own manifest entry (the skill that places the
  debuff the tick rides on), approximated against Outbreak's own scaled aggregate since this
  scorer has no separate DoT-scaling model — `bucket_key` stays empty, matching the field's
  existing convention that a mechanism which never reaches a `CombinedDamageModifier` bucket
  claims no key. Miasma's own forced retick still carries no independent score: it has no
  `DamageEffect` of its own, top-level or zone-trigger, to attach a `gated_bonus` to.

**Consequence for measurement.** `total_contrast_ratio` stays the pure single-action figure the
30-50x burst-band target is checked against; `combined_contrast_ratio` is the separate figure
`Best()` and the sweep's top-decile selection actually rank by, sustained payload included. Reading
`total_contrast_ratio` alone for a sustained-heavy kit understates its actual standing in the
roster — `Tests/manual/team_corpus_sweep.gd`'s top-decile report prints both, plus a
`sustained_driven` flag per row, so which figure moved is visible rather than conflated.
