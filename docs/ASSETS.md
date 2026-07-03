# Asset manifest

Everything resolves through `AssetResolver` by name — drop files in with these
exact names and they're picked up automatically, no code changes. Until an
asset exists, views fall back to gradient backdrops and a streak-flyby
placeholder.

**Concept:** the user is a team member standing in the paddock / on the pit
wall. One backdrop per circuit (shared by all teams), and flyby clips show
mixed generic cars passing — teams are an identity/livery layer in the UI,
not separate footage.

## Totals: 6 backdrops + 30 clips

## Specs

| Type | Format | Details |
| --- | --- | --- |
| Backdrop | PNG/HEIC in `Assets.xcassets` | 9:16 portrait, ≥1179×2556 (fills the racing screen) |
| Flyby clip | `.mp4` (HEVC) bundled in the app target | 9:16 portrait full-frame, 2–4 s, muted, 30/60 fps, keep ≤3 MB each |
| SFX (optional) | `.m4a`/`.mp3` bundled | `whoosh`, `stamp`, `light`, `lightsout` |

Flyby clips are shown full-bleed over the backdrop with `.resizeAspectFill`,
so generate each clip **from its backdrop still (image-to-video)** — same
framing, same light — so the cut between still and clip is invisible.

## Naming convention

- Backdrop: `<circuitID>_paddock_backdrop`
- Clips: `<circuitID>_paddock_flyby1` … `flyby5` (`.mp4`)

Circuit IDs: `monteCarlo`, `marina`, `midlands`, `hachi`, `ardennes`, `custom`

## Scene briefs (one per circuit)

All from the same vantage: **standing at the pit wall inside the paddock,
looking across the wall onto the main straight**, portrait framing, track
filling the lower half, sky/setting filling the top.

| Circuit | Setting flavour |
| --- | --- |
| `monteCarlo` (25 min) | Golden-hour harbour street circuit; yachts and apartment blocks beyond the armco; warm sunset haze |
| `marina` (45 min) | Night race under floodlights; futuristic hotel glow and marina lights; deep violet sky |
| `midlands` (60 min) | Overcast British afternoon; green infield, old grandstands on the far side; flat grey-blue light |
| `hachi` (90 min) | Clear Japanese day; distant ferris wheel silhouette; clean bright light |
| `ardennes` (120 min) | Misty forest circuit; spruce treeline and elevation beyond the straight; cool green fog |
| `custom` | Anonymous test facility; grey sky, cones, timing boards, empty grandstand scaffolding |

## Clip motion briefs (5 per circuit, from the same backdrop still)

1. Single car blasts past left → right at full speed, heavy motion blur, heat haze
2. Single car blasts past right → left, slightly different speed feel
3. Two cars nose-to-tail flash past
4. Car peels off the straight into the pit lane, slows past camera (paddock flavour)
5. Distant car crosses on the far side of the straight, subtle — a "quiet" flyby

**Priority order if generating in batches:** free circuits first
(`monteCarlo`, `midlands`), clips 1–2 first — those carry most sessions.

**Legal:** generic open-wheel car silhouettes only — no team liveries that
copy real teams, no sponsor logos, no text, no driver helmets with real
designs, no official circuit signage/branding in any generated frame.
