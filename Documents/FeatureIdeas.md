# Feature Ideas

Quick-capture list for future features. Add new ideas under the relevant section.

Format per idea:
`- **[Title]** *(Priority: High/Medium/Low | Effort: S/M/L)*`
`  1–2 sentence description.`

Priority: **High** = core loop impact, **Medium** = meaningful addition, **Low** = polish/nice-to-have
Effort: **S** = hours, **M** = days, **L** = week+

---

## Combat

- **True Revive Reagent** *(Priority: Low | Effort: M)*
  If true revival ever exists, it should be a Legendary-only reagent rather than any role's skill. Currently the Deathward Charm reagent (prevention, not resurrection) is the only death counterplay; whether resurrection should exist at all is undecided.

- **Alternative Battle Objectives** *(Priority: Low | Effort: L)*
  Win/loss conditions beyond defeating all enemies: survive N rounds, protect a target, defeat a specific enemy before their Nth turn. A combat-core extension (coordinate with Plans/Plan_Headless_Combat_Core.md if picked up); would serve story-mode escape and protection beats. Not planned for now.

- **Rework Orphaned Turn Bar Effects** *(Priority: Medium | Effort: M)*
  Three of the seven turn bar effects in Concept_Document 3.2.3.1 (Anchor, Steadfast, Resonance) are still unclaimed, largely because their effects are too weak to spend a skill slot on. Revisit them — strengthen, replace, or design new turn bar effects — before assigning them to future kits, opponent skills, or the passive pass. Slipstream left the list by being granted as a rider bundled with Empower rather than costing a slot (Role_Kit_Design.md section 9.13), which is one answer to the weakness.

- **Attack is under-represented across the roster** *(Priority: Medium | Effort: M)*
  Attack is a primary attribute on 3 of 20 Roles, against Knowledge's 9, Mysticism's 7 and Speed's 5 (Concept_Document 3.1.3). Any effect keyed to Attack is therefore near-dead for most teams — the constraint that pushed Sea Legs onto a per-holder attribute (Role_Kit_Design.md section 9.13). Consider moving some Roles onto Attack as their kits are reworked, so the attribute spread supports fixed-attribute grants at all.

- **Zone placement should not be blocked outright** *(Priority: Medium | Effort: M)*
  Concept_Document 3.2.4.1 blocks placing a zone into an occupied section until that zone is gone, so a zone cast can be dead on arrival. Proposal: placement resolves to the nearest free section instead of failing, keeping one-zone-per-section. Affects all six player zones and both enemy zones, and removes section-occupancy denial as an emergent tactic — hence its own pass rather than riding in on one kit. The Gilded Deck (Role_Kit_Design.md section 9.13) already needs a local fallback because it is auto-placed.

- **Knowledge-Bypass Variant of Cracked Facet** *(Priority: Low | Effort: S)*
  Alternative effect for the Appraiser's Cracked Facet debuff: instead of flat bonus Critical Damage taken, the target's Knowledge does not blunt critical hits while the debuff holds (bypassing the `Defender's Knowledge * 0.5` term in the Critical Damage formula). Thematic for the Knowledge-scaling Appraiser but swingy — worthless against low-Knowledge enemies, huge against high-Knowledge ones. Shelved in favor of the flat bonus.

- **Speed as a Field of Study Weakness** *(Priority: Low | Effort: S)*
  The Scholar's Field of Study still excludes Speed from `PRIMARY_ATTRIBUTES` (`field_of_study_trait.gd`), a holdover from when turn order read only base Speed and a Speed weakness would have been identified but done nothing. Turn order now reads live, status-inclusive Speed (`BattleResolver.GetEffectiveAttributes`, `Battle.RefreshTurnBarSpeeds`), so the original blocker is gone — a Field of Study weakness rider reducing Speed would now genuinely slow the target's turn-bar advance. Revisit whether to add Speed back to the identifiable set.

- **Calibration Zone "Upgrade" Feel** *(Priority: Low | Effort: S)*
  Final Calculation's tier-3 effect (7+ charges) re-erects the Architect's construction zone for free, or "upgrades" it if one is already standing (Concept_Document.md 3.1.3 / 3.2.4.3). The current implementation collapses "upgrade" to simply setting the existing zone's remaining charges to 8 — functionally correct but flavorless. Brainstorm a more distinct upgrade effect (e.g. a stronger Barrier size, bonus duration, or a visual/mechanical tell that the zone was reinforced rather than merely refilled) before this reads as a real tier-3 payoff.

- **Additive Damage Bonuses as a Distinct Lever** *(Priority: Low | Effort: S)*
  Per-use ramps (`ramp_per_use`, e.g. Heap On) scale the attack *before* mitigation, so each use improves Defence penetration as well as raw size and the curve is super-linear. A bonus applied additively at the end of the damage formula instead grows strictly linearly and is blunted by high Defence — worth 5–26% less on the ramp skills at 3–5 uses, more the tankier the target. Both forms read as "+X% damage" but behave differently; the additive one suits effects that should stay honest against armored targets (conditional riders, buff-count scaling), the pre-mitigation one suits "this skill grows" identities. Consider using the split deliberately when designing future scaling skills. See Technical_Design_Document.md section 7.4.

- **Crit-Conditional Combined_Damage_Modifier Contribution** *(Priority: Medium | Effort: S)*
  Critical Hit stays deliberately outside `Combined_Damage_Modifier` (Concept_Document.md 3.2.1) — the base crit roll is a baseline per-swing expectation every character has, not a built condition, so folding it into the channel would silently compound it with the mitigation-ratio effect the same way Daunting Strength is. A crit-focused build-around mechanic instead — a trait or buff contributing its own factor to `Combined_Damage_Modifier` specifically when a hit crits — would give crit-focused kits a blowout hook without touching the universal baseline roll.

- **Taut Weave — turn-bar section occupancy as a damage condition** *(Priority: Medium | Effort: S)*
  Skill sketch, unassigned: deals damage to one enemy, +20% per *other* character standing in the same turn-bar section as the target. Opens **section occupancy** as a Channel 2 condition surface — listed as legitimate in Role_Kit_Design.md section 2 and currently read by nothing in the roster. Rewards bunching enemies and composes indirectly with any kit that drags characters around the bar. Designed during the Herald of the Loom kit pass and set aside there because the Herald needed a Channel 2 skill that also feeds its own resource; this one does not, so it suits a Role whose resource comes from elsewhere. Check against the Chronophage's turn-bar identity before assigning.

- **Per-Source Burst Attribution** *(Priority: Medium | Effort: M)*
  Concept_Document.md 1.1.5 asks for each burst instance to land "attributed to its source", but nothing in battle names a source: floating combat text spawns at the target with no label, and there is no combat log. The `Debuff_Tick` branch in `battle.gd` even collapses `amount_by_source` into one aggregate number despite the per-source breakdown already being on the result — splitting that is the cheapest first step. Fuller options (source-labelled floating text, a per-instance mechanic banner naming the `Cascade_Triggered` mechanic key, or a scrolling combat log) each add a new UI surface with a screen-space cost, so none were taken alongside the tempo and magnitude escalation.

---

## Characters & Progression

- **New Role: The Abacist (Control/Sustain)** *(Priority: Medium | Effort: M)*
  A stillness-control role — the Chronophage's opposite: it forbids turn-bar movement instead of causing it, claiming the orphaned Anchor, Steadfast, and Sequence Lock effects. Unblocks the shelved turn-bar-tyrant boss concept and completes the Reanimating Statues 1 answer set; lore home: the Silent Monks of the Abacus (World_Building 5.2).

- **New Role: The Outrider (Buffer/Control)** *(Priority: Medium | Effort: M)*
  A momentum support giving the God of Adventure / Khasar Fleet its first playable role, claiming Wanderlust plus ally turn-bar pushes. Slipstream is no longer available to it — the Tidal Corsair claims it (Role_Kit_Design.md section 9.13).

- **New Role: The Underwriter (declared wagers)** *(Priority: Medium | Effort: L)*
  A role built on a mechanic type new to the genre: its skills declare a wager on an outcome before it happens (e.g. "this enemy dies within 3 of the Underwriter's turns", "this ally takes no Health damage before my next turn") and settle later — a party payoff if the prediction holds, a penalty on the Underwriter if it fails. Skill effects are placeholders to be tweaked; the declare-then-settle structure is the idea. Lore home: Iron Ledger actuarial insurance or the Arrears' Grey Ledger.

---

## Gear & Economy

- **Reagent Shop Purchase** *(Priority: Low | Effort: M)*
  Reagents are currently loot-only (bosses and the Escalate adventure node). Add a shop
  purchase path once the 3.6.4 shop design lands, so players aren't fully dependent on drops.

---

## Content & Encounters

- **World Boss (Timed)** *(Priority: Medium | Effort: L)*
  A powerful boss that only appears during special real-time windows (e.g. weekends or seasonal events). Ties into the God-themed event rotation from the concept doc.

- **Run Multiplier** *(Priority: Medium | Effort: S)*
  Let the player select a multiplier (e.g. x3, x5) before entering a repeatable encounter to auto-run it that many times and batch the rewards. Reduces friction for grinding.

---

## UI & Quality of Life

- **Enemy Passive Reveal-on-Trigger with Bestiary** *(Priority: Medium | Effort: L)*
  Enemy passives show only a name and a flavor line until the effect triggers once, then the full mechanical text unlocks — for the rest of the battle and permanently in a bestiary, so knowledge transfers across encounters re-using the variant. Upgrade path from the current rule (enemy passives not inspectable at all, Concept_Document 3.2); needs investigation of screen-space budget and reveal handling first.



---

## World & Narrative

- **Faction Reputation Meter** *(Priority: Low | Effort: M)*
  Track player standing with each faction. Higher rep unlocks exclusive characters or gear in that faction's hub. Reinforces the faction/synergy system noted in Concept_Document section 3.1.2.
