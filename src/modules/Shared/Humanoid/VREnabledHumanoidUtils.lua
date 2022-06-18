--[=[
	@class VREnabledHumanoidUtils
]=]

local require = require(script.Parent.loader).load(script)

local VREnabledHumanoidUtils = {}

function VREnabledHumanoidUtils.getGripAttachmentName(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	return ("VREnabledHumanoid_IK%sGripAttachment"):format(sideName)
end

function VREnabledHumanoidUtils.getHoldingValueName(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	return ("VREnabledHumanoid_%sHolding"):format(sideName)
end

return VREnabledHumanoidUtils