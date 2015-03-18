#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <autoexecconfig>
#include <war>
#include <hosties>
#include <lastrequest>

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL		"http://bitbucket.toastdev.de/sourcemod-plugins/raw/master/LRWar.txt"

public Plugin:myinfo = 
{
	name = "Lastrequest: War",
	author = "Toast",
	description = "A controller plugin for War using lastrequest",
	version = "0.0.1",
	url = "bitbucket.toastdev.de"
}

new Handle:g_cLRWarRounds = INVALID_HANDLE;
new Handle:g_cLRWarOverwrite = INVALID_HANDLE;

new String:g_sLR_Name[64];

new g_LREntryNum;
new g_Explosion;

public OnMapStart()
{
	
	g_Explosion = PrecacheModel("sprites/sprite_fire01.vmt");
	
	PrecacheSound("ambient/explosions/exp2.wav", true);
}

public OnPluginStart()
{
	g_cLRWarRounds = AutoExecConfig_CreateConVar("sm_war_lr_rounds", "1", "How many rounds will war be by lr?", _, true, 0.0);
	g_cLRWarOverwrite = AutoExecConfig_CreateConVar("sm_war_lr_min_overwrite", "1", "Overwrite min rounds of no war (1 = true, 0 = false)", _, true, 0.0, true, 1.0);

	LoadTranslations("warlr.phrases");

	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Title", LANG_SERVER);

	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}

public OnPluginEnd()
{
	RemoveLastRequestFromList(LR_WAR_START, LR_WAR_STOP, g_sLR_Name);
}

public LR_WAR_START(Handle:LR_Array, iIndexInArray)
{
	new This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (This_LR_Type == g_LREntryNum)
	{
		new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		// Somone wishes to have war
		if(WAR_IsWar())
		{
			CPrintToChatAll("%t %t", "prefix", "lr_error_already_war");
		}
		else if(GetConVarBool(g_cLRWarOverwrite))
		{
			WAR_SetStatus(WS_PROCESS);
			CPrintToChatAll("%t %t", "prefix", "lr_sucess");
			CreateTimer(2.0, Timer_KillExplosion, LR_Player_Prisoner);
		}
		else
		{
			if(!WAR_IsInit())
			{
				WAR_SetStatus(WS_INITIALISING);
				CPrintToChatAll("%t %t", "prefix", "lr_sucess_init", WAR_GetMinNoWarRounds());
				CreateTimer(2.0, Timer_KillExplosion, LR_Player_Prisoner);
			}
			else
			{
				CPrintToChatAll("%t %t", "prefix", "lr_error_already_init");
			}
		}
	}
}

public LR_WAR_STOP(This_LR_Type, LR_Player_Prisoner, LR_Player_Guard)
{
	// Nothing
}

public Action:Timer_KillExplosion(Handle:timer, any:client){
	if(IsClientInGame(client) && IsPlayerAlive(client)){
		new Float:vPlayer[3];
		GetClientAbsOrigin(client, vPlayer);
		TE_SetupExplosion(vPlayer, g_Explosion, 10.0, 1, 0, 600, 5000);
		TE_SendToAll();
		ForcePlayerSuicide(client);
	}
}

public WAR_OnWarRound(any:WarRound)
{
	if(WarRound <= GetConVarInt(g_cLRWarRounds) - 1)
	{
		WAR_SetStatus(WS_WAITING);
	}
}

public OnConfigsExecuted()
{
	// Add War to the Last Request API
	static bool:bAddedWar = false;
	if (!bAddedWar)
	{
		g_LREntryNum = AddLastRequestToList(LR_WAR_START, LR_WAR_STOP, g_sLR_Name);
		bAddedWar = true;
	}
}

public Action:KillExplosion(Handle:timer, any:client){
	if(IsClientInGame(client) && IsPlayerAlive(client)){
		new Float:vPlayer[3];
		GetClientAbsOrigin(client, vPlayer);
		TE_SetupExplosion(vPlayer, g_Explosion, 10.0, 1, 0, 600, 5000);
		TE_SendToAll();
		ForcePlayerSuicide(client);
	}
}