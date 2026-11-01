-- ============================================================
-- Character Changer — Fixed for R6 and R15 Local Players
-- ============================================================

local Id = 7808058034

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local R6_BODY_PARTS = {
	["Head"] = true, ["Torso"] = true,
	["Left Arm"] = true, ["Right Arm"] = true,
	["Left Leg"] = true, ["Right Leg"] = true,
}

local R15_BODY_PARTS = {
	["Head"] = true, 
	["UpperTorso"] = true, ["LowerTorso"] = true,
	["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true,
	["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true,
	["LeftUpperLeg"] = true, ["LeftLowerLeg"] = true, ["LeftFoot"] = true,
	["RightUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true,
}

local R15_TO_R6 = {
	Head = "Head",
	UpperTorso = "Torso", LowerTorso = "Torso",
	LeftUpperArm = "Left Arm", LeftLowerArm = "Left Arm", LeftHand = "Left Arm",
	RightUpperArm = "Right Arm", RightLowerArm = "Right Arm", RightHand = "Right Arm",
	LeftUpperLeg = "Left Leg", LeftLowerLeg = "Left Leg", LeftFoot = "Left Leg",
	RightUpperLeg = "Right Leg", RightLowerLeg = "Right Leg", RightFoot = "Right Leg",
}

local function clear_current_appearance(character)
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Accessory")
		or item:IsA("Hat")
		or item:IsA("Shirt")
		or item:IsA("Pants")
		or item:IsA("ShirtGraphic")
		or item:IsA("CharacterMesh")
		or item:IsA("BodyColors") then
			item:Destroy()
		end
	end
end

local function transfer_clothing(character, source, userId)
	local got_shirt, got_pants, got_tshirt = false, false, false

	for _, item in ipairs(source:GetChildren()) do
		if item:IsA("Shirt") then
			item:Clone().Parent = character
			got_shirt = true
		elseif item:IsA("Pants") then
			item:Clone().Parent = character
			got_pants = true
		elseif item:IsA("ShirtGraphic") then
			item:Clone().Parent = character
			got_tshirt = true
		elseif item:IsA("CharacterMesh") then
			item:Clone().Parent = character
		end
	end

	if not (got_shirt and got_pants and got_tshirt) then
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(tonumber(userId) or userId)
		end)
		if ok and desc then
			if not got_shirt and desc.Shirt and desc.Shirt ~= 0 then
				local s = Instance.new("Shirt")
				s.ShirtTemplate = "rbxassetid://" .. desc.Shirt
				s.Parent = character
			end
			if not got_pants and desc.Pants and desc.Pants ~= 0 then
				local p = Instance.new("Pants")
				p.PantsTemplate = "rbxassetid://" .. desc.Pants
				p.Parent = character
			end
			if not got_tshirt and desc.GraphicTShirt and desc.GraphicTShirt ~= 0 then
				local t = Instance.new("ShirtGraphic")
				t.Graphic = "rbxassetid://" .. desc.GraphicTShirt
				t.Parent = character
			end
		end
	end
end

-- Properly welds accessories on the client using Roblox's Attachment system
local function attach_accessory_client(character, accessory, isTargetR15)
	local handle = accessory:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return end

	-- Destroy broken old welds pointing to the deleted source model
	for _, c in ipairs(handle:GetChildren()) do
		if c:IsA("JointInstance") or c:IsA("WeldConstraint") then
			c:Destroy()
		end
	end

	handle.CanCollide = false
	handle.Massless = true

	-- Look for an Attachment inside the accessory's Handle (Standard for R15 & R6)
	local accAttachment = handle:FindFirstChildOfClass("Attachment")
	local charAttachment = nil

	if accAttachment then
		-- Find the matching attachment name inside the character's body parts
		for _, desc in ipairs(character:GetDescendants()) do
			if desc:IsA("Attachment") and desc.Name == accAttachment.Name and not desc:IsDescendantOf(accessory) then
				charAttachment = desc
				break
			end
		end
	end

	accessory.Parent = character

	if accAttachment and charAttachment then
		local targetPart = charAttachment.Parent
		handle.CFrame = targetPart.CFrame * charAttachment.CFrame * accAttachment.CFrame:Inverse()

		local weld = Instance.new("Weld")
		weld.Name = "AccessoryWeld"
		weld.Part0 = handle
		weld.Part1 = targetPart
		weld.C0 = accAttachment.CFrame
		weld.C1 = charAttachment.CFrame
		weld.Parent = handle
	else
		-- Fallback for legacy hats without attachments
		local head = character:FindFirstChild("Head")
		if head then
			local attachmentPos = accessory:IsA("Accoutrement") and accessory.AttachmentPoint or CFrame.new()
			handle.CFrame = head.CFrame * CFrame.new(0, 0.5, 0) * attachmentPos:Inverse()

			local weld = Instance.new("Weld")
			weld.Name = "AccessoryWeld"
			weld.Part0 = head
			weld.Part1 = handle
			weld.C0 = CFrame.new(0, 0.5, 0)
			weld.C1 = attachmentPos
			weld.Parent = handle
		end
	end
end

local function transfer_accessories(character, source, isTargetR15)
	for _, item in ipairs(source:GetChildren()) do
		if item:IsA("Accessory") or item:IsA("Hat") then
			local clone = item:Clone()
			attach_accessory_client(character, clone, isTargetR15)
		end
	end
end

local function transfer_body_colors(character, source, isTargetR15)
	-- 1. Clone the actual BodyColors instance so Roblox doesn't override individual limb colors
	local srcBodyColors = source:FindFirstChildOfClass("BodyColors")
	if srcBodyColors then
		srcBodyColors:Clone().Parent = character
	end

	-- 2. Apply exact per-limb colors (supports both R6 and R15 without overwriting everything with HeadColor)
	local targetParts = isTargetR15 and R15_BODY_PARTS or R6_BODY_PARTS
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and targetParts[part.Name] then
			local srcPart = source:FindFirstChild(part.Name)
			if not srcPart and not isTargetR15 then
				-- If target is R6 and source is R15, map R6 limb to R15 equivalent
				for r15Name, r6Name in pairs(R15_TO_R6) do
					if r6Name == part.Name and source:FindFirstChild(r15Name) then
						srcPart = source:FindFirstChild(r15Name)
						break
					end
				end
			elseif not srcPart and isTargetR15 then
				-- If target is R15 and source is R6
				local r6Name = R15_TO_R6[part.Name]
				if r6Name then srcPart = source:FindFirstChild(r6Name) end
			end

			if srcPart and srcPart:IsA("BasePart") then
				part.Color = srcPart.Color
			end
		end
	end
end

local function transfer_face(character, source)
	local head = character:FindFirstChild("Head")
	local srcHead = source:FindFirstChild("Head")
	if not (head and srcHead) then return end

	-- Only look for the actual face decal on the source head, not random textures
	local srcFace = srcHead:FindFirstChild("face") or srcHead:FindFirstChild("Face")

	-- Clear existing face decals on the player's head
	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("Decal") and (child.Name:lower() == "face") then
			child:Destroy()
		end
	end

	if srcFace and srcFace:IsA("Decal") then
		local d = srcFace:Clone()
		d.Name = "face"
		d.Face = Enum.NormalId.Front
		d.Parent = head
	end
end

local function apply(id)
	local character = LocalPlayer.Character
	if not character then warn("[CharacterChanger] no character"); return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	local isTargetR15 = (humanoid.RigType == Enum.HumanoidRigType.R15)

	local ok, err = pcall(function()
		-- Generate the source model matching the player's actual RigType!
		local desc = Players:GetHumanoidDescriptionFromUserId(tonumber(id) or id)
		local source = Players:CreateHumanoidModelFromDescription(desc, humanoid.RigType)

		clear_current_appearance(character)
		transfer_body_colors(character, source, isTargetR15)
		transfer_face(character, source)
		transfer_clothing(character, source, id)
		transfer_accessories(character, source, isTargetR15)

		source:Destroy()
		print("[CharacterChanger] Applied appearance successfully for rig type:", isTargetR15 and "R15" or "R6")
	end)

	if not ok then warn("[CharacterChanger]", err) end
end

apply(Id)

LocalPlayer.CharacterAdded:Connect(function(newChar)
	newChar:WaitForChild("Humanoid", 5)
	task.wait(0.5)
	apply(Id)
end)
