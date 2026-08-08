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
