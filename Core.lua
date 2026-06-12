AutoMessage = LibStub("AceAddon-3.0"):NewAddon("AutoMessage", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")

local colors = {
  reset   = "|r",
  red     = "|cffff0000",
  green   = "|cFF00FF00",
  yellow  = "|cFFFFFF00",
  blue    = "|cFF0000FF",
}

local defaults = {
    profile = {
        debug = false,
        enabled = true,
        channels = {
            PRINT = false,
            GUILD = true,
            PARTY = false,
            RAID = false,
            WHISPER = false
        },
        cooldown = 300, -- 5 minutes
        gratzMessages = {
            "Grats [username] on lvl [lvl]!",
            "Well done [username], you reached level [lvl]!",
            "Finally, [username] hit level [lvl]! Congrats!",
            "Awesome job [username], level [lvl] achieved!",
            "Congratulations [username] on reaching level [lvl]!",
            "Way to go [username], level [lvl] is yours!",
            "Great work [username], you made it to level [lvl]!",
            "Fantastic [username], level [lvl] unlocked!",
            "Impressive [username], you hit level [lvl]!"
        },
        welcomeMessages = {
            "Welcome to the guild, [username]!",
            "Glad to have you with us, [username]!",
            "Welcome aboard, [username]!",
            "Great to see you join us, [username]!",
            "Welcome to the family, [username]!",
            "Happy to have you here, [username]!",
            "Welcome to the team, [username]!",
            "Glad you could join us, [username]!",
            "Welcome to the guild, [username]! Looking forward to adventuring together!",
            "Welcome [username]! We're excited to have you in the guild!",
            "Welcome [username]! Can't wait to see you in action with us!",
        },
        updateCongratsLock = true,
        updateWelcomeLock = true,
        enableCongrats = true,
        enableWelcome = true
    },
}

local options = {
    name = "AutoMessage",
    handler = AutoMessage,
    type = "group",
    childGroups = "tab",
    args = {
        settings = {
            type = "group",
            name = "Settings",
            order = 1,
            args = {
                debug = {
                    type = "toggle",
                    name = "Enable Debug Messages",
                    desc = "Toggle debug messages in the chat window.",
                    order = 1,
                    get = function(info) return AutoMessage.db.profile.debug end,
                    set = function(info, value) AutoMessage.db.profile.debug = value end,
                },
                channelHeader = {
                    type = "header",
                    name = "Common Settings",
                    order = 2,
                },
                channels = {
                    type = "multiselect",
                    name = "Message Channels",
                    desc = "Select the channels to send congratulatory messages to.",
                    order = 3,
                    values = {
                        PRINT = "Print",
                        GUILD = "Guild",
                        PARTY = "Party",
                        RAID = "Raid",
                        WHISPER = "Whisper"
                    },
                    get = function(info, key) return AutoMessage.db.profile.channels[key] end,
                    set = function(info, key, state) AutoMessage.db.profile.channels[key] = state end,
                },
                cooldown = {
                    type = "range",
                    name = "Cooldown (seconds)",
                    desc = "Set the cooldown time between congratulatory messages to the same player.",
                    order = 4,
                    min = 10,
                    max = 3600,
                    step = 10,
                    get = function(info) return AutoMessage.db.profile.cooldown end,
                    set = function(info, value) AutoMessage.db.profile.cooldown = value end,
                },
                enableCongrats = {
                    type = "toggle",
                    name = "Enable Congrats Messages",
                    desc = "Toggle Congrats messages in the chat window.",
                    order = 5,
                    get = function(info) return AutoMessage.db.profile.enableCongrats end,
                    set = function(info, value) AutoMessage.db.profile.enableCongrats = value end,
                },
                enableWelcome = {
                    type = "toggle",
                    name = "Enable Welcome Messages",
                    desc = "Toggle Welcome messages in the chat window.",
                    order = 5,
                    get = function(info) return AutoMessage.db.profile.enableWelcome end,
                    set = function(info, value) AutoMessage.db.profile.enableWelcome = value end,
                }
            }
        },
        congrats = {
            type = "group",
            name = "Congratulations",
            order = 2,
            args = {
                CongratsMessages = {
                    type = "input",
                    name = "Congrats Messages",
                    desc = "Enter custom congrats messages, separated by new lines. Use [username] and [lvl] as placeholders.",
                    order = 1,
                    multiline = true,
                    disabled = function(info) return AutoMessage.db.profile.updateCongratsLock end,
                    confirm = true,
                    width = "full",
                    get = function(info) return table.concat(AutoMessage.db.profile.gratzMessages, "\n") end,
                    set = function(info, value) AutoMessage.db.profile.gratzMessages = { strsplit("\n", value) } end,
                },
                newMessages = {
                    type = "input",
                    name = "New Message",
                    desc = "Enter custom congrats messages for guild members. Use [username] and [lvl] as a placeholder.",
                    confirm = true,
                    order = 2,
                    width = "full",
                    set = "AddCongratsMessage",
                },
                updateMessage = {
                    type = "toggle",
                    name = "Enable list",
                    desc = "Allow to update the list, each value should be separated by new lines. Use [username] as a placeholder.",
                    width = "full",
                    order = -1,
                    get = function(info) return AutoMessage.db.profile.updateCongratsLock end,
                    set = function(info, value) AutoMessage.db.profile.updateCongratsLock = value end;
                }
            }
        },
        welcome = {
            type = "group",
            name = "Welcome",
            order = 3,
            args = {
                WelcomeMessages = {
                    type = "input",
                    name = "Messages",
                    desc = "Enter custom welcome messages for new guild members, separated by new lines. Use [username] as a placeholder.",
                    multiline = true,
                    disabled = function(info) return AutoMessage.db.profile.updateWelcomeLock end,
                    confirm = true,
                    order = 1,
                    width = "full",
                    get = function(info) return table.concat(AutoMessage.db.profile.welcomeMessages, "\n") end,
                    set = function(info, value) AutoMessage.db.profile.welcomeMessages = {strsplit('\n', value)} end
                },
                newMessage = {
                    type = "input",
                    name = "New Message",
                    desc = "Enter custom welcome messages for new guild members, separated by new lines. Use [username] as a placeholder.",
                    confirm = true,
                    order = 2,
                    width = "full",
                    set = "AddWelcomeMessage",
                },
                updateMessage = {
                    type = "toggle",
                    name = "Enable list",
                    desc = "Allow to update the list, each value should be separated by new lines. Use [username] as a placeholder.",
                    width = "full",
                    order = -1,
                    get = function(info) return AutoMessage.db.profile.updateWelcomeLock end,
                    set = function(info, value) AutoMessage.db.profile.updateWelcomeLock = value end;
                }
            }
        },
        profiles = {
            type = "group",
            name = "Profiles",
            order = -1,
            args = {}
        }
    }
}


function AutoMessage:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AutoMessageDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AutoMessage", options, {"amconfig"})
    options.args.profiles.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoMessage", "AutoMessage")
    
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self:RegisterChatCommand("am", "ChatCommand")
    self:RegisterChatCommand("automessage", "ChatCommand")
    
    self:RegisterEvent("PLAYER_LOGIN", "ScanGuildRoster")

    self:Print("loaded! Congratulating level-ups and welcoming new guild members.")
end

function AutoMessage:OnEnable()
    self.db.profile.enabled = true
end

function AutoMessage:OnDisable()
    self.db.profile.enabled = false
end

function AutoMessage:Print(message)
    local console = LibStub("AceConsole-3.0")
    console:Print(colors.red .. "[AutoMessage]" .. colors.reset .. " " .. message)
end

function AutoMessage:Debug(message)
    if self.db.profile.debug then
        self:Print(colors.yellow .. "[Debug] " .. colors.reset .. message)
    end
end

function AutoMessage:RefreshConfig()
    self:Debug("Configuration refreshed.")
end
