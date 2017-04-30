#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1 
#pragma newdecls required 

#define TAG_MESSAGE "[\x04VoidRealityWarmup\x01]"

Menu m_WarmupMapSelect;
int i_PlayerCount;
int i_PlayersNeeded = 2;
bool b_LimitReached;
bool b_CanWarmupMenu;
char DefaultValue[64];
char map[32];
ConVar sm_gt_installed = null;

static const char sMapList[][] =
{
	"de_dust2",
	"de_mirage",
	"de_overpass",
	"de_cbble",
	"de_cache",
	"de_train",
	"de_inferno"
}; 

public Plugin myinfo =  
{ 
    name        = "Warmup Checker", 
    author      = "B3none", 
    description = "Warmup until a defined number of players has been reached", 
    version     = "1.0.4", 
    url         = "https://forums.alliedmods.net/showthread.php?t=296558" 
}; 

public void OnPluginStart()
{
	CreateTimer(30.0, Announce_Loneliness);
	
	LoadTranslations("warmupcheckermenu.phrases");
	sm_gt_installed = CreateConVar("sm_gt_installed", "0", "Do you have the grenade trails plugin? | 1 = Yes, 2 = No");
	
	AutoExecConfig(true, "b3none_warmupchecker");
	
	RegConsoleCmd("sm_wm", WarmupMapMenu, "Select the map during warmup!");
	RegConsoleCmd("sm_warmupmap", WarmupMapMenu, "Select the map during warmup!");
	RegConsoleCmd("sm_WM", WarmupMapMenu, "Select the map during warmup!");
	
	HookEvent("round_start", OnRoundStart);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("hegrenade_detonate", HE_Detonate);
	HookEvent("smokegrenade_detonate", Smoke_Detonate);
	HookEvent("flashbang_detonate", Flash_Detonate);
	HookEvent("molotov_detonate", Molotov_Detonate);
	HookEvent("inferno_startburn", Inferno_Detonate);
}

public Action OnPlayerSpawn(Handle event, const char []name, bool dontbroadcast)
{
	if(!b_LimitReached)
	{
		for(int i = 1; i <= MAXPLAYERS+1; i++)
		{
			if(IsValidClient(i))
			{
				SetEntProp(i, Prop_Send, "m_iAccount", 16000);
				
				GivePlayerItem(i, "weapon_hegrenade");
				GivePlayerItem(i, "weapon_smokegrenade"); 
				GivePlayerItem(i, "weapon_flashbang");
				
				if (GetClientTeam(i) == 2)
				{
					GivePlayerItem(i, "weapon_molotov");
					GivePlayerItem(i, "weapon_ak47");
				}
				
				else if (GetClientTeam(i) == 3)
				{
					GivePlayerItem(i, "weapon_incgrenade");
					GivePlayerItem(i, "weapon_m4a1_silencer");
				}
			}
		}
		// This specific for loop is from splewis practicemode.sp @ https://goo.gl/VJunUm
	}
}

public Action OnRoundStart(Handle event, const char []name, bool dontbroadcast)
{
	WarmupCheck();
}

public int WarmupMapHandler(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			
			if(StrEqual(map, DefaultValue))
			{
				GetCurrentMap(map, sizeof(map));
			}
				
			menu.GetItem(choice, info, sizeof(info));
			
			ServerCommand("map %s;", sMapList[choice]);
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			
			if(StrEqual(map, DefaultValue))
			{
				GetCurrentMap(map, sizeof(map));
			}
			
			if(StrEqual(map, sMapList[choice]))
			{
				return ITEMDRAW_DISABLED;
			}
			
			else
			{
				return style;
			}
		}
	}
	return 0;
}

Menu BuildWarmupMapSelect()
{
	Menu wmm = new Menu(WarmupMapHandler, MENU_ACTIONS_ALL);
	wmm.SetTitle("Warmup Map Menu\nSelect a map:");
	wmm.AddItem("%T", "Dust 2");
	wmm.AddItem("%T" ,"Mirage");
	wmm.AddItem("%T" ,"Overpass");
	wmm.AddItem("%T" ,"Cobblestone");
	wmm.AddItem("%T" ,"Cache");
	wmm.AddItem("%T" ,"Train");
	wmm.AddItem("%T" ,"Inferno");
	wmm.ExitButton = true;
	return wmm;
}

public Action WarmupMapMenu(int client, int args)
{
	if(IsValidClient(client))
	{
		if(b_CanWarmupMenu)
		{
			m_WarmupMapSelect.Display(client, 30);
			// return Plugin_Handled;
		}
	
		else
		{
			PrintToChat(client, "%s It is not the warmup, this command is only available if there is one person in the server.", TAG_MESSAGE);
			// return Plugin_Handled;
		}
	}
	// return Plugin_Continue;
}

public Action Announce_Loneliness(Handle timer)
{
	if(!b_LimitReached)
	{
		PrintToChatAll("%s It appears you are lonely, you have plenty of time to use \x02!ws\x01.", TAG_MESSAGE);
		PrintToChatAll("%s You can also type \x02!wm\x01 to open the map selection menu.", TAG_MESSAGE);
		CreateTimer(30.0, Announce_Loneliness);
	}
}

public Action CanUseWarmupMenu(Handle timer)
{
	if(!b_LimitReached)
	{
		b_CanWarmupMenu = true;
	}
}

public Action WarmupCheck() 
{ 
    if(!b_LimitReached) 
    { 
        if(i_PlayerCount == i_PlayersNeeded) 
        { 
            PrintToChatAll("%s There are now \x0C%i\x01 players connected, initiating Retakes.", TAG_MESSAGE, i_PlayersNeeded);
            b_LimitReached = true;
            b_CanWarmupMenu = false;
            ResetGame();
        }
    } 
} 

public Action ResetGame() 
{
	if(b_LimitReached)
	{
		ServerCommand("mp_warmuptime 0;");
		
		if(sm_gt_installed)
		{
			ServerCommand("sm_tails_enabled 0;");
		}
		
		ServerCommand("mp_death_drop_defuser 1;");
		ServerCommand("mp_death_drop_grenade 1;");
		ServerCommand("mp_death_drop_gun 1;");
		ServerCommand("mp_restartgame 1;");
	}
	
	else
	{
		ServerCommand("mp_warmuptime 7200;");
		
		if(sm_gt_installed)
		{
			ServerCommand("sm_tails_enabled 1;");
		}
		
		ServerCommand("mp_death_drop_defuser 0;");
		ServerCommand("mp_death_drop_grenade 0;");
		ServerCommand("mp_death_drop_gun 0;");
		ServerCommand("mp_restartgame 1;");
		CreateTimer(5.0, Restart2);
	}
}

public Action HE_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MAXPLAYERS+1; i++)
	{
		if (!b_LimitReached)
		{
			if (IsValidClient(i))
			{
				GivePlayerItem(i, "weapon_hegrenade");
			}
		}
	}
}

public Action Smoke_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MAXPLAYERS+1; i++)
	{
		if (!b_LimitReached)
		{
			if (IsValidClient(i))
			{
				GivePlayerItem(i, "weapon_smokegrenade");
			}
		}
	}
}

public Action Flash_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MAXPLAYERS+1; i++)
	{
		if (!b_LimitReached)
		{
			if (IsValidClient(i))
			{
				GivePlayerItem(i, "weapon_flashbang");
			}
		}
	}
}

public Action Molotov_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MAXPLAYERS+1; i++)
	{
		if (!b_LimitReached)
		{
			if (IsValidClient(i))
			{
				GivePlayerItem(i, "weapon_molotov");
			}
		}
	}
}

public Action Inferno_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MAXPLAYERS+1; i++)
	{
		if (!b_LimitReached)
		{
			if (IsValidClient(i))
			{
				GivePlayerItem(i, "weapon_incgrenade");
			}
		}
	}
}

public Action Restart2(Handle timer)
{
	ServerCommand("mp_restartgame 1;");
}

public void OnClientPutInServer() 
{ 
    i_PlayerCount++;
    WarmupCheck(); 
} 

public void OnClientDisconnect() 
{ 
    i_PlayerCount = i_PlayerCount - 1;
    if(i_PlayerCount <= 1)
    {
		PrintToChatAll("%s There is now only 1 player connected, initiating warmup period.", TAG_MESSAGE);
		b_LimitReached = false;
		ResetGame();
    }
} 

public void OnMapStart() 
{
	ResetGame();
	i_PlayerCount = 0;
	b_LimitReached = false;
	CreateTimer(15.0, CanUseWarmupMenu);
	m_WarmupMapSelect = BuildWarmupMapSelect();
	b_CanWarmupMenu = false;
	DefaultValue = "Psst, I'm a default value!";
	Format(map, sizeof(map), DefaultValue);
} 

public void OnMapEnd() 
{ 
    i_PlayerCount = 0;
    b_LimitReached = false;
    b_CanWarmupMenu = false;
    DefaultValue = "Psst, I'm a default value!";
    Format(map, sizeof(map), DefaultValue);
    
    if(m_WarmupMapSelect != null)
    {
        delete(m_WarmupMapSelect);
        m_WarmupMapSelect = null;
    }
} 

stock bool IsValidClient(int client)
{
    return (0 < client <= MaxClients && IsClientInGame(client));
}
