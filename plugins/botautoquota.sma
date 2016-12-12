#include <amxmodx>
#include <cstrike>

#define PLUGIN "BotAutoQuota"
#define VERSION "1.0"
#define AUTHOR "WeeDzCokie"

// TODO: Check for message "JOIN_TEAM"? instead of using task

new gNumBots
new gPlayerList[32]
new gNumPlayers
new gBotAutoQuota

new gBot_Quota
new gBot_JoinTeam

public plugin_init() {
	register_plugin(PLUGIN,VERSION,AUTHOR)
	gBot_Quota = get_cvar_pointer("bot_quota")
	gBotAutoQuota = register_cvar("bot_autoquota","10")
	gBot_JoinTeam = get_cvar_pointer("bot_join_team")
	register_event("TeamInfo", "eventJoinTeam","a")
}

public eventJoinTeam() {
	new id = read_data(1)
	
	if (!is_user_connected(id) || is_user_bot(id)) {
		return PLUGIN_CONTINUE
	}
	
	static team[32]
	read_data(2,team,sizeof team)
	//console_print(0, "id: %d, team: %s",id,team)
	
	switch(team[0]) {
		case 'C':
			playerJoinTeamCT(id)
		case 'T':
			playerJoinTeamT(id)
		case 'S':
			playerJoinSpec(id)
	}
	return PLUGIN_CONTINUE
}
public playerJoinTeamCT(id) {
	//console_print(0, "pid: %d, team: CT",id)
	if (!gPlayerList[id]) {
		set_pcvar_string(gBot_JoinTeam,"T")
		playerJoinTeam(id)
	}
}
public playerJoinTeamT(id) {
	//console_print(0, "pid: %d, team: T",id)
	if (!gPlayerList[id]) {
		set_pcvar_string(gBot_JoinTeam,"CT")
		playerJoinTeam(id)
	}
}
public playerJoinTeam(id) {
	gPlayerList[id] = 1
	gNumPlayers++
	set_pcvar_num(gBot_Quota,gNumBots-1)
}
public playerJoinSpec(id) {
	//console_print(0, "pid: %d, team: SPEC",id)
	set_pcvar_string(gBot_JoinTeam,"any")
	gPlayerList[id] = 0
	gNumPlayers--
	set_pcvar_num(gBot_Quota,gNumBots)
}

public client_putinserver(id) {
	
}
public client_disconnected(id) {
	if (!is_user_bot(id)) {
		set_pcvar_string(gBot_JoinTeam,"any")
		
		if (gPlayerList[id]) {
			//gNumBots++
			gNumPlayers--
			set_pcvar_num(gBot_Quota,gNumBots+1)
		}
		gPlayerList[id] = 0
	}
}

public updateBotQuota() {
	
}
