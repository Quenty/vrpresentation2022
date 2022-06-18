--[=[
	@class PencilClient
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local DrawingRenderer = require("DrawingRenderer")
local RxAttributeUtils = require("RxAttributeUtils")
local PencilConstants = require("PencilConstants")
local AttributeValue = require("AttributeValue")
local Queue = require("Queue")
local PencilControl = require("PencilControl")

local PencilClient = setmetatable({}, BaseObject)
PencilClient.ClassName = "PencilClient"
PencilClient.__index = PencilClient

require("PromiseRemoteEventMixin"):Add(PencilClient, PencilConstants.REMOTE_EVENT_NAME)

function PencilClient.new(obj, serviceBag)
	local self = setmetatable(BaseObject.new(obj), PencilClient)

	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._drawParts = Queue.new()
	self._isDrawing = AttributeValue.new(self._obj, PencilConstants.IS_DRAWING_ATTRIBUTE, false)

	self._maid:GiveTask(self._isDrawing:Observe():Subscribe(function(isDrawing)
		if isDrawing then
			self._maid._drawingRenderer = DrawingRenderer.new(self._serviceBag, self)
		else
			self._maid._drawingRenderer = nil
		end
	end))


	return self
end

function PencilClient:OnVRHandHold(maid)
	self:EnableControl()

	maid:GiveTask(function()
		self:DisableControl()
	end)
end

function PencilClient:EnableControl()
	if not self._maid._control then
		self._maid._control = PencilControl.new(self._serviceBag, self)
	end
end

function PencilClient:DisableControl()
	self._maid._control = nil
end

function PencilClient:GiveDrawPart(drawPart)
	self._drawParts:PushRight(drawPart)

	while self._drawParts:GetCount() > PencilConstants.MAX_PARTS_COUNT do
		local removed = self._drawParts:PopLeft()
		removed:Destroy()
	end
end

function PencilClient:GetPosition()
	return self._obj.CFrame:pointToWorldSpace(self._obj.Size * Vector3.new(0, 0, 0.5))
end

function PencilClient:RequestStopDrawing()
	self._isDrawing.Value = false

	self:PromiseRemoteEvent():Then(function(remoteEvent)
		remoteEvent:FireServer(PencilConstants.REQUEST_SET_IS_DRAWING, false)
	end)
end

function PencilClient:RequestStartDrawing()
	self._isDrawing.Value = true

	self:PromiseRemoteEvent():Then(function(remoteEvent)
		remoteEvent:FireServer(PencilConstants.REQUEST_SET_IS_DRAWING, true)
	end)
end

function PencilClient:ObserveColor()
	return RxAttributeUtils.observeValue(self._obj, PencilConstants.COLOR_ATTRIBUTE, PencilConstants.DEFAULT_COLOR)
end

function PencilClient:GetColor()
	local attribute = self._obj:GetAttribute(PencilConstants.COLOR_ATTRIBUTE)
	if not attribute then
		return PencilConstants.DEFAULT_COLOR
	else
		return attribute
	end
end

return PencilClient