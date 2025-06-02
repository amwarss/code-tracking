QBCore = exports['qb-core']:GetCoreObject()
local isTracking = false
local trackingBlip = nil
local trackingTimer = nil
local trackingUpdateThread = nil
local currentTargetId = nil
local radarBlips = {}
local trackingData = {}
local Strings = {}

local function LoadLanguage()
    local lang = Config.Locale or 'en'
    
    if lang == 'ar' then
        Strings = {
        ['tracking_started'] = 'تم بدء تعقب الهدف بنجاح',
        ['tracking_ended'] = 'انتهى وقت التعقب',
        ['tracking_blocked'] = 'تم إحباط محاولة تعقبك بنجاح',
        ['tracking_success'] = 'تم تعقب موقعك! كن حذراً',
        ['no_permission'] = 'ليست لديك صلاحية استخدام هذا الجهاز',
        ['player_offline'] = 'الهدف غير متصل أو الرقم غير صحيح',
        ['tracking_failed'] = 'فشل تعقب الهدف، تم إحباط المحاولة',
        ['tracking_title'] = 'نظام التعقب العسكري',
        ['phone_input_label'] = 'رقم الهاتف المستهدف',
        ['phone_input_desc'] = 'أدخل رقم الهاتف المراد تعقبه (10 أرقام)',
        ['vpn_protection_blocked'] = 'فشل التعقب - الهدف محمي بتشفير متقدم VPN',
        ['vpn_protection_active'] = 'تم صد محاولة تعقب بنجاح - VPN Protection نشط',
        ['vpn_reward_received'] = 'حصلت على مكافأة لاستخدام VPN Protection',
        ['blip_name'] = 'موقع الهدف',
        ['use_tracker'] = 'استخدام جهاز التعقب',
        ['tracker_item_name'] = 'جهاز التعقب العسكري',
        ['target_detected'] = 'تم رصد الهدف',
        ['signal_lost'] = 'فقدان الإشارة',
        ['encryption_active'] = 'التشفير نشط',
        ['minigame_instruction'] = 'اضغط الأزرار بسرعة لتجنب التعقب!',
        ['tracking_in_progress'] = 'عملية التعقب جارية...',
        ['invalid_phone'] = 'رقم الهاتف غير صحيح - يجب أن يكون 10 أرقام',
        ['detection_warning'] = 'تحذير: يبدو أن هناك من يحاول تعقبك!',
        ['access_denied'] = 'تم رفض الوصول - مستوى التصريح غير كافي',
        ['system_online'] = 'النظام متصل وجاهز للعمل',
        ['system_offline'] = 'النظام غير متاح حالياً',
        ['coordinates_acquired'] = 'تم الحصول على الإحداثيات',
        ['phone_not_carried'] = 'الهدف لا يحمل هاتفه معه',
        ['phone_battery_dead'] = 'هاتف الهدف مغلق - البطارية فارغة', 
        ['phone_airplane_mode'] = 'هاتف الهدف في وضع الطيران',
        ['phone_not_registered'] = 'رقم الهاتف غير مسجل في النظام',
        ['target_owner_offline'] = 'مالك الهاتف غير متصل حالياً',
        ['target_moving'] = 'الهدف يتحرك',
        ['signal_strength'] = 'قوة الإشارة: قوية',
        ['encryption_level'] = 'مستوى التشفير: AES-256',
        ['clearance_level'] = 'مستوى التصريح: المستوى 5',
        ['connection_established'] = 'تم تأسيس الاتصال بنجاح'
        }
    else
        Strings = {
        ['tracking_started'] = 'Target tracking initiated successfully',
        ['tracking_ended'] = 'Tracking session terminated',
        ['tracking_blocked'] = 'Successfully blocked tracking attempt',
        ['tracking_success'] = 'Your location has been compromised!',
        ['no_permission'] = 'Access denied - Insufficient clearance level',
        ['player_offline'] = 'Target is offline or invalid number',
        ['tracking_failed'] = 'Tracking failed - Target evaded detection',
        ['tracking_title'] = 'Military Tracking System',
        ['phone_not_carried'] = 'Target is not carrying their phone',
        ['phone_battery_dead'] = 'Target phone is dead - battery empty',
        ['phone_airplane_mode'] = 'Target phone is in airplane mode', 
        ['phone_not_registered'] = 'Phone number not registered in system',
        ['target_owner_offline'] = 'Phone owner is currently offline',
        ['phone_input_label'] = 'Target Phone Number',
        ['vpn_protection_blocked'] = 'Tracking failed - Target protected by advanced VPN encryption',
        ['vpn_protection_active'] = 'Tracking attempt blocked successfully - VPN Protection active',
        ['vpn_reward_received'] = 'You received a reward for using VPN Protection',
        ['phone_input_desc'] = 'Enter target phone number (10 digits)',
        ['blip_name'] = 'Target Location',
        ['use_tracker'] = 'Use Tracking Device',
        ['tracker_item_name'] = 'Military Tracking Device',
        ['target_detected'] = 'Target Detected',
        ['signal_lost'] = 'Signal Lost',
        ['encryption_active'] = 'Encryption Active',
        ['minigame_instruction'] = 'Press buttons quickly to avoid tracking!',
        ['tracking_in_progress'] = 'Tracking in progress...',
        ['invalid_phone'] = 'Invalid phone number - Must be 10 digits',
        ['detection_warning'] = 'Warning: Someone is trying to track you!',
        ['access_denied'] = 'Access denied - Insufficient clearance',
        ['system_online'] = 'System online and ready',
        ['system_offline'] = 'System currently unavailable',
        ['coordinates_acquired'] = 'Coordinates acquired',
        ['target_moving'] = 'Target is moving',
        ['signal_strength'] = 'Signal Strength: Strong',
        ['encryption_level'] = 'Encryption Level: AES-256',
        ['clearance_level'] = 'Clearance Level: Level 5',
        ['connection_established'] = 'Connection established successfully'
        }
    end
end

local function HasPermission()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return false end
    
    for _, job in ipairs(Config.AllowedJobs) do
        if PlayerData.job.name == job and PlayerData.job.onduty then
            return true
        end
    end
    
    if Config.AllowSpecialRanks then
        for _, rank in ipairs(Config.SpecialRanks) do
            if PlayerData.job.grade.level >= rank.level and PlayerData.job.name == rank.job then
                return true
            end
        end
    end
    
    return false
end

local function CreateTrackingBlip(coords, targetName)
    if trackingBlip and DoesBlipExist(trackingBlip) then
        RemoveBlip(trackingBlip)
    end
    
    for _, blip in pairs(radarBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    radarBlips = {}

    if trackingTimer then
        Citizen.ClearTimeout(trackingTimer)
    end

    if trackingUpdateThread then
        trackingUpdateThread = nil
    end

    trackingBlip = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Tracking.Radius)
    SetBlipHighDetail(trackingBlip, true)
    SetBlipColour(trackingBlip, 1)
    SetBlipAlpha(trackingBlip, 100)

    local exactBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(exactBlip, 480)
    SetBlipColour(exactBlip, 1)
    SetBlipDisplay(exactBlip, 4)
    SetBlipScale(exactBlip, 1.0)
    SetBlipAsShortRange(exactBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Strings['blip_name'] .. (targetName and (" - " .. targetName) or ""))
    EndTextCommandSetBlipName(exactBlip)
    
    table.insert(radarBlips, exactBlip)

    for i = 1, 3 do
        Citizen.CreateThread(function()
            Citizen.Wait(i * 500)
            local pulseBlip = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Tracking.Radius * (0.3 * i))
            SetBlipHighDetail(pulseBlip, true)
            SetBlipColour(pulseBlip, 2)
            SetBlipAlpha(pulseBlip, 50)
            table.insert(radarBlips, pulseBlip)
            
            Citizen.Wait(2000)
            if DoesBlipExist(pulseBlip) then
                RemoveBlip(pulseBlip)
            end
        end)
    end

    local remainingTime = Config.Tracking.Duration / 1000
    
    trackingUpdateThread = Citizen.CreateThread(function()
        while remainingTime > 0 and isTracking do
            if currentTargetId then
                TriggerServerEvent('code:tracking:requestLocationUpdate', currentTargetId)
            end
            
            if remainingTime <= 10 then
                QBCore.Functions.Notify(Strings['signal_lost'] .. " (" .. remainingTime .. "s)", 'error', 1000)
            elseif remainingTime % 30 == 0 then
                QBCore.Functions.Notify(Strings['target_detected'], 'success', 2000)
            elseif remainingTime % 15 == 0 then
                QBCore.Functions.Notify(Strings['target_moving'], 'info', 2000)
            end
            
            Citizen.Wait(5000)
            remainingTime = remainingTime - 5
        end
    end)
    
    trackingTimer = Citizen.CreateThread(function()
        Citizen.Wait(Config.Tracking.Duration)
        
        if DoesBlipExist(trackingBlip) then RemoveBlip(trackingBlip) end
        for _, blip in pairs(radarBlips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
        radarBlips = {}
        isTracking = false
        trackingData = {}
        currentTargetId = nil
        trackingUpdateThread = nil
        
        QBCore.Functions.Notify(Strings['tracking_ended'], 'info', 5000)
    end)
    
    trackingData = {
        coords = coords,
        startTime = GetGameTimer(),
        targetName = targetName
    }
end

local function OpenTrackingUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showUI'
    })
end

local function CloseTrackingUI()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeTracker"
    })
end

local function StartCounterSurveillanceMiniGame(requesterId)
    minigameActive = true
    
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    QBCore.Functions.Notify(Strings['minigame_instruction'], 'error', 3000)
    
    minigameTimer = SetTimeout(15000, function()
        if minigameActive then
            minigameActive = false
            TriggerServerEvent('code:tracking:targetMinigameResult', requesterId, true)
            QBCore.Functions.Notify('Too late! You couldn escape being tracked.', 'error', 5000)
        end
    end)
    
    local success = false
    local rounds = math.random(1, 1)
    local completedRounds = 0
    
    CreateThread(function()
        for i = 1, rounds do
            if not minigameActive then break end
            
            Citizen.Wait(500)
            
            if not minigameActive then break end
            
            local gameResultCallback = exports["kane-chopskill"]:Minigame()
            
            if not minigameActive then break end
            
            if gameResultCallback and gameResultCallback == true then
                completedRounds = completedRounds + 1
                PlaySoundFrontend(-1, "SUCCESS", "HUD_MINI_GAME_SOUNDSET", 1)
            else
                PlaySoundFrontend(-1, "FAILURE", "HUD_MINI_GAME_SOUNDSET", 1)
                break
            end
        end
        
        if minigameActive then
            minigameActive = false
            
            if minigameTimer then
                ClearTimeout(minigameTimer)
                minigameTimer = nil
            end
            
            success = completedRounds >= math.ceil(rounds * 0.7)
            
            if success then
                QBCore.Functions.Notify(Strings['tracking_blocked'], 'success', 5000)
                TriggerServerEvent('code:tracking:targetMinigameResult', requesterId, false)
                
                CreateThread(function()
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed)
                    
                    for i = 1, 5 do
                        local effect = StartParticleFxLoopedAtCoord("scr_xs_celebration", coords.x, coords.y, coords.z + 2.0, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                        Citizen.Wait(200)
                        StopParticleFxLooped(effect, 0)
                    end
                end)
            else
                QBCore.Functions.Notify(Strings['tracking_success'], 'error', 5000)
                TriggerServerEvent('code:tracking:targetMinigameResult', requesterId, true)
                
                CreateThread(function()
                    local playerPed = PlayerPedId()
                    for i = 1, 10 do
                        SetFlash(0, 0, 100, 500, 100)
                        Citizen.Wait(100)
                    end
                end)
            end
        end
    end)
end

RegisterNetEvent('code:tracking:cleanupMinigame', function()
    minigameActive = false
    if minigameTimer then
        ClearTimeout(minigameTimer)
        minigameTimer = nil
    end
end)

RegisterNetEvent('code:tracking:targetMinigame', function(requesterId)
    minigameActive = false
    if minigameTimer then
        ClearTimeout(minigameTimer)
        minigameTimer = nil
    end
    
    StartCounterSurveillanceMiniGame(requesterId)
end)

CreateThread(function()
    LoadLanguage()
    
    RegisterNUICallback('startTracking', function(data, cb)
        local phoneNumber = tostring(data.phoneNumber)
        
        if not HasPermission() then
            cb({ success = false, message = Strings['no_permission'] })
            return
        end
        
        if not phoneNumber or phoneNumber == "" then
            cb({ success = false, message = Strings['invalid_phone'] })
            return
        end
        
        if string.len(phoneNumber) ~= 10 then
            cb({ success = false, message = Strings['invalid_phone'] })
            return
        end
        
        QBCore.Functions.TriggerCallback('code:tracking:checkPlayerByPhone', function(isOnline, playerId, phoneStatus, targetName, message)
            if not isOnline then
                cb({ success = false, message = message or Strings['player_offline'] })
                return
            end
            
            cb({ success = true, message = Strings['tracking_in_progress'] })
            TriggerServerEvent('code:tracking:startTracking', playerId, phoneNumber)
            CloseTrackingUI()
        end, phoneNumber)
    end)
    
    RegisterNUICallback('closeUI', function(data, cb)
        CloseTrackingUI()
        cb('ok')
    end)
    
    RegisterNUICallback('getPlayerData', function(data, cb)
        local PlayerData = QBCore.Functions.GetPlayerData()
        cb({
            job = PlayerData.job.name,
            rank = PlayerData.job.grade.name,
            onduty = PlayerData.job.onduty,
            hasPermission = HasPermission()
        })
    end)
end)

RegisterNetEvent('code:tracking:startClientTracking', function(coords, targetData, targetId)
    if isTracking then return end
    isTracking = true
    currentTargetId = targetId
    
    local targetName = targetData and targetData.name or nil
    QBCore.Functions.Notify(Strings['tracking_started'], 'success', 3000)
    
    PlaySoundFrontend(-1, "RADAR_ACTIVATE", "DLC_BTL_DRONE_RADAR_SOUNDS", 1)
    
    CreateTrackingBlip(coords, targetName)
    
    SendNUIMessage({
        action = "trackingStarted",
        coords = coords,
        targetName = targetName,
        duration = Config.Tracking.Duration
    })
end)

RegisterNetEvent('code:tracking:targetMinigame', function(requesterId)
    StartCounterSurveillanceMiniGame(requesterId)
end)

RegisterNetEvent('code:tracking:useTrackerItem', function()
    if not HasPermission() then
        cb({ success = true, message = Strings['no_permission'] })
        return
    end
    
    OpenTrackingUI()
end)

RegisterNetEvent('code:tracking:updateTargetLocation', function(coords)
    if not isTracking then return end
    
    if trackingBlip and DoesBlipExist(trackingBlip) then
        SetBlipCoords(trackingBlip, coords.x, coords.y, coords.z)
    end
    
    for _, blip in pairs(radarBlips) do
        if DoesBlipExist(blip) then
            SetBlipCoords(blip, coords.x, coords.y, coords.z)
        end
    end
    
    Citizen.CreateThread(function()
        local updateBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(updateBlip, 161)
        SetBlipColour(updateBlip, 3)
        SetBlipScale(updateBlip, 0.8)
        SetBlipAlpha(updateBlip, 200)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Target blip")
        EndTextCommandSetBlipName(updateBlip)
        
        Citizen.Wait(3000)
        if DoesBlipExist(updateBlip) then
            RemoveBlip(updateBlip)
        end
    end)
    
    trackingData.coords = coords
    
end)

RegisterNetEvent('code:tracking:detectionWarning', function()    
    Citizen.CreateThread(function()
        for i = 1, 5 do
            SetFlash(100, 0, 0, 200, 100)
            Citizen.Wait(300)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if trackingBlip and DoesBlipExist(trackingBlip) then
        RemoveBlip(trackingBlip)
    end
    
    for _, blip in pairs(radarBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    if trackingTimer then
        Citizen.ClearTimeout(trackingTimer)
    end
    
    if trackingUpdateThread then
        trackingUpdateThread = nil
    end
    
    currentTargetId = nil
    CloseTrackingUI()
end)

if Config.Debug then
    RegisterCommand('debugtracker', function()
        if HasPermission() then
            OpenTrackingUI()
        end
    end, false)
end