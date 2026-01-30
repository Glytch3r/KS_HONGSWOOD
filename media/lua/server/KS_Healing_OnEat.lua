------------------------------------------------------------
-- FILE NAME : KS_Healing_onEat.lua
-- AUTHOR    : KS (삼계탕 & 벵쇼 세트 만든 그 사람)
--
-- [요약]
--  - 부상 회복 음식 OnEat 핸들러
--  - 질병 회복 음식 OnEat 핸들러
--  - 각각 "모두 다 먹었을 때만" 효과 발동
--  - 효과 발동 시, 게임 시간 기준 24시간 쿨타임 부여
--  - 쿨타임 남았으면 효과 없이 말풍선만 출력 ("Still on cooldown!")
--
-- [주의사항]
--  - 이 파일은 "서버 사이드"에서 동작하는 스크립트로 사용하는 것을 권장
--    (media/lua/server 쪽에 두는 걸 추천)
--  - 쿨타임은 "OnEat 시점"에만 체크함
--    → 따로 EveryX 이벤트로 실시간 감시는 하지 않음
------------------------------------------------------------


------------------------------------------------------------
-- 공통 유틸 함수
------------------------------------------------------------

-- 현재 게임 세계의 누적 시간(시간 단위)을 반환
--  - getWorldAgeHours() : 게임이 시작된 후 흐른 시간(시간 단위, float)
--  - 쿨타임 계산에 사용
local function getNowHours()
    return getGameTime():getWorldAgeHours()
end

-- 음식이 "얼마나 먹혔는지" 비율(percent)을 보고
-- 완전히(또는 거의) 다 먹었을 때만 true를 반환
--  - PZ에서 percent가 nil인 경우도 있기 때문에 nil이면 "다 먹은 것"으로 간주
--  - percent는 0.0 ~ 1.0 사이 값. 0.97 이상이면 풀 섭취로 처리
local function KS_IsFullEat(percent)
    if not percent then return true end
    return percent >= 0.97
end

-- 플레이어 머리 위 말풍선 출력용 편의 함수
--  - player: IsoPlayer
--  - msg   : string
local function sayBubble(player, msg)
    if player and msg then
        player:Say(msg)
    end
end


------------------------------------------------------------
-- 설정 값 (밸런스 조절용)
------------------------------------------------------------

-- COOLDOWN_HOURS
--  - 회복 음식 사용 후 다시 사용할 수 있기까지 걸리는 시간(게임 시간 기준)
--  - 24.0이면 게임 내 24시간 = 인게임 1일 쿨타임
local COOLDOWN_HOURS = 24.0

-- HEAL_STEPS / HEAL_DELTA
--  - 질병 관련 수치(감기, 식중독, 가짜 감염 등)를
--    몇 번에 나눠서 0까지 내릴지 결정하는 용도
--  - 현재는 5번(20%씩 깎이는 구조) 기준 값
local HEAL_STEPS     = 5
local HEAL_DELTA     = 100.0 / HEAL_STEPS


------------------------------------------------------------
-- 쿨타임 체크 함수
--  - OnEat에서 "사용 가능 여부" 판단에 사용
------------------------------------------------------------

-- 부상 회복 음식 쿨타임 사용 가능 여부
--  - modData.KS_RecoveryInjuryNextUse : 다음 사용 가능 시간(월드 시간 기준)
--  - 현재 시간이 NextUse 이상이면 true → 사용 가능
local function canUseRecoveryInjury(player)
    local md = player:getModData()
    return getNowHours() >= (md.KS_RecoveryInjuryNextUse or 0)
end

-- 질병 회복 음식 쿨타임 사용 가능 여부
local function canUseRecoveryDisease(player)
    local md = player:getModData()
    return getNowHours() >= (md.KS_RecoveryDiseaseNextUse or 0)
end


------------------------------------------------------------
-- 1) 부상 회복 로직
--
-- 대상:
--  - 출혈(bleeding)
--  - 화상(burn)
--  - 골절(fracture)
--  - 베인 상처(cut)
--  - 깊은 상처(deep wound)
--  - 물림(bite)
--  - 상처 감염(infected wound)
--  - 추가 통증(Additional Pain)
--
-- 작동 방식:
--  - 각 부위별로 시간을 일정량 감소시켜 회복을 "당겨줌"
--  - 0 이하가 되면 해당 상태 플래그(false)로 전환
--  - 봉합된 상처는 stitchTime에 보너스를 줘서 회복을 빠르게 함
------------------------------------------------------------
local function applyRecoveryInjury(player)
    local bd    = player:getBodyDamage()
    local parts = bd and bd:getBodyParts()
    if not parts then return end

    -- 각 부상 종류별 시간 감소량
    local DELTA             = 10.0   -- 출혈 기본 감소량
    local BURN_DELTA        = 5.0    -- 화상
    local FRACTURE_DELTA    = 3.0    -- 골절
    local CUT_DELTA         = 2.0    -- 베임
    local DEEP_WOUND_DELTA  = 3.0    -- 깊은 상처
    local BITE_DELTA        = 3.0    -- 물림

    local PAIN_DELTA   = 20.0       -- 추가 통증 감소량
    local STITCH_BONUS = 10.0       -- 봉합 상처 회복 진행도 보너스

    for i = 0, parts:size() - 1 do
        local part = parts:get(i)

        ------------------------------------------------
        -- 출혈(bleeding)
        ------------------------------------------------
        local bleed = part:getBleedingTime()
        if bleed > 0 then
            bleed = math.max(bleed - DELTA, 0)
            part:setBleedingTime(bleed)
            if bleed == 0 then
                part:setBleeding(false)
            end
        end

        ------------------------------------------------
        -- 화상(burn)
        ------------------------------------------------
        local burn = part:getBurnTime()
        if burn > 0 then
            burn = math.max(burn - BURN_DELTA, 0)
            part:setBurnTime(burn)
        end

        ------------------------------------------------
        -- 골절(fracture)
        ------------------------------------------------
        local frac = part:getFractureTime()
        if frac > 0 then
            frac = math.max(frac - FRACTURE_DELTA, 0)
            part:setFractureTime(frac)
        end

        ------------------------------------------------
        -- 베임(cut)
        ------------------------------------------------
        local cut = part:getCutTime()
        if cut > 0 then
            cut = math.max(cut - CUT_DELTA, 0)
            part:setCutTime(cut)
            if cut == 0 then
                part:setCut(false)
            end
        end

        ------------------------------------------------
        -- 깊은 상처(deep wound)
        ------------------------------------------------
        local deep = part:getDeepWoundTime()
        if deep > 0 then
            deep = math.max(deep - DEEP_WOUND_DELTA, 0)
            part:setDeepWoundTime(deep)
            if deep == 0 then
                part:setDeepWounded(false)
            end
        end

        ------------------------------------------------
        -- 봉합된 깊은 상처(stitched deep wound)
        --  - stitchTime이 40에 도달하면 완치로 보는 기본 메커니즘을
        --    보너스로 빠르게 진행시킴
        ------------------------------------------------
        if part:stitched() then
            local st = part:getStitchTime()
            if st < 40 then
                st = math.min(st + STITCH_BONUS, 40)
                part:setStitchTime(st)
            end
        end

        ------------------------------------------------
        -- 물림(bite)
        ------------------------------------------------
        local bite = part:getBiteTime()
        if bite > 0 then
            bite = math.max(bite - BITE_DELTA, 0)
            part:setBiteTime(bite)
            if bite == 0 then
                -- 물림 상태 해제
                part:SetBitten(false)
            end
        end

        ------------------------------------------------
        -- 상처 감염(infected wound)
        --  - 회복 음식이 상처 감염 상태도 동시에 정리해주는 컨셉
        ------------------------------------------------
        if part:isInfectedWound() then
            part:setInfectedWound(false)
        end

        ------------------------------------------------
        -- 추가 통증(Additional Pain)
        ------------------------------------------------
        local ap = part:getAdditionalPain()
        if ap > 0 then
            ap = math.max(ap - PAIN_DELTA, 0)
            part:setAdditionalPain(ap)
        end
    end
end


------------------------------------------------------------
-- 2) 질병 회복 로직
--
-- 대상:
--  - 감기(ColdStrength, HasACold, CatchACold)
--  - 식중독(FoodSicknessLevel)
--  - 가짜 감염(FakeInfectionLevel, IsFakeInfected)
--
-- 작동 방식:
--  - 각 질병 수치를 HEAL_DELTA(=20)만큼 줄임
--  - 0 이하로 떨어지면 해당 상태 플래그를 false로 전환
------------------------------------------------------------
local function applyRecoveryDisease(player)
    local bd = player:getBodyDamage()
    if not bd then return end

    ------------------------------------------------
    -- 감기(Cold)
    ------------------------------------------------
    local cold = bd:getColdStrength()
    if cold > 0 then
        cold = math.max(cold - HEAL_DELTA, 0)
        bd:setColdStrength(cold)

        if cold == 0 then
            -- 완치: 감기, 감기 진행도 모두 리셋
            bd:setHasACold(false)
            bd:setCatchACold(0)
        else
            -- 아직 감기가 남아 있는 상태
            bd:setHasACold(true)
        end
    end

    ------------------------------------------------
    -- 식중독(Food Sickness)
    ------------------------------------------------
    local food = bd:getFoodSicknessLevel()
    if food > 0 then
        food = math.max(food - HEAL_DELTA, 0)
        bd:setFoodSicknessLevel(food)
    end

    ------------------------------------------------
    -- 가짜 감염(Fake Infection)
    ------------------------------------------------
    local fake = bd:getFakeInfectionLevel()
    if fake > 0 then
        fake = math.max(fake - HEAL_DELTA, 0)
        bd:setFakeInfectionLevel(fake)
        bd:setIsFakeInfected(fake > 0)
    end
end


------------------------------------------------------------
-- OnEat: 부상 회복 음식
--
-- 흐름:
--  1) 다 먹었는지 확인 (KS_IsFullEat)
--  2) 쿨타임 확인 (canUseRecoveryInjury)
--  3) 쿨타임 남았으면 "Still on cooldown!" 말풍선 출력 후 종료
--  4) 부상 회복 로직 적용 (applyRecoveryInjury)
--  5) NextUse & CooldownActive 갱신 (쿨타임 기록)
------------------------------------------------------------
function OnEat_KS_Recovery_Injury(food, player, percent)
    -- 다 안 먹었으면 효과 없음
    if not KS_IsFullEat(percent) then return end

    -- 쿨타임 체크
    if not canUseRecoveryInjury(player) then
        sayBubble(player, "Still on cooldown!")
        return
    end

    -- 부상 회복 처리
    applyRecoveryInjury(player)

    -- 쿨타임 기록
    local md = player:getModData()
    md.KS_RecoveryInjuryNextUse        = getNowHours() + COOLDOWN_HOURS
    md.KS_RecoveryInjuryCooldownActive = true  -- 향후 확장(예: HUD 표시)용 플래그

    -- 플레이어에게 버프 활성화 느낌 전달
    sayBubble(player, "Warm Samgyetang. Recovery buff lasts for 24 hours.")
end


------------------------------------------------------------
-- OnEat: 질병 회복 음식
--
-- 흐름:
--  1) 다 먹었는지 확인
--  2) 쿨타임 확인
--  3) 쿨타임 남았으면 "Still on cooldown!"
--  4) 질병 회복 로직 적용
--  5) 쿨타임 갱신
------------------------------------------------------------
function OnEat_KS_Recovery_Disease(food, player, percent)
    -- 다 안 먹었으면 효과 없음
    if not KS_IsFullEat(percent) then return end

    -- 쿨타임 체크
    if not canUseRecoveryDisease(player) then
        sayBubble(player, "Still on cooldown!")
        return
    end

    -- 질병 회복 처리
    applyRecoveryDisease(player)

    -- 쿨타임 기록
    local md = player:getModData()
    md.KS_RecoveryDiseaseNextUse        = getNowHours() + COOLDOWN_HOURS
    md.KS_RecoveryDiseaseCooldownActive = true  -- 향후 확장용 플래그

    -- 플레이어에게 버프 활성화 느낌 전달
    sayBubble(player, "Warm VinChaud. Recovery buff lasts for 24 hours.")
end


------------------------------------------------------------
-- END OF FILE
------------------------------------------------------------
