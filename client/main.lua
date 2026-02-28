local RESOURCE = GetCurrentResourceName()

local isUiOpen = false
local npcPed = nil
local deliveryPed = nil
local deliveryProp = nil
local textUiVisible = false
local currentTextUiText = nil
local interactionMode = 'key'

local function debugPrint(...)
    if Config.Debug then
        print(('[%s]'):format(RESOURCE), ...)
    end
end

local function notify(message, notifyType)
    local msg = message or 'Unknown message'
    local nType = notifyType or 'inform'

    if GetResourceState('ox_lib') == 'started' then
        lib.notify({
            title = 'Black Market',
            description = msg,
            type = nType
        })
        return
    end

    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(msg, nType)
        return
    end

    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', msg, nType)
        return
    end

    print(('[%s] %s'):format(RESOURCE, msg))
end

local function loadModel(modelName)
    local model = type(modelName) == 'number' and modelName or joaat(modelName)

    if not IsModelInCdimage(model) then
        return nil
    end

    RequestModel(model)
    local attempts = 0

    while not HasModelLoaded(model) do
        Wait(50)
        attempts = attempts + 1
        if attempts > 120 then
            return nil
        end
    end

    return model
end

local function createNpc()
    local model = loadModel(Config.Npc.model)
    if not model then
        debugPrint('Failed to load NPC model:', Config.Npc.model)
        return
    end

    local coords = Config.Npc.coords
    npcPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

    SetEntityAsMissionEntity(npcPed, true, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetEntityInvincible(npcPed, true)
    FreezeEntityPosition(npcPed, true)

    if Config.Npc.scenario and Config.Npc.scenario ~= '' then
        TaskStartScenarioInPlace(npcPed, Config.Npc.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(model)
end

local function loadAnimDict(dict)
    if type(dict) ~= 'string' or dict == '' then
        return false
    end

    RequestAnimDict(dict)
    local attempts = 0

    while not HasAnimDictLoaded(dict) do
        Wait(50)
        attempts = attempts + 1
        if attempts > 100 then
            return false
        end
    end

    return true
end

local function createDeliveryNpc()
    local delivery = Config.DeliveryNpc or {}
    local coords = delivery.coords
    if not coords then
        return
    end

    if deliveryProp and DoesEntityExist(deliveryProp) then
        DeleteEntity(deliveryProp)
        deliveryProp = nil
    end

    if deliveryPed and DoesEntityExist(deliveryPed) then
        DeleteEntity(deliveryPed)
        deliveryPed = nil
    end

    local model = loadModel(delivery.model or 's_m_m_dockwork_01')
    if not model then
        debugPrint('Failed to load delivery NPC model:', delivery.model)
        return
    end

    deliveryPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    SetEntityAsMissionEntity(deliveryPed, true, true)
    SetBlockingOfNonTemporaryEvents(deliveryPed, true)
    SetEntityInvincible(deliveryPed, true)
    FreezeEntityPosition(deliveryPed, true)

    local boxModel = loadModel(delivery.carryBoxModel or 'hei_prop_heist_box')
    if boxModel then
        deliveryProp = CreateObject(boxModel, coords.x, coords.y, coords.z + 0.2, false, false, false)
        SetEntityAsMissionEntity(deliveryProp, true, true)

        AttachEntityToEntity(
            deliveryProp,
            deliveryPed,
            GetPedBoneIndex(deliveryPed, tonumber(delivery.carryBoxBone) or 57005),
            0.12, 0.0, -0.26,
            -55.0, -115.0, 20.0,
            true, true, false, true, 1, true
        )

        SetModelAsNoLongerNeeded(boxModel)
    end

    if loadAnimDict('anim@heists@box_carry@') then
        TaskPlayAnim(deliveryPed, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    SetModelAsNoLongerNeeded(model)
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.33, 0.33)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(255, 255, 255, 220)

    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function showTextUi(text)
    if textUiVisible and currentTextUiText == text then return end
    if GetResourceState('ox_lib') ~= 'started' then return end

    if textUiVisible and currentTextUiText ~= text then
        lib.hideTextUI()
        textUiVisible = false
    end

    lib.showTextUI(text)
    textUiVisible = true
    currentTextUiText = text
end

local function hideTextUi()
    if not textUiVisible then return end
    if GetResourceState('ox_lib') ~= 'started' then
        textUiVisible = false
        currentTextUiText = nil
        return
    end

    lib.hideTextUI()
    textUiVisible = false
    currentTextUiText = nil
end

local function closeMarketUi(sendMessage)
    if not isUiOpen then return end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    isUiOpen = false

    if sendMessage ~= false then
        SendNUIMessage({ action = 'f4:blackmarket:close' })
    end
end

local function fetchOpenData()
    return lib.callback.await('f4:blackmarket:server:getOpenData', false)
end

local function pushSnapshotToUi(action, response)
    if not response or not response.success or not response.data then
        return false
    end

    SendNUIMessage({
        action = action,
        payload = response.data
    })

    return true
end

local function openMarketUi()
    if isUiOpen then return end

    local response = fetchOpenData()
    if not response or not response.success then
        notify(response and response.message or 'Market is unavailable right now.', 'error')
        return
    end

    isUiOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    hideTextUi()

    pushSnapshotToUi('f4:blackmarket:open', response)

    -- Retry sync after open to avoid race conditions with slow NUI boot.
    SetTimeout(300, function()
        if not isUiOpen then return end
        pushSnapshotToUi('f4:blackmarket:sync', fetchOpenData())
    end)

    SetTimeout(900, function()
        if not isUiOpen then return end
        pushSnapshotToUi('f4:blackmarket:sync', fetchOpenData())
    end)

    SetTimeout(2000, function()
        if not isUiOpen then return end
        pushSnapshotToUi('f4:blackmarket:sync', fetchOpenData())
    end)
end

local function claimDeliveries()
    local response = lib.callback.await('f4:blackmarket:server:claimDeliveries', false)
    if not response then
        notify('Could not contact delivery operator right now.', 'error')
        return
    end

    if response.data and isUiOpen then
        SendNUIMessage({
            action = 'f4:blackmarket:sync',
            payload = response.data
        })
    end

    if response.success then
        notify(response.message or 'Delivery collected.', 'success')
        return
    end

    if response.code == 'no_pending' then
        notify(response.message or 'No pending deliveries.', 'inform')
        return
    end

    notify(response.message or 'Delivery could not be collected.', 'error')
end

local function setupNpcInteraction()
    interactionMode = 'key'

    local hasVendor = npcPed and DoesEntityExist(npcPed)
    local hasDelivery = deliveryPed and DoesEntityExist(deliveryPed)
    if not hasVendor and not hasDelivery then
        return
    end

    local hasOxTarget = GetResourceState('ox_target') == 'started'
    local hasQbTarget = GetResourceState('qb-target') == 'started'

    if hasOxTarget then
        interactionMode = 'target'

        if hasVendor then
            exports.ox_target:addLocalEntity(npcPed, {
                {
                    name = 'f4:blackmarket:open',
                    icon = 'fa-solid fa-store',
                    label = 'Open Black Market',
                    distance = Config.OpenDistance + 0.5,
                    onSelect = function()
                        openMarketUi()
                    end
                }
            })
        end

        if hasDelivery then
            exports.ox_target:addLocalEntity(deliveryPed, {
                {
                    name = 'f4:blackmarket:claim',
                    icon = 'fa-solid fa-box-open',
                    label = 'Collect Delivery',
                    distance = (Config.DeliveryNpc and Config.DeliveryNpc.openDistance or Config.OpenDistance) + 0.5,
                    onSelect = function()
                        claimDeliveries()
                    end
                }
            })
        end

        return
    end

    if hasQbTarget then
        interactionMode = 'target'

        if hasVendor then
            exports['qb-target']:AddTargetEntity(npcPed, {
                options = {
                    {
                        icon = 'fas fa-store',
                        label = 'Open Black Market',
                        action = function()
                            openMarketUi()
                        end
                    }
                },
                distance = Config.OpenDistance + 0.5
            })
        end

        if hasDelivery then
            exports['qb-target']:AddTargetEntity(deliveryPed, {
                options = {
                    {
                        icon = 'fas fa-box-open',
                        label = 'Collect Delivery',
                        action = function()
                            claimDeliveries()
                        end
                    }
                },
                distance = (Config.DeliveryNpc and Config.DeliveryNpc.openDistance or Config.OpenDistance) + 0.5
            })
        end

        return
    end
end

RegisterNUICallback('f4:blackmarket:ready', function(_, cb)
    if isUiOpen then
        pushSnapshotToUi('f4:blackmarket:sync', fetchOpenData())
    end

    cb({ success = true })
end)

RegisterNUICallback('f4:blackmarket:close', function(_, cb)
    closeMarketUi(false)
    cb({ success = true })
end)

RegisterNUICallback('f4:blackmarket:refresh', function(_, cb)
    local response = fetchOpenData()
    pushSnapshotToUi('f4:blackmarket:sync', response)

    cb(response or { success = false, message = 'Failed to refresh market data.' })
end)

RegisterNUICallback('f4:blackmarket:purchase', function(data, cb)
    local response = lib.callback.await('f4:blackmarket:server:purchase', false, data)

    pushSnapshotToUi('f4:blackmarket:sync', response)

    cb(response or { success = false, message = 'Purchase request failed.' })
end)

RegisterNUICallback('f4:blackmarket:batchPurchase', function(data, cb)
    local response = lib.callback.await('f4:blackmarket:server:batchPurchase', false, data)

    pushSnapshotToUi('f4:blackmarket:sync', response)

    cb(response or { success = false, message = 'Batch purchase request failed.' })
end)

CreateThread(function()
    createNpc()
    createDeliveryNpc()
    setupNpcInteraction()

    local openMarketText = '[E] Open Black Market'
    local collectDeliveryText = '[E] Collect Delivery'

    while true do
        local sleep = 1250

        local vendorMissing = (not npcPed or not DoesEntityExist(npcPed))
        local deliveryMissing = (not deliveryPed or not DoesEntityExist(deliveryPed))

        if vendorMissing or deliveryMissing then
            hideTextUi()
            if vendorMissing then
                createNpc()
            end
            if deliveryMissing then
                createDeliveryNpc()
            end
            setupNpcInteraction()
            sleep = 1500
        elseif interactionMode == 'target' then
            hideTextUi()
            sleep = 2000
        else
            local playerCoords = GetEntityCoords(PlayerPedId())
            local promptText = nil
            local promptCoords = nil
            local promptAction = nil

            if not isUiOpen then
                local deliveryCfg = Config.DeliveryNpc or {}
                local deliveryCoordsRaw = deliveryCfg.coords
                if deliveryCoordsRaw then
                    local deliveryCoords = vec3(deliveryCoordsRaw.x, deliveryCoordsRaw.y, deliveryCoordsRaw.z)
                    local deliveryDistance = #(playerCoords - deliveryCoords)
                    local deliveryDrawDistance = tonumber(deliveryCfg.drawDistance) or Config.DrawDistance
                    local deliveryOpenDistance = tonumber(deliveryCfg.openDistance) or Config.OpenDistance

                    if deliveryDistance <= deliveryDrawDistance then
                        promptText = collectDeliveryText
                        promptCoords = vec3(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z + 1.05)

                        if deliveryDistance <= deliveryOpenDistance then
                            promptAction = claimDeliveries
                            sleep = 35
                        else
                            sleep = 220
                        end
                    end
                end

                if not promptText then
                    local vendorCoords = vec3(Config.Npc.coords.x, Config.Npc.coords.y, Config.Npc.coords.z)
                    local vendorDistance = #(playerCoords - vendorCoords)

                    if vendorDistance <= Config.DrawDistance then
                        promptText = openMarketText
                        promptCoords = vec3(vendorCoords.x, vendorCoords.y, vendorCoords.z + 1.05)

                        if vendorDistance <= Config.OpenDistance then
                            promptAction = openMarketUi
                            sleep = 35
                        else
                            sleep = 220
                        end
                    end
                end
            else
                sleep = 250
            end

            if promptText and promptCoords then
                if GetResourceState('ox_lib') == 'started' then
                    showTextUi(promptText)
                else
                    drawText3D(promptCoords, promptText)
                end
            else
                hideTextUi()
            end

            if promptAction and IsControlJustReleased(0, Config.InteractKey) then
                promptAction()
            end
        end

        Wait(sleep)
    end
end)

RegisterCommand('blackmarket', function()
    openMarketUi()
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE then return end

    hideTextUi()
    closeMarketUi(false)

    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
    end

    if deliveryProp and DoesEntityExist(deliveryProp) then
        DeleteEntity(deliveryProp)
    end

    if deliveryPed and DoesEntityExist(deliveryPed) then
        DeleteEntity(deliveryPed)
    end
end)
