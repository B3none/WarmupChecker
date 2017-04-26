#include <sourcemod> 

#pragma semicolon 1 
#pragma newdecls required 

#define TAG_MESSAGE "[\x04VoidRealityWarmup\x01] "

int i_PlayerCount;
int i_PlayersNeeded;
bool b_LimitReached;

public Plugin myinfo =  
{ 
    name        = "Warmup Checker", 
    author      = "B3none", 
    description = "Warmup until maxplayers has been reached", 
    version     = "1.0.0", 
    url         = "https://forums.alliedmods.net/showthread.php?t=296558" 
}; 

public void OnPluginStart()
{
	CreateTimer(30.0, Announce_Loneliness);
}

public Action Announce_Loneliness(Handle timer)
{
	if(!b_LimitReached)
	{
		PrintToChatAll("%s It appears you are lonely, you have plenty of time to use \x02!ws\x01.", TAG_MESSAGE);
	}
}

public Action WarmupCheck() 
{ 
    if(!b_LimitReached) 
    { 
        if(i_PlayerCount == i_PlayersNeeded) 
        { 
            ServerCommand("mp_warmuptime 0"); 
            ServerCommand("mp_restartgame 1");
            PrintToChatAll("%s There are now \x0C%i\x01 players connected, initiating Retakes.", TAG_MESSAGE, i_PlayersNeeded);
            b_LimitReached = true; 
        }
        
        /* Debugging else statement */
        /*
        else
        {
            PrintToChatAll("%s Warmup check performed!", TAG_MESSAGE);
            PrintToChatAll("%s b_MaxClients = ", b_MaxClients ? "True":"False", TAG_MESSAGE);
            PrintToChatAll("%s MaxClients = \x0C%i\x01", TAG_MESSAGE, i_PlayersNeeded);
        }
        */
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
    	b_LimitReached = false; 
    	ServerCommand("mp_warmuptime 999999");
    	ServerCommand("mp_restartgame 1");
    	PrintToChatAll("%s There is now only 1 player connected, initiating warmup period.", TAG_MESSAGE);
    }
    // PrintToChatAll("%s One deducted from playercount! It is now \x0C%i\x01", TAG_MESSAGE, i_PlayerCount); // Debug
} 

public void OnMapStart() 
{
    ServerCommand("mp_warmuptime 999999"); // I could look at forcing the "m_bWarmupPeriod" offset to 1.
    ServerCommand("mp_restartgame 1");
    i_PlayerCount = 0;
    i_PlayersNeeded = 2;
    b_LimitReached = false; 
} 

public void OnMapEnd() 
{ 
    i_PlayerCount = 0;
    i_PlayersNeeded = 2;
    b_LimitReached = false; 
}  
