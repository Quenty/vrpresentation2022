--[=[
	@class PencilControl
]=]

local require = require(script.Parent.loader).load(script)

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local BaseObject = require("BaseObject")

local PencilControl = setmetatable({}, BaseObject)
PencilControl.ClassName = "PencilControl"
PencilControl.__index = PencilControl

function PencilControl.new(serviceBag, pencilClient)
	local self = setmetatable(BaseObject.new(), PencilControl)

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._pencilClient = assert(pencilClient, "No pencilClient")

	self._key = "Pencil_" .. HttpService:GenerateGUID(false)

	ContextActionService:BindAction(self._key, function(_, userInputState, _inputObject)
		if userInputState == Enum.UserInputState.Begin then
			self._pencilClient:RequestStartDrawing()
		elseif userInputState == Enum.UserInputState.End then
			self._pencilClient:RequestStopDrawing()
		end
	end, false, Enum.KeyCode.ButtonR2, Enum.KeyCode.E)

	self._maid:GiveTask(function()
		ContextActionService:UnbindAction(self._key)
		self._pencilClient:RequestStopDrawing()
	end)

	return self
end

return PencilControl