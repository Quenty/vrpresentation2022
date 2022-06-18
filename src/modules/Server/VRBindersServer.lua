--[=[
	@class VRBindersServer
]=]

local require = require(script.Parent.loader).load(script)

local BinderProvider = require("BinderProvider")
local PlayerHumanoidBinder = require("PlayerHumanoidBinder")
local Binder = require("Binder")

return BinderProvider.new(function(self, serviceBag)
	self:Add(PlayerHumanoidBinder.new("VREnabledHumanoid", require("VREnabledHumanoid"), serviceBag))
	self:Add(Binder.new("Pencil", require("Pencil"), serviceBag))
end)