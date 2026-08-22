# Relic Design

The Relic contract — item type, rarity ladder, conditional upside, always-on drawback — is
`Concept_Document.md` section 3.3.1.

**Design pillar.** A Relic should change how a player thinks about using a skill or a team composition in turn for giving out a significant but most often conditional upside.

Each entry names its Role audience: the Role that meets the condition best and most often. No
entry requires that Role, except where marked.

Entries are grouped by what the upside pays out in. Slot is assigned per entry once the catalog is
broad enough to fill each slot deliberately; no entry carries one yet.

## Damage

### The Long Furrow

*Audience: Lancer.* [Channel 3 — Cascade]  hooks `OnSkillCast`, `OnSkillEffectsResolved`

Rending Charge cast at 4 or 5 sections of turn-bar distance resolves a second time, at
25 / 30 / 35 / 45 / 55% strength.

**Drawback:** Rending Charge can never critically hit.

The catalog's one exception to the mechanic-vocabulary rule: it reads a named skill.

### Vein-Split Athame

*Audience: Bloodmage.* [Channel 2]  hooks `OnSkillCast`, `GetOutgoingDamageBonus`

While below 50% of max Health, damaging skills deal +15 / 18 / 22 / 28 / 35% damage.

**Drawback:** healing and Barriers the wearer creates are reduced by 60%.

### Draught-Fed Edge

*Audience: Sorcerer, Alchemist.* [Channel 2]  hook `OnReagentConsumed`

The first damaging skill cast after consuming a reagent deals +25 / 30 / 35 / 45 / 60% damage.

**Drawback:** reagents the wearer consumes have 40% less effect.

### Threefold Bite

*Audience: Herald of the Loom, Plague Doctor, Sorcerer.* [Channel 3 — Cascade]  hook
`OnCascadeInstanceResolved`

Every third cascade instance a single action produces deals +60 / 80 / 100 / 130 / 170% damage.

**Drawback:** damage that is not a cascade instance is reduced by 30%.

### The Closed Wound

*Audience: Bloodmage, Cultist.* [Channel 2]  hook `GetOutgoingDamageBonus`

Damaging skills deal +25 / 30 / 35 / 45 / 60% damage.

**Compositional drawback:** healing received by anyone on the wearer's team, from any source, is
reduced by 80%.

### The Set Watch

*Audience: Warlord, Bar Brawler, Symbiote.* [Channel 2]  hooks `OnDamageTaken`,
`GetOutgoingDamageBonus`

After the wearer takes a single hit exceeding 15% of their max Health, their next damaging skill
deals +30 / 35 / 40 / 50 / 65% damage.

**Drawback:** enemies target the wearer at 1.5x weight, permanently.

### Lantern of the Standing Ward

*Audience: Chronophage, Architect, Plague Doctor, Tidal Corsair.* [Channel 3 — Cascade]  hook
`OnZoneUsed`

The first charge each zone the wearer places spends resolves its `on_trigger` payload a second
time, at 40 / 45 / 50 / 60 / 75% strength. That zone's remaining charges resolve once.

**Compositional drawback:** every reagent consumed by anyone on the wearer's team has half effect.

### The Answering Boss

*Audience: Warlord, Symbiote, Bar Brawler, Bloodmage.* [Channel 2]  hooks `OnBuffGained`,
`GetOutgoingDamageBonus`

While the wearer holds a Barrier, damaging skills deal +25 / 30 / 35 / 45 / 60% damage.

**Drawback:** the wearer's max Health is reduced by 30%.

### The Sealed Docket

*Audience: Emissary, Scholar, Diviner.* [Channel 2]  hook
`GetOutgoingDamageBonus`

While the target carries four or more distinct debuff types, damaging skills deal
+35 / 42 / 50 / 62 / 80% damage.

**Compositional drawback:** cascade instances produced by anyone on the wearer's team resolve at
half strength.

### The Unguarded Glass

*Audience: Thief, Tidal Corsair, Lancer.* [Channel 2 — crit path]  hooks `OnBuffGained`,
`OnCriticalHit`

While the wearer holds a buff granted by an ally, critical hits deal +25 / 30 / 35 / 45 / 60%
Critical Damage.

**Drawback:** the wearer can hold at most one buff at a time — a new buff replaces the one they
hold.

### The Ossuary Ledger

*Audience: Cultist, Bloodmage, Jester.* [Channel 2]  hook `OnAllyDeath`

When an ally dies, the wearer deals +25 / 30 / 35 / 45 / 60% damage for the rest of the battle.

**Drawback:** the wearer can never gain a buff, from any source (Severance, permanently).

### The Frayed Hour

*Audience: Herald of the Loom.* [Channel 2]  hook `GetAppliedStatusValue`

Temporal Leak applied by the wearer has +200 / 250 / 275 / 300 / 350% its effect.

**Compositional drawback:** Barriers on the wearer's team have 25% effect.

## Buff

### The Even Hand

*Audience: Tactician, Scholar, Warlord.* [Enabler]  hooks `OnBuffGained`, `GetAppliedStatusValue`

Buffs the wearer applies are 50 / 55 / 60 / 70 / 85% stronger.

**Compositional drawback:** the wearer's allies cannot critically hit.

## Debuff

### Signatory's Edge

*Audience: Emissary, Plague Doctor, Diviner.* [Enabler]  hook `OnDebuffApplied`

The first 2 / 2 / 3 / 3 / 4 debuffs applied to each enemy in a battle cannot be resisted.

**Drawback:** the wearer cannot resist debuffs (Signed Writ, permanently).

## Sustain

### The Consignment Bond

*Audience: Appraiser, Tactician, Warlord.* [Enabler]  hooks `OnCriticalHit`,
`GetIncomingHealMultiplier`

When an ally holding a buff the wearer applied lands a critical hit, that ally heals for
8 / 10 / 12 / 14 / 17% of the damage dealt.

**Drawback:** the wearer cannot be healed or Barriered by any source.

*Flagged for cut:* a team fielding a dedicated tank pays close to nothing for that drawback, so
the entry needs a cost that bites on any composition before it is final.

### The Quiet Mass

*Audience: Bar Brawler, Bloodmage, Warlord.* [Enabler]  hook `GetAttributeDelta`

Gain 25 / 30 / 35 / 40 / 50% max Health.

**Drawback:** the wearer's targeting weight is multiplied by 0.45 / 0.4 / 0.35 / 0.3 / 0.25.

## Control

### The Long Second

*Audience: Chronophage.* [Enabler]  hook `OnAllyTurnBarIncreased`

Forward turn-bar bumps the wearer grants an ally gain 20 / 25 / 30 / 35 / 45% increased effect.

**Compositional drawback:** buffs placed by the wearer's team have 40% reduced magnitude. A buff
carrying no magnitude keeps its full effect.

## Coverage

Refresh every table below in the same edit that lands a batch. Role names and channel tags follow
`Role_Kit_Design.md` sections 5 and 1.1.3.

**Payout groups:** Damage 12  Buff 1  Debuff 1  Sustain 2  Control 1.

### Role coverage

**Audience** is the entry's own tag. An entry is listed under **Won't wear** when its drawback
cancels a channel that Role's kit depends on, and under **Won't sit beside** when a compositional
drawback does the same to a Role sharing the team. A drawback that only taxes the wearer is not
listed.

| Role | Audience of | Won't wear | Won't sit beside |
|---|---|---|---|
| Alchemist | Draught-Fed Edge | Vein-Split Athame | Lantern of the Standing Ward, The Closed Wound, The Frayed Hour, The Long Second |
| Appraiser | The Consignment Bond | — | The Even Hand |
| Architect | Lantern of the Standing Ward | Vein-Split Athame | The Frayed Hour |
| Bar Brawler | The Set Watch, The Answering Boss, The Quiet Mass | The Ossuary Ledger, The Unguarded Glass, Vein-Split Athame | The Closed Wound, The Long Second |
| Bloodmage | Vein-Split Athame, The Closed Wound, The Answering Boss, The Ossuary Ledger, The Quiet Mass | — | The Frayed Hour |
| Chronophage | Lantern of the Standing Ward, The Long Second | — | The Sealed Docket |
| Cultist | The Closed Wound, The Ossuary Ledger | — | — |
| Diviner | Signatory's Edge, The Sealed Docket | Vein-Split Athame | The Closed Wound |
| Emissary | Signatory's Edge, The Sealed Docket | — | — |
| Herald of the Loom | Threefold Bite, The Frayed Hour | — | The Sealed Docket |
| Jester | The Ossuary Ledger | The Quiet Mass | — |
| Lancer | The Long Furrow, The Unguarded Glass | — | — |
| Plague Doctor | Threefold Bite, Signatory's Edge, Lantern of the Standing Ward | — | The Sealed Docket |
| Scholar | The Even Hand, The Sealed Docket | — | The Long Second |
| Sorcerer | Draught-Fed Edge, Threefold Bite | — | Lantern of the Standing Ward, The Sealed Docket |
| Symbiote | The Set Watch, The Answering Boss | The Ossuary Ledger, The Unguarded Glass | The Long Second |
| Tactician | The Even Hand, The Consignment Bond | — | The Long Second |
| Thief | The Unguarded Glass | — | — |
| Tidal Corsair | Lantern of the Standing Ward, The Unguarded Glass | — | — |
| Warlord | The Even Hand, The Set Watch, The Answering Boss, The Consignment Bond, The Quiet Mass | — | The Long Second |

**Roster-wide deterrents, listed here instead of in every row.** Threefold Bite's −30% on
non-cascade damage rules it out for the sixteen Roles holding no cascade. The Even Hand's
ally-no-crit clause reaches any teammate carrying a crit-path entry, not only Appraiser.

### Channel tally

| Channel | Count | Entries |
|---|---|---|
| Channel 1 | 0 | |
| Channel 2 | 8 | Vein-Split Athame, Draught-Fed Edge, The Closed Wound, The Set Watch, The Answering Boss, The Sealed Docket, The Ossuary Ledger, The Frayed Hour |
| Channel 2 — crit path | 1 | The Unguarded Glass |
| Channel 3 — Cascade | 3 | The Long Furrow, Threefold Bite, Lantern of the Standing Ward |
| Enabler | 5 | Signatory's Edge, The Even Hand, The Consignment Bond, The Quiet Mass, The Long Second |

### Condition surface

What the upside reads. Two entries sharing a surface is a duplication to justify, not a default.

| Surface | Entries |
|---|---|
| Wearer's own Health | Vein-Split Athame (below 50%) |
| Buff or Barrier the wearer holds | The Answering Boss (Barrier), The Unguarded Glass (ally-granted buff) |
| Target's state | The Sealed Docket (4+ distinct debuff types) |
| Resource consumed | Draught-Fed Edge (reagent), Lantern of the Standing Ward (zone charge) |
| Event count within the battle | Threefold Bite (every third cascade instance), Signatory's Edge (first N debuffs per enemy) |
| Incoming event | The Set Watch (hit above 15% max Health), The Ossuary Ledger (ally death) |
| Turn-bar distance | The Long Furrow (4 or 5 sections) |
| Application the wearer makes | The Even Hand (any buff applied), The Frayed Hour (Temporal Leak applied), The Long Second (forward bump granted to an ally) |
| Ally holding the wearer's buff | The Consignment Bond (that ally's critical hits) |
| None — always on | The Closed Wound, The Quiet Mass |

### Hook tally

| Hook | Count | Entries |
|---|---|---|
| `GetOutgoingDamageBonus` | 5 | Vein-Split Athame, The Closed Wound, The Set Watch, The Answering Boss, The Sealed Docket |
| `OnBuffGained` | 3 | The Answering Boss, The Unguarded Glass, The Even Hand |
| `OnSkillCast` | 2 | The Long Furrow, Vein-Split Athame |
| `OnSkillEffectsResolved` | 1 | The Long Furrow |
| `OnReagentConsumed` | 1 | Draught-Fed Edge |
| `OnCascadeInstanceResolved` | 1 | Threefold Bite |
| `OnDamageTaken` | 1 | The Set Watch |
| `OnZoneUsed` | 1 | Lantern of the Standing Ward |
| `OnCriticalHit` | 2 | The Unguarded Glass, The Consignment Bond |
| `OnAllyDeath` | 1 | The Ossuary Ledger |
| `OnDebuffApplied` | 1 | Signatory's Edge |
| `GetAppliedStatusValue` | 2 | The Even Hand, The Frayed Hour |
| `GetIncomingHealMultiplier` | 1 | The Consignment Bond |
| `GetAttributeDelta` | 1 | The Quiet Mass |
| `OnAllyTurnBarIncreased` | 1 | The Long Second |
| `StartOfTurn` | 0 | — |
| `EndOfTurn` | 0 | — |
| `OnKill` | 0 | — |
| `OnDeath` | 0 | — |
| `OnDefend` | 0 | — |
| `OnDebuffReceived` | 0 | — |
| `OnAllyDamageTaken` | 0 | — |
| `OnEnemyTurnBarReduced` | 0 | — |
| `OnZoneConstructed` | 0 | — |
| `OnAffectedByZone` | 0 | — |

### Status and mechanic surface

| Status or mechanic | Direction | Entries |
|---|---|---|
| Signed Writ | applied to wearer | Signatory's Edge |
| Severance | applied to wearer | The Ossuary Ledger |
| Buffs (held) | read | The Answering Boss, The Unguarded Glass |
| Buffs (applied) | amplified / suppressed | The Even Hand / The Long Second (magnitude only) |
| Buffs (denied) | suppressed | The Ossuary Ledger, The Unguarded Glass |
| Debuff resistance | bypassed on the target, removed on the wearer | Signatory's Edge |
| Distinct debuff types | read | The Sealed Docket |
| Reagents | suppressed | Draught-Fed Edge (wearer), Lantern of the Standing Ward (team) |
| Cascade instances | amplified / suppressed | Threefold Bite, Lantern of the Standing Ward, The Long Furrow / The Sealed Docket |
| Healing and Barriers | granted / suppressed | The Consignment Bond (to a buffed ally) / Vein-Split Athame (created), The Closed Wound (received), The Consignment Bond (wearer), The Frayed Hour (Barriers, team) |
| Critical hits | amplified / denied / read | The Unguarded Glass / The Long Furrow, The Even Hand / The Consignment Bond |
| Enemy targeting weight | raised / lowered | The Set Watch / The Quiet Mass |
| Max Health | raised / reduced | The Quiet Mass / The Answering Boss |
| Temporal Leak | amplified | The Frayed Hour |
| Turn-bar bumps (forward, ally) | amplified | The Long Second |

Signed Writ and Severance are on `Role_Kit_Design.md` section 10.1's *unclaimed by policy* list.
They are admissible here only because they land on the wearer as the fixed cost — no entry aims a
policy-locked status at an enemy.
