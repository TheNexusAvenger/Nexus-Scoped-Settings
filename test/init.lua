--[[
TheNexusAvenger

Tests the NexusScopedSettings class.
--]]
--!strict
--$NexusUnitTestExtensions

local NexusScopedSettings = require(game:GetService("ReplicatedStorage").NexusScopedSettings)

return function()
    describe("A NexusScopedSettings instance", function()
        it("should add scopes.", function()
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Serialize = function() return {Key = "Value1"} end,
            } :: any)
            Settings:AddScope("Scope2", {
                Serialize = function() return {Key = "Value2"} end,
            } :: any)

            expect(Settings:Serialize()).to.deepEqual({Scope1 = {Key = "Value1"}, Scope2 = {Key = "Value2"}})
        end)

        it("should throw an error adding duplicate scopes.", function()
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Serialize = function() return {Key = "Value1"} end,
            } :: any)
            
            expect(function() Settings:AddScope("Scope1", {} :: any) end).to.throw("Scope \"Scope1\" already exists. Scope names must be unique.")
        end)

        it("should get values from the outer scoppe.", function()
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Get = function() return "Value1" end,
            } :: any)
            expect(Settings:Get("Key")).to.equal("Value1")

            Settings:AddScope("Scope2", {
                Get = function() return "Value2" end,
            } :: any)
            expect(Settings:Get("Key")).to.equal("Value2")

        end)

        it("should throw an error getting values when no scopes exist.", function()
            local Settings = NexusScopedSettings.new()
            expect(function() Settings:Get("Key") end).to.throw("There are no scopes. Use AddScope before calling Get.")
        end)

        it("should set values in any scope.", function()
            local ScopeValue1, ScopeValue2 = nil, nil
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Set = function(_, _, Value) ScopeValue1 = Value end,
                Get = function() end,
            } :: any)
            Settings:AddScope("Scope2", {
                Set = function(_, _, Value) ScopeValue2 = Value end,
                Get = function() end,
            } :: any)

            Settings:Set("Scope1", "Key", "Value1")
            expect(ScopeValue1).to.equal("Value1")
            expect(ScopeValue2).to.equal(nil)

            Settings:Set("Scope1", "Key", "Value2")
            expect(ScopeValue1).to.equal("Value2")
            expect(ScopeValue2).to.equal(nil)

            Settings:Set("Scope2", "Key", "Value3")
            expect(ScopeValue1).to.equal("Value2")
            expect(ScopeValue2).to.equal("Value3")
        end)

        it("should throw an error when setting an unknown scope.", function()
            local Settings = NexusScopedSettings.new()
            expect(function() Settings:Set("Unknown", "Key", "Value") end).to.throw("Scope \"Unknown\" does not exist. Use AddScope before calling Set.")
        end)

        it("should fire changed events.", function()
            local ChangedValue1, ChangedValue2 = nil, nil
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Set = function() end,
                Get = function() return "Value1" end,
            } :: any)
            Settings.SettingChanged:Connect(function(_, Value) ChangedValue1 = Value end)
            Settings:GetSettingChangedEvent("Key"):Connect(function(Value) ChangedValue2 = Value end)

            Settings:Set("Scope1", "Key", "Value2")
            task.wait()
            expect(ChangedValue1).to.equal("Value2")
            expect(ChangedValue2).to.equal("Value2")
        end)

        it("should not fire changed events when value is unchanged.", function()
            local ChangedValue1, ChangedValue2 = nil, nil
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Set = function() end,
                Get = function() return "Value1" end,
            } :: any)
            Settings.SettingChanged:Connect(function(_, Value) ChangedValue1 = Value end)
            Settings:GetSettingChangedEvent("Key"):Connect(function(Value) ChangedValue2 = Value end)

            Settings:Set("Scope1", "Key", "Value1")
            task.wait()
            expect(ChangedValue1).to.equal(nil)
            expect(ChangedValue2).to.equal(nil)
        end)

        it("should not fire changed events when the outer scope value is unchanged.", function()
            local ChangedValue1, ChangedValue2 = nil, nil
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Set = function() end,
                Get = function() return "Value1" end,
            } :: any)
            Settings:AddScope("Scope2", {
                Set = function() end,
                Get = function() return "Value2" end,
            } :: any)
            Settings.SettingChanged:Connect(function(_, Value) ChangedValue1 = Value end)
            Settings:GetSettingChangedEvent("Key"):Connect(function(Value) ChangedValue2 = Value end)

            Settings:Set("Scope1", "Key", "Value2")
            task.wait()
            expect(ChangedValue1).to.equal(nil)
            expect(ChangedValue2).to.equal(nil)
        end)

        it("should disconnect events.", function()
            local ChangedValue1, ChangedValue2 = nil, nil
            local Settings = NexusScopedSettings.new()
            Settings:AddScope("Scope1", {
                Set = function() end,
                Get = function() return "Value1" end,
            } :: any)
            Settings.SettingChanged:Connect(function(_, Value) ChangedValue1 = Value end)
            Settings:GetSettingChangedEvent("Key"):Connect(function(Value) ChangedValue2 = Value end)

            Settings:Destroy()
            Settings:Set("Scope1", "Key", "Value2")
            task.wait()
            expect(ChangedValue1).to.equal(nil)
            expect(ChangedValue2).to.equal(nil)
        end)
    end)

    describe("A default settings instance", function()
        it("should have the default scopes from serialzied data.", function()
            local Settings = NexusScopedSettings.CreatePlayerDefault({
                User = {Key1 = "Value1", Key2 = "Value2", Key3 = "Value3"},
                System = {CY = {Key3 = "Value3A"}, CN = {Key3 = "Value3B"}},
            })
            expect(Settings:Get("Key1", "CY")).to.equal("Value1")
            expect(Settings:Get("Key2", "CY")).to.equal("Value2")
            expect(Settings:Get("Key3", "CY")).to.equal("Value3A")
            expect(Settings:Get("Key3", "CN")).to.equal("Value3B")
            expect(Settings:Get("Key4", "CY")).to.equal(nil)
            
            Settings:Set("Default", "Key0", "Value3", "CY")
            Settings:Set("User", "Key3", "Value3C", "CY")
            Settings:Set("Session", "Key4", "Value4", "CY")
            expect(Settings:Get("Key1", "CY")).to.equal("Value1")
            expect(Settings:Get("Key2", "CY")).to.equal("Value2")
            expect(Settings:Get("Key3", "CY")).to.equal("Value3A")
            expect(Settings:Get("Key3", "CN")).to.equal("Value3B")
            expect(Settings:Get("Key4", "CY")).to.equal("Value4")
            expect(Settings:Serialize()).to.deepEqual({
                User = {Key1 = "Value1", Key2 = "Value2", Key3 = "Value3C"},
                System = {CY = {Key3 = "Value3A"}, CN = {Key3 = "Value3B"}},
            })
        end)
    end)
end