local _,addon=...;

function addon.print(text, color, size)
    local sizes = addon.Sizes()
    local R, G, B

    if color == nil then
        R, G, B = 1, 1, 1 -- white default
    else
        R, G, B = color["R"], color["G"], color["B"]
    end

    if
        size == sizes.LARGE or
        size == sizes.BIG
    then
        ZoneTextString:SetText(text);
        PVPInfoTextString:SetText("");
        ZoneTextFrame.startTime = GetTime()
        ZoneTextFrame.fadeInTime = 0
        ZoneTextFrame.holdTime = 1
        ZoneTextFrame.fadeOutTime = 2
        ZoneTextString:SetTextColor(R, G, B);
        ZoneTextFrame:Show()
    else -- size == sizes.SMALL
        UIErrorsFrame:AddMessage(text, R, G, B);
    end
end

function addon.playSound(sound)
    PlaySoundFile("Interface\\AddOns\\SpellNotifications\\sounds\\" .. sound .. ".mp3", "Master");
end
