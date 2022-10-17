--[[
DrugTrafficking - Created by Lama, optimized and made secure by WLVF#0001	
For support - Lama#9612 on Discord	
Do not edit below if you don't know what you are doing
]] --

-- ND_Framework exports (edit with your framework's)
NDCore = exports["ND_Core"]:GetCoreObject()

-- variables, do not touch
local deliveries = {}
local playersOnJob = {}

function isClientTooFar(location)
    if not location then
        return true
    end
    local distance = #(GetEntityCoords(GetPlayerPed(source)) - vector3(location.x, location.y, location.z))
    -- checking from a distance of 20 because it might not be 100% correct
    if distance > 20 then return true end
    return false
end

RegisterNetEvent("DrugTrafficking:StartedCollecting", function()
    local src = source
    playersOnJob[src] = true
end)

RegisterNetEvent("DrugTrafficking:DrugsDelivered", function(location)
    local src = source
	if playersOnJob[src] and not isClientTooFar(location) then
		-- keep track of amount of deliveries made
        if not deliveries[src] then
            deliveries[src] = 0
        end
		deliveries[src] = deliveries[src] + 1
	else
		print(string.format("^1Possible exploiter detected\nName: ^0%s\n^1Identifier: ^0%s\n^1Reason: ^0has delivered from a too big distance", GetPlayerName(source), GetPlayerIdentifier(source, 0)))
	end
end)

RegisterNetEvent("DrugTrafficking:NeedsPayment", function()
    local src = source
	if not deliveries[src] or deliveries[src] == 0 then
		print(string.format("^1Possible exploiter detected\nName: ^0%s\n^1Identifier: ^0%s\n^1Reason: ^0has somehow requested to be paid without delivering anything", GetPlayerName(source), GetPlayerIdentifier(source, 0)))
        return
    end
    -- calculate amount of money to give to the player
    local amount = Config.Pay * deliveries[src]
    if playersOnJob[src] and not isClientTooFar(Config.StartingPosition) then
        -- give the money to player
        -- if using another framework than ND, simply change the function below to your framework's
        deliveries[src] = 0
        playersOnJob[src] = false
        NDCore.Functions.AddMoney(amount, src, "cash")
        return
    end	
    print(string.format("^1Possible exploiter detected\nName: ^0%s\n^1Identifier: ^0%s\n^1Reason: ^0has somehow requested to be paid without being near the job ending location", GetPlayerName(source), GetPlayerIdentifier(source, 0)))
end)

RegisterServerEvent('DrugTrafficking:RemoveItems')
AddEventHandler('DrugTrafficking:RemoveItems', function(inv, item, count)
	local source = source
	local inv = inv
	local item = item
	local count = tonumber(count)
	exports.ox_inventory:RemoveItem(inv, item, count)
end)

RegisterServerEvent('DrugTrafficking:additem')
AddEventHandler('DrugTrafficking:additem', function(inv, item, count)
	print("item add start")
	source = source
	local inv = inv
	local item = item
	local count = count
	invAdded = false
	repeat
		print("repeat started")
		exports.ox_inventory:AddItem(inv, item, count)
		print("export ran")
		Citizen.Wait(1000)
		print("Items are: "..count.." of "..item.." for "..inv)
		local invLevel = exports.ox_inventory:Search(inv, 'count', {'meth', 'cocaine', 'drug_blue', 'drug_red', 'drug_white', 'joint'}, nil)
		print("search completed"..dump(invLevel))
		if invLevel ~= false then
			for name, count in pairs(invLevel) do
				if count > 0 then
					print("confirmed added to inventory")
					invAdded = true
				end
			end
		end

	until (invAdded == true)
end)

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end