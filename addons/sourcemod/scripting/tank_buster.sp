/**
 * ==============================================================================
 * Stop that Tank!
 * Copyright (C) 2014-2017 Alex Kowald
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
 * Purpose: This file contains functions that support sentry busters.
 */


#if !defined STT_MAIN_PLUGIN
#error This plugin must be compiled from tank.sp
#endif

enum eSentryVisionStruct
{
	Handle:g_hSentryVisionList,			// List of all obj_sentrygun entities that are being watched
};
int g_nSentryVision[eSentryVisionStruct];

bool g_hitBySentryBuster[MAXPLAYERS+1];

enum eBusterStruct
{
	bool:g_bBusterActive, // Whether or not to run the buster logic and choose/spawn another buster
	g_iBusterQueuedUserId, // Userid of the queued sentry buster
	// 3 conditions to be met in order for a sentry buster to be spawned
	g_iBusterTriggerTankBySentry, // Damage dealt to the tank by a sentry
	g_iBusterTriggerGiantBySentry, // Damage dealt to the giant by a sentry
	g_iBusterTriggerRobotsBySentry, // Damage dealt to normal robots by a sentry
	Float:g_flBusterTimeWarned, // Time when the queued sentry buster is warned
	Float:g_flBusterTriggerTimer, // Timer to bring out the sentry buster
	g_iBusterNumSentOut, // Number of sentry busters spawned during the round
	Float:g_flBusterTimeLastThink, // Time when the last think occurred, used for the buster timer trigger
	bool:g_bBusterTimerStarted, // Flag when the buster timer has been started
	bool:g_bBusterNoticeSent, // Flag when the user has been notified.
};
int g_nBuster[MAX_TEAMS][eBusterStruct];

enum
{
	BusterStat_Tank=0,
	BusterStat_Giant,
	BusterStat_Robots
};

void Buster_Cleanup(int team)
{
	g_nBuster[team][g_bBusterActive] = false;
	g_nBuster[team][g_iBusterQueuedUserId] = 0;
	g_nBuster[team][g_flBusterTimeWarned] = 0.0;
	g_nBuster[team][g_iBusterNumSentOut] = 0;
	g_nBuster[team][g_flBusterTimeLastThink] = 0.0;
	g_nBuster[team][g_bBusterTimerStarted] = false;

	g_nBuster[team][g_iBusterTriggerGiantBySentry] = 0;
	g_nBuster[team][g_iBusterTriggerRobotsBySentry] = 0;
	g_nBuster[team][g_iBusterTriggerTankBySentry] = 0;
	g_nBuster[team][g_flBusterTriggerTimer] = 0.0;
}

int Buster_PickPlayer(int team, int dontConsider=-1)
{
	Handle hArrayPlayers = CreateArray();
	Handle hArrayPlayersAux = CreateArray();

	// Picks a random player to become the sentry buster
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && !g_nSpawner[i][g_bSpawnerEnabled])
		{
			// Check if the player is already selected to be the giant robot
			if(g_nTeamGiant[team][g_bTeamGiantActive] && GetClientUserId(i) == g_nTeamGiant[team][g_iTeamGiantQueuedUserId]) continue;

			// Check if the player is already spawning as a giant
			if(g_nSpawner[i][g_bSpawnerEnabled]) continue;

			// Player has already passed this round
			if(g_bBusterPassed[i]) continue;

			PushArrayCell(hArrayPlayersAux, i);

			// Player has already been a sentry buster this round
			if(g_bBusterUsed[i]) continue;

			// Temporarily don't consider this given player.
			if(dontConsider == i) continue;

			PushArrayCell(hArrayPlayers, i);
		}
	}

	int iRandomPlayer = 0;

	if(GetArraySize(hArrayPlayers) > 0)
	{
		iRandomPlayer = GetArrayCell(hArrayPlayers, GetRandomInt(0, GetArraySize(hArrayPlayers)-1));
	}else{
		// Chooses players that has already been the sentry buster if there is no one left.
		if(GetArraySize(hArrayPlayersAux) > 0)
		{
			iRandomPlayer = GetArrayCell(hArrayPlayersAux, GetRandomInt(0, GetArraySize(hArrayPlayersAux)-1));
		}
	}

	CloseHandle(hArrayPlayers);
	CloseHandle(hArrayPlayersAux);

	return iRandomPlayer;
}

void Buster_QueuePlayer(int team, int client)
{
	PrintCenterText(client, "%t", "Tank_Center_Buster_YouAreNext");

	// Show who will become the next buster to one team.
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			PrintToChat(i, "%t", "Tank_Chat_Buster_Queued", 0x01, g_strTeamColors[team], 0x01, g_strTeamColors[team], client, 0x01);
		}
	}

	g_nBuster[team][g_iBusterQueuedUserId] = GetClientUserId(client);
	// Whenever a new player is selected, reset the warn period
	g_nBuster[team][g_flBusterTimeWarned] = 0.0;	
}

bool Buster_IsMedicExempt(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Medic) return false;

	// Any uber charge above a certain amount.
	int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
	if(medigun > MaxClients)
	{
		char className[32];
		GetEdictClassname(medigun, className, sizeof(className));
		if(strcmp(className, "tf_weapon_medigun") == 0)
		{
			if(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") >= config.LookupFloat(g_hCvarBusterExemptMedicUber)) return true;
		}
	}

	// The medic has healed a giant in the last 5 seconds.
	if(g_timeLastHealedGiant[client] != 0.0 && GetEngineTime() - g_timeLastHealedGiant[client] < 5.0) return true;

	return false;
}

bool Buster_IsUberExempt(int client)
{
	// The player is under any kind of uber effects.
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_MegaHeal)
			|| TF2_IsPlayerInCondition(client, TFCond_UberBulletResist) || TF2_IsPlayerInCondition(client, TFCond_UberBlastResist) || TF2_IsPlayerInCondition(client, TFCond_UberFireResist));
}

bool Buster_IsDemoExempt(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_DemoMan) return false;

	// The player has 3 or more eyelander kills.
	return (TF2_IsPlayerInCondition(client, TFCond_DemoBuff) && GetEntProp(client, Prop_Send, "m_iDecapitations") >= 3);
}

bool Buster_IsEngieExempt(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Engineer) return false;

	// Any level 3 building or both teleporters built.
	int building = MaxClients+1;
	while((building = FindEntityByClassname(building, "obj_sentrygun")) > MaxClients)
	{
		if(GetEntPropEnt(building, Prop_Send, "m_hBuilder") == client)
		{
			if(GetEntProp(building, Prop_Send, "m_iUpgradeLevel") == 3)
			{
				return true;
			}
		}
	}

	building = MaxClients+1;
	while((building = FindEntityByClassname(building, "obj_dispenser")) > MaxClients)
	{
		if(GetEntPropEnt(building, Prop_Send, "m_hBuilder") == client)
		{
			if(GetEntProp(building, Prop_Send, "m_iUpgradeLevel") == 3)
			{
				return true;
			}
		}
	}

	building = MaxClients+1;
	bool hasEntrance = false;
	bool hasExit = false;
	while((building = FindEntityByClassname(building, "obj_teleporter")) > MaxClients)
	{
		if(GetEntPropEnt(building, Prop_Send, "m_hBuilder") == client)
		{
			if(GetEntProp(building, Prop_Send, "m_iUpgradeLevel") == 3)
			{
				return true;
			}

			TFObjectMode mode = view_as<TFObjectMode>(GetEntProp(building, Prop_Send, "m_iObjectMode"));
			if(mode == TFObjectMode_Entrance) hasEntrance = true;
			else if(mode == TFObjectMode_Exit) hasExit = true;

			if(hasEntrance && hasExit) return true;
		}
	}

	return false;
}

void Buster_Think(int team)
{
	float flCurrentTime = GetEngineTime();

	// Not active yet - in between rounds
	if(!g_nBuster[team][g_bBusterActive]) return;

	// Ensure that there is a valid person queued up to become the sentry buster
	int client = 0;
	bool bIsValid = false;
	if(g_nBuster[team][g_iBusterQueuedUserId] != 0)
	{
		// Check if the queued player is still valid
		client = GetClientOfUserId(g_nBuster[team][g_iBusterQueuedUserId]);
		if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team && !g_nSpawner[client][g_bSpawnerEnabled] && !g_bBusterPassed[client]
			&& !(g_nTeamGiant[team][g_bTeamGiantActive] && g_nTeamGiant[team][g_iTeamGiantQueuedUserId] == g_nBuster[team][g_iBusterQueuedUserId]))
		{
			bIsValid = true;
		}else{
			g_nBuster[team][g_iBusterQueuedUserId] = 0;
		}
	}

	if(!bIsValid)
	{
		// Choose another player to become the sentry buster
		client = Buster_PickPlayer(team);
		if(client >= 1 && client <= MaxClients)
		{
			Buster_QueuePlayer(team, client);
		}

		return; // for simplicity
	}

	if(!g_bIsRoundStarted)
	{
		// We are in intermission so don't spawn a buster
		return;
	}

	int oppositeTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
	if(g_nBuster[team][g_bBusterTimerStarted] && g_nBuster[team][g_flBusterTimeLastThink] != 0.0)
	{
		if(Buster_GetNumActiveSentries(oppositeTeam) == 0)
		{
			// The buster timer should be paused
			// Enforce a minimum time when the buster timer becomes paused
			float flMinPause = config.LookupFloat(g_hCvarBusterTimePause);
			if(g_nBuster[team][g_flBusterTriggerTimer] < flMinPause)
			{
				g_nBuster[team][g_flBusterTriggerTimer] = flMinPause;
			}
		}else{
			// The buster timer is not paused
			// Decrement the buster timer based on how much time has passed since the last think
			g_nBuster[team][g_flBusterTriggerTimer] -= flCurrentTime - g_nBuster[team][g_flBusterTimeLastThink];
		}
	}

	// Check if the sentry buster is being warned/spawned
	if(g_nBuster[team][g_flBusterTimeWarned] == 0.0)
	{
		// Sentry buster has not been warned yet
		if(Buster_AreConditionsMet(team))
		{
			// Check various sorts of conditions to see if the player is exempt from becoming a sentry buster.
			// If they are exempt, pick another player.
			bool exempt = false;

			// Check if the player is carrying the bomb in pl_.
			char reason[32];
			if(g_nGameMode == GameMode_BombDeploy && g_iRefBombFlag != 0)
			{
				int iBomb = EntRefToEntIndex(g_iRefBombFlag);
				if(iBomb > MaxClients)
				{
					if(GetEntPropEnt(iBomb, Prop_Send, "moveparent") == client)
					{
#if defined DEBUG
						PrintToServer("(Buster_Think) %N is exempt: Has the bomb!", client);
#endif
						exempt = true;
						reason = "carrying bomb";
					}
				}
			}

			// Check if an engineer has both teles built OR at least one level 3 building.
			if(!exempt && Buster_IsEngieExempt(client))
			{
#if defined DEBUG
				PrintToServer("(Buster_Think) %N is exempt: Engie!", client);
#endif
				exempt = true;
				reason = "level 3 or teleporters built";
			}

			// Check if a medic has built up a certain amount of uber charge.
			if(!exempt && Buster_IsMedicExempt(client))
			{
#if defined DEBUG
				PrintToServer("(Buster_Think) %N is exempt: Medic!", client);
#endif
				exempt = true;
				reason = "too much uber or healing giant";
			}

			// Check if the player is currently ubered.
			if(!exempt && Buster_IsUberExempt(client))
			{
#if defined DEBUG
				PrintToServer("(Buster_Think) %N is exempt: Ubered!", client);
#endif
				exempt = true;
				reason = "ubered";
			}

			// Check if the player has eyelander heads.
			if(!exempt && Buster_IsDemoExempt(client))
			{
#if defined DEBUG
				PrintToServer("(Buster_Think) %N is exempt: Demo!", client);
#endif
				exempt = true;
				reason = "3 or more heads";
			}

			if(exempt)
			{
				// Player is exempt so pick another player to become the sentry buster.
				int newBuster = Buster_PickPlayer(team, client);
				if(newBuster >= 1 && newBuster <= MaxClients && client != newBuster) // If we picked the same player, do nothing.
				{
					Buster_QueuePlayer(team, newBuster);

					// Let the player know why he lost his buster slot.
					PrintToChat(client, "%t", "Tank_Chat_Buster_AutoPassed", g_strTeamColors[team], 0x01, 0x04, reason, 0x01);
				}

				return;
			}

			g_nBuster[team][g_flBusterTimeWarned] = flCurrentTime;

			// Prompt the player that they will become a sentry buster in a few minutes so they have time to pass it.
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
					SetEventInt(hEvent, "id", Annotation_BusterWarningRed);
				}else{
					SetEventInt(hEvent, "id", Annotation_BusterWarningBlue);
				}

				SetEventFloat(hEvent, "lifetime", 4.0);

				char strText[256];
				Format(strText, sizeof(strText), "%T", "Tank_Annotation_Buster_Warning", client, config.LookupInt(g_hCvarBusterTimeWarn));
				SetEventString(hEvent, "text", strText);

				SetEventString(hEvent, "play_sound", "misc/null.wav");

				FireEvent(hEvent); // Frees the handle
			}

			PrintToChat(client, "%t", "Tank_Chat_Buster_Warning", 0x01, g_strTeamColors[team], 0x01, 0x04, config.LookupInt(g_hCvarBusterTimeWarn), 0x01, 0x04, 0x01);
		}
	}else{
		// Sentry buster is currently being warned
		if(flCurrentTime - g_nBuster[team][g_flBusterTimeWarned] > config.LookupFloat(g_hCvarBusterTimeWarn))
		{
			// The player has had ample warning so make them a sentry buster
			Spawner_Spawn(client, Spawn_GiantRobot, Buster_PickTemplate());
			
			// Reset all three conditions
			g_nBuster[team][g_iBusterTriggerTankBySentry] = 0;
			g_nBuster[team][g_iBusterTriggerGiantBySentry] = 0;
			g_nBuster[team][g_iBusterTriggerRobotsBySentry] = 0;
			g_nBuster[team][g_flBusterTriggerTimer] = 0.0;
			g_nBuster[team][g_bBusterTimerStarted] = false;

			g_nBuster[team][g_flBusterTimeWarned] = 0.0;
			g_nBuster[team][g_iBusterQueuedUserId] = 0;

			g_bBusterUsed[client] = true; // flag this person so they will not become the buster again for the rest of the round

			g_nBuster[team][g_iBusterNumSentOut]++;
		}
	}
}

void Buster_IncrementStat(int stat, int team, int value)
{
	if(!g_nBuster[team][g_bBusterActive]) return;
	if(!g_bIsRoundStarted) return;

	switch(stat)
	{
		case BusterStat_Tank: g_nBuster[team][g_iBusterTriggerTankBySentry] += value;
		case BusterStat_Giant: g_nBuster[team][g_iBusterTriggerGiantBySentry] += value;
		case BusterStat_Robots: g_nBuster[team][g_iBusterTriggerRobotsBySentry] += value;
	}

	// Prep the "buster timer", a fourth sentry buster trigger
	if(!g_nBuster[team][g_bBusterTimerStarted])
	{
		g_nBuster[team][g_bBusterTimerStarted] = true;

		int oppositeTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
		int numSentries = Buster_GetNumActiveSentries(oppositeTeam);
		// Formula: Buster timer = base - (sentry_multiplier * num_active_sentries)
		if(g_nBuster[team][g_iBusterNumSentOut] == 0)
		{
			// First buster of the round
			g_nBuster[team][g_flBusterTriggerTimer] = config.LookupFloat(g_hCvarBusterFormulaBaseFirst) - (config.LookupFloat(g_hCvarBusterFormulaSentryMult) * float(numSentries));
		}else{
			// Every buster afterward
			g_nBuster[team][g_flBusterTriggerTimer] = config.LookupFloat(g_hCvarBusterFormulaBaseSecond) - (config.LookupFloat(g_hCvarBusterFormulaSentryMult) * float(numSentries));
		}
	}
}

int Buster_GetNumActiveSentries(int team)
{
	int iNumSentries = 0;
	int sentry = MaxClients+1;
	while((sentry = FindEntityByClassname(sentry, "obj_sentrygun")) > MaxClients)
	{
		if(GetEntProp(sentry, Prop_Send, "m_bWasMapPlaced")) continue;

		int sentryTeam = GetEntProp(sentry, Prop_Send, "m_iTeamNum");
		if(sentryTeam == team)
		{
			if(!GetEntProp(sentry, Prop_Send, "m_bDisabled") && GetEntPropFloat(sentry, Prop_Send, "m_flPercentageConstructed") >= 1.0)
			{
				int builder = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
				if(builder >= 1 && builder <= MaxClients && IsClientInGame(builder) && GetClientTeam(builder) == sentryTeam)
				{
					// As of the Gun Mettle, mini-sentries will not activate sentry busters.
					if(!GetEntProp(sentry, Prop_Send, "m_bMiniBuilding") || GetEntProp(builder, Prop_Send, "m_bIsMiniBoss"))
					{
						iNumSentries++;
					}
				}
			}
		}
	}
	return iNumSentries;
}

bool Buster_AreConditionsMet(int team)
{
	// Check if any of the 3 conditions are met and if so, begin to spawn a sentry buster
	bool bTriggerMet = false;

	Handle hTriggerTank = g_hCvarBusterTriggerTank;
	Handle hTriggerGiant = g_hCvarBusterTriggerGiant;
	Handle hTriggerRobots = g_hCvarBusterTriggerRobots;
	if(g_nGameMode == GameMode_Race)
	{
		// We have different trigger damage values for plr_ maps
		hTriggerTank = g_hCvarBusterTriggerTankPlr;
		hTriggerGiant = g_hCvarBusterTriggerGiantPlr;
		hTriggerRobots = g_hCvarBusterTriggerRobotsPlr;
	}

	if(g_nBuster[team][g_iBusterTriggerTankBySentry] >= config.LookupInt(hTriggerTank) || g_nBuster[team][g_iBusterTriggerGiantBySentry] >= config.LookupInt(hTriggerGiant) || g_nBuster[team][g_iBusterTriggerRobotsBySentry] >= config.LookupInt(hTriggerRobots))
	{
		bTriggerMet = true;
	}

	// Check if the sentry buster timer has elapsed
	if(g_nBuster[team][g_bBusterTimerStarted] && g_nBuster[team][g_flBusterTriggerTimer] <= 0.0)
	{
		bTriggerMet = true;
	}

	return bTriggerMet;
}

void Buster_Explode(int client, float heightOffset=110.0, const char[] explosionParticle="explosionTrail_seeds_mvm")
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += heightOffset;

	float effectRadius = config.LookupFloat(g_hCvarBusterExplodeRadius);
	float effectMagnitude = config.LookupFloat(g_hCvarBusterExplodeMagnitude);

	for(int i=0; i<MAXPLAYERS+1; i++) g_hitBySentryBuster[i] = false;

	// Spawn an explosion to hurt nearby entities
	int iExplosion = CreateEntityByName("env_explosion");
	if(iExplosion > MaxClients)
	{
		char strMagnitude[15];
		FloatToString(effectMagnitude, strMagnitude, sizeof(strMagnitude));

		char strRadius[15];
		FloatToString(effectRadius, strRadius, sizeof(strRadius));

		DispatchKeyValue(iExplosion, "iMagnitude", strMagnitude);
		DispatchKeyValue(iExplosion, "iRadiusOverride", strRadius);
		
		DispatchSpawn(iExplosion);
		
		SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", client);
		
		TeleportEntity(iExplosion, pos, NULL_VECTOR, NULL_VECTOR);
		
		g_busterExplodeTime = GetEngineTime();
		AcceptEntityInput(iExplosion, "Explode");
		
		CreateTimer(5.0, Timer_EntityCleanup, EntIndexToEntRef(iExplosion));
	}

	// env_explosion ain't perfect. Dispensers can be used to block explosions.
	// Collect entities of interest.
	ArrayList list = new ArrayList();
	int team = GetClientTeam(client);
	int entity = MaxClients+1;
	while((entity = FindEntityByClassname(entity, "obj_sentrygun")) > MaxClients)
	{
		if(Buster_CanBeDestroyed(entity, team, pos, effectRadius)) list.Push(entity);
	}
	entity = MaxClients+1;
	while((entity = FindEntityByClassname(entity, "obj_dispenser")) > MaxClients)
	{
		if(Buster_CanBeDestroyed(entity, team, pos, effectRadius)) list.Push(entity);
	}
	entity = MaxClients+1;
	while((entity = FindEntityByClassname(entity, "obj_teleporter")) > MaxClients)
	{
		if(Buster_CanBeDestroyed(entity, team, pos, effectRadius)) list.Push(entity);
	}
	for(int i=1; i<=MaxClients; i++)
	{
		if(i != client && !g_hitBySentryBuster[i] && IsClientInGame(i) && IsPlayerAlive(i) && Buster_CanBeDestroyed(i, team, pos, effectRadius)) list.Push(i);
	}
#if defined DEBUG
	PrintToServer("(Buster_Explode) Found %d entities of interest!", list.Length);
#endif

	int size = list.Length;
	float giantDamageCap = config.LookupFloat(g_hCvarBusterCap);
	for(int i=0; i<size; i++)
	{
		entity = list.Get(i);
		
		// See if the buster is within line of sight before hurting the entity.
		float targetPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetPos);

		float targetMaxs[3];
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", targetMaxs);

		targetPos[2] += targetMaxs[2] / 2.0;

		TR_TraceRayFilter(pos, targetPos, MASK_SHOT, RayType_EndPoint, TraceEntityFilter_BusterExplosion, team);
		if(!TR_DidHit())
		{
			// Has line of sight so hurt this entity.
#if defined DEBUG
			char className[32];
			GetEdictClassname(entity, className, sizeof(className));

			PrintToServer("(Buster_Explode) %d \"%s\" should take damage!", entity, className);
#endif
			float damage = effectMagnitude;
			if(entity >= 1 && entity <= MaxClients && GetEntProp(entity, Prop_Send, "m_bIsMiniBoss") && damage > giantDamageCap) damage = giantDamageCap;

			g_busterExplodeTime = GetEngineTime();
			SDKHooks_TakeDamage(entity, iExplosion, client, damage, DMG_BLAST);
		}
#if defined DEBUG
		else{
			char className[32];
			float hitPos[3];
			int contents = -1;
			TR_GetEndPosition(hitPos);

			int hit = TR_GetEntityIndex();
			if(hit >= 0)
			{
				contents = TR_GetPointContents(hitPos);
				GetEdictClassname(hit, className, sizeof(className));
			}

			PrintToServer("(Buster_Explode) Blocked by %d \"%s\" contents = %d!", hit, className, contents);
		}
#endif
	}

	delete list;

	// Spawn the explosion particle effects
	int iEntity = CreateEntityByName("info_particle_system");
	if(iEntity > MaxClients)
	{
		TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iEntity, "effect_name", explosionParticle);
		
		DispatchSpawn(iEntity);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		
		CreateTimer(5.0, Timer_EntityCleanup, EntIndexToEntRef(iEntity));
	}

	iEntity = CreateEntityByName("info_particle_system");
	if(iEntity > MaxClients)
	{
		TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iEntity, "effect_name", "fluidSmokeExpl_ring_mvm");
		
		DispatchSpawn(iEntity);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		
		CreateTimer(5.0, Timer_EntityCleanup, EntIndexToEntRef(iEntity));
	}

	// Generate an earth quake effect on player's screens
	// void UTIL_ScreenShake(float center[3], float amplitude, float frequency, float duration, float radius, int command, bool airShake)
	UTIL_ScreenShake(pos, 25.0, 5.0, 5.0, 1000.0, 0, true);

	// Make sure the sentry buster expires.
	g_bBlockRagdoll = true; // Set a flag to remove this player's ragdoll (since tf_gibsforced is probably 0).
	g_timeSentryBusterDied = GetEngineTime();
	// Make sure the sentry buster dies..
	ForcePlayerSuicide(client);
	FakeClientCommand(client, "explode");
	if(IsPlayerAlive(client))
	{
		SDKHooks_TakeDamage(client, 0, client, 99999999.0);
		SDKHooks_TakeDamage(client, 0, client, 99999999.0);
	}
}

bool Buster_CanBeDestroyed(int entity, int team, float checkPos[3], float checkRadius)
{
	if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == team) return false;

	float pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

	if(GetVectorDistance(pos, checkPos) > checkRadius) return false;

	return true;
}

public bool TraceEntityFilter_BusterExplosion(int entity, int contentsMask, int team)
{
	// Hit the world.
	if(entity <= 0) return true;

	// Pass through all players.
	if(entity >= 1 && entity <= MaxClients) return false;

	// Pass through all buildings.
	if(entity > MaxClients)
	{
		char className[32];
		GetEdictClassname(entity, className, sizeof(className));
		//PrintToServer("Hit: %s", className);
		if(strncmp(className, "obj_", 4) == 0 || strcmp(className, "tf_ammo_pack") == 0)
		{
			return false;
		}
	}

	return true;
}

public Action Command_Buster(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(client < 1 || client > MaxClients || !IsClientInGame(client)) return Plugin_Handled;
	int team = GetClientTeam(client);
	if(team == TFTeam_Red || team == TFTeam_Blue)
	{
		// This command allows players to see who will become the next sentry buster on their team

		int iBuster = GetClientOfUserId(g_nBuster[team][g_iBusterQueuedUserId]);
		if(iBuster >= 1 && iBuster <= MaxClients && IsClientInGame(iBuster))
		{
			PrintToChat(client, "%t", "Tank_Chat_Buster_Queued", 0x01, g_strTeamColors[team], 0x01, g_strTeamColors[team], iBuster, 0x01);
		}else{
			PrintToChat(client, "%t", "Tank_Chat_Buster_Next_NoOne", 0x01, g_strTeamColors[team], 0x01);
		}
	}

	// Admins will receive a menu with more detailed information
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		Handle hPanel = CreatePanel();

		char strText[200];
		Format(strText, sizeof(strText), "RED's next buster: %N\nBLU's next buster: %N\n \nCurrent BLU conditions:", GetClientOfUserId(g_nBuster[TFTeam_Red][g_iBusterQueuedUserId]), GetClientOfUserId(g_nBuster[TFTeam_Blue][g_iBusterQueuedUserId]));
		SetPanelTitle(hPanel, strText);

		int iTriggerTank = (g_nGameMode == GameMode_Race) ? config.LookupInt(g_hCvarBusterTriggerTankPlr) :  config.LookupInt(g_hCvarBusterTriggerTank);
		int iTriggerGiant = (g_nGameMode == GameMode_Race) ? config.LookupInt(g_hCvarBusterTriggerGiantPlr) : config.LookupInt(g_hCvarBusterTriggerGiant);
		int iTriggerRobots = (g_nGameMode == GameMode_Race) ? config.LookupInt(g_hCvarBusterTriggerRobotsPlr) : config.LookupInt(g_hCvarBusterTriggerRobots);

		// Show the damage amounts of the current triggers
		Format(strText, sizeof(strText), "Tank damage: %d/%d (%d%%)", g_nBuster[TFTeam_Blue][g_iBusterTriggerTankBySentry], iTriggerTank, RoundToNearest(float(g_nBuster[TFTeam_Blue][g_iBusterTriggerTankBySentry]) / float(iTriggerTank) * 100.0));
		DrawPanelText(hPanel, strText);
		Format(strText, sizeof(strText), "Giant damage: %d/%d (%d%%)", g_nBuster[TFTeam_Blue][g_iBusterTriggerGiantBySentry], iTriggerGiant, RoundToNearest(float(g_nBuster[TFTeam_Blue][g_iBusterTriggerGiantBySentry]) / float(iTriggerGiant) * 100.0));
		DrawPanelText(hPanel, strText);
		Format(strText, sizeof(strText), "Robot kills: %d/%d (%d%%)\n ", g_nBuster[TFTeam_Blue][g_iBusterTriggerRobotsBySentry], iTriggerRobots, RoundToNearest(float(g_nBuster[TFTeam_Blue][g_iBusterTriggerRobotsBySentry]) / float(iTriggerRobots) * 100.0));
		DrawPanelText(hPanel, strText);
		Format(strText, sizeof(strText), "Buster timer(%d): %1.2f", g_nBuster[TFTeam_Blue][g_bBusterTimerStarted], g_nBuster[TFTeam_Blue][g_flBusterTriggerTimer]);
		DrawPanelText(hPanel, strText);

		Format(strText, sizeof(strText), "Num active sentries: %d", Buster_GetNumActiveSentries(TFTeam_Red));
		DrawPanelText(hPanel, strText);

		DrawPanelItem(hPanel, "Dismiss");

		SendPanelToClient(hPanel, client, PanelHandler, MENU_TIME_FOREVER);
		CloseHandle(hPanel);
	}

	return Plugin_Handled;
}

int Buster_PickTemplate()
{
	int iForcedTemplate = config.LookupInt(g_hCvarBusterForce);
	if(iForcedTemplate != -1 && iForcedTemplate >= 0 && iForcedTemplate < MAX_NUM_TEMPLATES && g_nGiants[iForcedTemplate][g_bGiantTemplateEnabled] && g_nGiants[iForcedTemplate][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) return iForcedTemplate;

	Handle hArray = CreateArray();
	for(int i=0; i<MAX_NUM_TEMPLATES; i++)
	{
		if(g_nGiants[i][g_bGiantTemplateEnabled] && !g_nGiants[i][g_bGiantAdminOnly] && g_nGiants[i][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
		{
			PushArrayCell(hArray, i);
		}
	}

	int size = GetArraySize(hArray);
	if(size <= 0)
	{
		//LogMessage("Failed to find any valid giant robot templates! Are too many disabled?");
		delete hArray;
		return -1;
	}

	int iRandomTemplate = GetArrayCell(hArray, GetRandomInt(0, size-1));

	delete hArray;
	return iRandomTemplate;
}

void SentryVision_SetReference(int iGlow, int iSentryGun)
{
	SetEntProp(iGlow, Prop_Data, "m_iHealth", EntIndexToEntRef(iSentryGun));
}

int SentryVision_GetReference(int iGlow)
{
	return GetEntProp(iGlow, Prop_Data, "m_iHealth");
}

void SentryVision_UpdateModel(int iGlow, int iSentryGun)
{
	if(GetEntProp(iGlow, Prop_Send, "m_nModelIndex") != GetEntProp(iSentryGun, Prop_Send, "m_nModelIndex"))
	{
		char strModelSentry[PLATFORM_MAX_PATH];
		GetEntPropString(iSentryGun, Prop_Data, "m_ModelName", strModelSentry, sizeof(strModelSentry));
		if(strModelSentry[0] == '\0') return;

	#if defined DEBUG
		PrintToServer("(SentryVision_UpdateModel) Model changed: \"%s\"!", strModelSentry);
	#endif

		SetEntityModel(iGlow, strModelSentry);
	}
}

/*
SentryVision_UpdateFlags(iGlow, iSentryGun)
{
	new iFlags = result;
	char strText[64];
	for(int i=0; i<16; i++)
	{
		if(iFlags & (1 << i)) Format(strText, sizeof(strText), "%s %d", strText, i);
	}
	PrintCenterTextAll(strText);

	// Do not transmit the glow entity while the sentry is picked up
	new iFlags = GetEdictFlags(iGlow);
	if(GetEntProp(iSentryGun, Prop_Send, "m_bPlacing"))
	{
		// Do not transmit
		iFlags &= ~FL_EDICT_ALWAYS;
		iFlags &= ~FL_EDICT_PVSCHECK;
		iFlags |= FL_EDICT_DONTSEND;
		SetEdictFlags(iGlow, iFlags);
	}else{
		// Transmit
		iFlags &= ~FL_EDICT_PVSCHECK;
		iFlags &= ~FL_EDICT_DONTSEND;
		//iFlags |= FL_EDICT_ALWAYS|FL_EDICT_PVSCHECK;
	}
	SetEdictFlags(iGlow, iFlags);
}
*/

void SentryVision_OnSentryCreated(int iSentryGun)
{
	// Create the glow entity the sentry buster will see
	// The sentry buster will be able to see this entity while other players will not
	int iGlow = CreateEntityByName("tf_taunt_prop");
	if(iGlow > MaxClients)
	{
		float flModelScale = GetEntPropFloat(iSentryGun, Prop_Send, "m_flModelScale");

		SentryVision_UpdateModel(iGlow, iSentryGun);

		DispatchSpawn(iGlow);
		ActivateEntity(iGlow);

		SetEntityRenderMode(iGlow, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iGlow, 0, 0, 0, 0);
		SetEntProp(iGlow, Prop_Send, "m_bGlowEnabled", true);
		SetEntPropFloat(iGlow, Prop_Send, "m_flModelScale", flModelScale);

		int team = GetEntProp(iSentryGun, Prop_Send, "m_iTeamNum");
		SetEntProp(iGlow, Prop_Send, "m_iTeamNum", team);

		int iFlags = GetEntProp(iGlow, Prop_Send, "m_fEffects");
		SetEntProp(iGlow, Prop_Send, "m_fEffects", iFlags|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);

		SetVariantString("!activator");
		AcceptEntityInput(iGlow, "SetParent", iSentryGun);

		//SetVariantString("laser_origin");
		//AcceptEntityInput(iGlow, "SetParentAttachment");

		SentryVision_SetReference(iGlow, iSentryGun);
		PushArrayCell(g_nSentryVision[g_hSentryVisionList], EntIndexToEntRef(iGlow));
#if defined DEBUG
		PrintToServer("(SentryVision_OnSentryCreated) Created glow entity: %d!", EntIndexToEntRef(iGlow));
#endif
		Tank_HookShouldTransmit(iSentryGun);
		SDKHook(iGlow, SDKHook_SetTransmit, SentryVision_SetTransmit);
	}
}

void SentryVision_Think()
{
	for(int i=GetArraySize(g_nSentryVision[g_hSentryVisionList])-1; i>=0; i--)
	{
		int iGlow = EntRefToEntIndex(GetArrayCell(g_nSentryVision[g_hSentryVisionList], i));
		if(iGlow > MaxClients)
		{
			int iSentryGun = EntRefToEntIndex(SentryVision_GetReference(iGlow));
			if(iSentryGun > MaxClients)
			{
				SentryVision_UpdateModel(iGlow, iSentryGun);
				//SentryVision_UpdateFlags(iGlow, iSentryGun);
			}else{
#if defined DEBUG
				PrintToServer("(SentryVision_Think) Removed glow entity (non-existant sentry): %d!", GetArrayCell(g_nSentryVision[g_hSentryVisionList], i));
#endif
				RemoveFromArray(g_nSentryVision[g_hSentryVisionList], i);
			}
		}else{
#if defined DEBUG
			PrintToServer("(SentryVision_Think) Removed glow entity (no longer exists): %d!", GetArrayCell(g_nSentryVision[g_hSentryVisionList], i));
#endif
			RemoveFromArray(g_nSentryVision[g_hSentryVisionList], i);
		}
	}
}

public Action SentryVision_SetTransmit(int iGlow, int client)
{
	// Only transmit the glow entities to active sentry busters
	// They should not exist to the rest of the players
	if(Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		// When the sentry is picked up, we need to stop transmitting the glow entity
		int iSentryGun = EntRefToEntIndex(SentryVision_GetReference(iGlow));
		if(iSentryGun > MaxClients && GetClientTeam(client) != GetEntProp(iSentryGun, Prop_Send, "m_iTeamNum") && !GetEntProp(iSentryGun, Prop_Send, "m_bPlacing"))
		{
			return Plugin_Continue;
		}
	}

	return Plugin_Handled;
}

public Action Tank_OnShouldTransmit(int iSentryGun, int client, int &result)
{
	// This is fired whenever the server transmits a sentrygun
	// result is the bitstring of the FL_ flags from edict.h

	// If the client is a sentry buster, always transmit this entity to that client
	if(Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") && GetClientTeam(client) != GetEntProp(iSentryGun, Prop_Send, "m_iTeamNum") && !GetEntProp(iSentryGun, Prop_Send, "m_bPlacing"))
	{
		result &= ~FL_EDICT_DONTSEND;
		result &= ~FL_EDICT_PVSCHECK;
		result |= FL_EDICT_ALWAYS;
		return Plugin_Changed;
	}

	// Returns the value from the original function call
	return Plugin_Continue;
}

int BusterVision_Create(int client, bool superSpy=false)
{
	// Create the glow entity the sentry buster's team will see
	// Only the sentry buster's team will be able to see this entity
	int iGlow = CreateEntityByName("tf_taunt_prop");
	if(iGlow > MaxClients)
	{
		float flModelScale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
		SetEntProp(iGlow, Prop_Send, "m_nModelIndex", GetEntProp(client, Prop_Send, "m_nModelIndex"));

		char model[PLATFORM_MAX_PATH];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		SetEntityModel(iGlow, model);

		DispatchSpawn(iGlow);
		ActivateEntity(iGlow);

		SetEntityRenderMode(iGlow, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iGlow, 0, 0, 0, 0);
		SetEntProp(iGlow, Prop_Send, "m_bGlowEnabled", true);
		SetEntPropFloat(iGlow, Prop_Send, "m_flModelScale", flModelScale);

		int team = GetClientTeam(client);
		SetEntProp(iGlow, Prop_Send, "m_iTeamNum", team);

		int iFlags = GetEntProp(iGlow, Prop_Send, "m_fEffects");
		SetEntProp(iGlow, Prop_Send, "m_fEffects", iFlags|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);

		SetVariantString("!activator");
		AcceptEntityInput(iGlow, "SetParent", client);

		// Set up transmission rules for Buster Vision and Super Spy Vision.
		if(superSpy)
		{
			SDKHook(iGlow, SDKHook_SetTransmit, SuperSpy_SetTransmit);
		}else{
			SDKHook(iGlow, SDKHook_SetTransmit, BusterVision_SetTransmit);
		}
#if defined DEBUG
		PrintToServer("(BusterVision_Create) Created glow entity: %d!", iGlow);
#endif
		return iGlow;
	}

	return -1;
}

public Action BusterVision_SetTransmit(int glow, int client)
{
	// Sentry buster only glows to teammates
	int clientTeam = GetClientTeam(client);
	if(clientTeam == 1 || GetEntProp(glow, Prop_Send, "m_iTeamNum") == clientTeam)
	{
		// The buster should not see his own glow
		if(GetEntPropEnt(glow, Prop_Send, "moveparent") == client) return Plugin_Handled;

		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action SuperSpy_SetTransmit(int glow, int client)
{
	int bomb = EntRefToEntIndex(g_iRefBombFlag);
	if(bomb <= MaxClients) return Plugin_Handled;
	int giant = GetEntPropEnt(glow, Prop_Send, "moveparent");
	if(giant < 1 || giant > MaxClients) return Plugin_Handled;

	// Super Spy is carrying the bomb: Don't show glow to anyone.
	if(GetEntPropEnt(bomb, Prop_Send, "moveparent") == giant) return Plugin_Handled;

	// Super Spy only glows to his teammates and spectators.
	int clientTeam = GetClientTeam(client);
	if(clientTeam == 1 || GetEntProp(glow, Prop_Send, "m_iTeamNum") == clientTeam)
	{
		// The Super Spy should not see his own glow.
		if(giant == client) return Plugin_Handled;

		return Plugin_Continue;
	}

	return Plugin_Handled;
}