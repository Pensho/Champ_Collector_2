# Plan: Battle Presentation Split

`battle.gd` turns every result kind into visuals, starts every effect scene and resolves every
anchor, on top of turn flow and input. Each boss mechanic or trait effect grows it; the Hue-Eater
pushed it past the 1200-line lint limit, raised to 1250 in `gdlintrc` to fit. This plan moves
presentation out so new bosses and mechanics land in their own classes.

## Steps

### 1. Map the presentation surface
List what in `battle.gd` is presentation (`PresentResult`, the `_Present*` family, `_AnchorPoint`,
`_FieldCenter`, `_InstanceStart`, `_ReservePresentationPool`, echo and free-basic playback, impact
reactions) and what each reads from `Battle`. Agree the class boundaries with the user before code.

### 2. Extract
Move the agreed groups into their own classes, leaving `Battle` the turn flow, input and the state
those classes read. Behaviour is unchanged; the suite stays green throughout.

### 3. Restore the limit
Lower `max-file-lines` in `gdlintrc` back to 1200.

## Watch for

- `Battle` keeps no presentation logic a new trait effect or boss would need to extend.
- Results applied as they are produced (`_ChangesTurnBar`) keep that ordering.
