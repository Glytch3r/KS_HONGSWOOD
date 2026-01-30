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

TrailingHeat.ticks = 0
TrailingHeat.HeatSource = nil

function TrailingHeat.delHeat()
    if TrailingHeat.HeatSource then
        getCell():removeHeatSource(TrailingHeat.HeatSource)
        TrailingHeat.HeatSource = nil
    end
end

function TrailingHeat.addHeat(pl)
    
    pl = pl or getPlayer()
    if not pl or not pl:isAlive() then return end

    local sq = pl:getCurrentSquare()
    if not sq then return end

    TrailingHeat.HeatSource = IsoHeatSource.new(
        sq:getX(),
        sq:getY(),
        sq:getZ(),
        1,
        30
    )
    getCell():addHeatSource(TrailingHeat.HeatSource)
end

function TrailingHeat.update(pl)
    TrailingHeat.ticks = TrailingHeat.ticks + 1
    if TrailingHeat.ticks % 60 ~= 0 then return end
    pl:getModData()['TrailingHeat'] = pl:getModData()['TrailingHeat'] or false
    TrailingHeat.delHeat()
    if pl:getModData()['TrailingHeat'] then
        TrailingHeat.addHeat(pl)
    end
end

Events.OnPlayerUpdate.Remove(TrailingHeat.update)
Events.OnPlayerUpdate.Add(TrailingHeat.update)

function TrailingHeat.doTrailingHeat()
    local pl = getPlayer() 
    pl:getModData()['TrailingHeat'] = true
    TrailingHeat.pause(5, function()
        pl:getModData()['TrailingHeat'] = false
    end)
end


function TrailingHeat.pause(seconds, callback)
    local start = getTimestampMs()
    local duration = seconds * 1000
    
    local function tick()
        local now = getTimestampMs()
        if now - start >= duration then
            Events.OnTick.Remove(tick)
            if callback then callback() end
        end
    end
    Events.OnTick.Add(tick)
end

function TrailingHeat.init()
    getPlayer():getModData()['TrailingHeat'] = false
end
Events.OnCreatePlayer.Add(TrailingHeat.init)
