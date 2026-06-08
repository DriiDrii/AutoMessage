local Messages = {
    "Grats %s on lvl %d!",
    "Well done %s, you reached level %d!",
    "Finally, %s hit level %d! Congrats!",
    "Awesome job %s, level %d achieved!",
    "Congratulations %s on reaching level %d!",
    "Way to go %s, level %d is yours!",
    "Great work %s, you made it to level %d!",
    "Fantastic %s, level %d unlocked!",
    "Impressive %s, you hit level %d!",
}

local WelcomeMessages = {
    "Welcome to the guild, %s!",
    "Glad to have you with us, %s!",
    "Welcome aboard, %s!",
    "Great to see you join us, %s!",
    "Welcome to the family, %s!",
    "Happy to have you here, %s!",
    "Welcome to the team, %s!",
    "Glad you could join us, %s!",
    "Welcome to the guild, %s! Looking forward to adventuring together!",
    "Welcome %s! We're excited to have you in the guild!",
    "Welcome %s! Can't wait to see you in action with us!",
}

local KnownGuildMembers = {}

local LastCongratulated = {}

local WelcomeSent = {}

local GuildRosterInitialized = false

AutoMessageDB = {
    enabled = true,
    cooldown = 300,
    channel = "GUILD",
    whisperTarget = nil,
}

SLASH_AUTOMESSAGE = "/am"
SlashCmdList["AUTOMESSAGE"] = function(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    if command == "channel" then
        if arg == "PRINT" or arg == "GUILD" or arg == "PARTY" or arg == "RAID" or arg == "WHISPER" then
            AutoMessageDB.channel = arg
            print("|cffffd700AutoMessage|r: Channel set to " .. arg)
        else
            print("|cffffd700AutoMessage|r: Invalid channel. Use PRINT, GUILD, PARTY, RAID, or WHISPER.")
        end
    elseif command == "whisper" then
        AutoMessageDB.whisperTarget = arg
        print("|cffffd700AutoMessage|r: Whisper target set to " .. arg)
    elseif command == "cooldown" then
        local cooldown = tonumber(arg)
        if cooldown then
            AutoMessageDB.cooldown = cooldown
            print("|cffffd700AutoMessage|r: Cooldown set to " .. cooldown .. " seconds.")
        else
            print("|cffffd700AutoMessage|r: Invalid cooldown value.")
        end
    else
        print("|cffffd700AutoMessage|r Commands:")
        print("/am channel [CHANNEL] - Set the channel for messages (PRINT, GUILD, PARTY, RAID, WHISPER)")
        print("/am whisper [PLAYER] - Set the target player for whispers")
        print("/am cooldown [SECONDS] - Set the cooldown time between messages")
    end
end

local function GetCleanName(name)
    return gsub(name or "", "%-.*$", "")
end

local function IsCurrentPlayer(name)
    return GetCleanName(name) == GetCleanName(UnitName("player"))
end

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

local function ScanGuildRosterForLevelUps()
    if not IsInGuild() then
        GuildRosterInitialized = false
        return
    end

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
                    print("|cffffd700AutoMessage|r: Detected level up for " .. cleanName .. " from " .. previousLevel .. " to " .. level)
                    SendCongratulation(cleanName, level)
                end
            elseif GuildRosterInitialized then
                print("|cffffd700AutoMessage|r: Detected new guild member " .. cleanName .. ". Sending welcome.")
                SendWelcome(cleanName)
            end

            KnownGuildMembers[memberKey] = { name = cleanName, level = level, guid = guid }
        end
    end

    GuildRosterInitialized = true
end

local function InitializeGuildRoster()
    if IsInGuild() then
        GuildRoster()
    end
end

AutoMessage:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeGuildRoster()
        ScanGuildRosterForLevelUps()
    elseif event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        ScanGuildRosterForLevelUps()
    end
end)