Dueler = class({})
ListenToGameEvent("game_rules_state_game_in_progress", function()
		Timers:CreateTimer( BUTTINGS.DUEL_DELAY or 15, Dueler.Trigger )
end, GameMode)

Dueler.radiant = {}
Dueler.dire = {}

function Dueler:Trigger()
    Dueler.radiant = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, 
                                        Vector(0,0,0), 
                                        nil, 
                                        FIND_UNITS_EVERYWHERE, 
                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
                                        DOTA_UNIT_TARGET_HERO, 
                                        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, 
                                        FIND_ANY_ORDER, false)
    Dueler.dire = FindUnitsInRadius(    DOTA_TEAM_BADGUYS, 
                                        Vector(0,0,0), 
                                        nil, 
                                        FIND_UNITS_EVERYWHERE, 
                                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
                                        DOTA_UNIT_TARGET_HERO, 
                                        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
                                        FIND_ANY_ORDER, false)

    -- Iteration of duels
    for i = 1, math.max(#Dueler.radiant, #Dueler.dire) do
        Dueler:Duel(Dueler.radiant[i], Dueler.dire[i])
    end

	return BUTTINGS.DUEL_DELAY
end

function Dueler:Duel(dueler1, dueler2)
    -- Both heroes case
    if dueler1 and dueler2 then
        dueler1:EmitSound("Hero_Pangolier.Gyroshell.Stop")
        dueler2:EmitSound("Hero_Pangolier.Gyroshell.Stop")
    --else
        
    end
end