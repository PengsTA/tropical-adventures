-- A village landing court, with an open stone approach to the old wooden dais.
local ground = {
    { 0, 2, 2, 2, 2, 0, 2, 2 },
    { 0, 2, 4, 4, 4, 1, 2, 2 },
    { 2, 1, 4, 5, 4, 1, 1, 2 },
    { 2, 1, 4, 4, 4, 1, 1, 0 },
    { 2, 1, 1, 3, 1, 1, 1, 2 },
    { 2, 2, 1, 3, 1, 1, 1, 0 },
    { 2, 2, 1, 3, 1, 1, 2, 0 },
    { 0, 1, 1, 3, 1, 0, 2, 0 },
}
local objects = {}
local function Add(prefab, x, y)
    objects[#objects + 1] = { name = "", type = prefab, shape = "rectangle",
        x = x * 64, y = y * 64, width = 0, height = 0, visible = true, properties = {} }
end
Add("seaworthy_broken", 3.5, 2.5)
Add("pighouse", 1.35, 3.9)
Add("pighouse", 6.25, 2.85)
Add("deciduoustree", 1.7, 1.4)
Add("deciduoustree", 6.65, 1.2)
Add("deciduoustree", 1.35, 5.8)
Add("deciduoustree", 6.4, 6.25)
Add("pighead", 2.35, 4.8)
Add("pighead", 5.6, 4.2)
Add("berrybush", 2.05, 6.7)
Add("berrybush", 5.25, 5.55)
Add("flower", 2.6, 0.6)
Add("flower", 5.7, 1.75)
Add("flower", 2.15, 5.75)
Add("flower", 6.1, 4.85)

local tiles = {}
for _, row in ipairs(ground) do
    for _, tile in ipairs(row) do tiles[#tiles + 1] = tile end
end
return {
    version = "1.1", luaversion = "5.1", orientation = "orthogonal",
    width = 8, height = 8, tilewidth = 64, tileheight = 64, properties = {}, tilesets = {},
    layers = {
        { type = "tilelayer", name = "BG_TILES", x = 0, y = 0, width = 8, height = 8,
            visible = true, opacity = 1, properties = {}, encoding = "lua", data = tiles },
        { type = "objectgroup", name = "FG_OBJECTS", visible = true, opacity = 1,
            properties = {}, objects = objects },
    },
}
