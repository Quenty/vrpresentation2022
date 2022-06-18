--[=[
	@class VREnabledHumanoidClient
]=]

local require = require(script.Parent.loader).load(script)

local Players = game:GetService("Players")

local BaseObject = require("BaseObject")
local CharacterUtils = require("CharacterUtils")
local VRHandControls = require("VRHandControls")
local VREnabledHumanoidConstants = require("VREnabledHumanoidConstants")
local VREnabledHumanoidUtils = require("VREnabledHumanoidUtils")
local ThrottledFunction = require("ThrottledFunction")
local RxValueBaseUtils = require("RxValueBaseUtils")
local ValueBaseUtils = require("ValueBaseUtils")
local VRBinderGroupsClient = require("VRBinderGroupsClient")

local VREnabledHumanoidClient = setmetatable({}, BaseObject)
VREnabledHumanoidClient.ClassName = "VREnabledHumanoidClient"
VREnabledHumanoidClient.__index = VREnabledHumanoidClient

require("PromiseRemoteEventMixin"):Add(VREnabledHumanoidClient, VREnabledHumanoidConstants.REMOTE_EVENT_NAME)

function VREnabledHumanoidClient.new(humanoid, serviceBag)
	local self = setmetatable(BaseObject.new(humanoid), VREnabledHumanoidClient)

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._vrBinderGroupsClient = self._serviceBag:GetService(VRBinderGroupsClient)

	if self:_getPlayer() == Players.LocalPlayer then
		self:_setupLocal()
	end

	return self
end

function VREnabledHumanoidClient:RequestHold(sideName)
	self:PromiseRemoteEvent():Then(function(remoteEvent)
		remoteEvent:FireServer(VREnabledHumanoidConstants.REQUEST_GRIP, sideName)
	end)
end

function VREnabledHumanoidClient:RequestDrop(sideName)
	self:PromiseRemoteEvent():Then(function(remoteEvent)
		remoteEvent:FireServer(VREnabledHumanoidConstants.REQUEST_DROP, sideName)
	end)
end

function VREnabledHumanoidClient:SetGripCFrame(sideName, worldCFrame)
	assert(self:_getPlayer() == Players.LocalPlayer, "Cannot set grip for non-local player")
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	local gripAttachment = self:_getGripAttachment(sideName)
	if not gripAttachment then
		warn("No gripAttachment")
		return
	end

	gripAttachment.WorldCFrame = worldCFrame

	local cframe = gripAttachment.CFrame
	if sideName == "Left" then
		self._throttleLeftReplicate:Call(cframe)
	elseif sideName == "Right" then
		self._throttleRightReplicate:Call(cframe)
	else
		error("Bad sideName")
	end
end

function VREnabledHumanoidClient:_getGripAttachment(sideName)
	local rootPart = self._obj.RootPart
	if not rootPart then
		return nil
	end

	local attachmentName = VREnabledHumanoidUtils.getGripAttachmentName(sideName)
	local attachment = rootPart:FindFirstChild(attachmentName)

	return attachment
end

function VREnabledHumanoidClient:GetHoldingAdornee(sideName)
	return ValueBaseUtils.getValue(self._obj, "ObjectValue", VREnabledHumanoidUtils.getHoldingValueName(sideName))
end

function VREnabledHumanoidClient:ObserveHoldingAdorneeBrio(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	return RxValueBaseUtils.observeBrio(self._obj, "ObjectValue", VREnabledHumanoidUtils.getHoldingValueName(sideName))
end

function VREnabledHumanoidClient:_setupLocal()
	self._throttleLeftReplicate = ThrottledFunction.new(0.1, function(cframe)
		self:PromiseRemoteEvent():Then(function(remoteEvent)
			remoteEvent:FireServer(VREnabledHumanoidConstants.REQUEST_SET_GRIP_CFRAME, "Left", cframe)
		end)
	end, {
		leading = true;
		trailing = true;
	})
	self._maid:GiveTask(self._throttleLeftReplicate)

	self._throttleRightReplicate = ThrottledFunction.new(0.1, function(cframe)
		self:PromiseRemoteEvent():Then(function(remoteEvent)
			remoteEvent:FireServer(VREnabledHumanoidConstants.REQUEST_SET_GRIP_CFRAME, "Right", cframe)
		end)
	end, {
		leading = true;
		trailing = true;
	})
	self._maid:GiveTask(self._throttleRightReplicate)

	self._controls = VRHandControls.new(self._serviceBag, self)
	self._maid:GiveTask(self._controls)

	self._maid:GiveTask(self:ObserveHoldingAdorneeBrio("Right"):Subscribe(function(brio)
		self:_handleHoldingActivation(brio)
	end))

	self._maid:GiveTask(self:ObserveHoldingAdorneeBrio("Left"):Subscribe(function(brio)
		self:_handleHoldingActivation(brio)
	end))
end

function VREnabledHumanoidClient:_getPlayer()
	return CharacterUtils.getPlayerFromCharacter(self._obj)
end


function VREnabledHumanoidClient:_handleHoldingActivation(brio)
	if brio:IsDead() then
		return
	end

	local maid = brio:ToMaid()
	local adornee = brio:GetValue()

	print("adornee", adornee)

	if adornee then
		for _, binder in pairs(self._vrBinderGroupsClient.VRHoldable:GetBinders()) do
			local value = binder:Get(adornee)
			if value then
				print("Calling")
				value:OnVRHandHold(maid)
			end
		end
	end
end

return VREnabledHumanoidClient