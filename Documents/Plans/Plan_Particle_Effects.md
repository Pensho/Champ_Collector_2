# Plan: Particle Effects

A living inventory of the particle effects the game needs, in two families: **battle
effects** (skill impacts, status-effect visuals, zone ambience) and **environmental
effects** (ambient life in the Adventure map and the hub scenes). Battle-side facts
come from `Concept_Document.md` 3.2.3 (status effects) and 3.2.4 (skills); the
Adventure map architecture is described in `Technical_Design_Document.md`. This
document is mostly design — it fixes which effects exist, what they attach to, and
the conventions for building them — but its infrastructure section names code work
that becomes its own implementation task when picked up.

## Status

Long-running — a living inventory. Entries are added when a skill, status effect, or
scene needs a visual, checked off when the effect scene is built and wired in, and
removed when they turn out not to be wanted. Expected to grow and shrink over time.

No hard dependency on other plans. Soft relationships:

- Data-driven status effects (completed) — the status-effect-to-particle mapping
  should ride on `StatusEffectData` (`Technical_Design_Document.md` section 6.1).
- `Adventure_Background_Visuals_Checklist.md` — the Tier 1 fog/mist patch and the
  `REST_STOP` campfire prop are tracked there as static art; this plan covers their
  animated counterparts and cross-references rather than duplicates them.

## Conventions (confirmed decisions)

- **Shared archetype library, not bespoke effects.** Battle effects are a small set
  of reusable archetype scenes; each skill or status effect maps to one archetype
  plus variation parameters (color ramp, texture, scale). A skill only gets a bespoke
  effect if no archetype fits, and that is a deliberate exception recorded here.
- **Implemented first.** Skills and status effects that exist in code get explicit
  archetype mappings; the design-only catalog stays in the backlog section and is
  promoted when implemented.
- **Scene authoring patterns** (from existing precedents):
  - Anchored effect: `Node2D` root with `CPUParticles2D` children — the campfire
    pattern in `Scenes/Hubs/Reclaimed_City_Scene/reclaimed_city_fire_particle.tscn`
    (flame + smoke emitters, gradient color ramps, curve-driven scale).
  - Screen-wide ambient effect: `GPUParticles2D` with a `ParticleProcessMaterial`
    emitting over a box — the falling-leaves node inline in
    `Scenes/Hubs/Reclaimed_City_Scene/Reclaimed_City.tscn`.
- **Default to the built-in particle nodes.** Every effect above is `CPUParticles2D` /
  `GPUParticles2D` configured through a `ParticleProcessMaterial` — no script. Reach for
  a scripted approach (a custom generator plus a view node) only when there's a concrete
  requirement the built-in nodes can't express — for example a placement problem that
  needs deterministic, per-instance data (the decor scatter in
  `AdventureBackgroundGenerator` is the precedent: it drives node-avoidance and region
  logic that a `ParticleProcessMaterial` has no way to express). Panning, looping,
  drifting, and size/color variation are all native to the particle nodes and are not
  such a requirement by themselves.
- **Testing follows from that split.** A built-in-particle-node effect is pure visual
  configuration with no logic of its own, so it carries no unit test — consistent with
  the project's "test pure logic, not rendering or node trees" rule
  (`Test_Design_Document.md`). A scripted effect's generator/placement logic is pure and
  does get a unit test, same as `AdventureBackgroundGenerator`; the node that turns its
  output into visuals still doesn't.
- **File locations:** battle effect scenes in `Scenes/Battle_Visual_Effects/`
  (currently holds the `burning_environment.tscn` stub); environmental effect scenes
  next to the hub scene they belong to; shared particle textures in
  `Assets/Champ_Collector/Particles/`.
- **Entry template.** Every effect entry records: **name**, **archetype** (battle) or
  **location/anchor** (environmental), **trigger** (what causes or anchors it),
  **texture/color notes**, and **status** — one of `needed` / `built` / `wired in`,
  written as a checkbox that is checked at `wired in`.

## Battle effect archetype library

Eight archetypes. Per-skill visual identity comes from variation parameters, not new
scenes. Mappings below cover the implemented skills
(`Data/Character_Skill_Variants/`) and the implemented status effects
(`Scripts/common_enums.gd`: Empower, Fortify, Daunting Strength, Phalanx Guard;
Burning, Enfeeble, Expose Weakness). Catalog-only skills are mapped in the backlog.

- [ ] **Physical impact** — burst of sparks/slash flecks at the target on hit.
  Variation: scale with hit weight, fleck texture.
  Serves: Stab, Bash, Crush, Heap On, Boarding Strike, Saltwater Shot,
  Corsairs Reckoning, Pierce Weakness, Break Guard, Disarm, Burning Bolas
  (impact part), and the opponents' physical hits. Status: needed.
- [ ] **Magic impact** — concentrated flash/mote burst at the target for
  magic-scaling hits. Variation: color per element/school.
  Serves: Zap (Speed-scaled, electric palette). Status: needed.
- [ ] **Fire ignition + burning tick** — ignition flare on application, plus a small
  persistent flame emitter on the character while Burning lasts (reuse
  `Fire_Particle.png`; palette from the campfire scenes).
  Serves: Burning debuff — applied by Burning Bolas and Lava Zone. The
  `burning_environment.tscn` stub is the natural home for the persistent part.
  Status: needed.
- [ ] **Buff application shimmer** — upward-drifting motes around the recipient,
  color-coded per buff (align colors with the status icons in
  `Assets/Champ_Collector/Icons/Status_Effects/`).
  Serves: Empower (Power Tide), Fortify (Stalwart Hymn), Daunting Strength
  (Fatal Flaw), Phalanx Guard (no applying skill yet). Status: needed.
- [ ] **Debuff application** — downward/cracking motes at the recipient, color-coded
  per debuff.
  Serves: Enfeeble (Disarm), Expose Weakness (Break Guard). Burning uses the fire
  archetype instead. Status: needed.
- [ ] **Heal/restore sparkle** — soft rising sparkles at the recipient. No
  implemented skill heals yet; first catalog carriers include Fateful Glimpse and
  Grafted Flesh. Status: needed (deferred until a heal is implemented).
- [ ] **Barrier/shield shimmer** — a brief enveloping shimmer on application and a
  faint persistent edge glow while the shield holds. No implemented carrier yet;
  first catalog carriers include Transfusion and Raise the Frame.
  Status: needed (deferred).
- [ ] **Zone ambience** — an on-field emitter marking an active zone for its
  duration. The turn-bar already has zone particles
  (`Scenes/ui/Turn_Bar_Zones/Turn_Bar_Lava_Zone.tscn`, `Turn_Bar_Bump_Good.tscn`);
  this archetype is the battlefield-side counterpart. Variation per zone family
  (order / unstable / momentum, Concept 3.2.4.1).
  Serves: Flicker Zone, Lava Zone. Status: needed.

## Battle effect infrastructure (future code work)

There is currently no way to show any of the above: `Skills.gd` resolves effects and
the only visual feedback is floating combat text (`battle_ui.gd::SpawnCombatText`),
status icons on the character representation, turn-bar particles, and the sprite-echo
system (`Scripts/Battle/character_visual_effects.gd`). Decisions, at requirement
level — this section becomes its own implementation plan when picked up:

- **Mapping data:** skills and status effects reference an archetype scene plus
  variation parameters (color ramp, texture, scale) as resource data, consistent with
  the project's data-driven `.tres` pattern — either a field on `Skill`
  (`Scripts/Character/skill_data.gd`) or a lookup table keyed by skill/status
  identifiers. Status-effect mappings can live directly on `StatusEffectData`
  (`Scripts/Battle/status_effect_data.gd`).
- **Spawner hook:** the resolve path (`Skills.gd::ResolveSkillEffect` /
  `ResolveZoneEffect`, driven by `battle.gd`) spawns the mapped archetype at the
  target's `Character_Battle_Repr`, alongside the existing `SpawnCombatText` calls.
- **Persistent emitters:** duration effects (Burning, future Barrier) attach an
  emitter to the character representation for their lifetime, not just an application
  burst — added and removed where status icons are added and removed today
  (`character_battle_repr.gd::AddStatusEffect`).

## Environmental effects: Adventure map

The Adventure background is composed at runtime in
`Scripts/UI/Adventure/adventure_graph_ui.gd::Populate` (ground gradient → roads →
decor → node UI). The decor layer is a static `_draw()` pipeline
(`adventure_background.gd`, fed by `adventure_background_generator.gd`) and cannot
animate — moving effects need a **new animated overlay**, plus **node-anchored**
instances for point effects. Two ways to attach an overlay, depending on whether it
should track the map or the screen:

- **Screen-fixed** (stays put regardless of scroll position): a bare particle node
  (no script) placed once in `Adventure_Graph_UI.tscn` as a sibling of the
  `ScrollContainer`, outside `_graph_canvas`. Needs no `Populate` wiring at all.
- **Scrolls with the map** (reads as part of the world, not a HUD sticker): must be a
  child of `_graph_canvas` instead, which means it needs re-instancing in `Populate`
  every call (that method clears and rebuilds `_graph_canvas`'s children each time) and
  sizing from the generated canvas, which varies with adventure depth — the cloud
  shadows entry below is the precedent for this case. Only reach for this script path
  when the overlay genuinely needs data `Populate` computes (canvas size, node
  positions, biome palette); a screen-fixed overlay stays the default.

Overlay layer (screen-wide, subtle — the map must stay readable):

- [x] **Cloud shadows** — large, soft, organic dark blobs drifting slowly across the
  map, scrolling with it, and looping indefinitely. `GPUParticles2D`
  (`Scenes/Adventure_Scenes/Adventure_Cloud_Shadows.tscn`) cycling a 4-frame baked
  sprite sheet (`Cloud_Shadow_sheet.png`, white/alpha-only) via `CanvasItemMaterial`
  flipbook animation, driven by a `ParticleProcessMaterial` (slow rightward drift,
  large uniform scale, fade-in/fade-out `color_ramp`). This is the scrolls-with-the-map
  case above, not the screen-fixed default: `AdventureGraphUi.Populate` instances it as
  a child of `_graph_canvas` every call and sizes the emission box, particle count, and
  `visibility_rect` from the generated canvas dimensions — plus a left-side spawn
  margin so clouds drift in from off-screen rather than only ever appearing already in
  view, and a scale-aware `visibility_rect` margin (derived from `scale_max` and the
  frame size) so oversized particles don't get culled once scrolled. See the texture
  inventory below for why the silhouette is a baked flipbook rather than a live
  generated texture. Status: wired in.
- [ ] **Birds** — sparse and occasional: a small flock takes off or crosses the map,
  then nothing for a while. Needs a small flipbook texture (wing beats) on a
  particle or animated overlay. Status: needed.
- [ ] **Fog/mist drift** — animated counterpart of the checklist's Tier 1 "Fog / mist
  patch" static art; slow-moving translucent patches, top layer. Coordinate with
  `Adventure_Background_Visuals_Checklist.md` so static patch and drift effect share
  textures. Status: needed.

Node-anchored:

- [ ] **Rest Stop campfire** — flame + smoke at Rest Stop nodes; generalize the
  campfire pattern from `reclaimed_city_fire_particle.tscn` into a shared scene
  rather than duplicating it a third time. Anchors via the per-node-type `node_props`
  concept in `BiomeVisualData` (the checklist's Tier 2 "`REST_STOP` - campfire +
  small tent/bedroll" entry is the static side of this). Status: needed.

Per-biome note: only the Reclaimed City biome is authored today
(`Data/Adventure_Data/Biome_Visuals/`). Where feasible, overlay effects should take
their palette from `BiomeVisualData` so future biomes tint them without new scenes.

## Environmental effects: hub scenes

One list per existing hub; entries are one-line suggestions to curate, not
commitments.

**Reclaimed City** (`Scenes/Hubs/Reclaimed_City_Scene/`) — already has the campfire
instance and the inline falling-leaves `GPUParticles2D`.

- [ ] Drifting pollen/dust motes in the air, very sparse. Status: needed.
- [ ] Occasional bird crossing the skyline (shares the Adventure birds texture).
  Status: needed.

**Adventurers Guild** (`Scenes/Hubs/Adventurers_Guild/`) — interior, no effects yet.

- [ ] Dust motes in light shafts. Status: needed.
- [ ] Hearth fire, if the background art has a plausible spot (reuse the shared
  campfire scene). Status: needed.

**Statue Selection** (`Scenes/Hubs/Statue_Selection/`) —
`Statue_Selection_fire_particle.tscn` exists but is **not instanced** in the scene.

- [ ] Wire the existing fire particle scene into `Statue_Selection.tscn`.
  Status: built, not wired in.
- [ ] Ember drift / mystical shimmer around the statues. Status: needed.

**Reclaimed City World Atlas** (`Scenes/Hubs/Reclaimed_City_World_Atlas/`) — map
screen; probably none. Kept as a section so a future idea has a home; remove entries
freely.

## Texture inventory

Which components need authored textures, and which are generated in-engine.

**Generated (no image file):** any particle that is a soft round blob — smoke, fog,
glow motes, generic magic flashes — uses a `GradientTexture2D` with radial fill, built
as a sub-resource in the effect scene. The campfire's smoke emitter already works this
way. Never leave a particle texture empty (that renders a hard white square). Cloud
shadows were attempted this way and moved to the authored/baked bucket below — see the
note under "Needed textures" for why.

**Authored (image file needed):** any particle with a recognizable silhouette.

Conventions, derived from the existing assets:

- **Color:** author textures **white (or grayscale) with alpha only** — all color
  comes from the emitter at runtime (`color_ramp` gradient, modulate).
  `Fire_Particle.png` is pure white; the campfire tints it through its
  yellow→orange→red gradient. One silhouette therefore serves many effects: the
  same spark fleck can be a physical impact (white-yellow), an ember (orange), or a
  debuff mote (sickly green). Effect-specific palettes are set per entry: the fire
  palette is already defined by the campfire gradient; buff/debuff application
  colors should key to the matching icons in
  `Assets/Champ_Collector/Icons/Status_Effects/`.
- **Dimensions:** particles render scaled far down (the campfire caps scale at
  0.2–0.3), so sizes stay small: **32×32** for simple flecks and silhouettes
  (`Leaf_1.png`), **64×64** for shaped particles with soft edges
  (`Fire_Particle.png`). Flipbooks are horizontal strips of the frame size
  (`Leaves_sheet.png` is 64×32 = two 32×32 frames), played via `CanvasItemMaterial`
  particle animation as in the Reclaimed City leaves node.
- **Location:** all shared particle textures in `Assets/Champ_Collector/Particles/`.

Needed textures (checked when the file exists in `Assets/`):

- [x] Flame tongue — `Fire_Particle.png` (64×64, white). Serves fire ignition,
  burning tick, campfires, ember drift.
- [x] Leaves — `Leaf_1.png`, `Leaf_2.png`, `Leaves_sheet.png`. Serves the falling
  leaves and pollen-adjacent drift.
- [x] Cloud shadow blobs — `Cloud_Shadow_sheet.png` (4 frames, 160×128 each, white/
  alpha). Baked rather than generated live: the outline comes from noise sampled
  around a circle in noise-space to perturb the blob's radius per angle (an organic,
  connected silhouette with no hard rectangular cutoff — a live `GradientTexture2D` /
  `NoiseTexture2D` read as an obvious ellipse or punched full holes, since a
  `color_ramp` can only map one noise value and can't multiply that by a radial
  falloff in the same texture); a second noise layer modulates interior density for
  cotton-ball texture. Serves the Adventure map cloud shadow overlay.
- [ ] Spark/fleck (32×32, white) — sharp-edged chip. Serves physical impact, ember
  drift, debuff motes.
- [ ] Four-point sparkle glint (32×32, white) — serves heal sparkle, buff shimmer,
  magic impact.
- [ ] Crack shard (32×32, white) — angular fragment. Serves debuff application and
  Expose Weakness / Break Guard flavor.
- [ ] Shield fragment / arc sliver (64×64, white, soft edges) — serves barrier
  shimmer.
- [ ] Bird flipbook (strip of four 32×32 frames = 128×32, dark silhouette) — wing
  beats for Adventure map and hub birds.
- [ ] Fog wisp (128×64, white, very soft alpha) — serves fog/mist drift; only if
  the generated radial blob reads too round. Coordinate with the checklist's
  static fog patch so both share one look.

## Backlog

Grows only when the corresponding skill, status effect, or scene is implemented; on
promotion an entry moves into the archetype mappings above.

**Catalog skills** (Concept 3.2.4.2–3.2.4.4, ~20 role kits): most map onto the
existing archetypes by their nature — physical-damage skills to physical impact,
magic-damage skills to magic impact, buff/debuff appliers to the application
shimmers, heals to the sparkle, shields to the barrier shimmer, zones to zone
ambience with the god-family variation. Expected genuine additions rather than
variations, worth bespoke or new-archetype treatment when their roles land:

- Damage-over-time ticks beyond Burning (Bleed, Plague) — likely one shared "tick"
  archetype with per-effect color.
- Turn-bar effects (Concept 3.2.3.1) — probably turn-bar UI visuals like the
  existing zone particles, not battlefield particles; decide when implemented.
- Signature spectacle skills (for example Cataclysmic Surge, Final Calculation,
  Devour Blessing) — candidates for the bespoke exception.
- Projectile-flavored skills (Blood Bolt, Profane Bolt, Burning Bolas) — a travel
  archetype (origin → target) does not exist yet; decide whether impact-only reads
  well enough before adding one.

**Future biome environmental effects** (Pirate Coves sea spray, Clockwork Spire soot
and steam, and so on): added when those biomes exist — out of scope until then.

## Watch for

- Ambient effects must stay subordinate to readability — the Adventure map is a
  playable graph first; effects sit below node UI and never obscure it.
- Particle counts: the campfire precedent runs two 500-particle `CPUParticles2D`
  emitters; screen-wide overlays should prefer `GPUParticles2D` and far lower counts.
- Naming allowlist: effect and scene names spelled out in full, no new acronyms.

## Documentation

This plan is the inventory's home and stays alive. The infrastructure section spawns
a separate implementation plan when picked up; architecture decisions made there land
in `Technical_Design_Document.md`. If a mapping decision changes skill design facts,
that is a conflict to flag — `Concept_Document.md` wins.
