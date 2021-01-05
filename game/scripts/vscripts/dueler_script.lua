Dueler = class({})
LinkLuaModifier("dueler_movement", "modifiers/dueler_movement.lua", LUA_MODIFIER_MOTION_NONE)
ListenToGameEvent("game_rules_state_game_in_progress", function()
    if IsClient() then return end

    print("Dueling may now commence")
	Timers:CreateTimer( BUTTINGS.DUEL_DELAY or 15, Dueler.Trigger )
end, GameMode)

WORLD_XBOUND = 7200
WORLD_YBOUND = 6500
Dueler.radiant = {}
Dueler.dire = {}

function Dueler:Trigger()
    Dueler.radiant = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, 
                                        Vector(0,0,0), 
                                        nil, 
                                        FIND_UNITS_EVERYWHERE, 
                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
                                        DOTA_UNIT_TARGET_HERO, 
                                        DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, 
                                        FIND_ANY_ORDER, false)
    Dueler.dire = FindUnitsInRadius(    DOTA_TEAM_BADGUYS, 
                                        Vector(0,0,0), 
                                        nil, 
                                        FIND_UNITS_EVERYWHERE, 
                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
                                        DOTA_UNIT_TARGET_HERO, 
                                        DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
                                        FIND_ANY_ORDER, false)

    -- Iteration of duels
    for i = 1, math.max(#Dueler.radiant, #Dueler.dire) do
        Dueler:Duel(Dueler.radiant[i], Dueler.dire[i])
    end

	return BUTTINGS.DUEL_DELAY
end

function Dueler:Duel(dueler1, dueler2)
    -- Select Duelers
    if dueler1 and dueler2 then
        -- Nothing needs to be done here
    else
        dueler1 = dueler1 or dueler2
        if dueler1 == nil then 
            print("WE CALLED DUEL WITH NO DUELERS??")
            return 
        end
        local targetFlag = DOTA_UNIT_TARGET_BASIC --+ DOTA_UNIT_TARGET_BUILDING
        dueler2 = FindUnitsInRadius( dueler1:GetTeamNumber(), 
                                Vector(0,0,0), 
                                nil, 
                                FIND_UNITS_EVERYWHERE, 
                                DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                targetFlag, 
                                DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
                                FIND_ANY_ORDER, false)[1]
        if dueler2 == nil then
            print("Seriously? Every enemy dead?")
            return
        end
    end

    --[[ I thought to make the duel position at least on the point of a middle line based on the distance between the heroes, but that is not interesting enough.
    -- Obtain parameters
    local slope = (dueler2:GetAbsOrigin() - dueler1:GetAbsOrigin()):Normalized()
    local slopeInverse = Vector(slope.y, slope.x, slope.z) --print(slopeInverse:Length2D())
    local midpoint = (dueler2:GetAbsOrigin() + dueler1:GetAbsOrigin())/2
    local vectorOffset = RandomVector(75)

    -- Resolving duel position
    -- We find a spot that has the

    local dueler1pos = midpoint + vectorOffset
    local dueler2pos = midpoint - vectorOffset
    ]]

    -- Resolving duel position
    local duelpoint = Vector(RandomFloat(-WORLD_XBOUND, WORLD_XBOUND), RandomFloat(-WORLD_YBOUND, WORLD_YBOUND), 0)
    local vectorOffset = RandomVector(75)

    local dueler1pos = duelpoint + vectorOffset
    local dueler2pos = duelpoint - vectorOffset

    if dueler1:FindAbilityByName("duel_modified") == nil then
        local a = dueler1:AddAbility("duel_modified")
		a:SetLevel(1)
		a:SetHidden(true)
    end
    if dueler2:FindAbilityByName("duel_modified") == nil then
        local a = dueler2:AddAbility("duel_modified")
		a:SetLevel(1)
		a:SetHidden(true)
    end

    dueler1:AddNewModifier(dueler1, nil, "dueler_movement", {x = dueler1pos.x, y = dueler1pos.y, target = dueler2:entindex()})
    dueler2:AddNewModifier(dueler2, nil, "dueler_movement", {x = dueler1pos.x, y = dueler1pos.y, target = dueler1:entindex()})
end


