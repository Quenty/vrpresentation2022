--[=[
	@class VRPresentationServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local VRPresentationServiceClient = {}

function VRPresentationServiceClient:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("IKServiceClient"))
	self._serviceBag:GetService(require("FirstPersonCharacterTransparencyServiceClient"))
	self._serviceBag:GetService(require("HideBindersClient"))

	-- Internal
	self._serviceBag:GetService(require("VRBindersClient"))
	self._serviceBag:GetService(require("VRBinderGroupsClient"))

	-- Configure
	self._serviceBag:GetService(require("FirstPersonCharacterTransparencyServiceClient")):SetShowArms(true)
end

return VRPresentationServiceClient