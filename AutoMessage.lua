local GuildRosterInitialized = false
local KnownGuildMembers = {}

local LastCongratulated = {}
local WelcomeSent = {}

local function GetCleanName(name)
    return gsub(name or "", "%-.*$", "")
end

local function IsCurrentPlayer(name)
    return GetCleanName(name) == GetCleanName(UnitName("player"))
end

local function GetRandomMessage(playerName, level)
    local messageTemplate = AutoMessage.db.profile.congrats.messages[math.random(#AutoMessage.db.profile.congrats.messages)]
    messageTemplate = string.gsub(messageTemplate, "%[username%]", playerName)
    messageTemplate = string.gsub(messageTemplate, "%[lvl%]", level)
    return messageTemplate
end

local function GetRandomWelcomeMessage(playerName)
    local messageTemplate = AutoMessage.db.profile.welcome.messages[math.random(#AutoMessage.db.profile.welcome.messages)]
    messageTemplate = string.gsub(messageTemplate, "%[username%]", playerName)
    return messageTemplate
end

local function CanWelcome(playerName)
    if not GuildRosterInitialized then
        WelcomeSent[playerName] = true
    end

    if not AutoMessage.db.profile.settings.enableWelcome or IsCurrentPlayer(playerName) or not AutoMessage.db.profile.settings.enabled or WelcomeSent[playerName] then
        return false
    end
    return true
end

local function CanCongratulate(playerName)
    if not AutoMessage.db.profile.settings.enableCongrats or IsCurrentPlayer(playerName) or not GuildRosterInitialized then
        return false
    end

    local now = time()

    if LastCongratulated[playerName] then
        if now - LastCongratulated[playerName] < AutoMessage.db.profile.settings.cooldown then
            return false
        end
    end
    return true
end

local function GlobalSendMessage(message, playerName)
    AutoMessage:Debug(message)
    for key, value in pairs(AutoMessage.db.profile.settings.channels) do
        if value then
            local strKey = tostring(key)
            if strKey == "PRINT" then
                AutoMessage:Print(message)
            elseif strKey == "WHISPER" then
                SendChatMessage(message, strKey, nil, playerName)
            else
                SendChatMessage(message, strKey)
            end
        end
    end
end

local function SendWelcome(playerName, totalName)
    local message = GetRandomWelcomeMessage(playerName)
    GlobalSendMessage(message, totalName)
    WelcomeSent[playerName] = true
end

local function SendCongratulation(playerName, level, totalName)
    local message = GetRandomMessage(playerName, level)
    GlobalSendMessage(message, totalName)    
    LastCongratulated[playerName] = now
end

local function InitializeRoster()
    if not IsInGuild() then
        AutoMessage:Print("You must be in a guild to use this addon")
        AutoMessage.db.profile.settings.enabled = false
        GuildRosterInitialized = false
        return
    end

    AutoMessage:Debug("Initialize started")
    
    AutoMessage:RegisterEvent("GUILD_ROSTER_UPDATE", "ScanGuildRoster")
    AutoMessage:UnregisterEvent("PLAYER_LOGIN")
    C_Timer.NewTicker(11, function()
        if AutoMessage.db.profile.settings.enabled then
            AutoMessage:Debug("Tick - GuildRoster")
            GuildRoster()
        end
    end)    
    AutoMessage:Debug("Initialize finished")    
    
end

function AutoMessage:ScanGuildRoster()
    if not GuildRosterInitialized then
        self:Debug("Must be initialize first!")
        InitializeRoster()
    end

    AutoMessage:Debug("Scan started")
    local numMembers = GetNumGuildMembers()
    local hasDo = false
    for i = 1, numMembers do
        local name, _, _, level, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        if name and level and guid then
            local cleanName = gsub(name, "%-.*$", "")
            local memberKey = guid
            local previousMember = KnownGuildMembers[memberKey]
            local previousLevel = previousMember and previousMember.level or nil
            if previousMember and CanCongratulate(cleanName) then
                if previousLevel and level > previousLevel then
                    AutoMessage:Debug("Congrats " .. cleanName .. "Previous level " .. previousLevel .. " level " .. level)
                    SendCongratulation(cleanName, level, name)
                end
            end
            
            if not previousMember and CanWelcome(cleanName) then
                SendWelcome(cleanName, name)
            end

            KnownGuildMembers[memberKey] = { name = cleanName, level = level, guid = guid }
        end
        hasDo = true
    end
    if hasDo then
        GuildRosterInitialized = true
    end
    AutoMessage:Debug("Scan finsihed")
end

function AutoMessage:AddWelcomeMessage(info, newMessage)
   table.insert(AutoMessage.db.profile.welcome.messages, newMessage)
end

function AutoMessage:AddCongratsMessage(info, newMessage)
   table.insert(AutoMessage.db.profile.congrats.messages, newMessage)
end

function AutoMessage:GetSpecificMessages(info)
    AutoMessage:Debug("Get Number of info: " .. #info)
end

function AutoMessage:SetSpecificMessages(info, value)
    AutoMessage:Debug("Set Number of info: " .. #info)
end
