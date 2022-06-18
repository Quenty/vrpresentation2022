--[=[
	@class VREnabledHumanoidUtils
]=]

local require = require(script.Parent.loader).load(script)

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local CollectionServiceUtils = require("CollectionServiceUtils")
local Draw = require("Draw")
local AdorneeUtils = require("AdorneeUtils")

local VREnabledHumanoidUtils = {}

local GRIP_RADIUS_STUDS = 5

function VREnabledHumanoidUtils.getGripAttachmentName(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	return ("VREnabledHumanoid_IK%sGripAttachment"):format(sideName)
end

function VREnabledHumanoidUtils.getHoldingValueName(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	return ("VREnabledHumanoid_%sHolding"):format(sideName)
end

function VREnabledHumanoidUtils.findHoldable(position, debugMaid)
	local partsAvailable = Workspace:GetPartBoundsInRadius(position, GRIP_RADIUS_STUDS)

	if debugMaid then
		debugMaid._render = Draw.sphere(position, GRIP_RADIUS_STUDS)
	end

	local options = {}
	for _, item in pairs(partsAvailable) do
		local holdable = CollectionServiceUtils.findFirstAncestor("VRHoldable", item)
		if not holdable then
			if CollectionService:HasTag(item, "VRHoldable") then
				holdable = item
			end
		end

		if holdable then
			local center = AdorneeUtils.getCenter(item)
			if center then
				options[item] = (position - center).magnitude
			end
		end
	end

	local closest = nil
	local bestDist = math.huge
	for adornee, dist in pairs(options) do
		if dist < bestDist then
			bestDist = dist
			closest = adornee
		end
	end

	return closest
end

return VREnabledHumanoidUtils