--[[
TheNexusAvenger

Tests the BasicSettingsRepository class.
--]]
--!strict

local BasicSettingsRepository = require(game:GetService("ReplicatedStorage").NexusScopedSettings.Repository.BasicSettingsRepository)

return function()
    describe("A basic settings repository", function()
        it("should cache values.", function()
            local Repository = BasicSettingsRepository.new(function()
                return {} :: any
            end)

            local Settings = Repository:Get("Key1")
            expect(Settings).to.equal(Repository:Get("Key1"))
            expect(Settings).to.never.equal(Repository:Get("Key2"))
        end)

        it("should handle yielding when creating settings.", function()
            local Settings1, Settings2 = nil, nil
            local Repository = BasicSettingsRepository.new(function()
                task.wait(0.1)
                return {} :: any
            end)

            task.spawn(function()
                Settings1 = Repository:Get("Key1")
            end)
            task.spawn(function()
                Settings2 = Repository:Get("Key1")
            end)
            task.wait(0.2)
            expect(Settings1).to.equal(Settings2)
        end)
        it("should clear values.", function()
            local Repository = BasicSettingsRepository.new(function()
                return {} :: any
            end)

            local Settings = Repository:Get("Key1")
            expect(Settings).to.equal(Repository:Get("Key1"))
            Repository:Clear("Key1")
            expect(Settings).to.never.equal(Repository:Get("Key1"))
        end)
    end)
end