# Adventure Background Visuals Checklist

Art asset backlog for the adventure-map background decoration system (see
`BiomeVisualData` / `DecorLayerData` in `Scripts/Adventure_Scripts/Visuals/`). Elements
are scattered with noise (Tier 1/3) or placed per node (Tier 2) over the adventure graph
canvas. Suggested asset folders: `Assets/Adventure/Background/<biome_slug>/` and
`Assets/Adventure/Background/Shared/`.

Each entry is one logical sprite that may ship as 2-4 minor variants for visual variety.

## Tier 1 - Generic / shared (biome-agnostic, build first)

- [x] Grass tuft (short) - 3 variants
- [x] Grass tuft (tall / weed) - 2 variants
- [x] Small rock / pebble cluster - 3 variants
- [x] Large boulder - 2 variants
- [ ] Dead tree / bare stump - 2 variants
- [x] Bush / shrub - 2 variants
- [x] Dirt / scree patch (ground decal) - 3 variants
- [x] Water puddle (ground decal) - 2 variants
- [ ] Fog / mist patch (soft, semi-transparent, top layer) - 2 variants
- [ ] Flower / detail speck (tiny accent) - 3 variants

## Tier 2 - Node-type prop clusters

Small fixed prop drawn adjacent to a node's icon to reinforce its identity at a glance.
Keyed by `NodeData.Node_Type`.

- [ ] FIGHT - crossed weapons / scattered bones / battle debris
- [ ] BOSS - large ominous marker (banner, skull pile, monument)
- [ ] REST_STOP - campfire + small tent/bedroll
- [ ] HINT - signpost / wayshrine / open book on a stand
- [ ] GAMBLE - dice + scattered coins
- [ ] ESCALATE - cracked ground / warning totem / storm marker

## Tier 3 - Biome-specific scenery

### Reclaimed City (forest reclaiming ruins) - live biome, prioritize

- [x] Broadleaf tree - 3 variants
- [x] Overgrown ruined wall / pillar fragment - 3 variants
- [ ] Logic-Moss patch (grows in straight lines - distinctive ground decal)
- [x] Vine-draped rubble
- [ ] Toxic spore mushroom cluster
- [x] Fallen log - 2 variants

### Pirate Coves (coastal)

- [ ] Sand dune (ground decal) - 2 variants
- [ ] Palm / coastal tree
- [ ] Driftwood + rope/net debris
- [ ] Tide pool (water decal)
- [ ] Beached barrel / crate / anchor
- [ ] Jagged sea rock

### Clockwork Spire (desert / industrial)

- [ ] Sand dune (reuse Coves dune or desert variant)
- [ ] Broken gear / cog half-buried
- [ ] Scrap-metal / pipe debris
- [ ] Soot-Glass deposit (faint glow accent)
- [ ] Dead cactus / dry brush
- [ ] Steam vent (top-layer accent)

### Holy City Plains / God of Adventure's Caravan (grassland)

- [ ] Grass field (dense generic reuse)
- [ ] Wagon ruts (ground decal)
- [ ] Lone roadside stone marker / milestone
- [ ] Hoof-Iron / horseshoe accent
- [ ] Wildflower cluster
- [ ] Distant tent silhouette

### Ruins of the God of Magic / Glass Weald (corrupted)

- [ ] Glass-tree (chiming colored-glass tree) - 2 variants
- [ ] Memory-Vine (reality-warped plant)
- [ ] Prism-Salt / crystal cluster (glow accent)
- [ ] Floating shard / drifting color fragment (top layer)
- [ ] Cracked arcane pillar / rune stone

### Stub only (no live biome yet)

Named in `World_Building.md` lore but not yet built: Frozen Ledger (snow), Grease-Pits
(under-spire slum), Churning Marches (swamp - reeds, murk water, gnarled mangrove,
will-o-wisp).

## Rendering integration (implemented)

A two-tier, zone-based generator produces clustered scenery instead of evenly speckled
noise:

- **Tier A — region grid** (`BiomeVisualData.coarse_cell_size`, default 256 px): a
  low-frequency `region_noise` sample per coarse cell picks a `BiomeRegionData` zone
  (e.g. Forest / Clearing / Rubble) via cumulative `selection_weight`. Because the noise
  is continuous, neighbouring cells land in the same band, producing contiguous regions
  rather than pure speckle.
- **Tier B — placement grid** (`BiomeVisualData.fine_cell_size`, default 44 px): each fine
  cell looks up its parent zone, jitters one candidate point, and rolls every
  `ZoneDecorEntry` in that zone against `density × density_multiplier` and the
  high-frequency `detail_noise` threshold band from the entry's `DecorLayerData`.
- `AdventureBackgroundGenerator.Generate()` (`Scripts/Adventure_Scripts/Visuals/`) is a
  pure static function returning `Array[DecorPlacement]` — no nodes, no drawing, fully
  unit-tested in `Tests/unit/test_adventure_background_generator.gd`. Node-type props from
  `node_props` are appended once per node at a small seeded offset.
- `Scripts/UI/Adventure/adventure_ground.gd` (`AdventureGround`) is the bottom layer: the
  biome's gradient, mottled by its optional `ground_material` (`adventure_ground.gdshader`,
  noise tiled in pixel space). `Scripts/UI/Adventure/adventure_background.gd` (`Control`)
  draws each placement via `_draw()` above it and above `AdventureEdgeLayer`. The noise seeds and all placement jitter derive from
  `AdventureState._generation_seed`, so the same adventure always renders identical
  scenery.

### Structured biomes

A biome with a `StructureLayoutData` on `BiomeVisualData` is laid out as streets and lots
instead of zone-grid scatter. `StructureLayoutGenerator.Build` computes one
`StructureLayout` per canvas size (road polylines, lots, plazas, landmarks), and
`AdventureGraphUi` hands it to `AdventureEdgeLayer` and `AdventureBackground`.

- `AdventureNodePlacement` orders nodes within each row to reduce crossings, in every
  biome; `node_vertical_jitter` replaces the default row jitter.
- Roads run as streets: a vertical stub out of each node, one horizontal lane per row gap,
  chamfered corners, and a diagonal when the gap's lanes do not fit.
- `LandmarkData` layers are placed a set number of times per map before lots. Lots split
  the rest of the canvas on `lot_grid_size`, clear of plazas, road corridors and
  landmarks, and pick their region by `PickZoneAt` at their centre.
- `DecorLayerData.placement_mode` places a layer by `SCATTER` (inside its lot),
  `LOT_EDGE` (sides filtered by `edge_orientation`), `LOT_CORNER` or `LOT_FILL`.
  `BiomeRegionData.lot_interior_color` fills a region's lots beneath decor;
  `street_region` decorates open ground.

### Zone authoring

Author one `BiomeRegionData` resource per zone under
`Data/Adventure_Data/Biome_Visuals/Regions/`, each listing `ZoneDecorEntry` references
into `Data/Adventure_Data/Biome_Visuals/Decor_Layers/`. A `DecorLayerData` (one texture
set + placement rule) may be shared across multiple zones at different
`density_multiplier` values — e.g. `decor_grass_tuft.tres` appears in both a biome's
Forest and Clearing zones. Wire the finished `regions` array, `region_noise`, and
`detail_noise` into the biome's `visuals_<biome_slug>.tres`.

In a structured biome, author walls as `LOT_EDGE` layers whose `edge_spacing` is the
rendered piece length and equals `lot_grid_size`, so they enclose each lot corner to
corner; the top side gets its own `TOP` layer showing the face turned into the lot.
`adventure_ground_paved.gdshader` paves open ground: `fade_band` fades stones into darker
patches, `stone_opacity` sets the strength of the rest.

---

## Placeholder assets

Flat-color placeholder PNGs were originally generated for every Tier 1, Tier 2, and Tier 3
element of the biomes live at the time (Reclaimed City, Pirate Coves, Clockwork Spire, Holy
City Plains, Glass Weald) under `Assets/Adventure/Background/`, via
`Scripts/Debug/generate_placeholder_textures.gd` (re-runnable; skips files that already
exist so hand-replaced real art is never clobbered). Real art has since replaced the
placeholders for most of Tier 1 and the Reclaimed City Tier 3 set (checked above);
everything else (Tier 2 node props, the remaining Reclaimed City items, and all other
biomes) is still a flat-color placeholder and remains unchecked.
