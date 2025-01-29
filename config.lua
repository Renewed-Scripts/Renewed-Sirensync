return {
    ---@class audioConfig
    ---@field audioName string
    ---@field audioRef? string the audioBank to use, if for example you use custom serverside sirens

    ---@class SirenConfigTable
    ---@field models? table<string, boolean>
    ---@field sirenModes table<number, audioConfig> the key is the siren mode
    ---@field horn? audioConfig

    controls = {
        policeLights = 'Q',
        policeHorn   = 'E',
        sirenToggle  = 'LMENU',
        sirenCycle   = 'R',
    },

    sirenShutOff = true,          -- Set to true if you want the siren to automatically shut off when the player exits the vehicle

    disableDamagedSirens = false, -- Set to true if you want to disable the damaged siren
    useEngineHealth = false,      -- Determine wether to use engine health over body health for siren damage
    damageThreshold = 300,        -- If the vehicle's health is below this value, the siren will be considered damaged

    ---@type table<string, SirenConfigTable>
    --- Configure what siren sounds to use for a specific model and siren mode
    sirens = {
        base = {
            sirenModes = {
                { audioName = 'VEHICLES_HORNS_SIREN_1' },
                { audioName = 'VEHICLES_HORNS_SIREN_2' },
                { audioName = 'VEHICLES_HORNS_POLICE_WARNING' },
            },

            horn = {
                audioName = 'SIRENS_AIRHORN'
            }
        },

        fire = {
            sirenModes = {
                { audioName = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01' },
                { audioName = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01' },
                { audioName = 'VEHICLES_HORNS_AMBULANCE_WARNING' }
            },

            horn = {
                audioName = 'VEHICLES_HORNS_FIRETRUCK_WARNING'
            },

            models = {
                [`FIRETRUK`] = true,
                [`ambulance`] = true,
            }
        },

        unmarked = {
            sirenModes = {
                { audioName = 'RESIDENT_VEHICLES_SIREN_WAIL_02' },
                { audioName = 'RESIDENT_VEHICLES_SIREN_QUICK_02' }
            },

            models = {
                [`fbi`] = true,
                [`fbi2`] = true,
                [`police4`] = true,
            }
        },

        bikes = {
            sirenModes = {
                { audioName = 'RESIDENT_VEHICLES_SIREN_WAIL_03' },
                { audioName = 'RESIDENT_VEHICLES_SIREN_QUICK_03' }
            },

            models = {
                [`policeb`] = true
            }
        },
    }
}