# Plan: Audio Foundation

The project has `Master`, `Music` and `Sound Effects` buses (`default_bus_layout.tres`) with
persisted volumes (`Settings`, `Technical_Design_Document.md` 3.4), but nothing plays audio.
This plan adds the playback layer every later sound rides on: one autoload that plays music
and sound effects, a `SoundCue` resource that any owner (a button, a status effect, a
character, an effect scene, a hub) exports, Adventure music per `Concept_Document.md` 5.1.1,
and a reusable button-sound component.

Skill effects and the battle presentation timeline are separate plans. This one supplies what
they need from audio: many simultaneous sounds, loops that are started and stopped by handle,
per-cue limits, and a per-play pitch argument.

## Conventions

- **Cues, not raw streams.** Code plays a `SoundCue`, never an `AudioStream` directly. Owners
  hold typed `@export var x: SoundCue` fields, so no sound is looked up by string.
- **Variation lives in the stream.** A cue with variants or pitch/volume spread uses Godot's
  `AudioStreamRandomizer` as its stream. No custom randomization code.
- **All sound is non-positional stereo.**
- **Vocal sounds are sound effects.** Grunts, barks and hurt sounds are non-verbal and play
  on the `Sound Effects` bus.
- **One area, one music track.** Music always loops.
- **Files:** scripts in `Scripts/Audio/`, cue and profile resources in `Data/Sound_Cues/`,
  audio in `Assets/Champ_Collector/Sound/` (existing `Music/` and `Sound_Effects/`).

## Steps

### 1. `SoundCue` resource and playback rules
`SoundCue` (`Scripts/Audio/sound_cue.gd`, `extends Resource`):
- `stream: AudioStream`
- `bus: StringName = &"Sound Effects"`
- `volume_db: float = 0.0`
- `maximum_simultaneous: int` — instances of this cue playing at once; a request beyond it
  is dropped. `0` means unlimited.
- `minimum_interval: float` — seconds; a request sooner than this after the cue's previous
  start is dropped.

`SoundPlaybackRules` (`Scripts/Audio/sound_playback_rules.gd`, static functions only, no
nodes):
- `ShouldPlay(cue, active_count, seconds_since_last_start) -> bool`
- `ChoosePlayer(busy: Array[bool], looping: Array[bool], start_times: Array[float]) -> int` —
  the first idle player; with none idle, the oldest non-looping one is stolen; `-1` if every
  player is looping.

Tests: `Tests/unit/test_sound_playback_rules.gd` covers the limit, the interval, idle-first
selection, oldest-steal, and loops never being stolen.

### 2. `AudioHandler` autoload
`Scripts/Audio/audio_handler.gd`, `class_name AudioHandler`, registered as `Audio_Handler`.
The key differs from the class name for the same reason as `Game_Settings`/`Settings`.

- In `_ready`, creates a fixed pool of `AudioStreamPlayer`s as its own children. These are
  never freed and never added to afterwards. The pool size is a constant.
- `Play(cue: SoundCue, pitch_scale: float = 1.0) -> void` — one-shot.
- `PlayLoop(cue: SoundCue) -> int` returns a handle (`-1` if refused);
  `StopLoop(handle: int, fade_seconds: float = 0.0) -> void`. A looping player is exempt from
  stealing until stopped. A stale handle is a no-op.
- Each request goes through `SoundPlaybackRules`. The handler tracks per-cue active counts
  and last start times. A `null` cue or a cue with a `null` stream is a silent no-op, so an
  unassigned export costs nothing.

Because the players belong to the autoload, a click sound survives the scene change it
triggers.

### 3. Music
- Two `AudioStreamPlayer`s on the `Music` bus for crossfades, also owned by `AudioHandler`.
  `PlayMusic(track: AudioStream, fade_seconds: float)` crossfades. Requesting the track
  that is already playing is a no-op, so the music continues across scene changes. A `null`
  track fades to silence.
- `AdventureData.music_track: AudioStream`. Both Reclaimed City adventures, Jungle and
  Magic Ruins, get Swamp of Digeridoos.
- `Main_Instance._deferred_change_scene` calls `PlayMusic` after `Init`. It passes the
  adventure's track when `p_context._adventure_state` is set, and `null` otherwise. So music
  plays from the Adventure map through pre-battle, battle and post-battle, and fades out on
  leaving the Adventure.
- Set `loop=true` in the `.import` of every music track.

### 4. Button sounds
- `ButtonSoundProfile` (`Scripts/Audio/button_sound_profile.gd`, `extends Resource`):
  `hover_cue: SoundCue`, `press_cue: SoundCue`. Profiles are shared resources, so changing a
  profile changes every button that uses it.
- `ButtonSounds` (`Scripts/Audio/button_sounds.gd`, `extends Node`): a child node of any
  `BaseButton`, with `@export var profile: ButtonSoundProfile`. In `_ready` it connects its
  parent's `mouse_entered` and `focus_entered` to the hover cue and `pressed` to the press
  cue. A disabled parent stays silent.
- `Data/Sound_Cues/ui_hover_tick.tres` (stream `soft_tick.wav`, a small `minimum_interval`)
  and `Data/Sound_Cues/button_standard.tres` (hover: the tick; press: none until a press sound
  exists).
- The user adds `ButtonSounds` to buttons in the editor, one button at a time. A repeated-row
  scene (a skill button, a party slot) carries it once in its own `.tscn`.

### 5. Documentation
- `Technical_Design_Document.md` 3: add `Audio_Handler` to the autoload listing and a 3.6
  subsection covering the pool, the cue rules, the loop handles, music on scene change, and
  `ButtonSounds`.
- `Concept_Document.md`: add the rule that vocal sounds are non-verbal sound effects, under
  the section that owns presentation.
- Delete this plan per `Documents/Plans/README.md`.

## Watch for

- Music must start after `Init` and use the incoming context. `_adventure_state` has to be
  cleared once the player leaves the Adventure, or the music never stops. Verify this before
  relying on it.
- A menu that calls `grab_focus` when it opens fires its button's hover cue.
- A headless run uses the dummy audio driver. Tests cover the rules class only, never
  playback.
- `gdlint Scripts/` passes. No plan or step references in code comments.
