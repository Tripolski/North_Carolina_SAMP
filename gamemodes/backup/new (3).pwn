main(){}
#include <a_samp>
#include <streamer>
#include <a_mysql>
#include <mxINI>
#include <dc_cmd>
#include <sscanf2>
#include <foreach>
//------[Системы]-------
#include <pickup.pwn>
#include <cp.pwn>
//------[MySQL]----------
new MySQL:dbHandle;
enum MYSQL_SETTINGS
{
	DOOME_HOST,
	DOOME_USERNAME,
	DOOME_PASSWORD,
	DOOME_DATABASE
}
new MySQLSettings[MYSQL_SETTINGS][30];
new query[1024];
//---------------------
#define function:%0(%1) forward %0(%1); public %0(%1)
#define SCM SendClientMessage
#define SPD ShowPlayerDialog
//----------------------
new Text:TDEditor_TD[32],PlayerText:TDEditor_PTD[MAX_PLAYERS][3],
	Text:login_rp_TD[35],PlayerText:login_rp_PTD[MAX_PLAYERS][2],
	Text:TD_L[5];
//-----------------------
new bool:reg_password[MAX_PLAYERS] = false,bool:reg_email[MAX_PLAYERS] = false;
new PlayerRegistered[MAX_PLAYERS][2],bool:PL[MAX_PLAYERS],bool:AL[MAX_PLAYERS];
new Menu:skinmenu,ChosenSkin[MAX_PLAYERS],SelectCharPlace[MAX_PLAYERS];
static const stock ChoiseSkin[4] = {223,64,198,4};
static const stock ChoiseSkinM[4] = {5,6,7,8};
new PlayerLogTries[MAX_PLAYERS];
//----------------------
#define MAX_FRACTIONS   (11)
static const stock Fraction_Name[MAX_FRACTIONS][20]  = {
	"-",
	"Правительство",
	"Полиция",
	"СМИ",
	"Армия",
	"Больница",
	"Автошкола",
	"FBI",
	"Rifa",
	"Triada",
	"Vietnam"
};
#define TEAM_GOV    (1)
#define TEAM_PD     (2)
#define TEAM_SMI    (3)
#define TEAM_ARMY   (4)
#define TEAM_HOSPITAL   (5)
#define TEAM_AVTO   (6)
#define TEAM_FBI    (7)
#define TEAM_RIFA   (8)
#define TEAM_TRI    (9)
#define TEAM_VT     (10)
//-----------------------
enum pInfo {
	pID,
	pName[MAX_PLAYER_NAME],
	pPassword[32],
	pEmail[20],
	pReferal[MAX_PLAYER_NAME],
	pSex,
	pAdmin,
	pSkin_ID,
	pCash,
	pBank,
	pJob,
	pJobWork,
	pJob_Anim,
	pJob_State,
	pJob_State_2,
	pPlayerTimer,
	pMember,
	pRank
};
new PI[MAX_PLAYERS][pInfo];
#define GN(%0) PI[%0][pName]
#define GetInfo(%0,%1) PI[%0][%1]
#define SetInfo(%0,%1,%2) PI[%0][%1] = %2
#define AddInfo(%0,%1,%2,%3) PI[%0][%1] %2= %3
//--[Уровни администратирования]--
#define ADM_ZGA  (1)
#define ADM_GA   (2)
#define ADM_DEVELOPER (3)
//--------------------------------
enum
{
	dialog_none,
	dialog_register,
	dialog_login,
	dialog_email,
	dialog_sex,
	dialog_referal,
	dialog_errorpass,
	dialog_job,
	dialog_work_start,
	dialog_work,
	dialog_take_tk,
	dialog_alogin
}

enum E_TELEPORT_STRUCT
{
	T_NAME[64],
	Float: T_PICKUP_POS_X,
	Float: T_PICKUP_POS_Y,
	Float: T_PICKUP_POS_Z,
	T_PICKUP_VIRTUAL_WORLD,
	Float: T_POS_X,
	Float: T_POS_Y,
	Float: T_POS_Z,
	Float: T_ANGLE,
	T_INTERIOR,
	T_VIRTUAL_WORLD,
	T_ACTION_TYPE,
	Text3D: T_LABEL
};
enum
{
	CP_ACTION_TYPE_TAKE_Z = 1,
	CP_ACTION_TYPE_PUT_Z,
	CP_ACTION_TYPE_GIVE_Z,
	CP_ACTION_TYPE_JOB_Z,
	CP_ACTION_TYPE_JOB_Z_Z
};
enum
{
	A_OBJECT_SLOT_SPINE = 0, 		// Торс
	A_OBJECT_SLOT_HEAD, 			// Голова
	A_OBJECT_SLOT_ARM, 				// Плечи
	A_OBJECT_SLOT_HAND, 			// Руки
	A_OBJECT_SLOT_THIGH, 			// Бедра
	A_OBJECT_SLOT_FOOT, 			// Ноги
	A_OBJECT_SLOT_CALF, 			// Голень
	A_OBJECT_SLOT_FOREARM, 			// Предплечье
	A_OBJECT_SLOT_CLAVICLE,			// Ключица
	A_OBJECT_SLOT_NECK, 			// Шея
};
enum
{
	A_OBJECT_BONE_SPINE = 1, 		// Торс
	A_OBJECT_BONE_HEAD, 			// Голова
	A_OBJECT_BONE_LEFT_ARM, 		// Левое плечо
	A_OBJECT_BONE_RIGHT_ARM, 		// Правое плечо
	A_OBJECT_BONE_LEFT_HAND, 		// Левая рука
	A_OBJECT_BONE_RIGHT_HAND, 		// Правая рука
	A_OBJECT_BONE_LEFT_THIGH, 		// Левое бедро
 	A_OBJECT_BONE_RIGHT_THIGH,		// Правое бедро
	A_OBJECT_BONE_LEFT_FOOT, 		// Левая нога
	A_OBJECT_BONE_RIGHT_FOOT, 		// Правая нога
	A_OBJECT_BONE_RIGHT_CALF, 		// Правая голень
	A_OBJECT_BONE_LEFT_CALF, 		// Левая голень
	A_OBJECT_BONE_LEFT_FOREARM, 	// Левое предплечье
	A_OBJECT_BONE_RIGHT_FOREARM,	// Правое предплечье
	A_OBJECT_BONE_LEFT_CLAVICLE,	// Левая ключица (плечо)
	A_OBJECT_BONE_RIGHT_CLAVICLE,	// Правая ключица (плечо)
	A_OBJECT_BONE_NECK, 			// Шея
	A_OBJECT_BONE_JAW				// Челюсть
};
enum pWareHouse
{
	factory
};
new PW[pWareHouse];
new Text3D: z_factory;
//----------------------
#define GetTeleportData(%0,%1)		g_teleport[%0][%1]
#define SetTeleportData(%0,%1,%2)	g_teleport[%0][%1] = %2
new g_teleport[8][E_TELEPORT_STRUCT] =
{
// {"3D TEXT",}
	{"Завод\nЦентральный вход",-1836.6434,110.4750,15.1172, 0, 1401.6876,-26.0865,3001.4951,180.000, 1, 1}, // Вход в помещения офиса завода
	{"Раздевалка", 1405.1549,-28.7977,3001.4951, 1, 1405.4655,-33.9996,3001.5098,342.8550, 1, 1}, // Вход в раздевалку
	{"Строительная компания",-2051.1208,450.5173,35.1719,0,1416.1437,-1465.7645,916.8560,180.0,1,1},
	{"",1405.5546,-31.0472,3001.5098,1,1404.4229,-27.5078,3001.4951,10.76,1,1},
	{"",1415.9080,-1463.3682,916.8560,1,-2050.6907,452.9729,35.1719,333.4,0,0},
	{"Риэлторское агенство",-2043.5106,449.0459,35.1723,0,-1933.0280,-147.4610,1036.1940,95.5542,1,1},
	{"",-1931.3108,-146.9209,1036.1940,1,-2043.7488,452.0652,35.1723,2.8,0,0},
	{"",1398.9178,-26.3590,3001.4951,1,-1837.2098,112.8453,15.1172,342.0,0,0}
};
enum
{
	PICKUP_ACTION_TYPE_TELEPORT = 1,
	PICKUP_ACTION_TYPE,
    PICKUP_ACTION_TYPE_WORK,
    PICKUP_ACTION_TYPE_N
}
//--------Colors--------
#define COLOR_WHITE 0xFFFFFFAA
#define COLOR_YELLOW    0xFFFF00AA
#define COLOR_GREEN 0x33AA33FF
#define COLOR_RED   0xBC2C2CFF
#define COLOR_BLUE  0x6495EDFF
#define COLOR_DARKORANGE    0xFF6600FF
#define COLOR_ORANGE    0xFF9900AA
#define COLOR_LIME		0x99cc00FF
//-----------------------
static const stock ClothColor[4][24] = {"{ffcc00}желтую ткань","{FFA500}оранжевую ткань","{008000}зелёную ткань","{DC143C}красную ткань"};
//-----------------------
public OnGameModeInit()
{
    new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	LoadMySQLSettings();
	dbHandle = mysql_connect(MySQLSettings[DOOME_HOST],MySQLSettings[DOOME_USERNAME], MySQLSettings[DOOME_PASSWORD], MySQLSettings[DOOME_DATABASE],option_id);
	mysql_set_charset("utf8_general_ci");
    mysql_tquery(dbHandle, "SET CHARACTER SET 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET NAMES 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET character_set_client = 'utf8'", "", "");
    mysql_tquery(dbHandle, "SET character_set_connection = 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET character_set_results = 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET SESSION collation_connection = 'utf8_general_ci'", "", "");
	//Load
	LoadTextDraws();
	LoadObjects();
	Menu();
	LoadVehicle();
	TeleportPickupsInit();
	//-------
	SendRconCommand("hostname North Carolina RolePlay");
	SendRconCommand("weburl nc-rp.ru");
	SetGameModeText("RP Lite [v0.1]");
	//--------
	CreatePickup(1275, 23,1404.5094,-34.9383,3001.5098,1,0);
	//Таймеры
	SetTimer("timer", 1000, true); // sec
	//Re
	DisableInteriorEnterExits();
    EnableStuntBonusForAll(0);
	//-----
	CreateVehicle(522,-1981.4264,138.5520,27.6875,0,0,0,0);
	//Актеры
	new z_d = CreateActor(17, 1414.5465,-19.5869,3001.4951,181.1418);
	SetActorVirtualWorld(z_d,1);
	//---3DText
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, 1414.3397,-20.8316,3001.4951,20.0,1,1);
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, 1404.5094,-34.9383,3001.5098,20.0,1,1);
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, 1397.7651,-52.3436,3001.4951,20.0,1,1);
	z_factory = CreateDynamic3DTextLabel("{FFa500}Z",COLOR_WHITE, 1397.2087,-56.2949,3001.6,20.0);
	//-
	AddPlayerClass(1, -1981.4264,138.5520,27.6875, 269.1425, 0, 0, 0, 0, 0, 0);
	return 1;
}
function: timer()
{
	new text[55];
	format(text, sizeof text, "{FFA500}Состояние склада:\n%d продукции.", PW[factory]);
 	UpdateDynamic3DTextLabelText(z_factory, 0x79cb64FF, text);
	return 1;
}
stock LoadVehicle()
{
    CreateVehicle(462, -2391.0149, -601.7053, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2402.8796, -584.7465, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2396.1211, -594.4080, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2394.4458, -596.7962, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2392.7361, -599.2426, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2397.8079, -592.0035, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2399.4832, -589.6064, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2401.2158, -587.1272, 132.1472, 125.0000, -1, -1, 100);
	CreateVehicle(462, -2399.6724, -613.2277, 132.1472, 35.0000, -1, -1, 100);
	CreateVehicle(462, -2392.0825, -607.9318, 132.1472, 35.0000, -1, -1, 100);
	CreateVehicle(462, -2394.6016, -609.6895, 132.1472, 35.0000, -1, -1, 100);
	CreateVehicle(462, -2397.1533, -611.4700, 132.1472, 35.0000, -1, -1, 100);
	CreateVehicle(462, -2417.0940, -588.5388, 132.1472, -145.0000, -1, -1, 100);
	CreateVehicle(462, -2409.4387, -583.2258, 132.1472, -145.0000, -1, -1, 100);
	CreateVehicle(462, -2411.9578, -584.9741, 132.1472, -145.0000, -1, -1, 100);
	CreateVehicle(462, -2414.5422, -586.7678, 132.1472, -145.0000, -1, -1, 100);
}

stock LoadObjects()
{
	new object_world = -1,object_int=-1;
	#include <objects/server_job>
	#include <objects/OneWork.pwn>
	#include <objects/server_RL_office.pwn>
}
#define MOVE_SPEED              100.0
#define ACCEL_RATE              0.03
#define CAMERA_MODE_NONE        0
#define CAMERA_MODE_FLY         1
#define MOVE_FORWARD            1
#define MOVE_BACK               2
#define MOVE_LEFT               3
#define MOVE_RIGHT              4
#define MOVE_FORWARD_LEFT       5
#define MOVE_FORWARD_RIGHT      6
#define MOVE_BACK_LEFT          7
#define MOVE_BACK_RIGHT         8
enum noclipenum
{
    cameramode,
    flyobject,
    mode,
    lrold,
    udold,
    lastmove,
    Float:accelmul
}
new noclipdata[MAX_PLAYERS][noclipenum];
public OnGameModeExit()
{
    for(new x; x<MAX_PLAYERS; x++)
    {
        if(noclipdata[x][cameramode] == CAMERA_MODE_FLY) CancelFlyMode(x);
    }
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetTimerEx("users_connect",300,false,"i",playerid);
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid,PI[playerid][pName],MAX_PLAYER_NAME);
	LoadPlayerTD(playerid);
	for(new i; i < 5; i++) TextDrawShowForPlayer(playerid,TD_L[i]);
 	noclipdata[playerid][cameramode]     = CAMERA_MODE_NONE;
    noclipdata[playerid][lrold]                = 0;
    noclipdata[playerid][udold]           = 0;
    noclipdata[playerid][mode]           = 0;
    noclipdata[playerid][lastmove]       = 0;
    noclipdata[playerid][accelmul]       = 0.0;
    PL[playerid] = AL[playerid] = false;
    PI[playerid][pJobWork] = 0;
    DeletePVar(playerid,"job_factory_on");
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    SaveAccounts(playerid);
    RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!PL[playerid]) return Kick(playerid),SCM(playerid,0xFFFFFFAA,"Вы отменили авторизацию/регистрацию");
	SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
	SetPlayerPosEx(playerid,-2379.6804,-580.0637,132.1172,0,0,115.6077);
	GivePlayerMoney(playerid, GetInfo(playerid,pCash));
 	RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);
	if(PlayerRegistered[playerid][1])
	{
	    SetPlayerPosEx(playerid,-2376.3318,-578.2756,133.1120,playerid*10,0,123.0);
	    SCM(playerid,-1,"Выберите одежду");
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new string[100];
	format(string,sizeof(string),"%s[%d] говорит: %s",GN(playerid), playerid,text);
	SCM_I(playerid,string,-1,25.0);
	return 0;
}
CMD:tpcoord(playerid,params[])
{
	if(!PL[playerid]) return 1;
	new Float:x,Float:y,Float:z;
	if(sscanf(params,"P<,>fff",x,y,z)) return SCM(playerid,-1,"Информация: /tpcoord [x,y,z]");
	SetPlayerPos(playerid,x,y,z);
	return 1;
}
CMD:setspawn(playerid,params[])
{
	if(PI[playerid][pAdmin] < 1) return 1;
	if(sscanf(params,"d",params[0])) return SCM(playerid,COLOR_LIME,"Информация: {ffffff}/setspawn");
	SpawnPlayer(params[0]);
	return 1;
}
CMD:skin(playerid,params[])
{
	if(PI[playerid][pAdmin] < 1) return 1;
	if(sscanf(params,"d",params[0])) return SCM(playerid,COLOR_LIME,"Информация:{ffffff} /skin [ID: 1-299]");
	if(params[0] < 0 || params[0] > 299) return SCM(playerid,COLOR_WHITE,"ID: от 1 до 299!");
	SetPlayerSkin(playerid,params[0]);
	SetInfo(playerid,pSkin_ID,params[0]);
	return 1;
}
CMD:ainvite(playerid)
{
	if(PI[playerid][pAdmin] < 1) return 1;
	new string[100],s_string[150];
	for(new i = 1; i < MAX_FRACTIONS; i++)
	{
	    format(string, sizeof(string), "%i.- %s\n", i, Fraction_Name[i]);
    	strcat(s_string, string);
	}
	SPD(playerid, 0, 2, "{FFA500}Организации", s_string, "Выбрать", "Отмена");
	return 1;
}
CMD:stats(playerid) return StatsDialog(playerid, playerid);
CMD:spawn(playerid)
{
	return 1;
}
CMD:tp(playerid)
{
	return 1;
}
CMD:a(playerid)
{
	return 1;
}
CMD:alogin(playerid)
{
	//if(PI[playerid][pAdmin] < 1 ) return 1;
	new string[128];
	format(string, sizeof(string), "SELECT * FROM `a_users` WHERE `a_name` = '%s'", GN(playerid));
	mysql_tquery(dbHandle, string, "alogin", "is", playerid, GN(playerid));
	return 1;
}
function:alogin(playerid,name[MAX_PLAYER_NAME])
{
    new rows, fields;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(!rows) { if(PI[playerid][pAdmin] > 0) return PI[playerid][pAdmin] = 0; }
	new Password[16];
	cache_get_value_name(0, "a_password", Password);
	if(!strcmp(Password, "36592845", true))
	{
		SetPVarInt(playerid, "adm", 1);
		SPD(playerid, dialog_alogin, DIALOG_STYLE_PASSWORD, "{FFa500}Регистрация администратора", "{FFFFFF}Придумайте пароль, который будет использоваться от панели администратора\n\n{63BD4E}Примечание:\n\t- Пароль должен состоять из латинских букв и цифр\n\t- Размер пароля от 6 до 15 символов", "Ввести", "Отмена");
	}
	else
	{
		SetPVarInt(playerid, "adm", 0);
		SPD(playerid, dialog_alogin, DIALOG_STYLE_PASSWORD, "{FFA500}Авторизация администратора", "{FFFFFF}Введите свой пароль от панели администратора\nВ случае утери пароля - обратитесь к выше стоящий администрации!", "Ввести", "Отмена");
	}
	return 1;
}
CMD:fly(playerid)
{
    if(GetPVarType(playerid, "FlyMode")) CancelFlyMode(playerid);
    else FlyMode(playerid);
    return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    new action_type = GetPlayerCPInfo(playerid, CP_ACTION_TYPE),string[200];
	if(IsPlayerInCheckpoint(playerid))
	{
		switch(action_type)
		{
		    case CP_ACTION_TYPE_TAKE_Z:
		    {
		        if(PI[playerid][pJob] == 2)
		        {
		            //if(!GetInfo(playerid,pJob_State_2))
		            //{
		            	format(string,sizeof(string),"{ffcc00}Желтая ткань\n{FFA500}Оранжевая ткань\n{008000}Зелёная ткань\n{DC143C}Красная ткань");
						SPD(playerid,dialog_take_tk,2,"{FFA500}Выберите ткань",string,"Выбрать","Закрыть");
					//}
		        }
		    }
		    case CP_ACTION_TYPE_PUT_Z:
		    {
		        if(GetInfo(playerid,pJob) == 2)
		        {
		        	ApplyAnimation(playerid, "CARRY", "putdwn", 4.1, 1, 0, 1, 0, 800, 0);
		        	SCM(playerid,COLOR_YELLOW,"Вы положили ткань на конвейер. Пожалуйста, подождите!");
					SCM(playerid,COLOR_YELLOW,"После того, как ткань будет готова - упакуйте её в коробку на столе!");
					DisablePlayerCheckpoint(playerid);
					//SetPlayerCheckpoint(playerid, 1403.2104,-59.5703,3000.6, 0.9, CP_ACTION_TYPE_GIVE_Z);
					PI[playerid][pPlayerTimer] = SetTimerEx("d_factory",10_000,false,"i",playerid);
					RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);
                    
		        }
		    }
		    case CP_ACTION_TYPE_GIVE_Z:
		    {
		        //ApplyAnimation(playerid, "INT_HOUSE", "WASH_UP", 4.1, 1, 0, 1, 0, 800, 0);
		        ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 1, 0, 1, 0, 800, 0);
		        SCM(playerid,COLOR_BLUE,"Вы взяли ткань!");
		        DisablePlayerCheckpoint(playerid);
				switch(GetInfo(playerid,pJob_State)+1)
				{
					case 0: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFCC00,0xFFFFCC00);
					case 1: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFA500,0xFFFFA500);
					case 2: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF008000,0xFF008000);
					case 3: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFDC143C,0xFFDC143C);
				}
				SetPVarInt(playerid,"job_factory_on",1);
		    }
		    case CP_ACTION_TYPE_JOB_Z:
		    {
      			ApplyAnimation(playerid, "INT_HOUSE", "WASH_UP", 4.1, 1, 0, 1, 0, 10000, 0);
      			PI[playerid][pPlayerTimer] = SetTimerEx("animation_z",10_000,false,"i",playerid);
		    }
			case CP_ACTION_TYPE_JOB_Z_Z:
			{
			    new p_1 = random(100),p_2 = random(100),price = 200;
			    if(p_1 == p_2) SCM(playerid,COLOR_YELLOW,"Вы получили премию за качественно выполненую работу!"),price+=20;
				GiveMoney(playerid,price,true);
				PW[factory] += 1;
				mysql_format(dbHandle,query,100,"UPDATE `warehouse` SET `factory ` = '%d'",PW[factory]);
				mysql_tquery(dbHandle,query);
				StartJob(playerid,2);
			}
		}
	}
	return 1;
}
stock EndJob(playerid,job_id)
{
	switch(job_id)
	{
	    case 2:
	        {
				DisablePlayerCheckpoint(playerid);
				SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
				RemovePlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND);
				DeletePVar(playerid,"number"),DeletePVar(playerid,"job_factory_on");
			}
	}
}
function: animation_z(playerid)
{
	DisablePlayerCheckpoint(playerid);
	new j_s = PI[playerid][pJob_State],j_s2 = PI[playerid][pJob_State_2];
	if(j_s != j_s2)
	{
	    SCM(playerid,COLOR_DARKORANGE,"Получился брак! Начните работу заново");
	    PI[playerid][pJob_State] = PI[playerid][pJob_State_2] = 0;
	    StartJob(playerid,2);
	    return KillTimer(PI[playerid][pPlayerTimer]);
	}
	SetPlayerCheckpoint(playerid,1397.2087,-56.2949,3000.6, 0.9, CP_ACTION_TYPE_JOB_Z_Z);
	SCM(playerid,COLOR_BLUE,"Вы запаковали ткань! Положите готовую продукцию на склад.");
	KillTimer(PI[playerid][pPlayerTimer]);
	return 1;
}
public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}
public OnPlayerPickUpPickupEx(playerid, pickupid, action_type, action_id)
{
	if(IsPlayerInRangeOfPoint(playerid, 5.0, GetPickupInfo(pickupid, P_POS_X), GetPickupInfo(pickupid, P_POS_Y), GetPickupInfo(pickupid, P_POS_Z)))
	{
	    switch(action_type)
	    {
	        //case PICKUP_ACTION_TYPE_TELEPORT: SetPlayerPosEx(playerid,GetTeleportData(action_id, T_POS_X),GetTeleportData(action_id, T_POS_Y),GetTeleportData(action_id, T_POS_Z),GetTeleportData(action_id, T_VIRTUAL_WORLD),GetTeleportData(action_id, T_INTERIOR),GetTeleportData(action_id, T_ANGLE));
	        case PICKUP_ACTION_TYPE_WORK:
	        {
				if(!PL[playerid]) return 1;
				SPD(playerid,dialog_job,DIALOG_STYLE_MSGBOX,"{FFA500}Работа грузчика","{ffffff}- Добро пожаловать на завод работяга!\n\nВы хотите начать производство деталей?\n\nЗарплата за {FFA500}1{ffffff} готовый продукт = 250$\nТакже существуют дополнительные множители для зарплаты!\nЕсли качество вашей работы будет превышать 70%,\nто вы будете получать дополнительно {FFA500}20${ffffff}\n\nВы хотите начать работу?","Далее","Закрыть");
	        }
	    }
	}
	return 1;
}
public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	if(GetPlayerMenu(playerid) == Menu:INVALID_MENU) return Kick(playerid);
    if(GetPlayerMenu(playerid) == skinmenu)
    {
        switch(row)
        {
            case 0:
                {
         			if(PI[playerid][pSex] == 1)
		  			{
	       				if(SelectCharPlace[playerid] == 0) SelectCharPlace[playerid] = sizeof(ChoiseSkin)-1;
						else SelectCharPlace[playerid]--;
						SetPlayerSkin(playerid, ChoiseSkin[SelectCharPlace[playerid]]);
						ChosenSkin[playerid] = ChoiseSkin[SelectCharPlace[playerid]];
		  			}
		  			else
		  			{
						if(SelectCharPlace[playerid] == 0) SelectCharPlace[playerid] = sizeof(ChoiseSkin)-1;
						else SelectCharPlace[playerid]--;
						SetPlayerSkin(playerid, ChoiseSkin[SelectCharPlace[playerid]]);
						ChosenSkin[playerid] = ChoiseSkin[SelectCharPlace[playerid]];
			  		}
       				ShowMenuForPlayer(skinmenu,playerid);
                }
     		case 1:
       			{
         			if(PI[playerid][pSex] == 1)
		  			{
	       				if(SelectCharPlace[playerid] == sizeof(ChoiseSkin)-1) SelectCharPlace[playerid] = 1;
						else SelectCharPlace[playerid]++;
						SetPlayerSkin(playerid, ChoiseSkin[SelectCharPlace[playerid]]);
						ChosenSkin[playerid] = ChoiseSkin[SelectCharPlace[playerid]];
		  			}
		  			else
		  			{
						if(SelectCharPlace[playerid] == sizeof(ChoiseSkinM)-1) SelectCharPlace[playerid] = 1;
						else SelectCharPlace[playerid]++;
						SetPlayerSkin(playerid, ChoiseSkinM[SelectCharPlace[playerid]]);
						ChosenSkin[playerid] = ChoiseSkinM[SelectCharPlace[playerid]];
			  		}
  					ShowMenuForPlayer(skinmenu,playerid);
       			}
           	case 2:
           	    {
           	        PI[playerid][pSkin_ID] = ChosenSkin[playerid];
           	        ChosenSkin[playerid] = SelectCharPlace[playerid] = 0;
           	        SetClothes(playerid,1);
					CreateToAccount(playerid);
           	    }
        }
    }
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys & KEY_WALK)
	{
		if(IsPlayerInRangeOfPoint(playerid,2.0,1414.3397,-20.8316,3001.4951) && GetInfo(playerid,pJob) != 2) JobDialogList(playerid,2);
		if(IsPlayerInRangeOfPoint(playerid,1.0,1397.7651,-52.3436,3001.4951))
		{
			if(GetPVarInt(playerid,"job_factory_on"))
			{
				ApplyAnimation(playerid, "INT_HOUSE", "WASH_UP", 4.1, 1, 0, 1, 0, 10000, 0);
      			PI[playerid][pPlayerTimer] = SetTimerEx("animation_z",10_000,false,"i",playerid);
      			DeletePVar(playerid,"job_factory_on");
      			RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);
			}
			else SCM(playerid,COLOR_DARKORANGE,"У вас нет в руках необходимой продукции!");
		}
		if(IsPlayerInRangeOfPoint(playerid,2.0,1404.5094,-34.9383,3001.5098))
		{
		    if(PI[playerid][pJob] == 2)
		    {
				switch(PI[playerid][pJobWork])
				{
				    case 0: SPD(playerid,dialog_work_start,DIALOG_STYLE_MSGBOX,"{FFA500}Работа заводского","{ffffff}Вы хотите начать рабочий день?","Начать","Закрыть");
				    case 1: SPD(playerid,dialog_work,DIALOG_STYLE_MSGBOX,"{FFA500}Работа заводского","{ffffff}Вы хотите заклнчить рабочий день?","Закончить","Отмена");
				}
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"Вы не работаете на заводе!");
		}
		for(new idx; idx < sizeof g_teleport; idx ++)
		{
		    if(IsPlayerInRangeOfPoint(playerid,1.0,GetTeleportData(idx,T_PICKUP_POS_X),GetTeleportData(idx,T_PICKUP_POS_Y),GetTeleportData(idx,T_PICKUP_POS_Z)))
				SetPlayerPosEx(playerid,GetTeleportData(idx, T_POS_X),GetTeleportData(idx, T_POS_Y),GetTeleportData(idx, T_POS_Z),GetTeleportData(idx, T_VIRTUAL_WORLD),GetTeleportData(idx, T_INTERIOR),GetTeleportData(idx, T_ANGLE));
		}
 	}
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
    if(noclipdata[playerid][cameramode] == CAMERA_MODE_FLY)
    {
        new keyss,ud,lr;
        GetPlayerKeys(playerid,keyss,ud,lr);

        if(noclipdata[playerid][mode] && (GetTickCount() - noclipdata[playerid][lastmove] > 100))
        {
            // If the last move was > 100ms ago, process moving the object the players camera is attached to
            MoveCamera(playerid);
        }

        // Is the players current key state different than their last keystate?
        if(noclipdata[playerid][udold] != ud || noclipdata[playerid][lrold] != lr)
        {
            if((noclipdata[playerid][udold] != 0 || noclipdata[playerid][lrold] != 0) && ud == 0 && lr == 0)
            {   // All keys have been released, stop the object the camera is attached to and reset the acceleration multiplier
                StopPlayerObject(playerid, noclipdata[playerid][flyobject]);
                noclipdata[playerid][mode]      = 0;
                noclipdata[playerid][accelmul]  = 0.0;
            }
            else
            {   // Indicates a new key has been pressed

                // Get the direction the player wants to move as indicated by the keys
                noclipdata[playerid][mode] = GetMoveDirectionFromKeys(ud, lr);

                // Process moving the object the players camera is attached to
                MoveCamera(playerid);
            }
        }
        noclipdata[playerid][udold] = ud; noclipdata[playerid][lrold] = lr; // Store current keys pressed for comparison next update
        return 0;
    }
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case dialog_register:
	    {
	        if(!response) return SCM(playerid,0xFFFFFFAA,"Пароль является обязательным условием регистрации!"),Kick(playerid);
	        for(new i = strlen(inputtext); i != 0; --i)
         	switch(inputtext[i])
 			{
				case 'А'..'Я', 'а'..'я', ' ': //
				return SCM(playerid, 0xFFFFFFAA, "Пароль может содержать только латинские буквы и арабские числа!");
 			}
 			if(response)
 			{
 			    if(!strlen(inputtext) || strlen(inputtext) < 6 || strlen(inputtext) > 32 || IsTextRussian(inputtext))
				{
    				new string[360];
	    			format(string,sizeof(string),"{ffffff}Добро пожаловать в штат Северная Каролина, {FFA500}%s{ffffff} \n\
					\nЭтот аккаунт {F08080}не зарегистрирован {ffffff}на нашем сервере.\nДля регистрации ввелите пароль, который будете использовать\nдля авторизации на нашем сервере\n\n\t{DC143C}Требования к паролю :\n\t{DC143C}- Длина пароля от 6 до 32 символов\n\t{DC143C}- Пароль должен состоять из латинских букв и цифр\n\t{DC143C}- Пароль чувствителен к регистру",GN(playerid));
					ShowPlayerDialog(playerid,dialog_register,DIALOG_STYLE_INPUT,"{FFA500}[1/4]",string,"Далее","Закрыть");
		    	}
				else
				{
    				SetString(PI[playerid][pPassword],inputtext);
    				SPD(playerid,dialog_email,DIALOG_STYLE_INPUT,"{FFA500}[2/4]","{ffffff}Для продолжения регистрации, введите адрес элетронной почты в поле ниже. ","Далее","Назад");
    				/*PlayerTextDrawSetString(playerid,TDEditor_PTD[playerid][1],inputtext);
    				reg_password[playerid] = true;
    				if(!strlen(PI[playerid][pEmail])) SCM(playerid,-1,"Уведомление! Осталось пройти последний этап регистрации");*/
				}
 			}
	    }
	    case dialog_email:
	    {
	        if(!response) return SCM(playerid,0xFFFFFAA,"Почта является обязательным условием регистрации!"),Kick(playerid);
	        if(strlen(inputtext))
	        {
	        	if(!IsValidMail(inputtext,strlen(inputtext))) ShowPlayerDialog(playerid,dialog_email,DIALOG_STYLE_INPUT,"{FFA500}[2/4]","{ffffff}В поле ниже введите свой используемый почтовый ящик.","Далее","Закрыть");
	        	new Cache:result,email;
	        	mysql_format(dbHandle,query,sizeof(query),"SELECT `email` FROM `users` WHERE `email` = '%e'",inputtext);
	        	result = mysql_query(dbHandle,query);
	        	email = cache_num_rows();
	        	cache_delete(result);
	        	if(email) ShowPlayerDialog(playerid,dialog_email,DIALOG_STYLE_INPUT,"{FFA500}[2/4]","{ffffff}Для продолжения регистрации, введите адрес элетронной почты в поле ниже.\n{FF4500}Данный почтовый ящик уже существует!","Далее","Закрыть");
	        	else
	        	{
					/*format(query,30,"%s",inputtext);
					PlayerTextDrawSetString(playerid,TDEditor_PTD[playerid][2],query);
					reg_email = true;*/
					SetString(PI[playerid][pEmail],inputtext);
					SPD(playerid,dialog_sex,DIALOG_STYLE_MSGBOX,"{ff4500}[3/4]","{ffffff}Выберите пол персонажа","Мужчина","Женщина");
				}
	        }
	    }
		case dialog_sex:
		{
		    if(response) PI[playerid][pSex] = 1;
		    else PI[playerid][pSex] = 2;
		    SPD(playerid,dialog_referal,DIALOG_STYLE_INPUT,"{FFA500}[4/4]","{ffffff}Введите ник игрока пригласившего вас на сервер","Далее","Пропустить");
		}
		case dialog_referal:
		{
		    if(!response) PlayerRegistered[playerid][0] = 1,SetClothes(playerid,0);
		    if(response)
			{
			    if(strlen(inputtext)) SetString(PI[playerid][pReferal],inputtext);
			    PlayerRegistered[playerid][0] = 1,SetClothes(playerid,0);
		    }
		}
		case dialog_login:
		{
		    if(!response) return SCM(playerid,-1,"Ввод пароля является обязательным условием авторизации!"),Kick(playerid);
		    if(response)
		    {
		        for(new i = strlen(inputtext); i != 0; --i)
		    	switch(inputtext[i])
				{
					case 'А'..'Я', 'а'..'я', ' ':
					return SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть 3 минуты на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
				}
		        if(!strlen(inputtext)) SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите ваш пароль \n{F08080}- У Вас есть 3 минуты на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
				mysql_format(dbHandle, query, 150, "SELECT * FROM `users` WHERE `name`='%e' AND `password`='%e'", GN(playerid), inputtext);
				mysql_tquery(dbHandle, query, "LoadPlayerInfo", "ds", playerid, inputtext);
		    }
		}
  	case dialog_errorpass:
   		{
     		if(!response)  SCM(playerid, -1, "Вы отменили авторизацию!"), Kick(playerid);
			SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть 3 минуты на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
     	}
  	case dialog_job:
  	    {
  	        if(!response) return DeletePVar(playerid,"job_id");
  	        if(response)
  	        {
  	            new job = GetPVarInt(playerid,"job_id");
  	            switch(job)
  	            {
  	                case 2:
  	                    {
  	                        PI[playerid][pJob] = job;
  	                        SCM(playerid,COLOR_YELLOW,"Вы устроились на работу! Чтобы приступить к работе - вам необходимо переодеться и пройти в цех");
							PI[playerid][pJobWork] = 0;
  	                    }
  	            }
  	        }
  	    }
  	case dialog_work_start:
  	    {
  	        if(!response) return SetInfo(playerid,pJobWork,0);
  	        if(response)
  	        {
  	            SCM(playerid,COLOR_BLUE,"Вы начали рабочий день!");
  	            SCM(playerid,COLOR_BLUE,"Пройдите в цех, затем возьмите материалы и начинайте производство деталей!");
  	            StartJob(playerid,PI[playerid][pJob]);
				SetInfo(playerid,pJobWork,1);
				SetPlayerSkin(playerid,73);
  	        }
  	    }
 	case dialog_work:
 	    {
 	        if(response)
 	        {
 	            SCM(playerid,COLOR_BLUE,"Вы закончили рабочий день!");
 	            EndJob(playerid,2);
 	            SetInfo(playerid,pJobWork,0);
 	        }
 	    }
  	case dialog_take_tk:
		{
  			if(response)
  			{
  			    SetInfo(playerid,pJob_State_2,listitem+1);
  			    new string[100];
  			    format(string,sizeof(string),"Вы взяли %s{6495ED}!",ClothColor[listitem]);
				SCM(playerid,COLOR_BLUE,string);
				DisablePlayerCheckpoint(playerid);
				ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 1, 0, 1, 0, 1500, 0);
				switch(random(3))
				{
					case 0: SetPlayerCheckpoint(playerid, 1410.3984,-49.8641,3000.5951, 0.9, CP_ACTION_TYPE_PUT_Z),SetPVarInt(playerid,"number",1);
					case 1: SetPlayerCheckpoint(playerid, 1410.0653,-55.0321,3000.6951, 0.9, CP_ACTION_TYPE_PUT_Z),SetPVarInt(playerid,"number",2);
					case 2: SetPlayerCheckpoint(playerid, 1410.0598,-59.6086,3000.6951, 0.9, CP_ACTION_TYPE_PUT_Z),SetPVarInt(playerid,"number",3);
				}
				switch(listitem)
				{
					case 0: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFCC00,0xFFFFCC00);
					case 1: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFA500,0xFFFFA500);
					case 2: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF008000,0xFF008000);
					case 3: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFDC143C,0xFFDC143C);
				}
 			}
		}
	case dialog_alogin:
 		{
		        if(!response) return 1;
		        new string[144];
				switch(GetPVarInt(playerid,"adm"))
				{
					case 1:
					{
						if(!strlen(inputtext)|| !strcmp(inputtext, "36592845", true) || strlen(inputtext) < 6 || strlen(inputtext) > 16 || strfind(inputtext, "=", true) != -1)
							return SPD(playerid, dialog_alogin, DIALOG_STYLE_PASSWORD, "{FFA500}Регистрация администратора", "{FFFFFF}Придумайте пароль, который будет использоваться от панели администратора\n\n{63BD4E}Примечание:\n\t- Пароль должен состоять из латинских букв и цифр\n\t- Размер пароля от 6 до 15 символов", "Далее", "Отмена");
						SetPVarString(playerid, "inputtext", inputtext);
						format(string, sizeof(string), "SELECT * FROM `a_users` WHERE `a_name` = '%s'", GN(playerid));
						mysql_tquery(dbHandle, string, "admReg", "is", playerid, GN(playerid));
					}
					case 0:
					{
						if(!strlen(inputtext)) return SPD
						(
							playerid, dialog_alogin, DIALOG_STYLE_PASSWORD, "{FFA500}Авторизация администрация", "{FFFFFF}Введите свой пароль от панели администратора\nВ случае утери пароля обратитесь к выше стоящий администрации!", "Далее", "Отмена"
						);
						mysql_format(dbHandle, string, sizeof(string), "SELECT * FROM `a_users` WHERE `a_name` = '%s' AND `a_password` = '%e'", GN(playerid), inputtext);
						mysql_tquery(dbHandle, string, "admAuth", "is", playerid, inputtext);
					}
				}
				return 1;
    	}
	}
	return 1;
}
function: admReg(playerid, name[])
{
	new rows, fields;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(rows)
	{
		new inputtext[16], string[144];
		GetPVarString(playerid, "inputtext", inputtext, sizeof(inputtext));
		mysql_format(dbHandle, string, sizeof(string), "UPDATE `a_users` SET `a_password` = '%s' WHERE `a_name` = '%s' LIMIT 1", inputtext, GN(playerid));
		mysql_tquery(dbHandle, string, "", "");
		cache_get_value_name_int(0, "a_lvl", PI[playerid][pAdmin]);
		UpdatePlayerDatabaseInt(playerid, "a_lvl", PI[playerid][pAdmin]);
		AL[playerid] = true;
	}
	return 1;
}
function: admAuth(playerid, inputtext[])
{
	new rows, fields;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(!rows)
	{
		SCM(playerid, COLOR_DARKORANGE, "Неверный пароль");
		SetPVarInt(playerid, "attempt_pass", GetPVarInt(playerid, "attempt_pass") + 1);
		if(GetPVarInt(playerid, "attempt_pass") > 3)
		{
			DeletePVar(playerid, "attempt_pass");
			Kick(playerid);
		}
	}
	else
	{
		cache_get_value_name_int(0,"a_lvl",PI[playerid][pAdmin]);
		AL[playerid] = true;
	}
	return 1;
}
stock UpdatePlayerDatabaseInt(playerid, field[], value)
{
	if(IsPlayerConnected(playerid)) 
	{
		mysql_format(dbHandle, query, sizeof query, "UPDATE users SET %s=%d WHERE id=%d LIMIT 1", field, value, PI[playerid][pID]);
		mysql_query(dbHandle, query);
	}
	return 1;
}
public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
  if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) SetPlayerPos(playerid,fX,fY,fZ);
  if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) SetVehiclePos(GetPlayerVehicleID(playerid),fX,fY,fZ);
  return 1;
}
public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}
public OnPlayerClickTextDraw(playerid,Text:clickedid)
{
    if(clickedid==TDEditor_TD[10]) { if(reg_email[playerid] == true && reg_password[playerid] == true) SPD(playerid,dialog_sex,DIALOG_STYLE_MSGBOX,"{ff4500}Пол персонажа","{ffffff}Выберите  пол своего персонажа","Мужчина","Женщина"),UnloadPlayerRegister(playerid); }
    return 1;
}
public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if(playertextid == TDEditor_PTD[playerid][1])
	{
	    if(!reg_password[playerid])
	    {
		    new string[360];
		    format(string,sizeof(string),"{ffffff}Добро пожаловать в штат Северная Каролина, {FFA500}%s{ffffff} \n\
			\nЭтот аккаунт {F08080}не зарегистрирован {ffffff}на нашем сервере.\nДля регистрации ввелите пароль, который будете использовать\nдля авторизации на нашем сервере\n\n\t{DC143C}Требования к паролю :\n\t{DC143C}- Длина пароля от 6 до 32 символов\n\t{DC143C}- Пароль должен состоять из латинских букв и цифр\n\t{DC143C}- Пароль чувствителен к регистру",GN(playerid));
			ShowPlayerDialog(playerid,dialog_register,DIALOG_STYLE_INPUT,"{FFA500}[1/4]",string,"Далее","Закрыть");
		}
	}
	if(playertextid == TDEditor_PTD[playerid][2]) { if(!reg_email[playerid]) ShowPlayerDialog(playerid,dialog_email,DIALOG_STYLE_INPUT,"{FFA500}Почтовый ящик","{ffffff}Для продолжения регистрации, введите адрес элетронной почты в поле ниже.","Далее","Закрыть"); }
	if(playertextid == login_rp_PTD[playerid][1]) ShowPlayerDialog(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина. \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть 3 минуты на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
	return 1;
}
stock CreateToAccount(playerid)
{
    if(IsTextInvalid(PI[playerid][pPassword])) return SCM(playerid, -1, "В пароле должны быть только латиские буквы и арабские числа!");
	mysql_format(dbHandle,query,250,"INSERT INTO `users` (`name`,`password`,`email`,`referal`,`skin_id`,`sex`) VALUES ('%s','%s','%s','%s','%d','%d')",GN(playerid),PI[playerid][pPassword],
	PI[playerid][pEmail],PI[playerid][pReferal],PI[playerid][pSkin_ID],PI[playerid][pSex]);
  	mysql_tquery(dbHandle, query);
 	for(new i = 0; i != 10; ++i) SCM(playerid, -1, " ");
  	PL[playerid] = true;
  	SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
	return 1;
}
stock SetString(param_1[], param_2[], size = 300)
{
	return strmid(param_1, param_2, 0, strlen(param_2), size);
}
stock GetString(param1[],param2[])
{
	return !strcmp(param1, param2, false);
}
stock IsTextRussian(text[])
{
	if(strfind(text, "а", true) != -1) return 1;
	if(strfind(text, "б", true) != -1) return 1;
	if(strfind(text, "в", true) != -1) return 1;
	if(strfind(text, "г", true) != -1) return 1;
	if(strfind(text, "д", true) != -1) return 1;
	if(strfind(text, "е", true) != -1) return 1;
	if(strfind(text, "ё", true) != -1) return 1;
	if(strfind(text, "ж", true) != -1) return 1;
	if(strfind(text, "з", true) != -1) return 1;
	if(strfind(text, "и", true) != -1) return 1;
	if(strfind(text, "й", true) != -1) return 1;
	if(strfind(text, "к", true) != -1) return 1;
	if(strfind(text, "л", true) != -1) return 1;
	if(strfind(text, "м", true) != -1) return 1;
	if(strfind(text, "н", true) != -1) return 1;
	if(strfind(text, "о", true) != -1) return 1;
	if(strfind(text, "п", true) != -1) return 1;
	if(strfind(text, "р", true) != -1) return 1;
	if(strfind(text, "с", true) != -1) return 1;
	if(strfind(text, "т", true) != -1) return 1;
	if(strfind(text, "у", true) != -1) return 1;
	if(strfind(text, "ф", true) != -1) return 1;
	if(strfind(text, "х", true) != -1) return 1;
	if(strfind(text, "ц", true) != -1) return 1;
	if(strfind(text, "ч", true) != -1) return 1;
	if(strfind(text, "ш", true) != -1) return 1;
	if(strfind(text, "щ", true) != -1) return 1;
	if(strfind(text, "ъ", true) != -1) return 1;
	if(strfind(text, "ы", true) != -1) return 1;
	if(strfind(text, "ь", true) != -1) return 1;
	if(strfind(text, "э", true) != -1) return 1;
	if(strfind(text, "ю", true) != -1) return 1;
	if(strfind(text, "я", true) != -1) return 1;
	return 0;
}
stock IsValidMail(email[], len = sizeof email)
{
    new count[2];
    if(!(5 <= len <= 60)) return 0;
    for(new i; i != len; i++)
    {
		switch(email[i])
		{
			case '@':
			{
				count[0]++;
				if(count[0] != 1 || i == len - 1 || i == 0) return 0;
			}
			case '.':
			{
				if(count[0] == 1 && count[1] == 0 && i != len - 1)
				{
					count[1] = 1;
				}
			}
			case '0'..'9', 'a'..'z', 'A'..'Z', '_', '-':
			{
				continue;
			}
			default:
				return 0;
		}
    }
    if(count[1] == 0) return 0;
    return 1;
}
stock IsTextInvalid(text[])
{
	if(strfind(text, "'", true) != -1) return 1;
	if(strfind(text, "%", true) != -1) return 1;
	if(strfind(text, "&", true) != -1) return 1;
	if(strfind(text, "*", true) != -1) return 1;
	if(strfind(text, "(", true) != -1) return 1;
	if(strfind(text, ")", true) != -1) return 1;
	return 0;
}
function: users_connect(playerid)
{
	SetPlayerVirtualWorld(playerid, playerid + 1);
   	TogglePlayerControllable(playerid, 0);
   	format(query, sizeof(query), "SELECT `name`,`password` FROM `users` WHERE `name` = '%s' LIMIT 1", GN(playerid));
   	mysql_tquery(dbHandle, query, "users_next_connect","d",playerid);
}
function: users_next_connect(playerid)
{
    if(IsPlayerConnected(playerid))
	{
		new rows,fields;
		cache_get_row_count(rows);
		cache_get_field_count(fields);
		if(rows)
		{
		    /*for(new i = 0; i < 35; i++) TextDrawShowForPlayer(playerid, login_rp_TD[i]);
  			for(new i = 0; i < 2; i++) PlayerTextDrawShow(playerid,login_rp_PTD[playerid][i]);
			format(fmt, sizeof fmt, "%s", GN(playerid));
			PlayerTextDrawSetString(playerid, login_rp_PTD[playerid][0], fmt);
			SelectTextDraw(playerid, 0xFFFFFFF);*/
            SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть 3 минуты на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
 		}
		else
		{
			/*for(new i = 0; i < 32; i++) TextDrawShowForPlayer(playerid,TDEditor_TD[i]);
			for(new i = 0; i < 3; i++) PlayerTextDrawShow(playerid,TDEditor_PTD[playerid][i]);
			format(fmt, sizeof fmt, "%s", GN(playerid));
			PlayerTextDrawSetString(playerid, TDEditor_PTD[playerid][0], fmt);
			SelectTextDraw(playerid, 0xFFFFFFF);*/
			new string[500];
			format(string,sizeof(string),"{ffffff}Добро пожаловать в штат Северная Каролина, {FFA500}%s{ffffff} \n\
			\nЭтот аккаунт {F08080}не зарегистрирован {ffffff}на нашем сервере.\nДля регистрации ввелите пароль, который будете использовать\nдля авторизации на нашем сервере\n\n\t{DC143C}Требования к паролю :\n\t{DC143C}- Длина пароля от 6 до 32 символов\n\t{DC143C}- Пароль должен состоять из латинских букв и цифр\n\t{DC143C}- Пароль чувствителен к регистру",GN(playerid));
			ShowPlayerDialog(playerid,dialog_register,DIALOG_STYLE_INPUT,"{FFA500}[1/4]",string,"Далее","Закрыть");
		}
		SetPVarInt(playerid,"player_logged",1);
	}
    return 1;
}
stock UnloadPlayerLogin(playerid)
{
	for(new i; i < 35; i++) TextDrawHideForPlayer(playerid,login_rp_TD[i]);
	for(new i; i < 2; i++) PlayerTextDrawHide(playerid,login_rp_PTD[playerid][i]);
	CancelSelectTextDraw(playerid);
}
stock UnloadPlayerRegister(playerid)
{
	for(new i; i < 31; i++) TextDrawHideForPlayer(playerid,TDEditor_TD[i]);
	for(new i; i < 3; i++) PlayerTextDrawHide(playerid,TDEditor_PTD[playerid][i]);
	CancelSelectTextDraw(playerid);
}
stock LoadTextDraws()
{
	#include <TextDraws/server_TD>
}
stock LoadPlayerTD(playerid)
{
	TDEditor_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 321.3832, 153.3750, "Charles_Olmedo"); // пусто
	PlayerTextDrawLetterSize(playerid, TDEditor_PTD[playerid][0], 0.2070, 1.3509);
	PlayerTextDrawAlignment(playerid, TDEditor_PTD[playerid][0], 2);
	PlayerTextDrawColor(playerid, TDEditor_PTD[playerid][0], -5963521);
	PlayerTextDrawBackgroundColor(playerid, TDEditor_PTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, TDEditor_PTD[playerid][0], 2);
	PlayerTextDrawSetProportional(playerid, TDEditor_PTD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, TDEditor_PTD[playerid][0], 0);

	TDEditor_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 262.0834, 183.2084, "‹ўeљњ¦e_Јapoћ©"); // пусто
	PlayerTextDrawLetterSize(playerid, TDEditor_PTD[playerid][1], 0.1638, 0.9739);
	PlayerTextDrawTextSize(playerid, TDEditor_PTD[playerid][1], 381.0000, 0.0000);
	PlayerTextDrawAlignment(playerid, TDEditor_PTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, TDEditor_PTD[playerid][1], -1);
	PlayerTextDrawUseBox(playerid, TDEditor_PTD[playerid][1], 1);
	PlayerTextDrawBoxColor(playerid, TDEditor_PTD[playerid][1], -5963521);
	PlayerTextDrawBackgroundColor(playerid, TDEditor_PTD[playerid][1], 255);
	PlayerTextDrawFont(playerid, TDEditor_PTD[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, TDEditor_PTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, TDEditor_PTD[playerid][1], 0);
	PlayerTextDrawSetSelectable(playerid, TDEditor_PTD[playerid][1], true);

	TDEditor_PTD[playerid][2] = CreatePlayerTextDraw(playerid, 262.0834, 204.7097, "‹ўeљњ¦e_Єћek¦po®®y«_Јo¤¦y"); // пусто
	PlayerTextDrawLetterSize(playerid, TDEditor_PTD[playerid][2], 0.1638, 0.9739);
	PlayerTextDrawTextSize(playerid, TDEditor_PTD[playerid][2], 380.9898, 0.0000);
	PlayerTextDrawAlignment(playerid, TDEditor_PTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, TDEditor_PTD[playerid][2], -1);
	PlayerTextDrawUseBox(playerid, TDEditor_PTD[playerid][2], 1);
	PlayerTextDrawBoxColor(playerid, TDEditor_PTD[playerid][2], -5963521);
	PlayerTextDrawBackgroundColor(playerid, TDEditor_PTD[playerid][2], 255);
	PlayerTextDrawFont(playerid, TDEditor_PTD[playerid][2], 2);
	PlayerTextDrawSetProportional(playerid, TDEditor_PTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, TDEditor_PTD[playerid][2], 0);
	PlayerTextDrawSetSelectable(playerid, TDEditor_PTD[playerid][2], true);

	
	login_rp_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 321.3832, 135.5740, "Charles_Olmedo"); // пусто
	PlayerTextDrawLetterSize(playerid, login_rp_PTD[playerid][0], 0.2070, 1.3509);
	PlayerTextDrawAlignment(playerid, login_rp_PTD[playerid][0], 2);
	PlayerTextDrawColor(playerid, login_rp_PTD[playerid][0], -5963521);
	PlayerTextDrawBackgroundColor(playerid, login_rp_PTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, login_rp_PTD[playerid][0], 2);
	PlayerTextDrawSetProportional(playerid, login_rp_PTD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, login_rp_PTD[playerid][0], 0);

	login_rp_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 262.0834, 165.4075, "‹ўeљњ¦e_Јapoћ©"); // пусто
	PlayerTextDrawLetterSize(playerid, login_rp_PTD[playerid][1], 0.1638, 0.9739);
	PlayerTextDrawAlignment(playerid, login_rp_PTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, login_rp_PTD[playerid][1], -1);
	PlayerTextDrawBackgroundColor(playerid, login_rp_PTD[playerid][1], 255);
	PlayerTextDrawFont(playerid, login_rp_PTD[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, login_rp_PTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, login_rp_PTD[playerid][1], 0);
	PlayerTextDrawSetSelectable(playerid, login_rp_PTD[playerid][1], true);
}
stock SetPlayerPosEx(playerid,Float:x,Float:y,Float:z,v_world,interior,Float:angle)
{
	SetPlayerPos(playerid,x,y,z);
	SetPlayerVirtualWorld(playerid,v_world);
	SetPlayerInterior(playerid,interior);
	SetPlayerFacingAngle(playerid,angle);
}
stock SetClothes(playerid,id_c)
{
	if(PlayerRegistered[playerid][0] == 1)
	{
		switch(id_c)
		{
		    case 0:
		        {
		            PlayerRegistered[playerid][1] = 1;
		            PL[playerid] = true;
			  		SpawnPlayer(playerid);
			  		SetPlayerFacingAngle(playerid,303.0);
			  		//SetPlayerCameraLookAt(playerid, -2379.1594,-578.0125,132.1172);
			  		SetPlayerCameraPos(playerid, -2379.9355,-580.9198,134.1172);
                    ShowMenuForPlayer(skinmenu, playerid),TogglePlayerControllable(playerid, false);
                    if(PI[playerid][pSex] == 1) SetPlayerSkin(playerid, ChoiseSkin[SelectCharPlace[playerid]]), ChosenSkin[playerid] = ChoiseSkin[0];
					else SetPlayerSkin(playerid, ChoiseSkinM[SelectCharPlace[playerid]]), ChosenSkin[playerid] = ChoiseSkinM[0];
		        }
	     	case 1: PlayerRegistered[playerid][1] = 0,TogglePlayerControllable(playerid, true),SpawnPlayer(playerid);
		}
	}
}
function: LoadPlayerInfo(playerid,text[])
{
	if(!GetPVarInt(playerid, "player_logged")) return 1;
	new rows,fields;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(!rows)
	{
		PlayerLogTries[playerid]++;
		if(PlayerLogTries[playerid] == 4)
		{
			SCM(playerid,-1, "Вы несколько раз ввели неверный пароль!");
			return Kick(playerid);
		}
		new string[100];
		format(string, sizeof(string), "{F04245}Вы ввели неверный пароль!\nУ вас осталось {FFFFFF}%d {F04245}попыток", 3 - PlayerLogTries[playerid]);
		ShowPlayerDialog(playerid, dialog_errorpass, DIALOG_STYLE_MSGBOX, "{ffa500}Ошибка", string, "Повтор", "Выйти");
		return 1;
	}
	SetPVarInt(playerid, "connect", 1);
	cache_get_value_name_int(0,"id",PI[playerid][pID]);
	cache_get_value_name_int(0,"skin_id",PI[playerid][pSkin_ID]);
	cache_get_value_name(0,"email",PI[playerid][pEmail]);
	cache_get_value_name_int(0,"sex",PI[playerid][pSex]);
	cache_get_value_name_int(0,"cash",PI[playerid][pCash]);
	cache_get_value_name_int(0,"bank",PI[playerid][pBank]);
	cache_get_value_name_int(0,"job",PI[playerid][pJob]);
	DeletePVar(playerid, "player_logged");
	SpawnPlayer(playerid);
	UnloadPlayerLogin(playerid);
	PL[playerid] = true;
	return 1;
}
stock Menu()
{
   	skinmenu = CreateMenu("Form", 1, 50.0, 160.0, 90.0);
	AddMenuItem(skinmenu ,0,"Next");
	AddMenuItem(skinmenu ,0,"Back");
	AddMenuItem(skinmenu ,0,"Select");
}
stock SendAdminMSG(playerid,color,msg[])
{
	foreach(new i : Player)
	{
	    if(!AL[i] || !PL[i]) continue;
	    SCM(playerid,color,msg);
	}
}
stock TeleportPickupsInit()
{
	new Text3D:buffer,time=GetTickCount();
	for(new idx; idx < sizeof g_teleport; idx ++)
	{
		if(strlen(GetTeleportData(idx, T_NAME))) 
		{
			buffer = CreateDynamic3DTextLabel
			(
				GetTeleportData(idx, T_NAME),
				0x66CC00FF,
				GetTeleportData(idx, T_PICKUP_POS_X),
				GetTeleportData(idx, T_PICKUP_POS_Y),
				GetTeleportData(idx, T_PICKUP_POS_Z) + 0.8,
				5.0,
				INVALID_PLAYER_ID,
				INVALID_VEHICLE_ID,
				0,
				0,
				0,
				-1,
				STREAMER_3D_TEXT_LABEL_SD
			);
			SetTeleportData(idx, T_LABEL, buffer);
		}
		if(idx < 38)
		{
			CreatePickup(1318, 23, GetTeleportData(idx, T_PICKUP_POS_X), GetTeleportData(idx, T_PICKUP_POS_Y), GetTeleportData(idx, T_PICKUP_POS_Z), GetTeleportData(idx, T_PICKUP_VIRTUAL_WORLD), PICKUP_ACTION_TYPE_TELEPORT, idx);
		}
		else
		{
		    CreatePickup(19132, 23, GetTeleportData(idx, T_PICKUP_POS_X), GetTeleportData(idx, T_PICKUP_POS_Y), GetTeleportData(idx, T_PICKUP_POS_Z), GetTeleportData(idx, T_PICKUP_VIRTUAL_WORLD), PICKUP_ACTION_TYPE_TELEPORT, idx);
		}
	}

	printf("[Пикапы]: Все входы/выходы созданы за <%d ms>",GetTickCount()-time);
}
stock GiveMoney(playerid,price,bool:auto_save=false)
{
	GivePlayerMoney(playerid,price);
	PI[playerid][pCash] += price;
	if(auto_save)
	{
		format(query, sizeof query, "UPDATE users SET cash=%d WHERE id=%d LIMIT 1", PI[playerid][pCash], PI[playerid][pID]);
		mysql_tquery(dbHandle, query);
	}
	return 1;
}
stock LoadMySQLSettings()
{
	new FileID = ini_openFile("mysql_settings.ini"),errCode;
	if(FileID < 0)
	{
		printf("Error while opening MySQL settings file. Error code: %d",FileID);
		return 0;
	}
	errCode = ini_getString(FileID,"host",MySQLSettings[DOOME_HOST]);
	if(errCode < 0) printf("Error while reading MySQL settings file (host). Error code: %d",errCode);
	errCode = ini_getString(FileID,"username",MySQLSettings[DOOME_USERNAME]);
	if(errCode < 0) printf("Error while reading MySQL settings file (username). Error code: %d",errCode);
	errCode = ini_getString(FileID,"password",MySQLSettings[DOOME_PASSWORD]);
	if(errCode < 0) printf("Error while reading MySQL settings file (password). Error code: %d",errCode);
	errCode = ini_getString(FileID,"database",MySQLSettings[DOOME_DATABASE]);
	if(errCode < 0) printf("Error while reading MySQL settings file (database). Error code: %d",errCode);
	ini_closeFile(FileID);
	return 1;
}
stock GetMoveDirectionFromKeys(ud, lr)
{
    new direction = 0;

    if(lr < 0)
    {
        if(ud < 0)         direction = MOVE_FORWARD_LEFT;     // Up & Left key pressed
        else if(ud > 0) direction = MOVE_BACK_LEFT;     // Back & Left key pressed
        else            direction = MOVE_LEFT;          // Left key pressed
    }
    else if(lr > 0)     // Right pressed
    {
        if(ud < 0)      direction = MOVE_FORWARD_RIGHT;  // Up & Right key pressed
        else if(ud > 0) direction = MOVE_BACK_RIGHT;     // Back & Right key pressed
        else            direction = MOVE_RIGHT;          // Right key pressed
    }
    else if(ud < 0)     direction = MOVE_FORWARD;     // Up key pressed
    else if(ud > 0)     direction = MOVE_BACK;        // Down key pressed

    return direction;
}
stock MoveCamera(playerid)
{
	new Float:FV[3], Float:CPP[3];
    GetPlayerCameraPos(playerid, CPP[0], CPP[1], CPP[2]);          //     Cameras position in space
    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);  //  Where the camera is looking at

    // Increases the acceleration multiplier the longer the key is held
    if(noclipdata[playerid][accelmul] <= 1) noclipdata[playerid][accelmul] += ACCEL_RATE;

    // Determine the speed to move the camera based on the acceleration multiplier
    new Float:speed = MOVE_SPEED * noclipdata[playerid][accelmul];

    // Calculate the cameras next position based on their current position and the direction their camera is facing
    new Float:X, Float:Y, Float:Z;
    GetNextCameraPosition(noclipdata[playerid][mode], CPP, FV, X, Y, Z);
    MovePlayerObject(playerid, noclipdata[playerid][flyobject], X, Y, Z, speed);

    // Store the last time the camera was moved as now
    noclipdata[playerid][lastmove] = GetTickCount();
    return 1;
}
stock GetNextCameraPosition(move_mode, Float:CPP[3], Float:FV[3], &Float:X, &Float:Y, &Float:Z)
{
    // Calculate the cameras next position based on their current position and the direction their camera is facing
    #define OFFSET_X (FV[0]*6000.0)
    #define OFFSET_Y (FV[1]*6000.0)
    #define OFFSET_Z (FV[2]*6000.0)
    switch(move_mode)
    {
        case MOVE_FORWARD:
        {
            X = CPP[0]+OFFSET_X;
            Y = CPP[1]+OFFSET_Y;
            Z = CPP[2]+OFFSET_Z;
        }
        case MOVE_BACK:
        {
            X = CPP[0]-OFFSET_X;
            Y = CPP[1]-OFFSET_Y;
            Z = CPP[2]-OFFSET_Z;
        }
        case MOVE_LEFT:
        {
            X = CPP[0]-OFFSET_Y;
            Y = CPP[1]+OFFSET_X;
            Z = CPP[2];
        }
        case MOVE_RIGHT:
        {
            X = CPP[0]+OFFSET_Y;
            Y = CPP[1]-OFFSET_X;
            Z = CPP[2];
        }
        case MOVE_BACK_LEFT:
        {
            X = CPP[0]+(-OFFSET_X - OFFSET_Y);
            Y = CPP[1]+(-OFFSET_Y + OFFSET_X);
            Z = CPP[2]-OFFSET_Z;
        }
        case MOVE_BACK_RIGHT:
        {
            X = CPP[0]+(-OFFSET_X + OFFSET_Y);
            Y = CPP[1]+(-OFFSET_Y - OFFSET_X);
            Z = CPP[2]-OFFSET_Z;
        }
        case MOVE_FORWARD_LEFT:
        {
            X = CPP[0]+(OFFSET_X  - OFFSET_Y);
            Y = CPP[1]+(OFFSET_Y  + OFFSET_X);
            Z = CPP[2]+OFFSET_Z;
        }
        case MOVE_FORWARD_RIGHT:
        {
            X = CPP[0]+(OFFSET_X  + OFFSET_Y);
            Y = CPP[1]+(OFFSET_Y  - OFFSET_X);
            Z = CPP[2]+OFFSET_Z;
        }
    }
}
stock CancelFlyMode(playerid)
{
    DeletePVar(playerid, "FlyMode");
	CancelEdit(playerid);
    //TogglePlayerSpectating(playerid, false);
    new Float:x,Float:y,Float:z;
    GetPlayerObjectPos(playerid, noclipdata[playerid][flyobject], x, y, z);
    DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
    noclipdata[playerid][cameramode] = CAMERA_MODE_NONE;
    SetCameraBehindPlayer(playerid);
    return SetPlayerPos(playerid,x,y,z);
}
stock JobDialogList(playerid,job_id)
{
	if(PL[playerid])
	{
	    switch(job_id)
	    {
	        case 2: SPD(playerid,dialog_job,DIALOG_STYLE_MSGBOX,"{FFA500}Работа заводского","{ffffff}- Добро пожаловать на завод работяга!\n\nВы хотите начать производство ткани?\n\nЗарплата за {FFA500}1{ffffff} готовый продукт = {FFA500}250${ffffff}.\nТакже существуют дополнительные множители для зарплаты!\nЕсли качество вашей работы будет превышать 70%,\nто вы будете получать дополнительно {FFA500}20${ffffff}.\n\nВы хотите устроиться на работу?","Далее","Закрыть");
	        
	    }
	    SetPVarInt(playerid,"job_id",job_id);
	}
}
stock StartJob(playerid,job_id)
{
	if(PI[playerid][pJob] == job_id)
	{
		new string[100];
		switch(job_id)
		{
		    case 2:
		        {
		            new b_t = random(4);
		            format(string,sizeof(string),"Возьмите из ящика %s{6495ED}, затем положите на конвейер",ClothColor[b_t]);
		            SetInfo(playerid,pJob_State,b_t+1);
		            SCM(playerid,COLOR_BLUE,string);
		            SetPlayerCheckpoint(playerid, 1399.0405,-58.9619,3000.6, 0.9, CP_ACTION_TYPE_TAKE_Z);
		        }
		}
	}
}
function: d_factory(playerid)
{
	switch(GetPVarInt(playerid,"number")-1)
	{
    	case 1: SetPlayerCheckpoint(playerid, 1403.1617,-55.1036,3000.6, 0.9, CP_ACTION_TYPE_GIVE_Z);
    	case 2: SetPlayerCheckpoint(playerid, 1403.1624,-59.6582,3000.6, 0.9, CP_ACTION_TYPE_GIVE_Z);
    	case 0: SetPlayerCheckpoint(playerid, 1402.9274,-50.0483,3000.7, 0.9, CP_ACTION_TYPE_GIVE_Z);
    }
    SCM(playerid,COLOR_BLUE,"Возьмите готовый груз с конвейера, затем упакуйте готовую ткань в коробку!");
	return KillTimer(PI[playerid][pPlayerTimer]);
}
stock SaveAccounts(playerid)
{
    if(!PL[playerid] || !IsPlayerConnected(playerid)) return 1;
    new src[100];
	format(query,sizeof(query),"UPDATE `users` SET ");
	format(src,sizeof(src),"cash='%s',",PI[playerid][pCash]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"bank='%d',",PI[playerid][pBank]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"job='%d',",PI[playerid][pJob]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"skin_id='%d'",PI[playerid][pSkin_ID]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src)," WHERE id='%d' LIMIT 1",PI[playerid][pID]);
	strcat(query,src,sizeof(query));
 	mysql_tquery(dbHandle, query);
 	return 1;
}
function: LoadWareHouse()
{
    new time = GetTickCount(), rows,Cache: result;
    result = mysql_query(dbHandle, "SELECT * FROM `warehouse`");
	rows = cache_num_rows();
	if(rows)
	{
	  cache_get_value_name_int(0, "factory",PW[factory]); // Cклад ППС
	}
	cache_delete(result);
	printf("[Загрузка хранилищ]: Все хранилища загружены. Потрачено: <%i ms>.", GetTickCount() - time);
	return 1;
}
stock SCM_I(playerid, message[], color, Float: radius = 30.0)
{
	new virtual_world = GetPlayerVirtualWorld(playerid);
	new Float: x, Float: y, Float: z;
	GetPlayerPos(playerid, x, y, z);

	foreach(new idx : Player)
	{
		if(!PL[idx]) continue;
		if(GetPlayerVirtualWorld(idx) != virtual_world) continue;
		if(!IsPlayerInRangeOfPoint(idx, radius, x, y, z)) continue;

		SCM(idx, color, message);
	}
	return 1;
}
stock StatsDialog(playerid, targetid)
{
    new pol_text[20];
	switch(PI[targetid][pSex])
	{
		case 1:pol_text = "Мужской";
		case 2: pol_text = "Женский";
	}
	new sctring[1300], str[150];
	format(str,sizeof(str),"{ffffff}Имя_Фамилия:  {FFA500}%s\n\n",GN(targetid));
	strcat(sctring,str);
    format(str,sizeof(str),"{ffffff}Деньги:  {FFA500}%d рублей{FFFFFF}\n", PI[playerid][pCash]);
    strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Пол:  {FFA500}%s{FFFFFF}\n\n",pol_text);
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Организация:  {FFA500}%s{FFFFFF}\n",Fraction_Name[PI[playerid][pMember]]);
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Должность:  {FFA500}-{FFFFFF}\n");
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Работа:  {FFA500}-{FFFFFF}\n");
	strcat(sctring,str);
	SPD(playerid, 0, DIALOG_STYLE_MSGBOX, "{FFA500}Статистика", sctring, "Закрыть", "");
	return 1;
}
stock FlyMode(playerid)
{
    new Float:X, Float:Y, Float:Z;
    GetPlayerPos(playerid, X, Y, Z);
    noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, X, Y, Z, 0.0, 0.0, 0.0);
    AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);

    SetPVarInt(playerid, "FlyMode", 1);
    noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;
    return 1;
}
