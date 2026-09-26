# Art Style Guide

**Style name:** Lit Woodcut
**Tool:** Leonardo.ai (`app.leonardo.ai`) — no negative prompt field available
**Target:** 2D turn-based combat RPG, phone and desktop, characters ~250–350 px tall in play

This guide is the authority on visual style for every asset in the game. Where
`Concept_Document.md` and this guide disagree, this guide wins; the concept
document describes what the game *is*, this one describes what it *looks like*.

**How it is organised.** Part I holds the rules that bind every asset. Part II
applies those rules per asset domain; a domain section states only what differs
from Part I. Part III records what not to retry, how the pipeline is operated,
and what is still undecided.

---

## Contents

**Part I — Foundations**
1. The non-negotiables
2. Values
3. Materials and color
4. Perspective
5. Prompting method
6. Post-processing
7. Acceptance checklists

**Part II — Asset domains**
8. Champions
9. Enemies and bosses
10. Environments
11. Items, gear and reagents
12. Icons
13. UI art
14. Effects and VFX
15. Animation
16. Marketing and out-of-game art

**Part III — Record and process**
17. Do not retry
18. Operational notes
19. Open decisions

---

# Part I — Foundations

*Everything in Part I applies to every asset unless section 1.1 names an
exemption for its class.*

---

## 1. The non-negotiables

Every asset obeys these. If an output breaks one, reject it regardless of how
good it otherwise looks.

1. **Very thick uniform black contour outline on the outer silhouette**, and that
   silhouette edge stays clean and uninterrupted. Fussy, nibbled edges turn to
   mush at phone size.
2. **Flat color fields, hard-edged shadows, four value bands.** No gradients, no
   soft shading, no ambient occlusion. Four bands is a **value** rule, not a
   color-count rule — see section 2.
3. **One saturated accent per character**, flat and uniform, covering roughly
   15–20% of the figure.
4. **Hue is a free axis inside every band, including band 1.** Value structure is
   what makes the style cohere; desaturation is not. See section 3.5.
5. **Faces are lit and the eyes are visible.** Champions are people the player is
   meant to care about, and a concealed face reads as a prop. See section 8.4.
6. **The perspective spec** (section 4) is identical across every character,
   background, effect and icon, light direction included. This is what makes
   assets composite without looking assembled from different games.

A seventh rule is a tool constraint rather than a style rule and is stated in
full in 5.1: **Leonardo has no negative prompt field**, so every exclusion must
be phrased as a positive opposite.

### 1.1 Exemption registry

Every departure from Part I is listed here. A class not in this table takes
Part I whole, and no section grants an exemption this table does not carry.

| Class | Exempt from | Substitute rules in |
|---|---|---|
| Fodder enemies | Non-negotiable 3; the full detail tier | 9.1 |
| Overworld views | Section 4; non-negotiable 2 | 10.4 |
| Selection panels | Section 4; non-negotiable 2; the section 6 quantize step | 10.8 |
| Node, status and currency icons | Non-negotiable 2 (three values); the material slots of section 3 | 12.1 |
| Active skill art | Non-negotiables 1, 2, 3 and 6; sections 12.1–12.2; the section 6 quantize step | 12.4 |
| Passive icons | The material slots of section 3 | 12.6 |
| Turn bar zone art | Non-negotiables 1, 2 and 3; section 4's light direction; 14.1's outline and key background | 13.3.1 |
| Gear icons | Non-negotiable 3; section 4's camera, ground line and composition tail; the material slots of section 3 | 11.1 |
| Effects and VFX | Non-negotiable 3's coverage cap only | 14.1 |

---

## 2. Values

### 2.1 The four bands

Value structure is what makes the style cohere; hue variety is what makes it not
depressing. They are separate axes.

**Four value bands, measured in L\*:**

| Band | L\* | Role |
|---|---|---|
| 1 | 6–12 | Ink black — outline, deep shadow, costume blacks |
| 2 | 28–36 | Dark materials, shadow side of mid materials |
| 3 | 52–62 | The main readable mid tone of most materials |
| 4 | 78–86 | Light materials, lit skin |
| Highlight | 90–94 | Bone white — small shapes only, plus the eyes |

**Rules that follow:**

- **Each material occupies at most two adjacent bands.** That is what keeps eight
  fills reading as a flat woodcut rather than a painting.
- **Band 1 covers roughly half the figure.** Large committed areas of solid black
  are what make the rest read as bright.
- **Bone white is a highlight, not a fill.** Target 5% or less of the figure. If
  bone white is doing area work, the whole asset goes pale.
- **The outline black and the deepest shadow are the same value**, so shadow can
  eat part of a figure and merge it into the outline. Same value — not
  necessarily the same hue. See 2.2.
- **The outline is always ink black `#14121A`**, tinted slightly toward
  blue-violet. A true neutral black reads as photocopy; a tinted one reads as
  printed. The outline is the one part of band 1 that never varies.

### 2.2 Tinted band 1 — the shadow black is a per-subject slot

Band 1 is half the figure, so it is the largest colored area available. **The
shadow fill is tinted per character**, at the same L\* as the outline. The
outline stays `#14121A` so cohesion runs through every contour in the game; the
mass behind it carries hue.

Starting points, all to be measured to L\* 6–12 before use:

| Shadow black | Hex | Reads as |
|---|---|---|
| Blue-violet (default) | `#14121A` | The neutral option, and the outline value |
| Green-black | `#101A15` | Ruin damp, forest, verdigris |
| Aubergine-black | `#191220` | Arcane, corrupt |
| Umber-black | `#1A150F` | Warm, earthen, worked |
| Ash-blue-black | `#101519` | Cold, institutional |

**State the same-value rule in the prompt explicitly.** Given a tinted shadow,
Leonardo renders it lighter than the outline by default, and the result reads as
a mistake rather than a choice. The phrase has to say that the shadow mass and
the contour sit at the same value.

**Tint against the garment main, not with it.** A green-black shadow under a
green mantle reinforces a hue the figure already has. An umber or aubergine black
under that same mantle buys a genuine third hue. The cost is that the shadow
stops reading as the mantle's own shadow and starts reading as its own material
— generate both on any character where it matters.

**The light-dominant exception.** One Role may invert the band 1 rules and be
built on a light garment main, as the Jester is. For such a figure, judge instead
whether black still holds the outline and roughly a third of the figure, carried
by hose, boots and one split sleeve rather than by the torso. This is a
deliberate identity for a single Role; a second light-dominant character would
cost the first one its distinctiveness.

---

## 3. Materials and color

Color is assigned by **what a thing is made of**, not by a global palette limit.
Cohesion comes from the shared slots, which are identical on every character.

### 3.1 How the slots are used outside characters

> **Not yet written.** Environments (10), items (11) and UI (13) each need a
> stated position: which shared slots they inherit, which per-subject slots they
> are allowed, and whether they carry an accent at all. 12.1 answers this for
> icons and is the pattern.

### 3.2 Shared slots

| Slot | Light value | Dark value | Notes |
|---|---|---|---|
| Outline black | — | `#14121A` | Contour only. Never varies. |
| Shadow black | — | per character | Band 1 fill. Same value as the outline, own hue. See 2.2. |
| Bone white | `#EFE6D2` | — | Highlights and eyes only. |
| Metal, pewter | `#6E727A` | `#3F444B` | Non-accent hardware. Buckles, fittings, plain blades. |
| Skin, pale | `#D6BBA0` | `#937059` | The lightest row. |
| Skin, warm mid | `#C08A63` | `#7E5238` | |
| Skin, olive | `#A8875A` | `#6B5335` | Yellow-green cast rather than red. |
| Skin, brown | `#8C5A3A` | `#4F3122` | |
| Skin, deep brown | `#6A4028` | `#3A2318` | Dark row. Read 8.4.1 before using it. |

All five skin rows are shared slots and none is a default. Measure each to L\*
before use and keep the pair inside two adjacent bands like any other material.
The ramp is continuous — a row between two of these is legal, and the table
exists so that a character picks a stated position on it rather than inheriting
whatever the model returns.

### 3.3 Per-subject slots — where the variety lives

| Slot | Rule |
|---|---|
| Garment main | Two values. The largest colored area on the figure. **May be saturated.** |
| Material neutral | One or two values. Opposite temperature to the accent by default; may be saturated under 3.5. |
| Accent | One flat value, no texture, 15–20% coverage, head and chest region. |
| Shadow black | Band 1 fill hue, at the outline's value. |
| Leather | Two values, per character. See 3.4. |

The temperature rule on the material neutral is the default: brass on warm
leather disappears; brass on cold grey reads as metal. Terracotta on umber
disappears; terracotta on slate reads as clay.

**When temperature separation can be dropped.** The rule exists so the accent has
something to push against. If the garment main already sits at an extreme value —
bone white, or near-black — the value contrast does that job on its own and the
material neutral may be the same temperature as the accent. This holds only at
the ends of the ramp; it does not rescue a mid-value garment.

### 3.4 Leather is per subject

Leather varies per character: blackened, tar-dark, oxblood-stained, bark-brown,
bleached grey-tan, or the old warm brown `#4A3527`. Keep it inside two adjacent
bands like any other material.

### 3.5 Saturation — the two levers

**Lever one: saturate the garment main.** Give it real chroma and place it at a
value the accent is not at. Value does the separating instead of chroma, which is
what 3.3 already concedes at the ends of the ramp. Check garment and accent hue
adjacency per character; when they merge, move the garment a full value band,
never shift either hue.

**Lever two: tint band 1** — section 2.2. Half the figure becomes colored and no
value band moves.

Nothing requires the garment main to be desaturated. The temperature rule in 3.3
applies to the material neutral only.

**The garment's hue comes from the character's world first.** Contrast against
the accent decides the garment's *value*; it does not choose its hue. Pick the hue
from the character's faction and area palette (10.6) and from the Role's identity
colors — its accent (8.9) and its skill-art partner tone (12.4.4) — and only then
check it against the accent. The garment main is the largest colored area on the
figure, so a hue picked for contrast alone becomes what the character reads as. A
saturated bottle green chosen to make a red accent pop turned the Warlord into
the green one and imported a color the Iron Ledger does not use (8.7.4).

**Saturating the material neutral as well is a third step, and it is not free.**
It works where garment, neutral and accent sit at three clearly separated values,
but it removes the thing the accent pushes against. It is the first change to
roll back if a figure comes back noisy or if the accent stops reading at 300 px.
Per-character permission, not a default.

**Neither lever is the fix for a figure that reads flat.** That is a *detail*
budget problem — see 8.6.1 before touching non-negotiable 3. The scene-light LUT
(section 6) is not the fix either: it tints everything uniformly, so it moves area
mood without touching the sameness *within* a figure.

### 3.6 Watch for cool-neutral drift

The temperature rule pushes toward a cold material neutral every time, because
most accents in 8.9 are warm. Left unchecked this produces a roster where every
character wears blue-grey.

Cold neutrals available: slate blue-grey, ash grey, pewter blue, blue-violet
charcoal, slate-olive.
Warm and neutral alternatives that still serve: bone buff, sand tan, oxblood,
scarlet vermilion, warm charcoal brown, drab olive.

**Rule of thumb: no more than half the fielded roster on cool neutrals.** When a
new Role's accent is warm and a cold neutral is the obvious pick, take a warm
option if cool is already crowded.

3.5 relieves some of this pressure: with a saturated garment main and a tinted
shadow black carrying hue, the material neutral is no longer the only place
variety can live.

---

## 4. Perspective — identical everywhere

### 4.1 The spec

- Camera at **character chest height, straight on**. No tilt, ever.
- **Horizon line at a fixed screen fraction.** Pick one (45% from the top is a
  reasonable default), write it down, never move it.
- **Orthographic, no vanishing point.** State it explicitly. Models still cheat,
  but less.
- **One ground plane, 170 px of the 720 px frame.** Not a line. Figures stand at
  different heights within that band, and the band is where all the depth in the
  layout lives (10.3.3).
- **Light from upper left**, in every single asset. Mismatched light reads to
  players as a perspective error even when the geometry is fine.

### 4.2 Composition tail

Appended verbatim to every character prompt:

```
in contact with a single flat ground line, three-quarter view facing right,
eye-level camera at chest height, orthographic, isolated on a plain flat
background of one uniform color, full figure visible with headroom.
```

**The single ground line in the tail is a generation instruction, not a scene
fact.** Every asset is generated standing on one flat line so its bottom edge is
clean; the scene then places that line anywhere in the 170 px band (10.3.3).

The tail constrains the camera and the ground plane only. Squatting, kneeling,
braced, seated and leaning are all compatible with it. "Eye-level camera at chest
height" means the standing chest height the figure would have — it does not move
down when the character does, or the perspective breaks against everything else
in the scene.

### 4.3 Grey-box first

Build the battle scene in Godot with plain rectangles at final resolution. Decide
how tall a character is in pixels, where the ground line sits, how much
background shows above and to the sides. **Then** generate art to fill known
boxes.

---

## 5. Prompting method

The craft rules below are tool behaviour, not style, and they apply to every
prompt written for any asset — character, background, icon or effect.

### 5.1 There is no negative field

**Leonardo has no negative prompt field.** Every exclusion must be phrased as a
positive opposite. Never paste a list of unwanted terms into the prompt — it
reads as a request and you will get it.

When an unwanted element keeps returning, the fix is to change the vocabulary
that is summoning it (5.3), not to add words against it.

### 5.2 Tone comes from word choice

Leonardo builds mood from adjectives more than from anything structural. The same
design reads gritty or neutral depending on vocabulary:

| Avoid | Use |
|---|---|
| shirt straining | shirt pulled tight across the chest |
| fists loosely raised | fists raised ready |

**Frail** is the direction to watch: `wiry`, `hunched`, `head pushed ahead`,
`matted`. The failure is cumulative — two or more of these with nothing pushing
back lands on NPC. One of them against established bulk, a weapon and a wide
stance is a posture, not a status, and `hunched` in particular is useful for
getting weight into an asymmetric silhouette.

### 5.3 Genre attractors

Leonardo has strong genre basins, and a prompt that puts several of their
keywords together will land in one no matter what else it says. There is no
negative field, so **the only fix is to change the vocabulary wholesale.** Adding
qualifiers reinforces the basin.

| Attractor | Trigger words |
|---|---|
| Dracula | high collar, pale, long open coat, crimson at throat, "bloodmage" |
| Barbarian / nomad | torn strips, bare chest, hard muscle, notched blade, hide |
| Shaman | bone cords, antlers, bound bones at the belt, ritual bowl |
| Modern working man | plain buttoned coat, flat cap, ordinary, unremarkable |
| Modern outdoorsman | travel coat, gaiters, pack roll, tarp, harness, staff as walking pole |
| Generic wizard | robe, hood, staff, tome, wand, "sorcerer" |
| Cartoon | soft floppy cap, wide grin, `wiry`, large head relative to body |
| Roman / legionary | close-cropped grey hair, sleeveless tabard over a linen tunic, laced boots, panel divisions down the front |
| Wuxia sage | long beard, topknot, flowing robe, a large round weapon, an old man |

When an attractor lands, rewrite the costume from a different occupation rather
than negating.

**The two basins on either side of a magic Role are close together.** Fleeing the
generic-wizard basin with surveyor and travel vocabulary lands in the
modern-outdoorsman basin, and the fantasy content is gone either way. Take the
nouns from the Role's own area instead — ruin masonry, ruin ironwork, a shoulder
yoke, a chained slab.

**Historical accuracy is a basin too.** It does not show up as a genre, so it is
easy to fall into without noticing: a Role researched from its real-world
counterpart gets that counterpart's real props, and the result is competent,
legible and mundane. The fix is the same as for any attractor — change the
vocabulary wholesale, replacing real objects with the character's one element
from outside reality (8.1).

### 5.4 Counts, not adjectives

**Use numeric counts for built objects, never adjectives.** "Three or four wrap
bands" is a target the model can hit. "Moderate detail" is not, and it will
revert to maximalism.

**Grown things are described loosely.** A counted spec is a description of a made
object — a buckle has a number of straps because somebody put them there; grass
does not. Counts on foliage remove the model's own sense of how a plant
distributes itself and return every blade placed and nothing growing. Write them
loosely instead: *a broad low spray of coarse jungle grass, wider than it is
tall, splaying out loosely to both sides and sagging at the outer tips*.

The dividing line is **grown versus built, not character versus environment.** A
ruin's ironwork, a crate, a lantern, a wheel or a stair takes counts wherever it
appears; foliage, stone, fungus, water and debris masses do not. Detail *tiers*
still apply to both (8.6.1): loose does not mean undirected, and the element
still states where its heaviest carving goes.

**Name each element individually; a collective reference re-opens the count.** A
counted group stated once and then referred to collectively later in the same
prompt gives the number back — "all three shafts" is read as a licence to decide
how many "all" is. Treat "all the light", "the blades", "the shards" as an
instruction to invent, and repeat the members instead, each anchored to its own
origin.

### 5.5 Detail has to survive the pipeline

Ask for *structural* detail — shapes large enough to survive quantization to four
bands and downscaling to target size. Texture words (grime, stains, grease, fine
hatching) cost prompt budget and return nothing after post-processing.

**The round-trip test.** Downscale to target size, posterize to the ramp, upscale
back with nearest-neighbour. Detail that survives is detail worth keeping. Same
test for a costume, a wall, a sword and an icon.

### 5.6 Depth without gradients

No gradients means no atmospheric haze, so distance is built from **overlapping
flat planes, each one step darker than the one in front, receding into black.**
Five planes is the working number for a full plate. Dark recession rather than
pale is what reads as a place that continues past the lit part. State the
furthest plane as nearly gone rather than merely small — *a distant mossy stone
shape almost completely fading into the black*.

**At element scale the clause is per material class, not universal.** A knee-high
prop has no distance to recede through, and asking for flat fields without saying
where the values go returns one fill per shape and a cutout:

| Class | Depth comes from |
|---|---|
| Foliage, fungus, any mass of parts | Layers of parts overlapping, nearest lightest, each layer behind a full band darker into near-black |
| Stone, wood, any solid mass | The mass breaking into facets at different values, with one side falling away into near-black |

Getting the wrong one is visible instantly: layered grass on a boulder reads as
stripes, and facets on a grass clump read as folded paper.

### 5.7 The prompt describes the figure, not the story

Every clause should describe something the model can draw. Lore and narrative
clauses — what the character does for a living, who employs them, what they are
thinking about — cost prompt budget and return nothing a viewer can see.

**The occupation belongs to the design, not to the prompt.** 8.1 still requires
one, because a job is what supplies the clothes, the tools and the posture. Those
are what go into the prompt; the job title stays in the design notes recorded
with the reference example. The acceptance check in 7.2 — the occupation legible
from the costume alone — is the test that the translation was done.

**Stock phrasing is the same failure in a different form.** A clause that worked
on one character gets carried into the next by habit rather than chosen for it.
Every phrase in the subject block should be there because this character needs
it; only the general block (8.6) and the composition tail (4.2) are repeated word
for word.

### 5.8 One object, one state

**An object described twice is drawn twice.** Where it came from and what happened
to it are two clauses, and the model reads them as two entries in a list rather
than as one event in sequence — an intact bolt in flight and a broken one in the
same frame.

Name the object once, in the state the piece is about. The history goes to other
elements: gouge strokes trailing the path it came in on, and background cut lines
running along that same path, both ending at the break. They carry the direction
without a second object (12.4.3).

This is the mirror of the under-naming failure in 5.4. Count the objects, name
each one once.

---

## 6. Post-processing

Uniformity of this pass matters more than any individual generation. Run it even
on assets that already look right.

**The full pass:**

1. Quantize to the fixed value ramp from section 2
2. Mask the accent region and correct its saturation to the 8.9 hex
3. One shared overlay (grain or paper), identical settings every time
4. One LUT per area, identical within that area
5. Downscale to target in-game size, then judge

**Which classes take what:**

| Class | Pass |
|---|---|
| Characters, enemies, environment elements, effects | Full |
| Selection panels (10.8) | Overlay and LUT only — quantize would strip the extra bands and incident chroma |
| Active skill art (12.4) | Overlay only — quantize would strip the hatching and tone-block range; no LUT, since skill art is UI and not in scene light |
| Passive icons (12.6) | Quantize, accent correction, overlay, downscale to 40 px; no LUT |
| Turn bar zone art (13.3.1) | Key out, then downscale; no quantize, no accent correction, no LUT |
| Gear icons (11.1) | Crop, quantize, overlay, downscale to 100 × 120; no accent correction, no LUT. Quantize untested (19.4) |

**The quantize step must snap L\* while preserving hue.** A greyscale-ramp
implementation strips the tinted band 1 (2.2) and the saturated garment (3.5)
straight back out, and the levers appear to have done nothing. If a lever-built
character comes back muted, check the quantize step before blaming the
generation.

**The LUT is the mood dial, and it lives in the engine.** Because every asset
quantizes to a known ramp and the accent is a maskable flat fill, area mood can be
tuned live in Godot rather than baked into generations. Build the scene light as a
layer: a `CanvasModulate` for the global cast, a colored haze quad at low alpha
between bands, and the area LUT. A biome's color is then a value you can iterate
on in seconds instead of forty regenerations.

---

## 7. Acceptance checklists

Run before any asset enters the project. 7.1 applies to everything; the domain
lists are additions to it, not replacements. A class with an exemption in 1.1
skips the 7.1 checks its exemption removes, and its own list states what replaces
them.

### 7.1 Universal

- [ ] Outer silhouette is unbroken and reads at target size when filled pure black
- [ ] Outline thickness matches the rest of the set, and the outline is ink black `#14121A`
- [ ] Four value bands; no gradients anywhere
- [ ] Every material sits in at most two adjacent bands
- [ ] Bone white is under 5% and is not doing area work
- [ ] Ground line, horizon, camera height and light direction match section 4
- [ ] Wear and detail are structural, not textural
- [ ] Detail is tiered rather than uniform, and no region of the asset is left empty
- [ ] Post-processing applied per section 6, with the same settings as everything else
- [ ] Viewed at final in-game size, not full resolution
- [ ] Composited into the actual scene alongside an existing asset before acceptance

### 7.2 Champions

- [ ] Band 1 covers roughly half the figure, and its tint sits at the outline's value
- [ ] Shared slots (skin, pewter, outline black, bone) match the rest of the roster
- [ ] Garment main, accent and shadow black are separated by value, not by desaturation
- [ ] Material neutral is the opposite temperature to the accent, unless 3.5 permission was taken deliberately
- [ ] Exactly one accent, flat and uniform, roughly 15–20% coverage, and it has not bled onto skin, hair or background
- [ ] Face is lit, eyes are visible, head proportion is adult
- [ ] Face clause states an age, a skin row from 3.2, a face-structure cluster and a hair mass, with a region label where one is wanted — none of them repeating the last three approved characters (8.4.6)
- [ ] Expression reads through brow, tilt or mouth line, and was chosen for this character rather than carried over (8.4.4)
- [ ] The subject block describes only what can be seen — no occupation, lore or narrative clauses (5.7)
- [ ] Eyes hand-placed and consistent with the last approved character
- [ ] Three levels of detail present: focal region, garments, limbs — none of them left empty (8.6.1)
- [ ] Skin carries four engraved lines at most, each at contour weight (8.4.1)
- [ ] Counted groups within budget, or over it deliberately with a cut order recorded (8.6.2)
- [ ] Nothing hanging at the belt or hip breaks the outer silhouette (8.5.1)
- [ ] The Role's occupation is legible from the costume alone, with no name attached
- [ ] Where the figure carries an element from outside reality, it reads in the silhouette, and its strangeness is visible in the still image
- [ ] Garment hue belongs to the character's faction and Role colors, not only chosen for contrast with the accent (3.5)
- [ ] No signature prop shares a type with another Role's (vials, books, lanterns and similar)
- [ ] Filled pure black, separates from the approved characters it can be fielded beside — judged by composite, not by silhouette family label (8.3)

### 7.3 Enemies

> **Not yet written.** Which of 7.2 survives at fodder tier, and what a boss adds
> on top.

### 7.4 Environments

Applies to battle stages and their elements. Overworld views (10.4) take the
per-stage list only.

**Per element**

- [ ] Upright billboard in side elevation — nothing in it lies on the ground or carries perspective of its own (10.3.3.1)
- [ ] Reads at sizes it was not drawn at, since scale is applied on placement (10.3.3)
- [ ] Bottom edge is cut flat and straight, with no ground, shadow or base baked in (10.3.8)
- [ ] Depth clause matches the material class, and the element does not read as a flat cutout (5.6)
- [ ] Engraved linework present — flat fields alone return a vector cartoon (10.3.7)
- [ ] No bone white highlight edge (10.3.7)
- [ ] Organic subjects described loosely, built subjects counted (5.4)
- [ ] Small elements generated as a sheet of three, sliceable without overlap; large elements one per image, whole, with nothing cropped by the image edge (10.3.7)
- [ ] An element of two materials takes both depth clauses, and the one meant to dominate is the head noun (5.6, 10.3.7)
- [ ] Silhouette distinct from the other elements in its band, not a rescale of one

**Per band**

- [ ] Floor clutter sits under sprite height and holds its clear radius around every character's feet (10.3.3)
- [ ] Floor mass is low contrast; any saturated shape on the plane is small and does not pull the eye off a champion standing beside it (10.3.9)
- [ ] Midband behind the six character slots stays a band or two off the figures (10.1)
- [ ] Midband mass is muted and its chroma sits in growth, blooms and fungus on it, with hues spread across the band rather than one repeated (10.3.10)
- [ ] Foreground reads as pure band 1 and crosses no character slot (10.3.4)
- [ ] Background carries the variant's sky field from 10.2

**Per stage**

- [ ] Composited against a fielded team of three, at target size, before acceptance
- [ ] Scene light conforms to the variant's row in 10.2
- [ ] Ground line, horizon and light direction match section 4

### 7.5 Items, gear and reagents

See 11.

- [ ] Judged at exactly 100 × 120 px in a mocked inventory row, never at full resolution
- [ ] On the lower-right to upper-left diagonal; only a handle or shaft leaves the frame (11.1)
- [ ] Three levels of detail, every group counted, cut order recorded
- [ ] Four values; no gradients; outline ink black `#14121A`; one broad bone white edge
- [ ] No Role accent
- [ ] Silhouette survives being filled black
- [ ] Relics: one strange element visible in the still image, plus an ornate made finish (11.6)
- [ ] Rarity signal — not yet defined (11.5)

### 7.6 Icons

> **Not yet written.** Judged at exact target px, three values, one idea, survives
> being filled black, accent policy correct for the icon class.

#### 7.6.1 Passive icons

Replaces 7.6 for this class; see 12.6.

- [ ] Judged at exactly 40 × 40 px with the round mask applied — never at full resolution, never square
- [ ] The key shape (the gap, the opening, the thing the passive does) reads first; engraved detail reads second as texture on top of it, never instead of it
- [ ] Three levels of detail present: focal point, moderate on the main masses, light on the tool (12.6.3)
- [ ] Every engraved group was stated as a count, and a cut order is recorded with the prompt
- [ ] Four values; no gradients; outline ink black `#14121A`
- [ ] Exactly one accent, flat, on the Role's tool, matching the placement in 8.9
- [ ] Subject sits inside the circle with the four corners empty; nothing important is lost to the mask
- [ ] Silhouette survives being filled black inside the circle
- [ ] Does not repeat the subject of the Role's active skill art for the same mechanic (12.6.2)

### 7.7 UI

> **Not yet written.** Frame weight consistent, no gradient creep from templates,
> legible over both light and dark area LUTs.

### 7.8 Selection panels

- [ ] The way in ends before the frame does — path bends out of sight, or interior goes dark before its back wall
- [ ] Entry side is offset, not centered
- [ ] Nearest masses cropped by both side edges; top of the structure or canopy out of frame
- [ ] Vertical relief present — rise, fall, drop or stair
- [ ] Five depth planes distinguishable, each darker than the one in front
- [ ] Six to eight bands, no shading within a hue
- [ ] Mass low saturation, incident chroma under roughly 10% of area
- [ ] No element reads as a character accent
- [ ] Dark mass low in frame for the label
- [ ] Judged beside its pair panel at half-screen size, never alone

### 7.9 Active skill art

Replaces 7.1 for this class; see 12.4.

- [ ] Reads as a chiaroscuro woodcut: a black key block carrying the line work, two flat tone blocks beneath it, highlights as bare cream paper
- [ ] Detail lives in the carved line (hatching, contour, gouge strokes), not in color modelling or soft shading
- [ ] Exactly two tone-block colors: the caster's accent family and the Role's partner tone (12.4.4)
- [ ] The two tones read as two different colors, one light and one dark, and not as two shades of one hue
- [ ] One subject, caught in the act of the skill, on a diagonal or arc
- [ ] Background held in the darker tone and carried by sparse lines, so the subject stands forward
- [ ] Paper color, key-block line weight and registration offset match the approved set (12.4.6) when viewed side by side
- [ ] Chiaroscuro structure (dark key, mid tone, paper highlight) still reads at the display size, even where individual hatching lines do not

### 7.10 Turn bar zone art

Replaces 7.1 for this class; see 13.3.1.

- [ ] Judged in the actual turn bar section (248 × 80 px), with the tint field, planned opacity and a character marker standing in it — never alone or at full resolution
- [ ] The character marker is the first thing the eye goes to; the zone still reads as its subject second
- [ ] Outlines are darker shades of each fill color, not ink black
- [ ] Soft, muted, low-contrast fills; flat fields with no gradients
- [ ] Palette ties to the placing Role (accent family in the body color)
- [ ] Centerpiece fits the section with rocking or motion headroom; the pivot edge is clean
- [ ] Particle sprites read as the same object at 20–32 px
- [ ] Background keyed out cleanly, with no key color fringing into light edges

---
# Part II — Asset domains

*Each section below states only what differs from Part I.*

---

## 8. Champions

### 8.1 Design the character before writing the prompt

Settle who the character is, what their place in the world is and what they do,
before a word of the prompt exists. A prompt cannot be rewritten into a concept.

**A Role is a class, and a character is a person holding it.** Several characters
can field the same Role — the Lancer is held by a knight, a centaur outrider and
a forest hunter. The **Role** owns the kit and the accent registry entry (8.9),
because both are the mechanics made visible, and the element
from outside reality is *for*. The **character** owns the occupation, the
costume, the silhouette and pose (8.3), the materials in its per-subject slots,
the face, the skin row and the hair (8.4.6), and what the element is made of and
shaped like. Where a section below says Role and means the figure in front of
you, read character.

**Every character needs an occupation.** A job comes with clothes, tools and a
posture; a magic system does not. Before writing a prompt, answer: *what does
this person do for a living, and who employs or shuns them?*

**Check the concept for internal conflict.** "Shunned outcast" and "cool playable
champion" pull against each other, because low status is what outcast looks like.
No wording resolves that. Either the status changes (feared instead of shunned)
or the visual reading of it does.

**Flavour text is not a costume brief.** Concealment survives as *style* — a
brand showing at an open collar, dye that will not wash off — not as ordinary
clothing.

**Where the character lives sets their finish.** A city character with standing
in a wealthy faction keeps up appearances as much as function: clean cuts, strong
shapes, ornament and deliberate layers. A wilderness or slum character carries
the wear. Settle this with the occupation, because it decides whether the costume
is maintained at all (8.5).

**An element from outside reality is the strongest thing a character can
carry.** An occupation makes a figure legible; it does not make it fantasy. Left
to itself, every design drifts toward the historically plausible version of its
job, and a roster of accurate period costumes is a roster with nothing in it a
player could not see in a museum. Where a character can carry one thing our
world never made, make it large enough to matter in the silhouette. It is
encouraged on every figure and required on none.

**Outside reality does not mean magic.** Two kinds qualify, and both are equally
valid:

- **Impossible by behaviour** — the thing does what nothing real can do: the
  Diviner's shards hovering as a ball (8.7.3).
- **Unreal by design** — the thing is ordinary in physics but no culture ever
  made it: a shape no smith forged, a material nobody would use for the job, or
  one our world does not have. The Warlord's shield of stained glass in iron
  tracery (8.7.4) is the working example.

Either way, **the strangeness has to be visible in a still image.** A real object
with an invisible property — a door that pulls blades onto itself, a stone that is
warm — shows only the real object; the viewer cannot infer the intent, and the
design reads as mundane. If it cannot be seen at 300 px it is lore, and 5.7 keeps
lore out of the prompt.

- **Derive it from the kit, and the world.** The element is the Role's mechanic
  made physical, built from what the character's area and faction contain. The Plague Doctor's
  Septic Lance and Miasma became one object — an iron-shod pole levelled like a
  lance, carrying a caged giant tree gall that vents solid smoke (8.7.1).
- **Put it on the tool or the focal region.** A weapon is the cheapest place: it
  is already the strongest shape in the pose, and a straight, simple object is the
  least interesting silhouette available. A curve, a barb, an organic or
  impossible material does more than any amount of costume detail.
- **One, not several.** It is a single anchor, held to the counted-group budget
  like everything else. A figure where everything is strange reads as a creature,
  not a person with a job.
- **Harvested, worn or wielded — not grown.** Unless growth is the Role's
  identity, the strange thing is something the character has taken, caged,
  strapped on or carries. That keeps the person legible and keeps Roles out of
  each other's lanes.
- **Choose its vocabulary against the attractors.** Bone, hide and antler nouns
  summon the shaman and barbarian basins (5.3). Insect, plant, ruin-stone and
  impossible-mechanism nouns are less used and have held so far.
- **Make it strange by arrangement or behaviour, not by added parts.** A real
  object made impossible by what it does keeps one shape language: the Diviner's
  crystal ball is six raw jagged shards hovering in the shape of a ball, held
  together by nothing (8.7.3). Bolting a second shape language onto a real object
  reads as a rock with growths on it rather than as a designed prop. One shape
  language, and at most one deliberate break in it.

### 8.2 Decide the silhouette and the pose before anything else

Two phrases, written before a word of the prompt exists: what shape is this, and
what is the body doing. `strongly asymmetric silhouette, one human hand and one
bloomed limb` is a complete answer. So is `low squat, weight over the heels,
lance braced diagonally across the whole figure`.

State them near the front of the subject block and let the model solve them. Do
not decompose them into a parts list — enumerating chest, then shadow, then
limbs, then pose produces interchangeable figures. The parts that matter will
follow from the shape; the parts that do not should stay flat.

The subject block has no fixed running order. Its only fixed element is the
composition tail in 4.2.

### 8.3 Silhouette discipline

**The test is the composite, not the label.** Any three characters that can be
fielded together must separate when filled pure black. That is the whole
rule. Pose and specific shapes — what the figure holds, where its mass sits, what
breaks the outline — are what pass it.

**Silhouette families are vocabulary, not allocations.** With several characters
per Role and a growing roster, two-word families such as "wide and low" will be
shared by many figures, and that is not a problem in itself. Never reject or
redesign a character because its family is already in the table; composite it
against the figures it could stand beside and judge what you see.

The table records what each approved figure's outline is built from, so a new
design can be checked against it and composited early:

| Family | Roles | Cue |
|---|---|---|
| Wide and low | Bar Brawler | bulk at the waist, short stance |
| Forward slab with a bristle | Warlord (Ledger bailiff) | a tall ornate shield planted in front with the shoulder set into it, weight forward, a bundle of weapon hafts rising close above the far shoulder |
| Tall and angular | Architect, Emissary | gaunt vertical, hard corners |
| Squared column | Bloodmage | heavy square shoulders, long straight coat to the knee |
| Narrow vertical, high shouldered | Cultist | layered robes, raised shoulder line, ankle hem |
| Asymmetric mass | Symbiote, Herald | growth or apparatus on one side |
| Off balance | Jester | leaning back off the vertical, one arm out as counterweight |
| Top-heavy | Alchemist | loaded chest, narrow legs |
| Narrow and vertical | Thief, Diviner | tight outline, no shoulder mass |
| Braced diagonal, low | Lancer | low squat, lance braced diagonally across the figure |
| Planted diagonal | Sorcerer | mid-calf hem over boots, yoke across the back, rod planted forward across the figure |
| Forward wedge | Plague Doctor | weight forward, beak projecting right at head height, a pole levelled forward in parallel with a caged mass at its end, high hair knot as the only vertical at the head |
| Wide column with a disc | Appraiser | heavy square shoulder mass, straight upright stance, a great toothed wheel almost his own height standing behind the figure and breaking the outline above and to both sides |

**Robed Roles are crowded.** Cultist, Diviner and Sorcerer are all robed.
Giving up the ankle hem is the cheapest separation available to any robed
character: the Sorcerer's is cut at mid-calf over visible boots and carries a
hard diagonal from the planted rod; the Diviner's wrap-coat is kilted up into the
sash to the knee on the near side and falls to mid-calf on the far side. She holds
the narrow vertical against the Thief on two further cues — a long veil falling
straight down her back from the crown to the backs of the knees, and one hand
raised open-palmed at shoulder height with the shard ball hovering above it.

**Pose is the cheapest silhouette tool available.** A squatting Lancer, a braced
shield stance, a kneeling reload and a standing column are four unmistakable
black shapes at 300 px; four standing figures are not, however different their
costumes. Give every Role a pose that is doing work. The pose is a *held* combat
stance, not a moment inside an action, and it has to keep the face lit and the
accent visible.

When two figures that can be fielded together come close in pure black, that is
settled by the composite: change a pose, a held object or where the mass sits,
and keep their material neutrals apart. Sharing a family label is not by itself
a finding.

**Three Roles hold a long shaft forward.** Lancer, Sorcerer and Plague Doctor
separate on angle and on what ends the shaft: the Lancer's lance is braced
diagonally from a low squat, the Sorcerer's rod is planted into the ground line,
and the Plague Doctor's pole is levelled horizontal, clear of the ground, and
ends in a round mass rather than a point. Keep all three cues when revising any of
them, and composite them in pure black before a fourth Role takes a shaft weapon.

### 8.4 Faces and proportion

#### 8.4.1 The rules

- **The face is lit.** Shadow falls on the side of the head away from the light
  and beneath the jaw, never across the eyes.
- **Eyes are two bone white almond shapes, each with a solid ink black pupil.**
  Sized to read clearly at 300 px, but **no larger than an adult eye**.
- **Realistic adult head proportion.** State it explicitly in the prompt.
- **The head is the highest-contrast region of the figure.** The lit plane of the
  face sits a full band above everything touching it, band 1 never crosses it, and
  the eyes carry bone white. This is local contrast, not absolute value: a figure
  on the deep brown row satisfies it by keeping the shadow mass off the face and
  letting the coat, the hair and the collar fall to band 1 around it. State the
  surrounding darkness in the prompt when the skin row is dark; left unsaid, the
  model lights the chest instead and the face sinks.
- **A light accent must not touch a darker face.** On the brown and deep brown
  rows, a light accent — pale lilac, ice cyan, parchment — sits above the lit
  plane of the face in value, so an accent trim framing the face out-lights it.
  Keep a dark mass between the two: a veil border at the crown behind a dome of
  black hair, a throat sigil on a blackened collar band.
- **Hair and beard are single flat masses.** No interior detail.
- **Skin is a counted tier, not a flat field and not free.** Face, neck and bare
  limbs carry **no more than four engraved lines in total**, each cut as thick as
  the contour line. Anything thinner than the outline reads as noise at 300 px and
  dies in the quantize step. Scars and brands are band 1 shapes (8.5) and are
  counted separately.
- **Age is carried by structure first, by lines second.** The jaw, the neck, the
  build and the hair mass do most of it. An older face that needs more than four
  lines to read as old has the wrong head shape.

#### 8.4.2 State an age, and vary the noun cluster

Left unstated, Leonardo returns its average man: roughly forty, conventionally
handsome, and identical from character to character.

**Name the age in the prompt.** "A man in his late twenties with a smooth unlined
face" is a target. Nothing is not.

**Watch the noun cluster, not the individual nouns.** Hollow cheeks, shelf brow,
hooked nose and a hard-set jaw are four nouns from one gaunt-severe cluster, and
any two of them land on forty-year-old man regardless of the stated age. Build
each Role's face from a different cluster (8.4.6) and check the last approved
character before writing the next.

**Age is characterisation, not decoration.** A young face makes scarring read as
a story; the same scars on a middle-aged face read as ordinary wear. Pick the age
the Role's motive implies.

#### 8.4.3 Hair length is a silhouette tool

Hair is a single flat mass with no interior detail, so hair length costs nothing
in detail budget and changes the outline of the head. Long hair past the
shoulders gives a wider, softer head shape than anything else available, and on a
roster of cropped and bearded men it is one of the cheapest ways to make a figure
recognisable in pure black.

#### 8.4.4 Expression in flat woodcut

Three things carry expression at four values with no interior modelling.
Everything else is lost.

- **Brow asymmetry** — one eyebrow raised higher than the other
- **Head tilt** — toward or away from what the figure is holding or facing
- **Mouth line** — flat, parted, or set

Chin up reads as interest; chin tucked reads as caution. Curiosity is brow plus
tilt plus a slightly parted mouth. A young face with a raised brow and parted
lips sits close to the cartoon attractor (5.3) — if it goes goofy, cut the parted
lips first and keep the brow and the tilt.

**These are tools, not a default.** Choose the expression from the character, and
check the last three approved characters' expressions the same way as their face
clusters, or the roster ends up with one expression. Recorded so far: Sorcerer,
raised brow, parted lips, chin up; Plague Doctor, brows drawn hard together, chin
tucked; Appraiser, mouth set flat, chin tucked; Diviner, calm level brows, chin
raised slightly; Warlord, level unimpressed brows, chin up with the head tilted
back, one corner of the mouth drawn back.

**When the mouth is covered,** brow and tilt carry everything, and the choice
between them matters more.

#### 8.4.5 Concealed faces are an exception, not a tier

A hidden face is permitted only when concealment **is** the character's identity,
and it costs that Role its most direct expression tool. When in doubt, show the
face.

A hood is not automatically a concealed face. Worn up but pushed back off the
brow, it keeps the silhouette and the accent placement while leaving the whole
face open and lit.

**Partial coverage of the lower face is permitted** when the eyes and the upper
face stay open and lit, because the eyes are what non-negotiable 5 protects. The
Plague Doctor's half-beak (8.7.1) and the Diviner's veil (8.7.3) both hold it.
Each costs the mouth line as an expression tool (8.4.4).

**Semi-transparency in flat bands.** The style has no translucency, and "sheer"
on its own summons a soft blur. Describe the effect in woodcut terms instead: the
veil's upper edge as one hard straight line across the bridge of the nose beneath
the eyes, and the nose, lips and jaw showing through it as one flat shape a full
band darker than the lit upper face. The quantize pass (6) flattens whatever
softness the model still adds. Keep any light accent off the veil's upper edge —
it runs across the face and falls under 8.4.1. If a variant blurs, the untested
fallback is a coarse open net with a few large diamond openings.

Fodder enemies are the one place faces stay dark and anonymous, which is a free
legibility win and matches the reduced detail tier in 9.1.

#### 8.4.6 Appearance is stated, or the model picks it

Left unstated, Leonardo returns one recurring head across the whole roster:
mid-brown skin, straight black hair, broad flat cheekbones, a strong straight
nose. A roster meant to be drawn from four factions and half a dozen regions then
reads as one extended family from one place.

**Appearance belongs to the character, not to the Role.** It is assigned in the
character's own subject block, alongside its occupation and costume, and it is
never recorded in the accent registry or anywhere else keyed by Role. Two
characters on the same Role should look less alike than two characters on
different ones.

**Specify with three nouns, and add a region label where one is wanted.**

1. **The skin row**, named from the 3.2 table.
2. **The face structure** — two or three nouns for the shape of the skull and
   features, from a cluster no recently approved character used.
3. **The hair as a mass** — length, how it is bound, and the shape of its
   outline, since 8.4.3 makes hair a silhouette tool and it carries as much of the
   read as the face does at 300 px.
4. **A region or origin label, when the character is meant to read as from
   somewhere.** Alongside the nouns, not instead of them.

**On the label.** Put it inside the face clause with the feature nouns, not as a
standalone sentence, and check the costume at acceptance like any other clause.
Feature nouns alone do not reliably reach an intended regional read; the label
does, and a controlled pair differing in that phrase alone showed no costume
drift. Keep the nouns anyway — the label sets the read and the nouns keep the
character off the model's default within it.

A named origin imports a real-world culture into a world with its own four
factions. The prompt is a private document, so a label in it only reaches the
fiction if it is allowed through into the character's name, dress or dialogue.
Keep player-facing vocabulary in the world's own terms.

**Hair mass is the element most often left vague.** Tight coiled hair cropped
close reads as a rounded mass hugging the skull; the same hair grown out reads as
a wide soft dome and is one of the strongest head silhouettes available. Straight
hair takes a hard-edged mass with a clean parting line. Loose curls take a broken
outline, which is the one to avoid on a figure whose silhouette is already busy.
All of them stay flat inside, as 8.4.1 requires.

**Face-structure clusters, for rotation.** Pick one per character and check the
last three approved characters before writing:

| Cluster | Nouns |
|---|---|
| Round and heavy | round jaw, full cheeks, short snub nose, low brow ridge |
| Narrow and fine | narrow face, straight thin nose, small pointed chin, fine brow |
| Broad and flat | wide cheekbones, broad flat nose, heavy jaw, shallow brow |
| Long and angular | long face, high narrow bridge, hollow cheek, square chin |
| Gaunt and severe | shelf brow, hooked nose, hard-set jaw, hollow cheek |
| Young and unmarked | soft jawline, smooth unlined skin, even features, wide-set eyes |

The gaunt-severe row is the model's own favourite and needs a stated age pushing
against it every time. Broad-and-flat is close to the unstated default above, so
a character on it should be there on purpose.

**Rule of thumb: no more than a third of the fielded roster on any one skin row,
and no two of the next three approved characters on the same row.** A running
count looked at when a new character is designed, not a quota applied to the whole
roster at once. Only three champions are fielded at a time, so what the player
sees is any three of them standing together.

### 8.5 Wear is shape, not texture

Dirt, grime, stains and grease do not survive the post-processing pass — four
flat value bands quantize a smudge into nothing.

Wear that reads at 300 px is structural: a sleeve burned off at the elbow, a hem
torn and re-panelled, a mended patch with hard angular edges, a strap replaced
with the wrong material, a scar as a solid band 1 shape.

**Tie the wear to the Role's mechanics wherever possible.** The Sorcerer's Arcane
Instability surges damage him along with everyone else, so his burned-away right
sleeve and blackened forearm are the visible cost of how he fights — a mark no
other Role can carry. Wear derived from the kit is characterisation; wear applied
for grit is texture.

**Scarring is band 1, never the accent** (8.9). Burn marks, brands and glyph
scars are solid ink black shapes, which means they read as silhouette against a
light skin row and need to sit on the lit plane or against an edge to read at all
on a dark one.

#### 8.5.1 Layering, and history carried as structure

Kit-derived wear says how a character fights. It does not say where they came
from, and a roster where every figure's only story is its job is thin in a way
the accent budget gets blamed for and is not responsible for (8.6.1).

**Layer the clothing.** A single garment over a tunic gives one hem, one collar
and one closure, and there is nothing else for the eye to do. Two or three
garments in different materials give overlapping hems, an asymmetric closure, a
border where one meets another, and a second garment hue that costs nothing from
the accent.

**Four kinds of history, all of them structural.** Each is a shape at 300 px, not
a texture, and none of them is the accent:

- **Kept for warmth or protection.** A garment carried long past its season or
  its life — a heavy mantle worn on one shoulder indoors, a padded layer under a
  working garment. It says the character has been somewhere cold, or expects to be.
- **Cultural or inherited cut and motif.** A border band with a repeated
  geometric motif, an unusual closure — wrapped and fastened at the hip rather
  than buttoned down the front — a hem or sleeve cut nobody else on the roster
  wears. This is the cheapest of the four and it carries the furthest, because a
  cut reads in silhouette.
- **Symbolic objects the character keeps on them.** Held to the counted-group
  budget and clustered in one region.
- **Repair rather than damage.** A patch in a *different weave* sewn in with hard
  angular stitching reads as something mended and kept; a tear reads as something
  merely worn out.

**Do not spend the accent on any of this.** The accent is the identity signal
(8.9) and has to stay clustered in the head and chest region at 15–20% to keep
working on the card border, damage numbers and skill art. Richness comes from a
second garment hue, from layering, and from these four. If a figure still reads
thin after all of that, the next lever is extending the accent to one further
region, named explicitly; it is never spreading it evenly.

**Hanging objects and the silhouette.** Anything on a chain or a cord at the hip
or the belt is what nibbles the outer contour, which is a reject under 7.1
however good the rest is. State that the cluster hangs in front of the garment
and clear of the outline, and check that edge first in the output.

### 8.6 The canonical general block

Substitute the bracketed slots from section 3. Everything else is identical in
every character prompt, word for word. The repetition is doing most of the
consistency work.

```
bold woodcut illustration with engraved structural linework, very thick
uniform black contour outline on the outer silhouette, clean uninterrupted
silhouette edge, flat color fields, hard-edged shadows, high contrast with
large areas of solid shadow in a deep {SHADOW BLACK}, that shadow mass and
the outline sitting at the same value, colors assigned by material: {SKIN}
skin, {GARMENT MAIN}, {MATERIAL NEUTRAL}, {LEATHER} leather straps and
boots, dull pewter grey metal fittings, all flat and unmodulated, warm bone
white reserved for small highlight shapes and the eyes, outline black
tinted slightly toward blue-violet, light from the upper left casting a
narrow bone white edge along the upper left contour, three levels of
detail: {FOCAL REGION} carrying the heaviest engraved detail and reading as
the focal point of the figure; {GARMENTS} carrying moderate engraved detail
through seams, panel divisions, border bands and fastenings; the limbs and
boots carrying light detail through wraps and fold lines rather than being
left empty, all marks large and structural, with saturated
{ACCENT} as the single accent covering roughly a fifth of the figure, flat
and uniform with little texture, used only on {PLACEMENT}, hand-carved edge
quality.
```

**Detail vocabulary.** Derive the nouns from this Role's own trade and materials
rather than reusing the list from the last character. The test is size, not
vocabulary: any mark that survives the round-trip in 5.5 qualifies. Counts, not
adjectives (5.4).

#### 8.6.1 The detail budget

Three levels, and none of them empty:

1. **Focal region** — heaviest engraved detail, where the Role's mechanic is
   visible.
2. **Garments** — moderate detail through seams, panel divisions, border bands
   and fastenings.
3. **Limbs and boots** — light detail through wraps and fold lines.

A single focal region with flat empty panels everywhere else gives two or three
things per character and a figure that reads flat. That is a *detail* budget
problem, not a color one: **the accent cap stays**, because dropping it costs the
identity system (8.5.1, 8.9) for a problem it does not cause.

**Skin is the exception the three levels do not cover.** A stated age above fifty
is otherwise read as licence to carve every wrinkle. The rule is in 8.4.1 — a
count and a mark weight, never an adjective. Figures with a stated age above
fifty, or with unusually large areas of bare skin, need it in the subject block as
well as the general block.

#### 8.6.2 Counted groups

Three counted groups in three regions is the default budget. It is a budget, not
a limit: the Appraiser (8.7.2) carries five deliberately, because the trinkets at
his hip *are* his occupation.

**When a figure goes over, write the cut order down with the prompt.** A variant
that comes back busy is then one edit away from a fix instead of a fresh
judgement call. Cut smallest and least meaningful first — decorative counts before
kit-derived ones, and the groups carrying history (8.5.1) last.

---
### 8.7 Reference examples

A new character is judged side by side against these. **At most three prompts
are recorded here.** Adding one means removing another's prompt block.

#### 8.7.1 Plague Doctor

The working example of an element from outside reality (8.1) and of a partial
mask that keeps 8.4 intact. Three hues — saturated dark mustard garment,
aubergine-black band 1, moss accent — with the shadow tinted against the garment
main as 2.2 recommends: purple under yellow, so band 1 buys a real third hue
instead of reinforcing the second.

Slots: garment main saturated dark mustard ochre waxed oilcloth, material neutral
warm sand-buff linen, leather oxblood, shadow black aubergine-black, accent deep
moss on the gall's cracked interior, the goggle lenses and the collar lining,
focal region the beak and the caged gall. Occupation: a quarantine physician in
the Reclaimed City's jungle who builds her tools from what she cuts out of it.

Decisions recorded with it:

- **Half-beak, not full mask.** The beak covers only nose and mouth; goggles are
  pushed up onto the forehead, so the accent reaches the head without landing on
  the eyes (8.9). The mouth line is lost as an expression tool, and brow plus tilt
  carry it. Concealment is not this Role's identity; the beak is (8.4.5).
- **One object carries the kit.** The pole is Septic Lance, the venting gall is
  Miasma. Nothing on the chest holds containers, which is what keeps her clear of
  the Alchemist.
- **A gall, not a fungus.** A fungal mass in moss green would sit beside the
  Symbiote's fungal accent in an adjacent hue, and a plant tumour is closer to a
  disease Role.
- **Young face from the narrow, fine cluster.** Early thirties. The neck vein
  marks are kit-derived wear (8.5), and on a young face they read as a story, not
  age.
- **No hat.** A high hair knot gives the head its vertical against the horizontal
  beak (8.4.3).

```
bold woodcut illustration with engraved structural linework, very thick uniform black contour outline on the outer silhouette, clean uninterrupted silhouette edge, flat color fields, hard-edged shadows, high contrast with large areas of solid shadow in a deep aubergine-black, that shadow mass and the outline sitting at the same value, colors assigned by material: warm tan skin, a saturated dark mustard ochre waxed oilcloth jerkin, warm sand-buff linen wraps and cord, oxblood leather straps and boots, dull pewter grey metal fittings, all flat and unmodulated, warm bone white reserved for small highlight shapes and the eyes, outline black tinted slightly toward blue-violet, light from the upper left casting a narrow bone white edge along the upper left contour, the chitin beak and the caged gall at the end of the pole carrying the heaviest engraved detail and reading as the focal point of the figure, the rest of the body held as large flat angular panels with only sparse structural marks, all marks large and structural, with saturated deep moss green as the single accent covering roughly a fifth of the figure, flat and uniform with little texture, used only on the cracked-open interior of the gall, the round goggle lenses and the lining of the high collar, hand-carved edge quality.
full body character, a grim woman in her early thirties who works as a quarantine physician in a jungle of monstrous growth, building her tools from what she has cut out of it, forward-leaning wedge silhouette, weight forward on the front foot, both hands gripping a long iron-shod pole longer than she is tall, levelled forward toward the right like a lance and slightly raised, at its far end an iron cage of three curved prongs holding a giant warty tree gall the size of her head, a tumour-like growth cut from a jungle tree, cracked open along one jagged seam and venting one thick solid plume of smoke that curls up and back over her head, a hooked black chitin beak cut from a jungle creature strapped over only her nose and mouth and projecting forward to a point, a pair of round goggles pushed up onto her forehead, the upper half of the face fully open and lit, realistic adult head proportion, face lit with no shadow across the eyes, shadow falling on the side of the head away from the light and beneath the jaw, eyes as two bone white almond shapes each with a solid ink black pupil looking to the right, sized to read clearly but no larger than an adult eye, a narrow fine-boned face with a straight thin nose and a small pointed chin, a stern hard stare, narrow straight brows drawn hard together, chin tucked, head tilted toward the gall, black hair pulled back tight into one high knot at the crown as one flat mass, three ink black vein marks creeping up the side of her neck from beneath the collar, a fitted high-collared waxed oilcloth jerkin laced down one side, forearms bound tight in linen wraps from wrist to elbow, oxblood leather gloves, a skirt of four heavy blackened oilcloth panels split to the hip and hanging to mid-calf above tall laced boots, each panel ending in a ragged hard-edged hem, the panels and the lower right side of the figure falling into solid aubergine-black shadow, boots with a simple sole division, in contact with a single flat ground line, three-quarter view facing right, eye-level camera at chest height, orthographic, isolated on a plain flat background of one uniform color, full figure visible with headroom.
```

Counted groups: three cage prongs at the weapon head, four skirt panels at the
hem, three vein marks at the neck — three, in three regions, with the two goggles
as a small fourth. **Cut order:** the ragged hems before any of the counts.

This prompt carries the flat-panel clause and an occupation clause, both of which
8.6.1 and 5.7 have since replaced. Recorded as generated; do not copy those two
clauses forward.


#### 8.7.2 Diviner

Generated and judged good; not yet composited against an approved character,
which 18 requires before she is marked approved. Composite against the Plague
Doctor (the other Act 1 woman with her lower face covered) and the Thief (the
other narrow vertical, 8.3).

The first prompt recorded with no occupation or lore clause (5.7), and the
working example of a partial semi-transparent veil (8.4.5), of a light accent kept
off a brown-row face (8.4.1), and of an element from outside reality made strange
by arrangement rather than by added parts (8.1).

Slots: garment main saturated deep burnt sienna wrap-coat, material neutral warm
sand-tan linen, leather tar-dark blackened, shadow black green-black — tinted
against the garment main, so band 1 buys a green third hue under the warm garment
— skin brown row, accent pale lilac on the lit faces of the crystal shards, the
veil border at the crown and the sigil plate at the throat, focal region the shard
ball and the upper face. Occupation, for the design only: an omen-walker who walks
point for salvage crews into the Reclaimed City's jungle.

Decisions recorded with it:

- **The crystal ball is six floating raw shards.** Jagged, unpolished, like ore
  from a mine, hovering over an open palm in the shape of a ball, with narrow gaps
  between them. It keeps the ball read and one shape language, and it is
  impossible by arrangement alone (8.1).
- **The veil is split in function.** Pinned at the back of the crown and falling
  straight down her back to the knees, it gives the narrow vertical a rear mass
  that separates her from the Thief's hood without shoulder width. Drawn across the
  nose and mouth as a sheer layer, it keeps the diviner read while the eyes and
  upper face stay lit (8.4.5).
- **Accent kept off the face.** The registry's veil trim sits at the crown edge,
  behind the hair dome, because pale lilac out-lights a brown-row face (8.4.1).
  Nothing light touches the veil's edge across the nose.
- **Combat read from a tool, not a weapon.** A short hooked jungle blade held low
  and close at the thigh, pewter, hook turned outward. No long shaft, so the
  three-shaft count in 8.3 is unchanged.
- **Robed-Role exit through the hem.** Kilted up to the knee on the near side,
  mid-calf on the far side (8.3).
- **Face and appearance.** Brown skin row, long-and-angular cluster, late
  thirties, tight coiled black hair grown out into a high rounded dome — none
  repeating the last three approved characters (8.4.6). No region label was used.
- **Vocabulary.** "Fortune teller", "crystal ball", "robe", "headscarf" and coins
  were kept out of the prompt, on the suspicion that stereotypical diviner
  vocabulary is a basin of its own. Untested; not added to 5.3.

```
bold woodcut illustration with engraved structural linework, very thick uniform black contour outline on the outer silhouette, clean uninterrupted silhouette edge, flat color fields, hard-edged shadows, high contrast with large areas of solid shadow in a deep green-black, that shadow mass and the outline sitting at the same value, colors assigned by material: brown skin, a saturated deep burnt sienna wrap-coat, warm sand-tan linen trousers and wraps, tar-dark blackened leather straps, bracers, gloves and boots, dull pewter grey metal fittings, all flat and unmodulated, warm bone white reserved for small highlight shapes and the eyes, outline black tinted slightly toward blue-violet, light from the upper left casting a narrow bone white edge along the upper left contour, three levels of detail: the floating crystal shards above her raised hand and her upper face carry the heaviest engraved detail and read as the focal point of the figure; the wrap-coat, sash and veil carry moderate engraved detail through seams, panel divisions, border bands and wrapped fastenings; the limbs and boots carry light detail through wraps and fold lines rather than being left empty; the face and neck held as flat unbroken color carrying no more than four engraved lines in total, each one large and structural, all marks large and structural, with saturated pale lilac as the single accent covering roughly a fifth of the figure, flat and uniform with little texture, used only on the lit faces of the crystal shards, the border band of the veil at her crown and the sigil plate at her throat, hand-carved edge quality.
full body character, a woman in her late thirties, narrow tall vertical silhouette with a tight outline and no shoulder mass, standing upright in a guarded ready stance with her weight settled on the rear foot and the front foot pointed toward the right, one arm raised with the elbow tucked close to her side, the gloved hand held open palm up at shoulder height forward and clear of her face, above the open palm six large jagged raw crystal shards hovering in a tight cluster arranged into the shape of a ball the size of her head, each shard rough and unpolished with broken angular faces like ore fresh from a mine, the shards separated by narrow gaps and read together as one round mass with a jagged outer edge, the lit faces of the shards pale lilac and their shadow faces green-black, her other hand low and close against her thigh gripping a short hooked jungle blade of dull pewter with the hook turned outward, realistic adult head proportion, face lit with no shadow across the eyes, shadow falling on the side of the head away from the light and beneath the jaw, eyes as two bone white almond shapes each with a solid ink black pupil looking toward the shards, sized to read clearly but no larger than an adult eye, a long angular face with a high narrow bridge, a square chin and a hollow beneath the cheekbone, the lit upper face set against the dark hair and dark veil around it, a sheer near-black green gauze veil drawn across her nose and mouth and fastened behind the ears, its upper edge one hard straight line across the bridge of the nose beneath the eyes, her nose, lips and jaw visible through it as one flat shape a full band darker than the lit upper face, calm level brows, chin raised slightly, head tilted toward the shards, tight coiled black hair grown out into a wide high rounded dome as one flat mass, the veil continuing from the back of the crown behind the hair and falling straight down her back close to the body to the backs of her knees, its edge at the crown bound in a pale lilac border band, a high blackened leather collar band at her throat carrying one flat pale lilac sigil plate cut in the shape of an open eye, a fitted burnt sienna wrap-coat closed across the body and fastened with a knotted sash at the hip, the coat skirt kilted up into the sash to the knee on the near side and falling to mid-calf on the far side, the hem edged with a woven border band of five large repeated diamond motifs, the sleeves bound close to the forearms with blackened leather bracers, sand-tan linen trousers bound from ankle to knee in four heavy wrap bands, a square patch of a different weave sewn onto one knee of the wrappings with hard angular stitching, the coat and the lower right side of the figure falling into solid green-black shadow, tall blackened boots with a simple sole division, in contact with a single flat ground line, three-quarter view facing right, eye-level camera at chest height, orthographic, isolated on a plain flat background of one uniform color, full figure visible with headroom.
```

Counted groups: six shards at the raised hand, five diamond motifs at the hem,
four wrap bands on the shins — three, in three regions. **Cut order:** the diamond
motifs first. The knee patch is the history and is cut last.

Three failure modes on any revision. **Shard spacing:** if the gaps widen and the
cluster scatters, go to five shards and hairline gaps; if the shards fuse into one
rock, widen the gaps slightly. Either way the cluster's outer edge is the
silhouette risk under 7.1. **Accent coverage:** six lilac-faced shards is the
largest accent area on the figure; if it runs over a fifth, keep lilac on the
upper faces only. **Hue adjacency:** the burnt sienna garment sits near the
Thief's rust orange accent — check it in the composite.

#### 8.7.3 Warlord


Slots: garment main warm ivory parchment tabard, material neutral steel blue-grey
quilted doublet, leather bark-brown, shadow ash-blue-black, skin pale, accent deep
brick red on the standing collar, pauldron trim and baldric tags. Occupation, for
the design only: an Iron Ledger bailiff who fights with confiscated gear.

- **Seized arsenal.** "Master of none" as five hafts with different heads and
  three armor pieces from three suits, inventoried rather than scavenged (8.1).
  Runner-up occupation, kept for a second Warlord: a Margins barricade warden.
- **Stained glass shield** as the element, unreal by design (8.1).

```
bold woodcut illustration with engraved structural linework, very thick uniform black contour outline on the outer silhouette, clean uninterrupted silhouette edge, flat color fields, hard-edged shadows, high contrast with large areas of solid shadow in a deep ash-blue-black, that shadow mass and the outline sitting at the same value, colors assigned by material: pale skin, a warm ivory parchment tabard, a steel blue-grey quilted doublet, bark-brown leather straps, baldric and boots, dull pewter grey metal fittings, all flat and unmodulated, warm bone white reserved for small highlight shapes and the eyes, outline black tinted slightly toward blue-violet, light from the upper left casting a narrow bone white edge along the upper left contour, three levels of detail: the stained glass shield and the pauldron carry the heaviest engraved detail and read as the focal points of the figure; the tabard, doublet and baldric carry moderate engraved detail through quilting seams, panel divisions, border bands and strap fastenings; the limbs and boots carry light detail through wraps and fold lines rather than being left empty; the face and neck held as flat unbroken color carrying no more than four engraved lines in total, each one large and structural, all marks large and structural, with saturated deep brick red as the single accent covering roughly a fifth of the figure, flat and uniform with little texture, used only on the whole standing collar, the trim of the pauldron and the tags along the baldric, hand-carved edge quality.
full body character, a broad-shouldered solidly built man in his mid-forties, standing planted behind a tall ornate shield with his weight driven forward onto the front foot and his near shoulder set against the back of the shield, the shield standing on the ground line in front of him on the side toward the right, its top reaching his chest, his near forearm through its straps and his far hand gripping its upper edge, the shield wide at the top and rising to a pointed arch crowned by three short iron spires, its sides pinched inward at the middle and flaring out wide again at the base into two curled iron hooks that bite into the ground, a heavy black iron rim running around its whole outline, its face a stained glass design of twelve bold flat panes of colored glass held in thick black iron tracery with curling scrollwork, a round rose of panes at its center, the panes in deep sapphire blue, warm amber and dusky violet with a few pale clear panes among them, each pane one flat color, a bundle of five weapon hafts strapped diagonally across his back and rising in a tight bundle close above his far shoulder, each ending in a different head: an axe blade, a hook, a flanged mace, a spear point and a hammer, realistic adult head proportion, face lit with no shadow across the eyes, shadow falling on the side of the head away from the light and beneath the jaw, eyes as two bone white almond shapes each with a solid ink black pupil looking to the right, sized to read clearly but no larger than an adult eye, a round heavy face with a round jaw, full cheeks, a short snub nose and a low brow ridge, dark brown hair cropped close to the skull as one flat mass, a short squared dark brown beard as one flat mass, level unimpressed brows, chin up and head tilted slightly back, one corner of the mouth drawn back, a stiff standing collar at the throat, a steel blue-grey quilted doublet with clean square seams and a row of six pewter buttons down its front, over it a sleeveless ivory parchment tabard cut in four long panels falling to the knee, each panel ending in a scalloped hem, the hem and armholes edged with a border band of three hard parallel ruled lines, one large squared fluted pewter pauldron on the near shoulder, its edge trimmed in brick red, a bark-brown leather baldric running across the chest from the far shoulder carrying four flat brick red tags in a row, three mismatched armor pieces each from a different suit: a dented dark blued iron vambrace on the far forearm, a battered pale steel knee cop on the rear knee and a riveted blackened iron elbow cop on the far arm, the tabard and the whole lower right side of the figure falling into solid ash-blue-black shadow, tall square-toed bark-brown boots with a simple sole division, in contact with a single flat ground line, three-quarter view facing right, eye-level camera at chest height, orthographic, isolated on a plain flat background of one uniform color, full figure visible with headroom.
```


Fixes, if a revision fails:

- **Goes pale:** replace `the tabard and the whole lower right side` with `the far
  half of the tabard, the doublet sleeves and the whole lower right side`.
- **Glass competes with the accent:** replace `with a few pale clear panes among
  them` with `mostly in deep sapphire blue with only a few amber and violet panes`.
- **Reads as a window:** replace `rising to a pointed arch crowned by three short
  iron spires` with `rising to a sharp central point flanked by two swept-back iron
  horns`.
- **Tabard reads as a monk's habit:** replace `cut in four long panels falling to
  the knee` with `cut short and square at the knee, stiff and flared like plate`.
- **Build comes back fat:** replace `a broad-shouldered solidly built man` with `a
  broad-shouldered hard-bodied man with a thick neck and heavy forearms`.

### 8.8 Portrait and card crops

Portraits are **cut from the approved full figure**, not generated separately.
Each character preset carries a `_headshot_region` — a crop rectangle in
normalized (0–1) coordinates of its own art file, so it survives a re-export at
another resolution. Left at the full `0, 0, 1, 1`, the character shows its whole
figure.

The crop is what small slots draw: the roster and sacrifice grids, party-select
slots, post-battle results, and tally board. The full figure is what the
inspect-menu character portrait, the turn bar, the opponent preview, and the
battle sprite draw.

Compose the figure so a head-and-shoulders crop is available without the accent
falling outside it. Minimum face size in the crop, and whether the accent budget
is recounted within it, are open.

### 8.9 Accent registry

One color per Role, no sharing. Hue alone cannot separate twenty entries at phone
size, so **value** and **placement** carry the same signal in parallel.

| Role | Accent | Hex | Value | Placement |
|---|---|---|---|---|
| Thief | rust orange | #C25A1E | mid | hood lining, blade edges at belt |
| Bloodmage | crimson | #A32036 | dark | chest channels, forearm staining, belt-chain cord |
| Bar Brawler | terracotta | #B8563A | mid | apron, knuckle wraps |
| Lancer | flame copper | #E07B2C | light | lance pennant, helmet crest |
| Jester | saffron | #EDB431 | light | cap bells, collar motley, wrapped knife grips |
| Architect | muted brass | #C69A4B | mid-light | drafting instruments on chest, hat band |
| Appraiser | antique gold | #8F7326 | dark | lens ring at the wheel hub, stamped collar plates at the throat, one gauge disc among the hip trinkets |
| Scholar | ledger parchment | #DCCFA8 | lightest | open ledger at chest, spectacle rims |
| Alchemist | acid chartreuse | #A8BF3A | light | flask contents, apron spill stain |
| Symbiote | verdant green | #4E8C3F | mid | fungal mass on shoulder and skull |
| Plague Doctor | deep moss | #2F5D3A | dark | cracked interior of the caged gall, goggle lenses on the forehead, collar lining |
| Tidal Corsair | sea teal | #2E8C8C | mid | coat sash, pistol furniture |
| Chronophage | ice cyan | #8FD4DC | light | clock-face at chest |
| Sorcerer | unstable cobalt | #2F52C4 | mid | slab inscriptions at the chest, hood lining, stone in the rod crown |
| Emissary | ink indigo | #26326B | dark | seal wax on chest documents, badge |
| Diviner | pale lilac | #B9A5D9 | light | lit faces of the floating crystal shards, veil border at the crown, throat sigil |
| Cultist | deep amethyst | #5B2A78 | dark | throat brand, robe lining, stained fingers |
| Herald of the Loom | violet magenta | #8E3A91 | mid | active thread through chest loom-frame |
| Tactician | rose magenta | #C2447A | mid | map case, marker rods |
| Warlord | steel blue-grey & deep brick red | #6B7A88 #7E3222 | mid/dark | whole standing collar, pauldron trim, tags along the baldric |

**Watch these three pairs:** Architect brass / Appraiser gold, Sorcerer cobalt /
Emissary indigo, Cultist amethyst / Herald magenta. The value gap does the
separating in each case, so if a hex is adjusted, never adjust it toward its
neighbour's brightness. Placement differs in all three pairs as a backup.

**Check the accent against the Role's own garment too.** Hue adjacency between a
saturated garment main and the accent is a live failure mode. When they merge,
move the garment's value; never shift either hue.

**Eyes are never the accent.** Accent-colored eyes read as menacing and break 8.4.

**Accent never lands on skin.** Scars, brands and burns are band 1 shapes (8.5).

**Only three champions are fielded at a time**, so full-roster clashes are largely
theoretical. What matters is that any three the player picks stay separable.

**Extend each accent beyond the sprite** — card border, map icon, damage numbers,
skill VFX. Twenty hues is a lot to learn from sprites alone, but the association
forms within an hour or two of play when the same color appears in four places.

#### 8.9.1 Accent hexes that need attention

A dull accent on a dull garment gives a figure with no vibrancy anywhere:

- **Warlord** — resolved: steel blue-grey paired with deep brick red (8.7.4).
- **Appraiser `#8F7326`** and **Scholar `#DCCFA8`** are both close to being
  materials rather than accents. Raise chroma and let value and placement keep
  doing the separating.

Generate accents as flat uniform fills so they can be masked and boosted in post.
Asking Leonardo for a brighter accent drags the whole figure with it; recoloring
the mask does not.

---

## 9. Enemies and bosses

Enemies inherit everything in Part I and most of section 8. What follows is the
difference.

### 9.1 Detail tier by content tier

- **Player Roles** — the block as written.
- **Fodder enemies** — drop to `minimal interior detail, large simple shapes,
  three values`, faces dark and anonymous, no accent or a heavily reduced one.
- **Bosses** — same block as player Roles plus one additional counted focal
  element. Do not raise the detail ceiling. Distinguish bosses by scale and by the
  extra focal element.

### 9.2 Fodder

> **Not yet written.** How many distinct fodder bodies exist per area, whether
> recolours are permitted and on which slot, and how a fodder silhouette stays
> separable from a champion's at 300 px.

### 9.3 Mini-bosses and bosses

> **Not yet written.** Scale relative to champions, how the additional counted
> focal element is chosen, and whether bosses carry an accent registered like a
> Role's or borrow the area scene light.

### 9.4 Non-humanoid and creature forms

> **Not yet written.** The guide assumes a humanoid figure throughout. Beasts,
> constructs and statues need their own answers on band 1 coverage, the face rule
> (8.4 assumes eyes), and where the accent sits when there is no head-and-chest
> region.

### 9.5 Enemy color policy

> **Not yet written.** Whether enemies draw from the champion accent registry,
> from the area scene light, or from a separate reserved set — and how enemy color
> avoids being read as a champion's identity color during a fight.

---
## 10. Environments

There are **three kinds of environment art**, and they do not share a camera.

**Battle stages** (10.3) obey section 4 exactly, because characters stand in
them. They are built from four draw-order bands.

**Overworld views** (10.4) are the navigation screens — vistas, or high-above
views the player clicks points of interest on. A chest-height orthographic camera
cannot show a region, and a region has neither eight material fills nor character
scale, so they are exempt from section 4 and from the four-band rule (1.1).
Everything else in Part I still binds, and the outline weight and the
post-processing pass are what keep an overworld reading as the same game as the
battle it leads into. What the ramp becomes instead is 10.4.3.

**Selection panels** (10.8) show the viewpoint of a party looking into a place
they have not entered — what could be found if it were explored. Often epic, with
much verticality. They are exempt from section 4 as well (1.1), and they earn it
because nothing else is present beside them for the break to show against.

### 10.1 Rules

Applies to battle stages. Overworld views take the second and third bullets only.

- **Shallow stage.** A wall or skyline, and a floor plane of 170 px. Shallow is
  about how little sits between those two, not about the floor being thin.
- **No figures, no creatures** — state both.
- **Flat horizon low in frame**, at the fixed screen fraction from section 4.
- **Contrast budget behind the character line.** Whatever sits behind the six
  character slots stays a band or two off the figures. Density is free; value
  proximity is not.

#### 10.1.1 The contrast budget

The constraint is **value, not space.** Characters are roughly half band 1 (2.1),
so a champion in front of a band 3 foliage mass reads cleanly, and the same
champion in front of a band 1 trunk becomes a silhouette inside a silhouette.

The midband may therefore be packed wall to wall, as long as the region behind
the character slots holds the mids and leaves band 1 to the bands that have no
figures in front of them — the foreground and the far skyline. That is a budget
the layout spends, checked in the grey-box step (4.3, 10.3.5) rather than
enforced by a rule the engine knows about.

The floor keeps its own spatial rule: the scatter holds a clear radius around
every character's feet (10.3.3).

**A background may carry a character's accent hue.** Accent identity is carried
by card borders, damage numbers, skill art and the map icon, and a character's
accent is a flat 15–20% mass at mid-to-high chroma against a stage that is dark by
construction (10.2). If a saturated mid-value mass lands directly behind a
champion's accent, that is a value collision to fix in the layout, not a reason to
restrict the palette.

### 10.2 Scene light — the mood dial

Each variant gets a **scene light color** — one per variant, not one per area,
since a jungle and a ruin under the same sickly teal-green read as the same place.
It is not a Role accent and never appears on a character's costume. It lives in
the sky field, the haze band between bands, and the tint of the floor plane.

| Area | Variant | Sky field | Ground / skyline |
|---|---|---|---|
| Reclaimed City | Jungle | sickly teal-green #2E5A50 | #0E1614 |
| Reclaimed City | Ruins | violet #3A2A52 | #120E1A |
| Clockwork Spire | Construction areas | TBD | TBD |
| Clockwork Spire | Mine slums | TBD | TBD |
| Pirate Coves | Rocky islands | cold teal #2C5F72 | #0E1418 |
| Pirate Coves | Shanty town | TBD, warm (10.6) | TBD |
| The Iron Ledger | Slums | cold slate blue #33414D | #10161B |
| The Iron Ledger | Inner city | TBD (10.6) | TBD |

**Characters carry saturated hue of their own** (3.5), so check each new variant
against a fielded team of three: a saturated garment main can collide with a scene
light in a way a beige one never did. The fix is the variant, not the character.

**A shared hue is not a collision; a shared value is.** The check runs on a
composite at target size, and it fails when a figure stops separating from what is
behind it — not when a jungle and a Role are both green (10.1.1).

### 10.3 Battle stages — the four bands

Every battle stage is a scene authored by hand, laying its elements out across
four bands. A band is a budget as much as a layer: content that belongs to one
band does not appear in another, which is what lets elements be reused across
stages within an area.

They draw in the order **Background, Floor, Midband, characters, Foreground**.
A midband element that *stands on the ground* — a trunk, a shrub, a ruin — needs
its base to cover the floor's far edge; drawing the floor after it would cut a hard
horizontal line across it. This is a draw-order note for standing elements only.
Hanging masses, canopy strips and anything else that does not reach the ground owe
nothing to the floor edge.

#### 10.3.1 Background

Sky, clouds, moon, sun, mountains, silhouettes of far-away things. Carries the
scene light's sky field (10.2) as one flat saturated field. Lowest detail of the
four bands, and the only band permitted to reduce below the full value ramp.

One plate per stage, drawn to the full 1280×720 frame. The camera does not scroll
(10.3.5), so the sky and the far masses are one asset.

> **Not yet written.** Value range allowed, and whether distant masses are
> silhouette-only.

#### 10.3.2 Midband

The visible surroundings of the combat: buildings, trees, foliage, rocks, walls,
waterfalls. This is the band that says which area the player is in, and the band
that carries the stage's density.

Assembled from keyed elements, placed one by one in the stage scene. The band may
run full width with no gap; what it owes is the contrast budget in 10.1. Because
that is a value judgement rather than a placement rule, it is judged on the
grey-box against the six character positions (10.3.5) and again on the first
composite.

**Density is cheapest from above and behind.** Elements that hang from the top
edge — vine falls, aerial root curtains, a canopy underside strip closing the top
of the frame — fill the stage without adding mass at character height, which is
the one place mass costs readability.

**Midband elements are generated one per image** (10.3.7), and their color policy
is their own (10.3.10) — the floor's quiet rule does not carry up.

> **Not yet written.** Detail budget for a midband element relative to a champion
> standing in front of it. The floor set is held deliberately quiet (10.3.9) and
> gives no guidance here.

#### 10.3.3 Floor

**The floor is a plane, 170 px of the 720 px frame**, not a strip and not a line,
and **a character's Y position within it is their depth.**

Everything about that is handled in the engine and **no art accounts for it.**
Scale by depth is applied on placement, so an element is authored once at one size
and drawn at whatever size its Y calls for; draw order within the band follows Y
for the same reason. The art's only obligation is to survive being placed at a
size it was not drawn at, which is 5.5's structural-detail test doing its usual
job.

Clutter must not compete with a character's silhouette for the same value.

The plane itself is one shader-driven surface. The clutter over it is not baked
in: it is scattered by the engine from a small element set, authored per stage as
scatter rules — an element's textures, its density, its scale and rotation jitter,
and the radius it holds clear around every character's feet. The scatter is seeded
per battle, so the same fight re-entered looks the same.

##### 10.3.3.1 Every element is an upright billboard

**Nothing generated for this band lies on the ground.** Every element is an
upright billboard in side elevation, cut flat along the bottom (10.3.7), and that
holds for the midband and foreground too.

The reason is the tool, not the camera: **a generator cannot be made to hold a
consistent foreshortening.** A puddle, a paving slab or a fallen leaf drawn to the
plane's angle has to match every other ground-lying element in the scene and match
it again at the next placement depth, and no phrasing enforces that. One decal at
the wrong angle breaks the plane for everything standing on it.

So the ground-lying reads that a jungle floor might want are not element art:

| Wanted | Where it goes |
|---|---|
| Mud pools, puddles, standing water, wet patches | Floor shader |
| Paving, tile, cracked ground, scorch marks, worn paths | Floor shader |
| Contact shadows under elements and characters | Engine, drawn (10.3.8) |
| Fungus rings, scattered leaf litter, root runs | Not used, or re-formed as something standing |

**The shader owns the plane; the element set owns what stands on it.**

Re-forming is usually available and usually better. A leaf lying flat becomes a
litter mound or a leaf on a standing stem; flat debris becomes a slab tipped up
or a broken stub; a fungus ring becomes a cluster growing up out of the ground.
Ask what the element is *for* before writing it off.

#### 10.3.4 Foreground

The last band before UI: vines, weather (rain, snow, fog, sun rays), and
occasional silhouettes intruding from the bottom edge — crates, bushes, trash,
similar. Foreground reads as pure band 1 by default, since anything with interior
detail here fights the characters.

**No foreground element crosses a character slot.** Silhouettes are placed by hand
along the bottom edge, clear of the character line. Weather is neither art nor
shader in this band: it is a particle scene, chosen per encounter rather than per
stage, and it plays in front of the silhouettes — which is what keeps an indoor
fight dry on a stage otherwise used outdoors.

> **Not yet written.** Maximum screen coverage so the fight stays readable.

#### 10.3.5 Layer spec

The battle camera does not scroll, so the bands have no parallax ratio and nothing
sits off-screen at rest. Every band is authored to the full 1280×720 frame. Camera
shake moves the whole stage as one, bands and characters together — a band that
lagged behind the others under shake would read as a seam.

A stage is laid out against the six character positions and judged there, which is
the grey-box step (4.3) for this section.

> **Not yet written.** Section 6 assumes a haze quad between bands, so state where
> the haze sits relative to the four.

#### 10.3.6 Element catalog and reuse

Each variant owns a catalog of elements per band, and its stages are laid out from
that catalog — two or three stages per variant, so an element is seen again across
them. Reuse is what the catalog is for: a stage earns its distinctness from its
layout and its background plate, not from elements nothing else uses.

Elements are keyed individually rather than cut from a generated plate, since a
stage places them one at a time and at its own scale.

> **Not yet written.** How many elements a variant needs before its stages stop
> reading as the same place, and the rule for what may be reused across the two
> variants inside an area.

#### 10.3.7 Authoring a stage element

10.3.1–10.3.4 say what a band contains. This says how a single keyed element is
generated. The findings are craft rather than biome, and apply to every band and
every variant.

**The general block.** Prepended to every element prompt, the way 8.6 works for
characters. The bracketed clauses are filled per element.

```
bold woodcut illustration with engraved structural linework and visible
gouge marks, thick black contour outline on the outer silhouette, flat color
fields, hard-edged shadows, no gradients, orthographic side elevation seen
straight on at eye level, no highlight edge anywhere, [DEPTH CLAUSE],
[DETAIL CLAUSE], hand-carved edge quality, [FRAMING CLAUSE], [SUBJECT],
[FRAMING TAIL]
```

The framing clause and tail depend on how many subjects go on one image:

| Element size | Framing clause | Framing tail |
|---|---|---|
| Small — floor clutter, anything knee height | *three separate [subjects] standing far apart in a row with empty background between them* | *each cut off flat and straight along the bottom edge* |
| Large — anything tall enough to crowd a sheet of three (most of the midband) | *one single [subject] shown whole and complete with clear empty space on all sides, nothing cut off by the edges of the image* | *cut off flat and straight along the bottom edge, the whole subject visible with headroom above and margin to both sides* |

A subject that is meant to leave the frame says so for that part only and asks for
margin everywhere else — a hanging cluster's stem *runs up and out through the
top edge of the image*, and a trunk is *cut off cleanly along a straight
horizontal break at the top* (10.6.1.3).

**Background.** Generate with Leonardo's transparency setting and leave the
background clause out entirely. The earlier approved prompts end in *isolated on a
plain flat solid white background*, which is what a generation without
transparency still needs; see *Key color* below.

**Flat fields need the engraved line, or the element reads as a comic.** Flat
fields and engraved linework are a pair; removing the carving removes the style.
Nothing in this guide should ever ask for one without the other.

**No highlight edge on environment elements.** The bone white upper-left rim that
separates a focal mass in an icon (12.6.4) reads as comic-book inking on small
scatter props, and against a black contour it is the strongest cartoon cue
available. The light direction is still upper left and still carried by which side
falls into shadow; it just gets no drawn rim. Bone white in this band is spent on
the midband's lit masses, if anywhere.

**The depth clause is per material class** (5.6) — layers for masses of parts,
facets for solids. It is the clause that stops an element reading as a wooden
cutout, and it is the clause to strengthen when one still does: push it to *three
distinct depth layers, the back layer almost lost in black* rather than adding
detail elsewhere.

**Grit is structural** (5.5). On stone that means fracture lines, chipped edges,
pocked hollows, gouge marks and parallel hatching along the shadow side. *Rough*,
*weathered* and *mossy-looking* return nothing. On a soft mass the opposite holds:
leave it flat and uncarved, and the contrast against all that cutting is what
makes the stone read as hard.

**Organic subjects are described loosely** (5.4). Counts belong to built objects —
a crate, a lantern, a ruin's ironwork — wherever they appear.

**An element of two materials takes both depth clauses**, each tied to its own
material — layers for the foliage, facets for the stone showing through it; facets
for a trunk, layers for the growth clinging to it. The carving follows the same
split: engraved detail on the solid, the soft mass flat and uncarved. If the solid
starts reading as holes punched in the soft mass, the facet clause is losing — push
the solid's own value contrast up a band rather than enlarging it.

**The head noun sets the proportion.** Whatever the subject clause names is what
gets drawn, and everything described after it becomes decoration on it. *Broken
stone wall segments* with growth added afterwards returns a clean ruin with a
little moss, and *heavily overgrown* does not move it, for the same reason
*moderate detail* fails (5.4). To flip the proportion, flip the noun: name the
dominant mass first and the other thing as what is inside it — *dense masses of
jungle growth, each swallowing the remains of a stone wall almost entirely*. State
the minor part by how much of it is left showing, counted if it is built, so it
does not vanish altogether.

**Give the minor part the one shape the major part cannot make.** A swallowed ruin
stays a ruin, rather than becoming another bush, because a straight edge or a right
angle breaks its outer silhouette, which foliage cannot fake. When a variant comes
back as pure foliage, strengthen the hard-edge clause rather than raising the count.

**Small elements: three variants per sheet, in one generation.** A floor element
is generated as three of its kind spaced far apart in a row, described as *each a
different kind* with one loose phrase per variant. One generation gives three
slices and a choice, and the three read as siblings because they came out of the
same pass. When the variants drift together and merge at the bases, *far apart* is
the phrase to strengthen.

**Large elements: one per image.** Three colossal trunks on one sheet leaves each a
narrow column, and the model crops their sides to make them fit. A narrow column
also has no room for anything living on the subject, so a trunk comes back as a
bare shaft. Variants of a large element are separate generations of one prompt,
with the variant's shape wording swapped between them.

**Ask for the whole subject, never for a filled frame.** *Filling the frame* reads
as an instruction to push the subject past the edges, and every bloom generated
with it came back cropped. The large-element framing above is what fixed it. If a
subject still crops, weaken the scale words next — *enormous*, *taller than a man*
push outward on their own, and an element's scale comes from placement in the
engine anyway (10.3.3). *That last step is untested.*

**Key color, when transparency is not used, is flat white.** The contour is ink
black and the fills are muted, so a saturated key fringes every edge it touches.
Where a pale element fringes against white, drop the element's front layer a band
rather than changing the key color. With the transparency setting (above) there is
no key to fringe against.

#### 10.3.8 Grounding is an engine problem

Elements are cut flat along the bottom, which leaves them sitting on the plane
with a visible seam. **The join is made in the engine and never baked into the
art**, by three means together:

- **A contact shadow** drawn between the floor plane and the element — a flat band
  1 shape with a hard edge, offset down-right to agree with the upper-left light,
  scaled per element. Drawn in engine rather than generated: it is a flat shape
  with no interior detail, it costs nothing to draw, and it can be tuned live.
- **Sinking** the element a few pixels below the plane's near edge so the surface
  covers the cut.
- **Scatter bias** — the floor set placed in front of other elements' bases, which
  is the scatter rules (10.3.3) with one added bias toward bases rather than away
  from them.

The contact shadow does a second job on a 170 px plane: it is the cue that says
*where in the band* an element is standing. Elements are billboards and carry no
perspective of their own (10.3.3.1), so the shadow and the Y position are the only
depth information the floor has.

#### 10.3.9 Color policy for the floor band

The floor is the band the player least needs to look at, and the one closest to
their eye. Both pull the same way: **keep it quiet.** Quiet is a contrast
instruction, not a saturation one.

The policy is 10.8.5's, applied at element scale: **mass is low saturation,
incident is wide range.** The bulk of an element — stalks, stone, blade mass, dry
matter — sits muted and low in contrast. Small parts of it — a cap, a bloom, a cut
face — may carry real chroma, and should, because they are small enough that the
plane stays calm. Different hues across the set, so no single one reads as a
Role's accent.

The check is the composite: a saturated shape low in the frame is doing the same
job a character's accent does. If a cluster pulls the eye off a champion standing
beside it, **drop that element a value band rather than desaturating it.**

#### 10.3.10 Color policy for the midband

The floor is kept quiet because it is the band least worth looking at. The midband
is the opposite: it is the band that says which area the player is in (10.3.2), so
it is **not** held to 10.3.9. A trunk authored under the floor's rule came back
grey-brown from edge to edge and read as dead wood, not a jungle tree.

**The mass is muted; the chroma lives on it.** The structural mass of an element —
bark, stone, the bulk of a foliage clump — stays in the variant's mass direction
(10.6.1.1 for Jungle) and is the element's value anchor. The color arrives as
things *growing on or out of* that mass: epiphytes in the crooks, bromeliads in the
bark hollows, small blooms scattered through the growth, the coloured underside of
a leaf. That puts chroma on the element without asking for more carving on its
mass, which the quantize step would not keep anyway.

A dedicated chroma element — a giant bloom — is the opposite case: the petals are
the subject and carry saturated color at full area, while the stalk and leaves
stay in the mass direction.

**Spread hues across the set.** Each dedicated chroma element takes a different
hue so the band shows range rather than one color repeated, and no single hue reads
as a Role's accent. Small incident color — the blooms on a trunk — may borrow from
those hues. Where a midband hue repeats one from the floor set, check the
composite: two same-hue shapes landing in the same part of the frame means one of
them moves.

**The value rule still binds.** Chroma does not buy value. An element big enough to
sit entirely behind a character slot keeps its mass at bands 2–3, with near-black
confined to recesses and shadow sides (10.1.1). When one comes back too dark, cut
the dark growth patches before touching the mass — they are the cheapest area of
band 1 on the element.

> **Not yet decided.** Which band carries the stage's loudest chroma — the giant
> blooms, the growth on the trunks or the ground mushrooms (19.3).

### 10.4 Overworld and navigation views

One or more per area (10.6), used to navigate by clicking points of interest.

#### 10.4.1 Camera and framing

> **Not yet written.** Decide vista versus high-above, and whether that is one
> convention for all areas or a choice per area. Needs the camera treatment,
> whether the view scrolls or fits one screen, and how it holds the
> light-from-upper-left rule when the ground plane is no longer vertical.

#### 10.4.2 Points of interest

> **Not yet written.** What a clickable point looks like on the plate, its states
> (locked, available, cleared, current), how it stays legible against dense
> terrain, and whether it shares a visual language with the Adventure node icons
> in 12.3.

#### 10.4.3 Legibility at overworld scale

> **Not yet written.** State what survives at this camera: the outline weight at
> region scale, how many value bands replace the four this class is exempt from
> (1.1), and how an area reads as itself when its midband vocabulary is not
> visible.

### 10.5 Hub screens

One per area (10.6). The hub is where the war room, Armory, Adventurer's Guild and
shop live (`Concept_Document.md` 3.6).

> **Not yet written.** Decide first whether a hub is an illustrated plate with
> clickable regions, UI panels over a plate, or an icon-driven menu — that
> decision sets how much art exists at all. Then: whether a hub reuses its area's
> battle-band elements or is generated as its own composition, and how the four
> hubs stay distinguishable at a glance.

### 10.6 Area catalog

Four areas are planned. Each has **two variants**, one hub (10.5), at least one
overview screen (10.4), and its own element catalog per battle band (10.3.6). Each
variant owes two or three battle stages (10.3) laid out from that catalog.
Variants are as distinct from each other as two areas would be, so treat a
variant, not an area, as the unit of work. Each also owes Adventure an element set
(10.7).

| Area | Variant A | Variant B |
|---|---|---|
| Reclaimed City | Jungle | Ruins |
| Clockwork Spire | Mechanical construction areas | Oily ad-hoc slums in mines |
| Pirate Coves | Rocky islands, harsh ocean presence | Candle-lit moist and mouldy shanty town, wood and sailcloth |
| The Iron Ledger | Run-down slums of a massive city | White glistering inner city |

**The Iron Ledger's inner city is the hardest asset in the plan.** White
glistering is a light-dominant environment, and section 2 gives band 1 roughly
half of every figure, so a champion in front of a white plate is a black cutout.
Either the inner city takes a treatment that keeps large committed darks in the
midband, or the character rules bend for that one variant — the same trade the
Jester takes in 2.2. Decide it deliberately rather than discovering it in a
composite.

**Pirate Coves variant B is the only candle-lit interior in the set**, which means
a warm scene light and a light source that is not upper-left at region scale.
Section 4's light rule holds for the assets themselves; as the only warm entry in
the 10.2 table it carries the contrast against the other seven on its own.

#### 10.6.1 Reclaimed City

**Variant A — Jungle.** Scene light (10.2): sky field sickly teal-green `#2E5A50`,
ground and skyline `#0E1614`. The intended read is a semi-dark dense jungle — very
tall trees, thick bushes, vines hanging everywhere, vibrant flowers.

**Foliage color direction.** The foliage *mass* is desaturated blue-green and
teal-green; mid-chroma yellow-green is kept out of large areas, where it flips the
biome from dark jungle to daylit. Chroma is carried by the flowers, blooms and
fungus caps, spread across several hues so no single one reads as a Role's
identity color (10.3.9).

**Variant B — Ruins.** Scene light: violet `#3A2A52` / `#120E1A`. No catalog yet.
The ruin masses in the Jungle background were planned to carry straight over, and
so were the swallowed ruin fragments in the midband. The fragments as approved are
now mostly jungle growth with stone showing through (10.6.1.3), so whether they
still belong in Ruins is open (19.3). This is the first concrete case for the
cross-variant reuse question in 10.3.6.

##### 10.6.1.1 Jungle band vocabulary

Status is per band. The floor set and the first midband set are generated and
approved; the rest is planned but not yet generated.

**Background** — one plate per stage, 2–3 stages. *Planned.*

Flat teal-green sky field with no gradient; one bone white moon disc, hard edged,
upper left, partly occluded by the far canopy; three or four hard-edged straight
shafts cutting down through the canopy, each a flat fill a band up from the sky,
stated as cut shapes rather than as glow; a far canopy skyline of colossal trunks
and crowns in pure silhouette, crowns leaving the top of the frame; two or three
far ruin masses in silhouette — a stepped temple shoulder, a leaning column, a
carved stone head half-swallowed; one vertical ravine or waterfall notch breaking
the skyline.

**Midband** — keyed elements, one per image (10.3.7).

*Approved*, two slices kept of each; example prompts in 10.6.1.3:

- **Swallowed ruin fragments** — a swallowed wall and a swallowed column: jungle
  growth with the ruin nearly hidden inside it, a hard stone edge breaking the
  silhouette (10.3.7).
- **Buttress-root colossi** — trunk sections cut off above head height, crown
  unseen, carrying epiphytes, bromeliads and small blooms (10.3.10). Three shape
  variants: straight, tapering, hollowed at the base.
- **Giant blooms** — trumpet bloom on a tall stalk (coral red), ground-level
  cabbage bloom (violet), hanging pod-flower cluster (amber orange).
- **Bushes** — broad-leaf clump and spiked palm crown, the two outline languages
  furthest apart.

*Planned, not generated:*

- A leaning trunk and a dead snag pierced with holes.
- Further bush masses, each with its own outline language — fern fan, low tangled
  briar, tall reed clump, broad low mound are candidates. Outline variety is what
  stops several bushes reading as one bush.
- Hanging masses — aerial root curtains and vine falls at different lengths and
  densities, the band's main density tool (10.3.2).
- A canopy underside strip, foliage intruding down across the full frame width,
  which closes the top of the stage.
- Fungus shelf clusters sized to attach to a trunk.
- A low stepped plinth, the third ruin fragment. Its first prompt predates the
  swallowed-ruin finding (10.3.7) and has to be rewritten the same way before it is
  generated.


**Floor** — three elements, three variants each. **Approved**, prompts in
10.6.1.2. Grass tufts, mossed rocks, ground mushrooms. Weather is not in the
catalog: it is a particle
scene chosen per encounter (10.3.4) — drifting spore motes, light rain through the
shafts, falling leaves, low drifting mist.

**Foreground** — ~7 elements, pure band 1. *Planned.*

One full-height cropped trunk at a side edge, which is the cheapest depth in the
stage; three split-leaf clusters intruding from the bottom corners with distinct
outlines; one fern fan, bottom left; one buttress root arc, bottom right; two thin
vine strands crossing the top edge only; one drooping bloom chosen for a shape
that still reads when filled black.

##### 10.6.1.2 Approved floor prompts

New floor elements for any variant are judged side by side against these at target
size. All three take the general block in 10.3.7 expanded in full.

**Grass tufts (3 variants)**

```
bold woodcut illustration, thick black contour outline on the outer
silhouette, flat color fields, hard-edged shadows, no gradients, orthographic
side elevation seen straight on at eye level, no highlight edge anywhere,
depth built from overlapping layers of blades at different values, the
nearest blades lightest and each layer behind them a full value band darker
receding into near-black, hand-carved edge quality, all in desaturated dark
blue-green, three separate clumps of wild jungle grass standing far apart in
a row with empty background between them, each a different shape: a tall
narrow upright clump with blades shooting up and crossing over one another
at uneven angles, a broad low spray wider than it is tall splaying out
loosely to both sides and sagging at the outer tips, and a ragged clump
tallest at one side and falling away to the other with several blades bent
and drooping over, each clump cut off flat and straight along the bottom
edge, isolated on a plain flat solid white background
```

Generated before the engraved-linework finding and before the color policy, and
approved as it stands. Regenerate with the linework clause if the tufts read flat
beside a carved rock once the midband is in.

**Mossed rocks (3 variants)**

```
bold woodcut illustration with engraved structural linework and visible
gouge marks cut into the stone, thick black contour outline on the outer
silhouette, flat color fields, hard-edged shadows, no gradients, orthographic
side elevation seen straight on at eye level, no highlight edge anywhere,
depth built from the stone breaking into facets at different values, one
side of each rock falling away into near-black, the stone carrying heavy
engraved detail through fracture lines, chipped edges, pocked hollows and
parallel hatching along its shadow side, hand-carved edge quality, three
separate mossed rocks standing far apart in a row with empty background
between them, each a different shape: a broad low boulder much wider than it
is tall, worn and rounded with its stone cracked unevenly, a narrower
upright wedge leaning to one side with harder angular breaks, and a squat
split rock broken open down its middle with the halves settled apart, all in
dull grey-green stone, a thick uneven cap of dark moss sitting over the top
of each and spilling raggedly down one side, the moss as one flat mass with
a torn lower edge and no interior detail, each rock cut off flat and
straight along the bottom edge, isolated on a plain flat solid white
background
```

The moss is deliberately the one uncarved mass in the prompt. If it stops reading
as moss and starts reading as a dark patch of the rock, the phrase to strengthen
is the torn lower edge — that hard ragged boundary is what says a soft thing
growing over a hard one. **Cut order:** hatching, then pocked hollows, then
chipped edges; the fracture lines and the moss edge are never cut.

**Ground mushrooms (3 variants)**

```
bold woodcut illustration with engraved structural linework and visible
gouge marks, thick black contour outline on the outer silhouette, flat color
fields, hard-edged shadows, no gradients, orthographic side elevation seen
straight on at eye level, no highlight edge anywhere, depth built from the
caps and stalks overlapping each other at different values, the nearest
lightest and those behind falling away into near-black, engraved detail
through the gill lines beneath the caps and the fibres running down the
stalks, hand-carved edge quality, three separate clusters of strange jungle
mushrooms growing up out of the ground, standing far apart in a row with
empty background between them, none taller than a man's knee, each cluster a
different kind: one a huddle of squat heavy mushrooms with thick stalks and
broad caps sagging and split at their rims, one a tall slender bunch whose
caps are stacked in several tiers up each stalk like narrow pagodas, and one
a low spread of small bulbous mushrooms with caps curling upward at the
edges into shallow cups, the stalks in muted damp earth tones, the caps in
rich saturated colour each cluster a different hue, deep coral red, vivid
amber orange and bright violet, their undersides dropping into deep shadow
of the same hue, each cluster cut off flat and straight along the bottom
edge, isolated on a plain flat solid white background
```

Invented forms are permitted here and the tiered variant is one — but the
weirdness stays in silhouette and structure. This is the element
that carries the set's chroma (10.3.9); watch it against a fielded team before the
set is locked.

##### 10.6.1.3 Midband example prompts

Three working examples from the approved midband set, one per finding they
demonstrate: the swallowed wall for the head-noun rule and mixed materials, the
trunk for midband color (10.3.10), and the trumpet bloom for whole-subject framing
(10.3.7). They are examples, not the full record. Each ends in the white-background
clause; generated with transparency, that clause is left off and nothing else
changes.

**Swallowed wall (3 variants)**

```
bold woodcut illustration with engraved structural linework and visible gouge
marks, thick black contour outline on the outer silhouette, flat color fields,
hard-edged shadows, no gradients, orthographic side elevation seen straight on
at eye level, no highlight edge anywhere, depth built from overlapping layers
of foliage at different values, the nearest leaves lightest and each layer
behind them a full value band darker receding into near-black, and from the
stone that shows through breaking into facets at different values with one
side falling away into near-black, the exposed stone carrying heavy engraved
detail through fracture lines, chipped edges and parallel hatching along its
shadow side while the growth stays flat and uncarved, hand-carved edge
quality, three separate dense masses of jungle growth standing far apart in a
row with empty background between them, each swallowing the remains of a stone
wall almost entirely, the growth piled thick over and across the stone and
spilling loosely down both sides and sagging at the outer edges, only a few
patches of bare masonry left visible anywhere on each, each mass a different
shape: a tall mass with one straight vertical corner of stone standing clear
of the foliage at the top and three exposed blocks below it, a broad low mound
with one long straight course of stone running horizontally out of the growth
at one side and two chipped blocks showing near the base, and a leaning mass
with a single hard square opening cut through the foliage where a window
survives and four blocks framing it, the straight stone edges cutting hard
across the ragged outline of the growth, the growth in desaturated dark
blue-green and the exposed stone in dull cool grey, each mass cut off flat and
straight along the bottom edge, isolated on a plain flat solid white
background
```

**Buttress-root colossus**

```
bold woodcut illustration with engraved structural linework and visible gouge
marks cut into the bark, thick black contour outline on the outer silhouette,
flat color fields, hard-edged shadows, no gradients, orthographic side
elevation seen straight on at eye level, no highlight edge anywhere, depth
built from the trunk and its buttress fins breaking into facets at different
values, the forward-facing faces lightest and the recesses between the fins
falling away into near-black, and from the growth clinging to it built as
overlapping layers at different values, the nearest leaves lightest and each
layer behind a full value band darker into near-black, the bark carrying heavy
engraved detail through deep vertical fissures, ridged ropes of bark, knots
and healed scars and parallel hatching along its shadow side while the growth
stays flat and uncarved, hand-carved edge quality, one single colossal jungle
tree trunk filling the frame, far thicker than a man, cut off cleanly along a
straight horizontal break at the top well above head height so the crown is
unseen, standing straight and rising from a spread of towering buttress roots
that flare out wide at the base and arch down to the ground, their fins
spreading evenly and readable on both sides, the root edges wandering rather
than running straight, the bark in muted warm brown, the trunk carrying a
whole hanging garden of life growing on it: broad clumps of dark blue-green
epiphytes wedged in the crooks where the fins meet the trunk, spiky rosettes
of teal-green bromeliads sitting in the bark hollows further up, long strands
of trailing growth hanging loosely down from them and swaying away from the
trunk, a few shelf fungi stepping out from the shadow side, and small vivid
blooms scattered among the growth in deep coral red and bright violet, their
undersides dropping into deep shadow of the same hue, the whole trunk cut off
flat and straight along the bottom edge, isolated on a plain flat solid white
background
```

**Trumpet bloom on a tall stalk**

```
bold woodcut illustration with engraved structural linework and visible gouge
marks, thick black contour outline on the outer silhouette, flat color fields,
hard-edged shadows, no gradients, orthographic side elevation seen straight on
at eye level, no highlight edge anywhere, depth built from overlapping layers
of petals and leaves at different values, the nearest lightest and each layer
behind a full value band darker receding into near-black, engraved detail
through the veins running down the petal throats and the ribs along the stalk
and leaves, hand-carved edge quality, one single enormous jungle flower shown
whole and complete with clear empty space on all sides, nothing cut off by the
edges of the image, taller than a man, a long thick stalk rising and bending
over under the weight of the bloom at its top, the bloom a deep trumpet
opening toward the viewer and slightly to one side, its mouth wide and its
petal edges curling back and splitting unevenly, the throat of the trumpet
dropping away into deep shadow of its own hue, a few heavy leaves sagging
outward low on the stalk, the petals in rich saturated deep coral red, the
stalk and leaves in desaturated dark blue-green, cut off flat and straight
along the bottom edge, the whole subject visible with headroom above and
margin to both sides, isolated on a plain flat solid white background
```


#### 10.6.2 Clockwork Spire

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates.
> No scene light assigned yet at all (10.2).

#### 10.6.3 Pirate Coves

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates.

#### 10.6.4 The Iron Ledger

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates.
> Resolve the white-plate problem in 10.6 before generating.

**Faction palette, stated so far.** Bone white & ivory parchment belong to the Iron Ledger; green does not. The Ledger is wealthy, and
its made things carry style and ornament as well as function — stained glass in
iron tracery, fluting, scalloped hems. Established on the Warlord (8.7.4); binds
Ledger characters, and is the starting point for the stages when they are written.

### 10.7 Adventure — the derived overview

Adventure is reached from each of the four hubs, and a run starts in one of that
area's two variants (10.6). Every variant therefore owes Adventure an element set,
and **eight sets are in scope.** The screen where the player chooses the variant is
a selection panel pair (10.8).

It is a third camera case rather than a third kind of environment. Like an
overview (10.4) it shows a region the player clicks through, but it is not a
finished plate: the map is **composed at runtime from many small elements**, which
makes it the only environment in the game whose layout is decided by code rather
than by hand — a battle stage scatters only its floor clutter (10.3.3). That
inverts the usual acceptance route: a single element can pass every check in
section 7 and the assembled map still fail.

#### 10.7.1 Element set requirements

> **Not yet written.** What runtime composition demands that a plate does not:
> which elements tile or repeat without a visible seam, how many variations of
> each are needed before repetition is legible, how density and placement are
> driven, and how the outline weight survives elements being placed at differing
> scales next to each other. The catalog is per variant and derives from that
> variant's band vocabulary (10.3.6) rather than being drawn fresh.

#### 10.7.2 Map furniture

> **Not yet written.** Node icons (12.3), path connectors, and node states are the
> layer that sits on top of the composed field. Needs the same states as 10.4.2 and
> should share their answer. State whether furniture is generated art or drawn in
> engine.

#### 10.7.3 Composition acceptance

> **Not yet written.** Several generated maps viewed at target size, judged for
> repetition, for whether the variant is still recognisable once elements are
> scattered rather than composed by hand, and for whether nodes stay findable
> against a dense field.

#### 10.7.4 Scene light for Adventure

A run keeps the scene light of the variant it starts in (10.2). Adventure has no
light of its own: an expedition reads as a journey through that variant, and the
eight element sets stay eight places.

---
### 10.8 Selection panels — the third environment class

Battle stages (10.3) are inhabited. Overworld views (10.4) are navigated.
**Selection panels are looked into and not entered** — they are the plate a player
chooses a place *from*, and their job is to make that place worth choosing.

The first pair is the Adventure biome selector (`Concept_Document.md` 5.1): two
panels, each covering half the screen, one per variant of the area the run starts
in. Eight panels are in scope, for the same reason eight Adventure element sets
are (10.7).

A panel is a **window at standing height**, framed as if the party has stopped on
the path and is looking in. That framing is the whole class — everything below
follows from it.

Exempt from section 4 entirely, from non-negotiable 2, and from the quantize step
(1.1). A panel may take its key light from a source inside the scene, so long as
the source is visible or its opening is, so the light reads as belonging to the
place. What still binds: hard-edged shadows, no gradients, committed dark mass,
structural detail over texture (5.5), and no figures or creatures.

#### 10.8.1 Composition

- **State the entry side.** The path or threshold enters from a named edge —
  right, left, or underfoot — rather than being centered. A centered path reads as
  a poster; an offset one reads as somewhere you are standing.
- **The way in ends before the frame does.** The path bends out of sight into
  darkness; the interior stops at the second column. This is the single most
  load-bearing rule in the section. A panel that shows you the whole place has
  nothing left to offer the player who picks it.
- **Crop the scale out of frame.** Nearest masses cut by both side edges, the
  canopy or facade leaving the top edge unseen. Grandeur comes from what does not
  fit.
- **Vertical relief.** Trail rising and falling, stairs, a ravine, a drop. A flat
  ground plane costs the panel most of its scale even when everything else is
  right.
- **Tall vertical composition**, roughly half of the target screen. The inner edge
  meets the other panel, so weight the composition toward the outer edge and leave
  a dark mass low in frame for the label.
- The two panels of a pair are judged **side by side at target size**, never
  individually. They must read as two different places and as one screen.

#### 10.8.2 Value bands at plate scale

Four bands is a character and icon rule. It exists so eight material fills read as
a flat woodcut at 300 px, and a panel has neither eight fills nor that size.

**Panels state six to eight bands.** Approved: six for Jungle, eight for Magic
Ruins. Below six the depth planes collapse into each other; above eight the model
starts shading within a hue and the woodcut read is gone.

#### 10.8.3 Depth

Five overlapping flat planes, each darker than the one in front, receding into
black — 5.6 at plate scale, including the furthest-plane phrasing.

#### 10.8.4 Saturation by role

The panel palette splits by what a thing is doing, not by material:

- **Mass is low saturation.** Trunks, canopy, masonry, roots — the bulk of the
  frame, held subdued so it can carry the value structure.
- **Incident is wide-range.** Blooms, water, fungus, flame, spilled light — a
  small share of the area, permitted full chroma.

This is the 3.5 lever restated for environments. It also keeps 10.1's no-accent
rule intact: the saturated incidents are scattered and multi-hued, so none of them
reads as a character accent.

Scene light (10.2) still sets the panel's cast, but at panel scale it is one hue
among a range rather than a flat field.

#### 10.8.5 Approved prompts

The two were built differently and the divergence is unresolved — see 10.8.6.

**Jungle (Reclaimed City)**

```
A bold woodcut illustration of a colossal jungle, hard-edged shadows, six color value
bands, a wide dirt path entering from the right side and winding away
between cathedral-scale trees that twist and turn with buttress roots arching over it, the path
bending out of sight into the darkness on the left side of the screen, the nearest trunks cropped by both frame edges, canopy
leaving the top of the frame unseen, massive fantasy blooms, the trail going up and down, fungi growing on roots, a distant mossy stone shape almost completely fading into the black of the deep jungle, no figures, no creatures. Each layer quickly growing darker, fading into the black of the jungle. A large ravine splitting along the path, water falling down into the deep abyss. Trees in a subdued low saturated green, while flowers and water hold a wide color range
```

**Magic Ruins (Reclaimed City)**

```
bold woodcut illustration of a vast ruined stone temple, hard-edged shadows, eight value
bands, an enormous carved doorway viewed from a side angle three stories tall filling
the center with warm amber candlelight spilling out as flat hard-edged
shapes, forty small candle flames as bone white dots receding between two
rows of broken columns, the facade cropped by the top of the frame so its
height is unseen, five overlapping depth planes, colossal jungle roots cracking the
masonry in eight heavy coils, twenty relief carvings cut as large simple
shapes, a toppled statue half-buried in ferns, aubergine-black, cold violet,
moss green, teal, amber and rust all held to four values, tall vertical
composition, no figures, no creatures
```

#### 10.8.6 Open items for this class

- **The two panels use different palette methods.** Ruins names six hues
  explicitly and closes with *all held to four values*; Jungle names no hues and
  instead states the saturation split of 10.8.4. Both worked. Before the next six
  panels, generate one variant each way for the same place and decide which is the
  house method, because eight panels built two ways will not read as a set.
- **Ruins asks for eight bands and then for four values in the same prompt.** The
  contradiction may be doing real work — the first clause buying interior
  modelling, the second holding the palette — or it may be inert. Test by removing
  the tail clause alone.
- **Counts are used heavily in Ruins** (forty flames, eight coils, twenty
  carvings) **and almost not at all in Jungle.** Decide which is the house method
  at panel scale.
- Scene light hexes in 10.2 were specified for flat sky fields and no panel uses
  them as such. Decide whether the table now means "the panel's dominant cast" or
  stays a battle-stage spec with panels reading from it loosely.
- Remaining six panels unbuilt. Clockwork Spire and Iron Ledger inner city have no
  scene light assigned at all (10.2), and the inner city's white-plate problem
  (10.6) hits a panel harder than a stage, since a panel is mostly dark mass by
  construction.

---

## 11. Items, gear and reagents

Gear is shown as an icon in an inventory cell, and that icon is the only item art
(12.7). The rules below were established on two Relics (11.6); standard gear has
not been generated yet.

### 11.1 Gear icons — shared conventions

**100 × 120 px, portrait, inventory cell only.** Judge every candidate at exactly
that size, in a mocked inventory row beside an existing item.

The class is the engraved icon of 12.6 at a larger size: engraved structural
linework over four values, detail tiered and counted. The extra room over a 40 px
passive is spent on more counted groups and on pierced openings, which read as
silhouette where lines alone blur.

- **Diagonal from lower right to upper left.** The object's working end points to
  the upper left; any handle or shaft runs out through the lower right. Light
  stays upper left (4.1), so the working end sits in the lit corner.
- **Crop to the distinguishing part.** A long weapon shows its head, and only the
  handle end leaves the frame, stated for that part alone with margin everywhere
  else (10.3.7). A small or compact object is shown whole.
- **A whole object comes back small.** Crop the output in from the right and
  bottom edges afterwards rather than asking for a filled frame (10.3.7).
- **Three levels of detail** as 12.6.2: a focal region with the heaviest
  engraving, moderate on the main masses, light on the handle or strap. Every group
  counted, a cut order recorded with the prompt.
- **Materials named per part** — blued iron, dull bronze, bark-brown wood,
  oxblood leather. No shared-slot system and no tinted band 1, as in 12.1.
- **One broad bone white edge** along the upper rim of the main mass (12.6.3).
- **No Role accent.** Gear is not owned by a Role, so no 8.9 hex appears on it.
- **Generate with the transparency setting** and no background clause (18).
- **Prompt describes the object only** — no mechanic, name or lore (5.7). The
  design notes carry why the object looks as it does.

### 11.2 Weapons, off-hands and boots

- **Weapons:** the head or blade, cropped (11.1).
- **Off-hands:** usually small enough to show whole, tilted on the 11.1 diagonal.
- **Boots:** not yet generated. Decide whether a pair or a single boot reads at
  100 × 120 before the first prompt (19.4).

Whether each slot needs its own silhouette convention, so a weapon reads as a
weapon before it reads as which one, is open until standard gear exists.

### 11.3 Reagents

> **Not yet written.** Reagents are consumed and appear in kit text, so they need
> to be identifiable at very small size and in quantity. Decide whether they are
> icons (12) or objects (11).

### 11.4 Currencies and consumables

> **Not yet written.** Each currency in `Concept_Document.md` 3.3.2 needs one
> unmistakable shape, held to the icon rules rather than the item rules.

### 11.5 Rarity and gear-set signalling

> **Not yet written.** How rarity reads visually without a colored frame doing all
> the work, and how a gear set stays recognisable across three equipment slots.
> This competes with the champion accent system for the player's color vocabulary
> — decide the priority.

### 11.6 Relics

A Relic (`Concept_Document.md` 3.3.1) must look like a find, not like a slightly
magical version of standard gear. Two things together do that; either alone reads
as common.

- **One element from outside reality** (8.1), derived from the Relic's effect and
  drawback, and visible in the still image.
- **An ornate made finish.** Sculpted fittings, pierced tracery, inlay in a second
  metal, an engraved border band. The made parts carry the richness, not only the
  strange one.

**One saturated material**, flat, on the strange element or the part that shows
it. Provisional: whether it reads as rarity, as a Role, or as neither is part of
11.5.

#### 11.6.1 Approved prompts

**The Long Furrow (Weapon).** Ploughshare head with no point for the no-crit
drawback; the floating second share is the Echo.

```
bold woodcut icon with engraved structural linework, very thick black contour outline on the outer silhouette, hard-edged shadows, four values, hand-carved edge quality with visible gouge marks, the head of an ornate heavy lance on a diagonal from the lower right toward the upper left, the wooden shaft running out through the lower right edge of the frame, the lance head set into a socket cast in bronze as the head of an ox, the blade held in its open jaws, two long curved horns sweeping back from the ox head along the shaft, in place of a point the lance ends in a broad curved ploughshare blade with a blunt rounded tip and a thick unsharpened edge, three large pierced openings cut through the blade in a row, a thin gilded inlay line following the edge of the blade, a second smaller ploughshare blade of the same shape floating well ahead of it along the same diagonal, attached to nothing, pierced with the same three openings, a wide empty gap between the two blades, three levels of detail: the ox head carries the heaviest engraved detail and reads as the focal point, through its brow ridges, flared nostrils and a ring through its nose; the blades carry moderate engraved detail through the pierced openings, one chipped notch in the rim of the larger blade and parallel hatching lines across their shadow sides; the shaft carries light detail through four bands of cord binding, all marks bold and structural, the larger blade in dark blued iron falling into ink black shadow on its lower left, the ox head and horns in warm dull bronze, the shaft in bark-brown wood, the floating blade in flat saturated deep ultramarine, one broad bone white edge along the upper rim of the larger blade, light from the upper left, the whole head visible with margin on all sides except where the shaft leaves the frame
```

**Cut order:** hatching, cord bands, nose ring. The openings, horns and gap are
never cut.

**The Closed Wound (Off-Hand).** A metal shield with a wound stapled shut, for
healing denied to the team.

```
bold woodcut icon with engraved structural linework, very thick black contour outline on the outer silhouette, hard-edged shadows, four values, hand-carved edge quality with visible gouge marks, a small round buckler shield shown whole, facing the viewer and tilted on a diagonal with its top leaning toward the upper left, a long jagged gash torn across the face of the shield from the lower right toward the upper left, the gash clamped shut by six heavy iron staples driven across it at uneven intervals, the edges of the gash buckled and pulled tight against the staples, a thin flat line of saturated deep vermilion showing through the closed seam between the staples, a raised domed boss at the center of the shield cast as a clenched fist, three levels of detail: the gash and its staples carry the heaviest engraved detail and read as the focal point, through the torn metal lips of the gash, the staple heads and the puckered metal around each one; the boss and the rim carry moderate engraved detail through the knuckles of the fist, a border band of ten repeated triangular motifs running around the rim and parallel hatching lines across the shadow side of the shield; the back edge of the shield visible at the lower right carries light detail through a single leather strap, all marks bold and structural, the shield face in dark blued iron falling into ink black shadow on its lower right, the boss and the rim band in warm dull bronze, the strap in oxblood leather, one broad bone white edge along the upper left rim of the shield, light from the upper left, the whole shield visible with margin on all sides
```

Cropped in from the right and bottom after generation (11.1). **Cut order:**
hatching, then rim motifs to six. The staples and the seam are never cut.

---

## 12. Icons

Icons are where the style either works or fails, because they are the smallest
thing on screen.

### 12.1 Rules

Governs map nodes, status, currency and resource icons. Active skill art (12.4),
passive icons (12.6) and gear icons (11.1) are separate classes and do not follow
these.

- **Target size first.** Decide the pixel size (map nodes ~48–64 px, skill icons
  ~64–96 px) and judge every candidate at exactly that size, never at full
  resolution.
- **Drop to three values.**
- **Drop the material slot system.** At icon scale there is no room for eight
  fills. Icons use ink black, bone white, one mid neutral and the accent. The
  tinted band 1 of 2.2 does not apply.
- **One idea per icon.** A single object, centered, filling the frame.
- **Silhouette must survive being filled black.**
- **Outline gets proportionally thicker**, not thinner, as size drops.
- **Node type icons carry no accent** — they are map furniture.

### 12.2 Prompt pattern

```
bold woodcut icon, very thick uniform black contour outline, flat color
fields, three values, hard-edged shadows, a single {SUBJECT} centered and
filling the frame, large simple shapes, minimal interior detail, readable at
very small size, rendered in ink black, bone white and one mid
grey[, with {ACCENT} as the single flat accent on {PLACEMENT}], isolated on a
plain flat background of one uniform color.
```

### 12.3 Node icon subjects (Adventure map)

Keep these to one unmistakable object each: Fight — crossed blades; Boss — a
skull; Rest Stop — a tent; Hint — a closed gate; Gamble — a bag of coins and some
dice; Escalate — a bloodied parchment contract.

### 12.4 Active skill art — the chiaroscuro print class

The largest art set in the game, one or more per skill across twenty Roles. Skill
art is **not** built in the Lit Woodcut character style. It is built as a
**chiaroscuro woodcut** — the sixteenth-century technique (Burgkmair, Ugo da
Carpi) of printing one detailed black line block over two or three flat tone
blocks.

The class exists because the flat icon rules remove the carving, and **a woodcut
with the cutting taken out is a vector cartoon.** A real woodcut gets its richness
from the density and direction of cut marks, not from color or shading.
Chiaroscuro is also the closest print tradition to this guide's own foundations:
its tone blocks *are* a small number of flat value bands, and its key block
restores the engraved structural linework that 8.6 asks for and 12.1 drops.

Exempt from non-negotiables 1, 2, 3 and 6, from 12.1–12.2 entirely, and from the
quantize step (1.1). Light may come from a source named in the scene — moonlight
glinting on the blade, morning light behind a wave — as long as the source reads
as belonging to it. Carved hatching and visible wood grain are the content of this
class, so 5.5's ban on texture applies only to *asked-for grime*: dirt and stain
words remain wasted budget.

What still binds: no gradients in the tone blocks, one idea per piece, section 5's
prompting method, and the caster's accent (12.4.4).

#### 12.4.1 The technique block

Word for word in every skill prompt, closing it. The repetition is what makes
different subjects read as one set.

```
a detailed black key block with engraved hatching and contour lines
printed over two overlapping tone blocks of clearly different colors,
a light tone block in {LIGHT TONE} carrying the lit masses and a dark
tone block in {DARK TONE} carrying the shadows and background,
{HIGHLIGHTS} cut away to bare cream paper, slight registration offset
between blocks, visible wood grain in the tone blocks
```

And one phrase opening it: `chiaroscuro woodcut print,`

**Name each tone's job.** Given only `two tone blocks in X and Y`, Leonardo
merges two related colors into one, and the print comes back as a single color at
four values. Assigning one tone to the lit masses and the other to the shadows,
and stating that they differ, is what keeps both. Which slot the accent takes is
set per Role in 12.4.4.

The three approved prompts in 12.4.6 predate this wording and are recorded as
generated (18).

#### 12.4.2 Subject conventions

The subject block sits between the two.

- **Any subject that carries the skill, caught in the act.** The subject is
  whatever makes the mechanic readable, and the Role's tool is only one option:
  - **The tool** — a weapon mid-thrust, a thrown object mid-flight.
  - **The caster, whole or in part** — the body doing the skill, a stance, a
    lunge, a figure braced under a weight.
  - **The target or the consequence** — what the skill does to someone or
    something, with the caster absent or at the edge.
  - **A concept or thematic image** — the skill's idea made into a carved
    subject: a dolphin of seawater carrying swords, a heap, a scale tipping.
  Choose per skill, not per Role. What is ruled out is a UI glyph — a flat
  symbol with no carving, no action and nothing to look at.
- **Motion on a diagonal or arc**, toward the right where there is a direction,
  matching the battle layout. Speed is shown as *curved gouge strokes trailing the
  arc*, never blur.
- **Partial figures are allowed.** A hand and a striped sleeve gripping the
  cutlass, the rest beyond the frame. The Role is signalled by a costume detail at
  the frame edge, not by a face.
- **Highlights are cut to paper.** Name what glows or gleams — flames, a blade
  edge, foam and spray — and cut it away to bare cream paper.
- **Background is optional and sparse.** When present, it is carried by sparse cut
  lines and held in the darker tone so the subject stands forward.
- **Count the elements that create density.** Where a sword count or a shard count
  drives line clutter, state it and record a cut order.
- **Name every light shape separately, and say where it starts.** This class
  carries more light shapes than any other, and they are the first thing a summary
  clause inflates (5.4).
- **One object, one state** (5.8). A thrown thing is shown either in flight or
  arrived, never both. The trailing gouge strokes carry where it came from.
- **Transparency is replaced by breaking through.** Carved lines of a see-through
  form compete with the carved lines of what is inside it. Put objects *in* the
  form with their ends breaking out through its surface.

#### 12.4.3 A failure needs a cause in frame

A skill that negates something — a blocked shot, a broken bolt — has no readable
image if the thing simply breaks against empty air. Give the failure something to
happen against.

Build a barrier as smoke, not as a force field: a clean dome or disc reads as
science fiction. A solid mass with a hard torn edge and carved curls inside it,
irregular and offset from center, is the form that works (14.1). *Vapor* holds;
*solid smoke* or *carved cloud mass* is the fallback phrasing if a variant comes
back soft.

#### 12.4.4 Accent in the tone blocks

**One tone block carries the caster's accent family.** It stays a tone block —
flat, sharing the print with the second tone — not a spot color. This is how 8.9's
identity system reaches skill art.

**The second tone is the Role's partner tone**, fixed per Role in the table
below. A single-color print has too little contrast to read at small sizes: the
subject, the background and the lit masses merge into one shape. The partner has
to differ from the accent on two axes:

- **Value: the opposite end.** A light accent gets a dark partner, and a dark
  accent gets a light one. A mid accent can go either way, and the table fixes
  which. The print then has four distinct steps: black key, dark tone, light
  tone, paper.
- **Hue: roughly opposite temperature.** At minimum, the two are never neighbors
  on the wheel. Two shades of one hue family fail even when their values are far
  apart. Warm ochre and deep rust is the case on record (12.4.6).

**All partners come from one muted print palette** of earthen, stone and ink
tones, like those used in historical chiaroscuro prints. The accent stays the only
saturated color in the print. That keeps skill art identifiable by its accent,
stops a partner from reading as another Role's accent, and makes the whole set look
like it came from one print shop.

**The garment main is no longer the default second tone.** Several garment mains
sit next to their own accent's hue. On the figure, 3.5 separates them by value
band, but a two-block print has no room for that separation. Use the garment main
only where it passes both axes, as the Plague Doctor's does.

| Role | Accent (value) | Accent block | Partner tone | Starting hex | Rationale |
|---|---|---|---|---|---|
| Thief | rust orange (mid) | light | dark slate blue-grey | #3A4652 | complement; night work |
| Bloodmage | crimson (dark) | dark | pale cold blue-grey | #B8C4CC | blood against the bloodless |
| Bar Brawler | terracotta (mid) | light | deep bottle green | #22382C | tavern glass; red/green complement |
| Lancer | flame copper (light) | light | deep blue-violet charcoal | #2E2F48 | heraldic dark field under the pennant |
| Jester | saffron (light) | light | deep muted plum | #3A2A3E | classic motley complement |
| Architect | muted brass (mid-light) | light | dark verdigris | #2D4A44 | brass and its own oxidation |
| Appraiser | antique gold (dark) | dark | pale dove indigo | #A9B0C8 | taken from his mantle |
| Scholar | ledger parchment (lightest) | light | deep oxide teal | #2F4A4A | see the warning below |
| Alchemist | acid chartreuse (light) | light | deep oxblood | #4E1F24 | yellow-green against red |
| Symbiote | verdant green (mid) | dark | pale dusty flesh rose | #D2A89C | host flesh under the fungus |
| Plague Doctor | deep moss (dark) | dark | pale mustard sand | #D8B866 | lightened garment main family |
| Tidal Corsair | sea teal (mid) | dark | pale sand ochre | #D9C28E | approved in 12.4.6 |
| Chronophage | ice cyan (light) | light | deep burnt umber | #4A2A1C | warm against frozen |
| Sorcerer | unstable cobalt (mid) | dark | pale apricot | #E0B48A | blue/orange complement |
| Emissary | ink indigo (dark) | dark | pale seal-wax vermilion | #D99A84 | ink and wax |
| Diviner | pale lilac (light) | light | deep burnt sienna | #6B3520 | approved in 12.4.6 |
| Cultist | deep amethyst (dark) | dark | pale ash sage | #BFC4A0 | purple against yellow-green |
| Herald of the Loom | violet magenta (mid) | dark | pale straw thread | #DDCC96 | the loom's thread |
| Tactician | rose magenta (mid) | light | deep campaign olive | #3D4428 | field map under the marker rods |
| Warlord | deep brick red (dark) | dark | steel blue-grey | #7E3222 | taken from his doublet |

The hexes are starting points to measure against, not lock values. The prompt
names the color in words; the hex is what the output is judged against.

- **Scholar.** Parchment `#DCCFA8` is almost the cream paper, so the accent block
  disappears into the highlights and the print comes back as a single color
  whatever the partner is. Settle 8.9.1 for this Role before building its set.
- **Thief and Lancer** both get dark blue-greys, because blue is the complement of
  every orange accent. The accent separates them, but check any composite that
  puts the two side by side.

**Choose the accent before the first prompt of a set, not after the first piece.**

**Vary the accent's coverage across a set, never its hue.** Most in the piece
where the accent-colored mass *is* the subject; least where it is held to a few
lit faces and their trailing strokes. Across a set that reads as range. Three
plates at the same saturation read as one plate printed three times.

#### 12.4.5 Building a Role's whole set

A set has a failure mode a single piece cannot show: **four assets built on one prop are one
image four times.**

**Decide the split before the first prompt.** What the set shares and what varies
decides whether the opening piece is even allowed to show the whole prop.

- **Not every skill gets the same prop.** A skill that resolves on someone else is not
  the caster's moment. The caster's presence there is the tone block alone
  (12.4.4), which is enough.
- **Reserve something for the passive.** 12.6.2 dissuades the passive repeating its
  Role's active art for the same mechanic. Two actives on a prop and one off it
  leaves the passive free.
- **Judge a new piece against its own set first, then against 12.4.6.**
  Within-set sameness is the risk the reference set cannot catch.

Where a Role's kit has no single signature element, the vocabulary can be the
*motion* instead — an arc into the right of the frame, a water-and-steel pairing.

#### 12.4.6 Approved prompts

Three pieces across three Roles, spanning the three background treatments: none,
a sparse cut-line field, and a full scene. A new piece is judged side by side
against all three.

**Burning Bolas (Jester)**

```
chiaroscuro woodcut print, burning bolas thrown through the air in a spinning arc toward the right, two heavy iron balls joined by a thick twisted rope, each ball wreathed in curling flames, a detailed black key block with engraved hatching and contour lines printed over two overlapping tone blocks in warm ochre and deep rust, highlights cut away to bare cream paper, flames glowing where the paper shows through, curved gouge strokes trailing the arc, slight registration offset between blocks, visible wood grain in the tone blocks
```

The reference for a subject carried with no background at all, and for flames as
the paper showing through. Its warm ochre and deep rust are both in the Jester's
saffron family. The piece predates the partner-tone rule (12.4.4), and those two
tones are the single-hue pairing that rule replaces. Keep it as the reference for
subject and background treatment only. On regeneration, it becomes saffron and
deep muted plum.

**Corsair's Reckoning (Tidal Corsair)**

```
chiaroscuro woodcut print, a dolphin formed entirely of seawater leaping out of a breaking wave toward the viewer, its body built from curling carved current lines and swirling eddies, five cutlasses and sabres caught inside the water at different angles, their hilts and blade tips breaking out through its back and flanks, a great wave curling behind it with claw-like foam crests, a detailed black key block with engraved hatching and contour lines printed over two overlapping tone blocks in sea teal and pale sand ochre, foam, spray and the sword edges cut away to bare cream paper, a strip of beach and distant sea below in sparse horizontal cut lines, morning light from behind the wave, flying droplets as small gouged marks, slight registration offset between blocks, visible wood grain in the tone blocks
```

The reference for a subject that *is* the Role's concept rather than its tool, for
objects breaking out through a form instead of showing through it, and for a
carried scene. Counted groups: five swords. **Cut order:** the swords to three if
a variant tangles.

**Fateful Glimpse (Diviner)** — damage plus a heal on the most injured ally

```
chiaroscuro woodcut print, one large jagged raw crystal shard hovering alone at the center of the frame, tilted on a diagonal, rough and unpolished with five broken angular faces like ore fresh from a mine, one narrow hard-edged shaft of light entering from the upper left and striking its upper face, two shafts of light leaving the shard toward the lower right coming from the same point from the crystal shard, the first a narrow beam tapering to a sharp point, the second a wide fan of four broad bands spreading open beneath it, both the beam coming from the top left and the two exiting on the other side cut away to bare cream paper as hard-edged straight shapes, six short gouged marks bursting at the point where the entering light strikes the shard, the background a sparse field of straight cut lines radiating outward from the shard and held in the darker tone so the shard and the light stand forward, a detailed black key block with engraved hatching and contour lines printed over two overlapping tone blocks in pale lilac and deep burnt sienna, highlights cut away to bare cream paper, slight registration offset between blocks, visible wood grain in the tone blocks
```

Two outputs from one skill, in one object: a single shard used as a prism, with
the cut beam and the mending fan leaving the same point. They separate by **shape,
not softness** — narrow and tapering against a wide fan of broad bands — because
this class has no blur or gradient to separate them with.

Counted groups: five faces, four bands in the fan, six gouged marks. **Cut
order:** background radiating lines first, then the fan to three bands, then the
gouged marks to four. The five faces and the two-beam split are never cut.

#### 12.4.7 Open items for this class

- **Display size is unverified.** The pilot was judged at full resolution. Skill
  art shows in the skill bar and tooltips; decide the sizes, then check whether the
  chiaroscuro structure survives where the hatching does not. If it fails at the
  skill-bar size, the likely answer is two assets per skill — this illustration for
  tooltips and cards, and a cropped or simplified icon for the bar — rather than a
  return to 12.1.
- **Background convention.** Pieces with no scene now outnumber those with one.
  Decide whether the sparse cut-line field is the default and a scene is the thing
  that has to be earned.
- **Accent rule on a clashing element.** Nothing has yet forced a conflict: Jester
  fire sits near saffron, Corsair sea is teal. Test a skill whose element fights
  its Role's accent — a Sorcerer fire skill under cobalt — to settle whether
  element color or caster accent wins the accent block. The partner tone may make
  the conflict smaller: it is chosen near the accent's complement, and the
  Sorcerer's pale apricot can already carry fire.
- **Partner tones are unproven.** Only the Corsair and Diviner pairings have been
  generated. Generate one piece per new pairing and judge it at display size
  before locking its hex. Where a pairing still returns a single color, fix the
  wording of the technique block before changing the hue.
- **Status icon collision.** Burning (12.5) will want flames too. The status icon
  must not look like a crop of the Bolas art.
- **Relationship to VFX (14).** The in-battle effect for a skill is in the Lit
  Woodcut battle style; the skill art is not. Decide whether that split is
  accepted, or whether VFX borrow anything from the print (gouge-stroke motion,
  paper-cut highlights).

### 12.5 Status effect icons

> **Not yet written.** Eight simultaneous slots (`Concept_Document.md` 1.1.4), so
> these are read in a row at the smallest size in the game. Needs a buff/debuff
> distinction that is not color alone, a stack-count treatment, and a shared shape
> language across the status list in 3.2.3.

### 12.6 Passive icons — the engraved icon class

Every Role has one passive, shown as a small round icon: **40 × 40 px, masked to a
circle**. That is smaller than any skill art and close to status icon size, so
this class sits between the two others in this chapter. It keeps the icon rules'
scale discipline — one idea, thick outline, high contrast — and takes back the
engraved line that 12.1 removes.

The flat icon rules return an idea that reads but does not belong to the game, at
40 px exactly as at skill-art size. Chiaroscuro is not the answer either: at 40 px
a hatching line in a key block lands below one pixel, and two tone blocks with a
registration offset turn into a smear.

What works is the character block's own vocabulary (8.6) cut down to one object:
**engraved structural linework over four values, with the detail tiered and
counted.** At 40 px many individual lines will not resolve on their own; together
they read as worn-metal grit over the key shapes, which is what makes the icon
read as part of the set instead of as a vector glyph.

#### 12.6.1 Subject convention: the mechanic already working

- **Show the state, not the strike.** Active skill art catches the tool *in the
  act* (12.4.2). A passive is always on, so its icon shows the effect **already in
  progress** — the blade already wedged in and twisting, not the thrust that put it
  there.
- **Keep clear of the Role's active skill for the same mechanic.** The two should
  read as setup and follow-through, never as the same image twice.
- **Three large shapes carry the idea.** Hands, cuffs and costume details at the
  frame edge — the way skill art signals the Role — do not survive 40 px and are
  left out. The accent does the Role signalling instead (12.6.3).
- **The key shape is the highest-contrast shape.** Give the idea one solid ink
  black mass against a light one. State it as wide — a thin gap vanishes at size.
- **Motion on a diagonal toward the upper right**, entering from the lower left,
  as elsewhere in the game.

#### 12.6.2 Detail — tiered and counted

The three-level spec from 8.6.1, applied to one object:

1. **Focal point, heaviest detail.** Where the mechanic happens.
2. **Main masses, moderate detail.** Dents, notches, rivets, parallel hatching
   across the shadow sides.
3. **The tool, light detail.** One groove.

**Grit is structural wear, not grime.** Dents, notches, scratched grooves, gouge
marks and bent edges are shapes and survive the pipeline; dirt, stains and rust
spots are texture words and do not (5.5). Where a wear mark can show the mechanic
— grooves at a seam are the prying made visible — it belongs in the focal tier.

**Every group is a count** (5.4), and **every prompt records its cut order.** If a
variant turns to mush at 40 px, cut the moderate-tier groups first, starting with
the hatching, and keep the focal-tier marks until last.

#### 12.6.3 Values and color

- **Four values, not three.** Ink black, one mid neutral with its shadow side,
  bone white on one broad edge.
- **One broad bone white edge**, on the rim of the focal mass along the upper
  left. It separates the key shape from its neighbour at size.
- **The accent goes on the Role's tool** and follows its placement in 8.9. One
  accent, flat and uniform. Unlike node icons (12.1), passives carry the accent: a
  passive is Role identity, not map furniture.
- **No material slots and no tinted band 1**, as in 12.1.

#### 12.6.4 Frame and generation

**The circle is applied in the engine, not baked into the art.** Generate square at
1:1 on a plain flat background of one uniform color, with the subject compact and
centered and the four corners empty. The mask and any rim or frame are UI (13.1).
Post-processing per section 6.

#### 12.6.5 Approved prompt

New passive icons are judged side by side against this at 40 px.

**Between the Plates (Thief)**

```
bold woodcut icon with engraved structural linework, very thick black contour outline on the outer silhouette, hard-edged shadows, four values, hand-carved edge quality with visible gouge marks, a close-up of two overlapping curved steel armor plates, battered from long use, with a single narrow stiletto blade wedged into the seam between them and twisted, the blade entering from the lower left, the upper plate levered up and away on a diagonal toward the upper right, one wide solid ink black gap opening beneath the lifted plate, three levels of detail: the seam where the blade bites carries the heaviest engraved detail and reads as the focal point, with the metal edge bent and curling up around the blade tip and three short scratched grooves cut where the blade has worked the seam; the plates carry moderate engraved detail through three hammered dents, one chipped notch in the rim, two rivets on each plate and parallel hatching lines across their shadow sides; the blade carries light detail through a single groove running down its length, all marks bold and structural, the whole subject compact and centered inside a circle with open space in all four corners, light from the upper left, the plates in dull pewter grey falling into ink black shadow on their lower right, one broad bone white edge along the rim of the lifted plate, with saturated rust orange as the single flat accent on the stiletto blade, isolated on a plain flat background of one uniform color
```

Counted groups: three grooves and the curled edge at the seam, three dents, one
notch, four rivets and the hatching across the plates, one groove on the blade.
**Cut order:** hatching, then dents, then rivets.

Fixes for when a variant fails:

- **The gap does not read.** Widen it explicitly — *a wide dark gap, as wide as
  the blade is long*.
- **The plates read as a shell or a book.** Rivets are the cheapest cue that says
  armor; add or keep them.
- **The blade reads as a cartoon knife.** *Stiletto* or *thin spike blade* instead
  of *dagger* pushes it toward precision.

#### 12.6.6 Open items for this class

- **Post-processing pass unverified.** The quantize and accent-correction steps
  have not been run on a passive icon. Check that quantizing does not flatten the
  engraved grit that is the point of this class; if it does, passives take the
  overlay only, as skill art does.
- **Frame and rim.** Whether the UI circle carries a rim, and whether that rim is
  ink black at contour weight or tinted to the Role's accent. Belongs to 13.1 once
  written.
- **Grafting and thread-stance buttons.** The Symbiote's graft and the Herald's
  thread switch are persistent UI affordances rather than descriptions of a
  mechanic, and may belong with 13.1. Decide whether they take this class, get
  their own, or move.
- **Confirmed on one Role.** Watch the next two passives, especially one whose
  mechanic has no natural object (Plague Doctor's Comorbidity, Emissary's Standing
  Record), before treating the subject convention as settled.

### 12.7 Item and reagent icons

Gear: the icon is the item art, one asset, specified in 11.1. Reagents: not yet
written (11.3).

### 12.8 Currency and resource icons

> **Not yet written.** Energy, currencies, experience. Read constantly in HUD
> chrome, so they must survive at the smallest size of all and must not compete
> with status icons for attention.

---
## 13. UI art

> **Not yet written.** The style has strong opinions (thick outline, four values,
> no gradients) that a default engine UI will contradict on the first screen.

### 13.1 Frames, panels and buttons

> **Not yet written.** Outline weight at UI scale, corner treatment, panel fill
> values, button states (idle, pressed, disabled), and whether UI chrome sits
> inside the four-band ramp or is exempt.

### 13.2 Typography

> **Not yet written.** Typeface choice for headers and body, and whether numbers
> in combat get their own treatment. A woodcut style is unusually sensitive to
> this — a neutral UI sans will read as a different game.

### 13.3 Combat HUD

> **Not yet written.** Health and resource bars, turn order, damage numbers, and
> the Echo sequence presentation required by `Concept_Document.md` 1.1.5. Damage
> numbers carry the caster's accent (8.9), so they are style assets, not engine
> defaults.

#### 13.3.1 Turn bar zones — the receding class

Zones (`Concept_Document.md` 3.2.4.1) sit in sections of the turn bar, and
character markers move through them. The zone has to say *what* occupies a section
and *whose* it is, while the markers stay the first thing the player reads. Every
rule in this class follows from that ranking: **characters lead, zones recede.**

Exempt from non-negotiables 1, 2 and 3, from section 4's light direction, and from
14.1's outline and key background (1.1). What still binds: **orthographic pure
side profile** (4.1), one idea per sprite, flat fields, and section 5's prompting
method.

##### What is an asset and what is the engine

A zone is assembled in Godot from a small number of generated sprites. Only the
sprites are art assets.

| Layer (back to front) | Made in | Gilded Deck example |
|---|---|---|
| Tint field | Engine — `ColorRect` or shader, alpha set in engine | Pale blue field over the whole section |
| Particles | Asset sprites, driven by a particle node | Wave crests drifting within the section |
| Centerpiece | Asset sprite, animated by tween | Pirate ship rocking back and forth |
| Character markers | Existing HUD | Always in front of every zone layer |

Transparency is always applied in the engine, never baked into the asset. The
asset is delivered opaque on a key color and keyed out.

##### Dimensions

- **Turn bar section:** 248 × 80 px. Height is the binding limit.
- **Centerpiece:** around 100 × 60 px. Leave vertical headroom for motion — a 6–8°
  rock adds several pixels of height, and a centerpiece that fits 80 px when level
  will clip when tilted. Generate in a landscape aspect (3:2) so the subject comes
  out wide and low.
- **Particles:** 20–32 px each.
- At these sizes a carved line lands at about one pixel. Keep interior line counts
  to three or four on the centerpiece and one or two per particle.

##### Substitute rules

- **Outlines are drawn in a darker shade of each fill color.** This keeps the
  woodcut contour while removing the heaviest attention-grabbing mark in the style.
- **Fills are soft, muted and low in contrast.** Flat fields and no gradients still
  hold.
- **The Role's accent family may be the main body color**, because the whole zone
  is already at low opacity.
- **Keep any shading flat and minimal.** The objects are too small for a cast
  shadow to matter.

##### Color

- **The palette ties to the placing Role.** The Gilded Deck's hull is sea teal,
  the Corsair's accent family. This keeps zones inside the existing color-identity
  system rather than starting a separate one.
- **One named detail carries the zone's identity.** For the Gilded Deck it is the
  gold gilded trim on the rail and stern, and nothing else competes with it.
- **Particles take a simple two-color scheme** that fits the element: soft sea
  blue bodies with a white foam lip.
- **The tint field is an engine value.** Its color and alpha are tuned live in
  Godot.

##### Generation

- **Key color: flat magenta.** It appears in neither the Gilded Deck's teal, gold
  and off-white nor its blue and white waves. If magenta fringes into light edges
  (foam, sails), switch to plain bright green. Use a transparent-background output
  instead if the model offers one.
- **Particles as a sheet.** Ask for five separate shapes spaced apart in a row.
  The sheet slices cleanly and gives the particle system variety.
- **Centerpiece with a clean pivot edge.** Anything that rocks or bobs needs a
  flat, straight edge at its pivot — the Gilded Deck's hull is cut straight along
  the waterline. Set the rotation pivot at the waterline in the engine, not at the
  sprite's center.
- **Post-processing** per section 6.

##### Approved prompts

The Gilded Deck (Tidal Corsair, placed by Corsair's Reckoning), implemented in the
engine and approved.

**Ship (centerpiece)**

```
woodcut print style illustration of a small pirate ship in pure side profile facing right, a wide low hull with two masts and three square sails in weathered off-white canvas, hull of deep sea teal painted wood with one band of gold gilded trim along the rail and a gilded ornament on the stern, one small teal flag on the main mast, the hull cut straight and flat along the waterline at the bottom, flat color fields with three or four carved lines for planks and sail folds, soft muted colors, gentle low contrast, outlines drawn in darker shades of each color, large simple shapes readable at very small size, the whole ship centered, isolated on a plain flat solid magenta background
```

**Waves (particle sheet)**

```
woodcut print style illustration, a sheet of five small separate curling wave crests spaced apart in a row, each a different shape, bodies in soft sea blue with a white foam lip along each curl, one or two carved lines following each curl, flat color fields, outlines drawn in a darker shade of blue, soft muted colors, large simple shapes readable at very small size, isolated on a plain flat solid magenta background
```

##### Open items for this class

- **Lore family language.** Every zone belongs to the order, unstable or momentum
  family, and that family defines its visual language (`Concept_Document.md`
  3.2.4.1). The Gilded Deck's family has not been recorded here, and neither has
  which of its choices are family language (field treatment, how particles move)
  and which belong to this zone alone (the ship). Decide before the second zone of
  that family, or the first zone becomes the family by accident.
- **What the tint means.** Either the tint derives from the placing Role's accent
  — keeping one color-identity system — or it signals ally versus enemy ownership,
  which is a second system.
- **Enemy-placed zones.** Decide whether ownership is shown at all, and if so
  whether by tint, a marker, or nothing.
- **Charge readout.** Whether remaining charges show as a number, as particle
  density, or both.
- **Arrival and dissipation.** How a zone appears when placed and leaves when its
  last charge is consumed. Engine animation, but one convention across all zones.

### 13.4 Layout and screen inventory

> **Not yet written.** One entry per screen, each with its grey-box (4.3) before
> any art is generated.

---

## 14. Effects and VFX

### 14.1 Rules

Effects are the one place the accent may exceed its budget, because they are
transient. Everything else holds.

- **Same thick black outline**, even on magic. An unlined glow does not belong to
  this game.
- **Shape over glow.** Radiating lines, chunky sparks, solid smoke masses, cracked
  rings. Not soft bloom.
- **Effects inherit the caster's accent color.** This is the single strongest
  reinforcement of the identity color system.
- Generate on **plain black or plain white**, keyed out afterward, never on a
  scene.
- **Turn bar zone particles are not VFX** for these rules. They follow 13.3.1.

### 14.2 Where the juice actually comes from

Most perceived impact is code, not art, and costs far less than more VFX assets:

- Whole-sprite squash and stretch via Tween on `scale`, plus `skew`
- Hit-flash shader, white or the accent color, two frames
- Hitstop of 60–100 ms, screen shake
- Idle bob of 2–3 px plus 1–2% scale on a long sine

Build this layer before commissioning more effect art.

### 14.3 Status effect visual language

> **Not yet written.** A status is on a target for several rounds and must be
> visible on the sprite, not only in the status bar. Needs a persistent-effect
> vocabulary distinct from the transient hit effects above.

### 14.4 Impact and cascade library

> **Not yet written.** The burst resolves as a visible sequence of Echoes
> (`Concept_Document.md` 1.1.5): escalating tempo and magnitude across many
> resolutions. Needs a shared impact set and a rule for how an Echo differs
> visually from the action that spawned it.

---

## 15. Animation

Cutout skeletal animation suits this style — flat fields and hard outlines survive
being chopped apart.

- **Give every cut piece its own closed black outline.** Half-committing, where
  some edges are lined and some are raw, is the failure mode.
- **Cut with generous overlap**, not at the joint. Round the end of each limb
  piece so rotation sweeps inside the shape.
- **Three-quarter view costs extra work**: the far arm and leg are occluded and
  must be redrawn, plus whatever sits behind each piece.
- **Sprite2D on Bone2D** for rigid limbs. Polygon2D skinned to Skeleton2D only for
  genuinely soft things (tendrils, coat hems).
- **Keep the eyes on their own layer.** They are hand-placed and they are the
  first thing that breaks when a head piece rotates.

**Do the cheap layer first** (14.2). At 300 px on a phone, whole-sprite
squash/stretch plus hit-flash plus hitstop delivers most of the perceived quality.

**Middle option:** generate 3–4 pose variants per character and hard-cut between
them, no tweening. Limited animation is period-correct, hides a multitude of sins,
and plays better with generated art than rigging does.

---

## 16. Marketing and out-of-game art

> **Not yet written.** Store capsules, screenshots, wordmark and key art are
> consumed by players and fall under the same disclosure obligation as in-game art
> (18). They also break the composition tail in 4.2 — a capsule is a composition,
> not an isolated figure — so they need their own rules rather than an exception
> granted case by case.

### 16.1 Logo and wordmark

> **Not yet written.** Studio name is settled; the wordmark treatment is not.

### 16.2 Store capsules and screenshots

> **Not yet written.** Sizes, which champions appear, and whether capsule art is
> generated or composited from approved assets.

---

# Part III — Record and process

---

## 17. Do not retry

Directions that were generated and judged, or ruled out on a stated ground. Each
line is a trap, not a history; the rule it produced lives in the section named.

**Faces and proportion**

- Enlarged head plus enlarged eyes. Moving both dials at once is the cartoon
  recipe (8.4.1).
- Bone white eyes glowing out of a shadowed upper face. A horror device (8.4.1).
- A face-structure cluster with no stated age. Returns the model's default
  forty-year-old handsome man (8.4.2).
- Skin as a fully flat field, or skin left unconstrained. Both endpoints were
  reached by adjective; the answer is a count and a mark weight (8.4.1).

**Character concepts**

- A pale nobleman in a high-collared coat. Lands on Dracula, cape and fangs
  included (5.3).
- A frail wilderness outcast. Reads as an NPC; low status is what "shunned" looks
  like (8.1).
- Torn strips, bare chest and a notched blade. Reads as a barbarian (5.3).
- A plain working coat and flat cap. Removes all fantasy content (8.1).
- A soft floppy cap, wide grin and a wiry build. Cartoon; `wiry` shrinks the body
  and makes the head read as oversized (5.2).
- A field surveyor in a travel coat, gaiters and pack roll. Fleeing the wizard
  basin with travel vocabulary lands in the outdoorsman basin (5.3).
- Historically accurate props — a lancet cane, a hand bellows, a chest rack of
  vials. Legible, mundane, and the rack duplicated another Role's chest (5.3, 8.1).
- `heavy broad-built` plus `barrel chest` plus a round-and-heavy face. Returns fat
  rather than powerful (8.7.2).
- A jagged raw crystal with smooth spheres grown out of it; a cluster of small
  spheres in rope netting; spheres strung together and held. Two shape languages
  read as growths on a rock; small spheres die in the quantize step; a hanging
  strand nibbles the contour (8.1).
- A real object given an invisible property — a seized vault door that pulls
  enemy blades onto itself. Shows only a door with blades in it; the intent
  cannot be inferred from the image and it does not intrigue (8.1).
- Leaded glass panes in an iron lattice on a squared slab. Returns a window, not
  a shield (5.3, 8.1).
- A garment hue chosen for contrast with the accent alone — a saturated bottle
  green tabard under a red accent on an Iron Ledger figure. The green became the
  character's color and is off-faction (3.5).

**Prompt and rule failures**

- `the rest of the body held as large flat angular panels with only sparse
  structural marks`. Empties every part of the figure the focal region does not
  name (8.6.1).
- A desaturated garment main, taken as a default nobody wrote. Produces a roster
  of beige (3.5).
- Appearance left unstated. Returns the same head every time and the roster
  converges while every individual output passes its checklist (8.4.6).
- Banning region labels in the face clause. Feature nouns alone cannot reach an
  intended regional read; a controlled pair showed no costume drift (8.4.6).
- A stage-wide empty-center rule. Makes a dense biome impossible to build (10.1.1).
- Requiring backgrounds to carry no character accent. Hue exclusivity is not what
  the accent system rests on (10.1.1).
- The floor as a near-invisible strip. Characters do not fit a stage laid out that
  way (10.3.3).
- One silhouette family per Role, with any shared family treated as a design
  problem. Two-word families cannot stay unique across a roster with several
  characters per Role; the composite in pure black is the test (8.3).
- Reading "element from outside reality" as magic only. A shape or material no
  culture made qualifies just as well (8.1).

**Icons and skill art**

- Skill art on the flat icon rules. Comes back too simple and reads as cartoon —
  the rules remove the carved line (12.4).
- Passive icons on the flat icon rules. The same finding at 40 px (12.6).
- Passive icons as chiaroscuro prints. At 40 px the key block's hatching falls
  below one pixel and the tone blocks smear. Revisit only if passives get a larger
  display (12.6).
- Skill art in Renaissance black-line, white-line wood engraving, ukiyo-e or
  expressionist woodcut. Not failures, but chiaroscuro is closest to this guide's
  flat-band foundations. Revisit only if chiaroscuro fails at display size (12.4).
- Skill art tone blocks from one hue family, such as warm ochre and deep rust, or
  the accent paired with a garment main next to it on the wheel. Leonardo merges
  them and returns a single-color print that loses contrast at small sizes
  (12.4.4).
- Zone art as single-ink shapes recolored by `modulate`. Technically flexible, but
  waves are expected blue and white and the ship colored (13.3.1).
- A Relic as a plain object with one strange trick. Reads as a lesser magical
  item, not a find; it needs the ornate finish as well (11.6).

**Environment elements**

- Flat color fields with no engraved linework. Reads as a vector cartoon prop
  (10.3.7).
- A bone white highlight edge on floor clutter. A comic-book ink cue against a
  black contour (10.3.7).
- Counts on organic elements. Every blade placed and nothing growing (5.4).
- Ground-lying floor elements as generated art — mud pools, paving, fungus rings,
  root runs, flat leaves. A generator cannot be held to a consistent
  foreshortening (10.3.3.1).
- An oversized fallen leaf, lying, propped or leaning. Lying it is a dark dash;
  leaning it needs something to lean on that the scatter system will not provide
  (10.3.3.1).
- Shelf fungi as a floor element. Correct in form, wrong band — brackets want a
  trunk (10.6.1.1).
- Floor clutter desaturated wholesale. Gives a jungle floor of grey, dead-looking
  plants; quiet is a contrast instruction (10.3.9).
- Baked ground patches under floor elements. A patch lands wrong on every floor it
  was not drawn for and trades one hard edge for another (10.3.8).
- Magenta or bright green as the key color for environment elements. Both fringe a
  muted palette under a black contour (10.3.7).
- A ruin named as the subject with growth described on top of it. Returns a clean
  ruin with a little moss; *heavily overgrown* does not move it (10.3.7).
- Three colossal subjects on one sheet. The model crops their sides to fit them,
  and a narrow column leaves no room for growth on the subject (10.3.7).
- *Filling the frame* on a subject meant to be seen whole. Returns it cropped at
  the edges (10.3.7).
- A midband element muted from edge to edge under the floor's quiet rule. A jungle
  trunk comes back grey-brown and dead (10.3.10).

---

## 18. Operational notes

**Lock the model and settings.** Same Leonardo model, same Style Reference /
Elements, same generation settings across the whole set. Record them here once
chosen. Changing model mid-roster is the fastest way to break cohesion.

**Transparent background for keyed elements.** Leonardo's transparency setting
returns environment elements already cut out, with the background clause left out
of the prompt, and is the default for environment elements going forward
(10.3.7). Not yet tried on characters, whose composition tail (4.2) still asks
for a flat background.

**Pass and record prompts whole.** A subject block sent without the general block
in front of it loses the entire woodcut style. Every prompt handed over for
generation, and every prompt recorded as approved, includes the general block in
full and is recorded verbatim as generated.

**Composite early.** Perspective and value problems are obvious in a composite and
nearly invisible when looking at assets one at a time in a browser tab. Never
accept a character without dropping it into the battle scene next to one already
approved.

**Document ownership.** This guide owns style. Do not restate slot tables, accent
hexes or prompt blocks in `Concept_Document.md`; where the two disagree, this
guide is correct and the concept document is stale.

**Steam disclosure.** Valve requires disclosure of AI-generated content that ships
with the game and is consumed by players, including in-game art and store-page
marketing. AI dev tools used behind the scenes are exempt under the January 2026
rewrite. Write the disclosure as the public-facing document it is — it appears on
the store page.

**Commercial terms.** Confirm the Leonardo plan tier grants commercial rights and
the export resolution needed before building further on this pipeline.

---

## 19. Open decisions

### 19.1 Retrofit questions

The roster and the floor set predate several current rules. All four are the same
shape of question, and the answer to each is a composite, not a guess. Settle them
together, at six characters rather than at fifteen.

- **The pre-lever five.** Whether the saturation levers (3.5) are a requirement or
  a permission, and what happens to the characters approved under the old
  arithmetic.
- **Characters approved before 8.4.6.** Generated without a stated skin row, face
  cluster or hair mass, so they sit mostly on the model's default head.
- **Characters approved before the three-level detail spec.** The cheapest of the
  four, because it is a one-clause change rather than a redesign (8.6.1).
- **The Jungle grass tufts.** They predate both the engraved-linework finding and
  the color policy (10.6.1.2). Composite them beside the rocks and mushrooms before
  regenerating.

### 19.2 Characters

- **Whether the region label holds.** 8.4.6 was revoked on one character's
  evidence. Watch the next two: if either shows costume drift from the label,
  record it in 17 and narrow the rule rather than restoring the ban wholesale.
- **Appraiser act placement.** `Concept_Document.md` 5.5 lists him under Act 1
  Reclaimed City; his toothed wheel is Clockwork Spire vocabulary. Either the
  concept document moves him to Act 2 or it records the guild-assayer framing that
  reconciles the two (8.7.2).
- **Diviner composite.** Pending against the Plague Doctor and the Thief before she
  is marked approved (8.7.3).
- **Warlord composite.** Pending against the Bloodmage, Bar Brawler, Jester and
  Scholar before he is marked approved (8.7.4). The Jester check also decides
  whether 2.2's "one light-dominant Role" holds with a parchment-tabard Warlord on
  the roster, or needs the same composite-first wording 8.3 now has.
- **Silhouette table retrofit.** The families in 8.3 were written as allocations.
  They are now a record; entries for Roles with no approved character are
  placeholders and can be rewritten from the figure when it is approved.
- **Occupation clauses in the approved prompts.** 5.7 says they do not belong in
  prompts; 8.7.1 carries one. Leave it as recorded-as-generated, or
  strip it on the next revision.

### 19.3 Environments

- **The contrast budget is untested.** The Jungle midband is the first stage dense
  enough to test 10.1.1; if a band-3 foliage mass behind a champion is not enough
  separation at target size, the budget needs a stated minimum rather than "a band
  or two".
- **Midband detail budget.** No finding yet for how much detail a midband element
  carries relative to a champion standing in front of it (10.3.2).
- **Where the stage's loudest chroma sits.** The ground mushrooms, the growth on
  the trunks and the giant blooms all carry saturated color, and coral red and
  violet appear in all three. The proposal is blooms loudest, trunk growth a step
  below, mushrooms as they are; the composite decides it (10.3.10).
- **The trunks against the contrast budget.** A colossus is the one midband element
  large enough to sit entirely behind a champion. It is the first thing to check on
  the Jungle composite (10.3.10).
- **Swallowed ruin fragments in Ruins.** They were planned to carry over, but as
  approved they are mostly jungle growth. Either that reads correctly for a ruin
  the forest swallowed, or Ruins gets its own fragments with the growth dropped.
  The stone is a neutral cool grey rather than the floor rocks' grey-green, so that
  it can sit under the violet light; whether the LUT reconciles it with the rocks
  on the Jungle stage is unchecked (10.6.1).
- **World-specific midband elements.** Seven candidates are listed in 10.6.1.1 and
  none is chosen. Without at least one, the Jungle catalog is a plausible real
  jungle and nothing in it could only grow in this world.
- **What the floor shader owes.** Puddles, wet patches, paving and worn paths were
  all handed to the shader (10.3.3.1), which has no specification yet. Decide what
  it draws before the Jungle stage is called finished, or the band ends up as bare
  fill plus three standing elements.
- **Whether the floor set is biome-specific.** Three elements at three variants is
  nine slices for one variant, and eight variants are in scope (10.6). Decide how
  much is generic ground clutter recolored per variant before generating the second
  one.
- **The white inner city.** A light-dominant environment against figures that are
  half band 1. Either the midband keeps committed darks or the character rules bend
  for one variant (10.6).
- **Overworld camera.** Vista or high-above, one convention or per area (10.4.1).
- **One point-of-interest language or two.** The overview screens (10.4.2) and the
  Adventure map (10.7.2) both need clickable points with states. Answering them
  separately teaches the player two vocabularies.
- **Selection panel palette method.** Named hues or a stated saturation split
  (10.8.6).

### 19.4 Icons, UI and pipeline

- **Rarity colors versus accent colors.** Two color-identity systems competing for
  the same player attention (11.5). Relics add a third candidate: their one
  saturated material (11.6).
- **Standard gear.** Not yet generated. The plain finish that sets it apart from a
  Relic, and whether slots need their own silhouette conventions (11.2).
- **Boots.** Pair or single boot at 100 × 120 (11.2).
- **Gear icon post-processing.** Whether quantize keeps the engraved detail and
  pierced openings (6).
- **Skill art display size.** One illustration per skill or two assets — tooltip
  art plus bar icon — decided once the skill-bar size is known (12.4.7).
- **Element color or caster accent** in the skill art accent block, when the two
  clash (12.4.7).
- **Partner tone lock.** Eighteen of the twenty pairings in 12.4.4 have not been
  generated yet. Lock each hex after its first piece, and settle Scholar in 8.9.1
  first (12.4.7).
- **Background convention for skill art.** Make the sparse cut-line field the
  default, or state what earns a scene (12.4.7).
- **Foresight passive subject.** The Diviner's actives deliberately leave the
  crystal shards free of the passive (12.4.5), and no replacement subject has been
  chosen (12.6.1).
- **Passive icon post-processing.** Full pass or overlay only, once the quantize
  step has been tried on engraved grit at 40 px (12.6.6).
- **Grafting and thread-stance buttons.** Passive icon class, their own class, or
  UI chrome under 13.1 (12.6.6).
- **Zone tint meaning.** Caster accent or ally/enemy ownership (13.3.1).
- **Zone lore family language.** Which Gilded Deck choices belong to its family and
  which to the zone alone (13.3.1).
- **Model and settings lock.** Not yet recorded (18).
