QBCore = exports['qb-core']:GetCoreObject()
local trackingSessions = {}
local trackingLogs = {}
local blockedAttempts = {}
local Strings = {}

local WebhookConfig = {
    Enabled = true,-- Activate/Deactivate WebHook
    URL = "https://discord.com/api/webhooks/1111111111111111111/", -- Normal Webhook URL  -- لوقات للعساكر بروم خاص للعساكر
    URLSystem = "https://discord.com/api/webhooks/1111111111111111111/", -- System Webhook URL -- لوقات للنظام خاص بالادمن
    ServerInfo = {
        Name = "Los Santos Police Department", -- Server Name
        Logo = "https://r2.fivemanage.com/VCltKUncVNNG9E5iI6HBp/p.png",  -- Server Logo
        Color = 3447003,
        Footer = "LSPD Tracking System",
        FooterIcon = "https://r2.fivemanage.com/VCltKUncVNNG9E5iI6HBp/p.png"
    },
    Thumbnails = {
        Success = "https://r2.fivemanage.com/VCltKUncVNNG9E5iI6HBp/s.png", -- Success img dont touch
        Failed = "https://r2.fivemanage.com/VCltKUncVNNG9E5iI6HBp/f.png", -- Failed img dont touch
        Police = "https://r2.fivemanage.com/VCltKUncVNNG9E5iI6HBp/p.png", -- Public Police img dont touch
        image = "https://r2.fivemanage.com/VCltKUncVNNG9E5iI6HBp/p1.png" -- dont touch
    }
}


local function LoadLanguage()
    local lang = Config.Locale or 'ar'
    Strings = Config.Strings[lang] or Config.Strings['ar']
end

local function SendNormalWebhook(data)
    if not WebhookConfig.Enabled or not WebhookConfig.URL or WebhookConfig.URL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return
    end

    local embed = {
        {
            title = data.title or "📡 نظام التعقب",
            description = data.description or "",
            color = data.color or WebhookConfig.ServerInfo.Color,
            thumbnail = {
                url = data.thumbnail or WebhookConfig.Thumbnails.Police
            },
            image = {
                url = WebhookConfig.Thumbnails.image
            },
            fields = data.fields or {},
            footer = {
                text = WebhookConfig.ServerInfo.Footer .. " • " .. os.date("%Y-%m-%d %H:%M:%S"),
                icon_url = WebhookConfig.ServerInfo.FooterIcon
            },
            author = {
                name = WebhookConfig.ServerInfo.Name,
                icon_url = WebhookConfig.ServerInfo.Logo
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(WebhookConfig.URL, function(err, text, headers) end, 'POST', json.encode({
        username = "LSPD Tracking Bot",
        avatar_url = WebhookConfig.ServerInfo.Logo,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

local function SendSystemWebhook(data)
    if not WebhookConfig.Enabled or not WebhookConfig.URLSystem or WebhookConfig.URLSystem == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return
    end

    local embed = {
        {
            title = data.title or "📡 نظام التعقب",
            description = data.description or "",
            color = data.color or WebhookConfig.ServerInfo.Color,
            thumbnail = {
                url = data.thumbnail or WebhookConfig.Thumbnails.Police
            },
            image = {
                url = WebhookConfig.Thumbnails.image
            },
            fields = data.fields or {},
            footer = {
                text = WebhookConfig.ServerInfo.Footer .. " • " .. os.date("%Y-%m-%d %H:%M:%S"),
                icon_url = WebhookConfig.ServerInfo.FooterIcon
            },
            author = {
                name = WebhookConfig.ServerInfo.Name,
                icon_url = WebhookConfig.ServerInfo.Logo
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(WebhookConfig.URLSystem, function(err, text, headers) end, 'POST', json.encode({
        username = "LSPD System Bot",
        avatar_url = WebhookConfig.ServerInfo.Logo,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
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
    
    local webhookData = {
        title = success and "✅ Successful tracking attempt" or "❌ Failed tracking attempt",
        description = success and "Target successfully tracked" or "Failed to track target",
        color = success and 65280 or 16711680,
        thumbnail = success and WebhookConfig.Thumbnails.Success or WebhookConfig.Thumbnails.Failed,
        fields = {
            {
                name = "👮 The officer",
                value = string.format("**Name:** %s\n**Job:** %s\n**ID:** %s", 
                    logEntry.requester.name, 
                    logEntry.requester.job, 
                    logEntry.requester.citizenid),
                inline = true
            },
            {
                name = "🎯 target",
                value = string.format("**Phone Number:** %s\n**", 
                    phoneNumber or "undefined"),
                inline = true
            },
            {
                name = "📊 Process details",
                value = string.format("**Status:** %s\n**Cause:** %s\n**Time:** %s", 
                    success and "success" or "fail", 
                    reason or "undefined", 
                    logEntry.timestamp),
                inline = false
            }
        }
    }
    
    SendNormalWebhook(webhookData)
    
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
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                local webhookData = {
                    title = "⚠️ Warning: Spam Attempt",
                    description = "A spam attempt was detected in the tracking system.",
                    color = 16776960,
                    thumbnail = WebhookConfig.Thumbnails.Police,
                    fields = {
                        {
                            name = "👤 user",
                            value = string.format("**Name:** %s\n**ID:** %s\n**Job:** %s", 
                                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                                Player.PlayerData.citizenid,
                                Player.PlayerData.job.name),
                            inline = true
                        },
                        {
                            name = "📈 statistics",
                            value = string.format("**Number of attempts:** %d\n**Time:** %s", 
                                blockedAttempts[source].count,
                                os.date("%H:%M:%S")),
                            inline = true
                        }
                    }
                }
                SendSystemWebhook(webhookData)
            end
            return true
        end
    else
        blockedAttempts[source] = {count = 1, lastAttempt = currentTime}
    end
    
    blockedAttempts[source].lastAttempt = currentTime
    return false
end

local function SearchPhoneInDatabase(phoneNumber)
    local results = {}
    
    if Config.PhoneSystem == 'lb-phone' or Config.PhoneSystem == 'both' then
        local lbResult = MySQL.query.await('SELECT owner_id FROM phone_phones WHERE phone_number = ?', {phoneNumber})
        if lbResult and #lbResult > 0 then
            table.insert(results, {system = 'lb-phone', owner_id = lbResult[1].owner_id})
        end
    end
    
    if Config.PhoneSystem == 'qb-phone' or Config.PhoneSystem == 'both' then
        local qbResult = nil
        
        qbResult = MySQL.query.await('SELECT citizenid FROM players WHERE JSON_EXTRACT(charinfo, "$.phone") = ?', {phoneNumber})
        
        if not qbResult or #qbResult == 0 then
            qbResult = MySQL.query.await('SELECT citizenid FROM players WHERE phone = ?', {phoneNumber})
        end
        
        if not qbResult or #qbResult == 0 then
            qbResult = MySQL.query.await('SELECT citizenid FROM players WHERE charinfo LIKE ?', {'%"phone":"' .. phoneNumber .. '"%'})
        end
        
        if not qbResult or #qbResult == 0 then
            qbResult = MySQL.query.await('SELECT citizenid FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.phone")) = ?', {phoneNumber})
        end
        
        if not qbResult or #qbResult == 0 then
            qbResult = MySQL.query.await('SELECT citizenid FROM players WHERE JSON_EXTRACT(metadata, "$.phone") = ?', {phoneNumber})
        end
        
        if qbResult and #qbResult > 0 then
            table.insert(results, {system = 'qb-phone', owner_id = qbResult[1].citizenid})
        end
    end
    
    return results
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
        
        local webhookData = {
            title = "🚫 Unauthorized access attempt",
            description = "Someone tried to use the tracking device without authorization.",
            color = 16711680,
            thumbnail = WebhookConfig.Thumbnails.Police,
            fields = {
                {
                    name = "👤 user",
                    value = string.format("**Name:** %s\n**ID:** %s\n**Job:** %s", 
                        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                        Player.PlayerData.citizenid,
                        Player.PlayerData.job.name),
                    inline = true
                },
                {
                    name = "⏰ Timing",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = true
                }
            }
        }
        SendSystemWebhook(webhookData)
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
        
        local requesterPlayer = QBCore.Functions.GetPlayer(src)
        if requesterPlayer then
            local webhookData = {
                title = "🛡️ Active VPN protection",
                description = "A tracking attempt was thwarted by protection. VPN",
                color = 9932815,
            thumbnail = WebhookConfig.Thumbnails.Police,
                fields = {
                    {
                        name = "👮 Officer",
                        value = string.format("**Name:** %s\n**Job Title:**:** %s", 
                            requesterPlayer.PlayerData.charinfo.firstname .. ' ' .. requesterPlayer.PlayerData.charinfo.lastname,
                            requesterPlayer.PlayerData.job.name),
                        inline = true
                    }
                }
            }
            SendNormalWebhook(webhookData)
        end
        
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
    
    local requesterPlayer = QBCore.Functions.GetPlayer(src)
    if requesterPlayer then
        local webhookData = {
            title = "🎯 Start the tracking process",
            description = "A new tracking operation has been initiated - awaiting target response.",
            color = 16776960,
            thumbnail = WebhookConfig.Thumbnails.Police,
            fields = {
                {
                    name = "👮 Officer in charge",
                    value = string.format("**Name:** %s\n**Job:** %s\n**Rank:** %s", 
                        requesterPlayer.PlayerData.charinfo.firstname .. ' ' .. requesterPlayer.PlayerData.charinfo.lastname,
                        requesterPlayer.PlayerData.job.name,
                        requesterPlayer.PlayerData.job.grade.name),
                    inline = true
                },
                {
                    name = "🎯 Target information",
                    value = string.format("**Name:** %s\n**Phone number:** %s", 
                        targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
                        phoneNumber or "undefined"),
                    inline = true
                }
            }
        }
        SendSystemWebhook(webhookData)
    end
    
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
    
    local webhookData = {
        title = "📋 Tracking logs report",
        description = string.format("Another request was made %d Tracking process", limit),
        color = 3447003,
        thumbnail = WebhookConfig.Thumbnails.Police,
        fields = {
            {
                name = "👮 Request by",
                value = string.format("**Name:** %s\n**ID:** %s", 
                    Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    Player.PlayerData.citizenid),
                inline = true
            },
            {
                name = "📊 statistics",
                value = string.format("**Number of records:** %d\n**the time:** %s", 
                    #recentLogs,
                    os.date("%H:%M:%S")),
                inline = true
            }
        }
    }
    
    if #recentLogs > 0 then
        local successCount = 0
        local failCount = 0
        
        for _, log in ipairs(recentLogs) do
            if log.success then
                successCount = successCount + 1
            else
                failCount = failCount + 1
            end
        end
        
        table.insert(webhookData.fields, {
            name = "📈 Operations results",
            value = string.format("✅ **Successful:** %d\n❌ **Failed:** %d\n📍 **Success rate:** %.1f%%", 
                successCount, 
                failCount, 
                (successCount / #recentLogs) * 100),
            inline = false
        })
    end
    
    SendSystemWebhook(webhookData)
end, true)

RegisterCommand('trackingwebhook', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'You Dont Have Permission', 'error')
        return
    end
    
    local reportType = args[1] or 'summary'
    
    if reportType == 'summary' then
        local totalLogs = #trackingLogs
        local activeSessions = 0
        for _ in pairs(trackingSessions) do
            activeSessions = activeSessions + 1
        end
        
        local webhookData = {
            title = "📊 Comprehensive tracking system report",
            description = "Summary of the current status of the tracking system",
            color = 3447003,
            thumbnail = WebhookConfig.Thumbnails.Police,
            fields = {
                {
                    name = "📈 General statistics",
                    value = string.format("**Total Transactions:** %d\n**Active Sessions:** %d\n**Uptime:** Online", 
                        totalLogs, activeSessions),
                    inline = true
                },
                {
                    name = "👮 Report request",
                    value = string.format("**By:** %s\n**time:** %s", 
                        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                        os.date("%Y-%m-%d %H:%M:%S")),
                    inline = true
                }
            }
        }
        
        if totalLogs > 0 then
            local last24h = 0
            local currentTime = os.time()
            local successfulOps = 0
            
            for _, log in ipairs(trackingLogs) do
                local logTime = os.time({
                    year = tonumber(string.sub(log.timestamp, 1, 4)),
                    month = tonumber(string.sub(log.timestamp, 6, 7)),
                    day = tonumber(string.sub(log.timestamp, 9, 10)),
                    hour = tonumber(string.sub(log.timestamp, 12, 13)),
                    min = tonumber(string.sub(log.timestamp, 15, 16)),
                    sec = tonumber(string.sub(log.timestamp, 18, 19))
                })
                
                if currentTime - logTime <= 86400 then
                    last24h = last24h + 1
                end
                
                if log.success then
                    successfulOps = successfulOps + 1
                end
            end
            
            table.insert(webhookData.fields, {
                name = "🕐 Statistics for the last 24 hours",
                value = string.format("**Operations:** %d\n**Success Rate:** %.1f%%", 
                    last24h, 
                    totalLogs > 0 and (successfulOps / totalLogs) * 100 or 0),
                inline = false
            })
        end
        
        SendSystemWebhook(webhookData)
        TriggerClientEvent('QBCore:Notify', source, 'تم إرسال التقرير الشامل للديسكورد', 'success')
        
    elseif reportType == 'test' then
        local webhookData = {
            title = "🧪 Webhook System Test",
            description = "This is a test message to ensure the webhook system is working correctly.",
            color = 65280,
            thumbnail = WebhookConfig.Thumbnails.Police,
            fields = {
                {
                    name = "✅ System Status",
                    value = "The system is operating normally.",
                    inline = true
                },
                {
                    name = "👤 Tested By",
                    value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    inline = true
                },
                {
                    name = "🕐 Test Time",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = false
                }
            }
        }
        
        SendSystemWebhook(webhookData)
        TriggerClientEvent('QBCore:Notify', source, 'تم إرسال رسالة اختبار للديسكورد', 'success')
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
        
        if WebhookConfig.Enabled and WebhookConfig.URLSystem ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
            Citizen.SetTimeout(5000, function()
                local webhookData = {
                    title = "🟢 The tracking system is online",
                    description = "The tracking system has been successfully commissioned and is ready for use.",
                    color = 65280,
                    thumbnail = WebhookConfig.Thumbnails.Police,
                    fields = {
                        {
                            name = "🏢 Server information",
                            value = string.format("**Name:** %s\n**Status:** Online ✅", WebhookConfig.ServerInfo.Name),
                            inline = true
                        },
                        {
                            name = "⚙️ System settings",
                            value = string.format("**Webhook:** %s\n**Database:** %s", 
                                WebhookConfig.Enabled and "Activated✅" or "Disabled ❌",
                                Config.Database and Config.Database.SaveLogs and "Activated ✅" or "Disabled ❌"),
                            inline = true
                        },
                        {
                            name = "🕐 Operating time",
                            value = os.date("%Y-%m-%d %H:%M:%S"),
                            inline = false
                        }
                    }
                }
                
                SendSystemWebhook(webhookData)
            end)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if WebhookConfig.Enabled and WebhookConfig.URLSystem ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        local webhookData = {
            title = "🔴 Tracking system down",
            description = "The tracking system has been turned off.",
            color = 16711680,
            thumbnail = WebhookConfig.Thumbnails.Police,
            fields = {
                {
                    name = "🏢 Server information",
                    value = string.format("**Name:** %s\n**Status:** Disconnected❌", WebhookConfig.ServerInfo.Name),
                    inline = true
                },
                {
                    name = "📊 Session statistics",
                    value = string.format("**Total transactions:** %d\n**Active sessions:** %d", 
                        #trackingLogs,
                        #trackingSessions > 0 and #trackingSessions or 0),
                    inline = true
                },
                {
                    name = "🕐 Stop time",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = false
                }
            }
        }
        
        SendSystemWebhook(webhookData)
    end
end)
