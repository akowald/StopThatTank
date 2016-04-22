/**
 * ==============================================================================
 * Stop that Tank!
 * Copyright (C) 2014-2016 Alex Kowald
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
 * Purpose: This file contains functions that support team giant spawning during gameplay.
 */

#if !defined STT_MAIN_PLUGIN
#error This plugin must be compiled from tank.sp
#endif

#define PATH_GIANT_TEMPLATES 		"configs/stt/giant_robot.cfg"
#define PATH_GIANT_PLR_TEMPLATES	"configs/stt/giant_robot_plr.cfg"

#define KEYVALUE_DEFAULT	12256.0
#define MAX_NUM_TEMPLATES	50
#define WEAPON_ANY          -1
#define WEAPON_RESTRICT     -2
#define MAXLEN_GIANT_STRING 100
#define MAXLEN_GIANT_DESC 	512
#define MAX_GIANT_TAGS 		25
#define MAXLEN_GIANT_TAG 	50
#define MAXLEN_GIANT_TAGS 	((MAX_GIANT_TAGS * MAXLEN_GIANT_TAG) + MAX_GIANT_TAGS + 1)
#define MAX_CONFIG_WEAPONS	6
#define TF_COND_TEAM_GLOWS 	114

#define FLAG_DONT_DROP_WEAPON 				0x23E173A2
#define OFFSET_DONT_DROP					36

#define GIANTTAG_SENTRYBUSTER 				(1 << 0)
#define GIANTTAG_PIPE_EXPLODE_SOUND 		(1 << 1)
#define GIANTTAG_FILL_UBER 					(1 << 2)
#define GIANTTAG_MEDIC_AOE					(1 << 3)
#define GIANTTAG_DONT_CHANGE_RESPAWN		(1 << 4)
#define GIANTTAG_SCALE_BUILDINGS			(1 << 5)
#define GIANTTAG_TELEPORTER					(1 << 6)
#define GIANTTAG_MINIGUN_SOUNDS				(1 << 7)
#define GIANTTAG_AIRBOURNE_MINICRITS		(1 << 8)
#define GIANTTAG_MELEE_KNOCKBACK			(1 << 9)
#define GIANTTAG_MELEE_KNOCKBACK_CRITS		(1 << 10)
#define GIANTTAG_AIRBLAST_CRITS				(1 << 11)
#define GIANTTAG_NO_LOOP_SOUND				(1 << 12)
#define GIANTTAG_CAN_DROP_BOMB				(1 << 13)
#define GIANTTAG_AIRBLAST_KILLS_STICKIES	(1 << 14)
#define GIANTTAG_NO_GIB 					(1 << 15)
#define GIANTTAG_BLOCK_HEALONHIT 			(1 << 16)
#define GIANTTAG_JARATE_ON_HIT				(1 << 17)
#define GIANTTAG_DONT_SPAWN_IN_HELL 		(1 << 18)

char g_strGiantTags[][] =
{
	"sentrybuster", "pipe_explode_sound", "fill_uber", "medic_aoe", "dont_change_respawn", "scale_buildings", "teleporter", "minigun_sounds", "airbourne_minicrits", "melee_knockback", "melee_knockback_crits", "airblast_crits", "no_loop_sound", "can_drop_bomb", "airblast_kills_stickies", "no_gib", "block_healonhit", "jarate_on_hit", "dont_spawn_in_hell",
};

enum
{
	ArrayCond_Index=0,
	ArrayCond_Duration
};

enum
{
	GiantCleared_Misc=0,
	GiantCleared_Death,
	GiantCleared_Disconnect,
	GiantCleared_Deploy
};

enum eGiantStruct
{
	// Giant robot information based on scripts/population/robot_giant.pop
	bool:g_bGiantTemplateEnabled,
	bool:g_bGiantAdminOnly,
	String:g_strGiantName[MAXLEN_GIANT_STRING],
	String:g_strGiantModel[MAXLEN_GIANT_STRING],
	TFClassType:g_nGiantClass,
	g_iGiantHealth,
	g_iGiantOverheal,
	Float:g_flGiantCapHealth,
	Float:g_flGiantScale,
	String:g_strGiantDesc[MAXLEN_GIANT_DESC],
	String:g_strGiantHint[MAXLEN_GIANT_DESC],
	g_iGiantTags,
	Handle:g_hGiantConditions,
	g_iGiantActiveSlot,											// The active weapon slot when the giant is spawned.
	g_iGiantWeaponDefs[MAX_CONFIG_WEAPONS],
	bool:g_bGiantWeaponBotRestricted[MAX_CONFIG_WEAPONS],
	Handle:g_hGiantClassnames,
	// Arrays will house the attribute data on the player and weapons
	Handle:g_hGiantCharAttrib,
	Handle:g_hGiantCharAttribValue,
	Handle:g_hGiantWeaponAttrib[MAX_CONFIG_WEAPONS],
	Handle:g_hGiantWeaponAttribValue[MAX_CONFIG_WEAPONS]
};
int g_nGiants[MAX_NUM_TEMPLATES][eGiantStruct];

enum eTeamGiantStruct
{
	bool:g_bTeamGiantActive, // Whether or not to run giant logic such as warning the giants and starting the spawning sequence
	g_iTeamGiantQueuedUserId, // The userid of the player queued up to become the next giant
	Float:g_flTeamGiantTimeNextSpawn, // Time when the giant robot should be spawned next
	g_iTeamGiantTemplateIndex, // The giant robot template that will be used
	Float:g_flTeamGiantTimeSpawned, // Time when the giant robot is spawned, we use this to make sure the giant stays valid a certain amount of time after he is spawned
	Float:g_flTeamGiantTimeRoundStarts, // Time when the bomb round is scheduled to start, we use this time as a cut-off to stop watching over the giant
	Float:g_flTeamGiantTimeLastAngleChg, // Time when the giant's viewangles last changed
	Float:g_flTeamGiantViewAngles[3], // A record of the last giant's view angles to judge if they are AFK
	g_iTeamGiantButtons, // A record of the last giant's button bits to judge if they are AFK
	bool:g_bTeamGiantAlive, // Flag that the giant has been spawned
	bool:g_bTeamGiantPanelShown, // Flag to ensure the giant panel is only shown once
	bool:g_bTeamGiantNoRageMeter, // Flag to spawn the giant with a rage meter
	bool:g_bTeamGiantNoCritCash, // Flag for when the giant has been spawned and announced to everyone on the server. Crit cash will be denied after this point.
};
int g_nTeamGiant[MAX_TEAMS][eTeamGiantStruct];

enum eRageMeterStruct
{
	bool:g_rageMeterEnabled,
	Float:g_rageMeterTimeLastRageMsg, // Time when the last rage hudtext message was sent.
	bool:g_rageMeterLowRageAlert, // Flag that a sound has been played when the rage meter becomes low.
	Float:g_rageMeterLevel, // Seconds until the rage meter runs out and the player is killed.
	Float:g_rageMeterLastThinkTime, // Time when the last think occured.
	Float:g_rageMeterTimeLastTookDamage, // Time when the giant last took damage.
};
int g_rageMeter[MAXPLAYERS+1][eRageMeterStruct];

bool TeamGiant_IsPlayer(int client)
{
	int team = GetClientTeam(client);
	if(g_nTeamGiant[team][g_bTeamGiantActive] && g_nTeamGiant[team][g_iTeamGiantQueuedUserId] != 0 && g_nTeamGiant[team][g_iTeamGiantQueuedUserId] == GetClientUserId(client)) return true;

	return false;
}

void Giant_InitTemplates()
{
	// Prep the ADTArrays that will house the attribute data in the templates
	for(int i=0; i<MAX_NUM_TEMPLATES; i++)
	{
		g_nGiants[i][g_hGiantConditions] = CreateArray(2);

		g_nGiants[i][g_hGiantCharAttrib] = CreateArray(ByteCountToCells(MAXLEN_GIANT_STRING));
		g_nGiants[i][g_hGiantCharAttribValue] = CreateArray();

		for(int a=0; a<MAX_CONFIG_WEAPONS; a++)
		{
			g_nGiants[i][g_hGiantWeaponAttrib][a] = CreateArray(ByteCountToCells(MAXLEN_GIANT_STRING));
			g_nGiants[i][g_hGiantWeaponAttribValue][a] = CreateArray();
		}

		g_nGiants[i][g_hGiantClassnames] = CreateArray(ByteCountToCells(MAXLEN_GIANT_STRING));
	}
}

void Giant_LoadTemplates()
{
	// Clear the data on all templates
	for(int i=0; i<MAX_NUM_TEMPLATES; i++)
	{
		g_nGiants[i][g_bGiantTemplateEnabled] = false;

		ClearArray(g_nGiants[i][g_hGiantConditions]);
		ClearArray(g_nGiants[i][g_hGiantCharAttrib]);
		ClearArray(g_nGiants[i][g_hGiantCharAttribValue]);

		ClearArray(g_nGiants[i][g_hGiantClassnames]);
		for(int a=0; a<MAX_CONFIG_WEAPONS; a++)
		{
			ClearArray(g_nGiants[i][g_hGiantWeaponAttrib][a]);
			ClearArray(g_nGiants[i][g_hGiantWeaponAttribValue][a]);

			PushArrayString(g_nGiants[i][g_hGiantClassnames], "");
		}
	}

	char strPath[PLATFORM_MAX_PATH];
	if(g_nGameMode == GameMode_Race)
	{
		BuildPath(Path_SM, strPath, sizeof(strPath), PATH_GIANT_PLR_TEMPLATES);
	}else{
		BuildPath(Path_SM, strPath, sizeof(strPath), PATH_GIANT_TEMPLATES);
	}

	if(!FileExists(strPath))
	{
		LogMessage("Failed to load giant robot templates (file missing): %s!", strPath);
		return;
	}

	Handle hKv = CreateKeyValues("GiantRobot");
	if(hKv == INVALID_HANDLE)
	{
		LogMessage("Failed to load giant robot templates!");
		return;
	}
	KvSetEscapeSequences(hKv, true);

	if(!FileToKeyValues(hKv, strPath))
	{
		LogMessage("Failed to parse giant robot template keyvalues!");
		CloseHandle(hKv);
		return;
	}

	char strBuffer[MAXLEN_GIANT_STRING];
	char strBufferTags[MAXLEN_GIANT_TAGS];

	int iIndex = 0;
	if(KvJumpToKey(hKv, "Templates"))
	{
		if(KvGotoFirstSubKey(hKv))
		{
			do
			{
				KvGetSectionName(hKv, g_nGiants[iIndex][g_strGiantName], MAXLEN_GIANT_STRING);

				bool bValidated = true;
				
				KvGetString(hKv, "disable", strBuffer, sizeof(strBuffer));
				if(strlen(strBuffer) <= 0) KvGetString(hKv, "disabled", strBuffer, sizeof(strBuffer));
				if(strlen(strBuffer) > 0)
				{
					bValidated = false;
				}
				
				g_nGiants[iIndex][g_bGiantAdminOnly] = false;
				KvGetString(hKv, "admin-only", strBuffer, sizeof(strBuffer));
				if(strlen(strBuffer) > 0)
				{
					g_nGiants[iIndex][g_bGiantAdminOnly] = true;
				}

				KvGetString(hKv, "model", g_nGiants[iIndex][g_strGiantModel], MAXLEN_GIANT_STRING);
				if(strlen(g_nGiants[iIndex][g_strGiantModel]) <= 11 || !FileExists(g_nGiants[iIndex][g_strGiantModel], true) || PrecacheModel(g_nGiants[iIndex][g_strGiantModel]) == 0)
				{
					LogMessage("Template [%d] \"%s\" has invalid model: \"%s\"!", iIndex, g_nGiants[iIndex][g_strGiantName], g_nGiants[iIndex][g_strGiantModel]);
					bValidated = false;
				}

				KvGetString(hKv, "class", strBuffer, sizeof(strBuffer));
				g_nGiants[iIndex][g_nGiantClass] = TF2_GetClass(strBuffer);
				if(strlen(strBuffer) > 0 && g_nGiants[iIndex][g_nGiantClass] == TFClass_Unknown)
				{
					LogMessage("Template [%d] \"%s\" Invalid player class: \"%s\". Player class will be inherited.", iIndex, g_nGiants[iIndex][g_strGiantName], strBuffer);
				}

				g_nGiants[iIndex][g_iGiantHealth] = KvGetNum(hKv, "health");
				g_nGiants[iIndex][g_iGiantOverheal] = KvGetNum(hKv, "overheal");
				g_nGiants[iIndex][g_flGiantCapHealth] = KvGetFloat(hKv, "cap-health", -1.0);
				g_nGiants[iIndex][g_flGiantScale] = KvGetFloat(hKv, "scale", -1.0);

				KvGetString(hKv, "info", g_nGiants[iIndex][g_strGiantDesc], MAXLEN_GIANT_DESC);
				KvGetString(hKv, "hint", g_nGiants[iIndex][g_strGiantHint], MAXLEN_GIANT_DESC);

				int iTags = 0;
				KvGetString(hKv, "tag", strBufferTags, sizeof(strBufferTags));
				if(strlen(strBufferTags) <= 0) KvGetString(hKv, "tags", strBufferTags, sizeof(strBufferTags));
				if(strlen(strBufferTags) > 0)
				{
					char strExplode[MAX_GIANT_TAGS][MAXLEN_GIANT_TAG];
					int iNumExplode = ExplodeString(strBufferTags, ",", strExplode, MAX_GIANT_TAGS, MAXLEN_GIANT_TAG);
					if(iNumExplode > 0 && iNumExplode <= MAX_GIANT_TAGS)
					{
						for(int i=0; i<iNumExplode; i++)
						{
							TrimString(strExplode[i]);
							bool bFoundTag = false;
							
							for(int a=0; a<sizeof(g_strGiantTags); a++)
							{
								if(strcmp(strExplode[i], g_strGiantTags[a], false) == 0)
								{
									iTags |= (1 << a);
									bFoundTag = true;
									break;
								}
							}

							if(!bFoundTag)
							{
								LogMessage("Template [%d] \"%s\" has invalid tag: \"%s\"", iIndex, g_nGiants[iIndex][g_strGiantName], strExplode[i]);
							}
						}
					}else{
						LogMessage("Template [%d] \"%s\" has invalid number of tags: %d.", iIndex, g_nGiants[iIndex][g_strGiantName], iNumExplode);
					}
				}
				//LogMessage("Template [%d] \"%s\" Tags: %d",  iIndex, g_nGiants[iIndex][g_strGiantName], iTags);
				g_nGiants[iIndex][g_iGiantTags] = iTags;

				if(KvJumpToKey(hKv, "cond"))
				{
					if(KvGotoFirstSubKey(hKv, false))
					{
						do
						{
							KvGetSectionName(hKv, strBuffer, sizeof(strBuffer));
							float flCondDur = KvGetFloat(hKv, "", KEYVALUE_DEFAULT);
							int iCondIndex = StringToInt(strBuffer);
							if(iCondIndex < 0 || flCondDur == KEYVALUE_DEFAULT)
							{
								LogMessage("Template [%d] \"%s\" has invalid \"cond\": %d - %f!", iIndex, g_nGiants[iIndex][g_strGiantName], iCondIndex, flCondDur);
							}else{
								int iValues[2];
								iValues[ArrayCond_Index] = iCondIndex;
								iValues[ArrayCond_Duration] = view_as<int>(flCondDur);
								PushArrayArray(g_nGiants[iIndex][g_hGiantConditions], iValues, sizeof(iValues));
							}
						}while(KvGotoNextKey(hKv, false));

						KvGoBack(hKv);
					}

					KvGoBack(hKv);
				}

				if(KvJumpToKey(hKv, "PlayerAttributes"))
				{
					if(KvGotoFirstSubKey(hKv, false))
					{
						do
						{
							KvGetSectionName(hKv, strBuffer, sizeof(strBuffer));
							float flValue = KvGetFloat(hKv, "", KEYVALUE_DEFAULT);
							if(strlen(strBuffer) <= 3 || flValue == KEYVALUE_DEFAULT)
							{
								LogMessage("Template [%d] \"%s\" has invalid \"PlayerAttributes\" attribute: \"%s\" - %f!", iIndex, g_nGiants[iIndex][g_strGiantName], strBuffer, flValue);
							}else{
								PushArrayString(g_nGiants[iIndex][g_hGiantCharAttrib], strBuffer);
								PushArrayCell(g_nGiants[iIndex][g_hGiantCharAttribValue], flValue);
							}
						}while(KvGotoNextKey(hKv, false));

						KvGoBack(hKv);
					}

					KvGoBack(hKv);
				}

				char strWeaponKey[MAX_CONFIG_WEAPONS][] = {"WeaponPrimary", "WeaponSecondary", "WeaponMelee", "WeaponPDA", "WeaponPDA2", "WeaponPDA3"};

				// Active weapon when the giant is spawned.
				g_nGiants[iIndex][g_iGiantActiveSlot] = WeaponSlot_Primary;
				KvGetString(hKv, "active", strBuffer, sizeof(strBuffer));
				for(int i=0; i<sizeof(strWeaponKey); i++)
				{
					if(strcmp(strWeaponKey[i], strBuffer, false) == 0)
					{
						g_nGiants[iIndex][g_iGiantActiveSlot] = i;
						break;
					}
				}

				for(int i=0; i<sizeof(strWeaponKey); i++)
				{
					g_nGiants[iIndex][g_iGiantWeaponDefs][i] = WEAPON_ANY;

					KvGetString(hKv, strWeaponKey[i], strBuffer, sizeof(strBuffer));
					if(strcmp(strBuffer, "restrict", false) == 0)
					{
						g_nGiants[iIndex][g_iGiantWeaponDefs][i] = WEAPON_RESTRICT;
						continue;
					}

					if(KvJumpToKey(hKv, strWeaponKey[i]))
					{
						g_nGiants[iIndex][g_iGiantWeaponDefs][i] = KvGetNum(hKv, "itemdef", -1);
						if(g_nGiants[iIndex][g_iGiantWeaponDefs][i] == -1)
						{
							LogMessage("Template [%d] \"%s\" has invalid \"%s\" itemdef: %d!", iIndex, g_nGiants[iIndex][g_strGiantName], strWeaponKey[i], g_nGiants[iIndex][g_iGiantWeaponDefs][i]);
							bValidated = false;
						}

						KvGetString(hKv, "classname", strBuffer, sizeof(strBuffer));
						if(strlen(strBuffer) <= 3)
						{
							LogMessage("Template [%d] \"%s\" has invalid weapon \"%s\" classname: \"%s\"!", iIndex, g_nGiants[iIndex][g_strGiantName], strWeaponKey[i], strBuffer);
							bValidated = false;							
						}else{
							SetArrayString(g_nGiants[iIndex][g_hGiantClassnames], i, strBuffer);
						}

						g_nGiants[iIndex][g_bGiantWeaponBotRestricted][i] = false;
						KvGetString(hKv, "bot", strBuffer, sizeof(strBuffer));
						if(strBuffer[0] != '\0') g_nGiants[iIndex][g_bGiantWeaponBotRestricted][i] = true;

						if(KvJumpToKey(hKv, "WeaponAttributes"))
						{
							if(KvGotoFirstSubKey(hKv, false))
							{
								do
								{
									KvGetSectionName(hKv, strBuffer, sizeof(strBuffer));
									float flValue = KvGetFloat(hKv, "", KEYVALUE_DEFAULT);
									if(strlen(strBuffer) <= 3 || flValue == KEYVALUE_DEFAULT)
									{
										LogMessage("Template [%d] \"%s\" has invalid \"%s\" attribute: \"%s\" - %f!", iIndex, g_nGiants[iIndex][g_strGiantName], strWeaponKey[i], strBuffer, flValue);
									}else{
										PushArrayString(g_nGiants[iIndex][g_hGiantWeaponAttrib][i], strBuffer);
										PushArrayCell(g_nGiants[iIndex][g_hGiantWeaponAttribValue][i], flValue);
									}
								}while(KvGotoNextKey(hKv, false));

								KvGoBack(hKv);
							}

							KvGoBack(hKv);
						}

						KvGoBack(hKv);
					}
				}

				// Check that the template is valid and can be used
				g_nGiants[iIndex][g_bGiantTemplateEnabled] = bValidated;
				if(!bValidated)
				{
					LogMessage("Template [%d] \"%s\" has been disabled!", iIndex, g_nGiants[iIndex][g_strGiantName]);
				}

				iIndex++;
			}while(KvGotoNextKey(hKv));
		}
	}

	int iCount = 0;
	for(int i=0; i<MAX_NUM_TEMPLATES; i++) if(g_nGiants[i][g_bGiantTemplateEnabled]) iCount++;

	LogMessage("Found %d available giant template(s)!", iCount, iIndex);

	CloseHandle(hKv);
}

stock void Giant_PrintDebugTemplate(int iIndex)
{
	if(iIndex < 0 || iIndex >= MAX_NUM_TEMPLATES) return;

	PrintToServer("=============================================================");
	PrintToServer("%s (%d)", g_nGiants[iIndex][g_strGiantName], g_nGiants[iIndex][g_bGiantTemplateEnabled]);
	PrintToServer("=============================================================");
	PrintToServer(" model: %s", g_nGiants[iIndex][g_strGiantModel]);
	PrintToServer(" class: %d", g_nGiants[iIndex][g_nGiantClass]);
	PrintToServer(" health: %d", g_nGiants[iIndex][g_iGiantHealth]);
	PrintToServer(" overheal: %d", g_nGiants[iIndex][g_iGiantOverheal]);
	PrintToServer(" scale: %f", g_nGiants[iIndex][g_flGiantScale]);
	PrintToServer("=============================================================");
	char strAttributeName[MAXLEN_GIANT_STRING];
	float flAttribValue;
	for(int i=0,size=GetArraySize(g_nGiants[iIndex][g_hGiantCharAttrib]); i<size; i++)
	{
		GetArrayString(g_nGiants[iIndex][g_hGiantCharAttrib], i, strAttributeName, sizeof(strAttributeName));
		flAttribValue = GetArrayCell(g_nGiants[iIndex][g_hGiantCharAttribValue], i);
		PrintToServer(" \"%s\" %f", strAttributeName, flAttribValue);
	}
	
	for(int i=0; i<3; i++)
	{
		PrintToServer("=[SLOT %d]=====================================================", i);
		PrintToServer(" itemdef: %d", g_nGiants[iIndex][g_iGiantWeaponDefs][i]);
		switch(i)
		{
			case 0: PrintToServer(" classname: %s", g_nGiants[iIndex][g_strGiantPrimaryClassname]);
			case 1: PrintToServer(" classname: %s", g_nGiants[iIndex][g_strGiantSecondaryClassname]);
			case 2: PrintToServer(" classname: %s", g_nGiants[iIndex][g_strGiantMeleeClassname]);
		}
		PrintToServer("=[SLOT %d ATTRIBUTES]=========================================", i);
		for(int a=0; a<GetArraySize(g_nGiants[iIndex][g_hGiantWeaponAttrib][i]); a++)
		{
			GetArrayString(g_nGiants[iIndex][g_hGiantWeaponAttrib][i], a, strAttributeName, sizeof(strAttributeName));
			flAttribValue = GetArrayCell(g_nGiants[iIndex][g_hGiantWeaponAttribValue][i], a);
			PrintToServer(" \"%s\" %f", strAttributeName, flAttribValue);
		}
		PrintToServer("==============================================================");
	}
	PrintToServer("=[MISC ATTRIBUTES]============================================");
	for(int i=0,size=GetArraySize(g_nGiants[iIndex][g_hGiantWeaponAttrib][3]); i<size; i++)
	{
		GetArrayString(g_nGiants[iIndex][g_hGiantWeaponAttrib][3], i, strAttributeName, sizeof(strAttributeName));
		flAttribValue = GetArrayCell(g_nGiants[iIndex][g_hGiantWeaponAttribValue][3], i);
		PrintToServer(" \"%s\" %f", strAttributeName, flAttribValue);
	}
	PrintToServer("==============================================================");
}

/*
void Giant_UpdateHitbox(int client)
{
	// Updates the player's hitboxes based on their current m_flModelScale
	
	static float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 };
	static float vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	//static const float vecGenericPlayerMin[3] = { -16.5, -16.5, 0.0 }, float vecGenericPlayerMax[3] = { 16.5,  16.5, 73.0 };
	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3];
	
	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	
	float flModelScale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	
	ScaleVector(vecScaledPlayerMin, flModelScale);
	ScaleVector(vecScaledPlayerMax, flModelScale);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}
*/

void Giant_MakeGiantRobot(int client, int iIndex)
{
	// Preps the player to become a giant robot and respawns them where the cart resides
	
	if(iIndex < 0 || iIndex >= MAX_NUM_TEMPLATES)
	{
		LogMessage("Invalid giant template specified: %d!", iIndex);
		return;
	}

	Attributes_Clear(client);

	int team = GetClientTeam(client);
	int oppositeTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;

	TFClassType playerClass = TF2_GetPlayerClass(client);
	if(playerClass == TFClass_Unknown) playerClass = TFClass_DemoMan;

	TFClassType giantClass = g_nGiants[iIndex][g_nGiantClass];
	if(giantClass == TFClass_Unknown) giantClass = playerClass;

	// Respawn the player and move them to the tank spawn spot
	g_iClassOverride = client; // Flag this player as immune to class restrictions
	TF2_SetPlayerClass(client, giantClass, true, true);
	TF2_RespawnPlayer(client);
	g_iClassOverride = 0;

	// Sets the player's old class as the desired next class
	if(playerClass != TFClass_Unknown) SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", playerClass);

	// Set character attributes on the player
	char strAttributeName[MAXLEN_GIANT_STRING];
	float flAttribValue;
	for(int i=0,size=GetArraySize(g_nGiants[iIndex][g_hGiantCharAttrib]); i<size; i++)
	{
		GetArrayString(g_nGiants[iIndex][g_hGiantCharAttrib], i, strAttributeName, sizeof(strAttributeName));
		flAttribValue = GetArrayCell(g_nGiants[iIndex][g_hGiantCharAttribValue], i);
#if defined DEBUG
		PrintToServer("(TF2_MakeGiantRobot) Setting character attribute: %s -> %0.3f", strAttributeName, flAttribValue);
#endif
		Tank_SetAttributeValueByName(client, strAttributeName, flAttribValue);
	}

	// Give a level base of health for sentry busters of all classes.
	static int busterExtraHealth[10] = {
		0,
		50, // scout
		50, // sniper
		-25, // soldier
		0, // demoman
		25, // medic
		-125, // heavy
		0, // pyro
		50, // spy
		50, // engineer
	};
	int shimHealth = 0;
	if(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) shimHealth = busterExtraHealth[giantClass];

	// Set the max health attribute on the player to give the giant incresed health
	int maxHealth = RoundToNearest(float(g_nGiants[iIndex][g_iGiantHealth]) * Giant_GetScaleForPlayers(oppositeTeam)) + shimHealth;
	// Apply the "tank_giant_health_multiplier" config value.
	if(!(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
	{
		float healthMult = config.LookupFloat(g_hCvarGiantHealthMultiplier);
		if(healthMult != 1.0)
		{
#if defined DEBUG
			PrintToServer("(Giant_MakeGiantRobot) Scaling maxHealth from %d to %d!", maxHealth, RoundToNearest(float(maxHealth)*healthMult));
#endif
			maxHealth = RoundToNearest(float(maxHealth)*healthMult);
		}
	}
	Tank_SetAttributeValue(client, ATTRIB_HIDDEN_MAXHEALTH_NON_BUFFED, float(maxHealth));

	// Apply increased ammo attributes on the player
	Tank_SetAttributeValue(client, ATTRIB_MAXAMMO_PRIMARY_INCREASED, config.LookupFloat(g_hCvarGiantAmmoMultiplier));
	Tank_SetAttributeValue(client, ATTRIB_MAXAMMO_SECONDARY_INCREASED, config.LookupFloat(g_hCvarGiantAmmoMultiplier));
	
	// Check to see if a model was specified for this giants and apply it.
	if(strlen(g_nGiants[iIndex][g_strGiantModel]) > 3 && FileExists(g_nGiants[iIndex][g_strGiantModel], true))
	{
		SetVariantString(g_nGiants[iIndex][g_strGiantModel]);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
	
	// Set the appropriate model scale
	float scale = Giant_GetModelScale(iIndex);

	char modelScale[32];
	FloatToString(scale, modelScale, sizeof(modelScale));
	SetVariantString(modelScale);
	AcceptEntityInput(client, "SetModelScale");

	// Make sure the player's maxhealth is correct (this will be done again when weapons are given)
	int iMaxHealth = SDK_GetMaxHealth(client);
	if(iMaxHealth > 0)
	{
		SetEntityHealth(client, iMaxHealth);
	}

	// Flag the player as a miniboss
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 1);
	g_iGiantOldState[client] = MinigunState_Idle;

	// Without this, the giant will spawn as a ghost in hell
	if(g_nMapHack == MapHack_HightowerEvent && g_hellTeamWinner > 0)
	{
		TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
	}

	// Delay a frame or two to replace the players weapons, this is to prevent client crashes related to wearables
	CreateTimer(0.1, Timer_GiantReplaceWeapons, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

/***
 * Gets the appropriate model scale. If the scale is not specified in the template, it will return the scale set in stt.cfg. If it is not set in stt.cfg, it will return GIANT_DEFAULT_SCALE.
 *
 * @param templateIndex 		The giant template index to check.
 * @return float 				The giant template model scale.
 */
float Giant_GetModelScale(int templateIndex)
{
	// Get the appropriate model scale
	float scale = g_nGiants[templateIndex][g_flGiantScale];
	if(scale < 0.0)
	{
		// The scale was not specified in the template file. Grab the default from stt.cfg..
		scale = config.LookupFloat(g_hCvarDefaultGiantScale);
	}

	return scale;
}

float Giant_GetScaleForPlayers(int team)
{
	/* Calculate the scale for the giant's health based on this table:
		1-2: 15%
		3-4: 35%
		5-6: 50%
		7-8: 75%
		9-10: 85%
		11-12: 100%
		13-14: 115%
		15-16: 135%
	*/
	int iNumPlayers = CountPlayersOnTeam(team);
	float result = 1.35; // 15-16 players

	if(iNumPlayers <= 2)
	{
		result = 0.15;
	}else if(iNumPlayers <= 4)
	{
		result = 0.35;
	}else if(iNumPlayers <= 6)
	{
		result = 0.5;
	}else if(iNumPlayers <= 8)
	{
		result = 0.65;
	}else if(iNumPlayers <= 10)
	{
		result = 0.85;
	}else if(iNumPlayers <= 12)
	{
		result = 1.0;
	}else if(iNumPlayers <= 14)
	{
		result = 1.15;
	}

	// The minimum scale amount will be enforced in plr_
	if(g_nGameMode == GameMode_Race && result < config.LookupFloat(g_hCvarRaceGiantHealthMin)) result = config.LookupFloat(g_hCvarRaceGiantHealthMin);

	return result;
}

public Action Timer_GiantReplaceWeapons(Handle hTimer, any iUserId)
{
	// Check to see if the player is valid and is still allowed to be the giant
	int client = GetClientOfUserId(iUserId);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		Giant_GiveWeapons(client);
	}

	return Plugin_Handled;
}

void Giant_GiveWeapons(int client)
{
	int team = GetClientTeam(client);
	int iOppositeTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
	int iIndex = g_nSpawner[client][g_iSpawnerGiantIndex];

	char className[MAXLEN_GIANT_STRING];

	bool sentryBusterFixes = false;
	bool isBot = IsFakeClient(client);

	char auth[32];
	GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
	bool isSpecial = (strcmp(auth, "[U:1:13020913]") == 0 || strcmp(auth, "[U:1:16814162]") == 0); // IDs for Banshee and linux_lover.

	// Strip overrided weapons and apply them with the correct attributes
	for(int i=0; i<MAX_CONFIG_WEAPONS; i++)
	{
		if(g_nGiants[iIndex][g_iGiantWeaponDefs][i] == WEAPON_ANY) continue;
		if(g_nGiants[iIndex][g_iGiantWeaponDefs][i] == WEAPON_RESTRICT || (isBot && g_nGiants[iIndex][g_bGiantWeaponBotRestricted][i]))
		{
			// Remove any weapons or wearables in this slot.
			TF2_RemoveItemInSlot(client, i);

			continue;
		}
		
		GetArrayString(g_nGiants[iIndex][g_hGiantClassnames], i, className, sizeof(className));
		if(strlen(className) <= 0) continue; // Invalid classname so don't attempt to create the weapon.
		
		// Remove the weapon or wearable in the slot
		TF2_RemoveItemInSlot(client, i);
		
		// Create a new item with new attributes
		Handle hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
		
		TF2Items_SetClassname(hItem, className);
		TF2Items_SetItemIndex(hItem, g_nGiants[iIndex][g_iGiantWeaponDefs][i]);
		TF2Items_SetLevel(hItem, GetRandomInt(1, 100));
		if(team == TFTeam_Red)
		{
			TF2Items_SetQuality(hItem, QUALITY_COLLECTORS);
		}else{
			TF2Items_SetQuality(hItem, QUALITY_VINTAGE);
		}

		int numAttribs = 0;
		TF2Items_SetAttribute(hItem, numAttribs++, ATTRIB_KILLSTREAK_TIER, 1.0); // the standard killstreak tier
		if(i >= 0 && i <= 2 && config.LookupInt(g_hCvarWeaponInspect) >= 1) TF2Items_SetAttribute(hItem, numAttribs++, ATTRIB_WEAPON_ALLOW_INSPECT, 1.0); // Allows the weapon to be inspected by pressing 'f'.

		// Gives the mod creators Banshee and linux_lover weapons with self-made quality to make them feel special.
		if(isSpecial && i >= 0 && i <= 3)
		{
			TF2Items_SetQuality(hItem, QUALITY_SELFMADE);
			TF2Items_SetAttribute(hItem, numAttribs++, ATTRIB_PARTICLE_INDEX, 4.0);
		}

		TF2Items_SetNumAttributes(hItem, numAttribs);

		int iWeapon = TF2Items_GiveNamedItem(client, hItem);
		delete hItem;
		
		if(iWeapon > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Giant_GiveWeapons) Equipping \"%s\" (slot %d) (def %d): %d..", className, i, g_nGiants[iIndex][g_iGiantWeaponDefs][i], iWeapon);
#endif
			// Set the specified attributes on the weapon
			char strAttributeName[MAXLEN_GIANT_STRING];
			float flAttribValue;
			for(int a=0; a<GetArraySize(g_nGiants[iIndex][g_hGiantWeaponAttrib][i]); a++)
			{
				GetArrayString(g_nGiants[iIndex][g_hGiantWeaponAttrib][i], a, strAttributeName, sizeof(strAttributeName));
				flAttribValue = GetArrayCell(g_nGiants[iIndex][g_hGiantWeaponAttribValue][i], a);
#if defined DEBUG
				PrintToServer("(Giant_GiveWeapons) Setting weapon attribute on %d (slot %d): %s -> %0.3f", iWeapon, i, strAttributeName, flAttribValue);
#endif
				Tank_SetAttributeValueByName(iWeapon, strAttributeName, flAttribValue);
			}

			// Some class-related fixes that come from allowing any class to be the sentry buster.
			if(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER && !sentryBusterFixes)
			{
				sentryBusterFixes = true;

				if(TF2_GetPlayerClass(client) == TFClass_Medic)
				{
					Tank_SetAttributeValue(iWeapon, ATTRIB_HEALTH_DRAIN, -10.0);
				}
			}

			// Without this, sappers cannot be drawn.
			if(strcmp(className, "tf_weapon_sapper") == 0)
			{
				SetEntProp(iWeapon, Prop_Send, "m_iObjectType", 3);
				SetEntProp(iWeapon, Prop_Data, "m_iSubType", 3);
			}

			if(strncmp(className, "tf_wearable", 11) == 0)
			{
				SDK_EquipWearable(client, iWeapon);
			}else{
				EquipPlayerWeapon(client, iWeapon);
				
				// Make sure the weapon has the correct amount of ammo
				int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
				if(iAmmoType > -1)
				{
					int iMaxAmmo = SDK_GetMaxAmmo(client, iAmmoType);
					SetEntProp(client, Prop_Send, "m_iAmmo", iMaxAmmo, 4, iAmmoType);
				}

				// Make sure the weapon has the correct clip size as well
				if(g_nGiants[iIndex][g_iGiantWeaponDefs][i] != ITEM_BAZOOKA)
				{
					int iClip = SDK_GetMaxClip(iWeapon);
					if(iClip > 0)
					{
						SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip);
					}
				}
			}

			Giant_FlagWeaponDontDrop(iWeapon);
		}

	}

	Giant_ApplyConditions(client, iIndex);

	if(Spawner_HasGiantTag(client, GIANTTAG_FILL_UBER))
	{
		int iSecondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		if(iSecondary > MaxClients)
		{
			char strClassname[32];
			GetEdictClassname(iSecondary, strClassname, sizeof(strClassname));
			if(strcmp(strClassname, "tf_weapon_medigun") == 0)
			{
#if defined DEBUG
				PrintToServer("(Giant_GiveWeapons) Found tag \"fill_uber\", setting charge to 98%%!");
#endif
				SetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel", 0.98);
			}
		}
	}

	if(!(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
	{
		// Buildings are not destroyed when the wrench is removed as of the Gun Mettle update.
		Player_RemoveBuildings(client);

		// Remove the giant health bar when the spy disguises.
#if defined _SENDPROXYMANAGER_INC_
		if(g_hasSendProxy)
		{
			if(g_nGiants[iIndex][g_nGiantClass] == TFClass_Spy)
			{
				SendProxy_Hook(client, "m_bIsMiniBoss", Prop_Int, SendProxy_ToggleGiantHealthMeter);
			}
		}
#endif
	}

	if(g_nGiants[iIndex][g_nGiantClass] == TFClass_Engineer)
	{
		// Apply misc. attributes to the construction pda
		float flTeleHealthBonus = 1.0;
		int iPDA = GetPlayerWeaponSlot(client, WeaponSlot_PDABuild);
		if(iPDA > MaxClients)
		{
			char strClassname[40];
			GetEdictClassname(iPDA, strClassname, sizeof(strClassname));
			if(strcmp(strClassname, "tf_weapon_pda_engineer_build") == 0)
			{
				float flBuildingHealthMult;
				if(Tank_GetAttributeValue(iPDA, ATTRIB_BUILDING_HEALTH_BONUS, flBuildingHealthMult))
				{
					flTeleHealthBonus = flBuildingHealthMult;

					// Scale building health with player count
					flBuildingHealthMult -= 1.0;
					flBuildingHealthMult *= Giant_GetScaleForPlayers(iOppositeTeam);
					flBuildingHealthMult += 1.0;
#if defined DEBUG
					PrintToServer("(Giant_GiveWeapons) Scaling building health bonus from %f to %f!", flTeleHealthBonus, flBuildingHealthMult);
#endif
					Tank_SetAttributeValue(iPDA, ATTRIB_BUILDING_HEALTH_BONUS, flBuildingHealthMult);
					flTeleHealthBonus = flBuildingHealthMult;
				}
			}else{
				LogMessage("(Giant_GiveWeapons) Failed to find player's build pda.");
			}

			// Set the quality to unique so the item appears on the loadout hud
			if(GetEntProp(iPDA, Prop_Send, "m_iEntityQuality") == QUALITY_NORMAL) SetEntProp(iPDA, Prop_Send, "m_iEntityQuality", QUALITY_UNIQUE);
		}

		// All the engineer's buildings should be destroyed from giving a new wrench
		// Spawn a teleporter entrance that is linked with the giant, we need this link to teleport players on the exit
		float flPos[3];
		GetClientAbsOrigin(client, flPos);
		flPos[2] -= 3000.0; // Spawn outside the map, out of view

		int iTeleHealth = 150;
		iTeleHealth = RoundToNearest(float(iTeleHealth) * flTeleHealthBonus);
		Teleporter_BuildEntrance(client, flPos, iTeleHealth);
	}

	// Make sure the player's maxhealth is correct
	int overheal = RoundToNearest(float(g_nGiants[iIndex][g_iGiantOverheal]) * Giant_GetScaleForPlayers(iOppositeTeam));
	int maxHealth = SDK_GetMaxHealth(client);
	// Apply the "tank_giant_health_multiplier" config value.
	if(!(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
	{
		float healthMult = config.LookupFloat(g_hCvarGiantHealthMultiplier);
		if(healthMult != 1.0)
		{
	#if defined DEBUG
			PrintToServer("(Giant_GiveWeapons) Scaling overheal health from %d to %d!", overheal, RoundToNearest(float(overheal)*healthMult));
	#endif
			overheal = RoundToNearest(float(overheal)*healthMult);
		}
	}
	if(overheal < 0) overheal = 0;
	SetEntityHealth(client, maxHealth+overheal);

	PrintToChatAll("%t", "Tank_Chat_Giant_Spawned", g_strTeamColors[team], client, 0x01, "\x07FFD700", g_nGiants[iIndex][g_strGiantName], "\x07CF7336", maxHealth+overheal, 0x01);

	Player_FixVaccinator(client);

	// Enforce the giant's active weapon
	int perferred = GetPlayerWeaponSlot(client, g_nGiants[iIndex][g_iGiantActiveSlot]);
	if(perferred > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(Giant_GiveWeapons) Active weapon slot %d, entity %d!", g_nGiants[iIndex][g_iGiantActiveSlot], perferred);
#endif
		SDK_SwitchWeapon(client, perferred);
	}else{
		for(int i=0; i<3; i++)
		{
			int weapon = GetPlayerWeaponSlot(client, i);
			if(weapon > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Giant_GiveWeapons) Active weapon slot %d, entity %d!", i, weapon);
#endif
				SDK_SwitchWeapon(client, weapon);
				break;
			}
		}
	}

	// Makes sure the player's class and effect huds is updated.
	Handle msg = StartMessageOne("PlayerPickupWeapon", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(msg != null)
	{
		EndMessage();
	}
}

void Giant_ApplyConditions(int client, int templateIndex)
{
	for(int i=0,size=GetArraySize(g_nGiants[templateIndex][g_hGiantConditions]); i<size; i++)
	{
		int iValues[2];
		GetArrayArray(g_nGiants[templateIndex][g_hGiantConditions], i, iValues, sizeof(iValues));
		float flDuration = view_as<float>(iValues[ArrayCond_Duration]);
#if defined DEBUG
		PrintToServer("(Giant_ApplyConditions) Setting condition on %N: %d - %f", client, iValues[ArrayCond_Index], flDuration);
#endif
		if(flDuration < 0.0) flDuration = -1.0;
		TF2_AddCondition(client, view_as<TFCond>(iValues[ArrayCond_Index]), flDuration);
	}	
}

void Giant_PlayDestructionSound(int client)
{
	int iIndex = g_nSpawner[client][g_iSpawnerGiantIndex];
	int team = GetClientTeam(client);

	// Play sounds when the giant has been killed
	if(!(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		for(int i=2; i<=3; i++)
		{
			if(team == i)
			{
				// Alert the giant's team that he died
				BroadcastSoundToTeam(i, "MVM.PlayerDied");
			}else{
				// Alert the opposite team that the giant has died
				BroadcastSoundToTeam(i, "MVM.PlayerUsedPowerup");
			}
		}
	}

	// Play sounds indicating that a giant has perished.
	if(g_timePlayedDestructionSound == 0.0 || GetEngineTime() - g_timePlayedDestructionSound > 1.0)
	{
		g_timePlayedDestructionSound = GetEngineTime();

		EmitSoundToAll(SOUND_GIANT_EXPLODE);
	}
}

void Giant_Clear(int client, int reason=0)
{
#if defined DEBUG
	PrintToServer("(Giant_Clear) Clearing giant %N..", client);
#endif

	int team = GetClientTeam(client);
	int iIndex = g_nSpawner[client][g_iSpawnerGiantIndex];

	if(!Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER) && (reason != GiantCleared_Misc))
	{
		// Pick an MVP only when the giant dies or disconnects
		Giant_PickMVP(client, reason);

		// Spawn some gibs when the giant robot is defeated.
		if(reason == GiantCleared_Death)
		{
			Giant_SpawnGibs(client);

			g_bBlockRagdoll = true;
		}
	}

	Spawner_Cleanup(client);
	
	// Remove all effects and flags for giants
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 0);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	// Restore edict flags if modified
	int iFlags = GetEdictFlags(client);
	if(iFlags & FL_EDICT_ALWAYS)
	{
		iFlags &= ~FL_EDICT_ALWAYS;
		SetEdictFlags(client, iFlags);
	}

	switch(team)
	{
		case TFTeam_Blue: Robot_Toggle(client, true);
		case TFTeam_Red:
		{
			// Player player models will be used in plr_ maps
			if(g_nGameMode == GameMode_Race)
			{
				Robot_Toggle(client, true);
			}else{
				Robot_Toggle(client, false);
			}
		}
	}

	// Check if the giant is being tracked by the team giant object and if so clear it.
	for(int i=2; i<=3; i++)
	{
		if(g_nTeamGiant[i][g_bTeamGiantActive] && g_nTeamGiant[i][g_iTeamGiantQueuedUserId] != 0 && g_nTeamGiant[i][g_iTeamGiantQueuedUserId] == GetClientUserId(client))
		{
			// clear out the queued userid which will force the team giant spawner to find another valid giant and deactivate itself if past the cuttoff period
			g_nTeamGiant[i][g_iTeamGiantQueuedUserId] = 0;
		}
	}
	
	SetVariantString("1.0");
	AcceptEntityInput(client, "SetModelScale");
	
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
	
	if(strlen(g_strSoundGiantLoop[g_nGiants[iIndex][g_nGiantClass]]) > 3) StopSound(client, SNDCHAN_AUTO, g_strSoundGiantLoop[g_nGiants[iIndex][g_nGiantClass]]);
	StopSound(client, SNDCHAN_AUTO, SOUND_BUSTER_LOOP);

	// Remove the character attributes on the player
	char strAttributeName[MAXLEN_GIANT_STRING];
	for(int i=0,size=GetArraySize(g_nGiants[iIndex][g_hGiantCharAttrib]); i<size; i++)
	{
		GetArrayString(g_nGiants[iIndex][g_hGiantCharAttrib], i, strAttributeName, sizeof(strAttributeName));
#if defined DEBUG
		PrintToServer("(Giant_Clear) Removing character attribute: %s!", strAttributeName);
#endif
		Tank_RemoveAttributeByName(client, strAttributeName);
	}
	
	for(int i=0,size=GetArraySize(g_nGiants[iIndex][g_hGiantConditions]); i<size; i++)
	{
		int iValues[2];
		GetArrayArray(g_nGiants[iIndex][g_hGiantConditions], i, iValues, sizeof(iValues));
#if defined DEBUG
		PrintToServer("(Giant_Clear) Removing condition: %d!", iValues[ArrayCond_Index]);
#endif
		TF2_RemoveCondition(client, view_as<TFCond>(iValues[ArrayCond_Index]));
	}

	Tank_RemoveAttribute(client, ATTRIB_HIDDEN_MAXHEALTH_NON_BUFFED);
	Tank_RemoveAttribute(client, ATTRIB_MAXAMMO_PRIMARY_INCREASED);
	Tank_RemoveAttribute(client, ATTRIB_MAXAMMO_SECONDARY_INCREASED);
	Tank_RemoveAttribute(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS);
	Tank_RemoveAttribute(client, ATTRIB_MAJOR_INCREASED_JUMP_HEIGHT);
	Tank_RemoveAttribute(client, ATTRIB_REDUCED_HEALING_FROM_MEDIC);

	// This is an attempt to fix overheal and ammo carrying over when a giant dies and respawns.
	SetEntityHealth(client, 25);
	TF2_RegeneratePlayer(client);

	if(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_TELEPORTER && g_nGiants[iIndex][g_nGiantClass] == TFClass_Engineer)
	{
		GiantTeleporter_Cleanup(team);
	}

	if(!(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
	{
		Player_RemoveBuildings(client);
	}

	if(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_MINIGUN_SOUNDS)
	{
		EmitSoundToAll("misc/null.wav", client, SNDCHAN_WEAPON);
	}

	SDK_HealRadius(client, false);
	RageMeter_Cleanup(client);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);

	// Switch the player's class back as soon as they die.
	if(!IsPlayerAlive(client))
	{
		int desiredClass = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
		if(desiredClass >= 1 && desiredClass <= 9)
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(desiredClass));
		}
	}

#if defined _SENDPROXYMANAGER_INC_
	if(g_hasSendProxy)
	{
		SendProxy_Unhook(client, "m_bIsMiniBoss", SendProxy_ToggleGiantHealthMeter);
	}
#endif
}

int Giant_PickTemplate()
{
	int iForcedTemplate = config.LookupInt(g_hCvarGiantForce);

	if(iForcedTemplate != -1 && iForcedTemplate >= 0 && iForcedTemplate < MAX_NUM_TEMPLATES && g_nGiants[iForcedTemplate][g_bGiantTemplateEnabled] && !(g_nGiants[iForcedTemplate][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)) return iForcedTemplate;

	Handle hArray = CreateArray();
	for(int i=0; i<MAX_NUM_TEMPLATES; i++)
	{
		if(g_nGiants[i][g_bGiantTemplateEnabled] && !g_nGiants[i][g_bGiantAdminOnly] && !(g_nGiants[i][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) 
			&& (g_hellTeamWinner == 0 || !(g_nGiants[i][g_iGiantTags] & GIANTTAG_DONT_SPAWN_IN_HELL)))
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

int Giant_PickPlayer(int team)
{
	int iResource = GetPlayerResourceEntity();
	if(iResource <= MaxClients) return 0;
	
	// Pick the top player that hasn't been picked yet
	int iMaxIndex = 0;
	int iMaxPoints = -1024;

	int lastIndex = 0;
	int lastTime = -1;

	ArrayList bots = new ArrayList();

	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && !g_bBusterPassed[i] && !(g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[i][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)))
		{
			if(!IsFakeClient(i))
			{
				// Give human players preference.
				int score = GetEntProp(iResource, Prop_Send, "m_iTotalScore", 4, i);

				if(g_giantTracker.canPlayGiant(i))
				{
					if(score > iMaxPoints)
					{
						iMaxIndex = i;
						iMaxPoints = score;
					}
				}

				// There are no eligible giants so instead pick the player that has gone the longest without being the giant.
				char auth[MAXLEN_LASTGIANT];
				GetClientAuthId(i, AuthId_Steam3, auth, sizeof(auth));

				int timeLastGiant = 0;
				g_giantTracker.GetValue(auth, timeLastGiant);
				if(lastTime == -1 || timeLastGiant < lastTime)
				{
					lastIndex = i;
					lastTime = timeLastGiant;
				}
			}else{
				// Player is a bot.
				// If no players can be picked, go with a random bot.
				bots.Push(i);
			}
		}
	}

	int botIndex = 0;
	if(bots.Length > 0) botIndex = bots.Get(GetRandomInt(0, bots.Length-1));
	delete bots;

	if(iMaxIndex != 0) return iMaxIndex;
	if(lastIndex != 0) return lastIndex;
	if(botIndex != 0) return botIndex;

	return 0;
}

/*
Giant_PickPlayer(team)
{
	new iResource = GetPlayerResourceEntity();
	if(iResource <= MaxClients) return 0;
	
	// Pick a random player from the top x players on a team
	Handle hArrayTopPlayers = CreateArray();

	// Determine how many players with the top score we want to add
	new iNumPlayers = CountPlayersOnTeam(team);
	new iMaxToPick = RoundToCeil(float(iNumPlayers) * config.LookupFloat(g_hCvarBombTop));
	for(int iMax=0; iMax<iMaxToPick; iMax++)
	{
		new iMaxIndex = 0;
		new iMaxPoints = -1;
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == team && g_giantTracker.canPlayGiant(i) && !g_bBusterPassed[i] && !(g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && g_nSpawner[i][g_iSpawnerGiantIndex] != GiantRobot_SentryBuster))
			{
				bool bAlreadyPicked = false;
				// Make sure we haven't picked this person before
				for(int a=0; a<GetArraySize(hArrayTopPlayers); a++)
				{
					if(GetArrayCell(hArrayTopPlayers, a) == i)
					{
						bAlreadyPicked = true;
						break;
					}
				}
				if(bAlreadyPicked) continue;
				
				new iScore = GetEntProp(iResource, Prop_Send, "m_iTotalScore", 4, i);
				if(iScore > iMaxPoints)
				{
					iMaxIndex = i;
					iMaxPoints = iScore;
				}
			}
		}
		
		if(iMaxIndex > 0)
		{
			PushArrayCell(hArrayTopPlayers, iMaxIndex);
		}else{
			// We've ran out of players to pick
			break;
		}
	}
	
	if(GetArraySize(hArrayTopPlayers) <= 0)
	{
		// There are no more players to pick. This probably happened because too many players are flagged as already played the giant.
		// So pick a random person on the BLU team. If this fails.. there is probably no one on BLU.
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == team && !g_bBusterPassed[i] && !(g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && g_nSpawner[i][g_iSpawnerGiantIndex] != GiantRobot_SentryBuster))
			{
				PushArrayCell(hArrayTopPlayers, i);
			}
		}

		if(GetArraySize(hArrayTopPlayers) <= 0)
		{
			CloseHandle(hArrayTopPlayers);
			return 0;
		}
	}
	
	new iRandomPlayer = GetArrayCell(hArrayTopPlayers, GetRandomInt(0, GetArraySize(hArrayTopPlayers)-1));
	CloseHandle(hArrayTopPlayers);

	return iRandomPlayer;
}
*/

void Giant_StripWearables(int client)
{
	// Kill all wearables on the giant
	int iEntity = MaxClients+1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) > MaxClients)
	{
		if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == client)
		{
#if defined DEBUG
			PrintToServer("(Giant_StripWearables) Killing \"tf_wearable\"(def %d) for %N: %d!", GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex"), client, iEntity);
#endif
			SDK_RemoveWearable(client, iEntity);
			AcceptEntityInput(iEntity, "Kill");
		}
	}

	iEntity = MaxClients+1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) > MaxClients)
	{
		if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == client)
		{
#if defined DEBUG
			PrintToServer("(Giant_StripWearables) Killing \"tf_powerup_bottle\"(def %d) for %N: %d!", GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex"), client, iEntity);
#endif
			SDK_RemoveWearable(client, iEntity);
			AcceptEntityInput(iEntity, "Kill");
		}
	}
}

void Giant_Cleanup(int team)
{
	g_nTeamGiant[team][g_bTeamGiantActive] = false;
	g_nTeamGiant[team][g_iTeamGiantQueuedUserId] = 0;
	g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn] = 0.0;
	g_nTeamGiant[team][g_iTeamGiantTemplateIndex] = -1;
	g_nTeamGiant[team][g_flTeamGiantTimeSpawned] = 0.0;
	g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts] = 0.0;
	g_nTeamGiant[team][g_flTeamGiantTimeLastAngleChg] = 0.0;
	for(int i=0; i<3; i++) g_nTeamGiant[team][g_flTeamGiantViewAngles][i] = 0.0;
	g_nTeamGiant[team][g_iTeamGiantButtons] = 0;
	g_nTeamGiant[team][g_bTeamGiantAlive] = false;
	g_nTeamGiant[team][g_bTeamGiantPanelShown] = false;
	g_nTeamGiant[team][g_bTeamGiantNoRageMeter] = false;
	g_nTeamGiant[team][g_bTeamGiantNoCritCash] = false;
}

void Giant_Think(int team)
{
	// Not active yet - giant is not allowed to spawn right now
	if(!g_nTeamGiant[team][g_bTeamGiantActive]) return;

	float flTime = GetEngineTime();
	// Just in case the spawn time hasn't been initialized yet
	if(g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts] == 0.0) g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts] = flTime + config.LookupFloat(g_hCvarTankCooldown) - 5.0;
	// Initialize the giant robot template that will be used
	if(g_nTeamGiant[team][g_iTeamGiantTemplateIndex] == -1) g_nTeamGiant[team][g_iTeamGiantTemplateIndex] = Giant_PickTemplate();
	if(g_nTeamGiant[team][g_iTeamGiantTemplateIndex] == -1) return; // Failed to find a valid template

	int client = 0;
	bool bIsValid = false;
	if(g_nTeamGiant[team][g_iTeamGiantQueuedUserId] != 0)
	{
		// Check if the queued player is still valid
		client = GetClientOfUserId(g_nTeamGiant[team][g_iTeamGiantQueuedUserId]);
		if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team)
		{
			bIsValid = true;

			// Check to see if the player wants to pass the giant (don't bother checking for this after they spawn)
			if(g_bBusterPassed[client] && g_nTeamGiant[team][g_flTeamGiantTimeSpawned] == 0.0 && !IsFakeClient(client))
			{
				// If they've already spawned, it's too late
				bIsValid = false;
				g_nTeamGiant[team][g_iTeamGiantQueuedUserId] = 0;
			}
		}else{
			g_nTeamGiant[team][g_iTeamGiantQueuedUserId] = 0;
		}
	}

	if(!bIsValid)
	{
		HealthBar_Hide();
		// Check to see if too must time has passed since the bomb round has started, if so deactivate the team giant spawner which will allow normal robot carriers to pickup the bomb
		if(flTime > g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts] + config.LookupFloat(g_hCvarGiantWarnCutoff))
		{
#if defined DEBUG
			PrintToServer("(Giant_Think) Cutoff period has been reached, team %d now disabled.", team);
#endif
			g_nTeamGiant[team][g_bTeamGiantActive] = false;
			return;
		}

		// Choose another player to become the giant robot
		client = Giant_PickPlayer(team);
		if(client >= 1 && client <= MaxClients)
		{
			g_nTeamGiant[team][g_iTeamGiantQueuedUserId] = GetClientUserId(client);
			g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn] = 0.0;
			g_nTeamGiant[team][g_flTeamGiantTimeSpawned] = 0.0;
			g_nTeamGiant[team][g_bTeamGiantAlive] = false;

			// Set the time that the giant robot will spawn next
			if(flTime < g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts])
			{
				// Always prefer the time in which the round would naturally start, (when the countdown would begin)
				g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn] = g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts];
			}else{
				// Start spawning the giant in a few seconds, specified by tank_giant_warn_time
				g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn] = flTime + config.LookupFloat(g_hCvarGiantWarnTime);
			}

			// Warn the player as soon as they are selected by showing an annotation.
			if(!IsFakeClient(client))
			{
				Handle hEvent = CreateEvent("show_annotation");
				if(hEvent != INVALID_HANDLE)
				{
					float flPos[3];
					int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[TFTeam_Blue]);
					if(iTrackTrain > MaxClients)
					{
						GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPos);
					}
					
					if(team == TFTeam_Red)
					{
						SetEventInt(hEvent, "id", Annotation_GiantPickedRed);
					}else{
						SetEventInt(hEvent, "id", Annotation_GiantPickedBlue);
					}
					
					SetEventFloat(hEvent, "worldPosX", flPos[0]);
					SetEventFloat(hEvent, "worldPosY", flPos[1]);
					SetEventFloat(hEvent, "worldPosZ", flPos[2]);
					SetEventFloat(hEvent, "lifetime", config.LookupFloat(g_hCvarGiantWarnTime));
					SetEventString(hEvent, "play_sound", "misc/null.wav");
					
					char text[256];
					Format(text, sizeof(text), "%T", "Tank_Annotation_Giant_Warning", client, RoundToNearest(g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn] - flTime));
					SetEventString(hEvent, "text", text);
					
					SetEventInt(hEvent, "visibilityBitfield", (1 << client)); // Only the player becoming the giant should see this message
					FireEvent(hEvent); // Clears the handle
				}
			}

			PrintToChat(client, "%t", "Tank_Chat_Giant_Warning", 0x01, g_strTeamColors[team], 0x01, 0x04, RoundToNearest(g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn] - flTime), 0x01);

			// Only show the panel once to the team.
			if(!g_nTeamGiant[team][g_bTeamGiantPanelShown])
			{
				g_nTeamGiant[team][g_bTeamGiantPanelShown] = true;

				for(int i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i) == team)
					{
						if(Settings_ShouldShowGiantInfoPanel(i))
						{
							Giant_ShowDesc(i, g_nTeamGiant[team][g_iTeamGiantTemplateIndex], false, client);
						}else{
							PrintToChat(i, "%t", "Tank_Chat_ShowGiantInfo", 0x01, g_strTeamColors[team], client, 0x01, g_strRankColors[Rank_Unique], g_nGiants[g_nTeamGiant[team][g_iTeamGiantTemplateIndex]][g_strGiantName],0x01);
						}
					}
				}
			}
		}

		return;
	}

	// We have a valid giant, check if it is time to spawn
	if(flTime > g_nTeamGiant[team][g_flTeamGiantTimeNextSpawn])
	{
		// It is time to spawn the giant

		// Check if the giant has already been spawned
		if(g_nTeamGiant[team][g_flTeamGiantTimeSpawned] == 0.0)
		{
			// Giant hasn't been spawned yet
			// We are ready to begin the player giant spawn process!
			int flags = 0;
			if(!g_nTeamGiant[team][g_bTeamGiantNoRageMeter]) flags |= SPAWNERFLAG_RAGEMETER;
			if(g_nMapHack == MapHack_HightowerEvent && g_hellTeamWinner > 0) flags |= SPAWNERFLAG_NOPUSHAWAY;
			Spawner_Spawn(client, Spawn_GiantRobot, g_nTeamGiant[team][g_iTeamGiantTemplateIndex], flags);

			g_nTeamGiant[team][g_iTeamGiantQueuedUserId] = GetClientUserId(client); // Since the userid might be cleared during Spawner_Spawn if the player is already a giant

			// Save the time when the giant is spawned so we can watch over the giant and choose another if he becomes invalid before the cutoff time
			g_nTeamGiant[team][g_flTeamGiantTimeSpawned] = flTime;

			// Set a flag so this player won't be chosen again for awhile.
			g_giantTracker.applyCooldown(client);
		}else{
			// Giant has already started spawned

			// Check if the giant has gone AFK after spawning
			// First, check can another giant spawn?
			if(flTime < g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts] + config.LookupFloat(g_hCvarGiantWarnCutoff))
			{
				// Wait until the giant is spawned to determine if they've got AFK
				if(!IsFakeClient(client) && g_nTeamGiant[team][g_bTeamGiantAlive])
				{
					if(flTime - g_nTeamGiant[team][g_flTeamGiantTimeLastAngleChg] > config.LookupFloat(g_hCvarGiantTimeAFK))
					{
						// Giant has been alive and AFK too long - kill the player and hopefully trigger another giant spawn
						PrintToChatAll("%t", "Tank_Chat_Giant_AFK", 0x01, g_strTeamColors[GetClientTeam(client)], client, 0x01);

						StatsGiant_Reset(client); // Doing this prevents prevents a MVP from being chosen.
						FakeClientCommand(client, "explode");
						ForcePlayerSuicide(client);

						g_nTeamGiant[team][g_iTeamGiantQueuedUserId] = 0;
						return;
					}else{
						// Run a check to see if the giant's viewangles have changed enough
						float flDiff = 0.0;
						float flAng[3];
						GetClientEyeAngles(client, flAng);
						for(int i=0; i<3; i++)
						{
							flDiff += FloatAbs(flAng[i] - g_nTeamGiant[team][g_flTeamGiantViewAngles][i]);
						}

						int iCurrentButtons = GetClientButtons(client);

						if(flDiff > 0.1 || g_nTeamGiant[team][g_iTeamGiantButtons] != iCurrentButtons)
						{
							// Giant has proven NOT be AFK so reset the AFK time
							g_nTeamGiant[team][g_flTeamGiantTimeLastAngleChg] = flTime;
							//PrintToServer("(Giant_Think) Diff: %f", flDiff);
						}

						// Set the current view angles for future testing
						for(int i=0; i<3; i++) g_nTeamGiant[team][g_flTeamGiantViewAngles][i] = flAng[i];
						g_nTeamGiant[team][g_iTeamGiantButtons] = iCurrentButtons;
					}
				}
			}

			// Set a flag when the giant is respawned and ready to fight
			if(IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				if(!g_nTeamGiant[team][g_bTeamGiantAlive])
				{
					// Giant is now alive so get a snapshot of the player to track if they go AFK
					g_nTeamGiant[team][g_bTeamGiantAlive] = true;

					// Save a record of the giant's view angles so we can judge whether they have moved or not
					g_nTeamGiant[team][g_flTeamGiantTimeLastAngleChg] = flTime;
					float flAng[3];
					GetClientEyeAngles(client, flAng);
					for(int i=0; i<3; i++) g_nTeamGiant[team][g_flTeamGiantViewAngles][i] = flAng[i];

					// Save a record of the giant's buttons as well
					g_nTeamGiant[team][g_iTeamGiantButtons] = GetClientButtons(client);
				}
			}

			// Show the giant's health in bomb deploy mode
			if(g_nGameMode == GameMode_BombDeploy && g_nTeamGiant[team][g_bTeamGiantAlive])
			{
				
				int healthBar = HealthBar_FindOrCreate();
				if(healthBar > MaxClients)
				{
					int health = GetClientHealth(client);
					int maxHealth = SDK_GetMaxHealth(client);

					bool greenBar = (TF2_IsPlayerInCondition(client, TFCond_Healing) || health > maxHealth);
					int healthBarValue = RoundToCeil(float(health) / float(maxHealth) * 255.0);
					if(healthBarValue > 255) healthBarValue = 255;
					
					SetEntProp(healthBar, Prop_Send, "m_iBossHealthPercentageByte", healthBarValue);
					SetEntProp(healthBar, Prop_Send, "m_iBossState", (greenBar == true) ? 1 : 0);
				}
			}else{
				HealthBar_Hide();
			}
		}
	}
}

void Giant_PickMVP(int giant, int clearReason=0)
{
	// Print a message that shows who dealt the most damage to the giant
	int mvp, maxHealth;
	for(int i=1; i<=MaxClients; i++)
	{
		maxHealth += g_iDamageStatsGiant[giant][i];

		if(g_iDamageStatsGiant[giant][i] > g_iDamageStatsGiant[giant][mvp])
		{
			mvp = i;
		}
	}

	char reason[32] = "died";
	switch(clearReason)
	{
		case GiantCleared_Disconnect: reason = "disconnected";
		case GiantCleared_Deploy: reason = "deployed";
	}

	if(mvp >= 1 && mvp <= MaxClients && IsClientInGame(mvp))
	{
		PrintToChatAll("%t", "Tank_Chat_Giant_MVP", 0x01, g_strTeamColors[GetClientTeam(giant)], giant, 0x01, reason, g_strTeamColors[GetClientTeam(mvp)], mvp, "\x07CF7336", g_iDamageStatsGiant[giant][mvp], 0x01, 0x04, RoundToCeil(float(g_iDamageStatsGiant[giant][mvp])/float(maxHealth)*100.0));

		// Log an event so hlstats can pick it up
		char strAuth[32];
		GetClientAuthId(mvp, AuthId_Steam3, strAuth, sizeof(strAuth));
		
		char logEvent[32] = "giant_mvp";
		if(g_nGameMode == GameMode_Race) logEvent = "giant_mvp_race";

		LogToGame("\"%N<%d><%s><%s>\" triggered \"%s\"", mvp, GetClientUserId(mvp), strAuth, g_strTeamClass[GetClientTeam(mvp)], logEvent);
	}

	// Reset stats
	StatsGiant_Reset(giant);
}

void Giant_ShowMain(int client, bool bForceMain=false)
{
	// If the player's team currently has a giant queued, show them that giant info panel first.
	if(!bForceMain)
	{
		int team = GetClientTeam(client);
		if((team == TFTeam_Red || team == TFTeam_Blue) && g_nTeamGiant[team][g_bTeamGiantActive])
		{
			int giant = GetClientOfUserId(g_nTeamGiant[team][g_iTeamGiantQueuedUserId]);
			if(giant >= 1 && giant <= MaxClients && IsClientInGame(giant))
			{
				if(g_nGiants[g_nTeamGiant[team][g_iTeamGiantTemplateIndex]][g_bGiantTemplateEnabled])
				{
					Giant_ShowDesc(client, g_nTeamGiant[team][g_iTeamGiantTemplateIndex], true, giant);
					return;
				}
			}
		}
	}

	Handle hMenu = CreateMenu(MenuHandler_Main);

	int iCount = 0;
	for(int i=0; i<MAX_NUM_TEMPLATES; i++)
	{
		if(!g_nGiants[i][g_bGiantTemplateEnabled]) continue;
		if(g_nGiants[i][g_strGiantDesc][0] == '\0') continue;
		if(g_nGiants[i][g_bGiantAdminOnly]) continue;

		char strIndex[16];
		IntToString(i, strIndex, sizeof(strIndex));
		AddMenuItem(hMenu, strIndex, g_nGiants[i][g_strGiantName]);
		iCount++;
	}
	if(iCount == 0) AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);

	SetMenuTitle(hMenu, "%T", "Tank_Menu_Giant_Main_Title", client);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Main(Handle hMenu, MenuAction action, int client, int menu_item)
{
	if(action == MenuAction_Select)
	{
		char strIndex[16];
		GetMenuItem(hMenu, menu_item, strIndex, sizeof(strIndex));
		int iIndex = StringToInt(strIndex);

		Giant_ShowDesc(client, iIndex);
	}else if(action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
}

void Giant_ShowDesc(int client, int iIndex, bool bShowBackButton=true, int iGiant=-1)
{
	// Show a little info panel on the giant's special abilities
	if(iIndex < 0 || iIndex >= MAX_NUM_TEMPLATES || !g_nGiants[iIndex][g_bGiantTemplateEnabled]) return;

	Handle hPanel = CreatePanel();

	char strText[MAXLEN_GIANT_STRING+50];
	if(iGiant >= 1 && iGiant <= MaxClients && IsClientInGame(iGiant))
	{
		Format(strText, sizeof(strText), "%T", "Tank_Menu_Giant_Desc_WillBecome", client, iGiant);
		DrawPanelText(hPanel, strText);
		Format(strText, sizeof(strText), "%s", g_nGiants[iIndex][g_strGiantName]);
	}else{
		Format(strText, sizeof(strText), "%s:", g_nGiants[iIndex][g_strGiantName]);
	}
	DrawPanelItem(hPanel, strText);

	DrawPanelText(hPanel, g_nGiants[iIndex][g_strGiantDesc]);
	DrawPanelText(hPanel, " ");

	Format(strText, sizeof(strText), "%T", "Tank_Dismiss", client);
	DrawPanelItem(hPanel, strText);

	Format(strText, sizeof(strText), "%T", "Tank_GoBack", client);
	if(bShowBackButton) DrawPanelItem(hPanel, strText);

	SendPanelToClient(hPanel, client, PanelHandler_Desc, (bShowBackButton == true) ? MENU_TIME_FOREVER : 30);

	CloseHandle(hPanel);
}

public int PanelHandler_Desc(Handle hPanel, MenuAction action, int client, int menu_item)
{
	if(action == MenuAction_Select)
	{
		if(menu_item == 3)
		{
			Giant_ShowMain(client, true);
		}
	}
}

void Giant_ShowGuidingAnnotation(int client, int team, int iIndexCP)
{
	if(IsFakeClient(client)) return;
	if(iIndexCP < 0 || iIndexCP >= MAX_LINKS) return;

	int pathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][iIndexCP]);
	if(pathTrack <= MaxClients) return;

	// Send the player an annotation guiding them to the next control point
	Handle hEvent = CreateEvent("show_annotation");
	if(hEvent != INVALID_HANDLE)
	{
		float flPos[3];
		GetEntPropVector(pathTrack, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] -= 20.0;

		SetEventInt(hEvent, "id", Annotation_GuidingHint);
		SetEventFloat(hEvent, "worldPosX", flPos[0]);
		SetEventFloat(hEvent, "worldPosY", flPos[1]);
		SetEventFloat(hEvent, "worldPosZ", flPos[2]);
		
		SetEventInt(hEvent, "visibilityBitfield", (1 << client)); // Only show to player carrying the bomb

		char text[256];		
		if(g_iRefLinkedCPs[team][iIndexCP] == g_iRefControlPointGoal[team]) // Next control point is the final control point
		{
			if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale)
			{
				Format(text, sizeof(text), "%T", "Tank_Annotation_CactusCanyon_Hint", client);
			}else{
				Format(text, sizeof(text), "%T", "Tank_Annotation_Deploy", client);
			}
		}else{
			Format(text, sizeof(text), "%T", "Tank_Annotation_Capture", client);
		}
		SetEventString(hEvent, "text", text);

		SetEventFloat(hEvent, "lifetime", 5.0);
		SetEventString(hEvent, "play_sound", "misc/null.wav");
		
		FireEvent(hEvent); // Frees the handle
	}
}

void RageMeter_Cleanup(int client=-1)
{
	if(client == -1)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			RageMeter_Cleanup(i);
		}
	}else{
		g_rageMeter[client][g_rageMeterEnabled] = false;
		g_rageMeter[client][g_rageMeterTimeLastRageMsg] = 0.0;
		g_rageMeter[client][g_rageMeterLowRageAlert] = false;
		g_rageMeter[client][g_rageMeterLastThinkTime] = 0.0;
	}
}

void RageMeter_Tick()
{
	if(g_nGameMode != GameMode_Race) return;

	for(int i=1; i<=MaxClients; i++)
	{
		if(!g_rageMeter[i][g_rageMeterEnabled]) continue;

		if(g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && IsClientInGame(i) && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
		{
			RageMeter_Think(i);
		}else{
			RageMeter_Cleanup(i);
		}
	}	
}

void RageMeter_RestoreLevel(int client)
{
	int team = GetClientTeam(client);
	int oppositeTeam = TFTeam_Red;
	if(team == TFTeam_Red) oppositeTeam = TFTeam_Blue;

	// Formula: rage meter base + rage meter scale * (1 - player count / 12)
	float time = config.LookupFloat(g_hCvarRageBase) + config.LookupFloat(g_hCvarRageScale) * FloatAbs(1.0 - CountPlayersOnTeam(oppositeTeam) / 12.0);
	if(time < 5.0) time = 5.0; // In case the rage meter is set too low, set it to 5s.

	g_rageMeter[client][g_rageMeterLevel] = time;
}

void RageMeter_Think(int client)
{
	// Rage meter for giants in plr_ maps
	// Giants will expire if they do not do player damage for a certain amount of time
	float time = GetEngineTime();

	if(g_rageMeter[client][g_rageMeterLastThinkTime] == 0.0) g_rageMeter[client][g_rageMeterLastThinkTime] = time;

	// Reduce the rage meter level.
	if(g_rageMeter[client][g_rageMeterLevel] > config.LookupFloat(g_hCvarRageLow))
	{
		g_rageMeter[client][g_rageMeterLevel] -= time - g_rageMeter[client][g_rageMeterLastThinkTime];
	}else{
		// When we hit tank_rage_low, the rage meter can be paused for a few seconds when the giant takes damage.
		if(g_rageMeter[client][g_rageMeterTimeLastTookDamage] == 0.0 || time - g_rageMeter[client][g_rageMeterTimeLastTookDamage] > 2.0)
		{
			// Taking damage causes the rage meter to pause for a few seconds.
			g_rageMeter[client][g_rageMeterLevel] -= time - g_rageMeter[client][g_rageMeterLastThinkTime];
		}
	}

	g_rageMeter[client][g_rageMeterLastThinkTime] = time;

	if(g_rageMeter[client][g_rageMeterLevel] <= 0.0)
	{
		// Giant's rage meter has run out!
		if(IsPlayerAlive(client)) ForcePlayerSuicide(client);
#if defined DEBUG
		PrintToServer("(Giant_Think) Rage meter has been reached, %N now disabled.", client);
#endif
		ShowSyncHudText(client, g_hHudSync, "");
		PrintToChat(client, "%t", "Tank_Chat_RageMeter_Expired", 0x01);

		EmitSoundToClient(client, SOUND_GIANT_RAGE_DEATH);

		RageMeter_Cleanup(client);
		return;
	}else if(g_rageMeter[client][g_rageMeterLevel] <= config.LookupFloat(g_hCvarRageLow))
	{
		// Giant's rage meter is getting low!
		if(g_rageMeter[client][g_rageMeterTimeLastRageMsg] == 0.0 || time - g_rageMeter[client][g_rageMeterTimeLastRageMsg] > 0.3)
		{
			if(g_rageMeter[client][g_rageMeterTimeLastRageMsg] == 0.0) EmitSoundToClient(client, SOUND_GIANT_RAGE);

			char strMsg[128];
			strcopy(strMsg, sizeof(strMsg), "Attack enemy players to keep control:\nR");

			int maxBars = 20;
			int numBars = RoundToNearest(g_rageMeter[client][g_rageMeterLevel] / config.LookupFloat(g_hCvarRageLow) * float(maxBars));
			for(int i=0; i<numBars; i++)
			{
				Format(strMsg, sizeof(strMsg), "%s |", strMsg);
			}

			//SetHudTextParams(float x, float y, float holdTime, r, g, b, a, effect = 0, float fxTime=6.0, float fadeIn=0.1, float fadeOut=0.2)
			if(numBars <= maxBars / 2)
			{
				// Change the color of the rage meter when it becomes critically low.
				SetHudTextParams(0.1, -1.0, 0.7, 255, 255, 0, 255, 1, 6.0, 0.1, 6.0);

				if(!g_rageMeter[client][g_rageMeterLowRageAlert])
				{
					EmitSoundToClient(client, SOUND_GIANT_RAGE, _, _, _, _, _, 120);
					g_rageMeter[client][g_rageMeterLowRageAlert] = true;
				}			
			}else{
				SetHudTextParams(0.1, -1.0, 0.7, 117, 107, 95, 255, 1, 6.0, 0.1, 6.0);
			}

			ShowSyncHudText(client, g_hHudSync, strMsg);

			g_rageMeter[client][g_rageMeterTimeLastRageMsg] = time;
		}
	}
}

void RageMeter_OnDamageDealt(int client)
{
	// Record the last time when the giant robot has made a frag for the purposes of the rage meter
	if(g_rageMeter[client][g_rageMeterEnabled] && g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		// Make the rage meter disappear as soon as damage is dealt
		if(g_rageMeter[client][g_rageMeterTimeLastRageMsg] != 0.0)
		{
			ShowSyncHudText(client, g_hHudSync, "");
		}

		RageMeter_RestoreLevel(client);
		g_rageMeter[client][g_rageMeterTimeLastRageMsg] = 0.0;
		g_rageMeter[client][g_rageMeterLowRageAlert] = false;
		g_rageMeter[client][g_rageMeterTimeLastTookDamage] = 0.0;
	}	
}

void RageMeter_OnTookDamage(int client)
{
	// Record when the giant takes damage to pause the rage meter when it becomes low.
	if(g_rageMeter[client][g_rageMeterEnabled] && g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		g_rageMeter[client][g_rageMeterTimeLastTookDamage] = GetEngineTime();
	}
}

void RageMeter_Enable(int client)
{
	RageMeter_Cleanup(client);
	g_rageMeter[client][g_rageMeterEnabled] = true;
	g_rageMeter[client][g_rageMeterLastThinkTime] = GetEngineTime();
	RageMeter_RestoreLevel(client);
}

public Action Timer_ShowHint(Handle timer, any ref)
{
	int client = EntRefToEntIndex(ref);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot
		&& strlen(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_strGiantHint]) > 0 && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
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
			
			if(GetClientTeam(client) == TFTeam_Red)
			{
				SetEventInt(hEvent, "id", Annotation_GiantHintRed);
			}else{
				SetEventInt(hEvent, "id", Annotation_GiantHintBlue);
			}
			
			SetEventInt(hEvent, "visibilityBitfield", (1 << client)); // Only show to player carrying the bomb
			SetEventString(hEvent, "text", g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_strGiantHint]);

			SetEventFloat(hEvent, "lifetime", 8.0);
			SetEventString(hEvent, "play_sound", "misc/null.wav");
			
			FireEvent(hEvent); // Frees the handle
		}		
	}

	return Plugin_Handled;
}

void StatsGiant_Reset(int client=-1)
{
	if(client <= -1)
	{
		for(int i=0; i<sizeof(g_iDamageStatsGiant); i++)
		{
			StatsGiant_Reset(i);
		}
		return;
	}

	for(int i=0; i<sizeof(g_iDamageStatsGiant[]); i++)
	{
		g_iDamageStatsGiant[client][i] = 0;
	}
}

void Giant_FlagWeaponDontDrop(int weapon)
{
	int itemOffset = GetEntSendPropOffs(weapon, "m_Item", true);
	if(itemOffset <= 0) return;

	Address weaponAddress = GetEntityAddress(weapon);
	if(!IsValidAddress(weaponAddress)) return;

	Address addr = view_as<Address>((view_as<int>(weaponAddress)) + itemOffset + OFFSET_DONT_DROP); // Going to hijack CEconItemView::m_iInventoryPosition.

	StoreToAddress(addr, FLAG_DONT_DROP_WEAPON, NumberType_Int32);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
}

#if defined _SENDPROXYMANAGER_INC_
public Action SendProxy_ToggleGiantHealthMeter(int entity, char[] propName, int &value, int element)
{
	// Remove the giant health meter only when the spy is disguised.
	if(TF2_IsPlayerInCondition(entity, TFCond_Disguised))
	{
		value = false;
	}else{
		value = true;
	}

	return Plugin_Changed;
}
#endif

void Giant_SpawnGibs(int client)
{
	int maxGibs = config.LookupInt(g_hCvarGiantGibs);
	if(maxGibs <= 0) return;

	if(!g_nSpawner[client][g_bSpawnerEnabled] || g_nSpawner[client][g_nSpawnerType] != Spawn_GiantRobot) return;

	int index = g_nSpawner[client][g_iSpawnerGiantIndex];
	if(g_nGiants[index][g_iGiantTags] & GIANTTAG_SENTRYBUSTER || g_nGiants[index][g_iGiantTags] & GIANTTAG_NO_GIB) return;

	if(GetEntityCount() > GetMaxEntities()-ENTITY_LIMIT_BUFFER-maxGibs)
	{
		LogMessage("Not spawning gibs. Reaching entity limit: %d/%d!", GetEntityCount(), GetMaxEntities());
		return;
	}

	TFClassType class = g_nGiants[index][g_nGiantClass];
	int skin = GetClientTeam(client)-2;

	float playerPos[3];
	GetClientAbsOrigin(client, playerPos);

	float playerAng[3];
	GetClientEyeAngles(client, playerAng);

	float mins[3];
	float maxs[3];
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);

	float centerPos[3];
	for(int i=0; i<2; i++) centerPos[i] = playerPos[i];
	centerPos[2] = playerPos[2] + (maxs[2] - mins[2]) / 2.2;
	
	if(g_iParticleBotDeath != -1)
	{
		TE_Particle(g_iParticleBotDeath, centerPos);
		TE_SendToAll();
	}	

	char model[PLATFORM_MAX_PATH];
	
	// Spawn head gib.
	float pos[3];
	for(int i=0; i<3; i++) pos[i] = centerPos[i];
	pos[2] -= 100.0;

	float ang[3];
	ang[1] = playerAng[1]; // Have the head facing the same angle as the player.

	float vel[3];
	vel[2] = 325.0; // Have the head shoot upwards.

	switch(class)
	{
		case TFClass_DemoMan: strcopy(model, sizeof(model), g_demoBossGibs[0]);
		case TFClass_Heavy: strcopy(model, sizeof(model), g_heavyBossGibs[0]);
		case TFClass_Pyro: strcopy(model, sizeof(model), g_pyroBossGibs[0]);
		case TFClass_Scout: strcopy(model, sizeof(model), g_scoutBossGibs[0]);
		case TFClass_Soldier: strcopy(model, sizeof(model), g_soldierBossGibs[0]);
		case TFClass_Spy: strcopy(model, sizeof(model), g_spyBossGibs[0]);
		case TFClass_Sniper: strcopy(model, sizeof(model), g_sniperBossGibs[0]);
		case TFClass_Medic: strcopy(model, sizeof(model), g_medicBossGibs[0]);
		case TFClass_Engineer: strcopy(model, sizeof(model), g_engyBossGibs[0]);
	}

	if(strlen(model) > 0)
	{
		Giant_InitGib(model, pos, ang, vel, skin, true);
	}

	// Spawn arm/leg/torso gibs.
	for(int numGibs=0; numGibs<maxGibs; numGibs++)
	{
		for(int i=0; i<2; i++) pos[i] += GetRandomFloat(-42.0, 42.0);

		ang[1] = GetRandomFloat(-180.0, 180.0);

		for(int i=0; i<2; i++) vel[i] += GetRandomFloat(-100.0, 100.0);
		vel[2] = 300.0;

		switch(class)
		{
			case TFClass_DemoMan: strcopy(model, sizeof(model), g_demoBossGibs[GetRandomInt(1, sizeof(g_demoBossGibs)-1)]);
			case TFClass_Heavy: strcopy(model, sizeof(model), g_heavyBossGibs[GetRandomInt(1, sizeof(g_heavyBossGibs)-1)]);
			case TFClass_Pyro: strcopy(model, sizeof(model), g_pyroBossGibs[GetRandomInt(1, sizeof(g_pyroBossGibs)-1)]);
			case TFClass_Scout: strcopy(model, sizeof(model), g_scoutBossGibs[GetRandomInt(1, sizeof(g_scoutBossGibs)-1)]);
			case TFClass_Soldier: strcopy(model, sizeof(model), g_soldierBossGibs[GetRandomInt(1, sizeof(g_soldierBossGibs)-1)]);
			case TFClass_Spy: strcopy(model, sizeof(model), g_scoutBossGibs[GetRandomInt(1, sizeof(g_scoutBossGibs)-1)]); // No gib models for these classes so reuse.
			case TFClass_Sniper: strcopy(model, sizeof(model), g_scoutBossGibs[GetRandomInt(1, sizeof(g_scoutBossGibs)-1)]);
			case TFClass_Medic: strcopy(model, sizeof(model), g_scoutBossGibs[GetRandomInt(1, sizeof(g_scoutBossGibs)-1)]);
			case TFClass_Engineer: strcopy(model, sizeof(model), g_soldierBossGibs[GetRandomInt(1, sizeof(g_soldierBossGibs)-1)]);
		}

		if(strlen(model) > 0)
		{
			Giant_InitGib(model, pos, ang, vel, skin);
		}
	}
}

void Giant_InitGib(const char[] model, float pos[3], float ang[3]=NULL_VECTOR, float vel[3]=NULL_VECTOR, int skin=0, bool headGib=false)
{
	int gib = CreateEntityByName("prop_physics_multiplayer");
	if(gib > MaxClients)
	{
		DispatchKeyValue(gib, "model", model);
		DispatchKeyValue(gib, "physicsmode", "2");

		DispatchSpawn(gib);

		SetEntProp(gib, Prop_Send, "m_CollisionGroup", 1); // 24
		SetEntProp(gib, Prop_Send, "m_usSolidFlags", 0); // 8
		SetEntProp(gib, Prop_Send, "m_nSolidType", 2); // 6
		SetEntProp(gib, Prop_Send, "m_nSkin", skin);

		int effects = EF_NOSHADOW|EF_NORECEIVESHADOW;
		if(headGib)
		{
			effects |= EF_ITEM_BLINK;
		}
		SetEntProp(gib, Prop_Send, "m_fEffects", effects);

		TeleportEntity(gib, pos, ang, vel);

		CreateTimer(20.0, Timer_EntityCleanup, EntIndexToEntRef(gib), TIMER_FLAG_NO_MAPCHANGE);
	}
}

float Giant_GetScaleForHealing(int team)
{
	int numPlayers = CountPlayersOnTeam(team);
	float result = 1.0; // 8+ players.

	if(numPlayers <= 2)
	{
		result = 0.3;
	}else if(numPlayers <= 3)
	{
		result = 0.4;
	}else if(numPlayers <= 4)
	{
		result = 0.5;
	}else if(numPlayers <= 5)
	{
		result = 0.6;
	}else if(numPlayers <= 6)
	{
		result = 0.7;
	}else if(numPlayers <= 7)
	{
		result = 0.85;
	}

	return result;
}