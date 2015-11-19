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
 * Purpose: This file contains functions that support stt's config file.
 */

#if !defined STT_MAIN_PLUGIN
#error This plugin must be compiled from tank.sp
#endif

#define FILE_STT_CONFIG "configs/stt/stt.cfg"
#define MAXLEN_CONFIG_VALUE 128
#define MAXLEN_CHAT_TIP 192
#define MAXLEN_CART_PATH 256
#define MAXLEN_LASTGIANT 32

ArrayList g_chatTips;
ArrayList g_cartModels;
ArrayList g_parentList;
enum
{
	ParentType_Start=0,
	ParentType_End,
};
enum
{
	ParentArray_Type=0,
	ParentArray_Team,
	ParentArray_Location,
};
#define ARRAY_PARENT_SIZE 3

ArrayList g_giantSpawns;
enum
{
	GiantSpawnArray_Team=0,
	GiantSpawnArray_PointIndex,
	GiantSpawnArray_Origin,
	GiantSpawnArray_Angles=5,
};
#define ARRAY_GIANTSPAWN_SIZE 8

methodmap BlockedCosmetics < StringMap
{
	public BlockedCosmetics()
	{
		return view_as<BlockedCosmetics>(new StringMap());
	}

	public bool isBlocked(int itemDefinitionIndex)
	{
		char key[16];
		IntToString(itemDefinitionIndex, key, sizeof(key));

		int value;
		return this.GetValue(key, value);
	}

	public void addBlockedCosmetic(int itemDefinitionIndex)
	{
		char key[16];
		IntToString(itemDefinitionIndex, key, sizeof(key));

		this.SetValue(key, true, true);
	}
};
BlockedCosmetics g_blockedCosmetics = null;

methodmap CustomProps < ArrayList
{
	public CustomProps()
	{
		return view_as<CustomProps>(new ArrayList());
	}

	/**
	 * Makes sure any spawned custom props are removed and clears the ArrayList.
	 *
	 */
	public void Clear()
	{
		int size = this.Length;
		for(int i=0; i<size; i++)
		{
			int prop = EntRefToEntIndex(this.Get(i));
			if(prop > MaxClients)
			{
				AcceptEntityInput(prop, "Kill");
			}
		}

		this.Clear();
	}
};
CustomProps g_customProps = null;

methodmap Config < StringMap
{
	public Config()
	{
		return view_as<Config>(new StringMap());
	}

	/**
	 * A helper function to parse the list of blocked robot cosmetics.
	 *
	*/
	public void loadBlockedCosmetics(KeyValues kv, const char[] sectionName)
	{
		char bufferValue[MAXLEN_CONFIG_VALUE];
		if(kv.JumpToKey(sectionName, false))
		{
			if(kv.GotoFirstSubKey(false))
			{
				int numBlocked = 0;
				do
				{
					kv.GetString(NULL_STRING, bufferValue, sizeof(bufferValue));

					if(bufferValue[0] == '\0')
					{
						LogMessage("Blank config name or value in %s: section (%s)!", FILE_STT_CONFIG, sectionName);
						continue;
					}

					// Add this to the hash map of blocked cosmetics
					int itemDefinitionIndex = StringToInt(bufferValue);
					if(itemDefinitionIndex > 0)
					{
						g_blockedCosmetics.addBlockedCosmetic(itemDefinitionIndex);
						numBlocked++;
					}else{
						LogMessage("Invalid blocked cosmetic in (%s): \"%s\"", sectionName, bufferValue);
					}
				}while(kv.GotoNextKey(false));

				LogMessage("Loaded %d blocked cosmetic(s)!", numBlocked);

				kv.GoBack();
			}

			kv.GoBack();
		}
	}

	/**
	 * A helper function to parse the list of chat tips.
	 *
	*/
	public void loadChatTips(KeyValues kv, const char[] sectionName)
	{
		char bufferValue[MAXLEN_CHAT_TIP];
		if(kv.JumpToKey(sectionName, false))
		{
			if(kv.GotoFirstSubKey(false))
			{
				int numAdded = 0;
				do
				{
					kv.GetString(NULL_STRING, bufferValue, sizeof(bufferValue));
					TrimString(bufferValue);

					if(bufferValue[0] == '\0')
					{
						LogMessage("Blank config name or value in %s: section (%s)!", FILE_STT_CONFIG, sectionName);
						continue;
					}

					// Add this to the list of chat tips
					g_chatTips.PushString(bufferValue);
					numAdded++;
				}while(kv.GotoNextKey(false));
#if defined DEBUG
				PrintToServer("(loadChatTips) Loaded %d chat tip(s)!", numAdded);
#endif
				kv.GoBack();
			}

			kv.GoBack();
		}
	}

	/**
	 * A helper function to parse the list of cart models.
	 *
	*/
	public void loadCartModels(KeyValues kv, const char[] sectionName)
	{
		char bufferValue[MAXLEN_CART_PATH];
		if(kv.JumpToKey(sectionName, false))
		{
			if(kv.GotoFirstSubKey(false))
			{
				int numAdded = 0;
				do
				{
					kv.GetString(NULL_STRING, bufferValue, sizeof(bufferValue));
					TrimString(bufferValue);

					if(bufferValue[0] == '\0')
					{
						LogMessage("Blank config name or value in %s: section (%s)!", FILE_STT_CONFIG, sectionName);
						continue;
					}

					// Add this to the list of cart models.
					g_cartModels.PushString(bufferValue);
					numAdded++;
				}while(kv.GotoNextKey(false));
#if defined DEBUG
				PrintToServer("(loadChatTips) Loaded %d cart model(s)!", numAdded);
#endif
				kv.GoBack();
			}

			kv.GoBack();
		}
	}

	/**
	 * Clears all the current config values and re-parses the config file
	 *
	*/
	public void refresh()
	{
		this.Clear(); // Clear the hash table
		g_blockedCosmetics.Clear(); // Clear the list of blocked cosmetics
		g_chatTips.Clear(); // Clear the list of chat tips
		g_parentList.Clear(); // Clear the tank parenting settings.
		g_cartModels.Clear(); // Clear the list of cart models.
		g_giantSpawns.Clear(); // Clear the list of giant spawn overrides.
		g_customProps.Clear(); // Clear the custom props spawned into the map.

		char configPath[PLATFORM_MAX_PATH];
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));

		// See if a map specific config file is present and load that first.
		BuildPath(Path_SM, configPath, sizeof(configPath), "configs/stt/maps/%s.cfg", map);
		if(FileExists(configPath))
		{
#if defined DEBUG
			PrintToServer("(refresh) Map config file exists: %s!", configPath);
#endif
			KeyValues kv = new KeyValues("Config");
			kv.SetEscapeSequences(true);

			if(kv.ImportFromFile(configPath))
			{
				// Load config values for the current map.
				Config_LoadSection(kv, map, configPath, false);

				// Load the list of cart models.
				this.loadCartModels(kv, "_cart_models_");
			}else{
				LogMessage("Failed to parse map config file: %s!", configPath);
			}

			delete kv;
		}

		// Read the config file and insert values into the hash table.
		BuildPath(Path_SM, configPath, sizeof(configPath), FILE_STT_CONFIG);
		if(!FileExists(configPath))
		{
			LogMessage("Failed to load stt config file (file missing): %s!", configPath);
			return;
		}

		KeyValues kv = new KeyValues("Config");
		kv.SetEscapeSequences(true);

		if(!kv.ImportFromFile(configPath))
		{
			LogMessage("Failed to parse stt config file: %s!", configPath);
			delete kv;
			return;
		}

		// Load global config values.
		Config_LoadSection(kv, "_global_", configPath, true);

		// Load config values for the current map.
		Config_LoadSection(kv, map, configPath, true);

		// Load the list of blocked robot cosmetics.
		this.loadBlockedCosmetics(kv, "_blocked_cosmetics_");

		// Load the list of chat tips.
		this.loadChatTips(kv, "_chat_tips_");

		// Load the list of cart models.
		this.loadCartModels(kv, "_cart_models_");

		delete kv;
	}

	/**
	 * Retrieves a config value giving priority to config values over cvar values.
	 * 
	 * @param associatedCvar 	The handle to the convar to check.
	 * @return 					The config value converted to float.
	 *
	*/
	public float LookupFloat(Handle associatedCvar)
	{
		char configName[64];
		GetConVarName(associatedCvar, configName, sizeof(configName));

		char configValue[MAXLEN_CONFIG_VALUE];
		if(this.GetString(configName, configValue, sizeof(configValue)))
		{
			return StringToFloat(configValue);
		}

		return GetConVarFloat(associatedCvar);
	}

	/**
	 * Retrieves a config value giving priority to config values over cvar values.
	 * 
	 * @param associatedCvar 	The handle to the convar to check.
	 * @return 					The config value converted to int.
	 *
	*/
	public int LookupInt(Handle associatedCvar)
	{
		char configName[64];
		GetConVarName(associatedCvar, configName, sizeof(configName));

		char configValue[MAXLEN_CONFIG_VALUE];
		if(this.GetString(configName, configValue, sizeof(configValue)))
		{
			return StringToInt(configValue);
		}

		return GetConVarInt(associatedCvar);
	}

	/**
	 * Retrieves a config value giving priority to config values over cvar values.
	 * 
	 * @param associatedCvar 	The handle to the convar to check.
	 * @param value 			Buffer to store the value of the config setting.
	 * @param maxlength 		Maximum length of the string buffer.
	 *
	*/
	public void LookupString(Handle associatedCvar, char[] value, int maxlength)
	{
		char configName[64];
		GetConVarName(associatedCvar, configName, sizeof(configName));

		if(this.GetString(configName, value, maxlength))
		{
			return;
		}

		GetConVarString(associatedCvar, value, maxlength);
	}

	/**
	 * Retrieves a config value giving priority to config values over cvar values.
	 * 
	 * @param associatedCvar 	The handle to the convar to check.
	 * @return 					The config value converted to bool.
	 *
	*/
	public bool LookupBool(Handle associatedCvar)
	{
		char configName[64];
		GetConVarName(associatedCvar, configName, sizeof(configName));

		char configValue[MAXLEN_CONFIG_VALUE];
		if(this.GetString(configName, configValue, sizeof(configValue)))
		{
			return (StringToInt(configValue) != 0);
		}

		return GetConVarBool(associatedCvar);
	}

	/**
	 * Reads the config file and spawns any custom props.
	 * 
	*/
	public void spawnProps()
	{
		// Read the config file and spawn any props into the world.
		char configPath[PLATFORM_MAX_PATH];
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));

		// See if a map specific config file is present and load that first.
		BuildPath(Path_SM, configPath, sizeof(configPath), "configs/stt/maps/%s.cfg", map);
		if(FileExists(configPath))
		{
#if defined DEBUG
			PrintToServer("(spawnProps) Map config file exists: %s!", configPath);
#endif
			KeyValues kv = new KeyValues("Config");
			kv.SetEscapeSequences(true);

			if(kv.ImportFromFile(configPath))
			{
				Config_LoadPropSection(kv, "_global_");
				Config_LoadPropSection(kv, map);
			}else{
				LogMessage("Failed to parse map config file: %s!", configPath);
			}

			delete kv;
		}

		BuildPath(Path_SM, configPath, sizeof(configPath), FILE_STT_CONFIG);
		if(!FileExists(configPath))
		{
			LogMessage("Failed to load stt config file (file missing): %s!", configPath);
			return;
		}

		KeyValues kv = new KeyValues("Config");
		kv.SetEscapeSequences(true);

		if(!kv.ImportFromFile(configPath))
		{
			LogMessage("Failed to parse stt config file: %s!", configPath);
			delete kv;
			return;
		}

		Config_LoadPropSection(kv, "_global_");
		Config_LoadPropSection(kv, map);

		delete kv;
	}

	/**
	 * Confirms that a section matches the given pattern from the config file.
	 * 
	 * @param str 		The string to check the pattern on.
	 * @param pattern 	The given pattern from the config file. Patterns that start with @ will be considered a regular expression.
	 * @return 			True if the pattern matches, false otherwise.
	 */
	public bool matchesSection(const char[] str, const char[] pattern)
	{
		if(pattern[0] == '\0') return false; // Empty section name.

		if(pattern[0] == '@' && pattern[1] != '\0') // Regex pattern passed.
		{
			char error[32];
			int result = SimpleRegexMatch(str, pattern[1], 0, error, sizeof(error));
			if(result == -1)
			{
				LogMessage("Failed to parse regular expression: \"%s\". Error: %s", pattern[1], error);
				return false;
			}

			return (result > 0);
		}

		return (strcmp(str, pattern, false) == 0);
	}
};
Config config = null;

// Note: These are left out of the methodmap because the sourcepawn compiler can not handle recursive methodmap functions. https://bugs.alliedmods.net/show_bug.cgi?id=6359

/**
 * A helper function to parse a config values section.
 *
 * @param kv The keyvalue object to traversal.
 * @param sectionName The key to enter.
 */
public void Config_LoadSection(KeyValues kv, const char[] sectionName, const char[] fileName, bool trusted)
{

	// Loop through all the keys and check if they match sectionName.
	if(kv.GotoFirstSubKey(false))
	{
		char bufferName[MAXLEN_CONFIG_VALUE];
		char bufferValue[MAXLEN_CONFIG_VALUE];		

		do
		{
			kv.GetSectionName(bufferName, sizeof(bufferName));
			//PrintToServer("Comparing \"%s\" to \"%s\"..", sectionName, bufferName);
			if(config.matchesSection(sectionName, bufferName))
			{
#if defined DEBUG
				PrintToServer("(Config_LoadSection) \"%s\" matches \"%s\"!", sectionName, bufferName);
#endif
				if(kv.GotoFirstSubKey(false))
				{
					do
					{
						kv.GetSectionName(bufferName, sizeof(bufferName));
						kv.GetString(NULL_STRING, bufferValue, sizeof(bufferValue));
						//PrintToServer("     Encountered: \"%s\"", bufferName);

						if(strcmp(bufferName, "props", false) == 0) // The prop section is reserved.
						{
							continue;
						}

						if(strncmp(bufferName, "start:", 6, false) == 0 || strncmp(bufferName, "end:", 4, false) == 0) // The matches for the start or end goal node can be ignored
						{
							continue;
						}

						if(strncmp(bufferName, "parent", 6, false) == 0) // User wants to specify tank parenting information.
						{
							int team = 0; // any team
							if(StrContains(bufferName, "_red", false) != -1) team = TFTeam_Red;
							else if(StrContains(bufferName, "_blu", false) != -1) team = TFTeam_Blue;

							if(kv.GotoFirstSubKey(false))
							{
								do
								{
									kv.GetSectionName(bufferName, sizeof(bufferName));

									int parent[ARRAY_PARENT_SIZE];
									parent[ParentArray_Type] = -1;
									
									float location = -1.0;
									if(strcmp(bufferName, "start", false) == 0)
									{
										parent[ParentArray_Type] = ParentType_Start;
									}else if(strcmp(bufferName, "end", false) == 0)
									{
										parent[ParentArray_Type] = ParentType_End;
									}
									location = kv.GetFloat(NULL_STRING, -1.0);

									if(parent[ParentArray_Type] == -1)
									{
										LogMessage("Config error. Section \"%s\": Malformed parent type \"%s\". Use either \"start\" or \"stop\"!", sectionName, bufferName);
									}else if(location < 0.0 || location > 1.0)
									{
										LogMessage("Config error. Section \"%s\": Malformed parent location \"%f\". Specify a value between 0.0 and 1.0!", sectionName, location);
									}else{
										parent[ParentArray_Location] = view_as<int>(location);
										parent[ParentArray_Team] = team;

										if(team == 0)
										{
											parent[ParentArray_Team] = TFTeam_Red;
											g_parentList.PushArray(parent, ARRAY_PARENT_SIZE);
											parent[ParentArray_Team] = TFTeam_Blue;
											g_parentList.PushArray(parent, ARRAY_PARENT_SIZE);
										}else{
											g_parentList.PushArray(parent, ARRAY_PARENT_SIZE);
										}
									}
								}while(kv.GotoNextKey(false));

								kv.GoBack();
#if defined DEBUG
								PrintToServer("(Config_LoadSection) Size of parent config = %d", g_parentList.Length);
#endif
							}

							continue;
						}

						if(strncmp(bufferName, "giant_spawn", 11, false) == 0) // User wants to override a giant spawn.
						{
							int team = 0; // any team
							if(StrContains(bufferName, "_red", false) != -1) team = TFTeam_Red;
							else if(StrContains(bufferName, "_blu", false) != -1) team = TFTeam_Blue;

							int index = kv.GetNum("index", -2);
							if(index < -1 || index > MAX_LINKS)
							{
								LogMessage("Config error. Section \"%s\": Malformed giant spawn index. Use a value between -1 and %d (inclusive).", sectionName, MAX_LINKS);
								continue;
							}

							float pos[3];
							float ang[3];
							kv.GetVector("origin", pos);
							kv.GetVector("angle", ang);

							int giantSpawn[ARRAY_GIANTSPAWN_SIZE];
							giantSpawn[GiantSpawnArray_Team] = team;
							giantSpawn[GiantSpawnArray_PointIndex] = index;
							for(int i=0; i<3; i++)
							{
								giantSpawn[GiantSpawnArray_Origin+i] = view_as<int>(pos[i]);
								giantSpawn[GiantSpawnArray_Angles+i] = view_as<int>(ang[i]);
							}

							g_giantSpawns.PushArray(giantSpawn, sizeof(giantSpawn));
#if defined DEBUG
							PrintToServer("(Config_LoadSection) Added giant spawn, team = %d, index = %d. Length so far = %d!", team, index, g_giantSpawns.Length);
#endif
							continue;
						}

						if(strcmp(bufferName, "cvar", false) == 0) // User wants to specify a cvar value change.
						{
							if(!trusted)
							{
								LogMessage("Config error. Section \"%s\": Failed to load cvar. No cvars can be set in map config files.", sectionName);
								continue;
							}

							char explode[2][128];
							if(ExplodeString(bufferValue, ":", explode, sizeof(explode), sizeof(explode[]), true) == sizeof(explode))
							{
								ConVar cvar = FindConVar(explode[0]);
								if(cvar != null)
								{
									if(strcmp(explode[1], "default", false) == 0)
									{
										// Substitute the default value of the convar.
										cvar.GetDefault(explode[1], sizeof(explode[]));
									}

									cvar.SetString(explode[1], true, true);
#if defined DEBUG
									PrintToServer("(Config_LoadSection) ConVar(%s) => \"%s\"", explode[0], explode[1]);
#endif
								}else{
									LogMessage("Config error. Section \"%s\": Failed to find cvar \"%s\"!", sectionName, explode[0]);
								}
							}else{
								LogMessage("Config error. Section \"%s\": Malformed cvar value \"%s\"!", sectionName, explode[1]);
							}
							
							continue;
						}

						if(bufferName[0] == '\0' || bufferValue[0] == '\0')
						{
							LogMessage("Config error. Section \"%s\": Blank config name or value!", sectionName);
							continue;
						}

#if defined DEBUG
						PrintToServer("(Config_LoadSection) %s => %s", bufferName, bufferValue);
#endif
						config.SetString(bufferName, bufferValue, true);
					}while(kv.GotoNextKey(false));

					kv.GoBack();

					// Match for the start or end path_track node for stage-specific config values
					char match[256];
					for(int team=2; team<=3; team++)
					{
						int pathStart = EntRefToEntIndex(g_iRefPathStart[team]);
						if(pathStart > MaxClients)
						{
							GetEntPropString(pathStart, Prop_Data, "m_iName", match, sizeof(match));
							Format(match, sizeof(match), "start:%s", match);
							Config_LoadSection(kv, match, fileName, trusted);
						}

						int pathEnd = EntRefToEntIndex(g_iRefPathGoal[team]);
						if(pathEnd > MaxClients)
						{
							GetEntPropString(pathEnd, Prop_Data, "m_iName", match, sizeof(match));
							Format(match, sizeof(match), "end:%s", match);
							Config_LoadSection(kv, match, fileName, trusted);						
						}
					}
				}
			}
		}while(kv.GotoNextKey(false));

		kv.GoBack();
	}
}

/**
 * A helper function to parse the "props" key of a config section.
 * 
 * @param kv The keyvalue object to traverse.
 * @param sectionName The name of the key to jump to.
 *
*/
public void Config_LoadPropSection(KeyValues kv, const char[] sectionName)
{
	// Loop through all the keys and check if they match sectionName.
	if(kv.GotoFirstSubKey(false))
	{
		char bufferName[MAXLEN_CONFIG_VALUE];

		do
		{
			kv.GetSectionName(bufferName, sizeof(bufferName));
			//PrintToServer("Comparing \"%s\" to \"%s\"..", sectionName, bufferName);
			if(config.matchesSection(sectionName, bufferName))
			{
#if defined DEBUG
				PrintToServer("(Config_LoadPropSection) \"%s\" matches \"%s\"!", sectionName, bufferName);
#endif
				// See if the map config has custom props
				if(kv.JumpToKey("props", false))
				{
					if(kv.GotoFirstSubKey(false))
					{
						do
						{
							// Get model to spawn
							kv.GetString("model", bufferName, sizeof(bufferName), "");
							if(bufferName[0] == '\0' || !FileExists(bufferName, true))
							{
								LogMessage("Missing model name in section (%s): %s", sectionName, bufferName);
								continue;
							}

							if(!IsModelPrecached(bufferName) && PrecacheModel(bufferName) == 0)
							{
								LogMessage("Failed to precache model: %s", bufferName);
								continue;				
							}

							// Get origin and angles
							float origin[3];
							float angles[3];
							char skin[12];
							kv.GetVector("origin", origin, NULL_VECTOR);
							kv.GetVector("angle", angles, NULL_VECTOR);
							kv.GetString("skin", skin, sizeof(skin), "-1");

							// Spawn the prop
							int prop = CreateEntityByName("prop_dynamic");
							if(prop > MaxClients)
							{
								DispatchKeyValue(prop, "model", bufferName);
								DispatchKeyValue(prop, "solid", "6");
								if(strcmp(skin, "-1") != 0) DispatchKeyValue(prop, "skin", skin);

								DispatchSpawn(prop);
								AcceptEntityInput(prop, "TurnOn");

								TeleportEntity(prop, origin, angles, NULL_VECTOR);
#if defined DEBUG
								PrintToServer("(Config_LoadPropSection) Spawned map prop: %s", bufferName);
#endif
								g_customProps.Push(EntIndexToEntRef(prop));
							}

						}while(kv.GotoNextKey(true));

						LogMessage("Spawned %d prop(s) set by config file.", g_customProps.Length);

						kv.GoBack();
					}

					kv.GoBack();
				}

				// Match for the start or end path_track node for stage-specific config values
				char match[256];
				for(int team=2; team<=3; team++)
				{
					int pathStart = EntRefToEntIndex(g_iRefPathStart[team]);
					if(pathStart > MaxClients)
					{
						GetEntPropString(pathStart, Prop_Data, "m_iName", match, sizeof(match));
						Format(match, sizeof(match), "start:%s", match);
						Config_LoadPropSection(kv, match);
					}

					int pathEnd = EntRefToEntIndex(g_iRefPathGoal[team]);
					if(pathEnd > MaxClients)
					{
						GetEntPropString(pathEnd, Prop_Data, "m_iName", match, sizeof(match));
						Format(match, sizeof(match), "end:%s", match);
						Config_LoadPropSection(kv, match);						
					}
				}
			}
		}while(kv.GotoNextKey(false));

		kv.GoBack();
	}
}

methodmap GiantTracker < StringMap
{
	public GiantTracker()
	{
		return view_as<GiantTracker>(new StringMap());
	}

	/**
	 * Iterate through the StringMap and prune any keys that are too old.
	 *
	 */
	public void prune()
	{
		StringMapSnapshot snapshot = this.Snapshot();

		char buffer[MAXLEN_LASTGIANT];
		int numKeys = snapshot.Length;
		int currentTime = GetTime();
		for(int i=0; i<numKeys; i++)
		{
			snapshot.GetKey(i, buffer, sizeof(buffer));

			// If the time is outside the cooldown, delete the key
			int timeCooldownExpired;
			if(this.GetValue(buffer, timeCooldownExpired))
			{
				if(currentTime > timeCooldownExpired)
				{
					this.Remove(buffer);
				}
			}
		}

		delete snapshot;
	}

	/**
	 * Checks to see if a player's cooldown is up and they can become a giant.
	 *
	 * @param client 	Client index.
	 * @return 			True if player can become the giant, false otherwise.
	 */
	public bool canPlayGiant(int client)
	{
		char auth[MAXLEN_LASTGIANT];
		GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));

		int timeCooldownExpired;
		if(this.GetValue(auth, timeCooldownExpired))
		{
			if(GetTime() < timeCooldownExpired)
			{
				// Cooldown is still in effect
				return false;
			}else{
				this.Remove(auth); // Remove the key as it is no longer needed
			}
		}

		return true;
	}

	/**
	 * Applies a cooldown from being chosen as the giant robot.
	 *
	 * @param client 	Client index.
	 */
	public void applyCooldown(int client)
	{
		char auth[MAXLEN_LASTGIANT];
		GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));

		// Store a timestamp of when they can become a giant again. Typically, this will be lower on plr_ maps.
		int cooldown;
		if(g_nGameMode == GameMode_Race)
		{
			cooldown = GetConVarInt(g_hCvarGiantCooldownPlr);
		}else{
			cooldown = GetConVarInt(g_hCvarGiantCooldown);
		}

		this.SetValue(auth, GetTime()+cooldown, true);		
	}
};
GiantTracker g_giantTracker = null;

// Use an ArrayList as a holding space for patch information. The aim is to make it easier to enable/disable memory patches. The ArrayList will follow this structure:
// ------------------------------------------------------------------------------------------------
// address | NumberType | payload count | payload | original memory count | original memory payload
// ------------------------------------------------------------------------------------------------
enum
{
	MemoryIndex_Address=0,
	MemoryIndex_NumberType,
	MemoryIndex_PayloadCount,
};
methodmap MemoryPatch < ArrayList
{
	/**
	 * Creates a new MemoryPatch methodmap. This does not patch memory yet.
	 *
	 * @param address 		The starting address to start patching at.
	 * @param payload 		An array of values to apply.
	 * @param payloadCount 	The total number of values.
	 * @param size 			How many bytes should be applied.
	 */
	public MemoryPatch(Address address, int[] payload, int payloadCount, NumberType size)
	{
		if(address < (view_as<Address>(Address_MinimumValid)) || payloadCount == 0) return null;

		ArrayList list = new ArrayList();

		list.Push(address);
		list.Push(size);
		list.Push(payloadCount);
		for(int i=0; i<payloadCount; i++) list.Push(payload[i]);
		list.Push(0);

		return view_as<MemoryPatch>(list);
	}

	/**
	 * Determines if the memory patch is enabled or not.
	 *
	 * @return True if enabled, false otherwise.
	 */
	public bool isEnabled()
	{
		int origMemoryCount = MemoryIndex_PayloadCount+this.Get(MemoryIndex_PayloadCount)+1;

		return (this.Get(origMemoryCount) > 0);
	}

	/**
	 * Activates a memory patch.
	 *
	 */
	public void enablePatch()
	{
		if(this.isEnabled()) return; // Memory is already patched, do nothing.

		Address address = view_as<Address>(this.Get(MemoryIndex_Address));
		NumberType size = this.Get(MemoryIndex_NumberType);
		int payloadCount = this.Get(MemoryIndex_PayloadCount);

		// Chop off any old original memory by resizing the array.
		this.Resize(MemoryIndex_PayloadCount+this.Get(MemoryIndex_PayloadCount)+2);

		for(int i=0; i<payloadCount; i++)
		{
			int payload = this.Get(MemoryIndex_PayloadCount+i+1);
			int original = LoadFromAddress(address+view_as<Address>(i), size);

			this.Push(original); // Array should be properly resized so apply this to the end.

			StoreToAddress(address+view_as<Address>(i), payload, size);
		}

		// Set the original memory count that flags that we are now patched.
		this.Set(MemoryIndex_PayloadCount+this.Get(MemoryIndex_PayloadCount)+1, payloadCount);
	}

	/**
	 * Disables and cleans up a memory patch.
	 *
	 */
	public void disablePatch()
	{
		if(!this.isEnabled()) return; // Memory is not patched, do nothing.

		Address address = view_as<Address>(this.Get(MemoryIndex_Address));
		NumberType size = this.Get(MemoryIndex_NumberType);
		int payloadCount = this.Get(MemoryIndex_PayloadCount);

		int indexOriginalCount = MemoryIndex_PayloadCount+this.Get(MemoryIndex_PayloadCount)+1;

		for(int i=0; i<payloadCount; i++)
		{
			int payload = this.Get(indexOriginalCount+i+1);

			StoreToAddress(address+view_as<Address>(i), payload, size);
		}

		// Set the original memory count that flags that we are not patched anymore.
		this.Set(indexOriginalCount, 0);
	}
}
MemoryPatch g_patchPhysics = null;
MemoryPatch g_patchUpgrade = null;
MemoryPatch g_patchKnockback = null;
MemoryPatch g_patchChargeEffect = null;
MemoryPatch g_patchNavMesh = null;