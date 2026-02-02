

----------------------------------------------------------------
-----  ▄▄▄   ▄    ▄   ▄  ▄▄▄▄▄   ▄▄▄   ▄   ▄   ▄▄▄    ▄▄▄  -----
----- █   ▀  █    █▄▄▄█    █    █   ▀  █▄▄▄█  ▀  ▄█  █ ▄▄▀ -----
----- █  ▀█  █      █      █    █   ▄  █   █  ▄   █  █   █ -----
-----  ▀▀▀▀  ▀▀▀▀   ▀      ▀     ▀▀▀   ▀   ▀   ▀▀▀   ▀   ▀ -----
----------------------------------------------------------------
--                                                            --
--   Project Zomboid Modding Commissions                      --
--   https://steamcommunity.com/id/glytch3r/myworkshopfiles   --
--                                                            --
--   ▫ Discord  ꞉   glytch3r                                  --
--   ▫ Support  ꞉   https://ko-fi.com/glytch3r                --
--   ▫ Youtube  ꞉   https://www.youtube.com/@glytch3r         --
--   ▫ Github   ꞉   https://github.com/Glytch3r               --
--                                                            --
----------------------------------------------------------------
----- ▄   ▄   ▄▄▄   ▄   ▄   ▄▄▄     ▄      ▄   ▄▄▄▄  ▄▄▄▄  -----
----- █   █  █   ▀  █   █  ▀   █    █      █      █  █▄  █ -----
----- ▄▀▀ █  █▀  ▄  █▀▀▀█  ▄   █    █    █▀▀▀█    █  ▄   █ -----
-----  ▀▀▀    ▀▀▀   ▀   ▀   ▀▀▀   ▀▀▀▀▀  ▀   ▀    ▀   ▀▀▀  -----
----------------------------------------------------------------
TrailingHeat = TrailingHeat or {}
function TrailingHeat.invContext(plNum, context, items)
    local pl = getSpecificPlayer(plNum)
    if not pl then return end
    local item = nil
    for i, packet in ipairs(items) do
        if type(packet) == "table" then
            item = packet.items[1]
        elseif instanceof(packet, "InventoryItem") then
            item = packet
        end
    end
    if not item then return end
    if item:getModData()['isCanCauseHeat'] == nil then return end
    if not TrailingHeat then return end
    local opt = context:addOptionOnTop("Use Sun Packet", item, function() 
        TrailingHeat.doTrailingHeat(30)
        ISRemoveItemTool.removeItem(item, plNum)
    end)

    opt.iconTexture = getTexture("media/textures/Item_"..tostring(item:getType())..".png")
   
end

Events.OnFillInventoryObjectContextMenu.Remove(TrailingHeat.invContext)
Events.OnFillInventoryObjectContextMenu.Add(TrailingHeat.invContext)
