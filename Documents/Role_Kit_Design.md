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

**Status:** Settled, not yet implemented. Batch 1.

**Passive: Weft and Warp.** The Herald always holds exactly one thread. Once per turn, as a free
action, the Herald may switch thread — before or after using a skill, but not both. Max Tension is
a constant 7 at every rarity.
* Golden Thread — gain 1 Tension when a cascade instance resolves on an enemy (Cut the Cloth's own
  instances excluded, to avoid a self-feed loop).
* Silver Thread — the Herald's debuffs cannot be resisted and last 1 turn longer.
* Black Thread — the first cascade instance to resolve on an enemy each action resolves one
  additional time.
* Cascade instances cast by this champion deal bonus damage: +5% Uncommon, +10% Rare, +15% Epic,
  +20% Legendary. (Generic wording deliberately — applies to any cascade instance the Herald
  produces, names no skill, so the passive and the skills stay decoupled.)
* Starting Tension: 0 Uncommon/Rare, 1 Epic/Legendary. Tension does not persist between combats
  (matches Arcane Instability's precedent).

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Thread Snap | Mysticism-scaled damage to one enemy; applies Suppress for 1 turn. | 1 |
| Signature | Pull the Thread | Mysticism-scaled damage to one enemy, pushes them backward 15% on the turn bar, applies Temporal Leak for 3 turns, and grants the Herald 2 Tension (stance-independent). | 2 |
| Signature | Cut the Cloth | Damage to one enemy at 90% of a normal Mysticism-scaled hit, resolved once per Tension held (minimum once), then consumes all Tension. | 3 |

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

**Implementation needs (not yet built):** a `Combat_Event` value firing on indirect damage (debuff
ticks, zone triggers, cascade instances) for Golden Thread to hook, since `Combat_Event.Damage_Dealt`
only fires from the direct-cast path (`battle_resolver.gd:777`); and the generalized trait-declared
free-action button (the graft button's pattern, generalized off its current hardcoded
Symbiote-Role check at `battle.gd:277-279`) for the once-per-turn stance switch. The manifest
scoring shape for Cut the Cloth (section 11's now-generalized `gated_bonus`, `fold:
"separate_instance"`, `instances: 8`, no `instance_compounding` — the flat curve) is available once
the kit itself is authored; a `gate` value naming the Tension precondition (e.g. `&"tension_spent"`)
is a batch-time authoring decision, not a further scorer gap.

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

**Turn bar effects** — unchanged from the archived pass: Dead Weight (Bar Brawler), Battle Orders
(Tactician); Anchor, Temporal Leak, Slipstream, Steadfast, Resonance unclaimed.

**Debuffs** (rows that changed this batch; all others unchanged from the archived pass — see
`Plan_Role_Skill_Kits.md` Archive for the full table until the next batch refreshes it here)

| Effect | Claimed by |
|---|---|
| Plague | Plague Doctor (Outbreak) — moved from Miasma; now stackable, no longer expiry-spread |
| Blight | Plague Doctor (Miasma) — moved from Quarantine Breach (renamed Outbreak) |
| Suppress | Herald of the loom (Thread Snap) — **settled, not yet implemented** (section 9.2); shipped code still has this on Thread Lash until Herald's kit is authored |
| Temporal Leak | Herald of the loom (Pull the Thread) — **settled, not yet implemented** (section 9.2); newly claimed, retiring part of `FeatureIdeas.md`'s "Rework Orphaned Turn Bar Effects" item once live |
| Warped | Sorcerer (Unstable Rift reliably, Arc Lash's 25% rider) — **settled, not yet implemented** (section 9.3); both sources are the same Role, so the identity-effect rule still holds |

**Buffs** — unchanged from the archived pass this batch, with one pending removal: Attune's second
claim (Herald of the loom's Woven Blessing, alongside Cultist's Chosen Vessel passive) drops once
Herald's settled kit (section 9.2) is implemented — Woven Blessing is not part of it and nothing
in the new kit applies Attune.

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

Every other Role/skill in the manifest carries `bucket_key = ""` today — either genuinely Channel 1
/ Enabler, or a Batch-1-and-later target whose kit hasn't yet earned a bucket key. Batch 1's
remaining Roles (Bloodmage, Appraiser) are expected to add rows here; add them in the same edit
that updates the manifest.

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
  −0.1, flat) reproduces section 9.2's 7.2x.
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
