--[=[
	@class VRHandControls
]=]

local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")
local VRService = game:GetService("VRService")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local BaseObject = require("BaseObject")
local IKServiceClient = require("IKServiceClient")

local VRHandControls = setmetatable({}, BaseObject)
VRHandControls.ClassName = "VRHandControls"
VRHandControls.__index = VRHandControls

function VRHandControls.new(serviceBag, vrEnabledHumanoidClient)
	local self = setmetatable(BaseObject.new(), VRHandControls)

	self._serviceBag = assert(serviceBag, "No serviceBag")
	self._ikServiceClient = self._serviceBag:GetService(IKServiceClient)

	self._key = "VRHandControls_" .. HttpService:GenerateGUID(false)
	self._vrEnabledHumanoidClient = assert(vrEnabledHumanoidClient, "No vrEnabledHumanoidClient")

	self:_setupGripLoop("Left", Enum.UserCFrame.LeftHand)
	self:_setupGripLoop("Right", Enum.UserCFrame.RightHand)

	self:_bindInput()

	return self
end

function VRHandControls:_setupGripLoop(sideName, sideUserCFrame)
	if not VRService:GetUserCFrameEnabled(sideUserCFrame) then
		return
	end

	self._maid:GiveTask(RunService.Stepped:Connect(function()
		self:_updateGripStepped(sideName, sideUserCFrame)
	end))
end

function VRHandControls:_updateGripStepped(sideName, sideUserCFrame)
	local handCFrame = VRService:GetUserCFrame(sideUserCFrame)
	local camera = Workspace.CurrentCamera

	-- Need to compute relative to head scale and position
	handCFrame = handCFrame.Rotation + handCFrame.Position*camera.HeadScale
	handCFrame = handCFrame * CFrame.Angles(math.pi/2, 0, 0) -- Y axis back

	local cframe = camera.CFrame:toWorldSpace(handCFrame)

	self._vrEnabledHumanoidClient:SetGripCFrame(sideName, cframe)

	-- self._maid[sideName .. "debug"] = Draw.cframe(cframe)
end

function VRHandControls:_bindInput()
	ContextActionService:BindAction(self._key .. "Hold", function(_, userInputState, _inputObject)
		if userInputState == Enum.UserInputState.Begin then
			if self._vrEnabledHumanoidClient:GetHoldingAdornee("Right") then
				self._vrEnabledHumanoidClient:RequestDrop("Right")
			else
				self._vrEnabledHumanoidClient:RequestHold("Right")
			end
		end
	end, false, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.E)

	self._maid:GiveTask(function()
		ContextActionService:UnbindAction(self._key .. "Hold")
	end)
end

return VRHandControls