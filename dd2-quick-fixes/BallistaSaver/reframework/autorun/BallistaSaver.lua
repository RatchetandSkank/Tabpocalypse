-- Ballista Saver: keeps the Lake Norgan ballistas alive for "Reaching the Far Shore" (DD2 Dark Arisen).
--
-- How it works: every hit in the game goes through app.HitController.calcDamageValue(DamageInfo).
-- If the thing being hit is NOT a character (so not you, pawns, NPCs or Fimbl) and protection is on,
-- the hit's damage is set to 0 before the game applies it. Objects like ballistas then can't break.
--
-- Menu: REFramework (Insert) -> Script Generated UI -> Ballista Saver
--   * Mode "Everything that isn't a character" (default): the blunt fix. Turn it off after the quest,
--     because crates, barricades and other breakables can't break while it's on.
--   * Mode "Only names matching": protects only objects whose name contains one of the patterns.
--   * "Recently hit objects" shows the names of non-character objects that got hit, so you can see
--     what the ballistas are called and switch to name mode if you want.

local CONFIG_FILE = "BallistaSaver.json"

local cfg = {
    enabled = true,
    mode = 1,                -- 1 = everything that isn't a character, 2 = only names matching
    patterns = "ballista",   -- comma-separated, case-insensitive (for mode 2)
}

local ok_load, saved = pcall(json.load_file, CONFIG_FILE)
if ok_load and type(saved) == "table" then
    for k, v in pairs(saved) do if cfg[k] ~= nil then cfg[k] = v end end
end
local function save() pcall(json.dump_file, CONFIG_FILE, cfg) end

local recent = {}            -- { name, dmg, blocked, t }
local blocked_count = 0
local char_type = sdk.typeof("app.Character")

local is_char_cache = {}     -- GameObject address -> true/false
local cache_frames = 0

local function is_character(go)
    local addr = go:get_address()
    local c = is_char_cache[addr]
    if c ~= nil then return c end
    local ok, comp = pcall(function() return go:call("getComponent(System.Type)", char_type) end)
    c = ok and comp ~= nil
    is_char_cache[addr] = c
    return c
end

local function name_matches(name)
    local lname = name:lower()
    for raw in cfg.patterns:gmatch("[^,]+") do
        local p = raw:match("^%s*(.-)%s*$"):lower()
        if p ~= "" and lname:find(p, 1, true) then return true end
    end
    return false
end

local function note_hit(name, dmg, blocked)
    for _, r in ipairs(recent) do
        if r.name == name then
            r.dmg, r.blocked, r.t, r.hits = dmg, blocked, os.date("%H:%M:%S"), r.hits + 1
            return
        end
    end
    table.insert(recent, 1, { name = name, dmg = dmg, blocked = blocked, t = os.date("%H:%M:%S"), hits = 1 })
    while #recent > 15 do table.remove(recent) end
end

local hc_type = sdk.find_type_definition("app.HitController")
local calc_method = hc_type and hc_type:get_method("calcDamageValue(app.HitController.DamageInfo)")

if calc_method then
    sdk.hook(calc_method,
        function(args)
            local s = thread.get_hook_storage()
            s.bsInfo = nil
            local ok = pcall(function()
                local info = sdk.to_managed_object(args[3])
                if not info then return end
                local victim = info["<DamageGameObject>k__BackingField"]
                if not victim or is_character(victim) then return end
                local name = tostring(victim:get_Name())
                local protect = cfg.enabled and (cfg.mode == 1 or name_matches(name))
                s.bsInfo = info
                s.bsName = name
                s.bsProtect = protect
            end)
            if not ok then s.bsInfo = nil end
        end,
        function(retval)
            local s = thread.get_hook_storage()
            local info = s.bsInfo
            if info then
                s.bsInfo = nil
                pcall(function()
                    local dmg = info.Damage or 0
                    if s.bsProtect then
                        info.Damage = 0
                        blocked_count = blocked_count + 1
                    end
                    note_hit(s.bsName, dmg, s.bsProtect)
                end)
            end
            return retval
        end)
end

-- characters and objects come and go; drop the cache now and then so a reused address isn't misjudged
re.on_frame(function()
    cache_frames = cache_frames + 1
    if cache_frames > 600 then is_char_cache = {}; cache_frames = 0 end
end)

re.on_draw_ui(function()
    if not imgui.tree_node("Ballista Saver") then return end
    if not calc_method then
        imgui.text_colored("Couldn't find the damage function. The game may have updated; tell the author.", 0xFF4040FF)
        imgui.tree_pop()
        return
    end
    local changed
    changed, cfg.enabled = imgui.checkbox("Protection on", cfg.enabled)
    if changed then save() end
    changed, cfg.mode = imgui.combo("Mode", cfg.mode, { "Everything that isn't a character", "Only names matching" })
    if changed then save() end
    if cfg.mode == 2 then
        changed, cfg.patterns = imgui.input_text("Name patterns (comma-separated)", cfg.patterns)
        if changed then save() end
    end
    if cfg.enabled and cfg.mode == 1 then
        imgui.text("Turn this off after the quest: other breakables can't break while it's on.")
    end
    imgui.text(("Hits blocked so far: %d"):format(blocked_count))
    if imgui.tree_node("Recently hit objects (non-characters)") then
        if #recent == 0 then imgui.text("Nothing yet. Hit something, or wait for Fimbl to hit a ballista.") end
        for _, r in ipairs(recent) do
            imgui.text(("%s  %s  x%d  last dmg %.1f  %s"):format(r.t, r.name, r.hits, r.dmg,
                r.blocked and "[BLOCKED]" or "[let through]"))
        end
        if imgui.button("Clear list") then recent = {} end
        imgui.tree_pop()
    end
    imgui.tree_pop()
end)
