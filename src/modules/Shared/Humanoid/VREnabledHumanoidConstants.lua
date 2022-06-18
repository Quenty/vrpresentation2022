--[=[
	@class VREnabledHumanoidConstants
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({
	REMOTE_EVENT_NAME = "VREnabledHumanoidRemoteEvent";
	REQUEST_SET_GRIP_CFRAME = "requestSetGripCFrame";
	REQUEST_GRIP = "requestGrip";
	REQUEST_DROP = "requestDrop";
})