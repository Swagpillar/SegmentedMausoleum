SegmentedMausoleum = RegisterMod("Segmented Mausoleum", 1)
local mod = SegmentedMausoleum

CollectibleType.COLLECTIBLE_KNIFE_PIECE_3 = Isaac.GetItemIdByName("Knife Piece 3")
include("lua/items/KnifePiece3.lua")

mod.savedrooms={}
mod.bannedspecialrooms={}
local rng = RNG()

function mod:CheckIntegrity()
	local level = Game():GetLevel()
	local count = 0
	for i = 0, 168 do
		local room = level:GetRoomByIdx(i)
		if room and room.Data then
			if (room.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0) then
				count = count + 1
			end
		end
	end
	if count < 10 then
		return false
	end
	return true
end

function mod:CountNeighbors(index)
	local count = 0
	local neighbors={-1,-13,1,13}
	for i = 1, 4 do
		local room = Game():GetLevel():GetRoomByIdx(index+neighbors[i], 0)
		if room and room.Data then
			count = count + 1
		end
	end
	
	return count
end

function mod:CountFreeDeadEnds()
	local level = Game():GetLevel()
	local count = 0
	for i = 0, 168 do
		local room = level:GetRoomByIdx(i, 0)
		if room and room.Data then
			if room.Data.Type == RoomType.ROOM_DEFAULT then
				if (room.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0) then
					if mod:CountNeighbors(room.GridIndex) == 1 then
						count = count + 1
					end
				end
			end
		end
	end
	return count
end

function mod:ShiftSpecialRooms()
	local level = Game():GetLevel()
	local deadEnds = mod:CountFreeDeadEnds()
	for i = 0, 168 do
		local room = level:GetRoomByIdx(i, 0)
		
		local tempData = nil
		if room and room.Data then
			if (room.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0) and room.Data.Type ~= RoomType.ROOM_DEFAULT then
				if not mod.bannedspecialrooms[room.Data.Type] then
					if mod:CountNeighbors(i) > 1 then
						if mod:CountFreeDeadEnds() == 0 then
							room.Data = level:GetRoomByIdx(level:GetStartingRoomIndex(), 0).Data
						else
							tempData = room.Data
						end
					end
				else
					room.Data = level:GetRoomByIdx(level:GetStartingRoomIndex(), 0).Data
				end
			end
		end
		
		if tempData then
			local newRoom = nil
			repeat newRoom = level:GetRoomByIdx(rng:RandomInt(169))
			until newRoom and newRoom.Data and (newRoom.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0) and newRoom.Data.Type == RoomType.ROOM_DEFAULT and mod:CountNeighbors(newRoom.GridIndex) == 1
			if newRoom.Data then
				mod.bannedspecialrooms[room.Data.Type] = true
				room.Data = newRoom.Data
				newRoom.Data = tempData
				tempData = nil
			end
		end
	end
end

function mod:SetVisibility()
	local level = Game():GetLevel()
	if level:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT) then
		level:ApplyCompassEffect(true)
	end
	if level:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then
		level:ApplyMapEffect()
	end
	if level:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT) then
		level:ApplyBlueMapEffect()
	end
	if level:GetStateFlag(LevelStateFlag.STATE_FULL_MAP_EFFECT) then
		level:ShowMap()
	end
end

function mod:CanCreateRoom(id, doorSlot) -- this can definitely be done better
	local level = Game():GetLevel()
	
	if doorSlot == DoorSlot.LEFT0 then
		if level:GetRoomByIdx(id-1,0).GridIndex > -1 or level:GetRoomByIdx(id-2,0).GridIndex > -1 or level:GetRoomByIdx(id-14,0).GridIndex > -1 or level:GetRoomByIdx(id+12,0).GridIndex > -1 then
			return false
		end
		if level:GetRoomByIdx(id-1,0).GridIndex < -1 or level:GetRoomByIdx(id-2,0).GridIndex < -1 or level:GetRoomByIdx(id-14,0).GridIndex < -1 or level:GetRoomByIdx(id+12,0).GridIndex < -1 then
			return false
		end
	elseif doorSlot == DoorSlot.UP0 then
		if level:GetRoomByIdx(id-13,0).GridIndex > -1 or level:GetRoomByIdx(id-26,0).GridIndex > -1 or level:GetRoomByIdx(id-14,0).GridIndex > -1 or level:GetRoomByIdx(id-12,0).GridIndex > -1 then
			return false
		end
		if level:GetRoomByIdx(id-13,0).GridIndex < -1 or level:GetRoomByIdx(id-26,0).GridIndex < -1 or level:GetRoomByIdx(id-14,0).GridIndex < -1 or level:GetRoomByIdx(id-12,0).GridIndex < -1 then
			return false
		end
	elseif doorSlot == DoorSlot.RIGHT0 then
		if level:GetRoomByIdx(id+1,0).GridIndex > -1 or level:GetRoomByIdx(id+2,0).GridIndex > -1 or level:GetRoomByIdx(id+14,0).GridIndex > -1 or level:GetRoomByIdx(id-12,0).GridIndex > -1 then
			return false
		end
		if level:GetRoomByIdx(id+1,0).GridIndex < -1 or level:GetRoomByIdx(id+2,0).GridIndex < -1 or level:GetRoomByIdx(id+14,0).GridIndex < -1 or level:GetRoomByIdx(id-12,0).GridIndex < -1 then
			return false
		end
	elseif doorSlot == DoorSlot.DOWN0 then
		if level:GetRoomByIdx(id+13,0).GridIndex > -1 or level:GetRoomByIdx(id+26,0).GridIndex > -1 or level:GetRoomByIdx(id+14,0).GridIndex > -1 or level:GetRoomByIdx(id+12,0).GridIndex > -1 then
			return false
		end
		if level:GetRoomByIdx(id+13,0).GridIndex < -1 or level:GetRoomByIdx(id+26,0).GridIndex < -1 or level:GetRoomByIdx(id+14,0).GridIndex < -1 or level:GetRoomByIdx(id+12,0).GridIndex < -1 then
			return false
		end
	end
	
	return true
end

local numRooms = 0
local loops = 0
function mod:CreateRooms(id,rng)
	local oldroom = Game():GetLevel():GetRoomByIdx(id)
	if oldroom.GridIndex < 0 then return end
	local neighbors={-1,-13,1,13}
	while numRooms < 10 do
		for i = 1, 4 do
			local door = rng:RandomInt(4) + 1
			if oldroom.Data.Doors & (1 << door-1) > 0 then
				if mod:CanCreateRoom(id, door-1) then
					local out = rng:RandomFloat()
					if out < 0.5 then
						Game():GetLevel():MakeRedRoomDoor(id,door-1)
						
						local newRoom = Game():GetLevel():GetRoomByIdx(id+neighbors[door],0)
						if newRoom.GridIndex > -1 then
							newRoom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
							numRooms = numRooms + 1
							mod:CreateRooms(id+neighbors[door], rng)
						end
					end
				end
			end
		end
		
		loops = loops + 1
		if loops > 1000 then
			break
		end
	end
end

function mod:GenerateBackroomSpace()
	local chosenroomslot=nil
	local level = Game():GetLevel()
	for i=2+26,168-2-26 do
		local skip=false
		for x=-2,2 do
			for y=-2,2 do
				if not skip then
					local offroom=level:GetRoomByIdx(i+x+13*y,0)
					if (i+x+13*y)>168 or offroom.GridIndex > -1 then
						skip=true
					end
				end
			end
		end
		if not skip then
			chosenroomslot=i
			break
		end
	end
	if not chosenroomslot then
		return
	end
	
	local oldchallenge = Game().Challenge
	Game().Challenge = Challenge.CHALLENGE_RED_REDEMPTION
	level:MakeRedRoomDoor(chosenroomslot - 13, DoorSlot.DOWN0)
	local exitroom = level:GetRoomByIdx(chosenroomslot, 0)
	if mod.savedrooms["teleporterexit"] then
		exitroom.Data = mod.savedrooms["teleporterexit"]
		exitroom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
	end
	Game().Challenge = oldchallenge
	
	local neighbors = {-1,-13,1,13}
	local lastroom = nil
	
	local randomdoorslot = nil
	repeat randomdoorslot = rng:RandomInt(4)
	until exitroom.Data.Doors & (1 << randomdoorslot) > 0
	
	if mod:CanCreateRoom(chosenroomslot, randomdoorslot) then
		level:MakeRedRoomDoor(chosenroomslot, randomdoorslot)
		
		local newRoom = level:GetRoomByIdx(chosenroomslot+neighbors[randomdoorslot+1],0)
		newRoom.Flags = RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP
		mod:CreateRooms(chosenroomslot+neighbors[randomdoorslot+1], rng)
		mod.bannedspecialrooms={
			[7] = true,
			[8] = true,
			[14] = true,
			[15] = true,
			[24] = true,
		}
		mod:ShiftSpecialRooms()
		mod:SetVisibility()
		numRooms = 0
		loops = 0
		return chosenroomslot
	end
end

function mod:Init()
	local level = Game():GetLevel()
	mod.savedrooms = {}
	rng:SetSeed(Game():GetSeeds():GetStageSeed(level:GetStage()),0)

	local ran = rng:RandomInt(6)
	Isaac.ExecuteCommand("goto x.teleporter."..ran)
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		mod.savedrooms["teleporter"] = gotor.Data
	end
	ran = rng:RandomInt(6)
	Isaac.ExecuteCommand("goto x.teleporterexit."..ran)
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		mod.savedrooms["teleporterexit"] = gotor.Data
	end
	
	--todo: get a super secret room and figure out how to place it

	Isaac.ExecuteCommand("goto 6 6 0")
	
	local dontReplace =
	{
		[RoomType.ROOM_TREASURE] = true,
		[RoomType.ROOM_SHOP] = true,
		[RoomType.ROOM_BOSS] = true,
		[RoomType.ROOM_PLANETARIUM] = true, -- not a guaranteed special room like the others but I don't want to lower the chances for no reason.
		[RoomType.ROOM_SECRET] = true,
		[RoomType.ROOM_SUPERSECRET] = true,
		[RoomType.ROOM_ULTRASECRET] = true,
	}
	
	local room = nil
	repeat room = level:GetRoomByIdx(rng:RandomInt(169))
	until room.Data and room.Data.Shape == RoomShape.ROOMSHAPE_1x1 and mod:CountNeighbors(room.GridIndex) == 1 and not dontReplace[room.Data.Type]
	if mod.savedrooms["teleporter"] then
		room.Data = mod.savedrooms["teleporter"]
		if MinimapAPI then
			local apiRoom = MinimapAPI:GetRoomByIdx(room.GridIndex)
			apiRoom:UpdateType()
		end
	end
	
	mod:GenerateBackroomSpace()
	if mod:CheckIntegrity() == false then -- uh oh
		Isaac.ExecuteCommand("reseed") -- back to the lab again
		--mod:Init()
	end
end

function mod:Room()
	local level = Game():GetLevel()
	local room = level:GetCurrentRoom()
	local roomDesc = level:GetRoomByIdx(level:GetCurrentRoomIndex())
	
	if room:GetBackdropType() == BackdropType.MAUSOLEUM or room:GetBackdropType() == BackdropType.MAUSOLEUM2 then
		if roomDesc.Flags & RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP > 0 then
			Game():ShowHallucination(0, BackdropType.MAUSOLEUM3)
			SFXManager():Stop(SoundEffect.SOUND_DEATH_CARD)
		end
		
		if roomDesc.GridIndex < 14 and room:GetDoor(DoorSlot.UP0) then
		    room:GetDoor(DoorSlot.UP0):ToDoor():SetLocked(true)
		elseif roomDesc.GridIndex > 155 and room:GetDoor(DoorSlot.DOWN0) then
		    room:GetDoor(DoorSlot.DOWN0):ToDoor():SetLocked(true)
		end
		
		if (roomDesc.GridIndex + 1) % 13 == 0 and room:GetDoor(DoorSlot.LEFT0) then
		    room:GetDoor(DoorSlot.LEFT0):ToDoor():SetLocked(true)
		elseif roomDesc.GridIndex % 13 == 0 and room:GetDoor(DoorSlot.RIGHT0) then
		    room:GetDoor(DoorSlot.RIGHT0):ToDoor():SetLocked(true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.Room)

function mod:Level()
	local level = Game():GetLevel()
	if not Game():IsGreedMode() and not level:IsAscent() then
		if level:GetStageType() == StageType.STAGETYPE_REPENTANCE then
			if level:GetStage() == LevelStage.STAGE3_1 or level:GetStage() == LevelStage.STAGE3_2 then
				if level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH == 0 then
					mod:Init()
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.Level)
