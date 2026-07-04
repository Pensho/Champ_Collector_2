# Plans

One document per topic, sized so each can be executed and reviewed as an isolated
body of work. Findings behind these plans are recorded in
`Technical_Design_Document.md` sections 15.6–15.9.

Suggested order (dependencies noted inside each plan):

1. `Plan_Combat_Correctness_Fixes.md` — small defect fixes; do first.
2. `Plan_Documentation_Parity.md` — realign `Concept_Document.md` with the
   implemented combat formulas; no code dependency, can run in parallel.
3. `Plan_Team_And_Roster_Abstraction.md` — replace magic slot IDs with teams.
4. `Plan_Headless_Combat_Core.md` — extract testable combat resolution
   (largest; builds on 1 and ideally 3).
5. `Plan_Data_Driven_Status_Effects.md` — status effects as resources
   (independent; hooks into 4 if done after it).
6. `Plan_Naming_Convention_Alignment.md` — align written conventions and code;
   mechanical, schedule last.
7. `Plan_Reagent_System_And_Sorcerer_Passive.md` — reagent consumables (inventory,
   loadout, in-battle use) plus the Sorcerer's Arcane Instability trait;
   independent, but coordinate ordering with `Plan_Headless_Combat_Core.md`
   (whichever lands second adapts).

When a plan completes: update the documentation sections it names, strike the
matching entries from `Technical_Design_Document.md` section 15, and delete or
archive the plan file.
