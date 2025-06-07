Config = {
    -- Language Settings
    Locale = 'en', -- 'ar' for Arabic, 'en' for English
    
    -- Tracker Item
    TrackerItem = 'tracker', -- Item name in database
    
    phoneNumber = 10,

    -- Allowed Jobs
    AllowedJobs = {
        'police',
        'sheriff',
        'fbi',
        'swat',
        'cia',
        'military'
    },

    PhoneSystem = 'lb-phone', -- Options: 'lb-phone', 'qb-phone'

    -- Phone Database
    PhoneDatabase = {
        ['lb-phone'] = {
            table = 'phone_phones',
            owner_column = 'owner_id'
    },
        ['qb-phone'] = {
            table = 'player_phones', 
            owner_column = 'citizenid'
        }
    },
    
    -- Special Ranks System (optional)
    AllowSpecialRanks = true,
    SpecialRanks = {
        {job = 'police', level = 3}, -- Sergeant and above
        {job = 'sheriff', level = 2}, -- Deputy and above
        {job = 'fbi', level = 1}, -- All FBI ranks
    },
    
    -- Tracking Settings
    Tracking = {
        Duration = 45000, -- Duration in milliseconds (45 seconds)
        Radius = 35.0, -- Tracking radius
        UpdateThreshold = 50.0, -- Distance threshold for location updates
        MinigameTimeout = 20000, -- Time limit for minigame response (20 seconds)
        NotifyTarget = false,
        RealTimeUpdates = true,
        CheckNetworkStatus = true,
        MinigameTimeout = 15000,
    },
    
    -- Anti-Spam Protection
    AntiSpam = {
        Enabled = true,
        MaxAttempts = 3, -- Max attempts before cooldown
        Cooldown = 30000 -- Cooldown time in milliseconds (30 seconds)
    },
    
    -- Safe Zones (areas where tracking is disabled)
    SafeZones = {
        Enabled = true,
        Zones = {
            {x = -1037.0, y = -2737.0, z = 20.0, radius = 100.0, name = "Military Base"},
            {x = 1854.0, y = 3687.0, z = 34.0, radius = 150.0, name = "Prison"},
            {x = -75.0, y = -818.0, z = 243.0, name = "Maze Bank"}, -- Example: Maze Bank rooftop
            {x = 315.0, y = -593.0, z = 43.0, radius = 80.0, name = "Pillbox Hospital"}
        }
    },
    -- Rewards System
    Rewards = {
        BlockingReward = 500, -- Money reward for successfully avoiding tracking
        TrackingBonus = 100, -- Bonus for successful tracking (for law enforcement)
        VPNProtectionReward = 5000, -- مكافأة عند صد التعقب بواسطة VPN
    },
    
    -- Database Settings
    Database = {
        SaveLogs = true, -- Save tracking logs to database
        LogRetention = 30 -- Days to keep logs (0 = forever)
    },
    
    
    -- Debug Settings
    Debug = {
        Enabled = false, -- Enable debug prints
        LogLevel = 1 -- 1 = Basic, 2 = Detailed, 3 = Verbose
    }
}

Config.Strings = {
    ['ar'] = {
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
        ['target_moving'] = 'الهدف يتحرك',
        ['signal_strength'] = 'قوة الإشارة: قوية',
        ['encryption_level'] = 'مستوى التشفير: AES-256',
        ['clearance_level'] = 'مستوى التصريح: المستوى 5',
        ['connection_established'] = 'تم تأسيس الاتصال بنجاح'
    },
    ['en'] = {
        ['tracking_started'] = 'Target tracking initiated successfully',
        ['tracking_ended'] = 'Tracking session terminated',
        ['tracking_blocked'] = 'Successfully blocked tracking attempt',
        ['tracking_success'] = 'Your location has been compromised!',
        ['no_permission'] = 'Access denied - Insufficient clearance level',
        ['player_offline'] = 'Target is offline or invalid number',
        ['tracking_failed'] = 'Tracking failed - Target evaded detection',
        ['tracking_title'] = 'Military Tracking System',
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
}
