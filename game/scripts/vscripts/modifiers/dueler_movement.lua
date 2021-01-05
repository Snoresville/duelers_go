--Dash movement modifier
dueler_movement = dueler_movement or class({})

function dueler_movement:OnCreated(kv)
    if IsClient() then return end
    self:GetParent():EmitSound("Hero_Pangolier.Gyroshell.Stop")

	--variables
	self.time_elapsed = 0

	-- Wait one frame to get the target point from the ability's OnSpellStart, then calculate distance
    Timers:CreateTimer(FrameTime(), function()
        self.target_point = Vector(kv.x, kv.y, 0)
		self.distance = (self:GetCaster():GetAbsOrigin() - self.target_point):Length2D()
		self.dash_time = 1
		self.direction = (self.target_point - self:GetCaster():GetAbsOrigin()):Normalized()

		--Add dash particle
		local dash = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_swashbuckler_dash.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(dash, 0, self:GetCaster():GetAbsOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
		self:AddParticle(dash, false, false, -1, true, false)

        self.frametime = FrameTime()
		self:StartIntervalThink(self.frametime)
	end)
	
end

--pangolier is stunned during the dash
function dueler_movement:CheckState()
	state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_INVULNERABLE] = true
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

	-- Check Motion controllers
	if not self:CheckMotionControllers() then
		self:Destroy()
		return nil
	end

	--Talent #1: Enemies in the dash path are applied a basic attack
	if self:GetCaster():HasTalent("special_bonus_imba_pangolier_1") then
		self.enemies_hit = self.enemies_hit or {}
		local direction = self:GetCaster():GetForwardVector()
		local caster_loc = self:GetCaster():GetAbsOrigin()
		local target_loc = caster_loc + direction * self.talent_radius

		--Check for enemies in front of pangolier
		local enemies = FindUnitsInLine(self:GetCaster():GetTeamNumber(),
			caster_loc,
			target_loc,
			nil,
			self.talent_radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)

		for _,enemy in pairs(enemies) do
			--Do nothing if the target was hit already
			local already_hit = false
			for k,v in pairs(self.enemies_hit) do

				if v == enemy then
					already_hit = true
					break
				end
			end

			if not already_hit then
				--Play damage sound effect
				EmitSoundOn(self.hit_sound, enemy)

				--can't hit Ethereal enemies
				if not enemy:IsAttackImmune() then
					--Apply the basic attack
					self:GetCaster():PerformAttack(enemy, true, true, true, true, false, false, true)

					table.insert(self.enemies_hit, enemy) --Mark the target as hit
				end
			end

		end
	end

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
			self:GetCaster():SetAbsOrigin(new_location)
		else
			self:Destroy()
		end
	end
end

function dueler_movement:OnRemoved()
	if IsServer() then
		self:GetCaster():SetUnitOnClearGround()

		--Pangolier finished the dash: look for enemies in range starting from the nearest
		local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
			self:GetCaster():GetAbsOrigin(),
			nil,
			self.range,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
			FIND_CLOSEST,
			false)

		--Check if there is an enemy hero in range. In case there is, he will be targeted, otherwise the nearest enemy unit is targeted
		local target_unit = nil
		local target_direction = nil
		if #enemies > 0 then --In case there is no target in range, Pangolier will attack in front of him
			for _,enemy in pairs(enemies) do
				target_unit = target_unit or enemy	--track the nearest unit
				if enemy:IsRealHero() then
					target_unit = enemy
					break
				end
		end
		--Turn Pangolier towards the target
		target_direction = (target_unit:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized()
		self:GetCaster():SetForwardVector(target_direction)
		end

		--plays the slash animation
		self:GetCaster():StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)

		--Add the attack modifier on Pangolier that will handle the slashes

		local attack_modifier_handler = self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), self.attack_modifier, {})

		--pass the target
		attack_modifier_handler.target = target_unit
	end
end