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

-- If the client refuses the file (PlaySoundFile answers false; WoW Forever can), the game's raid-warning sound plays
-- instead, so a warning is never silent
function addon.playSound(sound)
    local ok, willPlay = pcall(PlaySoundFile, "Interface\\AddOns\\SpellNotifications\\sounds\\" .. sound .. ".mp3", "Master")
    if not (ok and willPlay) and PlaySound then
        local kit = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959
        pcall(PlaySound, kit, "Master")
    end
end
