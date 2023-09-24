--Dash movement modifier
dueler_movement = dueler_movement or class({})

function dueler_movement:OnCreated(kv)
    if IsClient() then return end
    self:GetParent():EmitSound("Hero_Pangolier.Gyroshell.Stop")
    ProjectileManager:ProjectileDodge(self:GetParent())

	--variables
    self.time_elapsed = 0
    self:SetStackCount(math.random(6))
    self.target = kv.target

	-- Wait one frame to get the target point from the ability's OnSpellStart, then calculate distance
    Timers:CreateTimer(FrameTime(), function()
        self.target_point = Vector(kv.x, kv.y, GetGroundHeight(self:GetParent():GetAbsOrigin(), self:GetParent()))
        self.distance = (self:GetCaster():GetAbsOrigin() - self.target_point):Length2D()
        self.dash_time =  math.min(Buttings:GetValue("CUSTOM_GAME_OPTIONS", "DASH_TIME"), Buttings:GetValue("CUSTOM_GAME_OPTIONS", "DUEL_DELAY") - 5) -- prevents yeeting mid-duel
        self.dash_speed = self.distance / self.dash_time
        self.direction = (self.target_point - self:GetCaster():GetAbsOrigin()):Normalized()

		--Add dash particle
		local dash = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_swashbuckler_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(dash, 0, self:GetParent():GetAbsOrigin()) -- point 0: origin
        ParticleManager:SetParticleControl(dash, 2, self:GetParent():GetAbsOrigin()) -- point 2: sparkles
        ParticleManager:SetParticleControl(dash, 5, self:GetParent():GetAbsOrigin()) -- point 5: burned soil
		self:AddParticle(dash, false, false, -1, true, false)

        self.frametime = FrameTime()
		self:StartIntervalThink(self.frametime)
	end)
	
end

--pangolier is stunned during the dash
function dueler_movement:CheckState()
	state = {
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }

	return state
end

function dueler_movement:IsHidden() return true end
function dueler_movement:IsPurgable() return false end
function dueler_movement:IsDebuff() return false end
function dueler_movement:IgnoreTenacity() return true end
function dueler_movement:IsMotionController() return true end
function dueler_movement:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end

function dueler_movement:OnIntervalThink()
	-- Horizontal motion
	self:HorizontalMotion(self:GetParent(), self.frametime)
end

function dueler_movement:HorizontalMotion(me, dt)
	if IsServer() then
		-- Check if we're still dashing
		self.time_elapsed = self.time_elapsed + dt
		if self.time_elapsed < self.dash_time then

			-- Go forward
            local new_location = self:GetCaster():GetAbsOrigin() + self.direction * self.dash_speed * dt
            new_location.z = GetGroundHeight(self:GetParent():GetAbsOrigin(), self:GetParent())
			self:GetCaster():SetAbsOrigin(new_location)
		else
			self:Destroy()
		end
	end
end

function dueler_movement:OnRemoved()
    if IsClient() then return end
    GridNav:DestroyTreesAroundPoint(self:GetParent():GetAbsOrigin(), 150, false)
    FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)

    local ability = self:GetParent():FindAbilityByName("duel_modified")
    if ability and not self:GetParent():HasModifier("modifier_legion_commander_duel") then
        self:GetParent():SetCursorCastTarget(EntIndexToHScript(self.target))
        ability:OnSpellStart()
    end
end

-- Modifier Effects
function dueler_movement:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function dueler_movement:GetOverrideAnimation( params )
    local anims = {
        ACT_DOTA_IDLE_RARE,
        ACT_DOTA_RUN,
        ACT_DOTA_DISABLED,
        ACT_DOTA_VICTORY,
        ACT_DOTA_DEFEAT,
        ACT_DOTA_FLAIL,
    }

	return anims[math.min(self:GetStackCount(), #anims)]
end