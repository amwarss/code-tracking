QBCore = exports['qb-core']:GetCoreObject()

local trackingSessions = {}
local trackingLogs = {}
local blockedAttempts = {}
local Strings = {}

local function LoadLanguage()
    local lang = Config.Locale or 'ar'
    Strings = Config.Strings[lang] or Config.Strings['ar']
end

local function SendCustomNotification(source, message, type, duration)
    TriggerClientEvent('code:tracking:customNotification', source, message, type, duration)
end

local function HasPermission(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    for _, job in ipairs(Config.AllowedJobs) do
        if Player.PlayerData.job.name == job and Player.PlayerData.job.onduty then
            return true
        end
    end
    
    if Config.AllowSpecialRanks then
        for _, rank in ipairs(Config.SpecialRanks) do
            if Player.PlayerData.job.grade.level >= rank.level and Player.PlayerData.job.name == rank.job then
                return true
            end
        end
    end
    
    return false
end

local function LogTrackingAttempt(requesterId, targetId, phoneNumber, success, reason)
    local requester = QBCore.Functions.GetPlayer(requesterId)
    local target = QBCore.Functions.GetPlayer(targetId)
    
    local logEntry = {
        timestamp = os.date('%Y-%m-%d %H:%M:%S'),
        requester = {
            id = requesterId,
            name = requester and requester.PlayerData.charinfo.firstname .. ' ' .. requester.PlayerData.charinfo.lastname or 'Unknown',
            job = requester and requester.PlayerData.job.name or 'Unknown',
            citizenid = requester and requester.PlayerData.citizenid or 'Unknown'
        },
        target = {
            id = targetId,
            name = target and target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname or 'Unknown',
            citizenid = target and target.PlayerData.citizenid or 'Unknown',
            phone = phoneNumber
        },
        success = success,
        reason = reason or 'Unknown'
    }
    
    table.insert(trackingLogs, logEntry)
    
    if Config.Database.SaveLogs then
        MySQL.insert('INSERT INTO tracking_logs (requester_id, requester_name, target_id, target_name, phone_number, success, reason, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            logEntry.requester.citizenid,
            logEntry.requester.name,
            logEntry.target.citizenid,
            logEntry.target.name,
            phoneNumber,
            success and 1 or 0,
            reason,
            logEntry.timestamp
        })
    end   
end

local function IsSpamming(source)
    local currentTime = GetGameTimer()
    if not blockedAttempts[source] then
        blockedAttempts[source] = {count = 1, lastAttempt = currentTime}
        return false
    end
    
    local timeDiff = currentTime - blockedAttempts[source].lastAttempt
    if timeDiff < Config.AntiSpam.Cooldown then
        blockedAttempts[source].count = blockedAttempts[source].count + 1
        if blockedAttempts[source].count >= Config.AntiSpam.MaxAttempts then
            return true
        end
    else
        blockedAttempts[source] = {count = 1, lastAttempt = currentTime}
    end
    
    blockedAttempts[source].lastAttempt = currentTime
    return false
end

QBCore.Functions.CreateCallback('code:tracking:checkPlayerByPhone', function(source, cb, phoneNumber)
    if not phoneNumber or type(phoneNumber) ~= 'string' then
        return cb(false, nil, false, nil, 'Invalid phone number')
    end
    
    phoneNumber = string.gsub(phoneNumber, '%D', '')
    if string.len(phoneNumber) ~= Config.phoneNumber then
        return cb(false, nil, false, nil, 'Phone number must be ' .. Config.phoneNumber .. ' digits')
    end
    
    local searchResults = SearchPhoneInDatabase(phoneNumber)
    
    if not searchResults or #searchResults == 0 then 
        LogTrackingAttempt(source, nil, phoneNumber, false, 'Unregistered phone number')
        return cb(false, nil, false, nil, 'The phone number is not registered in any system.') 
    end

    local target = nil
    local phoneSystem = nil
    
    for _, result in ipairs(searchResults) do
        local tempTarget = QBCore.Functions.GetPlayerByCitizenId(result.owner_id)
        if tempTarget then
            target = tempTarget
            phoneSystem = result.system
            break
        end
    end
    
    if not target then 
        LogTrackingAttempt(source, nil, phoneNumber, false, 'Owner is offline')
        return cb(false, nil, false, nil, 'The phone owner is currently offline.') 
    end

    local targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
    
    local hasPhone = target.Functions.GetItemByName('phone')
    if not hasPhone or hasPhone.amount <= 0 then
        LogTrackingAttempt(source, target.PlayerData.source, phoneNumber, false, 'The phone is not with the target')
        return cb(false, nil, false, nil, 'The target does not have his phone with him.')
    end
    
    local phoneOnNetwork = true
    
    if Config.Tracking.CheckNetworkStatus then
        local phoneData = target.Functions.GetItemByName('phone').info
        if phoneData and phoneData.battery then
            if phoneData.battery <= 0 then
                phoneOnNetwork = false
                LogTrackingAttempt(source, target.PlayerData.source, phoneNumber, false, 'Phone battery is empty')
                return cb(false, nil, false, nil, 'Target phone is off - battery dead')
            end
        end
        
        if phoneData and phoneData.airplane_mode then
            phoneOnNetwork = false
            LogTrackingAttempt(source, target.PlayerData.source, phoneNumber, false, 'The phone is in airplane mode')
            return cb(false, nil, false, nil, 'Target phone in airplane mode')
        end
    end
    
    cb(true, target.PlayerData.source, phoneOnNetwork, targetName, 'Successfully found target in ' .. phoneSystem)
end)

QBCore.Functions.CreateUseableItem(Config.TrackerItem, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not HasPermission(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Access denied - Insufficient clearance level', 'error')
        return
    end
    
    if IsSpamming(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Dont Spam', 'error')
        return
    end
    
    TriggerClientEvent('code:tracking:useTrackerItem', source)
end)

local function HasVPNProtection(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local hasVPN = Player.Functions.GetItemByName('vpn_protection')
    if hasVPN and hasVPN.amount > 0 then
        return true
    end
    
    return false
end

RegisterNetEvent('code:tracking:startTracking', function(targetId, phoneNumber)
    local src = source
    
    if not HasPermission(src) then
        print(string.format('^1[TRACKING] ^7Unauthorized use attempt by ID: %s^0', src))
        LogTrackingAttempt(src, targetId, phoneNumber, false, 'No permission')
        return
    end
    
    if IsSpamming(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Dont Spam', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Target offline', 'error')
        LogTrackingAttempt(src, targetId, phoneNumber, false, 'Target offline')
        return
    end
    
    if HasVPNProtection(targetPlayer.PlayerData.source) then
        TriggerClientEvent('QBCore:Notify', src, 'Tracking failed - Target is protected with advanced encryption ', 'error')
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'A tracking attempt was successfully repelled. - VPN Protection', 'success')
        
        LogTrackingAttempt(src, targetId, phoneNumber, false, 'VPN Protection Active')
        
        if Config.Rewards and Config.Rewards.VPNProtectionReward and Config.Rewards.VPNProtectionReward > 0 then
            targetPlayer.Functions.AddMoney('cash', Config.Rewards.VPNProtectionReward, 'VPN Protection Reward')
            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'I got rewarded for using VPN Protection: $' .. Config.Rewards.VPNProtectionReward, 'success')
        end
        
        return
    end

    if Config.SafeZones and Config.SafeZones.Enabled then
        if not targetPlayer or not targetPlayer.PlayerData or not targetPlayer.PlayerData.source then
            TriggerClientEvent('QBCore:Notify', src, 'Target player not found', 'error')
            LogTrackingAttempt(src, targetId, phoneNumber, false, 'Target player not found')
            return
        end
        
        local targetPed = GetPlayerPed(targetPlayer.PlayerData.source)
        if not targetPed or targetPed == 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Target player not available', 'error')
            LogTrackingAttempt(src, targetId, phoneNumber, false, 'Target player not available')
            return
        end
        
        local targetCoords = GetEntityCoords(targetPed)
        if not targetCoords then
            TriggerClientEvent('QBCore:Notify', src, 'Could not get target location', 'error')
            LogTrackingAttempt(src, targetId, phoneNumber, false, 'Could not get target location')
            return
        end
        
        for _, zone in ipairs(Config.SafeZones.Zones) do
            if zone.x and zone.y and zone.z and zone.radius then
                local distance = #(vector3(targetCoords.x, targetCoords.y, targetCoords.z) - vector3(zone.x, zone.y, zone.z))
                if distance <= zone.radius then
                    TriggerClientEvent('QBCore:Notify', src, 'Target in safe zone', 'error')
                    LogTrackingAttempt(src, targetId, phoneNumber, false, 'Target in safe zone')
                    return
                end
            end
        end
    end
    
    local sessionId = 'track_' .. src .. '_' .. targetId .. '_' .. os.time()
    trackingSessions[sessionId] = {
        requesterId = src,
        targetId = targetId,
        phoneNumber = phoneNumber,
        startTime = os.time(),
        active = true
    }
    
    TriggerClientEvent('code:tracking:targetMinigame', targetPlayer.PlayerData.source, src, sessionId)
    
    SetTimeout(Config.Tracking.MinigameTimeout or 15000, function()
        if trackingSessions[sessionId] and trackingSessions[sessionId].active then
            trackingSessions[sessionId].active = false
            
            local currentTargetPlayer = QBCore.Functions.GetPlayer(targetId)
            if currentTargetPlayer then
                local targetPed = GetPlayerPed(currentTargetPlayer.PlayerData.source)
                if targetPed and targetPed ~= 0 then
                    local coords = GetEntityCoords(targetPed)
                    local targetName = currentTargetPlayer.PlayerData.charinfo.firstname .. ' ' .. currentTargetPlayer.PlayerData.charinfo.lastname
                    
                    TriggerClientEvent('code:tracking:startClientTracking', src, coords, {name = targetName}, targetId)
                    
                    TriggerClientEvent('QBCore:Notify', src, 'Tracking started - Target did not respond to challenge', 'success')
                    
                    TriggerClientEvent('QBCore:Notify', currentTargetPlayer.PlayerData.source, 'Its too late! Your location has been tracked.', 'error')
                    
                    LogTrackingAttempt(src, targetId, phoneNumber, true, 'Minigame timeout - tracking started')
                    
                    if Config.Tracking.RealTimeUpdates then
                        CreateThread(function()
                            local updateCount = 0
                            local maxUpdates = Config.Tracking.Duration / 5000
                            
                            while updateCount < maxUpdates do
                                Wait(5000)
                                
                                local currentTarget = QBCore.Functions.GetPlayer(targetId)
                                if currentTarget then
                                    local newTargetPed = GetPlayerPed(currentTarget.PlayerData.source)
                                    if newTargetPed and newTargetPed ~= 0 then
                                        local newCoords = GetEntityCoords(newTargetPed)
                                        TriggerClientEvent('code:tracking:updateTargetLocation', src, newCoords)
                                    end
                                else
                                    break
                                end
                                
                                updateCount = updateCount + 1
                            end
                        end)
                    end
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Failed to obtain target location', 'error')
                    LogTrackingAttempt(src, targetId, phoneNumber, false, 'Could not get target position after timeout')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Target is offline', 'error')
                LogTrackingAttempt(src, targetId, phoneNumber, false, 'Target disconnected during timeout')
            end
            trackingSessions[sessionId] = nil
        end
    end)
end)


RegisterNetEvent('code:tracking:requestLocationUpdate', function(targetId)
    local src = source
    
    if not HasPermission(src) then
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        return
    end
    
    local targetPed = GetPlayerPed(targetPlayer.PlayerData.source)
    if targetPed and targetPed ~= 0 then
        local coords = GetEntityCoords(targetPed)
        
        TriggerClientEvent('code:tracking:updateTargetLocation', src, coords)
        
        if Config.Tracking.NotifyTarget then
            TriggerClientEvent('code:tracking:detectionWarning', targetPlayer.PlayerData.source)
        end
    end
end)


RegisterNetEvent('code:tracking:targetMinigameResult', function(requesterId, allowTracking, sessionId)
    local src = source
    
    local session = nil
    for id, sess in pairs(trackingSessions) do
        if sess.requesterId == requesterId and sess.targetId == src and sess.active then
            session = sess
            sessionId = id
            break
        end
    end
    
    if not session then
        print('^1[TRACKING] ^7Invalid tracking session or already processed^0')
        return
    end
    
    trackingSessions[sessionId].active = false
    trackingSessions[sessionId] = nil
    
    local requesterPlayer = QBCore.Functions.GetPlayer(requesterId)
    if not requesterPlayer then return end
    
    if allowTracking then
        local coords = GetEntityCoords(GetPlayerPed(src))
        local targetPlayer = QBCore.Functions.GetPlayer(src)
        local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
        
        TriggerClientEvent('code:tracking:startClientTracking', requesterId, coords, {name = targetName}, src)
        LogTrackingAttempt(requesterId, src, session.phoneNumber, true, 'Minigame failed')
        
        if Config.Tracking.RealTimeUpdates then
            CreateThread(function()
                local updateCount = 0
                local maxUpdates = Config.Tracking.Duration / 5000
                
                while updateCount < maxUpdates do
                    Wait(5000)
                    
                    local currentTargetPlayer = QBCore.Functions.GetPlayer(src)
                    if currentTargetPlayer then
                        local newTargetPed = GetPlayerPed(src)
                        if newTargetPed and newTargetPed ~= 0 then
                            local newCoords = GetEntityCoords(newTargetPed)
                            TriggerClientEvent('code:tracking:updateTargetLocation', requesterId, newCoords)
                        end
                    else
                        break
                    end
                    
                    updateCount = updateCount + 1
                end
            end)
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Your site has been acquired!', 'error')
    else
        TriggerClientEvent('QBCore:Notify', requesterId, 'Tracking Failed - Target Escaped', 'error')
        LogTrackingAttempt(requesterId, src, session.phoneNumber, false, 'Target blocked successfully')
        
        if Config.Rewards and Config.Rewards.BlockingReward and Config.Rewards.BlockingReward > 0 then
            local targetPlayer = QBCore.Functions.GetPlayer(src)
            targetPlayer.Functions.AddMoney('cash', Config.Rewards.BlockingReward, 'Avoided tracking')
            TriggerClientEvent('QBCore:Notify', src, 'I got a reward for avoiding tracking.: $' .. Config.Rewards.BlockingReward, 'success')
        end
    end
end)
RegisterCommand('trackinglog', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'You Dont Have Permission', 'error')
        return
    end
    
    local limit = tonumber(args[1]) or 10
    local recentLogs = {}
    
    for i = math.max(1, #trackingLogs - limit + 1), #trackingLogs do
        table.insert(recentLogs, trackingLogs[i])
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 255, 0, 0.1); border-radius: 3px;"><b>Tracking Logs (Last ' .. limit .. '):</b></div>'
    })
    
    for _, log in ipairs(recentLogs) do
        local message = string.format(
            '[%s] %s → %s (%s) - %s',
            log.timestamp,
            log.requester.name,
            log.target.name,
            log.target.phone,
            log.success and 'SUCCESS' or 'FAILED: ' .. log.reason
        )
        
        TriggerClientEvent('chat:addMessage', source, {
            template = '<div style="padding: 0.3vw; margin: 0.2vw; background-color: rgba(0, 0, 0, 0.3); border-radius: 3px;">' .. message .. '</div>'
        })
    end
end, true)

CreateThread(function()
    while true do
        Wait(60000)
        
        local currentTime = os.time()
        for sessionId, session in pairs(trackingSessions) do
            if currentTime - session.startTime > 300 then
                trackingSessions[sessionId] = nil
            end
        end
    end
end)

CreateThread(function()
    if Config.Database.SaveLogs then
        MySQL.ready(function()
            MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `tracking_logs` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `requester_id` varchar(50) DEFAULT NULL,
                    `requester_name` varchar(100) DEFAULT NULL,
                    `target_id` varchar(50) DEFAULT NULL,
                    `target_name` varchar(100) DEFAULT NULL,
                    `phone_number` varchar(20) DEFAULT NULL,
                    `success` tinyint(1) DEFAULT 0,
                    `reason` varchar(255) DEFAULT NULL,
                    `timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ]])
        end)
    end
end)



AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Citizen.SetTimeout(1000, function()
        local p1 = "\27[95m"  
        local p2 = "\27[35m"  
        local p3 = "\27[91m"  
        local p4 = "\27[31m"  
        local white = "\27[97m"
        local reset = "\27[0m"
        print(p1 .. "  ____ ___  ____  _____       ____            _       _   " .. reset)
        print(p1 .. " / ___/ _ \\|  _ \\| ____|     / ___| _ __ ___ (_)_ __ | |_ " .. reset)
        print(p2 .. "| |  | | | | |_) |  _| _____| |   | '__/ _ \\| | '_ \\| __|" .. reset)
        print(p2 .. "| |__| |_| |  __/| |__|_____| |___| | | (_) | | |_) | |_ " .. reset)
        print(p3 .. " \\____\\___/|_|   |_____|     \\____|_|  \\___/|_| .__/ \\__|" .. reset)
        print(p4 .. "                                              |_|        " .. reset)
        print(white .. "                 Created by: codescripts" .. reset)
        print(white .. "                 Discord: https://discord.gg/codescripts" .. reset)
        print(white .. "                 If you want to get more resources, please contact me on discord." .. reset)
    end)
end)
