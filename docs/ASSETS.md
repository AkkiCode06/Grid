# Asset manifest

Everything resolves through `AssetResolver` by name — drop files in with these
exact names and they're picked up automatically, no code changes. Until an
asset exists, views fall back to gradient backdrops and a streak-flyby
placeholder.

## Specs

| Type | Format | Details |
| --- | --- | --- |
| Backdrop | PNG/HEIC in `Assets.xcassets` | 9:16 portrait, ≥1179×2556 (fills the racing screen) |
| Flyby clip | `.mp4` (HEVC) bundled in the app target | 9:16 portrait full-frame, 2–4 s, muted, 30/60 fps, keep ≤3 MB each |
| SFX (optional) | `.m4a`/`.mp3` bundled | `whoosh`, `stamp`, `light`, `lightsout` |

Flyby clips are shown full-bleed over the backdrop with `.resizeAspectFill`,
so shoot/generate them as the **same grandstand view as the backdrop, with a
car passing through** — the cut between still backdrop and clip should be
invisible (same framing, same light).

## Naming convention

- Backdrop: `<circuitID>_<seatID>_backdrop`
- Clips: `<circuitID>_<seatID>_flyby1` … `flyby3` (`.mp4`)

Circuit IDs: `monteCarlo`, `marina`, `midlands`, `hachi`, `ardennes`, `custom`
Seat IDs: `mainStraight`, `hairpin`, `chicane`

## Shot list (18 backdrops + 54 clips)

Seat angle briefs — same for every circuit, flavoured by its setting:

- **mainStraight** — grandstand head-on view of a straight; flybys are fast
  left-to-right blurs at full speed
- **hairpin** — elevated view over a tight corner; flybys are slow-in,
  rotate, hard accelerate out
- **chicane** — low trackside view of a left-right flick; flybys snap
  direction mid-frame

| Circuit | Setting flavour | Files |
| --- | --- | --- |
| `monteCarlo` (25 min) | Sunset harbour street circuit, yachts, armco barriers | `monteCarlo_{seat}_backdrop` + 3 clips each |
| `marina` (45 min) | Night race, floodlights, marina + hotel glow | `marina_{seat}_backdrop` + 3 clips each |
| `midlands` (60 min) | Overcast British daytime, green infield, old grandstands | `midlands_{seat}_backdrop` + 3 clips each |
| `hachi` (90 min) | Japanese daytime, figure-eight character, ferris wheel silhouette | `hachi_{seat}_backdrop` + 3 clips each |
| `ardennes` (120 min) | Misty forest, elevation change, spruce treeline | `ardennes_{seat}_backdrop` + 3 clips each |
| `custom` | Anonymous test facility, grey sky, cones + timing boards | `custom_{seat}_backdrop` + 3 clips each |

**Priority order if generating in batches:** the two free circuits first
(`monteCarlo`, `midlands`), mainStraight seat first — that's the default
selection users see.

**Legal:** generic open-wheel car silhouettes only — no team liveries,
sponsor logos, driver helmets, or official circuit signage/branding in any
generated frame.
