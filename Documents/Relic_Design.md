# Relic Design

The Relic contract — item type, rarity ladder, unique effect, drawback — is
`Concept_Document.md` section 3.3.1.

**Design pillar.** A Relic should change how a player thinks about using a skill or a team composition in turn for giving out a significant but most often conditional upside.

Each entry names its Role audience: the Roles that could choose to wear it for benefit, read off the
kits that can meet the condition rather than the Role that produces it. No entry requires one of
them, except where marked.

**Drawbacks.** A **drawback** lands on the wearer and costs them on every composition. A
**compositional drawback** lands on who can be fielded beside the wearer, and is priced by how
attractive the composition it forecloses is — foreclosing options is the category's purpose, so a
cost taxing a channel the wearer's own Role uses belongs to the first category, not this one. Only a
narrow audience makes an exclusion priceable. The two stay separate on any one entry: a compositional
drawback that is too light is strengthened by deepening the exclusion, a tax on the excluded Roles
becoming a flat denial, never by adding a cost to the wearer.

**Magnitude** sits in the band the catalog already uses for that payout and channel — a channel-2
damage multiplier reaches +60% at Legendary. An entry above the band carries a correspondingly
harder condition or drawback.

An equipped item is a cheap source, so Fatigue and Stun-class denial rides one only with a severe
drawback attached.

Entries are grouped by what the upside pays out in, and each carries one of the three live slots —
Weapon, Off-Hand, Boots. Slot is the stacking control: see *Slots and stacking* below.

## Damage

### The Long Furrow

*Audience: Lancer.* **Weapon.** [Channel 3 — Cascade]  hook `OnSkillCast`

Rending Charge cast at 4 or 5 sections of turn-bar distance Echoes once, at
25 / 30 / 35 / 45 / 55% strength.

**Drawback:** Rending Charge can never critically hit.

The catalog's one exception to the mechanic-vocabulary rule: it reads a named skill.

### Draught-Fed Edge

*Audience: Sorcerer, Alchemist.* **Weapon.** [Channel 2]  hook `OnReagentConsumed`

The first damaging skill cast after consuming a reagent deals +25 / 30 / 35 / 45 / 60% damage.

**Drawback:** reagents the wearer consumes have 40% less effect.

### Threefold Bite

*Audience: Herald of the Loom, Plague Doctor, Sorcerer.* **Weapon.** [Channel 3 — Cascade]  hook
`GetOutgoingDamageBonus`

Every third Echo a single action produces deals +60 / 80 / 100 / 130 / 170% damage.

**Drawback:** damage that is not an Echo is reduced by 30%.

### The Closed Wound

*Audience: Bloodmage, Cultist.* **Off-Hand.** [Channel 2]  hook `GetOutgoingDamageBonus`

Damaging skills deal +25 / 30 / 35 / 45 / 60% damage.

**Compositional drawback:** no one on the wearer's team can be healed, by any source.

### The Planted Heel

*Audience: Warlord, Bar Brawler, Symbiote.* **Boots.** [Channel 2]  hook `OnSkillCast`

After the wearer takes a single hit exceeding 15% of their max Health, their next damaging skill
deals +30 / 35 / 40 / 50 / 65% damage.

**Drawback:** enemies target the wearer at 1.5x weight, permanently.

### Lantern of the Standing Ward

*Audience: Chronophage, Architect, Plague Doctor, Tidal Corsair.* **Off-Hand.** [Channel 3 — Cascade]  hook
`OnZoneConstructed`, `OnZoneUsed`

Each zone the wearer places Echoes once for the first charge spent, at
40 / 45 / 50 / 60 / 75% strength.

**Compositional drawback:** every reagent consumed by anyone on the wearer's team has half effect.

### The Answering Boss

*Audience: Warlord, Symbiote, Bar Brawler.* **Off-Hand.** [Channel 2]  hook `GetOutgoingDamageBonus`

While the wearer holds a Barrier, damaging skills deal +25 / 30 / 35 / 45 / 60% damage.

**Drawback:** the wearer's max Health is reduced by 30%.

### The Sealed Docket

*Audience: Architect, Diviner, Emissary, Lancer, Tidal Corsair.* **Off-Hand.** [Channel 2]  hooks
`GetOutgoingDamageBonus`, `Start_Combat`

While the target carries four or more distinct debuff types, damaging skills deal
+35 / 42 / 50 / 62 / 80% damage.

**Compositional drawback:** Echoes produced by anyone on the wearer's team resolve at
half strength.

### The Unguarded Glass

*Audience: Thief, Tidal Corsair, Lancer.* **Off-Hand.** [Channel 2 — crit path]  hooks `OnBuffGained`,
`OnCriticalHit`

While the wearer holds a buff granted by an ally, critical hits deal +35 / 45 / 55 / 70 / 80%
Critical Damage.

**Drawback:** the wearer can hold at most one buff at a time — a new buff replaces the one they
hold.

### The Ossuary Ledger

*Audience: Cultist, Bloodmage, Jester.* **Off-Hand.** [Channel 2]  hook `OnAllyDeath`

When an ally dies, the wearer deals +25 / 30 / 35 / 45 / 60% damage for the rest of the battle.

**Drawback:** the wearer can never gain a buff, from any source (Severance, permanently).

### The Frayed Hour

*Audience: Herald of the Loom.* **Boots.** [Channel 2]  hook `GetAppliedStatusValue`

Temporal Leak applied by the wearer has +200 / 250 / 275 / 300 / 350% its effect.

**Compositional drawback:** Barriers on the wearer's team have 25% effect.

### Kiln Brand

*Audience: Tidal Corsair, Thief.* **Weapon.** [Channel 2]  hook `OnSkillCast`

Skills carrying a cooldown deal +20 / 30 / 40 / 50 / 65% damage.

**Drawback:** the wearer's damaging skills that can apply a debuff deal 40% less damage.

### Sunderplate Nail

*Audience: Thief, Lancer, Bloodmage.* **Weapon.** [Channel 1]  hooks `GetOutgoingDefenceIgnoreFactor`,
`OnBuffGained`

The wearer's damaging skills treat the target's Defence as 18 / 20 / 23 / 27 / 32% lower.

**Compositional drawback:** the wearer loses 10% of their max Health whenever they gain a buff.

The multiplicative lever, never the wearer's base ignore rate: a rate belongs to the Thief's
Between the Plates, and granting one both hands out that Role's identity and multiplies into
Pierce Weakness's 2.5x.

## Buff

### The Even Tread

*Audience: Tactician, Scholar, Warlord.* **Boots.** [Enabler]  hooks `OnBuffGained`, `GetAppliedStatusValue`

Buffs the wearer applies are 50 / 55 / 60 / 70 / 85% stronger.

**Compositional drawback:** the wearer's allies cannot critically hit.

### Prism of Small Favors

*Audience: Appraiser, Bloodmage, Cultist, Jester, Lancer, Thief, Tidal Corsair.* **Off-Hand.** [Channel 2 — crit
path]  hooks `OnBuffGained`, `GetAttributeDelta`, `GetAppliedStatusValue`

Each buff the wearer holds, up to 2 / 2 / 3 / 3 / 4 of them, grants +12 percentage points Critical
Chance.

**Drawback:** buffs the wearer holds have half their magnitude.

## Debuff

### Signatory's Seal

*Audience: Emissary, Plague Doctor, Diviner.* **Off-Hand.** [Enabler]  hook `OnDebuffApplied`

The first 2 / 2 / 3 / 3 / 4 debuffs applied to each enemy in a battle cannot be resisted.

**Drawback:** the wearer cannot resist debuffs (Signed Writ, permanently).

### The Solvent Mark

*Audience: Alchemist, Architect, Plague Doctor.* **Off-Hand.** [Enabler]  hooks `GetAppliedStatusValue`,
`OnDebuffReceived`

Unravel, Expose Weakness, Blight and Blind applied by the wearer are 45 / 50 / 55 / 60 / 70%
stronger, and none of the four can be applied to the wearer.

**Drawback:** debuffs affecting the wearer have double magnitude.

### Quorum Bell

*Audience: Scholar, Emissary, Tactician.* **Weapon.** [Enabler]  hooks
`GetAppliedAttributeAmplification`, `GetConditionCount`, `OnSkillCast`, `GetOutgoingDamageBonus`

While at least one zone stands on the turn bar, attribute buffs and debuffs the wearer applies are
11 / 13 / 15 / 17 / 20 percentage points stronger, adding to any other attribute amplification the
team supplies rather than replacing it. Defence, Critical Chance and Critical Damage are excluded.

**Compositional drawback:** damaging skills carrying no cooldown deal 30% less damage, for everyone
on the wearer's team.

## Sustain

### Ceded Ground

*Audience: Appraiser, Tactician, Warlord.* **Boots.** [Enabler]  hooks `OnCriticalHit`, `GetAttributeDelta`

When an ally holding a buff the wearer applied lands a critical hit, that ally heals for
8 / 10 / 12 / 14 / 17% of the damage dealt.

**Drawback:** the healing is paid out of the wearer's own Health, and the wearer's Mysticism is
reduced by 50%.

### The Quiet Mass

*Audience: Bar Brawler, Bloodmage, Warlord.* **Off-Hand.** [Enabler]  hook `GetAttributeDelta`

Gain 25 / 30 / 35 / 40 / 50% max Health.

**Drawback:** the wearer's targeting weight is multiplied by 0.45 / 0.4 / 0.35 / 0.3 / 0.25.

### Mercy Stitch

*Audience: Jester, Symbiote, Sorcerer, Bar Brawler.* **Boots.** [Enabler]  hooks `OnDamageTaken`,
`GetOutgoingDamageBonus`

Once per battle, damage that would take the wearer below 25% Health instead leaves them there, and
heals them for 20 / 25 / 30 / 35 / 45% of max Health.

**Drawback:** while at or below 40% Health, the wearer's damaging skills deal 40% less damage.

## Control

### The Long Second

*Audience: Chronophage.* **Boots.** [Enabler]  hook `OnAllyTurnBarIncreased`

Forward turn-bar bumps the wearer grants an ally gain 20 / 25 / 30 / 35 / 45% increased effect.

**Compositional drawback:** buffs placed by the wearer's team have 30% reduced magnitude.

### Understudy's Coat

*Audience: Jester, Symbiote, Bar Brawler.* **Off-Hand.** [Enabler]  hooks `OnAllyDamageTaken`,
`GetOutgoingDamageBonus`

Enemy single-target skills aimed at any other ally with the lowest current Health redirect
85 / 80 / 75 / 70 / 60% of the damage to the wearer, mitigated by the wearer's own Defence; the
rest still lands on the original target.

**Drawback:** the wearer's damaging skills deal 35% less damage.

## Auxiliary

### Laden Coffer

*Audience: every Role.* **Boots.** [Out of combat]  hooks `GetRewardMultiplier`, `GetAttributeDelta`

Rewards from a battle the wearer fought in are increased by 10 / 15 / 20 / 25 / 35%. Only the
largest bonus among the fielded team applies; copies do not add.

**Drawback:** the wearer's Speed is reduced by 30%.

## Slots and stacking

The number of equipped Relics is uncapped, so a champion can field one from each live slot. The
worst case is therefore the product of the strongest entry per slot **among those a single Role
qualifies for** — a stack only exists where one champion meets every condition.

Ranked without slots, the roster's three widest damage audiences reach 5.67x (Tidal Corsair), 5.02x
(Lancer) and 3.92x (Thief); every other Role sits below 3.4x. The overlap driving all three is The
Sealed Docket, The Unguarded Glass, Lantern of the Standing Ward and Kiln Brand. Holding that group
to one slot is what caps the product — how many damage entries a slot holds does not matter, which
leaves the assignment free to follow the fantasy of the gear.

With the current tags the worst case is **2.97x**, reached by Tidal Corsair and Thief. Every entry
added to the catalog is checked against that figure by its audience, not by its slot's headcount.

| Slot | Count | Entries |
|---|---|---|
| Weapon | 6 | The Long Furrow, Draught-Fed Edge, Threefold Bite, Kiln Brand, Sunderplate Nail, Quorum Bell |
| Off-Hand | 11 | The Closed Wound, Lantern of the Standing Ward, The Answering Boss, The Sealed Docket, The Unguarded Glass, The Ossuary Ledger, Prism of Small Favors, Signatory's Seal, The Solvent Mark, The Quiet Mass, Understudy's Coat |
| Boots | 7 | The Planted Heel, The Frayed Hour, The Even Tread, Ceded Ground, Mercy Stitch, The Long Second, Laden Coffer |

## Coverage

Refresh every table below in the same edit that lands a batch. Role names and channel tags follow
`Role_Kit_Design.md` sections 5 and 1.1.3.

**Payout groups:** Damage 13  Buff 2  Debuff 3  Sustain 3  Control 2  Auxiliary 1.

### Role coverage

**Audience** is the entry's own tag. An entry is listed under **Won't wear** when its drawback
cancels a channel that Role's kit depends on, and under **Won't sit beside** when a compositional
drawback does the same to a Role sharing the team. A drawback that only taxes the wearer is not
listed.

Five entries is the soft ceiling on any one Role's audience, checked whenever an audience changes.

| Role | Audience of | Won't wear | Won't sit beside |
|---|---|---|---|
| Alchemist | Draught-Fed Edge, The Solvent Mark | Kiln Brand | Lantern of the Standing Ward, The Closed Wound, The Frayed Hour, The Long Second |
| Appraiser | Prism of Small Favors, Ceded Ground | — | The Even Tread |
| Architect | Lantern of the Standing Ward, The Sealed Docket, The Solvent Mark | Kiln Brand | The Frayed Hour |
| Bar Brawler | The Planted Heel, The Answering Boss, The Quiet Mass, Mercy Stitch, Understudy's Coat | The Ossuary Ledger, The Unguarded Glass | The Closed Wound, The Long Second |
| Bloodmage | Prism of Small Favors, Sunderplate Nail, The Closed Wound, The Ossuary Ledger, The Quiet Mass | — | Sunderplate Nail, The Frayed Hour |
| Chronophage | Lantern of the Standing Ward, The Long Second | — | The Sealed Docket |
| Cultist | Prism of Small Favors, The Closed Wound, The Ossuary Ledger | Kiln Brand | — |
| Diviner | Signatory's Seal, The Sealed Docket | — | The Closed Wound |
| Emissary | Signatory's Seal, The Sealed Docket, Quorum Bell | Kiln Brand | — |
| Herald of the Loom | Threefold Bite, The Frayed Hour | Kiln Brand | The Sealed Docket |
| Jester | Prism of Small Favors, The Ossuary Ledger, Mercy Stitch, Understudy's Coat | The Quiet Mass | — |
| Lancer | Prism of Small Favors, Sunderplate Nail, The Long Furrow, The Sealed Docket, The Unguarded Glass | Kiln Brand | — |
| Plague Doctor | Threefold Bite, Signatory's Seal, Lantern of the Standing Ward, The Solvent Mark | Kiln Brand | The Sealed Docket |
| Scholar | The Even Tread, Quorum Bell | Kiln Brand | Sunderplate Nail, The Long Second |
| Sorcerer | Draught-Fed Edge, Threefold Bite, Mercy Stitch | — | Lantern of the Standing Ward, The Sealed Docket |
| Symbiote | The Planted Heel, The Answering Boss, Mercy Stitch, Understudy's Coat | The Ossuary Ledger, The Unguarded Glass | The Closed Wound, The Long Second |
| Tactician | The Even Tread, Ceded Ground, Quorum Bell | — | Sunderplate Nail, The Long Second |
| Thief | Kiln Brand, Prism of Small Favors, Sunderplate Nail, The Unguarded Glass | — | Quorum Bell |
| Tidal Corsair | Kiln Brand, Prism of Small Favors, Lantern of the Standing Ward, The Sealed Docket, The Unguarded Glass | — | Quorum Bell |
| Warlord | The Even Tread, The Planted Heel, The Answering Boss, Ceded Ground, The Quiet Mass | — | Sunderplate Nail, The Long Second |

**Roster-wide entries, listed here instead of in every row.** Laden Coffer pays out in currency
rather than in a battle effect, so every Role is its audience. Threefold Bite's −30% on non-Echo
damage rules it out for the sixteen Roles that produce no Echoes. The Even Tread's ally-no-crit clause
reaches any teammate carrying a crit-path entry, not only Appraiser. Quorum Bell's tax lands on
every Role's basic; the two rows listing it are the Roles routing real payload through a
no-cooldown skill.

### Channel tally

| Channel | Count | Entries |
|---|---|---|
| Channel 1 | 1 | Sunderplate Nail |
| Channel 2 | 8 | Draught-Fed Edge, Kiln Brand, The Closed Wound, The Planted Heel, The Answering Boss, The Sealed Docket, The Ossuary Ledger, The Frayed Hour |
| Channel 2 — crit path | 2 | The Unguarded Glass, Prism of Small Favors |
| Channel 3 — Cascade | 3 | The Long Furrow, Threefold Bite, Lantern of the Standing Ward |
| Enabler | 9 | Signatory's Seal, The Solvent Mark, Quorum Bell, The Even Tread, Ceded Ground, The Quiet Mass, Mercy Stitch, The Long Second, Understudy's Coat |
| Out of combat | 1 | Laden Coffer |

### Condition surface

What the upside reads. Two entries sharing a surface is a duplication to justify, not a default.

| Surface | Entries |
|---|---|
| Buff or Barrier the wearer holds | The Answering Boss (Barrier), The Unguarded Glass (ally-granted buff), Prism of Small Favors (count of buffs held) |
| Target's state | The Sealed Docket (4+ distinct debuff types) |
| Resource consumed | Draught-Fed Edge (reagent), Lantern of the Standing Ward (zone charge) |
| Event count within the battle | Threefold Bite (every third Echo), Signatory's Seal (first N debuffs per enemy) |
| Incoming event | The Planted Heel (hit above 15% max Health), The Ossuary Ledger (ally death), Mercy Stitch (damage crossing 25% of the wearer's max Health) |
| Turn-bar distance | The Long Furrow (4 or 5 sections) |
| Application the wearer makes | The Even Tread (any buff applied), The Frayed Hour (Temporal Leak applied), The Solvent Mark (Unravel, Expose Weakness, Blight or Blind applied), The Long Second (forward bump granted to an ally) |
| Ally holding the wearer's buff | Ceded Ground (that ally's critical hits) |
| Ally's current Health | Understudy's Coat (the lowest among the other allies) |
| Property of the skill cast | Kiln Brand (the skill carries a cooldown) |
| Zone standing on the turn bar | Quorum Bell (at least one) |
| None — always on | The Closed Wound, The Quiet Mass, Sunderplate Nail, Laden Coffer |

### Hook tally

| Hook | Count | Entries |
|---|---|---|
| `GetOutgoingDamageBonus` | 9 | Kiln Brand, The Closed Wound, The Planted Heel, The Answering Boss, The Sealed Docket, Quorum Bell, Mercy Stitch, Understudy's Coat, Threefold Bite |
| `OnBuffGained` | 5 | The Answering Boss, The Unguarded Glass, The Even Tread, Sunderplate Nail, Prism of Small Favors |
| `OnSkillCast` | 3 | The Long Furrow, Kiln Brand, Quorum Bell |
| `OnSkillEffectsResolved` | 1 | The Long Furrow |
| `OnReagentConsumed` | 1 | Draught-Fed Edge |
| `OnCascadeInstanceResolved` | 0 | — |
| `OnDamageTaken` | 2 | The Planted Heel, Mercy Stitch |
| `OnZoneUsed` | 1 | Lantern of the Standing Ward |
| `OnCriticalHit` | 2 | The Unguarded Glass, Ceded Ground |
| `OnAllyDeath` | 1 | The Ossuary Ledger |
| `OnDebuffApplied` | 1 | Signatory's Seal |
| `OnDebuffReceived` | 1 | The Solvent Mark |
| `GetAppliedStatusValue` | 4 | The Even Tread, The Frayed Hour, The Solvent Mark, Prism of Small Favors |
| `GetAppliedAttributeAmplification` | 1 | Quorum Bell |
| `GetConditionCount` | 1 | Quorum Bell |
| `GetAttributeDelta` | 4 | The Quiet Mass, Prism of Small Favors, Laden Coffer, Ceded Ground |
| `GetIncomingHealMultiplier` | 0 | — |
| `OnAllyTurnBarIncreased` | 1 | The Long Second |
| `GetOutgoingDefenceIgnoreFactor` | 1 | Sunderplate Nail |
| `GetRewardMultiplier` | 1 | Laden Coffer |
| `GetBaseDefenceIgnoreRate` | 0 | — |
| `StartOfTurn` | 0 | — |
| `EndOfTurn` | 0 | — |
| `OnKill` | 0 | — |
| `OnDeath` | 0 | — |
| `OnDefend` | 0 | — |
| `OnAllyDamageTaken` | 1 | Understudy's Coat |
| `OnEnemyTurnBarReduced` | 0 | — |
| `OnZoneConstructed` | 1 | Lantern of the Standing Ward |
| `OnAffectedByZone` | 0 | — |
| `GetZoneChargeBonus` | 0 | — |

### Status and mechanic surface

| Status or mechanic | Direction | Entries |
|---|---|---|
| Signed Writ | applied to wearer | Signatory's Seal |
| Severance | applied to wearer | The Ossuary Ledger |
| Buffs (held) | read | The Answering Boss, The Unguarded Glass, Prism of Small Favors |
| Buffs (received) | taxed in the wearer's Health / halved in magnitude | Sunderplate Nail / Prism of Small Favors |
| Buffs (applied) | amplified / suppressed | The Even Tread / The Long Second |
| Attribute buffs and debuffs applied, Defence and crit excluded | amplified | Quorum Bell |
| Buffs (denied) | suppressed | The Ossuary Ledger, The Unguarded Glass |
| Debuff resistance | bypassed on the target, removed on the wearer | Signatory's Seal |
| Debuffs on the wearer | amplified against the wearer | The Solvent Mark |
| Unravel, Expose Weakness, Blight, Blind | amplified, and denied on the wearer | The Solvent Mark |
| Distinct debuff types | read | The Sealed Docket |
| Reagents | suppressed | Draught-Fed Edge (wearer), Lantern of the Standing Ward (team) |
| Echoes | amplified / suppressed | Threefold Bite, Lantern of the Standing Ward, The Long Furrow / The Sealed Docket |
| Healing and Barriers | granted / denied | Ceded Ground (to a buffed ally, out of the wearer's Health), Mercy Stitch (to the wearer, on a Health threshold) / The Closed Wound (healing, team), The Frayed Hour (Barriers, team) |
| Damaging skills while the wearer is wounded | suppressed | Mercy Stitch (wearer) |
| Damaging skills, unconditionally | suppressed | Understudy's Coat (wearer) |
| Enemy target selection | redirected onto the wearer | Understudy's Coat |
| Critical hits | amplified / denied / read | The Unguarded Glass, Prism of Small Favors / The Long Furrow, The Even Tread / Ceded Ground |
| Enemy targeting weight | raised / lowered | The Planted Heel / The Quiet Mass |
| Max Health | raised / reduced | The Quiet Mass / The Answering Boss |
| Temporal Leak | amplified | The Frayed Hour |
| Turn-bar bumps (forward, ally) | amplified | The Long Second |
| Target Defence | bypassed | Sunderplate Nail |
| Skill cooldowns | read | Kiln Brand, Quorum Bell |
| Damaging skills able to apply a debuff | suppressed | Kiln Brand (wearer) |
| Damaging skills carrying no cooldown | suppressed | Quorum Bell (team) |
| Zones standing on the turn bar | read | Quorum Bell |
| Mysticism | reduced | Ceded Ground |
| Speed | reduced | Laden Coffer |
| Battle rewards | raised | Laden Coffer |

Signed Writ and Severance are on `Role_Kit_Design.md` section 10.1's *unclaimed by policy* list.
They are admissible here only because they land on the wearer as the fixed cost — no entry aims a
policy-locked status at an enemy.
