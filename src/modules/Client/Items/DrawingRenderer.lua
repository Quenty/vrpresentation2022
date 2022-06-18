--[=[
	@class DrawingRenderer
]=]

local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local Draw = require("Draw")

local DrawingRenderer = setmetatable({}, BaseObject)
DrawingRenderer.ClassName = "DrawingRenderer"
DrawingRenderer.__index = DrawingRenderer

function DrawingRenderer.new(serviceBag, pencilClient)
	local self = setmetatable(BaseObject.new(), DrawingRenderer)

	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._pencilClient = assert(pencilClient, "Bad pencilClient")

	self:_drawUpdate()

	self._maid:GiveTask(RunService.Stepped:Connect(function()
		self:_drawUpdate()
	end))

	self._maid:GiveTask(function()
		self:_drawUpdate(true)
	end)

	return self
end

function DrawingRenderer:_drawUpdate(forceFinalize)
	local position = self._pencilClient:GetPosition()
	if self._lastPosition then
		local offset = position - self._lastPosition
		if offset.magnitude <= 0.05 and not forceFinalize then
			return
		end

		local vector = Draw.vector(self._lastPosition, offset, self._pencilClient:GetColor())
		vector.Transparency = 1
		self._pencilClient:GiveDrawPart(vector)

		self._lastPosition = position
	else
		self._lastPosition = position
	end
end

return DrawingRenderer