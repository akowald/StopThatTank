/**
 * ==============================================================================
 * Stop that Tank!
 * Copyright (C) 2014-2015 Alex Kowald
 * ==============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/** 
 * Note: Do NOT compile this file alone. Compile tank.sp.
 *
 * Purpose: This file contains functions that support tank, giant robot, and sentry buster spawning during gameplay.
 */

#if !defined STT_MAIN_PLUGIN
#error This plugin must be compiled from tank.sp
#endif

int g_iNumGiantSpawns[MAX_TEAMS][MAX_NUM_TEMPLATES];

void Spawner_Cleanup(int client=-1)
{
	if(client == -1)
	{
		// Clear everything
		for(int i=0; i<MAXPLAYERS+1; i++)
		{
			Spawner_CleanupData(i);
		}
	}else{
		Spawner_CleanupData(client);

		if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		{
			SetEntityRenderMode(client, RENDER_NORMAL);
			SetEntityRenderColor(client);
		}
	}
}

void Spawner_CleanupData(int client)
{
	g_nSpawner[client][g_bSpawnerEnabled] = false;
	Spawner_KillTimer(client);
	g_nSpawner[client][g_flSpawnerTimeSpawned] = 0.0;
	g_nSpawner[client][g_iSpawnerFlags] = 0;
	Spawner_KillEntity(client);
}

void Spawner_KillEntity(int client)
{
	if(g_nSpawner[client][g_iSpawnerExtraEnt] != 0)
	{
		int entity = EntRefToEntIndex(g_nSpawner[client][g_iSpawnerExtraEnt]);
		if(entity > MaxClients)
		{
			AcceptEntityInput(entity, "Kill");
		}

		g_nSpawner[client][g_iSpawnerExtraEnt] = 0;
	}
}

void Spawner_KillTimer(int client)
{
	if(g_nSpawner[client][g_hSpawnerTimer] != INVALID_HANDLE)
	{
		KillTimer(g_nSpawner[client][g_hSpawnerTimer]);
		g_nSpawner[client][g_hSpawnerTimer] = INVALID_HANDLE;
	}
}

bool Spawner_HasGiantTag(int client, int iTag)
{
	return g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & iTag;
}

void Spawner_CheckGiantSpawns(int team, int pointIndex, float pos[3], float ang[3])
{
	int length = g_giantSpawns.Length;
	int giantSpawn[ARRAY_GIANTSPAWN_SIZE];
	for(int i=0; i<length; i++)
	{
		g_giantSpawns.GetArray(i, giantSpawn, sizeof(giantSpawn));

		if(giantSpawn[GiantSpawnArray_Team] != 0 && giantSpawn[GiantSpawnArray_Team] != team) continue; // Meant for another team.
		if(pointIndex != -1 && giantSpawn[GiantSpawnArray_PointIndex] != pointIndex) continue; // Meant for another control point index.
#if defined DEBUG
		PrintToServer("(Spawner_CheckGiantSpawns) Overrided with team = %d, index = %d!", giantSpawn[GiantSpawnArray_Team], giantSpawn[GiantSpawnArray_PointIndex]);
#endif
		// Override where the giant will spawn.
		for(int a=0; a<3; a++)
		{
			pos[a] = view_as<float>(giantSpawn[GiantSpawnArray_Origin+a]);
			ang[a] = view_as<float>(giantSpawn[GiantSpawnArray_Angles+a]);
		}

		return;
	}
}

void Spawner_SaveSpawnPosition(int client, eSpawnerType spawnType)
{
	// Gets the spawn position of the object and saves it for later.
	int team = GetClientTeam(client);
	float pos[3];
	float ang[3];

	for(int i=0; i<3; i++)
	{
		g_nSpawner[client][g_flSpawnerPos][i] = 0.0;
		g_nSpawner[client][g_flSpawnerAng][i] = 0.0;		
	}

	// The tank will always spawn where the cart resides.
	if(spawnType == Spawn_Tank)
	{
		int trackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
		if(trackTrain > MaxClients)
		{
			GetEntPropVector(trackTrain, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(trackTrain, Prop_Send, "m_angRotation", ang);

			for(int i=0; i<3; i++)
			{
				g_nSpawner[client][g_flSpawnerPos][i] = pos[i];
				g_nSpawner[client][g_flSpawnerAng][i] = ang[i];
			}
		}

		return;
	}

	// Find a spawn position in hell on plr_hightower_event.
	if(spawnType == Spawn_GiantRobot && g_nMapHack == MapHack_HightowerEvent && g_hellTeamWinner > 0)
	{
		char targetName[32] = "spawn_loot_loser";
		if(g_hellTeamWinner == team) targetName = "spawn_loot_winner";

		if(strcmp(targetName, "spawn_loot_winner") == 0)
		{
			// In an effort to give some kind of reward for winning the payload race, spawn the winning team's giant a little closer to the gate.
			g_nSpawner[client][g_flSpawnerPos][0] = -1896.09;
			g_nSpawner[client][g_flSpawnerPos][1] = -294.79;
			g_nSpawner[client][g_flSpawnerPos][2] = -8384.29;
			g_nSpawner[client][g_flSpawnerAng][0] = 0.0;
			g_nSpawner[client][g_flSpawnerAng][1] = 173.77;
			g_nSpawner[client][g_flSpawnerAng][2] = 0.0;

			return;
		}else{
			ArrayList list = new ArrayList();

			int marker = MaxClients+1;
			while((marker = FindEntityByClassname(marker, "info_target")) > MaxClients)
			{
				char name[sizeof(targetName)];
				GetEntPropString(marker, Prop_Data, "m_iName", name, sizeof(name));

				if(strcmp(targetName, name) == 0)
				{
					list.Push(marker);
				}
			}

			if(list.Length > 0)
			{
				marker = list.Get(GetRandomInt(0, list.Length-1));

				GetEntPropVector(marker, Prop_Send, "m_vecOrigin", pos);
				GetEntPropVector(marker, Prop_Send, "m_angRotation", ang);

				for(int i=0; i<3; i++)
				{
					g_nSpawner[client][g_flSpawnerPos][i] = pos[i];
					g_nSpawner[client][g_flSpawnerAng][i] = ang[i];
				}

				delete list;
				return;
			}

			delete list;
		}
	}

	// For the RED team on payload maps:
	// Go through the control points of the BLUE team sequentially. The first captured control point by the RED team will be chosen.
	if(g_nGameMode != GameMode_Race && team == TFTeam_Red)
	{
		int linkedTeam = TFTeam_Blue;
		for(int i=0; i<MAX_LINKS; i++)
		{
			if(g_iRefLinkedCPs[linkedTeam][i] == 0 || g_iRefLinkedPaths[linkedTeam][i] == 0) continue; // non-existant

			int controlPoint = EntRefToEntIndex(g_iRefLinkedCPs[linkedTeam][i]);
			int pathTrack = EntRefToEntIndex(g_iRefLinkedPaths[linkedTeam][i]);
			if(controlPoint <= MaxClients || pathTrack <= MaxClients) continue;

			if(GetEntProp(controlPoint, Prop_Data, "m_iTeamNum") != team) continue; // Control point isn't owned by the spawning player.

#if defined DEBUG
			PrintToServer("(Spawner_SaveSpawnPosition) RED on payload: Control point #%d chosen.", i);
#endif
			GetEntPropVector(pathTrack, Prop_Send, "m_vecOrigin", pos);
			Path_GetOrientation(pathTrack, ang, true);
			Spawner_CheckGiantSpawns(linkedTeam, i+1, pos, ang);

			for(int a=0; a<3; a++)
			{
				g_nSpawner[client][g_flSpawnerPos][a] = pos[a];
				g_nSpawner[client][g_flSpawnerAng][a] = ang[a];
			}

			return;
		}
	}else{
		// For payload race maps and BLUE team on payload.
		// Go through the control points backwards. The first capture point that isn't start or goal and is more than tank_distance_move is chosen from the goal is chosen.
		int pathGoal = EntRefToEntIndex(g_iRefPathGoal[team]);
		if(pathGoal > MaxClients)
		{
			for(int i=MAX_LINKS-1; i>=0; i--)
			{
				if(g_iRefLinkedCPs[team][i] == 0 || g_iRefLinkedPaths[team][i] == 0) continue; // non-existant
				if(g_iRefLinkedCPs[team][i] == g_iRefControlPointGoal[team]) continue; // Bypass the final control point (the goal)

				int controlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
				int pathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][i]);
				if(controlPoint <= MaxClients || pathTrack <= MaxClients) continue;
				
				if(GetEntProp(controlPoint, Prop_Data, "m_iTeamNum") != team) continue; // Control point isn't owned by the spawning player.

				float distanceToGoal = Path_GetDistance(pathTrack, pathGoal);
				float maxDistance = config.LookupFloat(g_hCvarDistanceMove);
				if(distanceToGoal > maxDistance)
				{
#if defined DEBUG
					PrintToServer("(Spawner_SaveSpawnPosition) Payload race or BLU on payload: Control point #%d: Distance to goal: %0.1f/%0.1f", i, distanceToGoal, maxDistance);
#endif
					GetEntPropVector(pathTrack, Prop_Send, "m_vecOrigin", pos);
					Path_GetOrientation(pathTrack, ang);
					Spawner_CheckGiantSpawns(team, i+1, pos, ang);

					for(int a=0; a<3; a++)
					{
						g_nSpawner[client][g_flSpawnerPos][a] = pos[a];
						g_nSpawner[client][g_flSpawnerAng][a] = ang[a];
					}

					return;
				}
			}
		}
	}

	// Fallback on spawning at the start path track node.
	int teams[2];
	teams[0] = team;
	teams[1] = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
	for(int i=0; i<sizeof(teams); i++)
	{
		int startPath = EntRefToEntIndex(g_iRefPathStart[teams[i]]);
		if(startPath > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Spawner_SaveSpawnPosition) Chose start path, team = %d!", teams[i]);
#endif		
			GetEntPropVector(startPath, Prop_Send, "m_vecOrigin", pos);
			Path_GetOrientation(startPath, ang);
			Spawner_CheckGiantSpawns(teams[i], 0, pos, ang);

			for(int a=0; a<3; a++)
			{
				g_nSpawner[client][g_flSpawnerPos][a] = pos[a];
				g_nSpawner[client][g_flSpawnerAng][a] = ang[a];
			}

			return;
		}
	}

	LogMessage("Failed to find spawn position for giant! Make sure 'sm_makegiant' is used after tanks spawn.");
}

void Spawner_GetSpawnPosition(int client, float pos[3], float ang[3])
{
	for(int i=0; i<3; i++)
	{
		pos[i] = g_nSpawner[client][g_flSpawnerPos][i];
		ang[i] = g_nSpawner[client][g_flSpawnerAng][i];
	}
}

void Spawner_Spawn(int client, eSpawnerType spawnType, int giantType=-1, int flags=0)
{
	if(spawnType == Spawn_GiantRobot && giantType < 0 || giantType >= MAX_NUM_TEMPLATES || !g_nGiants[giantType][g_bGiantTemplateEnabled])
	{
		LogMessage("Invalid giant robot template index %d (type %d) specified! Are too many templates disabled/missing?", giantType, view_as<int>(spawnType));
		return;
	}

	if(spawnType == Spawn_GiantRobot)
	{
		if(client < 1 || client > MaxClients || !IsClientInGame(client))
		{
			LogMessage("Invalid client index %d: not a player!", client);
			return;
		}
		int team = GetClientTeam(client);
		if(team != TFTeam_Red && team != TFTeam_Blue)
		{
			LogMessage("Invalid client index %d: not on RED or BLU!", client);
			return;
		}

		// If the player is already a giant robot, we need to force a suicide to clear them
		if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
		{
#if defined DEBUG
			PrintToServer("(Spawner_Spawn) %N is already a giant, clearing them now..", client);
#endif
			Giant_Clear(client);
			ForcePlayerSuicide(client);
		}
	}

	if(spawnType == Spawn_Tank && client != 0)
	{
		LogMessage("Invalid client index %d: must be 0 for tank!", client);
		return;
	}

	Spawner_Cleanup(client);

	g_nSpawner[client][g_bSpawnerEnabled] = true;
	g_nSpawner[client][g_nSpawnerType] = spawnType;
	g_nSpawner[client][g_iSpawnerFlags] = flags;

	if(spawnType == Spawn_GiantRobot)
	{
		if(g_nGiants[giantType][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
		{
			g_flTimeBusterTaunt[client] = 0.0;
		}

		g_nSpawner[client][g_iSpawnerGiantIndex] = giantType;
	}

	// Save the position to spawn the player at
	Spawner_SaveSpawnPosition(client, spawnType);
	float flPos[3];
	float flAng[3];
	Spawner_GetSpawnPosition(client, flPos, flAng);

	float flTime = 4.0;
	if(spawnType == Spawn_GiantRobot && g_nGiants[giantType][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) flTime = 1.9;
	if(!(g_nSpawner[client][g_iSpawnerFlags] & SPAWNERFLAG_NOPUSHAWAY)) PushAway_Create(flPos, flTime);

	// Spawn a particle effect to make it clear they are being pushed
	int iEntity = CreateEntityByName("info_particle_system");
	if(iEntity > MaxClients)
	{
		TeleportEntity(iEntity, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iEntity, "effect_name", "merasmus_spawn");
		
		DispatchSpawn(iEntity);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		
		CreateTimer(4.0, Timer_EntityCleanup, EntIndexToEntRef(iEntity));
	}

	// Start a timer to spawn in the object when ready
	Spawner_KillTimer(client);
	g_nSpawner[client][g_hSpawnerTimer] = CreateTimer(2.0, Spawner_Timer_Spawn, client, TIMER_REPEAT);
}

public Action Spawner_Timer_Spawn(Handle hTimer, any client)
{
	g_nSpawner[client][g_flSpawnerTimeSpawned] = GetEngineTime();
	float flTime = 3.0;
	// Now that the area is clear, the object will be spawned and teleported into the game
	switch(g_nSpawner[client][g_nSpawnerType])
	{
		case Spawn_Tank:
		{
			// Spawns a new tank where the cart resides
			int iTank = Tank_CreateTank(TFTeam_Blue);
			if(iTank > MaxClients)
			{
				g_iRefTank[TFTeam_Blue] = EntIndexToEntRef(iTank);
				
				Tank_SetNoTarget(TFTeam_Blue, true);
				
				// Find the tracks associated with this tank
				Tank_FindParts(TFTeam_Blue);
			}
		}
		case Spawn_GiantRobot:
		{
			int team = GetClientTeam(client);
			// If for some reason the player isn't on RED or BLU anymore, abort spawn
			if(team != TFTeam_Red && team != TFTeam_Blue)
			{
				g_nSpawner[client][g_hSpawnerTimer] = INVALID_HANDLE;
				Spawner_Cleanup(client);
				return Plugin_Stop;
			}

			g_iNumGiantSpawns[team][g_nSpawner[client][g_iSpawnerGiantIndex]]++;

			// Show a hint a few seconds after the giant has spawned.
			if(strlen(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_strGiantHint]) > 0)
			{
				CreateTimer(5.0, Timer_ShowHint, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
			}

			// If the player is carrying the bomb, drop it before spawning them.
			if(g_nGameMode == GameMode_BombDeploy)
			{
				int bomb = EntRefToEntIndex(g_iRefBombFlag);
				if(bomb > MaxClients && GetEntPropEnt(bomb, Prop_Send, "moveparent") == client)
				{
					AcceptEntityInput(bomb, "ForceDrop");
				}
			}

			// Spawns a giant robot in the cached spawn position
			float flPos[3];
			float flAng[3];
			float flVel[3];
			Spawner_GetSpawnPosition(client, flPos, flAng);

			if(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
			{
				// Turn the player into a sentry buster
				Giant_MakeGiantRobot(client, g_nSpawner[client][g_iSpawnerGiantIndex]);

				// Any wearable looks out of place on the sentry buster
				Giant_StripWearables(client);

				// Teleport the player into position
				TeleportEntity(client, flPos, flAng, flVel);

				// Set the player's movetype to none so the point_push won't affect them
				SetEntityMoveType(client, MOVETYPE_NONE);

				// Put the player into third person while they can't move
				// Doing this on a timer because doing it right after spawn seems to have no effect
				CreateTimer(0.2, Timer_GiantThirdperson, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

				// Make the player invincible while they can't move
				TF2_AddCondition(client, TFCond_UberchargedHidden, 5.0);
				// Catch death on the sentry buster and have them self-destruct instead
				TF2_AddCondition(client, TFCond_PreventDeath, -1.0);

				// Play a short intro sound
				EmitSoundToAll(SOUND_BUSTER_START, client);

				// There is no RED skin for the sentry buster so color it RED instead
				if(GetClientTeam(client) == TFTeam_Red)
				{
					SetEntityRenderMode(client, RENDER_TRANSCOLOR);
					SetEntityRenderColor(client, 255, 0, 0);
				}

				// Create a glow entity for the sentry buster
				Spawner_KillEntity(client);
				int glow = BusterVision_Create(client);
				if(glow > MaxClients)
				{
					g_nSpawner[client][g_iSpawnerExtraEnt] = EntIndexToEntRef(glow);
				}

				flTime = 1.0;	
			}else{
				// Applies giant effects and spawns them on the cart
				Giant_MakeGiantRobot(client, g_nSpawner[client][g_iSpawnerGiantIndex]);
				
				// Teleport the giant to the saved location
				TeleportEntity(client, flPos, flAng, flVel);

				// Set the player's movetype to none so the point_push won't affect them
				SetEntityMoveType(client, MOVETYPE_NONE);
				
				// Put the player into third person while they can't move
				// Doing this on a timer because doing it right after spawn seems to have no effect
				CreateTimer(0.2, Timer_GiantThirdperson, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

				// Make the player invincible while they can't move
				TF2_AddCondition(client, TFCond_UberchargedHidden, 5.0);
				
				// Have the giant play a little voiceline when they spawn
				int iIndexClass = view_as<int>(TF2_GetPlayerClass(client));
				if(iIndexClass >= 1 && iIndexClass <= 9 && strlen(g_strSoundGiantSpawn[iIndexClass]) > 3)
				{
					EmitSoundToAll(g_strSoundGiantSpawn[iIndexClass], client, SNDCHAN_VOICE, 95, 0, 0.81, 100);
				}

				// Force the player to carry the the bomb
				if(g_nGameMode == GameMode_BombDeploy && TeamGiant_IsPlayer(client))
				{
					int iBomb = EntRefToEntIndex(g_iRefBombFlag);
					if(iBomb > MaxClients)
					{
						SDK_PickUp(iBomb, client);
					}

					if(!(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_CAN_DROP_BOMB))
					{
						// Run this again to make sure the giant picks up the bomb.
						CreateTimer(3.0, Timer_GiantBombPickup, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}

				// Giants in plr_ show an outline to all players indicating their health
				if(g_nGameMode == GameMode_Race && iIndexClass != view_as<int>(TFClass_Spy))
				{
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
				}

				if(g_nSpawner[client][g_iSpawnerFlags] & SPAWNERFLAG_RAGEMETER)
				{
					RageMeter_Enable(client);
				}

				// Create a glow entity for when the Super Spy drops his bomb
				if(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_CAN_DROP_BOMB)
				{
					Spawner_KillEntity(client);
					int glow = BusterVision_Create(client, true);
					if(glow > MaxClients)
					{
						g_nSpawner[client][g_iSpawnerExtraEnt] = EntIndexToEntRef(glow);
					}
				}
			}

			if(g_nMapHack == MapHack_HightowerEvent && g_hellTeamWinner > 0)
			{
				// Roll a common spell on the giant
				// An alternative is to call CTFSpellBook::RollNewSpell
				int spell = CreateEntityByName("tf_spell_pickup");
				if(spell > MaxClients)
				{
					DispatchSpawn(spell);
					
					flPos[2] += 50.0;
					TeleportEntity(spell, flPos, NULL_VECTOR, NULL_VECTOR);
					SetEntityMoveType(spell, MOVETYPE_NONE);

					CreateTimer(1.0, Timer_EntityCleanup, EntIndexToEntRef(spell));
				}
			}

			// Check the spawn position of the giant to see if they are stuck.
			GetClientAbsOrigin(client, flPos);
			float mins[3];
			float maxs[3];
			GetClientMins(client, mins);
			GetClientMaxs(client, maxs);
			int mask = MASK_RED;
			if(team != TFTeam_Red) mask = MASK_BLUE;

			TR_TraceHullFilter(flPos, flPos, mins, maxs, mask, TraceEntityFilter_NotTeam, team);
			if(TR_DidHit())
			{
#if defined DEBUG
				PrintToServer("(Spawner_Timer_Spawn) Giant %N might be stuck..", client);
#endif
				Player_FindFreePosition2(client, flPos, mins, maxs);
			}
		}
	}

	g_nSpawner[client][g_hSpawnerTimer] = CreateTimer(flTime, Spawner_Timer_Active, client, TIMER_REPEAT);
	return Plugin_Stop;
}

int Spawner_CountSpawnsWithTag(int team, int iTags)
{
	int iCount = 0;
	for(int i=0; i<MAX_NUM_TEMPLATES; i++)
	{
		if(g_nGiants[i][g_iGiantTags] & iTags) iCount += g_iNumGiantSpawns[team][i];
	}
	return iCount;
}

public Action Spawner_Timer_Active(Handle hTimer, any client)
{
	switch(g_nSpawner[client][g_nSpawnerType])
	{
		case Spawn_GiantRobot:
		{
			int team = GetClientTeam(client);
			bool bIsTeamGiant = TeamGiant_IsPlayer(client);
			if(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
			{
				// Enable player movement
				SetEntityMoveType(client, MOVETYPE_WALK);

				SetVariantInt(1);
				AcceptEntityInput(client, "SetForcedTauntCam");

				if(g_nGameMode == GameMode_Race)
				{
					// Play announcer sound to just the enemy team in plr_
					if(Spawner_CountSpawnsWithTag(team, GIANTTAG_SENTRYBUSTER) > 1)
					{
						BroadcastSoundToEnemy(team, "Announcer.MVM_Sentry_Buster_Alert_Another");
					}else{
						BroadcastSoundToEnemy(team, "Announcer.MVM_Sentry_Buster_Alert_Another");
					}
				}else{
					// Goes out to all teams in pl_
					if(Spawner_CountSpawnsWithTag(team, GIANTTAG_SENTRYBUSTER) > 1)
					{
						BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Sentry_Buster_Alert_Another");
					}else{
						BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Sentry_Buster_Alert");
					}					
				}

				// Start the loop sentry buster sound
				EmitSoundToAll(SOUND_BUSTER_LOOP, client, SNDCHAN_AUTO, _, _, 1.0);
				//EmitSoundToAll(SOUND_BUSTER_LOOP, client, SNDCHAN_AUTO, SNDLEVEL_RUSTLE, SND_CHANGEVOL, 1.0);

				// Spawn a helpful annotation letting the player know how to use the sentry buster.
				if(!IsFakeClient(client))
				{
					Handle hEvent = CreateEvent("show_annotation");
					if(hEvent != INVALID_HANDLE)
					{
						float flPosAnnotation[3];

						float flPosEye[3];
						float flAngEye[3];
						GetClientEyePosition(client, flPosEye);
						GetClientEyeAngles(client, flAngEye);
						GetPositionForward(flPosEye, flAngEye, flPosAnnotation, 1100.0);

						SetEventFloat(hEvent, "worldPosX", flPosAnnotation[0]);
						SetEventFloat(hEvent, "worldPosY", flPosAnnotation[1]);
						SetEventFloat(hEvent, "worldPosZ", flPosAnnotation[2]);

						SetEventInt(hEvent, "visibilityBitfield", (1 << client));

						if(team == TFTeam_Red)
						{
							SetEventInt(hEvent, "id", Annotation_BusterHintRed);
						}else{
							SetEventInt(hEvent, "id", Annotation_BusterHintBlue);
						}

						SetEventFloat(hEvent, "lifetime", 4.0);

						char text[256];
						Format(text, sizeof(text), "%T", "Tank_Annotation_Buster_Hint", client);
						SetEventString(hEvent, "text", text);

						SetEventString(hEvent, "play_sound", "misc/null.wav");

						FireEvent(hEvent); // Frees the handle
					}
				}
			}else{
				SetEntityMoveType(client, MOVETYPE_WALK);
				
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");

				// Play loop sound
				if(!Spawner_HasGiantTag(client, GIANTTAG_NO_LOOP_SOUND)) EmitSoundToAll(g_strSoundGiantLoop[TF2_GetPlayerClass(client)], client, SNDCHAN_AUTO, _, _, 0.50);

				if(g_lastPlayedWarning == 0.0 || GetEngineTime() - g_lastPlayedWarning > 2.0)
				{
					EmitSoundToAll(SOUND_WARNING);
					g_lastPlayedWarning = GetEngineTime();
				}

				// Show an annotation to let everyone that the giant has spawned
				if(bIsTeamGiant)
				{
					// Play announcer sounds
					if(g_nGameMode != GameMode_Race)
					{
						if(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_nGiantClass] == TFClass_Engineer)
						{
							BroadcastSoundToEnemy(team, g_strSoundEngieBotAppearedEnemy[GetRandomInt(0, sizeof(g_strSoundEngieBotAppearedEnemy)-1)]);
							BroadcastSoundToTeam(team, g_strSoundEngieBotAppearedTeam[GetRandomInt(0, sizeof(g_strSoundEngieBotAppearedTeam)-1)]);
						}else{
							BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Bomb_Alert_Entered");
						}
					}

					Handle hEvent = CreateEvent("show_annotation");
					if(hEvent != INVALID_HANDLE)
					{			
						char text[256];
						if(g_nGameMode == GameMode_Race)
						{
							Format(text, sizeof(text), "%T", "Tank_Annotation_Giant_Spawned", LANG_SERVER, g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_strGiantName]);
						}else{
							Format(text, sizeof(text), "%T", "Tank_Annotation_Giant_Spawned_BombDeploy", LANG_SERVER, g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_strGiantName]);
						}
						SetEventString(hEvent, "text", text);

						// Show to everyone but the giant
						int iBits = 1;
						for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && i != client) iBits |= (1 << i);
						SetEventInt(hEvent, "visibilityBitfield", iBits);
						
						// Put message at the cart where the bomb will spawn
						float flPos[3];
						int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[TFTeam_Blue]);
						if(iTrackTrain > MaxClients)
						{
							GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPos);
						}
						SetEventFloat(hEvent, "worldPosX", g_nSpawner[client][g_flSpawnerPos][0]);
						SetEventFloat(hEvent, "worldPosY", g_nSpawner[client][g_flSpawnerPos][1]);
						SetEventFloat(hEvent, "worldPosZ", g_nSpawner[client][g_flSpawnerPos][2]);

						if(team == TFTeam_Red)
						{
							SetEventInt(hEvent, "id", Annotation_GiantSpawnedRed);
						}else{
							SetEventInt(hEvent, "id", Annotation_GiantSpawnedBlue);
						}
						
						SetEventFloat(hEvent, "lifetime", 5.0);
						
						SetEventString(hEvent, "play_sound", "misc/null.wav");
						
						FireEvent(hEvent); // Frees the handle
					}

					if(g_nGameMode == GameMode_BombDeploy && !g_nTeamGiant[team][g_bTeamGiantNoCritCash])
					{
						CritCash_RemoveEffects(); // Remove the crit cash effects from all players.
						g_nTeamGiant[team][g_bTeamGiantNoCritCash] = true;
					}
				}
			}
		}
	}

	g_nSpawner[client][g_hSpawnerTimer] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Timer_GiantThirdperson(Handle hTimer, any iUserId)
{
	int iGiant = GetClientOfUserId(iUserId);
	if(iGiant >= 1 && iGiant <= MaxClients && IsClientInGame(iGiant) && IsPlayerAlive(iGiant) && GetEntProp(iGiant, Prop_Send, "m_bIsMiniBoss"))
	{
		SetVariantInt(1);
		AcceptEntityInput(iGiant, "SetForcedTauntCam");
	}
	
	return Plugin_Handled;
}

public Action Timer_GiantBombPickup(Handle timer, any ref)
{
	int client = EntRefToEntIndex(ref);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot
		&& TeamGiant_IsPlayer(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		int bomb = EntRefToEntIndex(g_iRefBombFlag);
		if(bomb > MaxClients && GetEntPropEnt(bomb, Prop_Send, "moveparent") != client)
		{
			SDK_PickUp(bomb, client);
		}		
	}

	return Plugin_Handled;
}