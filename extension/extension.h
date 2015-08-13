#ifndef _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_
#define _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_

#include "smsdk_ext.h"
#include "CDetour/detours.h"
#include <server_class.h>
#include <IBinTools.h>
#include <ISDKHooks.h>
#include <utlmap.h>

//#define DEBUG

#define OFFSET_RUNTIME 4 // Offset from CAttributeList
#define OFFSET_MANAGER 24 // Offset from CAttributeList

class CAttributeList;
class CAttributeManager; // CAttributeList + 24

class CTFPlayer;
class CEconItemAttributeDefinition;
class CTFItemDefinition;
class CEconItemDefinition;
class CEconItemSystem;
class CEconItemSchema; // CEconItemSystem + 4
class CEconItem;
class CTakeDamageInfo;
class CTFDroppedWeapon;
class ITexture;
class ITextureCompositor;

struct inputdata_t
{
	CBaseEntity *pActivator;		// The entity that initially caused this chain of output events.
	CBaseEntity *pCaller;			// The entity that fired this particular output.
	class value;					// The data parameter for this output.
	int nOutputID;					// The unique ID of the output that was fired.
};

#pragma pack(push, 4)

class CEconItemAttribute
{
public:
	void *m_pVTable; //0

	uint16 m_iAttributeDefinitionIndex; //4
	float m_flValue; //8
	int32 m_nRefundableCurrency; //12
};

class CEconItemHandle
{
public:
	void *m_pVTable;

	CEconItem *m_pItem;

	int64 m_ulItemID;
	uint64 m_SteamID;
};

class CEconItemView
{
public:
	void *m_pVTable; //0

	uint16 m_iItemDefinitionIndex; //4
	
	int32 m_iEntityQuality; //8
	uint32 m_iEntityLevel; //12

	uint64 m_iItemID; //16
	uint32 m_iItemIDHigh; //24
	uint32 m_iItemIDLow; //28
	uint32 m_iAccountID; //32
	uint32 m_iInventoryPosition; //36
	
	CEconItemHandle m_ItemHandle; //40 (44, 48, 52, 56, 60)

	bool	m_bColorInit; //64
	uint32	m_unHalloweenRGB; //68
	uint32	m_unHalloweenAltRGB; //72
	uint32	m_unRGB; //76
	uint32	m_unAltRGB; //80

	ITexture *m_pWeaponSkinBase; //84
	ITextureCompositor *m_pWeaponSkinBaseCompositor; //88

	// no love given here
	uint32 m_Unk1; //92
	uint32 m_Unk2; //94
	uint32 m_Unk3; //100

	int32 m_iTeamNumber; //104

	bool m_bInitialized; //108

	//CAttributeList m_AttributeList; //112 (116, 120, 124, 128, 132, 136)
	//CAttributeList m_NetworkedDynamicAttributesForDemos; //140 (144, 148, 152, 156, 160, 164)
	uint32 padding[14]; //112...164

	bool m_bDoNotIterateStaticAttributes; //168
};

#pragma pack(pop)

static_assert(sizeof(CEconItemView) == 172, "CEconItemView - incorrect size on this compiler");
static_assert(sizeof(CEconItemHandle) == 24, "CEconItemHandle - incorrect size on this compiler");

/**
 * @brief Sample implementation of the SDK Extension.
 * Note: Uncomment one of the pre-defined virtual functions in order to use it.
 */
class Tank : 
	public SDKExtension,
	public ISMEntityListener
{
public:
	/**
	 * @brief This is called after the initial loading sequence has been processed.
	 *
	 * @param error		Error message buffer.
	 * @param maxlength	Size of error message buffer.
	 * @param late		Whether or not the module was loaded after map load.
	 * @return			True to succeed loading, false to fail.
	 */
	virtual bool SDK_OnLoad(char *error, size_t maxlength, bool late);
	
	/**
	 * @brief This is called right before the extension is unloaded.
	 */
	virtual void SDK_OnUnload();

	/**
	 * @brief This is called once all known extensions have been loaded.
	 * Note: It is is a good idea to add natives here, if any are provided.
	 */
	virtual void SDK_OnAllLoaded();

	/**
	 * @brief Called when the pause state is changed.
	 */
	//virtual void SDK_OnPauseChange(bool paused);

	/**
	 * @brief this is called when Core wants to know if your extension is working.
	 *
	 * @param error		Error message buffer.
	 * @param maxlength	Size of error message buffer.
	 * @return			True if working, false otherwise.
	 */
	virtual bool QueryRunning(char *error, size_t maxlength);
public:
#if defined SMEXT_CONF_METAMOD
	/**
	 * @brief Called when Metamod is attached, before the extension version is called.
	 *
	 * @param error			Error buffer.
	 * @param maxlength		Maximum size of error buffer.
	 * @param late			Whether or not Metamod considers this a late load.
	 * @return				True to succeed, false to fail.
	 */
	//virtual bool SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlength, bool late);

	/**
	 * @brief Called when Metamod is detaching, after the extension version is called.
	 * NOTE: By default this is blocked unless sent from SourceMod.
	 *
	 * @param error			Error buffer.
	 * @param maxlength		Maximum size of error buffer.
	 * @return				True to succeed, false to fail.
	 */
	//virtual bool SDK_OnMetamodUnload(char *error, size_t maxlength);

	/**
	 * @brief Called when Metamod's pause state is changing.
	 * NOTE: By default this is blocked unless sent from SourceMod.
	 *
	 * @param paused		Pause state being set.
	 * @param error			Error buffer.
	 * @param maxlength		Maximum size of error buffer.
	 * @return				True to succeed, false to fail.
	 */
	//virtual bool SDK_OnMetamodPauseChange(bool paused, char *error, size_t maxlength);
#endif
public: // ISMEntityListener
	//virtual void OnEntityCreated(CBaseEntity *pEntity, const char *classname);
	virtual void OnEntityDestroyed(CBaseEntity *pEntity);
};

#endif // _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_
