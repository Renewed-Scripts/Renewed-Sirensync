return {
    ---@class audioConfig
    ---@field audioName string
    ---@field audioRef? string the audioBank to use, (ie: you use custom serverside sirens)

    controls = {
        policeLights = 'Q',
        policeHorn   = 'E',
        sirenToggle  = 'LMENU',
        sirenCycle   = 'R',
    },

    ---@type table<string, audioConfig> override what horn to use for a specific vehicle model
    addonHorns = {},

    fireModels = {
        [`FIRETRUK`] = true,
        [`ambulance`] = true,
    },

    sirenShutOff = true, -- Set to true if you want the siren to automatically shut off when the player exits the vehicle

    disableDamagedSirens = false, -- Set to true if you want to disable the damaged siren
    useEngineHealth = false, -- Determine wether to use engine health over body health for siren damage
    damageThreshold = 300, -- If the vehicle's health is below this value, the siren will be considered damaged
}
