# Symbiote Graft Pool

The concrete graft options for the Symbiote's `Graft` passive (`Concept_Document.md`,
Symbiote entry in 3.1.3). Each graft is bound to an enemy: grafting onto that enemy
gives the Symbiote the graft's effect and, where it complements the effect, an attribute
bonus and a drawback. The effect potency and attribute bonus scale with the Symbiote's
own rarity; the drawback is flat and identical at every rarity.

An attribute bonus is optional — a graft that is interesting on its effect alone grants
none. Any attribute a graft raises or lowers must be one the Symbiote actually uses (the
Symbiote's damaging skills currently scale with Resistance, so Attack, for instance, does
nothing for it) — unless the graft's own effect is what gives that attribute a purpose.

Values are listed by rarity in the order **Uncommon / Rare / Epic / Legendary**.

This is the content the graft machinery consumes: each graft below becomes one
`GraftEffect` subclass plus a one-line `.tres`. Concrete enemy sources are assigned later,
once more opponents are designed.

## Grafts

### Spreading Rot

- **Effect:** the Symbiote's attacks apply **Blight** (healing received −50%) to the
  target — 1 turn at Uncommon and Rare, 2 turns at Epic and Legendary.
- **Attribute bonus:** Health +12% / 16% / 20% / 24%.
- **Drawback:** at the start of each of its turns the Symbiote takes rot damage equal
  to 3% of its max Health.

### Hollow Hunger

- **Effect:** the Symbiote heals for 10% / 13% / 16% / 19% of the damage it deals.
- **Attribute bonus:** none.
- **Drawback:** max Health −15%.

### Carrion Bloom

- **Effect:** at the start of the Symbiote's turn, heal the lowest-Health ally for
  3% / 4% / 5% / 6% of that ally's max Health.
- **Attribute bonus:** Health +10% / 12% / 14% / 16%.
- **Drawback:** healing the Symbiote itself receives is reduced by 50%.

### Caravan Cadence

- **Effect:** at the start of the Symbiote's turn, push the ally furthest behind on
  the turn bar forward by 7% / 8% / 9% / 10%.
- **Attribute bonus:** Knowledge +15% / 20% / 25% / 30%
- **Drawback:** the Symbiote is permanently Anchored — it cannot be pushed forward on
  the turn bar by any source.

### Glass Refraction

- **Effect:** when the Symbiote is hit by an attack, a chaotic backlash strikes the
  attacker for magical damage equal to 25% of the Symbiote's Mysticism.
- **Attribute bonus:** Mysticism +12% / 16% / 20% / 24%.
- **Drawback:** Resistance −40%.

### Living Bloom

- **Effect:** at the start of battle the Symbiote seeds one Spore Bloom in a free section
  of the turn bar, starting with 10 charges. Each time the Symbiote takes a turn, the Bloom
  gains one charge, up to its 10-charge maximum. Enemies that stop in it gain **Blight** for
  1 turn; allies gain **Regeneration** for 1 turn.
- **Attribute bonus:** Knowledge +15% / 20% / 25% / 30% (the Bloom's potency scales with
  the Symbiote's Knowledge, the standard ally-zone rule).
- **Drawback:** none.
- **Implementation note:** needs a dual-faction zone — one zone that buffs allies and
  debuffs enemies, versus today's Ally / Enemy / All targeting — and charge replenishment
  on the placer's turns.

### Rootfeeder

- **Effect:** whenever the Symbiote is affected by any zone (either side), it heals
  4% / 5% / 6% / 7% of its max Health on top of the zone's normal effect. It consumes one
  charge exactly as any character does and never clears a zone early.
- **Attribute bonus:** none.
- **Drawback:** enemy-placed zones affect the Symbiote at +50% effect.
- **Implementation note:** needs an "affected-by-a-zone" trigger hook.

### Gravitic Rot

- **Effect:** at the start of the Symbiote's turn, every enemy within 20% behind it on the
  turn bar loses 5% / 6% / 7% / 8% turn bar.
- **Attribute bonus:** none.
- **Drawback:** Speed −10%.
- **Implementation note:** needs a rear-facing proximity turn-bar drain.

### Contagion Bond

- **Effect:** when the Symbiote gains a buff, the nearest ally within the contagion width
  gains a copy for 1 turn; when a debuff lands on the Symbiote, the nearest enemy within
  the width catches a copy (contested against that enemy's Resistance). Contagion width,
  measured both ahead and behind: 6% / 8% / 10% / 12% of the turn bar.
- **Attribute bonus:** none.
- **Drawback:** debuffs on the Symbiote last 2 turns longer.
- **Implementation note:** needs proximity-gated copying of buffs and debuffs.

### Symbiotic Anchor

- **Effect:** at the start of battle the Symbiote tethers to a random ally (re-tethering to
  another random ally if that ally dies). The tethered ally gains bonus Resistance equal to
  20% of the Symbiote's Resistance and bonus Attack equal to 20% of the Symbiote's Attack.
- **Attribute bonus:** Resistance +14% / 16% / 18% / 20% (also raises the Resistance shared
  to the tethered ally).
- **Drawback:** the Symbiote's own Defense −30% and Critical Damage −30% — one defensive and
  one offensive stat, a cost whether the Symbiote is pushed toward tanking or damage.
- **Implementation note:** needs a persistent random-ally tether with attribute-sharing.

### Bloodscent

- **Effect:** the Symbiote's attacks deal +20% / 25% / 30% / 35% damage to the enemy with
  the lowest current Health, and a killing blow heals it for 15% of its max Health.
- **Attribute bonus:** none (the Symbiote's damage already rides on its Resistance).
- **Drawback:** −25% damage against any enemy above 50% Health.
- **Implementation note:** needs a target-Health-conditional damage modifier and an on-kill
  heal hook.

### Reactive Plating

- **Effect:** each time the Symbiote takes attack damage it gains a **Hardened** stack —
  +2% / 3% / 4% / 5% Defense per stack, up to 9 stacks, lasting the rest of the battle.
- **Attribute bonus:** none.
- **Drawback:** Speed −15%.
- **Implementation note:** needs a new stacking **Hardened** bonus applied from an
  on-damage-taken hook.

### Undertow

- **Effect:** when an enemy hits the Symbiote, that attacker is pulled back 6% / 7% / 8% / 9%
  on the turn bar.
- **Attribute bonus:** Health +13% / 16% / 19% / 22%.
- **Drawback:** the Symbiote loses 5% turn bar whenever it is hit.
- **Implementation note:** needs a retaliatory turn-bar pull on the attacker.

### Wretched Conscript

A whole run-of-the-mill soldier fused on and worn like a second hide — the graft that marks
its bearer as a disgusting outcast. Deliberately the pool's dull floor: a safe, unglamorous
pick when no prize catch is on the field.

- **Effect:** none.
- **Attribute bonus:** Defense +8% / 10% / 12% / 14%.
- **Drawback:** none.

### Strength in Numbers

- **Effect:** the Symbiote gains +8% / 10% / 12% / 14% Resistance and the same Defense for
  each *other* living ally (up to two others).
- **Attribute bonus:** none (the per-ally scaling above is the payoff).
- **Drawback:** while the Symbiote has no living allies, −25% Resistance.

### Detritivore

A wretch that subsists on everyone's leavings and grows from them — the scraps, the spent,
the discarded.

- **Effect:** whenever a reagent is consumed, a buff expires, or a zone dissipates — anywhere
  in the battle, on either side — the Symbiote scavenges the remains: it heals 2% of its max
  Health and gains a **Scrap** stack worth +2% / 3% / 4% / 5% Resistance for the rest of the
  battle (no cap).
- **Attribute bonus:** none — the Scrap stacks are the scaling.
- **Drawback:** the Symbiote begins each battle at −20% Resistance, scraping its way back up
  from nothing.
- **Implementation note:** reuses the existing `Reagent_Consumed` hook; needs new
  **buff-expired** and **zone-dissipated** triggers.

### Overgrowth

- **Effect:** at the start of each of its turns the Symbiote gains an **Overgrowth** stack and
  heals 1% of its max Health per stack it holds. On reaching 6 stacks the growth spills over —
  every ally gains **Regeneration** for 1 / 1 / 2 / 2 turns — and the Overgrowth stacks reset
  to zero.
- **Attribute bonus:** none.
- **Drawback:** none for now.

### Glamour

- **Effect:** single-target attacks against the Symbiote have a 25% / 30% / 35% / 40% chance
  to be **Refracted** onto a random other character. The Symbiote also deals +10% damage.
- **Attribute bonus:** none.
- **Drawback:** the Symbiote takes +10% damage and is targeted 20% more often — enemies swat
  at the maddening blur.
- **Implementation note:** redirects the current attack itself (a defender-side
  `GetIncomingSingleTargetRedirectChance` roll in target resolution), not the existing
  Refracted debuff, which is caster-side and redirects the *holder's own* future casts.

## Open decisions

- **Dedicated Rot debuff.** Spreading Rot currently reuses the existing **Blight**
  debuff. A signature Symbiote-flavored **Rot** debuff could replace or accompany it if
  it proves mechanically interesting; undecided.
