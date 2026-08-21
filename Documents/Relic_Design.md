# Relic Design

The Relic contract — item type, rarity ladder, conditional upside, fixed drawback — is
`Concept_Document.md` section 3.3.1.

Each entry names its Role audience: the Role that meets the condition best and most often. No
entry requires that Role, except where marked.

## Weapon

### The Long Furrow

*Audience: Lancer.* [Channel 3 — Cascade] · hooks `OnSkillCast`, `OnSkillEffectsResolved`

Rending Charge cast at 4 or 5 sections of turn-bar distance resolves a second time, at
25 / 30 / 35 / 45 / 55% strength.

**Drawback:** Rending Charge can never critically hit.

The catalog's one exception to the mechanic-vocabulary rule: it reads a named skill.

### Vein-Split Athame

*Audience: Bloodmage.* [Channel 2] · hooks `OnSkillCast`, `GetOutgoingDamageBonus`

While below 50% of max Health, damaging skills deal +15 / 18 / 22 / 28 / 35% damage.

**Drawback:** healing and Barriers the wearer creates are reduced by 60%.

### Draught-Fed Edge

*Audience: Sorcerer, Alchemist.* [Channel 2] · hook `OnReagentConsumed`

The first damaging skill cast after consuming a reagent deals +25 / 30 / 35 / 45 / 60% damage.

**Drawback:** reagents the wearer consumes have 40% less effect.

### Threefold Bite

*Audience: Herald of the Loom, Plague Doctor, Sorcerer.* [Channel 3 — Cascade] · hook
`OnCascadeInstanceResolved`

Every third cascade instance a single action produces deals +60 / 80 / 100 / 130 / 170% damage.

**Drawback:** damage that is not a cascade instance is reduced by 30%.

### Signatory's Edge

*Audience: Emissary, Plague Doctor, Diviner.* [Enabler] · hook `OnDebuffApplied`

The first 2 / 2 / 3 / 3 / 4 debuffs applied to each enemy in a battle cannot be resisted.

**Drawback:** the wearer cannot resist debuffs (Signed Writ, permanently).

### The Closed Wound

*Audience: Bloodmage, Cultist.* [Channel 2] · hook `GetOutgoingDamageBonus`

Damaging skills deal +25 / 30 / 35 / 45 / 60% damage.

**Drawback:** healing received by anyone on the wearer's team, from any source, is reduced by 80%.

### The Even Hand

*Audience: Tactician, Scholar, Warlord.* [Enabler] · hooks `OnBuffGained`, `GetAppliedStatusValue`

Buffs the wearer applies are 50 / 55 / 60 / 70 / 85% stronger.

**Compositional drawback:** the wearer's allies cannot critically hit.
