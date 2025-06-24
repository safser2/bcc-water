local CanUseCanteen = true
local IsSick = false

local function LoadAnim(animDict)
    DebugPrint('Loading animation dictionary: ' .. animDict)
    if HasAnimDictLoaded(animDict) then return end

    RequestAnimDict(animDict)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not HasAnimDictLoaded(animDict) do
        if GetGameTimer() - startTime > timeout then
            print('Failed to load dictionary:', animDict)
            return
        end
        Wait(10)
    end
    DebugPrint('Animation dictionary loaded: ' .. animDict)
end

local function PlayAnim(animDict, animName, flagValue, waitTime)
    DebugPrint('Playing animation: ' .. animName .. ' from dictionary: ' .. animDict)
    local playerPed = PlayerPedId()
    local flag = flagValue or 1
    local time = waitTime or 5000

    LoadAnim(animDict)
    HidePedWeapons(playerPed, 2, true)

    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, flag, 1.0, false, false, false)
    Wait(time)
    ClearPedTasks(playerPed)

    Filling = false
    DebugPrint('Animation played successfully.')
end

local function LoadModel(model, modelName)
    DebugPrint('Loading model: ' .. modelName)
    if not IsModelValid(model) then
        print('Invalid model:', modelName)
        return
    end

    if HasModelLoaded(model) then return end

    RequestModel(model, false)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not HasModelLoaded(model) do
        if GetGameTimer() - startTime > timeout then
            print('Failed to load model:', modelName)
            return
        end
        Wait(10)
    end
    DebugPrint('Model loaded: ' .. modelName)
end

local function FillContainer(pumpAnim, modelName, modelHash, notificationMessage)
    DebugPrint('Filling container with model: ' .. modelName)
    Filling = true
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    if not pumpAnim then
        local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_HAND')
        LoadModel(modelHash, modelName)

        Container = CreateObject(modelHash, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false, false, true)
        SetEntityVisible(Container, true)
        SetEntityAlpha(Container, 255, false)
        SetModelAsNoLongerNeeded(modelHash)
        AttachEntityToEntity(Container, playerPed, boneIndex, 0.12, 0.00, -0.10, 306.0, 18.0, 0.0, true, true, false, true, 2, true)

        local animDict = 'amb_work@world_human_crouch_inspect@male_c@idle_a'
        local animName = 'idle_a'

        LoadAnim(animDict)

        TaskSetCrouchMovement(playerPed, true, 0, false)
        Wait(1500)
        TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 3, 1.0, false, false, false)
        Wait(10000)
        TaskSetCrouchMovement(playerPed, false, 0, false)
        Wait(1500)

        DeleteObject(Container)
    else
        local taskRun = false
        local DataStruct = DataView.ArrayBuffer(256 * 4)
        local pointsExist = GetScenarioPointsInArea(PlayerCoords, 2.0, DataStruct:Buffer(), 10)

        if not pointsExist then goto NEXT end

        for i = 1, 1 do
            local scenario = DataStruct:GetInt32(8 * i)
            local hash = GetScenarioPointType(scenario)

            if hash == joaat('PROP_HUMAN_PUMP_WATER') then
                taskRun = true
                ClearPedTasksImmediately(playerPed)
                TaskUseScenarioPoint(playerPed, scenario, '', -1.0, true, false, 0, false, -1.0, true)
                Wait(15000)
                break
            end
        end

        ::NEXT::
        if not taskRun then
            local animDict = 'amb_work@prop_human_pump_water@female_b@idle_a'
            local animName = 'idle_a'
            if IsPedMale(playerPed) then
                animDict = 'amb_work@prop_human_pump_water@male_a@idle_a'
            end
            PlayAnim(animDict, animName, 1, 10000)
        end
    end

    ClearPedTasks(playerPed)
    Filling = false

    if Config.showMessages then
        Core.NotifyRightTip(notificationMessage, 4000)
    end
    DebugPrint('Container filled successfully.')
end

function CanteenFill(pumpAnim)
    DebugPrint('Filling canteen.')
    FillContainer(pumpAnim, 'p_cs_canteen_hercule', joaat('p_cs_canteen_hercule'), _U('fillingComplete'))
end

function BottleFill(pumpAnim)
    DebugPrint('Filling bottle.')
    FillContainer(pumpAnim, 'p_bottlebeer01a_2', joaat('p_bottlebeer01a_2'), _U('fillingComplete'))
end

function BucketFill(pumpAnim)
    DebugPrint('Filling bucket.')
    Filling = true
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    if not pumpAnim then
        TaskStartScenarioInPlaceHash(playerPed, joaat('WORLD_HUMAN_BUCKET_FILL'), -1, true, 0, -1, false)
        Wait(8000)
        ClearPedTasks(playerPed, true, true)
        Wait(4000)
        HidePedWeapons(playerPed, 2, true)
    else
        local taskRun = false
        local DataStruct = DataView.ArrayBuffer(256 * 4)
        local pointsExist = GetScenarioPointsInArea(PlayerCoords, 2.0, DataStruct:Buffer(), 10)

        if not pointsExist then goto NEXT end

        for i = 1, 1 do
            local scenario = DataStruct:GetInt32(8 * i)
            local hash = GetScenarioPointType(scenario)

            if hash == joaat('PROP_HUMAN_PUMP_WATER') or hash == joaat('PROP_HUMAN_PUMP_WATER_BUCKET') then
                taskRun = true
                ClearPedTasksImmediately(playerPed)
                TaskUseScenarioPoint(playerPed, scenario, '', -1.0, true, false, 0, false, -1.0, true)
                Wait(15000)
                ClearPedTasks(playerPed, true, true)
                Wait(5000)
                HidePedWeapons(playerPed, 2, true)
                break
            end
        end

        ::NEXT::
        if not taskRun then
            local animDict = 'amb_work@prop_human_pump_water@female_b@idle_a'
            local animName = 'idle_a'
            if IsPedMale(playerPed) then
                animDict = 'amb_work@prop_human_pump_water@male_a@idle_a'
            end
            PlayAnim(animDict, animName, 1, 10000)
        end
    end

    Filling = false
    if Config.showMessages then
        Core.NotifyRightTip(_U('fillingComplete'), 4000)
    end
    DebugPrint('Bucket filled successfully.')
end

RegisterNetEvent('bcc-water:UseCanteen', function()
    DebugPrint('Using canteen.')
    if CanUseCanteen then
        local result = Core.Callback.TriggerAwait('bcc-water:UpdateCanteen')
        if not result then return end

        DrinkCanteen()
        CanUseCanteen = false
        Wait(6000)
        CanUseCanteen = true
    end
end)

function DrinkCanteen()
    DebugPrint('Drinking from canteen.')
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    local modelHash = joaat('p_cs_canteen_hercule')

    local animDict = 'amb_rest_drunk@world_human_drinking@male_a@idle_a'

    LoadAnim(animDict)
    LoadModel(modelHash, 'p_cs_canteen_hercule')

    Canteen = CreateObject(modelHash, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false, false, true)
    SetEntityVisible(Canteen, true)
    SetEntityAlpha(Canteen, 255, false)
    SetModelAsNoLongerNeeded(modelHash)

    TaskPlayAnim(playerPed, animDict, 'idle_a', 1.0, 1.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(Canteen, playerPed, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true, false, false)
    Wait(5500)
    DeleteObject(Canteen)
    ClearPedTasks(playerPed)
    PlayerStats(false)
end

function WildDrink()
    DebugPrint('Drinking from wild water.')
    PlayAnim('amb_rest_drunk@world_human_bucket_drink@ground@male_a@idle_c', 'idle_h', 1, 10000)
    PlayerStats(true)
    local sicknessChance = Config.sickness.chance

    -- Sickness chance roll
    if (sicknessChance > 0) and (math.random(1, 100) <= sicknessChance) then
        ApplySicknessEffect()
    end
end

RegisterNetEvent('bcc-water:DrinkBottle', function(wild)
    DebugPrint('Drinking from bottle. Wild: ' .. tostring(wild))
    local playerPed = PlayerPedId()
    HidePedWeapons(playerPed, 2, true)

    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    local modelHash = joaat('p_bottlebeer01a_2')
    local animDict = 'amb_rest_drunk@world_human_drinking@male_a@idle_a'
    local animName = 'idle_a'

    LoadAnim(animDict)
    LoadModel(modelHash, 'p_bottlebeer01a_2')

    Bottle = CreateObject(modelHash, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, true, true, false, false, true)
    SetEntityVisible(Bottle, true)
    SetEntityAlpha(Bottle, 255, false)
    SetModelAsNoLongerNeeded(modelHash)

    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(Bottle, playerPed, boneIndex, 0.05, 0.0, 0.05, 15.0, 175.0, 0.0, true, true, false, true, 1, true)
    Wait(5500)
    DeleteObject(Bottle)
    ClearPedTasks(playerPed)

    -- Apply effects
    local sicknessChance = Config.sickness.chance
    if wild and (sicknessChance > 0) and (math.random(1, 100) <= sicknessChance) then
        ApplySicknessEffect()
    end

    PlayerStats(wild)
end)

function PumpDrink()
    DebugPrint('Drinking from pump water.')
    local animDict = 'amb_work@prop_human_pump_water@female_b@idle_c'
    local animName = 'idle_g'
    if IsPedMale(PlayerPedId()) then
        animDict = 'amb_work@prop_human_pump_water@male_a@idle_a'
        animName = 'idle_a'
    end
    PlayAnim(animDict, animName, 1, 5000)
    PlayerStats(true)
end

function WashPlayer(animType)
    DebugPrint('Washing player with animation type: ' .. animType)
    local playerPed = PlayerPedId()

    local animDict = ''
    local animName = 'idle_l'

    if animType == 'ground' then
        animDict = IsPedMale(playerPed)
            and 'amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d'
            or 'amb_misc@world_human_wash_face_bucket@ground@female_a@idle_d'
    elseif animType == 'stand' then
        animDict = IsPedMale(playerPed)
            and 'amb_misc@world_human_wash_face_bucket@table@male_a@idle_d'
            or 'amb_misc@world_human_wash_face_bucket@table@female_a@idle_d'
    else
        print('Invalid animType provided:', animType)
        return
    end

    PlayAnim(animDict, animName, 1, 10000)

    ClearPedEnvDirt(playerPed)
    ClearPedDamageDecalByZone(playerPed, 10, 'ALL')
    ClearPedBloodDamage(playerPed)
    SetPedDirtCleaned(playerPed, 0.0, -1, true, true)

    if tonumber(Config.app) == 11 then
        exports['POS-Metabolism']:ShowerEvent()
    end

    if tonumber(Config.app) == 12 then
        exports.bln_hud:PlayerWash()
    end

    DebugPrint('Player washed successfully.')
end

function ApplySicknessEffect()
    if IsSick then
        DebugPrint('Sickness effect already active, skipping.')
        return
    end

    TriggerServerEvent('bcc-water:UpdateSickness', true)
    DebugPrint('Trigger server event to update sickness status to true.')

    IsSick = true
    local duration = Config.sickness.duration
    local tickInterval = Config.sickness.interval
    local healthPerTick = Config.sickness.health
    local remaining = duration

    DebugPrint('Sickness effect applied.')

    Core.NotifyRightTip(_U('feelingSick'), 4000)

    -- Animation + Health Tick Thread
    CreateThread(function()
        DebugPrint('Starting sickness animation/health tick thread.')
        local playerPed = PlayerPedId()

        while IsSick and remaining > 0 do
            ClearPedTasks(playerPed)
            DebugPrint('Cleared playerPed tasks for sickness animation.')

            local currentHealth = GetEntityHealth(playerPed)
            local newHealth = currentHealth - healthPerTick

            -- Play animation
            if (remaining > (duration / 2)) and (currentHealth > 200) then
                DebugPrint('Playing coughing animation.')
                PlayAnim('amb_wander@code_human_coughing_hacking@male_a@wip_base', 'wip_base', 1, 5000)
            else
                local vomit = math.random(1, 2) == 1 and 'idle_g' or 'idle_h'
                DebugPrint('Playing vomiting animation: ' .. vomit)
                PlayAnim('amb_misc@world_human_vomit@male_a@idle_c', vomit, 1, 5000)
            end

            -- Apply health damage
            if newHealth <= 0 then
                DebugPrint('Player health reached 0 during sickness. Killing player.')
                SetEntityHealth(playerPed, 0)
                break
            else
                SetEntityHealth(playerPed, newHealth)
                DebugPrint('Health reduced by sickness. New health: ' .. newHealth)
            end

            Wait(tickInterval * 1000)
            remaining = remaining - tickInterval
        end

        if IsSick then
            DebugPrint('Sickness ended. Forcing death if still alive.')
            Core.NotifyRightTip(_U('succumbed'), 6000)

            SetEntityHealth(playerPed, 0)
            IsSick = false
            ClearPedTasks(playerPed)

            TriggerServerEvent('bcc-water:UpdateSickness', false)
            DebugPrint('Sickness effect fully cleared.')
        end
    end)
end

RegisterNetEvent('bcc-water:CureSickness', function()
    if IsSick then
        IsSick = false
        ClearPedTasks(PlayerPedId())
        Core.NotifyRightTip(_U('feelingBetter'), 4000)

        TriggerServerEvent('bcc-water:UpdateSickness', false)
        DebugPrint('Trigger server event to update sickness status to false.')
    end
end)

function PlayerStats(isWild)
    DebugPrint('Updating player stats.')
    local playerPed = PlayerPedId()
    local health = GetAttributeCoreValue(playerPed, 0, Citizen.ResultAsInteger())
    local stamina = GetAttributeCoreValue(playerPed, 1, Citizen.ResultAsInteger())
    local thirst = isWild and Config.wildDrink.thirst or Config.canteenDrink.thirst
    local app = tonumber(Config.app)

    local appUpdate = {
        [1] = function() TriggerEvent('vorpmetabolism:changeValue', 'Thirst', thirst * 10) end,
        [2] = function() TriggerEvent('fred:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0) end,
        [3] = function() local data = { AddThirst = thirst } exports.outsider_needs:SetNeedsData(data) end,
        [4] = function() TriggerEvent('fred_meta:consume', 0, thirst, 0, 0.0, 0.0, 0, 0.0, 0.0) end,
        [5] = function() exports.fred_metabolism:consume('thirst', thirst) end,
        [6] = function() TriggerEvent('rsd_metabolism:SetMeta', { drink = thirst }) end,
        [7] = function() TriggerServerEvent('hud.decrease', 'thirst', thirst * 10) end,
        [8] = function() TriggerEvent('hud:client:changeValue', 'Thirst', thirst) end,
        [9] = function() exports['fx-hud']:setStatus('thirst', thirst) end,
        [10] = function() local ClientAPI = exports['mega_metabolism']:api() ClientAPI.addMeta('water', thirst) end,
        [11] = function() exports['POS-Metabolism']:UpdateMultipleStatus({ ["water"] = thirst, ["piss"] = thirst * 0.5 }) end,
        [12] = function() exports.bln_hud:SetThirst(thirst) end,
    }

    local function updateAttribute(attributeIndex, value, maxValue)
        local newValue = math.max(0, math.min(maxValue, value))
        SetAttributeCoreValue(playerPed, attributeIndex, newValue)
    end

    if appUpdate[app] then
        appUpdate[app]()

        local healthConfig = isWild and Config.wildDrink.health or Config.canteenDrink.health
        local staminaConfig = isWild and Config.wildDrink.stamina or Config.canteenDrink.stamina
        local gainHealth = isWild and Config.wildDrink.gainHealth or true
        local gainStamina = isWild and Config.wildDrink.gainStamina or true

        if healthConfig > 0 then
            updateAttribute(0, gainHealth and (health + healthConfig) or (health - healthConfig), 100)
        end

        if staminaConfig > 0 then
            updateAttribute(1, gainStamina and (stamina + staminaConfig) or (stamina - staminaConfig), 100)
        end

        PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
    else
        DebugPrint('Check Config.app setting for correct metabolism value')
    end
    DebugPrint('Player stats updated successfully.')
end
