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

#include "extension.h"

Tank g_Interface;
SMEXT_LINK(&g_Interface);

CDetour *passDetour;
CDetour *upgradeDetour;
CDetour *statsDetour;
CDetour *dropCreateDetour;
CDetour *dropPickupDetour;
CDetour *entityFilterDetour;

IGameConfig *g_pGameConf = NULL;
IBinTools *g_pBinTools = NULL;
ISDKHooks *g_pSDKHooks = NULL;

IForward *g_pForwardUpgrades = NULL;
IForward *g_pForwardShouldTransmit = NULL;
IForward *g_pForwardOnWeaponPickup = NULL;
IForward *g_pForwardOnWeaponCreate = NULL;
IForward *g_pForwardPassFilter = NULL;

void *g_addr_GetItemSchema = NULL;
void *g_addr_GetAttributeDefinition = NULL;
void *g_addr_SetRuntimeAttributeValue = NULL;
void *g_addr_RemoveAttribute = NULL;
void *g_addr_GetAttributeDefinitionByName = NULL;
void *g_addr_IncrementStat = NULL;

int g_vtbl_ClearCache = 0;

void *g_pCTFGameStats = NULL;

bool g_bShouldTransmitReady = false;

SH_DECL_MANUALHOOK1(MHook_ShouldTransmit, 0, 0, 0, int, CCheckTransmitInfo*);

bool MapLessFunc(const int32_t &in1, const int32_t &in2)
{
	return (in1 < in2);
}
typedef CUtlMap<int32_t, int32_t> HookMap;
HookMap g_Hooks(MapLessFunc);

// Detour for int CPathTrack::InputPass(inputdata_t &)
DETOUR_DECL_MEMBER1(InputPass, void, inputdata_t&, input)
{
	if(input.pCaller != NULL)
	{
		const char *classname = gamehelpers->GetEntityClassname(input.pCaller);
		if(classname && strcmp(classname, "tank_boss") == 0)
		{
#ifdef DEBUG
			g_pSM->LogMessage(myself, "Blocked tank boss from activating OnPass!");
#endif
			return;
		}
	}

	//g_pSM->LogMessage(myself, "InputPass called by %d!", gamehelpers->EntityToBCompatRef(input.pCaller));
	return DETOUR_MEMBER_CALL(InputPass)(input);
}

// Detour for CTFGameRules::GameModeUsesUpgrades(void)
DETOUR_DECL_MEMBER0(GameModeUsesUpgrades, bool)
{
	//g_pSM->LogMessage(myself, "(GameModeUsesUpgrades)");

	if(g_pForwardUpgrades != NULL)
	{
		int returnValue = 0;

		cell_t result = Pl_Continue;
		g_pForwardUpgrades->PushCellByRef(&returnValue);
		g_pForwardUpgrades->Execute(&result);

		if(result != Pl_Continue)
		{
			return returnValue != 0;
		}
	}

	return DETOUR_MEMBER_CALL(GameModeUsesUpgrades)();
}

// Detour for CTFGameStats::Event_LevelInit(void)
DETOUR_DECL_MEMBER0(Event_LevelInit, void)
{
	if(g_pCTFGameStats == NULL)
	{
		g_pCTFGameStats = reinterpret_cast<void *>(this);
		g_pSM->LogMessage(myself, "CTFGameStats = 0x%.8X", g_pCTFGameStats);
	}

	return DETOUR_MEMBER_CALL(Event_LevelInit)();
}

// Detour for CTFDroppedWeapon* CTFDroppedWeapon::Create(CTFPlayer *,Vector const&,QAngle const&,char const*,CEconItemView const*)
DETOUR_DECL_STATIC5(CTFDroppedWeapon_Create, CTFDroppedWeapon*, CTFPlayer*, player, Vector const&, pos, QAngle const&, ang, char const*, worldModel, CEconItemView*, item)
{
	//g_pSM->LogMessage(myself, "CTFDroppedWeapon::Create(?,?,\"%s\",%X)", worldModel, item);

	// We can stop the creation of a dropped weapon here.
	if(item != NULL && g_pForwardOnWeaponCreate->GetFunctionCount() > 0)
	{
		g_pForwardOnWeaponCreate->PushCell(item->m_iItemDefinitionIndex);

		// At this time, a weapon is dropped for 3 reasons: 1) Spy feign 2) Player death 3) On weapon regen.
		g_pForwardOnWeaponCreate->PushCell(item->m_iAccountID);
		g_pForwardOnWeaponCreate->PushCell(item->m_iItemIDHigh);
		g_pForwardOnWeaponCreate->PushCell(item->m_iItemIDLow);
		g_pForwardOnWeaponCreate->PushCell(reinterpret_cast<cell_t>(item));

		cell_t result = Pl_Continue;
		g_pForwardOnWeaponCreate->Execute(&result);

		if(result != Pl_Continue) return NULL; // Block the dropped weapon from being created.
	}

	return DETOUR_STATIC_CALL(CTFDroppedWeapon_Create)(player, pos, ang, worldModel, item);
}

// Detour for bool CTFPlayer::PickupWeaponFromOther(CTFDroppedWeapon const*)
DETOUR_DECL_MEMBER1(PickupWeaponFromOther, bool, CTFDroppedWeapon const*, droppedWeapon)
{
	//g_pSM->LogMessage(myself, "CTFPlayer::PickupWeaponFromOther(%X)", droppedWeapon);

	// A player is attempting to pick up a dropped weapon. We can cleanly control if the weapon can be picked up here!
	if(droppedWeapon != NULL && g_pForwardOnWeaponPickup->GetFunctionCount() > 0)
	{
		int client = gamehelpers->EntityToBCompatRef((CBaseEntity*)this);
		int weapon = gamehelpers->EntityToBCompatRef((CBaseEntity*)droppedWeapon);

		g_pForwardOnWeaponPickup->PushCell(client);
		g_pForwardOnWeaponPickup->PushCell(weapon);
		cell_t returnValue = 0;
		g_pForwardOnWeaponPickup->PushCellByRef(&returnValue);

		cell_t result = Pl_Continue;
		g_pForwardOnWeaponPickup->Execute(&result);

		if(result != Pl_Continue) return (returnValue != 0);
	}

	return DETOUR_MEMBER_CALL(PickupWeaponFromOther)(droppedWeapon);
}

// adapted from util_shared.h
inline const CBaseEntity *UTIL_EntityFromEntityHandle( const IHandleEntity *pConstHandleEntity )
{
	IHandleEntity *pHandleEntity = const_cast<IHandleEntity *>( pConstHandleEntity );
	IServerUnknown *pUnk = static_cast<IServerUnknown *>( pHandleEntity );

	return pUnk->GetBaseEntity();
}

// This code is adapted from CollisionHook: https://forums.alliedmods.net/showthread.php?t=197815
// Detour for bool PassServerEntityFilter(IHandleEntity const*, IHandleEntity const*)
DETOUR_DECL_STATIC2(PassServerEntityFilterFunc, bool, const IHandleEntity *, pTouch, const IHandleEntity *, pPass)
{
	if(g_pForwardPassFilter == NULL || g_pForwardPassFilter->GetFunctionCount() == 0)
		return DETOUR_STATIC_CALL( PassServerEntityFilterFunc )(pTouch, pPass);

	if(pTouch == pPass)
		return DETOUR_STATIC_CALL(PassServerEntityFilterFunc)(pTouch, pPass); // self checks aren't interesting

	if(pTouch == NULL || pPass == NULL)
		return DETOUR_STATIC_CALL(PassServerEntityFilterFunc)(pTouch, pPass); // need two valid entities

	CBaseEntity *pEnt1 = const_cast<CBaseEntity *>(UTIL_EntityFromEntityHandle(pTouch));
	CBaseEntity *pEnt2 = const_cast<CBaseEntity *>(UTIL_EntityFromEntityHandle(pPass));

	if(pEnt1 == NULL || pEnt2 == NULL)
		return DETOUR_STATIC_CALL(PassServerEntityFilterFunc)(pTouch, pPass); // we need both entities

	cell_t ent1 = gamehelpers->EntityToBCompatRef(pEnt1);
	cell_t ent2 = gamehelpers->EntityToBCompatRef(pEnt2);

	// todo: do we want to fill result with with the game's result? perhaps the forward path is more performant...
	cell_t result = 0;
	g_pForwardPassFilter->PushCell(ent1);
	g_pForwardPassFilter->PushCell(ent2);
	g_pForwardPassFilter->PushCellByRef(&result);

	cell_t retValue = 0;
	g_pForwardPassFilter->Execute(&retValue);

	if(retValue > Pl_Continue)
	{
		// plugin wants to change the result
		return result == 1;
	}

	// otherwise, game decides
	return DETOUR_STATIC_CALL(PassServerEntityFilterFunc)(pTouch, pPass);
}

bool LookupSignature(char const *key, void **addr)
{
	if(!g_pGameConf->GetMemSig(key, addr))
	{
		g_pSM->LogMessage(myself, "Failed to read signature: %s.", key);
	}else{
		if(*addr == NULL)
		{
			g_pSM->LogMessage(myself, "Failed to find signature: %s", key);
			return false;
		}

		//g_pSM->LogMessage(myself, "%s call: 0x%.8X.", key, *addr);
		return true;
	}

	return false;
}

CBaseEntity *GetCBaseEntityFromIndex(int num, bool onlyPlayers)
{	
	edict_t *pEdict = engine->PEntityOfEntIndex(num);
	if (!pEdict || pEdict->IsFree())
	{
		return NULL;
	}

	if (num > 0 && num <= playerhelpers->GetMaxClients())
	{
		IGamePlayer *pPlayer = playerhelpers->GetGamePlayer(pEdict);
		if (!pPlayer || !pPlayer->IsConnected())
		{
			return NULL;
		}
	}
	else if (onlyPlayers)
	{
		return NULL;
	}

	IServerUnknown *pUnk;
	if ((pUnk=pEdict->GetUnknown()) == NULL)
	{
		return NULL;
	}

	return pUnk->GetBaseEntity();
}

bool LookupOffset(char const *classname, char const *offset, int &iOffset, bool bVerbose)
{
	sm_sendprop_info_t info_t;
	if(!gamehelpers->FindSendPropInfo(classname, offset, &info_t))
	{
		if(bVerbose) g_pSM->LogMessage(myself, "Offset Error: %s::%s.", classname, offset);
	}else{
		iOffset = info_t.actual_offset;
		if(bVerbose) g_pSM->LogMessage(myself, "Offset: %s::%s = %d.", classname, offset, iOffset);
		return true;
	}

	return false;
}

int FindEntityOffset(CBaseEntity *pEntity, const char *strOffset)
{
	// Find the offset in the sendprops for the m_AttributeList property, this will allow us to interact with CAttributeList
	IServerUnknown *pUnk = (IServerUnknown *)pEntity;
	IServerNetworkable *pNet = pUnk->GetNetworkable();
	if(!pNet) return 0;

	// Get the IServerNetworkable interface
	ServerClass *pClass = pNet->GetServerClass();
	if(!pClass) return 0;

	int iOffset;
	if(!LookupOffset(pClass->GetName(), strOffset, iOffset, false)) return 0;

	return iOffset;
}

CEconItemSchema *TF2_GetItemSchema()
{
#if defined DEBUG
	g_pSM->LogMessage(myself, " > TF2_GetItemSchema..");
#endif

	if(!g_pBinTools || !g_addr_GetItemSchema)
	{
		g_pSM->LogMessage(myself, "Failed to call TF2_GetItemSchema!");
		return NULL;
	}

	static ICallWrapper *pWrapper = NULL;

	// CEconItemSchema *GetItemSchema(void) 
	if (!pWrapper)
	{
		PassInfo ret;
		ret.flags = PASSFLAG_BYVAL;
		ret.size = sizeof(CEconItemSchema *);
		ret.type = PassType_Basic;
		
		pWrapper = g_pBinTools->CreateCall(g_addr_GetItemSchema, CallConv_Cdecl, &ret, NULL, 0);
	}

	unsigned char vstk[sizeof(void *)];
	unsigned char *vptr = vstk;

	*(void **)vptr = g_addr_GetItemSchema;

	CEconItemSchema *pItemSchema;

	pWrapper->Execute(vstk, &pItemSchema);

	return pItemSchema;
}

CEconItemAttributeDefinition *CEconItemSchema_GetAttributeDefinition(CEconItemSchema *pSchema, int iAttributeDefinitionIndex)
{
#if defined DEBUG
	g_pSM->LogMessage(myself, " > CEconItemSchema_GetAttributeDefinition..");
#endif
	if(!pSchema || !g_addr_GetAttributeDefinition)
	{
		g_pSM->LogMessage(myself, " > Failed to call CEconItemSchema_GetAttributeDefinition.");
		return NULL;
	}

	static ICallWrapper *pWrapper = NULL;

	// CEconItemAttributeDefinition *CEconItemSchema::GetAttributeDefinition(int)
	if(!pWrapper)
	{
		PassInfo pass[1];
		pass[0].flags = PASSFLAG_BYVAL;
		pass[0].size = sizeof(int);
		pass[0].type = PassType_Basic;

		PassInfo ret;
		ret.flags = PASSFLAG_BYVAL;
		ret.size = sizeof(CEconItemAttributeDefinition *);
		ret.type = PassType_Basic;
		
		pWrapper = g_pBinTools->CreateCall(g_addr_GetAttributeDefinition, CallConv_ThisCall, &ret, pass, 1);
	}
	
	unsigned char vstk[sizeof(void *) + sizeof(int)];
	unsigned char *vptr = vstk;

	*(void **)vptr = (void *)pSchema;
	vptr += sizeof(void *);
	*(int *)vptr = iAttributeDefinitionIndex;

	CEconItemAttributeDefinition *pAttribDef;

	pWrapper->Execute(vstk, &pAttribDef);

	return pAttribDef;
}

CEconItemAttributeDefinition *CEconItemSchema_GetAttributeDefinitionByName(CEconItemSchema *pSchema, const char *strAttribute)
{
#if defined DEBUG
	g_pSM->LogMessage(myself, " > CEconItemSchema_GetAttributeDefinitionByName..");
#endif
	if(!pSchema || !g_addr_GetAttributeDefinitionByName)
	{
		g_pSM->LogMessage(myself, " > Failed to call CEconItemSchema_GetAttributeDefinitionByName.");
		return NULL;
	}

	static ICallWrapper *pWrapper = NULL;

	// CEconItemAttributeDefinition *CEconItemSchema::GetAttributeDefinitionByName(char const*)
	if(!pWrapper)
	{
		PassInfo pass[1];
		pass[0].flags = PASSFLAG_BYVAL;
		pass[0].size = sizeof(char const *);
		pass[0].type = PassType_Basic;

		PassInfo ret;
		ret.flags = PASSFLAG_BYVAL;
		ret.size = sizeof(CEconItemAttributeDefinition *);
		ret.type = PassType_Basic;
		
		pWrapper = g_pBinTools->CreateCall(g_addr_GetAttributeDefinitionByName, CallConv_ThisCall, &ret, pass, 1);
	}
	
	unsigned char vstk[sizeof(void *) + sizeof(char const *)];
	unsigned char *vptr = vstk;

	*(void **)vptr = (void *)pSchema;
	vptr += sizeof(void *);
	*(char const **)vptr = strAttribute;

	CEconItemAttributeDefinition *pAttribDef;

	pWrapper->Execute(vstk, &pAttribDef);

	return pAttribDef;
}

CEconItemAttributeDefinition *TF2_GetAttributeDefinition(int iAttributeDefinitionIndex)
{
	CEconItemSchema *pItemSchema = TF2_GetItemSchema();
	if(pItemSchema)
	{
		CEconItemAttributeDefinition *pDef = CEconItemSchema_GetAttributeDefinition(pItemSchema, iAttributeDefinitionIndex);
		if(pDef)
		{
			return pDef;
		}
	}

	return NULL;
}

CEconItemAttributeDefinition *TF2_GetAttributeDefinitionByName(const char *strAttribute)
{
	CEconItemSchema *pItemSchema = TF2_GetItemSchema();
	if(pItemSchema)
	{
		CEconItemAttributeDefinition *pDef = CEconItemSchema_GetAttributeDefinitionByName(pItemSchema, strAttribute);
		if(pDef)
		{
			return pDef;
		}
	}

	return NULL;
}

void CAttributeList_SetRuntimeAttributeValue(CAttributeList *pAttribList, CEconItemAttributeDefinition *pAttribDef, float flAttribValue)
{
#if defined DEBUG
	g_pSM->LogMessage(myself, " > CAttributeList_SetRuntimeAttributeValue..");
#endif
	if(!pAttribList || !pAttribDef || !g_addr_SetRuntimeAttributeValue)
	{
		g_pSM->LogMessage(myself, " > Failed to call CAttributeList_SetRuntimeAttributeValue.");
		return;
	}

	static ICallWrapper *pWrapper = NULL;

	// void CAttributeList::SetRuntimeAttributeValue(CEconItemAttributeDefinition  const*,float)
	if(!pWrapper)
	{
		PassInfo pass[2];
		pass[0].flags = PASSFLAG_BYVAL;
		pass[0].size = sizeof(CEconItemAttributeDefinition *);
		pass[0].type = PassType_Basic;

		pass[1].flags = PASSFLAG_BYVAL;
		pass[1].size = sizeof(float);
		pass[1].type = PassType_Basic;
		
		pWrapper = g_pBinTools->CreateCall(g_addr_SetRuntimeAttributeValue, CallConv_ThisCall, NULL, pass, 2);
	}
	
	unsigned char vstk[sizeof(void *) + sizeof(CEconItemAttributeDefinition *) + sizeof(float)];
	unsigned char *vptr = vstk;

	*(void **)vptr = (void *)pAttribList;
	vptr += sizeof(void *);
	*(CEconItemAttributeDefinition **)vptr = pAttribDef;
	vptr += sizeof(CEconItemAttributeDefinition *);
	*(float *)vptr = flAttribValue;

	pWrapper->Execute(vstk, NULL);
}

int CAttributeList_RemoveAttribute(CAttributeList *pAttribList, CEconItemAttributeDefinition *pDefinition)
{
#if defined DEBUG
	g_pSM->LogMessage(myself, " > CAttributeList_RemoveAttribute..");
#endif
	if(!pAttribList || !pDefinition || !g_addr_RemoveAttribute)
	{
		g_pSM->LogMessage(myself, " > Failed to call CAttributeList_RemoveAttribute.");
		return 0;
	}

	static ICallWrapper *pWrapper = NULL;

	// int CAttributeList::RemoveAttribute(CEconItemAttributeDefinition  const*)
	if(!pWrapper)
	{
		PassInfo pass[2];
		pass[0].flags = PASSFLAG_BYVAL;
		pass[0].size = sizeof(CEconItemAttributeDefinition *);
		pass[0].type = PassType_Basic;

		PassInfo ret;
		ret.flags = PASSFLAG_BYVAL;
		ret.size = sizeof(int);
		ret.type = PassType_Basic;
		
		pWrapper = g_pBinTools->CreateCall(g_addr_RemoveAttribute, CallConv_ThisCall, &ret, pass, 1);
	}
	
	unsigned char vstk[sizeof(void *) + sizeof(CEconItemAttributeDefinition *)];
	unsigned char *vptr = vstk;

	*(void **)vptr = (void *)pAttribList;
	vptr += sizeof(void *);
	*(CEconItemAttributeDefinition **)vptr = pDefinition;

	int iResult;

	pWrapper->Execute(vstk, &iResult);

	return iResult;
}

bool TF2_GetAttributeValue(CBaseEntity *pEntity, int iAttribIndex, float& flValue)
{
	// Find the m_AttributeList property (not always under m_Item)
	int iOffset = FindEntityOffset(pEntity, "m_AttributeList");
	if(iOffset <= 0) return 0;

	CAttributeList *pAttribList = (CAttributeList *)((uint8_t *)pEntity + iOffset);
	if(pAttribList)
	{
		CUtlVector<CEconItemAttribute> *m_Attributes = (CUtlVector<CEconItemAttribute> *)((uint8_t *)pAttribList + OFFSET_RUNTIME);
		if(m_Attributes)
		{
			// Search the runtime attributes
			for(int i=0; i<m_Attributes->Count(); i++)
			{
				if(m_Attributes->Element(i).m_iAttributeDefinitionIndex == iAttribIndex)
				{
					flValue = m_Attributes->Element(i).m_flValue;
					return true;
				}
			}
		}
	}

	return false;
}

static cell_t Tank_SetAttributeValue(IPluginContext *pContext, const cell_t *params)
{
	// This native calls CAttributeList::SetRuntimeAttributeValue, overwriting an existing attribute and refreshing
	// Returns true if the attribute was added/changed -> false otherwise
	CBaseEntity *pEntity;
	int iEntity = params[1];
	int iAttribIndex = params[2];
	if(iEntity < 1 || !(pEntity = GetCBaseEntityFromIndex(iEntity, false))) return pContext->ThrowNativeError("Entity index %d is not valid!", iEntity);
	
	// Find the m_AttributeList property (not always under m_Item)
	int iOffset = FindEntityOffset(pEntity, "m_AttributeList");
	if(iOffset <= 0) return 0;

	CAttributeList *pAttribList = (CAttributeList *)((uint8_t *)pEntity + iOffset);
	if(pAttribList)
	{
		CEconItemAttributeDefinition *pDef = TF2_GetAttributeDefinition(iAttribIndex);
		if(pDef)
		{
			// New code - attempts to call SetRuntimeAttributeValue
			CAttributeList_SetRuntimeAttributeValue(pAttribList, pDef, sp_ctof(params[3]));
			return 1;
		}else{
			g_pSM->LogMessage(myself, "Attribute index %d is not valid!", iAttribIndex);
		}
	}

	return 0;
}

static cell_t Tank_SetAttributeValueByName(IPluginContext *pContext, const cell_t *params)
{
	// This native calls CAttributeList::SetRuntimeAttributeValue, overwriting an existing attribute and refreshing
	// Returns true if the attribute was added/changed -> false otherwise
	CBaseEntity *pEntity;
	int iEntity = params[1];
	if(iEntity < 1 || !(pEntity = GetCBaseEntityFromIndex(iEntity, false))) return pContext->ThrowNativeError("Entity index %d is not valid!", iEntity);
	
	char *strAttribute = NULL;
	pContext->LocalToString(params[2], &strAttribute);
	if(strAttribute == NULL) return pContext->ThrowNativeError("Attribute name is NULL!");

	// Find the m_AttributeList property (not always under m_Item)
	int iOffset = FindEntityOffset(pEntity, "m_AttributeList");
	if(iOffset <= 0) return 0;

	CAttributeList *pAttribList = (CAttributeList *)((uint8_t *)pEntity + iOffset);
	if(pAttribList)
	{
		CEconItemAttributeDefinition *pDef = TF2_GetAttributeDefinitionByName(strAttribute);
		if(pDef != NULL)
		{
			// New code - attempts to call SetRuntimeAttributeValue
			CAttributeList_SetRuntimeAttributeValue(pAttribList, pDef, sp_ctof(params[3]));
			return 1;
		}else{
			g_pSM->LogMessage(myself, "Attribute name \"%s\" is not valid!", strAttribute);
		}
	}

	return 0;
}

static cell_t Tank_RemoveAttribute(IPluginContext *pContext, const cell_t *params)
{
	// This native calls CAttributeList::RemoveAttribute(CEconItemAttributeDefinition  const*)
	CBaseEntity *pEntity;
	int iEntity = params[1];
	int iAttribIndex = params[2];
	if(iEntity < 1 || !(pEntity = GetCBaseEntityFromIndex(iEntity, false))) return pContext->ThrowNativeError("Entity index %d is not valid!", iEntity);
	
	// Find the m_AttributeList property (not always under m_Item)
	int iOffset = FindEntityOffset(pEntity, "m_AttributeList");
	if(iOffset <= 0) return 0;

	CAttributeList *pAttribList = (CAttributeList *)((uint8_t *)pEntity + iOffset);
	if(pAttribList)
	{
		CEconItemAttributeDefinition *pDef = TF2_GetAttributeDefinition(iAttribIndex);
		if(pDef)
		{
			CAttributeList_RemoveAttribute(pAttribList, pDef);
		}else{
			g_pSM->LogMessage(myself, "Attribute index %d is not valid!", iAttribIndex);
		}
	}

	return 0;
}

static cell_t Tank_RemoveAttributeByName(IPluginContext *pContext, const cell_t *params)
{
	// This native calls CAttributeList::RemoveAttribute(CEconItemAttributeDefinition  const*)
	CBaseEntity *pEntity;
	int iEntity = params[1];
	if(iEntity < 1 || !(pEntity = GetCBaseEntityFromIndex(iEntity, false))) return pContext->ThrowNativeError("Entity index %d is not valid!", iEntity);

	char *strAttribute = NULL;
	pContext->LocalToString(params[2], &strAttribute);
	if(strAttribute == NULL) return pContext->ThrowNativeError("Attribute name is NULL!");

	// Find the m_AttributeList property (not always under m_Item)
	int iOffset = FindEntityOffset(pEntity, "m_AttributeList");
	if(iOffset <= 0) return 0;

	CAttributeList *pAttribList = (CAttributeList *)((uint8_t *)pEntity + iOffset);
	if(pAttribList)
	{
		CEconItemAttributeDefinition *pDef = TF2_GetAttributeDefinitionByName(strAttribute);
		if(pDef)
		{
			CAttributeList_RemoveAttribute(pAttribList, pDef);
		}else{
			g_pSM->LogMessage(myself, "Attribute name \"%d\" is not valid!", strAttribute);
		}
	}

	return 0;
}

static cell_t Tank_GetAttributeValue(IPluginContext *pContext, const cell_t *params)
{
	// This native will search for a matching attribute in the runtime attributes
	// Returns true if the attribute was found -> false otherwise
	CBaseEntity *pEntity;
	int iEntity = params[1];
	int iAttribIndex = params[2];
	cell_t *flValue;
	pContext->LocalToPhysAddr(params[3], &flValue);
	if(iEntity < 1 || !(pEntity = GetCBaseEntityFromIndex(iEntity, false))) return pContext->ThrowNativeError("Entity index %d is not valid!", iEntity);
	
	float flReturnedValue;
	if(TF2_GetAttributeValue(pEntity, iAttribIndex, flReturnedValue))
	{
		flValue[0] = sp_ftoc(flReturnedValue);
		return 1;
	}

	return 0;
}

int Hook_ShouldTransmit(CCheckTransmitInfo *pInfo)
{
	if(!g_pForwardShouldTransmit || g_pForwardShouldTransmit->GetFunctionCount() == 0) RETURN_META_VALUE(MRES_IGNORED, 0);

	CBaseEntity *pEntity = META_IFACEPTR(CBaseEntity);
	if(!pEntity) RETURN_META_VALUE(MRES_IGNORED, 0);
	int iEntity = gamehelpers->EntityToBCompatRef(pEntity);
	if(iEntity <= 0) RETURN_META_VALUE(MRES_IGNORED, 0);

	int client = 0;
	if(pInfo && pInfo->m_pClientEnt) client = gamehelpers->IndexOfEdict(pInfo->m_pClientEnt);
	if(client <= 0 || client > playerhelpers->GetMaxClients()) RETURN_META_VALUE(MRES_IGNORED, 0);

	cell_t result = Pl_Continue;
	cell_t origReturn = META_RESULT_ORIG_RET(int);

	g_pForwardShouldTransmit->PushCell(iEntity);
	g_pForwardShouldTransmit->PushCell(client);
	g_pForwardShouldTransmit->PushCellByRef(&origReturn);

	g_pForwardShouldTransmit->Execute(&result);

	if(result != Pl_Continue)
	{
		RETURN_META_VALUE(MRES_SUPERCEDE, origReturn);
	}

	RETURN_META_VALUE(MRES_IGNORED, 0);
}

static cell_t Tank_HookShouldTransmit(IPluginContext *pContext, const cell_t *params)
{
	// This native will hook ShouldTransmit on the given entity
	CBaseEntity *pEntity;
	if(!(pEntity = GetCBaseEntityFromIndex(params[1], false))) return pContext->ThrowNativeError("Entity index %d is not valid!", params[1]);

	if(!g_bShouldTransmitReady) return 0;

	int hookId = SH_ADD_MANUALHOOK(MHook_ShouldTransmit, pEntity, SH_STATIC(Hook_ShouldTransmit), false);

#ifdef DEBUG
	g_pSM->LogMessage(myself, "Adding ShouldTransmit hook on entity %d (hook id %d) (ref %d)!", params[1], hookId, gamehelpers->EntityToReference(pEntity));
#endif
	g_Hooks.Insert(gamehelpers->EntityToReference(pEntity), hookId);

	return 0;
}

static cell_t Tank_IncrementStat(IPluginContext *pContext, const cell_t *params)
{
	CBaseEntity *player;
	if(!(player = GetCBaseEntityFromIndex(params[1], true))) return pContext->ThrowNativeError("Client index %d is not valid!", params[1]);
	int statType = params[2];
	int increment = params[3];

#if defined DEBUG
	g_pSM->LogMessage(myself, "> Calling CTFGameStats::IncrementStat..");
#endif

	if(g_addr_IncrementStat == NULL || g_pCTFGameStats == NULL)
	{
		g_pSM->LogMessage(myself, "Failed to call CTFGameStats::IncrementStat!");
		return 0;
	}

	static ICallWrapper *pWrapper = NULL;

	// CTFGameStats::IncrementStat(CTFPlayer *, TFStatType_t, int)
	if(!pWrapper)
	{
		PassInfo pass[3];
		pass[0].flags = PASSFLAG_BYVAL;
		pass[0].size = sizeof(CBaseEntity *);
		pass[0].type = PassType_Basic;

		pass[1].flags = PASSFLAG_BYVAL;
		pass[1].size = sizeof(int);
		pass[1].type = PassType_Basic;
		
		pass[2].flags = PASSFLAG_BYVAL;
		pass[2].size = sizeof(int);
		pass[2].type = PassType_Basic;

		pWrapper = g_pBinTools->CreateCall(g_addr_IncrementStat, CallConv_ThisCall, NULL, pass, 3);
	}
	
	unsigned char vstk[sizeof(void *) + sizeof(CBaseEntity *) + sizeof(int) + sizeof(int)];
	unsigned char *vptr = vstk;

	*(void **)vptr = g_pCTFGameStats;
	vptr += sizeof(void *);
	*(CBaseEntity **)vptr = player;
	vptr += sizeof(CBaseEntity *);
	*(int *)vptr = statType;
	vptr += sizeof(int);
	*(int *)vptr = increment;

	pWrapper->Execute(vstk, NULL);

	return 1;
}

static cell_t Tank_ClearCache(IPluginContext *pContext, const cell_t *params)
{
	// This native calls CAttributeManager::ClearCache
	CBaseEntity *pEntity;
	int iEntity = params[1];
	if(iEntity < 1 || !(pEntity = GetCBaseEntityFromIndex(iEntity, false))) return pContext->ThrowNativeError("Entity index %d is not valid!", iEntity);

	// Find the m_AttributeList property (not always under m_Item)
	int iOffset = FindEntityOffset(pEntity, "m_AttributeList");
	if(iOffset <= 0) return pContext->ThrowNativeError("Failed to find CAttributeList for entity %d!", iEntity);

	CAttributeList *list = (CAttributeList *)((uint8_t *)pEntity + iOffset);
	if(list)
	{
		CAttributeManager *manager = *(CAttributeManager **)((uint8_t *)list + OFFSET_MANAGER);
		if(manager)
		{
#if defined DEBUG
			g_pSM->LogMessage(myself, "> Calling CAttributeManager::ClearCache..");
#endif
			if(g_vtbl_ClearCache <= 0)
			{
				g_pSM->LogMessage(myself, "Failed to call CAttributeManager::ClearCache!");
				return 0;
			}

			static ICallWrapper *pWrapper = NULL;

			// CAttributeManager::ClearCache(void)
			if(!pWrapper)
			{
				pWrapper = g_pBinTools->CreateVCall(g_vtbl_ClearCache, 0, 0, NULL, NULL, 0);
			}
	
			unsigned char vstk[sizeof(void *)];
			unsigned char *vptr = vstk;

			*(void **)vptr = (void *)manager;

			pWrapper->Execute(vstk, NULL);			
		}
	}

	return 0;
}

sp_nativeinfo_t g_ExtensionNatives[] = 
{
	{"Tank_SetAttributeValue",			Tank_SetAttributeValue},
	{"Tank_SetAttributeValueByName",	Tank_SetAttributeValueByName},
	{"Tank_RemoveAttribute",			Tank_RemoveAttribute},
	{"Tank_RemoveAttributeByName",		Tank_RemoveAttributeByName},
	{"Tank_GetAttributeValue",			Tank_GetAttributeValue},
	{"Tank_HookShouldTransmit",			Tank_HookShouldTransmit},
	{"Tank_IncrementStat",				Tank_IncrementStat},
	{"Tank_ClearCache",					Tank_ClearCache},
	{NULL,								NULL}
};

void Tank::OnEntityDestroyed(CBaseEntity *pEntity)
{
	if(!pEntity) return;

	int entRef = gamehelpers->EntityToReference(pEntity);
	unsigned short index = g_Hooks.Find(entRef);
	if(g_Hooks.IsValidIndex(index))
	{
		int hookId = g_Hooks.Element(index);
#ifdef DEBUG
		g_pSM->LogMessage(myself, "Removing hook id %d..", hookId);
#endif
		SH_REMOVE_HOOK_ID(hookId);
	}
}

bool LookupOffset(char const *classname, char const *offset, int &iOffset)
{
	sm_sendprop_info_t info_t;
	if(!gamehelpers->FindSendPropInfo(classname, offset, &info_t))
	{
		g_pSM->LogMessage(myself, "Failed to find offset: %s::%s", classname, offset);
		iOffset = -1;
	}else{
		iOffset = info_t.actual_offset;
		return true;
	}

	return false;
}

bool Tank::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
	if(strcmp(g_pSM->GetGameFolderName(), "tf") != 0)
	{
		snprintf(error, maxlength, "Cannot run on other mods than TF2.");
		return false;
	}

	sharesys->AddDependency(myself, "bintools.ext", true, true);
	sharesys->AddDependency(myself, "sdkhooks.ext", true, true);

	char conf_error[255] = "";
	if (!gameconfs->LoadGameConfigFile("tank", &g_pGameConf, conf_error, sizeof(conf_error)))
	{
		snprintf(error, maxlength, "Could not read tank.txt: %s", conf_error);
		return false;
	}

	CDetourManager::Init(g_pSM->GetScriptingEngine(), g_pGameConf);
	
	passDetour = DETOUR_CREATE_MEMBER(InputPass, "CPathTrack::InputPass");
	if(passDetour == NULL)
	{
		g_pSM->LogMessage(myself, "Could not initalize InputPass detour. Will continue to run!");
	}else{
		passDetour->EnableDetour();
	}

	upgradeDetour = DETOUR_CREATE_MEMBER(GameModeUsesUpgrades, "CTFGameRules::GameModeUsesUpgrades");
	if(upgradeDetour == NULL)
	{
		g_pSM->LogMessage(myself, "Could not initalize GameModeUsesUpgrades detour. Will continue to run!");
	}else{
		upgradeDetour->EnableDetour();
	}

	statsDetour = DETOUR_CREATE_MEMBER(Event_LevelInit, "CTFGameStats::Event_LevelInit");
	if(statsDetour == NULL)
	{
		g_pSM->LogMessage(myself, "Could not initalize Event_LevelInit detour. Will continue to run!");
	}else{
		statsDetour->EnableDetour();
	}

	dropCreateDetour = DETOUR_CREATE_STATIC(CTFDroppedWeapon_Create, "CTFDroppedWeapon::Create");
	if(dropCreateDetour == NULL)
	{
		g_pSM->LogMessage(myself, "Could not initalize CTFDroppedWeapon_Create detour. Will continue to run!");
	}else{
		dropCreateDetour->EnableDetour();
	}

	dropPickupDetour = DETOUR_CREATE_MEMBER(PickupWeaponFromOther, "CTFPlayer::PickupWeaponFromOther");
	if(dropPickupDetour == NULL)
	{
		g_pSM->LogMessage(myself, "Could not initalize PickupWeaponFromOther detour. Will continue to run!");
	}else{
		dropPickupDetour->EnableDetour();
	}

	entityFilterDetour = DETOUR_CREATE_STATIC(PassServerEntityFilterFunc, "PassServerEntityFilter");
	if(entityFilterDetour == NULL)
	{
		g_pSM->LogMessage(myself, "Could not initalize PassServerEntityFilter detour. Will continue to run!");
	}else{
		entityFilterDetour->EnableDetour();
	}

	LookupSignature("GetItemSchema", &g_addr_GetItemSchema);
	LookupSignature("CEconItemSchema::GetAttributeDefinition", &g_addr_GetAttributeDefinition);
	LookupSignature("CEconItemSchema::GetAttributeDefinitionByName", &g_addr_GetAttributeDefinitionByName);
	LookupSignature("CAttributeList::SetRuntimeAttributeValue", &g_addr_SetRuntimeAttributeValue);
	LookupSignature("CAttributeList::RemoveAttribute", &g_addr_RemoveAttribute);
	LookupSignature("CTFGameStats::IncrementStat", &g_addr_IncrementStat);

	if(!g_pGameConf->GetOffset("CAttributeManager::OnAttributeValuesChanged", &g_vtbl_ClearCache))
	{
		g_pSM->LogMessage(myself, "Failed to find offset: CAttributeManager::OnAttributeValuesChanged!");
	}

	g_pForwardUpgrades = forwards->CreateForward("Tank_OnGameModeUsesUpgrades", ET_Event, 1, NULL, Param_CellByRef);
	g_pForwardShouldTransmit = forwards->CreateForward("Tank_OnShouldTransmit", ET_Event, 3, NULL, Param_Cell, Param_Cell, Param_CellByRef);
	g_pForwardOnWeaponPickup = forwards->CreateForward("Tank_OnWeaponPickup", ET_Event, 3, NULL, Param_Cell, Param_Cell, Param_CellByRef);
	g_pForwardOnWeaponCreate = forwards->CreateForward("Tank_OnWeaponDropped", ET_Event, 5, NULL, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_pForwardPassFilter = forwards->CreateForward("Tank_PassFilter", ET_Hook, 3, NULL, Param_Cell, Param_Cell, Param_CellByRef);

	int iOffset;
	if(!g_pGameConf->GetOffset("CBaseEntity::ShouldTransmit", &iOffset))
	{
		g_pSM->LogMessage(myself, "Failed to find offset: CBaseEntity::ShouldTransmit!");
		g_bShouldTransmitReady = false;
	}else{
		SH_MANUALHOOK_RECONFIGURE(MHook_ShouldTransmit, iOffset, 0, 0);
		g_bShouldTransmitReady = true;
	}

	sharesys->AddNatives(myself, g_ExtensionNatives);

	g_bShouldTransmitReady = false;

	return true;
}

void Tank::SDK_OnAllLoaded()
{
	SM_GET_LATE_IFACE(BINTOOLS, g_pBinTools);
	SM_GET_LATE_IFACE(SDKHOOKS, g_pSDKHooks);

	if(g_pBinTools == NULL)
	{
		g_pSM->LogMessage(myself, "Unable to retrieve interface: BINTOOLS!");
	}

	if(g_pSDKHooks == NULL)
	{
		g_pSM->LogMessage(myself, "Unable to retrieve interface: SDKHOOKS!");
	}else{
		g_pSDKHooks->AddEntityListener(this);
	}
}

bool Tank::QueryRunning(char *error, size_t maxlength)
{
	SM_CHECK_IFACE(BINTOOLS, g_pBinTools);
	SM_CHECK_IFACE(SDKHOOKS, g_pSDKHooks);	

	return true;
}

void Tank::NotifyInterfaceDrop(SMInterface *pInterface)
{
	if(strcmp(pInterface->GetInterfaceName(), SMINTERFACE_SDKHOOKS_NAME) == 0)
	{
		if(g_pSDKHooks != NULL)
		{
			g_pSDKHooks->RemoveEntityListener(this);
			g_pSDKHooks = NULL;
		}
	}else if(strcmp(pInterface->GetInterfaceName(), SMINTERFACE_BINTOOLS_NAME) == 0)
	{
		g_pBinTools = NULL;
	}
}

void Tank::SDK_OnUnload()
{
	gameconfs->CloseGameConfigFile(g_pGameConf);

	if(passDetour != NULL)
	{
		passDetour->Destroy();
	}
	if(upgradeDetour != NULL)
	{
		upgradeDetour->Destroy();
	}
	if(statsDetour != NULL)
	{
		statsDetour->Destroy();
	}
	if(dropCreateDetour != NULL)
	{
		dropCreateDetour->Destroy();
	}
	if(dropPickupDetour != NULL)
	{
		dropPickupDetour->Destroy();
	}
	if(entityFilterDetour != NULL)
	{
		entityFilterDetour->Destroy();
	}

	forwards->ReleaseForward(g_pForwardUpgrades);
	forwards->ReleaseForward(g_pForwardShouldTransmit);
	forwards->ReleaseForward(g_pForwardOnWeaponPickup);
	forwards->ReleaseForward(g_pForwardOnWeaponCreate);
	forwards->ReleaseForward(g_pForwardPassFilter);
	
	if(g_pSDKHooks != NULL)
	{
		g_pSDKHooks->RemoveEntityListener(this);
		g_pSDKHooks = NULL;
	}

	FOR_EACH_MAP_FAST(g_Hooks, hookId)
	{
#ifdef DEBUG
		g_pSM->LogMessage(myself, "Removing hook id %d..", hookId);
#endif
		SH_REMOVE_HOOK_ID(hookId);
	}

	g_bShouldTransmitReady = false;
}
