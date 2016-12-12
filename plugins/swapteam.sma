#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <engine>
#include <fun>

#define PLUGIN "SwapTeam"
#define VERSION "1.0"
#define AUTHOR "WeeDzCokie"

new gSwapTeamsRoundEnd
new gScoreTeam1,gScoreTeam1_t // At start of map, T
new gScoreTeam2,gScoreTeam2_t // At start of map, CT
new gTeamSwapped
new gMaxPlayers

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_logevent("LogEventRoundStart", 2, "1=Round_Start")
	register_logevent("LogEventRoundEnd",2,"1=Round_End")
	register_logevent("ResetScore",2,"1=Game_Commencing")
	register_event("TeamScore","EventTScore", "a","1=TERRORIST")
	register_event("TeamScore","EventCTScore", "a","1=CT")
	gMaxPlayers = get_maxplayers()
}

public ResetScore() {
	gScoreTeam1_t = 0
	gScoreTeam1 = 0
	gScoreTeam2_t = 0
	gScoreTeam2 = 0
}
public EventTScore() {
	if (gTeamSwapped) {
		if (gScoreTeam1 != read_data(2))
			gScoreTeam2_t++
		gScoreTeam1 = read_data(2)
	} else {
		if (gScoreTeam1 != read_data(2))
			gScoreTeam1_t++
		gScoreTeam1 = read_data(2)
	}
	return PLUGIN_HANDLED
}
public EventCTScore() {
	if (gTeamSwapped) {
		if (gScoreTeam2 != read_data(2))
			gScoreTeam1_t++
		gScoreTeam2 = read_data(2)
	} else {
		if (gScoreTeam2 != read_data(2))
			gScoreTeam2_t++
		gScoreTeam2 = read_data(2)
	}
	return PLUGIN_HANDLED
}

public LogEventRoundStart() {
	new team1[32],team2[32]
	if (gTeamSwapped) {
		team1 = "CT"
		team2 = "T"
	} else {
		team1 = "T"
		team2 = "CT"
	}
	client_print(0,3,"Scoreboard - Team 1(%s): %d - Team 2(%s): %d",team1,gScoreTeam1_t,team2,gScoreTeam2_t)
	if (gSwapTeamsRoundEnd) {
		new bombT
		new CsTeams:team
		gSwapTeamsRoundEnd = 0
		for (new i = 1; i < gMaxPlayers; i++) {
			if (!is_user_connected(i)) {
				continue;
			}
			team = cs_get_user_team(i)
			strip_user_weapons(i)
			give_item(i,"weapon_knife")
			cs_set_user_armor(i,0,CS_ARMOR_NONE)
			if (team == CS_TEAM_T) {
				bombT = i
				give_item(i,"weapon_glock18")
				cs_set_user_bpammo(i,17,40)
				cs_set_user_defuse(i,0)
			} else if (team == CS_TEAM_CT) {
				give_item(i,"weapon_usp")
				cs_set_user_bpammo(i,16,24)
			}
			set_pdata_int(i, 116, 0);
			cs_set_user_money(i,get_cvar_num("mp_startmoney"))
		}
		give_item(bombT,"weapon_c4")
		cs_set_user_plant(bombT)
	}
	// Check time limit, time_left < (time_limt/2 + round_time): swap teams next round start
	if (!gTeamSwapped) {
		new timelimit = get_cvar_num("mp_timelimit") * 60
		new roundtime = get_cvar_num("mp_roundtime") * 60
		if (get_timeleft() < timelimit/2 + roundtime/2) {
			log_amx("Swapping teams next round")
			static szHud[1102]
			format(szHud,45,"Swapping teams next round")
			set_hudmessage(200,100,0,-1.0,0.6,0,0.0,10.0,0.0,0.0,-1)
			client_print(0,3,"Swapping teams next round")
			show_hudmessage(0,szHud)
			
			gSwapTeamsRoundEnd = 1
		}
	}
}
public LogEventRoundEnd() {
	new team1[32],team2[32]
	if (gTeamSwapped) {
		team1 = "CT"
		team2 = "T"
	} else {
		team1 = "T"
		team2 = "CT"
	}
	client_print(0,3,"Scoreboard - Team 1(%s): %d - Team 2(%s): %d",team1,gScoreTeam1_t,team2,gScoreTeam2_t)
	if (gSwapTeamsRoundEnd && !gTeamSwapped) {
		SwapTeams()
	}
}

public SwapTeams() {
	for (new i = 1; i < gMaxPlayers; i++) {
		if (!is_user_connected(i)) {
			continue;
		}
		switch(cs_get_user_team(i)) {
			case CS_TEAM_CT:
				cs_set_user_team(i,CS_TEAM_T)
			case CS_TEAM_T:
				cs_set_user_team(i,CS_TEAM_CT)
		}
		cs_set_user_money(i,0)
		strip_user_weapons(i)
	}
	set_task(0.1, "tskRemoveWeapons")
	gTeamSwapped = 1
}

public tskRemoveWeapons() {
	remove_entity_name("weaponbox")
	remove_entity_name("item_thighpack")
}