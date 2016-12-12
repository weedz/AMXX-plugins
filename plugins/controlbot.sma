#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define PLUGIN "Control CSBot"
#define VERSION "1.0"
#define AUTHOR "WeeDzCokie"

// DEFINE
#define UPDATEINTERVAL 1.0

// Fix player dies when taking over bot without ever spawning on server

new weaponArray[30][32] = {
	"weapon_p228","weapon_shield","weapon_scout","weapon_hegrenade","weapon_xm1014",
	"weapon_c4","weapon_mac10","weapon_aug","weapon_smokegrenade","weapon_elite",
	"weapon_fiveseven","weapon_ump45","weapon_sg550","weapon_galil","weapon_famas",
	"weapon_usp","weapon_glock18","weapon_awp","weapon_mp5navy","weapon_m249",
	"weapon_m3","weapon_m4a1","weapon_tmp","weapon_g3sg1","weapon_flashbang",
	"weapon_deagle","weapon_sg552","weapon_ak47","weapon_knife","weapon_p90"
}

new gNewRound
new gMaxPlayers;
new targetBot[32] = {-1, ...};
new processBot[32] = {-1,...};
//new gPlayerName[32][64]
new gMsgMoney
new gMsgMoneyHook

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	gMaxPlayers = get_maxplayers()
	register_clcmd("controlbot","cmdControlBot")
	
	register_event("HLTV", "eventNewRound", "a", "1=0", "2=0")
	register_event("DeathMsg","eventDeathMsg", "a")
	RegisterHam(Ham_Spawn,"player","hamPlayerSpawn",1,true)
	
	gMsgMoney = get_user_msgid("Money")
	
	//set_task(UPDATEINTERVAL, "tskSpectating",_,_,_,"b")
}

public plugin_cfg() {
	set_task(UPDATEINTERVAL, "tskSpectating",_,_,_,"b")
	
	return PLUGIN_CONTINUE
}

public eventDeathMsg() {
	new killer = read_data(1)
	new victim = read_data(2)
	if(victim == killer && processBot[victim] != -1 && targetBot[processBot[victim]] != -1) {
		cs_set_user_deaths(victim,cs_get_user_deaths(victim)-1)
		return PLUGIN_HANDLED;
	}
	if (targetBot[victim] != -1) {
		cs_set_user_deaths(targetBot[victim],cs_get_user_deaths(targetBot[victim])+1)
		cs_set_user_deaths(victim,cs_get_user_deaths(victim)-1)
		processBot[targetBot[victim]] = -1
		targetBot[victim] = -1
		return PLUGIN_HANDLED;
	}
	if (targetBot[killer] != -1 && killer != victim && processBot[targetBot[killer]] != -1) {
		set_user_frags(targetBot[killer],get_user_frags(targetBot[killer])+1)
		set_user_frags(killer,get_user_frags(killer)-1)
		
		gMsgMoneyHook = register_message(gMsgMoney, "msgBlockMoney")
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE
}
// Do not give player money for kills using bot
public msgBlockMoney(msgId,msgDest,id) {
	unregister_message(gMsgMoney, gMsgMoneyHook)
	cs_set_user_money(id, cs_get_user_money(id)-300,0)
	cs_set_user_money(targetBot[id], cs_get_user_money(targetBot[id])+150,0)
	return PLUGIN_HANDLED
}

public hamPlayerSpawn(i) {
	if (gNewRound) {
		set_task(0.1,"tskFixBotItems",i)
	}
	
}
public tskFixBotItems(i) {
	if (!is_user_connected(i) || is_user_bot(i)) {
		return PLUGIN_CONTINUE
	}
	if (targetBot[i] != -1) {
		if (processBot[targetBot[i]] == -1) {
			targetBot[i] = -1
			return PLUGIN_CONTINUE
		}
		/*if (!equal(gPlayerName[i],"")) {
			set_user_info(i,"name",gPlayerName[i])
			gPlayerName[i] = ""
		}*/
		
		new num = 0
		new weapons[32]
		get_user_weapons(i,weapons,num)
		strip_user_weapons(i)
		strip_user_weapons(targetBot[i])
		
		new ammo
		
		for (new j = 0; j < sizeof weapons; j++) {
			if (weapons[j] == 0) {
				break;
			}
			if (weapons[j] == 6) {
				continue;
			}
			give_item(targetBot[i],weaponArray[weapons[j]-1])
			if (weapons[j] == 2 || weapons[j] == 4 || weapons[j] == 6 || weapons[j] == 9 || weapons[j] == 25 || weapons[j] == 29) {
				continue;
			}
			ammo = cs_get_user_bpammo(i,weapons[j])
			cs_set_user_bpammo(targetBot[i], weapons[j],ammo)
		}
		
		new CsArmorType:armorType
		new armorValue = cs_get_user_armor(i, armorType)
		cs_set_user_armor(targetBot[i], armorValue, armorType)
		cs_set_user_armor(i,0,armorType)
		cs_set_user_defuse(targetBot[i], cs_get_user_defuse(i))
		cs_set_user_defuse(i, 0)
		give_item(i,"weapon_knife")
		new CsTeams:team = cs_get_user_team(i)
		if (team == CS_TEAM_CT) {
			give_item(i,"weapon_usp")
			cs_set_user_bpammo(i, 16, 24)
		} else if (team == CS_TEAM_T) {
			give_item(i, "weapon_glock18")
			cs_set_user_bpammo(i, 17, 40)
		}
		processBot[targetBot[i]] = -1
		targetBot[i] = -1
	}
	return PLUGIN_CONTINUE
}

public eventNewRound() {
	gNewRound = 1
	set_task(2.0, "tskResetNewRound")
}
public tskResetNewRound() {
	gNewRound = 0
}

public tskSpectating() {
	for (new alive = 1; alive <= gMaxPlayers; alive++) {
		if (!is_user_connected(alive) || !is_user_alive(alive) || !is_user_bot(alive)) {
			continue;
		}
		
		for (new dead = 1; dead <= gMaxPlayers; dead++) {
			if (!is_user_connected(dead) || is_user_alive(dead) || is_user_bot(dead)) {
				continue;
			}
			if (pev(dead, pev_iuser2) == alive) {
				new CsTeams:botTeam = cs_get_user_team(alive)
				if (botTeam != cs_get_user_team(dead)) {
					continue;
				}
				static szHud[1102]
				format(szHud,45,"Type 'controlbot' in console to control bot")
				set_hudmessage(200,100,0,-1.0,0.8,0,0.0,UPDATEINTERVAL+0.1,0.0,0.0,-1)
				show_hudmessage(dead,szHud)
				targetBot[dead] = alive;
				new float:origin[3];
				pev(alive,pev_origin, origin);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public cmdControlBot(id) {
	if (!is_user_alive(id) && targetBot[id] > 0 && is_user_bot(targetBot[id])) {
		new CsTeams:botTeam = cs_get_user_team(targetBot[id])
		if (botTeam != cs_get_user_team(id)) {
			return PLUGIN_HANDLED;
		}
		
		new Float:origin[3];
		new Float:angle[3];
		new Float:velocity[3];
		
		pev(targetBot[id],pev_origin, origin);
		pev(targetBot[id],pev_angles, angle);
		pev(targetBot[id],pev_velocity, velocity);
		
		origin[2] += Float:5.0
		
		//spawn(id)
		
		/*new name[64]
		new botname[32]
		get_user_name(id,name, sizeof name)
		gPlayerName[id] = name
		get_user_name(targetBot[id], botname, sizeof botname)
		format(name, sizeof name, "%s(%s)",botname, name)
		set_user_info(id,"name",name)*/
		
		processBot[targetBot[id]] = id;
		
		new num = 0
		new weapons[32]
		get_user_weapons(targetBot[id],weapons,num)
		
		new ammo[32]
		new i
		for (i = 0; i < num; i++) {
			if (weapons[i] == 2 || weapons[i] == 4 || weapons[i] == 6 || weapons[i] == 9 || weapons[i] == 25 || weapons[i] == 29) {
				continue;
			}
			ammo[i] = cs_get_user_bpammo(targetBot[id],weapons[i])
		}
		
		new health = get_user_health(targetBot[id])
		new CsArmorType:armorType
		new armorValue = cs_get_user_armor(targetBot[id], armorType)
		strip_user_weapons(targetBot[id])
		
		cs_user_spawn(id)
		strip_user_weapons(id)
		
		cs_set_user_defuse(id, cs_get_user_defuse(targetBot[id]))
		cs_set_user_plant(id, cs_get_user_plant(targetBot[id]))
		cs_set_user_vip(id, cs_get_user_vip(targetBot[id]))
		set_msg_block(get_user_msgid("ClCorpse"), BLOCK_ONCE)
		user_silentkill(targetBot[id])
		
		set_pev(id,pev_origin,origin)
		set_pev(id,pev_angles,angle)
		set_pev(id,pev_velocity,velocity)
		
		for (i = 0; i < num; i++) {
			if (weapons[i] == 0) {
				break;
			}
			/*if (weapons[i] == 6) {
				cs_set_user_plant(id)
			}*/
			give_item(id,weaponArray[weapons[i]-1])
			if (weapons[i] == 2 || weapons[i] == 4 || weapons[i] == 6 || weapons[i] == 9 || weapons[i] == 25 || weapons[i] == 29) {
				continue;
			}
			cs_set_user_bpammo(id, weapons[i],ammo[i])
		}
		
		set_user_health(id, health)
		cs_set_user_armor(id, armorValue, armorType)
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public client_disconnected(id) {
	if(targetBot[id] != -1)
		processBot[targetBot[id]] = -1;
	targetBot[id] = -1;
}
public client_connect(id) {
	if (processBot[id] != -1)
		targetBot[processBot[id]] = -1;
	processBot[id] = -1;
}
