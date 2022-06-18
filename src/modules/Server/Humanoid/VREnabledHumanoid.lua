--[=[
	@class VREnabledHumanoid
]=]

local require = require(script.Parent.loader).load(script)

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local AdorneeUtils = require("AdorneeUtils")
local BaseObject = require("BaseObject")
local CharacterUtils = require("CharacterUtils")
local CollectionServiceUtils = require("CollectionServiceUtils")
local Draw = require("Draw")
local IKBindersServer = require("IKBindersServer")
local IKGripUtils = require("IKGripUtils")
local Maid = require("Maid")
local NetworkOwnerService = require("NetworkOwnerService")
local NetworkRopeUtils = require("NetworkRopeUtils")
local RootPartUtils = require("RootPartUtils")
local VREnabledHumanoidConstants = require("VREnabledHumanoidConstants")
local VREnabledHumanoidUtils = require("VREnabledHumanoidUtils")

local GRIP_RADIUS_STUDS = 10

local VREnabledHumanoid = setmetatable({}, BaseObject)
VREnabledHumanoid.ClassName = "VREnabledHumanoid"
VREnabledHumanoid.__index = VREnabledHumanoid

function VREnabledHumanoid.new(humanoid, serviceBag)
	local self = setmetatable(BaseObject.new(humanoid), VREnabledHumanoid)

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._ikBindersServer = self._serviceBag:GetService(IKBindersServer)
	self._networkOwnerService = self._serviceBag:GetService(NetworkOwnerService)

	self._remoteEvent = Instance.new("RemoteEvent")
	self._remoteEvent.Name = VREnabledHumanoidConstants.REMOTE_EVENT_NAME
	self._remoteEvent.Archivable = false
	self._remoteEvent.Parent = self._obj
	self._maid:GiveTask(self._remoteEvent)

	self._maid:GiveTask(self._remoteEvent.OnServerEvent:Connect(function(...)
		self:_handleServerEvent(...)
	end))

	self._leftGripAttachment = Instance.new("Attachment")
	self._leftGripAttachment.Name = VREnabledHumanoidUtils.getGripAttachmentName("Left")
	self._maid:GiveTask(self._leftGripAttachment)

	self._rightGripAttachment = Instance.new("Attachment")
	self._rightGripAttachment.Name = VREnabledHumanoidUtils.getGripAttachmentName("Right")
	self._maid:GiveTask(self._rightGripAttachment)

	self._leftGrip = IKGripUtils.create(self._ikBindersServer.IKLeftGrip, humanoid)
	self._maid:GiveTask(self._leftGrip)

	self._rightGrip = IKGripUtils.create(self._ikBindersServer.IKRightGrip, humanoid)
	self._maid:GiveTask(self._rightGrip)

	self._maid:GivePromise(RootPartUtils.promiseRootPart(self._obj)):Then(function(rootPart)
		self._leftGripAttachment.Parent = rootPart
		self._rightGripAttachment.Parent = rootPart
	end)

	self._leftHolding = Instance.new("ObjectValue")
	self._leftHolding.Name = VREnabledHumanoidUtils.getHoldingValueName("Left")
	self._leftHolding.Value = nil
	self._leftHolding.Parent = self._obj
	self._maid:GiveTask(self._leftHolding)

	self._rightHolding = Instance.new("ObjectValue")
	self._rightHolding.Name = VREnabledHumanoidUtils.getHoldingValueName("Right")
	self._rightHolding.Value = nil
	self._rightHolding.Parent = self._obj
	self._maid:GiveTask(self._rightHolding)

	self._maid:GiveTask(self:_setupHoldingValue(self._leftHolding, self._leftGripAttachment))
	self._maid:GiveTask(self:_setupHoldingValue(self._rightHolding, self._rightGripAttachment))

	return self
end

function VREnabledHumanoid:_getPlayer()
	return CharacterUtils.getPlayerFromCharacter(self._obj)
end

function VREnabledHumanoid:_setupHoldingValue(holdingValue, holdingAttachment)
	local topMaid = Maid.new()

	topMaid:GiveTask(holdingValue.Changed:Connect(function(adornee)
		topMaid._current = nil

		if not adornee then
			return
		end

		local part = AdorneeUtils.getPart(adornee)
		if not part then
			warn("No part")
			return
		end

		local maid = Maid.new()

		local parts = AdorneeUtils.getParts(adornee)

		-- todo: could also create can collision constraint between all parts
		local couldCollide = {}
		for _, item in pairs(parts) do
			couldCollide[item] = item.CanCollide
			item.CanCollide = false
		end

		maid:GiveTask(function()
			for _, item in pairs(parts) do
				item.CanCollide = couldCollide[part]
			end
		end)

		-- hackily hint ownership
		maid:GiveTask(NetworkRopeUtils.hintSharedMechanism(self._obj.RootPart, part))

		local player = self:_getPlayer()
		if player then
			maid:GiveTask(self._networkOwnerService:AddSetNetworkOwnerHandle(part, player))
		end

		local attachment = Instance.new("Attachment")
		attachment.Name = "PartHoldingAttachment"
		attachment.CFrame = CFrame.Angles(math.pi, 0, 0)
		attachment.Archivable = false
		attachment.Parent = part
		maid:GiveTask(attachment)

		local alignPosition = Instance.new("AlignPosition")
		alignPosition.Name = "HoldingAlignPosition"
		alignPosition.Responsiveness = 100
		alignPosition.Attachment0 = attachment
		alignPosition.Attachment1 = holdingAttachment
		alignPosition.Parent = attachment
		maid:GiveTask(alignPosition)

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "HoldingAlignOrientation"
		alignOrientation.Responsiveness = 100
		alignOrientation.Attachment0 = attachment
		alignOrientation.Attachment1 = holdingAttachment
		alignOrientation.Parent = attachment
		maid:GiveTask(alignOrientation)

		topMaid._current = maid
	end))

	return topMaid
end
function VREnabledHumanoid:_handleServerEvent(player, request, ...)
	assert(self:_getPlayer() == player, "Bad player")

	if request == VREnabledHumanoidConstants.REQUEST_SET_GRIP_CFRAME then
		self:_setGripCFrame(...)
	elseif request == VREnabledHumanoidConstants.REQUEST_GRIP then
		self:_handleGrip(...)
	elseif request == VREnabledHumanoidConstants.REQUEST_DROP then
		self:_handleDrop(...)
	else
		error(("Bad request %q"):format(tostring(request)))
	end
end

function VREnabledHumanoid:_getGripAttachment(sideName)
	local rootPart = self._obj.RootPart
	if not rootPart then
		return nil
	end

	local attachmentName = VREnabledHumanoidUtils.getGripAttachmentName(sideName)
	local attachment = rootPart:FindFirstChild(attachmentName)

	return attachment
end

function VREnabledHumanoid:_handleDrop(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	local gripAttachment = self:_getGripAttachment(sideName)
	if not gripAttachment then
		return
	end

	if sideName == "Left" then
		self._leftHolding.Value = nil
	elseif sideName == "Right" then
		self._rightHolding.Value = nil
	else
		error("Bad sideName")
	end
end

function VREnabledHumanoid:_handleGrip(sideName)
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	local gripAttachment = self:_getGripAttachment(sideName)
	if not gripAttachment then
		warn("No gripAttachment for ", sideName)
		return
	end

	local partsAvailable = Workspace:GetPartBoundsInRadius(gripAttachment.WorldPosition, GRIP_RADIUS_STUDS)
	-- self._maid._render = Draw.sphere(gripAttachment.WorldPosition, GRIP_RADIUS_STUDS)

	for _, item in pairs(partsAvailable) do
		local holdable = CollectionServiceUtils.findFirstAncestor("VRHoldable", item)
		if not holdable then
			if CollectionService:HasTag(item, "VRHoldable") then
				holdable = item
			end
		end

		if holdable then
			-- print("Holding holdable", holdable)
			if sideName == "Left" then
				self._leftHolding.Value = holdable
			elseif sideName == "Right" then
				self._rightHolding.Value = holdable
			else
				error("Bad sideName")
			end
			break
		end
	end
end

function VREnabledHumanoid:_setGripCFrame(sideName, relCFrame)
	assert(typeof(relCFrame) == "CFrame" or relCFrame == nil, "Bad CFrame")
	assert(sideName == "Left" or sideName == "Right", "Bad sideName")

	if sideName == "Left" then
		if relCFrame  then
			self._leftGripAttachment.CFrame = relCFrame
			self._leftGrip.Parent = self._leftGripAttachment
		else
			self._leftGrip.Parent = nil
		end
	elseif sideName == "Right" then
		if relCFrame  then
			self._rightGripAttachment.CFrame = relCFrame
			self._rightGrip.Parent = self._rightGripAttachment
		else
			self._rightGrip.Parent = nil
		end
	else
		error("Bad sideName")
	end
end

return VREnabledHumanoid