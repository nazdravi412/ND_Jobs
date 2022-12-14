JobStarted = false
local pay = 0
blipStatus = false
timerCompleted = false
itemsConfirmed = false

NDCore = exports["ND_Core"]:GetCoreObject()	

-- Set blip only for civs. 
Citizen.CreateThread(function()
	while true do
		local on_duty = NDCore.Functions.GetSelectedCharacter()	
		if(on_duty) then
			PlayerJob = on_duty.job
		end
		TriggerEvent("drugTrafficking:blipToggle")
		Citizen.Wait(3000)
	end
end)

RegisterNetEvent('drugTrafficking:blipToggle')
AddEventHandler('drugTrafficking:blipToggle', function()
	if PlayerJob == Config.civJob and blipStatus == false then
		local bliplocation = vector3(2196.65, 5609.89, 53.56)
		blip = AddBlipForCoord(bliplocation.x, bliplocation.y, bliplocation.z)
		SetBlipSprite(blip, 457)
		SetBlipDisplay(blip, 4)
		SetBlipColour(blip, 21)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Drug Trafficking Job")
		EndTextCommandSetBlipName(blip)
		blipStatus = true
	elseif PlayerJob ~= Config.civJob then
		RemoveBlip(blip)
		blipStatus = false
		Citizen.Wait(3000)
	end
end)

RegisterNetEvent('DrugTrafficking:itemConfirmed')
AddEventHandler('DrugTrafficking:itemConfirmed', function(confirmation)
	--print("Confirmation received")
	if confirmation == "true" then
		--print("true")
		itemsConfirmed = true
	else
		itemsConfirmed = false
		--print("false")
	end	
end)

RegisterNetEvent('drugTrafficking:startJob')
AddEventHandler('drugTrafficking:startJob', function()
	StartJob()
end)

RegisterNetEvent('drugTrafficking:stopJob')
AddEventHandler('drugTrafficking:stopJob', function()
	ForceStopService()
end)

RegisterCommand('stopdrugs', function(source, args)
    TriggerEvent("drugTrafficking:stopJob")
end, false)

function NewBlip()
	timerCompleted = false
    local objective = math.randomchoice(Config.Positions)
    local ped = cache.ped
	local narco = math.randomchoice(Config.Narcos)
	CreateNPCdropOff(GetHashKey(narco), objective)
    blip = AddBlipForCoord(objective.x, objective.y, objective.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 2)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 2)

	exports.rprogress:Custom({
    Radius = 60,
    Stroke = 60,
	x = 0.95,
	y = 0.90,
	Label = "Delivery",
	LabelPosition = "top",
	Duration = 60000*5,
	ShowTimer = true,
	onComplete = function(cancelled)
		timerCompleted = true
    end
	})
	
    local coords = GetEntityCoords(ped)
    local distance = Vdist2(coords, objective.x, objective.y, objective.z)

    while true do
        local opti = 5000
        coords = GetEntityCoords(ped)
        distance = Vdist2(coords, objective.x, objective.y, objective.z)
        AddTextEntry("press_collect_drugs2", 'Press ~INPUT_CONTEXT~ to deliver the drugs')
		if not timerCompleted then 
			if distance <= 50 then
				opti = 1000
				if itemsConfirmed == false then
					TriggerServerEvent("DrugTrafficking:confirmItem", pedID, cargo, drugAmount)
				end
				if distance <= 10 and itemsConfirmed then
					opti = 2
					DisplayHelpTextThisFrame("press_collect_drugs2")
					TaskTurnPedToFaceEntity(npcNarco, ped, -1)
					if IsControlJustPressed(1, 38) then
						ExecuteCommand("e c")
						TriggerEvent("rprogress:stop")
						itemsConfirmed = false
						TriggerServerEvent("DrugTrafficking:DrugsDelivered", objective)
						pay = pay + Config.Pay
						RemoveBlip(blip)
						TriggerServerEvent("DrugTrafficking:RemoveItems", pedID , cargo, drugAmount)
						TaskWanderStandard(npcNarco, 10.0, 10.0)
						ChoiceNotif()
						break
					end
				end
			end
		else
			TextMessage("CHAR_DAVE", "Kingpin", "Drug Trafficking", "I knew you weren't cut out for the job. Marcus and Timothy will enjoy this!", true)
			local jimothy = math.randomchoice(Config.Bodyguards)
			CreateNPChitmen(GetHashKey(jimothy))
			RemoveBlip(blip)
			break
		end
        if IsControlJustPressed(1, 73) then
            RemoveBlip(blip)
            drawnotifcolor("Come back to the house to get your money.", 25)
            StopService()
            break
        end
        Wait(opti)
    end
end

function ChoiceNotif()
    drawnotifcolor("Press ~g~E~w~ for more drug deliveries.\nPress ~r~X~w~ if you want to stop the job", 140)

    local timer = 1500
    while timer >= 1 do
        Wait(10)
        timer = timer - 1

        if IsControlJustPressed(1, 38) then
            NewChoice()
            break
        end

        if IsControlJustPressed(1, 73) then
            drawnotifcolor("Come back to the house to get your money.", 25)
            StopService()
            break
        end

        if timer == 1 then
            drawnotifcolor("You took too much time to decide! The deal is off, get back to the house, now.", 208)
            StopService()
            break
        end

    end
end

function NewChoice()
    route = math.randomchoice(Config.Positions)
    ped = cache.ped
	local narco = math.randomchoice(Config.Narcos)
	CreateNPCdropOff(GetHashKey(narco), route)
    blip = AddBlipForCoord(route.x, route.y, route.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 3)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 3)

    drawnotifcolor("New location is set, press ~r~X~w~ if you want to stop the job.", 140)
    local coords = GetEntityCoords(ped)
    local distance = Vdist2(coords, route.x, route.y, route.z)
	
    while true do
        local opti = 5000
        coords = GetEntityCoords(ped)
        distance = Vdist2(coords, route.x, route.y, route.z)
        AddTextEntry("press_collect_drugs", 'Press ~INPUT_CONTEXT~ to collect the drugs')
        if distance <= 60 then
            opti = 1000
            if distance <= 10 and not deadNarco then
                opti = 2
                DisplayHelpTextThisFrame("press_collect_drugs")
				TaskTurnPedToFaceEntity(npcNarco, ped, -1)
                if IsControlJustPressed(1, 38) and not IsPedInAnyVehicle(ped, true) then
					ExecuteCommand("e box")
					TaskWanderStandard(npcNarco, 10.0, 10.0)
					drugAmount = math.random(5, 15)
					pedID = GetPlayerId(ped)
					--local vehicle = GetVehiclePedIsIn(ped)
					--local plates = GetVehicleNumberPlateText(vehicle)
					cargo = math.randomchoice(Config.Drugs)
					--drugStash = "trunk"..plates -- Will delete and use pedID once we have NPCs and ddialog.
					--Citizen.Wait(100)
					TriggerServerEvent("DrugTrafficking:additem", pedID , cargo, drugAmount)
                    RemoveBlip(blip)
                    NewBlip()
                    break
				end
            end
        end
        if IsControlJustPressed(1, 73) then
            RemoveBlip(blip)
            drawnotifcolor("Head back to the garage to get paid.", 140)
            StopService()
            break
        end
        Wait(opti)
    end
end


Citizen.CreateThread(function()
	while true do
		if thugNarco ~= nil then
			deadNarco = IsPedDeadOrDying(thugNarco, true)
			if deadNarco then
				-- Create hitmen with function below.
				print("Jimothy is dead!")
				RemoveBlip(blip)
				TextMessage("CHAR_DAVE", "Kingpin", "Drug Trafficking", "I'll have your head on my desk by morning!", true)
				local jimothy = math.randomchoice(Config.Bodyguards)
				CreateNPChitmen(GetHashKey(jimothy))
				break
			end
		end
	Wait(1000)
	end
	
	while true do
			local deadPlayer = IsPedDeadOrDying(cache.ped, true)
			if deadPlayer and JobStarted then

				print("Player is dead!")
				RemoveBlip(blip)
				TextMessage("CHAR_DAVE", "Kingpin", "Drug Trafficking", "I told you I'd have your head....hahahaha!", true)
				playerIncapacitated()
				break
			end
	Wait(1000)
	end
end)

function StopService()
    local coordsEndService = Config.StartingPosition
    local ped = cache.ped
    AddTextEntry("press_ranger_ha420", 'Press ~INPUT_CONTEXT~ to return to the house and get the money.')

    blip = AddBlipForCoord(coordsEndService)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 1)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 1)

    while true do
        local opti = 5000
        local coords = GetEntityCoords(ped)
        local distance = Vdist2(coordsEndService, coords)
        if distance <= 50 then
            opti = 1000
            if distance <= 10 then
                opti = 2
                DisplayHelpTextThisFrame("press_ranger_ha420")
                if IsControlJustPressed(1, 38) then
					TriggerServerEvent("DrugTrafficking:RemoveItems", pedID , cargo, drugAmount)
                    local playerPed = cache.ped
                        TriggerServerEvent("DrugTrafficking:NeedsPayment", coordsEndService)
                        drawnotifcolor("You've received ~g~$" .. pay .. "~w~ for completing the job.", 140)
                        RemoveBlip(blip)
						TaskWanderStandard(npcNarco, 10.0, 10.0)
                        JobStarted = false
                        pay = 0
                        break
                end
            end
        end
        Wait(opti)
    end
end

function ForceStopService()
    TextMessage("CHAR_DAVE", "Kingpin", "Drug Trafficking", "Come see me when you want to take this seriously!", true)
	RemoveBlip(blip)
	TaskWanderStandard(npcNarco, 10.0, 10.0)
	JobStarted = false
	pay = 0
end

function StartJob()
    local ped = cache.ped
    JobStarted = true
	showSubtitle("I need you to make some drops for me today.", 5000)
	Citizen.Wait(4000)
	showSubtitle("I'll give you $1250 for each one.", 5000)
	Citizen.Wait(4000)
	showSubtitle("Take your car...you're not using mine.", 5000)
	Citizen.Wait(4000)
	showSubtitle("Don't screw me over, or you'll deal with Marcus and Jimothy, here.", 5000)
    TriggerServerEvent("DrugTrafficking:StartedCollecting")
    NewChoice()
end

CreateThread(function()
	AddRelationshipGroup('DrugTraffickers')
	local bodyguard1 = math.randomchoice(Config.Bodyguards)
	local bodyguard2 = math.randomchoice(Config.Bodyguards)
	CreateNPCstart(GetHashKey("ig_davenorton"),vector4(2194.06, 5597.26, 52.77, 334.34))
	CreateNPCbodyguards(GetHashKey(bodyguard1),vector4(2198.27, 5599.23, 52.72, 79.82))
	CreateNPCbodyguards(GetHashKey(bodyguard2),vector4(2192.96, 5607, 52.65, 259.08))
    while true do
        local opti = 5000
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local distance = Vdist2(vector3(2194.06, 5597.26, 53.77), coords)
		
        if distance <= 50 and not JobStarted then
            opti = 1000
            if distance <= 40 then
                opti = 2
                if distance <= 30 then
                    -- Create dialog for NPC to give instructions via messages like used in the vehicle boost script.
					showSubtitle("You're late! We have work to do.", 5000)
					break
					-- Create option to start via Drawtext and proximity??
                end
            end
        end
        Wait(0)
    end
end)

function drawnotifcolor(text, color)
    Citizen.InvokeNative(0x92F0DA1E27DB96DC, tonumber(color))
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, true)
end

function math.randomchoice(d)
    return d[math.random(1, #d)]
end

-- Gets Players
function GetPlayers()
    players = {}
    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end
    return players
end

-- Gets Player ID
function GetPlayerId(target_ped)
    players = GetPlayers()
    for a = 1, #players do
        ped = GetPlayerPed(players[a])
        server_id = GetPlayerServerId(players[a])
        if target_ped == ped then
            return server_id
        end
    end
    return 0
end

-- Create NPCs
function CreateNPCstart(model, startCoords)
    local hashFile = model
    while not HasModelLoaded(hashFile) do
        RequestModel(hashFile)
        Citizen.Wait(10) 
    end

    npc = CreatePed(69, hashFile, startCoords, false, true) 
    --FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, false)
	GiveWeaponToPed(npc, GetHashKey("weapon_assaultsmg"),1000, false, false)
	SetCurrentPedWeapon(npc, GetHashKey("weapon_unarmed"), false)
	SetCanAttackFriendly(npc, true, false)
    --SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(hashFile)
    --TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_GUARD_STAND', 0, true)
	SetPedRelationshipGroupHash(npc, "DrugTraffickers")
	SetPedDropsWeaponsWhenDead(npc, false)
end

-- Create NPCs
function CreateNPChitmen(model)
    local hashFile = model
    while not HasModelLoaded(hashFile) do
        RequestModel(hashFile)
        Citizen.Wait(10) 
    end
	
	while not HasModelLoaded(GetHashKey("gauntlet")) do
        RequestModel(GetHashKey("gauntlet"))
        Citizen.Wait(10) 
    end
	
	hitmenVehicle = CreateVehicle(GetHashKey("gauntlet"), 1730.91, 3320.4, 40.8, 194.5, true, true)
	SetVehicleColours(hitmenVehicle, 147, 147)

    npcHitman = CreatePedInsideVehicle(hitmenVehicle, 26, hashFile, -1, true, true)
	npcHitman2 = CreatePedInsideVehicle(hitmenVehicle, 26, hashFile, 0, true, true)
	--TaskWarpPedIntoVehicle(npcHitman, hitmenVehicle, -1)
	--Initiate chase code here.
	
	
    --FreezeEntityPosition(npc, true)
    SetEntityInvincible(npcHitman, false)
	GiveWeaponToPed(npcHitman, GetHashKey("weapon_minismg"),1000, false, true)
	SetCurrentPedWeapon(npcHitman, GetHashKey("weapon_minismg"), true)
	SetCanAttackFriendly(npcHitman, true, false)
    --SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(hashFile)
	SetPedCombatAttributes(npcHitman, 2, true)
    --TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_GUARD_STAND', 0, true)
	SetPedRelationshipGroupHash(npcHitman, "DrugTraffickers")
	SetPedDropsWeaponsWhenDead(npcHitman, false)
	
	SetEntityInvincible(npcHitman2, false)
	SetPedCombatAttributes(npcHitman2, 2, true)
	GiveWeaponToPed(npcHitman2, GetHashKey("weapon_minismg"),1000, false, true)
	SetCurrentPedWeapon(npcHitman2, GetHashKey("weapon_minismg"), true)
	SetCanAttackFriendly(npcHitman2, true, false)
    --SetBlockingOfNonTemporaryEvents(npc, true)
    --TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_GUARD_STAND', 0, true)
	SetPedRelationshipGroupHash(npcHitman2, "DrugTraffickers")
	SetPedDropsWeaponsWhenDead(npcHitman2, false)

	while true do -- test this loop
		local playerCoords = GetEntityCoords(cache.ped)
		TaskVehicleDriveToCoord(npcHitman, hitmenVehicle, playerCoords, 100.0, 0, GetHashKey("gauntlet"), 524800, 10.0, true)
		if (#(GetEntityCoords(cache.ped) - GetEntityCoords(npcHitman)) < 100.0) then
			--print("Finished drive to coord")
			break
		end 
	Wait(5000)
	end
	
	while true do -- test this loop
		local playerCoords = GetEntityCoords(cache.ped)
		TaskVehicleChase(npcHitman, cache.ped)
		SetTaskVehicleChaseBehaviorFlag(npcHitman, 1, true)
		TaskShootAtEntity(npcHitman, cache.ped, 2500, GetHashKey("FIRING_PATTERN_BURST_FIRE_DRIVEBY"))
		TaskShootAtEntity(npcHitman2, cache.ped, 2500, GetHashKey("FIRING_PATTERN_BURST_FIRE_DRIVEBY"))
		if (#(GetEntityCoords(cache.ped) - GetEntityCoords(npcHitman)) < 25.0) and not IsPedInAnyVehicle(cache.ped) then
			--print("Breaking Vehicle Chase Loop")
			TaskLeaveVehicle(npcHitman, hitmenVehicle, 256)
			TaskLeaveVehicle(npcHitman2, hitmenVehicle, 256)
			break
		end 
	Wait(3000)
	end
	
	TaskCombatPed(npcHitman, cache.ped, 0, 16)

end

-- Create NPCs with weapons
function CreateNPCbodyguards(model, startCoords)
    local hashFile = model
    while not HasModelLoaded(hashFile) do
        RequestModel(hashFile)
        Citizen.Wait(10) 
    end

    npcBG = CreatePed(69, hashFile, startCoords, false, true) 
    --FreezeEntityPosition(npcBG, true)
    SetEntityInvincible(npcBG, false)
    --SetBlockingOfNonTemporaryEvents(npcBG, true)
    SetModelAsNoLongerNeeded(hashFile)
    --TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_GUARD_STAND', 0, true)
	GiveWeaponToPed(npcBG, GetHashKey("weapon_assaultsmg"),1000, false, true)
	SetCurrentPedWeapon(npcBG, GetHashKey("weapon_assaultsmg"), true)
	SetCanAttackFriendly(npcBG, true, false)
	SetPedRelationshipGroupHash(npcBG, "DrugTraffickers")
	SetPedDropsWeaponsWhenDead(npcbg, false)

end

-- Create NPCs at drops.
function CreateNPCdropOff(model, startCoords)
    local hashFile = model
    while not HasModelLoaded(hashFile) do
        RequestModel(hashFile)
        Citizen.Wait(10) 
    end
	local randomHeading = math.random(0.0, 360.0)
    npcNarco = CreatePed(69, hashFile, startCoords.x, startCoords.y, startCoords.z+2.0, randomHeading, true, true) 
	thugNarco = npcNarco
	
    --FreezeEntityPosition(npcBG, true)
    SetEntityInvincible(npcNarco, false)
    --SetBlockingOfNonTemporaryEvents(npcBG, true)
    SetModelAsNoLongerNeeded(hashFile)
    --TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_GUARD_STAND', 0, true)
	GiveWeaponToPed(npcNarco, GetHashKey("weapon_assaultsmg"),1000, true, false)
	SetCurrentPedWeapon(npcNarco, GetHashKey("weapon_unarmed"), false)
	SetCanAttackFriendly(npcNarco, true, false)
	SetPedRelationshipGroupHash(npcNarco, "DrugTraffickers")
	SetPedDropsWeaponsWhenDead(npcNarco, false)
	

end

-- Ox_Target integration
exports.ox_target:addBoxZone({
    coords = vec3(2194.05, 5597.25, 53.75),
    size = vec3(1, 0.75, 2.0),
    rotation = 0.0,
    options = {
        {
            name = 'drug_trafficker',
            event = 'drugTrafficking:startJob',
            icon = 'fa-solid fa-cube',
            label = 'Start Job',

        }
    }
})

--ShowTitle Function
function showSubtitle(message, duration)
	BeginTextCommandPrint('STRING')
	AddTextComponentString(message)
	EndTextCommandPrint(duration, true)
end

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

function TextMessage(NotiPic, SenderName, Subject, MessageText, PlaySound)
	RequestStreamedTextureDict(NotiPic,1)
	while not HasStreamedTextureDictLoaded(NotiPic)  do
		Wait(1)
	end

   	Citizen.InvokeNative(0x202709F4C58A0424,"STRING")
   	AddTextComponentString(MessageText)
   	Citizen.InvokeNative(0x92F0DA1E27DB96DC,140)
    Citizen.InvokeNative(0x1CCD9A37359072CF,NotiPic, NotiPic, true, 4, SenderName, Subject, MessageText)
   	Citizen.InvokeNative(0xAA295B6F28BD587D,false, true)
	if PlaySound then
		PlaySoundFrontend(GetSoundId(), "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
	end

	if SendChatMessages then
		TriggerEvent('chatMessage', '', { 255, 255, 255 }, MessageText)
	end
end

function playerIncapacitated()
	ClearPedTasks(npcHitman)
	ClearPedTasks(npcHitman2)
	TaskVehicleDriveWander(npcHitman, hitmenVehicle, 17.0, 524288)
	SetEntityAsNoLongerNeeded(npcHitman)
	SetEntityAsNoLongerNeeded(npcHitman2)
	SetEntityAsNoLongerNeeded(hitmenVehicle)
	RemoveBlip(blip)
	JobStarted = false
	blipStatus = false
	timerCompleted = false
end 