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
* Cinder Spit
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with
      Mysticism.
* Cinder Sermon
    * Type: Damage (AoE)
    * Cooldown: 2 turns
    * Effect: Deals Magical Damage to all enemies, scaling with Mysticism
      (starting point: 90% of a standard hit); each cast is permanently 20
      percentage points stronger than the last for the rest of the battle.
* Ash Offering
    * Type: Passive
    * Effect: When an ally Cinder Husk dies, the user's next Cinder Sermon
      deals +40% damage. Multiple deaths stack; the bonus is consumed by that
      one Sermon.
* Inscribe
    * Type: Damage, Turn Bar (Zone) (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with
      Mysticism, and places a Wild Glyph zone (unstable family) in the
      left-most empty turn bar section, if any. Affected enemies take Magical
      Damage scaling with the placer's Mysticism (starting point: 40% of a
      standard hit) and gain the Warped debuff for 2 turns (see Concept
      Document 3.2.3.2). Holds 3 charges.
* Inscription Surge
    * Type: Damage (AoE)
    * Cooldown: 3 turns
    * Effect: Deals Magical Damage to all enemies, scaling with Mysticism
      (starting point: 80% of a standard hit), increased by 30% per zone
      standing on the turn bar — regardless of who placed it.
* Foreclosure
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with
      Attack, increased by 20% per buff the user holds.
* Lien
    * Type: Passive
    * Effect: At the start of the user's turn, if the user holds no buffs,
      they gain the Empower buff for 2 turns (see Concept Document 3.2.3.2).
      Triggers at most once every 4 turns.
* Writ of Seizure
    * Type: Buff theft (basic skill, no cooldown), Damage
    * Effect: Steals one buff from a random enemy: the buff is removed and
      applied to the user's designated ward (stated per encounter) with a
      fresh 2-turn duration. Deals Magical
      Damage, scaling with Knowledge.
* Reliquary Ward
    * Type: Buff (basic skill, no cooldown)
    * Effect: Grants one ally a protection, alternating with each use: odd
      uses grant a Barrier absorbing 60% of that ally's max Health for
      2 turns; even uses grant the Deathward buff for 2 turns (see Concept
      Document 3.2.3.2).
* Vault Slam
    * Type: Damage, Debuff (Turn Bar)
    * Cooldown: 3 turns
    * Effect: Deals heavy Physical Damage to a single enemy, scaling with
      Attack (starting point: 220% of a basic hit), and applies the Dead
      Weight debuff for 2 turns (see Concept Document 3.2.3.1).
* Warden's Failsafe
    * Type: Passive
    * Effect: When an ally dies, the user gains the Frenzy buff for the rest
      of the battle (see Concept Document 3.2.3.2).

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

#### The Ashen Oracle

- **Tier:** Mini-boss. **Theme:** Ruins of the God of Magic (unstable).
- **Enemy composition:** the Ashen Oracle; two Cinder Husks — fragile melee
  bodies (universal Stab, dying to roughly two hits) whose mechanical reason
  is Ash Offering fuel: their deaths feed the Sermon.
- **Mechanics:** Cinder Sermon (section 1) — an escalating AoE wave every
  other turn; onset: first cast on enemy turn 2, dangerous from around turn 6.
  Ash Offering (section 1, passive) — a dead Cinder Husk supercharges the next
  Sermon, so careless AoE accelerates the very mechanic the player is racing;
  onset: immediate once a Husk drops. The Oracle's passive is not readable in
  battle (Concept Document 3.2) — the player learns it by watching a Husk
  death detonate.
- **Intended solutions:** Suppress (e.g. the Herald of the loom's Thread Lash)
  guts the Mysticism scaling for 2 of every 3 turns; Mana Burn (e.g. the
  Bloodmage's Tithe of Vitality) bleeds the Oracle for every Sermon cast;
  Hexed (e.g. the Diviner's Ill Omen) forces the Sermon to roll twice and take
  the worse result. Play-pattern lever for any roster: leave the Husks alive
  and tunnel the Oracle.
- **Unsolved texture:** a bloody race against rising waves — roughly double
  length with heavy incidental damage, but no hard wall.
- **Reward hook (deferred):** assigned at placement.

#### Reanimating Statues 1 (Boots)

- **Tier:** Mini-boss.
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

- **Tier:** Mini-boss.
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

- **Tier:** Mini-boss.
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

#### The Glyphbound Archivist

- **Tier:** Boss, full mechanical weight. **Theme:** Ruins of the God of Magic
  (unstable).
- **Enemy composition:** the Glyphbound Archivist alone — it is the zone
  engine, and a second body would dilute the bar pressure.
- **Mechanics:** Inscribe (section 1) — every turn the Archivist attacks and
  writes a Wild Glyph zone into the left-most empty turn bar section (3
  charges; Magical Damage plus Warped for 2 turns on affected champions).
  Onset: enemy turn 1. Because occupied sections cannot be targeted (Concept
  Document 3.2.4.1), an uncontested Archivist also progressively locks the
  player out of their own zone play. Inscription Surge (section 1) — an AoE
  that grows 30% stronger per zone standing on the bar, regardless of who
  placed it, so the player's own zones feed it equally. Onset: first cast on
  enemy turn 4, then every 3rd turn; a wall from roughly turn 8 if the bar
  stays full.
- **Intended solutions (configurations):** (1) the Scholar — Refutation
  removes a glyph every 3 turns and punishes the Archivist per remaining
  charge; (2) the reagent configuration — up to 3 Zone-Dissolving Salts,
  spent just before Surges; (3) charge-burn sustain — a durable front (e.g.
  the Warlord's Hold the Line, the Bar Brawler's bulk and healing)
  deliberately walks glyphs to drain their 3 charges between Surges, keeping
  the standing count low. Contesting sections with the player's own zones
  denies glyph slots but feeds the Surge exactly as much — a trade, not an
  answer.
- **Unsolved texture:** hard wall. The bar fills by turn 5, the player's zone
  skills go dark, and Surges compound past survivable. A zone-reliant roster
  with no clearing is the worst roster here.
- **Reward hook (deferred):** assigned at placement.

#### The Collector of Debts

- **Tier:** Boss, full mechanical weight. **Theme:** Iron Ledger (order).
- **Enemy composition:** the Collector of Debts; one Warded Notary — its
  mechanical reason is running the seizure paperwork (Writ of Seizure, with
  the Collector as its designated ward) while the Collector fights. Killing
  the Notary stops the theft but leaves the Lien self-funding, so kill order
  is a real decision. The Collector's high Resistance is a natural attribute,
  not a mechanic (echoing the Warded Clerks fodder so knowledge transfers).
- **Mechanics:** Writ of Seizure (Notary, section 1) — steals one champion
  buff to the Collector each turn with a fresh 2-turn duration. Onset: enemy
  turn 1. Foreclosure (Collector, section 1) — the Collector's attack deals
  +20% per buff it holds. Onset: bites from around turn 3 as seized buffs
  stack. Lien (Collector passive, section 1) — an unbuffed Collector grants
  itself Empower for 2 turns, at most once every 4 turns, so a buffless
  roster never disarms the fight by accident. Onset: enemy turn 2. Per
  Concept Document 3.2 the passive is learned by observation.
- **Intended solutions (configurations):** (1) the Cultist buff economy —
  Devour Blessing spends the party's buffs before they can be seized, and
  buff-light play starves the Writ, leaving only the slow Lien drip to
  manage; (2) buff repossession — the Emissary's Signed Writ shears the
  Collector's stacked durations, the Thief's Pilfer steals them back;
  (3) the reagent configuration — tinctures and the Fractured Idol are
  explicitly not buffs (undispellable, invisible to buff counting), so a
  reagent-powered roster fights at full strength with nothing to seize; the
  Sorcerer's Arcane Instability amplifies them and makes it the natural
  carrier.
- **Unsolved texture:** hard wall for buff-reliant rosters — by turn 5 the
  Collector holds 3–4 stolen buffs and Foreclosure starts deleting champions.
- **Reward hook (deferred):** assigned at placement.

#### The Warden of the Reliquary

- **Tier:** Boss, full mechanical weight. **Theme:** Clockwork Spire (order).
- **Enemy composition:** the Vault Warden — a modest Health pool of its own
  (starting point: a standard champion's expected Health); the Reliquary
  Core — no attacks, very high Health and Defense (starting point: 3× a
  champion's expected Health). The Core's mechanical reason: it is the lock —
  every protection the Warden survives behind flows from it.
- **Mechanics:** Reliquary Ward (Core, section 1) — alternates a large
  Barrier (60% of the Warden's max Health, 2 turns) and Deathward (2 turns)
  onto the Warden. Onset: enemy turn 1 — the Warden is never unprotected
  unless the player intervenes. Vault Slam (Warden, section 1) — a 220% hit
  applying Dead Weight for 2 turns, dragging the soaker down the turn bar.
  Onset: enemy turn 2. Mitigated by Enfeeble (e.g. the Lancer's Disarm) or a
  Barrier (e.g. the Bloodmage's Transfusion, the Architect's Raise the
  Frame). Warden's Failsafe (Warden passive, section 1) — when
  the Core dies, the Warden gains Frenzy for the rest of the battle; tunneling
  the Core is the viable brute-force route (the over-leveled path), but it is
  slow and punished.
- **Intended solutions (configurations):** (1) the Cultist — Rite of
  Severance blocks new protections for 2 of every 4 turns, opening kill
  windows on the Warden; (2) the Emissary — Signed Writ shears the
  protections' durations so they fall off before they matter; (3) the burst
  window — the Tactician (Daunting Strength) plus the Appraiser (Full
  Appraisal: Keen Edge and Lethal Precision) stack one crit round that breaks
  the Barrier, kills into the Deathward, and finishes the 1-Health Warden in
  the same round.
- **Unsolved texture:** hard wall — chip damage dies on fresh protections
  while Vault Slams grind the party backward down the bar.
- **Reward hook (deferred):** assigned at placement.
