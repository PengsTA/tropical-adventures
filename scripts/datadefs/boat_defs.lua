local BOAT_TYPES = {
    armouredboat = {
        name = "armouredboat",
        build = "rowboat_armored_build",
        icon = "armouredboat.tex",
        maxuses = 500,
        loottable = { "boards", "boards", "boards", "rope", "seashell", "seashell", "seashell", "seashell", "seashell" },
        collapse = "flotsam_armoured_build",
        useamount = 0.00862,
    },
    cargoboat = {
        name = "cargoboat",
        build = "rowboat_cargo_build",
        icon = "cargo.tex",
        maxuses = 300,
        loottable = { "boards", "boards", "boards", "rope" },
        collapse = "flotsam_cargo_build",
        useamount = 0.00625,
    },
    corkboat = {
        name = "corkboat",
        build = "coracle_boat_build",
        icon = "coracle_boat.tex",
        maxuses = 80,
        loottable = { "cork" },
        collapse = "flotsam_lograft_build",
        useamount = 0.00468,
    },
    encrustedboat = {
        name = "encrustedboat",
        build = "rowboat_encrusted_build",
        icon = "encrustedboat.tex",
        maxuses = 800,
        loottable = { "limestone", "limestone", "boards", "boards", "boards" },
        collapse = "flotsam_encrusted_build",
        useamount = 0.0100,
    },
    lograft_old = {
        name = "lograft_old",
        build = "raft_log_build",
        bank = "raft",
        icon = "lograft.tex",
        maxuses = 150,
        loottable = { "log", "log", "log", "cutgrass", "cutgrass" },
        collapse = "flotsam_lograft_build",
        useamount = 0.00468,
    },
    woodlegsboat = {
        name = "woodlegsboat",
        build = "pirate_boat_build",
        icon = "woodlegsboat.tex",
        maxuses = 500,
        loottable = { "boards", "boards", "dubloon", "dubloon" },
        collapse = "flotsam_rowboat_build",
        useamount = 0.00468,
    },
    raft_old = {
        name = "raft_old",
        build = "raft_build",
        bank = "raft",
        icon = "raft.tex",
        maxuses = 150,
        loottable = { "vine", "bamboo", "bamboo" },
        collapse = "flotsam_bamboo_build",
        useamount = 0.00468,
    },
    rowboat = {
        name = "rowboat",
        build = "rowboat_build",
        icon = "rowboat.tex",
        maxuses = 250,
        loottable = { "boards", "vine", "vine" },
        collapse = "flotsam_rowboat_build",
        useamount = 0.00781,
    },
    surfboard = {
        name = "surfboard",
        build = "raft_surfboard_build",
        bank = "raft",
        icon = "surfboard.tex",
        maxuses = 100,
        loottable = { "seashell" },
        collapse = "flotsam_surfboard_build",
        tags = { "surfboard" },
        useamount = 0.00312,
    },
    shadowwaxwell_boat = {
        name = "shadowwaxwell_boat",
        build = "waxwell_shadowboat_build",
        icon = "shadowboat.tex",
        maxuses = 150,
        loottable = { "log" },
        collapse = "flotsam_shadowwaxwell_boat_build",
        useamount = 0,
        postfn = function(inst)
            inst.AnimState:SetMultColour(0, 0, 0, .4)
        end,
    },
}

local mt = {
    __index = function(t, k)
        return rawget(t, k) or BOAT_TYPES.rowboat
    end,
}

setmetatable(BOAT_TYPES, mt)

return BOAT_TYPES
