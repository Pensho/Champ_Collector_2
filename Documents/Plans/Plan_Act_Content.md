# Plan: Act Content

Defines what an Act contains and connects each element only far enough to test it. When
the player can reach each element (unlock order, gating, the Mandatory tag, story) is
decided by a separate progression and story plan.

## Decisions

- An Act holds a hub (Armory, Adventurer's Guild, shop), the Region Map, a quest board,
  two Adventures with their own opponents, Act gear, and a way to travel to the Overworld.
- The Statues area is removed. The three Reanimating Statue encounters serve as placeholder
  mini-bosses in the Adventure mini-boss pools until dedicated mini-bosses replace them.
- Mini-boss nodes appear in Adventures and guarantee a gear drop from one slot, which the
  pre-battle drop preview shows. They sit on forked depths where possible, so the player
  opts into them.
- The quest board is a board of posted quests. A side quest is an encounter launched from
  the board. Side quests post on a real-world timer every X minutes up to a cap of Y and
  stay until completed. Main quests are exempt from the timer and the cap and point to an
  objective elsewhere in the Act.
- An Adventure has a top-left button that aborts the current run so a new one can start.

## Steps

Design steps record their outcome in `Concept_Document.md` after the user approves it, and
touch no code. Code steps follow the design steps they depend on.

1. **Done. Record the Act contents (design).** Concept Document 3.6.1, 3.9, 5.1, 5.2.1 and 5.4:
   the quest board joins the 5.4 Act tree, mini-boss nodes and their shown slot
   join 3.9, the abort button joins 5.1, the 5.2.1 stub is replaced. Net-neutral.
2. **Done. Remove the Statues area (code).** Delete `Scenes/Hubs/Statue_Selection/` (scene and
   particle scene), `Scripts/UI/statues_selection_menu.gd`, and the Statues button and its
   handler in `region_map_menu.gd` and the four `*_Region_Map.tscn` scenes. Fix the
   Technical Design Document section 4 Region Map row. The Statue encounters, enemies,
   trait, skills, tests and Encounter Design Document entries stay for step 3.
3. **Done. Mini-boss node (code).** `Node_Type.MINI_BOSS`, a frequency on `AdventureLayout`,
   `mini_boss_battle_variants` on `AdventureData`; the three `Battle_Statue_*.tres` go into
   both Act 1 Adventures. The generator places one per chosen depth, forked depths first,
   and rolls each one's drop slot from the seed. The guaranteed drop is `LootTable` primary loot
   restricted to that slot from the Adventure's gear pool. Bait applies. Test placement and
   the slot-restricted drop.
4. **Done. Abort Adventure (code).** A top-left button in `Adventure.tscn` with a confirmation
   resets the run through `AdventureStateHandler.Reset()` and returns to the pre-adventure
   menu, refunding nothing. Test that the run state clears and difficulty progress stays.
5. **Quest board (design).** Settle: side quest encounter kinds and how each sets its loot
   budget; the values of X and Y; whether the board lives on the Region Map or in the hub;
   how a posted main quest looks and what it can point to; whether bringing a character
   type the player usually leaves out earns a larger loot budget, and if so how usage is
   measured (it needs per-Role usage tracking).
6. **Quest board (code).** A `QuestBoard` state object on the shop and Tally Board pattern:
   real-time restock, `stock_changed` to autosave, save serialization. A static board scene
   with a preallocated pool of quest rows; side quests launch their encounter from it,
   replacing `_on_experience_quests_pressed`. Main quest entries are a kind outside the
   timer and cap, exercised by one test entry. Test the timer, the cap, and the exemption.
7. **Unique node (code).** The 3.9 Unique node type: the generator can place it and its
   completion is recorded once. A main quest entry pointing to it completes with it. The
   Mandatory tag and what each Unique node unlocks belong to the progression plan.
8. **Hint node (design).** Keep, rework or cut it. Cutting it removes one of the boss
   hint's three channels (Encounter Design Document introduction), leaving the pre-battle
   tooltip and combat text.
9. **New node types (design).** A `/brainstorm`. A new type resolves in the Adventure scene
   or in combat, gives the player a real decision, interacts uniformly with every existing
   reader of node state, and is not a reskin of Rest Stop, Gamble or Escalate. Code steps
   are added once types are chosen.
10. **Adventure modifiers (design).** A modifier applies across node types, changing node
    costs, encounter starting conditions, or node behavior, and is shown on the Adventure
    screen. Settle: Adventure-wide or tied to biome zones (`AdventureBackgroundGenerator`
    already assigns zones); how many are active at once against the kit readability budget;
    how one shows on a node. Implementation fills the `NodeData.modifier` stub as a
    follow-up code step.

## Watch for

- No plan or step references in code comments, data comments or commit messages.
- UI is static scenes with typed `@export` references; repeated rows use preallocated pools.
- Tuning values (X, Y, loot budgets, mini-boss frequency) live in `.tres` files; exported
  script defaults stay neutral.
- No unlock gating or story ordering; leave hooks for the progression plan.
- Run the suite in both the default and `--mode playtest`.

## Documentation

Concept Document 3.6, 3.9, 5.1, 5.2.1 and 5.4; Technical Design Document sections 4 and
6.1.
