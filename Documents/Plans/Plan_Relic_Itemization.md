# Plan: Relic Itemization

Moves Relic off the rarity ladder and onto a second, orthogonal axis: an **item type**
(Standard or Relic) that decides what a rarity step buys. A Relic occupies one of the same
slots, carries its own rarity from Common to Legendary, and trades attribute steps for a unique
effect and a fixed drawback.

Design only — this plan authors no code. The mechanism is owed separately; the entry in
`Plan_System_Buildout.md` tracks it.

## Status

Created 2026-08-21. Phases 1 and 4 are complete. Phases 2–3 are the brainstorm pass and have not
started; they run against Phase 1's settled wording.

## Why the axis moves

`Relic` is the sixth value of `Types.Rarity`. That placement gates it behind a 28,268 loot budget
(`LootManager.RARITY_WEIGHTING`), which `CalculateBudget()` only reaches near difficulty 17 of
20, and the shop excludes it outright. `EquipmentPreset.Setup()` skips attribute rolling for it
and no unique-effect mechanism exists, so a dropped Relic today is strictly worse than the
Legendary it outranks. A Relic is not "more gear" — it is a different trade, and a trade the
player should meet from the first hour rather than once, at the end.

## Phase 1 — The contract

Rewrites the authoritative wording. Net-neutral: superseded text is deleted, not left standing.

- **`Concept_Document.md` 3.3.1** — the bulk. Relic leaves the rarity list; the item-type axis
  and its per-type table replace it. The **Gear verdict** paragraph loses its "single exception
  is Relic rarity's unique effect" framing. Adds the conditional-upside rule, the multi-Relic
  bound, and the acquisition rule. **Done.**
- **`Concept_Document.md` 2.1** — "loot ranging from Common to Relic rarity" → Common to
  Legendary.
- **`Concept_Document.md` 3.1** — delete "there will be no Relic tier Characters, that tier level
  is restricted for Items"; no Relic tier exists to restrict.
- **`Concept_Document.md` 3.6.4** — the shop's three gear slots roll item type on the same flat
  5%; a Relic carries a higher markup. No new stock slot.
- **`Concept_Document.md` 3.8** — the reward-value mapping stays keyed by rarity alone; item type
  sits outside the budget as a flat conversion roll.
- **Trinket leaves committed scope.** 3.3.1's core loadout is three slots (Weapon, Off-Hand,
  Boots); Trinket joins the seven not-in-scope slots, and the talent-tree-gated fourth slot moves
  to `FeatureIdeas.md`. 2.2's "rare Trinkets" becomes rare Relics. The ceiling paragraph drops its
  Trinket-exclusion parenthetical, which existed only to explain the four-slot gap.

## Phase 2 — The catalog

A brainstorm pass, run against Phase 1's settled wording. Output lands in a new
`Relic_Design.md`, which outlives this plan as the living balancing reference for every Relic —
the same role `Role_Kit_Design.md` plays for kits. It opens with a one-line pointer to 3.3.1 for
the contract and does not restate it.

A first batch of **12 Relics**, four per slot (Weapon, Off-Hand, Boots). Each entry names its
slot, its unique effect and how rarity ladders the magnitude, its fixed drawback, its channel
tag, and the character-trait-vocabulary hook it fires on.

Every entry in this batch is a **general drop** — no Relic is tied to a named boss. Boss-specific
Relics are a later addition, once bosses exist to carry them.

Channel spread across the batch: at least four [Channel 2], three [Channel 3 — Cascade], three
[Enabler], with dual tags where a mechanism genuinely serves two roles.

Favour intricate conditions — on crit, on a death, while a named status is present, on a
threshold crossing — over lightly-conditioned flat bonuses. At most one or two entries sit at the
simple end.

## Phase 3 — The audit ledger

One row per Relic in `Relic_Design.md` recording its 1.1.6 verdict: which of the two routes it
passes by (multiplies with something else in play, or gates a burst that fails without it), plus
the worst-case three-slot product for the batch.

If that worst case cannot be held under 3.3.1's published contrast figure by conditionality
alone, a stated cap on equipped Relics ships instead of the no-cap rule, and 3.3.1 records
whichever shipped — not both.

## Phase 4 — Backlog

- `Remaining_Scope_Checklist.md` — "implement Relic rarity tier" no longer describes the work;
  restate against the new contract.
- `Plan_System_Buildout.md` — rewrite the Relic coverage-gap entry. Its premise (Relic rarity as
  the sole sanctioned gear-sourced factor) is superseded; the entry now points at the settled
  contract and names only the code mechanism as owed. Its Trinket entry is deleted — Trinket is
  no longer scope, and its latent `Equipment.Upgrade()` crash is recorded in the `FeatureIdeas.md`
  entry instead.
- `FeatureIdeas.md` — the Trinket slot as a candidate feature.
- `Plans/README.md` — index entry for this plan; the buildout plan's summary drops Trinket.

## Watch for

- **The gear ceiling is an upper bound, not a target.** A Relic displaces a standard item and
  rolls fewer attribute steps, so a Relic loadout sits below 3.3.1's published Channel 1 ceiling.
  No recalibration of `Scripts/Debug/blowout_calibration.gd` is needed; what rises is Channel 2/3.
- **The main code expense, for whoever writes the mechanism plan:** character-trait dispatch is
  wired to a single `_trait` field across roughly forty call sites in `Scripts/Battle/`. Serving a
  character's trait *plus* their equipped Relic effects means routing those through a collection.
- Enabler-identity Relics with no damage factor are a full pass, not a weak entry.
- Drawbacks must not pressure the owner into building Accuracy; that attribute is already
  overloaded.
- Fatigue/Stun-class denial cannot ride a Relic without a severe drawback, per the
  puzzle-breaking-status policy in `Role_Kit_Design.md` 10.1.
- Build-specific upsides (crit, for instance) need deliberate targeting, not automatic or
  positional triggers.
- The eight-status cap is a readability constraint; a Relic applying statuses competes for those
  slots and gets no exemption.
