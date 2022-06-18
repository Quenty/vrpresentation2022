--[=[
	@class VRPresentationService
]=]

local require = require(script.Parent.loader).load(script)

local VRPresentationService = {}

function VRPresentationService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("IKService"))
	self._serviceBag:GetService(require("NetworkOwnerService"))
	self._serviceBag:GetService(require("HideBindersServer"))

	-- Internal
	self._serviceBag:GetService(require("VRBindersServer"))
end

return VRPresentationService