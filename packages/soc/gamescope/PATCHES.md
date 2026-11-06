# gamescope patches

What this package carries and why, one entry per patch. How each patch works is in its header.

## Base

Valve `3.16.31` (f6916aa, 2026-09-27)

Launch: logical landscape -W/-H, rotation autodetected from the primary plane (scanout on
sm8550 via kernel 0066, composite on sm8250); POCKNIX_PANEL_ROTATE_SHADER=1 forces
--force-composition-rotation for panels past the 1088-line rotator cap.

Last rebased: 2026-10-22 (0014/0015 native Wayland windows: focus, touch).

## Carried

### Input

- **0001** Touch works when gamescope runs nested: the Wayland backend wires up wl_touch.
  Source: ROCKNIX set.
- **0006** The gamepad cursor sprite no longer freezes when the cursor is driven through XTest.
  Source: ROCKNIX set.
- **0015** Android under Lepton gets real taps and swipes: a touch that goes down on an xdg-shell
  window passes through as wl_touch instead of Steam's pointer emulation, and keeps that mode
  until it lifts. X11 windows keep Steam's mode. Source: armada 0025, code verbatim, hunks
  re-anchored.

### Display and planes

- **0004** GAMESCOPE_FAKE_OUTPUT_MM sets a custom display physical size. Source: ROCKNIX set.
- **0012** A plane layout msm has no free hardware pipe for (test commit -ENODEV) counts as no fit
  instead of aborting. Source: sunshineinabox.
- **0013** The Steam overlay and MangoHud stay above the game: libliftoff sets a plane's mutable
  zpos from its layer, so msm's several primary planes (all zpos 0, else stacked by plane id)
  follow layer order. Source: ROCKNIX 0020 + 0022, verbatim.

### Frame pacing and colour

- **0009** FSR resolves to SGSR on SDR RGB, since the Steam Deck client offers no SGSR entry.
  The `fsr_means_sgsr` convar (default on) restores plain FSR. Source: ours.
- **0010** A frame that misses its vblank no longer waits a whole extra period: the fixed-refresh
  limiter releases frames by elapsed time since the last latch instead of a vblank-count
  divisor. The `limiter_use_elapsed_time` convar (default on) restores the divisor.
  Source: armada 0027.
- **0011** The composite skips identity colour LUTs, the larger half of sm8250's every-frame
  composite (the shaper + 3D LUT taps). Steam's 0.5 gamut wideness counts as native where planes
  cannot be colour managed (new `IBackend::SupportsPlaneColorManagement`), and a virtual white
  within 0.001 xy of the display's is no override. The `color_mgmt_skip_identity_luts` and
  `color_mgmt_native_gamut_without_plane_cm` convars (default on) turn each half off.
  Trap: a raw shaper/3D LUT override is never treated as identity. Source: ours.

### Steam focus

- **0014** An app whose only window is native Wayland (Lepton's Android container) leaves the
  launch spinner: mapped xdg-shell windows that carry an appid are reported in
  GAMESCOPE_FOCUSABLE_APPS/WINDOWS (id = top bit + xdg id, also published as
  GAMESCOPE_FOCUSED_WINDOW and honoured in GAMESCOPECTRL_BASELAYER_WINDOW).
  Source: armada 0024, verbatim.

### HDR

Prerequisite chain for 0025 (per-plane color management), landed in armada's own series
order; traced by hunk-failure evidence against our base, not guessed from thematic grouping.
Tests hunks dropped from every one of these (we don't build gamescope_tests).

- **0016** Synthesizes a client EDID for EDID-less internal panels (ours have none — see
  kernel 1021/1059) from the connector's preferred mode, sRGB, no HDR. Physical EDIDs are
  unchanged and preferred; the synthetic one never reaches KMS. Source: armada 0002, tests
  dropped.
- **0017** Known-display profiles (Lua `gamescope.config.known_displays`) can match an
  EDID-less panel via 0016's synthesized identity. Source: armada 0003, tests dropped.
  pocknix consumer: `GAMESCOPE_INTERNAL_DEVICE_ID` (pocknix-steam, set to `POCKNIX_DEVICE`)
  feeds `display.device_id`, since 0016 gives every EDID-less board the same generic
  vendor/model — a board's own profile lives in its BSP's
  `root/etc/gamescope/scripts/pocknix/displays/` (see sm8550's rp6 entry; colorimetry/HDR
  there are ported from armada-os's own profile for this panel — nominal DCI-P3 primaries,
  not individually measured, cross-checked against Retroid's published spec).
- **0018** Composes gamma 2.2 HDR when the backend has no hardware color management.
  Source: armada 0004, tests dropped.
- **0019** The Vulkan WSI layer only advertises extra HDR surface formats the display
  actually supports underneath. Adapted: the two call sites use this tree's dispatch shape
  (`pDispatch->Method`, `vkroots::helpers::append`) instead of `std::bind_front` +
  `vkroots::append` — same `SurfaceFormatUtils` logic armada's patch defines, different
  calling convention. Source: armada 0005, tests dropped, two hunks rewritten.
- **0020** Scales SDR white when composing gamma 2.2 HDR output. Adapted: the
  `update_color_mgmt()` dirty-check hunk is merged with 0011's `bNativeGamut ==
  s_bLastNativeGamut` guard at the same `if` — both now AND together. Source: armada 0006,
  tests dropped, one hunk rewritten.
- **0021** Falls back to the app's own HDR metadata for inverse tone-mapping when gamescope
  has none of its own. Source: armada 0010, tests dropped.
- **0022** SDR color management through the DPU's CRTC-level output LUTs
  (`cv_drm_output_luts`, `DEGAMMA_LUT`/`DPU_3D_LUT`) — needs kernel 1090. The real
  prerequisite 0025 was missing; its symbols are defined here. Adapted: the `paint_all()`
  hunk is merged with 0011's identity-LUT-skip loop at the same location — the new
  `bOutputLUTs`/`EOTF_Gamma22`-skip check runs first, our existing per-i identity-skip still
  runs for every other EOTF index. Source: armada 0017, tests dropped, one hunk rewritten.
- **0023** arm64 virtual white point fix for the gamma 2.2 HDR path. Source: armada 0018,
  tests dropped.
- **0024** P3 red is wide gamut (colorimetry classification fix feeding gamut-wideness
  decisions). Source: armada 0019, tests dropped.
- **0025** Per-plane color management through msm plane color pipelines: with per-plane IGC
  + 3D LUT colorops (kernel 1094), each scanned-out layer gets its own EOTF's tables, so an
  HDR10 game and SDR overlays no longer need composition. Needs: kernel 1093, 1094.
  Adapted: appends a hunk making our own 0011's `SupportsPlaneColorManagement()` also return
  true when `g_DRM.bPlaneLuts` is set (it only checked the CRTC-level path, `0011` predates
  this patch), so the SDR native-gamut fallback recognizes planes as colour-managed via
  either path. Source: armada 0021, tests dropped, one hunk appended.
- Not ported: armada's own prerequisite-adjacent 0020
  (`libliftoff-fix-multiple-primary-plane-stacking`) rewrites the same zpos-tracking core
  our own 0013 (`ROCKNIX 0020 + 0022`) already covers, with an incompatible, deeper
  restructure of `alloc.c`'s plane-selection logic. Confirmed via 0021's actual diff that
  nothing in 0021 depends on it — it isn't a real prerequisite, just adjacent in armada's
  numbering. Left for a separate investigation if pocknix's own zpos fix ever needs
  revisiting.

## Not taken

- ROCKNIX 0008 --rotated-output-max-height: no such board yet.
- The revert of upstream e572411d (mangoapp frametimes): its early return skips
  `wlserver_app_presented()`, dropping the game's presentation feedback.

## Retired numbers

0005, 0007, 0008
