--[=[
	@class VRBinderGroupsClient
]=]

local require = require(script.Parent.loader).load(script)

local BinderGroup = require("BinderGroup")
local VRBindersClient = require("VRBindersClient")
local t = require("t")

return require("BinderGroupProvider").new(function(self, serviceBag)
	local vrBindersClient = serviceBag:GetService(VRBindersClient)

	self:Add("VRHoldable", BinderGroup.new(
		{
			vrBindersClient.Pencil;
		},
		t.interface({
			OnVRHandHold = t.callback; -- (maid)
		})
	))
end)