-- ============================================================
-- Character Changer — Fixed for R6 and R15 Local Players
-- Usage:
-- getgenv().ID = 7808058034
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/d11oO/cloth-changer-universal/refs/heads/main/main.luau"))()
-- ============================================================

local env = (getgenv and getgenv()) or _G

local function getTargetId()
	return tonumber(env.ID or env.Id or _G.ID) or 7808058034
end

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
