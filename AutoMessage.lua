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
    local messageTemplate = AutoMessage.db.profile.gratzMessages[math.random(#AutoMessage.db.profile.gratzMessages)]
    messageTemplate = string.gsub(messageTemplate, "%[username%]", playerName)
    messageTemplate = string.gsub(messageTemplate, "%[lvl%]", level)
    return messageTemplate
end

local function GetRandomWelcomeMessage(playerName)
    local messageTemplate = AutoMessage.db.profile.welcomeMessages[math.random(#AutoMessage.db.profile.welcomeMessages)]
    messageTemplate = string.gsub(messageTemplate, "%[username%]", playerName)
    return messageTemplate
end

local function CanCongratulate(playerName)
    local now = time()

    if LastCongratulated[playerName] then
        if now - LastCongratulated[playerName] < AutoMessage.db.profile.cooldown then
            return false
        end
    end
    LastCongratulated[playerName] = now
    return true
end

local function GlobalSendMessage(message, playerName)
    AutoMessage:Debug("Will send " .. message)
    local hasSend = false
    for key, value in pairs(AutoMessage.db.profile.channels) do
        if value then
            hasSend = true
            local strKey = tostring(key)
            AutoMessage:Debug("Key is " .. strKey .. " Message is " .. message .. " PlayerName is " .. playerName)
            if strKey == "PRINT" then
                AutoMessage:Print(message)
            elseif strKey == "WHISPER" then
                SendChatMessage(message, strKey, nil, playerName)
            else
                SendChatMessage(message, strKey)
            end
        end
    end
    return hasSend
end

local function SendWelcome(playerName, totalName)
    if IsCurrentPlayer(playerName) or not AutoMessage.db.profile.enabled or WelcomeSent[playerName] then
        return
    end

    local message = GetRandomWelcomeMessage(playerName)
    if GlobalSendMessage(message, totalName) then
        AutoMessage:Debug("Welcome sent to " .. playerName)
        WelcomeSent[playerName] = true
    end
end

local function SendCongratulation(playerName, level, totalName)
    AutoMessage:Debug("Call for " .. playerName)
    if IsCurrentPlayer(playerName) then
        AutoMessage:Debug("It's me -- Oops")
        return
    end
    AutoMessage:Debug("Try to send a message to " .. playerName)
    if CanCongratulate(playerName) then
        AutoMessage:Debug("Allowed to send")
        local message = GetRandomMessage(playerName, level)
        GlobalSendMessage(message, totalName)
    end
end

function AutoMessage:ScanGuildRoster()
    if not IsInGuild() then
        self:Print("You must be in a guild to use this addon")
        GuildRosterInitialized = false
        return
    end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, _, _, level, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        if name and level then
            local cleanName = gsub(name, "%-.*$", "")
            local memberKey = guid or cleanName
            local previousMember = KnownGuildMembers[memberKey]
            local previousLevel = previousMember and previousMember.level or nil

            if previousMember then
                if previousLevel and level > previousLevel then
                    self:Print("Detected level up for " .. cleanName .. " from " .. previousLevel .. " to " .. level)
                    SendCongratulation(cleanName, level, name)
                end
            elseif GuildRosterInitialized then
                self:Print("Detected new guild member " .. cleanName .. ".")
                SendWelcome(cleanName, name)
            end

            KnownGuildMembers[memberKey] = { name = cleanName, level = level, guid = guid }
        end
    end

    GuildRosterInitialized = true
end

function AutoMessage:AddWelcomeMessage(info, newMessage)
    self:Debug("Ajout du message " .. newMessage)
   table.insert(AutoMessage.db.profile.welcomeMessages, newMessage)
end
