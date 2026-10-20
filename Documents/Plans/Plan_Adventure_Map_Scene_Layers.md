# Plan: Adventure Map Scene Layers

`AdventureGraphUi.Populate` frees every child of `_graph_canvas` and rebuilds the whole map
each time `adventure_ui.gd` calls it: once in `Init` and again after every resolved node
interaction. The graph, node positions, seed and biome stay fixed for the whole adventure
scene, though. Only each node's completed/eligible state and the scroll target change. This
plan builds the map once per scene and makes the per-interaction call a refresh that touches
existing nodes only, as the UI scene conventions in `CLAUDE.md` require.

## Steps

### 1. Static layer nodes in `Adventure_Graph_UI.tscn`
Add `AdventureGround`, `AdventureEdgeLayer` and `AdventureBackground` as full-rect children
of `GraphCanvas`, in today's draw order (ground → roads → decor → node UI). Wire them as
typed `@export` variables on `AdventureGraphUi` and drop the three `preload` script
constants. A biome with no `BiomeVisualData` hides ground and background instead of skipping
their creation.

### 2. Split `Populate` into `Build` and `Refresh`
- `Build(p_nodes)`: computes positions and canvas size, calls `Generate` / `configure` /
  `set_edges` on the static layers, instances one `AdventureNodeUi` per node and connects
  its `node_selected` once. Called once from `adventure_ui.gd` `Init`.
- `Refresh()`: re-runs `AdventureNodeUi.Init` with the current eligibility for each built
  node and re-aims the scroll. Called from `Init` after `Build`, and from
  `_on_interaction_resolved` in place of `Populate`.
- Move node placement into a static pure function (nodes plus canvas width → positions and
  canvas height) so it can be tested.

The node UIs and road `Line2D`s are instanced at build time because their count follows
the generated graph (`AdventureLayout.MAX_DEPTH` plus branches is data, not a fixed
maximum). Nothing is instanced or freed in `Refresh`.

### 3. Per-biome ambient particles
Add `ambient_particles: PackedScene` to `BiomeVisualData` and set it to
`Adventure_Cloud_Shadows.tscn` on the Reclaimed City visuals. Empty means no ambient layer.
`Build` instances it under `GraphCanvas` above the decor and below the node UI, then sizes
it. The amount comes from the scene's own shipped `amount` scaled by canvas height over one
screen height, which replaces `CLOUD_SHADOWS_AMOUNT_PER_HEIGHT`. Move the emission box and
`visibility_rect` math into a static function testable without a scene tree. Remove
`CloudShadowsScene`.

### 4. Tests
- `test_adventure_graph_layout.gd`: positions are deterministic per node index, clamped
  inside the padding, and canvas height follows max depth.
- Ambient sizing: amount scales with canvas height and stays inside its clamp; the
  visibility rect covers the emission box plus the particle margin.
- Lint `Scripts/` and run the suite.

### 5. Documentation
- `Plan_Particle_Effects.md` "Environmental effects: Adventure map": the scrolls-with-the-map
  overlay becomes the biome's `ambient_particles` scene, built once per scene. Update the
  cloud shadows entry to match.
- `Test_Design_Document.md`: coverage for the new test file.

## Watch for
- `AdventureBackground` keeps a reference to the `_node_positions` dictionary and regenerates
  on `NOTIFICATION_RESIZED`. It must hold positions that are complete before the canvas
  resize lands. Hand it a finished dictionary that is never cleared afterwards.
- `AdventureEdgeLayer._Rebuild` appends lines without clearing old ones. That is safe only
  while `set_edges` runs once per scene.
- `AdventureGround.Generate` duplicates the biome's `ground_material`. Keep it that way so the
  shared `.tres` is never written to.
- `CLOUD_SHADOWS_LEFT_SPAWN_MARGIN` assumes a rightward drift. Keep it with the cloud sizing
  for now. A biome whose particles move another way generalizes it when that biome is built.
- Check whether `visuals_reclaimed_city.tres` inherits from `visuals_shared_base.tres` before
  choosing which one carries `ambient_particles`.
