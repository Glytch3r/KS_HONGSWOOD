function SetBodyTemperature365(player, item)
    local player = getPlayer()
    if player then
        player:getModData().warmCoffee = true
        player:getModData().warmCoffeeTime = 21600
        
        player:Say("Drink the warm coffee.")
        print("Coffee effect started - 6 hours")
    end
end

local minuteCounter = 0
local tickCounter = 0

-- 1분마다 시간 감소 (기존 로직 유지)
local function checkWarmthTimer()
    local player = getPlayer()
    if player and player:getModData().warmCoffee then
        local timeLeft = player:getModData().warmCoffeeTime or 0
        
        if timeLeft > 0 then
            player:getModData().warmCoffeeTime = timeLeft - 60  -- 1분씩 감소
            
            -- 시간 알림
            local hoursLeft = math.floor(timeLeft / 3600)
            if timeLeft % 3600 == 0 and hoursLeft > 0 then
                print("Coffee warmth remaining: " .. hoursLeft .. " hours")
            end
        else
            -- 효과 종료 시 열원 제거
            if player:getModData().coffeeHeatSource then
                local square = player:getSquare()
                if square then
                    square:getCell():removeHeatSource(player:getModData().coffeeHeatSource)
                end
                player:getModData().coffeeHeatSource = nil
            end
            
            player:getModData().warmCoffee = nil
            player:getModData().warmCoffeeTime = nil
            player:Say("The warmth of the coffee has disappeared.")
            print("Coffee effect ended")
        end
    end
end

-- 빠른 열원 갱신 (매초)
local function updateHeatSource()
    tickCounter = tickCounter + 1
    
    -- 1초마다 열원 위치 갱신
    if tickCounter >= 60 then
        tickCounter = 0
        
        local player = getPlayer()
        if player and player:getModData().warmCoffee then
            local square = player:getSquare()
            if square then
                -- 기존 열원 제거
                if player:getModData().coffeeHeatSource then
                    square:getCell():removeHeatSource(player:getModData().coffeeHeatSource)
                end
                
                -- 새 열원 생성 (현재 위치에)
                local heatSource = IsoHeatSource.new(
                    square:getX(), 
                    square:getY(), 
                    square:getZ(), 
                    1,   -- 작은 반경
                    30   -- 온도
                )
                
                square:getCell():addHeatSource(heatSource)
                player:getModData().coffeeHeatSource = heatSource
            end
        end
    end
end

-- 이벤트 등록
Events.EveryOneMinute.Add(checkWarmthTimer)  -- 시간 관리용
Events.OnTick.Add(updateHeatSource)          -- 열원 갱신용