--[=[
	@class PencilConstants
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({
	REMOTE_EVENT_NAME = "PencilRemoteEvent";
	IS_DRAWING_ATTRIBUTE = "IsDrawing";
	COLOR_ATTRIBUTE = "PencilColor";
	DEFAULT_COLOR = Color3.new(1, 0, 0);
	MAX_PARTS_COUNT = 500;
	REQUEST_SET_IS_DRAWING = "requestSetIsDrawing";
})