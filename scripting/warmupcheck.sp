/*
*	TODO
*	-> Add ConVar's
*	-> Refine / condense code.
*/

#include <sourcemod>

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
    version     = "1.0.1", 
    url         = "https://forums.alliedmods.net/showthread.php?t=296558" 
}; 

public void OnPluginStart()
{
	CreateTimer(30.0, Announce_Loneliness); // Every 30 seconds make an announcment
	
	LoadTranslations("warmupcheckermenu.phrases");
	
	RegConsoleCmd("sm_wm", WarmupMapMenu, "Select the map during warmup!");
	RegConsoleCmd("sm_warmupmap", WarmupMapMenu, "Select the map during warmup!");
	RegConsoleCmd("sm_WM", WarmupMapMenu, "Select the map during warmup!");
	
	HookEvent("round_start", OnRoundStart);
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action OnPlayerSpawn(Handle event, const char []name, bool dontbroadcast)
{
	if(!b_LimitReached)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				SetEntProp(i, Prop_Send, "m_iAccount", 16000);
			}
		}
		// This specific for loop is from splewis practicemode.sp @ https://goo.gl/VJunUm
	}
}

public Action OnRoundStart(Handle event, const char []name, bool dontbroadcast)
{
	b_CanWarmupMenu = false;
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
			return Plugin_Handled;
		}
	
		else
		{
			ReplyToCommand(client, "%s It is not the warmup, this command is only available if there is one person in the server.", TAG_MESSAGE);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
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
            ResetGame();
        }
        
        /* Debugging else statement */
        /*
        else
        {
            PrintToChatAll("%s Warmup check performed!", TAG_MESSAGE);
            PrintToChatAll("%s b_LimitReached = ", b_LimitReached ? "True":"False", TAG_MESSAGE);
            PrintToChatAll("%s MaxClients = \x0C%i\x01", TAG_MESSAGE, i_PlayersNeeded);
        }
        */
    } 
} 

public Action ResetGame() 
{
	if(b_LimitReached)
	{
		ServerCommand("mp_warmuptime 0;");
		ServerCommand("mp_death_drop_defuser 1;");
		ServerCommand("mp_death_drop_grenade 1;");
		ServerCommand("mp_death_drop_gun 1;");
		ServerCommand("mp_restartgame 1;");
	}
	
	else
	{
		ServerCommand("mp_warmuptime 7200;");
		ServerCommand("mp_death_drop_defuser 0;");
		ServerCommand("mp_death_drop_grenade 0;");
		ServerCommand("mp_death_drop_gun 0;");
		ServerCommand("mp_restartgame 1;");
	}
} 

public void OnClientPutInServer() 
{ 
    i_PlayerCount++;
    // PrintToChatAll("%s Playercount incrimented! It is now \x0C%i\x01", TAG_MESSAGE, i_PlayerCount); // Debug
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
    // PrintToChatAll("%s One deducted from playercount! It is now \x0C%i\x01", TAG_MESSAGE, i_PlayerCount); // Debug
} 

public void OnMapStart() 
{
	ResetGame();
	i_PlayerCount = 0;
	b_LimitReached = false;
	CreateTimer(15.0, CanUseWarmupMenu); //15 second delay to stop a player changing the map of a full server (before everyone joins.)
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
