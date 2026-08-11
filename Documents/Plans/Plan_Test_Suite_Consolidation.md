# Plan: Test Suite Consolidation

The GUT suite has grown to **134 files / 1015 tests / 7860 asserts** (green in 2.05s).
It grew by accretion: nearly every champion trait, graft, and skill kit got its own test
file, and those files re-test mechanisms a system-level test already covers. This plan
reorganizes the suite around **what can break** rather than **what content exists**, and
fixes the two documents that let the per-item growth happen unchallenged.

Runtime is not the problem — the suite is fast and fully green. The cost is authorship
and maintenance friction: adding a champion currently implies adding a test file, and
reading the suite gives a misleading picture of what is actually protected.

## Status

Analysis complete, nothing changed. Phases are checkboxes below.

No dependency on other plans. Soft relationship to `Plan_Role_Kit_Rework.md`: that plan
reworks all 20 Role skill kits, which under today's conventions would spawn a wave of new
per-kit test files. Landing at least Phases 3 and 5 of this plan **before** that rework
avoids authoring bloat that then has to be deleted again.

## The evidence

- **41 of 134 files are named after one content item** — 22 `test_*_trait.gd`, 18 graft
  files, plus per-champion kit files (`test_emissary_skills.gd`, `test_jester_skills.gd`).
  There are 23 character-specific traits and 18 grafts in
  `Scripts/Character/character_traits/` — close to one test file per content item.
- **44 test functions across 26 files are data-table restatements.**
  `test_lancer_trait.gd` `test_momentum_per_stack_table` copies `MOMENTUM_PER_STACK`
  into the test and asserts it equals itself. Such a test cannot fail except when
  someone edits both sides, so it detects nothing.
- **Per-graft rarity tests duplicate `test_graft.gd`.** `test_rootfeeder_graft.gd`,
  `test_living_bloom_graft.gd`, `test_detritivore_graft.gd` and peers each assert
  "bonus scales by rarity" / "has no attribute drawback"; `test_graft.gd`
  already covers exactly that as a mechanism of `GetAttributeDelta`.
- **Per-champion skill tests build replicas, not the real content.**
  `test_emissary_skills.gd` hand-assembles `Skill` / `DamageEffect` /
  `ApplyDebuffEffect` objects in GDScript instead of loading the shipped `.tres`. They
  therefore cover neither the shipped data (a typo in `Data/Character_Skill_Variants/`
  passes) nor the engine beyond what `test_skill_effects.gd` already tests directly.
- **`Test_Design_Document.md` no longer describes the suite.** Its "What we test" table
  lists 11 files; there are 134. No written rule governed the other 123.
- **`.claude/skills/new-champion/SKILL.md` prescribes the bloat.** Step 2 item 3 reads
  "Test: `Tests/unit/test_<name>_trait.gd`". This is the generator, and fixing it
  matters more than any single deletion.

## Conventions (confirmed decisions)

**Three tiers.** Every test belongs to exactly one, and the tier decides its shape.

- **Tier 1 — Mechanism tests.** One file per engine mechanism, parameterized over its
  cases. This is where thoroughness belongs. The exemplar already exists:
  `test_skill_effects.gd` has one section per effect class. Also `test_status_effect_hooks.gd`,
  `test_skill_effect_order.gd`, the `test_turn_bar_*` family, `test_targeting_order.gd`,
  `test_graft.gd`.
- **Tier 2 — Contract sweeps.** One data-driven test iterating *all* items of a kind,
  asserting a semantic invariant. Two exist already and are 26 and 32 lines:
  `test_character_preset_skill_invariant.gd` and `test_skill_resources.gd`. A sweep over
  23 traits catches more than 23 bespoke files did, in roughly 40 lines.
- **Tier 3 — Novel behavior.** A bespoke file survives only for behavior no other content
  has: `test_shield_wall_trait.gd`'s damage-redirect split, `test_standing_record_trait.gd`'s
  counter source, `test_detritivore_graft.gd`'s uncapped scrap stacks. Anything a trait
  shares with its peers (rarity scaling, "the hook fires", "does nothing when the owner is
  dead") drops to Tier 1 or Tier 2.

**Sweeps assert semantics, never cosmetics.** A Tier 2 sweep may assert that an authored
enum resolves in its registry, that a preset's skill references load, that a hook returns
a neutral value for a dead owner. It must **not** assert description wording, icon
not-null, non-empty strings, or expected row counts — that is out of scope under the
project's test-scope rule. `test_skill_icon_table.gd` (`test_expected_row_count`) violates
this today and is a deletion candidate on its own merits.

**Regression tests are preserved regardless of tier.** 13 files carry explicit regression
comments documenting real shipped defects — `test_character_skill_isolation.gd` (shared
`Skill` resource), `test_emissary_skills.gd` (`bonus_per` leaking onto every damaging
skill), `test_health_result_ordering.gd`, `test_targeting_order.gd`, `test_turn_bar_speed.gd`
and others. These are kept verbatim even where they look redundant: a regression test's
value is that the bug actually happened. If one moves file, its explanatory comment moves
with it.

**Consolidation is full, not partial.** All 134 files are audited and verdicts applied —
not only the obvious tautologies.

**Per-champion kit tests do not survive.** Their engine-level cases move into
`test_skill_effects.gd`, their content coverage moves to the `.tres` sweep, and the
replica-building files are deleted. Their regression tests carry over.

## Phases

### Phase 0 — Audit and classify (no code changes)

- [x] Produce `Documents/Plans/Test_Suite_Audit.md`: one row per test file with its tier
      and a verdict of `keep` / `keep-trimmed` / `fold-and-delete` / `delete`. All 134
      files audited by four parallel reads split by content family (traits, grafts +
      kit-skills, then the rest in two batches), cross-checked against the actual file
      list with no omissions or duplicates.
      Result: 87 `keep`, 26 `keep-trimmed`, 4 `fold-and-delete`, 3 whole-file `delete`.
      Two open judgment calls are flagged at the bottom of the audit for review before
      Phase 3 executes (the `test_pilfer_trait.gd` `RemoveBuff` tests, and the
      `test_battle_over.gd` UI-focus tests).
- [ ] This audit is reviewed and approved before any deletion lands. It is deleted with
      this plan on completion.

### Phase 1 — Strengthen Tier 1 where Tier 3 currently carries coverage

Move real coverage down into the mechanism tests *before* deleting anything.

- [ ] `test_skill_effects.gd` — add effect-level cases for condition mutual exclusion
      (`Below` vs `At_Least` on one threshold must produce exactly one attempt, so a
      single Aegis blocks it) and for `bonus_per` absence meaning no bonus. Both are
      genuinely engine-level and today live only in `test_emissary_skills.gd`.
- [ ] `test_graft.gd` — absorb the graft-hook dispatch and start-of-battle contract that
      the individual graft files each re-prove.
- [ ] `test_status_effect_hooks.gd` — absorb the "hook returns neutral when the owner is
      dead" contract, currently repeated per trait.

### Phase 2 — Add the Tier 2 sweeps

Both follow the shape of `test_skill_resources.gd`.

- [ ] `Tests/unit/test_trait_contract.gd` — instantiate every trait in
      `Scripts/Character/character_traits/CharacterSpecificTraits/` and every graft in
      `Grafts/`, `Init()` at each rarity, then assert the `CharacterTrait` hook contract:
      each of the ~40 hooks in `character_trait.gd` is callable without error, returns
      within its declared range, and returns the neutral value for a dead owner. Rarity
      monotonicity (Legendary at least Uncommon) is asserted here once, replacing the 44
      hand-copied tables.
- [ ] `Tests/unit/test_skill_content_sweep.gd` — load all 81 shipped `.tres` skills and
      assert every authored enum resolves: debuff types exist in the status-effect
      registry, condition and target enums are in range, `bonus_per` sources are known.
      This is coverage the suite does not have today, since the kit tests use replicas.
- [ ] Add any builders the sweeps need to `Tests/unit/helpers/test_factory.gd`.

### Phase 3 — Delete and fold, in reviewable batches

- [ ] Apply the Phase 0 verdicts, batched by content family: traits, then grafts, then
      skill kits. Each batch is a small reviewable diff.
- [ ] Run `./Tests/run_tests.sh` after every batch; never leave a batch red.

### Phase 4 — Rewrite the strategy so it does not regrow

- [ ] `Documents/Test_Design_Document.md` — replace the stale 11-row "What we test" table
      with the three-tier rule, plus a **"When adding content, do not add a test file"**
      section: new traits, grafts, and skills are covered by the Tier 2 sweeps by
      construction; a new file is justified only by genuinely novel mechanism (Tier 3) or
      by a fixed bug. Keep the determinism rules, file-naming, and helper sections as they
      are — they are still accurate.
- [ ] `.claude/skills/new-champion/SKILL.md` — Step 2 item 3 currently instructs
      "Test: `Tests/unit/test_<name>_trait.gd`". Replace with: verify the new trait passes
      the Tier 2 sweeps, and add a test file only if the trait introduces a mechanism no
      existing trait has.

## Verification

- `./Tests/run_tests.sh` green after every batch.
- Track the suite shape before and after: file count, test count, **and assert count**.
  Files and tests should fall substantially; **asserts should not fall proportionally** —
  a sweep runs many asserts from few tests. A large drop in asserts means real coverage
  was deleted rather than consolidated. Baseline: 134 / 1015 / 7860.
- Mutation spot-check on the new sweeps: temporarily break one trait's rarity table and
  one skill `.tres` enum, confirm `test_trait_contract.gd` and
  `test_skill_content_sweep.gd` fail, then revert. A sweep that cannot fail is worse than
  the tests it replaced.
- `gdlint Scripts/` if any `Scripts/` file changes (Phases 1–3 should not need it).

## Watch for

- **Deleting the only coverage of a real past bug.** The regression-comment rule is the
  guard; when in doubt, keep the test and note the overlap rather than deleting it.
- **Sweeps that pass vacuously.** A hook contract asserted over an empty iteration, or a
  `for` loop over a directory listing that silently finds nothing, looks green and proves
  nothing. Each sweep asserts a non-zero item count as its first assert.
- **Re-introducing static content checks.** The pull toward "assert every skill has a
  description" is strong when writing a sweep. It is out of scope.
- **Coupling the suite to the folder layout.** The sweeps scan
  `CharacterSpecificTraits/`, `Grafts/`, and `Data/Character_Skill_Variants/`. If content
  moves, the sweeps must fail loudly (zero items found), not silently skip.
- Naming allowlist: new test files and helpers spelled out in full, no new acronyms.

## Documentation

`Test_Design_Document.md` is rewritten by Phase 4 and is the living home for this
plan's content. `Technical_Design_Document.md` needs no change — the architecture is
untouched. When this plan completes, delete it and `Test_Suite_Audit.md`; nothing here
stays useful as a standalone reference once the strategy document carries the rule.
