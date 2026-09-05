# Remaining Scope Checklist

Tracks the big-ticket items left before the game can be considered feature-complete,
grouped by priority. Ambiguity in detail is fine — each item links to the doc/section
that holds (or will hold) the detail.

## Important

- [ ] Gacha mechanic with presentation elements — pull animations/UI; ties into
  Fortune's Favor and champion recruitment (Concept_Document.md 3.6.3 The Adventurer's Guild)
- [ ] Story mode — narrative campaign built on World_Building.md lore
  (design plan: Plans/Plan_Story_Mode.md)
- [ ] Visuals for Adventure mode — art/UI pass on the adventure graph/node system
  (data structure landed: `BiomeVisualData`/`DecorLayerData`; see
  Adventure_Background_Visuals_Checklist.md for the art backlog and remaining
  rendering-integration work)
- [x] The shop (Concept_Document.md 3.6.4 The shop)
- [ ] Music
- [ ] Sound effects
- [ ] More skills — expand role-specific and universal skill rosters (Concept_Document.md 3.2.4)
- [ ] Effects when skills are cast — visual/animation feedback in combat
- [ ] More big battles as puzzles — encounter design (Concept_Document.md 3.2 "Tactical Puzzles")
- [ ] Upgrading items — stat-value upgrades done; rarity/affix rerolling still pending (Concept_Document.md 3.3.1)
- [ ] Additional biomes — beyond Reclaimed City (World_Building.md 4.3)
- [ ] Relic items — implement the Relic item type: unique effects, drawbacks, and the item-type
      roll (Concept_Document.md 3.3.1)
- [x] Renown system — post-level-cap progression via duplicate-funded attribute ranks
  (Concept_Document.md 3.1.2); rank pip art is still a placeholder texture

## Technical Groundwork

Not player-facing scope, but tracked here so the checklist covers everything
outstanding. Detail and suggested order live in `Plans/` (see `Plans/README.md`).

Nothing outstanding. Completed groundwork is deleted from this list, not checked off.

## Optional

- [ ] Character talent trees (Concept_Document.md 3.3.1)
- [ ] Timed world bosses (FeatureIdeas.md "World Boss (Timed)")
- [ ] Additional hub areas (Concept_Document.md 3.6 Hub Area)
- [ ] Daily/Weekly challenges (Concept_Document.md 3.4.2)

## Cut

- [x] Draft mode (removed from Concept_Document.md)
- [x] Roguelite mode (removed from Concept_Document.md)
