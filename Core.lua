AutoMessage = LibStub("AceAddon-3.0"):NewAddon("AutoMessage", "AceConsole-3.0", "AceEvent-3.0")

local colors = {
  reset   = "|r",
  red     = "|cffff0000",
  green   = "|cFF00FF00",
  yellow  = "|cFFFFFF00",
  blue    = "|cFF0000FF",
}

local defaults = {
    profile = {
        settings = {
            debug = true,
            enabled = true,
            channels = {
                PRINT = false,
                GUILD = true,
                WHISPER = false
            },
            cooldown = 300,            
            enableCongrats = true,
            enableWelcome = true
        },
        congrats = {
            messages = {
            },
            updateCongratsLock = true,
        },
        welcome = {
            messages = {
            },            
            updateWelcomeLock = true,
        }
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
                    get = function(info) return AutoMessage.db.profile.settings.debug end,
                    set = function(info, value) AutoMessage.db.profile.settings.debug = value end,
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
                        WHISPER = "Whisper"
                    },
                    get = function(info, key) return AutoMessage.db.profile.settings.channels[key] end,
                    set = function(info, key, state) AutoMessage.db.profile.settings.channels[key] = state end,
                },
                cooldown = {
                    type = "range",
                    name = "Cooldown (seconds)",
                    desc = "Set the cooldown time between congratulatory messages to the same player.",
                    order = 4,
                    min = 10,
                    max = 3600,
                    step = 10,
                    get = function(info) return AutoMessage.db.profile.settings.cooldown end,
                    set = function(info, value) AutoMessage.db.profile.settings.cooldown = value end,
                },
                enableCongrats = {
                    type = "toggle",
                    name = "Enable Congrats Messages",
                    desc = "Toggle Congrats messages in the chat window.",
                    order = 5,
                    get = function(info) return AutoMessage.db.profile.settings.enableCongrats end,
                    set = function(info, value) AutoMessage.db.profile.settings.enableCongrats = value end,
                },
                enableWelcome = {
                    type = "toggle",
                    name = "Enable Welcome Messages",
                    desc = "Toggle Welcome messages in the chat window.",
                    order = 5,
                    get = function(info) return AutoMessage.db.profile.settings.enableWelcome end,
                    set = function(info, value) AutoMessage.db.profile.settings.enableWelcome = value end,
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
                    disabled = function(info) return AutoMessage.db.profile.congrats.updateCongratsLock end,
                    confirm = true,
                    width = "full",
                    get = function(info) return table.concat(AutoMessage.db.profile.congrats.messages, "\n") end,
                    set = function(info, value) AutoMessage.db.profile.congrats.messages = { strsplit("\n", value) } end,
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
                    get = function(info) return AutoMessage.db.profile.congrats.updateCongratsLock end,
                    set = function(info, value) AutoMessage.db.profile.congrats.updateCongratsLock = value end;
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
                    disabled = function(info) return AutoMessage.db.profile.welcome.updateWelcomeLock end,
                    confirm = true,
                    order = 1,
                    width = "full",
                    get = function(info) return table.concat(AutoMessage.db.profile.welcome.messages, "\n") end,
                    set = function(info, value) AutoMessage.db.profile.welcome.messages = {strsplit('\n', value)} end
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
                    get = function(info) return AutoMessage.db.profile.welcome.updateWelcomeLock end,
                    set = function(info, value) AutoMessage.db.profile.welcome.updateWelcomeLock = value end;
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

local function LoadDefaultMessageIfNecessary()
    if #AutoMessage.db.profile.congrats.messages == 0 then
        AutoMessage.db.profile.congrats.messages = {            
            "Grats [username] on lvl [lvl]!",
            "Well done [username], you reached level [lvl]!",
            "Finally, [username] hit level [lvl]! Congrats!",
            "Awesome job [username], level [lvl] achieved!",
            "Congratulations [username] on reaching level [lvl]!",
            "Way to go [username], level [lvl] is yours!",
            "Great work [username], you made it to level [lvl]!",
            "Fantastic [username], level [lvl] unlocked!",
            "Impressive [username], you hit level [lvl]!",
            "Big grats [username] on level [lvl]!",
            "Keep it up [username], level [lvl] reached!",
            "Another one down, [username]! Welcome to level [lvl]!",
            "Nicely done [username], level [lvl] complete!",
            "You're on fire [username]! Level [lvl] achieved!",
            "GG [username], level [lvl] unlocked!",
            "Outstanding [username], welcome to level [lvl]!",
            "The grind pays off! Grats on level [lvl], [username]!",
            "Amazing work [username], level [lvl] reached!",
            "Level [lvl]? Easy for [username]! Grats!",
            "Keep climbing [username], level [lvl] attained!",
            "Cheers to [username] for reaching level [lvl]!",
            "Well played [username], level [lvl] is yours now!",
            "Another milestone for [username]: level [lvl]!",
            "Legendary effort [username], level [lvl] achieved!",
            "Congrats [username]! Level [lvl] looks good on you!",
            "Level [lvl] complete! Nice job [username]!",
            "Excellent work [username], level [lvl] reached!",
            "The adventure continues! Grats on level [lvl], [username]!",
            "Strong work [username], level [lvl] unlocked!",
            "You're crushing it [username]! Level [lvl] reached!",
            "A new level awaits! Congrats [username] on [lvl]!",
            "Nicely done, [username]! Welcome to level [lvl]!",
            "Another step toward greatness, [username]! Level [lvl]!",
            "Level [lvl] down, many more to go! Grats [username]!",
            "Keep those levels coming, [username]! [lvl] achieved!",
            "Victory! [username] has reached level [lvl]!",
            "Everybody clap for [username] hitting level [lvl]!",
            "Level [lvl] conquered by [username]! Grats!",
            "That's what I'm talking about! Grats [username] on [lvl]!",
            "Fantastic progress [username], level [lvl] reached!",
            "Another ding for [username]! Welcome to level [lvl]!",
            "The guild salutes [username] on reaching level [lvl]!",
            "Keep up the great work [username], level [lvl] achieved!",
            "Well earned, [username]! Congrats on level [lvl]!",
            "Level [lvl] has no chance against [username]!",
            "Brilliant effort [username], level [lvl] reached!",
            "The journey continues! Grats [username] on level [lvl]!",
            "Shiny new level acquired: [lvl]! Congrats [username]!",
            "Level [lvl] complete, onward and upward [username]!",
            "Huge congratulations to [username] for reaching level [lvl]!"
        }
    end
    if #AutoMessage.db.profile.welcome.messages == 0 then
        AutoMessage.db.profile.welcome.messages = {
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
            "Hey everyone, give a warm welcome to [username]!",
            "A big welcome to [username]!",
            "Welcome [username]! May your bags be full of loot!",
            "Welcome [username]! Happy questing!",
            "Great to have you join our ranks, [username]!",
            "Welcome [username]! Wishing you epic adventures ahead!",
            "Cheers and welcome, [username]!",
            "Welcome [username]! Let's make some great memories together!",
            "Welcome [username]! Hope you enjoy your stay!",
            "Another hero joins us! Welcome, [username]!",
            "Welcome [username]! Ready for raids and adventures?",
            "Greetings, [username]! Welcome to the guild!",
            "Welcome [username]! May your crits be plentiful!",
            "Welcome [username]! Glad you're part of the crew now!",
            "Welcome [username]! The guild just got stronger!",
            "Happy to see you here, [username]! Welcome!",
            "Welcome [username]! Looking forward to gaming with you!",
            "Welcome [username]! Hope you feel at home here!",
            "A warm guild welcome to [username]!",
            "Welcome [username]! Let's conquer Azeroth together!",
            "Welcome [username]! Adventure awaits!",
            "Welcome [username]! Great things are ahead!",
            "Welcome [username]! Enjoy your journey with us!",
            "Welcome [username]! Time to make some legends!",
            "Welcome [username]! We’re happy you found us!",
            "Welcome [username]! Here's to epic loot and good times!",
            "Welcome [username]! The adventure begins now!",
            "Everyone say hello to [username]!",
            "Welcome [username]! May your rolls always be high!",
            "Welcome [username]! Let's have some fun together!",
            "Welcome [username]! Hope you're ready for greatness!",
            "Welcome [username]! Glad to have another awesome member!",
            "Welcome [username]! Your adventure with us starts today!",
            "Welcome [username]! Thanks for joining our guild!",
            "Welcome [username]! Let's achieve great things together!",
            "Welcome [username]! Looking forward to many victories!",
            "Welcome [username]! May your journey be legendary!",
            "Welcome [username]! We can't wait to get to know you!",
            "Welcome [username]! Here's to friendship, fun, and loot!"
        }
    end
end


function AutoMessage:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AutoMessageDB", defaults, true)
    LoadDefaultMessageIfNecessary()
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
    LoadDefaultMessageIfNecessary()
end
