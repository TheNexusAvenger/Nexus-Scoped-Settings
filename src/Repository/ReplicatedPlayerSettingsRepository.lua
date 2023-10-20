--[[
TheNexusAvenger

Settings repository that includes client -> server replication.
--]]
--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BasicSettingsRepository = require(script.Parent:WaitForChild("BasicSettingsRepository"))
local PlatformScope = require(script.Parent.Parent:WaitForChild("Scope"):WaitForChild("PlatformScope"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

local ReplicatedPlayerSettingsRepository = {}
ReplicatedPlayerSettingsRepository.__index = ReplicatedPlayerSettingsRepository

export type ReplicatedPlayerSettingsRepository = {
    Validators: {[string]: (Value: any?) -> ()},
    SettingsRepository: BasicSettingsRepository.BasicSettingsRepository<Player>,
    new: (Name: string, CreateSettingsFunction: (Key: Player, ServerData: {[string]: any}?) -> (Types.ScopedSettings)) -> (ReplicatedPlayerSettingsRepository),
    SetValidator: (self: ReplicatedPlayerSettingsRepository, Key: string, Validator: (any?) -> () | {any?}) -> (),
    LoadOnPlayerJoin: (self: ReplicatedPlayerSettingsRepository) -> (ReplicatedPlayerSettingsRepository),
    ClearOnPlayerLeaving: (self: ReplicatedPlayerSettingsRepository) -> (ReplicatedPlayerSettingsRepository),
} & Types.SettingsRepository<Player>



--[[
Creates a replicated player settings repository.
The CreateSettingsFunction function is meant to return the settings for the key. It can yield.
ServerData is provided on the client from the server data.
--]]
function ReplicatedPlayerSettingsRepository.new(Name: string, CreateSettingsFunction: (Key: Player, ServerData: {[string]: any}?) -> (Types.ScopedSettings)):  ReplicatedPlayerSettingsRepository
    --Create the object.
    local self = setmetatable({
        Validators = {},
    }, ReplicatedPlayerSettingsRepository)
    
    --Create or get the replication objects.
    if RunService:IsServer() and not script:FindFirstChild("ChangedEvent"..Name) then
        local NewChangedEvent = Instance.new("RemoteEvent")
        NewChangedEvent.Name = "ChangedEvent"..Name
        NewChangedEvent.Parent = script

        NewChangedEvent.OnServerEvent:Connect(function(Player, Scope: string, Key: string, Value: any?, HardwareKey: string?)
            if not self.Validators[Key] then
                error(`Player sent key "{Key}" but no validator was provided.`)
            end
            self.Validators[Key](Value)
            self:Get(Player):Set(Scope, Key, Value, HardwareKey)
        end)
    end
    local ChangedEvent = script:WaitForChild("ChangedEvent"..Name) :: RemoteEvent

    if RunService:IsServer() and not script:FindFirstChild("GetSettings"..Name) then
        local NewGetSettingsFunction = Instance.new("RemoteFunction")
        NewGetSettingsFunction.Name = "GetSettings"..Name
        NewGetSettingsFunction.Parent = script

        NewGetSettingsFunction.OnServerInvoke = function(Player: Player)
            return self:Get(Player):Serialize()
        end
    end
    local GetSettingsFunction = script:WaitForChild("GetSettings"..Name) :: RemoteFunction

    --Wrap the create settings function and create the repository.
    local OriginalCreateSettingsFunction = CreateSettingsFunction
    if RunService:IsClient() then
        CreateSettingsFunction = function(Player: Player)
            --Create the settings.
            local Settings = OriginalCreateSettingsFunction(Player, GetSettingsFunction:InvokeServer(Player))

            --Wrap Set.
            --This is to track all changes to lower scopes (as well as know the scope).
            local OriginalSet = Settings.Set
            Settings.Set = function(self: Types.ScopedSettings, Scope: string, Key: string, Value: any?, ...: any): ()
                OriginalSet(self, Scope, Key, Value, ...)
                ChangedEvent:FireServer(Scope, Key, Value, PlatformScope.CreateHardwareKey())
            end

            --Return the settings.
            return Settings
        end
    end
    self.SettingsRepository = BasicSettingsRepository.new(CreateSettingsFunction)

    --Return the object.
    return (self :: any) :: ReplicatedPlayerSettingsRepository
end

--[[
Returns an instance of settings for the given key.
Depending on CreateSettingsFunction, this may yield.
--]]
function ReplicatedPlayerSettingsRepository:Get(Key: Player): Types.ScopedSettings
    return self.SettingsRepository:Get(Key)
end

--[[
Clears an instance of settings if it exists.
--]]
function ReplicatedPlayerSettingsRepository:Clear(Key: Player): ()
    self.SettingsRepository:Clear(Key)
end

--[[
Sets the validator for a setting.
On the server, a validator is REQUIRED for settings to save. This is to prevent clients storing irrelevant data.
When there is an issue, an error must be raised.
--]]
function ReplicatedPlayerSettingsRepository:SetValidator(Key: string, Validator: (any?) -> () | {any?}): ()
    if typeof(Validator) == "table" then
        local Map = {}
        for _, Value in Validator do
            Map[Value] = true
        end
        self.Validators[Key] = function(Value: any?)
            if not Map[Value] then
                error(`Invalid value "{Value}" attempted to be stored for {Key}.`)
            end
        end
    else
        self.Validators[Key] = Validator
    end
end

--[[
Connects loading settings when a player joins to reduce delays loading on the client.
--]]
function ReplicatedPlayerSettingsRepository:LoadOnPlayerJoin(): ReplicatedPlayerSettingsRepository
    Players.PlayerAdded:Connect(function(Player)
        self:Get(Player)
    end)
    for _, Player in Players:GetPlayers() do
        task.spawn(self.Get, self, Player)
    end
    return (self :: any) :: ReplicatedPlayerSettingsRepository
end

--[[
Connects clearing on player disconnection.
Only use when not referencing after a player leaves.
--]]
function ReplicatedPlayerSettingsRepository:ClearOnPlayerLeaving(): ReplicatedPlayerSettingsRepository
    Players.PlayerRemoving:Connect(function(Player)
        self:Clear(Player)
    end)
    return (self :: any) :: ReplicatedPlayerSettingsRepository
end



return ReplicatedPlayerSettingsRepository