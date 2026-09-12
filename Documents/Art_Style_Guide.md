# Art Style Guide

**Style name:** Lit Woodcut
**Tool:** Leonardo.ai (`app.leonardo.ai`) — no negative prompt field available
**Target:** 2D turn-based combat RPG, phone and desktop, characters ~250–350 px tall in play

This guide is the authority on visual style for every asset in the game. Where
`Concept_Document.md` and this guide disagree, this guide wins; the concept
document describes what the game *is*, this one describes what it *looks like*.

**How it is organised.** Part I holds the rules that bind every asset —
values, materials, perspective, prompting method, the post-processing pass and
the acceptance gate. Part II applies those rules per asset domain; a domain
section states only what differs from Part I. Part III records what has been
tried, how the pipeline is operated, and what is still undecided.

Sections marked *Not yet written* are known gaps with an owner-less
placeholder, deliberately listed so the span of the guide is visible even where
the content is missing.

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
12. Icons (active skill art: 12.4)
13. UI art (turn bar zones: 13.3.1)
14. Effects and VFX
15. Animation
16. Marketing and out-of-game art

**Part III — Record and process**
17. Rejected directions
18. Operational notes
19. Open decisions

---

# Part I — Foundations

*Everything in Part I applies to every asset in the game unless a Part II
section states an explicit, named exception.*

---

## 1. The non-negotiables

Every asset for character or battle visual element in the game obeys these. If an output breaks one, reject it regardless of how good it otherwise looks. Active skill art (12.4) is the named exception: it follows its own print technique and is exempt from rules 1, 2, 3 and 6. Turn bar zone art (13.3.1) is the second: it is built to recede and is exempt from rules 1, 2 and 3.

1. **Very thick uniform black contour outline on the outer silhouette**, and that silhouette edge stays clean and uninterrupted. Fussy, nibbled edges turn to mush at phone size.
2. **Flat color fields, hard-edged shadows, four value bands.** No gradients, no soft shading, no ambient occlusion. Four bands is a **value** rule, not a color-count rule — see section 2.
3. **One saturated accent per character**, flat and uniform, covering roughly
15–20% of the figure.
4. **Hue is a free axis inside every band, including band 1.** Value structure is what makes the style cohere; desaturation is not, and was never a rule. See section 3.5.
5. **Faces are lit and the eyes are visible.** Champions are people the player is meant to care about, and a concealed face reads as a prop. See section 8.4.
6. **Perspective spec** (section 4) is identical across every character, background, effect and icon. This is what makes assets composite without looking assembled from different games.

The seventh rule is a tool constraint rather than a style rule, and it is stated in full in section 5.1: **Leonardo has no negative prompt field**, so every exclusion must be phrased as a positive opposite.

---

## 2. Values

### 2.1 The four bands

Value structure is what makes the style cohere. Hue variety is what makes it not depressing. These are separate axes and the old "four values, three colors" rule conflated them, which is what produced flat sepia figures that sank into their backgrounds. This is for character and battle visual element designs, not overworld or other environment design.

**Four value bands, measured in L\*:**

| Band | L\* | Role |
|---|---|---|
| 1 | 6–12 | Ink black — outline, deep shadow, costume blacks |
| 2 | 28–36 | Dark materials, shadow side of mid materials |
| 3 | 52–62 | The main readable mid tone of most materials |
| 4 | 78–86 | Light materials, lit skin |
| Highlight | 90–94 | Bone white — small shapes only, plus the eyes |

**Rules that follow:**

- **Each material occupies at most two adjacent bands.** That is what keeps eight fills reading as a flat woodcut rather than a painting.
- **Band 1 covers roughly half the figure.** Large committed areas of solid black are what make the rest read as bright. This is the single biggest difference from the earlier sepia version.
- **Bone white is a highlight, not a fill.** Target 5% or less of the figure. If bone white is doing area work, the whole asset goes pale.
- **The outline black and the deepest shadow are the same value**, so shadow can eat part of a figure and merge it into the outline. Same value — not necessarily the same hue. See 2.2.
- **The outline is always ink black `#14121A`**, tinted slightly toward blue-violet, on every character. A true neutral black reads as photocopy; a tinted one reads as printed. The outline is the one part of band 1 that never varies.

### 2.2 Tinted band 1 — the shadow black is a per-subject slot

Band 1 is half the figure. Holding it at one blue-violet black across twenty Roles was throwing away the largest colored area available, for no reason the value rules require.

**The shadow fill may be tinted per character**, at the same L\* as the outline. The outline stays `#14121A` so cohesion still runs through every contour in the game; the mass behind it carries hue.

Starting points, all to be measured to L\* 6–12 before use:

| Shadow black | Hex | Reads as |
|---|---|---|
| Blue-violet (default) | `#14121A` | The neutral option, and the outline value |
| Green-black | `#101A15` | Ruin damp, forest, verdigris |
| Aubergine-black | `#191220` | Arcane, corrupt |
| Umber-black | `#1A150F` | Warm, earthen, worked |
| Ash-blue-black | `#101519` | Cold, institutional |

**Two things to watch.**

**State the same-value rule in the prompt explicitly.** Given a tinted shadow, Leonardo renders it lighter than the outline by default, and the result reads as a mistake rather than a choice. The phrase has to say that the shadow mass and the contour sit at the same value.

**Tint against the garment main, not with it.** A green-black shadow under a green mantle reinforces a hue the figure already has, so half the figure changed and the figure still reads as two hues plus the accent. An umber or aubergine black under that same green mantle buys a genuine third hue. The cost is that the shadow stops reading as the mantle's own shadow and starts reading as its own material, which is the tension the lever creates — generate both on any character where it matters.

**The light-dominant exception.** One Role may invert the band 1 rules and be built on a light garment main, as the Jester is. For such a figure, the band 1 and bone white rules above do not apply. Judge it instead on whether black still holds the outline and roughly a third of the figure, carried by hose, boots and one split sleeve rather than by the torso. This is a deliberate identity for a single Role, not a second option — a second light-dominant character would cost the first one its distinctiveness.

---

## 3. Materials and color

Color is assigned by **what a thing is made of**, not by a global palette limit. Cohesion comes from the shared slots, which are identical on every character in the roster.

### 3.1 How the slots are used outside characters

> **Not yet written.** The slot system was written for champions and currently reads as if characters were the only consumer. Environments (10), items (11), icons (12) and UI (13) each need a stated position: which shared slots they inherit, which per-subject slots they are allowed, and whether they carry an accent at all. Section 12.1 already answers this for icons — the pattern of that answer is what the other domains need.

### 3.2 Shared slots

| Slot | Light value | Dark value | Notes |
|---|---|---|---|
| Outline black | — | `#14121A` | Contour only. Never varies. |
| Shadow black | — | per character | Band 1 fill. Same value as the outline, own hue. See 2.2. |
| Bone white | `#EFE6D2` | — | Highlights and eyes only. |
| Metal, pewter | `#6E727A` | `#3F444B` | Non-accent hardware. Buckles, fittings, plain blades. |
| Skin, warm | `#C08A63` | `#7E5238` | The default. |
| Skin, pale variant | `#D6BBA0` | `#937059` | Earned by concept, not chosen for looks. The Bloodmage uses it. |

Leather **left the shared slot list** — see 3.4.

The two skin rows were previously specified only in `Concept_Document.md` 7.1 even though the acceptance checklist and the general block both treat skin as a shared slot. They are recorded here now and the concept document no longer holds them.

### 3.3 Per-subject slots — where the variety lives

| Slot | Rule |
|---|---|
| Garment main | Two values. The largest colored area on the figure. **May be saturated.** |
| Material neutral | One or two values. Opposite temperature to the accent by default; may be saturated under 3.5. |
| Accent | One flat value, no texture, 15–20% coverage, head and chest region. |
| Shadow black | Band 1 fill hue, at the outline's value. |
| Leather | Two values, per character. |

The temperature rule on the material neutral remains the default: brass on warm leather disappears; brass on cold grey reads as metal. Terracotta on umber disappears; terracotta on slate reads as clay.

**When temperature separation can be dropped.** The rule exists so the accent has something to push against. If the garment main already sits at an extreme value — bone white, or near-black — the value contrast does that job on its own and the material neutral may be the same temperature as the accent. The Jester's scarlet neutral under a saffron accent works because both sit on white. Do not invoke this to rescue a mid-value garment; it only holds at the ends of the ramp.

### 3.4 Leather is per subject

One warm brown `#4A3527` on every belt, strap, boot and satchel in the roster was a large share of the shared mud, and it bought nothing that the outline and the value ramp were not already buying.

Leather now varies: blackened, tar-dark, oxblood-stained, bark-brown, bleached grey-tan. Pick per character and keep it inside two adjacent bands like any other material. The old warm brown remains available; it is now a choice rather than a default.

### 3.5 Saturation — why every character was beige, and the two levers

This section exists because six characters in, every figure was arriving as a different grade of beige with one muted accent, and the cause was arithmetic rather than prompting.

**The arithmetic.** The old shared slots were four neutrals — brown leather, grey pewter, tan skin, black — and they appeared on every figure. Band 1 was specified at roughly half the figure and held at one hue. Accent was capped at 15–20%. That left about a quarter of the figure for the two variable slots, and the material neutral rule then asked one of those two to be a *neutral*. Essentially nothing on the figure was permitted to carry saturated color except the accent, which is exactly what the outputs showed.

**Nothing in the rules ever required the garment main to be desaturated.** The temperature rule in 3.3 applies to the material neutral only. But all six worked examples — dirty cream, ash grey, oatmeal, near-black charcoal, slate-violet, bone white — chose a neutral anyway, and the precedent hardened into a rule nobody wrote.

**Lever one: saturate the garment main.** Give it real chroma and place it at a value the accent is not at. Value does the separating instead of chroma, which is what 3.3 already concedes at the ends of the ramp. Check garment and accent hue adjacency per character; when they merge, move the garment a full value band, never shift either hue.

**Lever two: tint band 1** — section 2.2. Half the figure becomes colored and no value band moves.

**Saturating the material neutral as well is a third step, and it is not free.** It was taken on the Sorcerer and it worked, because garment, neutral and accent sat at three clearly separated values. But it removes the thing the accent pushes against, and it is the first change to roll back if a figure comes back noisy or if the accent stops reading at 300 px. Treat it as per-character permission, not as a new default.

**What is *not* the fix:** the scene-light LUT (section 6). It tints everything uniformly, so it moves area mood without touching the sameness *within* a figure. Keep it as the mood dial it is.

**Open decision.** The five characters approved before these levers were built under the old arithmetic. The three strongest outputs on the roster so far are the Symbiote and the Architect, both pre-lever, and the Plague Doctor, lever-built (8.8.1–8.8.3) — so the split is not yet costing what this section assumed, and regenerating the five is not the default. Composite a lever-built character next to the approved Bar Brawler before going further: if the new one sings and the Brawler now reads as a placeholder, regenerate; if the pre-lever figures keep holding their own, the levers are a permission rather than a requirement and the old arithmetic stays legal. Cheaper to settle at six characters than at fifteen.

### 3.6 Watch for cool-neutral drift

The temperature rule pushes toward a cold material neutral every time, because most accents in section 8.9 are warm. Left unchecked this produces a roster where every character wears blue-grey. Five of the first six Roles did exactly that before it was caught.

Cold neutrals available: slate blue-grey, ash grey, pewter blue, blue-violet charcoal, slate-olive.
Warm and neutral alternatives that still serve: bone buff, sand tan, oxblood, scarlet vermilion, warm charcoal brown, drab olive.

**Rule of thumb: no more than half the fielded roster on cool neutrals.** When a new Role's accent is warm and a cold neutral is the obvious pick, take a warm option if cool is already crowded. The Bar Brawler is the easiest existing Role to move if rebalancing is needed — dirty cream with warm leather works as well as the cold slate.

Note that 3.5 relieves some of this pressure: with a saturated garment main and a tinted shadow black carrying hue, the material neutral is no longer the only place variety can live, so a cool neutral costs less than it used to.

---

## 4. Perspective — identical everywhere

### 4.1 The spec

- Camera at **character chest height, straight on**. No tilt, ever.
- **Horizon line at a fixed screen fraction.** Pick one (45% from the top is a reasonable default), write it down, never move it.
- **Orthographic, no vanishing point.** State it explicitly. Models still cheat, but less.
- **One ground line.** Depth in the battle layout comes from scale and overlap, not from moving figures up the screen.
- **Light from upper left**, in every single asset. Mismatched light reads to players as a perspective error even when the geometry is fine.

### 4.2 Composition tail

Appended verbatim to every character prompt:

```
in contact with a single flat ground line, three-quarter view facing right,
eye-level camera at chest height, orthographic, isolated on a plain flat
background of one uniform color, full figure visible with headroom.
```
The tail constrains the camera and the ground plane only. Squatting, kneeling,
braced, seated and leaning are all compatible with it. "Eye-level camera at
chest height" means the standing chest height the figure would have — it does
not move down when the character does, or the perspective breaks against
everything else in the scene.

### 4.3 Grey-box first

Build the battle scene in Godot with plain rectangles at final resolution. Decide how tall a character is in pixels, where the ground line sits, how much background shows above and to the sides. **Then** generate art to fill known boxes.

---

## 5. Prompting method

The craft rules below are tool behaviour, not style, and they apply to every prompt written for any asset — character, background, icon or effect.

### 5.1 There is no negative field

**Leonardo has no negative prompt field.** Every exclusion must be phrased as a positive opposite. Never paste a list of unwanted terms into the prompt — it reads as a request and you will get it.

When an unwanted element keeps returning, the fix is to change the vocabulary that is summoning it (5.3), not to add words against it.

### 5.2 Tone comes from word choice

Leonardo builds mood from adjectives more than from anything structural. The same design reads gritty or neutral depending on vocabulary:

| Avoid | Use |
|---|---|
| shirt straining | shirt pulled tight across the chest |
| fists loosely raised | fists raised ready |

a direction to watch out for, because it was reached by accident:

- **Frail.** `wiry`, `hunched`, `head pushed ahead`, `matted`. The failure is
  cumulative — two or more of these with nothing pushing back lands on NPC. One
  of them against established bulk, a weapon and a wide stance is a posture, not
  a status, and `hunched` in particular is useful for getting weight into an
  asymmetric silhouette.

### 5.3 Genre attractors

Leonardo has strong genre basins, and a prompt that puts several of their keywords together will land in one no matter what else it says. There is no negative field, so **the only fix is to change the vocabulary wholesale.** Adding qualifiers reinforces the basin.

Attractors hit so far, with the words that summoned them:

| Attractor | Trigger words |
|---|---|
| Dracula | high collar, pale, long open coat, crimson at throat, "bloodmage" |
| Barbarian / nomad | torn strips, bare chest, hard muscle, notched blade, hide |
| Shaman | bone cords, antlers, bound bones at the belt, ritual bowl |
| Modern working man | plain buttoned coat, flat cap, ordinary, unremarkable |
| Modern outdoorsman | travel coat, gaiters, pack roll, tarp, harness, staff as walking pole |
| Generic wizard | robe, hood, staff, tome, wand, "sorcerer" |
| Cartoon | soft floppy cap, wide grin, `wiry`, large head relative to body |

When an attractor lands, rewrite the costume from a different occupation rather than negating. The Bloodmage escaped Dracula by becoming a debt collector in a uniform; nothing about the words "not a vampire" would have done it.

**The two basins on either side of a magic Role are close together.** Fleeing the generic-wizard basin with surveyor and travel vocabulary lands in the modern-outdoorsman basin, which is the same failure as the Bloodmage's plain working coat: the fantasy content is gone and there is nothing a player wants to field. The Sorcerer escaped by taking his nouns from the ruins themselves — ruin masonry, ruin ironwork, a shoulder yoke, a chained slab — rather than from either travel gear or wizardry.

**Historical accuracy is a basin too.** It does not show up as a genre, so it is easy to fall into without noticing: a Role researched from its real-world counterpart gets that counterpart's real props, and the result is competent, legible and mundane. The Plague Doctor's first pass — a straight lancet cane, a hand bellows, a chest rack of vials — was all of that, and the vials also collided with the Alchemist. The fix is the same as for any attractor: change the vocabulary wholesale, here by replacing real objects with the Role's one element from outside reality (8.1).

### 5.4 Counts, not adjectives

**Use numeric counts, never adjectives.** "Three or four wrap bands" is a target the model can hit. "Moderate detail" is not, and it will revert to maximalism. This holds for icons and character designs, not for environment design.

### 5.5 Detail has to survive the pipeline

Ask for *structural* detail — shapes large enough to survive quantization to four bands and downscaling to target size. Texture words (grime, stains, grease, fine hatching) cost prompt budget and return nothing after post-processing. The test is the round-trip in section 6, and it is the same test for a costume, a wall, a sword and an icon.

### 5.6 Depth without gradients

No gradients means no atmospheric haze, so distance is built from
**overlapping flat planes, each one step darker than the one in front,
receding into black.** Five planes is the working number for a full plate.
Dark recession rather than pale is the finding — it reads as a place that
continues past the lit part, which is exactly what a selection panel is
selling. State the furthest plane as nearly gone rather than merely small.
The technique is stated here rather than in section 10 because effects (14)
and any future large plate will need it.

---

## 6. Post-processing — applied to every asset

Uniformity of this pass matters more than any individual generation. Run it even on assets that already look right. Selection panels (10.8.6) take the overlay and the LUT only. The quantize step targets the chroma those panels are built on. Every other asset takes the full pass.

1. Quantize to the fixed value ramp from section 2
2. Mask the accent region and correct its saturation to the section 8.9 hex
3. One shared overlay (grain or paper), identical settings every time
4. One LUT per area, identical within that area
5. Downscale to target in-game size, then judge

**The quantize step must snap L\* while preserving hue.** A greyscale-ramp implementation strips the tinted band 1 (2.2) and the saturated garment (3.5) straight back out, and the levers appear to have done nothing. If a lever-built character comes back muted, check the quantize step before blaming the generation.

**The LUT is the mood dial, and it lives in the engine.** Because every asset quantizes to a known ramp and the accent is a maskable flat fill, area mood can be tuned live in Godot rather than baked into generations. Build the scene light as a layer: a `CanvasModulate` for the global cast, a colored haze quad at low alpha between bands, and the area LUT. Then a biome's color is a value you can iterate on in seconds instead of forty regenerations.

**The round-trip detail test.** Downscale to target size, posterize to the ramp, upscale back with nearest-neighbour. Detail that survives is detail worth keeping.

---

## 7. Acceptance checklists

Run before any asset enters the project. Section 7.1 applies to everything; the domain lists are additions to it, not replacements.

### 7.1 Universal

- [ ] Outer silhouette is unbroken and reads at target size when filled pure black
- [ ] Outline thickness matches the rest of the set, and the outline is ink black `#14121A`
- [ ] Four value bands; no gradients anywhere
- [ ] Every material sits in at most two adjacent bands
- [ ] Bone white is under 5% and is not doing area work
- [ ] Ground line, horizon, camera height and light direction match the spec
- [ ] Wear and detail are structural, not textural
- [ ] Detail concentrated in one focal region, not spread evenly
- [ ] Post-processing pass applied with the same settings as everything else
- [ ] Viewed at final in-game size, not full resolution
- [ ] Composited into the actual scene alongside an existing asset before acceptance

### 7.2 Champions

- [ ] Band 1 covers roughly half the figure, and its tint sits at the outline's value
- [ ] Shared slots (skin, pewter, outline black, bone) match the rest of the roster
- [ ] Garment main, accent and shadow black are separated by value, not by desaturation
- [ ] Material neutral is the opposite temperature to the accent, unless 3.5 permission was taken deliberately
- [ ] Exactly one accent, flat and uniform, roughly 15–20% coverage
- [ ] Accent has not bled onto skin, hair or background
- [ ] Face is lit, eyes are visible, head proportion is adult
- [ ] An age is stated and the face nouns are not the last character's cluster
- [ ] Expression reads through brow, tilt or mouth line
- [ ] Eyes hand-placed and consistent with the last approved character
- [ ] Limbs carry light detail, not blank
- [ ] The Role's occupation is legible from the costume alone, with no name attached
- [ ] One element on the figure could not exist in our world, reads in the silhouette, and derives from the kit (8.1)
- [ ] No signature prop shares a type with another Role's (vials, books, lanterns and similar)
- [ ] Silhouette family is not shared with another fielded Role

### 7.3 Enemies

> **Not yet written.** Which of 7.2 survives at fodder tier, and what a boss adds on top.

### 7.4 Environments

> **Not yet written.** Empty-center sizing, scene-light conformance, no accent bleed, band separation, composite against a fielded team of three.

### 7.5 Items, gear and reagents

> **Not yet written.** Reads at inventory-cell size, silhouette distinct from other items in its slot, rarity signal present and legible.

### 7.6 Icons

> **Not yet written.** Judged at exact target px, three values, one idea, survives being filled black, accent policy correct for the icon class.

### 7.7 UI

> **Not yet written.** Frame weight consistent, no gradient creep from templates, legible over both light and dark area LUTs.

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
- [ ] Overlay and LUT applied, quantize step skipped

### 7.9 Active skill art

Replaces 7.1 for this class; see 12.4.1 for why.

- [ ] Reads as a chiaroscuro woodcut: a black key block carrying the line work, two flat tone blocks beneath it, highlights as bare cream paper
- [ ] Detail lives in the carved line (hatching, contour, gouge strokes), not in color modelling or soft shading
- [ ] Exactly two tone-block colors, one of them the caster's accent family (12.4.4)
- [ ] One subject, caught in the act of the skill, on a diagonal or arc
- [ ] Background held in the darker tone and carried by sparse lines, so the subject stands forward
- [ ] Paper color, key-block line weight and registration offset match the approved set (12.4.6) when viewed side by side
- [ ] Chiaroscuro structure (dark key, mid tone, paper highlight) still reads at the display size, even where individual hatching lines do not
- [ ] Shared overlay applied; quantize step skipped

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

Note that 7.1's universal list contains four checks a panel cannot pass — ground
line and light direction, four bands, and the full post-processing pass. Either
7.1 gains a scope line or 7.8 states its overrides. Recommend the former, since
the overworld class will need the same treatment.

---

# Part II — Asset domains

*Each section below states only what differs from Part I.*

---

## 8. Champions

### 8.1 Design the character before writing the prompt

Three characters cost several rounds each because the prompt was being rewritten when the concept was the thing that was undecided. So start by settling who/what the character is, what is their place in the world, what do they do?

**Every character needs an occupation.** Bar Brawler, Architect and Alchemist worked on the first or second attempt because each names a job, and a job comes with clothes, tools and a posture. "Bloodmage" names a magic system and left the person unspecified, which is why it took five attempts. Before writing a prompt, answer: *what does this person do for a living, and who employs or shuns them?*

**Check the concept for internal conflict.** "Shunned outcast" and "cool playable champion" pull against each other, because low status is what outcast looks like. No wording resolves that. Either the status changes (feared instead of shunned) or the visual reading of it does.

**Flavour text is not a costume brief.** "Hides from the Iron Ledger" taken literally produced a man in a plain working coat with no fantasy content and nothing for a player to want. Concealment survives as *style* — a brand showing at an open collar, dye that will not wash off — not as ordinary clothing.

**Every character carries one element from outside reality.** An occupation makes a figure legible; it does not make it fantasy. Left to itself, every design drifts toward the historically plausible version of its job — a real cane, a real bellows, a real rack of vials — and a roster of accurate period costumes is a roster with nothing in it a player could not see in a museum. Before writing the prompt, name the one thing on this figure that could not exist in our world, and make it large enough to matter in the silhouette.

- **Derive it from the kit, and the world.** The element should be the Role's mechanic made physical, built from what that Role's area contains. The Plague Doctor's Septic Lance and Miasma became one object — an iron-shod pole levelled like a lance, carrying a caged giant tree gall that vents solid smoke — because the Reclaimed City's forest is monstrous and she builds her tools from what she cuts out of it. See 8.8.1.
- **Put it on the tool or the focal region.** A weapon is the cheapest place: it is already the strongest shape in the pose, and a straight, simple object is the least interesting silhouette available. A curve, a barb, an organic or impossible material does more than any amount of costume detail.
- **One, not several.** It is a single anchor, held to the counted-group budget like everything else. A figure where everything is strange reads as a creature, not a person with a job.
- **Harvested, worn or wielded — not grown.** Unless growth is the Role's identity (the Symbiote), the strange thing is something the character has taken, caged, strapped on or carries. That keeps the person legible and keeps Roles out of each other's lanes.
- **Choose its vocabulary against the attractors.** Bone, hide and antler nouns summon the shaman and barbarian basins (5.3). Insect, plant, ruin-stone and impossible-mechanism nouns are less used and have held so far.

The Architect and the Plague Doctor (8.8.1) are the approved references for this. Treat a figure with no such element as unfinished, however well it passes every other check.

### 8.2 Decide the silhouette and the pose before anything else

Two phrases, written before a word of the prompt exists: what shape is this,
and what is the body doing. `strongly asymmetric silhouette, one human hand
and one bloomed limb` is a complete answer. So is `low squat, weight over the
heels, lance braced diagonally across the whole figure`.

State them near the front of the subject block and let the model solve them.
Do not decompose them into a parts list — enumerating chest, then shadow, then
limbs, then pose is what produced three interchangeable figures. The parts that
matter will follow from the shape; the parts that do not should stay flat.

The subject block has no fixed running order. The only fixed element is the
composition tail in 8.2.

### 8.3 Silhouette discipline

Each Role must be identifiable in pure black at 300 px. Assign a distinct silhouette family and hold to it:

| Family | Roles | Cue |
|---|---|---|
| Wide and low | Bar Brawler, Warlord | bulk at the waist, short stance |
| Tall and angular | Architect, Emissary | gaunt vertical, hard corners |
| Squared column | Bloodmage | heavy square shoulders, long straight coat to the knee |
| Narrow vertical, high shouldered | Cultist | layered robes, raised shoulder line, ankle hem |
| Asymmetric mass | Symbiote, Herald | growth or apparatus on one side |
| Off balance | Jester | leaning back off the vertical, one arm out as counterweight |
| Top-heavy | Alchemist | loaded chest, narrow legs |
| Narrow and vertical | Thief, Diviner | tight outline, no shoulder mass |
| Planted diagonal | Sorcerer | mid-calf hem over boots, yoke across the back, rod planted forward across the figure |
| Forward wedge | Plague Doctor | weight forward, beak projecting right at head height, a pole levelled forward in parallel with a caged mass at its end, high hair knot as the only vertical at the head |

**Robed Roles are crowded.** Cultist, Diviner and Sorcerer are all robed, and the Sorcerer stays out of that family on two cues: the hem is cut at mid-calf over visible boots rather than falling to the ankle, and the planted rod puts a hard diagonal through a silhouette the other two hold as a clean vertical. Giving up the ankle hem is the single cheapest separation available to any robed character.

**Pose is the cheapest silhouette tool available.**
A squatting Lancer, a braced shield stance, a kneeling reload and a
standing column are four unmistakable black shapes at 300 px; four standing
figures are not, however different their costumes. Give every Role a pose that
is doing work.

The pose is a *held* combat stance, not a moment inside an action,
and it has to keep the face lit and the accent visible.

If two fielded Roles share a family, that is a design problem, not a prompt problem. Architect and Emissary are the pair to composite side by side early, and their material neutrals must not converge.

**Three Roles now hold a long shaft forward.** Lancer, Sorcerer and Plague Doctor separate on angle and on what ends the shaft: the Lancer's lance is braced diagonally from a low squat, the Sorcerer's rod is planted into the ground line, and the Plague Doctor's pole is levelled horizontal, clear of the ground, and ends in a round mass rather than a point. Keep all three of those cues when revising any of them, and composite them in pure black before a fourth Role takes a shaft weapon.

### 8.4 Faces and proportion

This section exists because every failure mode here was expensive to find.

#### 8.4.1 The rules

- **The face is lit.** Shadow falls on the side of the head away from the light and beneath the jaw, never across the eyes.
- **Eyes are two bone white almond shapes, each with a solid ink black pupil.** Sized to read clearly at 300 px, but **no larger than an adult eye**.
- **Realistic adult head proportion.** State it explicitly in the prompt.
- **The head is the lightest region of the figure.** One bright area in a mostly dark figure pulls the eye straight to the face at any size.
- **Hair and beard are single flat masses.** No interior detail.

#### 8.4.2 State an age, and vary the noun cluster

Left unstated, Leonardo returns its average man: roughly forty, conventionally handsome, and identical from character to character. Two rules follow.

**Name the age in the prompt.** "A man in his late twenties with a smooth unlined face" is a target. Nothing is not.

**Watch the noun cluster, not the individual nouns.** Hollow cheeks, shelf brow, hooked nose and a hard-set jaw are four nouns from one gaunt-severe cluster, and any two of them land on forty-year-old man regardless of the stated age. Build each Role's face from a different cluster — round and heavy, narrow and fine, broad and flat, young and unmarked — and check the last approved character before writing the next.

**Age is characterisation, not decoration.** A young face makes scarring read as a story; the same scars on a middle-aged face read as ordinary wear. Pick the age the Role's motive implies.

#### 8.4.3 Hair length is a silhouette tool

Hair is a single flat mass with no interior detail, so hair length costs nothing in detail budget and changes the outline of the head. Long hair past the shoulders gives a wider, softer head shape than anything else available, and on a roster of cropped and bearded men it is one of the cheapest ways to make a figure recognisable in pure black.

#### 8.4.4 Expression in flat woodcut

Three things carry expression at four values with no interior modelling. Everything else is lost.

- **Brow asymmetry** — one eyebrow raised higher than the other
- **Head tilt** — toward or away from what the figure is holding or facing
- **Mouth line** — flat, parted, or set

Chin up reads as interest; chin tucked reads as caution. Curiosity is brow plus tilt plus a slightly parted mouth. Note that a young face with a raised brow and parted lips sits close to the cartoon attractor (5.3) — if it goes goofy, cut the parted lips first and keep the brow and the tilt.

#### 8.4.5 Concealed faces are an exception, not a tier

A hidden face is permitted only when concealment **is** the character's identity, and it costs that Role its most direct expression tool. The Architect earns it through the hat brim; most Roles do not. When in doubt, show the face.

A hood is not automatically a concealed face. Worn up but pushed back off the brow, it keeps the silhouette and the accent placement while leaving the whole face open and lit — this is how the Sorcerer keeps his hood.

Fodder enemies are the one place faces stay dark and anonymous, which is a free legibility win and matches the reduced detail tier in section 9.1.

### 8.5 Wear is shape, not texture

Dirt, grime, stains and grease do not survive the post-processing pass — four flat value bands quantize a smudge into nothing, and asking for them costs prompt words for no visible result.

Wear that reads at 300 px is structural: a sleeve burned off at the elbow, a hem torn and re-panelled, a mended patch with hard angular edges, a strap replaced with the wrong material, a scar as a solid band 1 shape.

**Tie the wear to the Role's mechanics wherever possible.** The Sorcerer's Arcane Instability surges damage him along with everyone else, so his burned-away right sleeve and blackened forearm are the visible cost of how he fights — a mark no other Role can carry. Wear derived from the kit is characterisation; wear applied for grit is texture.

**Scarring is band 1, never the accent.** Accent on skin breaks the acceptance checklist. Burn marks, brands and glyph scars are solid ink black shapes.

### 8.6 The canonical general block

Substitute the bracketed slots from section 3. Everything else is identical in every character prompt, word for word. The repetition is doing most of the consistency work.

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
narrow bone white edge along the upper left contour, {FOCAL REGION}
carrying the heaviest engraved detail and reading as the focal point of the
figure, the rest of the body held as large flat angular panels with only
sparse structural marks, all marks large and structural, with saturated
{ACCENT} as the single accent covering roughly a fifth of the figure, flat
and uniform with little texture, used only on {PLACEMENT}, hand-carved edge
quality.
```

**Detail vocabulary.** Ask for *structural* detail, and derive the nouns from
this Role's own trade and materials rather than reusing the list from the last
character. The test is size, not vocabulary: any mark that survives the round-trip in section 6 qualifies.

**Always use numeric counts, never adjectives.** "Three or four wrap bands" is a target the model can hit. "Moderate detail" is not, and it will revert to maximalism.

**The three strongest outputs so far are the Plague Doctor (8.8.1), the Symbiote (8.8.2) and the Architect (8.8.3).** Two of the three are pre-lever, and each breaks something in this chapter: the Symbiote and the Architect carry an untinted band 1 and spread detail rather than holding a focal region, and the Symbiote's accent lands on the head. Those rules are the ones to relax first when a figure fights them — see the open decision in 3.5. The concealed face in 8.4.5 is not among them; it stays a strict exception the Architect earns and the next Role has to earn again.

### 8.7 Reference example — Bar Brawler (pre-levers)

Kept as the reference for the subject block's shape. Its slot assignments predate section 3.5 and should not be copied.

```
[GENERAL BLOCK with warm tan skin, a dirty cream shirt, cold slate blue-grey
trousers, terracotta accent on the apron and knuckle wraps]
full body character, heavyset broad-shouldered brawler, barrel chest,
realistic adult head proportion, face lit with no shadow across the eyes,
shadow falling on the side of the head away from the light and beneath the
jaw, eyes as two bone white almond shapes each with a solid ink black pupil,
sized to read clearly but no larger than an adult eye, wide flattened nose,
heavy brow, solid beard shape as one flat mass, a worn tavern apron with
visible seams, ties and pocket divisions, shirt pulled tight across the
chest with a few bold fold lines, shirt and trousers falling into solid
black shadow on the lower right side, thick forearms wrapped in cloth
showing three or four wrap bands, trousers with two or three heavy fold
lines and a visible belt, boots with a simple sole division, weight forward
on the front foot, fists raised ready, standing on a flat ground line,
three-quarter view facing right, eye-level camera at chest height,
orthographic, isolated on a plain flat background of one uniform color,
full figure visible with headroom.
```

### 8.8 Reference example — Sorcerer (post-levers, approved)

The working example of sections 2.2, 3.5, 8.4.2–8.4.4 and 8.5 together. Three real hues on the figure — saturated bottle green garment, saturated warm ochre neutral, cobalt accent — separated by value rather than by desaturating two of them, over a green-black band 1.

Slots: garment main saturated deep bottle green, material neutral saturated warm ochre, leather blackened, shadow black green-black, accent unstable cobalt `#2F52C4` on the slab inscriptions, hood lining and rod crown, focal region the chained slab and the hands. Occupation: a ruin-breaker who pries relics out of dead temples.

```
[GENERAL BLOCK with the slots above]
full body character, a young ruin-breaker who pries relics out of dead temples, heavy hooded mantle over a shorter under-robe cut at mid-calf above laced boots, a dark iron shoulder yoke across the back carrying a broken slab of carved ruin masonry chained flat against his chest, weight settled back on the rear foot, a thick cord-wrapped length of ruin ironwork planted forward as one hard diagonal across the whole figure ending in swirling in weird shapes, realistic adult head proportion, a man in his late twenties with a smooth unlined face and a lean jaw, long hair falling past the shoulders as one flat mass inside the hood, deep hood worn up but pushed back off the brow so the entire face is open and lit, face lit with no shadow across the eyes, shadow falling on the side of the head away from the light and beneath the jaw, eyes as two bone white almond shapes each with a solid ink black pupil, sized to read clearly but no larger than an adult eye, one eyebrow raised higher than the other, lips slightly parted, chin up, head tilted toward the slab at his chest, three ink black glyph scars burned across the temple, four rough ruin-stone reagent chunks held in a hinged case at the chest, the mantle burned away at the right sleeve leaving the bare forearm blackened to the elbow, the mantle falling into solid green-black shadow on the lower right side and inside the hood, the free hand closed hard around the cord grip, the rod crown broken and asymmetric with three iron teeth swirling around a carved stone, boots with a simple sole division, in contact with a single flat ground line, three-quarter view facing right, eye-level camera at chest height, orthographic, isolated on a plain flat background of one uniform color, full figure visible with headroom.
```

Counted groups: glyph scars at the temple, reagent chunks at the chest, iron teeth on the rod crown — three, in three regions. The mended hem panels are a borderline fourth and are the first cut if a variant comes back busy.

The Alchemist subject block follows the same pattern with its own slot assignments, generated and approved under the pre-lever rules.

#### 8.8.1 Reference example — Plague Doctor (post-levers, approved)

The first Role built under the 8.1 rule on elements from outside reality, and the working example of a partial mask that keeps 8.4 intact. Three hues — saturated dark mustard garment, aubergine-black band 1, moss accent — with the shadow tinted against the garment main as 2.2 recommends: purple under yellow, so band 1 buys a real third hue instead of reinforcing the second.

Slots: garment main saturated dark mustard ochre waxed oilcloth, material neutral warm sand-buff linen, leather oxblood, shadow black aubergine-black, accent deep moss on the gall's cracked interior, the goggle lenses and the collar lining, focal region the beak and the caged gall. Occupation: a quarantine physician in the Reclaimed City's jungle who builds her tools from what she cuts out of it.

Decisions recorded with it:

- **Half-beak, not full mask.** The beak covers only nose and mouth; goggles are pushed up onto the forehead, so the accent reaches the head without landing on the eyes (8.9). The mouth line is lost as an expression tool, and brow plus tilt carry it. A full mask was rejected under 8.4.5 — concealment is not this Role's identity; the beak is.
- **One object carries the kit.** The pole is Septic Lance, the venting gall is Miasma. Nothing on the chest holds containers, which is what keeps her clear of the Alchemist.
- **A gall, not a fungus.** A fungal mass in moss green would sit beside the Symbiote's fungal accent in an adjacent hue. A plant tumour is also closer to a disease Role.
- **Young face from the narrow, fine cluster.** Early thirties, avoiding the Sorcerer's smooth-and-lean nouns. The neck vein marks are kit-derived wear (8.5), and on a young face they read as a story, not age (8.4.2).
- **No hat.** A high hair knot gives the head its vertical against the horizontal beak (8.4.3).

Recorded whole, general block included, as generated:

```
bold woodcut illustration with engraved structural linework, very thick uniform black contour outline on the outer silhouette, clean uninterrupted silhouette edge, flat color fields, hard-edged shadows, high contrast with large areas of solid shadow in a deep aubergine-black, that shadow mass and the outline sitting at the same value, colors assigned by material: warm tan skin, a saturated dark mustard ochre waxed oilcloth jerkin, warm sand-buff linen wraps and cord, oxblood leather straps and boots, dull pewter grey metal fittings, all flat and unmodulated, warm bone white reserved for small highlight shapes and the eyes, outline black tinted slightly toward blue-violet, light from the upper left casting a narrow bone white edge along the upper left contour, the chitin beak and the caged gall at the end of the pole carrying the heaviest engraved detail and reading as the focal point of the figure, the rest of the body held as large flat angular panels with only sparse structural marks, all marks large and structural, with saturated deep moss green as the single accent covering roughly a fifth of the figure, flat and uniform with little texture, used only on the cracked-open interior of the gall, the round goggle lenses and the lining of the high collar, hand-carved edge quality.
full body character, a grim woman in her early thirties who works as a quarantine physician in a jungle of monstrous growth, building her tools from what she has cut out of it, forward-leaning wedge silhouette, weight forward on the front foot, both hands gripping a long iron-shod pole longer than she is tall, levelled forward toward the right like a lance and slightly raised, at its far end an iron cage of three curved prongs holding a giant warty tree gall the size of her head, a tumour-like growth cut from a jungle tree, cracked open along one jagged seam and venting one thick solid plume of smoke that curls up and back over her head, a hooked black chitin beak cut from a jungle creature strapped over only her nose and mouth and projecting forward to a point, a pair of round goggles pushed up onto her forehead, the upper half of the face fully open and lit, realistic adult head proportion, face lit with no shadow across the eyes, shadow falling on the side of the head away from the light and beneath the jaw, eyes as two bone white almond shapes each with a solid ink black pupil looking to the right, sized to read clearly but no larger than an adult eye, a narrow fine-boned face with a straight thin nose and a small pointed chin, a stern hard stare, narrow straight brows drawn hard together, chin tucked, head tilted toward the gall, black hair pulled back tight into one high knot at the crown as one flat mass, three ink black vein marks creeping up the side of her neck from beneath the collar, a fitted high-collared waxed oilcloth jerkin laced down one side, forearms bound tight in linen wraps from wrist to elbow, oxblood leather gloves, a skirt of four heavy blackened oilcloth panels split to the hip and hanging to mid-calf above tall laced boots, each panel ending in a ragged hard-edged hem, the panels and the lower right side of the figure falling into solid aubergine-black shadow, boots with a simple sole division, in contact with a single flat ground line, three-quarter view facing right, eye-level camera at chest height, orthographic, isolated on a plain flat background of one uniform color, full figure visible with headroom.
```

Counted groups: three cage prongs at the weapon head, four skirt panels at the hem, three vein marks at the neck — three, in three regions, with the two goggles as a small fourth. If a variant comes back busy, cut the ragged hems before touching the counts.

#### 8.8.2 Reference example — Symbiote (pre-levers, approved)

The working example of 8.3: the fungal shelf over one shoulder and the bloomed limb make the silhouette strongly asymmetric, and the accent sits on exactly those two masses. It is also the earliest prompt to name a focal point and hold the clothing and limbs as empty flat panels.

Slots: garment main peat brown-black waxed canvas, material neutral sand tan sackcloth, leather dark brown, band 1 untinted ink black, accent verdant green `#4E8C3F` on the shoulder growth and the temple bloom. Occupation: a Symbiote Slums harvester bonded to a forest organism to survive the spores.

Recorded whole, general block included, as generated:

```
bold woodcut illustration with engraved structural linework, very thick
uniform black contour outline on the outer silhouette, clean uninterrupted
silhouette edge, flat color fields, hard-edged shadows, high contrast with
large areas of solid ink black, colors assigned by material: warm tan skin,
a peat brown-black waxed canvas harvesting smock, sand tan sackcloth wraps
and hood lining, dark brown leather straps and boots, dull pewter grey metal
fittings, all flat and unmodulated, warm bone white reserved for small
highlight shapes and the eyes, ink black tinted slightly toward blue-violet,
light from the upper left casting a narrow bone white edge along the upper
left contour, two levels of detail: the torso, clothing and face carry
moderate engraved detail through seams, folds, straps and panel divisions;
the limbs carry light detail through wraps and fold lines rather than being
left empty, detail spread evenly across the body rather than concentrated in
one area, all marks large and structural, with saturated verdant green as the
single accent covering roughly a fifth of the figure, flat and uniform with
little texture, used only on the shelf growth over the right shoulder and the
bloom across the right temple, hand-carved edge quality.
full body character, hunched human host, fungal mass over one shoulder and
half the head rendered with fine engraved gill texture and hatching as the
focal point, crisp linework, ragged clothing and limbs as large flat angular
panels with no interior detail, strongly asymmetric silhouette, one human
hand and one bloomed limb ending a fungi claw, standing on a flat ground
line, three-quarter view facing right, eye-level camera at chest height,
orthographic, isolated on plain neutral background, full figure visible with
headroom.
```

The subject block is the shortest of the approved set and still carries the silhouette, which is what makes it the reference for a Role whose identity is one shape rather than a set of carried objects.

#### 8.8.3 Reference example — Architect (pre-levers, approved)

The working example of a narrow vertical silhouette, and the approved case of a face concealed under 8.4.5 — the hat brim, not the features, carries the read.

Slots: garment main cold ash grey coat over dark blue-grey underlayers, material neutral bone white rolled plans, leather dark brown, band 1 untinted ink black, accent muted brass `#C69A4B` on the chest drafting instruments, the hat band and the armature joints. Occupation: a surveyor aligned with the God of Rules who measures a structure before rebuilding it.

Recorded whole, general block included, as generated:

```
Bold woodcut illustration with engraved structural linework, very thick
uniform black contour outline on the outer silhouette, clean uninterrupted
silhouette edge, flat color fields, hard-edged shadows, high contrast with
large areas of solid ink black, colors assigned by material: pale cool skin,
a cold ash grey coat, dark blue-grey underlayers, dark brown leather straps
and boots, all flat and unmodulated, warm bone white reserved for small
highlight shapes, the rolled plans and the eyes, ink black tinted slightly
toward blue-violet, light from the upper left casting a narrow bone white
edge along the upper left contour, two levels of detail: the torso and
clothing carry moderate engraved detail through seams, folds, straps and
panel divisions; the limbs carry light detail through wraps and fold lines
rather than being left empty, detail spread evenly across the body rather
than concentrated in one area, all marks large and structural, with
saturated muted brass as the single accent covering roughly a fifth of the
figure, flat and uniform with little texture, used only on the drafting
instruments across the chest, the hat band and the joints of the measuring
armature, hand-carved edge quality.
full body woman character, gaunt tall angular figure in a long tattered
surveyor's coat, narrow vertical silhouette with the coat falling in three
or four heavy vertical fold lines, realistic adult head proportion, face
hidden beneath a wide flat-brimmed hat, narrow features, hair as one flat
mass at the shoulders, brass drafting tools and three rolled plans strapped
across the chest with two visible strap divisions, coat with a panel
division down the front and a visible collar, coat falling into solid black
shadow along the lower right side, one arm ending in a jointed measuring
armature showing three counted joints, other arm with two fold lines at the
sleeve, boots with a simple sole division, posture stiff and precise, weight
evenly on both feet, standing on a flat ground line, three-quarter view
facing right, eye-level camera at chest height, orthographic, isolated on a
plain flat background of one uniform color, full figure visible with
headroom.
```

Counted groups: three or four coat fold lines, three rolled plans at the chest, three armature joints — three, in three regions, on a figure with no face to compete with them.

### 8.9 Accent registry

One color per Role, no sharing. Hue alone cannot separate twenty entries at phone size, so **value** and **placement** carry the same signal in parallel.

| Role | Accent | Hex | Value | Placement |
|---|---|---|---|---|
| Thief | rust orange | #C25A1E | mid | hood lining, blade edges at belt |
| Bloodmage | crimson | #A32036 | dark | chest channels, forearm staining, belt-chain cord |
| Bar Brawler | terracotta | #B8563A | mid | apron, knuckle wraps |
| Lancer | flame copper | #E07B2C | light | lance pennant, helmet crest |
| Jester | saffron | #EDB431 | light | cap bells, collar motley, wrapped knife grips |
| Architect | muted brass | #C69A4B | mid-light | drafting instruments on chest, hat band |
| Appraiser | antique gold | #8F7326 | dark | loupe, scale beam, tally gorget |
| Scholar | ledger parchment | #DCCFA8 | lightest | open ledger at chest, spectacle rims |
| Alchemist | acid chartreuse | #A8BF3A | light | flask contents, apron spill stain |
| Symbiote | verdant green | #4E8C3F | mid | fungal mass on shoulder and skull |
| Plague Doctor | deep moss | #2F5D3A | dark | cracked interior of the caged gall, goggle lenses on the forehead, collar lining |
| Tidal Corsair | sea teal | #2E8C8C | mid | coat sash, pistol furniture |
| Chronophage | ice cyan | #8FD4DC | light | clock-face at chest |
| Sorcerer | unstable cobalt | #2F52C4 | mid | slab inscriptions at the chest, hood lining, stone in the rod crown |
| Emissary | ink indigo | #26326B | dark | seal wax on chest documents, badge |
| Diviner | pale lilac | #B9A5D9 | light | veil trim, throat sigil |
| Cultist | deep amethyst | #5B2A78 | dark | throat brand, robe lining, stained fingers |
| Herald of the Loom | violet magenta | #8E3A91 | mid | active thread through chest loom-frame |
| Tactician | rose magenta | #C2447A | mid | map case, marker rods |
| Warlord | steel blue-grey | #6B7A88 | mid | shield device, helmet plume |

**Watch these three pairs:** Architect brass / Appraiser gold, Sorcerer cobalt / Emissary indigo, Cultist amethyst / Herald magenta. The value gap does the separating in each case, so if a hex is adjusted, never adjust it toward its neighbour's brightness. Placement differs in all three pairs as a backup.

**With saturated garments in play, check the accent against the garment too.** Hue adjacency between a Role's own garment main and its accent is a new failure mode — the Sorcerer's bottle green sits next to cobalt and holds only because the garment is a full value band darker. When they merge, move the garment's value; never shift either hue.

**Eyes are never the accent.** Cultist and Chronophage previously listed eye placements; both have been moved to chest elements. Accent-colored eyes read as menacing and break section 8.4.

**Accent never lands on skin.** Scars, brands and burns are band 1 shapes (8.5).

**Only three champions are fielded at a time**, so full-roster clashes are largely theoretical. What matters is that any three the player picks stay separable.

**Extend each accent beyond the sprite** — card border, map icon, damage numbers, skill VFX. Twenty hues is a lot to learn from sprites alone, but the association forms within an hour or two of play when the same color appears in four places.

#### 8.9.1 Accent hexes that need attention

Several accents in section 8.9 are low-chroma by nature, and a dull accent on a dull garment gives a figure with no vibrancy anywhere:

- **Warlord `#6B7A88`** is a neutral, not an accent. It needs a real color or an explicit decision that this Role is the drab one.
- **Appraiser `#8F7326`**, **Plague Doctor `#2F5D3A`** and **Scholar `#DCCFA8`** are all close to being materials rather than accents. Raise chroma and let value and placement keep doing the separating.

Generate accents as flat uniform fills so they can be masked and boosted in post. Asking Leonardo for a brighter accent drags the whole figure with it; recoloring the mask does not.

### 8.10 Portrait and card crops

> **Not yet written.** Roster, party-select and card UI show champions at a different crop and size from the battle sprite. Needs: crop rectangle relative to the full figure, minimum face size in px, whether the accent budget is recomputed for the crop, and whether portraits are generated separately or cut from the approved full figure.

---

## 9. Enemies and bosses

Enemies inherit everything in Part I and most of section 8. What follows is the difference.

### 9.1 Detail tier by content tier

- **Player Roles** — the block as written.
- **Fodder enemies** — drop to `minimal interior detail, large simple shapes, three values`, faces dark and anonymous, no accent or a heavily reduced one.
- **Bosses** — same block as player Roles plus one additional counted focal element. Do not raise the detail ceiling. Distinguish bosses by scale and by the extra focal element.

### 9.2 Fodder

> **Not yet written.** Beyond the reduced detail tier: how many distinct fodder bodies exist per area, whether recolours are permitted and on which slot, and how a fodder silhouette stays separable from a champion's at 300 px.

### 9.3 Mini-bosses and bosses

> **Not yet written.** Scale relative to champions, how the additional counted focal element is chosen, and whether bosses carry an accent registered like a Role's or borrow the area scene light.

### 9.4 Non-humanoid and creature forms

> **Not yet written.** The whole guide currently assumes a humanoid figure. Beasts, constructs and statues need their own answers on band 1 coverage, the face rule (section 8.4 assumes eyes), and where the accent sits when there is no head-and-chest region.

### 9.5 Enemy color policy

> **Not yet written.** Whether enemies draw from the champion accent registry, from the area scene light, or from a separate reserved set — and how enemy color avoids being read as a champion's identity color during a fight.

---

## 10. Environments

There are **three kinds of environment art**, and they do not share a camera.

**Battle stages** (10.3) obey the perspective spec in section 4 exactly, because
characters stand in them. They are built from four draw-order bands.

**Overworld views** (10.4) are the navigation screens — vistas, or high-above
views the player clicks points of interest on. They are the one asset class in
the game that is **exempt from section 4**, since a chest-height orthographic
camera cannot show a region. The exemption is granted here and nowhere else, and
it is bounded: everything else in Part I still binds, and the value ramp,
outline weight and post-processing pass are what keep an overworld reading as
the same game as the battle it leads into.

**Environment selection panels** (10.8) are for screens to depict the viewpoint of characters, to see what a possible area could look like, to inspire and give mystery for what could be found if explored. It should often be epic and use much verticality. It by design breaks some rules that it doesn't hinder the games design as other elements will not be present or compared next to it.

### 10.1 Rules

Applies to battle stages. Overworld views take the last two bullets only.

- **Shallow stage.** A wall or skyline, a thin floor strip, almost nothing in between. This is what makes perspective mismatch impossible to see.
- **Empty center**, sized for the character line.
- **No figures, no creatures** — state both.
- **Flat horizon low in frame**, at the fixed screen fraction from section 4.
- **Backgrounds carry no character accent.** Accent belongs to characters and effects.

### 10.2 Scene light — the mood dial

Each variant gets a **scene light color** — one per variant, not one per area, since a jungle and a ruin under the same sickly teal-green read as the same place. It is not a Role accent and never appears on a character's costume. It lives in the sky field, the haze band between bands, and the tint of the floor strip.

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

**Characters now carry saturated hue of their own** (3.5), so check each new variant against a fielded team of three: a saturated garment main can collide with a scene light in a way a beige one never did. The fix is the variant, not the character.

### 10.3 Battle stages — the four bands

Every battle stage is a scene authored by hand, laying its elements out across
four bands. A band is a budget as much as a layer: content that belongs to one
band does not appear in another, which is what lets elements be reused across
stages within an area.

They draw in the order **Background, Floor, Midband, characters, Foreground**.
Midband elements stand on the ground, so their bases must cover the floor's top
edge; drawing the floor after them cuts a hard horizontal line across every
trunk and shrub.

#### 10.3.1 Background

Sky, clouds, moon, sun, mountains, silhouettes of far-away things. Carries the
scene light's sky field (10.2) as one flat saturated field. Lowest detail of the
four bands, and the only band permitted to reduce below the full value ramp.

One plate per stage, drawn to the full 1280×720 frame. The camera does not
scroll (10.3.5), so the sky and the far masses are one asset.

> **Not yet written.** Value range allowed, and whether distant masses are silhouette-only.

#### 10.3.2 Midband

The visible surroundings of the combat: buildings, trees, foliage, rocks, walls,
waterfalls. This is the band that says which area the player is in, and the band
where the empty-center rule in 10.1 is actually enforced.

Assembled from keyed elements, placed one by one in the stage scene. The empty
center is guaranteed by that placement rather than by a rule the engine
enforces, so it is checked against the character line while the stage is laid
out (10.3.5).

> **Not yet written.** Detail budget relative to a champion, and how the empty center is composed rather than merely left blank.

#### 10.3.3 Floor

Characters are drawn on top of this band. It is deliberately not a clean plane:
small ground clutter — rocks, grass tufts, dirt piles, trash — breaks the strip
up. Everything here must sit below the ground line established in section 4, and
clutter must not compete with a character's silhouette for the same value.

The strip itself is one shader-driven surface. The clutter over it is not baked
in: it is scattered by the engine from a small element set, authored per stage
as scatter rules — an element's textures, its density, its scale and rotation
jitter, and the radius it holds clear around every character's feet, which is
what keeps the empty center (10.1) open on a band nobody places by hand. The
scatter is seeded per battle, so the same fight re-entered looks the same.

#### 10.3.4 Foreground

The last band before UI: vines, weather (rain, snow, fog, sun rays), and
occasional silhouettes intruding from the bottom edge — crates, bushes, trash,
similar. Foreground reads as pure band 1 by default, since anything with
interior detail here fights the characters.

**No foreground element crosses a character slot.** Silhouettes are placed by
hand along the bottom edge, clear of the character line. Weather is neither art
nor shader in this band: it is a particle scene, chosen per encounter rather
than per stage, and it plays in front of the silhouettes — which is what keeps
an indoor fight dry on a stage otherwise used outdoors.

> **Not yet written.** Maximum screen coverage so the fight stays readable.

#### 10.3.5 Layer spec

The battle camera does not scroll, so the bands have no parallax ratio and
nothing sits off-screen at rest. Every band is authored to the full 1280×720
frame. Camera shake moves the whole stage as one, bands and characters
together — a band that lagged behind the others under shake would read as a
seam.

A stage is laid out against the six character positions and judged there, which
is the grey-box step (4.3) for this section.

> **Not yet written.** Section 6 already assumes a haze quad between bands, so state where the haze sits relative to the four.

#### 10.3.6 Element catalog and reuse

Each variant owns a catalog of elements per band, and its stages are laid out
from that catalog — two or three stages per variant, so an element is seen again
across them. Reuse is what the catalog is for: a stage earns its distinctness
from its layout and its background plate, not from elements nothing else uses.

Elements are keyed individually rather than cut from a generated plate, since a
stage places them one at a time and at its own scale.

> **Not yet written.** How many elements a variant needs before its stages stop reading as the same place, and the rule for what may be reused across the two variants inside an area.

### 10.4 Overworld and navigation views

One or more per area (10.6), used to navigate by clicking points of interest.

#### 10.4.1 Camera and framing

> **Not yet written.** Vista versus high-above is a choice per area or a single convention for all of them — decide which. Needs the camera treatment, whether the view scrolls or fits one screen, and how it holds the light-from-upper-left rule when the ground plane is no longer vertical.

#### 10.4.2 Points of interest

> **Not yet written.** What a clickable POI looks like on the plate, its states (locked, available, cleared, current), how it stays legible against dense terrain, and its relationship to the Expeditions node icons in 12.3 — the same visual language or a separate one.

#### 10.4.3 Legibility at overworld scale

> **Not yet written.** Detail at this camera is far smaller than a character's, so state what survives: the outline weight at region scale, whether the four-band ramp holds or drops to three like icons do, and how an area reads as itself when its midband vocabulary is not visible.

### 10.5 Hub screens

One per area (10.6). The hub is where the war room, Armory, Adventurer's Guild
and shop live (`Concept_Document.md` 3.6).

> **Not yet written.** Decide first whether a hub is an illustrated plate with clickable regions, UI panels over a plate, or an icon-driven menu — that decision sets how much art exists at all. Then: whether a hub reuses its area's battle-band elements or is generated as its own composition, and how the four hubs stay distinguishable at a glance.

### 10.6 Area catalog

Four areas are planned. Each has **two variants**, one hub (10.5), at least one
overview screen (10.4), and its own element catalog per battle band (10.3.6).
Each variant owes two or three battle stages (10.3) laid out from that catalog.
Variants are as distinct from each other as two areas would be, so treat a
variant, not an area, as the unit of work. Each also owes Adventure an element
set (10.7), since a run starts from a chosen variant.

| Area | Variant A | Variant B |
|---|---|---|
| Reclaimed City | Jungle | Ruins |
| Clockwork Spire | Mechanical construction areas | Oily ad-hoc slums in mines |
| Pirate Coves | Rocky islands, harsh ocean presence | Candle-lit moist and mouldy shanty town, wood and sailcloth |
| The Iron Ledger | Run-down slums of a massive city | White glistering inner city |

**The Iron Ledger's inner city is the hardest asset in the plan.** White
glistering is a light-dominant environment, and section 2 gives band 1 roughly
half of every figure. A champion in front of a white plate is a black cutout.
Either the inner city takes a treatment that keeps large committed darks in the
midband, or the character rules bend for that one variant — the same trade the
Jester takes in 2.2, and it should be decided deliberately rather than
discovered in a composite.

**Pirate Coves variant B is the only candle-lit interior in the set**, which
means a warm scene light and a light source that is not upper-left at region
scale. Section 4's light rule holds for the assets themselves; it is the only
warm entry in the 10.2 table, so it carries the contrast against the other seven
on its own.

#### 10.6.1 Reclaimed City

> **Not yet written.** Per variant: scene light, band vocabulary (10.3.1–10.3.4), approved plates.

#### 10.6.2 Clockwork Spire

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates. No scene light assigned yet at all (10.2).

#### 10.6.3 Pirate Coves

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates.

#### 10.6.4 The Iron Ledger

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates. Resolve the white-plate problem above before generating.

### 10.7 Adventure — the derived overview

Adventure is a feature reached from each of the four
hubs, and a run starts in one of that area's two variants (10.6) and the screen where the player chooses the area shows two panels that together covers the screen, half each. Each panel depicting the area taking its look from the biome. Every variant therefore owes Adventure an element set, and
**eight sets are in scope.**

It is a third camera case rather than a third kind of environment. Like an
overview (10.4) it shows a region the player clicks through, but it is not a
finished plate: the map is **composed at runtime from many small elements**,
which makes it the only environment in the game whose layout is decided by code
rather than by hand — a battle stage scatters only its floor clutter (10.3.3).
That inverts the usual acceptance route — a single element can pass every check
in section 7 and the assembled map still fail.

#### 10.7.1 Element set requirements

> **Not yet written.** What runtime composition demands that a plate does not: which elements tile or repeat without a visible seam, how many variations of each are needed before repetition is legible, how density and placement are driven, and how the outline weight survives elements being placed at differing scales next to each other. The catalog is per variant and derives from that variant's band vocabulary (10.3.6) rather than being drawn fresh.

#### 10.7.2 Map furniture

> **Not yet written.** Node icons (12.3), path connectors, and node states are the layer that sits on top of the composed field. Needs the same states as 10.4.2 and should share their answer — a player should not learn two POI languages. State whether furniture is generated art or drawn in engine.

#### 10.7.3 Composition acceptance

> **Not yet written.** The check that a plate does not need: several generated maps viewed at target size, judged for repetition, for whether the variant is still recognisable once elements are scattered rather than composed by hand, and for whether nodes stay findable against a dense field.

#### 10.7.4 Scene light for Adventure

A run keeps the scene light of the variant it starts in (10.2). Adventure has no
light of its own: an expedition reads as a journey through that variant, and the
eight element sets stay eight places.

---

### 10.8 Selection panels — the third environment class

There are three kinds of environment art. Battle stages (10.3) are
inhabited. Overworld views (10.4) are navigated. **Selection panels are looked
into and not entered** — they are the plate a player chooses a place *from*,
and their job is to make that place worth choosing.

The first pair is the Adventure biome selector (`Concept_Document.md` 5.1): two
panels, each covering half the screen, one per variant of the area the run
starts in. Eight panels are in scope for the same reason eight Adventure element
sets are (10.7).

A panel is a **window at standing height**, framed as if the party has stopped
on the path and is looking in. That framing is the whole class — everything
below follows from it.

#### 10.8.1 What this class is exempt from

This is the second named exemption in the guide, after the overworld camera in
10.4, and it is wider. Granted here and nowhere else:

- **Section 4 entirely.** No fixed horizon fraction, no orthographic
  projection, no single ground line, no chest-height camera. A panel recedes,
  and recession is the point.
- **Light from upper left.** A panel may take its key light from a source
  inside the scene — the Magic Ruins panel is lit by the candlelight in its own
  doorway. The source must be visible or its opening must be, so the light
  reads as belonging to the place.
- **The four value bands of 2.1.** See 10.8.3.
- **The section 6 post-processing pass.** See 10.8.6.

What still binds: hard-edged shadows, no gradients, committed dark mass,
structural detail over texture (5.5), and no figures or creatures.

#### 10.8.2 Composition

- **State the entry side.** The path or threshold enters from a named edge —
  right, left, or underfoot — rather than being centered. A centered path reads
  as a poster; an offset one reads as somewhere you are standing.
- **The way in ends before the frame does.** The Jungle path bends out of sight
  into darkness; the Ruins interior stops at the second column. This is the
  single most load-bearing rule in the section. A panel that shows you the whole
  place has nothing left to offer the player who picks it.
- **Crop the scale out of frame.** Nearest masses cut by both side edges, the
  canopy or facade leaving the top edge unseen. Grandeur comes from what does
  not fit.
- **Vertical relief.** Trail rising and falling, stairs, a ravine, a drop. A
  flat ground plane costs the panel most of its scale even when everything else
  is right.
- **Tall vertical composition**, roughly half of the target screen. The inner
  edge meets the other panel, so weight the composition toward the outer edge
  and leave a dark mass low in frame for the label.
- The two panels of a pair are judged **side by side at target size**, never
  individually. They must read as two different places and as one screen.

#### 10.8.3 Value bands at plate scale

Four bands is a character and icon rule. It exists so eight material fills read
as a flat woodcut at 300 px, and a panel has neither eight fills nor that size.

**Panels state six to eight bands.** Approved: six for Jungle, eight for Magic
Ruins. Below six the depth planes collapse into each other; above eight the
model starts shading within a hue and the woodcut read is gone.

#### 10.8.4 Depth without gradients

Atmospheric haze is a gradient and cannot be used. Panels build depth from
**overlapping flat planes, each one darker than the one in front, receding into
black.** Five planes is the working number.

This inverts the usual print convention, where distance goes pale. Dark
recession is what makes both panels read as a place that continues past what is
lit, and it is why the guide's earlier instinct — planes stepping lighter toward
the back — was wrong for this class.

State the furthest plane as almost gone: *a distant mossy stone shape almost
completely fading into the black*.

#### 10.8.5 Saturation by role

The panel palette splits by what a thing is doing, not by material:

- **Mass is low saturation.** Trunks, canopy, masonry, roots — the bulk of the
  frame, held subdued so it can carry the value structure.
- **Incident is wide-range.** Blooms, water, fungus, flame, spilled light — a
  small share of the area, permitted full chroma.

This is the 3.5 lever restated for environments and it is what stopped the
panels arriving as four-color prints. It also keeps 10.1's no-accent rule
intact: the saturated incidents are scattered and multi-hued, so none of them
reads as a character accent.

Scene light (10.2) still sets the panel's cast — teal-green for Jungle, violet
for Ruins — but at panel scale it is one hue among a range rather than a flat
field.

#### 10.8.6 Post-processing

**Panels do not take the section 6 pass.** The quantize step targets the
four-band ramp and would strip the extra bands and the incident chroma straight
out, which is the entire content of 10.8.3 and 10.8.5.

Panels take instead: the shared grain or paper overlay at the same settings as
everything else, and the area LUT. Nothing else. The overlay is what keeps a
panel in the same game as the screen it sits on.

#### 10.8.7 Approved prompts

Recorded verbatim as generated. The two were built differently and the
divergence is unresolved — see 10.8.8.

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

#### 10.8.8 Open items for this section

- **The two panels use different palette methods.** Ruins names six hues
  explicitly and closes with *all held to four values*; Jungle names no hues and
  instead states the saturation split of 10.8.5. Both worked. Before the next
  six panels, generate one variant each way for the same place and decide which
  is the house method, because eight panels built two ways will not read as a
  set.
- **Ruins asks for eight bands and then for four values in the same prompt.**
  The contradiction may be doing real work — the first clause buying interior
  modelling, the second holding the palette — or it may be inert. Test by
  removing the tail clause alone.
- **Counts are used heavily in Ruins** (forty flames, eight coils, twenty
  carvings) **and almost not at all in Jungle**. See amendment C4.
- Scene light hexes in 10.2 were specified for flat sky fields and no panel uses
  them as such. Decide whether the table now means "the panel's dominant cast"
  or stays a battle-stage spec with panels reading from it loosely.
- Remaining six panels unbuilt. Clockwork Spire and Iron Ledger inner city have
  no scene light assigned at all (10.2), and the inner city's white-plate
  problem (10.6) hits a panel harder than a stage, since a panel is mostly dark
  mass by construction.

---

## 11. Items, gear and reagents

> **Not yet written.** This whole section is missing and is the largest gap in the guide. Gear is a core loop (`Concept_Document.md` 3.3), and none of it has a visual spec.

### 11.1 Shared conventions

> **Not yet written.** Which value bands and slots items use, whether items carry an accent, the camera treatment (items are objects, not figures, so 4.2's composition tail does not apply), and the presentation angle.

### 11.2 Weapons, off-hands and boots

> **Not yet written.** One silhouette convention per equipment slot so an item is identifiable as a weapon or a boot at inventory-cell size before it is identified as which one.

### 11.3 Reagents

> **Not yet written.** Reagents are consumed and appear in kit text, so they need to be identifiable at very small size and in quantity. Decide whether they are icons (12) or objects (11) — they are currently neither.

### 11.4 Currencies and consumables

> **Not yet written.** Each currency in `Concept_Document.md` 3.3.2 needs one unmistakable shape, held to the icon rules rather than the item rules.

### 11.5 Rarity and gear-set signalling

> **Not yet written.** How rarity reads visually without a colored frame doing all the work, and how a gear set stays recognisable across three equipment slots. Note this competes with the champion accent system for the player's color vocabulary — decide the priority.

---

## 12. Icons

Icons are where the style either works or fails, because they are the smallest thing on screen.

### 12.1 Rules

- **Target size first.** Decide the pixel size (map nodes ~48–64 px, skill icons ~64–96 px) and judge every candidate at exactly that size, never at full resolution.
- **Drop to three values.**
- **Drop the material slot system.** At icon scale there is no room for eight fills. Icons use ink black, bone white, one mid neutral and the accent. The tinted band 1 of 2.2 does not apply at icon scale.
- **One idea per icon.** A single object, centered, filling the frame.
- **Silhouette must survive being filled black.**
- **Outline gets proportionally thicker**, not thinner, as size drops.
- **Node type icons carry no accent** — they are map furniture.

These rules and the pattern in 12.2 govern map nodes, status, currency and resource icons. **Active skill art does not follow them** — it was tried and failed (17), and it now has its own class in 12.4.

### 12.2 Prompt pattern

```
bold woodcut icon, very thick uniform black contour outline, flat color
fields, three values, hard-edged shadows, a single {SUBJECT} centered and
filling the frame, large simple shapes, minimal interior detail, no fine
linework, no small marks, readable at very small size, rendered in ink
black, bone white and one mid grey[, with {ACCENT} as the single flat accent
on {PLACEMENT}], plain flat background, no scenery.
```

This pattern predates section 5.1 and contradicts it: "no fine linework, no small marks, no scenery" are exclusions in a field with no negative prompt. Positive phrasings that were used instead during the skill pilot: *every mark as thick as the outline* and *isolated on a plain flat background of one uniform color*. Rewrite the pattern before the next icon batch.

### 12.3 Node icon subjects (Expeditions map)

Keep these to one unmistakable object each: Fight — crossed blades; Boss — a horned skull; Rest Stop — a campfire with three logs; Hint — an open eye; Gamble — a pair of dice; Escalate — an upward arrow through a broken ring.

### 12.4 Active skill art — the chiaroscuro print class

The largest art set in the game, one or more per skill across twenty Roles. Skill art is **not** built in the Lit Woodcut character style. It is built as a **chiaroscuro woodcut** — the sixteenth-century technique (Burgkmair, Ugo da Carpi) of printing one detailed black line block over two or three flat tone blocks.

The class was found by piloting three skills: Burning Bolas (Jester), Boarding Strike and Corsair's Reckoning (Tidal Corsair). All three were approved, and they read as prints from one workshop, which is the thing a skill set has to do.

#### 12.4.1 Why skill art left the icon rules

The first pilot put Burning Bolas through 12.1 and 12.2: three values, flat fields, large simple shapes, every mark as thick as the outline. All three variants came back too simple — flat color planes with no texture and no level of detail, reading as cartoon rather than woodcut (17).

The diagnosis: **the icon rules removed the carving.** A real woodcut gets its richness from the density and direction of cut marks, not from color or shading. Flat fields with no texture describe a woodcut with the cutting taken out, which is a vector cartoon.

Five print traditions were then generated on the same subject: Renaissance black-line, white-line wood engraving, chiaroscuro, ukiyo-e and expressionist. Chiaroscuro was chosen. It is also the closest to this guide's own foundations: its tone blocks *are* a small number of flat value bands, and its key block restores the "engraved structural linework" that the character block in 8.6 already asks for and the icon template dropped.

#### 12.4.2 What this class is exempt from

The third named exemption in the guide, after the overworld camera (10.4) and selection panels (10.8.1). Granted here and nowhere else:

- **Non-negotiables 1–3 and 6.** No thick uniform contour requirement, no four-band rule, no 15–20% accent budget, no perspective spec. Skill art is a framed illustration, not a battle element, and never composites against a champion.
- **Section 12.1 and 12.2 entirely.**
- **"Wear is shape, not texture" (5.5, 8.5)** as far as line work goes. Carved hatching and visible wood grain are the content of this class. The rule still holds for *asked-for grime* — dirt and stain words remain wasted budget.
- **Light from upper left.** Light may come from a source named in the scene — moonlight glinting on the blade, morning light behind a wave — as long as the source reads as belonging to it.
- **The quantize step of section 6.** See 12.4.5.

What still binds: no gradients in the tone blocks, one idea per piece, section 5's prompting method (positive phrasing, counts not adjectives, genre attractors), and the caster's accent (12.4.4).

#### 12.4.3 The technique block

Word for word in every skill prompt, closing it. The repetition is what makes three different subjects read as one set.

```
a detailed black key block with engraved hatching and contour lines
printed over two overlapping tone blocks in {TONE A} and {TONE B},
{HIGHLIGHTS} cut away to bare cream paper, slight registration offset
between blocks, visible wood grain in the tone blocks
```

And one phrase opening it: `chiaroscuro woodcut print,`

**The subject block** sits between the two and follows these conventions:

- **Subject convention: the tool in the act of the skill.** A weapon mid-thrust, a thrown object mid-flight, a summoned form mid-leap. Not the caster's portrait, and not an abstract effect symbol. Where the Role's kit names a concept (Corsair's Reckoning spends Sea and Steel stacks), let the subject *be* that concept — a dolphin of seawater carrying swords.
- **Motion on a diagonal or arc**, toward the right where there is a direction, matching the battle layout. Speed is shown as *curved gouge strokes trailing the arc*, never blur.
- **Partial figures are allowed.** A hand and a striped sleeve gripping the cutlass, the rest beyond the frame. The Role is signalled by a costume detail at the frame edge, not by a face.
- **Highlights are cut to paper.** Name what glows or gleams — flames, a blade edge, foam and spray — and cut it away to bare cream paper. This is where the "light" in the old prompts went.
- **Background is optional and sparse.** When present, it is carried by sparse cut lines and held in the darker tone so the subject stands forward. Bolas used a sky of horizontal cut lines; the Corsair pieces carry a ship's deck and a beach. See 12.4.7.
- **Count the elements that create density.** In Corsair's Reckoning the sword count is what drives line clutter; five was approved, three is the first cut if a variant tangles.
- **Transparency is replaced by breaking through.** Carved lines of a see-through form compete with the carved lines of what is inside it. Put objects *in* the form with their ends breaking out through its surface.

#### 12.4.4 Accent in the tone blocks

**One tone block carries the caster's accent family.** It stays a tone block — flat, sharing the print with the second tone — not a spot color. This is how 8.9's identity system reaches skill art.

The second tone is free, and is chosen for the scene: a warm/cool pair where the subject calls for one (Boarding Strike's moonlight teal against lantern amber).

Status in the pilot: the Corsair pieces carry sea teal explicitly. Burning Bolas used warm ochre and deep rust, which sits near the Jester's saffron but was not specified as the accent. Regenerate Bolas with saffron named in one block before treating the rule as confirmed.

#### 12.4.5 Post-processing

Skill art takes **the shared overlay only**. The quantize step would strip the hatching and tone-block range that are the whole class, as it would for panels (10.8.6). The area LUT does not apply: skill art is shown in UI, not in an area's scene light.

#### 12.4.6 Approved prompts

Recorded verbatim as generated. These are the reference set; a new piece is judged side by side against all three.

**Burning Bolas (Jester)**

```
chiaroscuro woodcut print, burning bolas thrown through the air in a spinning arc toward the right, two heavy iron balls joined by a thick twisted rope, each ball wreathed in curling flames, a detailed black key block with engraved hatching and contour lines printed over two overlapping tone blocks in warm ochre and deep rust, highlights cut away to bare cream paper, flames glowing where the paper shows through, curved gouge strokes trailing the arc, slight registration offset between blocks, visible wood grain in the tone blocks
```

**Boarding Strike (Tidal Corsair)**

```
chiaroscuro woodcut print, a curved pirate cutlass thrust in from the left edge on a hard diagonal across the frame toward the upper right, a broad crescent-shaped blade ending in a sharp point, a cupped guard of pierced metal around the grip, a woman's hand in a firm grip on the hilt, only her forearm visible in a sleeve of bold horizontal stripes, the rest of her beyond the frame, a detailed black key block with engraved hatching and contour lines printed over two overlapping tone blocks in deep sea teal and warm lantern amber, the blade's edge and point cut away to bare cream paper as a gleam of moonlight, behind it a ship's deck at night carved in sparse lines, rigging, a mast and two hanging lanterns glowing amber, a moonlit sea of horizontal cut lines, the background held in the darker tone so the blade stands forward, slight registration offset between blocks, visible wood grain in the tone blocks
```

**Corsair's Reckoning (Tidal Corsair)**

```
chiaroscuro woodcut print, a dolphin formed entirely of seawater leaping out of a breaking wave toward the viewer, its body built from curling carved current lines and swirling eddies, five cutlasses and sabres caught inside the water at different angles, their hilts and blade tips breaking out through its back and flanks, a great wave curling behind it with claw-like foam crests, a detailed black key block with engraved hatching and contour lines printed over two overlapping tone blocks in sea teal and pale sand ochre, foam, spray and the sword edges cut away to bare cream paper, a strip of beach and distant sea below in sparse horizontal cut lines, morning light from behind the wave, flying droplets as small gouged marks, slight registration offset between blocks, visible wood grain in the tone blocks
```

The Bolas prompt predates the fixed technique block and words it slightly differently (*highlights cut away* rather than naming them, and the trail phrase after the block). Its result was approved, so it is kept as generated; new prompts use the 12.4.3 order.

#### 12.4.7 Open items for this class

- **Display size is unverified.** The pilot was judged at full resolution. Skill art shows in the skill bar and tooltips; decide the sizes, then check whether the chiaroscuro structure survives where the hatching does not. If it fails at the skill-bar size, the likely answer is two assets per skill — this illustration for tooltips and cards, and a cropped or simplified icon for the bar — rather than a return to 12.1.
- **Background convention.** Bolas has almost none; both Corsair pieces carry a scene. Decide one convention for the set, or state when a scene is earned.
- **Accent rule on a clashing element.** The pilot never forced a conflict: Jester fire sits near saffron, Corsair sea is teal. Test a skill whose element fights its Role's accent — a Sorcerer fire skill under cobalt — to settle whether element color or caster accent wins the accent block.
- **Status icon collision.** Burning (12.5) will want flames too. The status icon must not look like a crop of the Bolas art.
- **Relationship to VFX (14).** The in-battle effect for a skill is in the Lit Woodcut battle style; the skill art is not. Decide whether that split is accepted, or whether VFX borrow anything from the print (gouge-stroke motion, paper-cut highlights).

### 12.5 Status effect icons

> **Not yet written.** Eight simultaneous slots (`Concept_Document.md` 1.1.4), so these are read in a row at the smallest size in the game. Needs a buff/debuff distinction that is not color alone, a stack-count treatment, and a shared shape language across the status list in 3.2.3.

### 12.6 Passive and identity buttons

> **Not yet written.** Passive skills, grafting, thread stance switching. These are persistent UI affordances rather than one-shot icons and may belong with 13.1 instead — decide which.

### 12.7 Item and reagent icons

> **Not yet written.** The inventory-cell rendering of section 11. State whether these are separate assets from the item art or downscales of it.

### 12.8 Currency and resource icons

> **Not yet written.** Energy, currencies, experience. Read constantly in HUD chrome, so they must survive at the smallest size of all and must not compete with status icons for attention.

---

## 13. UI art

> **Not yet written.** Also entirely missing. The style has strong opinions (thick outline, four values, no gradients) that a default engine UI will contradict on the first screen.

### 13.1 Frames, panels and buttons

> **Not yet written.** Outline weight at UI scale, corner treatment, panel fill values, button states (idle, pressed, disabled), and whether UI chrome sits inside the four-band ramp or is exempt.

### 13.2 Typography

> **Not yet written.** Typeface choice for headers and body, and whether numbers in combat get their own treatment. A woodcut style is unusually sensitive to this — a neutral UI sans will read as a different game.

### 13.3 Combat HUD

> **Not yet written.** Health and resource bars, turn order, damage numbers, and the Echo sequence presentation required by `Concept_Document.md` 1.1.5. Damage numbers carry the caster's accent (8.9), so they are style assets, not engine defaults.

#### 13.3.1 Turn bar zones — the receding class

Zones (`Concept_Document.md` 3.2.4.1) sit in sections of the turn bar, and character markers move through them. The zone has to say *what* occupies a section and *whose* it is, while the markers stay the first thing the player reads. Every rule in this class follows from that ranking: **characters lead, zones recede.**

Piloted on The Gilded Deck (Tidal Corsair, placed by Corsair's Reckoning). Its assets were implemented in the engine and approved.

##### What is an asset and what is the engine

A zone is assembled in Godot from a small number of generated sprites. Only the sprites are art assets.

| Layer (back to front) | Made in | Gilded Deck example |
|---|---|---|
| Tint field | Engine — `ColorRect` or shader, alpha set in engine | Pale blue field over the whole section |
| Particles | Asset sprites, driven by a particle node | Wave crests drifting within the section |
| Centerpiece | Asset sprite, animated by tween | Pirate ship rocking back and forth |
| Character markers | Existing HUD | Always in front of every zone layer |

Transparency is always applied in the engine, never baked into the asset. The asset is delivered opaque on a key color and keyed out (see *Generation* below).

##### Dimensions

- **Turn bar section:** 248 × 80 px. Height is the binding limit.
- **Centerpiece:** around 100 × 60 px. Leave vertical headroom for motion — a 6–8° rock adds several pixels of height, and a centerpiece that fits 80 px when level will clip when tilted. Generate in a landscape aspect (3:2) so the subject comes out wide and low.
- **Particles:** 20–32 px each.
- At these sizes a carved line lands at about one pixel. Keep interior line counts to three or four on the centerpiece and one or two per particle.

##### What this class is exempt from

- **Non-negotiable 1, the ink black outline.** Outlines are drawn in **a darker shade of each fill color**. This keeps the woodcut contour while removing the heaviest attention-grabbing mark in the style.
- **Non-negotiable 2, four value bands.** Fills are soft, muted and low in contrast. Flat fields and no gradients still hold.
- **Non-negotiable 3, the accent budget.** The Role's accent family may be the main body color, because the whole zone is already at low opacity.
- **Light from upper left (4.1).** The objects are too small for a cast shadow to matter. Keep any shading flat and minimal.
- **14.1's black outline and black/white generation background**, for zone particles.

What still binds: **orthographic pure side profile** (4.1), one idea per sprite, flat fields, and section 5's prompting method.

##### Color

- **The palette ties to the placing Role.** The Gilded Deck's hull is sea teal, the Corsair's accent family. This keeps zones inside the existing color-identity system rather than starting a separate one.
- **One named detail carries the zone's identity.** For the Gilded Deck it is the gold gilded trim on the rail and stern — the "Gilded" in the name — and nothing else competes with it.
- **Particles take a simple two-color scheme** that fits the element: soft sea blue bodies with a white foam lip.
- **The tint field is an engine value.** Its color and alpha are tuned live in Godot. What the tint *means* is an open decision (see below).

##### Generation

- **Key color: flat magenta.** It appears in neither the Gilded Deck's teal, gold and off-white nor its blue and white waves. If magenta fringes into light edges (foam, sails), switch to plain bright green. Use a transparent-background output instead if the model offers one.
- **Particles as a sheet.** Ask for five separate shapes spaced apart in a row. The sheet slices cleanly and gives the particle system variety.
- **Centerpiece with a clean pivot edge.** Anything that rocks or bobs needs a flat, straight edge at its pivot — the Gilded Deck's hull is cut straight along the waterline. Set the rotation pivot at the waterline in the engine, not at the sprite's center.
- **Post-processing.** Key out, then downscale to target. The quantize step and the accent correction of section 6 do not apply, since this class is not built on the four-band ramp. The area LUT does not apply either, because the turn bar is HUD and does not sit in scene light.

##### Approved prompts

The Gilded Deck, recorded as generated.

**Ship (centerpiece)**

```
woodcut print style illustration of a small pirate ship in pure side profile facing right, a wide low hull with two masts and three square sails in weathered off-white canvas, hull of deep sea teal painted wood with one band of gold gilded trim along the rail and a gilded ornament on the stern, one small teal flag on the main mast, the hull cut straight and flat along the waterline at the bottom, flat color fields with three or four carved lines for planks and sail folds, soft muted colors, gentle low contrast, outlines drawn in darker shades of each color, large simple shapes readable at very small size, the whole ship centered, isolated on a plain flat solid magenta background
```

**Waves (particle sheet)**

```
woodcut print style illustration, a sheet of five small separate curling wave crests spaced apart in a row, each a different shape, bodies in soft sea blue with a white foam lip along each curl, one or two carved lines following each curl, flat color fields, outlines drawn in a darker shade of blue, soft muted colors, large simple shapes readable at very small size, isolated on a plain flat solid magenta background
```

A single-ink version of both (dark ink on white, recolored in the engine) was tried first and not chosen; see 17.

##### Open items for this class

- **Lore family language.** Every zone belongs to the order, unstable or momentum family, and that family defines its visual language (`Concept_Document.md` 3.2.4.1). The Gilded Deck's family has not been recorded here, and neither has which of its choices are family language (field treatment, how particles move) and which belong to this zone alone (the ship). Decide before the second zone of that family, or the first zone becomes the family by accident.
- **What the tint means.** The Deck's tint is pale blue. Either the tint derives from the placing Role's accent — keeping one color-identity system — or it signals ally versus enemy ownership, which is a second system and needs the explicit decision the concept document asks for.
- **Enemy-placed zones.** Enemies place zones too. Decide whether ownership is shown at all, and if so whether by tint, a marker, or nothing.
- **Charge readout.** A zone holds charges. Whether remaining charges show as a number, as particle density, or both is not decided.
- **Arrival and dissipation.** How a zone appears when placed and leaves when its last charge is consumed. Engine animation, but it should be one convention across all zones.

### 13.4 Layout and screen inventory

> **Not yet written.** One entry per screen, each with its grey-box (4.3) before any art is generated.

---

## 14. Effects and VFX

### 14.1 Rules

Effects are the one place the accent may exceed its budget, because they are transient. Everything else holds.

- **Same thick black outline**, even on magic. An unlined glow does not belong to this game.
- **Shape over glow.** Radiating lines, chunky sparks, solid smoke masses, cracked rings. Not soft bloom.
- **Effects inherit the caster's accent color.** This is the single strongest reinforcement of the identity color system.
- Generate on **plain black or plain white**, keyed out afterward, never on a scene.
- **Turn bar zone particles are not VFX** for these rules. They follow 13.3.1: tonal outlines, muted fills, magenta key.

### 14.2 Where the juice actually comes from

Most perceived impact is code, not art, and costs far less than more VFX assets:

- Whole-sprite squash and stretch via Tween on `scale`, plus `skew`
- Hit-flash shader, white or the accent color, two frames
- Hitstop of 60–100 ms, screen shake
- Idle bob of 2–3 px plus 1–2% scale on a long sine

Build this layer before commissioning more effect art.

### 14.3 Status effect visual language

> **Not yet written.** A status is on a target for several rounds and must be visible on the sprite, not only in the status bar. Needs a persistent-effect vocabulary distinct from the transient hit effects above.

### 14.4 Impact and cascade library

> **Not yet written.** The burst resolves as a visible sequence of Echoes (`Concept_Document.md` 1.1.5), which is a specific VFX requirement: escalating tempo and magnitude across many resolutions. Needs a shared impact set and a rule for how an Echo differs visually from the action that spawned it.

---

## 15. Animation

Cutout skeletal animation suits this style — flat fields and hard outlines survive being chopped apart.

- **Give every cut piece its own closed black outline.** Half-committing, where some edges are lined and some are raw, is the failure mode.
- **Cut with generous overlap**, not at the joint. Round the end of each limb piece so rotation sweeps inside the shape.
- **Three-quarter view costs extra work**: the far arm and leg are occluded and must be redrawn, plus whatever sits behind each piece.
- **Sprite2D on Bone2D** for rigid limbs. Polygon2D skinned to Skeleton2D only for genuinely soft things (tendrils, coat hems).
- **Keep the eyes on their own layer.** They are hand-placed and they are the first thing that breaks when a head piece rotates.

**Do the cheap layer first** (section 14.2). At 300 px on a phone, whole-sprite squash/stretch plus hit-flash plus hitstop delivers most of the perceived quality.

**Middle option:** generate 3–4 pose variants per character and hard-cut between them, no tweening. Limited animation is period-correct, hides a multitude of sins, and plays better with generated art than rigging does.

---

## 16. Marketing and out-of-game art

> **Not yet written.** Store capsules, screenshots, wordmark and key art are consumed by players and fall under the same disclosure obligation as in-game art (18). They also break the composition tail in 4.2 — a capsule is a composition, not an isolated figure — so they need their own rules rather than an exception granted case by case.

### 16.1 Logo and wordmark

> **Not yet written.** Studio name is settled; the wordmark treatment is not.

### 16.2 Store capsules and screenshots

> **Not yet written.** Sizes, which champions appear, and whether capsule art is generated or composited from approved assets.

---

# Part III — Record and process

---

## 17. Rejected directions

Recorded so they are not retried. Each of these was generated and judged, not reasoned about.

- **Enlarged head plus enlarged eyes.** Moving both dials at once is the cartoon recipe. The lit face was the fix for distance; the proportions were not, and changing them read as goofy.
- **Bone white eyes glowing out of a shadowed upper face.** A horror device. Pushed the tone further toward menacing, which was the opposite of the goal.
- **Bloodmage as a pale nobleman in a high-collared coat.** Landed on Dracula immediately, cape and fangs included. See 5.3.
- **Bloodmage as a frail wilderness outcast.** Read as an NPC. Low status is what "shunned" looks like, and no amount of gear fixes it.
- **Bloodmage as a composed sorcerer in bone regalia.** The overcorrection from frail. Regal, clean, and no longer transgressive.
- **Cultist in torn strips with a bare chest and a notched blade.** Reads as a barbarian, and it was also four counted groups deep.
- **Cultist in a plain working coat and flat cap.** Taking "hides from the Ledger" literally removed all fantasy content and left nothing a player would want to field.
- **Jester with a soft floppy cap, wide grin and a wiry build.** Cartoon. `wiry` shrinks the body and makes the head read as oversized.
- **Sorcerer as a field surveyor in a travel coat, gaiters and pack roll.** Competent and legible, and completely bland — modern hiking gear with no fantasy content, and the staff came back as a plain walking pole. Fleeing the wizard basin with travel vocabulary lands in the outdoorsman basin.
- **Sorcerer with hollow cheeks, shelf brow, hooked nose and a hard-set jaw.** Four nouns from one cluster, no stated age: returned the model's default forty-year-old handsome man, indistinguishable from the other male heads in the set.
- **Skill art on the flat icon rules (12.1–12.2).** Burning Bolas generated three ways — three values, flat fields, large simple shapes. All three came back too simple, with no level of detail, and read as cartoon. The rules had removed the carved line that makes woodcut rich. Replaced by the chiaroscuro class in 12.4.
- **Zone art as single-ink shapes.** Gilded Deck ship and waves as one-color woodcut silhouettes, recolored in the engine by `modulate`. Technically flexible, but the result lacked the color the zone needed — waves are expected to be blue and white and the ship colored. Replaced by muted multi-color fills with tonal outlines (13.3.1).
- **Skill art in four other print traditions.** Renaissance black-line, white-line wood engraving, ukiyo-e and expressionist woodcut were generated on the Bolas subject alongside chiaroscuro. Not failures, but chiaroscuro was clearly best and is the one closest to this guide's flat-band foundations. Revisit only if chiaroscuro fails at display size.
- **Desaturated garment main as an unwritten default.** Not a generation failure but a documentation one — six characters were built on a rule nobody had written, and the roster came out as grades of beige with one muted accent each. See 3.5.
- **Plague Doctor with historically accurate props.** A straight lancet-tipped cane, a hand bellows and a chest rack of vials. Legible, but clean, mundane and with no fantasy content; the cane was the least interesting shape in the figure, and the vial rack duplicated the Alchemist's chest. This is the case that produced the 8.1 rule on elements from outside reality.
- **Plague Doctor with a hat, an insect stinger and a chest seed-pod.** Not a failure — the second pass was strong and proved the 8.1 rule — but superseded. A woman in her fifties did not fit the intended character, the chest pod still sat in the region the Alchemist owns, and smoke from beak vents split the kit across two objects. Replaced by the version in 8.8.1. The stinger remains a good weapon for a future Role from the same jungle.

---

## 18. Operational notes

**Lock the model and settings.** Same Leonardo model, same Style Reference / Elements, same generation settings across the whole set. Record them here once chosen. Changing model mid-roster is the single fastest way to break cohesion.

**Pass and record prompts whole.** A subject block sent without the general block in front of it loses the entire woodcut style — this happened once on the Plague Doctor and produced an unrelated image. Every prompt handed over for generation, and every prompt recorded as approved, includes the general block in full. Where a reference example abbreviates it as `[GENERAL BLOCK]`, expand it before use.

**Composite early.** Perspective and value problems are obvious in a composite and nearly invisible when looking at assets one at a time in a browser tab. Never accept a character without dropping it into the battle scene next to one already approved.

**Document ownership.** This guide owns style. `Concept_Document.md` section 7 has been reduced to a pointer at it plus the game-facing facts style depends on; when the two disagree, this guide is correct and the concept document is stale. Do not restate slot tables, accent hexes or prompt blocks in the concept document again — the last duplication drifted in three places before it was caught.

**Steam disclosure.** Valve requires disclosure of AI-generated content that ships with the game and is consumed by players, including in-game art and store-page marketing. AI dev tools used behind the scenes are exempt under the January 2026 rewrite. Write the disclosure as the public-facing document it is — it appears on the store page.

**Commercial terms.** Confirm the Leonardo plan tier grants commercial rights and the export resolution needed before building further on this pipeline.

---

## 19. Open decisions

Collected so they are visible in one place rather than buried in the sections that raise them.

- **The pre-lever five.** Whether the levers are a requirement or a permission, and what happens to the five characters approved under the old arithmetic. See 3.5; act on it at six characters rather than at fifteen.
- **Approved Roles without an element from outside reality.** Only the Architect and the Plague Doctor clearly carry one. The rest of the approved roster predates the 8.1 rule and either gets a revised tool or focal element or carries a visible split — the same decision as the pre-lever five, and cheapest to settle alongside it.
- **Warlord accent.** `#6B7A88` is a neutral, not an accent. Either it becomes a real color or this Role is declared the drab one on purpose (8.9.1).
- **Clockwork Spire scene light.** Unassigned for both variants (10.2, 10.6.2).
- **The white inner city.** A light-dominant environment against figures that are half band 1. Either the midband keeps committed darks or the character rules bend for one variant (10.6).
- **Overworld camera.** The one exemption from section 4 in the whole guide. Vista or high-above, one convention or per area (10.4.1).
- **One POI language or two.** The overview screens (10.4.2) and the Adventure map (10.7.2) both need clickable points with states. Answering them separately teaches the player two vocabularies.
- **Model and settings lock.** Not yet recorded (18).
- **Rarity colors versus accent colors.** Two color-identity systems competing for the same player attention (11.5).
- **Skill art display size.** One illustration per skill or two assets (tooltip art plus bar icon), decided once the skill-bar size is known (12.4.7).
- **Element color or caster accent** in the skill art accent block, when the two clash (12.4.7).
- **Zone tint meaning.** Caster accent or ally/enemy ownership (13.3.1).
- **Zone lore family language.** Which Gilded Deck choices belong to its family and which to the zone alone (13.3.1).
