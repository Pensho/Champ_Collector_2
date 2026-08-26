# Role Kit Design

Archived design record for the Blowout pillar's kit layer, produced by the completed
`Plan_Role_Kit_Rework.md` and kept as the balancing reference for every kit's channel contract,
synergy grammar, and coverage ledger — the content `Concept_Document.md` 3.2.4.2 (the current
authority for what each Role's kit does) does not carry. Supersedes the older
`Plan_Role_Skill_Kits.md` in that role.

**Status:** channel identity allocation, contribution direction, and pairing web settled; all four
batches designed and all 20 Roles settled — 19 with a section 9 entry, the Tactician kept unchanged
in section 7's table. **All 20 implemented**: 17 kits changed, and the Tactician, Symbiote (§9.17)
and Bar Brawler (§9.18) settled as kept, owing no code. **Final sweep**
(`Tests/manual/team_corpus_sweep.gd`): combined-modifier-product median 1.95x, 90th percentile
4.68x, ceiling 16.24x; contrast-ratio ceiling 21.12x; top decile (114 teams) across **10 distinct
pairings**, meeting section 4's roster-shape target.

## 1. The per-Role kit contract

**The 30-50x burst figure is not a per-Role target** — it is a team figure, and section 4 owns the
distinction. **The figure a kit is designed and checked against is a factor of roughly 2x, one or
two of them.** No Role is required to reach 30-50x, on its own cast or at all; a kit that does is
carrying the team's whole burst by itself, which is the monoculture this document exists to
prevent.

Each Role declares two things — **one primary channel identity** (Channel 1, Channel 2, Channel 3,
or Enabler) and **one contribution direction** (self-facing or exported) — and must be able to put
on the table by burst time:

* **one contribution matching its declared identity.** For a Channel 1/2/3 identity that is at
  least one distinct damage factor of roughly 2x — a `CombinedDamageModifier` bucket key, a cascade
  instance count, or a crit-path contribution (`Concept_Document.md` 1.1.4 places the crit path
  outside the combined modifier by design, so a crit-path kit claims no bucket key and is measured
  where its factor lands instead). For an Enabler identity it is the collapse test (section 1.2)
  in place of a damage factor;
* **at least one composition hook** — something it reliably puts into the world that another
  kit's condition can read.

A kit clearing the contract with one ~2x factor and a hook is a finished kit. "Could it be made to
contribute more damage?" is not a reason to keep designing, and a kit is never revised upward to
close a gap against another Role's recorded number.

**A declared identity is a claim on one term of a product the team assembles, never a self-contained
total.** A Role supplies its term; the other channels come from teammates (`Concept_Document.md`
1.1.3). Reading a Channel 3 kit's small Channel 2 bucket as a shortfall measures a term the Role
never claimed, and pushes every kit toward being a self-sufficient damage dealer. Judge a kit on the
term it declared, in that term's own kind (section 4).

### 1.1 Contribution direction

Direction is **whose sheet the Role's primary contribution is measured on** — not what kind of
effect produces it.

* **Self-facing.** The kit's value shows up in the Role's own output. Its factor multiplies its
  own damage (Outbreak's debuff-count bucket, Corsair's Reckoning, Cut the Cloth's instance
  count). Played alone it still does its job, worse but intact.
* **Exported.** The kit's value shows up on teammates. Either as a damage factor they carry — a
  granted modifier-bearing status (Daunting Strength, Sanguine Pact), a debuff every attacker
  reads (Hemorrhage), a consigned attribute (Keen Edge, Lethal Precision) — or as the window they
  survive in: damage redirection (Shield Wall), a blocked application (Premonition, Aegis), a
  granted defensive attribute (Fortify). Played alone the kit does very little; its output is
  defined by who it is played with.

The test is: **remove the teammates — does the kit still do its job?** If no, it is exported. Both
directions satisfy the contract equally, and both are held to the same standards — an exported
damage factor to the same ~2x figure, an exported window to the collapse test (section 1.2).

Section 9 records an exported Role's contribution where it lands — the factor's magnitude on the
carrier (§9.4's Bloodmage, §9.5's Appraiser), or the collapse-test claim its protective skill
makes. Direction is already half-visible in section 10.2, where a granted-status row and a
skill-name row are the two bucket shapes; declaring it per Role extends that to the protective
kits, which claim no bucket at all, and makes it a design target rather than a byproduct. The
roster target is in section 5.

### 1.2 Enabler, and where a Sustain purpose lands

**Enabler is both a skill-level tag and a permitted Role-level identity.**
`Concept_Document.md` 1.1.3 establishes enablers as a fourth class of effect that produces no
damage at all, and states plainly that they "are not a damage channel and are not to be converted
into one — … A roster where every status touches damage carries fewer decisions, not more." A Role
whose flavor centers on protection, denial, or control may therefore declare **Enabler** as its
primary identity and field no damage factor at all, and it is measured on the collapse test alone.
That is a complete pass, not a concession.

Every Role still fields a basic skill, which is Channel 1 by default simply by scaling an
attribute; that is not a channel identity claim. A basic may also carry a rider — a low-chance
status application, a small heal, a stack grant — or a Channel 2 bucket key, **provided the key is
conditional**: gated on world state the player has to produce (Pratfall Sting's avoidance, Citation's
Infraction tally). An *unconditional* key on a no-cooldown cast makes channel contribution free and
is the one shape forbidden. Bar Brawler's Heap On ramp is a **sanctioned exception** to both this
rule and section 4's uncapped-growth constraint, kept on the rule of cool (§9.18).
Most basics stay plain: the allowance lets a kit put its identity on its basic, not a licence
for every Role's basic to grow a second clause. A Role of any identity may carry zero or more
Enabler-tagged skills or riders — a basic skill's secondary rider, a dedicated protection/denial
skill, a heal — each held to the **collapse test** (`Concept_Document.md` 1.1.6) on its own
merits: removing it makes the burst not happen, or not survive to happen. "Useful to have" fails.

Whether a protection-flavored Role (Scholar, Diviner, Symbiote, Bar Brawler, Warlord — section 5)
declares Enabler or a damage channel is a per-Role decision made at its own batch, from what the
kit actually wants to be. It is not a target to be met: do not add a damage anchor to a kit that
does not want one merely so its section 5 row reads Channel 1 or Channel 2.

**A Sustain purpose is discharged through Enabler-tagged skills.** Sustain, Control, and denial
(`Concept_Document.md` 3.1.3's purpose vocabulary) are ways to *reach* the burst, not to build
it — they create or protect the window the three channels fire in, which is exactly 1.1.3's
enabler class. A Role carrying one of those purposes therefore needs no separate channel
allocation for it; it needs its Enabler skills to be **authored with intent and recorded as kit
content**, not left as whatever the third slot ended up holding after the damage anchor was
designed. Each settled kit's section 9 entry names its Enabler skills and the collapse-test claim
each one makes. A Role that satisfies its channel contract with three damage skills while its
declared Sustain or Control purpose goes unserved has failed the contract, not passed it.

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
* how many distinct debuff *types* are on the target (`bonus_per: {Target_Debuff_Count}` counts any
  type from any source, including types authored later).

## 3. The synergy grammar

"Synergy" has to be expressible in the `.tres` schema, so the design works from the mechanisms
that actually multiply (`Technical_Design_Document.md` 7.4):

| Mechanism | Schema | Why it multiplies |
|---|---|---|
| Trait-counter factor | `DamageEffect.bonus_per: {Trait_Count_Source: float}` | Reads a counter another kit can feed. `Target_Debuff_Count` is the debuff-density surface: it counts any distinct debuff type from any source, so a type authored in a later batch feeds it without editing the skill. Sums into the skill's own single bucket, so density is a linear payoff. |
| Per-named-debuff factor | `DamageEffect.bonus_per_debuff_on_target: {Debuff_Type: float}` | One independent bucket per **named** debuff type, so each named type present multiplies. **Identity-scoped, not a general hook**: the dictionary enumerates its debuff types at authoring time, so it reads nothing invented later and is a step toward the named coupling section 2 forbids. Sole claimant is the Sorcerer's Cataclysm reading Warped, and it stays that way — a kit wanting debuff density uses the counter above. |
| Granted modifier-bearing status | `ApplyBuffEffect` of a `DamageMultiplier` / `PerTargetDebuffDamagePercent` status | Lands the factor on whoever consumes it. |
| Echo count | `Types.Cascade_Trigger` | Each Echo re-reads channels 1 and 2, so count multiplies against them. |
| Zone `on_trigger` payload | `ZoneEffect.on_trigger: Array[SkillEffect]` | A separate resolution on a schedule the enemy walks into. |

Governed by the composition law (`Concept_Document.md` 1.1.3): **same bucket key adds, distinct
keys multiply, and keys are mechanic identity — never character identity.** Two Roles applying the
same debuff type produce one factor, not two.

**Using the cascade machinery is not the same as being Channel 3.** The test is the **total number
of resolutions**, not whether cascade plumbing was involved. An effect qualifies when it takes a
resolution count of 1 and makes it more than 1 — an *additional* resolution of a skill that already
resolved, whether the extra count is fixed (+1 is 2x) or varies with a resource, tally, duration or
charge count. What fails the test is an effect whose total is one: it re-triggers nothing, so it
multiplies nothing, and it belongs to whichever channel its scaling puts it in whatever plumbing
delivers it. Overflow is the worked example — a `Status_Expired` listener whose payload is a single
delayed area hit, total count 1, and therefore Channel 1.

**Channel 3's vocabulary is explicitly open.** `Types.Cascade_Trigger` currently holds only
`Status_Expired`, `Status_Landed`, and `Skill_Resolved`. The named gaps with no trigger at all:
threshold crossings (Health, status count), and cascade-on-cascade. Section 5 below proposes using
the threshold-crossing gap for two of the new Channel 3 anchors; the plan authors the enum value
and its `Post()` call site when a batch's design earns it.

## 4. Targets and current baseline

**Two different figures, never interchangeable.**

* **The team figure — 30-50x.** A boss-tier burst resolution deals 30-50x the champion's own basic,
  preferring 50x (`Concept_Document.md` 1.1.2). This is a property of a **team in an encounter at
  the moment of one resolution**, never of a Role. Nothing is designed against it directly; the
  sweep reports it, and it is the only place the number belongs.
* **The per-Role figure — roughly 2x, one or two factors.** Against a boss-tier Defence of 120
  (Defence's mitigation ratio is taken against the fixed `GameBalance.DEFENCE_SCALE_CONSTANT =
  100.0`, per `Concept_Document.md` 1.1.4, so it keeps its full percentage weight at burst scale),
  a 50x burst needs a 50x multiplier on the scaled attribute aggregate — which 1.1.2 decomposes as
  "about six independent factors of 2x, ten of 1.5x, or four of 3x", spread across three champions.
  **This is the figure a kit is designed and checked against.** A Role landing one or two factors
  in the 1.5-3x range has met the target; a Role declaring an Enabler identity (section 1.2) meets
  it with no damage factor at all.

**A per-Role projection in section 9 that reads 30-50x is a team figure.** Those projections
multiply the Role's own factors by an assumed teammate product (§9.2 and §9.3 both assume 5.5) to
show the kit *composing*. The resulting number belongs to the illustrative team, not to the Role,
and is never a bar another Role is expected to match.
* Current roster baseline (`Tests/manual/team_corpus_sweep.gd`): combined-modifier-product median
  **1.62x**, 90th percentile **2.80x**, ceiling **7.22x**; contrast-ratio ceiling **9.39x**. Every
  batch records its delta against this baseline as the distribution's *shape* (median, 90th
  percentile, ceiling, count of distinct top-decile pairings), not only the maximum.

### The roster-level distribution of per-Role factors

The figure above sizes one kit; this is what the *set* of them should look like.

**Target: the Roles declaring a damage identity cluster at the contract figure**, most between 1.5x
and 3x, no long tail either way. A few Roles at 5-8x with the rest at 1.3-1.5x fails section 1 in
both directions — the high kits carry a team's whole burst alone, and fielding one becomes the only
route to the band.

**Factors are only comparable within their own kind** — bucket product, Echo count,
crit-path multiplier, mitigation-term factor (§9.12's bypass, §9.10's Defence debuff),
aggregate-term factor (§9.14's attribute-modifier amplification), exported factor on a carrier. One
ranked column across all of them is not a measurement.

**Current state: bimodal.** Instance counts: Herald 8.64x, Sorcerer 6.25x at its gated ceiling (1.5x
steady state), Plague Doctor's Comorbidity never projected (§9.1). Bucket products: Architect,
Tactician, Tidal Corsair, Bloodmage at 1.7-2.2x, Lancer at 1.54-1.90x; Emissary, Alchemist, Scholar at 1.3-1.5x.
Appraiser's ≈5.58x is the only crit-path figure. Closing this runs one way: **a Role above the band
is pulled down at its own batch; a Role below it is not raised to match** — a low figure is first a
question about whether the Role's declared identity is honest (section 1.2).

### What the sweep measures

The sweep is a sanity check on one calculable factor — single-action damage against a boss. It
reports whether the burst band is reachable and through how many distinct pairings, and whether a
kit lands far outside the band. It holds no survival, turn-count, or encounter term, so it never
says whether a team is good. Two rules follow:

* **A kit is never designed to raise its number.** The number reports on the design; it does not
  direct it.
* **Enabler, sustain, and exported-window contributions get no synthetic scores.** They are judged
  by 1.1.6's collapse test in the batch's own review, and are absent from the ranking by design.
* **A kit far outside the band is a prompt to look, not a verdict.**

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
* **Skill and passive description length is soft-capped** (`Concept_Document.md` 3.2.4).
* Existing anti-overlap rules: identity effects to one Role, commodity buffs/debuffs to at most
  two, turn-bar effects to one, zones stay signature.
* **Accumulate-then-spend stays at its current claimants** — Tidal Corsair, Architect, Herald,
  Sorcerer. A legitimate RPG idiom and a fair allocation at four; no further Role takes it
  absent new information. The Lancer left when its passive settled onto a positional gate (§9.11). Cultist's per-cast bonus and Bar Brawler's Heap On ramp are continuous
  growth, not build-then-spend, and are not counted here.

## 5. Channel identity allocation

Current shipped tags (`Concept_Document.md` 3.1.3 / 3.2.4.2) are a byproduct of one-note kits, not
a considered allocation — most Roles are tagged Channel 1 today simply because that's what a plain
damage or attribute-debuff skill defaults to. This section states the *intended* primary identity
for the reworked kit, chosen to fix the two shortfalls the current baseline exposes: Channel 3 is
nearly empty (see section 3's instance-count test — one real entry when this plan opened) and
Channel 2's buckets are almost all private (section 8).

Target shape: 4 Channel 3 anchors (up from ~1 real Role-driven anchor), 9 Channel 2 anchors, 7
Channel 1 anchors.

**This shape is a proposal, not a quota**, and every row for an unsettled Role is a proposal at
most. The table was written in Phase 1, **before** Enabler was permitted as a Role-level identity
(section 1.2), so a row reading Channel 1/2/3 may be an artifact of an allocation made when no
other answer was available — not a judgment that the Role wants a damage anchor. Read an unsettled
row as a starting suggestion, and settle the identity from what the kit wants at its own batch;
Appraiser and Jester have already moved off their rows. The five Roles leaning hardest into protection or denial
(Scholar, Diviner, Symbiote, Bar Brawler, Warlord) are proposed as Channel 1 or 2 here but are all
legitimate Enabler candidates — none is given a damage anchor it does not want to hold its row.
The roster-level concern is only that Channel 3 and cross-kit Channel 2 hooks stop being nearly
empty.

**Direction target: at least half the roster exports its primary contribution** (section 1.1). This
is the roster-shape guard against 20 kits that each only multiply their own damage — the allocation
below sets **10 exported against 10 self-facing**. The two groups are not tiers: an exported Role
is as load-bearing as a self-facing one, and several of them (Tactician, Scholar, Alchemist) are
already what the current ceiling pairings run through.

Direction is settled for all 20 Roles; each Role's own section 9 entry owns its status and what it
ships, and this table records only the allocation.
A Role's basic skill is always self-facing; direction describes the declared-identity contribution.

| Role | Purpose (unchanged) | Primary identity | Direction | Composition hook |
|---|---|---|---|---|
| Plague Doctor | Debuffer | **Channel 3** | Self | §9.1. Debuff density on the target feeds Echo count — the deepest identity claim in the roster. |
| Sorcerer | Damage, Debuffer, Control | **Channel 3** | Self | §9.3. Reagent-triggered repeat re-resolves channels 1 and 2 as a fresh instance; the second, independently-gated cascade anchor. |
| Herald of the Loom | Debuffer, Buffer | **Channel 3** | Self | §9.2, which replaced this row's Phase 1 sketch of a status-expiry cascade. Weft and Warp's three threads carry the identity, and Cut the Cloth resolves once more per Tension held — the roster's deepest instance count. |
| Chronophage | Control | **Channel 3** | Exported | §9.9, confirming this row without the threshold-crossing trigger it originally proposed — a boundary-counting gate reads as arithmetic the player cannot see. Instead the passive grants Borrowed Time to an ally it boosts alone, and that ally's next skill resolves once more. The Role fields no damage factor of its own (Batch 2). |
| Emissary | Debuffer, Control | **Channel 2** | Exported | §9.7, confirming this row. Sanction carries a snapshotted per-Infraction damage multiplier every attacker on the team reads, and stays a distinct debuff type feeding the density count (Batch 2). |
| Alchemist | Debuffer, Buffer | **Channel 2** | Exported | §9.15, confirming this row. Fresh Batch's team damage buff stays the reagent-consumption anchor and Catalyst Cloud's refund keeps the consumption count up; the factor lands on the whole team, not the Alchemist. |
| Appraiser | Debuffer | **Enabler** | Exported | §9.5, moved off this table's Phase 1 proposal of Channel 2: the whole contribution runs through the crit path, which claims no bucket key and multiplies outside the combined modifier (1.1.4), independent of the debuff-density and cascade routes. The kit consigns that contribution to a carrier. |
| Cultist | Debuffer, Damage | **Channel 2** | Self | §9.8, confirming this row. Chosen Vessel's flat per-cast bonus stays flat; Vessel death now also grants permanent Devotion, and the basic reads the Vessel's half-Health threshold (Batch 2). |
| Jester | Damage, Sustain | **Enabler** | Exported | Hexed on the boss degrades every roll it makes in its own favor — crit checks, resist checks against the team's debuffs, its own Burning ticks — so a debuff-density burst becomes reliable rather than a coin flip; Spotlight pulls focused fire onto the champion built to dodge it. §9.6, and moved off this table's Phase 1 proposal of Channel 2 / self-facing: the kit declares no damage contribution (Batch 2). |
| Architect | Buffer, Damage | **Channel 2** | Self | §9.10, confirming this row. The kit is kept as it ships — the finisher's charge bucket already meets the contract and the zone already consumes charges against it. Only Expose Weakness changes, scaling with the charges spent (Batch 2). |
| Tidal Corsair | Damage | **Channel 2** | Self | §9.13, confirming this row. Corsair's Reckoning resolves by the composition of the stacks it consumes; Sea's turn-bar push retires and Sea instead raises The Gilded Deck, a signature zone granting boarding allies permanent Sea Legs stacks (Batch 3). |
| Thief | Damage | **Channel 1** | Self | §9.12, confirming this row. Pilfer retired for Between the Plates, a passive bypass reading a fraction of a debuff-free reference Defence, so a teammate's Defence shred compounds with it instead of being eaten by it; Weigh the Mark rebuilt as Cut Purse. |
| Lancer | Damage | **Channel 2** | Self | §9.11, moved off this table's Phase 1 proposal of Channel 1. Momentum and Phalanx Guard retire for Couched Lance: the charge scales with the turn-bar sections it touches and throws the Lancer back half that distance. The Role reads turn-bar position rather than accumulating stacks, so it is no longer route D's second anchor (Batch 3). |
| Tactician | Buffer | **Channel 1** | Exported | **Settled: kept as shipped.** A second hook was explored (Batch 3) and shelved — no addition fit without a clearer read on the Role's team fantasy than a sweep figure can give; open to revisiting outside this plan. |
| Bloodmage | Sustain, Damage | **Channel 1** | Exported | §9.4. Hemoclarity's missing-Health Mysticism curve is already Channel 1 by mechanism; the kit's weight lands in Sanguine Pact (on the carrier) and Hemorrhage (on the boss, readable by every attacker) rather than on the Bloodmage's own cast. |
| Scholar | Debuffer, Buffer | **Channel 2** | Exported | §9.14, confirming this row. Opportunist stays the modifier-bucket anchor; the passive is replaced with an amplifier on every attribute modification the team applies, giving the roster its first reader of the Channel 1 attribute layer, and the basic gains a zone-gated Suppress rider (Batch 3). |
| Diviner | Sustain, Debuffer | **Enabler** | Exported | Redeclared from Channel 1 at Batch 4 (§9.16): Enfeeble, Premonition and Hexed are all mitigation and denial, and the kit owes no damage factor. Measured on the collapse test. |
| Symbiote | Sustain, Buffer | **Channel 1** | Self | Exhert's attribute buff is the baseline anchor, present from the ungrafted state on, and it lands on the Symbiote itself. Direction corrected from Exported at Batch 4 (§9.17); post-graft the kit may read either way depending on which graft the player binds (pool-dependent, `Symbiote_Graft_Pool.md`), and the ungrafted baseline is what fixes the declaration. |
| Bar Brawler | Sustain, Buffer | **Channel 2** | Self | §9.18, kept as shipped. Heap On already grows stronger with every use — the basic skill itself is the modifier-bucket anchor. On the House's heal-on-buff stays an Enabler-tagged skill within the kit, not the Role's identity. |
| Warlord | Sustain | **Enabler** | Exported | Redeclared from Channel 1 at Batch 4 (§9.19): Fortify raises Defence, which is no damage term, and the whole kit is mitigation. The weight is the window it holds open — Shield Wall's redirection, Hold the Line's Fortify, Brace for Impact's Enfeeble. Measured on the collapse test. |

## 6. The pairing web

Tidal Corsair's Steel/Sea route already reaches the ceiling and stays as-is. The gap the current
baseline exposes is that it was the *only* route — the top decile was one repeated pairing. The
routes below are each gated by a different mechanic and none depends on Tidal Corsair or on
Tactician's grant alone. "Independent" means: remove any one route's anchor Roles from the roster
and the rest still reach a comparable product through unrelated mechanics. Routes A-E were sketched
in Phase 1; route F was opened by a settled kit, and a later batch may open another the same way.

| Route | Gating mechanic | Anchor Roles | Batch |
|---|---|---|---|
| **A — Debuff density** | Count of distinct debuff *types* on the target, read through `bonus_per: {Target_Debuff_Count}` (open to any source, linear in the count) | **Closed.** Plague Doctor (Plague, Blight, self-facing) + Emissary (Sanction, exported — §9.7) | 1 → 2 |
| **B — Cascade count** | Repeat/expiry-triggered re-resolution compounding fan-out | Sorcerer (reagent repeat) + Herald of the Loom (status-expiry cascade) | 1 |
| **C — Crit path** | Crit chance/damage growth, outside the combined modifier (1.1.4) | Appraiser (§9.5). **Second anchor open** — the Jester was the Phase 1 proposal and is no longer a candidate (§9.6). Any Role not yet settled may fill it if its kit genuinely wants the crit path; none is assumed to. | 1 → open |
| **D — Stack consumption** | Self-contained accumulate-then-spend payload | **Closed.** Architect (Calibration finisher, exported through Expose Weakness — §9.10) + Tidal Corsair (the Reckoning's composition modes, self — §9.13). The route's original "non-Corsair" framing was a guard against the shipped ceiling pairing, which the post-Herald sweep has already displaced. | 2 → 3 |
| **E — Health threshold** | Missing-Health percentage as a `bonus_per` surface | **Closed.** Bloodmage (caster-own and enemy-own missing Health, §9.4) + Cultist (the Vessel's threshold and its death, §9.8) | 1 → 2 |
| **F — Turn-bar distance** | The turn-bar span between attacker and target, read at the moment of impact | Lancer (Couched Lance, §9.11). Every kit that pushes an enemy back feeds it — the Corsair's Sea stacks, the Chronophage's theft, Dead Weight, Temporal Leak — so the route's other half is any turn-bar writer, not a designated anchor. | 3 |
| **G — Armour removal** | The target's effective Defence at the moment of impact, outside the combined modifier | **Closed and implemented.** Architect (Expose Weakness, exported — §9.10) + Thief (base-referenced bypass, self — §9.12). The two compose because the bypass subtracts points off a debuff-free reference Defence rather than scaling what a shred leaves behind. The Alchemist's Dissolving Agent is a third feeder, implemented (§9.15). | 2, 3, 4 |

**Direction mix across the routes.** A route with one exported anchor and one self-facing anchor is
the healthy shape — one kit hands the factor over, the other spends it. Routes A and E have it;
route C has only its exported anchor so far.
**Routes B and D are predominantly self-facing**: Sorcerer and Herald both multiply their own
damage, as do Architect and Lancer — Chronophage's Borrowed Time (§9.9) and Architect's Expose
Weakness (§9.10) are the exported exceptions. Those two routes therefore compose only
by both champions bursting, not by one enabling the other, which makes them the routes most likely
to produce the "every kit is its own damage dealer" shape section 1.1 guards against. Not corrected
here — Batch 1's cascade anchors are already settled or implemented — but it is the first thing to
look at if the sweep's top decile collapses onto a single cascade pairing again (see the plan's
post-Herald sweep note). Chronophage is the exported cascade anchor route B lacked, settled in
§9.9: Borrowed Time hands an extra resolution to a teammate, so the roster's cascade weight is no
longer entirely each champion multiplying its own damage.

Each route is a candidate combination to validate during its batch's own 1.1.6 review, not a
scripted pair enforced in code — per section 2, no skill in any of these kits may name the other
Role. A team assembling route A's debuff types is satisfied by *any* kit producing Plague, Blight,
or an Infraction-scaled debuff, not specifically Plague Doctor and Emissary. Route assignments are
proposals on the same terms as section 5's rows: a route left with one anchor is a gap to fill from
any Role that genuinely fits, or to drop.

## 7. Batch composition for Phases 2-5

Batch 1 (Phase 2) is fixed by the plan: Plague Doctor, Herald of the Loom, Sorcerer, Bloodmage,
Appraiser — chosen to open routes A (partial), B, C (partial), and E (partial) in one pass, plus
absorb the Comorbidity fix.

Batches 2-4 (Phases 3-5), proposed here per the plan's instruction that composition is fixed once
the pairing web exists:

* **Batch 2 — close the routes batch 1 opened.** Emissary (closes A), Architect (opens D
  independently), Chronophage (new Channel 3 anchor, no route dependency yet), Cultist (closes E),
  Jester (settled as an Enabler kit, §9.6 — it strengthens route A's reliability rather than
  anchoring a route, and route C's second anchor stays open).
* **Batch 3 — the positional and Enabler pass.** Lancer (**settled, §9.11** — replaced its passive
  with a turn-bar read, leaving route D's second anchor open), Thief (**settled, §9.12** — a
  base-referenced bypass passive, opening route G with the Architect), Scholar, Tactician
  (**settled, kept as shipped** — see this table's row), Tidal Corsair (**settled,
  §9.13** — a composition-reading Reckoning, closing route D).
* **Batch 4 — remaining protection/denial kits and expansion-only kits.** Alchemist (**settled,
  §9.15** — passive kept, a refund payload on Catalyst and a two-debuff third slot), Diviner
  (**settled, §9.16** — redeclared Enabler, one reworked slot), Symbiote (**settled, §9.17** —
  kept, direction corrected), Bar Brawler (**settled, §9.18** — kept, Heap On sanctioned),
  Warlord (**settled, §9.19** — redeclared Enabler, one reworked slot). **Batch complete.** All five
  are adaptations or kept kits; two Roles' declared channels were redeclared and one's direction
  corrected, since §5's rows for the protection kits had assumed a damage term each kit does not owe.

This grouping favors closing routes early over leaving half-pairings scattered across three
batches — batch 2 alone completes the pairing web's every proposed route, leaving batches 3-4 to
fix known bugs (Lancer, Comorbidity already in batch 1) and give the remaining Enablers their
collapse-test payload without inventing new gating mechanics.

## 8. Open items for later batches

* **Cross-kit Channel 2 stays the axis to watch.** Section 10.2 is still mostly private: nine
  self-facing skill-name buckets and three sharing the self-facing trait-resource key, against five
  exporting entries (`Daunting_Strength`, `Volatile_Mixture`, Bloodmage's two grants, Emissary's
  Sanction). The same privacy runs through the seven accumulate-then-spend counters, which feed
  nothing outside their own kit; most are expected to stay that way, but check it whenever a kit
  could export instead.
* The exact `Trait_Count_Source` / debuff-type identifiers for Emissary's Infraction hook and
  Bloodmage's missing-Health hook are batch-time authoring decisions, not Phase 1 commitments.
* The contrast baseline (bursting champion's own basic vs. team's average per-action output)
  remains open per the plan; not touched by this document.

## 9. Settled kit designs

One entry per Role once its kit is **settled** (brainstormed, picked, and projected against
section 4's per-Role ~2x figure), recorded *before* any `.tres`, trait script, or status effect is
written. This is the record a coverage review reads: what every settled Role's passive and three
skills do and what they project to. An entry's **Status** line tracks whether it has been
implemented yet; a settled-but-unimplemented entry is expected. Rationale for *why* a kit was
shaped this way lives in the history that settled it, not here; claimed status effects and bucket
keys live in section 10's ledger, not duplicated here. **An entry's "Implementation needs" block is
deleted when the kit lands** — never annotated as done, and never rewritten into a description of
what shipped.

Format per entry: Status, Passive, Skills (name / effect / channel), Projected numbers.

### 9.1 Plague Doctor — debuff-density damage and cascade-breadth passive

**Status:** Implemented (`aca439b`). Batch 1.

**Passive: Comorbidity.** Debuffs placed by this Role's skills trigger a cascading extra tick
(`Types.Cascade_Trigger.Debuff_Ticked`) once for every other distinct debuff type on the target
(any source, uncapped, bounded by the shared `MAX_CASCADE_INSTANCES_PER_ACTION` fan-out cap). Each
repeat is a real Echo — its own `Cascade_Triggered` marker and its own
`Cascade_Instance_Resolved` broadcast — rather than a multiplier folded into one aggregated tick
number, so the passive is a genuine Channel 3 anchor, not Channel 2 dressed as one.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Septic Lance | Mysticism-scaled damage to one enemy. | 1 |
| Signature | Outbreak | Mysticism-scaled damage to one enemy, +8% per distinct debuff type on the target (uncapped); applies a stack of Plague for 3 turns (now stackable, no longer expiry-spread). | 2 |
| Signature | Miasma | Zone, 4 charges. On trigger, forces every active debuff on the caught enemy to tick again immediately without losing duration, and applies Blight for 2 turns. | 3 (Enabler-classed by the scorer today — see below) |

**Projected numbers:** not separately recorded before implementation. Comorbidity's sustained,
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
* Golden Thread — gain 1 Tension when an Echo resolves on an enemy (Cut the Cloth's own
  instances excluded, to avoid a self-feed loop — enforced by construction, since Cut the Cloth's
  repeats never call `CascadeResolver.Post`).
* Silver Thread — the Herald's debuffs cannot be resisted and last 1 turn longer.
* Black Thread — the Echo produced by the Herald's own action resolves one additional
  time (not a double — a skill that would resolve once now resolves twice). Scoped to the Herald's
  own action only, since the Herald casts at most one skill per turn.
* Echoes cast by this champion deal bonus damage: +5% Uncommon, +10% Rare, +15% Epic,
  +20% Legendary. (Generic wording deliberately — applies to any Echo the Herald
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
**47.5x** for that whole team. Against a more modest team (product ≈3.0), ≈25.9x. At Uncommon
(same 8-instance ceiling — rarity affects tempo via starting Tension and the smaller +5% self
bonus, not the ceiling itself, since max Tension is now rarity-flat) the same strong-team scenario
gives ≈41.6x.

**These are team figures, not the Herald's own contribution** (section 4). The Herald's own factor
is the instance count: **8.64x at Legendary**, which is well above section 4's per-Role ~2x target
and is why the post-Herald sweep's top decile collapsed onto a single pairing (see the plan's
Status). That is a flag on this kit, not a bar for the next one. Cut the Cloth's 90% strength
(rather than a Sorcerer-style 50% discount) reflects that the setup tax is Tension's multi-turn
build time rather than a second discount on the payoff.

**Implemented as:** `weft_and_warp_trait.gd`, `Thread_Snap.tres` (reworked), `Pull_the_Thread.tres`,
`Cut_the_Cloth.tres` (new), `Herald_of_the_loom.tres` (rewired), `Thread_Switch_Button.tscn` (shares
the Symbiote graft button's slot — the two are mutually exclusive by whose turn it is). A debuff
tick still doesn't post to `CascadeResolver` at all, so Golden Thread does not see one; tracked as a
gap in `Plan_Channel_3_Unification.md`'s Step 9.

### 9.3 Sorcerer — Echo charges and the Surge that feeds them

**Status:** Implemented. Batch 1.

**Passive: Arcane Instability.** Four clauses, each doing one job:

* Using any skill grants 1 Instability stack, maximum 5. Stacks do not persist between combats.
* Consuming a reagent grants 2 Instability stacks, amplifies the reagent's effect, and grants
  1 **Echo** charge.
* At maximum stacks the next skill also releases a **Surge**: damage to all characters, allies and
  the Sorcerer included, scaling 1.4x the Sorcerer's Mysticism, never a critical hit — then all
  stacks reset and the Sorcerer gains 1 Echo charge.
* Each Echo charge held makes the Sorcerer's next skill repeat one additional time; all charges are
  consumed when it does. The first Echo deals 50% of the skill's damage and each further Echo
  compounds on the previous. Each Echo assembles its own combined
  damage modifier; a repeated debuff or zone charge is not reapplied, only the damage.

Rarity scales only on the passive, never on the kit's skills: Echo compounding 1.40 Uncommon /
1.50 Rare / 1.60 Epic / 1.70 Legendary; reagent amplification 20 / 30 / 40 / 50% (unchanged).
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
Surge. At Legendary the four Echoes deal 50 / 85 / 144.5 / 245.65% — 5.25x in repeats, **6.25x**
total including the original cast.

| Scenario | Team contrast ratio |
|---|---|
| Legendary, 4 Echoes, strong team (product 5.5) | **34.4x** |
| Legendary, 4 Echoes, modest team (product 3.0) | 18.8x |
| Legendary, 1 Echo (steady state, no reagents banked) | 8.3x |
| Uncommon, 4 Echoes, strong team | 25.0x |

**These are team figures, not the Sorcerer's own contribution** (section 4). The Sorcerer's own
factor is the Echo multiplier: **6.25x at the 4-Echo ceiling**, 1.5x in the 1-Echo steady state —
above section 4's per-Role ~2x target at the ceiling, which is the deliberate shape of a Channel 3
anchor whose ceiling is gated behind spending three banked reagents in one turn.

The 1.70 compounding factor is steeper than a flat-instance design would need precisely because
the per-stack Mysticism ramp was dropped: that ramp was worth a flat 1.5x on the aggregate, and
moving its weight into the compounding curve puts the ceiling in Channel 3 where the Role's
identity claims it. Peak 4 Echoes plus the Surge in one action, well inside
`CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION = 16`.

### 9.4 Bloodmage — the missing-Health surface, caster-side and exported

**Status:** Implemented. Batch 1 complete.

**Passive: Hemoclarity.** Changed from a below-50% cliff to a continuous curve, and widened past
damage: for every 1% of max Health the Bloodmage is missing, gain +1% Mysticism (0.7/0.8/0.9/1.0%
per rarity, capped at 80% missing), and the same percentage increases all healing and Barrier
absorption the Bloodmage creates. This is the only place in the kit that reads the Bloodmage's own
missing Health — every skill below reads someone else's.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Blood Bolt | Kept as-is. Mysticism-scaled damage to one enemy; self-costs 3% max Health. | 1 |
| Signature | Transfusion | Kept: sacrifices 15% max Health, all other allies gain a Barrier absorbing 200% of the Health sacrificed (2 turns, scaled by Hemoclarity). Added: the same allies also gain **Sanguine Pact** for 2 turns. Cooldown 4. | Enabler + 2 (granted) |
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
against a modest team (product 3.0), ≈13.8x. Both are team figures (section 4); the Bloodmage's own
factors are the 1.70x Wounded_Allies bucket and Hemoclarity's 1.80x aggregate bonus, comfortably
inside §1's ~2x contract. The exported factors below are where this kit's weight actually lands:

* **Sanguine Pact**, on the carrier: 1.60x at 50% missing Health, up to 1.96x at 80% missing —
  handed to whichever teammate is bursting, independent of the Bloodmage's own cast.
* **Hemorrhage**, on the whole team: 1.30x with the boss at half Health, rising to 1.48x as the
  boss drops to 20% remaining — a standing multiplier every damage dealer on the team reads for
  free, plus a distinct debuff type for route A.

### 9.5 Appraiser — overflow crit chance and consigned attributes

**Status:** Implemented.

**Identity note.** This kit's entire contribution runs through the crit path, which
`Concept_Document.md` 1.1.4 places outside the `CombinedDamageModifier` by design. It therefore
claims **no bucket key at all**. Section 1 admits a crit-path contribution alongside a bucket key,
so the kit satisfies the contract as an **Enabler** identity — settled, and section 5's row updated
to match its Phase 1 proposal of Channel 2.

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
* **Confound** (debuff): magnitude raised roster-wide to -50% Knowledge — the term that blunts crit
  damage, which nothing in the roster attacked before. Scholar's Expose Fallacy is the other
  claimant.

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

A `StatusEffectData.caster_scaled` field generalizes the applier-scaled snapshot beyond
`CasterAttributeSnapshotPercent` (`status_effect_resolver.gd`'s `_SnapshotStatusValue`), so Keen
Edge, Lethal Precision, and Cracked Facet snapshot off the applier while keeping their own
`magnitude_kind` (their existing readers — `ApplyAttributeModifiers`, `_AttackerCritDamageBonus` —
are unchanged). Status tooltips now substitute a `{value}` placeholder with the resolved instance
value (`battle.gd`'s `ShowStatusApplied`), fixing every applier-scaled status's previously-silent
magnitude at once.

**Judgment calls made while settling, listed so they can be overruled:** Cracked Facet was placed
on Flaw Analysis rather than left without a source when Strike the Flaw retired, and it scales off
Knowledge rather than Critical Damage so it does not double-dip the attribute Lethal Precision
already consigns.

### 9.6 Jester — the luck Role

**Status:** Implemented. Batch 2.

**Identity: Enabler, exported.** The Jester declares no damage contribution. Its kit holds the
window the burst fires in — pulling focused fire onto the one champion built to survive it — and
denies the boss its favorable rolls. Both attack skills carry ordinary Channel 1 damage and the
basic carries one small conditional factor, but neither is a declared contribution and neither is
sized against section 4's per-Role figure. Section 5's Phase 1 proposal of Channel 2 / self-facing
does not survive contact with the kit.

**The kit is an adaptation, not a rework.** Passive, all three skills, and the Role's shipped
attribute spread (Accuracy, Knowledge, Speed) stand; the changes below are Luck's reach, Hexed's
addition, and Burning's magnitude shape.

**Passive: Double the fun!** Unchanged — 5% base chance to avoid an incoming attack's damage,
ramping by rarity per hit taken to a cap of 3 stacks, resetting on a successful avoidance,
and raising the Jester's targeting weight. Its avoidance roll now goes through
`BattleResolver.RollFavoring` rather than a bare `randf()`, so Luck and Hexed reach it.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Pratfall Sting | Accuracy-scaled damage to one enemy, +30% if the Jester avoided an attack since its last turn. | 1 + 2 |
| Signature | Burning Bolas | Attack-scaled damage to one enemy; applies Burning and **Hexed** for 2 turns. Cooldown 2. | 1 + Enabler |
| Signature | Center Stage | The Jester gains Spotlight for 2 turns and Luck for 1 turn. Cooldown 3. | Enabler |

**The kit depended on three roster-wide mechanics changes** — Luck and Hexed's reach, the
debuff-resist contest band, and Burning's tick — which were not Jester kit content and have shipped
(`Concept_Document.md` 3.2.1 #3, 3.2.3). What they buy this kit: Hexed's resistance clause stops
being nearly inert, and because Hexed makes its holder take the worse of two rolls, a Hexed
target's expected Burning tick is **7.33%** against the 6% mean.

**Composition hooks (exported).**

* **Hexed on the boss** is the kit's primary export and its most load-bearing piece. It degrades
  every roll the boss makes in its own favor — its critical-chance roll, its resist checks against
  the team's debuffs, and its own Burning ticks. A debuff-density team needs its debuffs to land;
  this is what makes that reliable rather than a coin flip, and it names no Role.
* **Burning** is a distinct debuff type, so it feeds any teammate's `Target_Debuff_Count` reader and
  the density count generally.
* **Spotlight** redirects the boss's target selection onto the Jester by targeting weight.

**Collapse-test claims** (section 1.2), the whole of what this kit is measured on:

* **Center Stage.** The Jester draws focused fire onto the champion built to dodge it, across
  exactly the build-up turns where `Concept_Document.md` 1.1.1 puts the threat peak. Remove it and
  that damage lands on the burst carrier instead, and the burst does not survive to happen.
* **Burning Bolas' Hexed.** Claimed on the *breadth* of rolls it degrades, not on debuff landing
  alone: the boss's crit roll against the team, its own Burning ticks, and every other chance roll
  except damage variance all turn against it at once, for two turns, off a 2-cooldown skill. Remove
  it and the build-up turns become a run of coin flips the player cannot plan around. The
  debuff-resist clause alone would not carry this claim — Emissary's Signed Writ removes resistance
  outright and is strictly stronger on that one axis.
* **Double the fun! and Luck.** The passive is what makes drawing fire survivable rather than
  suicidal, and self-Luck is what makes the dodge roll trend the Jester's way. Neither produces
  damage; together they are the reason Center Stage's claim holds.

**Projected numbers.** None recorded, and none owed — an Enabler identity is measured on the
collapse test (section 1). Its one measurable factor is Pratfall Sting's conditional **1.30x**,
which is not the declared contribution and is sized against no target. The Jester is expected to be
invisible in `team_corpus_sweep.gd`'s ranking.

`Encounter_Design_Document.md:267,407`'s Reanimating Statues 3 names Burning Bolas as its intended
solution for burning past Defence; the 4% → 6% mean is a buff to that solution. Recorded, not
tuned: encounter values are not being balanced at this stage.

**Judgment calls made while settling, listed so they can be overruled:** Burning was reworked in
place rather than given a Jester-exclusive successor status, which spreads the rolled tick to Lava
Zone; Hexed's second claimant (alongside Diviner's Ill Omen) puts it at the commodity-debuff limit
of two, so no later Role can take it.

### 9.7 Emissary — the verdict the whole team reads

**Status:** Implemented. Batch 2.

**Identity: Channel 2, exported.** Confirms section 5's proposal. The kit is an **adaptation**:
passive, basic skill and Signed Writ keep their shape, and only Levied Sanction's payload changes —
it was the kit's dead slot, a raw attribute reduction with no bucket key and nothing outside the
Emissary's own sheet reading it.

**Passive: Standing Record.** Unchanged mechanism and unchanged rate (2.5/3/3.5/4% per Infraction
by rarity, tally capped at 9). One clarification it now needs: the passive owns the rate, and a
skill may state its own **multiple** of that rate — it may not declare a rate of its own.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Citation | Kept as-is. Knowledge-scaled damage to one enemy, +1× the Standing Record rate per Infraction on the target. | 1 + 2 |
| Signature | Signed Writ | Kept: reduces the durations of all the target's buffs by 1 turn (2 turns at 6+ Infractions) and applies Signed Writ for 1 turn (2 at 6+). Added: **every buff whose duration this reduces to zero adds an Infraction**. Cooldown 3. | Enabler |
| Signature | Levied Sanction | Applies **Sanction** for 2 turns, its value snapshotted from the target's tally at application. Cooldown 4. | 2 (exported) |

**Sanction widens from an attribute debuff to an exported damage bucket.** Two clauses off the one
snapshotted value:

* attacks against the holder deal **+2× the Standing Record rate per Infraction** — 8% at
  Legendary, so **1.72x** at the tally cap;
* all primary attributes except Health are reduced by **0.5× the rate per Infraction** — 2% at
  Legendary, 18% at cap, down from the 36% it carries today.

The damage clause is the Role's declared contribution and the attribute clause is the survivability
rider, not two full-weight jobs on one debuff.

**Composition hooks (exported).**

* **Sanction is a debuff-type bucket on the boss**, so every attacker on the team multiplies by it,
  not only the Emissary. This is the exported Channel 2 bucket the roster was short of (section 8).
* **Sanction stays a distinct debuff type**, so it also feeds any teammate's `Target_Debuff_Count`.
  Route A (debuff density) closes here: the density count now carries a factor of its own.
* **Signed Writ's strip rider** makes the tally something the player drives rather than waits on —
  it reads enemy buff state, which any buff-heavy encounter supplies.

**Projected numbers.** Exported factor **1.72x** at the 9-Infraction cap, **1.48x** at a realistic
mid-fight tally of 6 — inside section 1's ~2x contract and in the same kind as §9.4's Hemorrhage
(1.30-1.48x), the roster's other debuff-type bucket. The Emissary's own self-facing Citation bucket
is unchanged at 1.36x at cap. Nothing here is sized against the team figure.

**Judgment calls made while settling, listed so they can be overruled:** the tally stays a
caster-side counter rather than becoming a stacking debuff on the enemy — a real status would let
any kit read the count directly, at the cost of a permanent slot against the 8-status cap in the
kit whose whole route is debuff density. Weight of Law stays ownerless (section 10.3): a signature
zone would have to displace Levied Sanction, which is where the export now lives.

### 9.8 Cultist — the sacrifice pays out

**Status:** Implemented. Batch 2.

**Identity: Channel 2, self-facing.** Confirms section 5's proposal on both axes. **Exporting is
against the Role's pillar** — the Cultist profits from what allies lose, so no clause in this kit
puts a factor on a teammate's sheet. An **adaptation**: Devour Blessing and Rite of Severance are
untouched, and the passive keeps its existing per-cast multiplier.

**Passive: Chosen Vessel.** The existing mechanism is unchanged — marks a random ally at combat
start, drains 5% of the Vessel's max Health on every non-basic cast, that cast gains a **flat**
power bonus (15/20/25/30% by rarity), and Vessel death grants Attune for 3 turns and re-marks a new
Vessel. **The per-cast bonus stays flat**: an automatic ramp is a timer to strength, not a decision.

Added — **Devotion**: each Vessel that dies grants the Cultist a permanent damage bonus for the rest
of the fight, **10/13/16/20% by rarity**, in its own bucket. Never expires and is never spent. It
has no cap of its own; the party is the cap, so a full team affords two.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Desecrated Blade | Attack-scaled damage to one enemy, **+25% while the Vessel is below half Health**. | 1 + 2 (conditional) |
| Signature | Devour Blessing | Kept as-is. Consumes all buffs on the ally holding the most; Attack-scaled damage to one enemy, +25% per buff consumed. Cooldown 3. | 1 + 2 |
| Signature | Rite of Severance | Kept as-is. Mysticism-scaled damage to one enemy, applies Severance for 2 turns. Cooldown 4. | 1 + Enabler |

**What the kit now reads.** Vessel death stops being a consolation event and becomes the
transaction the Role is built on — the sacrifice has a price the player pays and a payout they
keep. Desecrated Blade's rider is the threshold read on the way there: the drain that used to be a pure
tax now moves the basic across a line the player can aim at. Both surfaces are the Vessel's own
Health, distinct from §9.4's caster-own and enemy-own reads, so route E's two anchors multiply
rather than share a key.

**Projected numbers.** Chosen Vessel's per-cast 1.30x is unchanged. Devotion adds **1.20x** per
dead Vessel in a distinct bucket — 1.56x combined with one Vessel spent, 1.87x with two, at which
point the Cultist is the last champion standing and the team's other terms are gone. Desecrated
Blade's conditional 1.25x is on the basic and is not the declared contribution. Devour Blessing's 1.25x per
buff consumed is unchanged. Inside section 1's contract; the ceiling is self-limiting by
construction.

**Implementation.**

* `chosen_vessel_trait.gd` — Devotion is a permanent per-cast-independent count, incremented on
  the existing Vessel-death branch. It contributes through `CharacterTrait.GetOutgoingDamageBonus`
  (`battle_resolver.gd`'s `_ContributePersistentCasterFactors`), which keys the bucket by the
  trait's own script global name — `&"ChosenVesselTrait"`, not a literal `"Devotion"` string — so
  it lands distinct from the per-cast bonus's shared `TRAIT_RESOURCE_KEY` bucket and the two
  multiply. Reusing this existing hook needed no new plumbing and correctly covers every damage
  source the Cultist has, not only skill casts.
* `Desecrated_Blade.tres` — `bonus_per: {Trait_Condition: 0.25}`; `GetConditionCount` answers
  `Trait_Condition` with 1.0 while the Vessel is alive and below half its own max Health, 0.0
  otherwise. No new enum value.
* `kit_contribution_manifest.gd` — Chosen Vessel's entry gains Devotion as a `gated_bonus` (not a
  second passive row — `burst_reachability.gd` reads only a Role's first passive entry, so a
  second row would be invisible to the scorer) with `reach: "self"`, `bucket_key:
  "ChosenVesselTrait"`, magnitude 0.20, gated on "a Vessel has died"; Desecrated Blade's entry gains
  `bucket_key: "Desecrated Blade"`, magnitude 0.25, with its condition stated. `burst_reachability.gd`
  gained `_ContributeGatedCasterPassiveBonus`, the self-reach counterpart to the existing
  team-reach `_ContributeGatedTeamBonuses`, to read it.
* `Concept_Document.md` 3.1.3's Chosen Vessel entry (Devotion) and 3.2.4.2's Desecrated Blade
  entry (the threshold rider) updated.

**Judgment calls made while settling, listed so they can be overruled:** the party is Devotion's
only cap, which is honest but means a wipe-adjacent team reads as the Cultist's strongest state;
Rite of Severance keeps its plain-damage payload rather than gaining a Vessel-consuming clause, so
Vessel death stays something the drain produces rather than something a skill executes.

### 9.9 Chronophage — time given away, not spent

**Status:** Implemented. Batch 2.

**Identity: Channel 3, exported — with no damage factor of its own.** The Chronophage brings no
damage to the table; its entire contribution is an extra resolution on a teammate's skill. Zap,
Flicker Zone and Temporal Sinkhole all ship unchanged, and the whole kit change is one passive
clause plus one new buff.

**Passive: Time Tithe.** The existing half is unchanged — time stolen from enemies converts into
the Chronophage's own turn-bar progress (25/35/45/55% by rarity). Added: when the Chronophage's
effects move an ally forward on the turn bar and **no other ally is in that turn-bar section**,
that ally gains **Borrowed Time** for 1 turn.

The two halves follow the fiction in opposite directions: time taken from an enemy goes to the
thief, time given to an ally stays with that ally. Nothing grants a bystander a payout for an
enemy being drained.

**Borrowed Time** (new buff): the holder's next damaging skill resolves **one additional time**, at
**30/40/50/60%** strength by the applier's rarity. Does not stack.

**The alone-clause is the design, not a balance gate.** The roster already pays champions to bunch
up on the turn bar — three separate passives grant to whoever sits close behind or within a window
of their owner — and nothing paid them to spread out. Borrowed Time only lands on a champion who
takes the boost with no ally beside it in the section, which is the first effect in the roster
pulling team-building the other way. It is also what earns the buff its magnitude: the player pays
a positional cost for it. Legibility is part of the choice — the bar's five sections are on screen,
so "alone in the section" needs no distance arithmetic to read.

**Composition hook (exported).** Any teammate can hold Borrowed Time; the Chronophage never fires
it. It names no Role and reads only turn-bar position, so a kit authored later benefits without
either side knowing about the other.

**Projected numbers.** Instance-count factor **1.6x** at Legendary, landing on whichever teammate
holds the buff — below §9.2's Herald (8.64x) and §9.3's Sorcerer (6.25x), which is correct: those
are self-facing counts a champion builds toward across a fight, and this is a free extra resolution
handed to someone else once per boost. In the exported kind it sits alongside §9.4's Sanguine Pact
(1.60-1.96x) and Hemorrhage (1.30-1.48x). The Chronophage's own damage is Zap and stays where it
is; the Role fields no factor of its own and is expected to be near-invisible in the sweep's
ranking.

**Implementation.** `SubscribeInstanceModifier` turned out to be the wrong seam — it only amplifies
a listener that already matched, and nothing matches a plain teammate's cast. The alone-clause fires
off a new `Combat_Event.Ally_Turn_Bar_Increased` hook (`Skills.DispatchAllyTurnBarIncreased`, the
positive/ally mirror of the existing tithe's `TurnBarTithe`), checked against a new
`TurnPositions.GetSectionIndex` query (the base class returns -1 for "unknown", which declines the
grant rather than assuming aloneness). The Chronophage counts as an occupant of its own section. The
replay itself is a `Cascade_Trigger.Skill_Resolved` `Subscribe` in `StatusEffectResolver`, gated on
the holder carrying Borrowed Time *and* the cast skill carrying a `DamageEffect` — so a non-damaging
cast leaves the buff untouched for a later damaging one, matching Daunting Strength's own
`ConsumeDamageMultiplierFactors` semantics. The one-turn buff needed `_IsBuffExpired`'s existing
`DamageMultiplier` one-shot survival rule (`duration < 0` rather than `<= 0`) widened to cover
Borrowed Time too, or the start-of-cast duration decrement kills it before its own cast's cascade
gets a chance to consume it. `kit_contribution_manifest.gd`'s Time Tithe entry records Borrowed Time
as an exported `separate_instance` `gated_bonus`, reclassified to `Channel3_Cascade`; the scorer
reads it via `_ExternalGatedContrastRatios` (§11), reaching every non-Chronophage candidate on the
team.

**Judgment calls made while settling, listed so they can be overruled:** the buff does not stack,
so a champion boosted twice before acting still echoes once — the alone-clause already limits
frequency and stacking would compound a factor handed to someone else's finisher; and the echo is a
fraction rather than a full resolution, which keeps the Chronophage from doubling a teammate's
burst outright.

### 9.10 Architect — kept, with the debuff scaled to the spend

**Status:** Implemented. Batch 2 complete.

**Identity: Channel 2, self-facing.** Confirms section 5's proposal. **The kit is kept.** Calibration,
Cornerstone, Raise the Frame and Final Calculation all ship as they are; the only change is Expose
Weakness's magnitude, and the rest of this entry records what the kit already does.

**Why it passes unchanged.** Final Calculation's charge bucket is **1.84x** at 12 charges (0.07 per
charge at Legendary), inside section 4's contract and its 1.7-2.2x bucket-product group. Route D is
independent of Tidal Corsair by construction — charges come from the Architect's own basic and its
own zone's use, sharing nothing. And the Buffer purpose is served with a decision attached rather
than as a leftover slot: Raise the Frame **consumes** up to 3 charges to size its Barrier, so the
player chooses protection now against a larger finisher later, every time.

**The one change: Expose Weakness scales with the charges spent.** -30% Defence at the 5-charge
threshold, +2% per charge beyond it, so a full 12-charge finisher lands **-44%**. A longer
calculation finds a deeper flaw.

**Composition hook.** Expose Weakness is a debuff on the target, so it is read by **every attacker
on the team**, not only the Architect — a small exported rider on an otherwise self-facing kit, and
a distinct debuff type feeding route A's density count.

**Projected numbers.** Against a boss-tier Defence of 120 (mitigation ratio taken against
`DEFENCE_SCALE_CONSTANT = 100.0`), Expose Weakness is worth **1.16x** at -30% and **1.25x** at -44%,
for the whole team. Phase 0 is what created this factor: under the old formula Defence lost its
weight at burst scale and the debuff was build-up pressure only. The Architect's own declared
contribution is unchanged at 1.84x.

**Judgment calls made while settling, listed so they can be overruled:** the 9-12 tier's free zone
re-erect is left as the only reward for a maximum spend beyond raw magnitude, rather than gaining an
exported clause of its own — route D stays predominantly self-facing.

### 9.11 Lancer — the charge and the ride back

**Status:** Implemented. Batch 3.

**Identity: Channel 2, self-facing**, moved off section 5's Phase 1 proposal of Channel 1: the
charge's magnitude is a bucket on its own skill, not an attribute change. The passive is
**replaced** — Reckless Momentum and Phalanx Guard both retire — and all three skills are kept.

**Passive: Couched Lance.** Rending Charge deals **+9/12/15/18% by rarity per turn-bar section the
charge touches**, counting the Lancer's own section and the target's: the same section is 1, the
opposite ends of the bar is 5, so the ceiling is +90% at Legendary. **After the charge resolves the
Lancer is thrown back 10% of the turn bar per section touched** — half the ground it covered.

**The recoil is what makes the distance a decision.** The Lancer's own charge resets its phase
against the target, so the gap it reads keeps moving instead of settling into a constant the player
cannot influence. The cost is proportional, so a maximum impact cannot be farmed for free, and the
span is bounded by the bar, so a slow build buys no magnitude at all — a *fast* Lancer takes several
turns per enemy action and chooses which one to spend the charge on. The Role reads turn-bar
position and never writes to it, which is what keeps it clear of the Chronophage's identity.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Lance Thrust | Kept as-is. Attack-scaled damage to one enemy — the cheap action taken while riding back into position. | 1 |
| Signature | Rending Charge | Kept, and now the passive's only reader: Attack-scaled damage carrying the per-section bonus in its own bucket, plus Bleed for 2 turns. Cooldown 3. | 1 + 2 |
| Signature | Disarm | Kept as-is. Attack-scaled damage, applies Enfeeble for 2 turns. Cooldown 3. | 1 + Enabler |

**Composition hooks.** The passive reads the turn-bar gap, so anything that pushes an enemy back
lengthens the Lancer's run-up — Sea stacks, stolen time, Dead Weight, Temporal Leak — with no skill
in this kit naming any of them. Bleed is a distinct debuff type feeding any `Target_Debuff_Count`
reader, and it snapshots the caster's damage factors at application, so a full-bar charge writes its
own size into every subsequent tick. Enfeeble is the kit's Enabler clause: it blunts what the team
absorbs during the window it bursts in.

**What retires with the passive.** The Lancer keeps no defensive half. The roster carries three
dedicated defensive Roles and four more that touch survival, and nobody reading the turn bar, so the
Role's Damage purpose (`Concept_Document.md` 3.1.3) is finally what its passive does. Phalanx Guard
returns to unclaimed, and the accumulate-then-spend idiom drops from five claimants to four.

**Projected numbers.** **1.18x** at one section, **1.54x** at three, **1.90x** at five — one factor,
inside section 1's contract, in the same bucket-product kind as Architect (1.84x) and Tidal Corsair
(2.80x). The kit needs nothing further to pass, which is why Disarm keeps its shipped payload.

**Implementation.**

* `lancer_trait.gd` — Momentum, the Defence penalty, Phalanx Guard and the offensive/defensive skill
  name sets are gone. The trait reads the inclusive section span between the Lancer and Rending
  Charge's target at cast (`OnSkillCast`, cached), and throws the Lancer back after the damage
  resolves (`OnSkillEffectsResolved`, reading the cached span rather than re-querying the bar).
* `Rending_Charge.tres` carries `bonus_per` keyed to the new `Turn_Bar_Section_Span` count source at
  a flat 1.0 — the rarity ladder (9/12/15/18% per section) lives on the trait's own
  `GetConditionCount`, not the `.tres`, since `bonus_per` is a single float and the Role is fielded
  at two different rarities (`Centaur_Lancer.tres` Epic, `Knight.tres` Uncommon).
* `Types.Trait_Count_Source` gained `Turn_Bar_Section_Span`; `damage_effect.gd`'s `_Count` routes it
  through `_TraitCount` alongside the other trait-delegated sources. The self-pushback runs through
  `BattleResolver.BumpTurnBar(owner_ID, -fraction, owner_ID)` — a same-ID bump neither recurses
  through `_EmitTurnBarBump`'s tithe tail nor fires `Skills.DispatchAllyTurnBarIncreased` (both bail
  when source equals target), and Anchor/Steadfast on the Lancer gate its own recoil the same as any
  other bump.
* `kit_contribution_manifest.gd` — Reckless Momentum's entry is Couched Lance; Rending Charge's own
  entry carries `bucket_key: ""` (magnitude folded entirely into its `gated_bonus`, to avoid double-
  counting the same bucket) with `gated_bonus.bucket_key: "Rending Charge"`, `magnitude: 0.45`
  (`gate: &"charge_distance"`, an assumed three-section span at Epic rarity: 3 * 0.15).
* `Concept_Document.md` 3.1.3's Lancer entry, 3.2.3.2's Phalanx Guard entry, and 3.2.4.2's Rending
  Charge entry updated to match.

Post-Lancer sweep: median 1.95x, 90th percentile 4.68x, ceiling 16.24x — unchanged, as expected
since the gate's contribution lands in `combined_contrast_ratio`, not the shared bucket product. The
top decile (114 teams) **gains a ninth distinct pairing**: Lancer/Rending Charge (2 teams,
10.45x-12.15x, both `charge_distance`-gated) joins Herald of the Loom/Cut the Cloth,
Sorcerer/Cataclysm, Tidal Corsair/Corsairs Reckoning, Architect/Final Calculation,
Emissary/Citation, Diviner/Ill Omen, Cultist/Devour Blessing, Bar Brawler/Headbutt.

**Judgment calls made while settling, listed so they can be overruled:** Disarm keeps its shipped
payload rather than gaining a deliberate distance lever, since the passive already carries the loop
and the kit clears its contract without a second one; and the recoil is a fixed half of the span
rather than an amount the player chooses at cast time.

### 9.12 Thief — between the plates

**Status:** Implemented.

**Identity: Channel 1, self-facing.** Confirms section 5's proposal — the whole contribution is a
mitigation term, which claims no bucket key. The passive is **replaced**, the third skill is
**rebuilt**, and Pierce Weakness keeps its shape while its magnitude moves onto the passive's rate.

**Passive: Between the Plates.** The Thief's attacks ignore **12/16/20/25% by rarity of a
debuff-free reference Defence** — base + equipment + trait deltas + battle-long bonuses + Defence
buffs, excluding Defence debuffs — subtracted in points from the target's actual effective Defence
and floored at zero. Pilfer retires; the bypass is what the Role is rather than one skill it owns,
and it is the half that scales with rarity naturally. The passive owns the rate and a skill may
state a **multiple** of it, never a rate of its own (the convention §9.7 established).

**Excluding debuffs from the reference is the point.** A multiplicative ignore lands on the same
term as a Defence debuff, so each one makes the other worth less — the Thief's own factor *fell*
from 1.39x to 1.31x when a teammate shredded first. Reading every durable contributor except a
Defence debuff inverts that: the teammate's shred survives intact against the target's actual
effective Defence, and the Thief's own points come off the unshredded reference — the two compound
(route G) instead of one eating the other's contribution.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Stab | Kept as-is. Attack-scaled damage to one enemy, carrying the passive's bypass like any attack. | 1 |
| Signature | Pierce Weakness | Kept, with its magnitude restated as a multiple: ignores **2.5× the passive's rate** instead of the usual 1×. Cooldown 2. | 1 |
| Signature | Cut Purse | Rebuilt from Weigh the Mark. Attack-scaled damage to one enemy; **steals one buff, which lasts an extra turn on the Thief**; grants the Thief Opportunist for 2 turns. Cooldown 3. | 1 + 2 |

**Cut Purse replaces a bare slot.** Weigh the Mark was one unconditional self-buff. The rebuilt skill
asks three questions at once — is there a buff worth taking, is the boss carrying enough debuff
types for Opportunist to be worth the turn, does the damage matter now — and the theft rides on a
skill that pays regardless, so it no longer resolves to nothing against a boss carrying no buffs.
Moving theft off the passive costs frequency (a per-cast roll becomes one guaranteed steal every
three turns) and buys reliability and the extra turn.

**No skill in the kit carries a rarity-scaled number.** Pierce Weakness states a multiple, Cut
Purse's extra turn is flat, and Opportunist's magnitude lives in the status resource.

**Composition hooks.** The bypass reads the target's *current* Defence at impact, so every Defence
reduction in the roster is worth more when the Thief attacks — the Architect's Expose Weakness above
all, which is what opens route G. Opportunist puts the Thief on the thin spender side of route A: it
reads distinct debuff types from any source without producing any. The steal removes enemy buff
state, which is world state any later kit may read.

**Projected numbers.** Against a boss-tier reference Defence of 120 (no equipment or buffs on a
boss, so the debuff-free reference equals its base): the passive is **1.10x** on every attack,
Pierce Weakness **1.30x** alone, **1.40x** against a boss under Expose Weakness at −30%, and
**1.47x** at −44%. Opportunist is **1.40x** at four distinct debuff types. Two factors, **1.82x** on
the Pierce turn. Against a reference Defence of 40 the same skill is worth 1.14x — the mechanic
pays only against armour, which is the fantasy stating its own limit.

**Scorer plumbing implemented alongside the kit** (closing section 11's defence-ignore gap):
`burst_reachability.gd` now computes each candidate's effective boss Defence the same two-step way
`battle_resolver.gd` does — a team-reach shred first, then a caster-side base-referenced ignore off
the unshredded reference — via new manifest fields `defence_ignore` (a passive's rate, a skill's
multiple) and `defence_reduction` (a skill's exported shred fraction), read by
`_DefenceIgnorePoints`/`_ContributeDefenceReduction`/`_EffectiveDefenceForCandidate`. The
Architect's Final Calculation entry carries the matching `defence_reduction`.

**Judgment calls made while settling, listed so they can be overruled:** the passive's bypass applies
to the basic skill too, which is a mitigation gain on a no-cooldown cast rather than the
unconditional bucket key §1.2 forbids; and Cut Purse steals exactly one buff at every rarity, since
the rate that scales already lives in the passive; and the debuff-free reference was widened past
the settled "base Defence" to include equipment, trait deltas, battle-long bonuses, and Defence
buffs, since a plain base-Defence reference would have gone stale the moment gear existed.

### 9.13 Tidal Corsair — the ship the crew boards

**Status:** Implemented.

**Identity: Channel 2, self-facing**, confirming section 5's row: the declared contribution is
Broadside's bucket on the Corsair's own sheet. The kit carries a large exported second clause in the
ship, and if play or the sweep shows that is where the Role's weight actually lands, the direction
row moves to exported — noted rather than pre-empted.

**The defect closed.** Steel and Sea competed for the same three slots while both paid in the same
currency — Reckoning damage — so the comparison collapsed to a scalar the player solves once, and it
solved *against* Sea: banking three Sea and then spending three Steel yields 11.21 damage units over
eight turns against 11.72 for two pure Steel cycles, and break-even needs a per-stack rate that
would push the Role outside section 4's band. Saltwater Shot was also Boarding Strike with a
different icon — same scaling, same cooldown, no rider.

**Sea now pays in a currency Steel cannot.** Steel buys the Corsair's own spike, resolved now; Sea
buys the crew permanent growth, worth more the earlier it is spent and nothing once the fight ends.
A permanent bonus decays in value across a fight while a spike does not, so the question is *when*,
not *how much* — and fight length is uncertain, so it does not solve.

**Passive: Wrangle the Sea.** Unchanged in shape and in its per-Steel damage rate (45/50/55/60% by
rarity). The per-Sea turn-bar push retires.

| Hand | Mode | Effect (Legendary) | Channel |
|---|---|---|---|
| Steel only | **Broadside** | Per-Steel rate 0.60; 3 Steel = **2.80x**. No ship. | 1 + 2 |
| Sea only | **Bring Her Alongside** | No damage bonus. The Gilded Deck is raised or resupplied, **2 charges per Sea** — 6 at three. | Enabler |
| Mixed | **Boarding Party** | Steel damages at the base rate, **1 charge per Sea** (2 maximum), and every other living ally gains Slipstream and Empower for 2 turns. | 1 + Enabler |

Three time horizons rather than three sizes: the Corsair's spike now, the team's window now, the
team's growth for the rest of the fight.

**The Gilded Deck** is the Corsair's signature zone (Zone Ally, momentum family) and the only zone in
the roster placed without the player choosing its section, since Corsair's Reckoning spends its
targeting on an enemy. It resolves to the free section holding the most allies, ties breaking toward
the end of the bar; failing that, a random free section; and if all five are occupied the Reckoning
deals its damage and no ship is raised. One deck stands at a time — further Sea resupplies it rather
than raising a second.

**Sea Legs** is a new permanent buff. An ally whose turn starts on the deck gains one stack:
**+5/6/7/8% by rarity to that character's highest base primary attribute, Health excluded**, scaled
by the Corsair's Knowledge through the existing ally-zone rule
(`GameBalance.ZONE_KNOWLEDGE_SCALING`). Never expires, never spent, capped at 4 stacks per
character. Health is excluded because its values run 270-330 against roughly 100-200 for every other
attribute, so it would otherwise always be the highest.

**Per-holder targeting is what makes the ship universal.** Attack is a primary attribute on 3 of the
roster's 20 Roles, against Knowledge's 9 and Mysticism's 7. A fixed-attribute grant would be worth
nothing to most of any team, making the Corsair a Role that only pays off beside the two other
Attack Roles — the opposite of a ship the whole crew boards.

**Composition hooks.** The deck reads nothing and names no Role: any ally advancing into it boards.
Sea Legs lands entirely on teammates' sheets and scales with the Corsair's own Knowledge, so a
Knowledge-built Corsair doubles what the crew gets while giving up its own Attack scaling. The kit
closes route D as the self-facing half against the Architect's exported one.

**Projected numbers.** Broadside 2.80x, unchanged from what ships and inside section 4's band. The
ship is an aggregate contribution rather than a modifier-product one, landing in the same term as
Empower and Attune: at Corsair Knowledge 120 (multiplier 1.60) a full deck gives each ally 2 stacks
at +12.8% on their highest attribute, and a second full deck reaches the 4-stack cap at +51%. Two
pure-Sea Reckonings is the price, which is why the investment is only correct early.

**Implementation.** `tidal_corsair_trait.gd`'s Reckoning branch counts the consumed hand and
dispatches; `_turn_bar_bump` is gone. Sea Legs holds as **one buff instance carrying a stack count**
(`trait_riders[&"stacks"]`), not four separate instances — four would permanently occupy half of
every ally's 8-slot status cap. Restacking reuses the buff's own `status_ID` rather than emitting a
fresh one, and `CharacterRepresentation` gained `UpdateStatusEffect` (refreshing an existing icon's
tooltip and duration) alongside `AddStatusEffect`, so a restack updates the holder's one icon in
place instead of claiming a second slot for what is still one instance; the tooltip reads the
current total through a new `{percent}` token, `_EmitBuffApplied` now stamping `CombatResult.fraction`
for buffs the same way debuffs already did. The per-holder attribute rides a new generic
`trait_riders: Dictionary[StringName, Variant]` on `StatusEffects.Effect`, which also absorbed the
two prior bespoke rider fields (Comorbidity's repeat flag, Field of Study's weakness rider) — the
plan's own long-carried deferred fix, closed here since Sea Legs was its third claimant. The Gilded
Deck's section resolution (`ZoneResolver.SectionWithMostAllies`) and its own `Section.Most_Allies`
zone-placement kind are new; the deck's payload is `SeaLegsZoneEffect`, constructed by the trait with
the rarity's own per-stack rate. Boarding Party raises a fresh deck when none stands, not only
resupplying one that does. Saltwater Shot gained no new payload of its own — the settled kit's
"gains a new payload" line for it does not match the hand table, where every mode-specific effect is
trait-side; only its description changed, to say what a Sea stack now buys. The deck's Sea Legs
grant is not declared in `kit_contribution_manifest.gd` as a `granted_attribute_buff`: the shape
(stacking, zone-delivered, per-holder-attribute) doesn't fit the field's fixed-attribute,
one-shot contract, and forcing an approximation onto one attribute both misrepresents the mechanic
and perturbed an unrelated base-term/modifier-term invariant in the scorer's own test suite — left
as an explicit gap in section 11 instead. Post-implementation sweep: median 1.95x, 90th percentile
4.68x, ceiling 16.24x, 114 teams across 10 distinct top-decile pairings — all unchanged, as predicted
for a passive whose rate didn't move and a ship the scorer cannot see.

**Known bug, unresolved.** In live play, the Sea Legs tooltip's displayed percent does not track
the stack count correctly — a report of 6% on the first stack followed by 5% on the second, on the
same standing deck with no re-raise. `StatusEffectResolver.ApplySeaLegs`'s own math and the
`CombatResult` it emits are confirmed correct by both the unit suite and a direct headless
simulation of the same scenario (linearly increasing: 6%, 12%, 18%), so the defect is somewhere
between that emitted result and the live tooltip's rendered text — a surface `Tests/unit/` cannot
reach (GUT does not exercise `battle.gd`/`CharacterRepresentation`/`ToolTip`) and manual repro
attempts have not isolated. A latent, likely-unrelated ID mismatch in
`CharacterRepresentation.AddStatusEffect` (passing a recycled texture slot where an effect ID was
expected) was found and fixed alongside this, but does not explain the percent discrepancy.

**Judgment calls made while settling, listed so they can be overruled:** the mixed mode keeps the
Slipstream and Empower grants rather than only a reduced charge count, which is a third clause on
one mode but is what makes it a distinct choice rather than a blend; the direction row stays
self-facing on the strength of Broadside being the declared contribution; and the three
implementation-time calls above (one-instance Sea Legs, the generic rider dictionary, Boarding Party
raising rather than only resupplying).

### 9.14 Scholar — every advantage sharpened

**Status:** Implemented. Batch 3.

**Identity: Channel 2, exported**, confirming section 5's row on both axes. An **adaptation**: the
passive is **replaced** and the basic gains a conditional rider. Expose Fallacy and Refutation are
kept exactly as they ship.

**Passive: Field of Study** (replaced). Attribute buffs and debuffs applied by the Scholar's team
are **+7/8/9/11 percentage points by rarity** stronger. Scope: the six primary attributes plus Speed
and Health. Critical Chance and Critical Damage are excluded — amplifying them would put the Scholar
on the crit path, which is the Appraiser's whole declared contribution (§9.5). Enemy self-buffs are
not amplified.

**What the replacement reaches.** Nothing in the roster reads the Channel 1 attribute layer —
Confound, Suppress, Unravel and Blind are Channel-1-only in practice because nothing makes them
worth casting (section 2). This passive is what reads them. It lands on the scaled attribute
aggregate rather than a `CombinedDamageModifier` bucket, so it multiplies with every Channel 2 and 3
factor a teammate brings instead of sharing a bucket with any of them; and being second-order — a
modifier on a modifier — it reaches the entire roster at a magnitude that cannot run away.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Sharp Rebuttal | Kept, plus a rider: if any zone stands on the turn bar, also applies **Suppress** for 1 turn. | 1 |
| Signature | Expose Fallacy | Kept as-is. Confound to one enemy and Opportunist to all allies, 2 turns each. Cooldown 3. | 1 + 2 |
| Signature | Refutation | Kept as-is. Removes one zone from the turn bar. Cooldown 3. | 1 + Enabler |

**The rider's gate is the kit's own tension.** Refutation clears zones; the rider needs one
standing. The Scholar chooses between denying the enemy's setup and holding its own condition open —
the first real decision the kit has ever carried, and it gives Refutation's ally-placed branch a cost
it needed to pass the collapse test on its own merits.

**Why Suppress.** The passive amplifies whatever the basic applies at near-permanent uptime, so the
rider is chosen for what is safe to hold inflated, not for what gains most from inflation. Suppress
is purely defensive: at 41% it cuts an enemy's magic output and inflates no part of the team's burst,
where Slow's tempo denial or Expose Weakness's Defence shred would. Duration carries the whole
restraint — every attribute debuff in the catalog is 30% except Slow at 15%, so there is no minor one
to reach for — and 1 turn makes it upkeep the Scholar spends its basic on rather than banked value.

**Composition hooks.** Three, none naming another Role:

* The passive amplifies any attribute modification the team applies — Empower, Fortify, Attune,
  Exhert, Enfeeble, Expose Weakness, and every attribute status a later batch authors.
* Opportunist stays the exported bucket anchor, and the kit now feeds the density it reads: Suppress
  and Confound are two distinct types the Scholar produces itself.
* Suppress is inert against a physical boss and bites once that boss's damage is re-pointed through
  Mysticism — Warped (§9.3) makes the Scholar's basic matter in fights where it otherwise would not.

**Projected numbers.** The passive is an **aggregate-term factor**, a kind no other Role fields
(section 4). One amplified 30% modification is **1.085x** at Legendary; a team running three is
**≈1.27x**. Opportunist is unchanged at **1.40x** on four distinct debuff types, and easier to reach
now that the Scholar produces two of them. The Role's exported contribution is **≈1.78x** from two
terms that multiply rather than share a bucket — inside section 4's band, with no damage factor on
the Scholar's own sheet.

**Implementation.** `field_of_study_trait.gd` was rewritten in place (kept the filename and the
`Field_of_Study_Trait.tres` resource) rather than replaced, retiring `StartOfBattle`/`OnDebuffApplied`/
`_IdentifyWeakness`/`_weakness_by_enemy` along with `Skills.ApplyWeaknessRider` and its call site — the
old passive's defective "identifies each enemy's *weakest* attribute" description (the code and
`Concept_Document.md` both said highest) is moot. `PRIMARY_ATTRIBUTES` stayed on the class: Tidal
Corsair's `SeaLegsZoneEffect._HighestBasePrimaryAttribute` reads it too (section 9.13), an external
dependency the original settle missed.

A new `CharacterTrait.GetAppliedAttributeAmplification()` virtual (default 0.0) and
`Skills.AppliedAttributeAmplification` (highest value among the source's own living side, not summed —
answering this batch's own "two amplifying teammates" judgment call) feed a stamp
(`&"attribute_amplification"` in `trait_riders`) written once in `StatusEffectResolver._InsertOrRefresh`
for any attribute-modifier-kind status, covering both the new-instance and refresh branches so a
refreshed status keeps the amplification. `Skills.ApplyAttributeModifiers` adds the stamped value onto
`resolved_value` for every non-crit attribute; `ApplyActiveAttributeModifiers` now threads
`debuff.trait_riders` through on the debuff side too (previously buffs only). `Sharp_Rebuttal.tres`
gained the Suppress rider gated on `Skill_Condition.Trait_Condition`, read through a new
`FieldOfStudyTrait.GetConditionCount` override (`GetZoneResolver().GetZones().size()`) — no new
`Skill_Condition` member needed. `kit_contribution_manifest.gd`'s Field of Study entry carries the new
`attribute_amplification` field; Sharp Rebuttal's precondition notes the rider; Expose Fallacy's stale
"-30% Knowledge" (Confound is -50%) and Refutation's stale `_damage_multiplier` note are both gone.
`burst_reachability.gd`'s `_ContributeGrantedAttributeBuffs`/`_AccumulateAttributeBuff` close section
11's gap — see that section for the sweep's own result. Rarity ladder invented for Uncommon/Rare/Epic
(0.07/0.08/0.09), mirroring the retired passive's ladder shape; only Legendary (0.11) was fixed by this
section's own projected numbers.

The team's own status tooltips needed a follow-up so the amplification is legible, not just
mechanically real: every `Data/Status_Effects/*.tres` description that hardcoded a flat percentage for
an amplifiable status (Attune, Blind, Clarity, Confound, Empower, Enfeeble, Exhert, Fortify, Frenzy,
Haste, Insight, Rush, Slow, Suppress, True Aim, Unravel, Vigor) now reads a `{percent}` token instead,
matching Expose Weakness's and Sea Legs' own existing convention. `Skills.DisplayedAttributeModifierFraction`
(mirrors `ApplyAttributeModifiers`'s own branching, crit attributes excluded) feeds
`StatusEffectResolver._EmitBuffApplied`/`_EmitDebuffApplied`'s `CombatResult.fraction`, so a Fortify
applied alongside the Scholar reads its own 41%, not the .tres's flat 30%. Vigor needed its own gate:
`MaxHealthAttributePercent` is computed in `BattleResolver._MaxHealth`, entirely outside
`ApplyAttributeModifiers`/`GetEffectiveAttributes` (`IsAttributeModifierKind` doesn't cover it), so a new
`Skills.IsAmplifiableKind` widens the `StatusEffectResolver._InsertOrRefresh` stamping gate to cover it
too and `_MaxHealth` reads the `&"attribute_amplification"` rider directly off the buff — Health is
inside Field of Study's own declared scope (the six primary attributes plus Speed and Health) and was
missed in the first implementation pass.

**Judgment calls made while settling, listed so they can be overruled:** the rider applies Suppress
at the status's own magnitude, with duration carrying all of the restraint; the passive's scope is
modifications the Scholar's *team* applies, so an enemy's own Frenzy is untouched; and Slow was
considered and rejected for the basic — tempo denial is unsafe at permanent uptime regardless of
magnitude, and the passive makes it more dangerous rather than more interesting.

### 9.15 Alchemist — the reagent economy kept running

**Status:** Implemented.

**Identity: Channel 2, exported**, confirming section 5's row on both axes. An **adaptation**: the
passive and the basic are kept exactly as they ship; the zone gains a payload and the third slot
gains two clauses. The passive's 1.29x sits below section 4's band and stays there — the factor is
unconditional, reaches all three champions, and is one of two effects the passive pays.

**Passive: Fresh Batch** (kept). Brews one battle-scoped reagent from the Alchemist pool; any ally
consuming any reagent grants the team Volatile Mixture, +20/23/26/29% damage by rarity for 2 turns.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Acrid Splash | Kept as-is. Knowledge-scaled single-target damage, no rider. | 1 |
| Signature | Catalyst Cloud | Kept, plus a payload on Catalyst: when the holder consumes a **non-brew** reagent, one reagent from the Alchemist brew pool is refunded. Zone, 4 charges, cooldown 3. | Enabler |
| Signature | Dissolving Agent | Modest Knowledge-scaled damage, plus **Unravel** and **Expose Weakness** to one enemy. Cooldown 3. | 1 |

**Catalyst Cloud's claim is the window, not the magnitude.** The refund multiplies the *number* of
reagent consumptions, and every consumption re-arms Volatile Mixture and pays its own reagent
payload. Volatile Mixture refreshes rather than stacks, so the zone's collapse-test claim is that
the buff is live when the burst lands and the team has not run dry — never that the factor is
deeper. The chain terminates on its own: refunded brews are non-refunding, and the pool is the
lesser one, so the loop trades power for volume.

**Dissolving Agent's damage is a floor, not a payload.** It stops the slot being a pure application
on the turn it is spent; the value is the two debuffs. Expose Weakness lands outside the combined
modifier, so it multiplies against the passive's bucket rather than sharing it, and discharges
section 10.1's standing reservation of the effect's second Role source.

**Composition hooks.** Volatile Mixture stays the exported bucket every teammate consumes; Expose
Weakness puts a third feeder on route G, readable by any attacker; the refund raises the reagent
consumption count any reagent-reading kit sees.

**Projected numbers.** Bucket product unchanged at **1.29x** at Legendary. Expose Weakness is a
mitigation-term factor, the kind section 4 holds separate from the bucket product, and it is
comparable to §9.10's Defence debuff rather than to the passive.

**Implementation.** The refund refills the just-spent reagent slot in place
(`ReagentLoadout.RefillWithBrew`) rather than appending one — the battle UI exports a fixed four
reagent buttons, so an appended slot would render nowhere. It fires when the consumer held Catalyst
before the cast and the spent slot was not itself brewed
(`BattleResolver.TryRefundBrew`, `battle.gd:_ResolveReagentConsumption`); gating on presence rather
than on Catalyst actually being consumed also covers binary reagents, which skip the potency-add
path that would otherwise consume it. Brewed slots refunding themselves would never terminate, so
`ReagentLoadout.IsBrewed` gates every refund. `Dissolving_Agent.tres` gained a `DamageEffect`
(Knowledge 0.9) and the Expose Weakness `ApplyDebuffEffect` alongside the existing Unravel one.

**Watch item, parked outside this plan:** the refund loop makes Lesser Barrier Brew (a Barrier
absorbing 40% of max Health) repeatable where it was once per battle. Brew-pool magnitudes are the
lever, and tuning them is out of scope here.

Post-Alchemist sweep: median 1.95x, 90th percentile 4.68x, ceiling 16.24x, 114 top-decile teams
across 10 distinct pairings — all unchanged, as this section's own projection predicted: the bucket
product doesn't move, and the scorer has no representation for the refund's raised consumption
count.

### 9.16 Diviner — the read pays back

**Status:** Implemented. Batch 4.

**Identity: Enabler, exported**, redeclaring section 5's Channel 1 row. Enfeeble cuts the enemy's
Attack, Premonition blocks a hit, Hexed denies rolls — all mitigation and denial, and §1.2's
Enabler identity is what the kit already is. An **adaptation**: one skill gains a clause, everything
else is kept.

**Passive: Foresight** (kept). At turn start, applies Enfeeble for 1 turn with no resist roll to
every enemy within 10/15/20/25% turn-bar-behind reach by rarity.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Fateful Glimpse | Kept as-is. Mysticism-scaled damage plus a heal to the most injured ally. | 1 |
| Signature | Premonition | Kept, plus a clause: the attack the holder avoids is answered by an **immediate counter-attack with the holder's basic skill**. One ally, 1 turn, cooldown 3. | Enabler |
| Signature | Ill Omen | Kept as-is. Mysticism-scaled damage plus Hexed, 2 turns. Cooldown 3. | 1 + Enabler |

**The counter pays a correct read.** Premonition's decision is predicting who the enemy attacks —
a readable, repeatable call, not a guess, since targeting follows gear and stats rather than
changing turn to turn. A team-wide version was considered and rejected: it removes the target choice
and turns the skill into an on-cooldown cast. The counter leaves the prediction as the whole
decision and returns tempo for calling it right; calling it wrong still costs the cast.

Three details settled with it: the counter resolves at **full basic strength** (rarity ladders live
on the passive, so a fraction here would sit in the wrong place); the auto-miss and the counter are
**one event** — the attack whiffs, the buff is consumed, the counter fires, including when the
holder is one target of an enemy AoE; and the counter **costs the holder nothing** — no turn-bar
movement, no turn spent.

**Composition hooks.** Enfeeble and Hexed are world state any kit can read. The counter is the third
and the only exported one: an off-turn resolution on a teammate's sheet.

**The counter is a minor exported instance count.** By §3's total-resolutions test an off-turn basic
is one more resolution than would otherwise happen, the same *kind* of contribution as §9.9's
Borrowed Time. Recorded here so a later coverage review reads it as what it is rather than as an
unclaimed Channel 3 anchor. The two are distinguishable in shape — Borrowed Time's holder chooses
when to spend it, the counter is triggered by the enemy — and this one is a single basic behind a
correct prediction and a 3-turn cooldown. It does not unseat the Enabler declaration: an identity is
a claim on one term, not a ceiling on the rest of the kit.

**Projected numbers.** None. The kit fields no damage factor and is measured on the collapse test,
absent from the sweep's ranking by design (§4).

**Implementation.** `ConsumePremonitionIfPresent` (`status_effect_resolver.gd`) calls a new
`_ResolvePremonitionCounter`, which is a **full first resolution of the holder's basic skill**
against the attacker — the holder's `Skill_Cast` trait hook, a real (advancing)
`_SkillUseCount`, and every effect the basic carries, not the stripped repeat-only shape Borrowed
Time and the Sorcerer's Echo use. Full fidelity is load-bearing here rather than optional: Premonition
is generic across holders, so a Bar Brawler's counter has to carry Heap On's ramp and a
trait-bonus-bearing basic has to carry its multiplier, or the counter silently underpays whichever
Role holds it. Everything past the effect loop in `BattleResolver.ResolveSkill` (cooldown, turn-bar
bump, cascade post, zone trigger) is skipped, which is what makes the counter free. New shared helper
`Skills.BasicSkill` (the character's cooldown-0 skill) backs both this and `burst_reachability.gd`'s
existing private copy. A mutual-Premonition exchange is bounded by the number of buffs in play, not
guarded by a depth counter — each step consumes one buff, so a 1-buff exchange ends in a miss and a
landed counter, a 2-buff exchange ends in two misses and one landed hit once both buffs are spent
(pinned by `test_mutual_premonition_terminates_once_both_buffs_are_spent`). Post-Diviner sweep:
median 1.95x, 90th percentile 4.68x, ceiling 16.24x, 114 top-decile teams — unchanged, as predicted:
the manifest declares no bucket for the counter, and the scorer has no representation for an
off-turn resolution.

### 9.17 Symbiote — kept

**Status:** Settled as kept, unchanged. Batch 4.

**Identity: Channel 1, self-facing.** Exhert is a real attribute-layer anchor — +20% on every
primary attribute except Health — and it points inward: Symbiotic Overdrive targets the Symbiote,
not an ally. Section 5's row is corrected on direction only. Post-graft the kit may read either way,
which is what the graft pool is for.

Passive Graft, Spore Lash, Symbiotic Overdrive and Grafted Flesh all keep exactly as they ship. The
Role's variety is meant to come from the graft pool, not from its three fixed slots, and §1's
contract is met without touching them.

**Composition hook: the Symbiote wounds itself, reliably and repeatedly.** Exhert's per-turn tick
and Grafted Flesh's 10% self-cost are the world state §9.4's `Wounded_Allies` counter reads and
route E is built on. The hook already exists and needed only naming.

**Two decisions made and closed, so they are not rediscovered as gaps:**

* **The Buffer purpose is served by the graft pool, not by the fixed kit.** Several grafts are
  ally-facing; the three slots are not required to duplicate them.
* **The 5- and 4-turn cooldowns stay.** Both skills cost Health rather than tempo, which is the
  Role's fiction. Their durations nearly cover their cooldowns, so re-casting is upkeep rather than
  a spend-or-hold gamble; widening that gap is a tuning change, out of this plan's scope.

**Projected numbers.** Exhert's +20% is an aggregate-term contribution on the Symbiote's own sheet,
comparable only to §9.14's kind. No bucket key, by design.

### 9.18 Bar Brawler — kept, Heap On sanctioned

**Status:** Settled as kept, unchanged. Batch 4.

**Identity: Channel 2, self-facing**, confirming section 5's row on both axes. Heap On's ramp is the
bucket anchor; On the House is Enabler content beside it, not the Role's identity.

Passive On the House!, Heap On, Liquid Courage and Headbutt all keep exactly as they ship.

**Heap On's ramp is a sanctioned exception, on the rule of cool.** It is an unconditional Channel 2
key on a no-cooldown cast (§1.2's one forbidden shape) and it is uncapped (§4). Both stand: the
skill is more fun than the rules it breaks, and fun wins. Consequence, recorded so a later review
reads it as the exception working rather than a regression: a long fight can carry Heap On above the
roster's ceiling in the sweep, and it is expected to.

**Composition hook.** On the House reads any buff the Bar Brawler gains from any source, so every
Buffer kit in the roster feeds it without either side naming the other. Liquid Courage is the kit's
own trigger for it.

**Projected numbers.** Heap On's bucket is +20% per use with no ceiling, so it has no fixed figure
to place in section 4's distribution — the only entry in the roster of which that is true.

### 9.19 Warlord — everything that strikes the wall pays for it

**Status:** Implemented. Batch 4.

**Identity: Enabler, exported**, redeclaring section 5's Channel 1 row. Fortify raises Defence, which
is no damage term; redirection, Fortify and Aegis are all mitigation. An **adaptation**: one slot
gains a clause.

**Passive: Shield Wall** (kept). Allies within 15% turn-bar proximity have 15/20/25/30% of incoming
attack damage redirected to the Warlord by rarity, re-mitigated against his own Defence.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Shield Slam | Kept as-is. Defence-scaled single-target damage. | 1 |
| Signature | Hold the Line | Kept as-is. All allies gain Fortify, 2 turns. Cooldown 3. | Enabler |
| Signature | Brace for Impact | Kept, plus a clause: while it holds, any enemy whose attack lands on the Warlord — **including damage redirected to him by Shield Wall** — gains **Enfeeble for 2 turns**, rolled against the Warlord's own Accuracy like any other applied debuff. Rush and Aegis 1 turn each, Rush's expiry self-Stun kept as the price. Cooldown 4. | Enabler |

**The reactive form is the design.** An all-enemies Enfeeble would be a generic debuff button; keying
it to attackers makes it proportional to the pressure the team is actually under, and Shield Wall
already guarantees the trigger by making the Warlord the thing being hit. Counting redirected damage
closes the kit into one loop: proximity pulls the hit, the hit taxes the attacker, Fortify and Aegis
hold him through it. It also completes the mitigation triangle — Fortify raises the team's Defence,
Shield Wall moves the damage, Enfeeble cuts it at the source — and discharges §10.1's reservation of
Enfeeble's second Role source.

**Enfeeble lands on impact, not before it.** An attack's damage is computed from the attacker's
attributes when the skill resolves, so a debuff applied at the moment of impact cannot shrink that
same hit; making it genuinely pre-hit would mean applying it at the start of the attacker's action,
which is new plumbing and reads on screen as an icon appearing for no visible cause. The first blow
lands full — which is what bracing *for* an impact means — and the 2-turn duration taxes every
follow-up.

**Composition hooks.** Enfeeble is world state any kit can read, and the redirection window is the
exported one: an ally standing inside it survives a resolution it otherwise would not.

**Damage redirection stays claimed twice**, closing §8's open item at the batch it named. This kit
does not lean harder on redirection, so Shield Wall and Bloodmage's Sanguine Pact remain
distinguishable — one redirects to protect, the other prices a damage buff.

**Projected numbers.** None. The kit fields no damage factor and is measured on the collapse test,
absent from the sweep's ranking by design (§4).

**Implementation.** No new `Combat_Event`, status resource, or `StatusEffectData` field — the clause
reuses `StatusEffects.Effect.trait_riders` (already generalized for Comorbidity and Field of Study).
`shield_wall_trait.gd` gains an `OnSkillCast` hook that, only when the cast is Brace for Impact, sets
an `&"attacker_debuff_on_damage"` rider (Enfeeble, 2 turns) on `TraitSkillResult`, threaded onto the
Rush and Aegis buffs the cast applies (`apply_buff_effect.gd` now copies `trait_result._trait_riders`
onto every buff template, the missing symmetric half of the debuff path). `_ApplyHealthLoss`
(`battle_resolver.gd`) gained an `p_attacker_ID` parameter, passed at both the direct-hit and
Shield-Wall-soaker call sites — the one place both paths already converge — forwarded into
`_TriggerDamageTakenReactions` (`status_effect_resolver.gd`), which now also scans the holder's buffs
for the rider and calls `CastDebuff` on the attacker through the normal resist roll. A fully
Barrier-absorbed hit never reaches the reaction, matching "lands on the Warlord."
`kit_contribution_manifest.gd`'s Brace for Impact entry updated. Post-implementation sweep: median
1.95x, 90th percentile 4.68x, ceiling 16.24x, 114 top-decile teams across 10 pairings — unchanged, as
predicted for a kit the scorer cannot see.

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
to one each.

**Claiming an existing status is preferred to authoring a new one.** Check the unclaimed list below
before adding a status resource; a new status needs a shape no unclaimed one covers. A preference,
not a rule — never hand a kit a status it does not want to shorten the list. State as of Batch 1's Plague Doctor rework (`aca439b`); everything else reflects the
archived pass's final state and goes stale as each further batch lands — refresh the claiming
Role's rows in the same edit, not after.

**Turn bar effects** — Dead Weight (Bar Brawler), Battle Orders (Tactician), Temporal Leak (Herald
of the loom, Pull the Thread), Slipstream (Tidal Corsair, Corsair's Reckoning — **implemented**,
section 9.13, granted alongside Empower on the mixed hand rather than costing a slot); Anchor,
Steadfast, Resonance unclaimed.

**Debuffs** (rows that changed this batch; all others unchanged from the archived pass — see
`Plan_Role_Skill_Kits.md` Archive for the full table until the next batch refreshes it here)

| Effect | Claimed by |
|---|---|
| Plague | Plague Doctor (Outbreak) — moved from Miasma; now stackable, no longer expiry-spread |
| Blight | Plague Doctor (Miasma) — moved from Quarantine Breach (renamed Outbreak) |
| Suppress | Herald of the loom (Thread Snap) — moved off the retired Thread Lash, now 1 turn (was 2); Scholar (Sharp Rebuttal's zone-gated rider) — **implemented** (section 9.14). At the commodity-debuff limit of two, so no later Role may take it |
| Temporal Leak | Herald of the loom (Pull the Thread) — newly claimed, retiring part of `FeatureIdeas.md`'s "Rework Orphaned Turn Bar Effects" item |
| Warped | Sorcerer (Unstable Rift reliably, Arc Lash's 25% rider) — **implemented** (section 9.3); both sources are the same Role, so the identity-effect rule still holds |
| Sanction | Emissary (Levied Sanction) — unchanged claimant; widened from an attribute reduction to a per-Infraction damage multiplier every attacker reads, **implemented** (section 9.7) |
| Hemorrhage | Bloodmage (Tithe of Vitality) — **implemented** (section 9.4); new debuff, no prior claimant |
| Mana Burn | Unclaimed — dropped from Bloodmage's Tithe of Vitality (section 9.4); nothing in the reworked kit read it |
| Exposed Facet | Appraiser (Sizing Cut) — **implemented** (section 9.5); moved onto the basic skill's 1-turn rider |
| Cracked Facet | Appraiser (Flaw Analysis) — **implemented** (section 9.5); moved off the retired Strike the Flaw passive, now scaled by the applier's Knowledge |
| Confound | Scholar (Expose Fallacy), Appraiser (Flaw Analysis) — **implemented** (section 9.5). Second claimant, within the commodity-debuff limit of two |
| Hexed | Diviner (Ill Omen), Jester (Burning Bolas) — **implemented** (section 9.6). Second claimant, at the commodity-debuff limit of two, so no later Role may take it. Scope now covers every chance roll in combat except damage variance |
| Enfeeble | Lancer (Disarm, shipped before this ledger's commodity-debuff limit was adopted), Diviner (Foresight), Warlord (Brace for Impact's reactive clause) — **implemented** (section 9.19). Three claimants, one over the commodity-debuff limit of two; no later Role may take it |
| Unravel | Alchemist (Dissolving Agent) — unchanged claimant; the skill keeps it alongside a second debuff — **implemented** (section 9.15) |
| Expose Weakness | Architect (Calibration), Alchemist (Dissolving Agent) — **implemented** (section 9.15). Second claimant, at the commodity-debuff limit of two, and its first skill source |
| Burning | Jester (Burning Bolas), Lava Zone — unchanged claimants. Tick rolls 2-10% of max Health per stack roster-wide — **implemented** (section 9.6) |

**Buffs** — Sea Legs is a new buff, claimed by Tidal Corsair (The Gilded Deck) — **implemented**
(section 9.13); no prior claimant, and the roster's only permanent stacking attribute grant, sized
per holder rather than by a fixed attribute. Borrowed Time is a new buff, claimed by Chronophage
(Time Tithe) — **implemented** (section 9.9); no prior claimant, and the only buff in the roster
granting an Echo. Attune's second claim (Herald of the loom's Woven Blessing, alongside Cultist's Chosen
Vessel passive) has dropped: Woven Blessing is no longer part of the Herald's kit (section 9.2,
implemented) and nothing in the new kit applies Attune, so Attune is now solely Cultist's (Chosen
Vessel passive). Sanguine Pact is a new buff, claimed by Bloodmage (Transfusion) — **implemented**
(section 9.4). Keen Edge and Lethal Precision stay claimed solely
by Appraiser (Full Appraisal), re-authored as consigned applier-scaled grants — **implemented**
(section 9.5); no other skill in the corpus applies either.

**Unclaimed inventory**, as of this review — "unclaimed" means *nothing in the game applies it*.
Refresh in the same edit that lands a batch.

* **No source — debuffs:** Slow, Blind, Refracted, Mana Burn.
* **Unclaimed by policy, not available to claim:** Fatigue, Stun, Sequence Lock, Signed Writ,
  Severance. Fights are puzzles, and a status that freezes an enemy's cooldowns, turns, or ability
  to resist can break one single-handedly. No Role applies these without a severe drawback, and
  never from a basic skill. Stun's only current source is the ownerless Weight of Law zone
  (section 10.3) and Rush's expiry, both of which fall on the holder rather than being aimed.
* **No source — buffs:** True Aim, Clarity, Insight, Mirror Coat, Rehearsed, Wanderlust, Overflow,
  Phalanx Guard.
  Turn bar buffs Anchor, Steadfast, Resonance are listed above.
* **Enemy-only:** Frenzy, Haste, Deathward.
* **Trait code only, never a skill:** Empower (Plan; Tidal Corsair's Corsair's Reckoning becomes a
  second claimant and its first skill source when 9.13 lands, within the commodity-buff limit of
  two), Attune (Chosen Vessel), Expose Weakness
  (Calibration, charge-scaled — gains its first skill source when 9.15 lands).

### 10.2 Damage-channel bucket keys in use

Sourced from `Scripts/Debug/kit_contribution_manifest.gd`'s `bucket_key` field (the runtime's own
key, not a doc paraphrase) — the authority the burst-reachability scorer actually reads. A blank
`bucket_key` means the entry contributes Channel 1 only, or is a pure Enabler; it claims no key.

| Bucket key | Claimed by | Shape |
|---|---|---|
| `CombinedDamageModifier.TRAIT_RESOURCE_KEY` | Cultist (Chosen Vessel), Architect (Calibration), Tidal Corsair (Wrangle the Sea) | Shared resource-key identifier — each Role's own trait-resource meter, not a collision: the key names the *mechanism* (caster's own resource-driven bucket), and each caster only ever reads their own resource, so three Roles sharing it composes rather than colliding. |
| `Volatile_Mixture` (granted status) | Alchemist (Fresh Batch) | Granted `DamageMultiplier` status on reagent consumption — lands on every teammate, refreshed rather than stacked |
| `Citation` | Emissary (Citation) | Skill-name bucket |
| `Warped` | Sorcerer (Cataclysm) | Debuff-type bucket — doubles as the debuff identity itself. Skill renamed from Cataclysmic Surge in section 9.3; the bucket key is the debuff name, so the rename does not move the key |
| `Zone: Unstable Rift` | Sorcerer (Unstable Rift) | Zone-name bucket |
| `Daunting_Strength` (granted status) | Tactician (Fatal Flaw) | Granted `DamageMultiplier` status — lands in whoever consumes it, not the caster's own bucket |
| `Pratfall Sting` | Jester (Pratfall Sting) | Skill-name bucket |
| `Devour Blessing` | Cultist (Devour Blessing) | Skill-name bucket |
| `ChosenVesselTrait` | Cultist (Chosen Vessel's Devotion) | `GetOutgoingDamageBonus` bucket (the trait's own script global name, `battle_resolver.gd`'s shared contribution key for that hook) — permanent per dead Vessel; distinct from the same passive's per-cast `TRAIT_RESOURCE_KEY` bonus so the two multiply |
| `Desecrated Blade` | Cultist (Desecrated Blade) | Skill-name bucket, conditional on the Vessel being alive and below half its own max Health |
| `Rending Charge` | Lancer (Rending Charge) — **implemented** (section 9.11) | Skill-name bucket, `bonus_per` keyed to the turn-bar section span the charge touches |
| `Heap On (ramp)` | Bar Brawler (Heap On) | Skill-name bucket, per-instance ramp (not a stacking cap) |
| `Final Calculation` | Architect (Final Calculation) | Skill-name bucket |
| `Corsairs Reckoning` | Tidal Corsair (Corsairs Reckoning) | Skill-name bucket |
| `Outbreak` | Plague Doctor (Outbreak) | Skill-name bucket, `bonus_per` keyed to `Target_Debuff_Count` (Batch 1's new generic trait-count source) |
| `Tithe of Vitality` | Bloodmage (Tithe of Vitality) — **implemented** (section 9.4) | Skill-name bucket, `bonus_per` keyed to `Wounded_Allies` (new Batch 1 trait-count source) |
| `Sanguine Pact` (granted status) | Bloodmage (Transfusion) — **implemented** (section 9.4) | Granted holder-missing-Health damage multiplier; lands in whoever holds it, not the caster's own bucket |
| `Sanction` (debuff on target) | Emissary (Levied Sanction) — **implemented** (section 9.7) | Debuff-type bucket, per-Infraction damage multiplier snapshotted at application; readable by any teammate's damage, not only the applier's |
| `Hemorrhage` (debuff on target) | Bloodmage (Tithe of Vitality) — **implemented** (section 9.4) | Debuff-type bucket, holder-missing-Health damage multiplier; readable by any teammate's damage, not only the applier's |

Every other Role/skill in the manifest carries `bucket_key = ""` today — either genuinely Channel 1
/ Enabler, or a kit that hasn't yet earned a bucket key. Appraiser's settled kit (section 9.5)
claims none by design, its contribution running through the crit path instead.

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
| The Gilded Deck | Tidal Corsair — **implemented** (section 9.13); the only zone placed without the player choosing its section |
| Weight of Law | **Unclaimed — no player or enemy fields it** |

Seven player-facing zones across six Roles, Chronophage holding two — the one existing exception to
the one-per-Role rule, and consistent with its turn-bar identity.

## 11. Scorer plumbing for Channel 3 payloads

`Scripts/Debug/burst_reachability.gd` and `kit_contribution_manifest.gd` are the authority the
sweep reads. Batch 1's Channel 3 payloads (the Sorcerer's Echo, Herald's Cut the Cloth, Plague
Doctor's Comorbidity/Miasma retick, Unstable Rift's zone damage) each needed scorer capability that
did not exist. What the manifest carries now:

`gated_bonus` (formerly `reagent_gated_bonus`, widened in place):

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
  instances, −0.5, 1.70 compounding) reproduces section 9.3's 5.2515x; Cut the Cloth (8 instances,
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
  claims no key. Miasma's own forced retick remains unscored: it has no `DamageEffect` of its
  own, top-level or zone-trigger, so it never becomes a candidate at all — and even a
  passive-scoped external `gated_bonus` (the shape added for the Chronophage's Time Tithe below)
  would still need a defensible magnitude for a retick this scorer has no battle state to size,
  so it stays undeclared rather than guessed.

**Closed implementing §9.14.** A new `attribute_amplification` manifest field
(`kit_contribution_manifest.gd`) and `_AttributeAmplification` (highest-wins across the team, mirroring
`Skills.AppliedAttributeAmplification`'s own runtime fold) let `_AccumulateAttributeBuff` add the
Scholar's own percentage points onto any "percentage"-kind grant before it lands in `fractions` —
confirmed against the real manifest (Tactician's Plan ahead: 0.3 becomes 0.41 with the Scholar
present). The sweep's recorded distribution is unchanged by this (median 1.95x, 90th percentile
4.68x, ceiling 16.24x, 114 top-decile teams across 10 pairings) for a structural reason rather than a
wiring gap: `_ScaledAggregate` divides the burst skill's aggregate by the basic skill's own, and 19 of
the roster's 20 kits scale their basic and their burst off the same attribute, so a uniform
percentage-point amplification cancels in the ratio exactly the way Tactician's own Empower grant
already does (noted in this plan's Context section). The amplification still inflates both aggregates
in absolute terms — real burst damage rises — just not the contrast-ratio metric this scorer reports.
The Jester is the one exception (Pratfall Sting scales Accuracy, Burning Bolas scales Attack); whether
its damage skill and basic should share an attribute is an open design question, not a code change.

**Verified while settling §9.5.** Full Appraisal's reciprocal loss (Consigned zeroing the
Appraiser's own crit attributes while lent out) is not modeled, but cannot move the metric either
way: it scales the Appraiser's own numerator and denominator alike, the same cancellation
`test_burst_reachability_crit.gd`'s crit test already pins.

**Closed while settling §9.4.** `granted_status` gained a `"reach": "team"` option
(`BurstReachability._ContributeGrantedStatuses`), for a status that sits on the enemy target itself
and is read by every attacker rather than granted to an ally — Hemorrhage's shape, generalizing the
`granted_attribute_buff` field's existing team reach (Sizing Cut's Exposed Facet) to the
`CombinedDamageModifier`-bucket case.

**Closed while settling §9.5.** `_CritFactor`'s chance clamp (`clampf(chance, 0.0, 100.0)`) dropped
the excess above 100 entirely, scoring No Wasted Margin's conversion as zero. Chance is now left
unclamped for the overflow term while the roll's own probability still saturates at 1.0
(`BurstReachability._CritChanceOverflowRate`). `granted_attribute_buff` also gained a
`"source_attribute"` kind, sizing a grant off the granting champion's own attribute
(`_AccumulateAttributeBuff`) rather than a fixed number — Keen Edge, Lethal Precision, and Cracked
Facet all read this way now.

**Consequence for measurement.** `total_contrast_ratio` stays the pure single-action figure the
30-50x burst-band target is checked against; `combined_contrast_ratio` is the separate figure
`Best()` and the sweep's top-decile selection actually rank by, sustained payload included. Reading
`total_contrast_ratio` alone for a sustained-heavy kit understates its actual standing in the
roster — `Tests/manual/team_corpus_sweep.gd`'s top-decile report prints both, plus a
`sustained_driven` flag per row, so which figure moved is visible rather than conflated.

**Open gap, found implementing §9.13.** `granted_attribute_buff` only models a fixed one-shot grant
on a fixed attribute. The Gilded Deck's Sea Legs is stacking, zone-delivered, and sized on whichever
attribute is highest on the *holder* — a shape the field cannot represent without either naming a
wrong attribute or forcing an aggregate contribution that isn't there for most teams. Left
undeclared; the Tidal Corsair's contribution to the sweep is Broadside's bucket only.

**Open gap, found implementing §9.15.** The scorer has no model of the reagent economy at all — no
notion of a consumption count, a shared slot, or a refund. Catalyst Cloud's payload raises how many
times a team consumes a reagent within a battle, which re-arms Volatile Mixture more often than the
sweep's single-action scoring can see. Left undeclared, the same posture the Tidal Corsair's zone
grant took in §9.13.
