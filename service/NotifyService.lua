local _,addon=...;

function addon.print(text, color, size)
    local color = string.lower(color)
    local size = string.lower(size)
    local colors = addon.Colors()[color]
    local R, G, B

    if colors == nil then
        R, G, B = 1, 1, 1 -- white default
    else
        R, G, B = colors["R"], colors["G"], colors["B"]
    end

    if size == "large" or size == "big" then
        ZoneTextString:SetText(text);
        PVPInfoTextString:SetText("");
        ZoneTextFrame.startTime = GetTime()
        ZoneTextFrame.fadeInTime = 0
        ZoneTextFrame.holdTime = 1
        ZoneTextFrame.fadeOutTime = 2
        ZoneTextString:SetTextColor(R, G, B);
        ZoneTextFrame:Show()
    else -- size == "small"
        UIErrorsFrame:AddMessage(text, R, G, B);
    end
end

function addon.playSound(sound)
    PlaySoundFile("Interface\\AddOns\\SpellNotifications\\sounds\\" .. sound .. ".mp3", "Master");
end
