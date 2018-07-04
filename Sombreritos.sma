#include <amxmodx>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <adv_vault>

#define PLUGIN  "HATS"
#define VERSION "1.0"
#define AUTHOR  "Sugisaki"

#define MAX_ITEMS 	32

new const FILE_HATS[] = "hats.ini"

enum _:E_FIELDS
{
	HAT = 0,
	MODEL,
	COINS
}

new g_fields[E_FIELDS];
new g_vault;
new ent_hat[33]
new pCoins[33]

new bool:g_pHats[33][MAX_ITEMS]
new bool:g_pModels[33][MAX_ITEMS]

new Array:g_hats
new Array:g_hats_name
new Array:g_hats_costo
new Array:g_models
new Array:g_models_name
new Array:g_models_costo

new bool:DataLoaded[33]

new callback_hats
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("joinclass", "OnJoinClass")
	register_vault();
	register_clcmd("say /hats", "OnCallHats")
	register_clcmd("say /spuntos", "CGame_SPuntos")
	callback_hats = menu_makecallback("mc_hats_buy")
}

public client_putinserver(id)
{
	set_task(10.0, "MonedasTest", id);
}

public MonedasTest(id)
{
	add_coins(id, 30)
	client_print_color(id, print_team_default, "^4[MultiMOD Sunshine]^1 Has recibido monedas de manera temporal.");
}

register_vault()
{
	g_vault = adv_vault_open("hats")
	g_fields[HAT]	= adv_vault_register_field(g_vault, "hats", DATATYPE_STRING, 128)
	g_fields[MODEL]	= adv_vault_register_field(g_vault, "models", DATATYPE_STRING, 128)
	g_fields[COINS]	= adv_vault_register_field(g_vault, "coins", DATATYPE_INT)
	adv_vault_init( g_vault)
}
set_hat(id, hat_id)
{
	if(ent_hat[id] <= 0)
	{
		new ent = create_entity("info_target")
		ent_hat[id] = ent
		entity_set_string(ent, EV_SZ_classname, "player_hat")
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW)
		entity_set_edict(ent, EV_ENT_aiment, id)
		entity_set_edict(ent, EV_ENT_owner, id)
	}
	if(0 <= hat_id < ArraySize( g_hats))
	{
		if(is_valid_ent(ent_hat[id]))
		{
			new hat_loc[68]
			ArrayGetString( g_hats, hat_id, hat_loc, charsmax(hat_loc))
			engfunc(EngFunc_SetModel, ent_hat[id], hat_loc)
		}
	}
	else if(hat_id < 0)
	{
		if(is_valid_ent(ent_hat[id]))
		{
			remove_entity(ent_hat[id])
		}
		ent_hat[id] = 0
	}
}
public plugin_precache()
{
	new config[128]
	get_localinfo("amxx_configsdir", config, charsmax(config))
	formatex(config[ strlen(config) ], charsmax(config), "/%s", FILE_HATS)
	if(! file_exists(config))
	{
		set_fail_state("Archivo de configuracion: ^"%s^" no existe", config)
		return
	}
	new fh = fopen( config, "r")
	if(!fh)
	{
		set_fail_state("No se pudo abrir el Archivo de configuracion")
		return
	}
	new line[256], parse1[128], parse2[128],precache_mode,parse3[10]
	g_hats = ArrayCreate(68,MAX_ITEMS)
	g_hats_name = ArrayCreate(68,MAX_ITEMS)
	g_hats_costo = ArrayCreate(1, MAX_ITEMS)
	g_models_costo = ArrayCreate(1, MAX_ITEMS)
	g_models = ArrayCreate(68,MAX_ITEMS)
	g_models_name = ArrayCreate(68,MAX_ITEMS)
	while(!feof(fh))
	{
		fgets(fh, line, charsmax(line))
		trim(line)
		if(!line[0] || line[0] == ';')
		{
			continue;
		}
		if(line[0] == '[')
		{
			if(equali(line,"[HATS]"))
			{
				precache_mode = 1;
				continue;
			}
			else if(equali(line,"[MODELS]"))
			{
				precache_mode = 2;
				continue
			}
			else
			{
				precache_mode = 0;
			}
		}
		if(!(1<=precache_mode<=2))
		{
			continue;
		}
		parse(line, parse1, charsmax(parse1), parse2, charsmax(parse2), parse3, charsmax(parse3))
		trim(parse1)
		trim(parse2)
		trim(parse3)
		if(! parse3[0])
		{
			copy(parse3, charsmax(parse3), "0")
		}
		if(!is_str_num(parse3))
		{
			log_amx("Solo Se Admiten Numeros en el costo [ITEM: %s]", parse1)
			continue;
		}
		switch(precache_mode)
		{
			case 1 :
			{
				if( ArraySize( g_hats_name) >= MAX_ITEMS)
				{
					log_amx("Se Alcanzo el numero maximo de items en HATS")
					precache_mode = 2;
					continue;
				}
				if(! file_exists(parse2))
				{
					log_amx("Modelo %s No existe", parse2) 
					continue;
				}
				ArrayPushString( g_hats, parse2)
				ArrayPushString( g_hats_name, parse1)
				ArrayPushCell( g_hats_costo , str_to_num(parse3))
				precache_model(parse2);
			}
			case 2 :
			{
				if( ArraySize( g_models_name) >= MAX_ITEMS)
				{
					log_amx("Se Alcanzo el numero maximo de items en HATS")
					break;
				}
				ArrayPushString( g_models_name, parse1)
				formatex(parse1, charsmax(parse1), "models/%s/%s.mdl", parse2, parse2)
				if(! file_exists(parse1))
				{
					log_amx("Modelo %s No existe", parse1)
					ArrayDeleteItem( g_models_name, ArraySize( g_models_name) - 1);
					continue;
				}
				precache_model(parse1)
				formatex(parse1, charsmax(parse1), "models/%s/%sT.mdl", parse2, parse2)
				if( file_exists(parse1))
				{
					precache_model(parse1)
				}
				ArrayPushString( g_models, parse2)
				ArrayPushCell( g_models_costo , str_to_num(parse3))
			}
		}
	}
	fclose(fh)
}
stock add_coins(id, amount)
{
	if(!(1<=id  <= get_maxplayers()))
	{
		return false;
	}
	pCoins[id] += amount
	return true
}

stock bool:rest_coins(id, amount)
{
	if(! (1<= id <= get_maxplayers()) || pCoins[id] < amount)
	{
		return false
	}
	pCoins[id] -= amount
	return true
}

public plugin_natives()
{
	register_native("add_coins", "_native_add_coins")
	register_native("rest_coins", "_native_rest_coins")
	register_native("get_coins", "_native_get_coins")
}
public _native_add_coins()
{
	add_coins( get_param(1), get_param(2))
}
public _native_rest_coins()
{
	return rest_coins( get_param(1), get_param(2))
}

public _native_get_coins()
{
	if(1<= get_param(1) <= get_maxplayers())
	{
		return pCoins[get_param(1)]
	}
	return 0;
}
stock explode(const string[], const delimiter[] = " ", output[][], array_len ,out_lent)
{
	new temp[128]
	copy(temp, charsmax(temp), string)
	for(new i = 0 ; i <= array_len ; i++)
	{
		split(temp, output[i], out_lent, temp, charsmax(temp), delimiter)
	}
}
public load(id)
{
	if(DataLoaded[id])
	{
		return
	}
	new name[33]
	get_user_name(id, name, charsmax(name))
	DataLoaded[id] = true
	arrayset( g_pHats[id], false, 33)
	if(! adv_vault_get_prepare( g_vault, 0, name))
	{
		return;
	}
	new temp[128]
	adv_vault_get_field( g_vault, g_fields[ HAT], temp, charsmax(temp));
	SplitSpring(id, temp, g_pHats)
	adv_vault_get_field( g_vault, g_fields[ MODEL], temp, charsmax(temp))
	SplitSpring(id, temp, g_pModels)
	pCoins[id] = adv_vault_get_field( g_vault, g_fields[ COINS])
}
SplitSpring(id, temp[], bool:outarray[33][])
{
	new temp2[ MAX_ITEMS][3]
	explode(temp, ",", temp2, charsmax(temp2), charsmax(temp2[]));
	new i = 0; 
	for( i = 0 ; i < MAX_ITEMS ; i++)
	{
		trim(temp2[i])
		if(!temp2[i][0])
		{
			continue
		}
		outarray[id][ str_to_num(temp2[i])] = true
	}
}
stock implode(bool:array[], array_len, outstr[], outstr_len)
{
	new len = 0;
	for(new i = 0 ; i < array_len ; i++)
	{
		if(len >= outstr_len)
		{
			break;
		}
		if(array[i])
		{
			if(len > 0)
			{
				len = formatex(outstr[len], outstr_len, ",%i", i)
			}
			else
			{
				len = formatex(outstr, outstr_len, "%i", i)
			}
		}
	}
	return 1;
}
public save(id)
{
	adv_vault_set_start( g_vault)
	adv_vault_set_field( g_vault, g_fields[ COINS], pCoins[id])
	new str[128]
	implode(g_pHats[id], charsmax(g_pHats[]), str, charsmax(str))
	adv_vault_set_field( g_vault, g_fields[ HAT], str)
	implode( g_pModels[id], charsmax( g_pModels[]), str, charsmax(str))
	adv_vault_set_field( g_vault, g_fields[ MODEL], str)
	new name[32]
	get_user_name(id, name, charsmax(name))
	adv_vault_set_end( g_vault, 0, name)
}
public client_disconnected(id)
{
	save(id)
	DataLoaded[id] = false
}
public OnJoinClass(id)
{
	load(id)
}
public client_connect(id)
{
	DataLoaded[id] = false
}
public OnCallHats(id)
{
	if(! DataLoaded[id])
	{
		return
	}
	new menu = menu_create("Menu general de sombreros", "mh_hatsmenu")
	menu_additem(menu, "Acceder a la tienda de sombreros")
	menu_additem(menu, "Ver mis sombreros comprados")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu)
}
public mh_hatsmenu(id, menu, item)
{
	if(item == MENU_EXIT || ! DataLoaded[id])
	{
		menu_destroy(menu)
		return
	}
	menu_destroy(menu)
	new i = 0
	new num[4]
	switch(item)
	{
		case 0 : 
		{
			menu = menu_create(fmt("\wMenu de compra de sombreros^n\wPosees: \y%i SCoins", pCoins[id]), "mh_buyhat")
			for(i = 0 ; i < ArraySize( g_hats_name) ; i++)
			{
				num_to_str(i, num, charsmax(num))
				if( g_pHats[id][i])
				{
					menu_additem(
						menu, 
						fmt("%a \y[Comprado]", ArrayGetStringHandle( g_hats_name, i)),
						num, 
						0, 
						callback_hats
						);
				}
				else if( ArrayGetCell( g_hats_costo, i) > pCoins[id])
				{
					menu_additem(
						menu, 
						fmt("%a [%i SCoins\d]", ArrayGetStringHandle( g_hats_name, i), ArrayGetCell( g_hats_costo, i)),
						num, 
						0, 
						callback_hats
						);
				}
				else
				{
					menu_additem(
						menu, 
						fmt("%a \r[\w%i \yC\r]", ArrayGetStringHandle( g_hats_name, i), ArrayGetCell( g_hats_costo, i)),
						num, 
						0, 
						callback_hats
						);
				}
			}
			menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
			menu_display(id, menu)
		}
		case 1 :
		{
			menu = menu_create("Mis sombreros", "mh_select_hat")

			for( i = 0 ; i < ArraySize( g_hats_name) ; i++)
			{
				num_to_str(i, num, charsmax(num))
				menu_additem(menu, "Quitar mi sombrero actual")
				if( g_pHats[id][i])
				{
					menu_additem(menu, fmt("%a", ArrayGetStringHandle( g_hats_name, i)), num);
				}
			}
			menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
			menu_display(id, menu)
		}
	}
}
public mc_hats_buy(id, menu, item)
{
	new info[4], a
	menu_item_getinfo(menu, item, a, info, 3, "", 0, a);
	a = str_to_num(info)
	if( ArrayGetCell( g_hats_costo, a) > pCoins[id] || g_pHats[id][a])
	{
		return ITEM_DISABLED
	}
	return ITEM_ENABLED
}

public mh_buyhat(id, menu, item)
{
	if(item == MENU_EXIT || ! DataLoaded[id])
	{
		menu_destroy(menu)
		return
	}
	new info[4], a
	menu_item_getinfo(menu, item, a, info, 3, "", 0, a);
	menu_destroy(menu)
	a = str_to_num(info)
	if( g_pHats[id][a])
	{
		client_print_color(id, print_team_default, "^4[MultiMOD Sunshine]^1 Ya posees este sombrero.")
		return	
	}
	else if( !rest_coins(id, ArrayGetCell( g_hats_costo, a)))
	{
		client_print_color(id, print_team_default, "^4[MultiMOD Sunshine]^1 No tienes suficientes coins para comprar este sombrero.")
		return;
	}
	g_pHats[id][a] = true
	client_print_color(id, print_team_default, "^4[MultiMOD Sunshine]^1 Compraste el sombrero:^4 %a", ArrayGetStringHandle( g_hats_name, a))
}

public mh_select_hat(id, menu, item)
{
	if(item == MENU_EXIT || ! DataLoaded[id])
	{
		menu_destroy(menu)
		return
	}
	if(item == 0)
	{
		set_hat(id, -1)
		menu_destroy(menu)
		return
	}
	new info[4], a
	menu_item_getinfo(menu, item, a, info, 3, "", 0, a);
	menu_destroy(menu)
	a = str_to_num(info);
	set_hat(id, a);
	client_print_color(id, print_team_default, "^4[MultiMOD Sunshine]^1 Ahora estas usando el sombrero:^4 %a", ArrayGetStringHandle( g_hats_name, a))

}

public CGame_SPuntos(id)
{	
	client_print_color(id, print_team_default, "^4[MultiMOD Sunshine]^1 Tienes^4 %i Sunshine Puntos en tu cuenta", pCoins[id])
}
