--Combat Script Beta 1.0
--EvanTheBuilder

--Changelog:

--V1.0
--Initial worg

--Plan:
--Finish smash ability
--Create more abilities
--Create another weapon

HITBOXDEBUG = false
FRAMEDEBUG = false

player = script.Parent.Parent
service = game.ContextActionService
runservice = game:GetService('RunService')

----------------------------------------------------------------------
--Player Input

function getMouse()
	local mouse = player:GetMouse()
	mouse.TargetFilter = workspace.MouseIgnores
	return mouse
end

function keyEventHandler(actionName, state, inputobject)
	if state == Enum.UserInputState.Begin then
		local key = inputobject.KeyCode
		--Take action
		if key == Enum.KeyCode.E then
			charge(getMouse())
		end
		return Enum.ContextActionResult.Pass
	elseif state == Enum.UserInputState.End then
		local key = inputobject.KeyCode
		if key == Enum.KeyCode.E then
			release()
		end
	end
end

service:BindAction("primaryKeyEventHandler", keyEventHandler, false, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R)

function mouseEventHandler(actionName, state, inputobject)
	if state == Enum.UserInputState.Begin then
		local mouse = getMouse()
		slash(mouse)
		return Enum.ContextActionResult.Pass
	end
end

service:BindAction("primaryMouseEventHandler", mouseEventHandler, false, Enum.UserInputType.MouseButton1)

---------------------------------------------------------------------
--Utilities

function getTorsoProps()
	local torso
	if player.Character:FindFirstChild("UpperTorso") then 
		torso = player.Character.UpperTorso
	elseif player.Character:FindFirstChild("Torso") then
		torso = player.Character.Torso
	end
	return torso, torso.CFrame
end

function debugDisplayPosition(cframe, color, length, timeout)
	if not timeout then timeout = 5 end
	if not length then length = 3 end
	local p = Instance.new("Part")
	p.Name = "DisplayDebugPart"
	p.Parent = workspace
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.5, 0.5, length)
	p.CFrame = cframe
	p.BottomSurface = 0
	p.TopSurface = 0
	p.BrickColor = color
	spawn(function() wait(timeout) p:Destroy() end)
	return p
end

function findInTable(tab, object)
	for i = 1, #tab do
		if tab[i] == object then
			return i
		end
	end
	return -1
end

function combineTables(tab1, tab2, uniques)
	if uniques == nil then uniques = true end
	local newtab = {}
	local index = 1
	for i = 1, #tab1 do
		newtab[index] = tab1[i]
		index = index + 1
	end
	for i = 1, #tab2 do
		if uniques and findInTable(newtab, tab2[i]) == -1 then
			newtab[index] = tab2[i]
			index = index + 1
		elseif not uniques then
			newtab[index] = tab2[i]
			index = index +1
		end
	end
	return newtab
end

-------------------------------------------------------------------------
--Ability Settings

smash_oncooldown = false
smash_cdLength = 0.5
smash_range = 25

using_ability = false
slash_onCooldown = false
slash_cdLength = 0.06
sword_mesh = "rbxasset://fonts/sword.mesh"

----------------------------------------------------------------------------
--Sounds

slash_sound = "http://www.roblox.com/asset/?id=12222208"
treefell_sound = "rbxassetid://1911995155"
swordhit_sound = "rbxassetid://566593606"
charge_sound = "rbxassetid://1371567007"
charge_gosound = "rbxassetid://1127797047"

function playSound(parent, soundid, volume, pitch, starttime, nodestroy)
	if not starttime then starttime = 0 end
	local s = Instance.new("Sound")
	if nodestroy then
		s.PlayOnRemove = false
		s:Play()
	else
		s.PlayOnRemove = true
	end
	s.SoundId = soundid
	local pitchmod = 0.15*math.sin(math.random() * 2 * math.pi) --Change by random +/- 0.1
	s.Volume = volume
	s.PlaybackSpeed = pitch + pitchmod
	s.TimePosition = starttime
	s.MaxDistance = 2000
	if parent.PrimaryPart ~= nil then
		s.Parent = parent.PrimaryPart
	else
		s.Parent = parent:GetChildren()[1]
	end
	if nodestroy then
		return s
	else
		s:Destroy()
	end
end

function createSound(soundid, volume, pitch, starttime)
	if not starttime then starttime = 0 end
	local s = Instance.new("Sound")
	s.SoundId = soundid
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.TimePosition = starttime
	s.MaxDistance = 2000
	return s
end

---------------------------------------------------------------
--Damage

--Damage a human for a given amount
function damageCharacter(char, damage)
	local human = char:FindFirstChild("Humanoid")
	if not human then return end
	human:TakeDamage(damage)
	playSound(char, swordhit_sound, 0.4, 1, 0.2)
end

--Go through a list of parts, and damage them accordingly to what they are, human or tree so far
function damageItems(parts, damage_amount, damaged_models)
	local new_damaged = {}
	for _, part in pairs(parts) do
		local model = part.Parent
		if findInTable(damaged_models, model) == -1 then --If not already damaged
			table.insert(new_damaged, model)
			if model:FindFirstChild("Humanoid") then
				if model ~= player.Character then 
					damageCharacter(model, damage_amount)
				end
			elseif model.Name == "Tree" then
				fellTree(model)
			end
		end
	end
	return new_damaged
end

function getSineVector3()
	local x = math.sin(2*math.pi*math.random())
	local y = math.sin(2*math.pi*math.random())
	local z = math.sin(2*math.pi*math.random())
	return Vector3.new(x, y, z)
end

--Fell a tree that is contacted by one of our weapons
function fellTree(tree)
	if tree:GetChildren()[1].Anchored == true then
		print "Felling tree"
		for _, part in pairs(tree:GetChildren()) do
			part.Anchored = false
			if part.Name ~= "Trunk" then
				local pos = Vector3.new(2, 3, 2) + (getSineVector3() * Vector3.new(3, 4, 3))
				local angles = getSineVector3() * Vector3.new(0.4, 0.4, 0.4) --Move everything a little bit to freak trees out
				part.CFrame = part.CFrame * CFrame.Angles(angles.X, angles.Y, angles.Z)
				part.CFrame = part.CFrame * CFrame.new(pos)
			else
				local angles = getSineVector3() * Vector3.new(0.2, 0.2, 0.2)
				part.CFrame = part.CFrame * CFrame.Angles(angles.X, angles.Y, angles.Z)
			end
		end
		local pitchmod = 0.3*(tree.Trunk.Size.Magnitude/20) + 0.2*(#tree:GetChildren() / 7) 
		print ("pitch mod: " .. pitchmod)
		playSound(tree, treefell_sound, 0.25, 1.3-pitchmod, 1.5)
		local i = 0
		
		--Tree fading function
		local fade = function(step) 
			for _, part in pairs(tree:GetChildren()) do
				if part:IsA("Part") then
					part.Transparency = i
				end
			end
			i = i + 0.009
		end
		
		--Wait a few seconds, then fade and destroy tree
		spawn(function() 
			wait(6) 
			local connection = runservice.Heartbeat:Connect(fade) 
			while i < 1 do 
				wait() 
			end 
			connection:Disconnect()
			tree:Destroy() 
		end)
	end
end

-----------------------------------------------------------------------------
--Sword sweep

--Take a hitbox object and sweep it along a path set by start and end pos and angle, referenced at angles angleframe, over time deltat
function sweepHitParts(hitbox, damage, angleframe, startpos, startangle, endpos, endangle, deltat)
	--Prep
	local damaged_models = {}
	local prim = player.Character.PrimaryPart
	local frames = 0
	local totalframes
	local _,_,_,R00,R01,R02,R10,R11,R12,R20,R21,R22 = angleframe:GetComponents()
	
	--Debug
	if FRAMEDEBUG or HITBOXDEBUG then totalframes = 60 else totalframes = deltat*60 end
	local framedebug_model
	if FRAMEDEBUG then
		framedebug_model = Instance.new("Model")
		framedebug_model.Parent = workspace
		framedebug_model.Name = "CombatFramedebugModel"
	end
	local hitboxdebug_box
	if HITBOXDEBUG then
		hitboxdebug_box = Instance.new("SelectionBox")
		hitboxdebug_box.Name = "HitboxDebugBox"
		hitboxdebug_box.Adornee = hitbox
		hitboxdebug_box.LineThickness = 0.1
		hitboxdebug_box.Transparency = 0.2
		hitboxdebug_box.SurfaceTransparency = 0.7
		hitboxdebug_box.Parent = hitbox
	end
	
	--Execute
	local connection = runservice.Heartbeat:Connect(function(step)
		damaged_models = combineTables(damaged_models, damageItems(hitbox:GetTouchingParts(), damage, damaged_models))

		local referenceframe = CFrame.new(prim.Position.X, prim.Position.Y, prim.Position.Z, 
			R00, R01, R02, R10, R11, R12, R20, R21, R22) --Form a frame at the player's position with the reference angle
		local startframe = referenceframe * CFrame.new(startpos) * CFrame.Angles(0, startangle, 0)
		local goalframe = referenceframe * CFrame.new(endpos) * CFrame.Angles(0, endangle, 0)
		local resultframe = startframe:Lerp(goalframe, frames/totalframes)
		
		if FRAMEDEBUG then
			local newhitbox = hitbox:Clone()
			if hitbox:FindFirstChild("HitboxDebugBox") then
				hitbox.HitboxDebugBox:Destroy()
			end
			newhitbox.Parent = framedebug_model
			newhitbox.CFrame = resultframe --Create new frame at result frame
			hitbox = newhitbox
		else
			hitbox.CFrame = resultframe --Update frame of sword
		end

		frames = frames + 1 --Increment frames in this animation
	end)
	while frames < totalframes do
		wait()
	end
	
	--Cleanup
	connection:Disconnect()
	if FRAMEDEBUG then
		spawn(function()
			wait(2) framedebug_model:Destroy()
		end)
	end
end

local righttoleft = true

function slash(mouse)
	if not slash_onCooldown and not using_ability then
		slash_onCooldown = true
		using_ability = true
		
		local sword = Instance.new("Part")
		sword.Size = Vector3.new(1, 1, 9)
		sword.Parent = player.Character
		sword.Name = "Sword"
		sword.Anchored = true
		sword.CanCollide = false
		sword.Touched:Connect(function() end) --Enable touch transmitter
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshId = sword_mesh
		mesh.Parent = sword
		mesh.Scale = Vector3.new(2, 2, -1.9)
		
		local prim = player.Character.PrimaryPart
		local hit = mouse.Hit
		local hit_onlyxz = Vector3.new(hit.X, prim.Position.Y, hit.Z)
		local angleframe = CFrame.new(prim.Position, hit_onlyxz)
		prim.CFrame = CFrame.new(prim.Position, hit_onlyxz)
		
		local sweepangle = math.pi/5
		
		local startpos, endpos, startangle, endangle
		if righttoleft then
			startpos = Vector3.new(3, 0, -5)
			endpos = Vector3.new(-3, 0, -5)
			startangle = -sweepangle
			endangle = sweepangle
			righttoleft = false
		else
			startpos = Vector3.new(-3, 0, -5)
			endpos = Vector3.new(3, 0, -5)
			startangle = sweepangle
			endangle = -sweepangle		
			righttoleft = true
		end
		
		playSound(prim.Parent, slash_sound, 0.25, 1, 0)
		sweepHitParts(sword, 30, angleframe, startpos, startangle, endpos, endangle, 0.12)
		sword:Destroy()
		
		spawn(function() 
			wait(slash_cdLength)
			slash_onCooldown = false
		end)
		using_ability = false
	end
end

charge_charging = false
charge_chargeconnection = nil
charge_chargingsound = nil
charge_oncooldown = false
charge_cdlength = 1
charge_amount = 0

--While e is held, scale down speed
--Until lowest speed is reached
--Then wait on while loop until E is released

function release()
	if charge_charging then --We are charging
		charge_chargeconnection:Disconnect()
		charge_chargingsound:Destroy()
		charge_charging = false
		local prim = player.Character.PrimaryPart
		prim.Anchored = true
		local startframe = prim.CFrame
		local endframe = startframe * CFrame.new(Vector3.new(0, 0, -40*charge_amount))
			local duration = 0.3
		local frames = 0
		local totalframes = duration * 60

		local sound = createSound(charge_gosound, 0.5, 1, 0.1)
		sound.Parent = player.Character
		sound.Pitch = 0.8 + 0.4*charge_amount
		sound.PlayOnRemove = true
		sound:Destroy()
		
		local connection = runservice.Heartbeat:Connect(function(step)
			local resultframe = startframe:Lerp(endframe, frames/totalframes)
			prim.CFrame = resultframe
			frames = frames + 1
		end)
		
		while frames < totalframes do
			wait()
		end 
		connection:Disconnect()
		prim.Anchored = false
		player.Character.Humanoid.WalkSpeed = 25
		
		using_ability = false
		spawn(function() 
			wait(charge_cdlength)
			charge_oncooldown = false
		end)
	end
end

function charge(mouse)
	if not using_ability and not charge_oncooldown then
		using_ability = true
		charge_charging = true
		charge_oncooldown = true
		charge_amount = 0.4
		
		charge_chargingsound = createSound(charge_sound, 0.4, 0.9)
		charge_chargingsound.Parent = player.Character
		charge_chargingsound:Play()
		playAnim("2921005437")
		
		--Slow down, prepare to charge
		--After 1 second, bodyvelocity forward for a bit
		charge_chargeconnection = runservice.Heartbeat:Connect(function(step)
			charge_amount = charge_amount + 0.01
			charge_amount = math.min(charge_amount, 1)
			player.Character.Humanoid.WalkSpeed = 25 - 23*charge_amount
		end)
	end
end

function playAnim(id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "http://www.roblox.com/asset/?id="..id
	local loaded_anim = player.Character.Humanoid:LoadAnimation(anim)
	loaded_anim:Play()
end
