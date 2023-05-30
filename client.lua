local Config = require 'Config'

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
local GetEntityFromStateBagName = GetEntityFromStateBagName
local NetworkGetEntityOwner = NetworkGetEntityOwner
local SetVehicleHasMutedSirens = SetVehicleHasMutedSirens
local SetVehicleSiren = SetVehicleSiren

-- Localized Functions --
local function releaseSound(veh, soundId, forced)
    if forced and (DoesEntityExist(veh) and not IsEntityDead(veh)) then return end
    StopSound(soundId)
    ReleaseSoundId(soundId)

    return true
end

local function isVehAllowed()
    if not cache.vehicle or not cache.seat or cache.seat ~= -1 or GetVehicleClass(cache.vehicle) ~= 18 or IsPedInAnyHeli(cache.vehicle) or IsPedInAnyPlane(cache.vehicle) then
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
            DisableControlAction(0, 80, true) -- R
            DisableControlAction(0, 81, true) -- .
            DisableControlAction(0, 82, true) -- ,
            DisableControlAction(0, 83, true) -- =
            DisableControlAction(0, 84, true) -- -
            DisableControlAction(0, 86, true) -- E
            DisableControlAction(0, 172, true) -- Up arrow
            Wait(0)
        end
    end)
end)

lib.onCache('vehicle', function(value)
    if value then return end
    if cache.seat ~= -1 then return end

    local oldVeh = cache.vehicle
    if GetVehicleClass(oldVeh) ~= 18 then return end

    local state = Entity(oldVeh).state

    if not state.stateEnsured then return end

    if Config.sirenShutOff then
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
        local entity = GetEntityFromStateBagName(bagName)

        local amOwner = NetworkGetEntityOwner(entity) == cache.playerId
        if (not amOwner and replicated) or (amOwner and not replicated) then return end

        if entity and entity ~= 0 then
            cb(entity, value)
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
    defaultKey = Config.Controls.PoliceLights,
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
local didSiren = false

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
    local soundName = Config.addonHorns[GetEntityModel(veh)] or 'SIRENS_AIRHORN'

    PlaySoundFromEntity(soundId, soundName, veh, 0, false, 0)
end)

local policeHorn = lib.addKeybind({
    name = 'policeHorn',
    description = 'Hold this button to use your vehicle Horn',
    defaultKey = Config.Controls.policeHorn,
    onPressed = function()
        if not isVehAllowed() then return end

        local state = Entity(cache.vehicle).state

        if not state.stateEnsured then return end

        didSiren = true
        restoreSiren = state.sirenMode
        state:set('sirenMode', 0, true)

        state:set('horn', true, true)
    end,
    onReleased = function()
        if not cache.vehicle then return end

        local state = Entity(cache.vehicle).state
        state:set('horn', false, true)


        if not didSiren or restoreSiren == 0 then return end

        if state.lightsOn then
            state:set('sirenMode', restoreSiren, true)
        end

        restoreSiren = 0
        didSiren = false
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

    if soundMode == 1 then
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_SIREN_1', veh, 0, false, 0)
    elseif soundMode == 2 then
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_SIREN_2', veh, 0, false, 0)
    elseif soundMode == 3 then
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_POLICE_WARNING', veh, 0, false, 0)
    end
end)

local sirenToggle = lib.addKeybind({
    name = 'sirenToggle',
    description = 'Press this button to use your siren',
    defaultKey = Config.Controls.sirenToggle,
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
    defaultKey = Config.Controls.sirenCycle,
    onPressed = function()
        if not isVehAllowed() then return end

        local state = Entity(cache.vehicle).state

        if not state.stateEnsured then return end

        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

        if state.sirenMode == 0 then

            state:set('sirenMode', 1, true)

            sirenToggle:disable(true)
            policeLights:disable(true)
            policeHorn:disable(true)

            Rpressed = true
        else
            local newSiren = state.sirenMode == 3 and 1 or state.sirenMode + 1

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
            Entity(cache.vehicle).state:set('sirenMode', 0, true)
        end

        Rpressed = false
    end
})
