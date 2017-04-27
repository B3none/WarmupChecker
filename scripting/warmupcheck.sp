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
int i_PlayersNeeded;
bool b_LimitReached;
bool b_CanWarmupMenu;

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
	
	RegConsoleCmd("sm_wm", WarmupMapMenu, "Select the map!");
	RegConsoleCmd("sm_warmupmap", WarmupMapMenu, "Select the map!");
	RegConsoleCmd("sm_WM", WarmupMapMenu, "Select the map!");
	
}

public int WarmupMapHandler(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			
			menu.GetItem(choice, info, sizeof(info));
			
			if(choice == 0)
			{
				ServerCommand("map de_dust2;");
			}
			
			else if(choice == 1)
			{
				ServerCommand("map de_mirage;");
			}
			
			else if(choice == 2)
			{
				ServerCommand("map de_overpass;");
			}
			
			else if(choice == 3)
			{
				ServerCommand("map de_cbble;");
			}
			
			else if(choice == 4)
			{
				ServerCommand("map de_cache;");
			}
			
			else if(choice == 5)
			{
				ServerCommand("map de_train;");
			}
			
			else if(choice == 6)
			{
				ServerCommand("map de_inferno;");
			}
		}
	}
	return 0;
}

Menu BuildWarmupMapSelect()
{
	Menu menu = new Menu(WarmupMapHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", "Menu Title");
	menu.AddItem("%T" ,"Dust 2");
	menu.AddItem("%T" ,"Mirage");
	menu.AddItem("%T" ,"Overpass");
	menu.AddItem("%T" ,"Cobblestone");
	menu.AddItem("%T" ,"Cache");
	menu.AddItem("%T" ,"Train");
	menu.AddItem("%T" ,"Inferno");
	menu.ExitButton = true;
	return menu;
}

public Action WarmupMapMenu(int client, int args)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(b_CanWarmupMenu)
		{
			m_WarmupMapSelect.Display(client, 20);
		}
		return Plugin_Continue;
	}
	
	else
	{
		ReplyToCommand(client, "%s It is not the warmup, this command is only available if there is one person in the server.", TAG_MESSAGE);
		return Plugin_Handled;
	}
}

public Action Announce_Loneliness(Handle timer)
{
	if(!b_LimitReached)
	{
		PrintToChatAll("%s It appears you are lonely, you have plenty of time to use \x02!ws\x01.", TAG_MESSAGE);
		PrintToChatAll("%s You can also type \x02!wm\x01 to open the map selection menu.", TAG_MESSAGE);
	}
}

public Action CanUseWarmupMenu(Handle timer)
{
	if(!b_LimitReached)
	{
		b_CanWarmupMenu = true;
	}
	
	else
	{
		b_CanWarmupMenu = false;
	}
}

public Action WarmupCheck() 
{ 
    if(!b_LimitReached) 
    { 
        if(i_PlayerCount == i_PlayersNeeded) 
        { 
            ServerCommand("mp_warmuptime 0;"); 
            ServerCommand("mp_restartgame 1;");
            PrintToChatAll("%s There are now \x0C%i\x01 players connected, initiating Retakes.", TAG_MESSAGE, i_PlayersNeeded);
            b_LimitReached = true; 
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

public Action ResetMap(Handle timer) 
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	ServerCommand("map %s;", map);
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
		PrintToChatAll("%s Resetting map in 5 seconds!.", TAG_MESSAGE);
		CreateTimer(5.0, ResetMap);
    }
    // PrintToChatAll("%s One deducted from playercount! It is now \x0C%i\x01", TAG_MESSAGE, i_PlayerCount); // Debug
} 

public void OnMapStart() 
{
	ServerCommand("mp_warmuptime 7200;"); // I could look at forcing the "m_bWarmupPeriod" offset to 1.
	ServerCommand("mp_restartgame 1;");
	i_PlayerCount = 0;
	i_PlayersNeeded = 2;
	b_LimitReached = false;
	CreateTimer(15.0, CanUseWarmupMenu); //15 second delay to stop a player changing the map of a full server (before everyone joins.)
	m_WarmupMapSelect = BuildWarmupMapSelect();
} 

public void OnMapEnd() 
{ 
    i_PlayerCount = 0;
    i_PlayersNeeded = 2;
    b_LimitReached = false;
    
    if(m_WarmupMapSelect != null)
    {
        delete(m_WarmupMapSelect);
        m_WarmupMapSelect = null;
    }
} 

stock bool IsValidClient(int client)
{
	if (client >= 1 && (client <= MaxClients) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}
	
	else
	{
		return false;
	}
}
