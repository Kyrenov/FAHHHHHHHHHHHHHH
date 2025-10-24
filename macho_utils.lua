local MachoUtils = {}

MachoUtils.ScriptRegistry = {}


---@param name string
---@param code string
---@param preferredResource string|table
function MachoUtils.RegisterScript(name, code, preferredResource)
    MachoUtils.ScriptRegistry[name] = {
        code = code,
        preferredResource = preferredResource
    }
end

function MachoUtils.InjectScript(name, resource, ...)
    local script = MachoUtils.ScriptRegistry[name]
    if not script then return print("Script not found:", name) end

    local targetResource = resource

    -- If no resource specified, check preferredResource (can be string or table)
    if not targetResource then
        local pref = script.preferredResource
        if type(pref) == "table" then
            for i = 1, #pref do
                if MachoResourceInjectable(pref[i]) then
                    targetResource = pref[i]
                    break
                end
            end
        elseif type(pref) == "string" then
            if MachoResourceInjectable(pref) then
                targetResource = pref
            end
        end
    end

    -- Fallback to "any" if still not found
    if not targetResource then
        targetResource = "any"
    end

    if not targetResource then return print("No valid resource found for injection") end

    local args = { ... }
    local needed = select(2, string.gsub(script.code, '%%s', ''))
    if #args < needed then return print("InjectScript, doesn't have enough args") end

    for i, v in ipairs(args) do
        if type(v) == "string" then
            args[i] = string.format("'%s'", v)
        end
    end

    local code = #args > 0 and string.format(script.code, table.unpack(args)) or script.code
    MachoInjectResource2(3, targetResource, code)

    return targetResource
end

function MachoUtils.InjectScriptRaw(name, resource, ...)
    local script = MachoUtils.ScriptRegistry[name]
    if not script then return print("Script not found:", name) end

    local targetResource = resource

    -- If no resource specified, check preferredResource (can be string or table)
    if not targetResource then
        local pref = script.preferredResource
        if type(pref) == "table" then
            for i = 1, #pref do
                if MachoResourceInjectable(pref[i]) then
                    targetResource = pref[i]
                    break
                end
            end
        elseif type(pref) == "string" then
            if MachoResourceInjectable(pref) then
                targetResource = pref
            end
        end
    end

    -- Fallback to "any" if still not found
    if not targetResource then
        targetResource = "any"
    end

    if not targetResource then return print("No valid resource found for injection") end

    local args = { ... }
    local needed = select(2, string.gsub(script.code, '%%s', ''))
    if #args < needed then return print("InjectScript, doesn't have enough args") end

    for i, v in ipairs(args) do
        if type(v) == "string" then
            args[i] = string.format("'%s'", v)
        end
    end

    local code = #args > 0 and string.format(script.code, table.unpack(args)) or script.code
    MachoInjectResourceRaw(targetResource, code)

    return targetResource
end

function MachoUtils.GetAllPlayers()
    local players_endpoint = "http://%s/players.json"
    local players_json = MachoWebRequest((players_endpoint):format(tostring(GetCurrentServerEndpoint())))

    local players = json.decode(players_json)

    local localplayer = PlayerId()
    local local_coords = GetEntityCoords(GetPlayerPed(localplayer))

    local plys = {}
    for _, player in ipairs(players) do
        local ply = {}

        ply.identifiers = player.identifiers
        ply.ping = player.ping
        ply.name = player.name
        ply.server_id = player.id
        ply.client_id = GetPlayerFromServerId(player.id)

        table.insert(plys, ply)
    end

    return plys
end

function MachoUtils.InjectOnInjectable(code, resource, type)
    local inject_type = type or 1
    local resource = resource or "any"
    local code = code or [[print("Hello!")]]

    Citizen.CreateThread(function()
        repeat
            Citizen.Wait(4)
        until MachoResourceInjectable(resource)
        if inject_type == 3 then Citizen.Wait(1000) end

        MachoInjectResource2(inject_type, resource, code)
    end)
end

function MachoUtils.GetAntiCheats()
    local ACs_found = {}

    for i=0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(i);
        if resource ~= nil then -- man, why does fivem doesnt have a continue statement 
            local author = GetResourceMetadata(resource,"author",0)
            local desc   = GetResourceMetadata(resource,"author",0)
            local ac     = GetResourceMetadata(resource,"ac",0) -- Yes, FG tells us directly

            local found = false

            if ac == "fg" then
                table.insert(ACs_found, {"Fiveguard", resource})
            elseif author == "WaveShield" then
                table.insert(ACs_found, {"WaveShield", resource})
            elseif string.find(author or "", "reaperac.com") then
                table.insert(ACs_found, {"ReaperV4", resource})
            elseif string.find(author or "", "Electron") then
                table.insert(ACs_found, {"ElectronAC", resource})
            elseif desc then
                local stripped = desc:gsub("-", ""):lower()
                if stripped:find("anticheat") then
                    table.insert(ACs_found, {"UnknownAC", resource})
                end
            elseif string.find(resource, "_ac") then
                table.insert(ACs_found, {"UnknownAC", resource})
            end
        end
    end

    return ACs_found
end

local resFilters = {
    ["inventory"] = function(name)
        return string.find(name:lower(), "_inv") or string.find(name:lower(), "_inventory") or name:lower() == "inventory"
    end
}

function MachoUtils.GetResourceByFilter(filter)
    local num_res = GetNumResources() - 1;

    for i=0, num_res do
        local resource = GetResourceByFindIndex(i);
        if (resFilters[filter] or function() return end)(resource) then
            return resource
        end
    end
end

return MachoUtils
