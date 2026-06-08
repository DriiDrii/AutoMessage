function AutoMessage:ChatCommand(input)
    local Dialog = LibStub("AceConfigDialog-3.0")
    if Dialog.OpenFrames["AutoMessage"] then
        Dialog:Close("AutoMessage")
    end
    if not input or input:trim() == "" then
       Dialog:Open("AutoMessage")
    else
        self:Print("Unknown command. Type /am or /automessage to open the configuration.")
    end
end