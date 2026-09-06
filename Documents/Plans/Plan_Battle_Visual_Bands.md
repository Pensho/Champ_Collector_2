# Plan: Battle Visual Bands

Context-aware battle stages assembled from the four bands in `Art_Style_Guide.md` 10.3 —
Background, Midband, Floor, Foreground — so a fight in the Reclaimed City jungle is built
from jungle elements and a fight in the Pirate Coves shanty town from its own. Today
`Battle.Init` loads one flat texture path from `Context_Battle._location` into a single
`TextureRect`, and the four bands exist in `battle.tscn` only as hardcoded `ColorRect`
placeholders. This plan replaces that with a per-variant resource chain, an authored slot
rig, and a seeded resolver, and fills the `Not yet written` stubs the art guide leaves at
10.3.1–10.3.6 and 10.6.1–10.6.4.

## Status

Design confirmed, nothing implemented.

Soft dependency on `Plan_Lighting.md`: it owns `LightingProfile` as the generalization of
`Context_Battle`'s three loose light fields. This plan's variant resource references a
profile rather than declaring scene-light fields of its own, which is how the art guide's
"one scene light per variant" rule (10.2) is satisfied. Either plan can start first; the
wiring in Phase 6 needs `LightingProfile` to exist.

## Conventions (confirmed decisions)

- **A variant is the unit of context, and a variant is one `BiomeData`.** The art guide
  plans four areas of two variants each (10.6). Those eight variants are eight biome
  resources in code — the area is fiction and art direction, not a runtime object.
- **Selection is random, placement is authored.** Each variant owns two stage
  compositions with *different* slot layouts, and both draw from that variant's single
  shared element pool. Composition count rises to three only if two read as repetitive.
- **The empty center (10.1) is guaranteed by authoring, not by chance.** Slot positions
  are placed by hand clear of the character line; scattered clutter honours a keep-clear
  radius around each character slot.
- **No texture is shared between battle stages and the Adventure map.** The Adventure map
  is a different camera (10.7), so its elements are drawn to a different perspective. What
  transfers is the shape of the data — `DecorLayerData` is the template the floor band's
  scatter type copies.
- **The foreground weather pool is shared across every variant.** Rain, snow, fog and sun
  rays are screen overlays, not area vocabulary, and live in one shared resource
  alongside the per-variant foreground elements.
- **Per band:** Background is one plate per composition. Midband is slot-driven selection.
  Floor is one strip plate plus scattered clutter. Foreground is an overlay pool plus
  shared weather.
- **Bands are static nodes** per the project's UI scene conventions: a preallocated slot
  pool authored in `battle.tscn`, filled and hidden by script. Floor clutter is the
  exception and draws through `_draw()`, following `AdventureBackground`.
- **Stage selection reuses `Battle.BattleSeed()`**, so a fight re-entered after a flee
  renders the same stage, and a hand-authored encounter randomizes.

## Phase 1 — Resource chain

New types under `Scripts/Battle/Visuals/`, authored resources under
`Data/Battle_Data/Stage_Visuals/` (new subfolder under the existing `Data/`).

- [ ] `StageVisualData` — the full battle look of one variant: `compositions:
  Array[StageCompositionData]`, `element_pool: Array[StageElementData]`,
  `floor_clutter: Array[StageClutterEntry]`, `foreground_elements:
  Array[StageElementData]`, `lighting_profile: LightingProfile`.
- [ ] `StageCompositionData` — one authored layout: `name: String`,
  `background_plate: Texture2D`, `floor_plate: Texture2D`, `slots: Array[StageSlotData]`.
- [ ] `StageSlotData` — one midband position: `position: Vector2`, `scale: float`,
  `flip_allowed: bool`, `tags: Array[String]` (a slot accepts only pool elements sharing
  a tag, so a canopy slot never draws a low shrub).
- [ ] `StageElementData` — one element: `textures: Array[Texture2D]` (variants),
  `tags: Array[String]`, `scale_min`/`scale_max`, `rotation_jitter_degrees`,
  `allow_horizontal_flip`, `tint`, `selection_weight`.
- [ ] `StageClutterEntry` — floor scatter rule, mirroring `DecorLayerData`: `textures`,
  `density`, `scale_min`/`scale_max`, `rotation_jitter_degrees`,
  `allow_horizontal_flip`, `tint`, `character_avoidance_radius`.
- [ ] `BiomeData.stage_visuals: StageVisualData` added alongside the existing
  `visual_data`.

## Phase 2 — Slot rig in `battle.tscn`

- [ ] Replace the four `ColorRect` placeholders with named band nodes in draw order,
  the character representations sitting between Floor and Foreground.
- [ ] Preallocate a midband slot pool as `Sprite2D` children at the maximum slot count
  across all authored compositions, wired to `battle.gd` by typed `@export`.
- [ ] Preallocate a foreground overlay pool the same way.
- [ ] Background and floor plates are one `TextureRect` each.
- [ ] Keep the existing normal-mapped `BattleBackground` path working until Phase 6
  retires it.

## Phase 3 — Composition resolver

- [ ] `StageComposer` (`Scripts/Battle/Visuals/stage_composer.gd`) — a pure static
  `Compose(p_visuals: StageVisualData, p_seed: int) -> StageComposition`, no node
  access, following `AdventureBackgroundGenerator`'s shape.
- [ ] Picks one composition, then per slot picks a tag-matching pool element by
  `selection_weight` and rolls its scale, rotation and flip.
- [ ] Returns a plain result object the view applies to the preallocated nodes.
- [ ] Tests in `Tests/unit/test_stage_composer.gd`: the same seed composes identically
  and different seeds diverge; every filled slot's element shares a tag with its slot;
  selection weight is respected across many seeds; a pool with no tag match for a slot
  leaves that slot empty rather than erroring.

## Phase 4 — Floor clutter

- [ ] `StageClutterGenerator` — pure static `Generate(p_entries, p_floor_rect,
  p_character_positions, p_seed) -> Array[DecorPlacement]`, reusing the existing
  `DecorPlacement` type.
- [ ] A thin `Control` view under the Floor band draws the placements via `_draw()`,
  mirroring `AdventureBackground`.
- [ ] Tests in `Tests/unit/test_stage_clutter_generator.gd`: no placement falls inside a
  character's avoidance radius; placements stay within the floor rect; the same seed
  generates the same placements.

## Phase 5 — Foreground and weather

- [ ] `StageWeatherData` — the shared overlay pool, one authored resource under
  `Data/Battle_Data/Stage_Visuals/`.
- [ ] Composition declares which weather entry (if any) it uses; the resolver fills the
  foreground overlay pool from the variant's foreground elements plus that entry.
- [ ] Foreground draws as flat silhouette per 10.3.4 — no overlay crosses a character
  slot until the art guide's coverage rule says one may.

## Phase 6 — Wiring and retirement

- [ ] `Context_Battle._location: String` retires in favour of `_stage_visuals:
  StageVisualData`; `Battle.Init` composes through `StageComposer` with `BattleSeed()`.
- [ ] `_global_scene_light`, `_global_scene_darkness` and `_scene_darkness_height` retire
  from `Context_Battle`; the light comes from `StageVisualData.lighting_profile`.
- [ ] `AdventureGenerator` stamps the biome's `stage_visuals` onto each generated
  `Context_Battle` (both construction sites).
- [ ] `DebugCatalog.BATTLE_CONTEXTS` entries get an explicit variant.
- [ ] One default `StageVisualData` covers a context that names none.
- [ ] Full suite green, `gdlint Scripts/` clean.

## Phase 7 — Authoring pass

- [ ] Reclaimed City Jungle first, end to end: two compositions, an element pool, floor
  clutter, a lighting profile. This is the pass that proves two compositions are enough.
- [ ] Placeholder flat-color art is acceptable here; real art is a separate backlog, and
  the checklist for it belongs with the art documents rather than this plan.

## Phase 8 — Documentation

- [ ] `Art_Style_Guide.md` 10.3.1–10.3.6 — fill the six stubs with the per-band strategy,
  the slot/pool rule, and the reuse rule.
- [ ] `Art_Style_Guide.md` 10.2 — Magic Ruins becomes Reclaimed City variant B; the scene
  light table gains a row per variant; the paragraph flagging the table as predating the
  four-area plan is deleted.
- [ ] `Art_Style_Guide.md` 10.3.5 — the battle camera does not scroll, so this states
  shake response and haze position, not scroll ratios.
- [ ] `Art_Style_Guide.md` 10.6 — Pirate Coves keeps the candle-lit shanty town as variant
  B; 10.6.1–10.6.4 gain their per-variant entries as each is authored.
- [ ] `Art_Style_Guide.md` 10.7.4 — resolved: a run keeps its source variant's light,
  and the ember-dusk reservation is deleted.
- [ ] `Technical_Design_Document.md` section 4 and 6 — the resource chain and the
  variant resolution path, linking to the art guide rather than restating it.
- [ ] `Adventure_Background_Visuals_Checklist.md` — the "five live biomes (Reclaimed
  City, Pirate Coves, Clockwork Spire, Holy City Plains, Glass Weald)" line predates the
  four-area/eight-variant plan and is corrected.

## Watch for

- The Iron Ledger's white inner city (10.6) is a light-dominant midband against dark
  characters. Resolve the treatment before authoring that variant, not during.
- Slot layouts differ per composition, so the preallocated pool is sized to the maximum
  across compositions and unused slots hide. Adding a composition with more slots than
  the pool holds is a scene edit, not a data edit.
- `Context_Battle` is a hand-authored resource in several places; retiring `_location`
  touches every authored context, not only the generated ones.
