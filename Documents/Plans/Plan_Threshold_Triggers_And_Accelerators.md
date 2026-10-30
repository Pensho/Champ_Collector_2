# Plan: Threshold Triggers and Accelerators

Most kits are cast whenever a skill comes off cooldown. The goal is teams that build over several
rounds toward a big payoff, with Enabler Roles opening the target or protecting the engine until it
lands; whole-kit Enablers stay correct. Threshold triggers and accelerators (`Concept_Document.md`
1.1.7) are means to that goal, and a kit changes only when a drafted team shows it must. Design
first, then code.

## Payoff drafts

Best teams at Legendary, against the Role's own basic skill. Sorcerer, Herald, Tidal Corsair and
Plague Doctor are sweep figures on shipped kits; the rest are hand figures pending implementation.
Boss build target is 4-6 rounds; secondary payoffs target 10-15x.

| Payoff | Tier | Build length | Best draft team | Gap |
|---|---|---|---|---|
| Sorcerer | Primary | 6 rounds | 68x with Bloodmage, 35x without | Settled: Echo ladder, Sanguine Pact off Echoes, 28x by hand; awaiting implementation |
| Herald of the Loom | Primary | 4-5 rounds | 53x with Bloodmage, 28x without | Sanguine Pact off Echoes brings it to 29.5x by hand |
| Tidal Corsair | Primary | 4 rounds | 21x | Stacks capped at 3 |
| Cultist | Primary | 2 rounds; Vessel death later | 6x | Settled: 10% drain, Devotion ladder, Rite of Severance's sacrifice; awaiting implementation. Measure the Vessel-killing cast, 17-22x by hand |
| Plague Doctor | Primary | Spread out | 7x per tick action at 6 types | Settled: tick growth, no single payoff; awaiting implementation. With it, about 15x per tick action on average, 32x with Bloodmage and Emissary |
| Architect | Secondary | 5 rounds | 15x, 18x at 12 charges | None; no change |
| Lancer | Secondary | 2-4 rounds, from teammates | 10-11x by hand, 22x on a crit | None; no change |
| Bar Brawler | Secondary | 10 rounds by Heap On | 9-19x by hand | Settled: Bar Fight replaces Headbutt, Liquid Courage cleanses; awaiting implementation |

The Thief is steady damage, not a payoff, and is unchanged.

**Team variety:** 35 of the 36 single-action results at 30x or above include the Bloodmage. Sweep
figures assume its factors at full strength. Check each kit change against this.

**Next:** implement the settled kits, then remeasure with `Tests/manual/team_corpus_sweep.gd`.

**Also settled, for step 4:** the Warlord's Hold the Line and Brace for Impact
(`Role_Kit_Design.md` 9.19), the Sorcerer's ladder (9.3) and Sanguine Pact on Echoes (9.4).

**Clean-up:** settle Concept 1.1.2's "confirmed reachable" against the measured figures;
`Technical_Design_Document.md` 15.5 and 15.6; `Role_Kit_Design.md` 9.11 still lists Sea stacks as
push-back and states magnitude 0.45 where the manifest has 0.54.

## Gap list

Drawn from the `Role_Kit_Design.md` 10.4 ledger and a read of teams from the previous corpus.

**Parts missing or thin.**

- **Threshold triggers:** seven, in six Roles. Two fire automatically (the Sorcerer's Surge,
  the Appraiser's Critical Chance conversion past 100); three are ally missing Health crossing a
  line (the Cultist's Desecrated Blade and Vessel death, the Bloodmage's Tithe of Vitality); the
  Architect's Final Calculation tiers read a charge count; the Chronophage's Borrowed Time reads
  turn-bar position.
- **Accumulators:** nine of twenty Roles own one. Thief, Lancer, Alchemist, Scholar, Diviner,
  Appraiser, Tactician, Jester, Chronophage, Warlord and the ungrafted Symbiote own none; the
  Lancer's payoff reads a positional condition.
- **Debuff density:** fed by fifteen of twenty Roles; read by Thief and Scholar through
  Opportunist and by the Plague Doctor.
- **Tempo accelerators:** Tactician, Symbiote, Chronophage, Tidal Corsair and Caravan Cadence
  speed per-turn and per-cast accumulators: the Sorcerer's Instability, the Bar Brawler's Heap
  On, the Architect's Calibration, and Sea Legs.
- **Ally missing Health:** fed by Symbiote, Cultist, Bloodmage, and the Sorcerer incidentally;
  read by Bloodmage and Cultist.
- **(own) accelerators:** seven of twenty — Emissary (Signed Writ's strip), Sorcerer (reagents),
  Cultist (the Vessel drain), Bloodmage (self-costs), Herald of the Loom (Pull the Thread),
  Architect (Raise the Frame), Plague Doctor (Miasma's forced tick). Each also takes external
  input.
- **Symbiote grafts:** Detritivore holds the pool's only accumulator. Nine of eighteen
  grafts supply no engine part.

**Step properties.**

- **Cash-out timing:** five of twenty Roles — Sorcerer, Cultist (Devour Blessing), Herald of the
  Loom (Cut the Cloth), Architect (Final Calculation), Tidal Corsair (Corsair's Reckoning).
- **Interruptible build-up:** opponent actions reach only what a payoff reads (debuffs, buffs,
  turn-bar position, zone sections); none reaches an accumulator itself.
- **The two-property guidance:** every corpus team meets it, the three Control teams included.
  Ordering and Interruptible build-up come with any payoff that reads a status, and the Appraiser,
  Chronophage, Warlord team meets it with no accumulator at all.

**Only a single-snapshot factor:** Tactician (Daunting Strength).

**Full passes:** Jester, Diviner and Warlord, Enabler identities supplying Protector parts.

**Team read**, Symbiote ungrafted. A part counts only when the team holds what it feeds or reads.

| Team | Tier | Linked accumulators | Threshold triggers | Step properties |
|---|---|---|---|---|
| Sorcerer, Scholar, Tactician | Intent | Instability, fed by the Tactician's tempo; debuff density, from Sorcerer and Scholar, read by Opportunist | Surge | Ordering, Cash-out timing, Interruptible, External input |
| Tidal Corsair, Cultist, Warlord | Intent | Steel and Sea, Sea Legs, fed by the Corsair's Haste; Devotion and the Vessel's missing Health; buffs on one ally, from Fortify, Haste and Slipstream, read by Devour Blessing | Desecrated Blade, Vessel death | all four |
| Bar Brawler, Tactician, Tidal Corsair | Intent | Heap On, Steel and Sea, Sea Legs, all fed by tempo | — | all four |
| Symbiote, Tactician, Tidal Corsair | Intent | Steel and Sea, Sea Legs, fed by tempo | — | all four |
| Scholar, Chronophage, Symbiote | Control | debuff density, from the Scholar alone | Borrowed Time | Ordering, Interruptible, External input |
| Alchemist, Scholar, Chronophage | Control | debuff density, from Alchemist and Scholar | Borrowed Time | Ordering, Interruptible, External input |
| Appraiser, Chronophage, Warlord | Control | — | Critical Chance conversion, Borrowed Time | Ordering, Interruptible |

- **Accelerators left without a target:** debuff density with no reader (teams 2, 3, 7);
  reagent-fed (team 6); ally missing Health (teams 1, 4, 5).
- **Devour Blessing consumes permanent buffs,** so in team 2 the Cultist spends the Tidal
  Corsair's Sea Legs; Shield Wall diverts damage off a nearby Vessel and slows the Cultist's
  thresholds.

## Design constraints

- Adapt existing kits with the smallest change that closes a gap; a replacement skill or
  passive is the exception and is justified per Role.
- The per-Role contribution target in `Role_Kit_Design.md` section 4 holds; no Role is
  required to become an engine piece.
- Coupling stays indirect (`Role_Kit_Design.md` section 2): a threshold reads a mechanic class,
  and an accelerator feeds a mechanic class, never a named Role or skill.
- Concept 1.1.4 governs: a threshold whose payoff feeds its own accumulator is re-entry; a
  trigger fires once per originating action; automatic accrual follows its stack-ceiling rule.
- An accumulator held as a status takes one of the eight status slots; prefer a trait resource
  unless the slot cost is the point.
- New sources interact with existing readers uniformly; no carve-outs for player sources.
- Accelerators for build-specific effects are applied deliberately, not by positional or
  automatic triggers.
- Stun- and Fatigue-class denial, and new Accuracy pressure, stay off the table.

## Brainstorm rules

Candidates are prompted with the constraints above and the gap list, never with example
mechanics. A threshold candidate states: the condition it reads, how the player sees progress
toward it, who can feed it, and whether firing is automatic or the player's call. Candidates
in one batch differ in the quantity the condition reads and in the channel the payoff lands
in. Rejected shapes:

- A threshold that fires on a fixed turn count with no player influence on timing.
- A condition only one Role can satisfy.
- An accelerator whose best case is a linear rate increase on a single source, failing 1.1.6.

## Steps

### 1. Settle the vocabulary — done
Decide with the user whether 1.1.7's parts become tags on kit entries alongside the channel
tags in Concept 1.1.3, or stay ledger-only in `Role_Kit_Design.md` 10.4. Decided: ledger-only,
and 1.1.7's accelerator and threshold definitions widened to match 10.4.

### 2. Design batches — done
One `/brainstorm` per Role, stating the observed problem, whether the Role must change, whether the
change is a new skill, a replacement or an amendment, and its before and after text. The user picks; accepted
designs are written into Concept 3.1.3 / 3.2.4.2 and the Role's `Role_Kit_Design.md` section 9
entry in the same edit, and the 10.4 ledger row is updated.

### 3. Technical design
Read `Technical_Design_Document.md` 7.8 (cascade resolution) and 9 (trait hooks) and decide
where a threshold lives: a trait hook, a cascade source, or a new resolver concept. Record the
decision in the Technical Design Document before implementing.

### 4. Implement per batch
Per accepted batch: data and scripts, a `KitContributionManifest` entry per changed kit, and
GUT tests for the threshold logic (condition met, fires once, respects caps, no re-entry). Lint
and run the suite after each Role.

### 5. Measure
Re-run burst reachability and, once `Plan_Engine_Build_Step_Metric.md` has shipped, the
build-step readout over the affected corpus teams; record the movement in
`Role_Kit_Design.md` section 4.

## Watch for
- Readability: a threshold whose progress the player cannot see breaks 1.1.7's guidance.
- A threshold that fires off the opponent's actions hands the engine's timing to the
  opponent; that is a lock surface (Concept 1.2), and is a choice, not a default.
- Coarse balancing: get the shape right; tune after playtests.

## Documentation
Concept 3.1.3, 3.2.4.2 (and 3.2.3 for any new status); `Role_Kit_Design.md` sections 4, 9,
10.4; `Technical_Design_Document.md` per step 3 and 7.10 for manifest changes.
