local config = lib.load('config')

-- soundId Tables --
local sirenVehicles = {}
local hornVehicles = {}

-- Natives Used --
local Wait = Wait
local TriggerServerEvent = TriggerServerEvent
local SetVehRadioStation = SetVehRadioStation
local SetVehicleRadioEnabled = SetVehicleRadioEnabled
local DisableControlAction = DisableControlAction
local GetVehicleClass = GetVehicleClass
local IsPedInAnyHeli = IsPedInAnyHeli
local IsPedInAnyPlane = IsPedInAnyPlane
local PlaySoundFromEntity = PlaySoundFromEntity
local GetSoundId = GetSoundId
local DoesEntityExist = DoesEntityExist
local IsEntityDead = IsEntityDead
local StopSound = StopSound
local ReleaseSoundId = ReleaseSoundId
local AddStateBagChangeHandler = AddStateBagChangeHandler
local NetworkGetEntityOwner = NetworkGetEntityOwner
local SetVehicleHasMutedSirens = SetVehicleHasMutedSirens
local SetVehicleSiren = SetVehicleSiren
local GetEntityModel = GetEntityModel
local GetVehicleEngineHealth = GetVehicleEngineHealth
local GetVehicleBodyHealth = GetVehicleBodyHealth

-- Localized Functions --
local function releaseSound(veh, soundId, forced)
    if forced and (DoesEntityExist(veh) and not IsEntityDead(veh)) then return end
    StopSound(soundId)
    ReleaseSoundId(soundId)

    return true
end

local function isVehAllowed()
    if cache.seat ~= -1 or GetVehicleClass(cache.vehicle) ~= 18 or IsPedInAnyHeli(cache.vehicle) or IsPedInAnyPlane(cache.vehicle) then
        return false
    end

    return true
end

-- Cleanup Loop --
CreateThread(function()
    while true do
        for veh, soundId in pairs(sirenVehicles) do
            if releaseSound(veh, soundId, true) then
                sirenVehicles[veh] = nil
            end
        end

        for veh, soundId in pairs(hornVehicles) do
            if releaseSound(veh, soundId, true) then
                hornVehicles[veh] = nil
            end
        end

        Wait(1000)
    end
end)

-- Cache Events --
lib.onCache('seat', function(seat)
    if seat ~= -1 then return end

    SetTimeout(0, function()
        if not isVehAllowed() then return end

        SetVehRadioStation(cache.vehicle, 'OFF')
        SetVehicleRadioEnabled(cache.vehicle, false)

        if not Entity(cache.vehicle).state.stateEnsured then
            TriggerServerEvent('Renewed-Sirensync:server:SyncState', VehToNet(cache.vehicle))
        end

        while cache.seat == -1 do
            DisableControlAction(0, 80, true)  -- R
            DisableControlAction(0, 81, true)  -- .
            DisableControlAction(0, 82, true)  -- ,
            DisableControlAction(0, 83, true)  -- =
            DisableControlAction(0, 84, true)  -- -
            DisableControlAction(0, 85, true)  -- Q
            DisableControlAction(0, 86, true)  -- E
            DisableControlAction(0, 172, true) -- Up arrow
            Wait(0)
        end
    end)
end)

lib.onCache('vehicle', function(value)
    if value or cache.seat ~= -1 then return end

    local state = Entity(cache.vehicle).state

    if not state.stateEnsured then return end

    if config.sirenShutOff then
        if state.sirenMode ~= 0 then
            state:set('sirenMode', 0, true)
        end
    end

    if state.horn then
        state:set('horn', false, true)
    end
end)

-- Statebags & Keybinds --
local function stateBagWrapper(keyFilter, cb)
    return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value, _, replicated)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        local loaded = netId and lib.waitFor(function()
            if NetworkDoesEntityExistWithNetworkId(netId) then return true end
        end, 'Timeout while waiting for entity to exist', 5000)

        local entity = loaded and NetToVeh(netId)

        if entity then
            local amOwner = NetworkGetEntityOwner(entity) == cache.playerId

            if amOwner == replicated then
                cb(entity, value)
            end
        end
    end)
end

-- Police Lights --
stateBagWrapper('lightsOn', function(veh, value)
    SetVehicleHasMutedSirens(veh, true)
    SetVehicleSiren(veh, value)
end)

local policeLights = lib.addKeybind({
    name = 'policeLights',
    description = 'Press this button to use your siren',
    defaultKey = config.controls.policeLights,
    onPressed = function()
        if not isVehAllowed() then return end

        local state = Entity(cache.vehicle).state

        if not state.stateEnsured then return end

        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

        local curMode = state.lightsOn
        state:set('lightsOn', not curMode, true)

        if not curMode or state.sirenMode == 0 then return end

        state:set('sirenMode', 0, true)
    end
})

-- Police Horns --
local restoreSiren = 0
stateBagWrapper('horn', function(veh, value)
    local relHornId = hornVehicles[veh]

    if relHornId then
        if releaseSound(veh, relHornId) then
            hornVehicles[veh] = nil
        end
    end

    if not value then return end

    local soundId = GetSoundId()

    hornVehicles[veh] = soundId
    local vehModel = GetEntityModel(veh)
    local audioName = 'SIRENS_AIRHORN' -- Default sound
    local audioRef

    for i = 1, #config.sirens do
        local sirenConfig = config.sirens[i]

        if (not sirenConfig.models or sirenConfig.models[vehModel]) and sirenConfig.horn then
            audioName = sirenConfig.horn?.audioName or audioName
            audioRef = sirenConfig.horn?.audioRef or audioRef
            -- no break here, allows it to take the base config and if there's another valid config after, replace it.
        end
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    PlaySoundFromEntity(soundId, audioName, veh, audioRef or 0, false, 0)
end)

local policeHorn = lib.addKeybind({
    name = 'policeHorn',
    description = 'Hold this button to use your vehicle Horn',
    defaultKey = config.controls.policeHorn,
    onPressed = function()
        if not isVehAllowed() then return end

        local state = Entity(cache.vehicle).state

        if not state.stateEnsured then return end

        if state.sirenMode == 0 then
            restoreSiren = state.sirenMode
            state:set('sirenMode', 0, true)
        end

        state:set('horn', not state.horn, true)
    end,
    onReleased = function()
        if not cache.vehicle or GetVehicleClass(cache.vehicle) ~= 18 then return end

        local state = Entity(cache.vehicle).state

        SetTimeout(0, function()
            if state.horn then
                state:set('horn', false, true)
            end

            if state.lightsOn and state.sirenMode == 0 and restoreSiren > 0 then
                state:set('sirenMode', restoreSiren, true)
                restoreSiren = 0
            end
        end)
    end,
})

-- Siren Modes and Toggles --
stateBagWrapper('sirenMode', function(veh, soundMode)
    local usedSound = sirenVehicles[veh]

    if usedSound then
        if releaseSound(veh, usedSound) then
            sirenVehicles[veh] = nil
        end
    end

    if soundMode == 0 or not soundMode then return end


    local soundId = GetSoundId()
    sirenVehicles[veh] = soundId

    local audioName
    local audioRef

    if not config.disableDamagedSirens and (config.useEngineHealth and GetVehicleEngineHealth(cache.vehicle) or GetVehicleBodyHealth(cache.vehicle)) <= config.damageThreshold then
        audioName = 'PLAYER_FUCKED_SIREN'
    else
        local vehModel = GetEntityModel(veh)
        for i = 1, #config.sirens do
            local sirenConfig = config.sirens[i]
            if (not sirenConfig.models or sirenConfig.models[vehModel]) and sirenConfig.sirenModes[soundMode] then
                audioName = sirenConfig.sirenModes[soundMode]?.audioName or audioName
                audioRef = sirenConfig.sirenModes[soundMode]?.audioRef or audioRef
                -- no break here, allows it to take the base config and if there's another valid config after, replace it.
            end
        end
    end

    if not audioName then
        return lib.print.error(('No sound found for siren mode %d on vehicle model (hash) %s'):format(soundMode, GetEntityModel(veh)))
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    PlaySoundFromEntity(soundId, audioName, veh, audioRef or 0, false, 0)
end)

local sirenToggle = lib.addKeybind({
    name = 'sirenToggle',
    description = 'Press this button to use your siren',
    defaultKey = config.controls.sirenToggle,
    onPressed = function()
        if not isVehAllowed() then return end

        local state = Entity(cache.vehicle).state

        if not state.stateEnsured or not state.lightsOn or state.horn then return end

        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

        local newSiren = state.sirenMode > 0 and 0 or 1

        state:set('sirenMode', newSiren, true)
    end
})

local Rpressed = false
lib.addKeybind({
    name = 'sirenCycle',
    description = 'Press this button to cycle through your sirens',
    defaultKey = config.controls.sirenCycle,
    onPressed = function()
        if not isVehAllowed() then return end

        local state = Entity(cache.vehicle).state

        if not state.stateEnsured then return end

        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

        if state.sirenMode == 0 and not Rpressed then
            local sirenMode = state.sirenMode > 0 and 0 or 1

            state:set('sirenMode', sirenMode, true)

            sirenToggle:disable(true)
            policeLights:disable(true)
            policeHorn:disable(true)

            Rpressed = true
        elseif state.sirenMode > 0 and state.lightsOn and not Rpressed then
            local newSiren = state.sirenMode + 1 > 3 and 1 or state.sirenMode + 1

            state:set('sirenMode', newSiren, true)
        end
    end,
    onReleased = function()
        if not Rpressed then return end

        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

        sirenToggle:disable(false)
        policeLights:disable(false)
        policeHorn:disable(false)

        if cache.vehicle then
            SetTimeout(0, function()
                local state = Entity(cache.vehicle).state

                if state.sirenMode > 0 then
                    state:set('sirenMode', 0, true)
                end

                Rpressed = false
            end)
        end
    end
})