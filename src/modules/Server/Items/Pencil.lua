--[=[
	@class Pencil
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local PencilConstants = require("PencilConstants")
local AttributeValue = require("AttributeValue")

local Pencil = setmetatable({}, BaseObject)
Pencil.ClassName = "Pencil"
Pencil.__index = Pencil

function Pencil.new(obj, serviceBag)
	local self = setmetatable(BaseObject.new(obj), Pencil)

	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._remoteEvent = Instance.new("RemoteEvent")
	self._remoteEvent.Name = PencilConstants.REMOTE_EVENT_NAME
	self._remoteEvent.Archivable = false
	self._remoteEvent.Parent = self._obj
	self._maid:GiveTask(self._remoteEvent)

	self._isDrawing = AttributeValue.new(self._obj, PencilConstants.IS_DRAWING_ATTRIBUTE, false)
	self._color = AttributeValue.new(self._obj, PencilConstants.COLOR_ATTRIBUTE, PencilConstants.DEFAULT_COLOR)

	self._maid:GiveTask(self._remoteEvent.OnServerEvent:Connect(function(...)
		self:_handleServerEvent(...)
	end))

	return self
end

function Pencil:_handleServerEvent(_player, request, isDrawing)
	if request == PencilConstants.REQUEST_SET_IS_DRAWING then
		assert(type(isDrawing) == "boolean", "Bad isDrawing")
		self._isDrawing.Value = isDrawing
	else
		error("Bad request")
	end
end

return Pencil