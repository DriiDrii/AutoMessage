--[[ 
local KnownGuildMembers = {}

local LastCongratulated = {}

local WelcomeSent = {}

local GuildRosterInitialized = false

AutoMessageDB = {
    enabled = true,
    cooldown = 300,
    channel = "PRINT",
    whisperTarget = nil,
}



local function GetRandomMessage(playerName, level)
    local messageTemplate = Messages[math.random(#Messages)]
    return string.format(messageTemplate, playerName, level)
end

local function GetRandomWelcomeMessage(playerName)
    local messageTemplate = WelcomeMessages[math.random(#WelcomeMessages)]
    return string.format(messageTemplate, playerName)
end

local function CanCongratulate(playerName)
    local now = time()

    if LastCongratulated[playerName] then
        if now - LastCongratulated[playerName] < AutoMessageDB.cooldown then
            return false
        end
    end
    LastCongratulated[playerName] = now
    return true
end

local function SendCongratulation(playerName, level)
    if IsCurrentPlayer(playerName) then
        return
    end

    if CanCongratulate(playerName) then
        local message = GetRandomMessage(playerName, level)
        local channel = AutoMessageDB.channel
        if channel == "PRINT" then
            print("|cffffd700AutoMessage|r: " .. message)
        elseif channel == "WHISPER" then
            SendChatMessage(message, "WHISPER", nil, playerName)
        else
            SendChatMessage(message, channel)
        end
    end
end

local function SendWelcome(playerName)
    if IsCurrentPlayer(playerName) or not AutoMessageDB.enabled or WelcomeSent[playerName] then
        return
    end

    local message = GetRandomWelcomeMessage(playerName)
    local channel = AutoMessageDB.channel
    if channel == "PRINT" then
        print("|cffffd700AutoMessage|r: " .. message)
    elseif channel == "WHISPER" then
        SendChatMessage(message, "WHISPER", nil, playerName)
    else
        SendChatMessage(message, channel)
    end

    WelcomeSent[playerName] = true
end
]]

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
    return string.format(messageTemplate, playerName, level)
end

local function GetRandomWelcomeMessage(playerName, level)
    local messageTemplate = AutoMessage.db.profile.welcomeMessages[math.random(#AutoMessage.db.profile.welcomeMessages)]
    return string.format(messageTemplate, playerName, level)
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

local function SendWelcome(playerName)
    if IsCurrentPlayer(playerName) or not AutoMessage.db.profile.enabled or WelcomeSent[playerName] then
        return
    end

    local message = GetRandomWelcomeMessage(playerName)
    if SendMessage(message) then
        WelcomeSent[playerName] = true
    end
end

local function SendCongratulation(playerName, level)
    if IsCurrentPlayer(playerName) then
        return
    end
    if CanCongratulate(playerName) then
        local message = GetRandomMessage(playerName, level)
        SendMessage(message)
    end
end

local function SendMessage(message)
    local hasSend = false
    for key, value in pairs(self.db.profile.channels) do
        if value then
            hasSend = true
            self:Debug("Key is " .. tostring(key))
        end
    end
    return hasSend
end


function AutoMessage:ScanGuildRoster()
    if not IsInGuild() then
        self:Print("You must be in a guild to use this addon")
        GuildRosterInitialized = false
        return
    end
    self:Debug("Scanning guild roster for level-ups and new members...")
    GuildRoster()
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
                    SendCongratulation(cleanName, level)
                end
            elseif GuildRosterInitialized then
                self:Print("Detected new guild member " .. cleanName .. ".")
                SendWelcome(cleanName)
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
