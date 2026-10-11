-- A weathered sailing shrine in a sandy clearing at the jungle village edge.
local ground = {
    { 1, 1, 1, 0, 1, 1, 1, 0 },
    { 1, 1, 4, 4, 4, 1, 1, 0 },
    { 1, 1, 4, 5, 4, 2, 1, 1 },
    { 0, 1, 4, 4, 4, 2, 2, 1 },
    { 1, 1, 2, 3, 2, 2, 2, 1 },
    { 0, 1, 2, 3, 2, 2, 2, 1 },
    { 0, 1, 2, 3, 2, 2, 2, 0 },
    { 0, 0, 0, 3, 2, 2, 0, 0 },
}
local objects = {}
local function Add(prefab, x, y)
    objects[#objects + 1] = { name = "", type = prefab, shape = "rectangle",
        x = x * 64, y = y * 64, width = 0, height = 0, visible = true, properties = {} }
end
Add("seaworthy_broken", 3.5, 2.5)
Add("wildborehouse", 1.6, 4.2)
Add("wildborehouse", 6.55, 5.25)
Add("wildborehead", 2.3, 5.05)
Add("wildborehead", 5.5, 3.9)
Add("palmtree", 2.2, 0.65)
Add("palmtree", 5.9, 1.2)
Add("palmtree", 2.15, 6.35)
Add("palmtree", 6.35, 6.35)
Add("jungletree", 0.95, 1.8)
Add("jungletree", 6.75, 2.65)
Add("bambootree", 1.1, 0.6)
Add("bambootree", 4.8, 0.75)
Add("bambootree", 7.15, 3.6)
Add("bambootree", 1.55, 5.7)
Add("seashell_beached", 5.4, 2.75)
Add("seashell_beached", 4.85, 6.15)
Add("seashell_beached", 2.6, 4.1)

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
