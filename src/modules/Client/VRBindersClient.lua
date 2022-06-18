--[=[
	@class VRBindersClient
]=]

local require = require(script.Parent.loader).load(script)

local BinderProvider = require("BinderProvider")
local Binder = require("Binder")

return BinderProvider.new(function(self, serviceBag)
	self:Add(Binder.new("VREnabledHumanoid", require("VREnabledHumanoidClient"), serviceBag))
	self:Add(Binder.new("Pencil", require("PencilClient"), serviceBag))
end)