# Plan: Lighting

A systemized 2D lighting design covering the three lit scene families: **battle
scenes**, the **Adventure map**, and the **hub scenes**. Lighting today exists only in
`Scenes/ui/Battle_UI/battle.tscn` — an ad-hoc `DirectionalLight2D` used as a global
darkness layer plus one warm `PointLight2D`, driven per encounter by three loose fields
on `Context_Battle` (`Scripts/Worldview/Context_Battle.gd`). This plan generalizes that
proven pattern into one shared system: a single mood data type, a reusable scene rig,
one script for all animated ("living") lights, and a small archetype library mirroring
the particle archetype convention in `Plan_Particle_Effects.md`.

## Status

Design confirmed, nothing implemented. Foundation and rollout steps are tracked as
checkboxes below; entries are checked when built and wired in.

No hard dependency on other plans. Soft relationships:

- `Plan_Particle_Effects.md` — lights that pair with particle emitters (campfire,
  torch) live inside the particle scene so the pair travels as one node; this plan
  owns the light half, that plan owns the emitter half.
- `Adventure_Background_Visuals_Checklist.md` — its "glow accent" static art entries
  (Soot-Glass deposit, Prism-Salt crystal cluster) get their animated counterparts
  from this plan's accent and pulse archetypes.

## Conventions (confirmed decisions)

- **Per-scene mood only — no day/night cycle.** Each battle encounter, biome, and hub
  declares its lighting state as data. A future time-of-day cycle layers on as
  interpolation between two profiles per frame; nothing in the schema precludes it,
  and nothing here designs it.
- **No new normal maps for now.** The system must read well through color, energy,
  and motion alone. The one existing normal-mapped battle background
  (`Troll_battle_area_2_Normal_Map.jpg` via `CanvasTexture`) keeps working for free
  because the rig uses real light nodes; future normal maps slot in without changes.
- **One mood data type: `LightingProfile`** (`Scripts/Lighting/lighting_profile.gd`,
  `Resource`). Fields: `darkness_color: Color`, `darkness_height: float`,
  `ambient_light_color: Color`, `ambient_light_energy: float`. A pure static
  `Resolve(p_base, p_override) -> LightingProfile` picks the override when non-null.
  Authored profiles live in `Data/Lighting/` (for example `lighting_daylight.tres`,
  `lighting_cavern.tres`, `lighting_reclaimed_city_evening.tres`).
- **One ambient rig: `Scenes/Lighting/Scene_Lighting.tscn`** (script
  `scene_lighting.gd`, `class_name SceneLighting`, method
  `Apply(p_lighting_profile: LightingProfile)`). It wraps the existing battle
  pattern: a `DirectionalLight2D` with subtract blend as canvas darkness plus a
  large soft `PointLight2D` as ambient fill. **Not `CanvasModulate`:**
  `CanvasModulate` tints everything in the canvas including UI (this project's UI
  shares the canvas with the world), and the existing
  `Assets/Champ_Collector/Material/Unshaded.tres` escape hatch protects against
  lights but not against `CanvasModulate`; also only real lights drive normal maps.
- **Documented exception — Adventure map ambient is `modulate`, not a light.** The
  map lives inside a `ScrollContainer` embedded in a larger UI screen, and a
  `DirectionalLight2D` is canvas-wide — it would leak darkness onto the surrounding
  UI. Instead, `Populate()` multiplies the graph canvas `modulate` by the tint
  derived from the biome's `LightingProfile`. Same data, different applicator, zero
  light slots; additive accent point lights still brighten above it.
- **One script for all living lights: `LivingLight`**
  (`Scripts/Lighting/living_light.gd`, `extends PointLight2D`). Exports:
  `base_energy: float`, `amplitude: float`, `speed: float`, `waveform` (enum —
  `FLICKER_NOISE` for fire, `PULSE_SINE` for magic), optional
  `secondary_color: Color` + `color_blend_amount: float` for hue breathing, and
  `seed_offset: int` so neighboring instances desynchronize deterministically.
  `_process` only evaluates the waveform and assigns `energy`/`color`.
- **Waveform math is pure and testable: `LightWave`**
  (`Scripts/Lighting/light_wave.gd`, static functions only). `Pulse(p_time, p_speed)`
  and `Flicker(p_time, p_speed, p_seed)` both return values in [-1.0, 1.0],
  deterministic from their inputs (layered sines and a hash — no
  `RandomNumberGenerator` state).
- **Archetype library, not bespoke lights.** Pre-tuned scenes in
  `Scenes/Lighting/Archetypes/`; a scene gets a bespoke light only when no archetype
  fits, recorded here as a deliberate exception. All archetypes share the existing
  radial texture `Assets/Champ_Collector/Light/Point_Light.tres` — one texture,
  varied by color, energy, and scale.
- **No custom light-mask scheme.** Lights and world items keep default masks; the
  Mobile renderer light budget is too small to spend on mask gymnastics. Nodes that
  must never be lit (UI text, buttons, bars) get the existing `Unshaded.tres`
  material (the battle UI precedent) or `light_mask = 0` where a material slot is
  already taken. The current battle light's meaningless
  `light_mask = 1024` / `visibility_layer = 1024` is normalized to defaults during
  migration.
- **Mobile renderer light budget.** The darkness and ambient fill lights already
  consume two of the per-item light slots on every lit item. Rule: at most ~6
  accent/living lights overlapping any one item, soft cap ~8–10 lights per scene
  total; merge clustered glows into one larger light rather than one per prop.
  `shadow_enabled` stays off everywhere — there are no occluders to justify it.
- **Testing follows the pure-logic rule.** `LightWave` and
  `LightingProfile.Resolve` get GUT tests; the rig and archetype scenes are visual
  configuration and get none (`Test_Design_Document.md`).
- **Entry template.** Rollout entries record: **name**, **target files/scenes**,
  **what to watch for**, and **status** — `needed` / `built` / `wired in`, written as
  a checkbox checked at `wired in`.

## Light taxonomy

| Kind | Mechanism | Examples |
|---|---|---|
| Static ambient | `Scene_Lighting` rig (graph-canvas `modulate` on the Adventure map) | daylight, dusk, cavern gloom |
| Static accent glow | plain `PointLight2D` archetype, constant energy | window glow, mineral deposit sheen |
| Living flicker | `LivingLight` + `FLICKER_NOISE` | torch, campfire, brazier |
| Living pulse | `LivingLight` + `PULSE_SINE` | crystal glow, magical statue |

Archetype scenes (`Scenes/Lighting/Archetypes/`): `Torch_Light.tscn`,
`Campfire_Light.tscn` (larger, warmer, slower flicker), `Crystal_Glow_Light.tscn`
(cool pulse), `Accent_Glow_Light.tscn` (static, low energy).

## Interaction with other visual components

- **Particles:** a light paired with an emitter is a child of the particle scene
  (for example a `Campfire_Light` inside
  `Scenes/Hubs/Reclaimed_City_Scene/reclaimed_city_fire_particle.tscn`), matching
  the particle plan's anchored-effect pattern — one instanced scene gives both glow
  and flame.
- **Cloud shadows:** additive accent light hitting the translucent shadow blobs is
  expected and acceptable; revisit only if it visibly reads wrong.
- **Biome palettes:** `BiomeVisualData`
  (`Scripts/Adventure_Scripts/Visuals/biome_visual_data.gd`) gains
  `@export var lighting_profile: LightingProfile`, so each biome carries its mood
  next to its palette.
- **Battle context:** `Context_Battle` gains
  `@export var _lighting_profile: LightingProfile` and drops the three loose fields
  (`_global_scene_light`, `_global_scene_darkness`, `_scene_darkness_height`) once
  the five `Data/Battle_Variants/*.tres` are migrated. `battle.gd` replaces its
  three assignments with one `SceneLighting.Apply` call, falling back to a default
  profile when the context's is null.

## Rollout

### 1. Foundation

- [ ] **Lighting scripts** — `Scripts/Lighting/`: `lighting_profile.gd`,
  `light_wave.gd`, `living_light.gd`, `scene_lighting.gd`. Watch for: type hints
  everywhere, gdlint clean, PascalCase function names. Status: needed.
- [ ] **Rig and archetype scenes** — `Scenes/Lighting/Scene_Lighting.tscn` plus the
  four archetypes under `Scenes/Lighting/Archetypes/`, all sharing
  `Point_Light.tres`. Status: needed.
- [ ] **First profiles** — `Data/Lighting/lighting_daylight.tres` and one moody
  profile (for example `lighting_cavern.tres`). Status: needed.
- [ ] **Unit tests** — `Tests/unit/test_light_wave.gd` (range, determinism, seed
  divergence, pulse period) and `Tests/unit/test_lighting_profile.gd` (`Resolve`
  override/base/null behavior). Status: needed.

### 2. Battle migration

- [ ] **Replace the ad-hoc battle lights** — `Scenes/ui/Battle_UI/battle.tscn`: swap
  the `DirectionalLight2D` + `PointLight2D` pair for a `Scene_Lighting` instance;
  keep the normal-mapped `CanvasTexture` background untouched; normalize the stray
  `1024` masks. Status: needed.
- [ ] **Context and data migration** — `Scripts/Worldview/Context_Battle.gd` (add
  `_lighting_profile`, remove the three loose fields),
  `Scripts/Battle/battle.gd` (single `Apply` call with default-profile fallback),
  migrate all five `Data/Battle_Variants/*.tres`. Watch for: each variant's current
  light/darkness colors must be preserved into its new profile resource.
  Status: needed.

### 3. Hubs

- [ ] **Reclaimed City** — `Reclaimed_City.tscn` gets a `Scene_Lighting` instance
  with `lighting_reclaimed_city_evening.tres`; a `Campfire_Light` goes inside
  `reclaimed_city_fire_particle.tscn`; navigation buttons and the resource bar get
  `Unshaded.tres` where not already protected. Status: needed.
- [ ] **Statue Selection** — rig plus a `LivingLight` paired with
  `Statue_Selection_fire_particle.tscn` (which the particle plan wires in);
  consider a `Crystal_Glow_Light` pulse on the statues. Status: needed.
- [ ] **Adventurers Guild** — rig with a warm interior profile; hearth light if the
  particle plan's hearth fire lands. Status: needed.

### 4. Adventure map

- [ ] **Biome profile field** — `biome_visual_data.gd` gains `lighting_profile`;
  author it for `Data/Adventure_Data/Biome_Visuals/` Reclaimed City.
  Status: needed.
- [ ] **Ambient modulate in Populate** —
  `Scripts/UI/Adventure/adventure_graph_ui.gd::Populate` derives the graph-canvas
  `modulate` tint from the resolved biome profile. Watch for: node markers and
  labels staying readable — compensate with `Unshaded.tres` or `self_modulate` on
  `Adventure_Node_UI.tscn` if a dark biome washes them out. Status: needed.
- [ ] **Node-anchored accent lights** — `Campfire_Light` at Rest Stop nodes (rides
  the particle plan's shared campfire scene), `Crystal_Glow_Light` /
  `Accent_Glow_Light` where the checklist's glow-accent props (Soot-Glass,
  Prism-Salt) are placed. Watch for: the per-item overlap budget when several lit
  nodes cluster. Status: needed.

## Backlog

- Future biome profiles (Pirate Coves, Clockwork Spire, Under-Spire Grease-Pits —
  strong atmospheric candidates per `Concept_Document.md` lore): authored when those
  biomes exist.
- A softer-falloff light texture variant, only if `Point_Light.tres` proves too
  hard-edged for large ambient fills.
- Day/night or story-beat lighting variation: interpolate between two
  `LightingProfile` resources driving `SceneLighting.Apply`; take up only if a
  gameplay reason appears.
- Normal maps for further battle backgrounds: deferred by decision; the rig
  supports them without changes when the art cost is worth paying.

## Watch for

- Readability first: darkness levels must never make node markers, labels, or
  battle UI hard to read; `Unshaded.tres` is the standing escape hatch.
- The Mobile renderer per-item light cap: darkness + ambient fill always occupy two
  slots, so accent lights are budgeted, not sprinkled.
- Living-light motion should be felt, not seen: flicker amplitudes stay small
  (roughly 10–20% of base energy); a strobing torch is worse than a static one.
- Naming allowlist: all lighting scripts, scenes, and resources spelled out in
  full, no new acronyms.

## Documentation

When implementation lands: update `Technical_Design_Document.md` where it names
context-carried lighting (the encounter-context field list and the battle scene
description) to reference `LightingProfile` and `SceneLighting`; cross-reference the
paired light/emitter convention in `Plan_Particle_Effects.md`; note the animated
counterparts of the glow-accent entries in
`Adventure_Background_Visuals_Checklist.md`. Ambient mood choices per biome/hub are
design facts — if one contradicts `Concept_Document.md` lore, flag it rather than
silently picking.
