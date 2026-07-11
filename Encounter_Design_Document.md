# Encounter Design Document

The catalog of battle encounter content: enemy families, encounter entries, and
opponent skills. Subordinate to `Concept_Document.md` — the Concept Document owns
the tier definitions (section 5), the two combat types (3.2), and the shared status
effect catalog (3.2.3); if the documents disagree, the Concept Document wins.

How content is produced: `Plans/Plan_Encounter_Solution_Design.md` (tier rules,
volume targets, overlap tolerance, entry template, theme palette, coverage ledger,
per-batch procedure). Encounters are designed progression- and content-agnostic;
themes are optional tags and placement into game modes happens in a later pass.

## 1. Opponent skills

Skills authored for enemies. Any status effect referenced here must exist in the
Concept Document 3.2.3 catalog.

* Break Guard
    * Type: Damage, Debuff
    * Cooldown: 2 turns
    * Effect: A blunt tackle dealing Physical Damage to a single target, scaling
      with Attack, and applies the Expose Weakness debuff for 2 turns (see
      Concept Document 3.2.3.2).
* Wind the Mainspring
    * Type: Damage, Buff (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Speed,
      and the user gains the Haste buff for 2 turns (see Concept Document
      3.2.3.2; Haste stacks, so an uninterrupted user ramps steadily faster).
* Overwhelming Blow
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: Deals massive Physical Damage to a single target enemy, scaling
      with Attack (starting point: 250% of a basic hit).
* Sporeburst Mend
    * Type: Heal (basic skill, no cooldown)
    * Effect: Restores Health to all allies, scaling with the user's Mysticism
      (starting point: 8% of each ally's max Health at expected power).
* Rally the Crew
    * Type: Buff (basic skill, no cooldown)
    * Effect: Grants one other ally the Empower buff for 2 turns (see Concept
      Document 3.2.3.2).
* March Cadence
    * Type: Buff, Turn Bar (basic skill, no cooldown)
    * Effect: All other allies gain 10% turn bar progress.
* Aimed Shot
    * Type: Damage
    * Cooldown: 2 turns
    * Effect: Deals heavy Physical Damage to the most injured enemy, scaling
      with Attack (starting point: 200% of a basic hit).
* Flank Cut
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to the right-most enemy (positional
      targeting, see Concept Document 3.2.4), scaling with Attack.
* Breaching Charge
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to the left-most enemy (positional
      targeting, see Concept Document 3.2.4), scaling with Attack; each use
      increases this skill's damage by 15% for the rest of the battle.

## 2. Encounters

Encounter entries per the template in `Plans/Plan_Encounter_Solution_Design.md`,
grouped by tier. Fodder entries use the compact variant. Seeded by the Reanimating
Statues retrofit, then grown per batch.

### 2.1. Fodder

Compact entries: composition, the single mechanic (with onset), and its answers.
Enemies without a listed skill fall back on the universal Stab and Zap (Concept
Document 3.2.4.3).

#### Sporeback Pack

- **Composition:** two Spore Hounds, one Sporeback Matron. **Theme:** Reclaimed
  City.
- **Mechanic:** the Matron's Sporeburst Mend (section 1) heals the whole pack
  every turn while the Hounds attack. Onset: enemy turn 1.
- **Answers:** Blight (e.g. the Plague Doctor's Quarantine Breach) halves the
  healing; Suppress (e.g. the Herald of the loom's Thread Lash) guts its
  Mysticism scaling.

#### Wake Skimmers

- **Composition:** two Skimmer Cutthroats, one Bosun. **Theme:** Pirate Coves.
- **Mechanic:** the Bosun's Rally the Crew (section 1) hands a Cutthroat the
  Empower buff (2 turns) every turn. Onset: enemy turn 1.
- **Answers:** buff-duration stripping (e.g. the Emissary's Signed Writ) shears
  the Empower off; buff theft (the Thief's Pilfer passive) turns it around.

#### Ledger Clerks

- **Composition:** three Warded Clerks. **Theme:** Iron Ledger.
- **Mechanic:** permanently very high Resistance — debuff-reliant teams watch
  everything fizzle. Onset: immediate.
- **Answers:** Unravel (e.g. the Alchemist's Dissolving Agent) opens the
  Resistance; the Signed Writ debuff (e.g. the Emissary's Signed Writ) makes
  debuffs land regardless.

#### Plains Outriders

- **Composition:** two Outrider Lancers, one War Drummer. **Theme:** Caravan
  plains.
- **Mechanic:** the Drummer's March Cadence (section 1) pushes both Lancers 10%
  up the turn bar every turn. Onset: enemy turn 2.
- **Answers:** turn-bar stripping (e.g. the Tidal Corsair's Corsair's Reckoning
  with Sea stacks) claws the tempo back; the Temporal Sinkhole zone (Chronophage)
  bleeds the pushed progress away.

#### Ridge Marksmen

- **Composition:** two Scavenger Skirmishers, one Ridge Marksman. **Theme:**
  Reclaimed City.
- **Mechanic:** the Marksman's Aimed Shot (section 1) fires a heavy hit at the
  most injured champion every other turn. Onset: enemy turn 2.
- **Answers:** Premonition (e.g. the Diviner's Premonition) blanks the shot;
  Barrier (e.g. the Architect's Raise the Frame, the Bloodmage's Transfusion)
  absorbs it.

#### Flank Cutter

- **Composition:** one Flank Cutter (a lone, fast duelist). **Theme:** Pirate
  Coves.
- **Mechanic:** Flank Cut (section 1) — every attack targets the right-most
  champion, absolutely (Spotlight does not redirect it). Onset: enemy turn 1.
- **Answers:** Fortify (e.g. the Warlord's Hold the Line) or Barrier (e.g. the
  Architect's Raise the Frame) hardens the right slot; the free lever is party
  order — put the bruiser on the right.

#### Line Breaker

- **Composition:** one Plains Charger, one Drover. **Theme:** Caravan plains.
  The Drover supplies side pressure with the universal Stab so the player
  cannot pile every defense onto the left slot.
- **Mechanic:** the Charger's Breaching Charge (section 1) hits the left-most
  champion harder with every use. Onset: enemy turn 1, noticeable by turn 3.
- **Answers:** Enfeeble (e.g. the Lancer's Disarm) blunts the ramp; Barrier
  (e.g. the Bloodmage's Transfusion) absorbs the spikes; party order decides
  who takes the charge.

### 2.2. Mini-bosses

The three Reanimating Statues are retrofitted from Concept Document 5.2.2 (the
Gear encounters — their drop-type placement and reward framing stay in the
Concept Document).

#### Reanimating Statues 1 (Boots)

- **Tier:** Mini-boss. **Theme:** Clockwork Spire (order).
- **Enemy composition:** one Reanimating Statue — Boots.
- **Mechanics:** Wind the Mainspring (section 1) — the statue re-applies Haste
  to itself every turn, stacking into an ever-faster attack cadence. Onset:
  noticeable from enemy turn 2, dangerous from enemy turn 4 onward.
- **Intended solutions:** Severance (e.g. the Cultist's Rite of Severance)
  blocks new Haste instances and halts the ramp; buff-duration stripping (e.g.
  the Emissary's Signed Writ) shears stacks off; turn-bar pressure (e.g. the
  Chronophage's Temporal Sinkhole zone, the Bar Brawler's Dead Weight) claws the
  tempo back. Sequence Lock is a natural future answer, but no kit or reagent
  carries it yet (see the coverage ledger in
  `Plans/Plan_Encounter_Solution_Design.md`).
- **Unsolved texture:** the statue's turns arrive faster and faster and the
  fight becomes a race against an accelerating attacker — roughly double length
  with mounting damage taken, but no hard wall.
- **Reward hook (deferred):** currently the Boots gear drop per Concept 5.2.2;
  final hook assigned at placement.

#### Reanimating Statues 2 (Weapons)

- **Tier:** Mini-boss. **Theme:** Clockwork Spire (order).
- **Enemy composition:** one Reanimating Statue — Weapon.
- **Mechanics:** a telegraphed kill-shot cycle — Break Guard softens a target,
  then Overwhelming Blow (both section 1) lands a massive single-target hit
  every few turns. Onset: the first Overwhelming Blow lands around enemy
  turn 2–3.
- **Intended solutions:** Enfeeble (e.g. the Lancer's Disarm) blunts the hit; a
  sustain-side answer — Fortify (e.g. the Warlord's Hold the Line) or Barrier
  (e.g. the Architect's Raise the Frame, the Bloodmage's Transfusion) — absorbs
  it.
- **Unsolved texture:** every cycle threatens to delete one champion; the
  player spends turns healing and re-positioning instead of attacking, dragging
  the fight toward double length with a real risk of losses.
- **Reward hook (deferred):** currently the Weapons gear drop per Concept
  5.2.2; final hook assigned at placement.

#### Reanimating Statues 3 (Off-hands)

- **Tier:** Mini-boss. **Theme:** Clockwork Spire (order).
- **Enemy composition:** one Reanimating Statue — Shield.
- **Mechanics:** extreme Defense — flat attacks barely scratch the statue.
  Onset: immediate, from enemy turn 1.
- **Intended solutions:** Expose Weakness (e.g. the Architect's Final
  Calculation at 4–6 charges) cracks the armor; Burning (e.g. the Jester's
  Burning Bolas) burns a percentage of its Health straight past Defense.
- **Unsolved texture:** a pure slog — chip damage stretches the fight well past
  double length, but the statue's own offense is modest, so unsolved reads slow
  rather than risky.
- **Reward hook (deferred):** currently the Off-hands gear drop per Concept
  5.2.2; final hook assigned at placement.

### 2.3. Bosses

*Empty.*
