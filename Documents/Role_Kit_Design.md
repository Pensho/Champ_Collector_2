# Role Kit Design

Living design document for the Blowout pillar's kit layer. Settled kits are promoted into
`Concept_Document.md` 3.2.4.2, which stays the authority once a kit lands; this document carries
the allocation and the in-flight synergy ledger before that promotion.

**Status:** channel identity allocation, contribution direction, and pairing web settled; batches
2-4 proposed. No skill or status `.tres` exists yet beyond what already ships
(`Concept_Document.md` 3.2.4.2).

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
is the one shape forbidden — Bar Brawler's Heap On ramp is the roster's only case, to fix at its own
batch. Most basics stay plain: the allowance lets a kit put its identity on its basic, not a licence
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
| Cascade instance count | `Types.Cascade_Trigger` | Each instance re-reads channels 1 and 2, so count multiplies against them. |
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

**Factors are only comparable within their own kind** — bucket product, cascade instance count,
crit-path multiplier, mitigation-term factor (§9.12's bypass, §9.10's Defence debuff), exported
factor on a carrier. One ranked column across all four is not a
measurement.

**Current state: bimodal.** Instance counts: Herald 8.64x, Sorcerer 6.59x at its gated ceiling (1.5x
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

Direction is settled for the Roles whose kits are settled (sections 9.1-9.5) and **proposed** for
the rest — confirm or overturn it at that Role's own batch, before its concrete numbers are fixed.
A Role's basic skill is always self-facing; direction describes the declared-identity contribution.

| Role | Purpose (unchanged) | Primary identity | Direction | Composition hook (sketch) |
|---|---|---|---|---|
| Plague Doctor | Debuffer | **Channel 3** | Self | Debuff density on the target feeds cascade instance count — the deepest identity claim in the roster (Batch 1 anchor; absorbs the Comorbidity fix). |
| Sorcerer | Damage, Debuffer, Control | **Channel 3** | Self | Reagent-triggered repeat re-resolves channels 1 and 2 as a fresh instance; the second, independently-gated cascade anchor (Batch 1). |
| Herald of the Loom | Debuffer, Buffer | **Channel 3** | Self | No passive exists in code today — free design space. A stance-driven status-expiry cascade (reads `Status_Expired`, the trigger already wired for Plague/Overflow) gives the roster a third cascade source gated by duration management rather than reagents or debuff count (Batch 1; needs a passive authored from scratch). |
| Chronophage | Control | **Channel 3** | Exported | Settled (§9.9), confirming this row without the threshold-crossing trigger it originally proposed — a boundary-counting gate reads as arithmetic the player cannot see. Instead the passive grants Borrowed Time to an ally it boosts alone, and that ally's next skill resolves once more. The Role fields no damage factor of its own (Batch 2). |
| Emissary | Debuffer, Control | **Channel 2** | Exported | Settled (§9.7), confirming this row. Sanction carries a snapshotted per-Infraction damage multiplier every attacker on the team reads, and stays a distinct debuff type feeding the density count (Batch 2). |
| Alchemist | Debuffer, Buffer | **Channel 2** | Exported | Fresh Batch's team damage buff on reagent consumption already fits — keep as the reagent-consumption anchor; the factor lands on the whole team, not the Alchemist (Batch 4). |
| Appraiser | Debuffer | **Enabler** | Exported | Settled (§9.5), moved off this table's Phase 1 proposal of Channel 2: the whole contribution runs through the crit path, which claims no bucket key. Strike the Flaw (crit applies Cracked Facet) was the crit-path anchor — independent of the debuff-density and cascade routes, since it multiplies through the crit-damage path outside the combined modifier (1.1.4). The settled kit (§9.5) consigns the whole contribution to a carrier (Batch 1). |
| Cultist | Debuffer, Damage | **Channel 2** | Self | Settled (§9.8), confirming this row. Chosen Vessel's flat per-cast bonus stays flat; Vessel death now also grants permanent Devotion, and the basic reads the Vessel's half-Health threshold (Batch 2). |
| Jester | Damage, Sustain | **Enabler** | Exported | Hexed on the boss degrades every roll it makes in its own favor — crit checks, resist checks against the team's debuffs, its own Burning ticks — so a debuff-density burst becomes reliable rather than a coin flip; Spotlight pulls focused fire onto the champion built to dodge it. Settled (§9.6), and moved off this table's Phase 1 proposal of Channel 2 / self-facing: the kit declares no damage contribution (Batch 2). |
| Architect | Buffer, Damage | **Channel 2** | Self | Settled (§9.10), confirming this row. The kit is kept as it ships — the finisher's charge bucket already meets the contract and the zone already consumes charges against it. Only Expose Weakness changes, scaling with the charges spent (Batch 2). |
| Tidal Corsair | Damage | **Channel 2** | Self | Settled (§9.13), confirming this row. An adaptation: Corsair's Reckoning resolves by the composition of the stacks it consumes, and Sea's turn-bar push retires for Undertow, a bank on the target that only a pure Steel hand converts (Batch 3). |
| Thief | Damage | **Channel 1** | Self | Settled (§9.12), confirming this row. Pilfer retires for Between the Plates, a passive bypass reading a fraction of the target's *base* Defence, so a teammate's Defence shred compounds with it instead of being eaten by it; Weigh the Mark is rebuilt as Cut Purse (Batch 3). |
| Lancer | Damage | **Channel 2** | Self | Settled (§9.11), moved off this table's Phase 1 proposal of Channel 1. Momentum and Phalanx Guard retire for Charge Distance: the charge scales with the turn-bar sections it touches and throws the Lancer back half that distance. The Role reads turn-bar position rather than accumulating stacks, so it is no longer route D's second anchor (Batch 3). |
| Tactician | Buffer | **Channel 1** | Exported | Plan's attribute grant stays, but the rework should add a second hook beyond Daunting Strength so this Role is one of several Channel-2 feeds into a pairing, not the roster's sole one (Batch 3). |
| Bloodmage | Sustain, Damage | **Channel 1** | Exported | Hemoclarity's Health-threshold Mysticism surge is already Channel 1 by mechanism; the kit's weight lands in Sanguine Pact (on the carrier) and Hemorrhage (on the boss, readable by every attacker) rather than on the Bloodmage's own cast (Batch 1 — currently a zero-contribution kit). |
| Scholar | Debuffer, Buffer | **Channel 2** | Exported | Expose Fallacy's Opportunist grant is the modifier-bucket anchor (feeds any per-debuff-type reader on the team). Refutation's zone removal stays an Enabler-tagged skill within the kit — denying the enemy's own zone setup, held to the collapse test on its own, not claimed as the Role's identity (Batch 3). |
| Diviner | Sustain, Debuffer | **Channel 1** | Exported | Foresight's pre-emptive Enfeeble is the attribute-channel anchor, and it lands on the enemy for the whole team's benefit; Premonition's auto-miss protection is the exported window. Not a damage carrier — the kit is measured on what it keeps alive and what it blunts (Batch 4). |
| Symbiote | Sustain, Buffer | **Channel 1** | Exported | Exhert's attribute buff is the baseline anchor, present from the ungrafted state on, and lands on the ally it targets. Post-graft the kit may read as self-facing depending on which graft the player binds (pool-dependent, `Symbiote_Graft_Pool.md`); the ungrafted baseline is what fixes the declared direction (Batch 4). |
| Bar Brawler | Sustain, Buffer | **Channel 2** | Self | Heap On already grows stronger with every use — the basic skill itself is the modifier-bucket anchor. On the House's heal-on-buff stays an Enabler-tagged skill within the kit, not the Role's identity (Batch 4). |
| Warlord | Sustain | **Channel 1** | Exported | Shield Slam scales with Defence as the self-facing floor, but the kit's weight is the window it holds open: Shield Wall's damage redirection and Hold the Line's granted Fortify. Measured on the collapse test, not on a damage factor (Batch 4). |

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
| **F — Turn-bar distance** | The turn-bar span between attacker and target, read at the moment of impact | Lancer (Charge Distance, §9.11). Every kit that pushes an enemy back feeds it — the Corsair's Sea stacks, the Chronophage's theft, Dead Weight, Temporal Leak — so the route's other half is any turn-bar writer, not a designated anchor. | 3 |
| **G — Armour removal** | The target's effective Defence at the moment of impact, outside the combined modifier | **Closed.** Architect (Expose Weakness, exported — §9.10) + Thief (base-referenced bypass, self — §9.12). The two compose because the bypass subtracts a fraction of *base* Defence rather than scaling what is left. | 2, 3 |

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
  base-referenced bypass passive, opening route G with the Architect), Scholar, Tactician (add the
  second hook so it isn't the pairing web's sole Channel-2 source), Tidal Corsair (**settled,
  §9.13** — a composition-reading Reckoning, closing route D).
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

* **Cross-kit Channel 2 stays the axis to watch.** Section 10.2 is still mostly private: nine
  self-facing skill-name buckets and three sharing the self-facing trait-resource key, against five
  exporting entries (`Daunting_Strength`, `Volatile_Mixture`, Bloodmage's two grants, Emissary's
  Sanction). The same privacy runs through the seven accumulate-then-spend counters, which feed
  nothing outside their own kit; most are expected to stay that way, but check it whenever a kit
  could export instead.
* Damage redirection is claimed twice — Warlord's Shield Wall (the Role's whole collapse-test claim)
  and Bloodmage's settled Sanguine Pact. Judged minor, since one redirects to protect and the other
  as the price of a damage buff. Revisit at Warlord's batch if its redesign leans harder on
  redirection; no change now.
* The exact `Trait_Count_Source` / debuff-type identifiers for Emissary's Infraction hook and
  Bloodmage's missing-Health hook are batch-time authoring decisions, not Phase 1 commitments.
* Whether Chronophage's new threshold-crossing `Cascade_Trigger` should also serve a future
  Health-threshold design (the other named gap in section 3) is worth revisiting once batch 2
  lands — not resolved here to avoid scope creep into code before sign-off.
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
repeat is a real cascade instance — its own `Cascade_Triggered` marker and its own
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
gap in `FeatureIdeas.md`.

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

| Scenario | Team contrast ratio |
|---|---|
| Legendary, 4 Echoes, strong team (product 5.5) | **36.2x** |
| Legendary, 4 Echoes, modest team (product 3.0) | 19.8x |
| Legendary, 1 Echo (steady state, no reagents banked) | 8.3x |
| Uncommon, 4 Echoes, strong team | 22.5x |

**These are team figures, not the Sorcerer's own contribution** (section 4). The Sorcerer's own
factor is the Echo multiplier: **6.59x at the 4-Echo ceiling**, 1.5x in the 1-Echo steady state —
above section 4's per-Role ~2x target at the ceiling, which is the deliberate shape of a Channel 3
anchor whose ceiling is gated behind spending three banked reagents in one turn.

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
against a modest team (product 3.0), ≈13.8x. Both are team figures (section 4); the Bloodmage's own
factors are the 1.70x Wounded_Allies bucket and Hemoclarity's 1.80x aggregate bonus, comfortably
inside §1's ~2x contract. The exported factors below are where this kit's weight actually lands:

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
* **Confound** (debuff): magnitude rises roster-wide (section 12) — the term that blunts crit
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

### 9.6 Jester — the luck Role

**Status:** Settled, not yet implemented. Batch 2.

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
`BattleResolver._RollFavoring` rather than a bare `randf()`, so Luck and Hexed reach it.

| Slot | Skill | Effect | Channel |
|---|---|---|---|
| Basic | Pratfall Sting | Accuracy-scaled damage to one enemy, +30% if the Jester avoided an attack since its last turn. | 1 + 2 |
| Signature | Burning Bolas | Attack-scaled damage to one enemy; applies Burning and **Hexed** for 2 turns. Cooldown 2. | 1 + Enabler |
| Signature | Center Stage | The Jester gains Spotlight for 2 turns and Luck for 1 turn. Cooldown 3. | Enabler |

**The kit depends on three roster-wide mechanics changes** — Luck and Hexed's reach, the
debuff-resist contest band, and Burning's tick — which are not Jester kit content and are recorded
in section 12. What they buy this kit: Hexed's resistance clause stops being nearly inert, and
because Hexed makes its holder take the worse of two rolls, a Hexed target's expected Burning tick
is **7.33%** against the 6% mean.

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

**Implementation needs (not yet built):**

* `double_the_fun_trait.gd:66` — the avoidance roll moves from `p_resolver.GetRandom().randf()` onto
  `_RollFavoring`.
* `BattleResolver._RollFavoring` reaches every remaining chance roll except the damage-variance
  roll in `_ResolveDamage`.
* `status_effect_resolver.gd:242-243` — the resist contest's random band widens to 0.85-1.0.
* `Burning.tres` — `magnitude_kind` stays `MaxHealthPercent`, but the tick reads a rolled range
  rather than a fixed `magnitude`; the range needs a representation on `StatusEffectData` and a
  roll site in the tick path that routes through `_RollFavoring` so Hexed and Luck bias it.
* `Burning_Bolas.tres` — a second `ApplyDebuffEffect` for Hexed, 2 turns.
* `kit_contribution_manifest.gd` — Burning Bolas' entry gains Hexed; all four Jester entries stay
  `bucket_key`-less apart from Pratfall Sting's existing `Pratfall Sting` key.
* `Concept_Document.md` at promotion: 3.1.3's Jester passive entry (Luck reaching the dodge roll),
  3.2.1 #3 (the widened band), 3.2.3's Luck, Hexed and Burning entries, and 3.2.4.2's Burning Bolas.
* `Encounter_Design_Document.md:267,407` — Reanimating Statues 3 names Burning Bolas as its
  intended solution for burning past Defence; the 4% → 6% mean is a buff to that solution. Recorded,
  not tuned: encounter values are not being balanced at this stage.

**Judgment calls made while settling, listed so they can be overruled:** Burning was reworked in
place rather than given a Jester-exclusive successor status, which spreads the rolled tick to Lava
Zone; Hexed's second claimant (alongside Diviner's Ill Omen) puts it at the commodity-debuff limit
of two, so no later Role can take it.

### 9.7 Emissary — the verdict the whole team reads

**Status:** Settled, not yet implemented. Batch 2.

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

**Implementation needs (not yet built):**

* `Sanction.tres` gains the damage-taken clause. Both clauses read the single float
  `standing_record_trait.gd:GetAppliedStatusValue` already snapshots (tally × applier rate) as
  fixed multiples — 2× and 0.5× — so no second snapshot field is added.
* The "damage multiplier read off a debuff the target holds" computation is shared with §9.4's
  Hemorrhage; Emissary's is snapshot-valued where Hemorrhage's is continuous.
* `Signed_Writ.tres` / `standing_record_trait.gd` — the strip rider needs the duration-reduction
  path to report which buffs it zeroed so the trait can credit an Infraction each.
* `kit_contribution_manifest.gd` — Levied Sanction's entry gains `bucket_key: "Sanction"`
  (debuff-type bucket, exported, magnitude 0.72); Signed Writ's precondition gains the rider.
* `Concept_Document.md` at promotion: 3.1.3's passive (skills may state a multiple of the rate),
  3.2.3's Sanction entry (retag Channel 1 → Channel 2, both clauses), 3.2.4.2's Signed Writ and
  Levied Sanction.

**Judgment calls made while settling, listed so they can be overruled:** the tally stays a
caster-side counter rather than becoming a stacking debuff on the enemy — a real status would let
any kit read the count directly, at the cost of a permanent slot against the 8-status cap in the
kit whose whole route is debuff density. Weight of Law stays ownerless (section 10.3): a signature
zone would have to displace Levied Sanction, which is where the export now lives.

### 9.8 Cultist — the sacrifice pays out

**Status:** Settled, not yet implemented. Batch 2.

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
| Basic | Profane Bolt | Mysticism-scaled damage to one enemy, **+25% while the Vessel is below half Health**. | 1 + 2 (conditional) |
| Signature | Devour Blessing | Kept as-is. Consumes all buffs on the ally holding the most; Mysticism-scaled damage to one enemy, +25% per buff consumed. Cooldown 3. | 1 + 2 |
| Signature | Rite of Severance | Kept as-is. Mysticism-scaled damage to one enemy, applies Severance for 2 turns. Cooldown 4. | 1 + Enabler |

**What the kit now reads.** Vessel death stops being a consolation event and becomes the
transaction the Role is built on — the sacrifice has a price the player pays and a payout they
keep. Profane Bolt's rider is the threshold read on the way there: the drain that used to be a pure
tax now moves the basic across a line the player can aim at. Both surfaces are the Vessel's own
Health, distinct from §9.4's caster-own and enemy-own reads, so route E's two anchors multiply
rather than share a key.

**Projected numbers.** Chosen Vessel's per-cast 1.30x is unchanged. Devotion adds **1.20x** per
dead Vessel in a distinct bucket — 1.56x combined with one Vessel spent, 1.87x with two, at which
point the Cultist is the last champion standing and the team's other terms are gone. Profane Bolt's
conditional 1.25x is on the basic and is not the declared contribution. Devour Blessing's 1.25x per
buff consumed is unchanged. Inside section 1's contract; the ceiling is self-limiting by
construction.

**Implementation needs (not yet built):**

* `chosen_vessel_trait.gd` — a Devotion count incremented on Vessel death, contributing its own
  `CombinedDamageModifier` bucket key rather than the shared `TRAIT_RESOURCE_KEY` the per-cast
  bonus uses, so the two multiply. The Vessel-death branch that grants Attune is the hook.
* `Profane_Bolt.tres` — `bonus_per: {Trait_Condition: 0.25}`; the trait answers `Trait_Condition`
  with 1.0 while the Vessel is alive and below half max Health, 0.0 otherwise. No new enum value.
* `kit_contribution_manifest.gd` — Chosen Vessel's entry gains Devotion as a second passive row
  (`bucket_key: "Devotion"`, magnitude 0.20, `stack_cap` = living allies at battle start); Profane
  Bolt gains `bucket_key: "Profane Bolt"` with its condition stated.
* `Concept_Document.md` at promotion: 3.1.3's Chosen Vessel entry (Devotion), 3.2.4.2's Profane
  Bolt.

**Judgment calls made while settling, listed so they can be overruled:** the party is Devotion's
only cap, which is honest but means a wipe-adjacent team reads as the Cultist's strongest state;
Rite of Severance keeps its plain-damage payload rather than gaining a Vessel-consuming clause, so
Vessel death stays something the drain produces rather than something a skill executes.

### 9.9 Chronophage — time given away, not spent

**Status:** Settled, not yet implemented. Batch 2.

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
holds the buff — below §9.2's Herald (8.64x) and §9.3's Sorcerer (6.59x), which is correct: those
are self-facing counts a champion builds toward across a fight, and this is a free extra resolution
handed to someone else once per boost. In the exported kind it sits alongside §9.4's Sanguine Pact
(1.60-1.96x) and Hemorrhage (1.30-1.48x). The Chronophage's own damage is Zap and stays where it
is; the Role fields no factor of its own and is expected to be near-invisible in the sweep's
ranking.

**Implementation needs (not yet built):**

* `Borrowed_Time.tres` — new buff. Its payload is an instance-count grant, not a damage modifier:
  the holder's next damaging skill resolves once more at the recorded fraction.
* `chronophage_trait.gd` — the ally-forward branch, gated on the moved ally being the only ally in
  its turn-bar section at the moment the boost lands, plus the grant itself.
  `CascadeResolver.SubscribeInstanceModifier` is the existing seam for adding a resolution to a
  skill the trait's owner did not cast.
* A reduced-strength cascade instance: the extra resolution re-reads channels 1 and 2 like any
  cascade instance but at a fraction of magnitude. The Herald's thread already modulates the damage
  of instances it produces; this needs the same modulation applied to an instance the *holder*
  produces.
* `kit_contribution_manifest.gd` — Time Tithe's entry records Borrowed Time as an exported
  instance-count grant landing on the holder, not on the Chronophage. The scorer has no
  representation for an instance count granted to another champion; expect this to need the same
  kind of plumbing work section 11 lists for Batch 1's Channel 3 payloads.
* `Concept_Document.md` at promotion: 3.1.3's Time Tithe entry, 3.2.3's buff catalog (Borrowed
  Time).

**Judgment calls made while settling, listed so they can be overruled:** the buff does not stack,
so a champion boosted twice before acting still echoes once — the alone-clause already limits
frequency and stacking would compound a factor handed to someone else's finisher; and the echo is a
fraction rather than a full resolution, which keeps the Chronophage from doubling a teammate's
burst outright.

### 9.10 Architect — kept, with the debuff scaled to the spend

**Status:** Settled, not yet implemented. Batch 2.

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

**Implementation needs (not yet built):**

* `calibration_trait.gd` — Expose Weakness's magnitude reads the charge count at the moment of
  application instead of a fixed value. The trait already applies the debuff and already holds the
  count.
* `kit_contribution_manifest.gd` — delete Calibration's stale `TRAP (doc disagreement)` note:
  `Concept_Document.md` 3.1.3 already states maximum 12 with tiers 1-4 / 5-8 / 9-12, matching
  `MAX_CHARGES`, `EXPOSE_WEAKNESS_THRESHOLD` and `ZONE_RE_ERECT_THRESHOLD`. Record Expose Weakness
  as an exported factor rather than leaving the entry reading Channel 2 only.
* `Concept_Document.md` at promotion: 3.2.3's Expose Weakness entry (charge-scaled magnitude) and
  3.2.4.2's Final Calculation.

**Judgment calls made while settling, listed so they can be overruled:** the 9-12 tier's free zone
re-erect is left as the only reward for a maximum spend beyond raw magnitude, rather than gaining an
exported clause of its own — route D stays predominantly self-facing.

### 9.11 Lancer — the charge and the ride back

**Status:** Settled, not yet implemented. Batch 3.

**Identity: Channel 2, self-facing**, moved off section 5's Phase 1 proposal of Channel 1: the
charge's magnitude is a bucket on its own skill, not an attribute change. The passive is
**replaced** — Reckless Momentum and Phalanx Guard both retire — and all three skills are kept.

**Passive: Charge Distance.** Rending Charge deals **+9/12/15/18% by rarity per turn-bar section the
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

**Implementation needs (not yet built):**

* `lancer_trait.gd` — Momentum, the Defence penalty, Phalanx Guard and the offensive/defensive skill
  name sets all go. The trait reads the inclusive section span between the Lancer and the charge's
  target at cast resolution, and applies the self-pushback after the damage resolves.
* `Rending_Charge.tres` — a `bonus_per` keyed to the new section-span count source, 0.18 per section
  at Legendary.
* A new count source for the span, plus the turn-bar self-pushback as a trait-driven effect: the
  existing pushback paths write to a *target's* bar, not the caster's own.
* `kit_contribution_manifest.gd` — Reckless Momentum's entry becomes Charge Distance; Rending Charge
  gains `bucket_key: "Rending Charge"`, magnitude 0.90 at the five-section ceiling. Both TRAP notes
  are stale and go with it — the skill-name bug they describe is fixed.
* `burst_reachability.gd` — the scorer has no model for a positional gate, so the charge's magnitude
  is declared as a `gated_bonus` (`gate: &"charge_distance"`) at an assumed three-section span, the
  same shape section 11's other gates use.
* `Concept_Document.md` at promotion: 3.1.3's Lancer entry — the passive, and the description line
  and primary attributes (Attack, Speed) the Role has never had; 3.2.3.2's Phalanx Guard entry
  retires; 3.2.4.2's Rending Charge and the Lancer's stale bug note.

**Judgment calls made while settling, listed so they can be overruled:** Disarm keeps its shipped
payload rather than gaining a deliberate distance lever, since the passive already carries the loop
and the kit clears its contract without a second one; and the recoil is a fixed half of the span
rather than an amount the player chooses at cast time.

### 9.12 Thief — between the plates

**Status:** Settled, not yet implemented. Batch 3.

**Identity: Channel 1, self-facing.** Confirms section 5's proposal — the whole contribution is a
mitigation term, which claims no bucket key. The passive is **replaced**, the third skill is
**rebuilt**, and Pierce Weakness keeps its shape while its magnitude moves onto the passive's rate.

**Passive: Between the Plates.** The Thief's attacks ignore **10/13/16/20% by rarity of the target's
base Defence**, subtracted in points after every other Defence modifier has applied and floored at
zero. Pilfer retires; the bypass is what the Role is rather than one skill it owns, and it is the
half that scales with rarity naturally. The passive owns the rate and a skill may state a **multiple**
of it, never a rate of its own (the convention §9.7 established).

**Reading the base Defence is the point.** A multiplicative ignore lands on the same term as a
Defence debuff, so each one makes the other worth less — the Thief's own factor *fell* from 1.39x to
1.31x when a teammate shredded first. Subtracting a base-referenced amount inverts that: the
teammate's reduction survives intact and the Thief's cut is worth more against a target already
opened up.

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

**Projected numbers.** Against a boss-tier base Defence of 120: the passive is **1.10x** on every
attack, Pierce Weakness **1.30x** alone, **1.40x** against a boss under Expose Weakness at −30%, and
**1.47x** at −44%. Opportunist is **1.40x** at four distinct debuff types. Two factors, **1.82x** on
the Pierce turn. Against a base Defence of 40 the same skill is worth 1.14x — the mechanic pays only
against armour, which is the fantasy stating its own limit.

**Implementation needs (not yet built):**

* `damage_effect.gd`'s `defense_ignore_factor` changes shape to a base-Defence fraction subtracted in
  points. Pierce Weakness is its only user in the entire data set, so the field changes in place.
* `battle_resolver.gd:770` and the Shield Wall re-mitigation at `:780` both compute effective Defence
  from the *effective* attribute; both need the target's base Defence as well.
* A new Thief trait carrying the rate and applying it to every attack the Thief makes;
  `pilfer_trait.gd` retires.
* `Pierce_Weakness.tres` — cooldown 1 → 2, ignore expressed as 2.5× the trait's rate.
* `Weigh_the_Mark.tres` → `Cut_Purse.tres` — damage, the steal, and the Opportunist grant.
  `StatusEffectResolver.StealBuff` already takes a duration override it never uses; the extra turn
  goes there.
* `kit_contribution_manifest.gd` — Pilfer's entry becomes Between the Plates; Pierce Weakness's
  precondition drops the stale "stops mattering at burst scale" note, superseded by Phase 0; Weigh
  the Mark's entry is renamed and its doc/code conflict note deleted.
* `burst_reachability.gd` — **the scorer models no defence ignore at all** (section 11), so the
  Thief's declared contribution is invisible to it until that lands.
* `Concept_Document.md` at promotion: 3.1.3's Thief passive, 3.2.4.2's skill entries (the rename, the
  cooldowns, and the ignore restated as a multiple), and 3.2.4.3's stale note claiming Weigh the Mark
  is fielded by no preset — `Thief.tres` fields it.

**Judgment calls made while settling, listed so they can be overruled:** the passive's bypass applies
to the basic skill too, which is a mitigation gain on a no-cooldown cast rather than the
unconditional bucket key §1.2 forbids; and Cut Purse steals exactly one buff at every rarity, since
the rate that scales already lives in the passive.

### 9.13 Tidal Corsair — the hand decides the Reckoning

**Status:** Settled, not yet implemented. Batch 3.

**Identity: Channel 2, self-facing**, confirming section 5's row on both axes. An **adaptation**: the
three slots, the two stack types, the passive's skill-name switch and the `TRAIT_RESOURCE_KEY`
bucket all stay. Corsair's Reckoning now reads *which* stacks it consumes, and the Sea half pays the
Corsair back instead of taxing it.

**The defect closed.** Steel and Sea compete for the same three slots, but a Sea slot cost 60%
Reckoning damage at Legendary and bought a 14% turn-bar push the Corsair converts into nothing. On a
burst turn that trade is never correct, so the "Combo character where you plan your moves ahead"
(`Concept_Document.md` 3.1.3) had exactly one line — Boarding Strike three times, then Reckoning —
and Saltwater Shot was Boarding Strike with a different icon: same scaling, same cooldown, no rider.

**Passive: Wrangle the Sea.** Unchanged in shape. The per-Steel damage rate drops to **28/32/36/40%
by rarity** and gains **+6/7/8/9% per Undertow spent**; the per-Sea turn-bar push retires.

**The Reckoning resolves by composition; count sets the size.** Ten possible hands, three rules — so
a hand of one or two stacks resolves as itself, and casting early is a tempo decision rather than a
failed Reckoning.

| Hand | Mode | Effect (Legendary) | Channel |
|---|---|---|---|
| Steel only | **Broadside** | Consumes all Undertow on the target; per-Steel rate 0.40 + 0.09 per Undertow spent. | 1 + 2 |
| Sea only | **Chart the Course** | One Undertow per Sea, no damage bonus, cooldown 1 instead of 3. | 2 |
| Mixed | **Cut of the Haul** | Steel damages at the base rate, reading no Undertow and spending none; Sea applies its Undertow; every other living ally gains Slipstream and Empower for 2 turns. | 1 + Enabler |

**Only a pure Steel hand ever touches the bank.** That one rule is what lets the crew cast keep the
Corsair's investment intact, and it is also why the mixed hand is not strictly better than Broadside:
the bank is convertible into damage by nothing else.

**Undertow** is a new stacking debuff on the target, cap 3 — the investment sits on the enemy, so a
target switch or an early kill loses it. That is the cost that keeps banking a decision.

**Composition hooks.** Undertow is a distinct debuff type, so it feeds any `Target_Debuff_Count`
reader (route A) without this kit naming a Role. Slipstream and Empower are existing statuses and
Channel 1 / Enabler grants, **not** a Channel 2 export — the declared contribution stays Broadside
on the Corsair's own sheet, which is what holds the self-facing direction. The kit closes route D's
open second anchor (section 6) as the self-facing half against Architect's exported one.

**Projected numbers.** Broadside at 3 Steel: **2.20x** bare, **3.01x** off a full bank — a
redistribution of the shipped 2.80x, not a raised ceiling, and the un-invested line now sits below
it. Cut of the Haul at 2 Steel is 1.80x plus Empower's +30% Attack on each ally, which lands in the
aggregate rather than the modifier product. Reaching the bank costs two Reckonings on one target
about six turns apart: inside a boss's 10-12 rounds, outside a fodder fight's 3-4, so the Role is
deliberately weakest in trash.

**Implementation needs (not yet built):**

* `tidal_corsair_trait.gd` — the `OnSkillCast` "Corsairs Reckoning" branch reads the consumed hand's
  composition and dispatches one of three payloads instead of summing per-stack effects;
  `_turn_bar_bump` goes. The per-Steel rate reads the target's Undertow count at resolution.
* `Data/Status_Effects/` — Undertow, stacking to 3. `Corsairs_Reckoning.tres` and
  `Saltwater_Shot.tres` gain their new payloads; Saltwater Shot stops being a scaling clone.
* `kit_contribution_manifest.gd` — Wrangle the Sea's magnitude rises 1.8 → 2.01 and its stale TRAP
  note about the apostrophe bug goes; the Slipstream/Empower grants are declared as a
  `granted_attribute_buff` so the scorer credits Empower into the ally's aggregate.
* `Concept_Document.md` at promotion: 3.1.3's Wrangle the Sea entry, 3.2.3's Undertow entry and
  Slipstream's claimant, 3.2.4.2's Saltwater Shot and Corsair's Reckoning.

**Judgment calls made while settling, listed so they can be overruled:** Chart the Course keeps its
cooldown clause, which is the first thing to cut if the description outgrows 3.2.4's soft cap; the
mixed hand grants two existing statuses rather than one new bespoke buff, so the kit adds one status
to the catalog instead of two; and Boarding Strike is untouched, since the dominance defect was
Sea's payload rather than the basic's.

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
of the loom, Pull the Thread), Slipstream (Tidal Corsair, Corsair's Reckoning — **settled, not yet
implemented**, section 9.13, granted as a rider alongside Empower rather than costing a slot);
Anchor, Steadfast, Resonance unclaimed.

**Debuffs** (rows that changed this batch; all others unchanged from the archived pass — see
`Plan_Role_Skill_Kits.md` Archive for the full table until the next batch refreshes it here)

| Effect | Claimed by |
|---|---|
| Plague | Plague Doctor (Outbreak) — moved from Miasma; now stackable, no longer expiry-spread |
| Blight | Plague Doctor (Miasma) — moved from Quarantine Breach (renamed Outbreak) |
| Suppress | Herald of the loom (Thread Snap) — moved off the retired Thread Lash, now 1 turn (was 2) |
| Temporal Leak | Herald of the loom (Pull the Thread) — newly claimed, retiring part of `FeatureIdeas.md`'s "Rework Orphaned Turn Bar Effects" item |
| Warped | Sorcerer (Unstable Rift reliably, Arc Lash's 25% rider) — **settled, not yet implemented** (section 9.3); both sources are the same Role, so the identity-effect rule still holds |
| Sanction | Emissary (Levied Sanction) — unchanged claimant; widened from an attribute reduction to a per-Infraction damage multiplier every attacker reads, **settled, not yet implemented** (section 9.7) |
| Hemorrhage | Bloodmage (Tithe of Vitality) — **settled, not yet implemented** (section 9.4); new debuff, no prior claimant |
| Mana Burn | Unclaimed — dropped from Bloodmage's Tithe of Vitality (section 9.4); nothing in the reworked kit read it |
| Exposed Facet | Appraiser (Sizing Cut) — **settled, not yet implemented** (section 9.5); moved onto the basic skill's 1-turn rider |
| Cracked Facet | Appraiser (Flaw Analysis) — **settled, not yet implemented** (section 9.5); moved off the retired Strike the Flaw passive, now scaled by the applier's Knowledge |
| Confound | Scholar (Expose Fallacy), Appraiser (Flaw Analysis) — **settled, not yet implemented** (section 9.5). Second claimant, within the commodity-debuff limit of two. Magnitude rises roster-wide (section 12) |
| Hexed | Diviner (Ill Omen), Jester (Burning Bolas) — **settled, not yet implemented** (section 9.6). Second claimant, at the commodity-debuff limit of two, so no later Role may take it. Scope widens roster-wide (section 12) |
| Undertow | Tidal Corsair (Saltwater Shot's Sea stacks, spent by Corsair's Reckoning) — **settled, not yet implemented** (section 9.13); new debuff, no prior claimant, stacks to 3 |
| Burning | Jester (Burning Bolas), Lava Zone — unchanged claimants. Tick changes roster-wide (section 12) — **settled, not yet implemented** (section 9.6) |

**Buffs** — Borrowed Time is a new buff, claimed by Chronophage (Time Tithe) — **settled, not yet
implemented** (section 9.9); no prior claimant, and the only buff in the roster granting a cascade
instance. Attune's second claim (Herald of the loom's Woven Blessing, alongside Cultist's Chosen
Vessel passive) has dropped: Woven Blessing is no longer part of the Herald's kit (section 9.2,
implemented) and nothing in the new kit applies Attune, so Attune is now solely Cultist's (Chosen
Vessel passive). One further pending change: Sanguine Pact is a new buff, claimed by Bloodmage (Transfusion) —
**settled, not yet implemented** (section 9.4). Keen Edge and Lethal Precision stay claimed solely
by Appraiser (Full Appraisal), re-authored as consigned applier-scaled grants — **settled, not yet
implemented** (section 9.5); no other skill in the corpus applies either.

**Unclaimed inventory**, as of this review — "unclaimed" means *nothing in the game applies it*.
Refresh in the same edit that lands a batch.

* **No source — debuffs:** Slow, Blind, Sequence Lock, Fatigue, Refracted. Stun only via the
  ownerless Weight of Law zone (section 10.3) and Rush's expiry. Mana Burn joins when 9.4 lands.
* **No source — buffs:** True Aim, Clarity, Insight, Mirror Coat, Rehearsed, Wanderlust, Overflow;
  Phalanx Guard joins when 9.11 lands.
  Turn bar buffs Anchor, Steadfast, Resonance are listed above.
* **Enemy-only:** Frenzy, Haste, Deathward.
* **Trait code only, never a skill:** Empower (Plan; Tidal Corsair's Corsair's Reckoning becomes a
  second claimant and its first skill source when 9.13 lands, within the commodity-buff limit of
  two), Attune (Chosen Vessel), Expose Weakness
  (Calibration — magnitude becomes charge-scaled, §9.10), Cracked Facet (Strike the Flaw, retiring
  in 9.5). Phalanx Guard leaves this list for the unclaimed buffs when 9.11 lands — Reckless
  Momentum, its only source, retires with the Lancer's passive.

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
| `Devotion` | Cultist (Chosen Vessel) — **settled, not yet implemented** (section 9.8) | Passive counter bucket, permanent per dead Vessel; distinct from the same passive's per-cast `TRAIT_RESOURCE_KEY` bonus so the two multiply |
| `Profane Bolt` | Cultist (Profane Bolt) — **settled, not yet implemented** (section 9.8) | Skill-name bucket, conditional on the Vessel being below half Health |
| `Rending Charge` | Lancer (Rending Charge) — **settled, not yet implemented** (section 9.11) | Skill-name bucket, `bonus_per` keyed to the turn-bar section span the charge touches |
| `Heap On (ramp)` | Bar Brawler (Heap On) | Skill-name bucket, per-instance ramp (not a stacking cap) |
| `Final Calculation` | Architect (Final Calculation) | Skill-name bucket |
| `Corsairs Reckoning` | Tidal Corsair (Corsairs Reckoning) | Skill-name bucket |
| `Outbreak` | Plague Doctor (Outbreak) | Skill-name bucket, `bonus_per` keyed to `Target_Debuff_Count` (Batch 1's new generic trait-count source) |
| `Tithe of Vitality` | Bloodmage (Tithe of Vitality) — **settled, not yet implemented** (section 9.4) | Skill-name bucket, `bonus_per` keyed to `Wounded_Allies` (new Batch 1 trait-count source) |
| `Sanguine Pact` (granted status) | Bloodmage (Transfusion) — **settled, not yet implemented** (section 9.4) | Granted holder-missing-Health damage multiplier; lands in whoever holds it, not the caster's own bucket |
| `Sanction` (debuff on target) | Emissary (Levied Sanction) — **settled, not yet implemented** (section 9.7) | Debuff-type bucket, per-Infraction damage multiplier snapshotted at application; readable by any teammate's damage, not only the applier's |
| `Hemorrhage` (debuff on target) | Bloodmage (Tithe of Vitality) — **settled, not yet implemented** (section 9.4) | Debuff-type bucket, holder-missing-Health damage multiplier; readable by any teammate's damage, not only the applier's |

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
| Weight of Law | **Orphaned — no player or enemy fields it** |

Six player-facing zones across five Roles, Chronophage holding two — the one existing exception to
the one-per-Role rule, and consistent with its turn-bar identity. Weight of Law having no owner at
all is a loose end this plan did not create and does not close; note it for whichever batch takes
Emissary, whose theme it matches.

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

**Open gap, found while settling Batch 3.** The scorer models no defence ignore: it mitigates every
candidate against the boss's full Defence, so a skill that halves the mitigation term scores
identically to one that does not. Phase 0 made that term a real lever again and §9.12's whole
declared contribution runs through it, as does §9.10's Expose Weakness. The burst skill's mitigation
needs the same effective-Defence computation `battle_resolver.gd` performs, base-referenced
subtraction included.

**Consequence for measurement.** `total_contrast_ratio` stays the pure single-action figure the
30-50x burst-band target is checked against; `combined_contrast_ratio` is the separate figure
`Best()` and the sweep's top-decile selection actually rank by, sustained payload included. Reading
`total_contrast_ratio` alone for a sustained-heavy kit understates its actual standing in the
roster — `Tests/manual/team_corpus_sweep.gd`'s top-decile report prints both, plus a
`sustained_driven` flag per row, so which figure moved is visible rather than conflated.

## 12. Roster-wide mechanics changes awaiting implementation

Changes a settled kit depends on that are **not** that kit's content — they alter shared mechanics
every Role touches. `Concept_Document.md` stays the authority, but it describes the game as it
runs, so nothing here is promoted into it until the change ships. This section owns each one
meanwhile, and the kit entry that produced it links here rather than restating it. Delete an entry
in the same edit that promotes it.

| Change | Today | Becomes | Promotes to | From |
|---|---|---|---|---|
| **Luck and Hexed's reach** | The critical-chance roll and the debuff-resist contest only | Every chance roll in combat except the damage-variance roll (a 0.95-1.05 band is too narrow for a reroll to matter), so a roll added later is covered without a further decision | 3.2.3 | §9.6 |
| **Debuff-resist contest band** | 0.95-1.0 | 0.85-1.0. In the old 5%-wide band, taking the worse of two rolls moved the outcome about 2 percentage points of the stat, leaving Hexed's resistance clause nearly inert; at 0.85-1.0 a reroll is worth roughly 5 points of effective Accuracy or Resistance. 3.2.1 #3's "no base chance and no floor or ceiling" still holds, and a large stat gap still settles the contest outright | 3.2.1 #3 | §9.6 |
| **Burning's tick** | Flat 4% of max Health per stack | A rolled 2-10% (mean 6%) per stack, biased by the holder's Luck or Hexed. Every source, Lava Zone included — Burning stays a shared commodity debuff | 3.2.3 | §9.6 |
| **Confound's magnitude** | -30% Knowledge | -50% Knowledge, so Scholar's Expose Fallacy gains the same increase. Knowledge halves crit damage (3.2.1 #4) and nothing in the roster attacked that term before | 3.2.3 | §9.5 |
