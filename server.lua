lib.versionCheck('Renewed-Scripts/Renewed-Sirensync')

RegisterNetEvent('Renewed-Sirensync:server:SyncState', function()
    local ped = GetPlayerPed(source)
    if ped == 0 then return end

    local veh = GetVehiclePedIsIn(ped)
    if veh == 0 or not DoesEntityExist(veh) then return end

    local state = Entity(veh).state
    if state.stateEnsured then return end

    state:set('sirenMode', 0, true)
    state:set('horn', false, true)
    state:set('lightsOn', false, true)
    state:set('stateEnsured', true, true)
end)
