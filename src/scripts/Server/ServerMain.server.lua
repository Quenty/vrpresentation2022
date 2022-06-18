--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService:FindFirstChild("LoaderUtils", true).Parent
local packages = require(loader).bootstrapGame(ServerScriptService.vrpresentation)

local serviceBag = require(packages.ServiceBag).new()

serviceBag:GetService(packages.VRPresentationService)

serviceBag:Init()
serviceBag:Start()