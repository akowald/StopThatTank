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

#pragma semicolon 1
#define STT_MAIN_PLUGIN

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <regex>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <dhooks>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#tryinclude <sendproxy>
#define REQUIRE_EXTENSIONS

#pragma newdecls required

#include "include/tank.inc"

// Enable this for diagnostic messages in server console (very verbose)
//#define DEBUG

#define PLUGIN_VERSION 				"1.5.4"

#define MODEL_TANK 					"models/bots/boss_bot/boss_tank.mdl"			// Model of the normal tank boss
#define MODEL_TRACK_L				"models/bots/boss_bot/tank_track_L.mdl"			// Model of the left tank track
#define MODEL_TRACK_R				"models/bots/boss_bot/tank_track_R.mdl"			// Model of the right tank track
#define MODEL_MECHANISM				"models/bots/boss_bot/bomb_mechanism.mdl"		// Model of the bomb mechanism that deploys
#define MODEL_BOMB					"models/props_td/atom_bomb.mdl"					// Model of the robot bomb that is carried
#define MODEL_REVIVE_MARKER 		"models/props_mvm/mvm_revive_tombstone.mdl"
#define MODEL_ROBOT_HOLOGRAM		"models/props_mvm/robot_hologram.mdl"
#define MODEL_TANK_STATIC			"models/bots/boss_bot/static_boss_tank.mdl"

#define MODEL_ROMEVISION_TANK		"models/bots/tw2/boss_bot/boss_tank.mdl"
#define MODEL_ROMEVISION_TRACK_L	"models/bots/tw2/boss_bot/tank_track_l.mdl"
#define MODEL_ROMEVISION_TRACK_R	"models/bots/tw2/boss_bot/tank_track_r.mdl"
#define MODLE_ROMEVISION_STATIC		"models/bots/tw2/boss_bot/static_boss_tank.mdl"

#define HIGHTOWER_LIFT_OFFSET_BLUE 	11.0
#define HIGHTOWER_LIFT_OFFSET_RED 	8.0

#define SOUND_CART_START		"items/cart_rolling_start.wav"
#define SOUND_CART_STOP			"items/cart_rolling_stop.wav"
#define SOUND_TANK_WARNING		"mvm/mvm_bomb_warning.wav"
#define SOUND_TANK_DEPLOY		"mvm/mvm_tank_deploy.wav"
#define SOUND_LOSE				"music/mvm_lost_wave.wav"
#define SOUND_ROUND_START		"music/mvm_start_mid_wave.wav"
#define SOUND_CHECKPOINT		"ui/scored.wav"
#define SOUND_WARNING			"mvm/mvm_warning.wav"
#define SOUND_DEPLOY_SMALL		"mvm/mvm_deploy_small.wav"
#define SOUND_DEPLOY_GIANT		"mvm/mvm_deploy_giant.wav"
#define SOUND_GIANT_ROCKET		"mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define SOUND_GIANT_ROCKET_CRIT "mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define SOUND_BOMB_EXPLODE		"mvm/mvm_bomb_explode.wav"
#define SOUND_RING				"pl_hoodoo/alarm_clock_alarm_3.wav"
#define SOUND_GIANT_GRENADE		"mvm/giant_demoman/giant_demoman_grenade_shoot.wav"
#define SOUND_GIANT_EXPLODE		"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define SOUND_GIANT_START		"music/mvm_start_last_wave.wav"
#define SOUND_EXPLOSION			"items/cart_explode.wav"
#define SOUND_FIZZLE			"ambient/energy/weld2.wav"
#define SOUND_DELIVER			"mvm/mvm_tele_deliver.wav"
#define SOUND_BACKSTAB			"player/spy_shield_break.wav"
#define SOUND_HOLOGRAM_START	"misc/hologram_start.wav"
#define SOUND_HOLOGRAM_STOP		"misc/hologram_stop.wav"
#define SOUND_GIANT_MINIGUN_SPINNING	"mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_GIANT_MINIGUN_LOWERING	"mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_GIANT_MINIGUN_RAISING		"mvm/giant_heavy/giant_heavy_gunwinddown.wav"
#define SOUND_GIANT_MINIGUN_SHOOTING	"mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_QUICKFIX_LOOP		"player/quickfix_invulnerable_on.wav"
#define SOUND_BUSTER_START		"mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define SOUND_BUSTER_LOOP		"mvm/sentrybuster/mvm_sentrybuster_loop.wav"
#define SOUND_BUSTER_SPIN		"mvm/sentrybuster/mvm_sentrybuster_spin.wav"
#define SOUND_REANIMATOR_PING	"ui/medic_alert.wav"
#define SOUND_GIANT_RAGE_DEATH 	"misc/ks_tier_01_death.wav"
#define SOUND_GIANT_RAGE 		"ui/system_message_alert.wav"
#define SOUND_TELEPORT 			"ui/item_mtp_drop.wav"
#define SOUND_TANK_RANKUP 		"ui/itemcrate_smash_ultrarare_short.wav"
#define SOUND_ANNOUNCER_FINAL_STRETCH_ALLY "vo/announcer_plr_racegeneral12.mp3"
#define SOUND_ANNOUNCER_FINAL_STRETCH_ENEMY "vo/announcer_plr_racegeneral11.mp3"
#define SOUND_DEATHPIT_BOOST 	"misc/halloween/spell_blast_jump.wav"
#define SOUND_SUPERSPY_HINT 	"misc/ks_tier_02_kill_02.wav"

#define EPSILON 				0.0005
#define TIME_SHIELD_EXPIRE		2.5
#define MAX_TEAMS 				4
// These override the TFTeam enum to avoid tag mismatch warnings
#define	TFTeam_Unassigned 		0
#define	TFTeam_Spectator 		1
#define TFTeam_Red 				2
#define TFTeam_Blue 			3
#define MAX_LINKS				8
#define MAX_LINK_STRING			100
#define MAX_TANK_HEALTH			2000000
#define MAX_RACE_LEVELS			5
#define FILE_TANK_KILLCOUNTER 	"tank.killcounter.txt"
#define TIME_BUSTER_EXPLODE 	2.0 // Time (seconds) that it takes the sentry buster to explode
#define VISIONFLAG_HALLOWEEN 	2.0
#define VISIONFLAG_ROMEVISION 	4.0
#define SETUP_UBER_CHARG_RATE 	6.0
#define COLOR_TANK_STRANGE		"\x07CF6A32"
#define MAX_EDICTS				2048
#define ENTITY_LIMIT_BUFFER 	20
#define MAD_MILK_HEALTH 		8

#define ITEM_PHLOG 594
#define ITEM_TRIAD_TRINKET 814
#define ITEM_MERCS_MUFFLER 987
#define ITEM_BORSCHT_BELT 30108
#define ITEM_GRENADE_LAUNCHER 19
#define ITEM_MINIGUN 15
#define ITEM_TOSS_PROOF_TOWEL 757
#define ITEM_SILVER_BOTKILLER_ROCKET_LAUNCHER_MK_II 965
#define ITEM_HUNTSMAN 56
#define ITEM_SILVER_BOTKILLER_FLAME_THROWER_MK_II 963
#define ITEM_ROCKET_LAUNCHER 18
#define ITEM_FLAMETHROWER 21
#define ITEM_SANDMAN 44
#define ITEM_JARATE 58
#define ITEM_WEE_BOOTIES 405
#define ITEM_CHARGIN_TARGE 131
#define ITEM_HEADTAKER 266
#define ITEM_FISTS 5
#define ITEM_SHOVEL 6
#define ITEM_SCORCH_SHOT 740
#define ITEM_BAZOOKA 730
#define ITEM_BUSINESS_CASUAL 782
#define ITEM_HORNBLOWER 30129
#define ITEM_GAELIC_GARB 30124
#define ITEM_KRINGLE_COLLECTION 650
#define ITEM_FLYING_GUILLOTINE 812
#define ITEM_FESTIVE_GRENADE_LAUNCHER 1007
#define ITEM_FESTIVE_ROCKET_LAUNCHER 658
#define ITEM_FESTIVE_MINIGUN 654
#define ITEM_FESTIVE_FLAMETHROWER 659
#define ITEM_FESTIVE_HUNTSMAN 1005
#define ITEM_FESTIVE_JARATE 1083
#define ITEM_FESTIVE_EYELANDER 1082
#define ITEM_ANGEL_OF_DEATH 30312
#define ITEM_BRAWLING_BUCCANEER 30131
#define ITEM_BEAR_NECESSITIES 30122
#define ITEM_LOOSE_CANNON 996
#define ITEM_WARD 30190
#define ITEM_MEDICAL_MYSTERY 30171
#define ITEM_CUT_THROAT_CONCIERGE 977
#define ITEM_ANTARCTIC_PARKA 30331
#define ITEM_FOUNDING_FATHER 30142
#define ITEM_FOPPISH_PHYSICIAN 878
#define ITEM_DISTINGUISHED_ROGUE 879
#define ITEM_NUNHOOD 30311
#define ITEM_EYELANDER 132
#define ITEM_BOTTLE 1
#define ITEM_FIREAXE 2
#define ITEM_CARIBBEAN_CONQUEROR 30116
#define ITEM_VOODOO_SCOUT 5617
#define ITEM_VOODOO_SOLDIER 5618
#define ITEM_VOODOO_HEAVY 5619
#define ITEM_VOODOO_DEMO 5620
#define ITEM_VOODOO_ENGINEER 5621
#define ITEM_VOODOO_MEDIC 5622
#define ITEM_VOODOO_SPY 5623
#define ITEM_VOODOO_PYRO 5624
#define ITEM_VOODOO_SNIPER 5625
#define ITEM_SHOTGUN_HWG 11
#define ITEM_KGB 43
#define ITEM_FAN 45
#define ITEM_QUICK_FIX 411
#define ITEM_HEAT_OF_WINTER 30356
#define ITEM_FRONTIER_JUSTICE 141
#define ITEM_ENGIE_PISTOL 22
#define ITEM_GUNSLINGER 142
#define ITEM_AFTER_DARK 30133
#define ITEM_DAS_HAZMATTENHATTEN 30095
#define ITEM_KILLERS_KIT 30339
#define ITEM_BLOOD_BANKER 30132
#define ITEM_EXORCIZOR 936
#define ITEM_DIE_REGIME 1088
#define ITEM_CABER 307
#define ITEM_THIRD_DEGREE 593
#define ITEM_BUSHWACKA 232
#define ITEM_PAIN_TRAIN 154
#define ITEM_HARDY_LAUREL 30065
#define ITEM_CROSSBOW 305
#define ITEM_KRITZKRIEG 35
#define ITEM_AMPUTATOR 304
#define ITEM_COLD_SNAP_COAT 30601
#define ITEM_LADY_KILLER 30476
#define ITEM_DASHIN_HASHSHASHIN 637
#define ITEM_COLDFRONT_CURBSTOMPERS 30558
#define ITEM_BACKSTABBERS_BOOMSLANG 30353
#define ITEM_CLASSIFIED_COIF 30388
#define ITEM_CHARRED_CHAINMAIL 30584
#define ITEM_BUSHI_DOU 30348
#define ITEM_BOUNTIFUL_BOW 30260
#define ITEM_VACCINATOR 998
#define ITEM_PUFFY_PROVOCATEUR 30602
#define ITEM_SANGU_SLEEVES 30366
#define ITEM_IMMOBILE_SUIT 30534
#define ITEM_DEAD_OF_NIGHT 30309
#define ITEM_SMOCK_SURGEON 30365
#define ITEM_SKY_CAPTAIN 30405
#define ITEM_EXECUTIONER 921
#define ITEM_MAGICAL_MERCENARY 30297
#define ITEM_DEAD_RINGER 59
#define ITEM_CONGA 1118
#define ITEM_KAZOTSKY_KICK 1157
#define ITEM_BOX_TROT 30615
#define ITEM_ZOOMIN_BROOM 30672
#define ITEM_MANNROBICS 1162
#define ITEM_PDA_DESTROY 26

#define ATTRIB_HIDDEN_MAXHEALTH_NON_BUFFED 140
#define ATTRIB_MAXAMMO_PRIMARY_INCREASED 76
#define ATTRIB_MAXAMMO_SECONDARY_INCREASED 78
#define ATTRIB_FLAME_LIFE_BONUS 164
#define ATTRIB_MOVE_SPEED_BONUS 107
#define ATTRIB_SELF_DMG_PUSH_FORCE_DECREASE 59
#define ATTRIB_BUILDING_HEALTH_BONUS 286
#define ATTRIB_ARMOR_PIERCING 399
#define ATTRIB_MAJOR_MOVE_SPEED_BONUS 442
#define ATTRIB_VISION_OPT_IN_FLAGS 406
#define ATTRIB_MAXAMMO_METAL_INCREASED 80
#define ATTRIB_UBERCHARGE_RATE_BONUS 10
#define ATTRIB_KILLSTREAK_TIER 2025
#define ATTRIB_MAJOR_INCREASED_JUMP_HEIGHT 443
#define ATTRIB_HEALTH_DRAIN 129
#define ATTRIB_WEAPON_ALLOW_INSPECT 731
#define ATTRIB_PARTICLE_INDEX 134
#define ATTRIB_REDUCED_HEALING_FROM_MEDIC 740
#define ATTRIB_DAMAGE_BONUS 2
#define ATTRIB_TELEPORTER_BUILD_RATE_MULTIPLIER 465

#define QUALITY_NORMAL 		0
#define QUALITY_UNIQUE 		6
#define QUALITY_SELFMADE 	9
#define QUALITY_COLLECTORS 	14
#define QUALITY_VINTAGE 	3

#define WeaponSlot_PDABuild 3

#define EF_PARITY_BITS	3
#define EF_PARITY_MASK  ((1<<EF_PARITY_BITS)-1)

#define EF_BONEMERGE			0x001 	// Performs bone merge on client side
#define	EF_BRIGHTLIGHT 			0x002	// DLIGHT centered at entity origin
#define	EF_DIMLIGHT 			0x004	// player flashlight
#define	EF_NOINTERP				0x008	// don't interpolate the next frame
#define	EF_NOSHADOW				0x010	// Don't cast no shadow
#define	EF_NODRAW				0x020	// don't draw entity
#define	EF_NORECEIVESHADOW		0x040	// Don't receive no shadow
#define	EF_BONEMERGE_FASTCULL	0x080	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
#define	EF_ITEM_BLINK			0x100	// blink an item so that the user notices it.
#define	EF_PARENT_ANIMATES		0x200	// always assume that the parent entity is animating
#define	EF_MAX_BITS = 10

#define FL_EDICT_CHANGED	(1<<0)	// Game DLL sets this when the entity state changes
									// Mutually exclusive with FL_EDICT_PARTIAL_CHANGE.
									
#define FL_EDICT_FREE		(1<<1)	// this edict if free for reuse
#define FL_EDICT_FULL		(1<<2)	// this is a full server entity

#define FL_EDICT_FULLCHECK	(0<<0)  // call ShouldTransmit() each time, this is a fake flag
#define FL_EDICT_ALWAYS		(1<<3)	// always transmit this entity
#define FL_EDICT_DONTSEND	(1<<4)	// don't transmit this entity
#define FL_EDICT_PVSCHECK	(1<<5)	// always transmit entity, but cull against PVS

// m_nSolidType
#define SOLID_NONE 0 // no solid model
#define SOLID_BSP 1 // a BSP tree
#define SOLID_BBOX 2 // an AABB
#define SOLID_OBB 3 // an OBB (not implemented yet)
#define SOLID_OBB_YAW 4 // an OBB, constrained so that it can only yaw
#define SOLID_CUSTOM 5 // Always call into the entity for tests
#define SOLID_VPHYSICS 6 // solid vphysics object, get vcollide from the model and collide with that
// m_usSolidFlags
#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects
// m_CollisionGroup
enum // Collision_Group_t in const.h
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};

// Settings for m_takedamage - from shareddefs.h
#define	DAMAGE_NO				0
#define DAMAGE_EVENTS_ONLY		1		// Call damage functions, but don't modify health
#define	DAMAGE_YES				2
#define	DAMAGE_AIM				3

enum // For use with UTIL_ScreenShake.
{
	Shake_Start=0,
	Shake_Stop,
	Shake_Amplitude,
	Shake_Frequency,
};

#define PATH_DISABLED 			(1 << 0)
#define PATH_FIRE_ONCE 			(1 << 1)
#define PATH_BRANCH_REVERSE 	(1 << 2)
#define PATH_DISABLE_TRAIN 		(1 << 3)
#define PATH_TELEPORT_TO_THIS 	(1 << 4)
#define PATH_UPHILL 			(1 << 5)
#define PATH_DOWNHILL 			(1 << 6)

#define CAPHUD_PARITY_BITS				6
#define CAPHUD_PARITY_MASK				((1<<CAPHUD_PARITY_BITS)-1)

#define SF_DISABLE_SOUNDS (1 << 3)
#define TARGETNAME_NULL "_null_entity_name___"

const float PI = 3.1415926535897932384626433832795;

#define MASK_RED 33640459
#define MASK_BLUE 33638411

#define HELL_GATES_TARGETNAME "underworld_play_timer_relay"

#define Address_MinimumValid 0x10000

int g_iRefTrackTrain[MAX_TEAMS];
int g_iRefTrackTrain2[MAX_TEAMS]; // for the flatbed in pl_frontier
int g_iRefTrainWatcher[MAX_TEAMS];
int g_iRefTrigger[MAX_TEAMS];

ArrayList g_trainProps;
enum
{
	TrainPropArray_Reference=0,
	TrainPropArray_SolidType,
};
#define ARRAY_TRAINPROP_SIZE 2

int g_iRefTank[MAX_TEAMS];
int g_iRefFakeTank[MAX_TEAMS];
int g_iRefHealthBar;
int g_iRefPointPush[MAX_TEAMS];
int g_iRefObj;

int g_iRefTankTrackL[MAX_TEAMS];
int g_iRefTankTrackR[MAX_TEAMS];
int g_iRefTankMechanism[MAX_TEAMS];
int g_iRefDispenser[MAX_TEAMS];
int g_iRefDispenserTouch[MAX_TEAMS];

// Information associated with team_train_watcher
int g_iRefPathGoal[MAX_TEAMS];
int g_iRefPathStart[MAX_TEAMS];
int g_iRefControlPointGoal[MAX_TEAMS];

int g_iRefLinkedPaths[MAX_TEAMS][MAX_LINKS];
int g_iRefLinkedCPs[MAX_TEAMS][MAX_LINKS];
int g_iRefCaptureTriggers[MAX_TEAMS][MAX_LINKS];
int g_iRefCaptureZones[MAX_TEAMS];

int g_iRefBombTimer;
int g_iRefBombFlag;
int g_iRefRoundControlPoint;

int g_iMaxControlPoints[MAX_TEAMS];
int g_iCurrentControlPoint[MAX_TEAMS];

Handle g_hCvarEnabled;
Handle g_hCvarMaxSpeed;
Handle g_hCvarTimeGrace;
Handle g_hCvarHealthBase;
Handle g_hCvarHealthPlayer;
Handle g_hCvarHealthDistance;
Handle g_hCvarRobot;
Handle g_hCvarDistanceWarn;
Handle g_hCvarTankCooldown;
Handle g_hCvarDistanceMove;
Handle g_hCvarCurrencyCrit;
Handle g_hCvarCheckpointHealth;
Handle g_hCvarCheckpointTime;
Handle g_hCvarCheckpointInterval;
Handle g_hCvarCheckpointCutoff;
Handle g_hCvarBombReturnTime;
Handle g_hCvarBombRoundTime;
Handle g_hCvarBombDistanceWarn;
Handle g_hCvarBombTimeDeploy;
Handle g_hCvarGiantAmmoMultiplier;
Handle g_hCvarRespawnBase;
Handle g_hCvarRespawnGiant;
Handle g_hCvarRespawnRace;
Handle g_hCvarGiantForce;
Handle g_hCvarBombMoveSpeed;
Handle g_hCvarBombCaptureRate;
Handle g_hCvarBombTimeAdd;
Handle g_hCvarBombTimePenalty;
Handle g_hCvarRespawnBombRed;
Handle g_hCvarBombHealDuration;
Handle g_hCvarBombMiniCritsDuration;
Handle g_hCvarBombHealCooldown;
Handle g_hCvarCheckpointDistance;
Handle g_hCvarRestartGame;
Handle g_hCvarScrambleHealth;
Handle g_hCvarScrambleEnabled;
Handle g_hCvarPointsForTank;
Handle g_hCvarPointsForGiant;
Handle g_hCvarPointsForTankPlr;
Handle g_hCvarPointsForGiantPlr;
Handle g_hCvarPointsDamageTank;
Handle g_hCvarPointsDamageGiant;
Handle g_hCvarGiantKnifeDamage;
Handle g_hCvarBombBuffsCuttoff;
Handle g_hCvarRaceLvls[MAX_RACE_LEVELS];
Handle g_hCvarRaceInterval;
Handle g_hCvarRaceDamageBase;
Handle g_hCvarRaceDamageAverage;
Handle g_hCvarReanimatorMaxHealthMult;
Handle g_hCvarReanimatorReviveMult;
Handle g_hCvarReanimatorVacUber;
Handle g_hCvarBusterExplodeRadius;
Handle g_hCvarBusterExplodeMagnitude;
Handle g_hCvarBusterTriggerTank;
Handle g_hCvarBusterTriggerGiant;
Handle g_hCvarBusterTriggerRobots;
Handle g_hCvarBusterTriggerTankPlr;
Handle g_hCvarBusterTriggerGiantPlr;
Handle g_hCvarBusterTriggerRobotsPlr;
Handle g_hCvarBusterTimeWarn;
Handle g_hCvarAttribHaulSpeed;
Handle g_hCvarAttribMetalMult;
Handle g_hCvarGiantWarnTime;
Handle g_hCvarGiantWarnCutoff;
Handle g_hCvarRaceTimeGiantStart;
Handle g_hCvarRaceTimeIntermission;
Handle g_hCvarGameDesc;
Handle g_hCvarGiantTimeAFK;
Handle g_hCvarTankStuckTime;
Handle g_hCvarBusterTimePause;
Handle g_hCvarBusterFormulaBaseFirst;
Handle g_hCvarBusterFormulaBaseSecond;
Handle g_hCvarBusterFormulaSentryMult;
Handle g_hCvarBusterForce;
Handle g_hCvarZapPenalty;
Handle g_hCvarSirNukesCap;
Handle g_hCvarRaceTimeWave;
Handle g_hCvarRaceNumWaves;
Handle g_hCvarRaceGiantHealthMin;
Handle g_hCvarTeleportUber;
Handle g_hCvarTimeTip;
Handle g_hCvarSuperSpyMoveSpeed;
Handle g_hCvarSuperSpyJumpHeight;
Handle g_hCvarGiantCooldown;
Handle g_hCvarScrambleProgress;
Handle g_hCvarScrambleGiants;
Handle g_hCvarTeamRed;
Handle g_hCvarTeamBlue;
Handle g_hCvarTeamRedPlr;
Handle g_hCvarTeamBluePlr;
Handle g_hCvarHellTowerTimeGate;
Handle g_hCvarBusterExemptMedicUber;
Handle g_hCvarRageBase;
Handle g_hCvarRageScale;
Handle g_hCvarRageLow;
Handle g_hCvarBusterCap;
Handle g_hCvarWeaponInspect;
Handle g_hCvarRaceTimeOvertime;
Handle g_hCvarFinaleDefault;
Handle g_hCvarTankHealthMultiplier;
Handle g_hCvarDeployDistance;
Handle g_hCvarMinPlantDistance;
Handle g_hCvarDefaultGiantScale;
Handle g_hCvarGoalDistance;
Handle g_hCvarGiantHealthMultiplier;
Handle g_hCvarDistanceSeparation;
Handle g_hCvarUpdatesPanel;
Handle g_hCvarOfficialServer;
Handle g_hCvarTags;
Handle g_hCvarTeleportStartRed;
Handle g_hCvarTeleportStartBlue;
Handle g_hCvarTeleportGoal;
Handle g_hCvarGiantHHHCap;
Handle g_hCvarGiantCooldownPlr;
Handle g_hCvarRespawnScaleMin;
Handle g_hCvarGiantGibs;
Handle g_hCvarPointsForDeploy;
Handle g_hCvarGiantScaleHealing;
Handle g_hCvarJarateOnHitTime;
Handle g_hCvarBombWinSpeed;
Handle g_hCvarBombCapAreaSize;
Handle g_hCvarGiantDeathpitDamage;
Handle g_hCvarGiantDeathpitCooldown;
Handle g_hCvarGiantDeathpitMinZ;
Handle g_hCvarRespawnCartBehind;
Handle g_hCvarRespawnAdvMult;
Handle g_hCvarRespawnAdvCap;
Handle g_hCvarRespawnAdvRunaway;
Handle g_hCvarBombSkipDistance;
Handle g_hCvarGiantDeathpitBoost;
Handle g_hCvarTeleBuildMult;
Handle g_hCvarRespawnTank;
Handle g_hCvarGiantHandScale;

Handle g_hSDKGetBaseEntity;
Handle g_hSDKSetStartingPath;
Handle g_hSDKSetSize;
Handle g_hSDKPlaySpecificSequence;
Handle g_hSDKPickup;
Handle g_hSDKGetEquippedWearable;
Handle g_hSDKGetMaxHealth;
Handle g_hSDKGetMaxAmmo;
Handle g_hSDKEquipWearable;
Handle g_hSDKPointIsWithin;
Handle g_hSDKRemoveWearable;
Handle g_hSDKTeleporterReceive;
Handle g_hSDKDoQuickBuild;
Handle g_hSDKTaunt;
Handle g_hSDKGetMaxClip;
Handle g_hSDKStartTouch;
Handle g_hSDKEndTouch;
Handle g_hSDKChargeEffects;
Handle g_hSDKHeal;
Handle g_hSDKStopHealing;
Handle g_hSDKFindHealerIndex;
Handle g_hSDKWeaponSwitch;
Handle g_hSDKSolidMask;
Handle g_hSDKSetBossHealth;
Handle g_hSDKSendWeaponAnim;

Handle g_cookieInfoPanel;

enum
{
	UpdatesPanel_NeverShow=0,	// Never show the updates panel.
	UpdatesPanel_OnlyTrigger,	// Only show the updates panel when requested by the !stt chat trigger.
	UpdatesPanel_AlwaysShow		// Show the updates panel when a player spawns for the first time.
};

enum eMapHack
{
	MapHack_None=0,
	MapHack_ThunderMountain,
	MapHack_Frontier,
	MapHack_Hightower,
	MapHack_HightowerEvent,
	MapHack_Pipeline,
	MapHack_Nightfall,
	MapHack_CactusCanyon,
	MapHack_Borneo,
	MapHack_MillstoneEvent,
	MapHack_Barnblitz,
	MapHack_SnowyCoast,
};
eMapHack g_nMapHack = MapHack_None;
bool g_bEnableMapHack[MAX_TEAMS];

bool g_bIsRoundStarted;
bool g_bIsFinale;

Handle g_hTimerStart;
Handle g_hTimerBombReturn;

char g_strTrackTrainTargetName[100];
char g_strGoalNode[MAX_TEAMS][100];

float g_flPathTotalDistance[MAX_TEAMS];

char g_strSoundCountdown[][] = {"vo/announcer_begins_1sec.mp3", "vo/announcer_begins_2sec.mp3", "vo/announcer_begins_3sec.mp3", "vo/announcer_begins_4sec.mp3", "vo/announcer_begins_5sec.mp3"};

char g_strModelRobots[][] = {"", "models/bots/scout/bot_scout.mdl", "models/bots/sniper/bot_sniper.mdl", "models/bots/soldier/bot_soldier.mdl", "models/bots/demo/bot_demo.mdl", "models/bots/medic/bot_medic.mdl", "models/bots/heavy/bot_heavy.mdl", "models/bots/pyro/bot_pyro.mdl", "models/bots/spy/bot_spy.mdl", "models/bots/engineer/bot_engineer.mdl"};
int g_iModelIndexRobots[sizeof(g_strModelRobots)];
char g_strModelHumans[][] =  {"", "models/player/scout.mdl", "models/player/sniper.mdl", "models/player/soldier.mdl", "models/player/demo.mdl", "models/player/medic.mdl", "models/player/heavy.mdl", "models/player/pyro.mdl", "models/player/spy.mdl", "models/player/engineer.mdl"};
int g_iModelIndexHumans[sizeof(g_strModelHumans)];

char g_strSoundRobotFootsteps[][] = {
	// Regular robot footsteps
	"mvm/player/footsteps/robostep_01.wav", "mvm/player/footsteps/robostep_02.wav", "mvm/player/footsteps/robostep_03.wav", "mvm/player/footsteps/robostep_04.wav", "mvm/player/footsteps/robostep_05.wav", "mvm/player/footsteps/robostep_06.wav", "mvm/player/footsteps/robostep_07.wav", "mvm/player/footsteps/robostep_08.wav", "mvm/player/footsteps/robostep_09.wav", "mvm/player/footsteps/robostep_10.wav", "mvm/player/footsteps/robostep_11.wav", "mvm/player/footsteps/robostep_12.wav", "mvm/player/footsteps/robostep_13.wav", "mvm/player/footsteps/robostep_14.wav", "mvm/player/footsteps/robostep_15.wav", "mvm/player/footsteps/robostep_16.wav", "mvm/player/footsteps/robostep_17.wav", "mvm/player/footsteps/robostep_18.wav"};
char g_strSoundGiantFootsteps[][] = {
	// Giant robot footsteps
	"^mvm/giant_common/giant_common_step_01.wav", "^mvm/giant_common/giant_common_step_02.wav", "^mvm/giant_common/giant_common_step_03.wav", "^mvm/giant_common/giant_common_step_04.wav", "^mvm/giant_common/giant_common_step_05.wav", "^mvm/giant_common/giant_common_step_06.wav", "^mvm/giant_common/giant_common_step_07.wav", "^mvm/giant_common/giant_common_step_08.wav"};
char g_strSoundBusterFootsteps[][] = {
	// Sentry buster footsteps
	"^mvm/sentrybuster/mvm_sentrybuster_step_01.wav", "^mvm/sentrybuster/mvm_sentrybuster_step_02.wav", "^mvm/sentrybuster/mvm_sentrybuster_step_03.wav", "^mvm/sentrybuster/mvm_sentrybuster_step_04.wav"};	
char g_strTeamColors[][] = {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};
char g_strClassName[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
char g_strTeamClass[][] = {"", "Unassigned", "Red", "Blue"};
char g_strSoundGiantSpawn[][] = {"", "vo/mvm/mght/scout_mvm_m_apexofjump03.mp3", "vo/mvm/norm/sniper_mvm_award09.mp3", "vo/mvm/mght/soldier_mvm_m_autodejectedtie02.mp3", "vo/mvm/mght/demoman_mvm_m_eyelandertaunt01.mp3", "vo/mvm/norm/medic_mvm_autocappedcontrolpoint03.mp3", "mvm/giant_heavy/giant_heavy_entrance.wav", "vo/mvm/mght/pyro_mvm_m_incoming01.mp3", "vo/mvm/norm/spy_mvm_laughevil01.mp3", "vo/mvm/norm/engineer_mvm_dominationengineer_mvm06.mp3"};
char g_strSoundGiantLoop[][] = {"", "mvm/giant_scout/giant_scout_loop.wav", "mvm/giant_demoman/giant_demoman_loop.wav", "mvm/giant_soldier/giant_soldier_loop.wav", "mvm/giant_demoman/giant_demoman_loop.wav", "mvm/giant_demoman/giant_demoman_loop.wav", "mvm/giant_heavy/giant_heavy_loop.wav", "mvm/giant_pyro/giant_pyro_loop.wav", "mvm/giant_demoman/giant_demoman_loop.wav", "mvm/giant_demoman/giant_demoman_loop.wav"};
char g_strSoundBombPickup[][] = {"vo/mvm_another_bomb01.mp3", "vo/mvm_another_bomb03.mp3"};
char g_strSoundNukes[][] = {"ambient/explosions/explode_1.wav", "ambient/explosions/explode_2.wav", "ambient/explosions/explode_3.wav", "ambient/explosions/explode_4.wav", "ambient/explosions/explode_5.wav", "ambient/explosions/explode_6.wav", "ambient/explosions/explode_7.wav", "ambient/explosions/explode_8.wav", "ambient/explosions/explode_9.wav"};
char g_strSoundEngieBotAppearedTeam[][] = {"vo/announcer_mvm_engbot_arrive01.mp3", "vo/announcer_mvm_engbot_arrive02.mp3"};
char g_strSoundEngieBotAppearedEnemy[][] = {"vo/announcer_mvm_engbot_arrive03.mp3"};
char g_strSoundTeleActivatedTeam[][] = {"vo/announcer_mvm_eng_tele_activated01.mp3", "vo/announcer_mvm_eng_tele_activated02.mp3", "vo/announcer_mvm_eng_tele_activated05.mp3"};
char g_strSoundTeleActivatedEnemy[][] = {"vo/announcer_mvm_eng_tele_activated03.mp3", "vo/announcer_mvm_eng_tele_activated04.mp3"};

char g_strSoundTankDestroyedScout[][] = {"vo/scout_autocappedcontrolpoint01.mp3", "vo/scout_autocappedcontrolpoint03.mp3", "vo/scout_autocappedcontrolpoint04.mp3", "vo/scout_cartgoingbackdefense02.mp3", "vo/scout_cartgoingbackdefense03.mp3", "vo/scout_cartgoingbackdefense04.mp3"};
char g_strSoundTankDestroyedSniper[][] = {"vo/sniper_cartgoingbackdefense02.mp3", "vo/sniper_cartgoingbackdefense07.mp3", "vo/sniper_autocappedcontrolpoint02.mp3", "vo/sniper_cheers04.mp3", "vo/sniper_cheers05.mp3"};
char g_strSoundTankDestroyedSoldier[][] = {"vo/soldier_mvm_tank_dead01.mp3", "vo/soldier_mvm_tank_dead02.mp3", "vo/soldier_mvm_wave_end01.mp3", "vo/soldier_mvm_wave_end04.mp3", "vo/soldier_kaboomalts02.mp3"};
char g_strSoundTankDestroyedDemoman[][] = {"vo/demoman_specialcompleted12.mp3", "vo/demoman_specialcompleted11.mp3", "vo/demoman_autocappedintelligence01.mp3", "vo/demoman_autocappedintelligence02.mp3"};
char g_strSoundTankDestroyedMedic[][] = {"vo/medic_mvm_wave_end02.mp3", "vo/medic_mvm_wave_end03.mp3"};
char g_strSoundTankDestroyedHeavy[][] = {"vo/heavy_mvm_tank_dead01.mp3", "vo/heavy_mvm_wave_end01.mp3", "vo/heavy_mvm_wave_end02.mp3", "vo/heavy_mvm_wave_end03.mp3", "vo/heavy_specialcompleted01.mp3", "vo/taunts/heavy_taunts16.mp3", "vo/heavy_sf13_influx_big02.mp3"};
char g_strSoundTankDestroyedPyro[][] = {"vo/pyro_autocappedcontrolpoint01.mp3", "vo/taunts/pyro_highfive_success01.mp3", "vo/pyro_cheers01.mp3"};
char g_strSoundTankDestroyedSpy[][] = {"vo/spy_sf12_goodmagic05.mp3", "vo/spy_sf12_goodmagic08.mp3", "vo/taunts/spy_highfive_success01.mp3"};
char g_strSoundTankDestroyedEngineer[][] = {"vo/engineer_mvm_tank_dead01.mp3", "vo/engineer_mvm_wave_end07.mp3", "vo/engineer_cheers01.mp3", "vo/engineer_cheers02.mp3", "vo/engineer_mvm_collect_credits03.mp3", "vo/engineer_specialcompleted01.mp3"};

char g_strSoundCashScout[][] = {"vo/scout_award01.mp3", "vo/scout_award09.mp3", "vo/scout_specialcompleted12.mp3", "vo/taunts/scout_taunts02.mp3", "vo/taunts/scout_taunts17.mp3"};
char g_strSoundCashSniper[][] = {"vo/sniper_mvm_loot_common01.mp3", "vo/taunts/sniper_taunts12.mp3", "vo/taunts/sniper_taunts14.mp3", "vo/taunts/sniper_taunts18.mp3", "vo/sniper_award09.mp3"};
char g_strSoundCashSoldier[][] = {"vo/soldier_mvm_taunt01.mp3", "vo/soldier_mvm_taunt02.mp3", "vo/taunts/soldier_taunts03.mp3", "vo/taunts/soldier_taunts21.mp3", "vo/taunts/soldier_taunts05.mp3"};
char g_strSoundCashDemoman[][] = {"vo/taunts/demoman_taunts11.mp3", "vo/taunts/demoman_taunts01.mp3", "vo/taunts/demoman_taunts06.mp3"};
char g_strSoundCashHeavy[][] = {"vo/heavy_mvm_get_upgrade03.mp3", "vo/heavy_specialcompleted05.mp3", "vo/heavy_mvm_taunt02.mp3"};
char g_strSoundCashPyro[][] = {"vo/pyro_specialcompleted01.mp3"};
char g_strSoundCashSpy[][] = {"vo/taunts/spy_taunts11.mp3", "vo/taunts/spy_taunts10.mp3", "vo/spy_sf13_influx_small06.mp3"};
char g_strSoundCashEngineer[][] = {"vo/engineer_mvm_taunt01.mp3", "vo/engineer_mvm_taunt02.mp3"};

char g_strSoundBombDeployedScout[][] = {"vo/scout_jeers04.mp3", "vo/scout_jeers05.mp3", "vo/scout_jeers08.mp3", "vo/scout_jeers11.mp3", "vo/scout_sf13_magic_reac03.mp3", "vo/scout_autodejectedtie01.mp3", "vo/scout_autodejectedtie02.mp3", "vo/scout_negativevocalization05.mp3"};
char g_strSoundBombDeployedSniper[][] = {"vo/sniper_negativevocalization03.mp3", "vo/sniper_jeers01.mp3", "vo/sniper_jeers06.mp3", "vo/sniper_autodejectedtie03.mp3"};
char g_strSoundBombDeployedSoldier[][] = {"vo/soldier_jeers02.mp3", "vo/soldier_jeers07.mp3", "vo/soldier_mvm_wave_end08.mp3", "vo/soldier_mvm_wave_end09.mp3", "vo/soldier_mvm_wave_end10.mp3"};
char g_strSoundBombDeployedDemoman[][] = {"vo/demoman_jeers05.mp3", "vo/demoman_jeers03.mp3", "vo/demoman_autodejectedtie04.mp3", "vo/demoman_sf12_badmagic07.mp3"};
char g_strSoundBombDeployedMedic[][] = {"vo/medic_mvm_wave_end04.mp3", "vo/medic_mvm_wave_end05.mp3", "vo/medic_mvm_wave_end06.mp3", "vo/medic_mvm_wave_end07.mp3"};
char g_strSoundBombDeployedHeavy[][] = {"vo/heavy_jeers07.mp3", "vo/heavy_negativevocalization06.mp3", "vo/heavy_negativevocalization03.mp3"};
char g_strSoundBombDeployedPyro[][] = {"vo/pyro_jeers01.mp3", "vo/pyro_jeers02.mp3"};
char g_strSoundBombDeployedSpy[][] = {"vo/spy_autodejectedtie01.mp3", "vo/spy_autodejectedtie02.mp3", "vo/spy_autodejectedtie03.mp3", "vo/spy_negativevocalization06.mp3", "vo/spy_jeers06.mp3"};
char g_strSoundBombDeployedEngineer[][] = {"vo/engineer_mvm_wave_end04.mp3", "vo/engineer_mvm_wave_end05.mp3", "vo/engineer_mvm_wave_end06.mp3", "vo/engineer_negativevocalization03.mp3"};

char g_strSoundTankCappedScout[][] = {"vo/scout_cartmovingforwarddefense01.mp3", "vo/scout_cartmovingforwarddefense02.mp3", "vo/scout_cartstopitdefense01.mp3", "vo/scout_cartstopitdefense03.mp3"};
char g_strSoundTankCappedSniper[][] = {"vo/sniper_cartmovingforwarddefense01.mp3", "vo/sniper_cartstopitdefense05.mp3", "vo/sniper_cartmovingforwarddefense02.mp3", "vo/sniper_cartmovingforwarddefense03.mp3", "vo/sniper_cartstopitdefensesoft03.mp3"};
char g_strSoundTankCappedSoldier[][] = {"vo/soldier_mvm_tank_shooting01.mp3", "vo/soldier_mvm_tank_shooting02.mp3", "vo/soldier_mvm_tank_shooting03.mp3"};
char g_strSoundTankCappedDemoman[][] = {"vo/demoman_cartgoingforwarddefense01.mp3", "vo/demoman_cartgoingforwarddefense02.mp3"};
char g_strSoundTankCappedMedic[][] = {"vo/medic_mvm_tank_shooting01.mp3", "vo/medic_mvm_tank_shooting02.mp3", "vo/medic_mvm_tank_shooting03.mp3", "vo/medic_cartstopitdefense01.mp3"};
char g_strSoundTankCappedHeavy[][] = {"vo/heavy_cartmovingforwarddefense02.mp3", "vo/heavy_cartmovingforwarddefense03.mp3", "vo/heavy_sf12_attack02.mp3"};
char g_strSoundTankCappedPyro[][] = {"vo/pyro_standonthepoint01.mp3"};
char g_strSoundTankCappedSpy[][] = {"vo/spy_cartstopitdefense01.mp3", "vo/spy_cartstopitdefense03.mp3", "vo/spy_cartgoingforwarddefense04.mp3"};
char g_strSoundTankCappedEngineer[][] = {"vo/engineer_mvm_tank_shooting01.mp3"};

char g_strSoundTankDeployingScout[][] = {"vo/scout_helpme02.mp3", "vo/scout_helpme04.mp3", "vo/scout_cartmovingforwarddefense03.mp3"};
char g_strSoundTankDeployingSniper[][] = {"vo/sniper_helpme03.mp3", "vo/sniper_helpmedefend02.mp3", "vo/sniper_helpmedefend03.mp3"};
char g_strSoundTankDeployingSoldier[][] = {"vo/soldier_mvm_tank_deploy01.mp3"};
char g_strSoundTankDeployingDemoman[][] = {"vo/demoman_helpmedefend01.mp3", "vo/demoman_helpmedefend02.mp3"};
char g_strSoundTankDeployingMedic[][] = {"vo/medic_mvm_tank_deploy01.mp3"};
char g_strSoundTankDeployingHeavy[][] = {"vo/heavy_mvm_tank_deploy01.mp3"};
char g_strSoundTankDeployingPyro[][] = {"vo/pyro_helpme01.mp3"};
char g_strSoundTankDeployingSpy[][] = {"vo/spy_helpmedefend01.mp3", "vo/spy_helpmedefend03.mp3"};
char g_strSoundTankDeployingEngineer[][] = {"vo/engineer_mvm_tank_deploy01.mp3"};

char g_strSoundGiantKillScout[][] = {"vo/scout_autocappedcontrolpoint03.mp3", "vo/scout_autocappedcontrolpoint04.mp3", "vo/scout_autocappedintelligence03.mp3", "vo/scout_award11.mp3", "vo/scout_award12.mp3", "vo/scout_cheers02.mp3", "vo/scout_domination06.mp3", "vo/scout_domination08.mp3", "vo/scout_domination14.mp3", "vo/scout_domination19.mp3", "vo/taunts/scout_taunts18.mp3", "vo/taunts/scout_taunts02.mp3"};
char g_strSoundGiantKillSniper[][] = {"vo/sniper_autocappedcontrolpoint02.mp3", "vo/sniper_award12.mp3", "vo/sniper_dominationheavy05.mp3", "vo/sniper_laughlong01.mp3", "vo/sniper_laughlong02.mp3", "vo/taunts/sniper_taunts21.mp3"};
char g_strSoundGiantKillSoldier[][] = {"vo/soldier_autocappedcontrolpoint01.mp3", "vo/soldier_autocappedintelligence02.mp3", "vo/soldier_dominationmedic03.mp3", "vo/soldier_laughhappy03.mp3", "vo/soldier_mvm_taunt05.mp3", "vo/soldier_mvm_wave_end04.mp3", "vo/taunts/soldier_taunts07.mp3"};
char g_strSoundGiantKillDemoman[][] = {"vo/demoman_autocappedintelligence01.mp3", "vo/demoman_laughlong01.mp3", "vo/taunts/demoman_taunts08.mp3", "vo/demoman_laughevil03.mp3"};
char g_strSoundGiantKillMedic[][] = {"vo/medic_autocappedcontrolpoint03.mp3", "vo/medic_laughlong01.mp3", "vo/medic_laughlong02.mp3", "vo/medic_laughhappy03.mp3", "vo/medic_mvm_giant_robot02.mp3", "vo/medic_sf13_influx_big03.mp3"};
char g_strSoundGiantKillHeavy[][] = {"vo/heavy_award09.mp3", "vo/heavy_laughlong01.mp3", "vo/heavy_laughterbig04.mp3", "vo/heavy_mvm_giant_robot02.mp3", "vo/heavy_revenge08.mp3", "vo/heavy_specialcompleted11.mp3", "vo/taunts/heavy_taunts02.mp3", "vo/taunts/heavy_taunts12.mp3", "vo/heavy_award08.mp3"};
char g_strSoundGiantKillPyro[][] = {"vo/pyro_autocappedcontrolpoint01.mp3", "vo/taunts/pyro/pyro_taunt_ballon_11.mp3"};
char g_strSoundGiantKillSpy[][] = {"vo/spy_laughevil01.mp3", "vo/spy_laughevil02.mp3", "vo/taunts/spy_taunts15.mp3", "vo/taunts/spy/spy_taunt_rps_win_11.mp3", "vo/spy_revenge03.mp3"};
char g_strSoundGiantKillEngineer[][] = {"vo/engineer_dominationspy10.mp3", "vo/engineer_dominationheavy12.mp3", "vo/engineer_dominationheavy10.mp3", "vo/engineer_revenge01.mp3", "vo/engineer_revenge02.mp3", "vo/engineer_laughlong02.mp3"};

char g_strSoundRobotFallDamage[][] = {"mvm/mvm_fallpain01.wav", "mvm/mvm_fallpain02.wav"};

char g_strSoundWaveFirst[][] = {"vo/mvm_firstwave_start01.mp3", "vo/mvm_firstwave_start02.mp3", "vo/mvm_firstwave_start05.mp3", "vo/mvm_firstwave_start06.mp3"};
char g_strSoundWaveFinal[][] = {"vo/mvm_final_wave_start01.mp3", "vo/mvm_final_wave_start02.mp3", "vo/mvm_final_wave_start04.mp3", "vo/mvm_final_wave_start05.mp3", "vo/mvm_final_wave_start06.mp3", "vo/mvm_final_wave_start07.mp3", "vo/mvm_final_wave_start12.mp3"};
char g_strSoundWaveMid[][] = {"vo/mvm_general_wav_start01.mp3", "vo/mvm_general_wav_start02.mp3", "vo/mvm_general_wav_start03.mp3", "vo/mvm_general_wav_start04.mp3", "vo/mvm_general_wav_start06.mp3", "vo/mvm_general_wav_start08.mp3"};

char g_soundBusterStabbed[][] = {"vo/spy_laughevil01.mp3", "vo/spy_laughevil02.mp3", "vo/spy_laughhappy01.mp3", "vo/spy_laughhappy02.mp3", "vo/spy_laughhappy03.mp3"};

char g_soundArrowImpact[][] = {"mvm/melee_impacts/arrow_impact_robo01.wav", "mvm/melee_impacts/arrow_impact_robo02.wav", "mvm/melee_impacts/arrow_impact_robo03.wav"};

char g_demoBossGibs[][] = {"models/bots/gibs/demobot_gib_boss_head.mdl", "models/bots/gibs/demobot_gib_boss_arm1.mdl", "models/bots/gibs/demobot_gib_boss_arm2.mdl", "models/bots/gibs/demobot_gib_boss_leg1.mdl", "models/bots/gibs/demobot_gib_boss_leg2.mdl", "models/bots/gibs/demobot_gib_boss_leg3.mdl", "models/bots/gibs/demobot_gib_boss_pelvis.mdl"};
char g_heavyBossGibs[][] = {"models/bots/gibs/heavybot_gib_boss_head.mdl", "models/bots/gibs/heavybot_gib_boss_arm.mdl", "models/bots/gibs/heavybot_gib_boss_arm2.mdl", "models/bots/gibs/heavybot_gib_boss_chest.mdl", "models/bots/gibs/heavybot_gib_boss_leg.mdl", "models/bots/gibs/heavybot_gib_boss_leg2.mdl", "models/bots/gibs/heavybot_gib_boss_pelvis.mdl"};
char g_pyroBossGibs[][] = {"models/bots/gibs/pyrobot_gib_boss_head.mdl", "models/bots/gibs/pyrobot_gib_boss_arm1.mdl", "models/bots/gibs/pyrobot_gib_boss_arm2.mdl", "models/bots/gibs/pyrobot_gib_boss_arm3.mdl", "models/bots/gibs/pyrobot_gib_boss_chest.mdl", "models/bots/gibs/pyrobot_gib_boss_chest2.mdl", "models/bots/gibs/pyrobot_gib_boss_leg.mdl", "models/bots/gibs/pyrobot_gib_boss_pelvis.mdl"};
char g_scoutBossGibs[][] = {"models/bots/gibs/scoutbot_gib_boss_head.mdl", "models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"};
char g_soldierBossGibs[][] = {"models/bots/gibs/soldierbot_gib_boss_head.mdl", "models/bots/gibs/soldierbot_gib_boss_arm1.mdl", "models/bots/gibs/soldierbot_gib_boss_arm2.mdl", "models/bots/gibs/soldierbot_gib_boss_chest.mdl", "models/bots/gibs/soldierbot_gib_boss_leg1.mdl", "models/bots/gibs/soldierbot_gib_boss_leg2.mdl", "models/bots/gibs/soldierbot_gib_boss_pelvis.mdl"};
char g_spyBossGibs[][] = {"models/bots/gibs/spybot_gib_head.mdl"};
char g_sniperBossGibs[][] = {"models/bots/gibs/sniperbot_gib_head.mdl"};
char g_medicBossGibs[][] = {"models/bots/gibs/medicbot_gib_head.mdl"};
char g_engyBossGibs[][] = {"models/bots/gibs/pyrobot_gib_boss_pelvis.mdl"}; // No engy bot head gib.

char g_soundBombFinalWarning[][] = {"vo/announcer_cart_attacker_finalwarning1.mp3", "vo/announcer_cart_attacker_finalwarning2.mp3", "vo/announcer_cart_attacker_finalwarning5.mp3", "vo/mvm_bomb_alerts03.mp3", "vo/mvm_bomb_alerts05.mp3"};

enum
{
	Rank_Normal=0,
	Rank_Unique,
	Rank_Vintage,
	Rank_Haunted,
	Rank_Strange,
	Rank_Genuine,
	Rank_Unusual,
	Rank_Community,
	Rank_Valve,
};
char g_strRankColors[][] = {"\x07B2B2B2", "\x07FFD700", "\x07476291", "\x0738F3AB", "\x07CF6A32", "\x074D7455", "\x078650AC", "\x0770B04A", "\x07A50F79"};

enum
{
	OpCode_NOP = 0x90
};

float g_flTankLastSound;
float g_flBombLastMessage;
bool g_bSoundHalfway[MAX_TEAMS];

int g_iOffset_m_pnext;
int g_iOffset_m_pprevious;
int g_iOffset_m_ppath;
int g_iOffsetReviveMarker;
int g_iOffset_m_Shared;
int g_iOffset_m_numGibs;
int g_iOffset_m_buildingPercentage;
int g_iOffset_m_uberChunk;
int g_iOffset_m_tauntProp;
int g_iOffset_m_bCapBlocked;
int g_offset_m_bPlayingHybrid_CTF_CP;
int g_offset_m_medicRegenMult;

int g_iNumTankMaxSimulated;

int g_iDamageStatsTank[MAXPLAYERS+1][MAX_TEAMS];
int g_iDamageStatsGiant[MAXPLAYERS+1][MAXPLAYERS+1];

int g_iDamageAccul[MAXPLAYERS+1][MAX_TEAMS];
float g_flTankHealEnd[MAX_TEAMS];
bool g_tankRespawned[MAX_TEAMS];
float g_flTankLastHealed[MAX_TEAMS];
bool g_bTankTriggerDisabled[MAX_TEAMS];

int g_iRaceTankDamage[MAX_TEAMS];
float g_flRaceLastChange[MAX_TEAMS];
int g_iRaceCurrentLevel[MAX_TEAMS];
bool g_bRaceGoingBackwards[MAX_TEAMS];
bool g_bRaceParentedForHill[MAX_TEAMS];

bool g_bEnabled = true;

Handle g_hCvarTournament;
Handle g_cvar_redTeamName;
Handle g_cvar_blueTeamName;
Handle g_hCvarLOSMode;
Handle g_cvar_sv_tags;
Handle g_cvar_mp_bonusroundtime;
// Class restriction global variables
Handle g_hCvarClassLimits[MAX_TEAMS][10];
Handle g_hCvarTournamentClassLimits[10];
char g_strSoundNo[10][24] = {"", "vo/scout_no03.mp3", "vo/sniper_no04.mp3", "vo/soldier_no01.mp3", "vo/demoman_no03.mp3", "vo/medic_no03.mp3", "vo/heavy_no02.mp3", "vo/pyro_no01.mp3", "vo/spy_no02.mp3", "vo/engineer_no03.mp3"};
int g_iClassOverride;

float g_flTimeRoundStarted;
bool g_bHasPlayers;
bool g_bIsInNaturalRound;

int g_iCreatingCartDispenser;

enum eGameMode
{
	GameMode_Unknown=0,
	GameMode_Tank,
	GameMode_BombDeploy,
	GameMode_Race,
};
eGameMode g_nGameMode = GameMode_Tank;

bool g_bBombPlayedNearHatch;
bool g_bBombEnteredGoal;
float g_flBombPlantStart;
int g_iBombPlayerPlanting;
float g_flBombGameEnd;
bool g_bBombSentDropNotice;
bool g_bBombGone;
float g_flTimeBombFell;
bool g_bombAtFinalCheckpoint;
float g_timeBombWarning[MAXPLAYERS+1];

Handle g_hHudSync;

enum
{
	MinigunState_Idle=0,
	MinigunState_Lowering,
	MinigunState_Shooting,
	MinigunState_Spinning
};
int g_iGiantOldState[MAXPLAYERS+1];

float g_flGlobalCooldown;
float g_busterExplodeTime;
bool g_bBlockRagdoll;

enum eFlagEvent
{
	FlagEvent_PickedUp=1,
	FlagEvent_Dropped=4
};
float g_flTimeBombDropped[MAXPLAYERS+1];

bool g_hasSpawnedOnce[MAXPLAYERS+1];
bool g_bIsScramblePending;
int g_iUserIdLastZapper;
float g_flTimeLastZapped;

enum
{
	Annotation_BombSpawned=0,
	Annotation_BombMovedBack,
	Annotation_BombPickupGiant,
	Annotation_BombPickupRobots,
	Annotation_GuidingHint,
	Annotation_BusterWarningRed,
	Annotation_BusterWarningBlue,
	Annotation_GiantPickedRed,
	Annotation_GiantPickedBlue,
	Annotation_GiantHintRed,
	Annotation_GiantHintBlue,
	Annotation_BusterHintRed,
	Annotation_BusterHintBlue,
	Annotation_GiantSpawnedRed,
	Annotation_GiantSpawnedBlue,
	Annotation_BombCaptureSkipped,
	Annotation_GiantBusterSwat, // 16-55
	Annotation_HellHint=56,
};

enum eTeleporterState
{
	TeleporterState_Unconnected=0,
	TeleporterState_Connected
};

enum eGiantTeleporterStruct
{
	g_iGiantTeleporterRefExit,					// Entity reference of the teleporter exit
	Handle:g_hGiantTeleporterTeleQueue,			// Array of players in queue to be teleported
	eTeleporterState:g_nGiantTeleporterState,	// State of the current teleporter exit
	Float:g_flGiantTeleporterLastTeleport,		// Time when the last person was teleported
	Float:g_flGiantTeleporterBeamUpdated, 		// Time when the beam above the teleporter was last updated
	g_iGiantTeleporterRefParticle,				// Entity reference of the teleporter exit beam for pl_ only. plr_ will use the tempent beam to show different team colors.
};
int g_nGiantTeleporter[MAX_TEAMS][eGiantTeleporterStruct];

float g_flTimeCashPickup[MAXPLAYERS+1];
float g_flHasShield[MAXPLAYERS+1];

int g_iRefReanimator[MAXPLAYERS+1];
int g_iRefReanimatorDummy[MAXPLAYERS+1];
bool g_bReanimatorSwitched[MAXPLAYERS+1];
bool g_bReanimatorIsBeingRevied[MAXPLAYERS+1];
int g_iReanimatorNumRevives[MAXPLAYERS+1]; // keeps track of how many times a player has revived in the current round, stored in CTFGameStats
float g_flTimeLastDied[MAXPLAYERS+1];

float g_flTimeBusterTaunt[MAXPLAYERS+1];
bool g_bBusterPassed[MAXPLAYERS+1];
bool g_bBusterUsed[MAXPLAYERS+1];
bool g_bTakingSentryDamage;

int g_iParticleHealRadius = -1;
int g_iParticleBotImpactLight = -1;
int g_iParticleBotImpactHeavy = -1;
int g_iParticleTeleport = -1;
int g_iParticleFireworks[MAX_TEAMS] = {-1, ...};
int g_iParticleFetti = -1;
int g_iSpriteBeam = -1;
int g_iSpriteHalo = -1;
int g_iParticleBotDeath = -1;
int g_iParticleJumpRed = -1;
int g_iParticleJumpBlue = -1;

int g_modelRomevisionTank = -1;
int g_modelRomevisionTrackL = -1;
int g_modelRomevisionTrackR = -1;
int g_teamOverrides[4] = {0, 0, 3, 0}; // This is the m_nModelIndexOverrides index for each team.

enum eDisguisedStruct
{
	g_iDisguisedTeam, // The spy's disguised team
	g_iDisguisedClass // The spy's disguised class
};
int g_nDisguised[MAXPLAYERS+1][eDisguisedStruct];

bool g_blockLogAction = false;

int g_iUserIdLastTrace;
float g_flTimeLastTrace;

bool g_bEnableGameModeHook = false;
bool g_bRaceIntermission = false;
float g_flTimeIntermissionEnds;
bool g_bRaceIntermissionBottom[MAX_TEAMS];
bool g_bCactusTrainOnce;
float g_flTimeStuckInTank[MAXPLAYERS+1][MAX_TEAMS];
Handle g_hAirbourneTimer[MAXPLAYERS+1];
float g_lastPlayedWarning;
int g_numGiantWave = 0;
bool g_isRaceInOvertime;
bool g_playedFinalStretch[MAX_TEAMS];

int g_hellTeamWinner = 0;
Handle g_hellGateTimer = INVALID_HANDLE; // Opens up the gates of hell!
Handle g_timerTip = INVALID_HANDLE; // Periodically shows game tips in chat to players.
Handle g_timerCountdown = INVALID_HANDLE; // Plays the 5,4,3,2,1 announcer countdown before an action.
int g_countdownTime;
Handle g_timerAnnounce = INVALID_HANDLE; // Announces the entrance of the giant with a theme song.

float g_spellTeleportPos[MAXPLAYERS+1][3];
float g_spellTeleportAng[MAXPLAYERS+1][3];

float g_timeLastHealedGiant[MAXPLAYERS+1];
float g_timeTankSeparation[MAX_TEAMS]; // Keeps track of how long the tank has been separated from the cart.
float g_lastClientTick[MAXPLAYERS+1];

int g_finalBombDeployer; // The userid of the player that deployed the bomb and won the round.

float g_timeSentryBusterDied;

float g_timeGiantEnteredDeathpit[MAXPLAYERS+1];

float g_timeControlPointSkipped; // Timestamp when the bomb carrier skips a control point.
float g_timePlayedDestructionSound; // Timestamp when the giant destruction sounds are played.

float g_timeNextMeleeAttack[MAXPLAYERS+1];
int g_numSuccessiveHits[MAXPLAYERS+1];

enum
{
	Interest_None=0,
	Interest_Dispenser,
};
int g_entitiesOfInterest[MAX_EDICTS+1];

Handle g_timerFailsafe;
bool g_overrideSound = false;
float g_timeLastRobotDamage = 0.0;
int g_hitWithScorchShot = 0;

enum eSpawnerType
{
	Spawn_Tank=0,
	Spawn_GiantRobot,
};

#define SPAWNERFLAG_RAGEMETER 		(1 << 0)
#define SPAWNERFLAG_NOPUSHAWAY 		(1 << 1)

#define SPAWNER_SIZE 				MAXPLAYERS+MAX_TEAMS+1
#define SPAWNER_MAX_REMINDERS 		2
// Structure for the giant/tank spawner that supports spawning multiple giants at a time onto the playing field.
enum eSpawnerStruct
{
	bool:g_bSpawnerEnabled,									// Flag to show if spawner is enabled
	Float:g_flSpawnerPos[3],								// Spawn position saved for later
	Float:g_flSpawnerAng[3],								// Spawn angle saved for later
	Handle:g_hSpawnerTimer,									// Timer used in the spawn process
	eSpawnerType:g_nSpawnerType,							// Spawn object type: Spawn_Tank or Spawn_GiantRobot
	g_iSpawnerGiantIndex,									// Template giant index used
	Float:g_flSpawnerTimeSpawned, 							// Engine time when the object has been spawned
	g_iSpawnerFlags, 										// Flags to be used when invoking Spawner_Spawn
	g_iSpawnerExtraEnt, 									// A reference to any entity
	bool:g_bSpawnerShownReminder[SPAWNER_MAX_REMINDERS],	// Flag that a particular reminder has been shown.
};
int g_nSpawner[SPAWNER_SIZE][eSpawnerStruct];

enum
{
	TFStat_PlayerInvulnerable=15,
	TFStat_PlayerStunBall=23,
	TFStat_PlayerRevived=39,
};

#define ANNOUNCER_MAX_MESSAGES 3
enum
{
	AnnouncerMessage_CloseGame=0,
	AnnouncerMessage_LargeDifference,
	AnnouncerMessage_CatchingUp,
};
enum eAnnouncerStruct
{
	bool:g_announcerActive,									// Engage announcer logic.
	bool:g_announcerCloseGame, 								// Tanks are neck-and-neck at the end.
	bool:g_announcerLargeDifference,						// Tanks are far apart from each other in terms of progress.
	bool:g_announcerCatchingUp,								// Tanks are catching up to each other.
	Float:g_announcerLastMessage[ANNOUNCER_MAX_MESSAGES],	// Time when the last message was sent.
};
int g_announcer[eAnnouncerStruct];

enum
{
	ShowInfoPanel_Always=0,
	ShowInfoPanel_PayloadOnly,
	ShowInfoPanel_PayloadRaceOnly,
	ShowInfoPanel_Never,
};
#define MAX_SHOW_INFO_PANEL 3
enum eSettingsStruct
{
	g_settingsShowInfoPanel,								// When to show the giant info panel when a team giant is selected.
};
int g_settings[MAXPLAYERS+1][eSettingsStruct];

#define TANKRANK_NAME_MAXLEN 64
enum eTankRankStruct
{
	g_tankRankNumKills,
	String:g_tankRankName[TANKRANK_NAME_MAXLEN]
};
int g_tankRank[][eTankRankStruct] = {
	{50, "Unremarkable"},
	{150, "Scarcely Lethal"},
	{250, "Mildly Menacing"},
	{400, "Somewhat Threatening"},
	{600, "Uncharitable"},
	{800, "Notably Dangerous"},
	{1024, "Sufficiently Lethal"},
	{1300, "Truly Feared"},
	{1650, "Spectacularly Lethal"},
	{2048, "Gore-Spattered"},
	{3000, "Wicked Nasty"},
	{4500, "Positively Inhumane"},
	{5999, "Totally Ordinary"},
	{6000, "Face-Melting"},
	{8850, "Rage-Inducing"},
	{15000, "Server-Clearing"},
	{30000, "Epic"},
	{40000, "Legendary"},
	{45000, "Australian"},
	{50000, "Hale's Own"}
};

bool g_hasSteamTools = false;
bool g_hasSendProxy = false;

#include "tank_config.sp"
#include "tank_giant.sp"
#include "tank_spawner.sp"
#include "tank_buster.sp"
#include "tank_devel.sp"

public Plugin myinfo = 
{
	name = "Stop that Tank!",
	author = "Banshee, linux_lover (abkowald@gmail.com)",
	description = "Payload gamemode where the defenders must stop an incoming tank.",
	version = PLUGIN_VERSION,
	url = "",
};

public void OnPluginStart()
{
	Tank_PrintLicense();

	CreateConVar("tank_version", PLUGIN_VERSION, "Stop that Tank! Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("tank_enabled", "1", "0/1 - Enable or disable gamemode.");
	g_hCvarGameDesc = CreateConVar("tank_game_description", "1", "0/1 - Enable or disable overriding the game description with the SteamTools extension.");
	g_hCvarMaxSpeed = CreateConVar("tank_speed", "45.0", "The maximum speed (units / second) that the tank can move.");
	g_hCvarTimeGrace = CreateConVar("tank_grace", "15", "Time after setup / round starts that the tank can be attacked and began to move.");
	g_hCvarHealthBase = CreateConVar("tank_health_base", "2000", "Base health of the tank.");
	g_hCvarHealthPlayer = CreateConVar("tank_health_player", "520", "Additional tank health per player on the red team.");
	g_hCvarHealthDistance = CreateConVar("tank_health_distance", "1.0", "Multiplier for the health based on how long the track is for the current stage.");
	g_hCvarRobot = CreateConVar("tank_robot", "1", "0/1 - Make use of robot player models.");
	g_hCvarDistanceWarn = CreateConVar("tank_distance_warn", "500.0", "Distance the tank must be from the goal before warning sounds will play.");
	g_hCvarTankCooldown = CreateConVar("tank_cooldown", "28.0", "Seconds after the tank is killed that a Giant Robot will spawn into the game.");
	g_hCvarDistanceMove = CreateConVar("tank_distance_move", "4600.0", "Distance the control point must be from the goal for tanks to spawn on it.");
	g_hCvarCurrencyCrit = CreateConVar("tank_currency_crit", "5.0", "(Seconds) Crit duration after a RED team member touches a currencypack.");
	g_hCvarCheckpointHealth = CreateConVar("tank_checkpoint_health", "0.2", "Tank health percentage earned when a checkpoint is reached.");
	g_hCvarCheckpointTime = CreateConVar("tank_checkpoint_time", "20.0", "Seconds that the tank will incrementaly heal tank_checkpoint_health.");
	g_hCvarCheckpointInterval = CreateConVar("tank_checkpoint_interval", "0.2", "Seconds that must pass before the tank is healed.");
	g_hCvarCheckpointCutoff = CreateConVar("tank_checkpoint_cutoff", "0.80", "Percentage of tank max health where checkpoint healing stops.");
	g_hCvarTeleBuildMult = CreateConVar("tank_teleporter_build_mult", "2.2", "Increased teleporter build multiplier for the BLU team in pl and ALL teams in plr. (Set to a negative number to disable.)");

	g_hCvarRespawnBase = CreateConVar("tank_respawn_base", "0.1", "Respawn time base for both teams. No respawn time can be less than this value.");
	g_hCvarRespawnTank = CreateConVar("tank_respawn_tank", "2.0", "Respawn time for BLU in pl when the Tank is out. Note: This will be scaled to playercount: x/24*this = final respawn time.");
	g_hCvarRespawnGiant = CreateConVar("tank_respawn_giant", "9.0", "Respawn time for BLU in pl when a Giant is out. Note: This will be scaled to playercount: x/24*this = final respawn time."); // 4.0 default
	g_hCvarRespawnRace = CreateConVar("tank_respawn_race", "3.0", "Respawn time for both teams in tank race (plr). Note: This will be scaled to playercount: x/24*this = final respawn time.");
	g_hCvarRespawnBombRed = CreateConVar("tank_respawn_bomb", "3.0", "Respawn time for RED during the bomb mission. This will be scaled to playercount: x/24*this = final respawn time.");
	g_hCvarRespawnScaleMin = CreateConVar("tank_respawn_scale_min", "0.5", "Scaled respawn times will be a minimum of this percentage. Set to a high number such as 5.0 to disable.");
	g_hCvarRespawnCartBehind = CreateConVar("tank_respawn_cart_behind", "0.25", "A team's tank is considered behind if the difference is greater than this percentage of total track length. Set to over 1.0 to disable.");
	g_hCvarRespawnAdvMult = CreateConVar("tank_respawn_advantage_mult", "3.0", "Respawn time multiplier per each Giant Robot advantage.");
	g_hCvarRespawnAdvCap = CreateConVar("tank_respawn_advantage_cap", "3", "Maximum Giant Robot advantage amount that can be factored into respawn time. Set to 0 to disable.");
	g_hCvarRespawnAdvRunaway = CreateConVar("tank_respawn_advantage_runaway", "2", "When the Giant Robot advantage is equal to or greater than this, the opposite team's respawn is reduced. Set to a really high number like 100 to disable.");

	g_hCvarCheckpointDistance = CreateConVar("tank_checkpoint_distance", "5600", "Track distance for each simulated extra tank. These are used in checkpoint tank health bonus calculation.");
	g_hCvarScrambleHealth = CreateConVar("tank_scramble_health", "0.03", "Trigger a team scramble if the tank's health is greater than this percentage of max health when the round is won. (RED is getting rolled)");
	g_hCvarScrambleEnabled = CreateConVar("tank_scramble_enabled", "1", "0/1 - Enable or disable triggering team scrambles.");
	g_hCvarScrambleProgress = CreateConVar("tank_scramble_progress", "0.25", "Scramble teams if the difference between the two team's tanks is more than this percentage. Set to over 1.0 to disable.");
	g_hCvarWeaponInspect = CreateConVar("tank_weapon_inspect", "2", "0 - no changes to the game | 1 - only the giant's weapons can be inspected | 2 - every weapon can be inspected.");
	g_hCvarScrambleGiants = CreateConVar("tank_scramble_giants", "2", "Scramble teams in payload race if one team has this many or more giants alive when the round is over. Set to -1 to disable.");
	g_hCvarFinaleDefault = CreateConVar("tank_is_finale", "yes", "By default the tank will deploy the bomb and explode when it reaches the end of the tracks. For multi-stage maps, set this to \"no\" to prevent that from happening.");
	g_hCvarTankHealthMultiplier = CreateConVar("tank_health_multiplier", "1.0", "Set a tank max health multiplier that is applied to the final max health of the tank. 2.0 = double tank health.");
	g_hCvarDeployDistance = CreateConVar("tank_deploy_distance", "400.0", "Trigger the tank deploy sequence when the cart is this close to the end.");
	g_hCvarMinPlantDistance = CreateConVar("tank_min_plant_distance", "100.0", "The minimum distance the bomb planter must be from the goal path_track node in order to deploy the bomb.");
	g_hCvarDefaultGiantScale = CreateConVar("tank_default_giant_scale", "1.75", "The default giant scale that will be used if no scale is specified in the giant's template.");
	g_hCvarGoalDistance = CreateConVar("tank_goal_distance", "325.0", "When the tank reaches this distance to the goal, it will be parented to the cart.");
	g_hCvarGiantHealthMultiplier = CreateConVar("tank_giant_health_multiplier", "1.0", "Set a giant max health multiplier that is applied to the total health of the tank. (includes overheal) 2.0 = double giant health.");
	g_hCvarDistanceSeparation = CreateConVar("tank_distance_separation", "200.0", "The tank can be teleported to the cart if it gets this far away from the cart.");
	g_hCvarUpdatesPanel = CreateConVar("tank_updates_panel", "1", "0 - never show updates panel | 1 - only show when requested by !stt in chat | 2 - show when the player first spawns");
	g_hCvarOfficialServer = CreateConVar("tank_official_server", "0", "This turns on specific messages only for our server.");
	g_hCvarTags = CreateConVar("tank_sv_tags", "1", "0/1 - Whether or not to attempt to set an 'stt' tag inside of sv_tags.");
	g_hCvarTeleportStartRed = CreateConVar("tank_teleport_start_red", "", "The targetname of the path_track to teleport the cart to when the round begins. Leaving this blank will use start_node from the team_train_watcher. Set this to \"disabled\" to disable teleporting.");
	g_hCvarTeleportStartBlue = CreateConVar("tank_teleport_start_blue", "", "The targetname of the path_track to teleport the cart to when the round begins. Leaving this blank will use start_node from the team_train_watcher. Set this to \"disabled\" to disable teleporting.");
	g_hCvarTeleportGoal = CreateConVar("tank_teleport_goal", "", "The targetname of the path_track to teleport the cart to when the bomb is deployed. The cart will start moving forward from this position and trigger a win.");

	g_hCvarPointsForTank = CreateConVar("tank_points_for_tank", "2", "Scoreboard points awarded when enough damage is done to the tank.");
	g_hCvarPointsForTankPlr = CreateConVar("tank_points_for_tank_plr", "1", "Scoreboard points awarded when enough damage is done to the tank.");
	g_hCvarPointsForGiant = CreateConVar("tank_points_for_giant", "2", "Scoreboard points awarded when enough damage is done to the giant.");
	g_hCvarPointsForGiantPlr = CreateConVar("tank_points_for_giant_plr", "1", "Scoreboard points awarded when enough damage is done to the giant.");
	g_hCvarPointsDamageTank = CreateConVar("tank_points_damage_tank", "1000", "Tank damage required to be rewarded with scoreboard points.");
	g_hCvarPointsDamageGiant = CreateConVar("tank_points_damage_giant", "1000", "Giant damage required to be rewarded with scoreboard points.");
	g_hCvarPointsForDeploy = CreateConVar("tank_points_for_deploy", "5", "Scoreboard points awarded when a bomb carrier deploys the bomb in pl.");

	g_hCvarAttribHaulSpeed = CreateConVar("tank_haul_speed", "1.1111", "Haul speed modifier for RED engineers on pl_ or ALL engineers on plr_.");
	g_hCvarAttribMetalMult = CreateConVar("tank_metal_mult", "1.7", "Metal multiplier for RED engineers on pl_ or ALL engineers on plr_.");
	g_hCvarTankStuckTime = CreateConVar("tank_stuck_time", "2.0", "Seconds a player must be stuck in a tank to be teleported back out.");
	g_hCvarZapPenalty = CreateConVar("tank_zap_penalty", "200", "Metal penalty for zapping Sir Nukesalot's projectile with the short circuit.");
	g_hCvarSirNukesCap = CreateConVar("tank_sirnukes_cap", "500", "Cap for sir nukesalot's deflected projectiles self damage.");
	g_hCvarTeleportUber = CreateConVar("tank_teleport_uber", "1.0", "Seconds of uber when a player uses a giant engineer's teleporter.");
	g_hCvarTimeTip = CreateConVar("tank_time_tip", "220", "Seconds in between chat tips. Anything less than 0 disables chat tips.");

	g_hCvarBombReturnTime = CreateConVar("tank_bomb_return_time", "50", "Time (in seconds) that it takes for a dropped bomb to expire.");
	g_hCvarBombRoundTime = CreateConVar("tank_bomb_round_time", "2.5", "Timelimit (in minutes) that the robots are under to deliever the bomb.");
	g_hCvarBombDistanceWarn = CreateConVar("tank_bomb_distance_warn", "650.0", "Distance the bomb must be from the goal for warnings to sound.");
	g_hCvarBombTimeDeploy = CreateConVar("tank_bomb_time_deploy", "1.9", "Seconds that it takes for a robot to deploy a bomb.");
	g_hCvarBombMoveSpeed = CreateConVar("tank_bomb_move_speed", "0.8", "Move speed bonus for normal bomb carriers. (percentage)");
	g_hCvarBombCapAreaSize = CreateConVar("tank_bomb_capture_size", "-175.0 -175.0 -50.0 175.0 175.0 125.0", "Define the bomb capture area size. First 3 numbers are the x,y,z mins. Last 3 numbers are the x,y,z maxs. Delimited by space.");
	g_hCvarBombCaptureRate = CreateConVar("tank_bomb_capture_rate", "2.9", "Capture rate for robots to capture a control point with the bomb.");
	g_hCvarBombTimeAdd = CreateConVar("tank_bomb_time_add", "60", "Time (seconds) added when a robot captures a control point with the bomb.");
	g_hCvarBombTimePenalty = CreateConVar("tank_bomb_time_penalty", "8.0", "Time (seconds) after a bomb turns up out of bounds that it is respawned back in the game.");
	g_hCvarBombHealDuration = CreateConVar("tank_bomb_heal_duration", "3.0", "Time (seconds) duration of heal effect when a normal robot picks up the bomb.");
	g_hCvarBombMiniCritsDuration = CreateConVar("tank_bomb_minicrits_duration", "-1.0", "Time (seconds) duration of minicrits when a normal robot picks up the bomb.");
	g_hCvarBombHealCooldown = CreateConVar("tank_bomb_heal_cooldown", "10.0", "Time (seconds) between dropping the bomb and picking it up that heal effects are granted.");
	g_hCvarBombBuffsCuttoff = CreateConVar("tank_bomb_buffs_cutoff", "10", "Minimum player count required for bomb carrier buffs to be activated.");
	g_hCvarBombWinSpeed = CreateConVar("tank_bomb_win_speed", "500.0", "Speed of the payload cart when the robots deploy the bomb, winning the round.");
	g_hCvarBombSkipDistance = CreateConVar("tank_bomb_skip_distance", "500.0", "Distance you must be to a locked control point to trigger the skipped annotation.");

	g_hCvarGiantAmmoMultiplier = CreateConVar("tank_giant_ammo_multiplier", "10.0", "Ammo multiplier for giant robots.");
	g_hCvarGiantForce = CreateConVar("tank_giant_force", "-1", "Index of giant template to pick. (-1 = random)");
	g_hCvarBusterForce = CreateConVar("tank_buster_force", "-1", "Index of giant templete to pick for the sentry buster. (-1 = random)");
	g_hCvarGiantKnifeDamage = CreateConVar("tank_giant_knife_damage", "750", "Set backstab damage against Giant Robots by given damage.");
	g_hCvarGiantWarnTime = CreateConVar("tank_giant_warn_time", "5.0", "Minimum time (in seconds) that a giant must be warned before that giant is spawned into the game.");
	g_hCvarGiantWarnCutoff = CreateConVar("tank_giant_cutoff_time", "17.0", "Seconds after a bomb deploy round begins that a giant can no longer replace an afk/disconnected giant. (May need to add 5.0s, round start is when the countdown begins)");
	g_hCvarGiantTimeAFK = CreateConVar("tank_giant_time_afk", "7.0", "Seconds after spawning when a giant will be considered AFK.");
	g_hCvarGiantCooldown = CreateConVar("tank_giant_cooldown", "30.0", "Time (minutes) that must pass in order for a player to be chosen as a giant again.");
	g_hCvarGiantCooldownPlr = CreateConVar("tank_giant_cooldown_plr", "15.0", "Time (minutes) that must pass in order for a player to be chosen as a giant again in payload race.");
	g_hCvarGiantGibs = CreateConVar("tank_giant_gibs", "5", "Number of gibs that spawn when a giant is destroyed. Set to 0 to spawn no gibs.");
	g_hCvarGiantScaleHealing = CreateConVar("tank_giant_scale_healing", "1", "0/1 - Enable or disable giant healing scaling for low player counts in pl.");
	g_hCvarGiantDeathpitDamage = CreateConVar("tank_giant_deathpit_damage", "500.0", "The amount of damage the giant should take when they fall into a death pit.");
	g_hCvarGiantDeathpitCooldown = CreateConVar("tank_giant_deathpit_cooldown", "0.4", "The time (seconds) that must pass before the giant can be hurt/teleported again.");
	g_hCvarGiantDeathpitMinZ = CreateConVar("tank_giant_deathpit_min_z", "500.0", "Minimum boost scaling in the Z(up) direction.");
	g_hCvarGiantDeathpitBoost = CreateConVar("tank_giant_deathpit_boost", "1", "0/1 - Enable or disable boosting Giant Robots out of deathpits.");
	g_hCvarGiantHandScale = CreateConVar("tank_giant_hand_scale", "1.9", "Giant hand scale to use when the special giant tag is set.");

	g_hCvarRageBase = CreateConVar("tank_rage_base", "45.0", "Time (seconds) that the giant has to do damage before they expire.");
	g_hCvarRageScale = CreateConVar("tank_rage_scale", "25.0", "The maximum time (seconds) that will be added to the rage meter base. This will scale for player count.");
	g_hCvarRageLow = CreateConVar("tank_rage_low", "20.0", "The rage meter will show when the player's rage meter has this much time (seconds) left.");

	g_hCvarRaceLvls[0] = CreateConVar("tank_race_level_0", "-0.24", "-1.0-0.0 - The speed the tank moves backwards < on hills as a percentage of maxspeed.", _, true, -1.0, true, 0.0);
	g_hCvarRaceLvls[1] = CreateConVar("tank_race_level_1", "0.15", "0.0-1.0 - The speed the tank moves at x1 as a percentage of maxspeed.", _, true, 0.0, true, 1.0);
	g_hCvarRaceLvls[2] = CreateConVar("tank_race_level_2", "0.4", "0.0-1.0 - The speed the tank moves at x2 as a percentage of maxspeed.", _, true, 0.0, true, 1.0);
	g_hCvarRaceLvls[3] = CreateConVar("tank_race_level_3", "0.7", "0.0-1.0 - The speed the tank moves at x3 as a percentage of maxspeed.", _, true, 0.0, true, 1.0);
	g_hCvarRaceLvls[4] = CreateConVar("tank_race_level_4", "1.0", "0.0-1.0 - The speed the tank moves at x4 as a percentage of maxspeed.", _, true, 0.0, true, 1.0);
	g_hCvarRaceInterval = CreateConVar("tank_race_interval", "3.0", "Time (seconds) in between tank level/speed changes.");
	g_hCvarRaceDamageBase = CreateConVar("tank_race_damage_base", "50", "base + EPC * average | The base damage in the formula for each level interval.");
	g_hCvarRaceDamageAverage = CreateConVar("tank_race_damage_average", "9", "base + EPC * average | The average damage in the formula for each level interval.");
	g_hCvarRaceTimeGiantStart = CreateConVar("tank_race_time_giant_start", "0.75", "Time (minutes) after tanks start moving when giant robots will spawn.");
	g_hCvarRaceTimeIntermission = CreateConVar("tank_race_time_intermission", "0.9", "Time (minutes) after giants spawn that the tanks will move again. Set to -1.0 to disable intermission. Can't be less than 0.2.");
	g_hCvarRaceTimeWave = CreateConVar("tank_race_time_wave", "0.75", "Time (minutes) between giant waves in payload race. The first giant spawn time is set with tank_race_time_giant_start.");
	g_hCvarRaceNumWaves = CreateConVar("tank_race_num_waves", "2", "Number of giants that spawn in each payload race round.");
	g_hCvarRaceGiantHealthMin = CreateConVar("tank_race_giant_health_min", "0.5", "Minimum percentage that giant health and overheal will be scaled to based on opposite team player count in plr_.");
	g_hCvarRaceTimeOvertime = CreateConVar("tank_race_time_overtime", "4.0", "Time (minutes) after the final wave that overtime will begin and the cart will no longer move backwards.");

	g_hCvarReanimatorReviveMult = CreateConVar("tank_reanimator_revive_multiplier", "5", "The health added for each successful revive of a player.");
	g_hCvarReanimatorMaxHealthMult = CreateConVar("tank_reanimator_maxhealth_multiplier", "0.5", "The max health multiplier of the player's max health.");
	g_hCvarReanimatorVacUber = CreateConVar("tank_reanimator_vac_uber", "0.75", "Percent of max health to instantly heal when the player pops a vaccinator uber while healing a revive marker.");

	g_hCvarBusterExplodeMagnitude = CreateConVar("tank_buster_explode_damage", "2500", "Damage dealt inside explosion radius.");
	g_hCvarBusterExplodeRadius = CreateConVar("tank_buster_explode_radius", "300", "Explosion radius.");
	g_hCvarBusterTriggerTank = CreateConVar("tank_buster_trigger_tank", "2500", "A sentry buster can spawn when this damage is dealt to the tank by a sentry.");
	g_hCvarBusterTriggerGiant = CreateConVar("tank_buster_trigger_giant", "1800", "A sentry buster can spawn when this damage is dealt to the giant by a sentry.");
	g_hCvarBusterTriggerRobots = CreateConVar("tank_buster_trigger_robot", "6", "A sentry buster can spawn after the specified robot kills.");
	g_hCvarBusterTimeWarn = CreateConVar("tank_buster_time_warn", "3.0", "Time (seconds) duration where a player will be warned that he will become a sentry buster and have a chance to pass.");
	g_hCvarBusterTriggerTankPlr = CreateConVar("tank_buster_trigger_tank_plr", "3250", "A sentry buster can spawn when this damage is dealt to the tank by a sentry in plr_ maps.");
	g_hCvarBusterTriggerGiantPlr = CreateConVar("tank_buster_trigger_giant_plr", "1500", "A sentry buster can spawn when this damage is dealt to the giant by a sentry in plr_ maps.");
	g_hCvarBusterTriggerRobotsPlr = CreateConVar("tank_buster_trigger_robot_plr", "5", "A sentry buster can spawn after the specified robot kills in plr_ maps.");
	g_hCvarBusterTimePause = CreateConVar("tank_buster_time_pause", "10.0", "Minimum time (in seconds) enforced on the buster timer when it becomes unpaused.");
	g_hCvarBusterFormulaBaseFirst = CreateConVar("tank_buster_formula_base_first", "100.0", "Base part for: base - (sentry_mult * active_sentries)");
	g_hCvarBusterFormulaBaseSecond = CreateConVar("tank_buster_formula_base_second", "60.0", "Base part for: base - (sentry_mult * active_sentries)");
	g_hCvarBusterFormulaSentryMult = CreateConVar("tank_buster_formula_sentry_mult", "5.0", "Sentry multiplier part for: base - (sentry_mult * active_sentries)");
	g_hCvarBusterExemptMedicUber = CreateConVar("tank_buster_excempt_medic_uber", "0.5", "Uber built to excempt the player from becoming a sentry buster. 0.5 = 50%.");
	g_hCvarBusterCap = CreateConVar("tank_buster_cap", "1000", "Damage cap against giant robots.");

	g_hCvarSuperSpyMoveSpeed = CreateConVar("tank_superspy_move_speed", "1.5", "Super spy move speed percentage while cloaked.");
	g_hCvarSuperSpyJumpHeight = CreateConVar("tank_superspy_jump_height", "2.0", "Super spy jump height percentage while cloaked.");

	g_hCvarTeamRed = CreateConVar("tank_team_red", "HUMANS", "Team name of the RED team.");
	g_hCvarTeamRedPlr = CreateConVar("tank_team_red_plr", "RED-BOTS", "Team name of the RED team in plr.");
	g_hCvarTeamBlue = CreateConVar("tank_team_blue", "ROBOTS", "Team name of the BLUE team.");
	g_hCvarTeamBluePlr = CreateConVar("tank_team_blue_plr", "BLU-BOTS", "Team name of the BLUE team in plr.");

	g_hCvarHellTowerTimeGate = CreateConVar("tank_helltower_time_gates_open", "30.0", "Seconds after hell starts that the gates open in hell. This triggers the relay which will then delay an additional 29 seconds.");
	g_hCvarGiantHHHCap = CreateConVar("tank_giant_hhh_cap", "250.0", "Damage cap for the HHH Halloween boss against the giant.");
	g_hCvarJarateOnHitTime = CreateConVar("tank_jarate_on_hit_time", "4.0", "Seconds that jarate is applied for the jarate_on_hit giant tag.");

	g_hCvarClassLimits[TFTeam_Red][1] = CreateConVar("tank_classlimit_red_scout", "2", "Class limit for scout. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][2] = CreateConVar("tank_classlimit_red_sniper", "2", "Class limit for sniper. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][3] = CreateConVar("tank_classlimit_red_soldier", "2", "Class limit for soldier. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][4] = CreateConVar("tank_classlimit_red_demoman", "2", "Class limit for demoman. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][5] = CreateConVar("tank_classlimit_red_medic", "2", "Class limit for medic. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][6] = CreateConVar("tank_classlimit_red_heavy", "2", "Class limit for heavy. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][7] = CreateConVar("tank_classlimit_red_pyro", "2", "Class limit for pyro. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][8] = CreateConVar("tank_classlimit_red_spy", "2", "Class limit for spy. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Red][9] = CreateConVar("tank_classlimit_red_engineer", "2", "Class limit for engineer. Set to -1 for no limit.");

	g_hCvarClassLimits[TFTeam_Blue][1] = CreateConVar("tank_classlimit_blu_scout", "2", "Class limit for scout. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][2] = CreateConVar("tank_classlimit_blu_sniper", "2", "Class limit for sniper. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][3] = CreateConVar("tank_classlimit_blu_soldier", "2", "Class limit for soldier. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][4] = CreateConVar("tank_classlimit_blu_demoman", "2", "Class limit for demoman. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][5] = CreateConVar("tank_classlimit_blu_medic", "2", "Class limit for medic. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][6] = CreateConVar("tank_classlimit_blu_heavy", "2", "Class limit for heavy. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][7] = CreateConVar("tank_classlimit_blu_pyro", "2", "Class limit for pyro. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][8] = CreateConVar("tank_classlimit_blu_spy", "2", "Class limit for spy. Set to -1 for no limit.");
	g_hCvarClassLimits[TFTeam_Blue][9] = CreateConVar("tank_classlimit_blu_engineer", "2", "Class limit for engineer. Set to -1 for no limit.");

	g_hCvarLOSMode = FindConVar("ai_los_mode");
	g_hCvarTournament = FindConVar("mp_tournament");
	g_cvar_redTeamName = FindConVar("mp_tournament_redteamname");
	g_cvar_blueTeamName = FindConVar("mp_tournament_blueteamname");
	g_cvar_sv_tags = FindConVar("sv_tags");
	g_cvar_mp_bonusroundtime = FindConVar("mp_bonusroundtime");
	int iFlags = GetConVarFlags(g_hCvarTournament);
	if(iFlags & FCVAR_NOTIFY) iFlags &= ~(FCVAR_NOTIFY);
	if(iFlags & FCVAR_REPLICATED) iFlags &= ~(FCVAR_REPLICATED);
	SetConVarFlags(g_hCvarTournament, iFlags);
	
	g_hCvarRestartGame = FindConVar("mp_restartgame");

	g_hCvarTournamentClassLimits[1] = FindConVar("tf_tournament_classlimit_scout");
	g_hCvarTournamentClassLimits[2] = FindConVar("tf_tournament_classlimit_sniper");
	g_hCvarTournamentClassLimits[3] = FindConVar("tf_tournament_classlimit_soldier");
	g_hCvarTournamentClassLimits[4] = FindConVar("tf_tournament_classlimit_demoman");
	g_hCvarTournamentClassLimits[5] = FindConVar("tf_tournament_classlimit_medic");
	g_hCvarTournamentClassLimits[6] = FindConVar("tf_tournament_classlimit_heavy");
	g_hCvarTournamentClassLimits[7] = FindConVar("tf_tournament_classlimit_pyro");
	g_hCvarTournamentClassLimits[8] = FindConVar("tf_tournament_classlimit_spy");
	g_hCvarTournamentClassLimits[9] = FindConVar("tf_tournament_classlimit_engineer");

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundActive);
	HookEvent("teamplay_setup_finished", Event_SetupFinished);
	HookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("npc_hurt", Event_TankHurt);
	HookEvent("teamplay_flag_event", Event_FlagEvent);
	HookEvent("player_builtobject", Event_BuildObject, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_chargedeployed", Event_ChargeDeployed, EventHookMode_Pre);
	HookEvent("player_carryobject", Event_CarryObject);
	HookEvent("player_dropobject", Event_DropObject);
	HookEvent("object_detonated", Event_DropObject);
	HookEvent("teamplay_point_captured", Event_PointCaptured);
	HookEvent("post_inventory_application", Event_Inventory);
	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("teamplay_win_panel", Event_WinPanel, EventHookMode_Pre);
	HookEvent("player_healonhit", Event_PlayerHealOnHit, EventHookMode_Pre);

	HookEvent("revive_player_notify", Event_ReviveNotify);
	HookEvent("revive_player_complete", Event_ReviveComplete);

	RegAdminCmd("tank_test", Command_Test, ADMFLAG_ROOT);
	RegAdminCmd("tank_test2", Command_Test2, ADMFLAG_ROOT);
	RegAdminCmd("sm_makebuster", Command_MakeGiant, ADMFLAG_ROOT);
	RegAdminCmd("sm_makegiant", Command_MakeGiant, ADMFLAG_ROOT);
	RegAdminCmd("sm_resetbomb", Command_ResetBomb, ADMFLAG_GENERIC);
	RegAdminCmd("tank_info", Command_Info, ADMFLAG_GENERIC);
	RegAdminCmd("tank_config", Command_Config, ADMFLAG_ROOT);
	RegAdminCmd("tank_explode", Command_Explode, ADMFLAG_ROOT);
	RegConsoleCmd("sm_buster", Command_Buster);
	RegConsoleCmd("sm_pass", Command_Pass);

	AddCommandListener(Listener_DropBomb, "dropitem");
	AddCommandListener(Listener_Destroy, "destroy");
	AddCommandListener(Listener_Joinclass, "joinclass");
	AddCommandListener(Listener_Joinclass, "join_class");
	AddCommandListener(Listener_Taunt, "taunt");
	AddCommandListener(Listener_TeamName, "tournament_teamname");
	
	RegConsoleCmd("stt", Command_Updates);
	
	g_cookieInfoPanel = RegClientCookie("stt.show_info_panel", "When to show the info panel when a giant has been selected.", CookieAccess_Private);
	SetCookieMenuItem(Settings_ItemSelected, 0, "Stop That Tank");
	
	AddNormalSoundHook(NormalSoundHook);
	AddGameLogHook(OnGameLog);

	for(int i=2; i<=3; i++)
	{
		g_nGiantTeleporter[i][g_hGiantTeleporterTeleQueue] = CreateArray();
	}
	g_nSentryVision[g_hSentryVisionList] = CreateArray();
	
	HookEntityOutput("team_round_timer", "On10SecRemain", Output_On10SecRemaining);
	HookEntityOutput("team_control_point", "OnCapTeam2", Output_OnBlueCapture);
	HookEntityOutput("team_control_point_round", "OnStart", Output_TeamControlPointRound_OnStart);
	HookEntityOutput("team_control_point_round", "OnEnd", Output_TeamControlPointRound_OnEnd);

	CreateTimer(0.3, Timer_CheckTeams, _, TIMER_REPEAT);

	g_hHudSync = CreateHudSynchronizer();

	// Do player hooks in case of late-load
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, Player_OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, Player_TraceAttack);

			Settings_Load(i);
		}
	}

	LookupOffset(g_iOffsetReviveMarker, "CTFPlayer", "m_nForcedSkin");
	LookupOffset(g_iOffset_m_Shared, "CTFPlayer", "m_Shared");
	LookupOffset(g_offset_m_bPlayingHybrid_CTF_CP, "CTFGameRulesProxy", "m_bPlayingHybrid_CTF_CP");
	if(LookupOffset(g_iOffset_m_numGibs, "CBaseObject", "m_bServerOverridePlacement"))
	{
		g_iOffset_m_numGibs -= 8; // This offset stores how many gibs are spawned when an object is detonated. Don't set this to a crazy number or you will crash. Valve references this number directly when creating the gib model name.
	}
	if(LookupOffset(g_iOffset_m_buildingPercentage, "CBaseObject", "m_flPercentageConstructed"))
	{
		g_iOffset_m_buildingPercentage += 4; // This offset stores the real construction percent. The netprop is a proxy.
	}
	if(LookupOffset(g_iOffset_m_uberChunk, "CWeaponMedigun", "m_nChargeResistType"))
	{
		g_iOffset_m_uberChunk += 56; // This offset stores the number of uber chucks deployed.
	}
	if(LookupOffset(g_iOffset_m_tauntProp, "CTFPlayer", "m_flVehicleReverseTime"))
	{
		g_iOffset_m_tauntProp += 32; // This offset stores a reference to the player's taunt prop entity when they are taunting.
	}
	if(LookupOffset(g_iOffset_m_bCapBlocked, "CTeamTrainWatcher", "m_nNumCappers"))
	{
		g_iOffset_m_bCapBlocked += 44; // This offset allows me to force the timer into overtime on plr maps.
	}
	if(LookupOffset(g_offset_m_medicRegenMult, "CTFPlayer", "m_iSpawnCounter"))
	{
		g_offset_m_medicRegenMult += 52; // This offset keeps medic health regen at a constant rate.
	}

	LoadTranslations("common.phrases");
	LoadTranslations("tank.phrases");

	AddTempEntHook("TFBlood", TempEntHook_Blood); // Hook blood on damage particle, robots don't bleed!
	AddTempEntHook("EffectDispatch", TempEntHook_Bleed); // Hook bleed effects on robots
	AddTempEntHook("World Decal", TempEntHook_Decal); // Hook blood stain decals on walls
	AddTempEntHook("Entity Decal", TempEntHook_Decal); // Hook blood stain decals on entities

	Giant_InitTemplates();

	g_hasSteamTools = LibraryExists("SteamTools");
	g_hasSendProxy = LibraryExists("sendproxy");
#if !defined _steamtools_included
	LogMessage("WARNING: Compiled with no SteamTools support. The Game in the server browser will always show \"Team Fortress\".");
#endif
#if !defined _SENDPROXYMANAGER_INC_
	LogMessage("WARNING: Compiled with no SendProxy support. Side effects:\n1. Giant engineer will not be able to destroy sapped buildings via the Destruction PDA.\n2. Giant health meter will show when the Super Spy is disguised.");
#endif

	config = new Config();
	g_blockedCosmetics = new BlockedCosmetics();
	g_giantTracker = new GiantTracker();
	g_customProps = new CustomProps();

	HookConVarChange(g_hCvarTimeTip, ConVarChanged_ChatTips);

	g_chatTips = new ArrayList(ByteCountToCells(MAXLEN_CHAT_TIP));
	g_parentList = new ArrayList(ARRAY_PARENT_SIZE);
	g_cartModels = new ArrayList(ByteCountToCells(MAXLEN_CART_PATH));
	g_giantSpawns = new ArrayList(ARRAY_GIANTSPAWN_SIZE);
	g_trainProps = new ArrayList(ARRAY_TRAINPROP_SIZE);
	g_captureSize = new ArrayList(ARRAY_CAPTURESIZE_SIZE);
}

public void OnAllPluginsLoaded()
{
	SDK_Init();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "SteamTools") == 0)
	{
		g_hasSteamTools = true;
	}else if(strcmp(name, "sendproxy") == 0)
	{
		g_hasSendProxy = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "SteamTools") == 0)
	{
		g_hasSteamTools = false;
	}else if(strcmp(name, "sendproxy") == 0)
	{
		g_hasSendProxy = false;
	}
}

bool LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if(iOffset <= 0)
	{
		LogMessage("Could not locate offset for %s::%s!", strClass, strProp);
		return false;
	}

	return true;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Player_OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, Player_TraceAttack);
}

public void OnClientPostAdminCheck(int client)
{
	Settings_Load(client);
}

public void OnMapStart()
{
	g_bEnabled = true;
	g_nMapHack = MapHack_None;
	
	char strMap[PLATFORM_MAX_PATH];
	GetMapName(strMap, sizeof(strMap));
	if(strcmp(strMap, "pl_thundermountain", false) == 0)
	{
		g_nMapHack = MapHack_ThunderMountain;
	}else if(strcmp(strMap, "pl_frontier_final", false) == 0)
	{
		g_nMapHack = MapHack_Frontier;
	}else if(strcmp(strMap, "plr_hightower", false) == 0)
	{
		g_nMapHack = MapHack_Hightower;
	}else if(strcmp(strMap, "plr_hightower_event", false) == 0)
	{
		g_nMapHack = MapHack_HightowerEvent;
	}else if(strcmp(strMap, "plr_pipeline", false) == 0)
	{
		g_nMapHack = MapHack_Pipeline;
	}else if(strcmp(strMap, "plr_nightfall_final", false) == 0)
	{
		g_nMapHack = MapHack_Nightfall;
	}else if(strcmp(strMap, "pl_cactuscanyon", false) == 0)
	{
		g_nMapHack = MapHack_CactusCanyon;
	}else if(strcmp(strMap, "pl_borneo", false) == 0)
	{
		g_nMapHack = MapHack_Borneo;
	}else if(strcmp(strMap, "pl_millstone_event", false) == 0)
	{
		g_nMapHack = MapHack_MillstoneEvent;
	}else if(strcmp(strMap, "pl_barnblitz", false) == 0)
	{
		g_nMapHack = MapHack_Barnblitz;
	}else if(strcmp(strMap, "pl_snowycoast", false) == 0)
	{
		g_nMapHack = MapHack_SnowyCoast;
	}

	g_nGameMode = GameMode_Unknown;
	g_strTrackTrainTargetName[0] = '\0';
	
	// Precache sounds to make sure they will play
	PrecacheSound(SOUND_CART_START);
	PrecacheSound(SOUND_CART_STOP);
	PrecacheSound(SOUND_TANK_WARNING);
	PrecacheSound(SOUND_TANK_DEPLOY);
	PrecacheSound(SOUND_LOSE);
	PrecacheSound(SOUND_ROUND_START);
	PrecacheSound(SOUND_WARNING);
	PrecacheSound(SOUND_DEPLOY_SMALL);
	PrecacheSound(SOUND_DEPLOY_GIANT);
	PrecacheSound(SOUND_GIANT_ROCKET);
	PrecacheSound(SOUND_GIANT_ROCKET_CRIT);
	PrecacheSound(SOUND_BOMB_EXPLODE);
	PrecacheSound(SOUND_RING);
	PrecacheSound(SOUND_GIANT_GRENADE);
	PrecacheSound(SOUND_GIANT_EXPLODE);
	PrecacheSound(SOUND_GIANT_MINIGUN_LOWERING);
	PrecacheSound(SOUND_GIANT_MINIGUN_SPINNING);
	PrecacheSound(SOUND_GIANT_MINIGUN_RAISING);
	PrecacheSound(SOUND_GIANT_MINIGUN_SHOOTING);
	PrecacheSound(SOUND_HOLOGRAM_START);
	PrecacheSound(SOUND_HOLOGRAM_STOP);
	PrecacheSound(SOUND_GIANT_START);
	PrecacheSound(SOUND_EXPLOSION);
	PrecacheSound(SOUND_FIZZLE);
	PrecacheSound(SOUND_DELIVER);
	PrecacheSound(SOUND_BACKSTAB);
	PrecacheSound(SOUND_BUSTER_START);
	PrecacheSound(SOUND_BUSTER_LOOP);
	PrecacheSound(SOUND_BUSTER_SPIN);
	PrecacheSound(SOUND_REANIMATOR_PING);
	PrecacheSound(SOUND_GIANT_RAGE);
	PrecacheSound(SOUND_GIANT_RAGE_DEATH);
	PrecacheSound(SOUND_TELEPORT);
	PrecacheSound(SOUND_TANK_RANKUP);
	PrecacheSound(SOUND_DEATHPIT_BOOST);
	PrecacheSound(SOUND_SUPERSPY_HINT);

	for(int i=0; i<sizeof(g_soundBombFinalWarning); i++) PrecacheSound(g_soundBombFinalWarning[i]);

	for(int i=0; i<sizeof(g_strSoundRobotFootsteps); i++)
	{
		PrecacheSound(g_strSoundRobotFootsteps[i]);
	}
	
	for(int i=0; i<sizeof(g_strSoundGiantFootsteps); i++)
	{
		PrecacheSound(g_strSoundGiantFootsteps[i]);
	}

	for(int i=0; i<sizeof(g_strSoundBusterFootsteps); i++)
	{
		PrecacheSound(g_strSoundBusterFootsteps[i]);
	}
	
	for(int i=0; i<sizeof(g_strSoundGiantSpawn); i++)
	{
		if(strlen(g_strSoundGiantSpawn[i]))
		{
			PrecacheSound(g_strSoundGiantSpawn[i]);
		}
	}
	
	for(int i=0; i<sizeof(g_strSoundGiantLoop); i++)
	{
		if(strlen(g_strSoundGiantLoop[i]))
		{
			PrecacheSound(g_strSoundGiantLoop[i]);
		}
	}
	
	for(int i=0; i<sizeof(g_strSoundBombPickup); i++)
	{
		if(strlen(g_strSoundBombPickup[i]))
		{
			PrecacheSound(g_strSoundBombPickup[i]);
		}
	}

	for(int i=0; i<sizeof(g_strSoundWaveFirst); i++)
	{
		PrecacheSound(g_strSoundWaveFirst[i]);
	}
	for(int i=0; i<sizeof(g_strSoundWaveMid); i++)
	{
		PrecacheSound(g_strSoundWaveMid[i]);
	}
	for(int i=0; i<sizeof(g_strSoundWaveFinal); i++)
	{
		PrecacheSound(g_strSoundWaveFinal[i]);
	}
	for(int i=0; i<sizeof(g_soundBusterStabbed); i++)
	{
		PrecacheSound(g_soundBusterStabbed[i]);
	}
	for(int i=0; i<sizeof(g_soundArrowImpact); i++) PrecacheSound(g_soundArrowImpact[i]);


	for(int i=0; i<sizeof(g_strSoundTankDestroyedScout); i++) PrecacheSound(g_strSoundTankDestroyedScout[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedSniper); i++) PrecacheSound(g_strSoundTankDestroyedSniper[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedSoldier); i++) PrecacheSound(g_strSoundTankDestroyedSoldier[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedDemoman); i++) PrecacheSound(g_strSoundTankDestroyedDemoman[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedMedic); i++) PrecacheSound(g_strSoundTankDestroyedMedic[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedHeavy); i++) PrecacheSound(g_strSoundTankDestroyedHeavy[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedPyro); i++) PrecacheSound(g_strSoundTankDestroyedPyro[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedSpy); i++) PrecacheSound(g_strSoundTankDestroyedSpy[i]);
	for(int i=0; i<sizeof(g_strSoundTankDestroyedEngineer); i++) PrecacheSound(g_strSoundTankDestroyedEngineer[i]);

	for(int i=0; i<sizeof(g_strSoundCashScout); i++) PrecacheSound(g_strSoundCashScout[i]);
	for(int i=0; i<sizeof(g_strSoundCashSniper); i++) PrecacheSound(g_strSoundCashSniper[i]);
	for(int i=0; i<sizeof(g_strSoundCashSoldier); i++) PrecacheSound(g_strSoundCashSoldier[i]);
	for(int i=0; i<sizeof(g_strSoundCashDemoman); i++) PrecacheSound(g_strSoundCashDemoman[i]);
	for(int i=0; i<sizeof(g_strSoundCashHeavy); i++) PrecacheSound(g_strSoundCashHeavy[i]);
	for(int i=0; i<sizeof(g_strSoundCashPyro); i++) PrecacheSound(g_strSoundCashPyro[i]);
	for(int i=0; i<sizeof(g_strSoundCashSpy); i++) PrecacheSound(g_strSoundCashSpy[i]);
	for(int i=0; i<sizeof(g_strSoundCashEngineer); i++) PrecacheSound(g_strSoundCashEngineer[i]);	

	for(int i=0; i<sizeof(g_strSoundBombDeployedScout); i++) PrecacheSound(g_strSoundBombDeployedScout[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedSniper); i++) PrecacheSound(g_strSoundBombDeployedSniper[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedSoldier); i++) PrecacheSound(g_strSoundBombDeployedSoldier[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedDemoman); i++) PrecacheSound(g_strSoundBombDeployedDemoman[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedMedic); i++) PrecacheSound(g_strSoundBombDeployedMedic[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedHeavy); i++) PrecacheSound(g_strSoundBombDeployedHeavy[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedPyro); i++) PrecacheSound(g_strSoundBombDeployedPyro[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedSpy); i++) PrecacheSound(g_strSoundBombDeployedSpy[i]);
	for(int i=0; i<sizeof(g_strSoundBombDeployedEngineer); i++) PrecacheSound(g_strSoundBombDeployedEngineer[i]);

	for(int i=0; i<sizeof(g_strSoundTankCappedScout); i++) PrecacheSound(g_strSoundTankCappedScout[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedSniper); i++) PrecacheSound(g_strSoundTankCappedSniper[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedSoldier); i++) PrecacheSound(g_strSoundTankCappedSoldier[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedDemoman); i++) PrecacheSound(g_strSoundTankCappedDemoman[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedMedic); i++) PrecacheSound(g_strSoundTankCappedMedic[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedHeavy); i++) PrecacheSound(g_strSoundTankCappedHeavy[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedPyro); i++) PrecacheSound(g_strSoundTankCappedPyro[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedSpy); i++) PrecacheSound(g_strSoundTankCappedSpy[i]);
	for(int i=0; i<sizeof(g_strSoundTankCappedEngineer); i++) PrecacheSound(g_strSoundTankCappedEngineer[i]);

	for(int i=0; i<sizeof(g_strSoundTankDeployingScout); i++) PrecacheSound(g_strSoundTankDeployingScout[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingSniper); i++) PrecacheSound(g_strSoundTankDeployingSniper[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingSoldier); i++) PrecacheSound(g_strSoundTankDeployingSoldier[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingDemoman); i++) PrecacheSound(g_strSoundTankDeployingDemoman[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingMedic); i++) PrecacheSound(g_strSoundTankDeployingMedic[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingHeavy); i++) PrecacheSound(g_strSoundTankDeployingHeavy[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingPyro); i++) PrecacheSound(g_strSoundTankDeployingPyro[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingSpy); i++) PrecacheSound(g_strSoundTankDeployingSpy[i]);
	for(int i=0; i<sizeof(g_strSoundTankDeployingEngineer); i++) PrecacheSound(g_strSoundTankDeployingEngineer[i]);

	for(int i=0; i<sizeof(g_strSoundGiantKillScout); i++) PrecacheSound(g_strSoundGiantKillScout[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillSniper); i++) PrecacheSound(g_strSoundGiantKillSniper[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillSoldier); i++) PrecacheSound(g_strSoundGiantKillSoldier[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillDemoman); i++) PrecacheSound(g_strSoundGiantKillDemoman[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillMedic); i++) PrecacheSound(g_strSoundGiantKillMedic[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillHeavy); i++) PrecacheSound(g_strSoundGiantKillHeavy[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillPyro); i++) PrecacheSound(g_strSoundGiantKillPyro[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillSpy); i++) PrecacheSound(g_strSoundGiantKillSpy[i]);
	for(int i=0; i<sizeof(g_strSoundGiantKillEngineer); i++) PrecacheSound(g_strSoundGiantKillEngineer[i]);

	for(int i=0; i<sizeof(g_strSoundRobotFallDamage); i++) PrecacheSound(g_strSoundRobotFallDamage[i]);

	for(int i=1; i<sizeof(g_strSoundNo); i++)
	{
		if(g_strSoundNo[i][0] != '\0') PrecacheSound(g_strSoundNo[i]);
	}

	// Precache robot models
	for(int i=0; i<sizeof(g_strModelRobots); i++) g_iModelIndexRobots[i] = Tank_PrecacheModel(g_strModelRobots[i]);
	
	// Precache human player model indices
	for(int i=0; i<sizeof(g_strModelHumans); i++) g_iModelIndexHumans[i] = Tank_PrecacheModel(g_strModelHumans[i]);

	// Precache robot gibs.
	for(int i=0; i<sizeof(g_demoBossGibs); i++) Tank_PrecacheModel(g_demoBossGibs[i]);
	for(int i=0; i<sizeof(g_heavyBossGibs); i++) Tank_PrecacheModel(g_heavyBossGibs[i]);
	for(int i=0; i<sizeof(g_pyroBossGibs); i++) Tank_PrecacheModel(g_pyroBossGibs[i]);
	for(int i=0; i<sizeof(g_scoutBossGibs); i++) Tank_PrecacheModel(g_scoutBossGibs[i]);
	for(int i=0; i<sizeof(g_soldierBossGibs); i++) Tank_PrecacheModel(g_soldierBossGibs[i]);
	for(int i=0; i<sizeof(g_spyBossGibs); i++) Tank_PrecacheModel(g_spyBossGibs[i]);
	for(int i=0; i<sizeof(g_sniperBossGibs); i++) Tank_PrecacheModel(g_sniperBossGibs[i]);
	for(int i=0; i<sizeof(g_medicBossGibs); i++) Tank_PrecacheModel(g_medicBossGibs[i]);
	for(int i=0; i<sizeof(g_engyBossGibs); i++) Tank_PrecacheModel(g_engyBossGibs[i]);

	Tank_PrecacheModel(MODEL_ROBOT_HOLOGRAM);

	for(int i=0; i<sizeof(g_entitiesOfInterest); i++) g_entitiesOfInterest[i] = Interest_None;
	
	// Precache currency models so they don't have to late precache
	Tank_PrecacheModel("models/items/currencypack_large.mdl");
	Tank_PrecacheModel("models/items/currencypack_medium.mdl");
	Tank_PrecacheModel("models/items/currencypack_small.mdl");
	// Precache flagtrail for the bomb, even though the trail_effect is set to 3 (color only)
	PrecacheGeneric("materials/effects/flagtrail_blu.vmt");
	PrecacheGeneric("materials/effects/flagtrail_red.vmt");

	Tank_PrecacheModel(MODEL_BOMB);
	Tank_PrecacheModel(MODEL_REVIVE_MARKER);

	Tank_PrecacheModel(MODEL_TANK);
	Tank_PrecacheModel(MODEL_TRACK_L);
	Tank_PrecacheModel(MODEL_TRACK_R);
	Tank_PrecacheModel(MODEL_TANK_STATIC);

	g_modelRomevisionTank = Tank_PrecacheModel(MODEL_ROMEVISION_TANK);
	g_modelRomevisionTrackL = Tank_PrecacheModel(MODEL_ROMEVISION_TRACK_L);
	g_modelRomevisionTrackR = Tank_PrecacheModel(MODEL_ROMEVISION_TRACK_R);
	Tank_PrecacheModel(MODLE_ROMEVISION_STATIC);

	Timers_KillAll();

	g_flTimeRoundStarted = 0.0;
	g_bHasPlayers = false;
	g_bIsInNaturalRound = false;
	g_bIsScramblePending = false;
	g_overrideSound = false;
	g_timeLastRobotDamage = 0.0;
	g_hitWithScorchShot = 0;
	g_iRefRoundControlPoint = 0;
	g_timePlayedDestructionSound = 0.0;

	Reanimator_Cleanup();
	Spawner_Cleanup();

	g_iParticleHealRadius = Particle_GetTableIndex("medic_healradius_red_buffed");
	g_iParticleBotImpactLight = Particle_GetTableIndex("bot_impact_light");
	g_iParticleBotImpactHeavy = Particle_GetTableIndex("bot_impact_heavy");
	g_iParticleTeleport = Particle_GetTableIndex("pyro_blast_warp");
	g_iParticleFireworks[TFTeam_Red] = Particle_GetTableIndex("utaunt_firework_teamcolor_red");
	g_iParticleFireworks[TFTeam_Blue] = Particle_GetTableIndex("utaunt_firework_teamcolor_blue");
	g_iParticleFetti = Particle_GetTableIndex("bday_confetti");
	g_iParticleBotDeath = Particle_GetTableIndex("bot_death");
	g_iParticleJumpRed = Particle_GetTableIndex("spell_cast_wheel_red");
	g_iParticleJumpBlue = Particle_GetTableIndex("spell_cast_wheel_blue");

	g_iSpriteBeam = Tank_PrecacheModel("materials/sprites/laser.vmt");
	g_iSpriteHalo = Tank_PrecacheModel("materials/sprites/halo01.vmt");

	Giant_LoadTemplates();

	config.refresh();
	g_giantTracker.prune();
}

public void OnPluginEnd()
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Attributes_Clear(i);
			if(g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot) Giant_Clear(i);
		}
	}

	Spawner_Cleanup();

	// Stops the tank from exploding whenever the plugin is reloaded
	for(int team=2; team<=3; team++)
	{
		int iTank = EntRefToEntIndex(g_iRefTank[team]);
		if(iTank > MaxClients)
		{
			AcceptEntityInput(iTank, "Kill");
		}
	}

	Bomb_KillTimer();

	// Unload the memory patches.
	Mod_Toggle(false);
}

public void OnConfigsExecuted()
{
	Tip_ResetTimer();

	g_bEnabled = false;
	if(Mod_CanBeLoaded())
	{
		g_bEnabled = true;
		Mod_DetermineGameMode();
	}
	Mod_Toggle(g_bEnabled);
}

void Tip_ResetTimer()
{
	if(g_timerTip != INVALID_HANDLE)
	{
		KillTimer(g_timerTip);
		g_timerTip = INVALID_HANDLE;
	}

	float time = config.LookupFloat(g_hCvarTimeTip);
	if(time > 0.0)
	{
		g_timerTip = CreateTimer(time, Timer_ShowTip, _, TIMER_REPEAT);
	}
}

public void ConVarChanged_ChatTips(ConVar convar, char[] oldValue, char[] newValue)
{
	Tip_ResetTimer();
}

public void OnClientDisconnect(int client)
{
	// Check if a giant robot has disconnected, this will ensure that looping sounds are stopped
	if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot)
	{
		Giant_Clear(client, GiantCleared_Disconnect);
	}

	for(int i=0; i<MAX_TEAMS; i++)
	{
		g_iDamageStatsTank[client][i] = 0;
		g_iDamageAccul[client][i] = 0;
	}

	StatsGiant_Reset(client);

	g_hasSpawnedOnce[client] = false;
	g_flTimeCashPickup[client] = 0.0;
	g_flHasShield[client] = 0.0;
	g_lastClientTick[client] = 0.0;
	g_timeGiantEnteredDeathpit[client] = 0.0;

	g_bBusterPassed[client] = false;
	g_bBusterUsed[client] = false;

	Reanimator_Cleanup(client);
	Spawner_Cleanup(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!g_bEnabled) return Plugin_Continue;

	g_lastClientTick[client] = GetEngineTime();

	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			int team = GetClientTeam(client);
			TFClassType class = TF2_GetPlayerClass(client);

			// Moniter the medic shield effect to make sure it gets placed and expires on the client
			if(g_flHasShield[client] != 0.0)
			{
				// Check if the shield should be expired
				if(GetEngineTime() - g_flHasShield[client] > TIME_SHIELD_EXPIRE)
				{
					// Should be expired
					g_flHasShield[client] = 0.0;
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0); // Remove any rage so they can't pop a shield later
				}else{
					// Not expired yet - try activating the shield on the player
					int iWeaponActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(iWeaponActive > MaxClients)
					{
						// Make sure the medigun is active
						char strClass[20];
						GetEdictClassname(iWeaponActive, strClass, sizeof(strClass));
						if(strcmp(strClass, "tf_weapon_medigun") == 0)
						{
							if(!GetEntProp(client, Prop_Send, "m_bRageDraining"))
							{
								// Rage isn't draining yet so try and apply the shield
								buttons |= IN_ATTACK3; // CWeaponMedigun::ItemPostFrame will check for this button and activate the medigun shield!
								SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
							}else{
								// Rage is draining which means the player got their shield, our work is done
								g_flHasShield[client] = 0.0;
							}
						}
					}
				}
			}

			if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				// Transmit the giant to the entire server to prevent PVS cull.
				int iFlags = GetEdictFlags(client);
				if(!(iFlags & FL_EDICT_ALWAYS))
				{
					iFlags |= FL_EDICT_ALWAYS;
					SetEdictFlags(client, iFlags);
				}

				// If we are hightower, we need to remove the outline when the giant uses the invis spell.
				if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
				{
					// m_bGlowEnabled should only be set on non-spy giants in plr mode.
					if(g_nGameMode == GameMode_Race && class != TFClass_Spy)
					{
						if(TF2_IsPlayerInCondition(client, TFCond_Stealthed))
						{
							SetEntProp(client, Prop_Send, "m_bGlowEnabled", false);
						}else{
							SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
						}
					}
				}

				// Apply "cap-health" rule set in the giant template.
				if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot)
				{
					float mult = g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_flGiantCapHealth];
					if(mult > 0.0)
					{
						int cap = RoundToNearest(float(SDK_GetMaxHealth(client)) * mult);
						if(GetClientHealth(client) > cap)
						{
							SetEntityHealth(client, cap);
						}
					}
				}

				if(Spawner_HasGiantTag(client, GIANTTAG_MEDIC_AOE))
				{
					Giant_PulseMedicRadiusHeal(client);
				}

				if(Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER))
				{
					// Disable the use of the sentry buster's caber
					int iMelee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
					if(iMelee > MaxClients)
					{
						SetEntPropFloat(iMelee, Prop_Send, "m_flNextPrimaryAttack", 99999999.0);
					}

					// Cancels out medic health regeneration on medic sentry busters.
					if(class == TFClass_Medic)
					{
						SetEntPropFloat(client, Prop_Send, "m_flLastDamageTime", GetEngineTime());
						if(g_offset_m_medicRegenMult > 0) SetEntDataFloat(client, g_offset_m_medicRegenMult, 0.0);
					}

					// Make attack cause the player to taunt and self-destruct
					// Prevent the bomb becoming armed as soon as they spawn
					if(g_nSpawner[client][g_flSpawnerTimeSpawned] != 0.0 && GetEngineTime() - g_nSpawner[client][g_flSpawnerTimeSpawned] > 2.5 && buttons & IN_ATTACK)
					{
						FakeClientCommand(client, "taunt");
					}

					// Detect a successful taunt
					if(g_flTimeBusterTaunt[client] != 0.0 && GetEngineTime() - g_flTimeBusterTaunt[client] > TIME_BUSTER_EXPLODE)
					{
#if defined DEBUG
						PrintToServer("(OnPlayerRunCmd) Self-destruct started on %N!", client);
#endif
						// Buster is armed and enough time has passed, go BOOM!
						Buster_Explode(client);

						g_flTimeBusterTaunt[client] = 0.0;
					}

					// Show a hint to Giants if a Sentry Buster gets too close letting them know they can swat them away.
					float busterPos[3];
					GetClientAbsOrigin(client, busterPos);
					for(int i=1; i<=MaxClients; i++)
					{
						if(i != client && g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[i][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) && g_nGiants[g_nSpawner[i][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_MELEE_KNOCKBACK && !g_nSpawner[i][g_bSpawnerShownReminder][SpawnerReminder_BusterSwat]
							&& IsClientInGame(i) && GetEntProp(i, Prop_Send, "m_bIsMiniBoss") && IsPlayerAlive(i) && GetClientTeam(i) != team)
						{
							float giantPos[3];
							GetClientAbsOrigin(i, giantPos);
							if(GetVectorDistance(busterPos, giantPos) < 350.0)
							{
								// Sentry Buster is invading the Giant's personal space.
								g_nSpawner[i][g_bSpawnerShownReminder][SpawnerReminder_BusterSwat] = true;

								Handle event = CreateEvent("show_annotation");
								if(event != INVALID_HANDLE)
								{
									SetEventInt(event, "id", Annotation_GiantBusterSwat+i-1);
									SetEventInt(event, "follow_entindex", client);
									SetEventInt(event, "visibilityBitfield", (1 << i)); // Only show to the one Giant.

									char text[256];
									Format(text, sizeof(text), "%T", "Tank_Annotation_Giant_SwatBuster", i);
									SetEventString(event, "text", text);

									SetEventFloat(event, "lifetime", 5.0);
									SetEventString(event, "play_sound", "misc/null.wav");
									
									FireEvent(event); // Frees the handle.
								}
							}
						}
					}
				}
				
				if(Spawner_HasGiantTag(client, GIANTTAG_CAN_DROP_BOMB) && g_nGameMode == GameMode_BombDeploy && class == TFClass_Spy)
				{
					// Drop the bomb automatically so the player can cloak easily.
					if(buttons & IN_ATTACK2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						int bomb = EntRefToEntIndex(g_iRefBombFlag);
						if(bomb > MaxClients && GetEntPropEnt(bomb, Prop_Send, "moveparent") == client)
						{
							int watch = GetPlayerWeaponSlot(client, WeaponSlot_InvisWatch);
							if(watch > MaxClients && GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") != ITEM_DEAD_RINGER)
							{
								AcceptEntityInput(bomb, "ForceDrop");
								//FakeClientCommand(client, "dropitem");
							}
						}
					}

					// Drop the bomb automatically so the player can disguise easily.
					if((impulse >= 221 && impulse <= 229) || (impulse >= 231 && impulse <= 239))
					{
						int bomb = EntRefToEntIndex(g_iRefBombFlag);
						if(bomb > MaxClients && GetEntPropEnt(bomb, Prop_Send, "moveparent") == client)
						{
							AcceptEntityInput(bomb, "ForceDrop");
						}						
					}
				}

				// Keep track of the last time when a player heals a giant.
				if(!Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER))
				{
					char className[20];
					for(int i=1; i<=MaxClients; i++)
					{
						if(i != client && IsClientInGame(i) && GetClientTeam(i) == team && TF2_GetPlayerClass(i) == TFClass_Medic)
						{
							int medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
							if(medigun > MaxClients)
							{
								GetEdictClassname(medigun, className, sizeof(className));
								if(strcmp(className, "tf_weapon_medigun") == 0)
								{
									if(GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == client)
									{
										g_timeLastHealedGiant[i] = GetEngineTime();
									}
								}
							}
						}
					}
				}

				// The Super Spy receives a speed and jump height bonus while cloaked.
				if(Spawner_HasGiantTag(client, GIANTTAG_CAN_DROP_BOMB) && class == TFClass_Spy)
				{
					float value;
					if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						if(!Tank_GetAttributeValue(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS, value) || !Float_AlmostEqual(value, config.LookupFloat(g_hCvarSuperSpyMoveSpeed)))
						{
							Tank_SetAttributeValue(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS, config.LookupFloat(g_hCvarSuperSpyMoveSpeed));
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
						}
						Tank_SetAttributeValue(client, ATTRIB_MAJOR_INCREASED_JUMP_HEIGHT, config.LookupFloat(g_hCvarSuperSpyJumpHeight));
					}else{
						// Player is not cloaked.
						if(Tank_GetAttributeValue(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS, value))
						{
							Tank_RemoveAttribute(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS);
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
						}
						Tank_RemoveAttribute(client, ATTRIB_MAJOR_INCREASED_JUMP_HEIGHT);
					}
				}

				// Increase the scale of the Giant's hands while un-disguised.
				if(Spawner_HasGiantTag(client, GIANTTAG_THE_DONALD))
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
					{
						SetEntPropFloat(client, Prop_Send, "m_flHandScale", 1.0);
					}else{
						SetEntPropFloat(client, Prop_Send, "m_flHandScale", config.LookupFloat(g_hCvarGiantHandScale));
					}
				}

				// Block the giant from being spooked by the HHH.
				if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
				{
					// The stun flags for the HHH scare: 192 (TF_STUNFLAGS_GHOSTSCARE)
					// The stun flags for a regular ghost scare: 193 (TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_SLOWDOWN)
					if(GetEntProp(client, Prop_Send, "m_iStunFlags") == TF_STUNFLAGS_GHOSTSCARE && GetEntPropEnt(client, Prop_Send, "m_hStunner") == -1)
					{
#if defined DEBUG
						PrintToServer("(OnPlayerRunCmd) Cancelling out stun to giant %N!", client);
#endif
						TF2_RemoveCondition(client, TFCond_Dazed);
					}
				}

				// Remind the Super Spy when his health is low that he can regenerate health by backstabbing.
				if(Spawner_HasGiantTag(client, GIANTTAG_BLOCK_HEALONHIT) && class == TFClass_Spy && !g_nSpawner[client][g_bSpawnerShownReminder][SpawnerReminder_SuperSpyLowHealth])
				{
					if(float(GetClientHealth(client)) / float(SDK_GetMaxHealth(client)) < 0.5)
					{
						g_nSpawner[client][g_bSpawnerShownReminder][SpawnerReminder_SuperSpyLowHealth] = true;

						EmitSoundToClient(client, SOUND_SUPERSPY_HINT);
						PrintCenterText(client, "%t", "Tank_Center_SuperSpyHint");
					}
				}
			}

			// Detect whenever a spy changes disguises and update their model overrides
			if(class == TFClass_Spy)
			{
				int iDisguisedClass = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
				int iDisguisedTeam = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
				if(g_nDisguised[client][g_iDisguisedClass] != iDisguisedClass || g_nDisguised[client][g_iDisguisedTeam] != iDisguisedTeam)
				{
					if(iDisguisedClass == 0 && iDisguisedTeam == 0)
					{
						ModelOverrides_Clear(client);
					}else{
						ModelOverrides_Think(client, iDisguisedClass, iDisguisedTeam);

						g_nDisguised[client][g_iDisguisedClass] = iDisguisedClass;
						g_nDisguised[client][g_iDisguisedTeam] = iDisguisedTeam;
					}
				}
			}

			// The running animation is backwards on the robot demoman model.
			// To fix this, force the primary grenade launcher animation all the time while the robot demoman has the sticky launcher out.
			if(config.LookupBool(g_hCvarRobot))
			{
				if(class == TFClass_DemoMan && (g_nGameMode == GameMode_Race || team == TFTeam_Blue))
				{
					int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
					if(secondary > MaxClients && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == secondary)
					{
						// Do not override the bomb deploy animation.
						bool planting = false;
						if(g_nGameMode == GameMode_BombDeploy && g_iBombPlayerPlanting > 0 && client == GetClientOfUserId(g_iBombPlayerPlanting))
						{
							planting = true;
						}

						// We chose this sequence because it is longer than Stand_PRIMARY.
						if(!planting) SDK_PlaySpecificSequence(client, "Stand_SECONDARY");
					}
				}

				if(class == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Disguised))
				{
					// Fix the animation when the spy disguises as a robot demo.
					TFClassType disguiseClass = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
					if(disguiseClass == TFClass_DemoMan && (g_nGameMode == GameMode_Race || GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == TFTeam_Blue))
					{
						// Check that the spy disguised as a demo with the sticky launcher out
						int disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
						if(disguiseWeapon > MaxClients && GetEntProp(disguiseWeapon, Prop_Send, "m_iPrimaryAmmoType") == 2)
						{
							if(g_nGameMode == GameMode_Race || team == TFTeam_Blue)
							{
								// Disguising with the ROBOT spy model
								SDK_PlaySpecificSequence(client, "Stand_SECONDARY");
							}else{
								// Disguising with the HUMAN spy model
								SDK_PlaySpecificSequence(client, "PDA_run_fire"); // This sequence index on the regular spy model corresponds to the Stand_SECONDARY index on the robot model.
								// It'll look messed up for teammates but that is not important.
							}
						}
					}
				}
			}
		}
	}	
	
	return Plugin_Continue;
}

public void Event_RoundStart(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_RoundStart)");
#endif

	if(!g_bEnabled) return;

	g_bIsRoundStarted = false;
	g_bIsFinale = true;
	g_flTimeRoundStarted = GetEngineTime();
	g_bHasPlayers = false;
	g_bIsInNaturalRound = true;
	g_bRaceIntermission = false;
	g_isRaceInOvertime = false;
	g_flTimeIntermissionEnds = 0.0;
	g_bCactusTrainOnce = false;
	g_hellTeamWinner = 0;
	g_finalBombDeployer = 0;
	for(int i=0; i<MAXPLAYERS+1; i++)
	{
		g_iReanimatorNumRevives[i] = 0;
		g_bBusterPassed[i] = false;
		g_bBusterUsed[i] = false;
		g_timeLastHealedGiant[i] = 0.0;
	}
	for(int i=0; i<MAX_NUM_TEMPLATES; i++) for(int a=0; a<MAX_TEAMS; a++) g_iNumGiantSpawns[a][i] = 0;
	for(int i=0; i<MAX_TEAMS; i++)
	{
		g_playedFinalStretch[i] = false;
	}

	Mod_DetermineGameMode();

	if(g_nGameMode == GameMode_Tank) Tournament_RestoreNames();
	Giant_LoadTemplates();

	Tank_BombDeployHud(false);

	// Remove any lingering resources from the map
	Tank_CleanUp();
	HealthBar_Hide();
	Bomb_KillTimer();
	Bomb_ClearMoveBonus();
	Reanimator_Cleanup();
	Spawner_Cleanup();
	Buster_Cleanup(TFTeam_Blue);
	Buster_Cleanup(TFTeam_Red);
	Giant_Cleanup(TFTeam_Blue);
	Giant_Cleanup(TFTeam_Red);
	GiantTeleporter_Cleanup(TFTeam_Red);
	GiantTeleporter_Cleanup(TFTeam_Blue);
	Stats_Reset();
	CaptureTriggers_Cleanup(TFTeam_Blue);
	CaptureZones_Cleanup(TFTeam_Blue);
	Tank_KillFakeTank(TFTeam_Red);
	Tank_KillFakeTank(TFTeam_Blue);
	RageMeter_Cleanup();
	Announcer_Reset();

	Timers_KillAll();

	// Find the model of the payload cart itself, usually a "prop_phyiscs_*", but can be prop_dynamic, depends on the map
	Train_FindProps();

	// The teams have just been scrambled so notify all the players with a sound when the round starts
	if(g_bIsScramblePending)
	{
		g_bIsScramblePending = false;

		Handle hEventSound = CreateEvent("teamplay_broadcast_audio");
		if(hEventSound != INVALID_HANDLE)
		{
			SetEventInt(hEventSound, "team", 255);
			SetEventString(hEventSound, "sound", "Announcer.AM_TeamScrambleRandom");
			SetEventInt(hEventSound, "additional_flags", 0);
			FireEvent(hEventSound); // this closes the handle
		}
	}
}

int Watcher_GetNumControlPoints(int team)
{
	// Count the number of control points for the stage
	// This will NOT include the start and goal checkpoints
	int iNumControlPoints = 0;

	for(int i=0; i<MAX_LINKS; i++)
	{
		if(g_iRefLinkedCPs[team][i] != 0 && EntRefToEntIndex(g_iRefLinkedCPs[team][i]) > MaxClients)
		{
			iNumControlPoints++;
		}
	}

	iNumControlPoints -= 1; // don't count the goal control point
	if(iNumControlPoints < 0) iNumControlPoints = 0;
	
	return iNumControlPoints;
}

void Mod_Disable()
{
	Mod_Toggle(false);

	g_bEnabled = false;
	ServerCommand("mp_restartgame 2");

	PrintToChatAll("%t", "Tank_Chat_FailToLoad", 0x01, g_strTeamColors[TFTeam_Blue], 0x01);
	LogMessage("Stop that Tank! has failed to load and has been disabled. Restart the map to reload the mod.");
}

public void Event_RoundActive(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_RoundActive)");
#endif
	if(!g_bEnabled) return;

	if(!GetConVarBool(g_hCvarEnabled))
	{
		LogMessage("(Event_RoundActive) tank_enabled set to 0, disabling Stop that Tank!..");
		Mod_Disable();
		return;
	}

	// Find BLUE's team_train_watcher
	if(Tank_FindTrainWatcher(TFTeam_Blue) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find BLUE team_train_watcher entity, disabling plugin!");
		Mod_Disable();
		return;
	}

	// Find RED's team_train_watcher (if we find it, we must be playing plr_)
	if(g_nGameMode == GameMode_Race)
	{
		int iWatcherRed = Tank_FindTrainWatcher(TFTeam_Red);
		if(iWatcherRed <= MaxClients)
		{
			LogMessage("(Event_RoundActive) Failed to find RED's team_train_watcher, disabling plugin!");
			Mod_Disable();
			return;
		}
	}

	// Find the main payload entity
	int iTrackTrainBlue = Tank_FindTrackTrain(TFTeam_Blue);
	if(iTrackTrainBlue <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find BLU's func_tracktrain, disabling plugin!");
		Mod_Disable();
		return;
	}

	if(g_nGameMode == GameMode_Race)
	{
		int iTrackTrainRed = Tank_FindTrackTrain(TFTeam_Red);
		if(iTrackTrainRed <= MaxClients)
		{
			LogMessage("(Event_RoundActive) Failed to find RED's func_tracktrain, disabling plugin!");
			Mod_Disable();
			return;
		}
	}

	Train_FindPropsByPhysConstraint(TFTeam_Blue);
	if(g_nGameMode == GameMode_Race) Train_FindPropsByPhysConstraint(TFTeam_Red);

	Train_FindPropsByParenting(TFTeam_Blue);
	if(g_nGameMode == GameMode_Race) Train_FindPropsByParenting(TFTeam_Red);

	// Find BLUE's first path_track
	if(Tank_FindPathStart(TFTeam_Blue) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find BLUE's starting path_track!");
	}

	// Find RED's first path_track
	if(g_nGameMode == GameMode_Race && Tank_FindPathStart(TFTeam_Red) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find RED's starting path_track!");
	}

	// Find the cart's trigger_capture_area.
	// Find the extra flatbed_tracktrain in pl_frontier_final
	if(g_nMapHack == MapHack_Frontier)
	{
		int iTrackTrain2 = Entity_FindEntityByName("flatbed_tracktrain", "func_tracktrain");
		if(iTrackTrain2 > MaxClients)
		{
			g_iRefTrackTrain2[TFTeam_Blue] = EntIndexToEntRef(iTrackTrain2);

#if defined DEBUG
			PrintToServer("(Event_RoundActive) flatbed_traintrack: %d!", iTrackTrain2);
#endif
		}
	}

	g_iRefTrackTrain2[TFTeam_Red] = 0;
	g_iRefTrackTrain2[TFTeam_Blue] = 0;

	Train_RemoveTriggerStun(TFTeam_Blue);
	if(g_nGameMode == GameMode_Race) Train_RemoveTriggerStun(TFTeam_Red);

	// Hook when giants come activate trigger_teleport entities to prevent them from becoming stuck on the other side.
	int trigger = MaxClients+1;
	while((trigger = FindEntityByClassname(trigger, "trigger_teleport")) > MaxClients)
	{
		HookSingleEntityOutput(trigger, "OnEndTouch", EntityOutput_TriggerTeleport, false);
	}

	if(g_hSDKSetBossHealth != INVALID_HANDLE)
	{
		// Create a hook to block any updating of the boss health bar.
		int bossbar = MaxClients+1;
		while((bossbar = FindEntityByClassname(bossbar, "monster_resource")) > MaxClients)
		{
			DHookEntity(g_hSDKSetBossHealth, false, bossbar); // Don't need to worry if the entity is already hooked.
		}
	}

	// Find BLUE's last path_track
	if(Tank_FindPathGoal(TFTeam_Blue) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find BLUE's path_track goal!");
	}

	// Find RED's last path_track
	if(g_nGameMode == GameMode_Race && Tank_FindPathGoal(TFTeam_Red) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find RED's path_track goal!");
	}

	switch(g_nMapHack)
	{
		case MapHack_Frontier:
		{
			// Find the extra flatbed_tracktrain in pl_frontier_final
			int trackTrain2 = Entity_FindEntityByName("flatbed_tracktrain", "func_tracktrain");
			if(trackTrain2 > MaxClients)
			{
				g_iRefTrackTrain2[TFTeam_Blue] = EntIndexToEntRef(trackTrain2);
				
				// Delete the sparks associated with the func_tracktrain entity
				Train_KillSparks(trackTrain2);
				
				// Teleport it to it's current location just to fix some dispenser trigger area bugs
				float flPos[3];
				GetEntPropVector(trackTrain2, Prop_Send, "m_vecOrigin", flPos);
				TeleportEntity(trackTrain2, flPos, NULL_VECTOR, NULL_VECTOR);
#if defined DEBUG
				PrintToServer("(Event_RoundActive) flatbed_traintrack: %d!", trackTrain2);
#endif
			}

			// Disable the trigger_hurt that kills the player if they stand in front of the cart
			// It's parented to the chew chew prop
			trigger = MaxClients+1;
			while((trigger = FindEntityByClassname(trigger, "trigger_hurt")) > MaxClients)
			{
				int parent = GetEntPropEnt(trigger, Prop_Send, "moveparent");
				if(parent > MaxClients)
				{
					for(int i=0,size=g_trainProps.Length; i<size; i++)
					{
						int array[ARRAY_TRAINPROP_SIZE];
						g_trainProps.GetArray(i, array, sizeof(array));

						int prop = EntRefToEntIndex(array[TrainPropArray_Reference]);
						if(prop > MaxClients && prop == parent)
						{
							AcceptEntityInput(trigger, "Kill");
#if defined DEBUG
							PrintToServer("(Event_RoundActive) Killed trigger_hurt parented to cart: %d!", trigger);
#endif
							break;
						}
					}
				}
			}
		}
		case MapHack_HightowerEvent:
		{
			// This is meant to catch the redmond and blutarch models in plr_hightower_event (they don't exist until halfway through teamplay_round_start and teamplay_round_active)
			int prop = MaxClients+1;
			while((prop = FindEntityByClassname(prop, "prop_dynamic")) > MaxClients)
			{
				char strModel[100];
				GetEntPropString(prop, Prop_Data, "m_ModelName", strModel, sizeof(strModel));		
				
				if(strcmp(strModel, "models/props_trainyard/bomb_blutarch.mdl") == 0 || strcmp(strModel, "models/props_trainyard/bomb_redmond.mdl") == 0)
				{
					Train_AddProp(prop);
				}
			}

			// Disable the hell gates relay so we can trigger it whenever we want.
			int relay = Entity_FindEntityByName(HELL_GATES_TARGETNAME, "logic_relay");
			if(relay != -1)
			{
				AcceptEntityInput(relay, "Disable");
			}else{
				LogMessage("Failed to find \"%s\" entity!", HELL_GATES_TARGETNAME);
			}

			trigger = Entity_FindEntityByName("underworld_skull_zap_hurt", "trigger_hurt");
			if(trigger != -1)
			{
				SetVariantInt(700);
				AcceptEntityInput(trigger, "SetDamage");
			}else{
				LogMessage("Failed to find \"underworld_skull_zap_hurt\" entity!");
			}
		}
		case MapHack_CactusCanyon:
		{
			// Find the train trigger for Stage 3 that surrounds the front of the train
			// We will hook touch and Trigger the crash_relay to end stage 3
			trigger = Entity_FindEntityByName("objective_train_hurt", "trigger_hurt");
			if(trigger > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Found \"objective_train_hurt\", hooking touch: %d!", trigger);
#endif
				// This triggers hurts players that get hit by the front of the train
				SDKHook(trigger, SDKHook_StartTouch, CactusCanyon_TrainTouch);
			}
		}
		case MapHack_Pipeline:
		{
			// Remove the first set of uphill paths near the start on stage 3 for game balance.
			static char paths[][] = {"red_path_c_3", "red_path_c_4", "red_path_c_5", "red_path_c_6",
										"blue_path_c_3", "blue_path_c_4", "blue_path_c_5", "blue_path_c_6",};
			for(int i=0; i<sizeof(paths); i++)
			{
				int path = Entity_FindEntityByName(paths[i], "path_track");
				if(path > MaxClients)
				{
					int flags = GetEntProp(path, Prop_Data, "m_spawnflags");
					flags &= ~PATH_UPHILL;
					SetEntProp(path, Prop_Data, "m_spawnflags", flags);
				}
			}
		}
	}

	// Find the capture areas for the lifts on plr_hightower and disable them
	if(g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent)
	{
		int iTrigger = Entity_FindEntityByName("plr_blu_pushzone_elv", "trigger_capture_area");
		if(iTrigger > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Event_RoundActive) Found trigger_capture_area for plr_hightower. \"plr_blu_pushzone_elv\": %d!", iTrigger);
#endif
			SDKHook(iTrigger, SDKHook_StartTouch, BlockTouch);
		}

		iTrigger = Entity_FindEntityByName("plr_red_pushzone_elv", "trigger_capture_area");
		if(iTrigger > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Event_RoundActive) Found trigger_capture_area for plr_hightower. \"plr_red_pushzone_elv\": %d!", iTrigger);
#endif
			SDKHook(iTrigger, SDKHook_StartTouch, BlockTouch);
		}
	}
	
	// Find the capture area that registers how many player's are pushing the cart and block touch
	if(Tank_HookCaptureTrigger(TFTeam_Blue) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find BLUE's capture trigger!");
	}

	if(g_nGameMode == GameMode_Race && Tank_HookCaptureTrigger(TFTeam_Red) <= MaxClients)
	{
		LogMessage("(Event_RoundActive) Failed to find RED's capture trigger!");
	}
	
	// Check for any map-related config settings.
	MapLogic_Init();

	// Reload the config file now that entity data has been populated.
	config.refresh();
	config.spawnProps();

	// Teleport both team's carts to the starting path_track node defined in the team's train watcher.
	for(int team=2; team<=3; team++)
	{
		Handle cvar = g_hCvarTeleportStartRed;
		if(team == TFTeam_Blue) cvar = g_hCvarTeleportStartBlue;

		char value[64];
		config.LookupString(cvar, value, sizeof(value));
		if(strcmp(value, "disabled", false) == 0) continue;

		int train = EntRefToEntIndex(g_iRefTrackTrain[team]);
		if(train <= MaxClients) continue;

		if(strlen(value) <= 0)
		{
			// tank_teleport_start* was left blank so teleport the cart to the start_node set from the active team_train_watcher.
			int pathStart = EntRefToEntIndex(g_iRefPathStart[team]);
			if(pathStart > MaxClients)
			{
				SetVariantFloat(0.0);
				AcceptEntityInput(train, "SetSpeed");

				SetVariantEntity(pathStart);
				AcceptEntityInput(train, "TeleportToPathTrack");
			}
		}else{
			// Attempt to find the targetname of the path_track node provided and teleport the func_tracktrain to it.
			int path = Entity_FindEntityByName(value, "path_track");
			if(path > MaxClients)
			{
				g_iRefPathStart[team] = EntIndexToEntRef(path);

				SetVariantFloat(0.0);
				AcceptEntityInput(train, "SetSpeed");

				SetVariantEntity(path);
				AcceptEntityInput(train, "TeleportToPathTrack");
			}else{
				LogMessage("Failed to find path_track \"%s\" set in cfg. The cart will not be teleported on round start.");
			}
		}
	}

	switch(g_nMapHack)
	{
		case MapHack_Frontier:
		{
			// Find the extra flatbed_tracktrain in pl_frontier_final
			int trackTrain2 = EntRefToEntIndex(g_iRefTrackTrain2[TFTeam_Blue]);
			if(trackTrain2 > MaxClients)
			{
				// Set the max of the flatbed, set it slightly faster so it doesn't get too far behind
				SetEntPropFloat(trackTrain2, Prop_Data, "m_maxSpeed", config.LookupFloat(g_hCvarMaxSpeed));
			}
		}
	}

	// For the finale, have the tank deploy and explode
	// For multi-stage maps, the tank needs to stay put.
	char finale[8];
	g_bIsFinale = true;
	config.LookupString(g_hCvarFinaleDefault, finale, sizeof(finale));
	if(strcmp(finale, "no", false) == 0)
	{
		// Current stage is not the finale.
		g_bIsFinale = false;
	}
#if defined DEBUG
	PrintToServer("(Event_RoundActive) Finale: %d!", g_bIsFinale);
#endif

	// Set the total distance of the path and store it for later
	g_flPathTotalDistance[TFTeam_Blue] = Path_GetTotalDistance(TFTeam_Blue);
#if defined DEBUG
	PrintToServer("(Event_RoundActive) BLUE track distance: %0.2f!", g_flPathTotalDistance[TFTeam_Blue]);
#endif
	if(g_nGameMode == GameMode_Race)
	{
		g_flPathTotalDistance[TFTeam_Red] = Path_GetTotalDistance(TFTeam_Red);
#if defined DEBUG
		PrintToServer("(Event_RoundActive) RED track distance: %0.2f!", g_flPathTotalDistance[TFTeam_Red]);
#endif
	}

	// Determine how many tanks will spawn during a round
	g_iNumTankMaxSimulated = (RoundToNearest(g_flPathTotalDistance[TFTeam_Blue]) / config.LookupInt(g_hCvarCheckpointDistance)) + 1;
#if defined DEBUG
	PrintToServer("(Event_RoundActive) Max CPs: %d, Sim. Tanks: %d!", g_iMaxControlPoints[TFTeam_Blue], g_iNumTankMaxSimulated);
#endif


	// Spawn a 'fake' tank in place of the actual tank before the game begins.
	// This will keep spawn exits open and make it more difficult to hide stickies around the tank.
	Tank_CreateFakeTank(TFTeam_Blue, true);
	if(g_nGameMode == GameMode_Race) Tank_CreateFakeTank(TFTeam_Red, true);

	// Get rid of the mapobj_cart_dispenser and spawn our own with increased range
	Train_RemoveAllDispensers();
	Train_ReplaceDispenser(TFTeam_Blue);
	if(g_nGameMode == GameMode_Race) Train_ReplaceDispenser(TFTeam_Red);

	// Check to see if there's a setup time or not
	bool bFoundTimer = false;
	int iTimer = MaxClients+1;
	while((iTimer = FindEntityByClassname(iTimer, "team_round_timer")) > MaxClients)
	{
		if(!GetEntProp(iTimer, Prop_Send, "m_bIsDisabled", 1))
		{
			//PrintToServer("m_nState = %d m_nSetupTimeLength = %d", GetEntProp(iTimer, Prop_Send, "m_nState"), GetEntProp(iTimer, Prop_Send, "m_nSetupTimeLength"));
			// There's a bug with the team_round_timer in pipeline's 3rd stage
			if(g_nMapHack == MapHack_Pipeline && g_bIsFinale)
			{
				SetVariantInt(3);
				AcceptEntityInput(iTimer, "SetSetupTime");
			}

			bFoundTimer = true;
		}
	}

	if(!bFoundTimer)
	{
		// There's no team_round_timer so we'll assume that there's no setup time, launch the round
#if defined DEBUG
		PrintToServer("(Event_RoundActive) No team_round_timer found, assuming no setup so launching round..");
#endif
		Event_SetupFinished(INVALID_HANDLE, "teamplay_setup_finished", false);
	}

#if defined DEBUG
		PrintToServer("(Event_RoundActive) Number of train props: %d", g_trainProps.Length);
#endif
}

void Train_RemoveTriggerStun(int team)
{
	int train = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(train >= MaxClients)
	{
		int trigger = MaxClients+1;
		while((trigger = FindEntityByClassname(trigger, "trigger_stun")) > MaxClients)
		{
			if(GetEntPropEnt(trigger, Prop_Send, "moveparent") == train)
			{
#if defined DEBUG
				PrintToServer("(Train_RemoveTriggerStun) Removing \"trigger_stun\" (%d) that is parented to team %d's cart (%d)..", trigger, team, train);
#endif
				AcceptEntityInput(trigger, "Kill");
			}
		}
	}
}

void Train_RemoveAllDispensers()
{
	// Frontier has a nice little dispenser_touch_trigger around the flatbed func_tracktrain so expanding it isn't really needed
	if(g_nMapHack == MapHack_Frontier) return;
	
	int iDispenser = MaxClients+1;
	while((iDispenser = FindEntityByClassname(iDispenser, "mapobj_cart_dispenser")) > MaxClients)
	{
		// We could check if it's parented to the cart, but I don't think its necessary
		char strTriggerName[100];
		GetEntPropString(iDispenser, Prop_Data, "m_iszCustomTouchTrigger", strTriggerName, sizeof(strTriggerName));
		if(strTriggerName[0] != '\0')
		{

			int iTouch = Entity_FindEntityByName(strTriggerName, "dispenser_touch_trigger");
			if(iTouch > MaxClients)
			{
				AcceptEntityInput(iTouch, "Kill");
#if defined DEBUG
				PrintToServer("(Train_RemoveDispenser) Removed dispenser_touch_trigger: %d!", iTouch);
#endif
			}
		}

		AcceptEntityInput(iDispenser, "Kill");
#if defined DEBUG
		PrintToServer("(Train_RemoveDispenser) Removed mapobj_cart_dispenser: %d!", iDispenser);
#endif
	}
}

void Train_ReplaceDispenser(int team)
{
	// Frontier has a nice little dispenser_touch_trigger around the flatbed func_tracktrain so expanding it isn't really needed
	if(g_nMapHack == MapHack_Frontier) return;
	
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iTrackTrain <= MaxClients)
	{
		LogMessage("Failed to replace dispenser: Missing func_tracktrain!");
		return;
	}
	
	int iDispenser;
	// Check to see if the old dispenser survived the round somehow
	if(g_iRefDispenser[team] != 0)
	{
		iDispenser = EntRefToEntIndex(g_iRefDispenser[team]);
		if(iDispenser > MaxClients)
		{
			AcceptEntityInput(iDispenser, "Kill");
		}
		
		g_iRefDispenser[team] = 0;
	}
	if(g_iRefDispenserTouch[team] != 0)
	{
		// Although the dispenser probably takes care of this when it's removed
		iDispenser = EntRefToEntIndex(g_iRefDispenserTouch[team]);
		if(iDispenser > MaxClients)
		{
			AcceptEntityInput(iDispenser, "Kill");
		}
		
		g_iRefDispenserTouch[team] = 0;
	}
	
	// Spawn a new dispenser at the func_tracktrain
	g_iCreatingCartDispenser = team;
	iDispenser = CreateEntityByName("mapobj_cart_dispenser");
	if(iDispenser > MaxClients && IsValidEntity(iDispenser))
	{
		char strTeam[5];
		IntToString(team, strTeam, sizeof(strTeam));
		DispatchKeyValue(iDispenser, "TeamNum", strTeam);

		DispatchSpawn(iDispenser);
		
		float flPos[3];
		GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += 50.0;
		TeleportEntity(iDispenser, flPos, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantInt(team);
		AcceptEntityInput(iDispenser, "SetTeam");
		
		ActivateEntity(iDispenser);
		
		SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", 65);
		SetEntProp(iDispenser, Prop_Send, "m_iHealth", 150);
		SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", 150);
		SetEntProp(iDispenser, Prop_Send, "m_iObjectType", view_as<int>(TFObject_CartDispenser));
		SetEntProp(iDispenser, Prop_Send, "m_iTeamNum", team);
		SetEntProp(iDispenser, Prop_Send, "m_nSkin", team-2);
		SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", 1);
		SetEntProp(iDispenser, Prop_Send, "m_fObjectFlags", 4);
		SetEntProp(iDispenser, Prop_Data, "m_fFlags", 4);

		//float flDispenserMins[] = {-24.0, -24.0, 0.0};
		float flDispenserMaxs[] = {24.0, 24.0, 55.0};
		SetEntPropVector(iDispenser, Prop_Send, "m_vecBuildMaxs", flDispenserMaxs);
		//SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", client);
		
#if defined DEBUG
		PrintToServer("(Train_ReplaceDispenser) Replaced map dispenser with %d!", iDispenser);
#endif
		g_iRefDispenser[team] = EntIndexToEntRef(iDispenser);
		
		// Increase the size of the dispenser touch so it can effectively heal around the tank
		int iTouch = EntRefToEntIndex(g_iRefDispenserTouch[team]);
		if(iTouch > MaxClients)
		{
			float flMins[3] = {-220.0, -220.0, -220.0};
			float flMaxs[3] = {220.0, 220.0, 220.0};
			SDK_SetSize(iTouch, flMins, flMaxs);
			
			SetVariantString("!activator");
			AcceptEntityInput(iTouch, "SetParent", iTrackTrain);
		}
		
		// Parent both the dispenser and the dispenser trigger to the tank, almost done now!
		SetVariantString("!activator");
		AcceptEntityInput(iDispenser, "SetParent", iTrackTrain);
	}
	g_iCreatingCartDispenser = 0;
	
	// The dispenser_touch_trigger is spawned by the dispenser when it's spawned
}

void Player_FixVaccinator(int client)
{
	if(!config.LookupBool(g_hCvarRobot)) return; // Robot player models are switched off.
	if(GetClientTeam(client) == TFTeam_Red && g_nGameMode != GameMode_Race) return;

	// Makes the backpack part of the vaccinator invisible to prevent stretching when bonemerged with the robot models
	int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
	if(medigun > MaxClients && GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex") == ITEM_VACCINATOR)
	{
		int backpack = GetEntPropEnt(medigun, Prop_Send, "m_hExtraWearable");
		if(backpack > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Player_FixVaccinator) %N, %d..", client, backpack);
#endif
			AcceptEntityInput(backpack, "Kill");

			//SetEntityRenderMode(backpack, RENDER_NONE);
			//SetEntityRenderColor(backpack, _, _, _, 0);
		}
	}	
}

public void Event_Inventory(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	// Mediguns receive an increased ubercharge rate only during the setup period
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		Player_FixVaccinator(client);

		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Engineer: Player_SetDefaultMetal(client);
		}

		// Give the new weapon inspect feature to everyone because why not!
		if(config.LookupInt(g_hCvarWeaponInspect) == 2)
		{
			for(int slot=0; slot<3; slot++)
			{
				int weapon = GetPlayerWeaponSlot(client, slot);
				if(weapon > MaxClients)
				{
					Tank_SetAttributeValue(weapon, ATTRIB_WEAPON_ALLOW_INSPECT, 1.0);
				}
			}
		}
	}
}

public void Event_SetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_SetupFinished)");
#endif

	if(!g_bEnabled) return;

	// Remove the faster ubercharge rate from mediguns whenever setup is completed (even if there's no setup period in the map, this function will still get called).
	Player_RemoveUberChargeBonus();

	// Start the grace period timer
	float graceTime = config.LookupFloat(g_hCvarTimeGrace);
	if(graceTime < 6.0) graceTime = 6.0;

	Timer_KillStart();
	g_hTimerStart = CreateTimer(graceTime-SPAWNER_TIME_TANK, Timer_StartRound, _, TIMER_REPEAT); // The spawning process takes 3s.
	
	g_countdownTime = 5;
	Timer_KillCountdown();
	g_timerCountdown = CreateTimer(graceTime-5.1, Timer_Countdown, _, TIMER_REPEAT);
	
	// Make the timer ago away after setup
	int iTimer = MaxClients+1;
	while((iTimer = FindEntityByClassname(iTimer, "team_round_timer")) > MaxClients)
	{
		if(g_iRefBombTimer != 0 && g_iRefBombTimer == EntIndexToEntRef(iTimer)) continue;

		AcceptEntityInput(iTimer, "Disable");
	}

	Train_Move(TFTeam_Blue, 0.0);
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[TFTeam_Blue]);
	if(iWatcher > MaxClients)
	{
		SetEntPropFloat(iWatcher, Prop_Send, "m_flRecedeTime", GetGameTime()+graceTime);
	}
	Buster_Cleanup(TFTeam_Blue);
	g_nBuster[TFTeam_Blue][g_bBusterActive] = true;

	if(g_nGameMode == GameMode_Race)
	{
		Train_Move(TFTeam_Red, 0.0);
		iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[TFTeam_Red]);
		if(iWatcher > MaxClients)
		{
			SetEntPropFloat(iWatcher, Prop_Send, "m_flRecedeTime", GetGameTime()+graceTime);
		}
		Buster_Cleanup(TFTeam_Red);
		g_nBuster[TFTeam_Red][g_bBusterActive] = true;
	}

	RequestFrame(NextFrame_EndSetup);
}

public void NextFrame_EndSetup(any data)
{
	// Wait a frame to prevent the 'Setup' phrase to appear below the team_round_timer on the HUD during the round.
	GameRules_SetProp("m_bInSetup", false);
}

void Tank_SetDefaultHealth(int team)
{
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	if(iTank <= MaxClients) return;

	switch(g_nGameMode)
	{
		case GameMode_Race:
		{
			// The tank cannot be killed in tank race
			SetEntProp(iTank, Prop_Data, "m_initialHealth", MAX_TANK_HEALTH);
			SetEntProp(iTank, Prop_Data, "m_iMaxHealth", MAX_TANK_HEALTH);
			SetEntProp(iTank, Prop_Data, "m_iHealth", MAX_TANK_HEALTH);

			SetEntProp(iTank, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY); // buddah
		}
		default:
		{
			// Set the tank's starting health and notify players
			float flHealthBase = config.LookupFloat(g_hCvarHealthBase);
			int iNumRedPlayers = CountPlayersOnTeam(TFTeam_Red);
			float flHealthPlayer = float(iNumRedPlayers) * config.LookupFloat(g_hCvarHealthPlayer);
			float flHealthDistance = float(iNumRedPlayers) / float(MaxClients/2) * g_flPathTotalDistance[team] * config.LookupFloat(g_hCvarHealthDistance);
			int iMaxHealthTank = RoundToNearest(flHealthBase + flHealthPlayer + flHealthDistance);
			
			// Apply a final tank max health modifier if requested
			float mapMultiplier = config.LookupFloat(g_hCvarTankHealthMultiplier);
			if(mapMultiplier != 1.0)
			{
				iMaxHealthTank = RoundToNearest(float(iMaxHealthTank) * mapMultiplier);

				// Trims off the trailing zeros left by KeyValues.
				char readable[32];
				config.LookupString(g_hCvarTankHealthMultiplier, readable, sizeof(readable));

				int endingZero = -1;
				for(int i=strlen(readable)-1; i>0; i--)
				{
					if(readable[i] != '0') break;

					endingZero = i;
				}
				if(endingZero != -1) readable[endingZero] = '\0';
				PrintToChatAll("%t", "Tank_Chat_Health_Multiplier", g_strTeamColors[TFTeam_Blue], 0x01, 0x04, readable);				
			}
			
			SetEntProp(iTank, Prop_Data, "m_initialHealth", iMaxHealthTank);
			SetEntProp(iTank, Prop_Data, "m_iMaxHealth", iMaxHealthTank);
			SetEntProp(iTank, Prop_Data, "m_iHealth", iMaxHealthTank);

			PrintToChatAll("%t", "Tank_Chat_Inbound_Single", g_strTeamColors[TFTeam_Blue], 0x01, "\x07CF7336", iMaxHealthTank, 0x01);
#if defined DEBUG
			LogMessage("(Tank_SetDefaultHealth) Tank inbound: %d HP (%0.0f+%0.0f+%0.1f)", iMaxHealthTank, flHealthBase, flHealthPlayer, flHealthDistance);
#endif
		}
	}
}

public Action Timer_StartRound(Handle timer)
{
	// Start the spawning of the tank. When that's finished, the spawner should call Tank_StartRound() below.
	Spawner_Spawn(MAXPLAYERS+TFTeam_Blue, Spawn_Tank);
	if(g_nGameMode == GameMode_Race) Spawner_Spawn(MAXPLAYERS+TFTeam_Red, Spawn_Tank);

	g_hTimerStart = INVALID_HANDLE;
	return Plugin_Stop;
}

void Tank_StartRound()
{
#if defined DEBUG
	PrintToServer("(Tank_StartRound)");
#endif
	if(g_bIsRoundStarted) return;

	// Grace period is over, tank now moves and can be damaged
	g_bIsRoundStarted = true;

	// Cactus canyon's map logic disables the cart's trigger_capture_area (while the elevator is in progress), so go ahead and re-enable it
	if(g_nGameMode != GameMode_Race && g_nMapHack == MapHack_CactusCanyon && g_bIsFinale)
	{
		int iTrigger = EntRefToEntIndex(g_iRefTrigger[TFTeam_Blue]);
		if(iTrigger > MaxClients)
		{
			if(iTrigger > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Timer_StartRound) MAP HACK: Enabling blue's capture area..");
#endif
				AcceptEntityInput(iTrigger, "Enable");
			}
		}
	}

	Tank_SetDefaultHealth(TFTeam_Blue);
	Train_Move(TFTeam_Blue, 1.0);
	Tank_SetNoTarget(TFTeam_Blue, false);
	Player_RemoveUberChargeBonus(); // Fail-safe backup.

	if(g_nGameMode == GameMode_Race)
	{
		g_bRaceIntermission = false;
		g_isRaceInOvertime = false;
		g_flTimeIntermissionEnds = 0.0;
		g_bRaceIntermissionBottom[TFTeam_Red] = false;
		g_bRaceIntermissionBottom[TFTeam_Blue] = false;
		Announcer_SetEnabled(true);

		Tank_SetDefaultHealth(TFTeam_Red);
		Train_Move(TFTeam_Red, 1.0);
		Tank_SetNoTarget(TFTeam_Red, false);

		BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Tank_Alert_Multiple");

		g_numGiantWave = 0;
		RaceTimer_Create();

		PrintToChatAll("%t", "Tank_Chat_Inbound_Multiple", "\x07ADFF2F", 0x01, "\x07ADFF2F", 0x01);
	}else{
		BroadcastSoundToTeam(TFTeam_Red, "Announcer.MVM_Tank_Alert_Spawn");
	}
	BroadcastSoundToTeam(TFTeam_Spectator, "MVM.TankStart");
	
	int iTimer = MaxClients+1;
	while((iTimer = FindEntityByClassname(iTimer, "team_round_timer")) > MaxClients)
	{
		if(g_iRefBombTimer != 0 && g_iRefBombTimer == EntIndexToEntRef(iTimer)) continue;

		AcceptEntityInput(iTimer, "Disable");
	}

	GameRules_SetProp("m_bInSetup", false); // Failsafe
}

void RaceTimer_Create()
{
	// Prevents the words 'Setup' from appearing below the team_round_timer in nightfall stage 3.
	GameRules_SetProp("m_bInSetup", false);

	// Create a HUD timer that will countdown the time until giant robots spawn for both teams
	// After the timer has ended, the plr round would continue like normal
	Bomb_KillTimer();
	g_numGiantWave++;

	int iTimerLength = RoundToNearest(config.LookupFloat(g_hCvarRaceTimeGiantStart)*60.0);			
	if(g_numGiantWave >= 2)
	{
		iTimerLength = RoundToNearest(config.LookupFloat(g_hCvarRaceTimeWave)*60.0);
	}

	if(iTimerLength > 0)
	{
		int iTimer = CreateEntityByName("team_round_timer");
		if(iTimer > MaxClients)
		{
			DispatchKeyValue(iTimer, "targetname", TARGETNAME_GIANTWAVE_TIMER);

			DispatchSpawn(iTimer);

			if(iTimerLength < 30) iTimerLength = 30;
			SetVariantInt(iTimerLength);
			AcceptEntityInput(iTimer, "SetTime");
			
			SetVariantInt(1);
			AcceptEntityInput(iTimer, "ShowInHUD");

			// Prevent the MISSION ENDS IN 60s/30s/10s announcer sounds
			// Countdown will be re-enabled at 10s
			SetVariantInt(0);
			AcceptEntityInput(iTimer, "AutoCountdown", iTimer);

			AcceptEntityInput(iTimer, "Enable");
			
			HookSingleEntityOutput(iTimer, "On30SecRemain", RaceTimer_On30SecRemain, true);
			HookSingleEntityOutput(iTimer, "On10SecRemain", RaceTimer_On10SecRemain, true);
			HookSingleEntityOutput(iTimer, "On3SecRemain", RaceTimer_On3SecRemain, true);
			HookSingleEntityOutput(iTimer, "OnFinished", RaceTimer_OnFinished, true);

#if defined DEBUG
			PrintToServer("(RaceTimer_Create) Created \"team_round_timer\" to countdown giants: %d!", iTimer);
#endif
			g_iRefBombTimer = EntIndexToEntRef(iTimer);

			// For some reason, nightfall stage 3 disables the timer after I create it
			RequestFrame(NextFrame_EnableTimer, g_iRefBombTimer);
		}else{
			LogMessage("Failed to create \"team_round_timer\" to countdown giant robot spawn.");
		}
	}	
}

public void NextFrame_EnableTimer(int iRefTimer)
{
	int iTimer = EntRefToEntIndex(iRefTimer);
	if(iTimer > MaxClients)
	{
		AcceptEntityInput(iTimer, "Enable");

		SetVariantInt(1);
		AcceptEntityInput(iTimer, "ShowInHUD");
	}
}

public void RaceTimer_On30SecRemain(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(RaceTimer_On30SecRemain) caller: %d, activator: %d, g_numGiantWave: %d!", caller, activator, g_numGiantWave);
#endif

	// Activate the giant spawner to start looking for an eligible player to become the giant robot
	for(int iTeam=2; iTeam<=3; iTeam++)
	{
		Giant_Cleanup(iTeam);
		g_nTeamGiant[iTeam][g_bTeamGiantActive] = true;
		g_nTeamGiant[iTeam][g_flTeamGiantTimeRoundStarts] = GetEngineTime()+30.0-5.0; // time when the spawn process should begin
	}
}

public void RaceTimer_On10SecRemain(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(RaceTimer_On10SecRemain) caller: %d activator: %d!", caller, activator);
#endif

	// Giant intro music
	if(g_numGiantWave == 1)
	{
		EmitSoundToAll(SOUND_GIANT_START);

		// Allow announcer countdown for the last 5 seconds
		//SetVariantInt(1);
		//AcceptEntityInput(caller, "AutoCountdown", caller);
	}else{
		// Disable announcer countdown for the last 5 seconds
		//SetVariantInt(0);
		//AcceptEntityInput(caller, "AutoCountdown", caller);
	}
}

public void RaceTimer_On3SecRemain(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(RaceTimer_On3SecRemain) caller: %d activator: %d!", caller, activator);
#endif

	// Play an announcer line announcing the entrance of the giant
	if(g_numGiantWave == 1)
	{
		EmitSoundToAll(g_strSoundWaveFirst[GetRandomInt(0, sizeof(g_strSoundWaveFirst)-1)]);
	}else if(g_numGiantWave >= config.LookupInt(g_hCvarRaceNumWaves))
	{
		EmitSoundToAll(g_strSoundWaveFinal[GetRandomInt(0, sizeof(g_strSoundWaveFinal)-1)]);
	}else{
		EmitSoundToAll(g_strSoundWaveMid[GetRandomInt(0, sizeof(g_strSoundWaveMid)-1)]);
	}	
}

public void RaceTimer_OnFinished(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(RaceTimer_OnFinished) caller: %d, activator: %d, g_numGiantWave: %d, maxWaves: %d", caller, activator, g_numGiantWave, config.LookupInt(g_hCvarRaceNumWaves));
#endif

	if(g_numGiantWave == 1 && config.LookupFloat(g_hCvarRaceTimeIntermission) >= 0.2)
	{
		// Enter intermission only during the first wave
		g_bRaceIntermission = true;
		g_flTimeIntermissionEnds = GetGameTime() + config.LookupFloat(g_hCvarRaceTimeIntermission) * 60.0;
		g_bRaceIntermissionBottom[TFTeam_Red] = false;
		g_bRaceIntermissionBottom[TFTeam_Blue] = false;

		// Stop both team's tanks
		for(int team=2; team<=3; team++)
		{
			// De-couple the tank from the track and hide it somewhere, doesn't matter where.
			int iTank = EntRefToEntIndex(g_iRefTank[team]);
			if(iTank > MaxClients)
			{
				Tank_CreateFakeTank(team, true);

				// Hide the real tank somewhere. Why? It keeps tank logic going..
				float pos[3] = {-10000.0, -10000.0, -10000.0};
				TeleportEntity(iTank, pos, NULL_VECTOR, NULL_VECTOR);
				
				SetEntProp(iTank, Prop_Send, "m_bGlowEnabled", false);
				Tank_SetNoTarget(team, true);
			}

			int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
			if(watcher > MaxClients)
			{
				SetEntPropFloat(watcher, Prop_Send, "m_flRecedeTime", g_flTimeIntermissionEnds);
			}
		}

		float timeIntermissionEnds = config.LookupFloat(g_hCvarRaceTimeIntermission)*60.0;
		if(timeIntermissionEnds < 6.0) timeIntermissionEnds = 6.0;

		Timer_KillStart();
		g_hTimerStart = CreateTimer(timeIntermissionEnds-SPAWNER_TIME_TANK, Timer_EndIntermission, _, TIMER_REPEAT); // The spawning process takes 3s.

		g_countdownTime = 5;
		Timer_KillCountdown();
		g_timerCountdown = CreateTimer(timeIntermissionEnds-5.1, Timer_Countdown, _, TIMER_REPEAT);

		MapLogic_OnIntermission();
	}

	// Create the timer to the next giant wave or when overtime begins.
	if(g_numGiantWave < config.LookupInt(g_hCvarRaceNumWaves))
	{
		// Recreate the timer
		RaceTimer_Create();
	}else{
		OvertimeTimer_Create();
	}
}

public Action Timer_EndIntermission(Handle timer)
{
	Spawner_Spawn(MAXPLAYERS+TFTeam_Red, Spawn_Tank);
	Spawner_Spawn(MAXPLAYERS+TFTeam_Blue, Spawn_Tank);

	g_hTimerStart = INVALID_HANDLE;
	return Plugin_Stop;
}

public void Tank_EndIntermission()
{
#if defined DEBUG
	PrintToServer("(Tank_EndIntermission)");
#endif
	if(!g_bRaceIntermission) return;

	// Intermission is over and the tanks can start moving again.
	g_bRaceIntermission = false;
	for(int i=0; i<MAX_TEAMS; i++) g_tankRespawned[i] = false;

	BroadcastSoundToTeam(TFTeam_Spectator, "harbor.red_whistle");
}

public void NextFrame_ParentTank(int team)
{
	int tank = EntRefToEntIndex(g_iRefTank[team]);
	int cart = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(tank > MaxClients && cart > MaxClients)
	{
		SetVariantString("!activator");
		AcceptEntityInput(tank, "SetParent", cart);
	}
}

public void NextFrame_TankRestorePath(int ref)
{
	int tank = EntRefToEntIndex(ref);
	if(tank > MaxClients)
	{
		Tank_RestorePath(tank);
	}
}

void Tank_RestorePath(int tank)
{
	int team = GetEntProp(tank, Prop_Send, "m_iTeamNum");
	if(team != TFTeam_Red && team != TFTeam_Blue) return;

	int cart = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(cart > MaxClients)
	{
		// Set the next path of the tank to that of the cart's
		int path = Train_GetCurrentPath(team);
		if(path > MaxClients)
		{
			int nextPath = GetEntDataEnt2(path, Offset_GetNextOffset(path));
			if(nextPath > MaxClients)
			{
				char pathName[128];
				GetEntPropString(nextPath, Prop_Data, "m_iName", pathName, sizeof(pathName));

				Tank_SetStartingPathTrack(tank, pathName);
			}
		}
	}	
}

int CountPlayersOnTeam(int team)
{
	int iCount;
	for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == team) iCount++;
	return iCount;
}

public Action Timer_Countdown(Handle hTimer, any junk)
{
	if(g_countdownTime >= 1 && g_countdownTime <= 5)
	{
		for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "playgamesound %s", g_strSoundCountdown[g_countdownTime-1]);

		g_countdownTime--;
		if(g_countdownTime >= 1)
		{
			g_timerCountdown = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
			return Plugin_Stop;
		}
	}

	g_timerCountdown = INVALID_HANDLE;
	return Plugin_Stop;
}

public void Event_BroadcastAudio(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	char strSound[50];
	GetEventString(hEvent, "sound", strSound, sizeof(strSound));
	//PrintToChatAll("Sound played naturally: %s", strSound);
	
	if(strcmp(strSound, "Announcer.MVM_Tank_Alert_Spawn") == 0 || strcmp(strSound, "Announcer.MVM_Tank_Alert_Multiple") == 0 || strcmp(strSound, "Announcer.MVM_Tank_Alert_Halfway") == 0 
		|| strcmp(strSound, "Announcer.MVM_Tank_Alert_Halfway_Multiple") == 0 || strcmp(strSound, "Announcer.MVM_Tank_Alert_Near_Hatch") == 0 || strcmp(strSound, "Announcer.MVM_General_Destruction") == 0
		|| strcmp(strSound, "Announcer.MVM_Bomb_Reset") == 0)
	{
		SetEventBroadcast(hEvent, true);
	}else if(GetEventInt(hEvent, "team") == TFTeam_Red && g_nGameMode != GameMode_Race)
	{
		// Block the game end sounds for only the RED team and play some substitute sounds
		if(strcmp(strSound, "Game.YourTeamLost") == 0)
		{
			if(g_bIsFinale)
			{
				BroadcastSoundToTeam(TFTeam_Red, "Announcer.MVM_Game_Over_Loss");
			}else{
				BroadcastSoundToTeam(TFTeam_Red, "Announcer.MVM_Wave_Lose");
			}
			BroadcastSoundToTeam(TFTeam_Red, "music.mvm_lost_wave");

			SetEventBroadcast(hEvent, true);
		}else if(strcmp(strSound, "Game.YourTeamWon") == 0)
		{
			BroadcastSoundToTeam(TFTeam_Red, "Announcer.MVM_Final_Wave_End");
			BroadcastSoundToTeam(TFTeam_Red, "music.mvm_end_mid_wave");

			SetEventBroadcast(hEvent, true);
		}
	}
}

void Tank_BombDeployHud(bool enable)
{
	// This will crash if changeState is true (more so on linux). I think SourceMod makes the incorrect assumption that the SendTables are identical in the real and proxy gamerules entity. I could be wrong.
	GameRules_SetProp("m_bPlayingHybrid_CTF_CP", enable);

	if(g_offset_m_bPlayingHybrid_CTF_CP > 0)
	{
		int gamerules = FindEntityByClassname(MaxClients+1, "tf_gamerules");
		if(gamerules > MaxClients)
		{
			ChangeEdictState(gamerules, g_offset_m_bPlayingHybrid_CTF_CP);
		}
	}
}

public void Event_RoundWin(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

#if defined DEBUG
	PrintToServer("(Event_RoundWin)");
#endif

	int winningTeam = GetEventInt(hEvent, "team");
	g_bIsRoundStarted = false;
	g_bIsInNaturalRound = false;
	Buster_Cleanup(TFTeam_Blue);
	Buster_Cleanup(TFTeam_Red);
	Giant_Cleanup(TFTeam_Blue);
	Giant_Cleanup(TFTeam_Red);
	RageMeter_Cleanup();
	HealthBar_Hide();
	Bomb_KillTimer();
	Announcer_Reset();

	Timers_KillAll();

	int iTimer = FindEntityByClassname(MaxClients+1, "team_round_timer");
	if(iTimer > MaxClients)
	{
		AcceptEntityInput(iTimer, "Enable");
	}
	
	// If there are any tanks still in place, make sentries no longer target them
	Tank_SetNoTarget(TFTeam_Red, true);
	Tank_SetNoTarget(TFTeam_Blue, true);

	// Toggle off the hybrid ctf/cp HUD
	Tank_BombDeployHud(false);

	switch(g_nGameMode)
	{
		case GameMode_Race:
		{
			// Destroy the tank of the team that won
			Tank_PickMVP(TFTeam_Red);
			Tank_PickMVP(TFTeam_Blue);

			// For some reason, RED sentry busters lose their color when the game ends, so reapply it
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Red && Spawner_HasGiantTag(i, GIANTTAG_SENTRYBUSTER) && GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
				{
					SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					SetEntityRenderColor(i, 255, 0, 0);
				}
			}

			// Normally, a point isn't awarded when a stage is won in plr_.
			if(GetEventInt(hEvent, "full_round") == 0 && winningTeam >= 2)
			{
				SetTeamScore(winningTeam, GetTeamScore(winningTeam)+1);
			}

			for(int team=2; team<=3; team++)
			{
				int iTank = EntRefToEntIndex(g_iRefTank[team]);
				if(iTank > MaxClients)
				{
					// Remove the tank's glowing outline
					SetEntProp(iTank, Prop_Send, "m_bGlowEnabled", false, 1);

					// Pipeline has the cart move into place in the center after the round has ended, and then triggers the map explosion, so simply wait a couple seconds before destroying the tank
					if(g_bIsFinale && winningTeam == team && (g_nMapHack == MapHack_Pipeline || g_nMapHack == MapHack_Nightfall))
					{
						switch(g_nMapHack)
						{
							case MapHack_Pipeline: CreateTimer(7.0, Timer_TankExplodePipeline, g_iRefTank[team], TIMER_FLAG_NO_MAPCHANGE);
							case MapHack_Nightfall: CreateTimer(1.8, Timer_TankExplodePipeline, g_iRefTank[team], TIMER_FLAG_NO_MAPCHANGE);
						}
					}else if(g_bIsFinale && winningTeam == team)
					{
						// Destroy the winning team's tank in the finale
						SetVariantInt(MAX_TANK_HEALTH);
						AcceptEntityInput(iTank, "RemoveHealth");
						g_iRefTank[team] = 0;
#if defined DEBUG
						PrintToServer("(RoundWin) Destroying tank (team %d) just in case..!", winningTeam);
#endif						
					}
				}

				// Make sure the losing team's payload cart stops moving
				if(winningTeam != team)
				{
					int iTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
					if(iTrain > MaxClients)
					{
						SetVariantFloat(0.0);
						AcceptEntityInput(iTrain, "SetSpeedDir");
					}
				}

				// Make sure the lifts stop moving after the round ends
				if(g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent)
				{
					int iLift = EntRefToEntIndex(g_iRefTrackTrain2[team]);
					if(iLift > MaxClients)
					{
						SetVariantFloat(0.0);
						AcceptEntityInput(iLift, "SetSpeedDir");
					}
				}
			}

			// Trigger a scramble if the losing team's tank was far behind when the round was over.
			if(config.LookupBool(g_hCvarScrambleEnabled) && !g_bIsScramblePending && g_nMapHack != MapHack_HightowerEvent)
			{
				// See how far the losing team's tank made it.
				float diff = 0.0;
				for(int team=2; team<=3; team++)
				{
					int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
					if(watcher > MaxClients)
					{
						diff = GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress") - diff;
					}
				}

				if(FloatAbs(diff) > config.LookupFloat(g_hCvarScrambleProgress))
				{
					Scramble_Execute();
				}
			}


			if(config.LookupBool(g_hCvarScrambleEnabled) && !g_bIsScramblePending)
			{
				int maxGiants = config.LookupInt(g_hCvarScrambleGiants);
				if(maxGiants > 0)
				{
					for(int team=2; team<=3 && !g_bIsScramblePending; team++)
					{
						int numGiants = 0;
						for(int client=1; client<=MaxClients; client++)
						{
							if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") &&
								g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
							{
								numGiants++;

								if(numGiants >= maxGiants)
								{
									Scramble_Execute();

									break;
								}
							}
						}
					}
				}
			}
		}
		default:
		{
			int iTank = EntRefToEntIndex(g_iRefTank[TFTeam_Blue]);
			if(iTank > MaxClients)
			{
				SetEntProp(iTank, Prop_Send, "m_bGlowEnabled", false, 1);
				
				switch(winningTeam)
				{
					case TFTeam_Blue: 
					{
						Tank_PickMVP(TFTeam_Blue);
						
						int iTankHealth = GetEntProp(iTank, Prop_Data, "m_iHealth");
						int iTankMaxHealth = GetEntProp(iTank, Prop_Data, "m_iMaxHealth");

						PrintToChatAll("%t", "Tank_Chat_TankDeploy", g_strTeamColors[TFTeam_Blue], 0x01, "\x07CF7336", iTankHealth, 0x01, RoundToCeil(float(iTankHealth)/float(iTankMaxHealth)*100.0));

						// Judge if we need to scramble because the tank had way too much health when the round was won
						if(config.LookupBool(g_hCvarScrambleEnabled) && !g_bIsScramblePending && float(iTankHealth) / float(iTankMaxHealth) >= config.LookupFloat(g_hCvarScrambleHealth))
						{
							Scramble_Execute();
						}
						
						// Blue has won, if the stage is a finale, the tank needs to be exploded
						if(g_bIsFinale)
						{
							SetVariantInt(MAX_TANK_HEALTH);
							AcceptEntityInput(iTank, "RemoveHealth");
						}
					}
					case TFTeam_Red:
					{
						// If RED won, the tank is already destroyed and an MVP was already selected
					}
				}
			}

			// See if any control points have been capped, if none have been capped, trigger a team scramble
			if(config.LookupBool(g_hCvarScrambleEnabled) && !g_bIsScramblePending && g_iMaxControlPoints[TFTeam_Blue] >= 1)
			{
				// The first control point should be index 0
				int iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[TFTeam_Blue][0]);
				if(iControlPoint > MaxClients)
				{
					bool bCaptured = (GetEntProp(iControlPoint, Prop_Send, "m_nSkin") != 0);
					if(!bCaptured)
					{
						Scramble_Execute();				
					}
				}
			}
		}
	}
	
	if(g_bIsScramblePending)
	{
		// The above code seems to block the team scramble alert
		Handle hEventAlert = CreateEvent("teamplay_alert");
		if(hEventAlert != INVALID_HANDLE)
		{
			SetEventInt(hEventAlert, "alert_type", 0);
			FireEvent(hEventAlert); // this closes the handle
		}
	}

	Timer_KillStart();
}

public Action Timer_TankExplodePipeline(Handle hTimer, int iRefTank)
{
	int iTank = EntRefToEntIndex(iRefTank);
	if(iTank > MaxClients)
	{
		// Destroy the team's tank for cinematic effect
		SetVariantInt(MAX_TANK_HEALTH);
		AcceptEntityInput(iTank, "RemoveHealth");	
	}

	return Plugin_Handled;
}

void Timer_KillStart()
{
	if(g_hTimerStart != INVALID_HANDLE)
	{
		KillTimer(g_hTimerStart);
		g_hTimerStart = INVALID_HANDLE;
	}
}

void Train_Move(int team, float flSpeed, int iNumCappers=-1)
{
	// Set the speed of the cart, value should be from 0.0 to 1.0
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iWatcher > MaxClients && iTrackTrain > MaxClients)
	{
		// Determine the number shown on the HUD (the number of players pushing the cart)
		if(iNumCappers == -1)
		{
			if(flSpeed != 0.0)
			{
				SetVariantInt(1);
			}else{
				SetVariantInt(0);
			}
		}else{
			SetVariantInt(iNumCappers);
		}
		AcceptEntityInput(iWatcher, "SetNumTrainCappers");

		// Set the speed of the func_tracktrain
		SetVariantFloat(flSpeed);
		AcceptEntityInput(iTrackTrain, "SetSpeedDirAccel");
		
		// Control the speed of the flatbed in frontier
		if(g_nMapHack == MapHack_Frontier)
		{
			int iTrackTrain2 = EntRefToEntIndex(g_iRefTrackTrain2[TFTeam_Blue]);
			if(iTrackTrain2 > MaxClients)
			{
				SetVariantFloat(flSpeed);
				AcceptEntityInput(iTrackTrain2, "SetSpeedDirAccel");
			}
		}
		
		if(flSpeed == 0.0 && !g_bRaceIntermission)
		{
			SetEntPropFloat(iWatcher, Prop_Send, "m_flRecedeTime", 0.0);
		}
	}
}

void BroadcastSoundToTeam(int team, const char[] strSound)
{
	//PrintToChatAll("Broadcasting %s..", strSound);
	switch(team)
	{
		case TFTeam_Red, TFTeam_Blue: for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team) ClientCommand(i, "playgamesound %s", strSound);
		default: for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "playgamesound %s", strSound);
	}
}

void BroadcastSoundToEnemy(int team, const char[] sound)
{
	for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != team) ClientCommand(i, "playgamesound %s", sound);
}

int Tank_FindTrackTrain(int team)
{
	// Find the func_tracktrain entity by looking at CTeamTrainWatcher::m_iszTrain
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	if(iWatcher > MaxClients)
	{
		char strTrainName[100];
		GetEntPropString(iWatcher, Prop_Data, "m_iszTrain", strTrainName, sizeof(strTrainName));
		
		int iTrackTrain = Entity_FindEntityByName(strTrainName, "func_tracktrain");
		if(iTrackTrain > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Tank_FindTrackTrain) func_tracktrain: %d (team %d) (solidType: %d) \"%s\"!", iTrackTrain, team, GetEntProp(iTrackTrain, Prop_Send, "m_nSolidType"), strTrainName);
#endif
			g_iRefTrackTrain[team] = EntIndexToEntRef(iTrackTrain);
			
			// Make the train non-solid and invisible
			DispatchKeyValue(iTrackTrain, "solid", "0");
			SetEntityRenderMode(iTrackTrain, RENDER_NONE); // Gets rid of outline
			SetEntityRenderColor(iTrackTrain, _, _, _, 0); // Makes the model invisible

			// Set the max cart/tank speed
			SetEntPropFloat(iTrackTrain, Prop_Data, "m_maxSpeed", config.LookupFloat(g_hCvarMaxSpeed));
			
			// Delete the sparks associated with the func_tracktrain entity
			Train_KillSparks(iTrackTrain);
			
			// Teleport the cart to its current position
			// The cart isn't non-solid until you do this for some unexplained reason
			float flPos[3];
			GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPos);
			TeleportEntity(iTrackTrain, flPos, NULL_VECTOR, NULL_VECTOR);

			return iTrackTrain;
		}
	}
	
	return -1;
}

void Train_FindProps()
{
	// Finds any entities that might be associated with the cart model and makes them invisible.
	// Ideally, we would detect if they were parented or phys_contraint to the cart, but at teamplay_round_start that information is not available.
	// Blindly search through all edicts and catch any entities with a matching model.
	// These entities sometimes trigger map logic so they are important to keep track of.

	g_trainProps.Clear();

	char model[MAXLEN_CART_PATH];
	char name[64];
	char cartModel[MAXLEN_CART_PATH];
	char classname[32];
	int size = g_cartModels.Length;

	for(int entity=MaxClients+1,maxEntities=GetMaxEntities(); entity<maxEntities; entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEdictClassname(entity, classname, sizeof(classname));
			if(strncmp(classname, "prop_physics", 12) != 0 && strncmp(classname, "prop_dynamic", 12) != 0) continue;

			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

			if(strcmp(name, TARGETNAME_CART_PROP, false) == 0)
			{
				Train_AddProp(entity);
				continue;
			}

			for(int i=0; i<size; i++)
			{
				g_cartModels.GetString(i, cartModel, sizeof(cartModel));
				if(strcmp(model, cartModel) == 0)
				{
					Train_AddProp(entity);
					break;
				}
			}
		}
	}
}

void Train_AddProp(int entity)
{
	int reference = EntIndexToEntRef(entity);

	int size = g_trainProps.Length;
	bool found = false;
	for(int i=0; i<size; i++)
	{
		int array[ARRAY_TRAINPROP_SIZE];
		g_trainProps.GetArray(i, array, sizeof(array));
		if(array[TrainPropArray_Reference] == reference)
		{
			found = true;
			break;
		}
	}

	if(!found)
	{
		int array[ARRAY_TRAINPROP_SIZE];
		// Save the solid type for later.
		array[TrainPropArray_Reference] = reference;
		array[TrainPropArray_SolidType] = SOLID_VPHYSICS; // GetEntProp(entity, Prop_Send, "m_nSolidType");

		g_trainProps.PushArray(array, sizeof(array));
#if defined DEBUG
		char model[PLATFORM_MAX_PATH];
		char className[64];
		char name[64];
		GetEdictClassname(entity, className, sizeof(className));
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

		PrintToServer("(Train_AddProp) %d \"%s\" - name=\"%s\",model=\"%s\",parent=%d,m_nSolidType=%d!", entity, className, name, model, GetEntPropEnt(entity, Prop_Send, "moveparent"), GetEntProp(entity, Prop_Send, "m_nSolidType"));
#endif

		SetEntityRenderMode(entity, RENDER_NONE); // Gets rid of outline
		SetEntityRenderColor(entity, _, _, _, 0); // Makes the model invisible
		
		// Make the conventional payload cart invisible
		DispatchKeyValue(entity, "solid", "0");
		AcceptEntityInput(entity, "DisableShadow");
	}
}

void LoadStringFromAddress(char[] buffer, int maxlength, Address address)
{
	bool terminated = false;
	for(int i=0; i<maxlength; i++)
	{
		buffer[i] = LoadFromAddress(address+view_as<Address>(i), NumberType_Int8);

		if(buffer[i] == '\0')
		{
			terminated = true;
			break;
		}
	}
	if(!terminated) buffer[maxlength-1] = '\0';	
}

void Train_FindPropsByParenting(int team)
{
	// Finds all props that are parented to the func_tracktrain and makes them transparent.
	int train = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(train > MaxClients)
	{
		int prop = MaxClients+1;
		while((prop = FindEntityByClassname(prop, "prop_dynamic")) > MaxClients)
		{
			if(GetEntPropEnt(prop, Prop_Send, "moveparent") == train)
			{
#if defined DEBUG
				PrintToServer("(Train_FindPropsByParenting) Found \"prop_dynamic\" (%d) parented to team %d's cart (%d)..", prop, team, train);
#endif
				Train_AddProp(prop);
			}
		}
	}
}

void Train_FindPropsByPhysConstraint(int team)
{
	// This will check for the phys_constraint relationship between the func_tracktrain and the physics prop of the cart. This is the default payload setup from the gametype library.
	int train = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(train > MaxClients)
	{
		char trainName[64];
		GetEntPropString(train, Prop_Data, "m_iName", trainName, sizeof(trainName));
		if(strlen(trainName) > 0)
		{
			int constraint = MaxClients+1;
			while((constraint = FindEntityByClassname(constraint, "phys_constraint")) != -1)
			{
				// I will get rid of this monstrosity when SM 1.8 becomes the stable branch.
				int offset = FindDataMapInfo(constraint, "m_nameAttach1");
				if(offset <= 0) continue;
				Address pointer = view_as<Address>(LoadFromAddress(GetEntityAddress(constraint)+view_as<Address>(offset), NumberType_Int32));
				if(!IsValidAddress(pointer)) continue;
				char name1[64];
				LoadStringFromAddress(name1, sizeof(name1), pointer);
				//PrintToServer("GetEntPropString: m_nameAttach1 = \"%s\"", GetEntPropString(constraint, Prop_Data, "m_nameAttach1", temp, sizeof(temp)));
				//PrintToServer("LoadStringFromAddress: m_nameAttach1 = \"%s\"", name1);			

				offset = FindDataMapInfo(constraint, "m_nameAttach2");
				if(offset <= 0) continue;
				pointer = view_as<Address>(LoadFromAddress(GetEntityAddress(constraint)+view_as<Address>(offset), NumberType_Int32));
				if(!IsValidAddress(pointer)) continue;
				char name2[64];
				LoadStringFromAddress(name2, sizeof(name2), pointer);

				if(strlen(name1) <= 0 || strlen(name2) <= 0) continue;

				bool found = false;
				if(strcmp(trainName, name1, false) == 0)
				{
					found = true;
					strcopy(name1, sizeof(name1), name2);
				}else if(strcmp(trainName, name2, false) == 0)
				{
					found = true;
				}

				if(found)
				{
					int maxEntities = GetMaxEntities();
					for(int entity=MaxClients+1; entity<maxEntities; entity++)
					{
						if(entity == train) continue;

						if(IsValidEntity(entity))
						{
							GetEntPropString(entity, Prop_Data, "m_iName", name2, sizeof(name2));

							if(strcmp(name1, name2) == 0)
							{
#if defined DEBUG
								PrintToServer("(Train_FindPropsByPhysConstraint) Found relationship between \"%s\" and \"%s\"!", trainName, name1);
#endif
								Train_AddProp(entity);
								break;
							}
						}
					}
				}
			}
		}
	}
}

void Tank_FindParts(int team)
{
	g_iRefTankTrackL[team] = 0;
	g_iRefTankTrackR[team] = 0;
	g_iRefTankMechanism[team] = 0;
	
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	if(iTank <= MaxClients) return;

	int iProp = MaxClients+1;
	while((iProp = FindEntityByClassname(iProp, "prop_dynamic")) != -1)
	{
		if(iProp > MaxClients)
		{
			char strModel[100];
			GetEntPropString(iProp, Prop_Data, "m_ModelName", strModel, sizeof(strModel));
			if(g_iRefTankTrackL[team] == 0 && strcmp(strModel, MODEL_TRACK_L) == 0 && GetEntPropEnt(iProp, Prop_Send, "moveparent") == iTank)
			{
				g_iRefTankTrackL[team] = EntIndexToEntRef(iProp);
			}else if(g_iRefTankTrackR[team] == 0 && strcmp(strModel, MODEL_TRACK_R) == 0 && GetEntPropEnt(iProp, Prop_Send, "moveparent") == iTank)
			{
				g_iRefTankTrackR[team] = EntIndexToEntRef(iProp);
			}else if(g_iRefTankMechanism[team] == 0 && strcmp(strModel, MODEL_MECHANISM) == 0 && GetEntPropEnt(iProp, Prop_Send, "moveparent") == iTank)
			{
				g_iRefTankMechanism[team] = EntIndexToEntRef(iProp);
			}
		}
		
		if(g_iRefTankTrackL[team] != 0 && g_iRefTankTrackR[team] != 0 && g_iRefTankMechanism[team] != 0) break;
	}

#if defined DEBUG
	PrintToServer("(Tank_FindParts) Left: %d Right: %d Mechanism: %d", EntRefToEntIndex(g_iRefTankTrackL[team]), EntRefToEntIndex(g_iRefTankTrackR[team]), EntRefToEntIndex(g_iRefTankMechanism[team]));
#endif
}

int Tank_HookCaptureTrigger(int team)
{
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iTrackTrain <= MaxClients)
	{
		return -1;
	}



	g_iRefTrigger[team] = 0;

	int iNumFound;
	int iTrigger = MaxClients+1;
	while((iTrigger = FindEntityByClassname(iTrigger, "trigger_capture_area")) > MaxClients)
	{
		int iParent = GetEntPropEnt(iTrigger, Prop_Send, "moveparent");
		if(iParent == iTrackTrain || (g_nMapHack == MapHack_Frontier && EntRefToEntIndex(g_iRefTrackTrain2[TFTeam_Blue]) > MaxClients && iParent == EntRefToEntIndex(g_iRefTrackTrain2[TFTeam_Blue])))
		{
			// Todo: Add another check for the teams that are allowed to cap
#if defined DEBUG
			char strName[64];
			GetEntPropString(iTrigger, Prop_Data, "m_iName", strName, sizeof(strName));
			PrintToServer("(Tank_HookCaptureTrigger) trigger_capture_area: \"%s\" %d! (team %d) Parent: %d!", strName, iTrigger, team, iParent);
#endif
			SDKHook(iTrigger, SDKHook_StartTouch, BlockTouch);
			
			if(g_iRefTrigger[team] == 0)
			{
				g_iRefTrigger[team] = EntIndexToEntRef(iTrigger);
			}
			
			iNumFound++;
		}
	}

	if(iNumFound <= 0)
	{
		LogMessage("(Tank_HookCaptureTrigger) Failed to find trigger_capture_area assoicated with func_tracktrain: %d!", iTrackTrain);
	}

	if(g_iRefTrigger[team] == 0) return -1;
	return EntRefToEntIndex(g_iRefTrigger[team]);
}

public Action BlockTouch(int iEntity, int iOther)
{
	//PrintToServer("Touched called on %d", iEntity);
	return Plugin_Handled;
}

void Tank_KillFakeTank(int team)
{
	if(g_iRefFakeTank[team] == 0) return;

	int tank = EntRefToEntIndex(g_iRefFakeTank[team]);
	if(tank > MaxClients)
	{
		AcceptEntityInput(tank, "Kill");
	}

	g_iRefFakeTank[team] = 0;
}

void Tank_CreateFakeTank(int team, bool glow)
{
	Tank_KillFakeTank(team);
	
	int tank = CreateEntityByName("prop_dynamic");
	if(tank > MaxClients)
	{
		if(g_nGameMode == GameMode_Race && team == TFTeam_Red)
		{
			DispatchKeyValue(tank, "model", MODLE_ROMEVISION_STATIC);
		}else{
			DispatchKeyValue(tank, "model", MODEL_TANK_STATIC);
		}
		DispatchKeyValue(tank, "solid", "0");

		DispatchSpawn(tank);

		int transparency = 50;
		SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
		if(team == TFTeam_Red)
		{
			SetEntityRenderColor(tank, 255, 35, 35, transparency);
		}else{
			SetEntityRenderColor(tank, 255, 255, 255, transparency);
		}

		// Set a special skin on the tank.
		SetEntProp(tank, Prop_Send, "m_nSkin", 1);
		SetEntProp(tank, Prop_Send, "m_fEffects", EF_NOSHADOW|EF_NORECEIVESHADOW|EF_ITEM_BLINK);
		SetEntProp(tank, Prop_Send, "m_nSolidType", SOLID_NONE);
		SetEntProp(tank, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);

		// To ensure the glow outline is visible in all parts of the map.
		int flags = GetEdictFlags(tank);
		flags |= FL_EDICT_ALWAYS;
		SetEdictFlags(tank, flags);

		int cart = EntRefToEntIndex(g_iRefTrackTrain[team]);
		// Teleport the fake tank to the real tank ONLY IF the real tank isn't parented..
		int realTank = EntRefToEntIndex(g_iRefTank[team]);
		if(realTank > MaxClients && GetEntPropEnt(realTank, Prop_Send, "moveparent") <= MaxClients)
		{
			float pos[3];
			float ang[3];
			GetEntPropVector(realTank, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(realTank, Prop_Send, "m_angRotation", ang);
			TeleportEntity(tank, pos, ang, NULL_VECTOR);
		}else{
			// Teleport the fake tank to the cart's location as best as we can..
			if(cart > MaxClients)
			{
				float pos[3];
				float ang[3];
				GetEntPropVector(cart, Prop_Send, "m_vecOrigin", pos);
				GetEntPropVector(cart, Prop_Send, "m_angRotation", ang);
				pos[2] -= 55.0;
				TeleportEntity(tank, pos, ang, NULL_VECTOR);				
			}
		}
		
		if(cart > MaxClients)
		{
			SetVariantString("!activator");
			AcceptEntityInput(tank, "SetParent", cart);
		}

		if(glow)
		{
			// Produce a team colored glow outline on the fake tank entity.
			int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
			if(watcher > MaxClients) SetEntPropEnt(watcher, Prop_Send, "m_hGlowEnt", tank);
		}

#if defined DEBUG
		PrintToServer("(Tank_CreateFakeTank) Created fake tank (team %d, glow %d): %d!", team, glow, tank);
#endif
		g_iRefFakeTank[team] = EntIndexToEntRef(tank);
	}
}

/* Creates and spawns a tank_boss entity on the cart's current location.
 *
 * @return Entity index of the created tanked, -1 if the tank could not be spawned.
 */
int Tank_CreateTankEntity(int team)
{
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iTrackTrain <= MaxClients)
	{
		LogMessage("(Tank_CreateTank) Failed to create tank_boss: Missing reference to \"func_tracktrain\"!");
		return -1;
	}

	Tank_KillFakeTank(team);

	int tank = CreateEntityByName("tank_boss");
	if(tank > MaxClients)
	{
		char tankName[64] = TARGETNAME_TANK_RED;
		if(team == TFTeam_Blue) tankName = TARGETNAME_TANK_BLUE;
		DispatchKeyValue(tank, "targetname", tankName);

		// Hook the tank output OnKilled
		HookSingleEntityOutput(tank, "OnKilled", Tank_OnKilled, true);
		
		// Keeps the tank from instantly exploding once it hits the payload cart
		SDKHook(tank, SDKHook_OnTakeDamage, Tank_OnTakeDamage);
		if(g_hSDKSolidMask != INVALID_HANDLE)
		{
			DHookEntity(g_hSDKSolidMask, false, tank);
		}

		// Set the tank's team.
		SetEntProp(tank, Prop_Send, "m_iTeamNum", team);

		// There's a bug in CTFTankBoss::Spawn which will cause an infinite loop if any path_tracks form a connected cycle.
		// The game's code finds one path_track and visits the previous path_track until it reaches a dead end. (I guess pl_angkor is unlucky enough to provide one of the few path_tracks that form a cycle.)
		// This is not a problem in MVM if you set the starting path track of the tank in the population files.
		// If you spawn a tank outside of MVM population files, you run the risk of hitting this buggy code.
		// You need to call CTFTankBoss::SetStartingPathTrackNode before calling CTFTankBoss::Spawn.
		Tank_RestorePath(tank);

		DispatchSpawn(tank);

		// Set the tank's team (again).
		SetEntProp(tank, Prop_Send, "m_iTeamNum", team);

		// Set the tank's initial speed
		SetEntPropFloat(tank, Prop_Data, "m_speed", 0.0);
		// Set a special skin on the final tank
		SetEntProp(tank, Prop_Send, "m_nSkin", 1);
		
		// No RED skin is included with the tank model so color it red
		if(team == TFTeam_Red)
		{
			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 255, 35, 35);
		}

		// Teleport the tank into position to follow the track_path
		float flPosTrain[3];
		float flAngTrain[3];
		GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPosTrain);
		GetEntPropVector(iTrackTrain, Prop_Send, "m_angRotation", flAngTrain);
		flPosTrain[2] -= 35.0;

		TeleportEntity(tank, flPosTrain, flAngTrain, NULL_VECTOR);
#if defined DEBUG
		PrintToServer("(Tank_CreateTankEntity) Spawned \"tank_boss\" (team %d): %d!", team, tank);
#endif
		return tank;
	}else{
		LogMessage("Failed to create entity: \"tank_boss\"");
	}

	return -1;
}

int Tank_CreateTank(int team)
{
	int tank = Tank_CreateTankEntity(team);
	if(tank > MaxClients)
	{
		// Reset some misc variables
		g_flTankLastSound = 0.0;
		g_bSoundHalfway[team] = false;
		g_bIsRoundStarted = false;
		g_bEnableMapHack[team] = false;
		g_flTankHealEnd[team] = 0.0;
		g_tankRespawned[team] = false;
		g_bTankTriggerDisabled[team] = false;
		g_timeTankSeparation[team] = 0.0;

		// Clear damage stats
		for(int i=0; i<MAXPLAYERS+1; i++)
		{
			g_iDamageStatsTank[i][team] = 0;
			g_flTimeStuckInTank[i][team] = 0.0;
		}
		// Race gamemode variables
		g_iRaceTankDamage[team] = 0;
		g_flRaceLastChange[team] = 0.0;
		g_iRaceCurrentLevel[team] = MAX_RACE_LEVELS-1;
		g_bRaceGoingBackwards[team] = false;
		g_bRaceParentedForHill[team] = false;

		return tank;
	}
	
	return -1;
}

int Tank_FindTrainWatcher(int team)
{
	int iWatcher = MaxClients+1;
	while((iWatcher = FindEntityByClassname(iWatcher, "team_train_watcher")) != -1)
	{
		//PrintToServer("Found timer @ %d - %d %d..", iWatcher, GetEntProp(iWatcher, Prop_Send, "m_iTeamNum"), GetEntProp(iWatcher, Prop_Data, "m_bDisabled"));
		if(iWatcher > MaxClients && GetEntProp(iWatcher, Prop_Send, "m_iTeamNum") == team && !GetEntProp(iWatcher, Prop_Data, "m_bDisabled"))
		{
#if defined DEBUG
			PrintToServer("(Tank_FindTrainWatcher) team_train_watcher: %d! (team %d)", iWatcher, team);
#endif
			g_iRefTrainWatcher[team] = EntIndexToEntRef(iWatcher);
			g_iCurrentControlPoint[team] = 0;

			Watcher_CacheLinks(team);
			g_iMaxControlPoints[team] = Watcher_GetNumControlPoints(team);

			return iWatcher;
		}
	}
	
	return -1;
}

int Train_MoveBack(int team)
{
	// Moves the cart backwards after a tank has been destroyed, this could be at the starting node or at a control point
	
	// Countdown through control points backwards
	// The point that isn't start or goal AND is more than tank_distance_move is chosen to move the cart to
	// 0 is the first capture point, the last is the final one, (the one that goes boom)

	// Returns -1 if not moved back, otherwise it's the index of the control point+1 and 0 for start node.
	int iTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	int iPathGoal = EntRefToEntIndex(g_iRefPathGoal[team]);
	if(iTrain <= MaxClients || iWatcher <= MaxClients || iPathGoal <= MaxClients) return -1;

	for(int i=MAX_LINKS-1; i>=0; i--)
	{
		if(g_iRefLinkedCPs[team][i] == 0 || g_iRefLinkedPaths[team][i] == 0) continue;
		if(g_iRefLinkedCPs[team][i] == g_iRefControlPointGoal[team]) continue; // Bypass the final control point (the goal)

		int iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
		int iPathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][i]);

		if(iControlPoint <= MaxClients || iPathTrack <= MaxClients) continue;
		
		float flDistanceToGoal = Path_GetDistance(iPathTrack, iPathGoal);
		bool bCaptured = (GetEntProp(iControlPoint, Prop_Send, "m_nSkin") != 0);
#if defined DEBUG
		PrintToServer("(Train_MoveBack) #%d Captured: %d Distance to goal: %0.1f/%0.1f", i, bCaptured, flDistanceToGoal, config.LookupFloat(g_hCvarDistanceMove));
#endif
		float flDistanceMax = config.LookupFloat(g_hCvarDistanceMove);
		if(bCaptured && flDistanceToGoal > flDistanceMax)
		{
			g_iCurrentControlPoint[team] = i+1;
			
			Train_MoveTo(iTrain, iPathTrack);

			return i+1;
		}
	}
	
	// Move the cart back to the start since we found no qualifying control points
	int iPathStart = EntRefToEntIndex(g_iRefPathStart[team]);
	if(iPathStart > MaxClients)
	{
		g_iCurrentControlPoint[team] = 0;
		
		Train_MoveTo(iTrain, iPathStart);

		return 0;
	}

	LogMessage("(Train_MoveBack) Failed to move the cart back to start: start not found!");
	return -1;
}

void Train_MoveTo(int iTrackTrain, int iPathTrack)
{
#if defined DEBUG
	PrintToServer("(Train_MoveTo) Moving train %d to path %d..", iTrackTrain, iPathTrack);
#endif

	// Enable all the path_tracks between the cart and the goal.
	AcceptEntityInput(iPathTrack, "EnablePath");
	int goalPath = EntRefToEntIndex(g_iRefPathGoal[TFTeam_Blue]);
	if(goalPath > MaxClients)
	{
		int nextPath;
		int currentPath = iPathTrack;
		while((nextPath = GetEntDataEnt2(currentPath, Offset_GetNextOffset(iPathTrack))) > MaxClients)
		{
			AcceptEntityInput(nextPath, "EnablePath");

			currentPath = nextPath;
			if(currentPath == goalPath) break;
		}
	}

	// Let's now move the cart back.
	SetVariantEntity(iPathTrack);
	AcceptEntityInput(iTrackTrain, "TeleportToPathTrack");
	
	// If frontier, there are two func_tracktrain so we need to move the flatbed one as well
	// The flagbed can't be moved in the bomb deployment mode, players will be stuck in it. :(
	// If we decide to have the second tank after a giant, this plugin needs to move the cart back when the round starts
	if(g_nMapHack == MapHack_Frontier && g_iRefTrackTrain2[TFTeam_Blue] != 0)
	{
		int flatbed = EntRefToEntIndex(g_iRefTrackTrain2[TFTeam_Blue]);
		if(flatbed > MaxClients)
		{
			// The flatbed rides along on the previous path_track so check to see if one exists
			//SetEntData(flatbed, Offset_GetPathOffset(flatbed), GetEntityAddress(iPathTrack));
			
			SetEntProp(flatbed, Prop_Send, "m_nSolidType", 0);
			SetEntityRenderMode(flatbed, RENDER_NONE);

			SetVariantEntity(iPathTrack);
			AcceptEntityInput(flatbed, "TeleportToPathTrack");

			float posFlatbed[3];
			GetEntPropVector(iPathTrack, Prop_Send, "m_vecOrigin", posFlatbed);
			posFlatbed[2] -= 50.0;

			TeleportEntity(flatbed, posFlatbed, NULL_VECTOR, NULL_VECTOR);
		}
	}

	int iPathPrevious = GetEntDataEnt2(iPathTrack, Offset_GetPreviousOffset(iPathTrack));
	if(iPathPrevious > MaxClients)
	{
		// Disable the path previous path from where we spawned the tank so it doesn't start reversing and go somewhere
		AcceptEntityInput(iPathPrevious, "DisablePath");
	}
	
	// Make the bomb prop non-solid again in case it was reset from parenting for the finale
	// Make an exception if the cart no longer exists: The prop is probably falling and triggering the explosion
	for(int i=0,size=g_trainProps.Length; i<size; i++)
	{
		int array[ARRAY_TRAINPROP_SIZE];
		g_trainProps.GetArray(i, array, sizeof(array));

		int prop = EntRefToEntIndex(array[TrainPropArray_Reference]);
		if(prop > MaxClients)
		{
			SetEntProp(prop, Prop_Send, "m_nSolidType", 0);
		}
	}	
}

public void Tank_OnKilled(char[] output, int caller, int activator, float delay)
{
	// The Tank has been killed by the Red team
#if defined DEBUG
	PrintToServer("(Tank_OnKilled) OnKilled output called: %d!", caller);
#endif

	// When the round is won and the tank is killed, we don't need to spawn another tank or trigger another round end
	if(!g_bIsRoundStarted)
	{
		return;
	}

	// The tank should never be killed in plr_ maps
	if(g_nGameMode == GameMode_Race) return;

	// Cancel out the tank deploy sound.
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			StopSound(client, SNDCHAN_AUTO, SOUND_TANK_DEPLOY);
		}
	}

	// Voice lines that should be played by HUMANS whenever a tank is destroyed
	int iMax = GetRandomInt(6, 7);
	int iCount;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i) && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) && !TF2_IsPlayerInCondition(i, TFCond_Disguised) && iCount++ < iMax)
		{
			switch(TF2_GetPlayerClass(i))
			{
				case TFClass_Scout: EmitSoundToAll(g_strSoundTankDestroyedScout[GetRandomInt(0, sizeof(g_strSoundTankDestroyedScout)-1)], i, SNDCHAN_VOICE);
				case TFClass_Sniper: EmitSoundToAll(g_strSoundTankDestroyedSniper[GetRandomInt(0, sizeof(g_strSoundTankDestroyedSniper)-1)], i, SNDCHAN_VOICE);
				case TFClass_Soldier: EmitSoundToAll(g_strSoundTankDestroyedSoldier[GetRandomInt(0, sizeof(g_strSoundTankDestroyedSoldier)-1)], i, SNDCHAN_VOICE);
				case TFClass_DemoMan: EmitSoundToAll(g_strSoundTankDestroyedDemoman[GetRandomInt(0, sizeof(g_strSoundTankDestroyedDemoman)-1)], i, SNDCHAN_VOICE);
				case TFClass_Medic: EmitSoundToAll(g_strSoundTankDestroyedMedic[GetRandomInt(0, sizeof(g_strSoundTankDestroyedMedic)-1)], i, SNDCHAN_VOICE);
				case TFClass_Heavy: EmitSoundToAll(g_strSoundTankDestroyedHeavy[GetRandomInt(0, sizeof(g_strSoundTankDestroyedHeavy)-1)], i, SNDCHAN_VOICE);
				case TFClass_Pyro: EmitSoundToAll(g_strSoundTankDestroyedPyro[GetRandomInt(0, sizeof(g_strSoundTankDestroyedPyro)-1)], i, SNDCHAN_VOICE);
				case TFClass_Spy: EmitSoundToAll(g_strSoundTankDestroyedSpy[GetRandomInt(0, sizeof(g_strSoundTankDestroyedSpy)-1)], i, SNDCHAN_VOICE);
				case TFClass_Engineer: EmitSoundToAll(g_strSoundTankDestroyedEngineer[GetRandomInt(0, sizeof(g_strSoundTankDestroyedEngineer)-1)], i, SNDCHAN_VOICE);
			}
		}
	}
	
	// Assume the tank was just killed and play an announcer line
	BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_General_Destruction");

	Tank_PickMVP(TFTeam_Blue);
	
	// If the tank is parented, unparented it so the pile of cash doesn't stay with the cart
	if(GetEntPropEnt(caller, Prop_Send, "moveparent") > MaxClients)
	{
		AcceptEntityInput(caller, "ClearParent");
	}
	
	// Stop the cart and hide the health bar from view
	Train_Move(TFTeam_Blue, 0.0);
	HealthBar_Hide();
	g_bIsRoundStarted = false;

	MapLogic_OnIntermission();

	// Delay the action of moving the cart back after the tank is destroyed.
	// Doing this fixes a rare bug where the cart is moved back at the instant it is waiting to drop in maps like pl_badwater.
	// This occurs when the tank is killed right at the end in a small window of time.
	Timer_KillFailsafe();
	g_timerFailsafe = CreateTimer(2.0, Timer_Failsafe, _, TIMER_REPEAT);
}

void GameLogic_DoNext()
{
#if defined DEBUG
	PrintToServer("(GameLogic_DoNext) g_nGameMode = %d!", g_nGameMode);
#endif
	Timer_KillStart();

	// Determine next action based on the current game mode.
	if(g_nGameMode == GameMode_Tank)
	{
		// Set the game mode to bomb deploy
		g_nGameMode = GameMode_BombDeploy;

		BombRound_Init();

		float flTimeCooldown = config.LookupFloat(g_hCvarTankCooldown); // when the spawning process should be complete
		if(flTimeCooldown < 10.0) flTimeCooldown = 10.0; // set a lower limit on the user-defined cooldown time			

		// Move the cart back
		int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[TFTeam_Blue]);
		if(iWatcher > MaxClients)
		{
			// Move the cart back to a control point
			int movedBack = Train_MoveBack(TFTeam_Blue);
			if(movedBack == 0)
			{
				PrintToChatAll("%t", "Tank_Chat_Giant_WillSpawnAt_Start", 0x01, g_strTeamColors[TFTeam_Blue], 0x01, 0x04, RoundToNearest(flTimeCooldown), 0x01, g_strRankColors[Rank_Unique], 0x01);	
			}else{
				PrintToChatAll("%t", "Tank_Chat_Giant_WillSpawnAt_ControlPoint", 0x01, g_strTeamColors[TFTeam_Blue], 0x01, 0x04, RoundToNearest(flTimeCooldown), 0x01, g_strRankColors[Rank_Unique], movedBack, 0x01);	
			}

			// Set the train hud to countdown the cooldown period
			SetEntPropFloat(iWatcher, Prop_Send, "m_flRecedeTime", GetGameTime()+flTimeCooldown);
		}

		// Activate the giant spawner to start looking for an eligible player to become the giant robot
		Giant_Cleanup(TFTeam_Blue);
		g_nTeamGiant[TFTeam_Blue][g_bTeamGiantActive] = true;
		g_nTeamGiant[TFTeam_Blue][g_flTeamGiantTimeRoundStarts] = GetEngineTime()+flTimeCooldown-5.0; // time when the spawn process should begin

		Timer_KillStart();
		g_hTimerStart = CreateTimer(flTimeCooldown-5.0, Timer_Spawn_Part1, _, TIMER_REPEAT); // spawns the bomb on the ground
		
		g_countdownTime = 5;
		Timer_KillCountdown();
		g_timerCountdown = CreateTimer(flTimeCooldown-5.1, Timer_Countdown, _, TIMER_REPEAT); // countdown the last 5 seconds before the giant spawns

		Timer_KillAnnounce();
		g_timerAnnounce = CreateTimer(flTimeCooldown-8.1, Timer_SoundGiant, _, TIMER_REPEAT); // Plays a sound to announce the entrance of a giant robot.

		return;
	}

	if(g_nGameMode == GameMode_BombDeploy)
	{
		// A tank and bomb deploy round has been completed, end the game.
		Game_SetWinner(TFTeam_Red);
		return;
	}
}

public Action Timer_SoundGiant(Handle hTimer)
{
	EmitSoundToAll(SOUND_GIANT_START);

	g_timerAnnounce = INVALID_HANDLE;
	return Plugin_Stop;
}

void Tank_PickMVP(int team)
{
	// Print a message that shows who dealt the most damage to the tank
	int iPlayerMvP, iMaxHealth;
	for(int i=1; i<=MaxClients; i++)
	{
		iMaxHealth += g_iDamageStatsTank[i][team];

		if(g_iDamageStatsTank[i][team] > g_iDamageStatsTank[iPlayerMvP][team])
		{
			iPlayerMvP = i;
		}
	}

	if(iPlayerMvP > 0 && IsClientInGame(iPlayerMvP))
	{
		int mvpTeam = GetClientTeam(iPlayerMvP);
		PrintToChatAll("%t", "Tank_Chat_Tank_MVP", g_strTeamColors[team], 0x01, g_strTeamColors[mvpTeam], iPlayerMvP, "\x07CF7336", g_iDamageStatsTank[iPlayerMvP][team], 0x01, 0x04, RoundToCeil(float(g_iDamageStatsTank[iPlayerMvP][team])/float(iMaxHealth)*100.0));

		// Log an event so hlstats can pick it up
		char strAuth[32];
		GetClientAuthId(iPlayerMvP, AuthId_Steam3, strAuth, sizeof(strAuth));
		
		LogToGame("\"%N<%d><%s><%s>\" triggered \"tank_mvp\"", iPlayerMvP, GetClientUserId(iPlayerMvP), strAuth, g_strTeamClass[GetClientTeam(iPlayerMvP)]);
	}

	for(int i=0; i<MAXPLAYERS+1; i++)
	{
		g_iDamageStatsTank[i][team] = 0;
	}
}

public Action Timer_Spawn_Part1(Handle hTimer)
{
	// Start spawning the objects into the playing field
	switch(g_nGameMode)
	{
		case GameMode_Tank:
		{
			Spawner_Spawn(0, Spawn_Tank);
		}
		case GameMode_BombDeploy:
		{
			// Nothing to do here
		}
	}
	
	g_hTimerStart = CreateTimer(2.0, Timer_Spawn_Part2, _, TIMER_REPEAT);
	return Plugin_Stop;
}

public Action Timer_Spawn_Part2(Handle hTimer)
{
	switch(g_nGameMode)
	{
		case GameMode_Tank:
		{
			//
		}
		case GameMode_BombDeploy:
		{	
			// Spawn a bomb that the giant will carry to the goal in the next round
			// Spawning it here because it has to be active for awhile before it can be picked up
			Bomb_KillFlag();
			int iBomb = CreateEntityByName("item_teamflag");
			if(iBomb > MaxClients)
			{
				// Initialize some misc. variables for the bomb round
				g_bBombPlayedNearHatch = false;
				g_bBombEnteredGoal = false;
				g_bombAtFinalCheckpoint = false;
				g_flBombPlantStart = 0.0;
				for(int i=0; i<MAXPLAYERS+1; i++)
				{
					g_flTimeBombDropped[i] = 0.0;
					g_timeBombWarning[i] = 0.0;
				}
				g_flBombGameEnd = 0.0;
				g_flGlobalCooldown = 0.0;
				g_bBombSentDropNotice = false;
				g_bBombGone = false;
				g_flBombLastMessage = 0.0;
				g_finalBombDeployer = 0;
				g_timeControlPointSkipped = 0.0;
				
				DispatchKeyValue(iBomb, "GameType", "2");
				char strTemp[50];
				config.LookupString(g_hCvarBombReturnTime, strTemp, sizeof(strTemp));
				DispatchKeyValue(iBomb, "ReturnTime", strTemp);
				DispatchKeyValue(iBomb, "trail_effect", "3");
				DispatchKeyValue(iBomb, "NeutralType", "1");
				DispatchKeyValue(iBomb, "ScoringType", "0");
				DispatchKeyValue(iBomb, "ReturnBetweenWaves", "1");
				DispatchKeyValue(iBomb, "VisibleWhenDisabled", "0");
				DispatchKeyValue(iBomb, "flag_model", MODEL_BOMB);
				DispatchKeyValue(iBomb, "flag_icon", "../hud/objectives_flagpanel_carried");
				DispatchKeyValue(iBomb, "flag_paper", "player_intel_papertrail");
				DispatchKeyValue(iBomb, "flag_trail", "flagtrail");
				DispatchKeyValue(iBomb, "tags", "");
				
				DispatchSpawn(iBomb);
				
				SetVariantInt(TFTeam_Blue);
				AcceptEntityInput(iBomb, "SetTeam");
				
				AcceptEntityInput(iBomb, "Enable");
				
				float pos[3];
				float ang[3];
				Spawner_LookupSpawnPosition(TFTeam_Blue, Spawn_GiantRobot, pos, ang, true);
				pos[2] -= 20.0;
				TeleportEntity(iBomb, pos, ang, NULL_VECTOR);
				
				HookSingleEntityOutput(iBomb, "OnReturn", Bomb_OnReturned, false);
				HookSingleEntityOutput(iBomb, "OnDrop", Bomb_OnDropped, false);
				HookSingleEntityOutput(iBomb, "OnPickupTeam2", Bomb_OnRobotPickup, false);
				
				SDKHook(iBomb, SDKHook_Touch, Bomb_OnTouch);

				if(g_nTeamGiant[TFTeam_Blue][g_bTeamGiantActive])
				{
					int giant = GetClientOfUserId(g_nTeamGiant[TFTeam_Blue][g_iTeamGiantQueuedUserId]);
					if(giant >= 1 && giant <= MaxClients && IsClientInGame(giant) && IsPlayerAlive(giant) && g_nSpawner[giant][g_bSpawnerEnabled] && g_nSpawner[giant][g_nSpawnerType] == Spawn_GiantRobot
						&& GetEntProp(giant, Prop_Send, "m_bIsMiniBoss"))
					{
#if defined DEBUG
						PrintToServer("(Timer_Spawn_Part2) BOMB SPAWNED AFTER GIANT!");
#endif
						SDK_PickUp(iBomb, giant);
					}
				}


				g_iRefBombFlag = EntIndexToEntRef(iBomb);
#if defined DEBUG
				PrintToServer("(Timer_Spawn_Part2) Created \"item_teamflag\" for bomb round: %d!", iBomb);
#endif
			}else{
				LogMessage("Failed to create \"item_teamflag\" for bomb mini-round!");
			}
		}
	}
	
	g_hTimerStart = CreateTimer(3.0, Timer_Spawn_Part3, _, TIMER_REPEAT);
	return Plugin_Stop;
}

public Action Timer_Spawn_Part3(Handle hTimer)
{
	switch(g_nGameMode)
	{
		case GameMode_Tank:
		{
			// Set the tank able to take damage and start moving the cart forward
			g_bIsRoundStarted = true;

			// Disable the hybird ctf/cp HUD
			Tank_BombDeployHud(false);

			Tank_SetDefaultHealth(TFTeam_Blue);
			
			Train_Move(TFTeam_Blue, 1.0);
			BroadcastSoundToTeam(TFTeam_Spectator, "MVM.TankStart");
			BroadcastSoundToTeam(TFTeam_Red, "Announcer.MVM_Tank_Alert_Another");
			Tank_SetNoTarget(TFTeam_Blue, false);
		}
		case GameMode_BombDeploy:
		{
			g_bIsRoundStarted = true;

			// Enable the hybird ctf/cp HUD
			Tank_BombDeployHud(true);

			// Stop the trains from coming during the bomb round
			// They will be re-enabled when the bomb carrier gets close to the control point
			if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale) CactusCanyon_EnableTrain(false);

			int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[TFTeam_Blue]);
			if(iWatcher > MaxClients)
			{
				SetEntPropFloat(iWatcher, Prop_Send, "m_flRecedeTime", 0.0);
			}
			
			// Try to find the current queued player to become the giant
			// If there is none, then send out a message prompting players to pick up the bomb
			int iGiant = GetClientOfUserId(g_nTeamGiant[TFTeam_Blue][g_iTeamGiantQueuedUserId]);
			if(iGiant <= 0 || iGiant > MaxClients)
			{
				Handle hEvent = CreateEvent("show_annotation");
				if(hEvent != INVALID_HANDLE)
				{
					char text[256];
					Format(text, sizeof(text), "%T", "Tank_Annotation_Bomb_Spawned", LANG_SERVER);
					SetEventString(hEvent, "text", text);

					// Put message at the cart where the bomb will spawn
					float flPos[3];
					int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[TFTeam_Blue]);
					if(iTrackTrain > MaxClients)
					{
						GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPos);
					}
					SetEventFloat(hEvent, "worldPosX", flPos[0]);
					SetEventFloat(hEvent, "worldPosY", flPos[1]);
					SetEventFloat(hEvent, "worldPosZ", flPos[2]);
					SetEventInt(hEvent, "id", Annotation_BombSpawned);
					SetEventFloat(hEvent, "lifetime", 5.0);
					SetEventString(hEvent, "play_sound", "misc/null.wav");
					
					FireEvent(hEvent); // Frees the handle			
				}

				PrintToChatAll("%t", "Tank_Chat_BombSpawned_AtCart", 0x01, g_strTeamColors[TFTeam_Blue], 0x01);
			}
			
			// Spawn a bomb team flag near the cart and start the bomb round timer.
			Bomb_KillTimer();
			int iTimer = CreateEntityByName("team_round_timer");
			if(iTimer > MaxClients)
			{
				DispatchKeyValue(iTimer, "targetname", TARGETNAME_OVERTIME_TIMER);

				DispatchSpawn(iTimer);
				
				SetVariantInt(RoundToNearest(config.LookupFloat(g_hCvarBombRoundTime) * 60.0));
				AcceptEntityInput(iTimer, "SetTime");
				
				SetVariantInt(1);
				AcceptEntityInput(iTimer, "ShowInHUD");
				
				AcceptEntityInput(iTimer, "Enable");
				
				g_iRefBombTimer = EntIndexToEntRef(iTimer);
				
				// OnFinished doesn't fire because sometimes the timer goes into overtime
				HookSingleEntityOutput(iTimer, "On3SecRemain", Bomb_3SecRemain, false);
			}else{
				LogMessage("Failed to create \"team_round_timer\" for bomb mini-round!");
			}
		}
	}
	
	g_hTimerStart = INVALID_HANDLE;
	return Plugin_Stop;
}

void Bomb_KillTimer()
{
	if(g_iRefBombTimer != 0)
	{
		int iTimer = EntRefToEntIndex(g_iRefBombTimer);
		if(iTimer > MaxClients)
		{
			AcceptEntityInput(iTimer, "Kill");
		}
		
		g_iRefBombTimer = 0;
	}
}

void Bomb_KillFlag()
{
	if(g_iRefBombFlag != 0)
	{
		int iBomb = EntRefToEntIndex(g_iRefBombFlag);
		if(iBomb > MaxClients)
		{
			AcceptEntityInput(iBomb, "Kill");
		}
		
		g_iRefBombFlag = 0;
	}
}

public Action Timer_EntityCleanup(Handle hTimer, int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if(iEntity > MaxClients)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
	
	return Plugin_Handled;
}

public Action Tank_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	//PrintToServer("(Tank_OnTakeDamage) victim: %d, attacker: %d, inflictor: %d, damage: %.2f, damagetype: %d, weapon: %d", victim, attacker, inflictor, damage, damagetype, weapon);
	g_bTakingSentryDamage = false;

	if(!g_bIsRoundStarted || g_bRaceIntermission)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	if(attacker >= 1 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) != GetEntProp(victim, Prop_Send, "m_iTeamNum"))
	{
		//PrintToServer("(Tank_OnTakeDamage) Victim: %d Attacker: %d Inflictor: %d Damage: %0.2f Type: %d", victim, attacker, inflictor, damage, damagetype);
		//for(int i=0; i<30; i++) if(damagetype & (1 << i)) PrintToServer("Damagetype: %d", i);
		
		// Keep track of sentry damage to the tank
		if(inflictor > MaxClients)
		{
			char strInflictor[32];
			GetEdictClassname(inflictor, strInflictor, sizeof(strInflictor));
			//PrintToServer("inflictor: \"%s\"", strInflictor);
			if(strcmp(strInflictor, "obj_sentrygun") == 0 || strcmp(strInflictor, "tf_projectile_sentryrocket") == 0)
			{
				bool countDamage = true;
				// Mini-sentry damage to tanks will no longer activate a sentry buster unless it is a giant's mini-sentry.
				if(strcmp(strInflictor, "obj_sentrygun") == 0 && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding"))
				{
					int builder = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
					if(builder >= 1 && builder <= MaxClients && IsClientInGame(builder) && !GetEntProp(builder, Prop_Send, "m_bIsMiniBoss"))
					{
						countDamage = false;
					}
				}

				if(countDamage) g_bTakingSentryDamage = true;
			}
		}

		if(weapon > MaxClients)
		{
			char strWeapon[32];
			GetEdictClassname(weapon, strWeapon, sizeof(strWeapon));
 			if(damagetype & DMG_CRIT && strcmp(strWeapon, "tf_weapon_flamethrower") == 0 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == ITEM_PHLOG && !TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged))
 			{
				// The phlog's rage damage to the tank is devastating and gamebreaking so it needs a nerf
				damage = damage * 0.73;
				return Plugin_Changed;
 			}


		}
		
		return Plugin_Continue;
	}
	
	damage = 0.0;
	return Plugin_Changed;
}

public Action Player_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	/*
	PrintToServer("victim: %d attacker: %d inflictor: %d damage: %0.2f damagetype: %d weapon: %d damageForce: (%0.2fx%0.2fy%0.2fz) damageCustom: %d", victim, attacker, inflictor, damage, damagetype, weapon, damageForce[0], damageForce[1], damageForce[2], damagecustom);
	char debugWeaponClass[32];
	char debugInflictorClass[32];
	if(weapon > MaxClients) GetEdictClassname(weapon, debugWeaponClass, sizeof(debugWeaponClass));
	if(inflictor >= 0) GetEdictClassname(inflictor, debugInflictorClass, sizeof(debugInflictorClass));
	PrintToServer("weapon = %s, inflictor = %s", debugWeaponClass, debugInflictorClass);
	for(int i=0; i<30; i++) if(damagetype & (1 << i)) PrintToServer("(1 << %d)", i);
	int removeMe;
	*/

	g_bTakingSentryDamage = false;
	
	if(!g_bEnabled) return Plugin_Continue;

	char inflictorClass[32];
	if(inflictor >= 0) GetEdictClassname(inflictor, inflictorClass, sizeof(inflictorClass));

	bool overrideReturn = false;

	if(attacker >= 1 && attacker <= MaxClients && g_nSpawner[attacker][g_bSpawnerEnabled] && g_nSpawner[attacker][g_nSpawnerType] == Spawn_GiantRobot && GetEntProp(attacker, Prop_Send, "m_bIsMiniBoss"))
	{
		// Increase knockback on victim for melee damage
		if((Spawner_HasGiantTag(attacker, GIANTTAG_MELEE_KNOCKBACK) || Spawner_HasGiantTag(attacker, GIANTTAG_MELEE_KNOCKBACK_CRITS)) && weapon > MaxClients && victim != attacker && victim >= 1 && victim <= MaxClients)
		{
			TFClassType classAttacker = TF2_GetPlayerClass(attacker);
			// Determine if damage done is by the giant's melee weapon. (damagetype of DMG_CLUB can also indicate melee damage.)
			int iMelee = GetPlayerWeaponSlot(attacker, WeaponSlot_Melee);
			if(iMelee > MaxClients && iMelee == weapon && (!Spawner_HasGiantTag(attacker, GIANTTAG_MELEE_KNOCKBACK_CRITS) || damagetype & DMG_CRIT))
			{
				// HACK: damageForce seems to be very high on non-soldiers so scale it down
				if(classAttacker != TFClass_Soldier)
				{
					if(classAttacker == TFClass_Engineer)
					{
						for(int i=0; i<3; i++) damageForce[i] *= 0.0033333333333; // 300x
					}else{
						for(int i=0; i<3; i++) damageForce[i] *= 0.0126582278481; // 79x
					}
				}
#if defined DEBUG
				PrintToServer("(Player_OnTakeDamage) Melee damage done by giant! (damage %f) (weapon %d) (force %f %f %f)", damage, weapon, damageForce[0], damageForce[1], damageForce[2]);
#endif
				float flScale = 3.0;
				if(GetEntProp(victim, Prop_Send, "m_bIsMiniBoss")) flScale = 2.0;

				ScaleVector(damageForce, flScale);

				if(damageForce[2] < 400.0) damageForce[2] = 400.0;
				//PrintToServer("Final force: %f %f %f", damageForce[0], damageForce[1], damageForce[2]);
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, damageForce);

				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				overrideReturn = true;
			}
		}

		// Keep track of melee strikes for the "gunslinger_combo" giant template tag.
		if(Spawner_HasGiantTag(attacker, GIANTTAG_GUNSLINGER_COMBO) && weapon > MaxClients && victim != attacker && victim >= 1 && victim <= MaxClients)
		{
			int melee = GetPlayerWeaponSlot(attacker, WeaponSlot_Melee);
			if(melee > MaxClients && melee == weapon)
			{
				if(damagetype & DMG_CRIT)
				{
					g_numSuccessiveHits[attacker] = -1;
				}else if(g_timeNextMeleeAttack[attacker] != 0.0 && GetGameTime() < g_timeNextMeleeAttack[attacker])
				{
					g_numSuccessiveHits[attacker]++;
				}else{
					g_numSuccessiveHits[attacker] = 0;
				}

#if defined DEBUG
				PrintToServer("(Player_OnTakeDamage) Time between melee hits for %N (%d): %1.2f", attacker, g_numSuccessiveHits[attacker], g_timeNextMeleeAttack[attacker] - GetGameTime());
#endif
				g_timeNextMeleeAttack[attacker] = GetEntPropFloat(melee, Prop_Send, "m_flNextPrimaryAttack") + 0.5;
			}
		}

		// Keep track of what players are hurt by the sentry buster's env_explosion so we can avoid hurting them again.
		if(Spawner_HasGiantTag(attacker, GIANTTAG_SENTRYBUSTER) && inflictor > MaxClients && victim != attacker && victim >= 1 && victim <= MaxClients && IsClientInGame(victim))
		{
			if(strcmp(inflictorClass, "env_explosion") == 0)
			{
#if defined DEBUG
				PrintToServer("(Player_OnTakeDamage) %N was hurt by the sentry buster..", victim);
#endif
				g_hitBySentryBuster[victim] = true;
			}
		}

		// Valve introduced a bug in Touch Break. The "damage bonus" attribute isn't being applied on cannon ball impacts.
		if(Spawner_HasGiantTag(attacker, GIANTTAG_PIPE_EXPLODE_SOUND) && victim != attacker && victim >= 1 && victim <= MaxClients && IsClientInGame(victim))
		{
			if(weapon > MaxClients && damagecustom == TF_CUSTOM_CANNONBALL_PUSH && strcmp(inflictorClass, "tf_projectile_pipe") == 0)
			{
				float value;
				if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == ITEM_LOOSE_CANNON && Tank_GetAttributeValue(weapon, ATTRIB_DAMAGE_BONUS, value))
				{
#if defined DEBUG
					PrintToServer("(Player_OnTakeDamage) Giant %N had cannonball impact on another player, multiplying damage by %1.2f..", attacker, value);
#endif
					damage *= value;
					overrideReturn = true;
				}
			}
		}
	}

	if(victim >= 1 && victim <= MaxClients && g_nSpawner[victim][g_bSpawnerEnabled] && g_nSpawner[victim][g_nSpawnerType] == Spawn_GiantRobot && GetEntProp(victim, Prop_Send, "m_bIsMiniBoss"))
	{
		// Catch when the giant comes out of the minify magic spell and block the damage.
		if(victim == attacker && victim == inflictor && damagetype == 1 && weapon == -1 && damagecustom == 0 && damage == 9999.0)
		{
#if defined DEBUG
			PrintToServer("(Player_OnTakeDamage) %N took damage coming out of a minify magic spell..", victim);
#endif
			return Plugin_Stop;
		}

		// Catch when the sentry buster hits one health and self-destruct
		if(g_nGiants[g_nSpawner[victim][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
		{
			if(g_flTimeBusterTaunt[victim] == 0.0)
			{
				if(GetClientHealth(victim) == 1)
				{
					// Condition 70 will catch the sentry buster from being killed, letting us self-destruct
					// Try to make the player taunt but be prepared if they are not taunting
					FakeClientCommand(victim, "taunt");
					SDK_PlaySpecificSequence(victim, "sentry_buster_preExplode"); // in case they weren't able to taunt

					if(g_flTimeBusterTaunt[victim] == 0.0) // taunt command didn't go through
					{
						SetEntPropFloat(victim, Prop_Send, "m_flMaxspeed", 0.0);
						Tank_SetAttributeValue(victim, ATTRIB_MAJOR_MOVE_SPEED_BONUS, 0.001);
						TF2_AddCondition(victim, TFCond_SpeedBuffAlly, 0.001);
						TF2_RemoveCondition(victim, TFCond_SpeedBuffAlly);

						g_flTimeBusterTaunt[victim] = GetEngineTime();

						EmitSoundToAll(SOUND_BUSTER_SPIN, victim);
					}

					damage = 0.0;
					return Plugin_Changed;
				}else{
					// Player's health hasn't reached 1 yet so make sure the prevent death condition stays applied
					TF2_AddCondition(victim, TFCond_PreventDeath, -1.0);
				}
			}else if(g_flTimeBusterTaunt[victim] != 0.0)
			{
				// Buster is armed so we should block all further damage
				damage = 0.0;
				return Plugin_Changed;
			}
		}

		// Make death pits a little kinder to Giant Robots.
		if(config.LookupBool(g_hCvarGiantDeathpitBoost) && damage >= 450.0 && attacker > MaxClients && attacker == inflictor && strcmp(inflictorClass, "trigger_hurt") == 0 && (g_timeGiantEnteredDeathpit[victim] == 0.0 || GetEngineTime() - g_timeGiantEnteredDeathpit[victim] >= config.LookupFloat(g_hCvarGiantDeathpitCooldown)))
		{
#if defined DEBUG
			PrintToServer("(Player_OnTakeDamage) %N hurt by death pit, boosting him out..", victim);
#endif
			float fallDamage = config.LookupFloat(g_hCvarGiantDeathpitDamage);
			if(float(GetClientHealth(victim)) > fallDamage)
			{
				g_timeGiantEnteredDeathpit[victim] = GetEngineTime();

				Deathpit_Boost(victim);

				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				damage = fallDamage;
				return Plugin_Changed;
			}
		}

		// Cap the damage that the HHH can do against giant robots.
		if(attacker > MaxClients && attacker == inflictor && damagecustom == TF_CUSTOM_DECAPITATION_BOSS && strcmp(inflictorClass, "headless_hatman") == 0)
		{
			float damageCap = GetConVarFloat(g_hCvarGiantHHHCap);
			if(damage > damageCap)
			{
#if defined DEBUG
				PrintToServer("(Player_OnTakeDamage) Giant %N took too much damage (%1.2f) from HHH boss, capping at %1.2f..", victim, damage, damageCap);
#endif
				damage = damageCap;
				return Plugin_Changed;
			}
		}

		if(attacker >= 1 && attacker <= MaxClients && victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker))
		{
			// Only track sentry damage to giant players.
			if(inflictor > MaxClients)
			{
				//PrintToServer("inflictor: \"%s\"", inflictorClass);
				if(strcmp(inflictorClass, "obj_sentrygun") == 0 || strcmp(inflictorClass, "tf_projectile_sentryrocket") == 0)
				{
					bool countDamage = true;
					// Mini-sentry damage to tanks will no longer activate a sentry buster unless it is a giant's mini-sentry.
					if(strcmp(inflictorClass, "obj_sentrygun") == 0 && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding"))
					{
						int builder = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
						if(builder >= 1 && builder <= MaxClients && IsClientInGame(builder) && !GetEntProp(builder, Prop_Send, "m_bIsMiniBoss"))
						{
							countDamage = false;
						}
					}

					if(countDamage) g_bTakingSentryDamage = true;
				}
			}

			if(Spawner_HasGiantTag(attacker, GIANTTAG_SENTRYBUSTER) && GetEntProp(attacker, Prop_Send, "m_bIsMiniBoss"))
			{
				// Cap sentry buster damage to other giants.
				if(damage > config.LookupFloat(g_hCvarBusterCap))
				{
					damage = config.LookupFloat(g_hCvarBusterCap);
					return Plugin_Changed;
				}
			}

			if(weapon > MaxClients)
			{
				// Note: that the weapon param may not be a weapon, such is the case of monoculus's rockets
				char weaponClass[32];
				GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));

				if(damagecustom == TF_CUSTOM_BACKSTAB && damagetype & DMG_CRIT && strcmp(weaponClass, "tf_weapon_knife") == 0)
				{
					// Someone just backstabbed the giant so set a custom damage and apply a less severe force
					damage = config.LookupFloat(g_hCvarGiantKnifeDamage) / 3.0; // Crits multiply damage force by 3
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;

					ScaleVector(damageForce, 0.03);
					for(int i=0; i<3; i++) if(damageForce[i] > 300.0) damageForce[i] = 300.0; else if(damageForce[i] < -300.0) damageForce[i] = -300.0;

					TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, damageForce);

					//PrintToChatAll("New velocity %0.2fx%0.2fy%0.2fz", damageForce[0], damageForce[1], damageForce[2]);

					// Indicate to the giant that he is getting backstabbed.
					EmitSoundToClient(victim, SOUND_BACKSTAB);
					

					g_overrideSound = true;
					EmitSoundToClient(victim, g_soundBusterStabbed[GetRandomInt(0, sizeof(g_soundBusterStabbed)-1)]);
					PrintCenterText(victim, "%t", "Tank_Center_Backstabbed");

					// Generate an earth quake effect to make the backstab more apparent.
					// void UTIL_ScreenShake(float center[3], float amplitude, float frequency, float duration, float radius, int command, bool airShake)
					//UTIL_ScreenShake(flPos, 25.0, 5.0, 5.0, 1000.0, 0, false);
					Handle msg = StartMessageOne("Shake", victim, USERMSG_RELIABLE);
					if(msg != null)
					{
						BfWriteByte(msg, Shake_Start);
						BfWriteFloat(msg, 15.0);
						BfWriteFloat(msg, 15.0);
						BfWriteFloat(msg, 1.0);

						EndMessage();
					}

					// Block the attacker from making repetitive backstabs. In contrast to the razorback, we will allow the spy to cloak. 
					EmitSoundToClient(attacker, SOUND_BACKSTAB);
					SDK_SendWeaponAnim(weapon, 0x61B);
					float gameTime = GetGameTime()+2.5;
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", gameTime);
					//SetEntDataFloat(weapon, g_offset_m_knifeSapped, GetGameTime()); // This prevents the player from being to switch weapons.

					return Plugin_Changed;
				}else if(inflictor > MaxClients && damagetype & DMG_PREVENT_PHYSICS_FORCE && strcmp(weaponClass, "tf_weapon_flaregun") == 0 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == ITEM_SCORCH_SHOT)
				{
					// The Scorch Shot flare shot on burning enemies has the projectile as the inflictor.
					//PrintToServer("inflictor = %s", inflictorClass);
					if(strcmp(inflictorClass, "tf_projectile_flare") == 0)
					{
						// Gun Mettle has changed how the Scorch Shot deals knockpack.
						// It is not associated with OnTakeDamage anymore. Here is the sequence of events:
						// 1. OnTakeDamage is called.
						// 2. Knockback is dealt.
						// 3. physics/rubber/rubber_tire_impact_bullet1.wav is played to the projectile.
						// Set a flag here if we need to enable MegaHeal in order to cancel out the normal knockback.
						// We will apply our own weaker knockback effect instead.
						// When the sound is played, we can remove MegaHeal.
						if(!TF2_IsPlayerInCondition(victim, TFCond_MegaHeal) && TF2_IsPlayerInCondition(victim, TFCond_OnFire))
						{
#if defined DEBUG
							PrintToServer("(Player_OnTakeDamage) %N got hit by a scorch shot. We need to cancel out the knockback..", victim);
#endif
							g_hitWithScorchShot = GetClientUserId(victim);

							float vel[3];
							vel[0] = GetRandomFloat(-100.0, 100.0);
							vel[1] = GetRandomFloat(-100.0, 100.0);
							vel[2] = 400.0;
							TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);

							TF2_AddCondition(victim, TFCond_MegaHeal, 0.01);
						}
					}
				}
				
				if(inflictor > MaxClients && strcmp(inflictorClass, "tf_projectile_pipe") == 0)
				{
					int origLauncher = GetEntPropEnt(inflictor, Prop_Send, "m_hOriginalLauncher");
					if(origLauncher > MaxClients && GetEntProp(origLauncher, Prop_Send, "m_iItemDefinitionIndex") == ITEM_LOOSE_CANNON)
					{
#if defined DEBUG
						PrintToServer("(Player_OnTakeDamage) Giant %N was hit by the loose cannon..", victim);
#endif
						// If the projectile is reflected, cap the damage that can be done to the giant.
						int owner = GetEntPropEnt(origLauncher, Prop_Send, "m_hOwner");
						if(owner >= 1 && owner <= MaxClients && victim == owner)
						{
							// Valve introduced a bug in Touch Break. The "damage bonus" attribute isn't being applied on cannon ball impacts.
							float value;
							if(Spawner_HasGiantTag(victim, GIANTTAG_PIPE_EXPLODE_SOUND) && Tank_GetAttributeValue(origLauncher, ATTRIB_DAMAGE_BONUS, value))
							{
#if defined DEBUG
								PrintToServer("(Player_OnTakeDamage) Giant %N was hit by his own cannonball, multiplying damage by %1.2f..", victim, value);
#endif
								damage *= value;
								overrideReturn = true;
							}

							float damageCap = config.LookupFloat(g_hCvarSirNukesCap);
							if(damagetype & DMG_CRIT) damageCap = config.LookupFloat(g_hCvarSirNukesCap) / 3.0;

							if(damage > damageCap)
							{
#if defined DEBUG
								PrintToServer("(Player_OnTakeDamage) Capping cannonball damage done to Giant %N to: %1.2f..", victim, damageCap);
#endif
								damage = damageCap;
								overrideReturn = true;
							}
						}

						// See notes above on how knockback is canceled out.
						if(!TF2_IsPlayerInCondition(victim, TFCond_MegaHeal))
						{
#if defined DEBUG
							PrintToServer("(Player_OnTakeDamage) Nulling out loose cannon knockback on Giant %N..", victim);
#endif
							// Giant was hit directly with a cannon ball. Substitute knockback with our own.
							g_hitWithScorchShot = GetClientUserId(victim);

							// Only provide knockback on direct hits with the loose cannon.
							if(damagecustom == TF_CUSTOM_CANNONBALL_PUSH)
							{
								float vel[3];
								vel[0] = GetRandomFloat(-100.0, 100.0);
								vel[1] = GetRandomFloat(-100.0, 100.0);
								vel[2] = 300.0;
								TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
							}

							TF2_AddCondition(victim, TFCond_MegaHeal, 0.01);
						}
					}
				}
			}
		}

		if(attacker > MaxClients)
		{
			// Block tank damage to the giant
			for(int iTeam=2; iTeam<=3; iTeam++)
			{
				if(g_iRefTank[iTeam] != 0 && EntRefToEntIndex(g_iRefTank[iTeam]) == attacker)
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}

	if(victim >= 1 && victim <= MaxClients)
	{
		// Track when damage is done to a player with a robot model.
		if(GetClientTeam(victim) == TFTeam_Blue || g_nGameMode == GameMode_Race)
		{
			g_timeLastRobotDamage = GetEngineTime();
		}
	}

	if(overrideReturn) return Plugin_Changed;
	return Plugin_Continue;
}

public Action Player_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(!g_bEnabled) return Plugin_Continue;

	// The game runs a trace attack before World/Entity Decals are created
	// Use the victim as a reference to who made the blood stain
	if(victim >= 1 && victim <= MaxClients)
	{
		g_iUserIdLastTrace = GetClientUserId(victim);
		g_flTimeLastTrace = GetEngineTime();
	}

	return Plugin_Continue;
}

void Tank_CleanUp()
{
	int iTank = MaxClients+1;
	while((iTank = FindEntityByClassname(iTank, "tank_boss")) > MaxClients)
	{
		AcceptEntityInput(iTank, "Kill");
	}
	
	for(int i=0; i<MAX_TEAMS; i++)
	{
		g_iRefTank[i] = 0;
		g_iRefTankMechanism[i] = 0;
		g_iRefTankTrackL[i] = 0;
		g_iRefTankTrackR[i] = 0;

		g_iRefPointPush[i] = 0;
	}
}

void Player_SetDefaultMetal(int client)
{
	SetEntProp(client, Prop_Send, "m_iAmmo", MaxMetal_Get(client), 4, 3);
}

public void OnGameFrame()
{
	if(!g_bEnabled) return;

	// Run a routine every frame to take care of tank logic code
	int iTank = EntRefToEntIndex(g_iRefTank[TFTeam_Blue]);
	if(iTank > MaxClients)
	{
		if(g_nGameMode == GameMode_Race)
		{
			Tank_ThinkRace(iTank);
		}else{
			Tank_Think(iTank);
		}
	}
	iTank = EntRefToEntIndex(g_iRefTank[TFTeam_Red]);
	if(iTank > MaxClients)
	{
		if(g_nGameMode == GameMode_Race)
		{
			Tank_ThinkRace(iTank);
		}else{
			Tank_Think(iTank);
		}		
	}
	
	// Do the same for the bomb entity
	int iBomb = EntRefToEntIndex(g_iRefBombFlag);
	if(iBomb > MaxClients)
	{
		Bomb_Think(iBomb);
	}

	// During setup, give ALL engineers quick build and full metal
	if(Tank_IsInSetup())
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				switch(TF2_GetPlayerClass(i))
				{
					case TFClass_Engineer: // During setup, give ALL engineers full metal
					{
						Player_SetDefaultMetal(i);
					}
					case TFClass_Medic:
					{
						int medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
						if(medigun > MaxClients)
						{
							char className[32];
							GetEdictClassname(medigun, className, sizeof(className));
							if(strcmp(className, "tf_weapon_medigun") == 0)
							{
								// Prevent the vaccinator from awarding invuln points during setup.
								// The vaccinator works a little bit differently. After 4 uber chunks are deployed, then 1 point is awarded in the scoreboard under Invulns.
								// Reset the counter for the chucks to 0 so the point is never awarded.
								if(g_iOffset_m_uberChunk > 0)
								{
									SetEntData(medigun, g_iOffset_m_uberChunk, 0, 4);
								}
							}
						}
					}
				}
			}
		}
	}

	// Run the logic for keeping track of sentry busters
	Buster_Think(TFTeam_Blue);
	if(g_nGameMode == GameMode_Race) Buster_Think(TFTeam_Red); // There are RED sentry busters in plr_ maps
	
	// Run rage meter logic
	RageMeter_Tick();

	// Set the last think time for the buster timer trigger
	float flCurrentTime = GetEngineTime();
	g_nBuster[TFTeam_Blue][g_flBusterTimeLastThink] = flCurrentTime;
	g_nBuster[TFTeam_Red][g_flBusterTimeLastThink] = flCurrentTime;	

	// Run the logic keeping track of player giants
	Giant_Think(TFTeam_Blue);
	if(g_nGameMode == GameMode_Race) Giant_Think(TFTeam_Red);

	// Recreate minigun sounds for giant heavies
	for(int i=1; i<=MaxClients; i++)
	{
		if(Spawner_HasGiantTag(i, GIANTTAG_MINIGUN_SOUNDS) && IsClientInGame(i) && GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
		{
			int iMinigun = GetPlayerWeaponSlot(i, TFWeaponSlot_Primary);
			if(iMinigun > MaxClients)
			{
				char strClass[20];
				GetEdictClassname(iMinigun, strClass, sizeof(strClass));
				if(strcmp(strClass, "tf_weapon_minigun") == 0)
				{
					int iWeaponState = GetEntProp(iMinigun, Prop_Send, "m_iWeaponState");
					if(iWeaponState != g_iGiantOldState[i])
					{
						switch(iWeaponState)
						{
							case MinigunState_Idle:
							{
								EmitSoundToAll(SOUND_GIANT_MINIGUN_RAISING, i, SNDCHAN_WEAPON);
								//PrintToServer("Going idle, clearing sounds and playing raising!");
							}
							case MinigunState_Lowering:
							{
								// This state is only entered when the player lowers the gun for the first time
								// When they stop shooting, it goes straight to idle
								EmitSoundToAll(SOUND_GIANT_MINIGUN_LOWERING, i, SNDCHAN_WEAPON);
								//PrintToServer("Playing lowering sound!");
							}
							case MinigunState_Shooting:
							{
								EmitSoundToAll(SOUND_GIANT_MINIGUN_SHOOTING, i, SNDCHAN_WEAPON);
								//PrintToServer("Playing shooting sound!");
							}
							case MinigunState_Spinning:
							{
								EmitSoundToAll(SOUND_GIANT_MINIGUN_SPINNING, i, SNDCHAN_WEAPON);
								//PrintToServer("Playing minigun spinning sound!");
							}
						}
						
						g_iGiantOldState[i] = iWeaponState;
					}
				}
			}
		}
	}

	// Logic for the giant engineer teleporter
	for(int iTeam=2; iTeam<=3; iTeam++)
	{
		if(g_nGiantTeleporter[iTeam][g_iGiantTeleporterRefExit] != 0)
		{
			GiantTeleporter_Think(iTeam);
		}
	}

	// Logic for sentry vision
	SentryVision_Think();

	if(g_nGameMode == GameMode_Race) Announcer_Think();

	g_timeSentryBusterDied = 0.0;
}

void Tank_CheckForStuckPlayers(int iTank, int team)
{
	float flPosPlayer[3];
	float flMins[3];
	float flMaxs[3];

	float flPosTank[3];
	int iParent = GetEntPropEnt(iTank, Prop_Send, "moveparent");

	if(iParent > MaxClients)
	{
		// Tank is parented so use the location of the parent instead
		GetEntPropVector(iParent, Prop_Send, "m_vecOrigin", flPosTank);
	}else{
		GetEntPropVector(iTank, Prop_Send, "m_vecOrigin", flPosTank);
	}

	float flTime = GetEngineTime();
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			// Don't bother checking if the player is too far from the tank
			GetClientAbsOrigin(i, flPosPlayer);
			if(GetVectorDistance(flPosPlayer, flPosTank) < 300.0)
			{
				// Player could be stuck so check
				GetClientMins(i, flMins);
				GetClientMaxs(i, flMaxs);
				/*
				for(int a=0; a<3; a++)
				{
					flMins[a] -= 10.0;
					flMins[a] += 10.0;
				}
				*/

				TR_TraceHullFilter(flPosPlayer, flPosPlayer, flMins, flMaxs, MASK_SOLID, TraceFilter_Tank, iTank);

				if(TR_DidHit())
				{
					// Player is stuck
					if(g_flTimeStuckInTank[i][team] == 0.0)
					{
						// Player just got stuck
						g_flTimeStuckInTank[i][team] = flTime;
					}else if(flTime - g_flTimeStuckInTank[i][team] > config.LookupFloat(g_hCvarTankStuckTime))
					{
						// Player has been stuck for tank_stuck_time so teleport them to safety
#if defined DEBUG
						PrintToServer("(Tank_CheckForStuckPlayers) %N is STUCK!", i);
#endif
						flPosTank[2] += 30.0;
						Player_FindFreePosition2(i, flPosTank, flMins, flMaxs);

						g_flTimeStuckInTank[i][team] = 0.0;
					}
				}else{
					// Player is NOT stuck
					g_flTimeStuckInTank[i][team] = 0.0;
				}
			}else{
				g_flTimeStuckInTank[i][team] = 0.0;
			}
		}
	}
}

bool Player_FindFreePosition2(int client, float position[3], float mins[3], float maxs[3])
{
	int team = GetClientTeam(client);
	int mask = MASK_RED;
	if(team != TFTeam_Red) mask = MASK_BLUE;

	// -90 to 90
	float pitchMin = 75.0; // down
	float pitchMax = -89.0; // up
	float pitchInc = 10.0;

	float yawMin = -180.0;
	float yawMax = 180.0;
	float yawInc = 10.0;

	float radiusMin = 150.0; // 150.0
	float radiusMax = 300.0;
	float radiusInc = 25.0; // 25.0

#if defined DEBUG
	int anglesTried = 0;
	int hitWall = 0;
	int radiusTried = 0;
	float time = GetEngineTime();
#endif

	float ang[3];

	for(float p=pitchMin; p>=pitchMax; p-=pitchInc)
	{
		ang[0] = p;
		for(float y=yawMin; y<=yawMax; y+=yawInc)
		{
			ang[1] = y;
#if defined DEBUG
			anglesTried++;
#endif

			for(float r=radiusMin; r<=radiusMax; r+=radiusInc)
			{
#if defined DEBUG
				radiusTried++;
#endif
				float freePosition[3];
				GetPositionForward(position, ang, freePosition, r);

				// Perform a line of sight check to avoid spawning players in unreachable map locations.
				// The tank has this weird bug where players can be pushed into map displacements and can sometimes go completely through a wall.
				TR_TraceRayFilter(position, freePosition, mask, RayType_EndPoint, TraceFilter_LOS);

				if(!TR_DidHit())
				{
					TR_TraceHullFilter(freePosition, freePosition, mins, maxs, mask, TraceFilter_NotTeam, team);

					if(!TR_DidHit())
					{
#if defined DEBUG
						PrintToServer("(Player_FindFreePosition2) Found a position to spawn %N in %d angles, took %1.4fs:\n  angle: %1.2f %1.2f\t\tradius: %1.2f", client, anglesTried, GetEngineTime()-time, ang[0], ang[1], r);
#endif
						TeleportEntity(client, freePosition, NULL_VECTOR, NULL_VECTOR);

						EmitSoundToClient(client, SOUND_TELEPORT);
						if(g_iParticleTeleport != -1)
						{
							freePosition[2] += 30.0;
							TE_Particle(g_iParticleTeleport, freePosition);
							TE_SendToAll();
						}

						return true;
					}
				}else{
					// We hit a wall, breaking line of sight. Give up on this angle.
#if defined DEBUG
					hitWall++;
#endif
					break;
				}
			}
		}
	}

#if defined DEBUG
	PrintToServer("(Player_FindFreePosition) Failed to find a spawn position after %d angles %d radius, took %1.4fs. Hit wall %d.", anglesTried, radiusTried, GetEngineTime()-time, hitWall);
#endif

	return false;
}

/*
bool Player_FindFreePosition(int client, float position[3], float mins[3], float maxs[3])
{
	int team = GetClientTeam(client);
	// We need to find a spot where the player will not get stuck
	// Go around the tank in a circle and try to find a spawn spot at various heights
	float flRadiusMin = 200.0; // 6
	float flRadiusMax = 300.0;
	float flRadiusInc = 25.0;

	float flAngleMin = 0.0; // 12
	float flAngleMax = 2.0*PI;
	float flAngleInc = PI/6.0; 

	float flHeightMin = -100.0; // 12
	float flHeightMax = 200.0;
	float flHeightInc = 25.0;

#if defined DEBUG
	int debugCount = 0;
	float time = GetEngineTime();
#endif

	for(float angle=flAngleMin; angle<flAngleMax; angle+=flAngleInc)
	{
		for(float radius=flRadiusMin; radius<flRadiusMax; radius+=flRadiusInc)
		{
			for(float height=flHeightMin; height<flHeightMax; height+=flHeightInc)
			{
#if defined DEBUG
				debugCount++;
#endif
				float flPos[3];
				flPos[0] = position[0] + radius * Cosine(angle);
				flPos[1] = position[1] + radius * Sine(angle);
				flPos[2] = position[2] + height;

				int mask = MASK_RED;
				if(team != TFTeam_Red) mask = MASK_BLUE;
				TR_TraceHullFilter(flPos, flPos, mins, maxs, mask, TraceFilter_NotTeam, team);

				if(!TR_DidHit())
				{
					// We found a spot where the player will not be stuck!

					// Perform a line of sight check to avoid spawning players in unreachable map locations.
					// The tank has this weird bug where players can be pushed into map displacements and can sometimes go completely into a wall.
					TR_TraceRayFilter(position, flPos, mask, RayType_EndPoint, TraceFilter_LOS);

					if(!TR_DidHit())
					{
#if defined DEBUG
						PrintToServer("(Player_FindFreePosition) Found a position to spawn %N in %d tries, took %1.4fs:\n  angle: %0.2f\t\tradius: %0.2f\t\theight: %0.2f\n  %1.4f\t\t%1.4f\t\t", client, debugCount, GetEngineTime()-time, angle, radius, height, radius*Cosine(angle), radius*Sine(angle));
#endif
						TeleportEntity(client, flPos, NULL_VECTOR, NULL_VECTOR);

						EmitSoundToClient(client, SOUND_TELEPORT);
						if(g_iParticleTeleport != -1)
						{
							flPos[2] += 30.0;
							TE_Particle(g_iParticleTeleport, flPos);
							TE_SendToAll();
						}

						return true;
					}else{
						int hit = TR_GetEntityIndex();
						char className[32];
						GetEdictClassname(hit, className, sizeof(className));
						PrintToServer("Hit: %d \"%s\"", hit, className);
					}
				}
			}
		}
	}

#if defined DEBUG
	PrintToServer("(Player_FindFreePosition) Failed to find a spawn position after %d tries, took %1.4fs.", debugCount, GetEngineTime()-time);
#endif
	return false;
}
*/

public bool TraceFilter_NotTeam(int entity, int contentsMask, int team)
{
	if(entity >= 1 && entity <= MaxClients && GetClientTeam(entity) == team)
	{
		return false;
	}

	return true;
}

public bool TraceFilter_LOS(int entity, int contentsMask, int notUsed)
{
	if(entity <= 0) return true; // Hit the world.

	if(entity >= 1 && entity <= MaxClients)
	{
		// Hit a player.
		return false;
	}

	// Hit an entity.
	for(int team=2; team<=3; team++)
	{
		if(g_iRefTank[team] != 0 && EntRefToEntIndex(g_iRefTank[team]) == entity) return false; // Don't let the tanks get in the way.
	}

	return true;
}

public bool TraceFilter_HitWorld(int entity, int contentsMask, int notUsed)
{
	if(entity <= 0) return true; // Hit the world.

	return false;
}

void Tank_Think(int iTank)
{
	int team = GetEntProp(iTank, Prop_Send, "m_iTeamNum");

	// Make sure that the romevision tank model can never be seen.
	SetEntProp(iTank, Prop_Send, "m_nModelIndexOverrides", 0, _, 3);
	int iTrackL = EntRefToEntIndex(g_iRefTankTrackL[team]);
	int iTrackR = EntRefToEntIndex(g_iRefTankTrackR[team]);
	if(iTrackL > MaxClients) SetEntProp(iTrackL, Prop_Send, "m_nModelIndexOverrides", 0, _, 3);
	if(iTrackR > MaxClients) SetEntProp(iTrackR, Prop_Send, "m_nModelIndexOverrides", 0, _, 3);

	// If the game goes into pregame, which is the case if everyone leaves in a payload round, make the tank idle
	if(GameRules_GetRoundState() == RoundState_Pregame)
	{
		Train_Move(team, 0.0);
		SetEntPropFloat(iTank, Prop_Data, "m_speed", 0.0);
		return;
	}
	
	// Keep the tank idle during the grace period
	if(!g_bIsRoundStarted)
	{
		SetEntPropFloat(iTank, Prop_Data, "m_speed", 0.0);

		// If the tank is parented when the round ends, keep the tank tracks moving accurately
		int trackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
		if(trackTrain > MaxClients && GetEntPropEnt(iTank, Prop_Send, "moveparent") > MaxClients)
		{
			float flSpeedTrain = GetEntPropFloat(trackTrain, Prop_Data, "m_flSpeed");
			float flPlaybackRate = flSpeedTrain / GetEntPropFloat(trackTrain, Prop_Data, "m_maxSpeed") * 0.56;
			if((g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent) && g_bEnableMapHack[team]) flPlaybackRate = 0.0; // When the tank is parented to the lift, it won't be moving anywhere
			
			if(iTrackL > MaxClients) SetEntPropFloat(iTrackL, Prop_Send, "m_flPlaybackRate", flPlaybackRate);
			if(iTrackR > MaxClients) SetEntPropFloat(iTrackR, Prop_Send, "m_flPlaybackRate", flPlaybackRate);			
		}

		int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
		if(watcher > MaxClients)
		{
			float flDistanceToGoal = Train_RealDistanceToGoal(team);
			float flDistanceParent = config.LookupFloat(g_hCvarGoalDistance);
			float flTotalProgress = GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress");

			// Control parenting of the tank to the cart in order to keep them in the same position.
			Parent_Think(iTank, team, flDistanceToGoal, flDistanceParent, flTotalProgress);
		}

		return;
	}
	
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	int iTrigger = EntRefToEntIndex(g_iRefTrigger[team]);
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	if(iTrackTrain <= MaxClients || iTrigger <= MaxClients || iWatcher <= MaxClients)
	{
		//LogMessage("(Tank_Think) Missing entities: %d %d %d!", iTrackTrain, iTrigger, iWatcher);
		return;
	}

	// Only check for stuck players when the tank in parented in pl_.
	Tank_CheckForStuckPlayers(iTank, team);
	
	bool bIsTankHealing;
	if(g_flTankHealEnd[team] != 0.0)
	{
		if(GetEngineTime() > g_flTankHealEnd[team])
		{
			// Time is up so the tank shouldn't be healed anymore
			g_flTankHealEnd[team] = 0.0;
		}else{
			// The tank is currently being healed
			bIsTankHealing = true;
			// Check to see if it's time to increment the tank's health
			if(GetEngineTime() - g_flTankLastHealed[team] > config.LookupFloat(g_hCvarCheckpointInterval))
			{
				// Heal that bitch
				Tank_AddCheckpointHealth(team);
			}
		}
	}
	
	// Keep track of checkpoint progress and award health bonuses
	if(g_iCurrentControlPoint[team] >= 0 && g_iCurrentControlPoint[team] <= g_iMaxControlPoints[team]-1 && g_iRefLinkedPaths[team][g_iCurrentControlPoint[team]] != 0)
	{
		// Check the current path of the cart and check it against the linked path of the CP
		int iPathCurrent = Train_GetCurrentPath(team);
		int iPathCP = EntRefToEntIndex(g_iRefLinkedPaths[team][g_iCurrentControlPoint[team]]);
		if(iPathCurrent > MaxClients && iPathCP > MaxClients && iPathCurrent == iPathCP)
		{
#if defined DEBUG
			PrintToServer("(Tank_Think) Passed control point #%d!", g_iCurrentControlPoint[team]);
#endif
			int iHealth = GetEntProp(iTank, Prop_Data, "m_iHealth");	
			int iMaxHealth = GetEntProp(iTank, Prop_Data, "m_iMaxHealth");
			
			// (NUMBER OF TANKS + NUMBER OF CHECKPOINTS) / 6 * (MAX TANK HEALTH * CHECKPOINT HEALTH CVAR)
			int iTanksAndCheckpoints = (4 - g_iMaxControlPoints[team]) + g_iNumTankMaxSimulated;
			if(iTanksAndCheckpoints <= 0) iTanksAndCheckpoints = 1;
			int iCheckpointHP = RoundToNearest((float(iTanksAndCheckpoints) / 6.0) * float(iMaxHealth) * config.LookupFloat(g_hCvarCheckpointHealth));
						
			// If the tank's health is above the cutoff amount, don't show the HP in the checkpoint chat message
			if(iHealth < RoundToNearest(float(iMaxHealth) * config.LookupFloat(g_hCvarCheckpointCutoff)))
			{
				PrintToChatAll("%t", "Tank_Chat_Tank_PassedCheckpoint_Health", g_strTeamColors[team], 0x01, g_strRankColors[Rank_Unique], 0x01, 0x04, iCheckpointHP, 0x01);
			}else{
				PrintToChatAll("%t", "Tank_Chat_Tank_PassedCheckpoint", g_strTeamColors[team], 0x01, g_strRankColors[Rank_Unique], 0x01);
			}
			
			g_flTankHealEnd[team] = GetEngineTime() + config.LookupFloat(g_hCvarCheckpointTime);
			Tank_AddCheckpointHealth(team);
			
			// Check to see if this control point has already been capped
			// If this is the case, fire a ding sound to alert that a control point was passed
			int iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][g_iCurrentControlPoint[team]]);
			if(iControlPoint > MaxClients)
			{
				// Check if the point is already capped by BLU
				if(GetEntProp(iControlPoint, Prop_Data, "m_iTeamNum") == TFTeam_Blue)
				{
					for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "playgamesound %s", SOUND_CHECKPOINT);
				}

				// Make sure the control point is captured with the SetOwner input. This SHOULD be done by the map maker however.
#if defined DEBUG
				PrintToServer("(Tank_Think) Calling SetOwner on control point: %d!", iControlPoint);
#endif
				SetVariantInt(team);
				AcceptEntityInput(iControlPoint, "SetOwner", -1, iControlPoint);
			}
			
			// Voice lines that should be played by HUMANS whenever a tank captures a control point
			int iMax = GetRandomInt(2, 3);
			int iCount;
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i) && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) && !TF2_IsPlayerInCondition(i, TFCond_Disguised) && iCount++ < iMax)
				{
					switch(TF2_GetPlayerClass(i))
					{
						case TFClass_Scout: EmitSoundToAll(g_strSoundTankCappedScout[GetRandomInt(0, sizeof(g_strSoundTankCappedScout)-1)], i, SNDCHAN_VOICE);
						case TFClass_Sniper: EmitSoundToAll(g_strSoundTankCappedSniper[GetRandomInt(0, sizeof(g_strSoundTankCappedSniper)-1)], i, SNDCHAN_VOICE);
						case TFClass_Soldier: EmitSoundToAll(g_strSoundTankCappedSoldier[GetRandomInt(0, sizeof(g_strSoundTankCappedSoldier)-1)], i, SNDCHAN_VOICE);
						case TFClass_DemoMan: EmitSoundToAll(g_strSoundTankCappedDemoman[GetRandomInt(0, sizeof(g_strSoundTankCappedDemoman)-1)], i, SNDCHAN_VOICE);
						case TFClass_Medic: EmitSoundToAll(g_strSoundTankCappedMedic[GetRandomInt(0, sizeof(g_strSoundTankCappedMedic)-1)], i, SNDCHAN_VOICE);
						case TFClass_Heavy: EmitSoundToAll(g_strSoundTankCappedHeavy[GetRandomInt(0, sizeof(g_strSoundTankCappedHeavy)-1)], i, SNDCHAN_VOICE);
						case TFClass_Pyro: EmitSoundToAll(g_strSoundTankCappedPyro[GetRandomInt(0, sizeof(g_strSoundTankCappedPyro)-1)], i, SNDCHAN_VOICE);
						case TFClass_Spy: EmitSoundToAll(g_strSoundTankCappedSpy[GetRandomInt(0, sizeof(g_strSoundTankCappedSpy)-1)], i, SNDCHAN_VOICE);
						case TFClass_Engineer: EmitSoundToAll(g_strSoundTankCappedEngineer[GetRandomInt(0, sizeof(g_strSoundTankCappedEngineer)-1)], i, SNDCHAN_VOICE);
					}
				}
			}

			g_iCurrentControlPoint[team]++;
		}
	}
	
	// Update the health bar to indicate the health of the tank.
	int healthBar = HealthBar_FindOrCreate();
	if(healthBar > MaxClients)
	{
		int health = GetEntProp(iTank, Prop_Data, "m_iHealth");
		int maxHealth = GetEntProp(iTank, Prop_Data, "m_iMaxHealth");

		bool greenBar = (bIsTankHealing || health > maxHealth);
		int healthBarValue = RoundToCeil(float(health) / float(maxHealth) * 255.0);
		if(healthBarValue > 255) healthBarValue = 255;

		SetEntProp(healthBar, Prop_Send, "m_iBossHealthPercentageByte", healthBarValue);
		SetEntProp(healthBar, Prop_Send, "m_iBossState", (greenBar == true) ? 1 : 0);
	}
	
	float flDistanceToGoal = Train_RealDistanceToGoal(team);
	float flTotalProgress = GetEntPropFloat(iWatcher, Prop_Send, "m_flTotalProgress");
	
	float flDistanceDeploy = config.LookupFloat(g_hCvarDeployDistance);
	float flDistanceParent = config.LookupFloat(g_hCvarGoalDistance);

	// Control the speed of the cart
	if(!GetEntProp(iTrigger, Prop_Data, "m_bDisabled"))
	{
		Train_Move(team, 1.0);
		g_bTankTriggerDisabled[team] = false;
	}else{
		// The map can disable the trigger_capture_area to indicate that the cart cannot move anymore
		// When this happens, sometimes the map triggers SetSpeedDirAccel on the cart
		// To not interfere with this, we will not change the cart's speed while the cart's trigger_capture_zone is disabled

		// Only kill the cart's speed just one time to avoid interfering with map logic
		if(!g_bTankTriggerDisabled[team])
		{
			Train_Move(team, 0.0);
			g_bTankTriggerDisabled[team] = true;
		}
	}
	
	// As we approach the goal node, parent the tank so it interacts with other map entities properly (and the tank doesn't auto-deploy)
	if(flDistanceToGoal < flDistanceParent)
	{
		if(GetEntPropEnt(iTank, Prop_Send, "moveparent") <= MaxClients)
		{
#if defined DEBUG
			PrintToChatAll("PARENTING FOR GOAL");
#endif
			Tank_Parent(team);
		}

		for(int i=0,size=g_trainProps.Length; i<size; i++)
		{
			int array[ARRAY_TRAINPROP_SIZE];
			g_trainProps.GetArray(i, array, sizeof(array));

			int prop = EntRefToEntIndex(array[TrainPropArray_Reference]);
			if(prop > MaxClients)
			{
#if defined DEBUG
				//PrintToServer("(Tank_Think) Restoring m_nSolidType %d on %d!", array[TrainPropArray_SolidType], prop);
#endif
				SetEntProp(prop, Prop_Send, "m_nSolidType", array[TrainPropArray_SolidType]);
			}
		}
	}

	// Control parenting of the tank to the cart in order to keep them in the same position.
	Parent_Think(iTank, team, flDistanceToGoal, flDistanceParent, flTotalProgress);
	
	// Play a sound when the tank reaches the halfway mark
	if(!g_bSoundHalfway[team] && flTotalProgress >= 0.5)
	{
		BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Tank_Alert_Halfway");
		g_bSoundHalfway[team] = true;
	}
	
	// Play a sound to alert players that the tank is approaching the goal
	if(flDistanceToGoal < config.LookupFloat(g_hCvarDistanceWarn) && (g_flTankLastSound == 0.0 || GetGameTime() - g_flTankLastSound > 4.0) && !(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale))
	{
		EmitSoundToAll(SOUND_TANK_WARNING);
		
		g_flTankLastSound = GetGameTime();
	}

	// When we get close enough to the goal of the final stage, deploy the tank's payload
	if(g_bIsFinale && g_nMapHack != MapHack_CactusCanyon && GetEntProp(iTank, Prop_Send, "m_nSequence") != 1 && flDistanceToGoal < flDistanceDeploy)
	{
		int iTankMechanism = EntRefToEntIndex(g_iRefTankMechanism[team]);
		if(iTankMechanism > MaxClients)
		{
			SetVariantString("deploy");
			AcceptEntityInput(EntRefToEntIndex(g_iRefTankMechanism[team]), "SetAnimation");
		}
		
		// Voice lines that should be played by HUMANS whenever a tank starts deploying
		int iMax = GetRandomInt(2, 3);
		int iCount;
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i) && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) && !TF2_IsPlayerInCondition(i, TFCond_Disguised) && iCount++ < iMax)
			{
				switch(TF2_GetPlayerClass(i))
				{
					case TFClass_Scout: EmitSoundToAll(g_strSoundTankDeployingScout[GetRandomInt(0, sizeof(g_strSoundTankDeployingScout)-1)], i, SNDCHAN_VOICE);
					case TFClass_Sniper: EmitSoundToAll(g_strSoundTankDeployingSniper[GetRandomInt(0, sizeof(g_strSoundTankDeployingSniper)-1)], i, SNDCHAN_VOICE);
					case TFClass_Soldier: EmitSoundToAll(g_strSoundTankDeployingSoldier[GetRandomInt(0, sizeof(g_strSoundTankDeployingSoldier)-1)], i, SNDCHAN_VOICE);
					case TFClass_DemoMan: EmitSoundToAll(g_strSoundTankDeployingDemoman[GetRandomInt(0, sizeof(g_strSoundTankDeployingDemoman)-1)], i, SNDCHAN_VOICE);
					case TFClass_Medic: EmitSoundToAll(g_strSoundTankDeployingMedic[GetRandomInt(0, sizeof(g_strSoundTankDeployingMedic)-1)], i, SNDCHAN_VOICE);
					case TFClass_Heavy: EmitSoundToAll(g_strSoundTankDeployingHeavy[GetRandomInt(0, sizeof(g_strSoundTankDeployingHeavy)-1)], i, SNDCHAN_VOICE);
					case TFClass_Pyro: EmitSoundToAll(g_strSoundTankDeployingPyro[GetRandomInt(0, sizeof(g_strSoundTankDeployingPyro)-1)], i, SNDCHAN_VOICE);
					case TFClass_Spy: EmitSoundToAll(g_strSoundTankDeployingSpy[GetRandomInt(0, sizeof(g_strSoundTankDeployingSpy)-1)], i, SNDCHAN_VOICE);
					case TFClass_Engineer: EmitSoundToAll(g_strSoundTankDeployingEngineer[GetRandomInt(0, sizeof(g_strSoundTankDeployingEngineer)-1)], i, SNDCHAN_VOICE);
				}
			}
		}

		EmitSoundToAll(SOUND_TANK_DEPLOY);
		
		SetEntProp(iTank, Prop_Send, "m_nSequence", 1);
		SetEntProp(iTank, Prop_Send, "m_nNewSequenceParity", 2);
		SetEntProp(iTank, Prop_Send, "m_nResetEventsParity", 2);
		SetEntPropFloat(iTank, Prop_Send, "m_flPlaybackRate", 0.0);
#if defined DEBUG
		PrintToChatAll("DEPLOYING TANK PAYLOAD!");
#endif
	}
	
	// While the tank is parented, we need to take care of a few things because the tank's Think routine is blocked
	if(GetEntPropEnt(iTank, Prop_Send, "moveparent") > MaxClients)
	{
		// Control the speeds of the treads based on the speed we are currently moving
		float trainSpeed = GetEntPropFloat(iTrackTrain, Prop_Data, "m_flSpeed");
		float flPlaybackRate = trainSpeed / GetEntPropFloat(iTrackTrain, Prop_Data, "m_maxSpeed") * 0.56;
		//PrintToServer("Speed: %0.2f", flPlaybackRate);
		
		if(iTrackL > MaxClients) SetEntPropFloat(iTrackL, Prop_Send, "m_flPlaybackRate", flPlaybackRate);
		if(iTrackR > MaxClients) SetEntPropFloat(iTrackR, Prop_Send, "m_flPlaybackRate", flPlaybackRate);
	}else{
		Tank_Controller(team, iTank, iTrackTrain);
	}

	Tank_CheckForSeparation(team, iTank, iTrackTrain);
}

void Tank_ThinkRace(int iTank)
{
	int team = GetEntProp(iTank, Prop_Send, "m_iTeamNum");

	// Make sure that the romevision model is seen on RED's tank but never on BLU's tank.
	if(team == TFTeam_Red && g_modelRomevisionTank > 0)
	{
		SetEntProp(iTank, Prop_Send, "m_nModelIndexOverrides", g_modelRomevisionTank, _, g_teamOverrides[TFTeam_Red]);
		SetEntProp(iTank, Prop_Send, "m_nModelIndexOverrides", g_modelRomevisionTank, _, g_teamOverrides[TFTeam_Blue]);
	}else{
		SetEntProp(iTank, Prop_Send, "m_nModelIndexOverrides", 0, _, g_teamOverrides[TFTeam_Red]);
		SetEntProp(iTank, Prop_Send, "m_nModelIndexOverrides", 0, _, g_teamOverrides[TFTeam_Blue]);
	}
	int iTrackL = EntRefToEntIndex(g_iRefTankTrackL[team]);
	if(iTrackL > MaxClients)
	{
		if(team == TFTeam_Red && g_modelRomevisionTrackL > 0)
		{
			SetEntProp(iTrackL, Prop_Send, "m_nModelIndexOverrides", g_modelRomevisionTrackL, _, g_teamOverrides[TFTeam_Red]);
			SetEntProp(iTrackL, Prop_Send, "m_nModelIndexOverrides", g_modelRomevisionTrackL, _, g_teamOverrides[TFTeam_Blue]);
		}else{
			SetEntProp(iTrackL, Prop_Send, "m_nModelIndexOverrides", 0, _, g_teamOverrides[TFTeam_Red]);
			SetEntProp(iTrackL, Prop_Send, "m_nModelIndexOverrides", 0, _, g_teamOverrides[TFTeam_Blue]);
		}
	}
	int iTrackR = EntRefToEntIndex(g_iRefTankTrackR[team]);
	if(iTrackR > MaxClients)
	{
		if(team == TFTeam_Red && g_modelRomevisionTrackR > 0)
		{
			SetEntProp(iTrackR, Prop_Send, "m_nModelIndexOverrides", g_modelRomevisionTrackR, _, g_teamOverrides[TFTeam_Red]);
			SetEntProp(iTrackR, Prop_Send, "m_nModelIndexOverrides", g_modelRomevisionTrackR, _, g_teamOverrides[TFTeam_Blue]);
		}else{
			SetEntProp(iTrackR, Prop_Send, "m_nModelIndexOverrides", 0, _, g_teamOverrides[TFTeam_Red]);
			SetEntProp(iTrackR, Prop_Send, "m_nModelIndexOverrides", 0, _, g_teamOverrides[TFTeam_Blue]);
		}
	}

	// If the game goes into pregame, which is the case if everyone leaves in a payload round, make the tank idle
	if(GameRules_GetRoundState() == RoundState_Pregame)
	{
		Train_Move(team, 0.0);
		SetEntPropFloat(iTank, Prop_Data, "m_speed", 0.0);
		return;
	}
	
	
	// Keep the tank idle during the grace period
	if(!g_bIsRoundStarted)
	{
		SetEntPropFloat(iTank, Prop_Data, "m_speed", 0.0);

		// If the tank is parented when the round ends, keep the tank tracks moving accurately
		int trackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
		if(trackTrain > MaxClients && GetEntPropEnt(iTank, Prop_Send, "moveparent") > MaxClients)
		{
			float flSpeedTrain = GetEntPropFloat(trackTrain, Prop_Data, "m_flSpeed");
			float flPlaybackRate = flSpeedTrain / GetEntPropFloat(trackTrain, Prop_Data, "m_maxSpeed") * 0.56;
			if((g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent) && g_bEnableMapHack[team]) flPlaybackRate = 0.0; // When the tank is parented to the lift, it won't be moving anywhere
			
			if(iTrackL > MaxClients) SetEntPropFloat(iTrackL, Prop_Send, "m_flPlaybackRate", flPlaybackRate);
			if(iTrackR > MaxClients) SetEntPropFloat(iTrackR, Prop_Send, "m_flPlaybackRate", flPlaybackRate);			
		}

		int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
		if(watcher > MaxClients)
		{
			float flDistanceToGoal = Train_RealDistanceToGoal(team);
			float flDistanceParent = config.LookupFloat(g_hCvarGoalDistance);
			float flTotalProgress = GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress");

			// Control parenting of the tank to the cart during the grace period.
			Parent_Think(iTank, team, flDistanceToGoal, flDistanceParent, flTotalProgress);
		}

		return;
	}
	
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	int iTrigger = EntRefToEntIndex(g_iRefTrigger[team]);
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	if(iTrackTrain <= MaxClients || iTrigger <= MaxClients || iWatcher <= MaxClients)
	{
		//LogMessage("(Tank_Think) Missing entities: %d %d %d!", iTrackTrain, iTrigger, iWatcher);
		return;
	}

	Tank_CheckForStuckPlayers(iTank, team);

	float flDistanceToGoal = Train_RealDistanceToGoal(team);
	float flTotalProgress = GetEntPropFloat(iWatcher, Prop_Send, "m_flTotalProgress");

	float flDistanceParent = config.LookupFloat(g_hCvarGoalDistance);

	// Get the current path of the func_tracktrain payload cart
	int iPathCurrent = Train_GetCurrentPath(team);
	int iPathNext;
	if(iPathCurrent > MaxClients)
	{
		iPathNext = GetEntDataEnt2(iPathCurrent, Offset_GetNextOffset(iPathCurrent));

		// When moving backwards, m_pnext will be incorrect. As a fix, assume the next track is the current track that we are on:
		// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/team_train_watcher.cpp#L1179
		if(GetEntPropFloat(iTrackTrain, Prop_Data, "m_dir") < 0.0)
		{
			iPathNext = iPathCurrent;
		}
	}

	// Map specific code to ensure everything runs smoothly
	switch(g_nMapHack)
	{
		case MapHack_Hightower,MapHack_HightowerEvent:
		{
			// When the cart hits the lift we need to do a few things:
			// 1. Parent the tank to the lift
			// 2. Switch over to the lift's func_tracktrain and trigger_capture_area
			if(!g_bEnableMapHack[team])
			{
				// When we hit these paths, we need to execute the above steps
				// BLU cart: plr_blu_pathC_hillA3
				// RED cart: plr_red_pathC_hillA3
				if(iPathCurrent > MaxClients)
				{
					char strName[30];
					GetEntPropString(iPathCurrent, Prop_Data, "m_iName", strName, sizeof(strName));
					if(team == TFTeam_Blue && strcmp(strName, "plr_blu_pathC_hillA3") == 0)
					{
						int iLift = Entity_FindEntityByName("clamp_blue", "func_tracktrain");
						if(iLift > MaxClients)
						{
#if defined DEBUG
							PrintToServer("(Tank_ThinkRace) Found tank parent \"clamp_blue\": %d!", iLift);
#endif
							g_iRefTrackTrain2[team] = EntIndexToEntRef(iLift);
							SetEntPropFloat(iLift, Prop_Data, "m_maxSpeed", config.LookupFloat(g_hCvarMaxSpeed));

							float flPos[3];
							GetEntPropVector(iTank, Prop_Send, "m_vecOrigin", flPos);
							if(team == TFTeam_Red)
							{
								flPos[2] += HIGHTOWER_LIFT_OFFSET_RED;
							}else{
								flPos[2] += HIGHTOWER_LIFT_OFFSET_BLUE;
							}
							TeleportEntity(iTank, flPos, NULL_VECTOR, NULL_VECTOR);

							Tank_Parent(team, true);
						}else{
							LogMessage("(Tank_ThinkRace) Failed to find \"clamp_blue\" to parent the tank!");
						}

						g_bEnableMapHack[team] = true;
					}else if(team == TFTeam_Red && strcmp(strName, "plr_red_pathC_hillA3") == 0)
					{
						int iLift = Entity_FindEntityByName("clamp_red", "func_tracktrain");
						if(iLift > MaxClients)
						{
#if defined DEBUG
							PrintToServer("(Tank_ThinkRace) Found tank parent \"clamp_blue\": %d!", iLift);
#endif
							g_iRefTrackTrain2[team] = EntIndexToEntRef(iLift);
							SetEntPropFloat(iLift, Prop_Data, "m_maxSpeed", config.LookupFloat(g_hCvarMaxSpeed));

							float flPos[3];
							GetEntPropVector(iTank, Prop_Send, "m_vecOrigin", flPos);
							if(team == TFTeam_Red)
							{
								flPos[2] += HIGHTOWER_LIFT_OFFSET_RED;
							}else{
								flPos[2] += HIGHTOWER_LIFT_OFFSET_BLUE;
							}
							TeleportEntity(iTank, flPos, NULL_VECTOR, NULL_VECTOR);

							Tank_Parent(team, true);
						}else{
							LogMessage("(Tank_ThinkRace) Failed to find \"clamp_red\" to parent the tank!");
						}

						g_bEnableMapHack[team] = true;
					}
				}
			}
		}
	}

	// Based on the damage the tank has taken, compute which speed level the tank should be moving at
	if(g_flRaceLastChange[team] == 0.0 || GetEngineTime() - g_flRaceLastChange[team] > config.LookupFloat(g_hCvarRaceInterval))
	{
		int iEnemyTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
		// Calculate the interval for each level based on the formula: base + EPC * average
		int iInterval = RoundToNearest(config.LookupFloat(g_hCvarRaceDamageBase) + CountPlayersOnTeam(iEnemyTeam) * config.LookupFloat(g_hCvarRaceDamageAverage));

		int iLevel = (g_iRaceTankDamage[team] / iInterval) + 1;
		if(iLevel >= MAX_RACE_LEVELS) iLevel = MAX_RACE_LEVELS-1;
		if(iLevel <= 0) iLevel = 1;
		// Flip from 1-4 levels to 4-1 levels | This number will show up on HUD so the higher the level, the faster the tank is moving. This is how people are used to it in payload.
		iLevel = MAX_RACE_LEVELS - iLevel;

		// Level is now between 1-4 with 4 being the level with the fastest tank, 1 being the slowest tank level
		g_iRaceCurrentLevel[team] = iLevel;

		g_iRaceTankDamage[team] = 0;
		g_flRaceLastChange[team] = GetEngineTime();
	}

	// Detect when we leave an uphill zone and unparent the tank as well as disable going backwards until the next uphill zone
	if(iPathCurrent > MaxClients && iPathNext > MaxClients && iPathCurrent != iPathNext && GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL && !(GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL))
	{
		if(g_bRaceParentedForHill[team] && flDistanceToGoal > flDistanceParent && GetEntPropEnt(iTank, Prop_Send, "moveparent") > MaxClients)
		{
			Tank_UnParent(team);
			g_bRaceParentedForHill[team] = false;
		}

		if(!g_bRaceGoingBackwards[team])
		{
#if defined DEBUG
			/*
			char strName1[100];
			if(iPathCurrent > MaxClients) GetEntPropString(iPathCurrent, Prop_Data, "m_iName", strName1, sizeof(strName1));
			char strName2[100];
			if(iPathNext > MaxClients) GetEntPropString(iPathNext, Prop_Data, "m_iName", strName2, sizeof(strName2));

			PrintToChatAll("Current: %s(%d) Next: %s(%d) Speed: %0.2f", strName1, GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL, strName2, GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL, GetEntPropFloat(iTrackTrain, Prop_Data, "m_dir"));
			*/
			PrintToChatAll("DISABLED TANK GOING BACKWARDS(%d)!", team);
#endif
			g_bRaceGoingBackwards[team] = true;
		}
	}

	// To solve problems with the tank toggling on/off, going backwards will be re-enabled when we reach the next non-uphill path_track
	if(g_bRaceGoingBackwards[team] && iPathCurrent > MaxClients && iPathNext > MaxClients && iPathCurrent != iPathNext
		&& !(GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL) && !(GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL))
	{
		// We shouldn't be parented right now, 
#if defined DEBUG
		PrintToChatAll("RE-ENABLED TANK GOING BACKWARDS(%d)!", team);
#endif
		g_bRaceGoingBackwards[team] = false;
	}

	// Control the speed of the cart and therefore the tank
	if(!GetEntProp(iTrigger, Prop_Data, "m_bDisabled"))
	{
		// trigger_capture_area is not disabled so we should be able to send speed inputs to the cart without breaking anything

		// Get the speed for the corresponding level
		float flCartSpeed = config.LookupFloat(g_hCvarRaceLvls[g_iRaceCurrentLevel[team]]);

		// There's one more caveat: if the current level is x1 and the cart's current path and next path are marked as uphill, then we should make it go backwards
		if(((g_iRaceCurrentLevel[team] == 1 && !g_isRaceInOvertime) || g_bRaceIntermission) && iPathCurrent > MaxClients && GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL && iPathNext > MaxClients && GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL)
		{
			//g_iRaceCurrentLevel[team] = 0;
			flCartSpeed = config.LookupFloat(g_hCvarRaceLvls[0]);

			// The tank can't move backwards..our solution to this is to parent the tank and then unparenting it when it reaches the top
			if(!g_bRaceParentedForHill[team] && GetEntPropEnt(iTank, Prop_Send, "moveparent") <= MaxClients)
			{
				Tank_Parent(team);
				g_bRaceParentedForHill[team] = true;
			}
		}

		// Overrides during intermission
		if(g_bRaceIntermission)
		{
			if(flCartSpeed > 0.0 || g_bRaceIntermissionBottom[team])
			{
				Train_Move(team, 0.0, 0);
			}else{
				// Determine if we are at the bottom of a hill, and if so stop moving the tank until intermission is over
				if(iPathCurrent > MaxClients && GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL)
				{
					int iPathPrev = GetEntDataEnt2(iPathCurrent, Offset_GetPreviousOffset(iPathCurrent));

					/*
					if(team == TFTeam_Blue)
					{
						char strName1[100];
						if(iPathPrev > MaxClients) GetEntPropString(iPathPrev, Prop_Data, "m_iName", strName1, sizeof(strName1));
						char strName2[100];
						if(iPathCurrent > MaxClients) GetEntPropString(iPathCurrent, Prop_Data, "m_iName", strName2, sizeof(strName2));

						PrintCenterTextAll("Prev: %s(%d)(%d) Current: %s(%d)(%d) Speed: %0.2f", strName1, GetEntProp(iPathPrev, Prop_Data, "m_spawnflags") & PATH_UPHILL, GetEntProp(iPathPrev, Prop_Data, "m_spawnflags") & PATH_DISABLE_TRAIN, strName2, GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL, GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_DISABLE_TRAIN, GetEntPropFloat(iTrackTrain, Prop_Data, "m_dir"));
					}
					*/

					float flPosPath[3];
					GetEntPropVector(iPathCurrent, Prop_Send, "m_vecOrigin", flPosPath);
					float flPosTrain[3];
					GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPosTrain);

					if(iPathPrev > MaxClients && !(GetEntProp(iPathPrev, Prop_Data, "m_spawnflags") & PATH_UPHILL) && GetVectorDistance(flPosPath, flPosTrain) < 25.0)
					{
#if defined DEBUG
						PrintToChatAll("REACHED BOTTOM DURING INTERMISSION(%d-%0.2f)!", team, GetVectorDistance(flPosPath, flPosTrain));
#endif
						g_bRaceIntermissionBottom[team] = true;
					}
				}

				Train_Move(team, flCartSpeed, 0);
			}

			SetEntPropFloat(iWatcher, Prop_Send, "m_flRecedeTime", g_flTimeIntermissionEnds);
		}else{
			// Set the speed of the cart, passing along the current level to show on the HUD
			Train_Move(team, flCartSpeed, g_iRaceCurrentLevel[team]);
		}

		/*
		if(team == TFTeam_Blue)
		{
			char strName1[100];
			if(iPathCurrent > MaxClients) GetEntPropString(iPathCurrent, Prop_Data, "m_iName", strName1, sizeof(strName1));
			char strName2[100];
			if(iPathNext > MaxClients) GetEntPropString(iPathNext, Prop_Data, "m_iName", strName2, sizeof(strName2));

			PrintCenterTextAll("Current: %s(%d) Next: %s(%d)", strName1, GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL, strName2, GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL);

			//PrintToServer("Level: %d Speed: %0.2f Tank: %0.2f Back: %d, %d %d", g_iRaceCurrentLevel[team], flCartSpeed, GetEntPropFloat(iTank, Prop_Data, "m_speed"), g_bRaceGoingBackwards[team], GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL, GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL);
			

			//PrintCenterTextAll("Level: %d Speed: %0.2f Tank: %0.2f Back: %d, %d %d", g_iRaceCurrentLevel[team], flCartSpeed, GetEntPropFloat(iTank, Prop_Data, "m_speed"), g_bRaceGoingBackwards[team], GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL, GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL);
		}
		*/

		g_bTankTriggerDisabled[team] = false;
	}else{
		// The map can disable the trigger_capture_area to indicate that the cart cannot move anymore
		// When this happens, sometimes the map triggers SetSpeedDirAccel on the cart
		// To not interfere with this, we will not change the cart's speed while the cart's trigger_capture_zone is disabled

		// Only kill the cart's speed just one time to avoid interfering with map logic
		if(!g_bTankTriggerDisabled[team])
		{
			Train_Move(team, 0.0);
			g_bTankTriggerDisabled[team] = true;
		}

		// Special tank move logic for plr_hightower's lift
		if((g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent) && g_bEnableMapHack[team])
		{
			// Get the speed for the corresponding level
			float flCartSpeed = config.LookupFloat(g_hCvarRaceLvls[g_iRaceCurrentLevel[team]]);

			// There's one more caveat: if the current level is x1 and the cart's current path and next path are marked as uphill, then we should make it go backwards
			if(((g_iRaceCurrentLevel[team] == 1 && !g_isRaceInOvertime) || g_bRaceIntermission) && iPathCurrent > MaxClients && GetEntProp(iPathCurrent, Prop_Data, "m_spawnflags") & PATH_UPHILL && iPathNext > MaxClients && GetEntProp(iPathNext, Prop_Data, "m_spawnflags") & PATH_UPHILL)
			{
				flCartSpeed = config.LookupFloat(g_hCvarRaceLvls[0]);
			}

			// The tank is now parented to the lift
			// In order to have it and the payload cart ascend to the top we have to move both func_tracktrain entities
			int iLift = EntRefToEntIndex(g_iRefTrackTrain2[team]);
			if(iLift > MaxClients)
			{
				// Lift is comestic so the speed really doesn't matter, just worry about making it look right
				SetVariantFloat(0.25);
				AcceptEntityInput(iLift, "SetSpeedForwardModifier");
				
				SetVariantFloat(1.0*flCartSpeed);
				AcceptEntityInput(iLift, "SetSpeedDirAccel");
			}

			// Forcing a modifier to keep both trains moving at a consistent speed
			SetVariantFloat(0.25);
			AcceptEntityInput(iTrackTrain, "SetSpeedForwardModifier");

			Train_Move(team, 1.0*flCartSpeed, g_iRaceCurrentLevel[team]);

			//if(team == TFTeam_Blue) PrintCenterTextAll("ON LIFT! Level: %d Speed: %0.2f Tank: %0.2f", g_iRaceCurrentLevel[team], flCartSpeed, GetEntPropFloat(iTank, Prop_Data, "m_speed"));
		}
	}

	// As we approach the goal node, parent the tank so it interacts with other map entities properly (and the tank doesn't auto-deploy)
	if(flDistanceToGoal < flDistanceParent)
	{
		if(GetEntPropEnt(iTank, Prop_Send, "moveparent") <= MaxClients)
		{
#if defined DEBUG
			PrintToChatAll("PARENTING FOR GOAL");
#endif
			Tank_Parent(team);
		}

		for(int i=0,size=g_trainProps.Length; i<size; i++)
		{
			int array[ARRAY_TRAINPROP_SIZE];
			g_trainProps.GetArray(i, array, sizeof(array));

			int prop = EntRefToEntIndex(array[TrainPropArray_Reference]);
			if(prop > MaxClients)
			{
#if defined DEBUG
				//PrintToServer("(Tank_Think) Setting m_nSolidType %d on %d!", GetEntProp(prop, Prop_Send, "m_nForceBone"), prop);
#endif
				SetEntProp(prop, Prop_Send, "m_nSolidType", array[TrainPropArray_SolidType]);
			}
		}
	}
	
	// Control parenting of the tank to the cart in order to keep them in the same position.
	Parent_Think(iTank, team, flDistanceToGoal, flDistanceParent, flTotalProgress);
	
	// Play a sound when the tank reaches the halfway mark
	if(!g_bSoundHalfway[team] && flTotalProgress >= 0.5)
	{
		BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Tank_Alert_Halfway");
		g_bSoundHalfway[team] = true;
	}

	// While the tank is parented, we need to take care of a few things because the tank's Think routine is blocked
	// Disable this while the tank sits stationary on hightower's lift
	if(GetEntPropEnt(iTank, Prop_Send, "moveparent") > MaxClients)
	{
		// Control the speeds of the treads based on the speed we are currently moving
		float trainSpeed = GetEntPropFloat(iTrackTrain, Prop_Data, "m_flSpeed");
		float flPlaybackRate = trainSpeed / GetEntPropFloat(iTrackTrain, Prop_Data, "m_maxSpeed") * 0.56;
		if((g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent) && g_bEnableMapHack[team]) flPlaybackRate = 0.0; // When the tank is parented to the lift, it won't be moving anywhere.
		//PrintToServer("Speed: %0.2f", flPlaybackRate);
		if(iTrackL > MaxClients) SetEntPropFloat(iTrackL, Prop_Send, "m_flPlaybackRate", flPlaybackRate);
		if(iTrackR > MaxClients) SetEntPropFloat(iTrackR, Prop_Send, "m_flPlaybackRate", flPlaybackRate);

		//if(team == TFTeam_Blue) PrintCenterTextAll("Rate: %0.2f", flPlaybackRate);
	}else if(!g_bRaceIntermission)
	{
		Tank_Controller(team, iTank, iTrackTrain);
	}

	Tank_CheckForSeparation(team, iTank, iTrackTrain);
}

public bool TraceFilter_Tank(int entity, int contentsMask, int iTank)
{
	if(entity == iTank)
	{
		return true;
	}
	
	return false;
}

void Tank_SetStartingPathTrack(int tank, const char[] pathName)
{
	if(strlen(pathName) <= 0)
	{
		LogMessage("(Tank_SetStartingPathTrack) path_track with no name was passed!");
		return;
	}
	
	if(tank > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(Tank_SetStartingPathTrack) Setting next path on tank to: \"%s\"..", pathName);
#endif
		SDKCall(g_hSDKSetStartingPath, tank, pathName);
	}
}

void SDK_SetSize(int iEntity, float flMins[3], float flMaxs[3])
{
	if(g_hSDKSetSize != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_SetSize) Calling SetSize on entity %d..", iEntity);
#endif
		SDKCall(g_hSDKSetSize, iEntity, flMins, flMaxs);
	}
}

void SDK_SendWeaponAnim(int weapon, int anim)
{
	if(g_hSDKSendWeaponAnim != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_SendWeaponAnim) Sending animation %d on %d..", anim, weapon);
#endif
		SDKCall(g_hSDKSendWeaponAnim, weapon, anim);
	}
}


void SDK_PlaySpecificSequence(int client, const char[] strSequence)
{
	if(g_hSDKPlaySpecificSequence != INVALID_HANDLE)
	{
#if defined DEBUG
		static bool once = true;
		if(once)
		{
			PrintToServer("(SDK_PlaySpecificSequence) Calling on player %N \"%s\"..", client, strSequence);
			once = false;
		}
#endif
		SDKCall(g_hSDKPlaySpecificSequence, client, strSequence);
	}
}

void SDK_PickUp(int iTeamFlag, int client)
{
	if(g_hSDKPickup != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_PickUp) Calling on entity %d..", iTeamFlag);
#endif
		SDKCall(g_hSDKPickup, iTeamFlag, client, true);

		// If we force a player to pickup the bomb, stop the bomb return timer in case it is active
		if(g_nGameMode == GameMode_BombDeploy) Timer_KillBombReturn();
	}
}

void SDK_DoQuickBuild(int iBaseObject)
{
	if(g_hSDKDoQuickBuild != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_DoQuickBuild) Calling on entity: %d..", iBaseObject);
#endif
		SDKCall(g_hSDKDoQuickBuild, iBaseObject, true);
	}
}

stock int TF2_GetEquippedItemInSlot(int client, int iSlot)
{
	new iWeapon = GetPlayerWeaponSlot(client, iSlot);
	if(iWeapon > MaxClients) return iWeapon;
	
	new iWearable = SDK_GetEquippedWearable(client, iSlot);
	if(iWearable > MaxClients) return iWearable;
	
	return -1;
}

int SDK_GetEquippedWearable(int client, int iSlot)
{
	if(g_hSDKGetEquippedWearable != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_GetEquippedWearable) Calling on client %N slot %d..", client, iSlot);
#endif
		return SDKCall(g_hSDKGetEquippedWearable, client, iSlot);
	}
	
	return -1;
}

int SDK_GetMaxHealth(int client)
{
	if(g_hSDKGetMaxHealth != INVALID_HANDLE)
	{
#if defined DEBUG
		//PrintToServer("(SDK_GetMaxHealth) Calling on client %N..", client);
#endif
		return SDKCall(g_hSDKGetMaxHealth, client);
	}
	
	return -1;
}

int SDK_GetMaxAmmo(int client, int iSlot)
{
	if(g_hSDKGetMaxAmmo != INVALID_HANDLE)
	{
#if defined DEBUG
		static int once = true;
		if(once)
		{
			PrintToServer("(SDK_GetMaxAmmo) Calling on client %N slot %d..", client, iSlot);
			once = false;
		}
#endif
		return SDKCall(g_hSDKGetMaxAmmo, client, iSlot, -1);
	}
	
	return -1;
}

void SDK_EquipWearable(int client, int iWearable)
{
	if(g_hSDKEquipWearable != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_EquipWearable) Calling on client %N wearable %d..", client, iWearable);
#endif
		SDKCall(g_hSDKEquipWearable, client, iWearable);
	}
}

bool SDK_PointIsWithin(int iBaseTrigger, float flPos[3])
{
	if(g_hSDKPointIsWithin != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_PointIsWithin) Calling on trigger %d (id %d)..", iBaseTrigger, GetEntProp(iBaseTrigger, Prop_Data, "m_iHammerID"));
#endif
		return view_as<bool>(SDKCall(g_hSDKPointIsWithin, iBaseTrigger, flPos));
	}

	return false;
}

void SDK_RemoveWearable(int client, int iWearable)
{
	if(g_hSDKRemoveWearable != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_RemoveWearable) Calling on client %N wearable %d..", client, iWearable);
#endif
		SDKCall(g_hSDKRemoveWearable, client, iWearable);
	}
}

void SDK_TeleporterReceive(int iTeleporter, int client)
{
	if(g_hSDKTeleporterReceive != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_TeleporterReceive) Receiving %N through teleporter %d (%f)..", client, iTeleporter, GetEngineTime());
#endif
		SDKCall(g_hSDKTeleporterReceive, iTeleporter, client);
	}
}

void SDK_Taunt(int client, int iParam1, int iParam2)
{
	if(g_hSDKTaunt != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_Taunt) Calling on client %N (%d, %d)..", client, iParam1, iParam2);
#endif
		SDKCall(g_hSDKTaunt, client, iParam1, iParam2);
	}
}

int SDK_GetMaxClip(int iWeapon)
{
	if(g_hSDKGetMaxClip != INVALID_HANDLE)
	{
#if defined DEBUG
		char strClass[40];
		GetEdictClassname(iWeapon, strClass, sizeof(strClass));
		PrintToServer("(SDK_GetMaxClip) Calling on weapon %d \"%s\"..", iWeapon, strClass);
#endif
		return SDKCall(g_hSDKGetMaxClip, iWeapon);
	}

	return -1;
}

int SDK_StartTouch(int iEntity, int iOther)
{
	if(g_hSDKStartTouch != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_StartTouch) %d is touching %d!", iOther, iEntity);
#endif
		return SDKCall(g_hSDKStartTouch, iEntity, iOther);
	}

	return -1;
}

int SDK_EndTouch(int iEntity, int iOther)
{
	if(g_hSDKEndTouch != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_EndTouch) %d is touching %d!", iOther, iEntity);
#endif
		return SDKCall(g_hSDKEndTouch, iEntity, iOther);
	}

	return -1;
}

int SDK_RecalculateChargeEffects(int client, bool enable)
{
	if(g_hSDKChargeEffects != INVALID_HANDLE && g_iOffset_m_Shared > 0 && client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
#if defined DEBUG
		//PrintToServer("(SDK_RecalculateChargeEffects) Calling on %N..", client);
#endif
		Address addrPlayerShared = GetEntityAddress(client) + view_as<Address>(g_iOffset_m_Shared);
		return SDKCall(g_hSDKChargeEffects, addrPlayerShared, enable);
	}

	return -1;
}

int SDK_Heal(int playerToHeal, int entityDoingHealing, float flAmountToHeal, float flHealTime, float flHealTime2, bool unk5=false, int unk6=0)
{
	if(g_hSDKHeal != INVALID_HANDLE && g_iOffset_m_Shared > 0 && playerToHeal >= 1 && playerToHeal <= MaxClients && IsClientInGame(playerToHeal) && IsValidEntity(entityDoingHealing))
	{
#if defined DEBUG
		//PrintToServer("(SDK_Heal) %N is being healed by %N..", playerToHeal, entityDoingHealing);
#endif
		Address addrPlayerShared = GetEntityAddress(playerToHeal) + view_as<Address>(g_iOffset_m_Shared);
		return SDKCall(g_hSDKHeal, addrPlayerShared, entityDoingHealing, flAmountToHeal, flHealTime, flHealTime2, unk5, unk6);
	}

	return -1;
}

int SDK_StopHealing(int client, int entity)
{
	if(g_hSDKStopHealing != INVALID_HANDLE && g_iOffset_m_Shared > 0 && client >= 1 && client <= MaxClients && IsClientInGame(client) && IsValidEntity(entity))
	{
		Address addrPlayerShared = GetEntityAddress(client) + view_as<Address>(g_iOffset_m_Shared);
#if defined DEBUG
		//PrintToServer("(SDK_StopHealing) [0x%X -> 0x%X](0x%X)", GetEntityAddress(client), addrPlayerShared, GetEntityAddress(entity));
#endif
		return SDKCall(g_hSDKStopHealing, addrPlayerShared, entity);
	}

	return -1;
}

int SDK_FindHealerIndex(int client, int entityDoingHealing)
{
	if(g_hSDKFindHealerIndex != INVALID_HANDLE && g_iOffset_m_Shared > 0 && client >= 1 && client <= MaxClients && IsClientInGame(client) && IsValidEntity(entityDoingHealing))
	{
		Address addrPlayerShared = GetEntityAddress(client) + view_as<Address>(g_iOffset_m_Shared);
		return SDKCall(g_hSDKFindHealerIndex, addrPlayerShared, entityDoingHealing);
	}

	return -1;
}

int SDK_SwitchWeapon(int client, int weapon)
{
	if(g_hSDKWeaponSwitch != INVALID_HANDLE)
	{
#if defined DEBUG
		PrintToServer("(SDK_SwitchWeapon) Switching weapon on %N to %d!", client, weapon);
#endif
		return SDKCall(g_hSDKWeaponSwitch, client, weapon, 0);
	}

	return -1;
}

void SDK_Init()
{
	Handle hGamedata = LoadGameConfigFile("sdkhooks.games");
	if(hGamedata != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "StartTouch");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDKStartTouch = EndPrepSDKCall();
		if(g_hSDKStartTouch == INVALID_HANDLE)
		{
			LogMessage("Failed to create call: StartTouch!");
		}

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "EndTouch");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDKEndTouch = EndPrepSDKCall();
		if(g_hSDKEndTouch == INVALID_HANDLE)
		{
			LogMessage("Failed to create call: EndTouch!");
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "Weapon_Switch");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDKWeaponSwitch = EndPrepSDKCall();
		if(g_hSDKWeaponSwitch == INVALID_HANDLE)
		{
			LogError("Failed to create call: CBasePlayer::Weapon_Switch");
		}

		delete hGamedata;
	}else{
		LogMessage("Failed to load gamedata: sdkhooks.games!");
	}

	hGamedata = LoadGameConfigFile("tank");
	if(hGamedata == INVALID_HANDLE)
	{
		LogMessage("Failed to load gamedata: tank.txt!");
		return;
	}
	
	int offset = GameConfGetOffset(hGamedata, "CBaseEntity::PhysicsSolidMaskForEntity");
	if(offset > 0)
	{
		g_hSDKSolidMask = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, CBaseEntity_PhysicsSolidMaskForEntity);
		if(g_hSDKSolidMask == INVALID_HANDLE)
		{
			LogMessage("Failed to create DHook handle: CBaseEntity::PhysicsSolidMaskForEntity!");
		}
	}else{
		LogMessage("Failed to get offset: CBaseEntity::PhysicsSolidMaskForEntity!");
	}

	offset = GameConfGetOffset(hGamedata, "CMonsterResource::SetBossHealthPercentage");
	if(offset > 0)
	{
		g_hSDKSetBossHealth = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CMonsterResource_SetBossHealthPercentage);
		if(g_hSDKSetBossHealth != INVALID_HANDLE)
		{
			DHookAddParam(g_hSDKSetBossHealth, HookParamType_Float);
		}else{
			LogMessage("Failed to create DHook handle: CMonsterResource::SetBossHealthPercentage!");
		}
	}else{
		LogMessage("Failed to get offset: CMonsterResource::SetBossHealthPercentage!");
	}

	// This call is used to translate a memory address into an entity index
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CBaseEntity::GetBaseEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKGetBaseEntity = EndPrepSDKCall();
	if(g_hSDKGetBaseEntity == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CBaseEntity::GetBaseEntity!");
	}

	// This call is used to set the starting path_track for a spawned tank
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFTankBoss::SetStartingPathTrackNode");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	//PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKSetStartingPath = EndPrepSDKCall();
	if(g_hSDKSetStartingPath == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFTankBoss::SetStartingPathTrackNode!");
	}
	
	// This call is used to increase the size of the dispenser_touch_trigger of the cart
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseEntity::SetSize");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSDKSetSize = EndPrepSDKCall();
	if(g_hSDKSetSize == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CBaseEntity::SetSize!");
	}
	
	// This call is used to set the deploy animation on the robots with the bomb
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKPlaySpecificSequence = EndPrepSDKCall();
	if(g_hSDKPlaySpecificSequence == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::PlaySpecificSequence!");
	}
	
	// This call forces a player to pickup the intel
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CCaptureFlag::PickUp");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSDKPickup = EndPrepSDKCall();
	if(g_hSDKPickup == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CCaptureFlag::PickUp!");
	}
	
	// This call gets wearable equipped in loadout slots
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKGetEquippedWearable = EndPrepSDKCall();
	if(g_hSDKGetEquippedWearable == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::GetEquippedWearableForLoadoutSlot!");
	}
	
	// This call calculates the max health of a player
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxHealth = EndPrepSDKCall();
	if(g_hSDKGetMaxHealth == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::GetMaxHealth!");
	}
	
	// This call calculates the max ammo of a given weapon of a slot
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxAmmo = EndPrepSDKCall();
	if(g_hSDKGetMaxAmmo == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::GetMaxAmmo!");
	}
	
	// This call allows us to equip a wearable
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(g_hSDKEquipWearable == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CBasePlayer::EquipWearable!");
	}
	
	// This allows us to check if a vector is within a cbasetrigger entity
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseTrigger::PointIsWithin");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKPointIsWithin = EndPrepSDKCall();
	if(g_hSDKPointIsWithin == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CBaseTrigger::PointIsWithin!");
	}

	// This call removes a player wearable properly
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CBasePlayer::RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKRemoveWearable = EndPrepSDKCall();
	if(g_hSDKRemoveWearable == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CBasePlayer::RemoveWearable!");
	}

	// This call lets us send players through teleporters
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CObjectTeleporter::TeleporterReceive");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeleporterReceive = EndPrepSDKCall();
	if(g_hSDKTeleporterReceive == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CObjectTeleporter::TeleporterReceive!");
	}

	// This call will fully upgrade any CBaseObject
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseObject::DoQuickBuild");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSDKDoQuickBuild = EndPrepSDKCall();
	if(g_hSDKDoQuickBuild == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CBaseObject::DoQuickBuild!");
	}

	// This call will force the player to taunt
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::Taunt");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKTaunt = EndPrepSDKCall();
	if(g_hSDKTaunt == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::Taunt!");
	}

	// This call gets the maximum clip 1 for a given weapon
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip = EndPrepSDKCall();
	if(g_hSDKGetMaxClip == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFWeaponBase::GetMaxClip1!");
	}

	// This call reactivates medigun charge effects based on healing.
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayerShared::RecalculateChargeEffects");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSDKChargeEffects = EndPrepSDKCall();
	if(g_hSDKChargeEffects == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayerShared::RecalculateChargeEffects!");
	}

	// This call is used for the medic healing aoe.
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayerShared::Heal");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKHeal = EndPrepSDKCall();
	if(g_hSDKHeal == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayerShared::Heal!");
	}

	// This call allows us to determine if a player is being healed by a specific entity.
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayerShared::FindHealerIndex");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKFindHealerIndex = EndPrepSDKCall();
	if(g_hSDKFindHealerIndex == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayerShared::FindHealerIndex!");
	}

	// This call is used for the medic healing aoe.
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayerShared::StopHealing");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_hSDKStopHealing = EndPrepSDKCall();
	if(g_hSDKStopHealing == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayerShared::StopHealing!");
	}

	// This call is used to play the knife blocked animation.
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CTFWeaponBase::SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSendWeaponAnim = EndPrepSDKCall();
	if(g_hSDKSendWeaponAnim == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFWeaponBase::SendWeaponAnim!");
	}

	// Set up memory patches but don't enable them just yet.

	// This patch stops the console spam activated when parenting the tank
	Address addrPhysics = GameConfGetAddress(hGamedata, "Patch_PhysicsSimulate");
	if(addrPhysics == Address_Null)
	{
		LogMessage("Failed to find address: Patch_PhysicsSimulate!");
	}else{
		int patchLength = GameConfGetOffset(hGamedata, "Patch_PhysicsSimulate");
		if(patchLength <= -1)
		{
			LogMessage("Failed to find offset: Patch_PhysicsSimulate!");
		}else{
			int[] payload = new int[patchLength];
			for(int i=0; i<patchLength; i++) payload[i] = OpCode_NOP;

			g_patchPhysics = new MemoryPatch(addrPhysics, payload, patchLength, NumberType_Int8);
			if(g_patchPhysics == null) LogMessage("Failed to create patch: Patch_PhysicsSimulate!");
		}
	}

	// This patch prevents a windows crash on spawn due to player upgrade history.
	Address addrUpgrade = GameConfGetAddress(hGamedata, "Patch_UpgradeHistory");
	if(addrUpgrade == Address_Null)
	{
		// This patch is meant to fail on linux so check for that before putting out an error message.
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_UpgradeHistory");
		if(patchOffset == -1)
		{
			// Must be running linux because the linux offset is left out.
			g_bEnableGameModeHook = true;
		}else{
			// Must be running windows, then it is not safe to enable the hook.
			LogMessage("Failed to find address: Patch_UpgradeHistory!");
		}
	}else{
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_UpgradeHistory");
		if(patchOffset <= -1)
		{
			LogMessage("Failed to find offset: Patch_UpgradeHistory!");
		}else{
			int payload[5];
			for(int i=0; i<sizeof(payload); i++) payload[i] = OpCode_NOP;

			g_patchUpgrade = new MemoryPatch(addrUpgrade+view_as<Address>(patchOffset), payload, sizeof(payload), NumberType_Int8);
			if(g_patchUpgrade == null) LogMessage("Failed to create patch: Patch_UpgradeHistory!");
		}
	}
	
	// This patch fixes giant damage knockback due to the GameModeUsesUpgrades hook.
	// This only needs to be patched if that function is hooked.
	Address addrKnockback = GameConfGetAddress(hGamedata, "Patch_Knockback");
	if(addrKnockback == Address_Null)
	{
		LogMessage("Failed to find address: Patch_Knockback!");
	}else{
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_Knockback");
		if(patchOffset <= -1)
		{
			LogMessage("Failed to find offset: Patch_Knockback!");
		}else{
			int patchPayload = GameConfGetOffset(hGamedata, "Payload_Knockback");
			if(patchPayload <= -1)
			{
				LogMessage("Failed to find payload: Payload_Knockback!");
			}else{
				int payload[1];
				payload[0] = patchPayload;

				g_patchKnockback = new MemoryPatch(addrKnockback+view_as<Address>(patchOffset), payload, sizeof(payload), NumberType_Int8);
				if(g_patchKnockback == null) LogMessage("Failed to create patch: Patch_Knockback!");
			}
		}
	}

	// This patch allows bonked players to pick up the bomb.
	Address addrTouchBonk = GameConfGetAddress(hGamedata, "Patch_FlagTouchBonk");
	if(addrTouchBonk == Address_Null)
	{
		LogMessage("Failed to find address: Patch_FlagTouchBonk!");
	}else{
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_FlagTouchBonk");
		if(patchOffset <= -1)
		{
			LogMessage("Failed to find offset: Patch_FlagTouchBonk!");
		}else{
			int patchPayload = GameConfGetOffset(hGamedata, "Payload_FlagTouchBonk");
			if(patchPayload <= -1)
			{
				LogMessage("Failed to find payload: Payload_FlagTouchBonk!");
			}else{
				int payload[1];
				payload[0] = patchPayload;

				g_patchTouchBonk = new MemoryPatch(addrTouchBonk+view_as<Address>(patchOffset), payload, sizeof(payload), NumberType_Int8);
				if(g_patchTouchBonk == null) LogMessage("Failed to create patch: Patch_FlagTouchBonk!");
			}
		}
	}

	// This patch allows ubered players to pick up the bomb.
	Address addrTouchUber = GameConfGetAddress(hGamedata, "Patch_FlagTouchUber");
	if(addrTouchUber == Address_Null)
	{
		LogMessage("Failed to find address: Patch_FlagTouchUber!");
	}else{
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_FlagTouchUber");
		if(patchOffset <= -1)
		{
			LogMessage("Failed to find offset: Patch_FlagTouchUber!");
		}else{
			int patchPayload = GameConfGetOffset(hGamedata, "Payload_FlagTouchUber");
			if(patchPayload <= -1)
			{
				LogMessage("Failed to find payload: Payload_FlagTouchUber!");
			}else{
				int payload[1];
				payload[0] = patchPayload;

				g_patchTouchUber = new MemoryPatch(addrTouchUber+view_as<Address>(patchOffset), payload, sizeof(payload), NumberType_Int8);
				if(g_patchTouchUber == null) LogMessage("Failed to create patch: Patch_FlagTouchUber!");
			}
		}
	}

	// This patch allows players to activate bonk while carrying the bomb.
	Address addrTauntBonk = GameConfGetAddress(hGamedata, "Patch_FlagTauntBonk");
	if(addrTauntBonk == Address_Null)
	{
		LogMessage("Failed to find address: Patch_FlagTauntBonk!");
	}else{
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_FlagTauntBonk");
		if(patchOffset <= -1)
		{
			LogMessage("Failed to find offset: Patch_FlagTauntBonk!");
		}else{
			int patchPayload = GameConfGetOffset(hGamedata, "Payload_FlagTauntBonk");
			if(patchPayload <= -1)
			{
				LogMessage("Failed to find payload: Payload_FlagTauntBonk!");
			}else{
				int payload[1];
				payload[0] = patchPayload;

				g_patchTauntBonk = new MemoryPatch(addrTauntBonk+view_as<Address>(patchOffset), payload, sizeof(payload), NumberType_Int8);
				if(g_patchTauntBonk == null) LogMessage("Failed to create patch: Patch_FlagTauntBonk!");
			}
		}
	}

	// This patch prevents the bomb from being dropped when the player activates bonk while carrying the bomb.
	Address addrDropBonk = GameConfGetAddress(hGamedata, "Patch_FlagDropBonk");
	if(addrDropBonk == Address_Null)
	{
		LogMessage("Failed to find address: Patch_FlagDropBonk!");
	}else{
		int patchOffset = GameConfGetOffset(hGamedata, "Patch_FlagDropBonk");
		if(patchOffset <= -1)
		{
			LogMessage("Failed to find offset: Patch_FlagDropBonk!");
		}else{
			int patchPayload = GameConfGetOffset(hGamedata, "Payload_FlagDropBonk");
			if(patchPayload <= -1)
			{
				LogMessage("Failed to find payload: Payload_FlagDropBonk!");
			}else{
				int payload[1];
				payload[0] = patchPayload;

				g_patchDropBonk = new MemoryPatch(addrDropBonk+view_as<Address>(patchOffset), payload, sizeof(payload), NumberType_Int8);
				if(g_patchDropBonk == null) LogMessage("Failed to create patch: Patch_FlagDropBonk!");
			}
		}
	}

	delete hGamedata;
}

int HealthBar_FindOrCreate()
{
	int iHealthBar = EntRefToEntIndex(g_iRefHealthBar);
	if(iHealthBar > MaxClients) return iHealthBar;
	
	iHealthBar = MaxClients+1;
	while((iHealthBar = FindEntityByClassname(iHealthBar, "monster_resource")) != -1)
	{
		if(iHealthBar > MaxClients)
		{
			g_iRefHealthBar = EntIndexToEntRef(iHealthBar);
			return iHealthBar;
		}
	}
	
	iHealthBar = CreateEntityByName("monster_resource");
	if(iHealthBar > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(HealthBar_FindOrCreate) monster_resource: %d!", iHealthBar);
#endif
		g_iRefHealthBar = EntIndexToEntRef(iHealthBar);
		DispatchSpawn(iHealthBar);
		
		return iHealthBar;
	}
	
	return -1;
}

void HealthBar_Hide()
{
	int iHealthBar = HealthBar_FindOrCreate();
	if(iHealthBar > MaxClients)
	{
		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
	}
}

void Game_SetWinner(int team)
{
	int gameRound = FindEntityByClassname(MaxClients+1, "game_round_win");
	if(gameRound <= MaxClients)
	{
		gameRound = CreateEntityByName("game_round_win");
#if defined DEBUG
		PrintToServer("(Game_SetWinner) Created entity game_round_win: %d!", gameRound);
#endif
	}
	
	if(gameRound <= MaxClients)
	{
		LogMessage("(Game_SetWinner) Failed to find or spawn entity: game_round_win!");
		return;
	}
	
	switch(team)
	{
		case TFTeam_Red: SetVariantInt(TFTeam_Red);
		case TFTeam_Blue: SetVariantInt(TFTeam_Blue);
		default: SetVariantInt(0);
	}
	AcceptEntityInput(gameRound, "SetTeam");
	AcceptEntityInput(gameRound, "RoundWin");
}

void Tank_SetNoTarget(int team, bool enable)
{
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	if(iTank > MaxClients)
	{
		int iFlags = GetEntityFlags(iTank);
		if(enable)
		{
			if(!(iFlags & FL_NOTARGET))
			{
				SetEntityFlags(iTank, iFlags|FL_NOTARGET);
			}
		}else{
			if(iFlags & FL_NOTARGET)
			{
				SetEntityFlags(iTank, iFlags&~FL_NOTARGET);
			}
		}
	}
}

void Tank_Parent(int team, bool useAlternate=false)
{
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	int iRef = g_iRefTrackTrain[team];
	if(useAlternate) iRef = g_iRefTrackTrain2[team];

	int iTrackTrain = EntRefToEntIndex(iRef);
	if(iTank > MaxClients && iTrackTrain > MaxClients)
	{
		// Breaks tank physics and makes it follow the train
		SetEntityMoveType(iTank, MOVETYPE_WALK);
		
		SetVariantString("!activator");
		AcceptEntityInput(iTank, "SetParent", iTrackTrain);
#if defined DEBUG
		if(useAlternate) PrintToChatAll("PARENTED THE TANK(%d) TO THE CART2!!", team);
		else PrintToChatAll("PARENTED THE TANK(%d) TO THE CART!!", team);
#endif
	}
}

void Tank_UnParent(int team)
{
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iTank > MaxClients && iTrackTrain > MaxClients)
	{
		AcceptEntityInput(iTank, "ClearParent");

		SetEntityMoveType(iTank, MOVETYPE_CUSTOM);

		CreateTimer(0.1, Timer_TankTeleport, team, TIMER_FLAG_NO_MAPCHANGE);
#if defined DEBUG
		PrintToChatAll("UN-PARENTED THE TANK(%d) TO THE CART!!", team);
#endif
	}

	int iPush = EntRefToEntIndex(g_iRefPointPush[team]);
	if(iPush > MaxClients)
	{
		AcceptEntityInput(iPush, "Kill");
	}
	g_iRefPointPush[team] = 0;
}

//public void NextFrame_TankTeleport(int team)
public Action Timer_TankTeleport(Handle timer, int team)
{
	int tank = EntRefToEntIndex(g_iRefTank[team]);
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(tank > MaxClients && iTrackTrain > MaxClients)
	{
		// Set the next path of the tank to that of the cart's
		Tank_RestorePath(tank);

		float flPosCart[3];
		float flAngCart[3];
		GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPosCart);
		GetEntPropVector(iTrackTrain, Prop_Send, "m_angRotation", flAngCart);
		TeleportEntity(tank, flPosCart, flAngCart, NULL_VECTOR);
		
		SetEntityMoveType(tank, MOVETYPE_CUSTOM);
	}

	return Plugin_Handled;
}

int Tank_FindPathStart(int team)
{
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iWatcher > MaxClients && iTrackTrain > MaxClients)
	{
		char strStartNode[100];
		GetEntPropString(iWatcher, Prop_Data, "m_iszStartNode", strStartNode, sizeof(strStartNode));
		
		int iPathStart = Entity_FindEntityByName(strStartNode, "path_track");
		if(iPathStart > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Tank_FindPathStart) path_track: %d \"%s\"!", iPathStart, strStartNode);
#endif
			g_iRefPathStart[team] = EntIndexToEntRef(iPathStart);
			return iPathStart;
		}
	}
	
	return -1;
}

int Offset_GetNextOffset(int iEntity)
{
	// CPathTrack path_track (CPathTrack	*m_pnext)
	if(g_iOffset_m_pnext <= 0)
	{
		g_iOffset_m_pnext = FindDataMapOffs(iEntity, "m_pnext");
	}
	
	return g_iOffset_m_pnext;
}

int Offset_GetPreviousOffset(int iEntity)
{
	// CPathTrack path_track (CPathTrack	*m_pprevious)
	if(g_iOffset_m_pprevious <= 0)
	{
		g_iOffset_m_pprevious = FindDataMapOffs(iEntity, "m_pprevious");
	}
	
	return g_iOffset_m_pprevious;
}

int Offset_GetPathOffset(int iEntity)
{
	// CFuncTrackTrain func_tracktrain (CPathTrack	*m_ppath)
	if(g_iOffset_m_ppath <= 0)
	{
		g_iOffset_m_ppath = FindDataMapOffs(iEntity, "m_ppath");
	}
	
	return g_iOffset_m_ppath;
}

int Tank_FindPathGoal(int team)
{
	g_strGoalNode[team][0] = '\0';
	
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iWatcher > MaxClients && iTrackTrain > MaxClients)
	{
		GetEntPropString(iWatcher, Prop_Data, "m_iszGoalNode", g_strGoalNode[team], sizeof(g_strGoalNode[]));

		int iPathGoal = Entity_FindEntityByName(g_strGoalNode[team], "path_track");
		if(iPathGoal > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Tank_FindPathGoal) path_track: %d \"%s\"!", iPathGoal, g_strGoalNode[team]);
#endif
			g_iRefPathGoal[team] = EntIndexToEntRef(iPathGoal);

			return iPathGoal;
		}
	}
	
	return -1;
}

int Train_GetCurrentPath(int team)
{
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(g_hSDKGetBaseEntity != INVALID_HANDLE && iTrackTrain > MaxClients)
	{
		int iOffset = Offset_GetPathOffset(iTrackTrain);
		if(iOffset > 0)
		{
			return SDKCall(g_hSDKGetBaseEntity, GetEntData(iTrackTrain, iOffset));
		}
	}
	
	return -1;
}

float Path_GetTotalDistance(int team)
{
	// Gets the total path distance of the entire stage
	return Path_GetDistance(EntRefToEntIndex(g_iRefPathStart[team]), EntRefToEntIndex(g_iRefPathGoal[team]));
}

float Path_GetDistance(int iPathStart, int iPathEnd)
{
	if(iPathStart == iPathEnd) return 0.0;

	// Iterate through all the path_track's and return the distance of the path
	float flDistance = 0.0;
	int iNumTracks;
	bool pathsAreConnected = false;

	if(iPathStart > MaxClients && iPathEnd > MaxClients)
	{
		int iPathCur = iPathStart;
		
		int iOffsetNext = Offset_GetNextOffset(iPathCur);
		int iPathNext;
		while((iPathNext = GetEntDataEnt2(iPathCur, iOffsetNext)) > MaxClients)
		{
			iNumTracks++;
			
			float flPosStart[3];
			float flPosEnd[3];
			GetEntPropVector(iPathCur, Prop_Send, "m_vecOrigin", flPosStart);
			GetEntPropVector(iPathNext, Prop_Send, "m_vecOrigin", flPosEnd);
			
			flDistance += GetVectorDistance(flPosStart, flPosEnd);
			
			iPathCur = iPathNext;
			// We've hit the end of the stage
			if(iPathCur == iPathEnd)
			{
				pathsAreConnected = true;
				break;
			}
		}
	}

	// If the paths are not connected, then return the straight distance between the two path_track's.
	if(!pathsAreConnected)
	{
		if(iPathStart > MaxClients && iPathEnd > MaxClients)
		{
			float pos1[3];
			GetEntPropVector(iPathStart, Prop_Send, "m_vecOrigin", pos1);
			float pos2[3];
			GetEntPropVector(iPathEnd, Prop_Send, "m_vecOrigin", pos2);

			flDistance = GetVectorDistance(pos1, pos2);
#if defined DEBUG
			//PrintToServer("(Path_GetDistance) Non-connected path given (%d to %d), using straight distance (%1.2f) instead!", iPathStart, iPathEnd, flDistance);
#endif
		}	
	}
	
	return flDistance;
}

stock float Train_DistanceToGoal()
{
	// Gets the distance in a straight line from the cart to the goal
	int iPathGoal = EntRefToEntIndex(g_iRefPathGoalBlue);
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrainBlue);
	if(iPathGoal > MaxClients && iTrackTrain > MaxClients)
	{	
		float flPosTrain[3];
		float flPosGoal[3];
		GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPosTrain);
		GetEntPropVector(iPathGoal, Prop_Send, "m_vecOrigin", flPosGoal);
		
		return GetVectorDistance(flPosTrain, flPosGoal);
	}
	
	return 9999.0;
}

float Train_RealDistanceToGoal(int team)
{
	// Iterate through path_tracks to get the distance from the cart to the goal
	float flDistance;
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	int iPathGoal = EntRefToEntIndex(g_iRefPathGoal[team]);
	if(iTrackTrain > MaxClients && iPathGoal > MaxClients)
	{
		int iPathCurrent = Train_GetCurrentPath(team);
		if(iPathCurrent > MaxClients)
		{
			int iPathNext = GetEntDataEnt2(iPathCurrent, Offset_GetNextOffset(iPathCurrent));
			if(iPathNext > MaxClients)
			{
				float flPos1[3];
				float flPos2[3];
				GetEntPropVector(iTrackTrain, Prop_Send, "m_vecOrigin", flPos1);
				GetEntPropVector(iPathNext, Prop_Send, "m_vecOrigin", flPos2);
				flDistance += GetVectorDistance(flPos1, flPos2);
				//PrintToServer("Distance start: %0.2f %d -> %d", flDistance, iPathCurrent, iPathNext);
				
				flDistance += Path_GetDistance(iPathNext, iPathGoal);
				//PrintToServer("Distance final: %0.2f %d -> %d", flDistance, iPathNext, iPathGoal);
				return flDistance;
			}
			
			return flDistance;
		}
	}
	
	return 9999.0;
}

void Train_KillSparks(int iTrackTrain)
{
	int iSpark = MaxClients+1;
	while((iSpark = FindEntityByClassname(iSpark, "env_spark")) != -1)
	{
		if(iSpark > MaxClients && GetEntPropEnt(iSpark, Prop_Send, "moveparent") == iTrackTrain)
		{
#if defined DEBUG
			PrintToServer("(Train_KillSparks) env_spark: %d!", iSpark);
#endif
			AcceptEntityInput(iSpark, "Kill");
		}
	}
}

public Action NormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	/*
	char strClass[32];
	if(entity >= 1 && IsValidEntity(entity)) GetEdictClassname(entity, strClass, sizeof(strClass));
	PrintToServer("Entity: %d \"%s\" Ch: %d Sound: %s, volume: %0.2f, pitch: %0.2f, time: %0.5f", entity, strClass, channel, sample, volume, pitch, GetEngineTime());
	int removeMe;
	*/

	int hitWithScorch = g_hitWithScorchShot;
	bool overrideSound = g_overrideSound;

	g_hitWithScorchShot = 0;
	g_overrideSound = false;

	if(!g_bEnabled) return Plugin_Continue;
	if(overrideSound) return Plugin_Continue;

	float engineTime = GetEngineTime();

	if(strcmp(sample, ")items/cart_rolling.wav") == 0)
	{
		return Plugin_Handled;
	}

	// Block ALL sounds coming from the cart
	for(int iTeam=2; iTeam<=3; iTeam++)
	{
		if(g_iRefTrackTrain[iTeam] != 0)
		{
			int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[iTeam]);
			if(iTrackTrain > MaxClients && iTrackTrain == entity)
			{
				return Plugin_Stop;
			}
		}
		if(g_iRefTrackTrain2[iTeam] != 0)
		{
			int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain2[iTeam]);
			if(iTrackTrain > MaxClients && iTrackTrain == entity)
			{
				return Plugin_Stop;
			}
		}
	}

	if(strncmp(sample, "vo/announcer_cart_defender_finalwarning", 39) == 0 || strncmp(sample, "vo/announcer_cart_attacker_finalwarning", 39) == 0)
	{
		if(g_nGameMode == GameMode_Race)
		{
			// Override "The bomb has almost reached the final terminus" with the team-specific message "Your coming into the final stretch".
			char className[32];
			GetEdictClassname(entity, className, sizeof(className));
			if(strcmp(className, "team_control_point") == 0)
			{
				int team = ControlPoint_GetTeam(entity);
				if(team != -1)
				{
					//PrintToChatAll("Point belongs to: %d", team);
					// The BLU tank is nearing the end.
					if(!g_playedFinalStretch[team])
					{
						BroadcastSoundToTeam(team, SOUND_ANNOUNCER_FINAL_STRETCH_ALLY);
						BroadcastSoundToEnemy(team, SOUND_ANNOUNCER_FINAL_STRETCH_ENEMY);

						g_playedFinalStretch[team] = true;
					}

					return Plugin_Stop;
				}
			}
		}else{
			if(g_nGameMode == GameMode_BombDeploy) return Plugin_Stop; // Block this sound during BombDeploy.

			// GameMode_Tank.
			if(g_bIsFinale)
			{
				// Alert! The tank is almost to the hatch.
				switch(GetRandomInt(0,1))
				{
					case 1: BroadcastSoundToTeam(TFTeam_Red, "vo/mvm_tank_alerts07.mp3"); // Stop it!
					default: BroadcastSoundToTeam(TFTeam_Red, "vo/mvm_tank_alerts06.mp3");
				}
				BroadcastSoundToEnemy(TFTeam_Red, "vo/mvm_tank_alerts06.mp3");

				return Plugin_Stop;
			}
		}
	}

	// Make use of the unused MVM impact sounds.
	if(g_timeLastRobotDamage != 0.0 && engineTime - g_timeLastRobotDamage < 0.01 && config.LookupBool(g_hCvarRobot) && strncmp(sample, "weapons/fx/rics/arrow_impact_flesh", 34) == 0) // 0.05
	{
		// May not work with verbose output.
		//PrintToChatAll("Time diff: %f", engineTime - g_timeLastRobotDamage);

		Format(sample, sizeof(sample), "mvm/melee_impacts/arrow_impact_robo0%d.wav", GetRandomInt(1,3));
		return Plugin_Changed;
	}

	// The tank's horn sound is a little loud, let's quiet it a bit
	if(strcmp(sample, ")mvm/mvm_tank_horn.wav") == 0)
	{
		volume *= 0.5;
		return Plugin_Changed;
	}
	if(strcmp(sample, ")mvm/mvm_tank_explode.wav") == 0)
	{
		volume = 0.5;
		return Plugin_Changed;
	}

	// Catch when a projectile is zapped by the short circuit to detect when sir nukesalot's ball is zapped
	if(strcmp(sample, ")weapons\\barret_arm_shot.wav") == 0)
	{
		if(entity > MaxClients)
		{
			char className[32];
			GetEdictClassname(entity, className, sizeof(className));
			if(strcmp(className, "tf_weapon_mechanical_arm") == 0)
			{
				int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
				if(iOwner >= 1 && iOwner <= MaxClients && IsClientInGame(iOwner) && IsPlayerAlive(iOwner))
				{
					g_iUserIdLastZapper = GetClientUserId(iOwner);
				}
			}
		}
		g_flTimeLastZapped = engineTime;
	}
	
	// Detect when a giant deflects a projectile with the flamethrower
	if(entity > MaxClients && strcmp(sample, ")weapons/flame_thrower_airblast_rocket_redirect.wav") == 0)
	{
		char className[32];
		GetEdictClassname(entity, className, sizeof(className));
		if(strcmp(className, "tf_projectile_pipe_remote") == 0)
		{
			int deflector = GetEntPropEnt(entity, Prop_Send, "m_hDeflectOwner");
			if(deflector >= 1 && deflector <= MaxClients)
			{
				// Detonate deflected stickies
				if(Spawner_HasGiantTag(deflector, GIANTTAG_AIRBLAST_KILLS_STICKIES) && GetEntProp(deflector, Prop_Send, "m_bIsMiniBoss"))
				{
					// Do not destroy the stickies if they belong to a giant.
					int owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
					if(owner >= 1 && owner <= MaxClients && !GetEntProp(owner, Prop_Send, "m_bIsMiniBoss"))
					{
						SetEntProp(entity, Prop_Send, "m_bTouched", true); // This bypass the check that the stickies have come to a rest in order to allow them to take damage.
						SDKHooks_TakeDamage(entity, 0, 0, 100.0, DMG_SLOWBURN|DMG_BUCKSHOT);
					}
				}
			}
		}else{
			int offset = GetEntSendPropOffs(entity, "m_hLauncher", true);
			if(offset > 0)
			{
				int launcherEntity = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
				if(launcherEntity > MaxClients)
				{
					int owner = GetEntPropEnt(launcherEntity, Prop_Send, "m_hOwnerEntity");
					if(owner >= 1 && owner <= MaxClients)
					{
						// Deflected projectile turn into criticals
						if(Spawner_HasGiantTag(owner, GIANTTAG_AIRBLAST_CRITS) && GetEntProp(owner, Prop_Send, "m_bIsMiniBoss"))
						{
							if(GetEntSendPropOffs(entity, "m_bCritical") > 0)
							{
								SetEntProp(entity, Prop_Send, "m_bCritical", true);
							}
						}
					}
				}
			}
		}
	}

	if(hitWithScorch > 0 && (strncmp(sample, "physics/rubber/rubber_tire_impact_bullet", 40) == 0 || strncmp(sample, "weapons/loose_cannon_ball_impact.wav", 36) == 0))
	{
		int giant = GetClientOfUserId(hitWithScorch);
		if(giant >= 1 && giant <= MaxClients && IsClientInGame(giant) && IsPlayerAlive(giant) && GetEntProp(giant, Prop_Send, "m_bIsMiniBoss"))
		{
#if defined DEBUG
			PrintToServer("(SoundHook) Removing TFCond_MegaHeal from %N..", giant);
#endif
			TF2_RemoveCondition(giant, TFCond_MegaHeal);
		}
	}

	// Block the demoman pain sound whenever the sentry buster is destroyed: vo/demoman_PainSharp05.wav
	if(g_busterExplodeTime != 0.0 && engineTime - g_busterExplodeTime < 0.1)
	{
		if(strncmp(sample, "vo/", 3) == 0 && StrContains(sample, "_Pain", false) != -1)
		{
			return Plugin_Stop;
		}
	}

	// The cart concepts for moving backwards and stopping cannot be blocked so easily (TLK_CART_STOP and TLK_CART_MOVING_BACKWARD)
	// https://github.com/ValveSoftware/source-sdk-2013/blob/56accfdb9c4abd32ae1dc26b2e4cc87898cf4dc1/sp/src/game/server/team_train_watcher.cpp#L1141
	if(StrContains(sample, "cartstoppedoffense", false) != -1 || StrContains(sample, "cartgoingback", false) != -1 || StrContains(sample, "cartstopitdefense", false) != -1)
	{
		return Plugin_Stop;
	}

	// When the cart is zoomed to the end when the bomb is deployed, we need to block "the bomb is nearing the checkpoint" announcer sounds
	// Entity: 534 "team_control_point" Ch: 7 Sound: vo/announcer_cart_defender_finalwarning3.wav, volume: 1.00 1678.50683 (there's 6 sounds 1-6 and a version for attacker an defender)
	if(g_nGameMode == GameMode_BombDeploy && strncmp(sample, "vo/announcer_cart_", 18) == 0)
	{
		return Plugin_Stop;
	}

	// Get notified when a player uses a teleport spell
	if(entity > MaxClients)
	{
		if(strcmp(sample, ")weapons/teleporter_ready.wav") == 0)
		{
			char className[64];
			GetEdictClassname(entity, className, sizeof(className));
			if(strcmp(className, "tf_projectile_spelltransposeteleport") == 0)
			{
				int client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
				if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
				{
					float pos[3];
					GetClientAbsOrigin(client, pos);
					
					float mins[3];
					float maxs[3];
					GetClientMins(client, mins);
					GetClientMaxs(client, maxs);

					int team = GetClientTeam(client);
					int mask = MASK_RED;
					if(team != TFTeam_Red) mask = MASK_BLUE;

					TR_TraceHullFilter(pos, pos, mins, maxs, mask, TraceFilter_NotTeam, team);
					if(TR_DidHit())
					{
#if defined DEBUG
						PrintToServer("(SoundHook) Detected that %N may be stuck after teleport spell!", client);
#endif
						// Player is probably stuck so teleport them to a new position
						if(!Player_FindFreePosition2(client, pos, mins, maxs))
						{
#if defined DEBUG
							PrintToServer("(SoundHook) Failed to find a free spot for %N, teleporting them back!", client);
#endif
							TeleportEntity(client, g_spellTeleportPos[client], g_spellTeleportAng[client], NULL_VECTOR);
							EmitSoundToClient(client, SOUND_FIZZLE);
						}
					}
				}
			}
		}else if(strcmp(sample, ")misc/halloween/spell_teleport.wav") == 0)
		{
			char className[64];
			GetEdictClassname(entity, className, sizeof(className));
			if(strcmp(className, "tf_weapon_spellbook") == 0)
			{
				int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
				if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
				{
					GetClientAbsOrigin(client, g_spellTeleportPos[client]);
					GetClientEyeAngles(client, g_spellTeleportAng[client]);
				}
			}
		}
	}

	// The sound that plays when the bridge is raised for the cart can become stuck so stop it from playing entirely.
	if(g_nMapHack == MapHack_ThunderMountain && strcmp(sample, "doors/drawbridge_move1.wav") == 0)
	{
		return Plugin_Stop;
	}

	// Robot sounds for the robot team!
	if(config.LookupBool(g_hCvarRobot) && entity >= 1 && entity <= MaxClients && IsClientInGame(entity) && !TF2_IsPlayerInCondition(entity, TFCond_HalloweenGhostMode))
	{
		int team = GetClientTeam(entity);
		int teamDisguised = GetEntProp(entity, Prop_Send, "m_nDisguiseTeam");
		if((g_nGameMode != GameMode_Race && ((team == TFTeam_Blue && teamDisguised != TFTeam_Red) || teamDisguised == TFTeam_Blue)) || (g_nGameMode == GameMode_Race))
		{
			TFClassType class = TF2_GetPlayerClass(entity);
			if(class == TFClass_Unknown) return Plugin_Continue;

			if(teamDisguised != 0) class = view_as<TFClassType>(GetEntProp(entity, Prop_Send, "m_nDisguiseClass"));

			// Hook footstep sounds
			if(StrContains(sample, "player/footsteps/", false) != -1 && !TF2_IsPlayerInCondition(entity, TFCond_Cloaked))
			{
				if(class != TFClass_Medic) EmitSoundToAll(g_strSoundRobotFootsteps[GetRandomInt(0, sizeof(g_strSoundRobotFootsteps)-1)], entity, _, _, _, 0.13, GetRandomInt(95, 100));
				return Plugin_Stop;
			}

			// Hook falldamage sounds
			if(strcmp(sample, "player/pl_fallpain.wav") == 0)
			{
				volume = 1.0;
				strcopy(sample, sizeof(sample), g_strSoundRobotFallDamage[GetRandomInt(0, sizeof(g_strSoundRobotFallDamage)-1)]);
				return Plugin_Changed;
			}

			// Hook voice lines
			if(StrContains(sample, "vo/", false) != -1 && StrContains(sample, "vo/announcer", false) == -1)
			{
				char strClassMvM[20];
				if(GetEntProp(entity, Prop_Send, "m_bIsMiniBoss") == 1 && class != TFClass_Sniper && class != TFClass_Engineer && class != TFClass_Medic && class != TFClass_Spy)
				{
					// Lookup miniboss sounds
					ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
					Format(strClassMvM, sizeof(strClassMvM), "%s_mvm_m", g_strClassName[view_as<int>(class)]);
				}else{
					ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/norm/", false);
					Format(strClassMvM, sizeof(strClassMvM), "%s_mvm", g_strClassName[view_as<int>(class)]);
				}
				
				ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false); // shouldn't need this anymore
				ReplaceString(sample, sizeof(sample), g_strClassName[view_as<int>(class)], strClassMvM);
				
				char strFileSound[PLATFORM_MAX_PATH];
				Format(strFileSound, sizeof(strFileSound), "sound/%s", sample);
				if(FileExists(strFileSound, true))
				{
					PrecacheSound(sample);
					return Plugin_Changed;
				}
			}
		}
	}

	// Hook weapon sounds for giants.
	if(entity >= 1 && entity <= MaxClients && IsClientInGame(entity) && GetEntProp(entity, Prop_Send, "m_bIsMiniBoss"))
	{
		if(strcmp(sample, ")weapons/rocket_shoot.wav") == 0)
		{
			EmitSoundToAll(SOUND_GIANT_ROCKET, entity, 1, _, _, 1.0);
			
			return Plugin_Stop;
		}else if(strcmp(sample, ")weapons/rocket_shoot_crit.wav") == 0)
		{
			EmitSoundToAll(SOUND_GIANT_ROCKET_CRIT, entity, 1, _, _, 1.0);
			
			return Plugin_Stop;				
		}else if(strcmp(sample, ")weapons/grenade_launcher_shoot.wav") == 0 || strcmp(sample, ")weapons/grenade_launcher_shoot_crit.wav") == 0)
		{
			EmitSoundToAll(SOUND_GIANT_GRENADE, entity, 1, _, _, 1.0);
			
			return Plugin_Stop;
		}else if(strcmp(sample, ")weapons/bow_shoot_pull.wav") == 0)
		{
			pitch = 100;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public void Event_PlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;
	
	if(g_nGameMode == GameMode_Unknown)
	{
		// Players can sometimes spawn before the round has started.
		Mod_DetermineGameMode();
	}

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		// Clear some misc variables
		g_flHasShield[client] = 0.0;

		Reanimator_Cleanup(client);
		g_bReanimatorSwitched[client] = false;

		// The quickfix sound keeps playing after a player is revived
		StopSound(client, 6, SOUND_QUICKFIX_LOOP);

		VisionFlags_Update(client);
		ModelOverrides_Clear(client);
		Attributes_Clear(client);

		if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
		{
#if defined DEBUG
			PrintToServer("(Event_PlayerSpawn) Clearing giant: %N!", client);
#endif
			Giant_Clear(client);
		}
		
		int team = GetClientTeam(client);
		// Turn the blue team (attackers) to robots
		if(config.LookupBool(g_hCvarRobot))
		{
			switch(team)
			{
				case TFTeam_Blue:
				{
					Robot_Toggle(client, true);
				}
				case TFTeam_Red:
				{
					// Robot player models will be used in plr_ maps
					if(g_nGameMode == GameMode_Race)
					{
						Robot_Toggle(client, true);
					}else{
						Robot_Toggle(client, false);
					}
				}
			}
		}

		// Enforce class restrictions on spawn.
		int currentClass = view_as<int>(TF2_GetPlayerClass(client));
		//PrintToServer("(PlayerSpawn) %N - team %d - class %d", client, team, currentClass);
		if(!ClassRestrict_IsImmune(client) && ClassRestrict_IsFull(team, currentClass) && ClassRestrict_PickClass(client, team))
		{
			ShowVGUIPanel(client, team == TFTeam_Blue ? "class_blue" : "class_red");
			EmitSoundToClient(client, g_strSoundNo[currentClass]);
		}else{
			// Player has spawned and is an acceptable class
			if(g_iClassOverride != client) Attributes_Set(client); // Don't apply special attributes when a player is becoming a giant

			if(g_bIsRoundStarted && (team == TFTeam_Red || team == TFTeam_Blue) && g_nGiantTeleporter[team][g_iGiantTeleporterRefExit] != 0 && g_iClassOverride != client && !g_nSpawner[client][g_bSpawnerEnabled])
			{
				int iExit = EntRefToEntIndex(g_nGiantTeleporter[team][g_iGiantTeleporterRefExit]);
				if(iExit > MaxClients)
				{
					// Check if the teleporter is ready
					int iState = GetEntProp(iExit, Prop_Send, "m_iState");
					if(iState >= 2 && !GetEntProp(iExit, Prop_Send, "m_bHasSapper"))
					{
						// Instead of immediately teleporting the player, put them into a queue
						// Unfortunately, I don't seem to be able to send multiple players on the same frame so out of desperation I came up with this solution

						// Clear them from the tele queue to prevent duplication
						int iRefClient = EntIndexToEntRef(client);
						for(int i=GetArraySize(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue])-1; i>=0; i--)
						{
							if(GetArrayCell(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue], i) == iRefClient)
							{
								RemoveFromArray(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue], i);
							}
						}

						PushArrayCell(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue], iRefClient);
					}
				}
			}

			if(!g_hasSpawnedOnce[client])
			{
				g_hasSpawnedOnce[client] = true;

				PrintToChat(client, "%t", "Tank_Chat_Creators", g_strTeamColors[TFTeam_Blue], 0x01, PLUGIN_VERSION, "\x075885A2", 0x01, "\x075885A2", 0x01);

				if(!IsFakeClient(client) && GetConVarInt(g_hCvarUpdatesPanel) == UpdatesPanel_AlwaysShow)
				{
					ShowUpdatePanel(client);
				}
			}
		}
	}
}

void Robot_Toggle(int client, bool bEnable)
{
	if(bEnable)
	{
		// Make the player into a robot
		SetVariantString(g_strModelRobots[TF2_GetPlayerClass(client)]);
		
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

		// Fix BLU spies appearing RED to teammates while disguised
		/*
		new team = GetClientTeam(client);
		if(g_nGameMode != GameMode_Race)
		{
			if(team == TFTeam_Blue && TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				SetEntProp(client, Prop_Send, "m_bForcedSkin", true);
				SetEntProp(client, Prop_Send, "m_nForcedSkin", team-2);
			}else{
				SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
				SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);		
			}
		}else{
			SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
			SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);	
		}
		*/
	}else{
		// Return the player back to normal
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);

		/*
		SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
		*/
	}
}

float g_flTankTempPos[MAX_TEAMS][3];
float g_flTankTempAng[MAX_TEAMS][3];
public void OnEntityDestroyed(int entity)
{
	//char strClassname[40];
	//GetEdictClassname(entity, strClassname, sizeof(strClassname));
	//PrintToServer("(OnEntityDestroyed) %d %s!", entity, strClassname);
	if(entity > 0) g_entitiesOfInterest[entity] = Interest_None;

	if(!g_bEnabled) return;

	// During the finale, the tank is sometimes destroyed before the explosion (by the map) because it's parent (the func_tracktrain) is destroyed
	// Try to detect this and unparent the tank at the last second, hopefully this will work
	// Check both team's tanks to see if their parent is removed
	for(int iTeam=2; iTeam<=3; iTeam++)
	{
		int iTank = EntRefToEntIndex(g_iRefTank[iTeam]);
		if(iTank > MaxClients)
		{
			if(iTank == entity)
			{
				StopSound(iTank, SNDCHAN_STATIC, "^mvm/mvm_tank_loop.wav");
			}

			if(GetEntPropEnt(iTank, Prop_Send, "moveparent") == entity)
			{
				// Give the tank godmode to prevent it from being destroyed by players at this point
				SetEntProp(iTank, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY); // Buddah

				if(g_nMapHack == MapHack_Hightower || g_nMapHack == MapHack_HightowerEvent)
				{
					// The round ends too quickly to wait 0.1s and teleport the tank, which means the tank is in limbo when the round ends
					// Just force the tank to explode right away when its parent is killed
					SetVariantInt(MAX_TANK_HEALTH);
					AcceptEntityInput(iTank, "RemoveHealth");
#if defined DEBUG
					PrintToServer("(OnEntityDestroyed) Tank's parent: %d destroyed, killing tank: %d!", entity, iTank);
#endif
					// We're going to assume the round has ended and stop all func_tracktrain entities
					for(int a=2; a<=3; a++)
					{
						int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[a]);
						if(iTrackTrain > MaxClients)
						{
							SetVariantFloat(0.0);
							AcceptEntityInput(iTrackTrain, "SetSpeedDir");
						}
						iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain2[a]);
						if(iTrackTrain > MaxClients)
						{
							SetVariantFloat(0.0);
							AcceptEntityInput(iTrackTrain, "SetSpeedDir");
						}
						int iTankEnt = EntRefToEntIndex(g_iRefTank[a]);
						if(iTankEnt > MaxClients)
						{
							SetEntProp(iTankEnt, Prop_Send, "m_bGlowEnabled", false, 1);
						}

						Train_Move(a, 0.0);

						// Disable the trigger_capture_area so that the tank logic will stop
						int iTrigger = EntRefToEntIndex(g_iRefTrigger[a]);
						if(iTrigger > MaxClients)
						{
							AcceptEntityInput(iTrigger, "Disable");
						}

						g_bEnableMapHack[a] = false; // disengages the special lift move logic
					}

					if(g_nMapHack == MapHack_HightowerEvent && g_hellTeamWinner == 0)
					{
						g_hellTeamWinner = iTeam;
#if defined DEBUG
						PrintToServer("(OnEntityDestroyed) Hell started, winning team = %d!", iTeam);
#endif
						// Disable the rage meter while in hell!
						RageMeter_Cleanup();
						Bomb_KillTimer(); // Kill the team_round_timer should it still be running
						Announcer_SetEnabled(false);

						// Activate the giant spawner to start looking for an eligible player to become the giant robot
						// We are entering hell so queue up a giant robot
						for(int team=2; team<=3; team++)
						{
							// Do not spawn any sentry busters while in hell
							Buster_Cleanup(team);

							Giant_Cleanup(team);
							g_nTeamGiant[team][g_bTeamGiantActive] = true;
							g_nTeamGiant[team][g_flTeamGiantTimeRoundStarts] = GetEngineTime()+12.0; // time when the spawn process should begin
							g_nTeamGiant[team][g_bTeamGiantNoRageMeter] = true;
						}

						Hell_KillGateTimer();
						g_hellGateTimer = CreateTimer(config.LookupFloat(g_hCvarHellTowerTimeGate), Timer_GatesOfHell, _, TIMER_REPEAT);

						// Kill off any alive Sentry Busters so they aren't teleported to hell.
						for(int i=1; i<=MaxClients; i++)
						{
							if(Spawner_HasGiantTag(i, GIANTTAG_SENTRYBUSTER) && IsClientInGame(i))
							{
								if(GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
								{
									if(IsPlayerAlive(i))
									{
										ForcePlayerSuicide(i);
										FakeClientCommand(i, "explode");
									}

									if(GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
									{
#if defined DEBUG
										PrintToServer("(OnEntityDestroyed) Clearing giant: %N!", i);
#endif
										Giant_Clear(i);
									}
								}

								Spawner_Cleanup(i);
							}
						}

					}

					// Nuke a bunch of map logic to hopefully prevent some helltower crashes
					if(g_nMapHack == MapHack_HightowerEvent)
					{
						// I believe the crash is related to these two func_tracktrain.
						// Removing the props is probably not necessary but doesn't hurt.
						// CFuncTrackTrain::DeadEnd(void) or CBaseEntity::VPhysicsUpdatePusher(IPhysicsObject *) are the two crashes.
						int iEntity = Entity_FindEntityByName("corpse_fly_blut_train", "func_tracktrain");
						if(iEntity > MaxClients)
						{
							AcceptEntityInput(iEntity, "Kill");
						}
						iEntity = Entity_FindEntityByName("corpse_fly_redm_train", "func_tracktrain");
						if(iEntity > MaxClients)
						{
							AcceptEntityInput(iEntity, "Kill");
						}

						iEntity = Entity_FindEntityByName("corpse_fly_blut_dynamic", "prop_dynamic");
						if(iEntity > MaxClients)
						{
							AcceptEntityInput(iEntity, "Kill");
						}
						iEntity = Entity_FindEntityByName("corpse_fly_redm_dynamic", "prop_dynamic");
						if(iEntity > MaxClients)
						{
							AcceptEntityInput(iEntity, "Kill");
						}
					}
				}else{
					AcceptEntityInput(iTank, "ClearParent");
					SetEntityMoveType(iTank, MOVETYPE_CUSTOM);

					GetEntPropVector(iTank, Prop_Send, "m_vecOrigin", g_flTankTempPos[iTeam]);
					GetEntPropVector(iTank, Prop_Send, "m_angRotation", g_flTankTempAng[iTeam]);
					
					CreateTimer(0.1, Timer_TankTeleportFinale, iTeam);
#if defined DEBUG
					PrintToChatAll("UN-PARENTED THE TANK TO THE CART FOR FINALE!!");
#endif
					// Teleport the cart prop on the goal node for maps with triggers to work on finales
					int iGoalNode = EntRefToEntIndex(g_iRefPathGoal[iTeam]);
					if(iGoalNode > MaxClients)
					{
						float flPos[3];
						GetEntPropVector(iGoalNode, Prop_Send, "m_vecOrigin", flPos);
						
						for(int i=0,size=g_trainProps.Length; i<size; i++)
						{
							int array[ARRAY_TRAINPROP_SIZE];
							g_trainProps.GetArray(i, array, sizeof(array));

							int prop = EntRefToEntIndex(array[TrainPropArray_Reference]);
							if(prop > MaxClients)
							{
#if defined DEBUG
								PrintToServer("(OnEntityDestroyed) Restoring m_nSolidType %d on %d!", array[TrainPropArray_SolidType], prop);
#endif
								SetEntProp(prop, Prop_Send, "m_nSolidType", array[TrainPropArray_SolidType]); // Just to be safe.
								TeleportEntity(prop, flPos, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}

					// For some reason, the bomb mechanism stays with the cart. Since we won't need it in plr_ kill it
					if(g_nGameMode == GameMode_Race)
					{
						int iMechanism = EntRefToEntIndex(g_iRefTankMechanism[iTeam]);
						if(iMechanism > MaxClients)
						{
#if defined DEBUG
							PrintToServer("(OnEntityDestroyed) Killing tank bomb mechanism(%d): %d!", iTeam, iMechanism);
#endif
							AcceptEntityInput(iMechanism, "Kill");
						}
					}
				}
			}
		}
	}

	if(g_bIsRoundStarted && IsValidEdict(entity))
	{
		// Detect when Sir Nukesalot's cannon balls explode and add an explosion sound
		char strClassname[25];
		GetEdictClassname(entity, strClassname, sizeof(strClassname));
		//PrintToServer("Entity: %s", strClassname);
		if(strcmp(strClassname, "tf_projectile_pipe") == 0)
		{
			int iThrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
			if(iThrower >= 1 && iThrower <= MaxClients && Spawner_HasGiantTag(iThrower, GIANTTAG_PIPE_EXPLODE_SOUND) && IsClientInGame(iThrower) && GetEntProp(iThrower, Prop_Send, "m_bIsMiniBoss"))
			{
				float flPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flPos);
				
				// Don't play an explosion sound if the pipe is removed by the short circuit
				//PrintToChatAll("%d Time passed: %f", g_iUserIdLastZapper, GetEngineTime() - g_flTimeLastZapped);
				if(g_flTimeLastZapped == 0.0 || GetEngineTime() - g_flTimeLastZapped > 0.1)
				{
					BroadcastSoundToTeam(TFTeam_Spectator, g_strSoundNukes[GetRandomInt(0, sizeof(g_strSoundNukes)-1)]);
				}else if(g_iUserIdLastZapper != 0)
				{
					// Assume that the projectile was zapped so reduce the player's metal
					int client = GetClientOfUserId(g_iUserIdLastZapper);
					if(client >= 1 && client <= MaxClients && IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Engineer && GetClientTeam(client) != GetClientTeam(iThrower) && IsPlayerAlive(client))
					{
						int iCurMetal = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 3) - config.LookupInt(g_hCvarZapPenalty);
						if(iCurMetal < 0) iCurMetal = 0;
						SetEntProp(client, Prop_Send, "m_iAmmo", iCurMetal, 4, 3);
					}
				}

				g_iUserIdLastZapper = 0;
			}
		}
	}
}

public Action Timer_TankTeleportFinale(Handle hTimer, int team)
{
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	if(iTank > MaxClients)
	{
		TeleportEntity(iTank, g_flTankTempPos[team], g_flTankTempAng[team], NULL_VECTOR);
	}
}

void CritCash_RemoveEffects()
{
	// Remove the crits and medigun shield effects from all players.
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) >= 2 && IsPlayerAlive(client))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture)) TF2_RemoveCondition(client, TFCond_CritOnFlagCapture);

			if(TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				g_flHasShield[client] = 0.0;
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0); // Remove any rage so they can't pop a shield later
				int shield = MaxClients+1;
				while((shield = FindEntityByClassname(shield, "entity_medigun_shield")) > MaxClients)
				{
					AcceptEntityInput(shield, "Kill");
				}
			}
		}
	}
}

public Action CritCash_OnTouch(int entity, int client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		switch(GetClientTeam(client))
		{
			case TFTeam_Red:
			{
				TFClassType class = TF2_GetPlayerClass(client);

				// Do not let the player's pick up crit cash if the giant has spawned.
				if(g_nGameMode == GameMode_BombDeploy && g_nTeamGiant[TFTeam_Blue][g_bTeamGiantActive] && g_nTeamGiant[TFTeam_Blue][g_bTeamGiantNoCritCash])
				{
					return Plugin_Handled;
				}

				// Players can only pick up one piece of cash at a time
				if(g_flTimeCashPickup[client] != 0.0 && GetEngineTime() - g_flTimeCashPickup[client] < config.LookupFloat(g_hCvarCurrencyCrit)) return Plugin_Handled;
				g_flTimeCashPickup[client] = GetEngineTime();

				// RED receives crits for a short duration
				TF2_AddCondition(client, TFCond_CritOnFlagCapture, config.LookupFloat(g_hCvarCurrencyCrit));
				// RED receives healing for a short duration
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, config.LookupFloat(g_hCvarBombHealDuration));
				// RED medics receive medigun shields
				if(class == TFClass_Medic)
				{
					g_flHasShield[client] = GetEngineTime();
				}

				// RED receives full ammo
				for(int i=0; i<3; i++)
				{
					int iWeapon = GetPlayerWeaponSlot(client, i);
					if(iWeapon > MaxClients)
					{
						int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
						if(iAmmoType > -1)
						{
							int iMaxAmmo = SDK_GetMaxAmmo(client, iAmmoType);
							SetEntProp(client, Prop_Send, "m_iAmmo", iMaxAmmo, 4, iAmmoType);
						}						
					}
				}

				// Replenish engineer metal
				int iMaxMetal = MaxMetal_Get(client);
				if(class == TFClass_Engineer && GetEntProp(client, Prop_Send, "m_iAmmo", 4, 3) < iMaxMetal)
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", iMaxMetal, 4, 3);
				}

				// Replenish demoman's charge shield
				if(class == TFClass_DemoMan && !TF2_IsPlayerInCondition(client, TFCond_Charging))
				{
					SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
				}

				// Replenish spy's cloak meter
				if(class == TFClass_Spy)
				{
					SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
				}

				// Voice lines that should be played by HUMANS whenever a tank is destroyed
				if(GetURandomFloat() < 0.65 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
				{
					switch(class)
					{
						case TFClass_Scout: EmitSoundToAll(g_strSoundCashScout[GetRandomInt(0, sizeof(g_strSoundCashScout)-1)], client, SNDCHAN_VOICE);
						case TFClass_Sniper: EmitSoundToAll(g_strSoundCashSniper[GetRandomInt(0, sizeof(g_strSoundCashSniper)-1)], client, SNDCHAN_VOICE);
						case TFClass_Soldier: EmitSoundToAll(g_strSoundCashSoldier[GetRandomInt(0, sizeof(g_strSoundCashSoldier)-1)], client, SNDCHAN_VOICE);
						case TFClass_DemoMan: EmitSoundToAll(g_strSoundCashDemoman[GetRandomInt(0, sizeof(g_strSoundCashDemoman)-1)], client, SNDCHAN_VOICE);
						case TFClass_Heavy: EmitSoundToAll(g_strSoundCashHeavy[GetRandomInt(0, sizeof(g_strSoundCashHeavy)-1)], client, SNDCHAN_VOICE);
						case TFClass_Pyro: EmitSoundToAll(g_strSoundCashPyro[GetRandomInt(0, sizeof(g_strSoundCashPyro)-1)], client, SNDCHAN_VOICE);
						case TFClass_Spy: EmitSoundToAll(g_strSoundCashSpy[GetRandomInt(0, sizeof(g_strSoundCashSpy)-1)], client, SNDCHAN_VOICE);
						case TFClass_Engineer: EmitSoundToAll(g_strSoundCashEngineer[GetRandomInt(0, sizeof(g_strSoundCashEngineer)-1)], client, SNDCHAN_VOICE);
					}
				}
			}
			case TFTeam_Blue:
			{
				// BLU is no longer allowed to pick up dropped currency from the tank
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Bomb_OnTouch(int iBomb, int iToucher)
{
	// Don't allow bomb pickup until the round has started and the bomb has been handed off to a giant
	if(!g_bIsRoundStarted) return Plugin_Handled;

	// No one can pickup the bomb as long as the giant robot is still spawning / still around
	if(g_nTeamGiant[TFTeam_Blue][g_bTeamGiantActive])
	{
		int iGiant = GetClientOfUserId(g_nTeamGiant[TFTeam_Blue][g_iTeamGiantQueuedUserId]);
		if(iGiant >= 1 && iGiant <= MaxClients && IsClientInGame(iGiant) && GetEntProp(iGiant, Prop_Send, "m_bIsMiniBoss"))
		{
			if(g_nSpawner[iGiant][g_bSpawnerEnabled] && g_nSpawner[iGiant][g_nSpawnerType] == Spawn_GiantRobot)
			{
				if(g_nGiants[g_nSpawner[iGiant][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_CAN_DROP_BOMB) return Plugin_Continue;

				if(iGiant == iToucher) return Plugin_Continue;
			}
		}

		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void NextFrame_FindFeignSpy(any unused)
{
	// Find the real spy that feigned
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i) && TF2_GetPlayerClass(i) == TFClass_Spy && TF2_IsPlayerInCondition(i, TFCond_DeadRingered) && GetEntProp(i, Prop_Send, "m_nDisguiseTeam") == TFTeam_Red && GetEntPropFloat(i, Prop_Send, "m_flCloakMeter") >= 100.0)
		{
			Reanimator_Cleanup(i);

			Reanimator_Create(i, true, GetEntProp(i, Prop_Send, "m_nDisguiseClass"));
			break;
		}
	}	
}

public Action Event_PlayerDeath(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return Plugin_Continue;
	
	int iVictim = GetEventInt(hEvent, "victim_entindex");
	if(iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim))
	{
		int teamVictim = GetClientTeam(iVictim);
		if(GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		{
			// We need to lay down a fake marker for RED spies that feign death, this dummy marker will show to everyone on the server
			if(g_nGameMode != GameMode_Race && teamVictim == TFTeam_Red && !Tank_IsInSetup())
			{
				// If the spy is disguised as someone from his team, the death event will filled out for the person the spy disguised as
				if(TF2_GetPlayerClass(iVictim) != TFClass_Spy)
				{
					RequestFrame(NextFrame_FindFeignSpy);

					return Plugin_Continue;
				}

				Reanimator_Cleanup(iVictim);
				int disguisedClass = 0;
				if(GetEntProp(iVictim, Prop_Send, "m_nDisguiseTeam") == TFTeam_Red)
				{
					disguisedClass = GetEntProp(iVictim, Prop_Send, "m_nDisguiseClass");
				}
				Reanimator_Create(iVictim, true, disguisedClass);
			}

			return Plugin_Continue;
		}

		g_flTimeLastDied[iVictim] = GetEngineTime();

		// Spawn the reanimator whenever a RED team member perishes
		if(g_nGameMode != GameMode_Race && teamVictim == TFTeam_Red && !Tank_IsInSetup())
		{
			// Don't spawn a reanimator when the player is stabbed with the YER
			char strWeapon[20];
			GetEventString(hEvent, "weapon_logclassname", strWeapon, sizeof(strWeapon));
			if(!(GetEventInt(hEvent, "customkill") == TF_CUSTOM_BACKSTAB && (strcmp(strWeapon, "eternal_reward") == 0 || strcmp(strWeapon, "voodoo_pin") == 0)))
			{
				// The player_team event is sent before the player_death event so we must block deaths that occured immediately after a team changes
				if(!g_bReanimatorSwitched[iVictim])
				{
					Reanimator_Cleanup(iVictim);
					Reanimator_Create(iVictim);
				}
			}
		}

		// Check if the giant died and clean-up effects
		bool giantWasVictim = false;
		if(GetEntProp(iVictim, Prop_Send, "m_bIsMiniBoss"))
		{
#if defined DEBUG
			PrintToServer("(Event_PlayerDeath) Clearing giant: %N!", iVictim);
#endif	
			giantWasVictim = (g_nSpawner[iVictim][g_bSpawnerEnabled] && g_nSpawner[iVictim][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[iVictim][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER));

			// Catch the giant suicide message when he explodes and block it
			if(Spawner_HasGiantTag(iVictim, GIANTTAG_SENTRYBUSTER))
			{
				SetEventBroadcast(hEvent, true);

				// Block the log action to prevent the player from losing any points in hlstats.
				g_blockLogAction = true;
			}
			
			Giant_PlayDestructionSound(iVictim);

			Giant_Clear(iVictim, GiantCleared_Death);
		}

		// If the player died from a trigger_hurt and was carrying the bomb, we need to return the bomb back
		if(g_nGameMode == GameMode_BombDeploy && GetEventInt(hEvent, "customkill") == TF_CUSTOM_TRIGGER_HURT)
		{
			// Check if the player that died was carrying the bomb
			int iBombFlag = EntRefToEntIndex(g_iRefBombFlag);
			if(iBombFlag > MaxClients && GetEntPropEnt(iBombFlag, Prop_Send, "moveparent") == iVictim)
			{
				int iTriggerHurt = GetEventInt(hEvent, "inflictor_entindex");
				if(iTriggerHurt > MaxClients && IsValidEntity(iTriggerHurt))
				{
					if(!GetEntProp(iTriggerHurt, Prop_Data, "m_bDisabled") && GetEntPropFloat(iTriggerHurt, Prop_Data, "m_flDamage") > 300.0)
					{
#if defined DEBUG
						PrintToServer("(Event_PlayerDeath) %N fell/died with the bomb from a trigger_hurt!", iVictim);
#endif
						g_flTimeBombFell = GetEngineTime();
					}
				}
			}
		}

		char strWeapon[50];
		GetEventString(hEvent, "weapon", strWeapon, sizeof(strWeapon));	

		// count deaths to clear the rage hud
		int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		if(iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker) && iAttacker != iVictim)
		{
			RageMeter_OnDamageDealt(iAttacker);

			if(strcmp(strWeapon, "env_explosion") == 0)
			{
				//PrintToServer("Time: %0.5f", GetEngineTime() - g_busterExplodeTime);
				if(g_busterExplodeTime != 0.0 && GetEngineTime() - g_busterExplodeTime < 0.5)
				{
					// Modify the death icon for the explosion after the bomb
					SetEventString(hEvent, "weapon_logclassname", "bomb_kamikaze");
					SetEventString(hEvent, "weapon", "tf_pumpkin_bomb");
					SetEventInt(hEvent, "customkill", TF_CUSTOM_PUMPKIN_BOMB);
					SetEventInt(hEvent, "damagebits",  GetEventInt(hEvent, "damagebits")|DMG_CRIT);
				}
			}

			if(teamVictim != GetClientTeam(iAttacker))
			{
				//PrintToServer("Weapon: \"%s\"", strWeapon);
				if(strcmp(strWeapon, "wrangler_kill") == 0 || strncmp(strWeapon, "obj_sentrygun", 13) == 0 || strcmp(strWeapon, "obj_minisentry") == 0)
				{
					// Mini-sentries should not activate a sentry buster unless it is a giant's mini-sentry.
					if(strcmp(strWeapon, "obj_minisentry") != 0 || GetEntProp(iAttacker, Prop_Send, "m_bIsMiniBoss"))
					{
						Buster_IncrementStat(BusterStat_Robots, teamVictim, 1);
					}
				}

				// Play a voiceline when a human player kills a giant in pl_
				if(giantWasVictim && g_nGameMode != GameMode_Race && teamVictim == TFTeam_Blue && IsPlayerAlive(iAttacker))
				{
					switch(TF2_GetPlayerClass(iAttacker))
					{
						case TFClass_Scout: EmitSoundToAll(g_strSoundGiantKillScout[GetRandomInt(0, sizeof(g_strSoundGiantKillScout)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Sniper: EmitSoundToAll(g_strSoundGiantKillSniper[GetRandomInt(0, sizeof(g_strSoundGiantKillSniper)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Soldier: EmitSoundToAll(g_strSoundGiantKillSoldier[GetRandomInt(0, sizeof(g_strSoundGiantKillSoldier)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_DemoMan: EmitSoundToAll(g_strSoundGiantKillDemoman[GetRandomInt(0, sizeof(g_strSoundGiantKillDemoman)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Medic: EmitSoundToAll(g_strSoundGiantKillMedic[GetRandomInt(0, sizeof(g_strSoundGiantKillMedic)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Heavy: EmitSoundToAll(g_strSoundGiantKillHeavy[GetRandomInt(0, sizeof(g_strSoundGiantKillHeavy)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Pyro: EmitSoundToAll(g_strSoundGiantKillPyro[GetRandomInt(0, sizeof(g_strSoundGiantKillPyro)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Spy: EmitSoundToAll(g_strSoundGiantKillSpy[GetRandomInt(0, sizeof(g_strSoundGiantKillSpy)-1)], iAttacker, SNDCHAN_VOICE);
						case TFClass_Engineer: EmitSoundToAll(g_strSoundGiantKillEngineer[GetRandomInt(0, sizeof(g_strSoundGiantKillEngineer)-1)], iAttacker, SNDCHAN_VOICE);
					}					
				}
			}
		}

		// count assists to clear the rage hud
		int iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));
		if(iAssister >= 1 && iAssister <= MaxClients && IsClientInGame(iAssister) && iAssister != iVictim)
		{
			RageMeter_OnDamageDealt(iAssister);
		}
	
		if(strcmp(strWeapon, "tank_boss") == 0)
		{
			// Player has died from the tank
			EmitSoundToClient(iVictim, SOUND_LOSE);
			
			// Reproduces the train icon, kind of looks like a tank?
			SetEventInt(hEvent, "customkill", TF_CUSTOM_TRIGGER_HURT);
			SetEventInt(hEvent, "damagebits", 16);
			
			// Tank kill counter
			int numKills = 0;
			Handle hFile = OpenFile(FILE_TANK_KILLCOUNTER, "r");
			if(hFile != INVALID_HANDLE)
			{
				char strLine[50];
				ReadFileLine(hFile, strLine, sizeof(strLine));                   
				TrimString(strLine);
				
				numKills = StringToInt(strLine);
				
				CloseHandle(hFile);
			}
			if(numKills < 0) numKills = 0;
			
			numKills++;
			bool rankedUp = false;
			int rankIndex = -1;
			char rank[TANKRANK_NAME_MAXLEN] = "Strange";
			for(int i=sizeof(g_tankRank)-1; i>=0; i--)
			{
				if(numKills >= g_tankRank[i][g_tankRankNumKills])
				{
					strcopy(rank, sizeof(rank), g_tankRank[i][g_tankRankName]);

					if(numKills == g_tankRank[i][g_tankRankNumKills])
					{
						// The tank has reached a new rank
						rankedUp = true;
					}

					rankIndex = i;
					break;
				}
			}

			int loopKills = 5000;
			int mark;
			if(rankIndex == sizeof(g_tankRank)-1 && (mark=((numKills - g_tankRank[rankIndex][g_tankRankNumKills]) / loopKills)) >= 1)
			{
				// The tank has reached the final rank, we need to calculate how many times it has leveled up in the final rank
				// Each 5000 kills will count as a mark
				PrintToChatAll("%t", "Tank_Chat_TankKS_Kills_Mk", COLOR_TANK_STRANGE, rank, mark+1, 0x01, numKills);

				if(numKills % loopKills == 0)
				{
					Tank_OnRankUp();
					PrintToChatAll("%t", "Tank_Chat_TankKS_NewRank_Mk", 0x01, COLOR_TANK_STRANGE, rank, mark+1, 0x01);

					char text[128];
					Format(text, sizeof(text), "%T", "Tank_GameText_TankKS_NewRank_Mk", LANG_SERVER, rank, mark+1);
					ShowGameMessage(text, "leaderboard_streak");
				}
			}else{
				PrintToChatAll("%t", "Tank_Chat_TankKS_Kills", COLOR_TANK_STRANGE, rank, 0x01, numKills);
			}

			if(rankedUp)
			{
				Tank_OnRankUp();
				PrintToChatAll("%t", "Tank_Chat_TankKS_NewRank", 0x01, COLOR_TANK_STRANGE, rank, 0x01);

				char text[128];
				Format(text, sizeof(text), "%T", "Tank_GameText_TankKS_NewRank", LANG_SERVER, rank);
				ShowGameMessage(text, "leaderboard_streak");
			}
			
			hFile = OpenFile(FILE_TANK_KILLCOUNTER, "w");
			if(hFile != INVALID_HANDLE)
			{
				WriteFileLine(hFile, "%d", numKills);
				CloseHandle(hFile);
			}
		}
	}
	
	return Plugin_Continue;
}

public void Event_TankHurt(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;
		
	int iTank = GetEventInt(hEvent, "entindex");
	int team;
	if(iTank > MaxClients) team = GetEntProp(iTank, Prop_Send, "m_iTeamNum");

	if(team >= 0 && team < MAX_TEAMS && iTank == EntRefToEntIndex(g_iRefTank[team]))
	{
		int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker_player"));
		if(iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker))
		{
			// A player has done damage to the tank so log it
			int iDamage = GetEventInt(hEvent, "damageamount");

			// Log damage dealt to the tank by a sentry
			if(g_bTakingSentryDamage)
			{
				g_bTakingSentryDamage = false;
				Buster_IncrementStat(BusterStat_Tank, team, iDamage);
			}

			g_iDamageStatsTank[iAttacker][team] += iDamage; // stats for tank mvp
			g_iDamageAccul[iAttacker][team] += iDamage; // acculmulated damage for extra points
			g_iRaceTankDamage[team] += iDamage; // damage to calculate tank speed in plr_

			// Check accumulated points to see if the player has earned some scoreboard points
			while(g_iDamageAccul[iAttacker][team] >= config.LookupInt(g_hCvarPointsDamageTank))
			{
				int numPoints = config.LookupInt(g_hCvarPointsForTank);
				if(g_nGameMode == GameMode_Race) numPoints = config.LookupInt(g_hCvarPointsForTankPlr);

				Score_IncrementBonusPoints(iAttacker, numPoints);

				// Log hlstats event: tank_damage

				char logEvent[32] = "tank_damage";
				if(g_nGameMode == GameMode_Race) logEvent = "tank_damage_race";

				char auth[32];
				GetClientAuthId(iAttacker, AuthId_Steam3, auth, sizeof(auth));
				LogToGame("\"%N<%d><%s><%s>\" triggered \"%s\"", iAttacker, GetClientUserId(iAttacker), auth, g_strTeamClass[GetClientTeam(iAttacker)], logEvent);

				g_iDamageAccul[iAttacker][team] -= config.LookupInt(g_hCvarPointsDamageTank);
			}
		}
	}
}

public void Event_PlayerHurt(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;
	
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if(iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim) && iVictim != iAttacker)
	{
		int iDamage = GetEventInt(hEvent, "damageamount");
		if(g_nGameMode == GameMode_BombDeploy && iAttacker == 0 && GetEventInt(hEvent, "health") == 0 && iDamage >= 300)
		{
			int bomb = EntRefToEntIndex(g_iRefBombFlag);
			if(bomb > MaxClients && GetEntPropEnt(bomb, Prop_Send, "moveparent") == iVictim)
			{
#if defined DEBUG
				PrintToServer("(Event_PlayerHurt) %N died to world with %d damage, assuming trigger_hurt death and resetting bomb!", iVictim, iDamage);
#endif
				g_flTimeBombFell = GetEngineTime();
			}
		}

		if(iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker))
		{
			int teamVictim = GetClientTeam(iVictim);

			// Record the last time when the giant robot has done damage for the purposes of the rage meter
			RageMeter_OnDamageDealt(iAttacker);
			RageMeter_OnTookDamage(iVictim);

			// Keep track of damage dealt to the giant robot
			if(g_nSpawner[iVictim][g_bSpawnerEnabled] && g_nSpawner[iVictim][g_nSpawnerType] == Spawn_GiantRobot && GetEntProp(iVictim, Prop_Send, "m_bIsMiniBoss"))
			{
				// Don't count damage done to the sentry buster for the Giant MVP
				if(!(g_nGiants[g_nSpawner[iVictim][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
				{
					g_iDamageStatsGiant[iVictim][iAttacker] += iDamage; // Record how much damage the attacker did to this particular giant for the giant mvp.

					// Log damage dealt to the giant by a sentry
					if(g_bTakingSentryDamage)
					{
						g_bTakingSentryDamage = false;
						Buster_IncrementStat(BusterStat_Giant, teamVictim, iDamage);
					}
				}

				// Check accumulated points to see if the player has earned some scoreboard points
				g_iDamageAccul[iAttacker][teamVictim] += iDamage;
				while(g_iDamageAccul[iAttacker][teamVictim] >= config.LookupInt(g_hCvarPointsDamageGiant))
				{
					int numPoints = config.LookupInt(g_hCvarPointsForGiant);
					if(g_nGameMode == GameMode_Race) numPoints = config.LookupInt(g_hCvarPointsForGiantPlr);

					Score_IncrementBonusPoints(iAttacker, numPoints);

					// Log hlstats event: giant_damage
					char logEvent[32] = "giant_damage";
					if(g_nGameMode == GameMode_Race) logEvent = "giant_damage_race";

					char auth[32];
					GetClientAuthId(iAttacker, AuthId_Steam3, auth, sizeof(auth));
					LogToGame("\"%N<%d><%s><%s>\" triggered \"%s\"", iAttacker, GetClientUserId(iAttacker), auth, g_strTeamClass[GetClientTeam(iAttacker)], logEvent);

					g_iDamageAccul[iAttacker][teamVictim] -= config.LookupInt(g_hCvarPointsDamageGiant);
				}
			}

			// Apply the effects of the giant tag: jarate_on_hit.
			if(Spawner_HasGiantTag(iAttacker, GIANTTAG_JARATE_ON_HIT) && GetEntProp(iAttacker, Prop_Send, "m_bIsMiniBoss") && GetClientTeam(iAttacker) != teamVictim)
			{
				if(IsPlayerAlive(iVictim))
				{
					TF2_AddCondition(iVictim, TFCond_Jarated, config.LookupFloat(g_hCvarJarateOnHitTime), iAttacker);
				}
			}
		}
	}
}

public Action Listener_DropBomb(int client, const char[] command, int argc)
{
	if(!g_bEnabled) return Plugin_Continue;
	
	// Block the command 'dropitem' on the giant
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_CAN_DROP_BOMB))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action Listener_Destroy(int client, const char[] command, int argc)
{
	if(!g_bEnabled) return Plugin_Continue;
	
	// Block the giant engineer from destroying teleporter entrances
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) >= 2 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss")
		&& g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		char strArg1[10];
		char strArg2[10];
		GetCmdArg(1, strArg1, sizeof(strArg1));
		GetCmdArg(2, strArg2, sizeof(strArg2));

		if(StringToInt(strArg1) == view_as<int>(TFObject_Teleporter) && StringToInt(strArg2) == view_as<int>(TFObjectMode_Entrance))
		{
			return Plugin_Handled;
		}

		// Allow the engineer to destroy sapped buildings
		TFObjectType type = view_as<TFObjectType>(StringToInt(strArg1));
		switch(type)
		{
			case TFObject_Sentry:
			{
				int sentry = MaxClients+1;
				while((sentry = FindEntityByClassname(sentry, "obj_sentrygun")) > MaxClients)
				{
					if(GetEntPropEnt(sentry, Prop_Send, "m_hBuilder") == client && GetEntProp(sentry, Prop_Send, "m_bHasSapper"))
					{
						CBaseObject_SpeedUpDestruction(sentry);
					}
				}
			}
			case TFObject_Dispenser:
			{
				int dispenser = MaxClients+1;
				while((dispenser = FindEntityByClassname(dispenser, "obj_dispenser")) > MaxClients)
				{
					if(GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client && GetEntProp(dispenser, Prop_Send, "m_bHasSapper"))
					{
						CBaseObject_SpeedUpDestruction(dispenser);
					}
				}
			}
			case TFObject_Teleporter:
			{
				if(StringToInt(strArg2) == view_as<int>(TFObjectMode_Exit))
				{
					int tele = MaxClients+1;
					while((tele = FindEntityByClassname(tele, "obj_teleporter")) > MaxClients)
					{
						TFObjectMode mode = view_as<TFObjectMode>(GetEntProp(tele, Prop_Send, "m_iObjectMode"));
						if(mode == TFObjectMode_Exit && GetEntPropEnt(tele, Prop_Send, "m_hBuilder") == client && GetEntProp(tele, Prop_Send, "m_bHasSapper"))
						{
							CBaseObject_SpeedUpDestruction(tele);
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

void CBaseObject_SpeedUpDestruction(int building)
{
	// This makes a sapped building destruct on command, giving proper credit to the player with the sapper.
	SetVariantInt(1);
	AcceptEntityInput(building, "SetHealth");

	if(g_iOffset_m_buildingPercentage > 0)
	{
		SetEntDataFloat(building, g_iOffset_m_buildingPercentage, 0.0);
	}	
}

void Tank_AddCheckpointHealth(int team)
{
	g_flTankLastHealed[team] = GetEngineTime();
	
	int iTank = EntRefToEntIndex(g_iRefTank[team]);
	if(iTank > MaxClients)
	{
		int iHealth = GetEntProp(iTank, Prop_Data, "m_iHealth");
		int iMaxHealth = GetEntProp(iTank, Prop_Data, "m_iMaxHealth");
		
		// Apply a health cutoff - if the health of the tank goes over a certain amount, stop healing
		// The regen is meant to help a losing BLU team recover
		if(iHealth < RoundToNearest(float(iMaxHealth) * config.LookupFloat(g_hCvarCheckpointCutoff)))
		{
			// Calculate the amount of health to add each increment of 0.1s, similar to the algorithm above
			int iTanksAndCheckpoints = (4 - g_iMaxControlPoints[team]) + g_iNumTankMaxSimulated;
			if(iTanksAndCheckpoints <= 0) iTanksAndCheckpoints = 1;
			int iCheckpointHP = RoundToNearest(((float(iTanksAndCheckpoints) / 6.0) * float(iMaxHealth) * config.LookupFloat(g_hCvarCheckpointHealth)) / config.LookupFloat(g_hCvarCheckpointTime) * config.LookupFloat(g_hCvarCheckpointInterval));
			
			iHealth += iCheckpointHP;
			if(iHealth > iMaxHealth)
			{
				iHealth = iMaxHealth;
			}
			
			SetEntProp(iTank, Prop_Data, "m_iHealth", iHealth);
		}else{
			// The tank has reached full health so don't bother healing
			g_flTankHealEnd[team] = 0.0;
		}
	}
}

void Watcher_CacheLinks(int team)
{
	int iWatcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
	if(iWatcher <= MaxClients) return;

	for(int i=0; i<MAX_LINKS; i++)
	{
		g_iRefLinkedCPs[team][i] = 0;
		g_iRefLinkedPaths[team][i] = 0;
	}

	int iNumCPs, iNumPaths;

	// Cache the information associated with the team_train_watcher
	for(int i=0; i<MAX_LINKS; i++)
	{
		char strProp[100];

		// Get the linked path_track's
		Format(strProp, sizeof(strProp), "m_iszLinkedPathTracks[%d]", i);

		char strLinkedPath[100];
		GetEntPropString(iWatcher, Prop_Data, strProp, strLinkedPath, sizeof(strLinkedPath));
		if(strLinkedPath[0] != '\0')
		{
			int iLinkedPath = Entity_FindEntityByName(strLinkedPath, "path_track");
			if(iLinkedPath > MaxClients)
			{
				g_iRefLinkedPaths[team][i] = EntIndexToEntRef(iLinkedPath);
				iNumPaths++;
			}
		}

		// Get the linked team_control_point's
		Format(strProp, sizeof(strProp), "m_iszLinkedCPs[%d]", i);

		char strLinkedCP[100];
		GetEntPropString(iWatcher, Prop_Data, strProp, strLinkedCP, sizeof(strLinkedCP));
		if(strLinkedCP[0] != '\0')
		{
			int iLinkedCP = Entity_FindEntityByName(strLinkedCP, "team_control_point");
			if(iLinkedCP > MaxClients)
			{
				g_iRefLinkedCPs[team][i] = EntIndexToEntRef(iLinkedCP);
				iNumCPs++;
			}
		}
	}

	// Cache the last control point found, this should be the final (goal) control point
	for(int i=MAX_LINKS-1; i>=0; i--)
	{
		if(g_iRefLinkedCPs[team][i] != 0)
		{
			g_iRefControlPointGoal[team] = g_iRefLinkedCPs[team][i];
			break;
		}
	}

#if defined DEBUG
	PrintToServer("(Watcher_CacheLinks) [Team %d] Num CPs: %d   Num Paths: %d!", team, iNumCPs, iNumPaths);
#endif
}

int Entity_FindEntityByName(const char[] strTargetName, const char[] strClassname)
{
	// This only searches for entities above MaxClients (non-player/non-world entities)
	char strName[100];
	int iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, strClassname)) != -1)
	{
		GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strTargetName, strName, false) == 0)
		{
			return iEntity;
		}
	}

	return -1;
}

public void Output_On10SecRemaining(const char[] output, int caller, int activator, float delay)
{
	if(!g_bEnabled) return;
	
#if defined DEBUG
	PrintToServer("(Output_On10SecRemaining) caller: %d activator: %d delay: %0.1f!", caller, activator, delay);
#endif

	// Play a mvm wave start sound when setup finishes
	if(Tank_IsInSetup())
	{
		EmitSoundToAll(SOUND_ROUND_START);
	}
}

int abs(int num)
{
	if(num < 0) return num * -1;
	return num;
}

public Action Timer_CheckTeams(Handle timer)
{
	if(!g_bEnabled) return Plugin_Continue;
	
	// The map doesn't reset on multi-stage maps for some reason
	// It works fine on my test server but I'm making this function just in case
	// It should restart the round when all players leave during a round that previously had players
	if(g_bIsInNaturalRound && g_flTimeRoundStarted != 0.0)
	{
		// It can glitch out during setup and round state 3 so checking that we're in round may not always work..
		if(GetEngineTime() - g_flTimeRoundStarted > 15.0)
		{
			if(g_bHasPlayers)
			{
				int iCount;
				for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) >= 2) iCount++;
				if(iCount == 0)
				{
					// We used to have players..now we don't..restart!
					PrintToChatAll("%t", "Tank_Chat_RestartingRound", 0x01);

					LogMessage("Restarting round cause everyone left!");
					ServerCommand("mp_restartgame 1");
					g_flTimeRoundStarted = 0.0;
				}
			}
		}
		
		// Keep track of whether we've seen players or not.
		if(!g_bHasPlayers)
		{
			int iCount;
			for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) >= 2) iCount++;
			g_bHasPlayers = (iCount > 0);
		}
	}
	
	Tank_EnforceRespawnTimes();

	// Faking tournament mode allows the advanced spectate gui, shows class limits in the class selection menu, shows team names on the scoreboard, and allows the players to set the team name at the start of the map.
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i)) SendConVarValue(i, g_hCvarTournament, "1");
	}

	char value[12];
	// Bump up the tf_tournament_classlimit_ cvars to take giant robot players into account.
	for(int team=2; team<=3; team++)
	{
		for(int class=1; class<=9; class++)
		{
			int limit = config.LookupInt(g_hCvarClassLimits[team][class]);

			// For no limit or no players allowed in a given slot, simply replicate the value to the client.
			if(limit <= 0)
			{
				config.LookupString(g_hCvarClassLimits[team][class], value, sizeof(value));

				for(int client=1; client<=MaxClients; client++)
				{
					if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team)
					{
						SendConVarValue(client, g_hCvarTournamentClassLimits[class], value);
					}
				}

				continue;
			}

			int numExempt = 0;
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsClientInGame(client) && GetClientTeam(client) == team && class == (view_as<int>(TF2_GetPlayerClass(client))) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == 1 && !Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER))
				{
					numExempt++;
				}
			}

			IntToString(limit+numExempt, value, sizeof(value));
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team)
				{
					SendConVarValue(client, g_hCvarTournamentClassLimits[class], value);
				}	
			}			
		}
	}
	
	// Scale the amount that Giant Robots can be healed based on the player count on the opposite team in payload.
	if(g_nGameMode != GameMode_Race && config.LookupBool(g_hCvarGiantScaleHealing))
	{
		float healingScale[MAX_TEAMS];
		healingScale[TFTeam_Red] = Giant_GetScaleForHealing(TFTeam_Blue); // Healing scale for Giant Robots on the RED team.
		healingScale[TFTeam_Blue] = Giant_GetScaleForHealing(TFTeam_Red); // Healing scale for Giant Robots on the BLU team.
		for(int client=1; client<=MaxClients; client++)
		{
			if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				int team = GetClientTeam(client);
				if(team == TFTeam_Red || team == TFTeam_Blue)
				{
					float scale = healingScale[team];
					if(scale >= 1.0)
					{
						// Remove the reduced_healing_from_medics attribute from the Giant Robot.
						float attribValue;
						if(Tank_GetAttributeValue(client, ATTRIB_REDUCED_HEALING_FROM_MEDIC, attribValue))
						{
							Tank_RemoveAttribute(client, ATTRIB_REDUCED_HEALING_FROM_MEDIC);
						}
					}else{
						// Set the reduced_healing_from_medics attribute on the Giant Robot.
						Tank_SetAttributeValue(client, ATTRIB_REDUCED_HEALING_FROM_MEDIC, scale);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	//PrintToServer("(OnEntityCreated) %s", classname);

	if(!g_bEnabled) return;

	if(strcmp(classname, "item_currencypack_custom") == 0)
	{
		if(g_nGameMode == GameMode_Race)
		{
			// No point in spawning cash in this gamemode
			AcceptEntityInput(iEntity, "Kill");
		}else{
			// Hook currency touch to award crits to the red team
			SDKHook(iEntity, SDKHook_Touch, CritCash_OnTouch);
			// After the 2015 Halloween update, currency packs will not spawn if there's no nav mesh. This allows Crit Cash to spawn on maps without a nav mesh!
			SetEntProp(iEntity, Prop_Send, "m_bDistributed", true);
		}
	}else if(g_iCreatingCartDispenser > 0 && strcmp(classname, "dispenser_touch_trigger") == 0)
	{
#if defined DEBUG
		PrintToServer("(OnEntityCreated) %s (%d) (team %d) created by dispenser, saving reference!", classname, iEntity, g_iCreatingCartDispenser);
#endif
		g_iRefDispenserTouch[g_iCreatingCartDispenser] = EntIndexToEntRef(iEntity);
	}else if(strncmp(classname, "item_healthkit_", 15) == 0 || strcmp(classname, "func_regenerate") == 0) // func_respawnroom
	{
		// Prevent the giant from activating these entities
		SDKHook(iEntity, SDKHook_Touch, Giant_OnTouch);
	}else if(g_bBlockRagdoll && strcmp(classname, "tf_ragdoll") == 0)
	{
		// Block the ragdoll when the giant deploys a bomb
#if defined DEBUG
		PrintToServer("(OnEntityCreated) Blocking tf_ragdoll..");
#endif
		AcceptEntityInput(iEntity, "Kill");
		g_bBlockRagdoll = false;
	}else if(strcmp(classname, "obj_sentrygun") == 0 || strcmp(classname, "obj_teleporter") == 0)
	{
		// Need to log sentries for Sentry Vision (tm)
		RequestFrame(NextFrame_Building, EntIndexToEntRef(iEntity));
	}else if(strcmp(classname, "obj_dispenser") == 0)
	{
		// Entity isn't prepared to change yet so wait a frame
		RequestFrame(NextFrame_Building, EntIndexToEntRef(iEntity));
	}else if(strcmp(classname, "tf_projectile_stun_ball") == 0)
	{
		// Block stun on giants
		SDKHook(iEntity, SDKHook_Touch, SandmanBall_OnTouch);
	}else if(strcmp(classname, "tf_projectile_arrow") == 0)
	{
		// Fixes for the arrow penetration attribute
		SDKHook(iEntity, SDKHook_Touch, Arrow_OnTouch);
	}else if(strcmp(classname, "tf_projectile_healing_bolt") == 0 || strcmp(classname, "tf_projectile_rocket") == 0 || strcmp(classname, "tf_projectile_syringe") == 0 || strcmp(classname, "tf_projectile_flare") == 0)
	{
		// Fix these projectiles from colliding with revive markers.
		SDKHook(iEntity, SDKHook_Touch, Projectile_OnTouch);
	}else if(g_timeSentryBusterDied > 0.0 && strcmp(classname, "tf_ammo_pack") == 0 && GetEngineTime() - g_timeSentryBusterDied < 0.05)
	{
		// Block the sentry buster from dropping an ammo pack.
#if defined DEBUG
		PrintToServer("(OnEntityCreated) Blocking sentry buster's tf_ammo_pack..: %f", GetEngineTime() - g_timeSentryBusterDied);
#endif
		g_timeSentryBusterDied = 0.0;
		
		AcceptEntityInput(iEntity, "Kill");
	}
}

public void NextFrame_AmmoPack(int ref)
{
	int ammoPack = EntRefToEntIndex(ref);
	if(ammoPack > MaxClients)
	{
		PrintToServer("tf_ammo_pack: m_hOwnerEntity = %d", GetEntPropEnt(ammoPack, Prop_Send, "m_hOwnerEntity"));

		int client = GetEntPropEnt(ammoPack, Prop_Send, "m_hOwnerEntity");
		if(client >= 1 && client <= MaxClients) PrintToServer("%d %d %d", g_nSpawner[client][g_bSpawnerEnabled], g_nSpawner[client][g_nSpawnerType], GetEntProp(client, Prop_Send, "m_bIsMiniBoss"));
	}
}

/* This hook causes giants to be immune to sandman stunning so this is no longer necesary
public Action:SandmanBall_OnTouch(iBall, client)
{
	// Check if the ball hit a giant and add a cooldown for it
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") && g_flTimeGiantStunned[client] != 0.0)
	{
		if(GetEngineTime() - g_flTimeGiantStunned[client] < config.LookupFloat(g_hCvarGiantSandmanCooldown))
		{
			return Plugin_Handled;
		}else{
			g_flTimeGiantStunned[client] = 0.0;
		}
	}

	return Plugin_Continue;
}
*/

public Action SandmanBall_OnTouch(int iBall, int client)
{
	// Check if the ball hit a giant and if so, block touch
	// Without, giants on linux can be stunned, but on windows they cannot
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Projectile_OnTouch(int arrow, int entity)
{
	if(entity > MaxClients)
	{
		char classname[24];
		GetEdictClassname(entity, classname, sizeof(classname));
		if(strncmp(classname, "entity_revive_marker", 20) == 0)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Arrow_OnTouch(int arrow, int entity)
{
	char classname[24];
	GetEdictClassname(entity, classname, sizeof(classname));
	if(entity > MaxClients)
	{
		if(strncmp(classname, "entity_revive_marker", 20) == 0)
		{
			return Plugin_Handled;
		}
	}

	// The "projectile penetration" attribute causes some problems.
	// Get the arrow's owner
	int owner = GetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity");
	if(owner >= 1 && owner <= MaxClients && IsClientInGame(owner) && GetEntProp(owner, Prop_Send, "m_bIsMiniBoss"))
	{
		// The launcher's uber will break arrows
		if(entity >= 1 && entity <= MaxClients)
		{
			//PrintToChatAll("m_hOwnerEntity = %d | team = %d", owner, GetEntProp(iProjectileArrow, Prop_Send, "m_iTeamNum"));
			if(owner >= 1 && owner <= MaxClients)
			{
				if(owner == entity)
				{
					return Plugin_Handled;
				}
			}
		}

		if(entity > MaxClients)
		{
			if(strncmp(classname, "prop_dynamic", 12) == 0) return Plugin_Handled;
			//if(strcmp(classname, "func_door_rotating") == 0) return Plugin_Handled; // Causes crashes
			//if(strncmp(classname, "func_brush", 10) == 0) return Plugin_Handled; // Causes crashes
		}
	}

	return Plugin_Continue;
}

public void NextFrame_Building(int iRef)
{
	int iBuilding = EntRefToEntIndex(iRef);
	if(iBuilding > MaxClients)
	{
		int iBuilder = GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder");
		if(iBuilder >= 1 && iBuilder <= MaxClients && IsClientInGame(iBuilder) && TF2_GetPlayerClass(iBuilder) == TFClass_Engineer)
		{
			int team = GetClientTeam(iBuilder);
			if(team == TFTeam_Red || team == TFTeam_Blue)
			{
				TFObjectType type = view_as<TFObjectType>(GetEntProp(iBuilding, Prop_Send, "m_iObjectType"));

				// Log the creation of sentries for sentry vision (tm)
				if(type == TFObject_Sentry && (team == TFTeam_Red || g_nGameMode == GameMode_Race))
				{
					SentryVision_OnSentryCreated(iBuilding);
				}

				// Take note of dispensers to keep them non-solid for sentry busters.
				if(type == TFObject_Dispenser && (team == TFTeam_Red || g_nGameMode == GameMode_Race))
				{
					g_entitiesOfInterest[iBuilding] = Interest_Dispenser;
				}

				if(GetEntProp(iBuilder, Prop_Send, "m_bIsMiniBoss"))
				{
					// Scale up the giant engineer's buildings
					if(Spawner_HasGiantTag(iBuilder, GIANTTAG_SCALE_BUILDINGS))
					{
						switch(type)
						{
							case TFObject_Sentry:
							{
								Building_SetScale(iBuilding, 2.0);
							}
							case TFObject_Dispenser:
							{
								Building_SetScale(iBuilding, 1.9);
							}
						}
					}

					// Set up the giant engineer's team teleporter
					if(Spawner_HasGiantTag(iBuilder, GIANTTAG_TELEPORTER))
					{
						if(type == TFObject_Teleporter && GetEntProp(iBuilding, Prop_Send, "m_iObjectMode") == view_as<int>(TFObjectMode_Exit))
						{
							g_nGiantTeleporter[team][g_nGiantTeleporterState] = TeleporterState_Unconnected;
							g_nGiantTeleporter[team][g_iGiantTeleporterRefExit] = EntIndexToEntRef(iBuilding);
						}
					}

					// The Destruction PDA will not send the destroy command while the building is sapped.
					// This fakes the netprop to trick the client into sending that command.
					if(g_hasSendProxy)
					{
#if defined _SENDPROXYMANAGER_INC_
						SendProxy_Hook(iBuilding, "m_bHasSapper", Prop_Int, SendProxy_BuildingNotSapped);
#endif
					}
				}
			}
		}
	}
}

#if defined _SENDPROXYMANAGER_INC_
public Action SendProxy_BuildingNotSapped(int entity, char[] propName, int &value, int element)
{
	int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	if(builder >= 1 && builder <= MaxClients && g_nSpawner[builder][g_bSpawnerEnabled] && g_nSpawner[builder][g_nSpawnerType] == Spawn_GiantRobot && IsClientInGame(builder))
	{
		int activeWeapon = GetEntPropEnt(builder, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon > MaxClients && GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex") == ITEM_PDA_DESTROY)
		{
			// Don't spoof m_bHasSapper unless the Destroy PDA is active.
			value = false;
		}
	}
	
	return Plugin_Changed;
}
#endif

void Building_SetScale(int iBuilding, float flScale)
{
	SetEntPropFloat(iBuilding, Prop_Send, "m_flModelScale", flScale);

	// Set the bounds of the building blueprint, without this, the engineer could get stuck in his own building!
	float flMins[3];
	float flMaxs[3];
	GetEntPropVector(iBuilding, Prop_Send, "m_vecBuildMins", flMins);
	GetEntPropVector(iBuilding, Prop_Send, "m_vecBuildMaxs", flMaxs);
	ScaleVector(flMins, flScale);
	ScaleVector(flMaxs, flScale);
	SetEntPropVector(iBuilding, Prop_Send, "m_vecBuildMins", flMins);
	SetEntPropVector(iBuilding, Prop_Send, "m_vecBuildMaxs", flMaxs);
}

/*
public Action:Timer_SandmanCheck(Handle:hTimer, any:iRef)
{
	// Fix the sandman ball being shot too low with giant robots
	new iBall = EntRefToEntIndex(iRef);
	if(iBall > MaxClients)
	{
		new iLauncher = GetEntPropEnt(iBall, Prop_Send, "m_hOwnerEntity");
		PrintToServer("%d", iLauncher);
		if(iLauncher >= 1 && iLauncher <= MaxClients && IsClientInGame(iLauncher) && GetClientTeam(iLauncher) == TFTeam_Blue && IsPlayerAlive(iLauncher) && GetEntProp(iLauncher, Prop_Send, "m_bIsMiniBoss"))
		{
			float flPos[3];
			GetEntPropVector(iBall, Prop_Send, "m_vecOrigin", flPos);
			flPos[2] += 50.0;
			PrintToServer("Doing it!");
			TeleportEntity(iBall, flPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	return Plugin_Handled;
}
*/

public Action Giant_OnTouch(int iHealthKit, int iToucher)
{
	// Block the giant from activating any ammo cabinets or healthkits
	if(iToucher >= 1 && iToucher <= MaxClients && IsClientInGame(iToucher) && IsPlayerAlive(iToucher) && GetEntProp(iToucher, Prop_Send, "m_bIsMiniBoss"))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &hItem)
{
	if(!g_bEnabled) return Plugin_Continue;
	if(!config.LookupBool(g_hCvarRobot)) return Plugin_Continue;

	if(GetClientTeam(client) == TFTeam_Blue || g_nGameMode == GameMode_Race)
	{
		// Some items stretch when bonemerged with the robot models and look horrible
		// It's easy enough to just blacklist them so they can't be worn in certain cases
		if(g_blockedCosmetics.isBlocked(iItemDefinitionIndex))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void TF2_RemoveItemInSlot(int client, int slot)
{
	// Make sure a weapon and its associated extra wearable/viewmodel is removed
	TF2_RemoveWeaponSlot(client, slot); // SourceMod should now take care of removing m_hExtraWearable & m_hExtraWearableViewModel

	// GetPlayerWeaponSlot won't catch wearables so check for wearables in the weapon slot
	int iWearable = SDK_GetEquippedWearable(client, slot);
	if(iWearable > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(TF2_RemoveItemInSlot) Removing wearable in slot %d (index: %d, def: %d)..", slot, iWearable, GetEntProp(iWearable, Prop_Send, "m_iItemDefinitionIndex"));
#endif
		SDK_RemoveWearable(client, iWearable);
		AcceptEntityInput(iWearable, "Kill");
	}	
}

void Bomb_Think(int iBomb)
{
	// The bomb or tank round isn't started yet
	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return;
	
	int team = GetEntProp(iBomb, Prop_Send, "m_iTeamNum");
	if(team != TFTeam_Blue) return;

	int iControlPoint, iPathTrack;
	int iIndexCP = -1;
	bool bIsGoal = false;
	g_bombAtFinalCheckpoint = false;
	// Find the next control point that needs to be capped
	for(int i=0; i<MAX_LINKS; i++)
	{
		if(g_iRefLinkedPaths[team][i] == 0 || g_iRefLinkedCPs[team][i] == 0) continue;

		iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
		iPathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][i]);

		if(iControlPoint <= MaxClients || iPathTrack <= MaxClients) continue;

		bIsGoal = (g_iRefLinkedCPs[team][i] == g_iRefControlPointGoal[team]);
		bool bCaptured = (GetEntProp(iControlPoint, Prop_Send, "m_iTeamNum") == team);

		if(bCaptured) continue; // Don't do anything for control points that were already captured by the tank

		// We're found the path & control point of the next control point that the bomber must cap
		iIndexCP = i;
		break;
	}

	// No eligible control point to cap, this shouldn't happen
	if(iIndexCP == -1 || iControlPoint <= MaxClients || iPathTrack <= MaxClients) return;

	// To account for overtime, check if there is still BLU capture progress on the current control point 
	bool bInCapture = false;
	int iObjective = Obj_Get();
	int iMapperIndex = GetEntProp(iControlPoint, Prop_Data, "m_iPointIndex");
	if(iObjective > MaxClients && iMapperIndex >= 0 && iMapperIndex < MAX_LINKS)
	{
		if(GetEntProp(iObjective, Prop_Send, "m_iCappingTeam", _, iMapperIndex) == team)
		{
			bInCapture = true;
		}
	}

	// Make sure a correct player is carrying the bomb
	int client = GetEntPropEnt(iBomb, Prop_Send, "moveparent");
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != team)
	{
		// No one is carrying the bomb, so check if the round should end
		if(!bInCapture && g_flBombGameEnd != 0.0 && GetEngineTime() > g_flBombGameEnd)
		{
			StopSound(iBomb, SNDCHAN_AUTO, SOUND_RING);
			//BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Bomb_Reset");
			
			Bomb_Cleanup();
			
			GameLogic_DoNext();
		}
		
		g_iBombPlayerPlanting = 0;
		return;
	}
	
	float flPosPlayer[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", flPosPlayer);
	bool bIsGiantCarrying = view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"));

	// Get the distance of the player to the control point
	float flPosPath[3];
	GetEntPropVector(iPathTrack, Prop_Send, "m_vecOrigin", flPosPath);
	float flDistanceToGoal = GetVectorDistance(flPosPlayer, flPosPath);

	//PrintToServer("Distance: %0.2f", flDistanceToGoal);
	// Sound an alert sound ONCE when the robots get near the hatch with the bomb carried
	if(flDistanceToGoal < config.LookupFloat(g_hCvarBombDistanceWarn))
	{
		// Just for the cactus canyon special deploy, cancel out the medigun and quick fix uber effects on the bomb carrier.
		// The uber effect only needs to be zapped if the carrier is a medic.
		if(bIsGoal && g_nMapHack == MapHack_CactusCanyon && g_bIsFinale)
		{
			// Cancel out the uber charge on the bomb carrier.
			if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
			{
				int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if(medigun > MaxClients)
				{
					char classname[24];
					GetEdictClassname(medigun, classname, sizeof(classname));
					if(strcmp(classname, "tf_weapon_medigun") == 0 && GetEntProp(medigun, Prop_Send, "m_bChargeRelease"))
					{
						int def = GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex");
						if(def != ITEM_QUICK_FIX && def != ITEM_VACCINATOR && def != ITEM_KRITZKRIEG)
						{
#if defined DEBUG
							PrintToServer("(Bomb_Think) Removing medigun uber on %N..", client);
#endif
							SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.0001);
							EmitSoundToClient(client, SOUND_FIZZLE);
						}
					}
				}
			}

			// Cancel out the quick fix uber on the bomb carrier.
			if(TF2_IsPlayerInCondition(client, TFCond_MegaHeal))
			{
				for(int i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
					{
						int medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
						if(medigun > MaxClients && GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex") == ITEM_QUICK_FIX && GetEntProp(medigun, Prop_Send, "m_bChargeRelease"))
						{
							if(i == client || GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == client)
							{
#if defined DEBUG
								PrintToServer("(Bomb_Think) Removing quick-fix uber on %N..", i);
#endif
								SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.0001);
								EmitSoundToClient(i, SOUND_FIZZLE);
							}
						}
					}
				}
			}

			if(TF2_IsPlayerInCondition(client, TFCond_Bonked))
			{
#if defined DEBUG
				PrintToServer("(Bomb_Think) Removing condition %d on %N..", TFCond_Bonked, client);
#endif
				TF2_RemoveCondition(client, TFCond_Bonked);
				EmitSoundToClient(client, SOUND_FIZZLE);
			}

			if(TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))
			{
#if defined DEBUG
				PrintToServer("(Bomb_Think) Removing condition %d on %N..", TFCond_UberchargedCanteen, client);
#endif
				TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
				EmitSoundToClient(client, SOUND_FIZZLE);
			}
		}

		if(bIsGoal) g_bombAtFinalCheckpoint = true;

		if(bIsGoal && !g_bBombPlayedNearHatch)
		{
			BroadcastSoundToTeam(TFTeam_Red, "Announcer.MVM_Bomb_Alert_Near_Hatch");

			int random = GetRandomInt(0, sizeof(g_soundBombFinalWarning)-1);
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) != TFTeam_Red)
				{
					g_overrideSound = true; // This sound is blocked in BombDeploy.
					EmitSoundToClient(i, g_soundBombFinalWarning[random]);
				}
			}

			g_bBombPlayedNearHatch = true;
		}else{
			// Play a sound to alert players that the bomb is near the goal
			float flTimeRepeat = 4.0;
			if(!bIsGoal) flTimeRepeat = 2.0;
			if(g_flTankLastSound == 0.0 || GetGameTime() - g_flTankLastSound > flTimeRepeat)
			{
				if(bIsGoal)
				{
					EmitSoundToAll(SOUND_TANK_WARNING);
				}else{
					BroadcastSoundToTeam(TFTeam_Spectator, "mvm.cpoint_alarm");
				}
				
				g_flTankLastSound = GetGameTime();
			}
		}

		if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale && bIsGoal)
		{
			// Only do this once
			if(!g_bBombEnteredGoal)
			{
				CactusCanyon_EnableTrain(true);
				g_bBombEnteredGoal = true;
			}
		}
	}else{
		// The bomb carrier is outside of the warn area

		// Disable the train from coming when the player goes outside the warn area in cactus canyon
		if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale && bIsGoal)
		{
			if(g_bBombEnteredGoal)
			{
				CactusCanyon_EnableTrain(false);
				g_bBombEnteredGoal = false;
			}
		}

		// A player is carrying the bomb outside the warn area so check if we need to end the game
		if(!bInCapture && g_flBombGameEnd != 0.0 && GetEngineTime() > g_flBombGameEnd)
		{
			// BOOM!
			StopSound(iBomb, SNDCHAN_AUTO, SOUND_RING);
			EmitSoundToAll(SOUND_BOMB_EXPLODE);
 			
 			// This will create the explosion effects and kill the player.
			if(bIsGiantCarrying)
			{
				Buster_Explode(client, _, "mvm_hatch_destroy");
			}else{
				Buster_Explode(client, 50.0, "mvm_hatch_destroy");
			} 
			
			g_bBombGone = true;
			Bomb_Cleanup();
						
			GameLogic_DoNext();
			return;
		}

		// Send an annotation to the bomb carrier every 30s or so to let them know where to take the bomb
		if(g_flBombLastMessage == 0.0 || GetEngineTime() - g_flBombLastMessage > 20.0)
		{
			g_flBombLastMessage = GetEngineTime();

			// Send the player an annotation guiding them to the next control point
			Giant_ShowGuidingAnnotation(client, team, iIndexCP);
		}

		// Warn the bomb carrier if they skip a control point.
		if(g_timeControlPointSkipped == 0.0 && g_flBombLastMessage != 0.0 && GetEngineTime() - g_flBombLastMessage > 5.0)
		{
			float playerPos[3];
			GetClientAbsOrigin(client, playerPos);

			for(int i=iIndexCP+1; i<MAX_LINKS; i++)
			{
				if(g_iRefLinkedPaths[team][i] == 0 || g_iRefLinkedCPs[team][i] == 0) continue;

				int nextPath = EntRefToEntIndex(g_iRefLinkedPaths[team][i]);
				int nextCP = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
				if(nextPath <= MaxClients || nextCP <= MaxClients) continue;
				if(GetEntProp(nextCP, Prop_Send, "m_iTeamNum") == team) continue; // Carrier already owns this point.

				float nextPos[3];
				GetEntPropVector(nextPath, Prop_Send, "m_vecOrigin", nextPos);
				if(GetVectorDistance(playerPos, nextPos) < config.LookupFloat(g_hCvarBombSkipDistance))
				{
					g_timeControlPointSkipped = GetEngineTime();
					g_flBombLastMessage = GetEngineTime();

					Bomb_ShowSkippedAnnotation(client, team, iIndexCP);

					break;
				}				
			}
		}
	}
	
	// Handle the trigger_capture_area logic for all the control points EXCEPT for the final one in which the robot will have to deploy in
	if(!bIsGoal)
	{
		// Get/create the trigger_capture_area for the current control point
		int iTriggerArea = CaptureTriggers_Get(team, iIndexCP);
		if(iTriggerArea > MaxClients)
		{
			// Get the trigger_capture_area associated with the cart and make sure it is not linked to the current control point. When this happens, the HUD has problems.
			int iTriggerCart = EntRefToEntIndex(g_iRefTrigger[team]);
			if(iTriggerCart > MaxClients)
			{
				int iOffset = FindDataMapInfo(iTriggerCart, "m_iszCapPointName");
				if(iOffset != -1)
				{
					int iLinkedCP = GetEntDataEnt2(iTriggerCart, iOffset-8);
					if(iLinkedCP > MaxClients)
					{
#if defined DEBUG
						char strName[32];
						GetEntPropString(iLinkedCP, Prop_Data, "m_iName", strName, sizeof(strName));
						PrintToServer("(Bomb_Think) Unlinking cart's trigger from control point %d: \"%s\"!", iLinkedCP, strName);
#endif
						// Unlink the cart's trigger area control point
						SetVariantString(TARGETNAME_NULL);
						AcceptEntityInput(iTriggerCart, "SetControlPoint");

						// Re-link our own custom trigger area to the control point to fix the HUD
						SetVariantEntity(iControlPoint);
						AcceptEntityInput(iTriggerArea, "SetControlPoint", iControlPoint, iControlPoint);
					}
				}
			}

			// Make sure the respawn times are properly set in the HUD
			if(iObjective > MaxClients)
			{
				int iReqCappers = GetEntProp(iObjective, Prop_Send, "m_iTeamReqCappers", _, iMapperIndex + 8 * team);
				float flCaptureTime = config.LookupFloat(g_hCvarBombCaptureRate) * float(iReqCappers * 2);
				if(!Float_AlmostEqual(flCaptureTime, GetEntPropFloat(iObjective, Prop_Send, "m_flTeamCapTime", iMapperIndex + 8 * team)))
				{
#if defined DEBUG
					PrintToServer("(Bomb_Think) m_flTeamCapTime set to %0.2f, expected %0.2f!", GetEntPropFloat(iObjective, Prop_Send, "m_flTeamCapTime", iMapperIndex + 8 * team), flCaptureTime);
#endif
					// You need to do this in order for client's HUDs to predict the capture rate
					// Mappers have a little control given by the property "Number of RED/BLUE players to cap" on trigger_capture_area
					SetEntPropFloat(iObjective, Prop_Send, "m_flTeamCapTime", flCaptureTime, iMapperIndex + 8 * team);

					// Tells the client to update the HUD
					int iHudParity = GetEntProp(iObjective, Prop_Send, "m_iUpdateCapHudParity");
					iHudParity = (iHudParity + 1) & CAPHUD_PARITY_MASK;
					SetEntProp(iObjective, Prop_Send, "m_iUpdateCapHudParity", iHudParity);
				}
			}
		}
	}

	// Make sure the func_capturezone is created for each control point.
	CaptureZones_Get(team, iIndexCP);

	float minPlantDistance = config.LookupFloat(g_hCvarMinPlantDistance);

	// Are we close enough the goal that we can plant?
	if(flDistanceToGoal < minPlantDistance && !(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale && bIsGoal))
	{
		// When a player stops transmitting UserCmds they become stuck and cannot be moved by other players.
		// This means that a player can deploy, pull their network cord, and get an easy win.
		// If the player stops transmitting updates during deploy, cancel it.
		bool lostConnection = false;
		if(!IsFakeClient(client) && g_lastClientTick[client] != 0.0 && GetEngineTime() - g_lastClientTick[client] > 0.5)
		{
			lostConnection = true;
		}

		// Check to see if there were any previous planters
		int iPlanter = GetClientOfUserId(g_iBombPlayerPlanting);
		if(iPlanter == client)
		{
			// Player is capping the final control point so the logic will be different
			if(bIsGoal)
			{
				// The same player is still planting so make sure they are still on track to delivering the bomb
				// Make sure they are still on the ground
				if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1 && !lostConnection && Bomb_CanPlayerDeploy(client))
				{
					// Check if enough time has passed, then the robots have won! ~ 1.90s
					if(GetEngineTime() - g_flBombPlantStart > config.LookupFloat(g_hCvarBombTimeDeploy))
					{
#if defined DEBUG
						PrintToServer("(Bomb_Think) %N has planted the bomb, BOOM!", client);
#endif					
						// Set the robots as the winner
						// To do this, we need to move the cart to the penultimate pathtrack and set the speed to really really fast
						// Will this work? Let's find out..
						int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
						if(iTrackTrain > MaxClients)
						{
							// Capture all the control points in normal progression so we can trigger a win.
							// This code is probably not needed anymore, all preceding points should be capped before the final point is capped.
							int controlPointGoal = EntRefToEntIndex(g_iRefControlPointGoal[team]);
							for(int i=0; i<MAX_LINKS; i++)
							{
								if(g_iRefLinkedCPs[team][i] == 0) continue;

								int cp = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
								if(cp <= MaxClients) continue;
								if(cp == controlPointGoal) continue; // Let the cart capture the final control point.

								if(GetEntProp(cp, Prop_Send, "m_iTeamNum") != team)
								{
									// This control point has not been captured yet.
#if defined DEBUG
									PrintToServer("(Bomb_Think) Capping payload team_control_point #%d: %d..", i, cp);
#endif
									SetVariantInt(team);
									AcceptEntityInput(cp, "SetOwner", -1, cp);
								}
							}

							// Make sure all the control points indicated by the active team_control_point_round has been captured.
							// There may be control points that are required to be captured that are not a part of the payload hud.
							if(g_iRefRoundControlPoint != 0)
							{
								int roundControlPoint = EntRefToEntIndex(g_iRefRoundControlPoint);
								if(roundControlPoint > MaxClients)
								{
									char cpNames[MAX_LINKS*64];
									GetEntPropString(roundControlPoint, Prop_Data, "m_iszCPNames", cpNames, sizeof(cpNames));
									if(strlen(cpNames) > 0)
									{
										char cpName[MAX_LINKS][64];
										int numCps = ExplodeString(cpNames, " ", cpName, sizeof(cpName), sizeof(cpName[]));
										for(int i=0; i<numCps; i++)
										{
											if(strlen(cpName[i]) > 0)
											{
												int cp = Entity_FindEntityByName(cpName[i], "team_control_point");
												if(cp <= MaxClients) continue;
												if(cp == controlPointGoal) continue; // Let the cart capture the final control point.

												if(GetEntProp(cp, Prop_Send, "m_iTeamNum") != team)
												{
													// This control point has not been captured yet.
#if defined DEBUG
													PrintToServer("(Bomb_Think) Capping round team_control_point #%d \"%s\": %d..", i, cpName[i], cp);
#endif
													SetVariantInt(team);
													AcceptEntityInput(cp, "SetOwner", -1, cp);
												}
											}
										}
									}
								}
							}
							
							bool teleportedCart = false;
							char targetname[64];
							config.LookupString(g_hCvarTeleportGoal, targetname, sizeof(targetname));
							if(strlen(targetname) > 0)
							{
								int path = Entity_FindEntityByName(targetname, "path_track");
								if(path > MaxClients)
								{
									AcceptEntityInput(path, "EnablePath");
#if defined DEBUG
									PrintToServer("(Bomb_Think) Teleporting the cart to tank_teleport_goal: \"%s\"!", targetname);
#endif
									SetVariantEntity(path);
									AcceptEntityInput(iTrackTrain, "TeleportToPathTrack");

									// Enable all path_tracks between here and the goal.
									int pathGoal = EntRefToEntIndex(g_iRefPathGoal[team]);
									if(pathGoal > MaxClients)
									{
										AcceptEntityInput(pathGoal, "EnablePath");

										int pathNext = path;
										while((pathNext = GetEntDataEnt2(pathNext, Offset_GetNextOffset(pathNext))) > MaxClients && pathNext != pathGoal)
										{
											AcceptEntityInput(pathNext, "EnablePath");
										}
									}

									teleportedCart = true;
								}else{
									LogMessage("Failed to find tank_teleport_goal \"%s\" set in config file.", targetname);
								}
							}

							if(!teleportedCart)
							{
								int pathGoal = EntRefToEntIndex(g_iRefPathGoal[team]);
								if(pathGoal > MaxClients)
								{
									AcceptEntityInput(pathGoal, "EnablePath");

									int pathPrevious = GetEntDataEnt2(pathGoal, Offset_GetPreviousOffset(pathGoal));
									if(pathPrevious > MaxClients)
									{
										AcceptEntityInput(pathPrevious, "EnablePath");
#if defined DEBUG
										GetEntPropString(pathPrevious, Prop_Data, "m_iName", targetname, sizeof(targetname));
										PrintToServer("(Bomb_Think) Teleporting the cart to previous path: \"%s\"!", targetname);
#endif
										SetVariantEntity(pathPrevious);
										AcceptEntityInput(iTrackTrain, "TeleportToPathTrack");
									}
								}
							}
							
							for(int i=0,size=g_trainProps.Length; i<size; i++)
							{
								int array[ARRAY_TRAINPROP_SIZE];
								g_trainProps.GetArray(i, array, sizeof(array));

								int prop = EntRefToEntIndex(array[TrainPropArray_Reference]);
								if(prop > MaxClients)
								{
#if defined DEBUG
									PrintToServer("(Bomb_Think) Restoring m_nSolidType %d on %d!", array[TrainPropArray_SolidType], prop);
#endif
									SetEntProp(prop, Prop_Send, "m_nSolidType", array[TrainPropArray_SolidType]);
								}
							}
							
							// Cart the start moving on its own.
							Train_Move(team, 1.0);
							SetEntPropFloat(iTrackTrain, Prop_Data, "m_maxSpeed", config.LookupFloat(g_hCvarBombWinSpeed));
							SetVariantFloat(1.0);
							AcceptEntityInput(iTrackTrain, "StartForward");
						}
						
						// Kill the bomb carrier and trigger the log events
						Bomb_Terminate(iBomb, client);

						// By now the train should activate a win for the blue team and the map should progress like normal
						return;
					}
				}else{
					// Reset the planter
					g_iBombPlayerPlanting = 0;
					g_flBombPlantStart = 0.0;
					
					// Reset the animation on the planter
					SDK_PlaySpecificSequence(client, "Stand_SECONDARY");
					TF2_RemoveCondition(client, TFCond_Taunting);

					if(lostConnection)
					{
						PrintToChatAll("%t", "Tank_Chat_Deploy_LostConnection", g_strTeamColors[GetClientTeam(client)], client, 0x01);

						char auth[32];
						GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
						LogMessage("%N<%s> lost connection while deploying the bomb.", client, auth);
					}
				}
			}
		}else{
			// A new player is planting at the final control point.
			if(bIsGoal)
			{
				// A new player is planting, check to see if they are on the ground.
				if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1 && !lostConnection && Bomb_CanPlayerDeploy(client))
				{
#if defined DEBUG
					PrintToServer("(Bomb_Think) %N is planting the bomb!..", client);
#endif
					// If the giant is charging, we need to stop it so we can force them to taunt
					if(TF2_IsPlayerInCondition(client, TFCond_Charging)) TF2_RemoveCondition(client, TFCond_Charging);
					// Cancel out any other taunts.
					if(TF2_IsPlayerInCondition(client, TFCond_Taunting)) TF2_RemoveCondition(client, TFCond_Taunting);

					// Trigger the deploy sequence on the robot
					SDK_Taunt(client, 1, 92);
					SDK_PlaySpecificSequence(client, "primary_deploybomb");

					//TF2_StunPlayer(client, config.LookupFloat(g_hCvarBombTimeDeploy)+0.5, 1.0, TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_THIRDPERSON);
					
					BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Bomb_Alert_Deploying");

					if(bIsGiantCarrying)
					{
						EmitSoundToAll(SOUND_DEPLOY_GIANT);
					}else{
						EmitSoundToAll(SOUND_DEPLOY_SMALL);
					}
					
					g_iBombPlayerPlanting = GetClientUserId(client);
					g_flBombPlantStart = GetEngineTime();

					PrintCenterText(client, " "); // Clear out the "You cannot deploy while INVULNERABLE!" message.

					if(Spawner_HasGiantTag(client, GIANTTAG_MEDIC_AOE) && bIsGiantCarrying)
					{
						// Deplete ubercharge in order to not allow medic AOE effects while the giant is deploying.
						int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						if(medigun > MaxClients)
						{
							char classname[24];
							GetEdictClassname(medigun, classname, sizeof(classname));
							if(strcmp(classname, "tf_weapon_medigun") == 0)
							{
								if(GetEntProp(medigun, Prop_Send, "m_bChargeRelease"))
								{
									SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.0001);
									EmitSoundToClient(client, SOUND_FIZZLE);
								}
							}
						}
					}
				}else{
					// Reset the planter
					g_iBombPlayerPlanting = 0;
					g_flBombPlantStart = 0.0;

					if(!Bomb_CanPlayerDeploy(client) && (g_timeBombWarning[client] == 0.0 || GetEngineTime() - g_timeBombWarning[client] > 0.3))
					{
						g_timeBombWarning[client] = GetEngineTime();

						PrintCenterText(client, "%t", "Tank_Center_CantDeploy");
						//SendHudNotification(client, message, "eotl_duck", GetClientTeam(client));
					}
				}
			}
		}
	}else{
		// Reset the player animation if the planter goes outside of bounds after planting so they don't end up invisible.
		if(bIsGoal && g_iBombPlayerPlanting != 0)
		{
			int iPlanter = GetClientOfUserId(g_iBombPlayerPlanting);
			if(iPlanter == client)
			{
				SDK_PlaySpecificSequence(client, "Stand_SECONDARY");
				TF2_RemoveCondition(client, TFCond_Taunting);
			}
		}

		// We are not close enough so clear any bomb planters, if there is any..
		g_iBombPlayerPlanting = 0;
		g_flBombPlantStart = 0.0;
	}
}

void Bomb_Terminate(int iBomb, int client)
{
	g_finalBombDeployer = GetClientUserId(client);
	StopSound(iBomb, SNDCHAN_AUTO, SOUND_RING);

	// Log the deployment so hlstats can pick it up
	char strAuth[32];
	GetClientAuthId(client, AuthId_Steam3, strAuth, sizeof(strAuth));

	LogToGame("\"%N<%d><%s><%s>\" triggered \"bomb_deploy\"", client, GetClientUserId(client), strAuth, g_strTeamClass[GetClientTeam(client)]);			

	// Throw the deployer some scoreboard points.
	int points = config.LookupInt(g_hCvarPointsForDeploy);
	if(points > 0)
	{
		Score_IncrementBonusPoints(client, points);
	}

	int iHealth = GetClientHealth(client);
	int iMaxHealth = SDK_GetMaxHealth(client);
	PrintToChatAll("%t", "Tank_Chat_BombDeploy", g_strTeamColors[GetClientTeam(client)], client, 0x01, "\x07CF7336", GetClientHealth(client), 0x01, RoundToNearest(float(iHealth)/float(iMaxHealth)*100.0)); 

	// All the HUMANS should make these remarks when the bomb is deployed
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i) && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) && !TF2_IsPlayerInCondition(i, TFCond_Disguised))
		{
			switch(TF2_GetPlayerClass(i))
			{
				case TFClass_Scout: EmitSoundToAll(g_strSoundBombDeployedScout[GetRandomInt(0, sizeof(g_strSoundBombDeployedScout)-1)], i, SNDCHAN_VOICE);
				case TFClass_Sniper: EmitSoundToAll(g_strSoundBombDeployedSniper[GetRandomInt(0, sizeof(g_strSoundBombDeployedSniper)-1)], i, SNDCHAN_VOICE);
				case TFClass_Soldier: EmitSoundToAll(g_strSoundBombDeployedSoldier[GetRandomInt(0, sizeof(g_strSoundBombDeployedSoldier)-1)], i, SNDCHAN_VOICE);
				case TFClass_DemoMan: EmitSoundToAll(g_strSoundBombDeployedDemoman[GetRandomInt(0, sizeof(g_strSoundBombDeployedDemoman)-1)], i, SNDCHAN_VOICE);
				case TFClass_Medic: EmitSoundToAll(g_strSoundBombDeployedMedic[GetRandomInt(0, sizeof(g_strSoundBombDeployedMedic)-1)], i, SNDCHAN_VOICE);
				case TFClass_Heavy: EmitSoundToAll(g_strSoundBombDeployedHeavy[GetRandomInt(0, sizeof(g_strSoundBombDeployedHeavy)-1)], i, SNDCHAN_VOICE);
				case TFClass_Pyro: EmitSoundToAll(g_strSoundBombDeployedPyro[GetRandomInt(0, sizeof(g_strSoundBombDeployedPyro)-1)], i, SNDCHAN_VOICE);
				case TFClass_Spy: EmitSoundToAll(g_strSoundBombDeployedSpy[GetRandomInt(0, sizeof(g_strSoundBombDeployedSpy)-1)], i, SNDCHAN_VOICE);
				case TFClass_Engineer: EmitSoundToAll(g_strSoundBombDeployedEngineer[GetRandomInt(0, sizeof(g_strSoundBombDeployedEngineer)-1)], i, SNDCHAN_VOICE);
			}
		}
	}

	// This should kill all the bomb-round entities
	g_bBombGone = true;
	Bomb_Cleanup();
	
	g_bBlockRagdoll = true; // Set a flag to remove this player's ragdoll (since tf_playergib is probably 0)

	if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
#if defined DEBUG
		PrintToServer("(Bomb_Terminate) Clearing giant: %N!", client);
#endif
		Giant_Clear(client, GiantCleared_Deploy);
	}

	// Trigger a suicide log event so that kill streak points will be awarded for hlstats.
	float pos[3];
	GetClientAbsOrigin(client, pos);
	LogToGame("\"%N<%d><%s><%s>\" committed suicide with \"world\" (attacker_position \"%d %d %d\")", client, GetClientUserId(client), strAuth, g_strTeamClass[GetClientTeam(client)], RoundToNearest(pos[0]), RoundToNearest(pos[1]), RoundToNearest(pos[2]));		

	// Prevent the player from losing hlstats points from being finished off after a bomb deploy.
	g_blockLogAction = true;
	FakeClientCommand(client, "explode");
	ForcePlayerSuicide(client);

	// Add a failsafe that catches if the round has not ended after the bomb has been deployed.
	Timer_KillFailsafe();
	g_timerFailsafe = CreateTimer(15.0, Timer_FailsafeBombDeploy, _, TIMER_REPEAT);
}

public void Bomb_OnReturned(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(Bomb_OnReturned) caller: %d activator: %d delay: %0.2f", caller, activator, delay);
#endif
	if(!g_bEnabled) return;

	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return;

	// Instead of ending the round, just move the bomb back to the last capped control point
	// We will end this round when the game timer runs out

	BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Bomb_Reset");

	Bomb_MoveBack(caller);

	if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale)
	{
		CactusCanyon_EnableTrain(false);
		g_bBombEnteredGoal = true;
	}
}

void Bomb_MoveBack(int bomb)
{
	int team = GetEntProp(bomb, Prop_Send, "m_iTeamNum");

	AcceptEntityInput(bomb, "ForceReset");

	BroadcastSoundToTeam(TFTeam_Spectator, "MVM.Warning");

	float pos[3];
	float ang[3];
	Spawner_LookupSpawnPosition(team, Spawn_GiantRobot, pos, ang, true);
	pos[2] -= 20.0;

	TeleportEntity(bomb, pos, ang, NULL_VECTOR);

	// Show a message to the robots where the bomb has been sent back
	Handle event = CreateEvent("show_annotation");
	if(event != INVALID_HANDLE)
	{
		SetEventInt(event, "id", Annotation_BombMovedBack);
		SetEventFloat(event, "worldPosX", pos[0]);
		SetEventFloat(event, "worldPosY", pos[1]);
		SetEventFloat(event, "worldPosZ", pos[2]);
		SetEventFloat(event, "lifetime", 5.0);
		SetEventString(event, "play_sound", "misc/null.wav");
		
		char text[256];
		Format(text, sizeof(text), "%T", "Tank_Annotation_Bomb_MovedBack", LANG_SERVER);
		SetEventString(event, "text", text);
		
		int iBitString;
		for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team) iBitString |= (1 << i);

		SetEventInt(event, "visibilityBitfield", iBitString); // Only the robots should see this message.
		
		FireEvent(event); // Clears the handle.
	}
}

public void Bomb_3SecRemain(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(Bomb_3SecRemain) caller: %d activator: %d delay: %0.2f", caller, activator, delay);
#endif
	if(!g_bEnabled) return;

	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return;
	
	g_flBombGameEnd = GetEngineTime() + 3.0;
	
	int iBomb = EntRefToEntIndex(g_iRefBombFlag);
	if(iBomb > MaxClients)
	{
		if(GetEntPropEnt(iBomb, Prop_Send, "moveparent") > 0)
		{
			EmitSoundToAll(SOUND_RING, iBomb);
		}
	}
}

void Bomb_ClearMoveBonus()
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetEntProp(i, Prop_Send, "m_bIsMiniBoss") == 0)
		{
			float flSpeedBonus;
			if(Tank_GetAttributeValue(i, ATTRIB_MOVE_SPEED_BONUS, flSpeedBonus))
			{
#if defined DEBUG
				PrintToServer("(Bomb_ClearMoveBonus) Clearing move speed bonus on %N!", i);
#endif
				Tank_RemoveAttribute(i, ATTRIB_MOVE_SPEED_BONUS);
				if(IsPlayerAlive(i)) TF2_AddCondition(i, TFCond_SpeedBuffAlly, 0.001);
			}

			float value;
			if(Tank_GetAttributeValue(i, ATTRIB_SELF_DMG_PUSH_FORCE_DECREASE, value))
			{
				Tank_RemoveAttribute(i, ATTRIB_SELF_DMG_PUSH_FORCE_DECREASE);
				// Because we are applying this attribute on the player entity, we need to refresh the attributes on any weapons that might be hooking this attribute.
				for(int slot=0; slot<3; slot++)
				{
					int weapon = GetPlayerWeaponSlot(i, slot);
					if(weapon > MaxClients) Tank_ClearCache(weapon);
				}
			}

			// Remove the MvM defense buff on the player
			TF2_RemoveCondition(i, TFCond_DefenseBuffNoCritBlock);
		}
	}
}

public void Event_FlagEvent(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	if(g_nGameMode != GameMode_BombDeploy || !g_bIsRoundStarted) return; // Don't run unless we are in bomb deployment mode
	if(GetEventInt(hEvent, "eventtype") != view_as<int>(FlagEvent_Dropped)) return; // Don't run unless the flag was dropped

	// Check if a robot dropped the bomb, if so then remove the minicrits and the healing effect
	int client = GetEventInt(hEvent, "player");
	if(client >= 1 && client <= MaxClients && IsClientInGame(client)) // Don't worry about team, they could have switched teams by now..
	{
#if defined DEBUG
		PrintToServer("(Event_FlagEvent) %N has dropped the bomb!", client);
#endif
		TF2_RemoveCondition(client, TFCond_HalloweenQuickHeal);
		TF2_RemoveCondition(client, TFCond_Buffed);

		g_flTimeBombDropped[client] = GetEngineTime(); // Record when the robot dropped the bomb so we can add a cooldown for the healing effect

		// Call EndTouch on the current trigger_capture_area
		int iIndexCP = -1;
		int iCaptureTrigger;
		// Find the next control point that needs to be capped
		for(int i=0; i<MAX_LINKS; i++)
		{
			if(g_iRefLinkedPaths[TFTeam_Blue][i] == 0 || g_iRefLinkedCPs[TFTeam_Blue][i] == 0) continue;

			int iCP = EntRefToEntIndex(g_iRefLinkedCPs[TFTeam_Blue][i]);
			int iTrigger = EntRefToEntIndex(g_iRefCaptureTriggers[TFTeam_Blue][i]);

			if(iCP <= MaxClients || iTrigger <= MaxClients) continue;
			if(g_iRefLinkedCPs[TFTeam_Blue][i] == g_iRefControlPointGoal[TFTeam_Blue]) continue;
			bool bCaptured = (GetEntProp(iCP, Prop_Send, "m_nSkin") != 0);

			if(bCaptured) continue; // Don't do anything for control points that were already captured by the tank

			// We're found the control point and custom trigger_capture_area for the next control point
			iCaptureTrigger = iTrigger;
			iIndexCP = i;
			break;
		}

		if(iIndexCP != -1)
		{
			SDK_EndTouch(iCaptureTrigger, client);
		}
	}
}

public void Bomb_OnDropped(const char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(Bomb_OnDropped) caller: %d activator: %d delay: %0.2f time: %f", caller, activator, delay, GetEngineTime());
#endif
	if(!g_bEnabled) return;
	Bomb_ClearMoveBonus();
	
	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return;
	if(g_bBombGone)
	{
		g_blockLogAction = true;
		return; // Don't detect the drop when the bomb is removed
	}

	float bombPos[3];
	GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", bombPos);

	float bombPos2[3]; // A little bit higher
	for(int i=0; i<3; i++) bombPos2[i] = bombPos[i];
	bombPos2[2] += 100.0; // Because the bomb drops to the ground, try a position slightly above

	bool bNeedsReset = false;
	
#if defined DEBUG
	PrintToServer("(Bomb_OnDropped) g_flTimeBombFell = %f, pos = (%1.2f %1.2f %1.2f)", GetEngineTime() - g_flTimeBombFell, bombPos[0], bombPos[1], bombPos[2]);
#endif
	if(g_flTimeBombFell != 0.0 && GetEngineTime() > g_flTimeBombFell && GetEngineTime() - g_flTimeBombFell < 0.1)
	{
		// The player died from a trigger_hurt while carrying the bomb, we're probably going to need a reset
#if defined DEBUG
		PrintToServer("(Bomb_OnDropped) Bomb carrier died from trigger_hurt, resetting bomb %d!..", caller);
#endif
		bNeedsReset = true;
	}else{
		// The bomb has been dropped, so do a quick check and see if it landed in a death pit
		int iTriggerHurt = MaxClients+1;
		while((iTriggerHurt = FindEntityByClassname(iTriggerHurt, "trigger_hurt")) > MaxClients)
		{
			if(GetEntProp(iTriggerHurt, Prop_Data, "m_bDisabled")) continue;
			if(GetEntPropFloat(iTriggerHurt, Prop_Data, "m_flDamage") < 300.0) continue; // Try to filter out non-lethal trigger_hurt entities

			// Sometimes the payload cart's trigger_hurt can trip this
			int iParent = GetEntPropEnt(iTriggerHurt, Prop_Send, "moveparent");
			if(iParent > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Bomb_OnDropped) Dropped in parented trigger_hurt, ignoring..");
#endif
				continue;
			}

			if(SDK_PointIsWithin(iTriggerHurt, bombPos) || SDK_PointIsWithin(iTriggerHurt, bombPos2))
			{
#if defined DEBUG
				PrintToServer("(Bomb_OnDropped) Dropped in trigger_hurt %d (%0.2f dmg), resetting bomb %d!..", iTriggerHurt, GetEntPropFloat(iTriggerHurt, Prop_Data, "m_flDamage"), caller);
#endif
				bNeedsReset = true;
				break;
			}
		}
	}

	if(!bNeedsReset && g_nMapHack == MapHack_Frontier && bombPos[2] < -400.00)
	{
#if defined DEBUG
		PrintToServer("(Bomb_OnDropped) Detected the bomb in the satelite dish, resetting bomb %d!", caller);
#endif
		bNeedsReset = true;
	}

	if(bNeedsReset)
	{
		// Spawn an explosion with a particle / sound
		int iParticle = CreateEntityByName("info_particle_system");
		if(iParticle > MaxClients)
		{
			TeleportEntity(iParticle, bombPos, NULL_VECTOR, NULL_VECTOR);
			
			DispatchKeyValue(iParticle, "effect_name", "cinefx_goldrush");
			
			DispatchSpawn(iParticle);
			ActivateEntity(iParticle);
			AcceptEntityInput(iParticle, "Start");
			
			CreateTimer(4.0, Timer_EntityCleanup, EntIndexToEntRef(iParticle));
		}
		EmitSoundToAll(SOUND_EXPLOSION);

		BroadcastSoundToTeam(TFTeam_Spectator, "Announcer.MVM_Bomb_Reset");
		BroadcastSoundToTeam(TFTeam_Blue, "MVM.BombResetExplode");

		// Bomb is in a trigger hurt so move the bomb back after a brief time period
		Timer_KillBombReturn();
		g_hTimerBombReturn = CreateTimer(config.LookupFloat(g_hCvarBombTimePenalty), Timer_BombReturn, _, TIMER_REPEAT);

		float pos[3];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
		pos[2] = -10000.0;
		TeleportEntity(caller, pos, NULL_VECTOR, NULL_VECTOR);

		return;
	}

	if(g_bBombSentDropNotice) return; // Only send this notification once!
	if(g_flBombGameEnd != 0.0) return; // Don't show this message close to the game ending
	
	// Don't show the notification if the giant is still alive because the robots aren't able to pick up the bomb at this time
	if(g_nTeamGiant[TFTeam_Blue][g_bTeamGiantActive])
	{
		bool dontSend = true;
		int iGiant = GetClientOfUserId(g_nTeamGiant[TFTeam_Blue][g_iTeamGiantQueuedUserId]);
		if(iGiant >= 1 && iGiant <= MaxClients && IsClientInGame(iGiant) && GetClientTeam(iGiant) == TFTeam_Blue && IsPlayerAlive(iGiant) && GetEntProp(iGiant, Prop_Send, "m_bIsMiniBoss"))
		{
			if(g_nSpawner[iGiant][g_bSpawnerEnabled] && g_nSpawner[iGiant][g_nSpawnerType] == Spawn_GiantRobot)
			{
				if(g_nGiants[g_nSpawner[iGiant][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_CAN_DROP_BOMB)
				{
					dontSend = false;
				}else{
					// Assume the giant has dropped the bomb, send a notification telling him he better pick the bomb back up
					Handle hEvent = CreateEvent("show_annotation");
					if(hEvent != INVALID_HANDLE)
					{
						SetEventInt(hEvent, "id", Annotation_BombPickupGiant);
						SetEventFloat(hEvent, "worldPosX", bombPos[0]);
						SetEventFloat(hEvent, "worldPosY", bombPos[1]);
						SetEventFloat(hEvent, "worldPosZ", bombPos[2]);
						SetEventFloat(hEvent, "lifetime", 5.0);
						SetEventString(hEvent, "play_sound", "misc/null.wav");
						
						char text[256];
						Format(text, sizeof(text), "%T", "Tank_Annotation_Bomb_PickupHint_Giant", iGiant);
						SetEventString(hEvent, "text", text);
						
						SetEventInt(hEvent, "visibilityBitfield", (1 << iGiant)); // Only the giant should see this message
						
						FireEvent(hEvent); // Clears the handle		
					}
				}
			}
		}

		if(dontSend) return;
	}
	
	// Show an annotation to the robots, letting them know once that the giant has died and they must carry the bomb to the end
	int iBits = 0;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Blue && !Spawner_HasGiantTag(i, GIANTTAG_CAN_DROP_BOMB))
		{
			iBits |= (1 << i);
		}
	}
	if(iBits != 0)
	{
		Handle hEvent = CreateEvent("show_annotation");
		if(!g_bBombGone && hEvent != INVALID_HANDLE)
		{
			SetEventInt(hEvent, "id", Annotation_BombPickupRobots);
			SetEventFloat(hEvent, "worldPosX", bombPos[0]);
			SetEventFloat(hEvent, "worldPosY", bombPos[1]);
			SetEventFloat(hEvent, "worldPosZ", bombPos[2]);
			SetEventFloat(hEvent, "lifetime", 5.0);
			SetEventString(hEvent, "play_sound", "misc/null.wav");
			SetEventInt(hEvent, "visibilityBitfield", iBits); // Only the robots should see this message, minus the giant
			
			char text[256];
			Format(text, sizeof(text), "%T", "Tank_Annotation_Bomb_PickupHint", LANG_SERVER);
			SetEventString(hEvent, "text", text);
			
			FireEvent(hEvent); // Clears the handle
		}
		
		g_bBombSentDropNotice = true;
	}
}

void Timer_KillBombReturn()
{
	if(g_hTimerBombReturn != INVALID_HANDLE)
	{
		KillTimer(g_hTimerBombReturn);
		g_hTimerBombReturn = INVALID_HANDLE;
	}
}

public Action Timer_BombReturn(Handle hTimer)
{
	g_hTimerBombReturn = INVALID_HANDLE;

	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return Plugin_Stop;
	if(g_bBombGone) return Plugin_Stop; // Don't detect the drop when the bomb is removed

	// Move the bomb back onto the field
	int iBombFlag = EntRefToEntIndex(g_iRefBombFlag);
	if(iBombFlag > MaxClients)
	{
		AcceptEntityInput(iBombFlag, "Enable");
		AcceptEntityInput(iBombFlag, "ForceReset"); // Reset the bomb, this should call Bomb_OnReturned and in turn move the bomb back into play
	}
	
	return Plugin_Stop;
}

public void Bomb_OnRobotPickup(const char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(Bomb_OnRobotPickup) caller: %d activator: %d delay: %0.2f", caller, activator, delay);
#endif
	if(!g_bEnabled) return;

	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return;
	
	g_flBombLastMessage = 0.0; // Send an annotation to the player that picks up the bomb ASAP
	g_timeControlPointSkipped = 0.0;

	Timer_KillBombReturn(); // In case a player manages to pick up the bomb while it is sitting on the ground waiting to be returned

	if(g_flGlobalCooldown == 0.0 || GetEngineTime() - g_flGlobalCooldown > 5.0)
	{
		// "The robots have picked up the bomb!"
		EmitSoundToAll(g_strSoundBombPickup[GetRandomInt(0, sizeof(g_strSoundBombPickup)-1)]);
		g_flGlobalCooldown = GetEngineTime();
	}
	
	int client = GetEntPropEnt(caller, Prop_Send, "moveparent");
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TFTeam_Blue)
	{
		// If a normal robot picks up the bomb, we need to slow them down for balance, apply a 0.5 move speed bonus
		if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == 0)
		{
			// As a balance, there will be no bomb carrier buffs if the player count is below x amount
			int iPlayerCount;
			for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) >= 2) iPlayerCount++;
			if(iPlayerCount >= config.LookupInt(g_hCvarBombBuffsCuttoff))
			{
#if defined DEBUG
				PrintToServer("(Bomb_OnRobotPickup) %N picked up the bomb, applying slow-down/defense buff!", client);
#endif
				// 42 is the defense buff that MvM uses, resistance to crits
				TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, -1.0);
				TF2_AddCondition(client, TFCond_Buffed, config.LookupFloat(g_hCvarBombMiniCritsDuration), client);

				// There's a cool down for the healing effect so the robot carrier can't just drop the bomb and pick it up again for free health
				if(g_flTimeBombDropped[client] == 0.0 || GetEngineTime() - g_flTimeBombDropped[client] > config.LookupFloat(g_hCvarBombHealCooldown))
				{
					TF2_AddCondition(client, TFCond_HalloweenQuickHeal, config.LookupFloat(g_hCvarBombHealDuration));
				}
			}

			// Nerf: Robot carriers move slower
			Tank_SetAttributeValue(client, ATTRIB_MOVE_SPEED_BONUS, config.LookupFloat(g_hCvarBombMoveSpeed));
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
			// Nerf: Robot carriers cannot rocket/sticky jump
			Tank_SetAttributeValue(client, ATTRIB_SELF_DMG_PUSH_FORCE_DECREASE, 0.1);
			// Because we are applying this attribute on the player entity, we need to refresh the attributes on any weapons that might be hooking this attribute.
			for(int i=0; i<3; i++)
			{
				int weapon = GetPlayerWeaponSlot(client, i);
				if(weapon > MaxClients) Tank_ClearCache(weapon);
			}
		}

		// If a robot pickups up the bomb in the trigger_capture_area, we need to call StartTouch manually
		int iIndexCP = -1;
		int iCaptureTrigger;
		// Find the next control point that needs to be capped
		for(int i=0; i<MAX_LINKS; i++)
		{
			if(g_iRefLinkedPaths[TFTeam_Blue][i] == 0 || g_iRefLinkedCPs[TFTeam_Blue][i] == 0) continue;

			int iCP = EntRefToEntIndex(g_iRefLinkedCPs[TFTeam_Blue][i]);
			int iTrigger = EntRefToEntIndex(g_iRefCaptureTriggers[TFTeam_Blue][i]);

			if(iCP <= MaxClients || iTrigger <= MaxClients) continue;
			if(g_iRefLinkedCPs[TFTeam_Blue][i] == g_iRefControlPointGoal[TFTeam_Blue]) continue;
			bool bCaptured = (GetEntProp(iCP, Prop_Send, "m_nSkin") != 0);

			if(bCaptured) continue; // Don't do anything for control points that were already captured by the tank

			// We're found the control point and custom trigger_capture_area for the next control point
			iCaptureTrigger = iTrigger;
			iIndexCP = i;
			break;
		}

		if(iIndexCP != -1)
		{
			// Determine if the player is within the trigger_capture_area
			float flPos[3];
			GetClientAbsOrigin(client, flPos);
			if(SDK_PointIsWithin(iCaptureTrigger, flPos))
			{
				SDK_StartTouch(iCaptureTrigger, client);
			}
		}
	}
}

void Bomb_Cleanup()
{
#if defined DEBUG
	PrintToServer("(Bomb_Cleanup)");
#endif
	Bomb_KillFlag();
	Bomb_KillTimer();
	Timer_KillBombReturn();
	CaptureTriggers_Cleanup(TFTeam_Blue);
	CaptureZones_Cleanup(TFTeam_Blue);

	Giant_Cleanup(TFTeam_Blue);

	HealthBar_Hide();

	g_bombAtFinalCheckpoint = false;
}

void TF2_SetRespawnTime(int team, float flRespawnTime)
{
	GameRules_SetPropFloat("m_TeamRespawnWaveTimes", flRespawnTime, team);
}

stock int GetRandomIntBetween(int iStart, int iEnd)
{
	if(iStart == iEnd) return iStart;
	
	int iModifier;
	if(iStart == 0)
	{
		iStart += 1;
		iEnd += 1;
		
		iModifier = -1;
	}
	
	return (GetURandomInt() % iEnd) + iStart + iModifier;
}

public Action Command_Test(int client, int args)
{
	// Sets the setup clock to 3 seconds.
	SetVariantInt(3);
	AcceptEntityInput(FindEntityByClassname(MaxClients+1, "team_round_timer"), "SetSetupTime");

	return Plugin_Handled;
}

int Teleporter_BuildEntrance(int iBuilder, float flPos[3], int iMaxHealth)
{
	int iEntrance = CreateEntityByName("obj_teleporter");
	if(iEntrance > MaxClients)
	{
		int iTeam = GetClientTeam(iBuilder);

		DispatchSpawn(iEntrance);
		TeleportEntity(iEntrance, flPos, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(iEntrance, "teleporterType", "1");

		char strTeam[5];
		IntToString(iTeam, strTeam, sizeof(strTeam));
		DispatchKeyValue(iEntrance, "teamnum", strTeam);

		SetVariantInt(iTeam);
		AcceptEntityInput(iEntrance, "setteam");
		AcceptEntityInput(iEntrance, "setbuilder", iBuilder);
		SetVariantInt(iMaxHealth);
		AcceptEntityInput(iEntrance, "SetHealth");

		SetEntProp(iEntrance, Prop_Send, "m_iState", 7); // Trip the teleporter's think function to make the teleporter link up and become active.
		
		// Remove the team glow outline.
		int flags = GetEntProp(iEntrance, Prop_Send, "m_fEffects");
		flags |= EF_NODRAW;
		SetEntProp(iEntrance, Prop_Send, "m_fEffects", flags);
#if defined DEBUG
		PrintToServer("(Teleporter_BuildEntrance) Entrance built for %N: %d!", iBuilder, iEntrance);
#endif
		return EntIndexToEntRef(iEntrance);
	}

	return 0;
}

public Action Command_Test2(int client, int args)
{
	//
	if(args == 1) SetEntPropFloat(GetPlayerWeaponSlot(client, WeaponSlot_Secondary), Prop_Send, "m_flChargeLevel", 1.0);

	return Plugin_Handled;
}

public void Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnabled) return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		Reanimator_Cleanup(client);
		g_bReanimatorSwitched[client] = true; // Don't try to spawn a reanimator until this player respawns.

		// Check if the player is currently carrying the bomb and if so, drop the bomb
		if(g_iRefBombFlag != 0)
		{
			int iBomb = EntRefToEntIndex(g_iRefBombFlag);
			if(iBomb > MaxClients)
			{
				if(GetEntPropEnt(iBomb, Prop_Send, "moveparent") == client)
				{
					AcceptEntityInput(iBomb, "ForceDrop");
				}
			}
		}

		// Check if the giant switched teams and clean-up effects
		if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
		{
#if defined DEBUG
			PrintToServer("(Event_PlayerTeam) Clearing giant: %N!", client);
#endif
			if(!GetEventBool(event, "silent"))
			{
				// The player manually changed teams
				Giant_PlayDestructionSound(client);

				Giant_Clear(client, GiantCleared_Death);
			}else{
				Giant_Clear(client);
			}
		}
		Spawner_Cleanup(client);

		// A player switched teams so check to see if they fit in their new team.
		int team = GetEventInt(event, "team");
		int class = view_as<int>(TF2_GetPlayerClass(client));
		//PrintToServer("(Event_PlayerTeam) %N - team %d - class %d - alive %d", client, team, class, IsPlayerAlive(client));
		if(!ClassRestrict_IsImmune(client) && ClassRestrict_IsFull(team, class, client))
		{
			ShowVGUIPanel(client, (team == TFTeam_Blue) ? "class_blue" : "class_red");
			if(class >= 1 && class <= 9) EmitSoundToClient(client, g_strSoundNo[class]);
			ClassRestrict_PickClass(client, team, false);
		}
	}
}

bool ClassRestrict_IsFull(int team, int class, int client=-1, bool included=true)
{
	// If plugin is disabled, or team or class is invalid, class is not full
	if(team != TFTeam_Red && team != TFTeam_Blue) return false;

	if(class < 1 || class > 9) return false;
	
	// Get team's class limit
	int classLimit = config.LookupInt(g_hCvarClassLimits[team][class]);

	// If limit is -1, class is not full
	if(classLimit == -1) return false;
	
	// If limit is 0, class is full
	if(classLimit == 0) return true;

	// Assume the player is not included in the check. Therefore, if the limit was 2 and there were 2 people in the slot, we would be full.
	if(!included) classLimit -= 1;

	// Loop through all clients
	for(int i=1, iCount=0; i<=MaxClients; i++)
	{
		// If client is in game, on this team, has this class and limit has been reached, class is full
		// Compiler bug: https://bugs.alliedmods.net/show_bug.cgi?id=6380

		// Note: Sentry busters will inherit the player's class. Therefore they will be counted in the class limits since the player gets to keep their class.
		if(IsClientInGame(i) && (GetClientTeam(i) == team || i == client) && class == (view_as<int>(TF2_GetPlayerClass(i)))
		 	&& (GetEntProp(i, Prop_Send, "m_bIsMiniBoss") == 0 || Spawner_HasGiantTag(i, GIANTTAG_SENTRYBUSTER)) && ++iCount > classLimit)
		{
			//PrintToServer("(ClassRestrict_IsFull) FULL - team %d - class %d - included %d", team, class, included);
			return true;
		}
		//if(IsClientInGame(i)) PrintToServer("-> %N - team %d - class %d", i, GetClientTeam(i), view_as<int>(TF2_GetPlayerClass(i)));
	}
	
	//PrintToServer("(ClassRestrict_IsFull) NOT FULL - team %d - class %d - included %d", team, class, included);
	return false;
}

bool ClassRestrict_IsImmune(int client)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;

	return (client == g_iClassOverride);
}

bool ClassRestrict_PickClass(int client, int team, bool respawn=true)
{
	//PrintToServer("(ClassRestrict_PickClass) %N - team %d", client, team);
	// Loop through all classes, starting at random class.
	for(int i=GetRandomInt(1,9), numTried=0;;i++)
	{
		if(i > 9) i = 1;

		// If team's class is not full, set client's class.
		if(!ClassRestrict_IsFull(team, i, client))
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(i));
			if(respawn) TF2_RespawnPlayer(client);
			return true;
		}
		
		numTried++;
		if(numTried >= 9) break;
	}
	return false;
}

int	ClassRestrict_GetOpenClass(int client, int team)
{
	// Loop through all classes, starting at random class.
	for(int i=GetRandomInt(1,9), numTried=0;;i++)
	{
		if(i > 9) i = 1;

		// If team's class is not full, set client's class.
		if(!ClassRestrict_IsFull(team, i, client, false))
		{
			return i;
		}
		
		numTried++;
		if(numTried >= 9) break;
	}
	return 0;	
}

void ShowUpdatePanel(int client)
{
	Handle hPanel = CreatePanel();
	
	char strTemp[100];
	Format(strTemp, sizeof(strTemp), "Welcome to Stop that Tank! v%s", PLUGIN_VERSION);
	SetPanelTitle(hPanel, strTemp);

	if(g_nGameMode != GameMode_Race)
	{
		DrawPanelText(hPanel, "  - RED: Destroy the tank!");
		DrawPanelText(hPanel, "     BLU: Defend the tank & deliver the bomb!\n ");
	}else{
		DrawPanelText(hPanel, "  - RED/BLU: Slow down the enemy's tank with damage!\n ");	
	}
	
	DrawPanelText(hPanel, "Recent changes:");
	DrawPanelText(hPanel, "May-5: Carry the bomb while ubered/bonked.");

	if(GetConVarBool(g_hCvarOfficialServer))
	{
		DrawPanelText(hPanel, "Type !invite to join our Steam Group!");
	}
	
	DrawPanelText(hPanel, " \nHope you enjoy the unique gameplay!\n ");
	
	DrawPanelItem(hPanel, "Dismiss");
	
	SendPanelToClient(hPanel, client, PanelHandler, 20);
	
	CloseHandle(hPanel);
}

public Action Command_Updates(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(GetConVarInt(g_hCvarUpdatesPanel) < UpdatesPanel_OnlyTrigger)
	{
		PrintToChat(client, "%t", "Tank_Chat_Creators", g_strTeamColors[TFTeam_Blue], 0x01, PLUGIN_VERSION, "\x075885A2", 0x01, "\x075885A2", 0x01);
		return Plugin_Handled;
	}

	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		ShowUpdatePanel(client);
	}
	
	return Plugin_Handled;
}

public int PanelHandler(Handle hPanel, MenuAction action, int client, int menu_item)
{
	return;
}

void Scramble_Execute()
{
	PrintToChatAll("%t", "Tank_Chat_TeamScramble_Triggered", 0x01, "\x07EF4293", 0x01);

	// Executes a teamscramble that will take place when the next round starts
	ServerCommand("mp_scrambleteams 2");
	ServerExecute();
	SetConVarInt(g_hCvarRestartGame, 0); // mp_scrambleteams sets mp_restartgame to 5 for some reason unknown to me

	g_bIsScramblePending = true; // Set a flag to announce the scramble once the round ends
}

/*
public Event_PlayerStunned(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iStunner = GetClientOfUserId(GetEventInt(hEvent, "stunner"));
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	if(iStunner >= 1 && iStunner <= MaxClients && iVictim >= 1 && iVictim <= MaxClients && iStunner != iVictim && IsClientInGame(iVictim) && GetEntProp(iVictim, Prop_Send, "m_bIsMiniBoss"))
	{
		// Record whenever the giant is stunned to apply the cooldown
		g_flTimeGiantStunned[iVictim] = GetEngineTime();
	}
}
*/

public void Output_OnBlueCapture(const char[] output, int iControlPoint, int activator, float delay)
{
	if(!g_bEnabled) return;

#if defined DEBUG
	PrintToServer("(Output_OnBlueCapture) caller: %d activator: %d delay: %0.1f!", iControlPoint, activator, delay);
#endif
	if(!g_bIsInNaturalRound || g_nGameMode == GameMode_Race) return;
	if(iControlPoint <= MaxClients) return;

	int team = GetEntProp(iControlPoint, Prop_Send, "m_iTeamNum");
	if(team != TFTeam_Blue) return;

	// Find the control point's index
	int iIndexCP = -1;
	for(int i=0; i<MAX_LINKS; i++)
	{
		if(g_iRefLinkedCPs[team][i] != 0 && EntRefToEntIndex(g_iRefLinkedCPs[team][i]) == iControlPoint)
		{
			iIndexCP = i;
			break;
		}
	}
	if(iIndexCP == -1) return;
	if(g_iRefLinkedCPs[team][iIndexCP] == g_iRefControlPointGoal[team]) return; // skip the final control point

	int iPathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][iIndexCP]);
	if(iPathTrack <= MaxClients) return;

	if(g_nMapHack == MapHack_MillstoneEvent)
	{
		switch(iIndexCP)
		{
			// Hellstone removes the starting path track when the first control point is captured so pick another path_track to act as our start.
			case 0:
			{
#if defined DEBUG
				PrintToServer("(Output_OnBlueCapture) First point captured on Hellstone, modifying start path_track to %d!", iPathTrack);
#endif
				g_iRefPathStart[team] = EntIndexToEntRef(iPathTrack);
			}
			// Remove BLU's spawn barriers when the third control point is captured.
			// BLU has spawn barriers that are removed when a certain path_track is passed. This never happen if the tank dies early.
			case 2:
			{
				int relay = Entity_FindEntityByName("elementti_2", "logic_relay");
				if(relay != -1)
				{
#if defined DEBUG
					PrintToServer("(Output_OnBlueCapture) Third control point captured on Hellstone, removing BLU spawn barrier via logic_relay (%d)..", relay);
#endif
					AcceptEntityInput(relay, "Trigger");
				}
			}
		}
	}else if(g_nMapHack == MapHack_Barnblitz)
	{
		switch(iIndexCP)
		{
			// Make sure the doors are opened if the tank is destroyed before reaching the turn table.
			case 1:
			{
#if defined DEBUG
				PrintToServer("(Output_OnBlueCapture) Second point captured on Barnblitz, opening doors..");
#endif
				static char doors[3][32] = {"gate_redbarn_1_door", "gate_cap2_tunnel2", "gate_cap2_tunnel1"};
				for(int i=0; i<sizeof(doors); i++)
				{
					int door = Entity_FindEntityByName(doors[i], "func_door");
					if(door != -1)
					{
						AcceptEntityInput(door, "Open");
					}
				}
			}
		}
	}else if(g_nMapHack == MapHack_SnowyCoast)
	{
		switch(iIndexCP)
		{
			case 2:
			{
#if defined DEBUG
				PrintToServer("(Output_OnBlueCapture) Third point captured on Snowycoast, opening big doors..");
#endif
				int relay = Entity_FindEntityByName("final_gate_open", "logic_relay");
				if(relay != -1)
				{
					AcceptEntityInput(relay, "Trigger");
					AcceptEntityInput(relay, "Disable");

					CreateTimer(0.1, Timer_SnowyCoastDoors, g_iRefTrainWatcher[TFTeam_Blue], TIMER_FLAG_NO_MAPCHANGE);
				}

				int door = Entity_FindEntityByName("mine_door", "func_door");
				if(door > MaxClients)
				{
					AcceptEntityInput(door, "Open");
				}
			}
		}
	}

	// Swap the boring old RED hologram with the robot carrier hologram.
	float flAng[3];
	Path_GetOrientation(iPathTrack, flAng);
	SetEntityModel(iControlPoint, MODEL_ROBOT_HOLOGRAM);
	TeleportEntity(iControlPoint, NULL_VECTOR, flAng, NULL_VECTOR);
}

public Action Timer_SnowyCoastDoors(Handle timer, int ref)
{
	if(!g_bIsRoundStarted) return Plugin_Handled;

	// Cancel out the final_gate_open relay setting SetSpeedForwardModifier to 0.01 so the tank does not stop.
	int watcher = EntRefToEntIndex(ref);
	if(watcher > MaxClients)
	{
		SetVariantFloat(1.0);
		AcceptEntityInput(watcher, "SetSpeedForwardModifier");
	}

	return Plugin_Handled;
}

public void Event_BuildObject(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	// Upgrade any built object during map setup period
	int iBuilder = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iBuilder >= 1 && iBuilder <= MaxClients && IsClientInGame(iBuilder) && IsPlayerAlive(iBuilder))
	{
		int iObject = GetEventInt(hEvent, "index");
		if(iObject > MaxClients)
		{
			TFObjectType type = view_as<TFObjectType>(GetEntProp(iObject, Prop_Send, "m_iObjectType"));

			if(Tank_IsInSetup())
			{
				if(type != TFObject_Sapper)
				{
					// Block the game log event to prevent stat farming on hlstatsx and the like.
					g_blockLogAction = true;

					SDK_DoQuickBuild(iObject);

					// Needed so quick built sentries will be counted as active for sentry busters
					SetEntPropFloat(iObject, Prop_Send, "m_flPercentageConstructed", 1.0);

					switch(type)
					{
						case TFObject_Dispenser:
						{
							// DoQuickBuild does not fill m_iAmmoMetal
							SetEntProp(iObject, Prop_Send, "m_iAmmoMetal", 400);							
						}
						case TFObject_Sentry:
						{
							// Mini-sentries spawn with 50 health instead of 100.
							if(GetEntProp(iObject, Prop_Send, "m_bMiniBuilding"))
							{
								SetEntProp(iObject, Prop_Send, "m_iHealth", GetEntProp(iObject, Prop_Send, "m_iMaxHealth"));
							}
						}
					}
				}
			}

			if(type == TFObject_Dispenser)
			{
				if(Spawner_HasGiantTag(iBuilder, GIANTTAG_SCALE_BUILDINGS) && GetEntProp(iBuilder, Prop_Send, "m_bIsMiniBoss"))
				{
					// The dispenser's screen does not scale properly with m_flModelScale
					int vgui = MaxClients+1;
					while((vgui = FindEntityByClassname(vgui, "vgui_screen")) > MaxClients)
					{
						if(GetEntPropEnt(vgui, Prop_Send, "m_hOwnerEntity") == iObject)
						{
							SetEntPropFloat(vgui, Prop_Send, "m_flWidth", GetEntPropFloat(vgui, Prop_Send, "m_flWidth")*0.55);
							SetEntPropFloat(vgui, Prop_Send, "m_flHeight", GetEntPropFloat(vgui, Prop_Send, "m_flHeight")*0.55);
						}
					}
				}
			}
		}
	}
}

void Reanimator_Cleanup(int client=0)
{
	if(client == 0)
	{
		for(int i=0; i<sizeof(g_iRefReanimator); i++)
		{
			if(g_iRefReanimator[i] != 0)
			{
				int iEntity = EntRefToEntIndex(g_iRefReanimator[i]);
				if(iEntity > MaxClients) AcceptEntityInput(iEntity, "Kill");
				g_iRefReanimator[i] = 0;
			}
			if(g_iRefReanimatorDummy[i] != 0)
			{
				int iEntity = EntRefToEntIndex(g_iRefReanimatorDummy[i]);
				if(iEntity > MaxClients) AcceptEntityInput(iEntity, "Kill");
				g_iRefReanimatorDummy[i] = 0;
			}

			g_bReanimatorIsBeingRevied[i] = false;
		}
	}else{
		if(g_iRefReanimator[client] != 0)
		{
			int iEntity = EntRefToEntIndex(g_iRefReanimator[client]);
			if(iEntity > MaxClients) AcceptEntityInput(iEntity, "Kill");
			g_iRefReanimator[client] = 0;
		}
		if(g_iRefReanimatorDummy[client] != 0)
		{
			int iEntity = EntRefToEntIndex(g_iRefReanimatorDummy[client]);
			if(iEntity > MaxClients) AcceptEntityInput(iEntity, "Kill");
			g_iRefReanimatorDummy[client] = 0;
		}

		g_bReanimatorIsBeingRevied[client] = false;
	}
}

void Reanimator_Create(int client, bool bFeignMarker=false, int disguisedClass=0)
{
	// There are several problems with the reanimator in non-mvm:
	// 1. (FIXED BY VALVE) Medics can't heal the revive markers -> fixed with a detour
	// 2. Whenever a marker is spawned, a bubble pops up on EVERY client's screen (even spectators) for 4s -> fixed by creating a dummy entity and only showing the revive marker to medics and the person that died
	// 2.5. The dummy entity won't be in the same position as the revive marker -> told I was too nit-picky for this one (medi-beams won't show to those who see the dummy marker as well)
	// 3. (FIXED BY VALVE) The cancel popup doesn't show to the dead player -> can be fixed by faking m_bBountyModeEnabled = 1, m_bIsInTraining = 0, but that has side-effects AND the client cancel keyvalue (MVM_Revive_Response) is not acknowledged by the server to kill the marker.. going to implement a cancel mechanism myself as it seems to be the easier option
	// 4. The game doesn't wait for the player to respawn -> fixed by setting an offset in CTFPlayer
	// 5. There's a bug where the player will be revived instantly if they are looking at the medic (caused by Valve not setting an initial maxhealth, but doing it later in the Think function) -> can be fixed calling the Think function OR by setting m_iMaxHealth immediately after the marker is spawned (this will override the default value in the game so make sure you set it to the max health you want)
	// 6. The quickfix uber sound will loop if a player is revived with it -> fixed by stopping the sound whenever they are revived
	// 7. The healing beams will not be visible to those who see the dummy entity -> fixed by adding a healing particle around the dummy for those who see it
	if(GetEntityCount() > GetMaxEntities()-ENTITY_LIMIT_BUFFER)
	{
		LogMessage("Not spawning reanimator. Reaching entity limit: %d/%d!", GetEntityCount(), GetMaxEntities());
		return;
	}

	// Spawn the revive marker that medics will heal and revive the player with
	int iMarker = -1;
	if(!bFeignMarker)
	{
		iMarker = CreateEntityByName("entity_revive_marker");
		if(iMarker > MaxClients)
		{
			float flPos[3];
			GetClientAbsOrigin(client, flPos);
			flPos[2] += 20.0;
			TeleportEntity(iMarker, flPos, NULL_VECTOR, NULL_VECTOR);

			SetEntPropEnt(iMarker, Prop_Send, "m_hOwner", client); // client index 
			SetEntProp(iMarker, Prop_Send, "m_iTeamNum", GetClientTeam(client)); // client team
			int bodyGroup = view_as<int>(TF2_GetPlayerClass(client));
			bodyGroup -= 1; // to avoid tag mismatch warning..
			SetEntProp(iMarker, Prop_Send, "m_nBody", bodyGroup);

			SDKHook(iMarker, SDKHook_SetTransmit, Reanimator_MarkerSetTransmit);

			DispatchSpawn(iMarker);
#if defined DEBUG
			PrintToServer("(Reanimator_Create) Spawned revive marker for %N: %d!", client, iMarker);
#endif
			g_iRefReanimator[client] = EntIndexToEntRef(iMarker);

			if(g_iOffsetReviveMarker > 0)
			{
				SetEntDataEnt2(client, g_iOffsetReviveMarker+4, iMarker);
			}

			// There's a bug where revive markers will sometimes spawn with 0 m_iMaxHealth and cause instant revive (thanks valve!)
			// Their formula for m_iMaxHealth is as follows: (player max health)/2 + 10*(revive count)
			int iMaxHealth = RoundToFloor(float(SDK_GetMaxHealth(client))*config.LookupFloat(g_hCvarReanimatorMaxHealthMult)) + config.LookupInt(g_hCvarReanimatorReviveMult)*g_iReanimatorNumRevives[client];
			SetEntProp(iMarker, Prop_Send, "m_iMaxHealth", iMaxHealth);

			//SetEntProp(iMarker, Prop_Send, "m_nSolidType", 2); 
			//SetEntProp(iMarker, Prop_Send, "m_usSolidFlags", 4|8); 
			//SetEntProp(iMarker, Prop_Send, "m_CollisionGroup", 24);
		}else{
			// Failed to spawn the revive marker so don't bother with the dummy entity
			return;
		}
	}

	// Spawn the dummy revive marker that everyone besides RED medics and the player that died will see
	int iDummy = CreateEntityByName("prop_dynamic");
	if(iDummy > MaxClients)
	{
		// Find the position that the marker will fall straight down
		float flAng[3] = {90.0, 0.0, 0.0};
		float flPos[3];
		GetClientEyePosition(client, flPos);

		TR_TraceRayFilter(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilter_Reanimator, iMarker);
		if(TR_DidHit())
		{
			TR_GetEndPosition(flPos);
		}

		TeleportEntity(iDummy, flPos, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(iDummy, "model", MODEL_REVIVE_MARKER);
		DispatchKeyValue(iDummy, "DefaultAnim", "idle");
		DispatchKeyValue(iDummy, "solid", "0");
		int class = view_as<int>(TF2_GetPlayerClass(client));
		if(disguisedClass >= 1 && disguisedClass <= 9) class = disguisedClass;
		SetEntProp(iDummy, Prop_Send, "m_nBody", class-1);

		AcceptEntityInput(iDummy, "DisableShadow");

		if(!bFeignMarker)
		{
			SDKHook(iDummy, SDKHook_SetTransmit, Reanimator_DummySetTransmit);
		}else{
			// The feign dummy marker should only show for the person that activated it (the spy) and to the enemy team to fool them
			// Make the assumption that markers only drop for the RED team and therefore the BLUE team activated it
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == TFTeam_Blue)
				{
					EmitSoundToClient(i, SOUND_REANIMATOR_PING, iDummy);
				}
			}
			EmitSoundToClient(client, SOUND_REANIMATOR_PING, iDummy);

			SDKHook(iDummy, SDKHook_SetTransmit, Reanimator_FeignSetTransmit);
		}

		DispatchSpawn(iDummy);

		//SetEntProp(iDummy, Prop_Data, "m_iInteractions", g_iRefReanimator[client]);
#if defined DEBUG
		PrintToServer("(Reanimator_Create) Spawned dummy entity for %N: %d!", client, iDummy);
#endif
		g_iRefReanimatorDummy[client] = EntIndexToEntRef(iDummy);
	}
}

public bool TraceFilter_Reanimator(int entity, int mask, int marker)
{
	if(entity == 0) return true; // Hit world.
	if(entity == marker) return false;

	char classname[24];
	GetEdictClassname(entity, classname, sizeof(classname));
	//PrintToServer("Hit entity %d \"%s\" mask: %d", entity, classname, mask);
	if(strncmp(classname, "tf_ammo_pack", 12) == 0) return false;
	if(strncmp(classname, "tf_dropped_weapon", 17) == 0) return false;
	if(strncmp(classname, "entity_revive_marker", 20) == 0) return false;
	if(strncmp(classname, "tf_projectile_arrow", 19) == 0) return false;

	return entity > MaxClients;
}

public Action Reanimator_MarkerSetTransmit(int iMarker, int client)
{
	// The revive marker should only be visible to RED medics and the player being healed
	if(GetClientTeam(client) == TFTeam_Red && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		return Plugin_Continue;
	}

	if(g_iRefReanimator[client] != 0 && EntRefToEntIndex(g_iRefReanimator[client]) == iMarker)
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action Reanimator_DummySetTransmit(int iDummy, int client)
{
	// The dummy entity should be visible to ALL players except for RED medics AND the player being healed
	if(GetClientTeam(client) == TFTeam_Red && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		return Plugin_Handled;
	}

	if(g_iRefReanimatorDummy[client] != 0 && EntRefToEntIndex(g_iRefReanimatorDummy[client]) == iDummy)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Reanimator_FeignSetTransmit(int iDummy, int client)
{
	// The feign marker should only show up for the player that feigned (usually the spy) AND the team of the player that activated the feign (assumed to be BLUE)
	if(GetClientTeam(client) == TFTeam_Blue)
	{
		return Plugin_Continue;
	}

	// Show the marker to the player that feigned
	if(g_iRefReanimatorDummy[client] != 0 && EntRefToEntIndex(g_iRefReanimatorDummy[client]) == iDummy)
	{
		return Plugin_Continue;
	}	


	return Plugin_Handled;
}

public void Event_ReviveNotify(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	int client = GetEventInt(hEvent, "entindex");
	if(client >= 1 && client <= MaxClients && !g_bReanimatorIsBeingRevied[client] && IsClientInGame(client) && GetClientTeam(client) == TFTeam_Red && !IsPlayerAlive(client))
	{
		g_bReanimatorIsBeingRevied[client] = true;

		// Let the player know that the dummy marker is being healed (medibeams will not show up)
		int iDummy = EntRefToEntIndex(g_iRefReanimatorDummy[client]);
		if(iDummy > MaxClients && g_iParticleHealRadius > -1)
		{
			// Send the particle to everyone that can see the dummy marker (everyone except RED medics and client)
			Handle hArray = CreateArray();
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
				{
					int team = GetClientTeam(i);
					if(team == TFTeam_Blue || (team == TFTeam_Red && TF2_GetPlayerClass(i) != TFClass_Medic))
					{
						PushArrayCell(hArray, i);
					}
				}
			}

			int iSize = GetArraySize(hArray);
			if(iSize > 0)
			{
				TE_Particle(g_iParticleHealRadius, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, iDummy);
				int[] clients = new int[iSize];
				for(int i=0; i<iSize; i++) clients[i] = GetArrayCell(hArray, i);

				TE_Send(clients, iSize);
			}

			CloseHandle(hArray);
		}
	}
}

public void Event_ReviveComplete(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	int client = GetEventInt(hEvent, "entindex");
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TFTeam_Red)
	{
		// Reviving a player awards the medic 5 points. That is way too many so block some of those points.
		Score_IncrementBonusPoints(client, -4);

		// Log hlstats event: player_revived
		char auth[32];
		GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
		LogToGame("\"%N<%d><%s><%s>\" triggered \"player_revived\"", client, GetClientUserId(client), auth, g_strTeamClass[GetClientTeam(client)]);

		// This event only reports the medic that revived the player
		// We need to log who was revived so look at what the medic was healing
		int iSecondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(iSecondary > MaxClients)
		{
			char strClass[40];
			GetEdictClassname(iSecondary, strClass, sizeof(strClass));
			if(strcmp(strClass, "tf_weapon_medigun") == 0)
			{
				int iMarker = GetEntPropEnt(iSecondary, Prop_Send, "m_hHealingTarget");
				if(iMarker > MaxClients)
				{
					int iRevivedPlayer = GetEntPropEnt(iMarker, Prop_Send, "m_hOwner");
					if(iRevivedPlayer >= 1 && iRevivedPlayer <= MaxClients && IsClientInGame(iRevivedPlayer))
					{
#if defined DEBUG
						PrintToServer("(Event_ReviveComplete) Logged a revive for: %N!", iRevivedPlayer);
#endif
						g_iReanimatorNumRevives[iRevivedPlayer]++;
					}
				}
			}
		}
	}
}

bool g_inJoinClass = false;
public Action Listener_Joinclass(int client, const char[] command, int argc)
{
	if(g_inJoinClass)
	{
		g_inJoinClass = false;
		return Plugin_Continue;
	}

	if(!g_bEnabled) return Plugin_Continue;

	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		// Sometimes a player will be in the class selection screen while they are a giant
		// They will be killed and ruin the round so catch when that happens and block it
		if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss")) return Plugin_Handled;

		int team = GetClientTeam(client);
		if(team == TFTeam_Red || team == TFTeam_Blue)
		{
			// Hooking the join_class command is a better way of implementing class limits.
			// I will leave in the check at player_spawn as a fall back.
			char arg[32];
			GetCmdArgString(arg, sizeof(arg));

			// Find the class that the player wants to spawn as.
			static char classNames[10][32] =
			{
				"",
				"scout",
				"sniper",
				"soldier",
				"demoman",
				"medic",
				"heavyweapons",
				"pyro",
				"spy",
				"engineer",
			};
			TFClassType class = TFClass_Unknown;
			for(int i=0; i<sizeof(classNames); i++)
			{
				if(strcmp(arg, classNames[i], false) == 0)
				{
					class = view_as<TFClassType>(i);
					break;
				}
			}

			if(class == TFClass_Unknown && (strcmp(arg, "random", false) == 0 || strcmp(arg, "auto", false) == 0))
			{
				// Player wants to spawn as a random class.
				TFClassType randomClass = view_as<TFClassType>(ClassRestrict_GetOpenClass(client, team));
				if(randomClass != TFClass_Unknown)
				{
					// We've got a random class.
					g_inJoinClass = true;
					FakeClientCommand(client, "joinclass %s", classNames[view_as<int>(randomClass)]);
					return Plugin_Handled;
				}else{
					// We failed to pick a random class so let the command go thru.
					return Plugin_Continue;
				}
			}else if(class != TFClass_Unknown)
			{
				// Do nothing if the player is already the requested class.
				if(class == TF2_GetPlayerClass(client)) return Plugin_Handled;

				// Check if there is a free slot for the class.
				if(!ClassRestrict_IsFull(team, view_as<int>(class), client, false))
				{
					// There's room for the player.
					g_inJoinClass = true;
					FakeClientCommand(client, "joinclass %s", classNames[view_as<int>(class)]);
					return Plugin_Handled;
				}else{
					// There's no room for the requested slot so deny the switch and bring up the class selection menu.
					ShowVGUIPanel(client, team == TFTeam_Blue ? "class_blue" : "class_red");
					EmitSoundToClient(client, g_strSoundNo[class]);
					return Plugin_Handled;
				}
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

void Path_GetOrientation(int iPathTrack, float flAng[3], bool pointBackwards=false)
{
	float flPosFirst[3];
	GetEntPropVector(iPathTrack, Prop_Send, "m_vecOrigin", flPosFirst);

	// Gets the angle from one path track, pointing to another
	int nextPath;
	if(pointBackwards)
	{
		nextPath = GetEntDataEnt2(iPathTrack, Offset_GetPreviousOffset(iPathTrack));
	}else{
		nextPath = GetEntDataEnt2(iPathTrack, Offset_GetNextOffset(iPathTrack));
	}

	if(nextPath <= MaxClients)
	{
		// Can't find a next path so use the linked paths to generate an angle.
		int index = -1;
		int team;
		for(team=2; team<=3; team++)
		{
			for(int i=0; i<MAX_LINKS; i++)
			{
				if(EntRefToEntIndex(g_iRefLinkedPaths[team][i]) == iPathTrack)
				{
					index = i;
					break;
				}
			}
			if(index != -1) break;
		}

		if(index != -1)
		{
			// Point to the next linked path_track.
			if(pointBackwards)
			{
				index--;
			}else{
				index++;
			}

			if(index >= 0 && index < MAX_LINKS)
			{
				nextPath = EntRefToEntIndex(g_iRefLinkedPaths[team][index]);
			}
		}
	}

	if(nextPath > MaxClients)
	{
		float flPosNext[3];
		GetEntPropVector(nextPath, Prop_Send, "m_vecOrigin", flPosNext);

		float flDir[3];
		SubtractVectors(flPosNext, flPosFirst, flDir);

		GetVectorAngles(flDir, flAng);
		flAng[0] = 0.0; // We don't care about pitch
	}
}

stock void Vector_GetAngleToPosition(float from[3], float to[3], float ang[3])
{
	float dir[3];
	SubtractVectors(to, from, dir);
	GetVectorAngles(dir, ang);
}

// Thanks to https://forums.alliedmods.net/showpost.php?p=1481096&postcount=2
void GetPositionForward(float vPos[3], float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	for(int i=0; i<3; i++) vReturn[i] += vDir[i] * fDistance;
}

bool g_inTauntListener = false;
public Action Listener_Taunt(int client, const char[] command, int argc)
{
	if(g_inTauntListener)
	{
		g_inTauntListener = false;
		return Plugin_Continue;
	}

	if(!g_bEnabled) return Plugin_Continue;

	if(client >= 1 && client <= MaxClients && Spawner_HasGiantTag(client, GIANTTAG_SENTRYBUSTER) && g_flTimeBusterTaunt[client] == 0.0 && GetEntProp(client, Prop_Send, "m_bIsMiniBoss")
		&& GetEntProp(client, Prop_Send, "m_hGroundEntity") != -1 && !TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		// If the sentry buster uses an action taunt, block it and do the normal class taunt in order to play the animation
		char strArgs[5];
		GetCmdArgString(strArgs, sizeof(strArgs));
		int iIndexTaunt = StringToInt(strArgs);
		if(iIndexTaunt >= 1 && iIndexTaunt <= 9)
		{
			FakeClientCommand(client, "taunt");
			return Plugin_Stop;
		}

		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 0.0);
		Tank_SetAttributeValue(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS, 0.001);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);

		EmitSoundToAll(SOUND_BUSTER_SPIN, client);

		//SDK_PlaySpecificSequence(client, "sentry_buster_preExplode");

		TFClassType class = TF2_GetPlayerClass(client);
		TF2_SetPlayerClass(client, TFClass_DemoMan, false, false);
		g_inTauntListener = true;
		FakeClientCommand(client, "taunt");
		TF2_SetPlayerClass(client, class, false, false);

		g_flTimeBusterTaunt[client] = GetEngineTime();
	}

	return Plugin_Continue;
}

public Action Command_MakeGiant(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	bool bMakeBuster = false;
	char strCommand[32];
	GetCmdArg(0, strCommand, sizeof(strCommand)); // The 0 arguement is the command name
	if(strcmp(strCommand, "sm_makebuster", false) == 0) bMakeBuster = true;

	if(args != 1 && args != 2)
	{
		if(bMakeBuster)
		{
			ReplyToCommand(client, "Usage: sm_makebuster <#userid|name> <index|giant name>");
		}else{
			ReplyToCommand(client, "Usage: sm_makegiant <#userid|name> <index|giant name>");
		}
		return Plugin_Handled;
	}

	char strTargets[128];
	GetCmdArg(1, strTargets, sizeof(strTargets));

	char strGiantName[MAXLEN_GIANT_STRING];
	GetCmdArg(2, strGiantName, sizeof(strGiantName));

	// Leaving out the second arguement picks a random template
	bool bPickRandom = (strlen(strGiantName) == 0);
	
	int iIndex = -1;
	if(!bPickRandom)
	{
		iIndex = StringToInt(strGiantName);
		if(iIndex == 0 && strcmp(strGiantName, "0") != 0)
		{
			// A number was not entered
			iIndex = -1;
			// Try to find the giant by name
			int iNumFound = 0;
			for(int i=0; i<MAX_NUM_TEMPLATES; i++)
			{
				if(g_nGiants[i][g_bGiantTemplateEnabled] && StrContains(g_nGiants[i][g_strGiantName], strGiantName, false) != -1)
				{
					if((bMakeBuster && g_nGiants[i][g_iGiantTags] & GIANTTAG_SENTRYBUSTER) || (!bMakeBuster && !(g_nGiants[i][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)))
					{
						iIndex = i;
						iNumFound++;
					}
				}
			}

			if(iNumFound > 1)
			{
				ReplyToCommand(client, "More than one giant matched the given pattern.");
				return Plugin_Handled;
			}
		}
	}

	// Find the target(s)
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	if((target_count = ProcessTargetString(strTargets, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i=0; i<target_count; i++)
	{
		if(bPickRandom)
		{
			if(bMakeBuster)
			{
				iIndex = Buster_PickTemplate();
			}else{
				iIndex = Giant_PickTemplate();
			}
		}

		if(iIndex < 0 || iIndex >= MAX_NUM_TEMPLATES || !g_nGiants[iIndex][g_bGiantTemplateEnabled] || (bMakeBuster && !(g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)) || (!bMakeBuster && g_nGiants[iIndex][g_iGiantTags] & GIANTTAG_SENTRYBUSTER))
		{
			ReplyToCommand(client, "No matching giant was found or template is disabled.");
			return Plugin_Handled;
		}

		int iTeam = GetClientTeam(target_list[i]);
		if(iTeam != TFTeam_Red && iTeam != TFTeam_Blue)
		{
			ReplyToCommand(client, "Failed to make %N a giant: Not on a team.", target_list[i]);
			continue;
		}

		if(g_nSpawner[target_list[i]][g_bSpawnerEnabled])
		{
			ReplyToCommand(client, "Failed to make %N a giant: Already being spawned.", target_list[i]);
			continue;
		}

		Spawner_Spawn(target_list[i], Spawn_GiantRobot, iIndex);
		ShowActivity2(client, "[SM] ", "%N was made into a %s!", target_list[i], g_nGiants[iIndex][g_strGiantName]);
	}	

	return Plugin_Handled;
}

public Action Command_Pass(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(client < 1 || client > MaxClients || !IsClientInGame(client)) return Plugin_Handled;
	int team = GetClientTeam(client);
	if(team != TFTeam_Red && team != TFTeam_Blue) return Plugin_Handled;

	// This command allows the queued sentry buster player to pass his role to another (random) player
	// or more generally, to opt-out of being a sentry buster for the rest of the round

	// Add them to the passed list so they will not be made into another sentry buster for the duration of the round
	if(!g_bBusterPassed[client])
	{
		g_bBusterPassed[client] = true;

		PrintToChat(client, "%t", "Tank_Chat_Passed_1", 0x01, g_strTeamColors[team], 0x01, g_strTeamColors[team], 0x01);
		PrintToChat(client, "%t", "Tank_Chat_Passed_2", 0x01);
	}else{
		g_bBusterPassed[client] = false;

		PrintToChat(client, "%t", "Tank_Chat_NotPassed_1", 0x01, g_strTeamColors[team], 0x01, g_strTeamColors[team], 0x01);
		PrintToChat(client, "%t", "Tank_Chat_NotPassed_2", 0x01);
	}

	return Plugin_Handled;
}

void ModelOverrides_Clear(int client)
{
	if(!g_bEnabled) return;

	for(int i=0; i<4; i++)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, i);
	}

	g_nDisguised[client][g_iDisguisedClass] = 0;
	g_nDisguised[client][g_iDisguisedTeam] = 0;
}

void VisionFlags_Update(int client)
{
	// RED will see index 4 (rome vision)
	// BLU will see index 0 (normal, everyone sees this, but RED won't see their index unless index 0 is non-zero)
	Tank_RemoveAttribute(client, ATTRIB_VISION_OPT_IN_FLAGS);

	switch(GetClientTeam(client))
	{
		case TFTeam_Red: Tank_SetAttributeValue(client, ATTRIB_VISION_OPT_IN_FLAGS, VISIONFLAG_ROMEVISION);
	}
}

void ModelOverrides_Think(int client, int iDisguisedClass, int iDisguisedTeam)
{
#if defined DEBUG
	PrintToServer("(ModelOverrides_Think) %N!", client);
#endif
	int team = GetClientTeam(client);
	int enemyTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;

	// RED spies disguised as BLU look HUMAN to BLU
	// BLU spies disguised as BLU look HUMAN to RED

	// We need to set the model that the spy's team will see, we have to do this so that the enemy team can see their overrided model (this is just how it works)
	if(g_nGameMode != GameMode_Race)
	{
		if(team == TFTeam_Red)
		{
			// Make the RED spy look human to their team
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[TFClass_Spy], _, g_teamOverrides[team]);

			if(iDisguisedTeam == TFTeam_Red)
			{
				// RED spy disguised as a RED team member, should look like a RED human to the BLU team
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[iDisguisedClass], _, g_teamOverrides[enemyTeam]);
			}else{
				// RED spy disguised as a BLU team member, should look like a BLU robot to the BLU team
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[iDisguisedClass], _, g_teamOverrides[enemyTeam]);
			}
		}else{
			// Make the BLU spy look like a robot to their team
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[TFClass_Spy], _, g_teamOverrides[team]);

			if(iDisguisedTeam == TFTeam_Red)
			{
				// BLU spy disguised as a RED team member, should look like a RED human to the RED team
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[iDisguisedClass], _, g_teamOverrides[enemyTeam]);
			}else{
				// BLU spy disguised as a BLU team member, should like like a BLU robot to the RED team
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[iDisguisedClass], _, g_teamOverrides[enemyTeam]);
			}
		}
	}else{
		// In PLR, both teams (RED and BLU) are robots so this will simplify things
		// The spy will always look like a spy to their teammates
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[TFClass_Spy], _, g_teamOverrides[team]);

		// The spy will always look like a robot to the enemy team
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[iDisguisedClass], _, g_teamOverrides[enemyTeam]);
	}	
}

void AirbourneTimer_Kill(int client)
{
	if(g_hAirbourneTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hAirbourneTimer[client]);
		g_hAirbourneTimer[client] = INVALID_HANDLE;
	}
}

public Action Timer_AirbourneMiniCrits(Handle hTimer, int client)
{
	if(IsClientInGame(client) && Spawner_HasGiantTag(client, GIANTTAG_AIRBOURNE_MINICRITS) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") && TF2_IsPlayerInCondition(client, TFCond_BlastJumping))
	{
		TF2_AddCondition(client, TFCond_CritCola);
	}

	g_hAirbourneTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(!g_bEnabled) return;

	switch(condition)
	{
		case TFCond_BlastJumping:
		{
			if(Spawner_HasGiantTag(client, GIANTTAG_AIRBOURNE_MINICRITS) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				// Apply a 0.5s delay to apply the effects to prevent abuse
				AirbourneTimer_Kill(client);
				g_hAirbourneTimer[client] = CreateTimer(0.5, Timer_AirbourneMiniCrits, client, TIMER_REPEAT);
			}
		}
		case TFCond_Taunting:
		{
			// Fix conga taunt for robot models.
			if(config.LookupBool(g_hCvarRobot) && !GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				if(g_nGameMode == GameMode_Race || GetClientTeam(client) == TFTeam_Blue)
				{
					switch(GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex"))
					{
						case ITEM_CONGA,ITEM_KAZOTSKY_KICK,ITEM_MANNROBICS:
						{
							SetEntPropFloat(client, Prop_Send, "m_flCurrentTauntMoveSpeed", 50.0);
							SetEntProp(client, Prop_Send, "m_bAllowMoveDuringTaunt", true);
						}
						case ITEM_BOX_TROT:
						{
							SetEntPropFloat(client, Prop_Send, "m_flCurrentTauntMoveSpeed", 100.0);
							SetEntProp(client, Prop_Send, "m_bAllowMoveDuringTaunt", true);
						}
						case ITEM_ZOOMIN_BROOM:
						{
							SetEntPropFloat(client, Prop_Send, "m_flCurrentTauntMoveSpeed", 200.0);
							SetEntProp(client, Prop_Send, "m_bAllowMoveDuringTaunt", true);
						}
					}
				}
			}

			if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] != Spawn_Tank && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				// Makes sure that the giant's taunt prop is properly scaled. Details like this matter.
				if(g_iOffset_m_tauntProp > 0 && GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex") != -1)
				{
					int tauntProp = GetEntDataEnt2(client, g_iOffset_m_tauntProp);
					if(tauntProp > MaxClients)
					{
						int tempIndex = g_nSpawner[client][g_iSpawnerGiantIndex];
						if(tempIndex >= 0 && tempIndex < MAX_NUM_TEMPLATES && g_nGiants[tempIndex][g_bGiantTemplateEnabled])
						{
							// Set the appropriate model scale
							float scale = Giant_GetModelScale(tempIndex);

							char modelScale[32];
							FloatToString(scale, modelScale, sizeof(modelScale));
							SetVariantString(modelScale);
							AcceptEntityInput(tauntProp, "SetModelScale");
						}
					}
				}
			}
		}
		case TFCond_HalloweenThriller:
		{
			if(g_nMapHack == MapHack_HightowerEvent)
			{
				// Player conditions get removed when the player is teleported to hell so reapply them.
				if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot && IsClientInGame(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
				{
					int template = g_nSpawner[client][g_iSpawnerGiantIndex];
					if(template >= 0 && template < MAX_NUM_TEMPLATES && g_nGiants[template][g_bGiantTemplateEnabled])
					{
						Giant_ApplyConditions(client, template);
					}
				}
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(!g_bEnabled) return;

	switch(condition)
	{
		case TFCond_Cloaked:
		{
			// Remove the dummy feign marker when a DR spy uncloaks
			if(g_nGameMode != GameMode_Race && GetClientTeam(client) == TFTeam_Red && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				Reanimator_Cleanup(client);
			}
		}
		case TFCond_HalloweenTiny:
		{
			if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] != Spawn_Tank && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				// Restore the player's model scale with the value from their template
				int iIndex = g_nSpawner[client][g_iSpawnerGiantIndex];
				if(iIndex >= 0 && iIndex < MAX_NUM_TEMPLATES && g_nGiants[iIndex][g_bGiantTemplateEnabled])
				{
					// Set the appropriate model scale
					float scale = Giant_GetModelScale(iIndex);

					char modelScale[32];
					FloatToString(scale, modelScale, sizeof(modelScale));
					SetVariantString(modelScale);
					AcceptEntityInput(client, "SetModelScale");
				}

				// Ensure that player is not stuck after re-scaling.
				float pos[3];
				GetClientAbsOrigin(client, pos);
				
				float mins[3];
				float maxs[3];
				GetClientMins(client, mins);
				GetClientMaxs(client, maxs);

				int team = GetClientTeam(client);
				int mask = MASK_RED;
				if(team != TFTeam_Red) mask = MASK_BLUE;

				TR_TraceHullFilter(pos, pos, mins, maxs, mask, TraceFilter_NotTeam, team);
				if(TR_DidHit())
				{
#if defined DEBUG
					PrintToServer("(TF2_OnConditionRemoved) Detected that %N may be stuck after minify spell!", client);
#endif
					// Player is probably stuck so teleport them to a new position
					if(!Player_FindFreePosition2(client, pos, mins, maxs))
					{
#if defined DEBUG
						PrintToServer("(TF2_OnConditionRemoved) Failed to find a free spot for %N!", client);
#endif
						//
					}
				}
			}
		}
		case TFCond_BlastJumping:
		{
			if(Spawner_HasGiantTag(client, GIANTTAG_AIRBOURNE_MINICRITS) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				TF2_RemoveCondition(client, TFCond_CritCola);
				AirbourneTimer_Kill(client);
			}
		}
	}
}

public Action OnGameLog(const char[] message)
{
	//PrintToServer("(OnGameLog) %s", message);

	if(g_blockLogAction)
	{
#if defined DEBUG
		PrintToServer("(OnGameLog) BLOCKED event: %s!", message);
#endif
		g_blockLogAction = false;
		return Plugin_Handled;
	}

	if(!g_bEnabled) return Plugin_Continue;

	// We need to block the "builtobject" player action during setup
	// This event is created by the superlogs-tf2 plugin and only for mini sentries. All the other buildings use player_builtobject which is blocked from the event.
	if(StrContains(message, ">\" triggered \"builtobject\" (object \"OBJ_SENTRYGUN_MINI\") (position", false) != -1 && Tank_IsInSetup())
	{
		// Note: Cannot check for setup because metamod's log events occur before the CTFGameRules class is ready.
#if defined DEBUG
		PrintToServer("(OnGameLog) BLOCKED superlogs-tf2 \"builtobject\" action!");
#endif
		return Plugin_Handled;
	}

	// Block the "escort_score" log event. This seems to be triggered when a player captures a checkpoint with the bomb and then does not move.
	if(StrContains(message, "\" triggered \"escort_score\"", false) != -1)
	{
#if defined DEBUG
		PrintToServer("(OnGameLog) BLOCKED \"escort_score\" log event!");
#endif
		return Plugin_Handled;
	}

	/*
	int idx = -1;
	int start = 0;
	int len = strlen(message);

	char triggered[] = "\" triggered \"";
	PrintToServer("len = %d", strlen(message));
	// This should return the last instance to prevent a possible match from the player's name.
	while((idx = StrContains(message[start], triggered)) != -1)
	{
		start += idx + (sizeof(triggered)-1);
	}

	if(start != 0)
	{
		// We need one more test to prevent players from forging events, check for the >< after the action name. It should only be present when it matches the player's name.
		if(StrContains(message[start], "><") == -1)
		{
			int end = -1;
			for(int i=start; i<len; i++)
			{
				// Find the ending quote
				if(message[i] == '"')
				{
					end = i;
					break;
				}
			}
			PrintToServer("start = %d end = %d", start, end);
			if(end != -1)
			{
				// We found the missing quote so we can piece together the action triggered
				char action[32];
				int destLen = end-start+1;
				if(destLen >= 0 && destLen <= sizeof(action))
				{
					strcopy(action, destLen, message[start]);

					PrintToServer("Action: \"%s\"", action);
				}
			}
		}
	}
	*/

	return Plugin_Continue;
}

public void Event_CarryObject(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		// Reapply the building blueprint size so the giant engineer can replace the building
		if(Spawner_HasGiantTag(client, GIANTTAG_SCALE_BUILDINGS) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
		{
			int building = GetEventInt(hEvent, "index");
			if(building > MaxClients && GetEntProp(building, Prop_Send, "m_iObjectType") == view_as<int>(TFObject_Sentry))
			{
				RequestFrame(NextFrame_ScaleBuilding, EntIndexToEntRef(building));
			}
		}

		// We have decided to give RED players/ALL players in plr_ a bonus haul speed
		if((GetClientTeam(client) == TFTeam_Red || g_nGameMode == GameMode_Race) && !GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
		{
			Tank_SetAttributeValue(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS, config.LookupFloat(g_hCvarAttribHaulSpeed));
		}
	}
}

public void NextFrame_ScaleBuilding(int buildingRef)
{
	int building = EntRefToEntIndex(buildingRef);
	if(building > MaxClients && GetEntProp(building, Prop_Send, "m_bCarried"))
	{
		// Reapply the building scale so the engineer can place the sentry down
		Building_SetScale(building, 2.0);	
	}
}

public void Event_DropObject(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		Tank_RemoveAttribute(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS);
	}

	if(Tank_IsInSetup())
	{
		// Players can spam the build/destroy command during setup to spawn insane amounts of metal on the ground
		// Disable tf_ammo_pack gibs during setup
		int baseObject = GetEventInt(hEvent, "index");
		if(baseObject > MaxClients)
		{
			CBaseObject_SetNumGibs(baseObject, 0);
		}

		// Block the log message so players do not lose points for destroying buildings during setup.
		if(strcmp(strEventName, "object_detonated") == 0)
		{
			g_blockLogAction = true;
		}
	}
}

void Attributes_Clear(int client)
{
	// This attribute is used by the sentry buster and engineer haul speed
	Tank_RemoveAttribute(client, ATTRIB_MAJOR_MOVE_SPEED_BONUS);

	// This attribute is used by engineers
	Tank_RemoveAttribute(client, ATTRIB_MAXAMMO_METAL_INCREASED);

	// This attribute is used during setup to increase the ubercharge rate.
	Tank_RemoveAttribute(client, ATTRIB_UBERCHARGE_RATE_BONUS);

	// This attribute is used by engineers to speed up teleporter deploy.
	Tank_RemoveAttribute(client, ATTRIB_TELEPORTER_BUILD_RATE_MULTIPLIER);
}

void Attributes_Set(int client)
{
	TFClassType class = TF2_GetPlayerClass(client);
	int team = GetClientTeam(client);

	// BLU team in payload, ALL players in payload race.
	if(team == TFTeam_Blue || g_nGameMode == GameMode_Race)
	{
		switch(class)
		{
			case TFClass_Engineer:
			{
				// Increases engineer teleporter build speed.
				float mult = config.LookupFloat(g_hCvarTeleBuildMult);
				if(mult > 0.0) Tank_SetAttributeValue(client, ATTRIB_TELEPORTER_BUILD_RATE_MULTIPLIER, mult);
			}
		}
	}

	switch(class)
	{
		case TFClass_Medic:
		{
			if(Tank_IsInSetup())
			{
				Tank_SetAttributeValue(client, ATTRIB_UBERCHARGE_RATE_BONUS, SETUP_UBER_CHARG_RATE);
			}
		}
		case TFClass_Engineer:
		{
			// Experiment with giving Engineers increased metal capacity.
			Tank_SetAttributeValue(client, ATTRIB_MAXAMMO_METAL_INCREASED, config.LookupFloat(g_hCvarAttribMetalMult));
			SetEntProp(client, Prop_Send, "m_iAmmo", MaxMetal_Get(client), 4, 3);
		}
	}
}

int Particle_GetTableIndex(const char[] strName)
{
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if(tblidx==INVALID_STRING_TABLE) 
    {
        LogMessage("Could not find string table: ParticleEffectNames!");
        return -1;
    }
    
    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;
    int i;
    for(i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, strName))
        {
            stridx = i;
            break;
        }
    }

    if(stridx==INVALID_STRING_INDEX)
    {
        LogMessage("Could not find particle: %s", strName);
        return -1;
    }

    return stridx;
}

void TE_Particle(int iParticleIndex, float origin[3]=NULL_VECTOR, float start[3]=NULL_VECTOR, float angles[3]=NULL_VECTOR, int entindex=-1, int attachtype=-1, int attachpoint=-1, bool resetParticles=true)
{
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", iParticleIndex);
    TE_WriteNum("entindex", entindex);

    if(attachtype != -1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if(attachpoint != -1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
}

stock void TE_PhysicsProp(int modelIndex, int skin, int flags, int effects, float pos[3])
{
	TE_Start("physicsprop");
	TE_WriteNum("m_nModelIndex", modelIndex);
	TE_WriteNum("m_nSkin", skin);
	TE_WriteNum("m_nFlags", flags);
	TE_WriteNum("m_nEffects", effects);
	TE_WriteVector("m_vecOrigin", pos);
}

public Action TempEntHook_Blood(const char[] te_name, int[] players, int numPlayers, float delay)
{
	if(!g_bEnabled) return Plugin_Continue;
	if(!config.LookupBool(g_hCvarRobot)) return Plugin_Continue;

	int client = TE_ReadNum("entindex");
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(g_nGameMode == GameMode_Race || GetClientTeam(client) == TFTeam_Blue)
		{
			float flOrigin[3]; // I don't think the origin matters, setting the entindex centers it on that entity
			flOrigin[0] = TE_ReadFloat("m_vecOrigin[0]");
			flOrigin[1] = TE_ReadFloat("m_vecOrigin[1]");
			flOrigin[2] = TE_ReadFloat("m_vecOrigin[2]");

			//float flNormal[3];
			//TE_ReadVector("m_vecNormal", flNormal);
			//PrintToServer("m_vecOrigin[%0.3f,%0.3f,%0.3f] m_vecNormal[%0.3f,%0.3f,%0.3f]", flOrigin[0], flOrigin[1], flOrigin[2], flNormal[0], flNormal[1], flNormal[2]);

			// Substitute a nuts and bots particle instead
			if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				if(g_iParticleBotImpactHeavy > -1)
				{
					//TE_Particle(iParticleIndex, Float:origin[3]=NULL_VECTOR, Float:start[3]=NULL_VECTOR, Float:angles[3]=NULL_VECTOR, entindex=-1, attachtype=-1, attachpoint=-1, bool:resetParticles=true)
					TE_Particle(g_iParticleBotImpactHeavy, flOrigin, _, _, client, 0, _, false);
					TE_SendToAll();
				}
			}else{
				if(g_iParticleBotImpactLight > -1)
				{
					TE_Particle(g_iParticleBotImpactLight, flOrigin, _, _, client, 0, _, false);
					TE_SendToAll();
				}
			}

			// Robots don't bleed!
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action TempEntHook_Bleed(const char[] te_name, int[] players, int numPlayers, float delay)
{
	//PrintToServer("m_iEffectName = %d, entindex = %d, m_nMaterial = %d", TE_ReadNum("m_iEffectName"), TE_ReadNum("entindex"), TE_ReadNum("m_nMaterial"));
	if(!g_bEnabled) return Plugin_Continue;

	if(!config.LookupBool(g_hCvarRobot)) return Plugin_Continue;
	if(TE_ReadNum("m_iEffectName") != 2) return Plugin_Continue;

	// Blocks the bleed effects associated with bleed on hit effect weapons

	return Plugin_Stop;
}

public Action TempEntHook_Decal(const char[] te_name, int[] players, int numPlayers, float delay)
{
	if(!g_bEnabled) return Plugin_Continue;
	if(!config.LookupBool(g_hCvarRobot)) return Plugin_Continue;

	// Blocks the blood decals on the walls / nearby entities

	int client = GetClientOfUserId(g_iUserIdLastTrace);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && (g_nGameMode == GameMode_Race || GetClientTeam(client) == TFTeam_Blue))
	{
		if(g_flTimeLastTrace != 0.0 && GetEngineTime() - g_flTimeLastTrace < 0.1) // 0.027 seems to be the highest time difference
		{
			//PrintToChatAll("Blocked blood stain for %N (%f)", client, GetEngineTime() - g_flTimeLastTrace);
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action Tank_OnGameModeUsesUpgrades(bool &result)
{
	if(!g_bEnabled) return Plugin_Continue;

	// This will override the return of GameModeUsesUpgrades only when it is safe to do so (won't crash).
	if(g_bEnableGameModeHook)
	{
		result = true;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void GiantTeleporter_Cleanup(int team)
{
	g_nGiantTeleporter[team][g_iGiantTeleporterRefExit] = 0;
	g_nGiantTeleporter[team][g_nGiantTeleporterState] = TeleporterState_Unconnected;
	ClearArray(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue]);
	g_nGiantTeleporter[team][g_flGiantTeleporterBeamUpdated] = 0.0;
	GiantTeleporter_RemoveParticle(team);
}

void GiantTeleporter_UpdateBeam(int team, int iTeleporter)
{
	if(g_iSpriteBeam == -1 || g_iSpriteHalo == -1) return;

	// Spawn a particle effect / temp ent above the teleporter similar to MvM
	float flPosStart[3];
	GetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", flPosStart);
	flPosStart[2] += 0.0;
	float flPosEnd[3];
	flPosEnd[0] = flPosStart[0];
	flPosEnd[1] = flPosStart[1];
	flPosEnd[2] = flPosStart[2] + 1500.0;

	int iColor[4];
	if(team == TFTeam_Red)
	{
		iColor = {255, 75, 75, 100}; // red
	}else{
		iColor = {75, 75, 255, 100}; // blue
	}

	TE_Start("BeamEntPoint");
	TE_WriteNum("m_nModelIndex", g_iSpriteBeam);
	TE_WriteNum("m_nHaloIndex", g_iSpriteHalo);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 10);
	TE_WriteFloat("m_fLife", 10.0);
	TE_WriteFloat("m_fWidth", 40.0);
	TE_WriteFloat("m_fEndWidth", 50.0);
	TE_WriteNum("m_nFadeLength", 10);
	TE_WriteFloat("m_fAmplitude", 0.5);
	TE_WriteNum("m_nSpeed", 5);
	TE_WriteNum("r", iColor[0]);
	TE_WriteNum("g", iColor[1]);
	TE_WriteNum("b", iColor[2]);
	TE_WriteNum("a", iColor[3]);
	TE_WriteNum("m_nStartEntity", iTeleporter);
	TE_WriteVector("m_vecEndPoint", flPosEnd);
	TE_SendToAll();

	g_nGiantTeleporter[team][g_flGiantTeleporterBeamUpdated] = GetEngineTime();
}

void GiantTeleporter_RemoveParticle(int team)
{
	if(g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle] != 0)
	{
		int particle = EntRefToEntIndex(g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle]);
		if(particle > MaxClients)
		{
			AcceptEntityInput(particle, "Kill");
		}

		g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle] = 0;
	}	
}

void GiantTeleporter_StopParticle(int team)
{
	if(g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle] != 0)
	{
		int particle = EntRefToEntIndex(g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle]);
		if(particle > MaxClients && GetEntProp(particle, Prop_Send, "m_bActive")) AcceptEntityInput(particle, "Stop"); // Check if the particle is started.
	}
}

// The MVM particle looks more pleasing so go ahead and use it for pl.
void GiantTeleporter_UpdateParticle(int team, int teleporter)
{
	if(g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle] != 0)
	{
		int particle = EntRefToEntIndex(g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle]);
		if(particle > MaxClients)
		{
			if(!GetEntProp(particle, Prop_Send, "m_bActive")) // Check if the particle is stopped.
			{
				float pos[3];
				GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

				AcceptEntityInput(particle, "Start");
			}
			return; // Entity exists, do nothing.
		}
	}

	// Create a persistent particle effect above the teleporter.
	int particle = CreateEntityByName("info_particle_system");
	if(particle > MaxClients)
	{
		float pos[3];
		GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", pos);

		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", "teleporter_mvm_bot_persist");
		
		DispatchSpawn(particle);
		ActivateEntity(particle);

		AcceptEntityInput(particle, "Start");
#if defined DEBUG
		PrintToServer("(GiantTeleporter_UpdateParticle) Created info_particle_system: %d!", particle);
#endif
		g_nGiantTeleporter[team][g_iGiantTeleporterRefParticle] = EntIndexToEntRef(particle);
	}
}

void GiantTeleporter_Think(int team)
{
	//PrintToServer("m_iState: %d m_bCarried: %d m_bCarryDeploy: %d m_nForceBone: %d", GetEntProp(iTeleporter, Prop_Send, "m_iState"), GetEntProp(iTeleporter, Prop_Send, "m_bCarried"), GetEntProp(iTeleporter, Prop_Send, "m_bCarryDeploy"), GetEntProp(iTeleporter, Prop_Send, "m_nForceBone"));
	int iTeleporter = EntRefToEntIndex(g_nGiantTeleporter[team][g_iGiantTeleporterRefExit]);
	if(iTeleporter > MaxClients)
	{
		switch(g_nGiantTeleporter[team][g_nGiantTeleporterState])
		{
			case TeleporterState_Unconnected:
			{
				// Teleporter hasn't been linked up so far so check if it can be linked and apply effects if necessary
				if(GetEntProp(iTeleporter, Prop_Send, "m_iState") >= 2) // 1 - fully built | 2 - teleporter ready | 0 - building/being carried
				{
					// Teleporter can be linked
					BroadcastSoundToTeam(team, g_strSoundTeleActivatedTeam[GetRandomInt(0, sizeof(g_strSoundTeleActivatedTeam)-1)]);
					BroadcastSoundToEnemy(team, g_strSoundTeleActivatedEnemy[GetRandomInt(0, sizeof(g_strSoundTeleActivatedEnemy)-1)]);

					if(g_nGameMode == GameMode_Race)
					{
						GiantTeleporter_UpdateBeam(team, iTeleporter);
					}else{
						GiantTeleporter_UpdateParticle(team, iTeleporter);
					}
#if defined DEBUG
					PrintToServer("(GiantTeleporter_Think) Giant teleporter state: connected!");
#endif
					g_nGiantTeleporter[team][g_nGiantTeleporterState] = TeleporterState_Connected;
					ClearArray(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue]);
				}
			}
			case TeleporterState_Connected:
			{
				int teleState = GetEntProp(iTeleporter, Prop_Send, "m_iState");
				// Teleporter should be linked so check if it's not and remove effects if necessary
				if(teleState <= 0) 
				{
					if(g_nGameMode != GameMode_Race)
					{
						GiantTeleporter_StopParticle(team);
					}

					if(!GetEntProp(iTeleporter, Prop_Send, "m_bHasSapper"))
					{
#if defined DEBUG
						PrintToServer("(GiantTeleporter_Think) Giant teleporter state: broken! (m_iState hit 0)");
#endif
						g_nGiantTeleporter[team][g_nGiantTeleporterState] = TeleporterState_Unconnected;
					}
				}else{
					if(teleState >= 2 && !GetEntProp(iTeleporter, Prop_Send, "m_bHasSapper") && !GetEntProp(iTeleporter, Prop_Send, "m_bBuilding"))
					{
						// Tele should be active.
						if(g_nGameMode != GameMode_Race)
						{
							GiantTeleporter_UpdateParticle(team, iTeleporter);
						}						

						float flTime = GetEngineTime();
						if(g_nGameMode == GameMode_Race)
						{
							// Keep the teleporter's beam effect updated
							if(g_nGiantTeleporter[team][g_flGiantTeleporterBeamUpdated] == 0.0 || flTime - g_nGiantTeleporter[team][g_flGiantTeleporterBeamUpdated] > 5.0)
							{
								GiantTeleporter_UpdateBeam(team, iTeleporter);
							}
						}

						if(g_nGiantTeleporter[team][g_flGiantTeleporterLastTeleport] == 0.0 || flTime - g_nGiantTeleporter[team][g_flGiantTeleporterLastTeleport] > 0.4)
						{
							// Teleporter is ready to send players through so work the queue
							for(int i=GetArraySize(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue])-1; i>=0; i--)
							{
								int client = EntRefToEntIndex(GetArrayCell(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue], i));
								if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team && IsPlayerAlive(client))
								{
									EmitSoundToAll(SOUND_DELIVER, client);

									int iBuilder = GetEntPropEnt(iTeleporter, Prop_Send, "m_hBuilder");
									if(iBuilder >= 1 && iBuilder <= MaxClients && IsClientInGame(iBuilder))
									{
										PrintToChat(client, "%t", "Tank_Chat_UsedTeleporter", 0x01, g_strTeamColors[GetClientTeam(iBuilder)], iBuilder, 0x01);
									}else{
										PrintToChat(client, "%t", "Tank_Chat_UsedTeleporter_NoBuilder", 0x01);
									}

									// Give the player a little uber so they can't be tele-camped
									TF2_AddCondition(client, TFCond_UberchargedCanteen, config.LookupFloat(g_hCvarTeleportUber));

									//new iEntrance = GetEntDataEnt2(iExit, 2700);
									//PrintToServer("Before=[State: %d Time: %f Time2: %f Flags: %d", GetEntProp(iEntrance, Prop_Send, "m_iState"), GetEntPropFloat(iEntrance, Prop_Send, "m_flCurrentRechargeDuration"), GetEntPropFloat(iEntrance, Prop_Send, "m_flRechargeTime"), GetEntProp(iEntrance, Prop_Send, "m_fObjectFlags"));

									SDK_TeleporterReceive(iTeleporter, client);
									g_nGiantTeleporter[team][g_flGiantTeleporterLastTeleport] = flTime;

									RemoveFromArray(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue], i);
									break;
								}

								RemoveFromArray(g_nGiantTeleporter[team][g_hGiantTeleporterTeleQueue], i);
							}
						}
					}else{
						// Tele is inactive.

						// Remove the teleporter particle whenever the tele is sapped/disabled.
						if(g_nGameMode != GameMode_Race)
						{
							GiantTeleporter_StopParticle(team);
						}						
					}
				}
			}
		}
	}else{
		// Teleporter doesn't exist anymore so kill the effects
#if defined DEBUG
		PrintToServer("(GiantTeleporter_Think) Giant teleporter state: destroyed!");
#endif
		if(g_nGiantTeleporter[team][g_nGiantTeleporterState] == TeleporterState_Connected)
		{
			BroadcastSoundToTeam(TFTeam_Spectator, "vo/mvm/norm/engineer_mvm_autodestroyedteleporter01.mp3");
		}

		g_nGiantTeleporter[team][g_iGiantTeleporterRefExit] = 0;
		g_nGiantTeleporter[team][g_nGiantTeleporterState] = TeleporterState_Unconnected;
		GiantTeleporter_RemoveParticle(team);
	}
}

void Stats_Reset()
{
	for(int team=2; team<=3; team++)
	{
		for(int i=0; i<MAXPLAYERS+1; i++)
		{
			g_iDamageStatsTank[i][team] = 0;
			g_iDamageAccul[i][team] = 0;
		}
	}

	StatsGiant_Reset();
}

void Tank_PrintLicense()
{
	PrintToServer("======================================================");
	PrintToServer("Stop that Tank!  Copyright (C) 2014-2016  Alex Kowald");
	PrintToServer("This program comes with ABSOLUTELY NO WARRANTY.");
	PrintToServer("This is free software, and you are welcome to");
	PrintToServer("redistribute it under certain conditions.");
	PrintToServer("For details see the included GPLv3 license.");
	PrintToServer("======================================================");
}

public Action CactusCanyon_TrainTouch(int iTrainTrigger, int iToucher)
{
	if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale)
	{
#if defined DEBUG
		PrintToServer("(CactusCanyon_TrainTouch) Touched %d (%d - %d)!", iToucher, EntIndexToEntRef(iToucher), g_iRefTank[TFTeam_Blue]);
#endif
		if(iToucher > MaxClients && g_iRefTank[TFTeam_Blue] != 0 && EntIndexToEntRef(iToucher) == g_iRefTank[TFTeam_Blue])
		{
			// The train has collided with the tank
			// Trigger the map explosion to end the game
			int iCrashRelay = Entity_FindEntityByName("crash_relay", "logic_relay");
			if(iCrashRelay != -1)
			{
#if defined DEBUG
				PrintToServer("(CactusCanyon_TrainTouch) Train hit tank, triggering \"crash_relay\": %d!", iCrashRelay);
#endif
				AcceptEntityInput(iCrashRelay, "Trigger");

				SDKUnhook(iTrainTrigger, SDKHook_StartTouch, CactusCanyon_TrainTouch);				

				/*
				// Before we trigger the "crash_relay" we must bypass the no HUD timer server crash
				// Server crashes because CBaseTeamObjectiveResource::m_iTimerToShowInHUD is set to 0 when SetOwner is called
				new iTimer = FindEntityByClassname(MaxClients+1, "team_round_timer");
				if(iTimer > MaxClients)
				{
					new iObj = FindEntityByClassname(MaxClients+1, "tf_objective_resource");
					if(iObj > MaxClients)
					{
						// Make sure we set the entity index of a valid timer to avoid a server crash
						SetEntProp(iObj, Prop_Send, "m_iTimerToShowInHUD", iTimer);
#if defined DEBUG
						PrintToServer("(CactusCanyon_TrainTouch) Train hit tank, triggering \"crash_relay\": %d!", iCrashRelay);
#endif
						AcceptEntityInput(iCrashRelay, "Trigger");

						SDKUnhook(iTrainTrigger, SDKHook_StartTouch, CactusCanyon_TrainTouch);
					}
				}
				*/
			}
		}else if(g_nGameMode == GameMode_BombDeploy && g_bIsRoundStarted && iToucher >= 1 && iToucher <= MaxClients && IsClientInGame(iToucher) && Tank_GetLastCapturedIndex(TFTeam_Blue) == g_iMaxControlPoints[TFTeam_Blue] - 1)
		{
			int iBomb = EntRefToEntIndex(g_iRefBombFlag);
			if(iBomb > MaxClients && GetEntPropEnt(iBomb, Prop_Send, "moveparent") == iToucher)
			{
				// A bomb carrier has been hit by the train
				// Trigger the map explosion to end the game
				int iCrashRelay = Entity_FindEntityByName("crash_relay", "logic_relay");
				if(iCrashRelay != -1)
				{
#if defined DEBUG
					PrintToServer("(CactusCanyon_TrainTouch) Bomb carrier hit tank, triggering \"crash_relay\": %d!", iCrashRelay);
#endif
					Bomb_Terminate(iBomb, iToucher);

					SDKUnhook(iTrainTrigger, SDKHook_StartTouch, CactusCanyon_TrainTouch);

					AcceptEntityInput(iCrashRelay, "Trigger");

					/*
					// Before we trigger the "crash_relay" we must bypass the no HUD timer server crash
					// Server crashes because CBaseTeamObjectiveResource::m_iTimerToShowInHUD is set to 0 when SetOwner is called
					new iTimer = FindEntityByClassname(MaxClients+1, "team_round_timer");
					if(iTimer > MaxClients)
					{
						new iObj = FindEntityByClassname(MaxClients+1, "tf_objective_resource");
						if(iObj > MaxClients)
						{
							// Make sure we set the entity index of a valid timer to avoid a server crash
							SetEntProp(iObj, Prop_Send, "m_iTimerToShowInHUD", iTimer);
#if defined DEBUG
							PrintToServer("(CactusCanyon_TrainTouch) Bomb carrier hit tank, triggering \"crash_relay\": %d!", iCrashRelay);
#endif
							AcceptEntityInput(iCrashRelay, "Trigger");

							Bomb_Terminate(iBomb, iToucher);

							SDKUnhook(iTrainTrigger, SDKHook_StartTouch, CactusCanyon_TrainTouch);
						}
					}
					*/
				}
			}
		}
	}

	return Plugin_Continue;
}

void CactusCanyon_EnableTrain(bool enable)
{
	if(enable)
	{
		// Enable the train
#if defined DEBUG
		PrintToServer("(CactusCanyon_EnableTrain) Enabling the trains..");
#endif
		// Call the train when the bomb is carried to the final deploy point.
		int iRelay = Entity_FindEntityByName("train_final_pass_loop_relay", "logic_relay");
		if(iRelay != -1)
		{
			AcceptEntityInput(iRelay, "Enable");
			AcceptEntityInput(iRelay, "Trigger");			
		}

		if(!g_bCactusTrainOnce)
		{
			g_bCactusTrainOnce = true;

			iRelay = Entity_FindEntityByName("switch_trains_setup", "logic_relay");
			if(iRelay != -1)
			{
				AcceptEntityInput(iRelay, "Enable");
				AcceptEntityInput(iRelay, "Trigger");
			}
		}
	}else{
		// Disable the train from coming
#if defined DEBUG
		PrintToServer("(CactusCanyon_EnableTrain) Disabling the trains..");
#endif
		// Disable the train from coming when the bomb is outside the final deploy point.
		int iRelay = Entity_FindEntityByName("train_pass_loop_relay", "logic_relay");
		if(iRelay != -1)
		{
			AcceptEntityInput(iRelay, "Disable");
			AcceptEntityInput(iRelay, "CancelPending");
		}

		iRelay = Entity_FindEntityByName("train_final_pass_loop_relay", "logic_relay");
		if(iRelay != -1)
		{
			AcceptEntityInput(iRelay, "Disable");
			AcceptEntityInput(iRelay, "CancelPending");			
		}
	}
}

int CaptureTriggers_Get(int team, int index)
{
	if(g_iRefCaptureTriggers[team][index] != 0)
	{
		int iTrigger = EntRefToEntIndex(g_iRefCaptureTriggers[team][index]);
		if(iTrigger > MaxClients) return iTrigger;

		g_iRefCaptureTriggers[team][index] = 0;
	}

	int iTrigger = CaptureTriggers_Create(team, index);
	if(iTrigger > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(CaptureTriggers_Get) Created \"trigger_capture_area\": %d!", iTrigger);
#endif
		g_iRefCaptureTriggers[team][index] = EntIndexToEntRef(iTrigger);
	}

	return iTrigger;
}

int CaptureTriggers_Create(int team, int index)
{
#if defined DEBUG
	PrintToServer("(CaptureTriggers_Create) team(%d) index(%d) - linked cp(%d)", team, index, EntRefToEntIndex(g_iRefLinkedCPs[team][index]));
#endif
	// Spawn a trigger_capture_area on the given control point entity and attempt to connected it with a control point

	int iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][index]);
	if(iControlPoint <= MaxClients) return -1;

	int iObjective = Obj_Get();
	if(iObjective <= MaxClients) return -1;

	int iTrigger = CreateEntityByName("trigger_capture_area");
	if(iTrigger > MaxClients && IsValidEntity(iTrigger))
	{
		// If we don't first disassociate the cart's trigger_capture_area from the current control point, the HUD will not update properly
		int iCartTrigger = EntRefToEntIndex(g_iRefTrigger[team]);
		if(iCartTrigger > MaxClients)
		{
			SetVariantString(TARGETNAME_NULL); // basically a non-existant targetname
			AcceptEntityInput(iCartTrigger, "SetControlPoint");
		}

		DispatchSpawn(iTrigger);
		ActivateEntity(iTrigger);

		// RED is NOT allowed to cap
		SetVariantString("2 0");
		AcceptEntityInput(iTrigger, "SetTeamCanCap");
		// BLU is allowed to cap
		SetVariantString("3 1");
		AcceptEntityInput(iTrigger, "SetTeamCanCap");
		// Associates the current control point with our new trigger_capture_area
		SetVariantEntity(iControlPoint);
		AcceptEntityInput(iTrigger, "SetControlPoint", iControlPoint, iControlPoint);

		// Update the capture rate on the trigger_capture_area
		float flCaptureTime = config.LookupFloat(g_hCvarBombCaptureRate);
		SetEntPropFloat(iTrigger, Prop_Data, "m_flCapTime", flCaptureTime);
		SetEntProp(iTrigger, Prop_Send, "m_nSolidType", 2); // 6
		SetEntProp(iTrigger, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(iTrigger, Prop_Send, "m_fEffects", 32);

		// Find the absolute origin should the team_control_point be parented.
		float pos[3];
		GetEntPropVector(iControlPoint, Prop_Data, "m_vecAbsOrigin", pos);

		// Teleport the trigger_capture_area onto the control point and set its size
		TeleportEntity(iTrigger, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(iTrigger, MODEL_ROBOT_HOLOGRAM);

		// If the control point is parented, parent the trigger_capture_area to it.
		if(GetEntPropEnt(iControlPoint, Prop_Send, "moveparent") > MaxClients)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iTrigger, "SetParent", iControlPoint);
		}

		float mins[3];
		float maxs[3];
		CaptureArea_GetSize(mins, maxs, index);

		SetEntPropVector(iTrigger, Prop_Send, "m_vecMinsPreScaled", mins);
		SetEntPropVector(iTrigger, Prop_Send, "m_vecMaxsPreScaled", maxs);
		SetEntPropVector(iTrigger, Prop_Send, "m_vecMins", mins);
		SetEntPropVector(iTrigger, Prop_Send, "m_vecMaxs", maxs);

		int iMapperIndex = GetEntProp(iControlPoint, Prop_Data, "m_iPointIndex");
		// You need to do this in order for clients' HUDs to predict the capture rate
		// Mappers have a little control given by the property "Number of RED/BLUE players to cap" on trigger_capture_area
		int iReqCappers = GetEntProp(iObjective, Prop_Send, "m_iTeamReqCappers", _, iMapperIndex + 8 * team);
		SetEntPropFloat(iObjective, Prop_Send, "m_flTeamCapTime", flCaptureTime * float(iReqCappers * 2), iMapperIndex + 8 * team);

		// Tells the client to update the HUD
		int iHudParity = GetEntProp(iObjective, Prop_Send, "m_iUpdateCapHudParity");
		iHudParity = (iHudParity + 1) & CAPHUD_PARITY_MASK;
		SetEntProp(iObjective, Prop_Send, "m_iUpdateCapHudParity", iHudParity);

		// Control point sounds are disabled on most payload maps
		int iFlags = GetEntProp(iControlPoint, Prop_Data, "m_spawnflags");
		iFlags &= ~SF_DISABLE_SOUNDS;
		//SetEntProp(iControlPoint, Prop_Data, "m_spawnflags", iFlags);
		SetEntProp(iControlPoint, Prop_Data, "m_iWarnOnCap", 0); // Susposed to enable announcer warning lines but doesn't seem to have an effect

		SDKHook(iTrigger, SDKHook_StartTouch, CaptureTriggers_StartTouch);

		SetVariantInt(0);
		AcceptEntityInput(iControlPoint, "SetLocked");

		return iTrigger;
	}else{
		LogMessage("Failed to create \"trigger_capture_area\"");
	}

	return -1;
}

void CaptureArea_GetSize(float mins[3], float maxs[3], int pointIndex)
{
	// Search for a capture_size override in stt.cfg.
	for(int i=0,size=g_captureSize.Length; i<size; i++)
	{
		int captureSize[ARRAY_CAPTURESIZE_SIZE];
		g_captureSize.GetArray(i, captureSize, sizeof(captureSize));

		if(captureSize[CaptureSizeArray_PointIndex] == -1 || captureSize[CaptureSizeArray_PointIndex] == pointIndex+1)
		{
#if defined DEBUG
			PrintToServer("(CaptureArea_GetSize) Overrided with index = %d!", captureSize[CaptureSizeArray_PointIndex]);
#endif
			for(int a=0; a<3; a++)
			{
				mins[a] = view_as<float>(captureSize[CaptureSizeArray_Mins+a]);
				maxs[a] = view_as<float>(captureSize[CaptureSizeArray_Maxs+a]);
			}

			return;
		}
	}

	char dim[64];
	config.LookupString(g_hCvarBombCapAreaSize, dim, sizeof(dim));

	char explode[6][24];
	if(ExplodeString(dim, " ", explode, sizeof(explode), sizeof(explode[])) == 6)
	{
		// Use the contents of tank_bomb_capture_size.
		for(int i=0; i<3; i++)
		{
			mins[i] = StringToFloat(explode[i]);
			maxs[i] = StringToFloat(explode[i+3]);
		}
	}else{
		// Fall back on a static value.
		LogMessage("Value of \"tank_bomb_capture_size\" cvar is formatted incorectly. Check your .cfg files!");

		mins[0] = -175.0;
		mins[1] = -175.0;
		mins[2] = -50.0;

		maxs[0] = 175.0;
		maxs[1] = 175.0;
		maxs[2] = 125.0;
	}
}

int CaptureZones_Get(int team, int index)
{
	if(g_iRefCaptureZones[team] != 0)
	{
		int capture = EntRefToEntIndex(g_iRefCaptureZones[team]);
		if(capture > MaxClients) return capture;

		g_iRefCaptureZones[team] = 0;
	}

	int capture = CaptureZones_Create(team, index);
	if(capture > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(CaptureZones_Get) Created \"func_capturezone\": %d!", capture);
#endif
		g_iRefCaptureZones[team] = EntIndexToEntRef(capture);
	}

	return capture;
}

int CaptureZones_Create(int team, int index)
{	
	// This entity acts as a hint for bots so they will try to capture control points and deploy the bomb. Otherwise, they won't have an objective.
	int iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][index]);
	if(iControlPoint <= MaxClients) return -1;

	int capture = CreateEntityByName("func_capturezone");
	if(capture > MaxClients)
	{
		SetEntProp(capture, Prop_Data, "m_nCapturePoint", index+1);
		SetEntProp(capture, Prop_Data, "m_iInitialTeamNum", team);

		DispatchSpawn(capture);
		ActivateEntity(capture);

		float pos[3];
		GetEntPropVector(iControlPoint, Prop_Send, "m_vecOrigin", pos);

		// Find the absolute origin should the team_control_point be parented.
		int parent = iControlPoint;
		for(int i=0; i<12; i++)
		{
			parent = GetEntPropEnt(parent, Prop_Send, "moveparent");
			if(parent <= 0) break;

			float parentPos[3];
			GetEntPropVector(parent, Prop_Send, "m_vecOrigin", parentPos);
			for(int j=0; j<3; j++) pos[j] += parentPos[j];
		}

		TeleportEntity(capture, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(capture, MODEL_ROBOT_HOLOGRAM);

		// If the control point is parented, parent the func_capturezone to it.
		if(GetEntPropEnt(iControlPoint, Prop_Send, "moveparent") > MaxClients)
		{
			SetVariantString("!activator");
			AcceptEntityInput(capture, "SetParent", iControlPoint);
		}

		float mins[3];
		float maxs[3];

		if(g_iRefLinkedCPs[team][index] == g_iRefControlPointGoal[team])
		{
			// We are at the final control point - use a smaller size.
			float boxSize = 100.0;

			mins[0] = boxSize*-1.0;
			mins[1] = boxSize*-1.0;
			mins[2] = -50.0;

			maxs[0] = boxSize;
			maxs[1] = boxSize;
			maxs[2] = 125.0;
		}else{
			// Use the same size as the trigger_capture_area's.
			CaptureArea_GetSize(mins, maxs, index);
		}

		SetEntPropVector(capture, Prop_Send, "m_vecMinsPreScaled", mins);
		SetEntPropVector(capture, Prop_Send, "m_vecMaxsPreScaled", maxs);
		SetEntPropVector(capture, Prop_Send, "m_vecMins", mins);
		SetEntPropVector(capture, Prop_Send, "m_vecMaxs", maxs);

		return capture;
	}else{
		LogMessage("Failed to create \"func_capturezone\"");
	}

	return -1;
}

public Action CaptureTriggers_StartTouch(int iTrigger, int client)
{
	// Block anyone on BLU from capturing except for the bomb carrier
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TFTeam_Blue)
	{
		// Check if they are the bomb carrier
		int iBomb = EntRefToEntIndex(g_iRefBombFlag);
		if(iBomb > MaxClients)
		{
			if(GetEntPropEnt(iBomb, Prop_Send, "moveparent") == client) return Plugin_Continue;
		}

		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Event_PointCaptured(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_PointCaptured) cp: %d team: %d!", GetEventInt(hEvent, "cp"), GetEventInt(hEvent, "team"));
#endif
	// The robots have capture a control point so move the cart up.
	if(!g_bEnabled) return;

	if(!g_bIsRoundStarted || g_nGameMode != GameMode_BombDeploy) return;

	int team = GetEventInt(hEvent, "team");
	if(team != TFTeam_Blue) return;

	// Find the index of the control point which was just capped (the event key "cp" will report the cp's index keyvalue).
	// Go backwards to find the first captured control point.
	int iIndexCP = -1;
	int iCaptureTrigger, iControlPoint, iPathTrack;
	for(int i=MAX_LINKS-1; i>=0; i--)
	{
		if(g_iRefLinkedPaths[team][i] == 0 || g_iRefLinkedCPs[team][i] == 0) continue;

		iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
		iCaptureTrigger = EntRefToEntIndex(g_iRefCaptureTriggers[team][i]);
		iPathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][i]);

		if(iControlPoint <= MaxClients || iCaptureTrigger <= MaxClients || iPathTrack <= MaxClients) continue;
		if(g_iRefLinkedCPs[team][i] == g_iRefControlPointGoal[team]) continue;

		if(GetEntProp(iControlPoint, Prop_Send, "m_iTeamNum") != team) continue; // Control point has not yet been captured.

		// We've found the control point and custom trigger_capture_area for the next control point.
		iIndexCP = i;
		break;
	}

#if defined DEBUG
	PrintToServer("(Event_PointCaptured) Control point index #%d was captured: cp(%d)!", iIndexCP, iControlPoint);
#endif

	if(iIndexCP == -1) // Failed to find a valid control point.
	{
		return;
	}

	// Determine the cappers - this should only be one person - the BLU bomb carrier.
	char strCappers[32];
	GetEventString(hEvent, "cappers", strCappers, sizeof(strCappers));
	int iLength = strlen(strCappers);
	int client = -1;
	for(int i=0; i<iLength; i++)
	{
		if(IsClientInGame(strCappers[i]))
		{
			client = strCappers[i];
			break;
		}
	}
	if(client < 1 || client > MaxClients || !IsClientInGame(client)) return;

	BroadcastSoundToTeam(TFTeam_Spectator, "harbor.blue_whistle");

	if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale && iIndexCP == 1)
	{
		// If last control point is captured by the bomb carrier, do not activate the relay that causes the cart to move forward.
		int relay = Entity_FindEntityByName("changer_relay", "logic_relay");
		if(relay != -1)
		{
#if defined DEBUG
			PrintToServer("(Event_PointCaptured) Disabling \"changer_relay\" so that the cart won't move forward!");
#endif
			AcceptEntityInput(relay, "Disable");
		}
	}

	// Capture the control point.
	int iTrackTrain = EntRefToEntIndex(g_iRefTrackTrain[team]);
	if(iTrackTrain > MaxClients)
	{
		AcceptEntityInput(iPathTrack, "InPass", iTrackTrain);
	}

	// The control point should now be capped and the code will move on to the next control point
	g_flBombPlantStart = 0.0; // Reset the bomb plant time to ensure this capping code is only ran once

	// Move the train to the captured control point
	g_iCurrentControlPoint[team] = iIndexCP+1; // This tracks tank health checkpoints if more tanks will spawn
	Train_MoveTo(iTrackTrain, iPathTrack);

	// Send the player an annotation guiding them to the next control point
	// I've duplicated this code because it needs to show the next control point and this think code won't pick up the capture until a few more frames
	int iIndexNext = iIndexCP+1;
	if(iIndexNext >= 0 && iIndexNext < MAX_LINKS && g_iRefLinkedCPs[team][iIndexNext] != 0 && g_iRefLinkedPaths[team][iIndexNext] != 0)
	{
		if(g_nMapHack == MapHack_Borneo && iIndexNext == 3 && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") && GetEntPropFloat(client, Prop_Send, "m_flModelScale") >= 1.6)
		{
			// It is not obvious that the giant can fit through the doorway on the penultimate control point.
			// Let the giant know to take the alternative path.
			Borneo_ShowAlternativeRoute(client);
		}else{
			Giant_ShowGuidingAnnotation(client, team, iIndexNext);
		}

		g_flBombLastMessage = GetEngineTime();
	}

	// Add time to the bomb round timer
	int iTimer = EntRefToEntIndex(g_iRefBombTimer);
	if(iTimer > MaxClients)
	{
		g_flBombGameEnd = 0.0; // Clear the bomb time end so that the game doesn't end on the next frame

		SetVariantInt(config.LookupInt(g_hCvarBombTimeAdd));
		AcceptEntityInput(iTimer, "AddTime");
	}

	// Log the deployment so hlstats can pick it up
	char strAuth[32];
	GetClientAuthId(client, AuthId_Steam3, strAuth, sizeof(strAuth));
	LogToGame("\"%N<%d><%s><%s>\" triggered \"bomb_capture\"", client, GetClientUserId(client), strAuth, g_strTeamClass[GetClientTeam(client)]);

	// Delete the func_capturezone to ensure one is created on the goal.
	CaptureZones_Cleanup(team);
}

void CaptureTriggers_Cleanup(int team)
{
	for(int i=0; i<MAX_LINKS; i++)
	{
		if(g_iRefCaptureTriggers[team][i] != 0)
		{
			int iTrigger = EntRefToEntIndex(g_iRefCaptureTriggers[team][i]);
			if(iTrigger > MaxClients)
			{
				AcceptEntityInput(iTrigger, "Kill");
			}

			g_iRefCaptureTriggers[team][i] = 0;
		}
	}
}

void CaptureZones_Cleanup(int team)
{
	if(g_iRefCaptureZones[team] != 0)
	{
		int capture = EntRefToEntIndex(g_iRefCaptureZones[team]);
		if(capture > MaxClients)
		{
			AcceptEntityInput(capture, "Kill");
		}

		g_iRefCaptureZones[team] = 0;
	}
}

int Obj_Get()
{
	if(g_iRefObj != 0)
	{
		int iObj = EntRefToEntIndex(g_iRefObj);
		if(iObj > MaxClients)
		{
			return iObj;
		}

		g_iRefObj = 0;
	}

	int iObj = FindEntityByClassname(MaxClients+1, "tf_objective_resource");
	if(iObj > MaxClients)
	{
		g_iRefObj = EntIndexToEntRef(iObj);
	}

	return iObj;
}

void BombRound_Init()
{
	// Called when the round enters a bomb round
	CaptureTriggers_Cleanup(TFTeam_Blue);
	CaptureZones_Cleanup(TFTeam_Blue);
}

bool Tank_IsInSetup()
{
	return view_as<bool>(GameRules_GetProp("m_bInSetup", 1));
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!g_bEnabled) return;

	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(strncmp(sArgs, "!giant", 6, false) == 0)
		{
			Giant_ShowMain(client);
		}
	}
}

int Tank_GetLastCapturedIndex(int team)
{
	// Go backwards to find the first captured control point
	int iIndex = -1;
	for(int i=MAX_LINKS-1; i>=0; i--)
	{
		if(g_iRefLinkedPaths[team][i] == 0 || g_iRefLinkedCPs[team][i] == 0) continue;

		int iControlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
		int iPathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][i]);

		if(iControlPoint <= MaxClients || iPathTrack <= MaxClients) continue;
		if(g_iRefLinkedCPs[team][i] == g_iRefControlPointGoal[team]) continue;
		bool bCaptured = (GetEntProp(iControlPoint, Prop_Send, "m_iTeamNum") == team);

		if(!bCaptured) continue;

		// We've found the control point and custom trigger_capture_area for the next control point
		iIndex = i;
		break;
	}

	return iIndex;
}

public Action Timer_ShowTip(Handle hTimer)
{
	if(!g_bEnabled) return Plugin_Continue;

	// Show players a helpful tip in chat
	// Pick a random phrase from stt.cfg

	if(g_chatTips.Length <= 0) return Plugin_Continue; // No phrases have been set!

	char tip[MAXLEN_CHAT_TIP];
	g_chatTips.GetString(GetRandomInt(0, g_chatTips.Length-1), tip, sizeof(tip));

	PrintToChatAll("%t", "Tank_Chat_Tip", "\x073B5998", 0x01, tip);

	return Plugin_Continue;
}

int MaxMetal_Get(int client)
{
	int maxMetal = SDK_GetMaxAmmo(client, 3); // Weapon slots began at 1 when calling GetMaxAmmo
	if(maxMetal <= 0) return 200;

	return maxMetal;
}

int PushAway_Create(float pos[3], float timeCleanup=4.0)
{
	// Spawn the particle and push away entity to keep the area clear
	// Spawn a point_push first so players won't clip with the tank/bomb
	int iEntity = CreateEntityByName("point_push");
	if(iEntity > MaxClients)
	{
		DispatchKeyValue(iEntity, "enabled", "1");
		DispatchKeyValue(iEntity, "magnitude", "1000.0");
		DispatchKeyValue(iEntity, "radius", "270.0");
		DispatchKeyValue(iEntity, "inner_radius", "200.0");
		DispatchKeyValue(iEntity, "spawnflags", "8");
		
		DispatchSpawn(iEntity);
		
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "TurnOn");
		
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Enable");
		
		TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
		
		CreateTimer(timeCleanup, Timer_EntityCleanup, EntIndexToEntRef(iEntity));
	}

	return iEntity;
}

/* 
 * Adjusts the output speed of the tank based on the inputs of how close the tank and cart are to the current path_track node.
 * 	
 */
void Tank_Controller(int team, int tank, int cart)
{
	static float minError = -10.0;
	static float maxError = 10.0;
	static float Kp = 0.1;

	float trainSpeed = GetEntPropFloat(cart, Prop_Data, "m_flSpeed");

	// If the cart isn't moving, don't try and correct the tank's position.
	if(trainSpeed <= 0.0)
	{
		SetEntPropFloat(tank, Prop_Data, "m_speed", 0.0);
		//PrintCenterTextAll("Cart not moving!\nNew speed: 0.0");
		return;
	}
	
	int currentPath = Train_GetCurrentPath(team);
	if(currentPath > MaxClients)
	{
		float currentPathPos[3];
		GetEntPropVector(currentPath, Prop_Send, "m_vecOrigin", currentPathPos);
		float tankPos[3];
		GetEntPropVector(tank, Prop_Send, "m_vecOrigin", tankPos);
		float cartPos[3];
		GetEntPropVector(cart, Prop_Send, "m_vecOrigin", cartPos);

		tankPos[2] = cartPos[2];
		float error = Kp * GetVectorDistance(tankPos, cartPos);

		tankPos[2] = currentPathPos[2];
		cartPos[2] = currentPathPos[2];

		float tankDist = GetVectorDistance(currentPathPos, tankPos);
		float cartDist = GetVectorDistance(currentPathPos, cartPos);

		if(tankDist > cartDist)
		{
			// The tank is further along than the cart (the cart is falling behind)
			error *= -1.0;
		}

		if(error < minError) error = minError;
		else if(error > maxError) error = maxError;

		float tankSpeed = trainSpeed + error;
		SetEntPropFloat(tank, Prop_Data, "m_speed", tankSpeed);

		//PrintCenterTextAll("Error: %1.4f\nNew speed: %1.4f", error, tankSpeed);
	}
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(teleporter > MaxClients && client >= 1 && client <= MaxClients)
	{
		if(GetEntProp(teleporter, Prop_Send, "m_iObjectMode") != view_as<int>(TFObjectMode_Entrance)) return Plugin_Continue; // This gets called when the player stands on the exit as well

		// Block giants and players that are becoming a giant from taking the teleporter. This lasts around 5 seconds.
		if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] == Spawn_GiantRobot)
		{
			// Allow the Super Spy to take the teleporter after he spawns in.
			if(!(g_nGiants[g_nSpawner[client][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_CAN_DROP_BOMB) || !GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
			{
				result = false;
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action Command_ResetBomb(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(g_nGameMode != GameMode_BombDeploy)
	{
		ReplyToCommand(client, "This command may only be used during the bomb-deploy period.");
		return Plugin_Handled;
	}

	int bomb = EntRefToEntIndex(g_iRefBombFlag);
	if(bomb > MaxClients)
	{
		ShowActivity2(client, "[SM] ", "%N reset the bomb.", client);
		AcceptEntityInput(bomb, "ForceReset");
	}else{
		ReplyToCommand(client, "Failed to find the \"item_teamflag\" bomb entity.");
	}

	return Plugin_Handled;
}

public Action Command_Info(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	ReplyToCommand(client, "Check console for information.");

	char reply[1024];

	Format(reply, sizeof(reply), "==================================================\n==================================================\n");
	Format(reply, sizeof(reply), "%spath_track start/end for the CURRENT stage:\n", reply);

	char name[128];

	for(int team=2; team<=3; team++)
	{
		if(team == TFTeam_Red)
		{
			Format(reply, sizeof(reply), "%s> Team RED:\n", reply);
		}else{
			Format(reply, sizeof(reply), "%s> Team BLU:\n", reply);
		}

		int startNode = EntRefToEntIndex(g_iRefPathStart[team]);
		if(startNode > MaxClients)
		{
			GetEntPropString(startNode, Prop_Data, "m_iName", name, sizeof(name));
			Format(reply, sizeof(reply), "%s  Path start: %s\n", reply, name);
		}

		int endNode = EntRefToEntIndex(g_iRefPathGoal[team]);
		if(endNode > MaxClients)
		{
			GetEntPropString(endNode, Prop_Data, "m_iName", name, sizeof(name));
			Format(reply, sizeof(reply), "%s  Path end: %s\n", reply, name);
		}

		Format(reply, sizeof(reply), "%s  Total distance: %f\n", reply, g_flPathTotalDistance[team]);

		int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
		if(watcher > MaxClients)
		{
			Format(reply, sizeof(reply), "%s  Train progress %%%%: %f\n", reply, GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress"));
		}
	}

	Format(reply, sizeof(reply), "%s==================================================\n==================================================", reply);
	PrintToConsole(client, reply);

	return Plugin_Handled;
}

/**
 * Increments a player's score by the given amount.
 *
 * @param client 	Client index.
 * @param score 	Amount to increment. Set to negative to subtract points.
 */
void Score_IncrementBonusPoints(int client, int score)
{
	// This increments the player's bonus points stat by using the sandman's stun bonus stat.
	// This allows us to modify the player's total score in increments of 1. Additionally, I can remove points by passing a negative number!
	Tank_IncrementStat(client, TFStat_PlayerStunBall, score * 10);

	// You may be wondering why I choose to do it this way.
	// There's not a consistent function for modifying revive stats in linux and windows.
	// I needed to block revive points and award points for a handful of game actions so this one method fits the bill. 
}

/**
 * Sets how many tf_ammo_pack gibs spawn when a CBaseObject is destroyed.
 *
 * @param object 	Entity index of the CBaseObject.
 * @param numGibs 	Number of gibs to spawn. Note: Setting this to more than 4 may crash the server.
 */
void CBaseObject_SetNumGibs(int baseObject, int numGibs)
{
	if(g_iOffset_m_numGibs <= 0) return;

	SetEntData(baseObject, g_iOffset_m_numGibs, numGibs, 4);
}

void Settings_Load(int client)
{
	Settings_Clear(client);

	if(IsFakeClient(client)) return;

	char cookie[12];

	GetClientCookie(client, g_cookieInfoPanel, cookie, sizeof(cookie));
	if(strlen(cookie) > 0)
	{
		g_settings[client][g_settingsShowInfoPanel] = StringToInt(cookie);
	}
}

bool Settings_ShouldShowGiantInfoPanel(int client)
{
	switch(g_settings[client][g_settingsShowInfoPanel])
	{
		case ShowInfoPanel_PayloadOnly: return (g_nGameMode != GameMode_Race);
		case ShowInfoPanel_PayloadRaceOnly: return (g_nGameMode == GameMode_Race);
		case ShowInfoPanel_Never: return false;
	}

	return true; // Always show.
}

void Settings_Clear(int client)
{
	// Set the default value for each setting here..
	g_settings[client][g_settingsShowInfoPanel] = ShowInfoPanel_PayloadOnly;
}

public void Settings_ItemSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_SelectOption)
	{
		Settings_MainMenu(client);
	}
}

void Settings_MainMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_SettingsMain);

	SetMenuTitle(menu, "%T", "Tank_Menu_Settings_Title", client);

	char buffer[256];
	char trans[64];
	switch(g_settings[client][g_settingsShowInfoPanel])
	{
		case ShowInfoPanel_PayloadOnly: trans = "Tank_Menu_Settings_ShowGiantInfoPanel_State_PayloadOnly";
		case ShowInfoPanel_PayloadRaceOnly: trans = "Tank_Menu_Settings_ShowGiantInfoPanel_State_PayloadRaceOnly";
		case ShowInfoPanel_Never: trans = "Tank_Menu_Settings_ShowGiantInfoPanel_State_Never";
		default: trans = "Tank_Menu_Settings_ShowGiantInfoPanel_State_AlwaysShow";
	}

	Format(buffer, sizeof(buffer), "%T", "Tank_Menu_Settings_ShowGiantInfoPanel", client, trans, client);
	AddMenuItem(menu, "", buffer);

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SettingsMain(Menu menu, MenuAction action, int client, int menu_item)
{
	if(action == MenuAction_Select)
	{
		enum
		{
			MainMenu_InfoPanel=0
		};

		switch(menu_item)
		{
			case MainMenu_InfoPanel:
			{
				// Toggle the value of the info panel setting.
				g_settings[client][g_settingsShowInfoPanel]++;

				if(g_settings[client][g_settingsShowInfoPanel] < 0 || g_settings[client][g_settingsShowInfoPanel] > MAX_SHOW_INFO_PANEL) g_settings[client][g_settingsShowInfoPanel] = ShowInfoPanel_Always;
				
				char cookie[12];
				IntToString(g_settings[client][g_settingsShowInfoPanel], cookie, sizeof(cookie));
				SetClientCookie(client, g_cookieInfoPanel, cookie);
			}
		}

		Settings_MainMenu(client);
	}else if(action == MenuAction_Cancel)
	{
		if(menu_item == MenuCancel_ExitBack) ShowCookieMenu(client);
	}else if(action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Listener_TeamName(int client, const char[] command, int argc)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(g_nGameMode != GameMode_Race) return Plugin_Continue; // Only allow name changing in tank race
	if(client < 1 || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;

	if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		// Only allow team name changes during the waiting for players state
		return Plugin_Continue;
	}

	int team = GetClientTeam(client);
	if(team != TFTeam_Red && team != TFTeam_Blue) return Plugin_Continue;

	char defaultName[32];
	if(g_nGameMode == GameMode_Race)
	{
		if(team == TFTeam_Red)
		{
			config.LookupString(g_hCvarTeamRedPlr, defaultName, sizeof(defaultName));
		}else{
			config.LookupString(g_hCvarTeamBluePlr, defaultName, sizeof(defaultName));
		}
	}else{
		if(team == TFTeam_Red)
		{
			config.LookupString(g_hCvarTeamRed, defaultName, sizeof(defaultName));
		}else{
			config.LookupString(g_hCvarTeamBlue, defaultName, sizeof(defaultName));
		}
	}

	char name[7]; // Tournament GUI only allows 5 characters, I will allow up to 6 for people smart enough to use the command.
	GetCmdArgString(name, sizeof(name));

	Handle cvarName = g_cvar_blueTeamName;
	if(team == TFTeam_Red) cvarName = g_cvar_redTeamName;

	char current[32];
	config.LookupString(cvarName, current, sizeof(current));
	// Block the change if that change is just going to be cutting off the default team name.
	if(strcmp(defaultName, current) == 0)
	{
		if(strncmp(name, defaultName, 6, false) == 0)
		{
			return Plugin_Continue;
		}
	}

	SetConVarString(cvarName, name, true, true);

	return Plugin_Continue;
}

void Tournament_RestoreNames()
{
	char name[32];
	if(g_nGameMode == GameMode_Race)
	{
		config.LookupString(g_hCvarTeamRedPlr, name, sizeof(name));
		SetConVarString(FindConVar("mp_tournament_redteamname"), name);

		config.LookupString(g_hCvarTeamBluePlr, name, sizeof(name));
		SetConVarString(FindConVar("mp_tournament_blueteamname"), name);
	}else{
		config.LookupString(g_hCvarTeamRed, name, sizeof(name));
		SetConVarString(FindConVar("mp_tournament_redteamname"), name);

		config.LookupString(g_hCvarTeamBlue, name, sizeof(name));
		SetConVarString(FindConVar("mp_tournament_blueteamname"), name);
	}
}

void Tank_OnRankUp()
{
	EmitSoundToAll(SOUND_TANK_RANKUP);
	Tank_FireworkEffects();

	CreateTimer(1.0, Timer_TankRankEffects, 4, TIMER_FLAG_NO_MAPCHANGE);

	// Put a disco ball above the tank
	for(int team=2; team<=3; team++)
	{
		int train = EntRefToEntIndex(g_iRefTrackTrain[team]);
		if(train > MaxClients)
		{
			int disco = CreateEntityByName("info_particle_system");
			if(disco > MaxClients)
			{
				DispatchKeyValue(disco, "effect_name", "utaunt_disco_party");
				SetEntPropEnt(disco, Prop_Send, "m_hOwnerEntity", train);

				DispatchSpawn(disco);
				ActivateEntity(disco);
				AcceptEntityInput(disco, "Start");

				float pos[3];
				pos[2] = -10000.0;
				TeleportEntity(disco, pos, NULL_VECTOR, NULL_VECTOR);

				CreateTimer(1.0, Timer_DiscoFix, EntIndexToEntRef(disco), TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(7.0, Timer_EntityCleanup, EntIndexToEntRef(disco));
			}
		}
	}
}

public Action Timer_DiscoFix(Handle timer, int ref)
{
	// The particle doesn't show correctly until a few moments after it is activated.
	int disco = EntRefToEntIndex(ref);
	if(disco > MaxClients)
	{
		int train = GetEntPropEnt(disco, Prop_Send, "m_hOwnerEntity");
		if(train > MaxClients)
		{
			float pos[3];
			GetEntPropVector(train, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 100.0;
			TeleportEntity(disco, pos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(disco, "SetParent", train);
		}
	}

	return Plugin_Handled;
}

public Action Timer_TankRankEffects(Handle timer, int numTimes)
{
	Tank_FireworkEffects();

	if(--numTimes > 0)
	{
		CreateTimer(GetRandomFloat(0.8, 1.5), Timer_TankRankEffects, numTimes, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

void Tank_FireworkEffects()
{
	if(g_iParticleFireworks[TFTeam_Red] == -1 || g_iParticleFireworks[TFTeam_Blue] == -1) return;

	EmitGameSoundToAll("Summer.Fireworks");

	// Spawns fireworks near all the trains
	for(int team=2; team<=3; team++)
	{
		int train = EntRefToEntIndex(g_iRefTrackTrain[team]);
		if(train > MaxClients)
		{
			float pos[3];
			GetEntPropVector(train, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 100.0;
			float ang[3];
			GetEntPropVector(train, Prop_Send, "m_angRotation", ang);

			float posFireworks[3];
			GetPositionForward(pos, ang, posFireworks, GetRandomFloat(-70.0, 90.0));

			int index = g_iParticleFireworks[TFTeam_Red];
			if(team == TFTeam_Blue) index = g_iParticleFireworks[TFTeam_Blue];

			TE_Particle(index, posFireworks);
			TE_SendToAll();

			pos[0] += GetRandomFloat(-150.0, 150.0);
			pos[1] += GetRandomFloat(-150.0, 150.0);
			TE_Particle(g_iParticleFetti, pos);
			TE_SendToAll();
		}
	}
}

void ShowGameMessage(const char[] message, const char[] icon="hud_taunt_hint", float time=5.0, int displayToTeam=0, int teamColor=0)
{
	int msg = CreateEntityByName("game_text_tf");
	if(msg > MaxClients)
	{
		DispatchKeyValue(msg, "message", message);
		switch(displayToTeam)
		{
			case 2: DispatchKeyValue(msg, "display_to_team", "2");
			case 3: DispatchKeyValue(msg, "display_to_team", "3");
			default: DispatchKeyValue(msg, "display_to_team", "0");
		}
		switch(teamColor)
		{
			case 2: DispatchKeyValue(msg, "background", "2");
			case 3: DispatchKeyValue(msg, "background", "3");
			default: DispatchKeyValue(msg, "background", "0");
		}
		DispatchKeyValue(msg, "icon", icon);
		DispatchSpawn(msg);

		AcceptEntityInput(msg, "Display");

		SetEntPropFloat(msg, Prop_Data, "m_flAnimTime", GetEngineTime()+time);

		CreateTimer(0.5, Timer_ShowGameMessage, EntIndexToEntRef(msg), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public Action Timer_ShowGameMessage(Handle timer, int ref)
{
	int msg = EntRefToEntIndex(ref);
	if(msg > MaxClients)
	{
		if(GetEngineTime() > GetEntPropFloat(msg, Prop_Data, "m_flAnimTime"))
		{
			AcceptEntityInput(msg, "Kill");
			return Plugin_Stop;
		}

		AcceptEntityInput(msg, "Display");
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

void Hell_KillGateTimer()
{
	if(g_hellGateTimer != INVALID_HANDLE)
	{
		KillTimer(g_hellGateTimer);
		g_hellGateTimer = INVALID_HANDLE;
	}
}

public Action Timer_GatesOfHell(Handle timer, any unused)
{
	// Since we are spawning an extra giant in hell, extend the period of time before the gates open to give players more time to battle.
	int relay = Entity_FindEntityByName(HELL_GATES_TARGETNAME, "logic_relay");
	if(relay != -1)
	{
		AcceptEntityInput(relay, "Enable");
		AcceptEntityInput(relay, "Trigger");
#if defined DEBUG
		PrintToServer("(Timer_GatesOfHell) Opened the gates of hell: %d", relay);
#endif
	}

	// Show a helpful annotation of what to do in hell.
	Handle event = CreateEvent("show_annotation");
	if(event != INVALID_HANDLE)
	{
		float pos[3] = {-201.50, 489.36, -8329.50};

		SetEventInt(event, "id", Annotation_HellHint);
		SetEventFloat(event, "worldPosX", pos[0]);
		SetEventFloat(event, "worldPosY", pos[1]);
		SetEventFloat(event, "worldPosZ", pos[2]);
		
		SetEventInt(event, "visibilityBitfield", 0); // Show to everyone.

		char text[256];		
		Format(text, sizeof(text), "%T", "Tank_Annotation_HellHint", LANG_SERVER);
		SetEventString(event, "text", text);

		SetEventFloat(event, "lifetime", 7.0);
		SetEventString(event, "play_sound", "misc/null.wav");
		
		FireEvent(event); // Frees the handle.
	}

	g_hellGateTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public void Event_ObjectDestroyed(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!g_bEnabled) return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker >= 1 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		TFObjectType type = view_as<TFObjectType>(GetEventInt(event, "objecttype"));
		if(type != TFObject_Sapper)
		{
			RageMeter_OnDamageDealt(attacker);
		}
	}
}

void Parent_Think(int tank, int team, float distanceToGoal, float distanceParent, float totalProgress)
{
	for(int i=g_parentList.Length-1; i>=0; i--)
	{
		int array[ARRAY_PARENT_SIZE];
		g_parentList.GetArray(i, array, ARRAY_PARENT_SIZE);
		if(array[ParentArray_Team] == 0 || array[ParentArray_Team] == team)
		{
			float location = view_as<float>(array[ParentArray_Location]);
			if(totalProgress >= location)
			{
#if defined DEBUG
				PrintToServer("(Parent_Think) Hit parent config at %f - type %d", location, array[ParentArray_Type]);
#endif
				g_parentList.Erase(i);

				if(g_bRaceParentedForHill[team]) continue; // The parenting is already being controlled for uphill paths. Give it precedence over user config.
				if(distanceToGoal < distanceParent) continue; // The tank is near enough to the goal that it will be parented anyway.

				if(array[ParentArray_Type] == ParentType_Start)
				{
					// The tank needs to be parented.
					if(GetEntPropEnt(tank, Prop_Send, "moveparent") == -1) // Check to make sure we aren't already parented.
					{
						Tank_Parent(team);
					}
				}else{
					// The tank needs to be un-parented.
					if(GetEntPropEnt(tank, Prop_Send, "moveparent") > MaxClients) // Check to make sure we aren't already parented.
					{
						Tank_UnParent(team);
					}
				}
			}
		}
	}
}

bool Float_AlmostEqual(float one, float two)
{
	// FloatCompare returns -1 if the first argument is smaller than the second argument.
	return (FloatCompare(FloatAbs(FloatSub(one, two)), EPSILON) == -1);
}

void Timer_KillFailsafe()
{
	if(g_timerFailsafe != INVALID_HANDLE)
	{
		KillTimer(g_timerFailsafe);
		g_timerFailsafe = INVALID_HANDLE;
	}
}

void Timer_KillCountdown()
{
	if(g_timerCountdown != INVALID_HANDLE)
	{
		KillTimer(g_timerCountdown);
		g_timerCountdown = INVALID_HANDLE;
	}	
}

void Timer_KillAnnounce()
{
	if(g_timerAnnounce != INVALID_HANDLE)
	{
		KillTimer(g_timerAnnounce);
		g_timerAnnounce = INVALID_HANDLE;
	}	
}

void Timers_KillAll()
{
	Timer_KillFailsafe();
	Timer_KillCountdown();
	Timer_KillStart();
	Timer_KillAnnounce();

	Hell_KillGateTimer();
}

public Action Timer_Failsafe(Handle timer, any unused)
{
#if defined DEBUG
	PrintToServer("(Timer_Failsafe)");
#endif
	// We've waited for a second after the tank is destroyed, now resume round logic.

	// There's a rare bug that the tank can stick around even after the OnKilled output is called.
	// This will just make sure the tank is removed. Therefore, the Tank_Think logic won't run and the cart won't move.
	int tank = EntRefToEntIndex(g_iRefTank[TFTeam_Blue]);
	if(tank > MaxClients)
	{
		SetVariantInt(MAX_TANK_HEALTH);
		AcceptEntityInput(tank, "RemoveHealth");
		AcceptEntityInput(tank, "Kill");

		LogMessage("Wow, you hit a rare bug where the tank stuck around after the OnKilled output. Congrats!");
	}

	// Check to see if the cart exists. If the cart does not exist, the round is buggered and we should declare a winner.
	int cart = EntRefToEntIndex(g_iRefTrackTrain[TFTeam_Blue]);
	if(cart <= MaxClients)
	{
		PrintToChatAll("%t", "Tank_Chat_RareBug_Badwater", 0x01, g_strTeamColors[TFTeam_Blue], 0x01, g_strRankColors[Rank_Unique], 0x01);
		LogMessage("Wow, you hit the rare pl_badwater bug where the tank was killed at the end. Congrats!");

		// Assume the cart was killed too close to the end and declare BLU as the winner.
		if(g_bIsFinale)
		{
			// Loop through all the control points and set them to BLU.
			Game_CaptureControlPoints(TFTeam_Blue, TFTeam_Blue);
		}else{
			// We are in the middle of a multi-stage map, setting the winner to BLU will break map logic so set it to RED in this very rare case.
			Game_SetWinner(TFTeam_Red);
		}
	}else{
		// Cart is fine - continue as normal.
		GameLogic_DoNext();
	}

	g_timerFailsafe = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Timer_FailsafeBombDeploy(Handle timer, any unused)
{
#if defined DEBUG
	PrintToServer("(Timer_FailsafeBombDeploy)");
#endif	
	PrintToChatAll("%t", "Tank_Chat_FailSafe_BombDeploy", 0x01, g_strRankColors[Rank_Unique], 0x01);

	// The round should have ended by now.
	// Declare a winner to keep the round from lasting forever.
	if(g_bIsFinale)
	{
		// Loop through all the control points and set them to BLU.
		Game_CaptureControlPoints(TFTeam_Blue, TFTeam_Blue);
	}else{
		// We are in the middle of a multi-stage map, setting the winner to BLU will break map logic so set it to RED in this very rare case.
		Game_SetWinner(TFTeam_Red);
	}

	g_timerFailsafe = INVALID_HANDLE;
	return Plugin_Stop;
}

void Game_CaptureControlPoints(int team, int ownerTeam)
{
	for(int i=0; i<MAX_LINKS; i++)
	{
		int controlPoint = EntRefToEntIndex(g_iRefLinkedCPs[team][i]);
		if(controlPoint > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Game_CaptureControlPoints) SetOwner(team %d) on #%d %d..", ownerTeam, i, controlPoint);
#endif
			SetVariantInt(ownerTeam);
			AcceptEntityInput(controlPoint, "SetOwner", -1, controlPoint);
		}
	}
}

public Action Tank_OnWeaponPickup(int client, int droppedWeapon, bool &result)
{
	if(!g_bEnabled) return Plugin_Continue;

	// The player is attempting to pick up a dropped weapon.
	if(IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
#if defined DEBUG
		PrintToServer("(Tank_OnWeaponPickup) Blocked %N from picking up %d!", client, droppedWeapon);
#endif
		result = false;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Tank_OnWeaponDropped(int itemDefinitionIndex, int accountId, int itemIdHigh, int itemIdLow, Address item)
{
	// CTFPlayer::m_AttributeManager + 104 seems to be the player's account id. Using this number you could possibly find the original owner of the weapon.
	// Alternative way: Grab the account id from the player's AuthId_Steam3 auth string.
	if(!g_bEnabled) return Plugin_Continue;
	// At this time, a weapon is dropped for 3 reasons: 1) Spy feign 2) Player death 3) Weapon regeneration.

	// The player is about to drop a weapon. Check if we have flagged this weapon as not dropable.
	if(IsValidAddress(item))
	{
		Address addr = item + view_as<Address>(OFFSET_DONT_DROP);
		if(LoadFromAddress(addr, NumberType_Int32) == FLAG_DONT_DROP_WEAPON)
		{
#if defined DEBUG
			PrintToServer("(Tank_OnWeaponDropped) Blocked weapon drop: itemdef = %d, account id = %d, itemidlow = %d, itemidhigh = %d!", itemDefinitionIndex, accountId, itemIdHigh, itemIdLow);
#endif
			// Block this weapon from being dropped.
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

bool IsValidAddress(Address pAddress)
{
	if(pAddress == Address_Null) return false;

	return ((pAddress & view_as<Address>(0x7FFFFFFF)) >= view_as<Address>(Address_MinimumValid));
}

void Player_RemoveBuildings(int client)
{
	Player_RemoveBuilding(client, "obj_sentrygun");
	Player_RemoveBuilding(client, "obj_dispenser");
	Player_RemoveBuilding(client, "obj_teleporter");
}

void Player_RemoveBuilding(int client, const char[] className)
{
	int building = MaxClients+1;
	while((building = FindEntityByClassname(building, className)) > MaxClients)
	{
		if(GetEntPropEnt(building, Prop_Send, "m_hBuilder") == client)
		{
			AcceptEntityInput(building, "Kill");
		}
	}
}

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/util.cpp#L838
//-----------------------------------------------------------------------------
// Purpose: Shake the screen of all clients within radius.
//			radius == 0, shake all clients
// UNDONE: Fix falloff model (disabled)?
// UNDONE: Affect user controls?
// Input  : center - Center of screen shake, radius is measured from here.
//			amplitude - Amplitude of shake
//			frequency - 
//			duration - duration of shake in seconds.
//			radius - Radius of effect, 0 shakes all clients.
//			command - One of the following values:
//				SHAKE_START - starts the screen shake for all players within the radius
//				SHAKE_STOP - stops the screen shake for all players within the radius
//				SHAKE_AMPLITUDE - modifies the amplitude of the screen shake
//									for all players within the radius
//				SHAKE_FREQUENCY - modifies the frequency of the screen shake
//									for all players within the radius
//			bAirShake - if this is false, then it will only shake players standing on the ground.
//-----------------------------------------------------------------------------
void UTIL_ScreenShake(float center[3], float amplitude, float frequency, float duration, float radius, int command, bool airShake)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(!airShake && command == Shake_Start && !(GetEntityFlags(i) && FL_ONGROUND)) continue;

			float playerPos[3];
			GetClientAbsOrigin(i, playerPos);

			float localAmplitude = ComputeShakeAmplitude(center, playerPos, amplitude, radius);

			if(localAmplitude < 0.0) continue;

			if(localAmplitude > 0 || command == Shake_Stop)
			{
				Handle msg = StartMessageOne("Shake", i, USERMSG_RELIABLE);
				if(msg != null)
				{
					BfWriteByte(msg, command);
					BfWriteFloat(msg, localAmplitude);
					BfWriteFloat(msg, frequency);
					BfWriteFloat(msg, duration);

					EndMessage();
				}
			}
		}
	}
}

float ComputeShakeAmplitude(float center[3], float playerPos[3], float amplitude, float radius)
{
	if(radius <= 0.0) return amplitude;

	float localAmplitude = -1.0;
	float delta[3];
	SubtractVectors(center, playerPos, delta);
	float distance = GetVectorLength(delta);

	if(distance <= radius)
	{
		float perc = 1.0 - (distance / radius);
		localAmplitude = amplitude * perc;
	}

	return localAmplitude;
}

public Action Tank_PassFilter(int ent1, int ent2, bool &result)
{
	if(!g_bEnabled) return Plugin_Continue;
	
	switch(g_entitiesOfInterest[ent1])
	{
		// Keep dispensers non-solid to enemy sentry busters.
		case Interest_Dispenser:
		{
			if(ent1 > MaxClients && ent2 >= 1 && ent2 <= MaxClients && Spawner_HasGiantTag(ent2, GIANTTAG_SENTRYBUSTER) && GetEntProp(ent2, Prop_Send, "m_bIsMiniBoss"))
			{
				result = false;
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

void OvertimeTimer_Create()
{
	// Create a HUD timer that will countdown the time until overtime starts, at which time the carts can no longer move backwards.
	Bomb_KillTimer();

	int timerDuration = RoundToNearest(config.LookupFloat(g_hCvarRaceTimeOvertime) * 60.0);
	if(timerDuration > 0)
	{
		int timer = CreateEntityByName("team_round_timer");
		if(timer > MaxClients)
		{
			DispatchKeyValue(timer, "targetname", TARGETNAME_OVERTIME_TIMER);

			DispatchSpawn(timer);
			
			if(timerDuration < 10) timerDuration = 10; // ???
			SetVariantInt(timerDuration);
			AcceptEntityInput(timer, "SetTime");
			
			SetVariantInt(1);
			AcceptEntityInput(timer, "ShowInHUD");

			SetVariantInt(1);
			AcceptEntityInput(timer, "AutoCountdown", timer);

			AcceptEntityInput(timer, "Enable");
			
			HookSingleEntityOutput(timer, "On1SecRemain", OvertimeTimer_On1SecRemain, true);
			//HookSingleEntityOutput(timer, "On30SecRemain", OvertimeTimer_On30SecRemain, true);

#if defined DEBUG
			PrintToServer("(OvertimeTimer_Create) Created \"team_round_timer\" to countdown overtime: %d!", timer);
#endif
			g_iRefBombTimer = EntIndexToEntRef(timer);

			// For some reason, nightfall stage 3 disables the timer after I create it
			RequestFrame(NextFrame_EnableTimer, g_iRefBombTimer);

			TrainWatcher_SetCapBlocked(true); // Allows the round to enter overtime. However, the OnFinished output will no longer fire when the countdown reaches 0.
		}else{
			LogMessage("Failed to create \"team_round_timer\" to countdown giant robot spawn.");
		}
	}	
}

public void OvertimeTimer_On1SecRemain(char[] output, int caller, int activator, float delay)
{
#if defined DEBUG
	PrintToServer("(OvertimeTimer_On1SecRemain) caller %d activator: %d!", caller, activator);
#endif

	Timer_KillFailsafe();
	g_timerFailsafe = CreateTimer(1.0, Timer_OvertimeStarted, _, TIMER_REPEAT);
}

public Action Timer_OvertimeStarted(Handle hTimer)
{
#if defined DEBUG
	PrintToServer("(Timer_OvertimeStarted) Overtime has begun!");
#endif

	// Leave the timer up to enforce that it is overtime.
	g_isRaceInOvertime = true;

	char message[256];
	Format(message, sizeof(message), "%T", "Tank_GameText_Overtime", LANG_SERVER);
	ShowGameMessage(message, "ico_notify_ten_seconds", 5.0);

	g_timerFailsafe = INVALID_HANDLE;
	return Plugin_Stop;
}

void TrainWatcher_SetCapBlocked(bool capBlocked)
{
	if(g_iOffset_m_bCapBlocked <= 0) return;

	int watcher = MaxClients+1;
	while((watcher = FindEntityByClassname(watcher, "team_train_watcher")) > MaxClients)
	{
		// Causes CTeamTrainWatcher::TimerMayExpire to return false, thereby allowing the round to go into overtime in plr.
		// Setting this netprop doesn't appear to cause any problems.
		// Alternatives include CTFGameRules + 1788 but it is easier to get at the train watcher.
		SetEntData(watcher, g_iOffset_m_bCapBlocked, capBlocked, 1, false);
	}
}

int ControlPoint_GetTeam(int controlPoint)
{
	if(controlPoint > MaxClients)
	{
		int ref = EntIndexToEntRef(controlPoint);

		for(int team=2; team<=3; team++)
		{
			for(int i=0; i<MAX_LINKS; i++)
			{
				if(g_iRefLinkedCPs[team][i] != 0 && g_iRefLinkedCPs[team][i] == ref)
				{
					return team;
				}
			}
		}
	}

	return -1;
}

void Announcer_SetEnabled(bool enabled)
{
	g_announcer[g_announcerActive] = enabled;
}

void Announcer_Reset()
{
	g_announcer[g_announcerActive] = false;

	g_announcer[g_announcerCatchingUp] = false;
	g_announcer[g_announcerCloseGame] = false;
	g_announcer[g_announcerLargeDifference] = false;
	for(int i=0; i<ANNOUNCER_MAX_MESSAGES; i++) g_announcer[g_announcerLastMessage][i] = 0.0;
}

void Announcer_Think()
{
	if(!g_announcer[g_announcerActive]) return;
	if(g_bRaceIntermission) return;

	// Both Tanks are very close to the end. "it's neck and neck" or "this is going to be close"
	if(!g_announcer[g_announcerCloseGame])
	{
		bool noProblem = true;
		bool closeToEnd = false;

		float diff = 0.0;
		for(int team=2; team<=3; team++)
		{
			int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
			if(watcher > MaxClients)
			{
				float totalProgress = GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress");
				if(totalProgress >= 0.98) closeToEnd = true;

				diff = totalProgress - diff;
			}else{
				noProblem = false;
				break;
			}
		}

		if(noProblem && closeToEnd && FloatAbs(diff) < 0.011) // 0.010590
		{
#if defined DEBUG
			PrintToServer("(Announcer_Think) Triggered CloseGame with diff: %f!", FloatAbs(diff));
#endif
			g_announcer[g_announcerCloseGame] = true;
			g_announcer[g_announcerLastMessage][AnnouncerMessage_CloseGame] = GetEngineTime();

			switch(GetRandomInt(0,1))
			{
				case 1: BroadcastSoundToTeam(TFTeam_Spectator, "vo/announcer_plr_racegeneral05.mp3");
				default: BroadcastSoundToTeam(TFTeam_Spectator, "vo/announcer_plr_racegeneral06.mp3");
			}
		}
	}

	// The Tanks are very far apart from each other in terms of progress.
	if(!g_announcer[g_announcerLargeDifference])
	{
		bool noProblem = true;
		int aheadTeam = -1;
		float aheadAmount = -1.0;

		float diff = 0.0;
		for(int team=2; team<=3; team++)
		{
			int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
			if(watcher > MaxClients)
			{
				float totalProgress = GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress");

				if(aheadTeam == -1 || totalProgress > aheadAmount)
				{
					aheadTeam = team;
					aheadAmount = totalProgress;
				}
				diff = totalProgress - diff;
			}else{
				noProblem = false;
				break;
			}
		}

		if(noProblem && aheadTeam != -1 && FloatAbs(diff) > 0.25)
		{
#if defined DEBUG
			PrintToServer("(Announcer_Think) Triggered LargeDifference with diff: %f!", FloatAbs(diff));
#endif
			g_announcer[g_announcerLargeDifference] = true;
			g_announcer[g_announcerLastMessage][AnnouncerMessage_LargeDifference] = GetEngineTime();

			BroadcastSoundToTeam(aheadTeam, "vo/announcer_plr_racegeneral14.mp3");
			BroadcastSoundToEnemy(aheadTeam, "vo/announcer_plr_racegeneral13.mp3");
		}
	}

	// TODO: Catch when one team tank's is gaining on the enemy's tank. Might get too spammy.
}

void Borneo_ShowAlternativeRoute(int client)
{
	if(IsFakeClient(client)) return;

	// Show the player the alternative route after capturing the penultimate control point.
	Handle hEvent = CreateEvent("show_annotation");
	if(hEvent != INVALID_HANDLE)
	{
		float flPos[3] = {-498.18, 4.53, 132.03};

		SetEventInt(hEvent, "id", Annotation_GuidingHint);
		SetEventFloat(hEvent, "worldPosX", flPos[0]);
		SetEventFloat(hEvent, "worldPosY", flPos[1]);
		SetEventFloat(hEvent, "worldPosZ", flPos[2]);
		
		SetEventInt(hEvent, "visibilityBitfield", (1 << client)); // Only show to player carrying the bomb

		char text[256];
		Format(text, sizeof(text), "%T", "Tank_Annotation_Borneo_Detour", client);
		SetEventString(hEvent, "text", text);

		SetEventFloat(hEvent, "lifetime", 13.0);
		SetEventString(hEvent, "play_sound", "misc/null.wav");
		
		FireEvent(hEvent); // Frees the handle
	}
}

void Player_RemoveUberChargeBonus()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			Tank_RemoveAttribute(client, ATTRIB_UBERCHARGE_RATE_BONUS);
		}
	}
}

void Tank_CheckForSeparation(int team, int tank, int cart)
{
	if(GetEntPropEnt(tank, Prop_Send, "moveparent") > MaxClients || g_bRaceIntermission)
	{
		// Tank is parented so it shouldn't separate from the cart.
		g_timeTankSeparation[team] = 0.0;
		return;
	}

	float tankPos[3];
	float cartPos[3];
	GetEntPropVector(tank, Prop_Send, "m_vecOrigin", tankPos);
	GetEntPropVector(cart, Prop_Send, "m_vecOrigin", cartPos);

	if(GetVectorDistance(tankPos, cartPos) > config.LookupFloat(g_hCvarDistanceSeparation))
	{
		// Tank is too far from the cart.
		if(g_timeTankSeparation[team] == 0.0)
		{
			g_timeTankSeparation[team] = GetEngineTime() + 10.0;
		}else if(GetEngineTime() > g_timeTankSeparation[team])
		{
			// Enough time has passed. Move the tank back to the cart.

			Tank_RestorePath(tank);

			// Try teleporting the tank back to the cart even though most likely it won't work.
			cartPos[2] -= 50.0;
			float cartAngles[3];
			GetEntPropVector(cart, Prop_Send, "m_angRotation", cartAngles);

			TeleportEntity(tank, cartPos, cartAngles, NULL_VECTOR);

			g_timeTankSeparation[team] = 0.0;
#if defined DEBUG
			PrintToServer("(Tank_CheckForSeparation) Detected separation team %d, teleporting the tank back to the cart..", team);
#endif
		}
	}else{
		// All is well.
		g_timeTankSeparation[team] = 0.0;
	}
}

public Action Command_Config(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: tank_config <config name> [value]");
		return Plugin_Handled;
	}

	char configName[64];
	GetCmdArg(1, configName, sizeof(configName));
	char configValue[MAXLEN_CONFIG_VALUE];

	if(args == 1)
	{
		if(config.GetString(configName, configValue, sizeof(configValue)))
		{
			ReplyToCommand(client, "Value from config file \"%s\": \"%s\".", configName, configValue);
			return Plugin_Handled;
		}

		ConVar cvar = FindConVar(configName);
		if(cvar != null)
		{
			cvar.GetString(configValue, sizeof(configValue));
			ReplyToCommand(client, "Value from convar \"%s\": \"%s\".", configName, configValue);
			return Plugin_Handled;
		}

		ReplyToCommand(client, "Config name does not exist!");
		return Plugin_Handled;
	}

	GetCmdArg(2, configValue, sizeof(configValue));
	if(config.SetString(configName, configValue, true))
	{
		ReplyToCommand(client, "Changed config name \"%s\" to \"%s\".", configName, configValue);
	}else{
		ReplyToCommand(client, "Failed to change config name \"%s\".", configName);
	}

	return Plugin_Handled;
}

void Mod_Toggle(bool enable)
{
	if(enable)
	{
		// Enable the mod.

		// Change the game description.
		if(g_hasSteamTools && GetConVarBool(g_hCvarGameDesc))
		{
#if defined _steamtools_included
			char desc[32];
			Format(desc, sizeof(desc), "Stop that Tank! v%s", PLUGIN_VERSION);
			Steam_SetGameDescription(desc);
#endif
		}

		// Add stt tag to sv_tags.
		Mod_ToggleTags(true);

		// Set some cvars.
		// Fixes sentry guns not targeting the tank on stage 2 maps
		// See: https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/baseentity.cpp#L2858
		SetConVarInt(g_hCvarLOSMode, 1);
		SetConVarInt(g_cvar_mp_bonusroundtime, 15); // Map logic on pl_goldrush & pl_hoodoo_final rely on the default bonus round time.
		ServerCommand("exec stt_cvars.cfg");
		Tournament_RestoreNames();

		// Enable memory patches.
		if(g_patchPhysics != null && !g_patchPhysics.isEnabled())
		{
			LogMessage("Patching PhysicsSimulate at 0x%X..", g_patchPhysics.Get(MemoryIndex_Address));
			g_patchPhysics.enable();
		}
		if(g_patchUpgrade != null && !g_patchUpgrade.isEnabled())
		{
			LogMessage("Patching UpgradeHistory at 0x%X..", g_patchUpgrade.Get(MemoryIndex_Address));
			g_patchUpgrade.enable();

			g_bEnableGameModeHook = true;
		}
		if(g_patchKnockback != null && !g_patchKnockback.isEnabled())
		{
			LogMessage("Patching Knockback at 0x%X..", g_patchKnockback.Get(MemoryIndex_Address));
			g_patchKnockback.enable();
		}
		if(g_patchTouchBonk != null && !g_patchTouchBonk.isEnabled())
		{
			LogMessage("Patching FlagTouchBonk at 0x%X..", g_patchTouchBonk.Get(MemoryIndex_Address));
			g_patchTouchBonk.enable();
		}
		if(g_patchTouchUber != null && !g_patchTouchUber.isEnabled())
		{
			LogMessage("Patching FlagTouchUber at 0x%X..", g_patchTouchUber.Get(MemoryIndex_Address));
			g_patchTouchUber.enable();
		}
		if(g_patchTauntBonk != null && !g_patchTauntBonk.isEnabled())
		{
			LogMessage("Patching FlagTauntBonk at 0x%X..", g_patchTauntBonk.Get(MemoryIndex_Address));
			g_patchTauntBonk.enable();
		}
		if(g_patchDropBonk != null && !g_patchDropBonk.isEnabled())
		{
			LogMessage("Patching FlagDropBonk at 0x%X..", g_patchDropBonk.Get(MemoryIndex_Address));
			g_patchDropBonk.enable();
		}

		LogMessage("Stop that Tank!: Ready");
	}else{
		// Disable the mod.

		// Remove stt tag from sv_tags.
		Mod_ToggleTags(false);

		// Disable memory patches.
		if(g_patchPhysics != null && g_patchPhysics.isEnabled())
		{
			LogMessage("Un-patching PhysicsSimulate at 0x%X..", g_patchPhysics.Get(MemoryIndex_Address));
			g_patchPhysics.disable();
		}
		if(g_patchUpgrade != null && g_patchUpgrade.isEnabled())
		{
			LogMessage("Un-patching UpgradeHistory at 0x%X..", g_patchUpgrade.Get(MemoryIndex_Address));
			g_patchUpgrade.disable();

			g_bEnableGameModeHook = false;
		}
		if(g_patchKnockback != null && g_patchKnockback.isEnabled())
		{
			LogMessage("Un-patching Knockback at 0x%X..", g_patchKnockback.Get(MemoryIndex_Address));
			g_patchKnockback.disable();
		}
		if(g_patchTouchBonk != null && g_patchTouchBonk.isEnabled())
		{
			LogMessage("Un-patching FlagTouchBonk at 0x%X..", g_patchTouchBonk.Get(MemoryIndex_Address));
			g_patchTouchBonk.disable();
		}
		if(g_patchTouchUber != null && g_patchTouchUber.isEnabled())
		{
			LogMessage("Un-patching FlagTouchUber at 0x%X..", g_patchTouchUber.Get(MemoryIndex_Address));
			g_patchTouchUber.disable();
		}
		if(g_patchTauntBonk != null && g_patchTauntBonk.isEnabled())
		{
			LogMessage("Un-patching FlagTauntBonk at 0x%X..", g_patchTauntBonk.Get(MemoryIndex_Address));
			g_patchTauntBonk.disable();
		}
		if(g_patchDropBonk != null && g_patchDropBonk.isEnabled())
		{
			LogMessage("Un-patching FlagDropBonk at 0x%X..", g_patchDropBonk.Get(MemoryIndex_Address));
			g_patchDropBonk.disable();
		}

		// User should reset cvars in server.cfg.

		LogMessage("Stop that Tank!: Disabled");
	}
}

bool Mod_CanBeLoaded()
{
	// Make a decision on whether the Stop that Tank! is enabled or not.
	// 1. tank_enabled must be set to 1. If it is then it will check the map prefix..
	// 2. The map must have one of the following prefixes: pl_, plr_, stt_.
	// If both of these things are satisfied, then STT will attempt to run.
	if(GetConVarBool(g_hCvarEnabled))
	{
		char map[PLATFORM_MAX_PATH];
		GetMapName(map, sizeof(map));
		if(strncmp(map, "pl_", 3, false) == 0 || strncmp(map, "plr_", 4, false) == 0 || strncmp(map, "stt_", 4, false) == 0)
		{
			return true;
		}
	}

	return false;
}

void Mod_DetermineGameMode()
{
	eGameMode gameMode = GameMode_Tank; // Fall back on regular payload.

	// First, look for the plr_ map prefix.
	char map[PLATFORM_MAX_PATH];
	GetMapName(map, sizeof(map));
	if(strncmp(map, "plr_", 4, false) == 0)
	{
		gameMode = GameMode_Race;
	}else if(FindEntityByClassname(MaxClients+1, "tf_logic_multiple_escort") > MaxClients) // Check for this plr_ specific entity.
	{
		gameMode = GameMode_Race;
	}
	
	g_nGameMode = gameMode;
#if defined DEBUG
	PrintToServer("(Mod_DetermineGameMode) g_nGameMode = %d!", g_nGameMode);
#endif
}

void Mod_ToggleTags(bool enable)
{
	if(!GetConVarBool(g_hCvarTags)) return;

	char tags[512];
	GetConVarString(g_cvar_sv_tags, tags, sizeof(tags));
	if(enable)
	{
		// Stick the stt tag in sv_tags.
		if(StrContains(tags, "stt") == -1)
		{
			// Tag doesn't exist so add it.
			if(strlen(tags) < sizeof(tags)-6)
			{
				Format(tags, sizeof(tags), "%s,stt,", tags);
				SetConVarString(g_cvar_sv_tags, tags);
			}
		}
	}else{
		// Make sure stt tag is removed from sv_tags.
		if(StrContains(tags, "stt") > -1)
		{
			ReplaceString(tags, sizeof(tags), "stt", "");
			SetConVarString(g_cvar_sv_tags, tags);
		}
	}
}

void GetMapName(char[] mapName, int maxlength)
{
	GetCurrentMap(mapName, maxlength);

	// Parse the display name out of workshop maps.
	int ugcPos;
	if(strncmp(mapName, "workshop/", 9, true) == 0 && (ugcPos = StrContains(mapName, ".ugc", true)) > 9)
	{
		mapName[ugcPos] = '\0';
		strcopy(mapName, maxlength, mapName[9]);
	}
}

public MRESReturn CBaseEntity_PhysicsSolidMaskForEntity(int entity, Handle returnStruct)
{
	// This overridees the default value of: 33570827 or MASK_SOLID -> (CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE)

	// This prevents tank_boss from blocking other entities with physics based movement: func_tracktrain, func_movelinear, func_door, etc..
	DHookSetReturn(returnStruct, CONTENTS_WATER);

	return MRES_Supercede;
}

public void EntityOutput_TriggerTeleport(const char[] output, int caller, int activator, float delay)
{
	if(!g_bEnabled) return;
	
#if defined DEBUG
	PrintToServer("(EntityOutput_TriggerTeleport) %s: caller = %d, activator = %d, delay = %f.", output, caller, activator, delay);
#endif
	// Make sure the giant doesn't come out of a trigger_teleport stuck.
	int client = activator;
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		if(g_nSpawner[client][g_bSpawnerEnabled] && g_nSpawner[client][g_nSpawnerType] != Spawn_Tank && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
		{
			// Ensure that player is not stuck after re-scaling.
			float pos[3];
			GetClientAbsOrigin(client, pos);
			
			float mins[3];
			float maxs[3];
			GetClientMins(client, mins);
			GetClientMaxs(client, maxs);

			int team = GetClientTeam(client);
			int mask = MASK_RED;
			if(team != TFTeam_Red) mask = MASK_BLUE;

			TR_TraceHullFilter(pos, pos, mins, maxs, mask, TraceFilter_NotTeam, team);
			if(TR_DidHit())
			{
#if defined DEBUG
				PrintToServer("(EntityOutput_TriggerTeleport) Detected that %N may be stuck after minify spell!", client);
#endif
				// Player is probably stuck so teleport them to a new position
				if(!Player_FindFreePosition2(client, pos, mins, maxs))
				{
#if defined DEBUG
					PrintToServer("(EntityOutput_TriggerTeleport) Failed to find a free spot for %N!", client);
#endif
					//
				}
			}
		}
	}
}

// void CMonsterResource::SetBossStunPercentage(CMonsterResource *this, float)
public MRESReturn CMonsterResource_SetBossHealthPercentage(int pThis, Handle hReturn, Handle hParams)
{
	if(!g_bEnabled) return MRES_Ignored;
	if(g_nGameMode != GameMode_Tank && g_nGameMode != GameMode_BombDeploy) return MRES_Ignored;

	// Block anything trying to update the monster_resource health bar.
	return MRES_Supercede;
}

public Action Tank_OnCanRecieveMedigunChargeEffect(int client, int medigunChargeType, bool &result)
{
	//PrintToServer("(Tank_OnCanRecieveMedigunChargeEffect) client=%N, medigunChargeType=%d", client, medigunChargeType);
	if(!g_bEnabled) return Plugin_Continue;

	// We are only able to block the stock uber effect with this detour so we don't need to worry about blocking other medigun charge effects.
	// The default behavior will block the stock uber effect on bomb carriers due to a check for: CTFGameRules::m_bPlayingMannVsMachine.
	if(g_nGameMode == GameMode_BombDeploy && g_iRefBombFlag != 0 && client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TFTeam_Blue)
	{
		// Check if the player is the bomb carrier.
		int bomb = EntRefToEntIndex(g_iRefBombFlag);
		if(bomb > MaxClients && GetEntPropEnt(bomb, Prop_Send, "moveparent") == client)
		{
			// Allow uber effect on the bomb carrier.
			result = true;

			if(g_nMapHack == MapHack_CactusCanyon && g_bIsFinale && g_bombAtFinalCheckpoint)
			{
				if(medigunChargeType == -1 || medigunChargeType == MedigunChargeEffect_Uber || medigunChargeType == MedigunChargeEffect_Quickfix)
				{
					// Block uber effect for the special deploy in the cactus canyon finale.
					result = false;
				}
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

int Tank_PrecacheModel(const char[] model)
{
	if(strlen(model) > 4)
	{
		if(FileExists(model, true))
		{
			return PrecacheModel(model);
		}else{
			LogMessage("Failed to precache model: %s", model);
		}
	}

	return 0;
}

public void Output_TeamControlPointRound_OnStart(const char[] output, int caller, int activator, float delay)
{
	if(!g_bEnabled) return;

#if defined DEBUG
	char callerClass[32];
	GetEdictClassname(caller, callerClass, sizeof(callerClass));
	PrintToServer("(Output_TeamControlPointRound_OnStart) caller: %d(%s) activator: %d delay: %0.1f!", caller, callerClass, activator, delay);
#endif

	// Save a reference of the active team_control_point_round entity.
	if(caller > MaxClients)
	{
		char className[32];
		GetEdictClassname(caller, className, sizeof(className));	
		if(strcmp(className, "team_control_point_round") == 0)
		{
			g_iRefRoundControlPoint = EntIndexToEntRef(caller);
		}
	}
}

public void Output_TeamControlPointRound_OnEnd(const char[] output, int caller, int activator, float delay)
{
	if(!g_bEnabled) return;

#if defined DEBUG
	PrintToServer("(Output_TeamControlPointRound_OnEnd) caller: %d activator: %d delay: %0.1f!", caller, activator, delay);
#endif

	g_iRefRoundControlPoint = 0;
}

public Action Event_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnabled) return Plugin_Continue;

#if defined DEBUG
	PrintToServer("(Event_WinPanel)");
#endif

	if(g_nGameMode != GameMode_BombDeploy) return Plugin_Continue;

	// The win panel will show the last player that captured a control point in the 'Winning capture' space.
	// Fix it so it credits the player that deployed the bomb, winning the round.
	if(g_finalBombDeployer != 0)
	{
		int client = GetClientOfUserId(g_finalBombDeployer);
		if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		{
			char cappers[6];
			cappers[0] = client;
			event.SetString("cappers", cappers);
		}
	}

	g_finalBombDeployer = 0;
	return Plugin_Continue;
}

public void Event_PlayerHealOnHit(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnabled) return;

	// Block the + particle from appearing over giants when they are healed.
	int client = event.GetInt("entindex");
	if(client >= 1 && client <= MaxClients && Spawner_HasGiantTag(client, GIANTTAG_BLOCK_HEALONHIT) && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		event.BroadcastDisabled = true;
	}
}

void Deathpit_Boost(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	float ang[3];
	GetClientEyeAngles(client, ang);

	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);

	float zMagnitude = FloatAbs(vel[2]);
	float xyMagnitude = zMagnitude;

	float vecForward[3];
	GetAngleVectors(ang, vecForward, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vecForward, vecForward);
	vecForward[2] = 1.0;
	for(int i=0; i<3; i++) vecForward[i] *= 1.15;

	float minZMagnitude = config.LookupFloat(g_hCvarGiantDeathpitMinZ);
	if(g_nMapHack == MapHack_HightowerEvent && g_hellTeamWinner >= 2) minZMagnitude = 500.0;
	float maxZMagnitude = 1500.0;
	if(zMagnitude < minZMagnitude) zMagnitude = minZMagnitude;
	else if(zMagnitude > maxZMagnitude) zMagnitude = maxZMagnitude;
	
	float minXyMagnitude = 400.0;
	float maxXyMagnitude = 1000.0;
	if(xyMagnitude < minXyMagnitude) xyMagnitude = minXyMagnitude;
	else if(xyMagnitude > maxXyMagnitude) xyMagnitude = maxXyMagnitude;

	for(int i=0; i<2; i++) vecForward[i] *= minXyMagnitude;
	vecForward[2] *= zMagnitude;

	/*
	int removeMe;
	PrintToServer("============================================");
	PrintToServer("   m_vecVelocity = %1.2f %1.2f %1.2f", vel[0], vel[1], vel[2]);
	PrintToServer("   zMagnitude = %1.2f, xyMagnitude = %1.2f", zMagnitude, xyMagnitude);
	PrintToServer("   vecForward = %1.2f %1.2f %1.2f", vecForward[0], vecForward[1], vecForward[2]);
	*/

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecForward);

	//StopSound(client, SNDCHAN_AUTO, SOUND_DEATHPIT_BOOST);
	//EmitSoundToClient(client, SOUND_DEATHPIT_BOOST);
	EmitSoundToAll(SOUND_DEATHPIT_BOOST, client);

	int particle = -1;
	if(GetClientTeam(client) == TFTeam_Red)
	{
		particle = g_iParticleJumpRed;
	}else{
		particle = g_iParticleJumpBlue;
	}
	
	if(particle != -1)
	{
		TE_Particle(particle, pos);
		TE_SendToAll();
	}

	TF2_AddCondition(client, TFCond_MegaHeal, 1.0);
}

void Bomb_ShowSkippedAnnotation(int client, int team, int indexCP)
{
	if(IsFakeClient(client)) return;
	if(indexCP < 0 || indexCP >= MAX_LINKS) return;

	int pathTrack = EntRefToEntIndex(g_iRefLinkedPaths[team][indexCP]);
	if(pathTrack <= MaxClients) return;

	// Send the player an annotation guiding them to the next control point.
	Handle event = CreateEvent("show_annotation");
	if(event != INVALID_HANDLE)
	{
		float pos[3];
		GetEntPropVector(pathTrack, Prop_Send, "m_vecOrigin", pos);
		pos[2] -= 20.0;

		SetEventInt(event, "id", Annotation_BombCaptureSkipped);
		SetEventFloat(event, "worldPosX", pos[0]);
		SetEventFloat(event, "worldPosY", pos[1]);
		SetEventFloat(event, "worldPosZ", pos[2]);
		
		SetEventInt(event, "visibilityBitfield", (1 << client)); // Only show to player carrying the bomb.

		char text[256];		
		Format(text, sizeof(text), "%T", "Tank_Annotation_SkippedControlPoint", client);
		SetEventString(event, "text", text);

		SetEventFloat(event, "lifetime", 10.0);
		SetEventString(event, "play_sound", "coach/coach_attack_here.wav");
		
		FireEvent(event); // Frees the handle.
	}
}

public Action Command_Explode(int client, int args)
{
	if(!g_bEnabled) return Plugin_Continue;

	if(g_nGameMode != GameMode_Tank || !g_bIsRoundStarted)
	{
		ReplyToCommand(client, "This command may only be used during the Tank period.");
		return Plugin_Handled;
	}

	int tank = EntRefToEntIndex(g_iRefTank[TFTeam_Blue]);
	if(tank > MaxClients)
	{
		SetVariantInt(MAX_TANK_HEALTH);
		AcceptEntityInput(tank, "RemoveHealth");

		ShowActivity2(client, "[SM] ", "%N blew up the BLU Tank.", client);
	}else{
		ReplyToCommand(client, "Failed to destroy tank: Find to find BLU Tank.");
	}

	return Plugin_Handled;
}

void Tank_EnforceRespawnTimes()
{
	// Scale respawn times with player count.
	int iPlayerCount = 0;
	for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) >= 2) iPlayerCount++;
	if(iPlayerCount < 1) iPlayerCount = 1;

	// Get the base respawn time.
	float flRespawnGiant = config.LookupFloat(g_hCvarRespawnGiant);
	float flRespawnBombRed = config.LookupFloat(g_hCvarRespawnBombRed);
	float flRespawnRace = config.LookupFloat(g_hCvarRespawnRace);
	float flRespawnTank = config.LookupFloat(g_hCvarRespawnTank);

	// Get the minimum respawn time when scaling for player count.
	float respawnScaleMin = config.LookupFloat(g_hCvarRespawnScaleMin);
	float respawnGiantMin = flRespawnGiant * respawnScaleMin;
	float respawnBombRedMin = flRespawnBombRed * respawnScaleMin;
	float respawnRaceMin = flRespawnRace * respawnScaleMin;
	float respawnTankMin = flRespawnTank * respawnScaleMin;

	// Get the respawn times scaled for player count.
	flRespawnGiant = float(iPlayerCount) / 24.0 * flRespawnGiant;
	flRespawnBombRed = float(iPlayerCount) / 24.0 * flRespawnBombRed;
	flRespawnRace = float(iPlayerCount) / 24.0 * flRespawnRace;
	flRespawnTank = float(iPlayerCount) / 24.0 * flRespawnTank;

	// Enforce a minimum respawn time for the scaled respawn times.
	if(flRespawnGiant < respawnGiantMin) flRespawnGiant = respawnGiantMin;
	if(flRespawnBombRed < respawnBombRedMin) flRespawnBombRed = respawnBombRedMin;
	if(flRespawnRace < respawnRaceMin) flRespawnRace = respawnRaceMin;
	if(flRespawnTank < respawnTankMin) flRespawnTank = respawnTankMin;

	// Scaled respawn times can never go lower than the base respawn time.
	float flRespawnBase = config.LookupFloat(g_hCvarRespawnBase);
	if(flRespawnGiant < flRespawnBase) flRespawnGiant = flRespawnBase;
	if(flRespawnBombRed < flRespawnBase) flRespawnBombRed = flRespawnBase;
	if(flRespawnRace < flRespawnBase) flRespawnRace = flRespawnBase;
	if(flRespawnTank < flRespawnBase) flRespawnTank = flRespawnBase;

	// Periodically update the respawn times in case the map tries to change the values (such as when a point is capped).
	TF2_SetRespawnTime(TFTeam_Blue, flRespawnBase);
	TF2_SetRespawnTime(TFTeam_Red, flRespawnBase);

	if(g_nGameMode == GameMode_Tank && g_bIsRoundStarted)
	{
		TF2_SetRespawnTime(TFTeam_Blue, flRespawnTank);
	}

	if(g_nGameMode == GameMode_BombDeploy && g_bIsRoundStarted)
	{
		// RED needs a slightly higher respawn time during the bomb round since the hatch is usually right by RED spawn
		TF2_SetRespawnTime(TFTeam_Red, flRespawnBombRed);

		// Give BLU a slightly higher respawn time when they have a Giant Robot out.
		for(int i=1; i<=MaxClients; i++)
		{
			if( IsClientInGame(i) && GetClientTeam(i) == TFTeam_Blue && IsPlayerAlive(i)
			 && g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[i][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
			 && !(g_nGiants[g_nSpawner[i][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_DONT_CHANGE_RESPAWN) && GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
			{
				TF2_SetRespawnTime(TFTeam_Blue, flRespawnGiant);
				break;
			}
		}
	}

	if(g_nGameMode == GameMode_Race)
	{
		TF2_SetRespawnTime(TFTeam_Blue, flRespawnRace);
		TF2_SetRespawnTime(TFTeam_Red, flRespawnRace);

		// Calculate if a team's tank has fallen behind.
		float tankProgress[MAX_TEAMS];
		for(int team=2; team<=3; team++)
		{
			int watcher = EntRefToEntIndex(g_iRefTrainWatcher[team]);
			if(watcher > MaxClients)
			{
				tankProgress[team] = GetEntPropFloat(watcher, Prop_Send, "m_flTotalProgress");
			}
		}

		int teamTankBehind = -1;
		if(FloatAbs(tankProgress[TFTeam_Red] - tankProgress[TFTeam_Blue]) > config.LookupFloat(g_hCvarRespawnCartBehind))
		{
			teamTankBehind = (tankProgress[TFTeam_Red] < tankProgress[TFTeam_Blue]) ? TFTeam_Red : TFTeam_Blue;
		}

		// Calculate if a team has a Giant Robot advantage.
		int numGiants[MAX_TEAMS];
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && g_nSpawner[i][g_bSpawnerEnabled] && g_nSpawner[i][g_nSpawnerType] == Spawn_GiantRobot && !(g_nGiants[g_nSpawner[i][g_iSpawnerGiantIndex]][g_iGiantTags] & GIANTTAG_SENTRYBUSTER)
				&& GetEntProp(i, Prop_Send, "m_bIsMiniBoss"))
			{
				int team = GetClientTeam(i);
				if(team >= 0 && team < MAX_TEAMS)
				{
					numGiants[team]++;
				}
			}
		}

		int teamWithAdvantage = -1;
		int advantage = abs(numGiants[TFTeam_Red] - numGiants[TFTeam_Blue]);
		if(advantage >= 1)
		{
			teamWithAdvantage = (numGiants[TFTeam_Red] > numGiants[TFTeam_Blue]) ? TFTeam_Red : TFTeam_Blue;
		}
		//PrintToServer("teamWithAdvantage = %d  teamTankBehind = %d", teamWithAdvantage, teamTankBehind);

		// Adjust respawn time by taking into account Giant Robot advantage.
		if(teamWithAdvantage != -1)
		{
			if(teamWithAdvantage == teamTankBehind)
			{
				// Has advantage, Tank behind.
				// Let the normal respawn time scaled for player count carry over from above!
			}else{
				// Has advantage, Tank NOT behind.
				int advantageCap = config.LookupInt(g_hCvarRespawnAdvCap);
				if(advantageCap > 0)
				{
					int cap = advantage;
					if(cap > advantageCap) cap = advantageCap;
					float advRespawnTime = config.LookupFloat(g_hCvarRespawnAdvMult) * float(cap) + flRespawnRace;

					TF2_SetRespawnTime(teamWithAdvantage, advRespawnTime);
				}
			}

			// If the advantage is great enough, give the opposite team instant respawn as a sort of "anti-spawn camp" mechanic.
			if(advantage >= config.LookupInt(g_hCvarRespawnAdvRunaway))
			{
				int oppositeTeam = (teamWithAdvantage == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;

				TF2_SetRespawnTime(oppositeTeam, flRespawnBase); // Near instant respawn.
			}
		}

		// Adjust respawn time by taking into account the difference in the Tank's progress.
		if(teamTankBehind != -1)
		{
			if(teamTankBehind != teamWithAdvantage)
			{
				// Tank behind, no advantage.
				TF2_SetRespawnTime(teamTankBehind, flRespawnBase); // Near instant respawn.
			}
		}
	}

	/*
	int removeMe;
	float waveRed = GameRules_GetPropFloat("m_TeamRespawnWaveTimes", TFTeam_Red);
	float waveBlue = GameRules_GetPropFloat("m_TeamRespawnWaveTimes", TFTeam_Blue);
	PrintCenterTextAll("Respawn times: RED = %1.2f BLU = %1.2f", waveRed, waveBlue);
	*/
}

bool Bomb_CanPlayerDeploy(int client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage)) return false;

	if(TF2_IsPlayerInCondition(client, TFCond_MegaHeal)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Bonked)) return false;

	return true;
}

/* A HUD bug prevents these messages from being seen if the player is healing or being healed.
void SendHudNotification(int client, const char[] message, const char[] icon="ico_notify_partner_taunt", int background=0)
{
	Handle msg = StartMessageOne("HudNotifyCustom", client, USERMSG_BLOCKHOOKS);
	if(msg != null)
	{
		BfWriteString(msg, message);
		BfWriteString(msg, icon);
		BfWriteByte(msg, background);

		EndMessage();
	}
}
*/

public Action Event_ChargeDeployed(Handle hEvent, const char[] strEventName, bool bDontBroadcast)
{
	if(!g_bEnabled) return Plugin_Continue;

	bool isSetup = Tank_IsInSetup();

	// Block the "chargedeployed" log action to prevent stats point farming.
	if(isSetup) g_blockLogAction = isSetup;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		if(medigun > MaxClients)
		{
			int def = GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex");

			if(isSetup && def != ITEM_VACCINATOR)
			{
				// This will cancel out the 1 point awarded for deploying an uber.
				Tank_IncrementStat(client, TFStat_PlayerInvulnerable, -1);
			}

			// Vaccinator ubers seem to not have any effect while healing revive markers outside of MVM. This fixes that.
			if(def == ITEM_VACCINATOR)
			{
				int marker = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
				if(marker > MaxClients)
				{
					char classname[24];
					GetEdictClassname(marker, classname, sizeof(classname));
					if(strcmp(classname, "entity_revive_marker") == 0)
					{
#if defined DEBUG
						PrintToServer("(Event_ChargeDeployed) %N used a vac uber while reviving, fast reviving..", client);
#endif
						int maxHealth = GetEntProp(marker, Prop_Send, "m_iMaxHealth");
						int health = GetEntProp(marker, Prop_Send, "m_iHealth");

						// Heal 90% or so of the revive marker's health when a vac uber is popped.
						health += RoundToCeil(float(maxHealth) * config.LookupFloat(g_hCvarReanimatorVacUber));
						if(health >= maxHealth) health = maxHealth-1;

						SetEntProp(marker, Prop_Send, "m_iHealth", health);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(client >= 1 && client <= MaxClients && Spawner_HasGiantTag(client, GIANTTAG_GUNSLINGER_COMBO) && IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") && IsPlayerAlive(client))
	{
		int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		if(melee > MaxClients && melee == weapon)
		{
			// Award a critical for every 3 successive melee strikes for the "gunslinger_combo" giant template tag.
			if(g_numSuccessiveHits[client] >= 1 && g_timeNextMeleeAttack[client] != 0.0 && GetGameTime() < g_timeNextMeleeAttack[client])
			{
#if defined DEBUG
				PrintToServer("(TF2_CalcIsAttackCritical) %N triggered a gunslinger combo crit (%d)!", client, g_numSuccessiveHits[client]);
#endif
				result = true;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}