-- KS_Healing_Moodles.lua
-- 부상/질병 쿨타임 동안 커스텀 무들 아이콘 표시 (클라이언트 전용)

--------------------------------------------------------
-- 공용 함수
--------------------------------------------------------
local function getNowHours()
    return getGameTime():getWorldAgeHours()
end

-- 아이콘 텍스처 미리 로드
local texInjury  = getTexture("media/ui/KS_Healing_MoodleInjury.png")
local texDisease = getTexture("media/ui/KS_Healing_MoodleDisease.png")

--------------------------------------------------------
-- 무들 비슷하게 화면 오른쪽에 아이콘 그리기(마우스오버, 무들lev 이벤트는 적용X)
--------------------------------------------------------
local function KS_Healing_DrawCooldownMoodles()
    local player = getPlayer()
    if not player or player:isDead() then return end

    local md = player:getModData()
    if not md then return end

    -- 쿨타임 만료 여부를 여기서 직접 체크해서 플래그 정리
    local now = getNowHours()

    -- 부상 회복 쿨타임 만료 체크
    if md.KS_RecoveryInjuryCooldownActive then
        local nextUse = md.KS_RecoveryInjuryNextUse or 0
        if now >= nextUse then
            md.KS_RecoveryInjuryCooldownActive = nil
            md.KS_RecoveryInjuryNextUse = nil
            -- 필요하면 말풍선도 가능:
            -- player:Say("Injury recovery buff ended.")
        end
    end

    -- 질병 회복 쿨타임 만료 체크
    if md.KS_RecoveryDiseaseCooldownActive then
        local nextUse = md.KS_RecoveryDiseaseNextUse or 0
        if now >= nextUse then
            md.KS_RecoveryDiseaseCooldownActive = nil
            md.KS_RecoveryDiseaseNextUse = nil
            -- player:Say("Disease recovery buff ended.")
        end
    end

    -- 정리된 플래그 기준으로 무들 표시 여부 결정
    local injuryActive  = md.KS_RecoveryInjuryCooldownActive
    local diseaseActive = md.KS_RecoveryDiseaseCooldownActive

    -- 둘 다 없으면 아무것도 그리지 않음
    if not injuryActive and not diseaseActive then
        return
    end

    -- 화면 사이즈 기준 위치 (우측 상단 쪽)
    local core = getCore()
    local screenW = core:getScreenWidth()
    -- local screenH = core:getScreenHeight() -- 지금은 안 쓰지만 필요하면 사용

    -- 바닐라 무들 위치 근처로 배치
    local baseX = screenW - 80
    local baseY = 120
    local offsetY = 34        -- 아이콘 간 간격 (px)

    local index = 0

    -- 부상 쿨타임 아이콘
    if injuryActive and texInjury then
        texInjury:render(baseX, baseY + index * offsetY)
        index = index + 1
    end

    -- 질병 쿨타임 아이콘
    if diseaseActive and texDisease then
        texDisease:render(baseX, baseY + index * offsetY)
        index = index + 1
    end
end

--------------------------------------------------------
-- 이벤트 등록
--------------------------------------------------------
Events.OnPostUIDraw.Add(KS_Healing_DrawCooldownMoodles)
