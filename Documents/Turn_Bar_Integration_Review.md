# Turn Bar Integration Review

A review of how far the turn bar reaches into battle design — Role skills, passives, status
effects, Relics and reagents — against `Concept_Document.md` and the shipped data. Opponents are
out of scope until their design settles.

Reviewed: 2026-09-28

---

## 1. Guiding concern

Most turn-bar interaction is settled before combat: Speed gear decides who stands where, and the
passives that read position either line up or they do not. Combat offers few actions that change
the bar and few moments that ask the player to react to it. New turn-bar content favours decisions
made inside combat — something to act on, something to react to — over conditions a loadout
satisfies in advance.

## 2. Coverage

| Layer | Reads the bar or places on it | Moves characters |
|---|---|---|
| Role skills (20 Roles × 3) | 14 of 60 | 6 of 60 |
| Role passives | 6 of 20 | 3 of 20 |
| Turn Bar Effects (Concept 3.2.3.1, 7 statuses) | 4 with a player source | — |
| Speed statuses (Haste, Slow, Sequence Lock, Frenzy, Wanderlust) | 0 with a player source | — |
| Relics (24) | 5 | 0 |
| Reagents | Second Wind Chime, Unbinding Shard | 1 |

- **Movers:** Flicker Zone, Temporal Sinkhole, Pull the Thread, Headbutt (Dead Weight), Battle
  Orders, Rending Charge (the Lancer's own recoil). Only the Chronophage moves characters by
  meaningful amounts.
- **Position readers:** Plan, Foresight, Shield Wall, Couched Lance, Time Tithe's Borrowed Time
  grant, The Gilded Deck.
- **No contact:** Emissary (by design), Thief, Appraiser, Symbiote (some grafts excepted), Jester,
  Cultist, Bloodmage.
- **Relics:** The Long Furrow, The Frayed Hour and The Long Second each serve one Role; Lantern of
  the Standing Ward and Quorum Bell serve several. None reads the wearer's own section or Speed as
  an upside, and none moves the bar.

## 3. Strengths

- Speed is a rate, and zones are shared terrain holding charges — the bar is a battlefield, not a
  turn-order number.
- Varied read surfaces: target distance (Lancer), a window behind the owner (Plan, Foresight), a
  window around the owner (Shield Wall), being alone in a section (Borrowed Time), zone presence
  (Scholar, Quorum Bell).
- Three passives reward bunching and Borrowed Time rewards spreading out — a real team-building
  tension.
- Zone placement predicts where characters stand when turns start, and zone removal (Refutation,
  Unbinding Shard) gives counterplay.
- Knowledge scales ally zones and Speed scales some damage, tying attributes to the bar.

## 4. Findings and concerns

### 4.1. The one-Role rule caps reach

`Role_Kit_Design.md` section 4 gives turn-bar effects to one Role, so tempo control is the
Chronophage's alone. "Zones stay signature" is a separate rule and is not in question here.

### 4.2. Five shared sections

Allies and enemies share five sections, one zone each. More zone placers need correspondingly more
present removal; today removal is the Scholar and one reagent. Related backlog:
`FeatureIdeas.md` "Zone placement should not be blocked outright".

### 4.3. Readers outnumber writers

Six passives care about position; outside the Chronophage almost nothing puts a character where
those passives want them. Setup is Speed tuning before the battle, so in combat the player watches
Plan, Foresight or Shield Wall line up rather than steering them. This is the main instance of
section 1's concern.

### 4.4. No player tempo basics

Haste and Slow have no player source. Neither do Sequence Lock, Frenzy or Wanderlust; Rush's Speed
on the Warlord is incidental.

### 4.5. Zones mostly deliver statuses

Catalyst Cloud, Unstable Rift, Raise the Frame, Miasma and The Gilded Deck dispense a buff or
debuff; placement is their only turn-bar decision. Only Flicker Zone and Temporal Sinkhole change
tempo.

### 4.6. Orphaned turn-bar statuses

Anchor, Steadfast and Resonance are implemented in the resolvers with no source. Owned by
`FeatureIdeas.md` "Rework Orphaned Turn Bar Effects".

### 4.7. Narrow Relic coverage

Section 2's Relic line. Missing hook surfaces: the wearer's own section, Speed, movement.

## 5. Own-section versus relative conditions

A character acts at the end of the bar and restarts at section 1, so a condition on the holder's
own section is a condition on time since their last turn. It becomes a decision only where the
player can move the holder. Relative conditions — a shared section, distance to the target — shift
with Speed differences and with every push.

## 6. Status effect drafts

Candidates to replace or extend existing statuses. The second draft labelled "buff d" is listed as
buff g. "Decided by" names what sets whether the condition holds; a condition decided by Speed
alone is settled before combat (section 1), and one decided by movement is steerable in combat only
as far as movers exist (4.3).

| Draft | Effect | Reads | Decided by | Notes |
|---|---|---|---|---|
| Buff a | Gains an Echo when stopping in section 2 or 3 | Own section | The holder's Speed — before combat | "Stops" is any turn start, so it can fire several times a cycle; needs a cap or no-stack rule. Adds a Channel 3 claimant. |
| Buff b | Ally zone effects apply double | Zone | Zone placement — in combat | Identical to Resonance (4.6). |
| Buff c | 50% less damage in section 1 or 5 | Own section | The holder's Speed — before combat | Protects just after and just before the holder's turn, about 40% of the cycle. |
| Debuff a | A skill targeting a character who shares a section retargets to the highest-Health character | Relative | Speed differences — mostly before combat | Enemy targeting already favours durability (Concept 3.2.1), so it bites mainly when applied to the player's side. Close to Refracted. |
| Buff d | +30% damage when no other character shares the section | Relative | Speed differences and movement | Third claimant of "alone" after Borrowed Time. |
| Debuff b | +30% damage taken without an ally in the section | Relative | Speed differences and movement | Mirrors buff d. Always met on a lone enemy. |
| Buff e | +60% damage, −20% per section of distance to the target | Relative | Speed differences and movement | Inverse of Couched Lance on the same surface. |
| Buff f | Buffs received in section 1 have double effect | Own section | Which ally acts next and whom they buff — in combat | Rewards sequencing an ally's turn right after the holder's. |
| Debuff c | Takes damage on receiving a debuff in sections 1–3 | Own section | The holder's Speed — before combat | Punisher shaped like Mana Burn; damage wants a caster snapshot like Temporal Leak. |
| Buff g | Stopping on a friendly zone consumes all its charges for +30% damage per charge | Zone | Zone placement — in combat | Spends a zone as a resource and frees a section (4.2). Up to +150% on a full zone; wants a one-shot payout or a charge cap. Undecided: whether the zone's own effect also applies. |

Natural pairs for one kit: buff d with debuff b, buff b with buff g, buff c with buff f.

## 7. Open topics

- How many Roles may carry tempo effects (4.1)?
- Which in-combat levers let a player deliberately move themselves or an ally (4.3)?
- How much zone removal the bar needs if placement widens; whether spending charges (buff g)
  counts as removal (4.2).
- Which kit, if any, takes Haste or Slow (4.4).
- Orphaned statuses: a new Role (`FeatureIdeas.md` Abacist, Outrider) or existing kits (4.6).
- Relic hooks on own section, Speed and movement (4.7).
- Replace or append for section 6's drafts, given the per-character status cap.
- The opponent side, once it is up for design.
