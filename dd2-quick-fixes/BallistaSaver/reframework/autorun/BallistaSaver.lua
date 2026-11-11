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
--   * "Repair broken objects": scan for wrecked objects near you and try to un-break them.

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

------------------------------------------------------------------------
-- Repair: find broken world objects (app.GimmickBase) near you and try to un-break them.
-- Known fields (from other working DD2 mods): _IsBroken, IsNoDamage. Which method rebuilds the
-- object isn't known yet, so the menu lists the object's own reset-style methods as buttons and
-- writes everything to reframework/data/BallistaSaver_scan.json for diagnosis.
------------------------------------------------------------------------
local repair = { radius = 60, onlyBroken = true, list = {}, msg = "", lockAfter = true }
local METHOD_WORDS = { "reset", "restore", "repair", "reviv", "rebirth", "recover", "rebuild", "respawn", "regenerat", "unbreak" }

local function cam_pos()
    local ok, p = pcall(function() return sdk.get_primary_camera():get_GameObject():get_Transform():get_Position() end)
    return ok and p or nil
end

local function gimmick_info(gb)
    local r = { gb = gb }
    pcall(function() r.go = gb:get_GameObject(); r.name = tostring(r.go:get_Name()) end)
    pcall(function() r.type = gb:get_type_definition():get_full_name() end)
    pcall(function() r.broken = gb:get_field("_IsBroken") end)
    pcall(function() r.noDamage = gb:get_field("IsNoDamage") end)
    pcall(function() r.pos = r.go:get_Transform():get_Position() end)
    return r
end

local function candidate_methods(gb)
    local out, seen = {}, {}
    local td = gb:get_type_definition()
    local depth = 0
    while td and depth < 8 do
        pcall(function()
            for _, m in ipairs(td:get_methods()) do
                local n = m:get_name()
                local ln = n:lower()
                if m:get_num_params() == 0 and not m:is_static() and not seen[n] then
                    for _, w in ipairs(METHOD_WORDS) do
                        if ln:find(w, 1, true) then seen[n] = true; out[#out + 1] = n; break end
                    end
                end
            end
        end)
        td = td:get_parent_type(); depth = depth + 1
    end
    table.sort(out)
    return out
end

local function dump_fields(gb)
    local out = {}
    local td = gb:get_type_definition()
    local depth = 0
    while td and depth < 8 do
        pcall(function()
            for _, f in ipairs(td:get_fields()) do
                if not f:is_static() then
                    local n = f:get_name()
                    local ok, v = pcall(function() return gb:get_field(n) end)
                    if ok and (type(v) == "boolean" or type(v) == "number" or type(v) == "string") then out[n] = v end
                end
            end
        end)
        td = td:get_parent_type(); depth = depth + 1
    end
    return out
end

local function scan()
    repair.list = {}
    local me = cam_pos()
    if not me then repair.msg = "Couldn't read your position."; return end
    local ok, err = pcall(function()
        local sm = sdk.get_native_singleton("via.SceneManager")
        local scene = sdk.call_native_func(sm, sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")
        local arr = scene:call("findComponents(System.Type)", sdk.typeof("app.GimmickBase"))
        for _, gb in ipairs(arr and arr:get_elements() or {}) do
            local r = gimmick_info(gb)
            if r.pos then
                local dx, dy, dz = r.pos.x - me.x, r.pos.y - me.y, r.pos.z - me.z
                r.dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if r.dist <= repair.radius and (not repair.onlyBroken or r.broken == true) then
                    r.methods = candidate_methods(gb)
                    repair.list[#repair.list + 1] = r
                end
            end
        end
    end)
    table.sort(repair.list, function(a, b) return a.dist < b.dist end)
    repair.msg = ok and ("Found %d object(s)."):format(#repair.list) or ("Scan failed: " .. tostring(err))
end

local function save_scan()
    local rows = {}
    for _, r in ipairs(repair.list) do
        rows[#rows + 1] = { name = r.name, type = r.type, broken = r.broken, noDamage = r.noDamage, dist = r.dist,
            pos = r.pos and { r.pos.x, r.pos.y, r.pos.z }, methods = r.methods, fields = dump_fields(r.gb) }
    end
    pcall(json.dump_file, "BallistaSaver_scan.json", rows)
    repair.msg = "Saved reframework/data/BallistaSaver_scan.json"
end

local function lock(r)
    if repair.lockAfter then pcall(function() r.gb:set_field("IsNoDamage", true) end) end
end

local function basic_repair(r)
    local ok = pcall(function() r.gb:set_field("_IsBroken", false) end)
    lock(r)
    local info = gimmick_info(r.gb)
    r.broken, r.noDamage = info.broken, info.noDamage
    return ok
end

local function try_method(r, m)
    local ok, err = pcall(function() r.gb:call(m .. "()") end)
    lock(r)
    local info = gimmick_info(r.gb)
    r.broken = info.broken
    repair.msg = ("%s.%s(): %s, broken now: %s"):format(r.name or "?", m, ok and "called" or ("error " .. tostring(err)), tostring(r.broken))
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
    if imgui.tree_node("Repair broken objects (ballistas)") then
        imgui.text("Stand next to the wrecked ballistas, then Scan.")
        local c
        c, repair.radius = imgui.slider_int("Radius (m)", repair.radius, 10, 200)
        c, repair.onlyBroken = imgui.checkbox("Only broken ones", repair.onlyBroken)
        c, repair.lockAfter = imgui.checkbox("Make repaired objects unbreakable", repair.lockAfter)
        if imgui.button("Scan") then scan() end
        imgui.same_line()
        if imgui.button("Save scan to file") then save_scan() end
        imgui.same_line()
        if imgui.button("Repair all listed (basic)") then
            for _, r in ipairs(repair.list) do basic_repair(r) end
            repair.msg = "Cleared the broken flag on all listed objects."
        end
        if repair.msg ~= "" then imgui.text(repair.msg) end
        for i, r in ipairs(repair.list) do
            imgui.push_id(i)
            if imgui.tree_node(("%s  (%.0f m)  broken: %s"):format(r.name or "?", r.dist or 0, tostring(r.broken))) then
                imgui.text("Type: " .. tostring(r.type))
                imgui.text("No-damage flag: " .. tostring(r.noDamage))
                if imgui.button("Basic repair (clear broken flag)") then
                    basic_repair(r)
                    repair.msg = ("%s: broken now %s"):format(r.name or "?", tostring(r.broken))
                end
                if #r.methods > 0 then
                    imgui.text("Its own reset-style methods (try one at a time):")
                    for _, m in ipairs(r.methods) do
                        if imgui.button(m) then try_method(r, m) end
                    end
                else
                    imgui.text("No reset-style methods found on this object.")
                end
                imgui.tree_pop()
            end
            imgui.pop_id()
        end
        imgui.tree_pop()
    end
    imgui.tree_pop()
end)
