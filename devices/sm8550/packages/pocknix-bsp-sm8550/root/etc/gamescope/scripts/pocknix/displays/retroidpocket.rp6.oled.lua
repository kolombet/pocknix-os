-- Retroid Pocket 6 panel: Visionox VTDR6130, DSI command mode, no EDID.
--
-- 0016 synthesizes the same generic sRGB EDID for every EDID-less internal panel pocknix
-- ships, so vendor/model/product can't tell this panel apart from any other board's. 0017
-- adds device_id (from GAMESCOPE_INTERNAL_DEVICE_ID, set by pocknix-steam to POCKNIX_DEVICE)
-- plus internal/has_edid so this profile can match on board identity instead.
--
-- Colorimetry/HDR values ported from armada-os's own retroid.vtdr6130.oled.lua profile for
-- this exact panel: nominal DCI-P3 primaries, not individually measured. Cross-checked
-- against Retroid's own published spec (~550 nits peak, ~92% DCI-P3 / 107% sRGB coverage),
-- which lines up closely enough to trust. No colorimeter reading of an actual unit exists
-- anywhere we could find; treat these as "good enough to ship", not ground truth.

gamescope.config.known_displays.retroidpocket_rp6_oled = {
    pretty_name = "Retroid Pocket 6 (Visionox VTDR6130)",
    colorimetry = {
        r = { x = 0.6800, y = 0.3200 },
        g = { x = 0.2650, y = 0.6900 },
        b = { x = 0.1500, y = 0.0600 },
        w = { x = 0.3127, y = 0.3290 },
    },
    hdr = {
        supported = true,
        force_enabled = false,
        eotf = gamescope.eotf.gamma22,
        max_content_light_level = 750,
        max_frame_average_luminance = 375,
        min_content_light_level = 0
    },
    -- No dynamic_refresh_rates/dynamic_modegen: kernel 1021 exposes only the panel's
    -- single 120Hz mode (a second mode races the init sequence's mode guess), so there is
    -- no refresh range for gamescope to switch within.
    matches = function(display)
        if display.internal and display.device_id == "rp6" then
            debug("[retroidpocket_rp6_oled] Matched internal device_id: "..display.device_id)
            return 5000
        end
        return -1
    end
}
debug("Registered Retroid Pocket 6 (Visionox VTDR6130) as a known display")
--debug(inspect(gamescope.config.known_displays.retroidpocket_rp6_oled))
