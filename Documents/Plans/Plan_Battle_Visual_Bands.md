# Plan: Battle Visual Bands

A battle stage is a hand-authored scene under `Scenes/Battle_Stages/`, laying out the four
bands of `Art_Style_Guide.md` 10.3 — Background, Midband, Floor, Foreground — as static
nodes. `battle.tscn` instances one under `Stage_Anchor`. The plan covers eight to twelve
stages across the four Acts, two or three per Act.

## Conventions (confirmed decisions)

- **Every element is an authored node.** A stage is placed and judged in the editor. The
  only runtime work is floor clutter, which needs character positions the stage scene
  cannot know.
- **Draw order is Background, Floor, Midband, characters, Foreground** — not the
  Background/Midband/Floor the art guide's 10.3 lists. Midband elements stand on the
  ground, so their bases must cover the floor's top edge; drawing the floor last cuts a
  hard horizontal line across every trunk and shrub. The foreground band carries
  `z_index = 10` so it draws over the characters, which `battle.tscn` holds outside the
  stage instance.
- **The empty center (10.1) is guaranteed by authoring.** Elements are placed by hand clear
  of the character line; scattered clutter honours a keep-clear radius around each
  character's feet.
- **Floor clutter is scattered, not placed.** `StageClutterView` holds the stage's
  `StageClutterEntry` rules in the inspector and draws the placements
  `StageClutterGenerator` produces, seeded from `Battle.BattleSeed()` so a fight re-entered
  after a flee scatters identically. It runs in the editor, with no characters to keep
  clear of, so clutter is visible while a stage is laid out.
- **No texture is shared between battle stages and the Adventure map.** The Adventure map
  is a different camera (10.7), so its elements are drawn to a different perspective.
- **Weather is per encounter, not per stage.** `Context_Battle._environment_effects` plays
  under `Weather_Anchor`, in front of the foreground band, so an indoor fight stays dry on
  a stage otherwise used outdoors. Each effect is a particle scene per
  `Plan_Particle_Effects.md`.
- **An encounter names its own stage.** `Context_Battle._stage_scene` selects it, null
  falling back to `battle_stage_default.tscn`. `AdventureGenerator` picks one from
  `BiomeData.stage_scenes` for each generated encounter.

## Authoring

- [ ] Reclaimed City, two stages. Both are one `BiomeData`; the area is fiction and art
  direction, not a runtime object.
- [ ] The remaining three Acts, two or three stages each.
- [ ] Placeholder flat-color art lives in `Assets/Battle_Visual_Elements/Placeholders/`.
  Real art is a separate backlog, and its checklist belongs with the art documents.

## Documentation

- [ ] `Art_Style_Guide.md` 10.3.1–10.3.6 — fill the six stubs with the per-band strategy
  and the reuse rule.
- [ ] `Art_Style_Guide.md` 10.3 — correct the band draw order.
- [ ] `Art_Style_Guide.md` 10.2 — Magic Ruins becomes a Reclaimed City stage; the scene
  light table gains a row per stage; the paragraph flagging the table as predating the
  four-area plan is deleted.
- [ ] `Art_Style_Guide.md` 10.3.5 — the battle camera does not scroll, so this states shake
  response and haze position, not scroll ratios.
- [ ] `Art_Style_Guide.md` 10.6 — Pirate Coves keeps the candle-lit shanty town;
  10.6.1–10.6.4 gain their entries as each stage is authored.
- [ ] `Art_Style_Guide.md` 10.7.2 and 10.7.4 — the battle band catalog is authored per
  stage rather than generated; a run keeps its source area's light, and the ember-dusk
  reservation is deleted.
- [ ] `Technical_Design_Document.md` sections 4 and 6 — the stage scene and how a battle
  resolves one, linking to the art guide rather than restating it.
- [ ] `Adventure_Background_Visuals_Checklist.md` — the "five live biomes (Reclaimed City,
  Pirate Coves, Clockwork Spire, Holy City Plains, Glass Weald)" line predates the
  four-area plan and is corrected.

## Watch for

- The Iron Ledger's white inner city (10.6) is a light-dominant midband against dark
  characters. Resolve the treatment before authoring that stage, not during.
- The scene light stays three loose fields on `Context_Battle`; `Plan_Lighting.md` owns
  collapsing them into `LightingProfile`.
