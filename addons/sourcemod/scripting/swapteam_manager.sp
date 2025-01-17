#include	<multicolors>
#include	<tklib>

#pragma		semicolon	1
#pragma		newdecls	required

public	Plugin	myinfo	=	{
	name		=	"[ANY] SwapTeam Manager",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Manage and swap players teams",
	version		=	"1.3.1",
	url			=	"https://steamcommunity.com"
}

/*
 *	This plugin is a standalone version of swapteam module part of my All-In-One Plugin "Random Commands Plugin" (Unreleased)
*/

char Prefix[64];

ConVar	swapNotifySwapTeam, swapNotifySpecTeam, swapNotifyExchangeTeam, swapNotifyForceTeam, swapNotifyScramble, swapInstant, swapInstantScramble, swapUpdateModel;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)	{
		//Fixes a bug that for some reason recalls 'CS_UpdateClientModel' as required native in non-cs games. even though this is not an issue in any other plugins.
	MarkNativeAsOptional("CS_UpdateClientModel");
}

public void OnPluginStart()	{
	//Getting the translations & plugin prefix-tag
	LoadTranslations("common.phrases");
	LoadTranslations("swapteam_manager.phrases");
	
	//Registering commands
	RegAdminCmd("sm_swap",			SwapTeamPlayer,		ADMFLAG_SLAY,	"Swap a player to a team");
	RegAdminCmd("sm_swapteam",		SwapTeamPlayer,		ADMFLAG_SLAY,	"Swap a player to a team");
	RegAdminCmd("sm_switch",		SwapTeamPlayer,		ADMFLAG_SLAY,	"Swap a player to a team");
	RegAdminCmd("sm_switchteam",	SwapTeamPlayer,		ADMFLAG_SLAY,	"Swap a player to a team");
	
	RegAdminCmd("sm_exchange",		ExchangeTeamPlayer,	ADMFLAG_SLAY,	"Exchange a players team to another players team");
	
	RegConsoleCmd("sm_spec",		SpecTeam,							"Switch to spectator team");
	RegAdminCmd("sm_switchspec",	SpecTeamPlayer,		ADMFLAG_SLAY,	"Switch player to spectator");
	RegAdminCmd("sm_swapspec",		SpecTeamPlayer,		ADMFLAG_SLAY,	"Switch player to spectator");
	
	RegAdminCmd("sm_forceteam",		ForceClientTeam,	ADMFLAG_ROOT,	"Force a team index number on a client");
	
	RegAdminCmd("sm_scramble",		ScramblePlayer,		ADMFLAG_SLAY,	"Scramble a player to a random team");
	RegAdminCmd("sm_scrambleteams",	ScrambleTeams,		ADMFLAG_SLAY,	"Scramble players to a random team");
	
	//Notification ConVars
	swapNotifySwapTeam		=	CreateConVar("sm_swapteam_notify_swapteam",		"0",	"SwapTeam Manager - Notify to everyone or just the client for chat team changes. 0 Displays only for client.",
	_, true, 0.0, true, 1.0);
	swapNotifySpecTeam		=	CreateConVar("sm_swapteam_notify_specteam",		"0",	"SwapTeam Manager - Notify to everyone or just the client for spec team changes. 0 Displays only for client.",
	_, true, 0.0, true, 1.0);
	swapNotifyExchangeTeam	=	CreateConVar("sm_swapteam_notify_exchangeteam",	"0",	"SwapTeam Manager - Notify to everyone or just the client for exhcnage team changes. 0 Displays only for client.",
	_, true, 0.0, true, 1.0);
	swapNotifyForceTeam		=	CreateConVar("sm_swapteam_notify_forceteam",	"0",	"SwapTeam Manager - Notify to everyone or just the client for force team changes. 0 Displays only for client.",
	_, true, 0.0, true, 1.0);
	swapNotifyScramble		=	CreateConVar("sm_swapteam_notify_scramble",		"0",	"SwapTeam Manager - Notify to everyone or just the client for scramble. 0 Displays only for client.",
	_, true, 0.0, true, 1.0);
	
	//Determine if the team swap shall be instant
	swapInstant			=	CreateConVar("sm_swapteam_instant",				"0",	"SwapTeam Manager - Determine wheter the team switch should be instant or not",
	_, true, 0.0, true, 1.0);
	swapInstantScramble	=	CreateConVar("sm_swapteam_instant_scramble",	"0",	"SwapTeam Manager - Determine wheter the scramble team switch should be instant or not",
	_, true, 0.0, true, 1.0);
	
	switch(IdentifyGame())	{
		case	Game_CSS, Game_CSGO, Game_CSPromod:
		//Checks if the game is CSGO or CSS for the update playermodel function
		swapUpdateModel			=	CreateConVar("sm_swapteam_updatemodel",	"1",	"Determine if the client model should be updated upon instant team swap");
	}
	
	ConVar	PrefixTag	=	CreateConVar("sm_swapteam_prefix",	"{lightgreen}SwapTeam",	"SwapTeam Manager - The prefix tag.");
	PrefixTag.AddChangeHook(PrefixTagCvar);
	
	AutoExecConfig(true, "plugin.swapteam_manager");	
}

void PrefixTagCvar(ConVar cvar, const char[] oldvalue, const char[] newvalue)	{
	Format(Prefix, sizeof(Prefix), "%s{default}", newvalue);
}

Action SwapTeamPlayer(int client, int args)	{
	switch(IdentifyGame() == Game_TF2C)	{
		case	true:	{
			if(args != 2)	{
				CPrintToChat(client, "%s %t", Prefix, "Swap team tf2c usage");
				return Plugin_Handled;
			}
		}
		case	false:	{
			if(args != 1)	{
				CPrintToChat(client, "%s %t", Prefix, "Swap team usage");
				return Plugin_Handled;
			}
		}
	}
	
	char arg1[64], arg2[64], teamname[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	int target = GetClientOfPlayername(arg1);
	
	switch(IdentifyGame())	{
		case	Game_TF2:	{
			switch(TF2_GetClientTeam(target))	{
				case	TFTeam_Unassigned:	return	Plugin_Handled;					
				case	TFTeam_Spectator:	swapInstant.BoolValue ? SetClientTeamNum(target, GetRandomInt(2, 3)):ChangeClientTeam(target, GetRandomInt(2, 3));
				case	TFTeam_Red:			swapInstant.BoolValue ? SetClientTeamNum(target, 3):TF2_ChangeClientTeam(target, TFTeam_Blue);
				case	TFTeam_Blue:		swapInstant.BoolValue ? SetClientTeamNum(target, 2):TF2_ChangeClientTeam(target, TFTeam_Red);
			}
			
			strcopy(teamname, sizeof(teamname), TF2_GetTeamStringName[TF2_GetClientTeam(client)]);
		}
		case	Game_TF2C:	{
			if(StrContainsEx(arg2, "Ran", false))
				swapInstant.BoolValue ? SetClientTeamNum(target, GetRandomInt(2, 5)):ChangeClientTeam(target, GetRandomInt(2, 5));
			
			if(StrContainsEx(arg2, "Yel Ylw", false) && TF2_GetClientTeam(target) != TFTeam_Yellow)
				swapInstant.BoolValue ? SetClientTeamNum(target, 5):TF2_ChangeClientTeam(target, TFTeam_Yellow);
			
			if(StrContainsEx(arg2, "Gre Grn", false) && TF2_GetClientTeam(target) != TFTeam_Green)
				swapInstant.BoolValue ? SetClientTeamNum(target, 4):TF2_ChangeClientTeam(target, TFTeam_Green);
			
			if(StrContainsEx(arg2, "Blu", false) && TF2_GetClientTeam(target) != TFTeam_Blue)
				swapInstant.BoolValue ? SetClientTeamNum(target, 3):TF2_ChangeClientTeam(target, TFTeam_Blue);
			
			if(StrContainsEx(arg2, "Red", false) && TF2_GetClientTeam(target) != TFTeam_Red)
				swapInstant.BoolValue ? SetClientTeamNum(target, 2):TF2_ChangeClientTeam(target, TFTeam_Red);
			
			strcopy(teamname, sizeof(teamname), TF2_GetTeamStringName[TF2_GetClientTeam(target)]);
		}
		case	Game_CSS, Game_CSGO, Game_CSPromod:	{
			switch(CS_GetClientTeam(target))	{
				case	CSTeam_Unassigned:	return Plugin_Handled;
				case	CSTeam_Spectator:	swapInstant.BoolValue ? SetClientTeamNum(target, GetRandomInt(2, 3)):ChangeClientTeam(target, GetRandomInt(2, 3));
				case	CSTeam_Terrorist:	swapInstant.BoolValue ? SetClientTeamNum(target, 3):CS_ChangeClientTeam(target, CSTeam_CTerrorist);
				case	CSTeam_CTerrorist:	swapInstant.BoolValue ? SetClientTeamNum(target, 2):CS_ChangeClientTeam(target, CSTeam_Terrorist);
			}
			
			if(swapUpdateModel.BoolValue)
				CS_UpdateClientModel(target);
			
			strcopy(teamname, sizeof(teamname), IdentifyGame() == Game_CSGO ? CSGO_GetTeamStringName[CS_GetClientTeam(target)]:CSS_GetTeamStringName[CS_GetClientTeam(target)]);
		}
		case	Game_L4D1, Game_L4D2:	{
			switch(L4D_GetClientTeam(target))	{
				case	L4DTeam_Unassigned:	return	Plugin_Handled;
				case	L4DTeam_Spectator:	swapInstant.BoolValue ? SetClientTeamNum(target, GetRandomInt(2, 3)):ChangeClientTeam(target, GetRandomInt(2, 3));
				case	L4DTeam_Survivor:	swapInstant.BoolValue ? SetClientTeamNum(target, 3):L4D_ChangeClientTeam(target, L4DTeam_Infected);
				case	L4DTeam_Infected:	swapInstant.BoolValue ? SetClientTeamNum(target, 2):L4D_ChangeClientTeam(target, L4DTeam_Survivor);
			}
			
			strcopy(teamname, sizeof(teamname), L4D_GetTeamStringName[L4D_GetClientTeam(target)]);
		}
		case	Game_DODS:	{
			switch(DOD_GetClientTeam(target))	{
				case	DODTeam_Unassigned:	return	Plugin_Handled;
				case	DODTeam_Spectator:	swapInstant.BoolValue ? SetClientTeamNum(target, GetRandomInt(2, 3)):ChangeClientTeam(target, GetRandomInt(2, 3));
				case	DODTeam_Red:		swapInstant.BoolValue ? SetClientTeamNum(target, 3):DOD_ChangeClientTeam(target, DODTeam_Blue);
				case	DODTeam_Blue:		swapInstant.BoolValue ? SetClientTeamNum(target, 2):DOD_ChangeClientTeam(target, DODTeam_Red);
			}
			
			strcopy(teamname, sizeof(teamname), DOD_GetTeamStringName[DOD_GetClientTeam(target)]);
		}
	}
	
	swapNotifySwapTeam.BoolValue ?
	CPrintToChatAll("%s %t", Prefix, "Swap team event", client, target, teamname):
	CPrintToChat(client, "%s %t", Prefix, "Swap team event", client, target, teamname);

	return Plugin_Handled;	
}

Action SpecTeamPlayer(int client, int args)	{
	if(args != 1)	{
		CPrintToChat(client, "%s %t", Prefix, "Swap team spec usage");
		return Plugin_Handled;
	}
		
	char arg1[64], teamname[128];	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = GetClientOfPlayername(arg1);
	if(!IsValidClient(target))	{
		CPrintToChat(client, "%s %t", Prefix, "Invalid target", target);
		return	Plugin_Handled;
	}
	
	//Checks if you're already in spectator team
	if(GetClientTeam(target) != 1)
		ChangeClientTeam(target, 1);
	
	swapNotifySpecTeam.BoolValue ?
	CPrintToChatAll("%s %t", Prefix, "Swap team event", client, target, teamname):
	CPrintToChat(client, "%s %t", Prefix, "Swap team event", client, target, teamname);

	return Plugin_Handled;	
}

Action ExchangeTeamPlayer(int client, int args)	{
	if(args != 2)	{
		CPrintToChat(client, "%s %t", Prefix, "Exchange team usage");
		return	Plugin_Handled;
	}
	
	char arg1[64], arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	int target1 = GetClientOfPlayername(arg1), target2 = GetClientOfPlayername(arg2);
	if(!IsValidClient(target1))	{
		CPrintToChat(client, "%s %t", Prefix, "Invalid target");
		return	Plugin_Handled;
	}
	if(!IsValidClient(target2))	{
		CPrintToChat(client, "%s %t", Prefix, "Invalid target2");
		return	Plugin_Handled;
	}

	char teamname1[256], teamname2[256];
	
	int team1 = GetClientTeam(target1), team2 = GetClientTeam(target2);
	
	if(team1 == team2)	{
		CPrintToChat(client, "%s %t", Prefix, "Exchange team error", target1, target2);
		return	Plugin_Handled;
	}
		
	switch(GetEngineVersion())	{
		case	Engine_TF2:	{
			SetClientTeamNum(target1, team2);
			SetClientTeamNum(target2, team1);
			strcopy(teamname1, sizeof(teamname1), TF2_GetTeamStringName[team1]);
			strcopy(teamname2, sizeof(teamname2), TF2_GetTeamStringName[team2]);
		}
		case	Engine_CSS,Engine_CSGO:	{
			swapInstant.BoolValue ? SetClientTeamNum(target1, team2):ChangeClientTeam(target1, team2);
			swapInstant.BoolValue ? SetClientTeamNum(target2, team1):ChangeClientTeam(target2, team1);
			
			if(swapUpdateModel.BoolValue)	{
				CS_UpdateClientModel(target1);
				CS_UpdateClientModel(target2);
			}
			
			strcopy(teamname1, sizeof(teamname1), IdentifyGame() == Game_CSGO ? CSGO_GetTeamStringName[team1]:CSS_GetTeamStringName[team1]);
			strcopy(teamname2, sizeof(teamname2), IdentifyGame() == Game_CSGO ? CSGO_GetTeamStringName[team2]:CSS_GetTeamStringName[team2]);
		}
	}
	
	swapNotifyExchangeTeam.BoolValue ?
	CPrintToChatAll("%s %t", Prefix, "Exchange team", client, target1, teamname2, target2, teamname1):
	CPrintToChat(client, "%s %t", Prefix, "Exchange team", client, target1, teamname2, target2, teamname1);
	
	return	Plugin_Handled;
}

Action	SpecTeam(int client, int args)	{
	ChangeClientTeam(client, 1);
}

Action ForceClientTeam(int client, int args)	{
	if(args != 2)	{
		CPrintToChat(client,	"%s %t", Prefix, "Forceteam usage");
		return Plugin_Handled;
	}
	
	char arg1[64], arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int value, limit = 0, target = GetClientOfPlayername(arg1);
	if(!IsValidClient(target))	{
		CPrintToChat(client, "%s %t", Prefix, "Invalid target");
		return	Plugin_Handled;
	}
	
	switch(IdentifyGame())	{
		case	Game_TF2C: limit = 5;
		default: limit = 3;
	}
	
	if(value < 0)	{
		CPrintToChat(client, "%s %t", Prefix, "Forceteam error too low");
		return	Plugin_Handled;
	}
	else if(value > limit)	{
		CPrintToChat(client, "%s %t", Prefix, "Forceteam error too high", limit);
		return	Plugin_Handled;
	}
	

	
	SetClientTeamNum(target, value);
	
	swapNotifyForceTeam.BoolValue ?
	CPrintToChatAll("%s %t", Prefix, "Forceteam event", client, value, target):CPrintToChat(client, "%s %t", Prefix, "Forceteam event", client, value, target);
	
	return	Plugin_Handled;
}

Action ScramblePlayer(int client, int args)	{
	if(args != 1)	{
		CPrintToChat(client, "%s %t", Prefix, "Scramble player usage");
		return	Plugin_Handled;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = GetClientOfPlayername(arg1);
	if(!IsValidClient(target))	{
		CPrintToChat(client, "%s %t", Prefix, "Invalid target");
		return	Plugin_Handled;
	}
	
	int	teams = 0;
	switch(IdentifyGame())	{
		case	Game_TF2C:	teams = 5;
		default:	teams = 3;
	}
		
	swapInstantScramble.BoolValue ? SetClientTeamNum(target, GetRandomInt(2, teams)):ChangeClientTeam(target, GetRandomInt(2, teams));
	
	swapNotifyScramble.BoolValue ? CPrintToChatAll("%s %t", Prefix, "Scramble player", client, target):CPrintToChat(client, "%s %t", Prefix, "Scramble player", target);
	
	return Plugin_Handled;
}

Action ScrambleTeams(int client, int args)	{
	for(int i = 0; i < MaxClients; i++)	{
		if(!IsValidClient(i))
			continue;
		
		int	teams;
		switch(IdentifyGame())	{
			case Game_TF2C: teams = 5;
			default: teams = 3;
		}
		
		swapInstantScramble.BoolValue ? SetClientTeamNum(i, GetRandomInt(2, teams)):ChangeClientTeam(i, GetRandomInt(2, teams));
	}
	
	swapNotifyScramble.BoolValue ?
	CPrintToChatAll("%s %t", Prefix, "Scramble teams event"):CPrintToChat(client, "%s %t", Prefix, "Scramble teams event");
	
	return Plugin_Handled;
}

bool IsValidClient(int client, bool MustBeAlive=false)	{
	if(client == 0 || client == -1)
		return	false;
	if(client < 1 || MaxClients)
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(!IsPlayerAlive(client) && MustBeAlive)
		return	false;
	return	true;
}
