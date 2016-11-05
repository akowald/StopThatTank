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

#if defined _tank_included
 #endinput
#endif
#define _tank_included

enum
{
	WeaponSlot_Primary=0,
	WeaponSlot_Secondary,
	WeaponSlot_Melee,
	WeaponSlot_PDABuild, // 3
	WeaponSlot_PDADisguise=3,
	WeaponSlot_PDADestroy, // 4
	WeaponSlot_InvisWatch=4,
	WeaponSlot_BuilderEngie,
	WeaponSlot_Unknown1,
	WeaponSlot_Head,
	WeaponSlot_Misc1,
	WeaponSlot_Action,
	WeaponSlot_Misc2
};

/**
 * Sets an attribute value (if the attribute already exists, it will overwrite the value)
 *
 * @param entity		Entity index to set attributes on
 * @param attribIndex	Attribute index to reference
 * @param attribValue	Attribute value to store
 *
 * @return				True if attribute was set, False otherwise
 * @error				Invalid entity index passed
 */
native bool Tank_SetAttributeValue(int entity, int attribIndex, float attribValue);

/**
 * Sets an attribute value (if the attribute already exists, it will overwrite the value)
 *
 * @param entity		Entity index to set attributes on
 * @param attributeName	Attribute name to reference
 * @param attribValue	Attribute value to store
 *
 * @return				True if attribute was set, False otherwise
 * @error				Invalid entity index passed or invalid attribute name
 */
native bool Tank_SetAttributeValueByName(int entity, const char[] attributeName, float attribValue);

/**
 * Removes an attribute value based on an attribute index
 *
 * @param entity		Entity index to check attributes on
 * @param attribIndex	Attribute index to reference
 *
 * @error				Invalid entity index passed
 */
native void Tank_RemoveAttribute(int entity, int attribIndex);

/**
 * Removes an attribute value based on an attribute name
 *
 * @param entity		Entity index to check attributes on
 * @param attribName	Attribute name to reference
 *
 * @error				Invalid entity index passed
 */
native void Tank_RemoveAttributeByName(int entity, const char[] attribName);

/**
 * Gets an attribute value based on an attribute index
 *
 * @param entity		Entity index to check attributes on
 * @param attribIndex	Attribute index to reference
 * @param attribValue	Buffer to store the attribute value
 *
 * @return				True if lookup was successful, False otherwise
 * @error				Invalid entity index passed
 */
native bool Tank_GetAttributeValue(int entity, int attribIndex, float &attribValue);

/**
 * Called whenever the function CTFGameRules::GameModeUsesUpgrades(void) is used.
 *
 * @param result		The value to return if the function is overridden.
 * @return				Return anything but Plugin_Continue to override with the value from 'result'.
 */
forward Action Tank_OnGameModeUsesUpgrades(bool &result);

/**
 * Hooks ShouldTransmit to be called back in the forward Tank_OnShouldTransmit.
 *
 * @param entity		Entity index to check attributes on.
 *
 * @return				True if hooked, false otherwise.
 * @error				Invalid entity index passed.
 */
native bool Tank_HookShouldTransmit(int entity);

/**
 * Called whenever ShouldTransmit is called on a hook entity.
 *
 * @param entity		The index of the entity being transmitted.
 * @param client		The client index the entity is being transmitted to.
 * @param result		The result from the original function.
 *
 * @return				Return anything but Plugin_Continue to override with the value from 'result'.
 */
forward Action Tank_OnShouldTransmit(int entity, int client, int &result);

/**
 * Increments a player stat. Allows us to modify the player's score.
 *
 * @param client 		Client index.
 * @param statType 		The stat id to change.
 * @param increment 	Increment stat amount.
 *
 * @return				True if successful, false otherwise.
 */
native bool Tank_IncrementStat(int client, int statType, int increment);

/**
 * Calls CAttributeManager::ClearCache on the given entity.
 * This is needed in some rare instances to refresh attribute hooks.
 *
 * @param entity 		Entity index.
 */
native void Tank_ClearCache(int entity);

/**
 * Called whenever a player attempts to pick up a dropped weapon.
 *
 * @param client 		The client who is attempting to pick up a weapon.
 * @param droppedWeapon The weapon index of the dropped weapon.
 * @param result 		The value to override return with.
 *
 * @return 				Return Plugin_Continue to run the function as normal. Anything else will return with the value set in result.
 */
forward Action Tank_OnWeaponPickup(int client, int droppedWeapon, bool &result);

/**
 * Called whenever a weapon is dropped.
 *
 * @param itemDefinitionIndex	The item def index of the dropped weapon.
 * @param accountId 			The account id of the player who dropped the weapon.
 * @param itemIdHigh			The higher bits of the item id.
 * @param itemIdLow				The lower bits of the item id.
 * @param item 					The address of the CEconItemView class the dropped weapon is built on.
 *
 * @return 						Return anything but Plugin_Continue to block the weapon from being dropped.
 */
forward Action Tank_OnWeaponDropped(int itemDefinitionIndex, int accountId, int itemIdHigh, int itemIdLow, Address item);

/**
 * Called when the game performs collision checks through traces (only for traces using filters).
 * Note: Any code in this forward should be efficient, the game will use many filtered traces per player per game frame.
 *
 * @param ent1 		Entity 1.
 * @param ent2 		Entity 2.
 * @param result 	Value to store override return.
 *
 * @return 			Something other than Plugin_Continue to have the game use the result parameter.
 */
forward Action Tank_PassFilter(int ent1, int ent2, bool &result);

enum
{
	MedigunChargeEffect_Healing=-1,
	MedigunChargeEffect_Uber,
	MedigunChargeEffect_Kritz,
	MedigunChargeEffect_Quickfix,
	MedigunChargeEffect_VaccinatorBullet,
	MedigunChargeEffect_VaccinatorBlast,
	MedigunChargeEffect_VaccinatorFire,
};

/**
 * Called whenever medigun effects are being applied on a player. This can be used to allow or deny uber effects.
 * 
 * @param client 				Client index.
 * @param medigunChargeType		The type of medigun charge effect. (kritz/uber/vaccinator)
 * @param result 				The value to override return with.
 *
 * @return 						Return Plugin_Continue to run the function as normal. Anything else will return with the value set in result.
 */
forward Action Tank_OnCanRecieveMedigunChargeEffect(int client, int medigunChargeType, bool &result);

/**
 * Called before player speed calculation begins.
 *
 * @param client 				Client index.
 */
forward void Tank_OnCalcSpeedPre(int client);

/**
 * Called after player speed calculation concludes.
 *
 * @param client 				Client index.
 */
forward void Tank_OnCalcSpeedPost(int client);

/**
 * Called whenever the Horseless Headless Horsemann chooses to chase a player.
 *
 * @param client 				Client index.
 * @param headlessHatman		Edict index of the hhh boss.
 * @param result				True to chase the player, false otherwise.
 *
 * @return 						Return Plugin_Continue to use the game result. Return anything else to use the value set in result.
 */
forward Action Tank_IsChaseable(int client, int headlessHatman, bool &result);

/**
 * Do not edit below this line!
 */
public Extension __ext_tank = 
{
	name = "Stop that Tank!",
	file = "tank.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
