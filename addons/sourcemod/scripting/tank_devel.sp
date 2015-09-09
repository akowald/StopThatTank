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
 * Purpose: This file contains functions that support map logic and stt development.
 */

#if !defined STT_MAIN_PLUGIN
#error This plugin must be compiled from tank.sp
#endif

#define TARGETNAME_CART_PROP			"stt_cart_prop"
#define TARGETNAME_OVERTIME_TIMER		"stt_overtime_timer"
#define TARGETNAME_GIANTWAVE_TIMER 		"stt_giant_wave_timer"
#define TARGETNAME_INTERMISSON_RELAY	"stt_intermission_started"
#define TARGETNAME_STT_ACTIVE			"stt_is_enabled"
#define TARGETNAME_PARENT_TANK			"stt_parent_tank"

enum eMapLogicStruct
{
	g_mapLogicParentTank,
};
int g_mapLogic[eMapLogicStruct];

void MapLogic_Reset()
{
	g_mapLogic[g_mapLogicParentTank] = 0;
}

void MapLogic_Init()
{
	MapLogic_Reset();

	// This entity allows the map to control the parenting of the tank to the cart.
	int entity = Entity_FindEntityByName(TARGETNAME_PARENT_TANK, "logic_relay");
	if(entity != -1)
	{
#if defined DEBUG
		PrintToServer("(MapLogic_Init) Found logic_relay:%s: %d!", TARGETNAME_PARENT_TANK, entity);
#endif
		HookSingleEntityOutput(entity, "OnUser1", EntityOutput_ParentRed, false);
		HookSingleEntityOutput(entity, "OnUser2", EntityOutput_UnParentRed, false);
		HookSingleEntityOutput(entity, "OnUser3", EntityOutput_ParentBlue, false);
		HookSingleEntityOutput(entity, "OnUser4", EntityOutput_UnParentBlue, false);

		g_mapLogic[g_mapLogicParentTank] = entity;
	}

	entity = Entity_FindEntityByName(TARGETNAME_STT_ACTIVE, "logic_relay");
	if(entity != -1)
	{
#if defined DEBUG
		PrintToServer("(MapLogic_Init) Found logic_relay:%s: %d!", TARGETNAME_STT_ACTIVE, entity);
#endif
		AcceptEntityInput(entity, "Trigger");
	}
}

public void EntityOutput_ParentRed(const char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(EntityOutput_ParentRed) caller: %d, activator: %d, delay: %f!", caller, activator, delay);
#endif

	MapLogic_ParentTank(TFTeam_Red);
}

public void EntityOutput_UnParentRed(const char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(EntityOutput_UnParentRed) caller: %d, activator: %d, delay: %f!", caller, activator, delay);
#endif

	MapLogic_UnParentTank(TFTeam_Red);
}

public void EntityOutput_ParentBlue(const char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(EntityOutput_ParentBlue) caller: %d, activator: %d, delay: %f!", caller, activator, delay);
#endif

	MapLogic_ParentTank(TFTeam_Blue);
}

public void EntityOutput_UnParentBlue(const char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(EntityOutput_UnParentBlue) caller: %d, activator: %d, delay: %f!", caller, activator, delay);
#endif

	MapLogic_UnParentTank(TFTeam_Blue);
}

void MapLogic_ParentTank(int team)
{
	// Map is requesting to parent a team's tank.
	int tank = EntRefToEntIndex(g_iRefTank[team]);
	if(tank <= MaxClients)
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) parent request failed for tank (team %d): Tank missing!", map, team);
		return;
	}

	int cart = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(cart <= MaxClients)
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) parent request failed for tank (team %d): Cart missing!", map, team);
		return;
	}

	if(g_bRaceParentedForHill[team])
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) parent request failed for tank (team %d): Under uphill path control!", map, team);
		return;
	}

	if(GetEntPropEnt(tank, Prop_Send, "moveparent") > MaxClients)
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) parent request failed for tank (team %d): Tank is already parented!", map, team);
		return;
	}

	Tank_Parent(team);
}

void MapLogic_UnParentTank(int team)
{
	// Map is requesting to parent a team's tank.
	int tank = EntRefToEntIndex(g_iRefTank[team]);
	if(tank <= MaxClients)
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) un-parent request failed for tank (team %d): Tank missing!", map, team);
		return;
	}

	int cart = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(cart <= MaxClients)
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) un-parent request failed for tank (team %d): Cart missing!", map, team);
		return;
	}

	if(g_bRaceParentedForHill[team])
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) un-parent request failed for tank (team %d): Under uphill path control!", map, team);
		return;
	}

	if(GetEntPropEnt(tank, Prop_Send, "moveparent") <= MaxClients)
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		
		LogMessage("Map (%s) un-parent request failed for tank (team %d): Tank is not parented at the moment!", map, team);
		return;
	}

	Tank_UnParent(team);
}

void MapLogic_OnIntermission()
{
	// Find the targetname of the specific logic_relay and trigger it.
	int entity = Entity_FindEntityByName(TARGETNAME_INTERMISSON_RELAY, "logic_relay");
	if(entity != -1)
	{
#if defined DEBUG
		PrintToServer("(MapLogic_OnIntermission) Found logic_relay %d, triggering it..", entity);
#endif

		AcceptEntityInput(entity, "Trigger");
	}
}