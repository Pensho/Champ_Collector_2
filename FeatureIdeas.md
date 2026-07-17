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
  Five of the seven turn bar effects in Concept_Document 3.2.3.1 (Anchor, Temporal Leak, Slipstream, Steadfast, Resonance) ended the Role-kit pass unclaimed, largely because their effects are too weak to spend a skill slot on. Revisit them — strengthen, replace, or design new turn bar effects — before assigning them to future kits, opponent skills, or the passive pass. Final claims state: Plans/Archive/Plan_Role_Skill_Kits.md.

- **Knowledge-Bypass Variant of Cracked Facet** *(Priority: Low | Effort: S)*
  Alternative effect for the Appraiser's Cracked Facet debuff: instead of flat bonus Critical Damage taken, the target's Knowledge does not blunt critical hits while the debuff holds (bypassing the `Defender's Knowledge * 0.5` term in the Critical Damage formula). Thematic for the Knowledge-scaling Appraiser but swingy — worthless against low-Knowledge enemies, huge against high-Knowledge ones. Shelved in favor of the flat bonus.

---

## Characters & Progression

- **New Role: The Abacist (Control/Sustain)** *(Priority: Medium | Effort: M)*
  A stillness-control role — the Chronophage's opposite: it forbids turn-bar movement instead of causing it, claiming the orphaned Anchor, Steadfast, and Sequence Lock effects. Unblocks the shelved turn-bar-tyrant boss concept and completes the Reanimating Statues 1 answer set; lore home: the Silent Monks of the Abacus (World_Building 5.2).

- **New Role: The Outrider (Buffer/Control)** *(Priority: Medium | Effort: M)*
  A momentum support giving the God of Adventure / Khasar Fleet its first playable role, claiming Slipstream and Wanderlust plus ally turn-bar pushes. Slipstream is a champion-bound, situational answer to zone-heavy encounters (e.g. the Glyphbound Archivist) that is not zone-clearing.

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
