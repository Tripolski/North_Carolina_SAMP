main(){}
#include <a_samp>
#include <streamer>
#include <a_mysql>
#include <mxINI>
#include <dc_cmd>
#include <sscanf2>
#include <foreach>
#include <md5>
#include <progress>
#include <fixobject>
//------[Системы]-------
#include <pickup.pwn>
#include <cp.pwn>
#include <cp_race.pwn>
#include <vehicle.pwn>
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
#define PRESSED(%0) \
    (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define SCM SendClientMessage
#define SPD ShowPlayerDialog
#define cGold   FFA500
#define cW      FFFFFF
//----------------------
new Text:TDEditor_TD[32],PlayerText:TDEditor_PTD[MAX_PLAYERS][3],
	Text:login_rp_TD[35],PlayerText:login_rp_PTD[MAX_PLAYERS][2],
	Text:TD_L[5],Text:farm_td[10],PlayerText:farm_ptd[MAX_PLAYERS][8],
	Text:c_skin[12],Text:p_alt[1],Text:td_speedometr[2],PlayerText:ptd_speedometr[MAX_PLAYERS][42],
	Text:captinfo_TD[9],Text:vbs2[12];
new g_zone[161];
new obj_f_1[22+1],obj_f_2[46],obj_f_3[48]; // теплица на ферме
new Bar:satiety;
new Text3D:frac_gun[10];
//-----------------------
new bool:reg_password[MAX_PLAYERS] = false,bool:reg_email[MAX_PLAYERS] = false;
new PlayerRegistered[MAX_PLAYERS][2],bool:PL[MAX_PLAYERS],bool:AL[MAX_PLAYERS];
new Menu:skinmenu,ChosenSkin[MAX_PLAYERS],SelectCharPlace[MAX_PLAYERS];
static const stock ChoiseSkin[4] = {223,64,198,4};
static const stock ChoiseSkinM[4] = {5,6,7,8};
new PlayerLogTries[MAX_PLAYERS];
new paydays;
//----------------------
#define IsNotAL "[A] Вы не авторизовались в панели администратирования! (/alogin)"
#define S_LOGIN "Вы отключены от сервера! Используйте команду - /q(uit), чтобы покинуть игру."
//#define CreateObject CreateDynamicObject
//#define MoveObject MoveDynamicObject
//#define SetObjectMaterial SetDynamicObjectMaterial
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
#define TEAM_GOV    	(1)
#define TEAM_PD     	(2)
#define TEAM_SMI    	(3)
#define TEAM_ARMY   	(4)
#define TEAM_HOSPITAL	(5)
#define TEAM_AVTO   	(6)
#define TEAM_FBI    	(7)
#define TEAM_RIFA   	(8)
#define TEAM_TRI    	(9)
#define TEAM_VT     	(10)
//-----------------------
#define MAX_WORKER  		(10)
#define MAX_HOUSES  		(200)
#define MAX_FARMS    		(1)
#define MAX_BUSINESS    	(75)
#define MAX_OWNABLE_CARS	(500)
//-----------------------
enum pInfo {
	pID,
	pName[MAX_PLAYER_NAME],
	pPassword[32],
	pEmail[20],
	pReferal[MAX_PLAYER_NAME],
	pDataReg,
	pRegIP[16],
	pIP[16],
	pMute,
	pSpawnID,
	pSex,
	pAdmin,
	pSkin_ID,
	pLVL,
	pExp,
	pCash,
	pBank,
	pJob,
	pJobWork,
	pJob_Anim,
	pJob_State,
	pJob_State_2,
	pJob_State_3,
	pJob_State_4,
	pReportState,
	pPlayerTimer,
	pPlayerTimeCont,
	pOnlineDay,
	pLeader,
	pMember,
	pRank,
	pMember_Skin,
	pFarmID,
	pCarID_L,
	pInHouse,
	pHouseID,
	pHouseType,
	pHouseRoom,
	pBusinessID,
	pInBusiness,
	pDialogData[3],
	pDrugs,
	pSatiety,
	pCarID,
	//-[Навыки]-
	pSkillFarm,
	pFarmLVL,
	pSkillFactory,
	pFactoryLVL,
	pSkillFish,
	pFishLVL,
	//-----
	pAFK_Time,
	//-[/inv]-
	pR_Kit,
	pHealc,
	pMask,
	pStateMask,
	//-[/phone]-
	pPhone,
	pPhoneNumber,
	pPhoneBalance,
	//-[Оффлайн статистика]-
	pLastConnect[20],
	pLastIP[16],
	//-[Админ Статистика]-
	pRepPositive,
	pRepNegative,
	//----------
	Float:pLeaveX,
	Float:pLeaveY,
	Float:pLeaveZ,
	pLeaveVW,
	pLeaveI,
	//-----[Вспомогательное]
	pInfoF,
	pInfoF2,
	pInfoF3,
	//--
	pCuffed,
	pTazered,
	pTazerTime,
	pSu,
	//---
	pMats,
	pAmmo1,
	pAmmo2,
	pAmmo3,
	pAmmo4,
	pAmmo5,
	pAmmo6,
	pBody1,
	pBody2,
	pBody3,
	pBody4,
	pBody5,
	pBody6
};
new PI[MAX_PLAYERS][pInfo];
#define GN(%0) PI[%0][pName]
#define GetInfo(%0,%1) PI[%0][%1]
#define SetInfo(%0,%1,%2) PI[%0][%1] = %2
#define AddInfo(%0,%1,%2,%3) PI[%0][%1] %2= %3
#define FreezePlayer(%0,%1) TogglePlayerControllable(%0, false), SetTimerEx("PlayerToggle", %1, false, "d", %0)
//--------------------------------
#define GetAP(%0) PI[%0][pAdmin]
#define GetPID(%0) PI[%0][pID]
#define GetPlayerAFK(%0)    PI[%0][pAFK_Time]
#define IsPlayerAFK(%0)			(GetInfo(%0, pAFK_Time) >= 5)
//--------------------------------
#define GetPlayerUseListitem(%0) 		g_player_listitem_use[%0]
#define SetPlayerUseListitem(%0,%1) 	g_player_listitem_use[%0] = %1
new g_player_listitem_use[MAX_PLAYERS] = {-1, ...};
#define UpdateF_Text()    CallLocalFunction("UpdateFarmText","")
#define IsValidVehicleID(%0)		(1 <= %0 < MAX_VEHICLES)
//------[Личный т/с]
#define GetOwnableCarData(%0,%1) 		g_ownable_car[%0][%1]
#define SetOwnableCarData(%0,%1,%2)		g_ownable_car[%0][%1] = %2
#define AddOwnableCarData(%0,%1,%2,%3)	g_ownable_car[%0][%1] %2= %3

#define IsOwnableCarOwned(%0)			(GetOwnableCarData(%0, OC_OWNER_ID) > 0)
enum E_OWNABLE_CAR_STRUCT
{
	OC_SQL_ID,
	OC_OWNER_ID,		
	OC_OWNER_NAME[21],	
	OC_NUMBER[8],		
	OC_MODEL_ID,		
	OC_COLOR_1,			
	OC_COLOR_2,			
	Float: OC_POS_X,	
	Float: OC_POS_Y,	
	Float: OC_POS_Z,	
	Float: OC_ANGLE,
	bool: OC_ALARM,		
	OC_DISKI,
	OC_GIDRA,
	OC_NITRO,
	OC_CREATE,			
	OC_LOCK,
	OC_N
};
new g_ownable_car[MAX_OWNABLE_CARS][E_OWNABLE_CAR_STRUCT];
new g_ownable_car_loaded;
#define GetPlayerOwnableCar(%0)	PI[%0][pCarID]
enum
{
	VEHICLE_NONE,
	VEHICLE_ACTION_TYPE_OWNABLE_CAR
};
#define GetPlayerListitemValue(%0,%1) 		g_player_listitem[%0][%1]
#define SetPlayerListitemValue(%0,%1,%2) 	g_player_listitem[%0][%1] = %2
new g_player_listitem[MAX_PLAYERS][32];
//-------[/capture]---------------
enum E_CAPTURE_STRUCT
{
	bool: C_STATUS,
	C_GANG_ZONE,
	C_ATTACK_TEAM,
	C_PROTECT_TEAM,
	C_ATTACKER_KILLS,
	C_PROTECTOR_KILLS,
	C_TIME,
	C_WAIT_TIME[3]
}
new g_capture[E_CAPTURE_STRUCT];
//------[Загрузка гангзон]--------
#define GetGangZoneData(%0,%1)			g_gang_zone[%0][%1]
#define SetGangZoneData(%0,%1,%2)		g_gang_zone[%0][%1] = %2
#define MAX_GZ 29
enum E_GANG_ZONES_STRUCT
{
	Float: GZ_MIN_X,
	Float: GZ_MIN_Y,
	Float: GZ_MAX_X,
	Float: GZ_MAX_Y,
	GZ_GANG,
	GZ_ZONE,
	GZ_AREA
}
new g_gang_zone[MAX_GZ][E_GANG_ZONES_STRUCT];
new g_gang_zones_loaded; 
new gang_zone_colors[4] =
{
	0xFFFFFF80,	// -
	0x00FF7F80, // Rifa
	0x00800080, // Triada
	0x80800080  // Vietman
};
//-------[Настройки транспорта]---
new bool:Engine[MAX_VEHICLES],bool:Lights[MAX_VEHICLES],
	Float:Fuel[MAX_VEHICLES],v_inventory[MAX_VEHICLES],v_i_quantity[MAX_VEHICLES];
	//Text3D:v_label[MAX_VEHICLES];
new engine,lights,alarm,doors,bonnet,boot,objective;
//---------------------------------
#define CONVERT_TIME_TO_SECONDS 	1
#define CONVERT_TIME_TO_MINUTES 	2
#define CONVERT_TIME_TO_HOURS 		3
#define CONVERT_TIME_TO_DAYS 		4
#define CONVERT_TIME_TO_MONTHS 		5
#define CONVERT_TIME_TO_YEARS 		6
//-----------[Areas]--------------
new biz_area[MAX_BUSINESS];
//--------------------------------
new server_gmx = 0;
//-----------[Система бизнесов]---
#define SetPlayerInBiz(%0,%1)	PI[%0][pInBusiness] = %1
#define GetPlayerInBiz(%0)		PI[%0][pInBusiness]
#define GetBusinessInteriorInfo(%0,%1)	 	g_business_interiors[%0][%1]
#define SetBusinessInteriorInfo(%0,%1,%2) 	g_business_interiors[%0][%1] = %2
enum // ID интерьеров
{
	BUSINESS_INTERIOR_SHOP_24_7 = 0,	// магазин 24/7
};
enum E_BUSINESS_INTERIOR_STRUCT
{
	Float: BT_EXIT_POS_X, 	// позиции пикапа выхода
	Float: BT_EXIT_POS_Y, 	// позиции пикапа выхода
	Float: BT_EXIT_POS_Z, 	// позиции пикапа выхода
	// -------------------
	Float: BT_ENTER_POS_X, 	// позиции входа
	Float: BT_ENTER_POS_Y, 	// позиции входа
	Float: BT_ENTER_POS_Z, 	// позиции входа
	Float: BT_ENTER_ANGLE, 	// угол поворота
	BT_ENTER_INTERIOR,		// интерьер
	// -------------------
	Float: BT_HEALTH_POS_X,	// позиции аптечки
	Float: BT_HEALTH_POS_Y,	// позиции аптечки
	Float: BT_HEALTH_POS_Z,	// позиции аптечки
	// -------------------
	Float: BT_BUY_POS_X, 	// позиции покупки
	Float: BT_BUY_POS_Y, 	// позиции покупки
	Float: BT_BUY_POS_Z, 	// позиции покупки
	// -------------------
	Float: BT_LABEL_POS_X,	// позиции 3д текста
	Float: BT_LABEL_POS_Y,	// позиции 3д текста
	Float: BT_LABEL_POS_Z,	// позиции 3д текста
	BT_BUY_CHECK_ID			// ид чекпоинта
};

new const
	g_business_interiors[1][E_BUSINESS_INTERIOR_STRUCT] =
{
	{ 
		-25.9052,-188.0836,1003.5469,
		-25.884498,-185.868988,1003.546875,90.0,
		17, 								
		1044.4398,1742.9457,1014.9285, 		// позиции аптечки
		-28.5805,-185.1386,1003.5469, 		// позиции покупки
		-28.5805,-185.1386,1003.5469,
		-1									
	}
};
#define GetBusinessData(%0,%1) 			g_business[%0][%1]
#define SetBusinessData(%0,%1,%2) 		g_business[%0][%1] = %2
#define AddBusinessData(%0,%1,%2,%3) 	g_business[%0][%1] %2= %3
#define IsBusinessOwned(%0)				(GetBusinessData(%0, B_OWNER_ID) > 0)
enum E_BUSINESS_STRUCT
{
	B_SQL_ID,			// ид в базе данных
	B_NAME[24],			// название
	B_OWNER_ID,			// ид аккаунта владельца
	B_CITY,				// ид города
	B_ZONE,				// ид района
	B_ENTER_PRICE,		// цена за вход в биз
	B_ENTER_MUSIC,		// звук при входе
	B_IMPROVEMENTS,		// уровень улучшений
	B_PRODS,			// количества продуктов
	B_PROD_PRICE,		// стоимость 1 продукта
	B_BALANCE,			// бюджет бизнеса
	B_RENT_DATE,		// аренда на n времени
	B_PRICE,			// стоимость бизнеса
	B_RENT_PRICE,		// плата за аренду в день
	B_LOCK_STATUS,		// статус (открыта/закрыта)
	B_TYPE,				// тип бизнеса
	B_INTERIOR,			// интерьер
	Float: B_POS_X,		// позиция бизнеса
	Float:B_POS_Y,		// позиция бизнеса
	Float: B_POS_Z,		// позиция бизнеса
	Float: B_EXIT_POS_X,// позиция после выхода из бизнеса
	Float: B_EXIT_POS_Y,// позиция после выхода из бизнеса
	Float: B_EXIT_POS_Z,// позиция после выхода из бизнеса
	Float: B_EXIT_ANGLE,// угол поворота
	// -------------------------
	B_OWNER_NAME[20 + 1],	// имя владельца
	Text3D: B_LABEL,		// 3д текст
	B_ORDER_ID,				// слот заказа
	B_HEALTH_PICKUP,		// ид пикапа аптечки
	// -------------------------
	B_EVICTION				// продажа из-за задолженности
};

enum // ID бизнесов
{
	BUSINESS_TYPE_SHOP_24_7 = 1 	// магазин 24/7
};
new g_business[MAX_BUSINESS][E_BUSINESS_STRUCT];
new g_business_loaded;
//-----------[Система домов]------
#define MAX_HOUSES  (200)
#define HOUSE_TYPE_NONE		(-1) 	// нет
#define HOUSE_TYPE_HOME		(0) 	// дом
#define GetPlayerInHouse(%0)	PI[%0][pInHouse]
#define SetPlayerInHouse(%0,%1)				PI[%0][pInHouse] = %1
#define GetHouseTypeInfo(%0,%1)		g_house_type[%0][%1]
#define SetHouseTypeInfo(%0,%1,%2)	g_house_type[%0][%1] = %2
#define GetHouseData(%0,%1)			g_house[%0][%1]
#define SetHouseData(%0,%1,%2)		g_house[%0][%1] = %2
#define AddHouseData(%0,%1,%2,%3)	g_house[%0][%1] %2= %3
#define IsHouseOwned(%0)			(GetHouseData(%0, H_OWNER_ID) > 0) // куплен ли дом

enum E_HOUSE_STRUCT
{
	H_SQL_ID,			// ид в базе данных
	H_NAME[20],			// название \ тип
	H_OWNER_ID,			// ид аккаунта владельца
	H_CITY,				// ид города
	H_ZONE,				// ид района
	H_IMPROVEMENTS,		// уровень улучшений
	H_RENT_DATE,		// аренда на n времени
	H_PRICE,			// стоимость дома
	H_RENT_PRICE,		// плата за аренду в день
	H_LOCK_STATUS,		// статус (открыто/закрыто)
	H_TYPE,				// тип дома (интерьер)
	Float: H_POS_X,		// позиция пикапа входа
	Float: H_POS_Y,		// позиция пикапа входа
	Float: H_POS_Z,		// позиция пикапа входа
	Float: H_EXIT_POS_X,// позиция после выхода из дома
	Float: H_EXIT_POS_Y,// позиция после выхода из дома
	Float: H_EXIT_POS_Z,// позиция после выхода из дома
	Float: H_EXIT_ANGLE,// угол поворота
	Float: H_CAR_POS_X,	// позиция транспорта
	Float: H_CAR_POS_Y,	// позиция транспорта
	Float: H_CAR_POS_Z,	// позиция транспорта
	Float: H_CAR_ANGLE,	// угол поворота транспорта
	Float: H_STORE_X,	// позиция шкафа
	Float: H_STORE_Y,	// позиция шкафа
	Float: H_STORE_Z,	// позиция шкафа
	// -------------------------
	H_OWNER_NAME[20 + 1],	// имя владельца
	Text3D: H_STORE_LABEL,	// 3д текст (шкаф)
	H_ENTER_PICKUP,			// пикап входа
	H_HEALTH_PICKUP,		// пикап аптечки
	Text3D: H_HEALTH_LABEL,
	H_MAP_ICON,				// иконка на карте
	H_FLAT_ID,				// номер квартиры
	// -------------------------
	H_EVICTION,			// продажа из-за задолженности
	// -------------------------
	H_STORE_METALL,		// металл в шкафу
	H_STORE_DRUGS,		// наркотики в шкафу
	H_STORE_WEAPON,		// оружие в шкафу
	H_STORE_AMMO,		// патроны оружия в шкафу
	H_STORE_SKIN		// одежда в шкафу
};

enum E_HOUSE_TYPE_STRUCT
{
	HT_NAME[20],
	Float: HT_ENTER_POS_X,		// позиции после входа в интерьера
	Float: HT_ENTER_POS_Y,		// позиции после входа в интерьера
	Float: HT_ENTER_POS_Z,		// позиции после входа в интерьера
	Float: HT_ENTER_POS_ANGLE,	// позиции после входа в интерьера
	Float: HT_HEALTH_POS_X,		// позиции аптечки
	Float: HT_HEALTH_POS_Y,		// позиции аптечки
	Float: HT_HEALTH_POS_Z,		// позиции аптечки
	Float: HT_STORE_POS_X,		// позиции шкафа
	Float: HT_STORE_POS_Y,		// позиции шкафа
	Float: HT_STORE_POS_Z,		// позиции шкафа
	HT_INTERIOR,				// ид интерьера
	HT_ROOMS					// кол-во комнат
};
new g_house[MAX_HOUSES][E_HOUSE_STRUCT];
new g_house_loaded;
new g_house_type[3][E_HOUSE_TYPE_STRUCT] =
{
	{
		"Низкий класс", 						// название / тип
		225.756989, 1240.0, 1082.149902,178.7700,	// после входа
		222.7009,1253.3455,1082.1406, 			// аптечка
		223.1564,1249.3755,1082.1406,			// шкаф
		2,										// интерьер
		1										// комнат
	},
	{
		"Средний класс",						// название / тип
		491.1569,1399.1304,1080.2578,90.2385,	// после входа
		483.0982,1413.0864,1080.2578, 			// аптечка
		479.2791,1411.3695,1080.2714,			// шкаф
		2,										// интерьер
		2										// комнат
	},
	{
		"Высокий класс",						// название / тип
		2317.7722,-1026.1692,1050.2178,93.0842,         // после входа
		2313.2344,-1008.6086,1050.2109, 			// аптечка
		2319.1047,-1017.0957,1050.2109,			// шкаф
		9,										// интерьер
		3										// комнат
	}
};
//----------[Ферма]---------------
#define GetFarmInfo(%0)  FI[%0]
#define SetFarmInfo(%0,%1) FI[%0] = %1
#define AddFarmInfo(%0,%1,%2)   FI[%0] %1= %2
#define AddfarmThings(%0,%1,%2) FI[%0] %1=%2
#define IsFarmOwned()			(GetFarmInfo(f_owner_id) > 0)
enum pFarm {
	f_id,
	f_owner_id,
	f_name[30], // название фермы
	f_owner_name[MAX_PLAYER_NAME],
	f_bank,
	f_sdl, // саженцы
	f_tools, // инструмены
	f_water, // вода
	f_renttime,
	f_price,
	f_apple, // яблоки
	f_orange, // апельсины
	f_flax,   // лён
	f_millet, // пшеница
	f_cotton, // хлопок
	f_corn, // кукуруза
	f_tomato,
	Text3D:f_text[4],
	//Text3D:f_text2,
	//Text3D:f_text3,
	f_pickup[3],
	f_cars[2],
	f_field_stats,
	Float:f_field_stats_2,
	f_field_stats_3
};
new FI[pFarm];
new farm_worker;
//--[Упавшое оружие]--
enum GunPick
{
	g_type,
	g_patron,
	Float:g_pos_x,
	Float:g_pos_y,
	Float:g_pos_z,
	Text3D:gunpick
};
new GP[500][GunPick],slotgp;
//--[Уровни администратирования]--
#define ADM_ZGA  (1)
#define ADM_GA   (2)
#define ADM_DEVELOPER (3)
//--------------------------------
enum E_FARM_TRUCK
{
	Float:Xx,
	Float:Yy,
	Float:Zz,
	bool:States,
	Float:rX,
	Float:rY,
	Float:rZ
};
new g_farm_CP_next[24][E_FARM_TRUCK] =
{
	{-1157.4359,-1135.5309,129.2188},
	{-1157.7277,-1133.6631,129.2188},
	{-1155.2139,-1135.8387,129.2642},
	{-1154.9171,-1134.3612,129.2695},
	{-1155.2635,-1133.2590,129.2188},
	{-1152.4246,-1133.1787,129.2188},
	{-1151.8184,-1134.7244,129.2188},
	{-1151.9803,-1135.5743,129.2188},
	{-1149.1509,-1135.7728,129.2794},
	{-1149.2581,-1134.6125,129.2974},
	{-1149.2352,-1133.4777,129.2188},
	{-1147.0438,-1133.3247,129.2188},
	{-1146.0917,-1134.6783,129.2294},
	{-1146.0708,-1135.8198,129.3350},
	{-1142.8184,-1135.8140,129.2188},
	{-1143.1274,-1134.2537,129.2188},
	{-1143.4873,-1133.2505,129.2696},
	{-1140.6154,-1133.3534,129.2281},
	{-1140.7194,-1134.0913,129.2188},
	{-1140.7178,-1135.6532,129.2224},
	{-1138.3804,-1135.6400,129.2188},
	{-1137.8241,-1134.7317,129.2475},
	{-1137.9337,-1133.4214,129.2584},
	{-1137.9337,-1133.4214,129.2584,true}
};
/*new g_farm_object[23][E_FARM_TRUCK] = {
	{-1137.80664, -1133.30396, 128.17990, false,132.00000, 158.00000, 10.00000},
	{-1137.80664, -1136.02405, 128.17990, false,132.00000, 158.00000, -24.00000},
	{-1137.80664, -1134.58398, 128.17990, false,132.00000, 158.00000, 28.00000},
	{-1140.52661, -1136.02405, 128.17990, false,132.00000, 158.00000, -58.00000},
	{-1140.52661, -1134.58398, 128.17990, false,132.00000, 158.00000, -16.00000},
	{-1143.30652, -1133.30396, 128.17990, false,132.00000, 158.00000, 84.00000},
	{-1143.30652, -1134.58398, 128.17990, false,132.00000, 158.00000, -8.00000},
	{-1143.30652, -1136.02405, 128.17990, false,132.00000, 158.00000, 186.00000},
	{-1146.17004, -1133.30396, 128.17990, false,132.00000, 158.00000, -8.00000},
	{-1146.17004, -1134.58398, 128.17990, false,132.00000, 158.00000, 60.00000},
	{-1146.17004, -1136.02405, 128.17990, false,132.00000, 158.00000, -70.00000},
	{-1149.15002, -1133.30396, 128.17990, false,132.00000, 158.00000, -34.00000},
	{-1149.15002, -1134.58398, 128.17990, false,132.00000, 158.00000, 78.00000},
	{-1149.15002, -1136.02405, 128.17990, false,132.00000, 158.00000, -24.00000},
	{-1151.96997, -1133.30396, 128.17990, false,132.00000, 158.00000, -40.00000},
	{-1151.96997, -1134.58398, 128.17990, false,132.00000, 158.00000, 28.00000},
	{-1151.96997, -1136.02405, 128.17990, false,132.00000, 158.00000, 38.00000},
	{-1154.87000, -1133.30396, 128.17990, false,132.00000, 158.00000, 46.00000},
	{-1154.87000, -1134.58398, 128.17990, false,132.00000, 158.00000, 2.00000},
	{-1154.87000, -1136.02405, 128.17990, false,132.00000, 158.00000, 10.00000},
	{-1157.19824, -1133.80347, 128.17990, false,132.00000, 158.00000, -30.00000},
	{-1156.96704, -1135.63684, 128.17990, false,132.00000, 158.00000, 52.00000},
	{-1140.52661, -1133.30396, 128.17990, true,132.00000, 158.00000, -38.00000}
};*/
new g_farm_CP[50][E_FARM_TRUCK] =
{
	{-1192.9772,-1059.1847,129.1843}, //  Начало
	{-1192.4102,-1037.8658,129.1833},
	{-1191.9529,-1018.5799,129.1860},
	{-1191.5520,-1001.6546,129.184},
	{-1191.1516,-984.7770,129.1841},
	{-1190.6051,-961.7153,129.1773},
	{-1189.4000,-940.2686,129.1773},
	{-1177.2633,-931.9185,129.1823},
	{-1177.3760,-960.2253,129.1771},
	{-1177.1765,-983.5152,129.1839},
	{-1177.5300,-1007.6150,129.1839},
	{-1177.1561,-1030.8988,129.1840},
	{-1177.1299,-1048.1637,129.1831},
	{-1170.5858,-1051.6100,129.1842},
	{-1170.4716,-1032.9213,129.1842},
	{-1170.8796,-1014.0836,129.1842},
	{-1171.2832,-995.4962,129.1843},
	{-1171.6277,-979.6439,129.1839},
	{-1172.0549,-960.0021,129.1771},
	{-1172.5537,-937.1100,129.1839},
	{-1166.3691,-933.9467,129.1841},
	{-1163.8651,-956.9907,129.1838},
	{-1162.2716,-973.4763,129.1798},
	{-1161.5823,-991.8888,129.1839},
	{-1161.3223,-996.8107,129.1840},
	{-1161.5630,-1030.8258,129.1839},
	{-1161.7096,-1046.0967,129.1857},
	{-1148.9965,-1046.6825,129.1823},
	{-1148.8369,-1023.7289,129.1842},
	{-1149.1755,-996.5221,129.1839},
	{-1149.4617,-977.7162,129.1839},
	{-1149.6866,-956.4916,129.1840},
	{-1149.9650,-930.1949,129.1840},
	{-1142.7908,-931.4886,129.1840},
	{-1140.3689,-955.6918,129.1839},
	{-1139.5591,-979.1641,129.1840},
	{-1138.3992,-1006.8408,129.1841},
	{-1138.3400,-1025.3776,129.1840},
	{-1138.7336,-1046.9628,129.1840},
	{-1130.8959,-1051.2627,129.1849},
	{-1127.5693,-1035.0486,129.1838},
	{-1126.8729,-1015.5605,129.1842},
	{-1126.6920,-1002.5411,129.1841},
	{-1126.3624,-978.8566,129.1840},
	{-1126.7384,-959.1552,129.1840},
	{-1127.0811,-932.7967,129.1840},
	{-1119.3551,-936.6550,129.1839},
	{-1119.2473,-957.1466,129.1839},
	{-1117.7778,-978.9001,129.1839},
	{-1116.5714,-1003.4163,129.1840,true}
};
//--------------------------------
enum
{
	dialog_none,
	dialog_register,
	dialog_login,
	dialog_spawn,
	dialog_email,
	dialog_sex,
	dialog_referal,
	dialog_errorpass,
	dialog_job,
	dialog_work_start,
	dialog_work,
	dialog_take_tk,
	dialog_alogin,
	dialog_npc,
	dialog_npc_next,
	dialog_tmenu,
	dialog_ainvite,
	dialog_jobleave,
	dialog_wh,
	dialog_enter,
	dialog_buy_house,
	dialog_biz,
	dialog_sellbiz,
	dialog_business,
	dialog_business_params,
	//---------------
	dialog_bank,
	dialog_bank_back,
	dialog_bank_put,
	dialog_bank_take,
	dialog_bank_realty,
	dialog_bank_biz,
	dialog_bank_biz_put,
	dialog_bank_biz_take,
	//--|/menu|------
	dialog_menu,
	dialog_menu_cmdhelp,
	dialog_menu_cmdhelp_2,
	dialog_menu_cmdhelp_3,
	dialog_menu_stats,
	dialog_help_admin,
	dialog_ask,
	dialog_report,
	dialog_dlz,
	//--[/asset]
	dialog_asset,
	dialog_asset_buy_tools,
	dialog_asset_buy_water,
	//--[/apanel]
	dialog_apanel,
	dialog_apanel_2,
	dialog_apanel_cmdhelp,
	dialog_apanel_cmdhelp_2,
	dialog_retime,
	dialog_redate,
	dialog_alladmins,
	dialog_apanel_members,
	dialog_apanel_reform,
	//--[24/7]
	dialog_buy,
	//--[/makeleader]
	dialog_makeleader,
	dialog_lmenu,
	dialog_lmenu_frname,
	dialog_lmenu_cfname,
	dialog_lmenu_repay,
	dialog_lmenu_setrepay,
	dialog_lmenu_back,
	dialog_lmenu_order,
	dialog_orders_mats,
	dialog_lmenu_regun,
	dialog_car,
	dialog_car_2,
	dialog_take_weapon,
	dialog_enter_price,
	dialog_fuel,
	dialog_gun
}
enum
{
	CP_TYPE_FARM = 1,
	CP_TYPE_FARM_G,
	RCP_TYPE_MARK_2
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
	T_FREEZE,
	T_ACTION_TYPE,
	Text3D: T_LABEL
};
enum
{
	CP_ACTION_TYPE_TAKE_Z = 1,
	CP_ACTION_TYPE_PUT_Z,
	CP_ACTION_TYPE_GIVE_Z,
	CP_ACTION_TYPE_JOB_Z,
	CP_ACTION_TYPE_JOB_Z_Z,
	CP_ACTION_TYPE_MARK,
	CP_ACTION_TYPE_MARK_2,
	CP_ACTION_TYPE_PUT_FARM,
	CP_TYPE_FARM_NEXT,
	CP_TYPE_FARM_NEXT_2,
	CP_TYPE_FARM_NEXT_3,
	CP_TYPE_FARM_NEXT_4
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
	factory,
	army_mats,
	army_ammo1,
	army_ammo3,
	army_ammo4,
	army_body1,
	army_body4
};
new PW[pWareHouse];
new Text3D: z_factory;
new a_factory,a_farm;
//---------------------
new g_fraction_rank[300][11][20];
new g_fraction_pay[11][20];
new g_fraction_gun[11][20];
#define Fraction_Pay(%0)    g_fraction_pay[PI[%0][pMember]][PI[%0][pRank]]
#define Fraction_Rank(%0)   g_fraction_rank[PI[%0][pMember]][PI[%0][pRank]]
//----------------------
new Iterator:adm_vehicles<MAX_VEHICLES-1>;
new TotalAdminVehicles = 0;
#if !defined IsValidVehicle
     native IsValidVehicle(vehicleid);
#endif

#if !defined FALSE
	new stock
	bool:FALSE = false;
#endif
//----------------------
#define GetTeleportData(%0,%1)		g_teleport[%0][%1]
#define SetTeleportData(%0,%1,%2)	g_teleport[%0][%1] = %2
new g_teleport[24][E_TELEPORT_STRUCT] =
{
	{"Завод\nЦентральный вход",-1836.6434,110.4750,15.1172, 0, 1401.6876,-26.0865,3001.4951,180.000, 1, 1,1}, // Вход в помещения офиса завода
	{"Раздевалка", 1405.1549,-28.7977,3001.4951, 1, 1405.4655,-33.9996,3001.5098,171.8550, 1, 1}, // Вход в раздевалку
	{"Строительная компания",-2051.1208,450.5173,35.1719,0,1416.1437,-1465.7645,916.8560,180.0,1,1,1},
	{"",1405.5546,-31.0472,3001.5098,1,1404.4229,-27.5078,3001.4951,10.76,1,1},
	{"",1415.9080,-1463.3682,916.8560,1,-2050.6907,452.9729,35.1719,333.4,0,0},
	{"Риэлторское агенство",-2043.5106,449.0459,35.1723,0,-1933.0280,-147.4610,1036.1940,95.5542,1,1},
	{"",-1931.3108,-146.9209,1036.1940,1,-2043.7488,452.0652,35.1723,2.8,0,0},
	{"",1398.9178,-26.3590,3001.4951,1,-1837.2098,112.8453,15.1172,342.0,0,0},
	{"Полиция",-1605.4318,711.3097,13.8672,0,2311.1189,745.8317,1011.1710,90.8308,1,1,1}, // полиция
	{"",2314.3633,746.0184,1011.1710,1,-1605.5082,714.5626,12.8192,1.7421,0,0},
	{"FBI",-2456.1494,503.9362,30.0781,0,355.3958,143.0660,1038.4609,169.1,1,1,1},
	{"",353.5104,143.1542,1038.4609,1,-2454.5642,503.8539,30.0784,180.0,0,0},
	{"Правительство",-2766.5503,375.5726,6.3347,0,1205.9379,2349.7295,3001.0989,89.4925,1,1,1},
	{"",1208.0299,2349.7620,3001.0989,1,-2763.4431,375.4667,6.0391,272.1208,0,0},
	{"Triada",-2463.3911,131.8724,35.1719,0,1868.9629,-2467.6685,1033.5547,359.5884,0,1,1},
	{"",1869.0167,-2470.3787,1033.5625,1,-2461.8203,133.3516,35.1719,90.0,0,0,1},
	{"Vietnam",-2192.6663,647.4243,49.4375,0,1868.9629,-2467.6685,1033.5547,359.5884,0,2,1},
	{"",1869.0167,-2470.3787,1033.5625,2,-2192.2095,645.3306,49.4375,187.3003,0,0},
	{"Rifa",-2655.4900,985.7838,64.9913,0,1868.9629,-2467.6685,1033.5547,180.0,0,3,1,1},
	{"",1869.0167,-2470.3787,1033.5625,3,-2656.0911,987.6091,65.1479,15.5920,0,0},
	{"СМИ",-2521.0686,-624.9531,132.7842,0,437.8537,-69.2893,1501.0859,89.4925,1,1,1},
	{"Выход",440.0757,-69.1129,1501.0859,1,-2521.2954,-621.8076,132.7404,4.6018,0,0},
	{"Банк",-2648.8894,376.0512,6.1593,0,1398.2928,-1676.0264,39.5649,177.3974,1,1,1},
	{"",1398.1160,-1672.0188,39.5649,1,-2652.7329,376.1389,4.7756,86.2400,0,0}
};
new gun_frac_name[12][] =
{
	"Пистолет 9mm\t\t\t[30 патрон]","Пистолет 9mm с глушителем\t[30 патрон]","Узи\t\t\t\t\t[120 патрон]","MP5\t\t\t\t\t[120 патрон]","Tec-9\t\t\t\t\t[120 патрон]","Дробовик\t\t\t\t[30 патрон]","Обрез\t\t\t\t[30 патрон]","Скорострельный дробовик\t\t[30 патрон]","АК-47\t\t\t\t\t[120 патрон]","М4\t\t\t\t\t[120 патрон]","Country Rifle\t\t\t[20 патрон]","Sniper Rifle\t\t\t\t[20 патрон]"
};
enum E_GUNS_WH
{
	E_FID,
	Float:pos_x,
	Float:pos_y,
	Float:pos_z,
	E_VID,
	E_INT
}
new g_gun_org[1][E_GUNS_WH] =
{
	{4,-1299.6852,497.6682,11.1953,0,0} // армия

};
enum
{
	PICKUP_ACTION_TYPE_TELEPORT = 1,
	PICKUP_ACTION_TYPE,
    PICKUP_ACTION_TYPE_WORK,
    PICKUP_ACTION_TYPE_N,
    PICKUP_ACTION_TYPE_HOUSE,
   	PICKUP_ACTION_TYPE_BIZ_ENTER,		// вход в бизнес
	PICKUP_ACTION_TYPE_BIZ_EXIT,		// выход из бизнеса
	PICKUP_ACTION_TYPE_BIZ_SHOP_247,
	PICKUP_ACTION_TYPE_GUN
}
enum //
{
	BIZ_OPERATION_PARAMS = 0,		// управление заправкой
	BIZ_OPERATION_LOCK,				// открыть / закрыть
	BIZ_OPERATION_ENTER_PRICE,		// установить цену за вход
	BIZ_OPERATION_PROFIT_STATS,	// финансовая статистика
	BIZ_OPERATION_ENTER_PRICE_2
};
//--------[Colors]--------
#define COLOR_WHITE 0xFFFFFFAA
#define COLOR_YELLOW    0xFFFF00AA
#define COLOR_GREEN 0x33AA33FF
#define COLOR_RED   0xBC2C2CFF
#define COLOR_BLUE  0x6495EDFF
#define COLOR_DARKORANGE    0xFF6600FF
#define COLOR_PURPLE 	0xDD90FFAA
#define COLOR_ORANGE    0xFF9900AA
#define COLOR_LIME		0x99cc00FF
#define COLOR_GREY 		0xAFAFAFAA
#define COLOR_ACTION    0xDD90FFFF
#define COLOR_PRIZE    	0xff1058ff
//-----------------------
static const stock ClothColor[12][30] = {"{ffcc00}желтую ткань","{FFA500}оранжевую ткань","{008000}зелёную ткань","{DC143C}красную ткань","{800080}фиолетовую ткань","{ffffff}белую ткань","{0099ff}синюю ткань","{000000}чёрную ткань","{0000FF}голубую ткань","{D2691E}коричневую ткань","{00FFFF}берёзовую ткань","{778899}серую ткань"};
//-----------------------
public OnGameModeInit()
{
    new MySQLOpt: option_id = mysql_init_options(),time = GetTickCount();
	LoadMySQLSettings();
	dbHandle = mysql_connect(MySQLSettings[DOOME_HOST],MySQLSettings[DOOME_USERNAME], MySQLSettings[DOOME_PASSWORD], MySQLSettings[DOOME_DATABASE],option_id);
	mysql_set_charset("utf8_general_ci");
    mysql_tquery(dbHandle, "SET CHARACTER SET 'utf8'", "", "");
	//mysql_tquery(dbHandle,"SET NAMES 'cp1251'");
	mysql_set_charset("cp1251");
	/*mysql_tquery(dbHandle, "SET character_set_client = 'utf8'", "", "");
    mysql_tquery(dbHandle, "SET character_set_connection = 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET character_set_results = 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET character_set_server = 'utf8'", "", "");
	mysql_tquery(dbHandle, "SET SESSION collation_connection = 'utf8_general_ci'", "", "");*/
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	//Load
	LoadTextDraws();
	LoadObjects();
	LoadArea();
	LoadGangZone();
	LoadGangZones();
	Menu();
	LoadWareHouse();
	LoadFractionsGun();
	LoadVehicle();
	for(new i = 1; i<10; i++)GunLabelInit(i);
	TeleportPickupsInit();
	GunPickupsInit();
	LoadFarmInfo();
	LoadFractionsPay();
	LoadFractionsRangName();
	LoadBusinesses();
	LoadHouses();
	Load3DText();
	if(getDayEx()==2) mysql_tquery(dbHandle, "UPDATE `users` SET `o_monday`='0',`o_tuesday`='0',`o_wednesday`='0',`o_thursday`='0',`o_friday`='0',`o_saturday`='0',`o_sunday`='0'", "", "");
	//-------
	SendRconCommand("hostname North Carolina RolePlay");
	SendRconCommand("weburl nc-rp.ru");
	SetGameModeText("RP Lite [v0.1]");
	//--------
	for(new i = MAX_VEHICLES; i != 0; i --)
	{
	    if(!IsValidVehicle(i)) continue;
	    if(IsAOwnableCar(i)) continue;
	    SetVehicleParamsEx(i, false, false, false, false, false, false, false);
	    Engine[i] = Lights[i] = false;
		Fuel[i] = 50;
	}
	//--------
	CreatePickup(1275, 23,1404.5094,-34.9383,3001.5098,1,0);
	CreatePickup(1275,23, -1068.0856,-1211.5553,129.7813,0,0);
	//Таймеры
	SetTimer("timer", 1000, true); // sec
	//Re
	DisableInteriorEnterExits();
    EnableStuntBonusForAll(0);
    ShowNameTags(true);
    ShowPlayerMarkers(0);
    LimitPlayerMarkerRadius(15.0);
    ManualVehicleEngineAndLights();
    SetNameTagDrawDistance(20.0);
	//Актеры
	new z_d = CreateActor(17, 1414.5465,-19.5869,3001.4951,181.1418);
	SetActorVirtualWorld(z_d,1);
	CreateActor(158, -1060.5692,-1206.4677,129.2188,302.9360);
	//---3DText
	z_factory = CreateDynamic3DTextLabel("{FFa500}Z",COLOR_WHITE, 1397.2087,-56.2949,3001.6,20.0);
	satiety = CreateProgressBar(548.00, 31.00, 57.50, 3.15, 0x0BB602AA, 100.0);
	//-
	AddPlayerClass(1, -2379.6804,-580.0637,132.1172, 269.1425, 0, 0, 0, 0, 0, 0);
	printf("[Загрузка проекта]: Проект успешно загружен. Потрачено времени: <%d ms>.",GetTickCount()-time);
	return 1;
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
	new string[200];
    for(new x; x<MAX_PLAYERS; x++)
    {
        if(noclipdata[x][cameramode] == CAMERA_MODE_FLY) CancelFlyMode(x);
    }
    foreach(new i : Player)
	{
		SaveAccounts(i);
		mysql_format(dbHandle,string, sizeof string, "SELECT `o_monday`,`o_tuesday`,`o_wednesday`,`o_thursday`,`o_friday`,`o_saturday`,`o_sunday` FROM `users` WHERE `id` = '%d'",PI[i][pID]);
		mysql_tquery(dbHandle,string,"SaveOnlineWeek","d",i);
	}
	for(new i; i < g_ownable_car_loaded; i++) SaveOwnableCar(i);
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
	GetPlayerIp(playerid,PI[playerid][pIP],16);
	LoadPlayerTD(playerid);
	for(new i; i < 5; i++) TextDrawShowForPlayer(playerid,TD_L[i]);
 	noclipdata[playerid][cameramode]     = CAMERA_MODE_NONE;
    noclipdata[playerid][lrold]                = 0;
    noclipdata[playerid][udold]           = 0;
    noclipdata[playerid][mode]           = 0;
    noclipdata[playerid][lastmove]       = 0;
    noclipdata[playerid][accelmul]       = 0.0;
    for(new i; i < 161; i++)  GangZoneShowForPlayer(playerid,g_zone[i],0x000000FF);
    //for(new i; i < 9; i ++) TextDrawShowForPlayer(playerid, captinfo_TD[i]);
	PI[playerid][pPlayerTimeCont] = SetTimerEx("p_cont",1000,true,"i",playerid);
    DefaultData(playerid);
    ShowGangZonesForPlayer(playerid);
    if(!g_capture[C_STATUS])
    {
    	for(new r; r < 9; r ++)
		TextDrawHideForPlayer(playerid,captinfo_TD[r]);
	}
 	if(PI[playerid][pStateMask])
	{
	    SetPlayerColor(playerid, 0xFFAA500FF);
	    PI[playerid][pStateMask] = 0;
	}
	RemoveBuild(playerid);
   	return 1;
}
stock DefaultData(playerid)
{
    PlayerRegistered[playerid][1] = 0;
    PI[playerid][pJob_State] = PI[playerid][pJob_State_2] = PI[playerid][pJob_State_3] = PI[playerid][pJob_State_4] = PI[playerid][pReportState] =  0;
    PL[playerid] = AL[playerid] = false;
    PI[playerid][pJobWork] = 0;
    PI[playerid][pHouseID] = PI[playerid][pBusinessID] = PI[playerid][pHouseType] = PI[playerid][pFarmID] = -1;
   	DeletePVar(playerid,"ID_F");
    DeletePVar(playerid,"job_factory_on");
    SetPVarInt(playerid,"time_out",0);
	PI[playerid][pSex] =
	PI[playerid][pAdmin] = 
	PI[playerid][pSkin_ID] =
	PI[playerid][pLVL] =
	PI[playerid][pExp] =
	PI[playerid][pCash] =
	PI[playerid][pMute] =
	PI[playerid][pBank] =
	PI[playerid][pJob] =
	PI[playerid][pJobWork] =
	PI[playerid][pJob_Anim] =
	PI[playerid][pJob_State] =
	PI[playerid][pJob_State_2] =
	PI[playerid][pJob_State_3] =
	PI[playerid][pJob_State_4] =
	PI[playerid][pReportState] =
	PI[playerid][pPlayerTimer] =
	PI[playerid][pPlayerTimeCont] =
	PI[playerid][pOnlineDay] =
	PI[playerid][pLeader] =
	PI[playerid][pMember] =
	PI[playerid][pRank] =
	PI[playerid][pSu] =
	PI[playerid][pDrugs] =
	PI[playerid][pCuffed] =
	PI[playerid][pTazered] =
	PI[playerid][pTazerTime] =
	PI[playerid][pMember_Skin] = 0;
	PI[playerid][pFarmID] = -1;
    PI[playerid][pPhone] =
	PI[playerid][pPhoneNumber] =
	PI[playerid][pPhoneBalance] =
	PI[playerid][pInfoF] =
	PI[playerid][pInfoF2] =
	PI[playerid][pInfoF3] = 0;
	
}
function:p_cont(playerid)
{
	if(!PL[playerid])
	{
	    PI[playerid][pPlayerTimer]--;
	    if(PI[playerid][pPlayerTimer] == 0)
	    {
	      	SCM(playerid,COLOR_DARKORANGE,"Время на авторизацию/регистрацию ограничено!");
			SCM(playerid,COLOR_DARKORANGE,S_LOGIN);
	        Kick(playerid);
	        return 1;
	    }
	}
	if(!PL[playerid]) return 1;
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	if(PL[playerid])
	{
	    //Где вышел
	    GetPlayerPos(playerid,PI[playerid][pLeaveX],PI[playerid][pLeaveY],PI[playerid][pLeaveZ]);
	    PI[playerid][pLeaveVW] = GetPlayerVirtualWorld(playerid);
		PI[playerid][pLeaveI] = GetPlayerInterior(playerid);
		new string[300];
		mysql_format(dbHandle,string, sizeof string, "UPDATE `users` SET `pos_x` = '%f', `pos_y` = '%f', `pos_z` = '%f', `virtual_world` = '%d', `interior` = '%d', `last_date` = '%d', `last_ip` = '%s' WHERE `id` = '%d'",
		PI[playerid][pLeaveX],PI[playerid][pLeaveY],PI[playerid][pLeaveZ],PI[playerid][pLeaveVW],PI[playerid][pLeaveI],gettime(),PI[playerid][pLastIP],PI[playerid][pID]);
		mysql_tquery(dbHandle,string);
		//Онлайн
		//mysql_format(dbHandle,string, sizeof string, "SELECT `o_monday`,`o_tuesday`,`o_wednesday`,`o_thursday`,`o_friday`,`o_saturday`,`o_sunday` FROM `users` WHERE `id` = '%d'",PI[playerid][pID]);
		//mysql_tquery(dbHandle,string,"SaveOnlineWeek","d",playerid);
	}
	SaveAccounts(playerid);
	return 1;
}
function: SaveOnlineWeek(playerid)
{
	new rows,fields,online,string[150];
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	switch(getDayEx())
	{
	    case 0:
	        {
	            cache_get_value_name_int(0, "o_saturday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_saturday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	    case 1:
	        {
	            cache_get_value_name_int(0, "o_sunday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_sunday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	    case 2:
	        {
	            cache_get_value_name_int(0, "o_monday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_monday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	    case 3:
	        {
	            cache_get_value_name_int(0, "o_tuesday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_tuesday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	    case 4:
	        {
	            cache_get_value_name_int(0, "o_wednesday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_wednesday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	    case 5:
	        {
	            cache_get_value_name_int(0, "o_thursday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_thursday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	    case 6:
	        {
	            cache_get_value_name_int(0, "o_friday", online);
            	mysql_format(dbHandle, string, sizeof(string), "UPDATE `users` SET `o_friday` = '%d' WHERE `id` = '%d'", online + PI[playerid][pOnlineDay], PI[playerid][pID]);
	        }
	}
	mysql_tquery(dbHandle,string);
}
public OnPlayerSpawn(playerid)
{
    GetPlayerIp(playerid,PI[playerid][pLastIP],16);
	switch(PI[playerid][pSpawnID])
	{
	    case 1: SetPlayerPosEx(playerid,-2379.6804,-580.0637,132.1172,0,0,115.6077),PL[playerid] = true;
	    case 2:
	        {
	            if(PI[playerid][pHouseID] != -1)
	            {
	                PL[playerid] = true;
	                EnterPlayerToHouse(playerid, PI[playerid][pHouseID]);
	            }
	        }
		case 3: PI[playerid][pSpawnID] = 1,SpawnPlayer(playerid);
	    case 4: SetPlayerPosEx(playerid,PI[playerid][pLeaveX],PI[playerid][pLeaveY],PI[playerid][pLeaveZ],PI[playerid][pLeaveVW],PI[playerid][pLeaveI],0.0),PL[playerid] = true;
	}
	if(!PL[playerid]) return Kick(playerid),SCM(playerid,0xFFFFFFAA,"Вы отменили авторизацию/регистрацию");
	SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
	SetPlayerWantedLevel(playerid,PI[playerid][pSu]);
	ResetPlayerMoney(playerid),GivePlayerMoney(playerid, GetInfo(playerid,pCash));
 	RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);
 	SetPlayerScore(playerid,PI[playerid][pLVL]);
 	if(PI[playerid][pFarmID] == FI[f_id])
 	{
 		if(GetElapsedTime(FI[f_renttime],gettime(),CONVERT_TIME_TO_DAYS) <= 0)
 		{
 		    SCM(playerid,COLOR_DARKORANGE,"Срок аренды заканчивается!");
 		}
 	}
 	SetInfo(playerid,pCarID_L,INVALID_VEHICLE_ID);
 	SetInfo(playerid,pInHouse,-1);
 	SetInfo(playerid,pInBusiness,-1);
	if(PlayerRegistered[playerid][1])
	{
	    SetPlayerPosEx(playerid,-2376.3318,-578.2756,133.1120,playerid*10,0,123.0);
	    SCM(playerid,-1,"Выберите одежду");
	}
	AL[playerid] = true;
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(PI[playerid][pStateMask])
	{
	    SetPlayerColor(playerid, 0xFFAA500FF);
	    PI[playerid][pStateMask] = 0;
	}
	if(GetPlayerWeapon(playerid))
	{
	    if(slotgp <= 500)
	    {
			new gun_id = GetPlayerWeapon(playerid),Float:gX,Float:gY,Float:gZ,string[50];
			GetPlayerPos(playerid,gX,gY,gZ);
			GP[slotgp][g_type] = gun_id;
			GP[slotgp][g_pos_x] = gX;
			GP[slotgp][g_pos_y] = gY;
			GP[slotgp][g_pos_z] = gZ;
			GP[slotgp][g_patron] = GetPlayerAmmo(playerid);
			format(string, sizeof string, "Оружие: %d\nALT",gun_id);
			GP[slotgp][gunpick] = CreateDynamic3DTextLabel(string, COLOR_ORANGE, gX, gY, gZ, 5.0);
			slotgp++;
		}
	}
	if(killerid != INVALID_PLAYER_ID)
	{
	    if(g_capture[C_STATUS])
		{
			if(8 <= PI[killerid][pMember] <= 10)
			{
				new area_id = GetGangZoneData(g_capture[C_GANG_ZONE], GZ_AREA);

				if(IsPlayerInDynamicArea(killerid, area_id) && IsPlayerInDynamicArea(playerid, area_id))
				{
					new gang_id[2];

					gang_id[0] = PI[killerid][pMember] - 7;
					gang_id[1] = PI[playerid][pMember] - 7;

					if(gang_id[0] == g_capture[C_ATTACK_TEAM] && gang_id[1] == g_capture[C_PROTECT_TEAM])
						g_capture[C_ATTACKER_KILLS] ++;

					else if(gang_id[0] == g_capture[C_PROTECT_TEAM] && gang_id[1] == g_capture[C_ATTACK_TEAM])
						g_capture[C_PROTECTOR_KILLS] ++;
				}
			}
		}
	}
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	if(IsAOwnableCar(vehicleid))
	{
		new index = GetVehicleData(vehicleid, V_ACTION_ID);

		SetVehiclePos
		(
			vehicleid,
			GetOwnableCarData(index, OC_POS_X),
			GetOwnableCarData(index, OC_POS_Y),
			GetOwnableCarData(index, OC_POS_Z)
		);
	}
	else
	{
		DestroyVehicleLabel(vehicleid);
		Fuel[vehicleid] = 50;
	}
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}
stock LoadArea()
{
    a_factory = CreateDynamicSphere(1402.7699,-44.5353,3001.4951,100.0,-1,-1,-1);
    a_farm = CreateDynamicSphere(-1060.5692,-1206.4677,129.2188,500.0,-1,-1,-1);
}
public OnPlayerText(playerid, text[])
{
	if(GetInfo(playerid,pMute))
	{
		SCM(playerid, COLOR_DARKORANGE, "У Вас заблокирован чат! Чтобы узнать время блокировки используйте команду - /time");

		SetPlayerChatBubble(playerid, "пытается что-то сказать", COLOR_DARKORANGE, 10.5, 2000);

		return 0;
	}
    if(!strcmp(text,")") || !strcmp(text,":D"))
    {
        Action(playerid,"улыбается");
		return 0;
	}
 	if(!strcmp(text,"))") || !strcmp(text,"xD") || !strcmp(text,"xd") || !strcmp(text,"XD"))
    {
        Action(playerid,"смеётся");
		return 0;
	}
	if(!strcmp(text,"+"))
	{
	    Action(playerid,"согласен");
		return 0;
	}
	if(!strcmp(text,"-"))
	{
	    Action(playerid,"не согласен");
		return 0;
	}
 	if(!strcmp(text,"("))
    {
        Action(playerid,"грустит");
		return 0;
	}
	if(!strcmp(text,"(("))
    {
        Action(playerid,"сильно расстроился");
		return 0;
	}
	new string[100];
	format(string,sizeof(string),"%s[%d] говорит: %s",GN(playerid), playerid,text);
	SCM_I(playerid,string,-1,10.0);
	return 0;
}
stock ShowMenuDialog(playerid)
{
	SPD(playerid,dialog_menu,2,"{FFA500}Игровое меню","{FFA500}1.{FFFFFF} Персонаж\n{FFA500}2.{FFFFFF} FAQ\n{FFA500}3.{FFFFFF} Связь с администрацией\n{FFA500}4.{FFFFFF} Команды сервера","Выбрать","Закрыть");
}
stock ShowBusinessStats(playerid,businessid)
{
	new string[500];
	format
	(
			string, sizeof string,
			"{"#cW"}Название:\t\t\t\t{"#cGold"}%s\n"\
			"{"#cW"}Номер бизнеса:\t\t\t%d\n"\
			"Владелец:\t\t\t\t%s\n"\
			"Плата за вход:\t\t\t\t%d$\n"\
			"Количество продуктов:\t\t%d/%d\n"\
			"Баланс бизнеса:\t\t\t%d$\n"\
			"Бизнес арендован на:\t\t%d/30 дней\n"\
			"{"#cW"}Гос. стоимость:\t\t\t%d$\n"\
			"Стоимость аренды:\t\t\t%d$/день\n"\
			"Статус:\t\t\t\t\t%s{FFFFFF}\n\n"\
			"- Используйте кнопку - \"{FFA500}Далее{FFFFFF}\",\n\
			 чтобы перейти в меню управления бизнесом",
			GetBusinessData(businessid, B_NAME),
			businessid,
			GetBusinessData(businessid, B_OWNER_NAME),
			GetBusinessData(businessid, B_ENTER_PRICE),
			GetBusinessData(businessid, B_PRODS),
			500,
			GetBusinessData(businessid, B_BALANCE),
			GetBusinessData(businessid, B_RENT_DATE) <= gettime() ? 0 :
			GetElapsedTime(GetBusinessData(businessid, B_RENT_DATE), gettime(), CONVERT_TIME_TO_DAYS),
			GetBusinessData(businessid, B_PRICE),
			GetBusinessData(businessid, B_RENT_PRICE),
			GetBusinessData(businessid, B_LOCK_STATUS) ? ("{CC3333}Бизнес закрыт") : ("{66CC33}Бизнес открыт")
	);
	SPD(playerid,dialog_business,DIALOG_STYLE_MSGBOX,"{FFA500}Статистика бизнеса",string,"Далее","Закрыть");
}
CMD:drugs(playerid, params[])
{
	if(PL[playerid])
	{
	    if(GetPVarInt(playerid, "DrugsTime") < gettime())
		{
		    if(!sscanf(params,"d",params[0]))
		    {
				if(params[0] >= 1 && params[0] <= 3)
				{
					new string[100],Float:health;
				 	GetPlayerHealth(playerid,health);
					if(health < 96) SetPlayerHealth(playerid, health + 5 * params[0]);
					format(string, sizeof string, "Вы употребили %d грамм наркотиков. Наркозависимость увеличилась!",params[0]);
					SCM(playerid,COLOR_LIME, string);
					Action(playerid,"употребил(-а) наркотики");
					if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) ApplyAnimation(playerid,"SMOKING","M_smk_drag",4.1,0,0,0,0,0,1);
					SetPVarInt(playerid,"DrugsTime", gettime() + 60);
					PI[playerid][pDrugs] -= params[0];
					SetPlayerTime(playerid,17,0);
					SetPlayerDrunkLevel(playerid, 3000);
					SetPlayerWeather(playerid, -68);
				}
				else SCM(playerid,COLOR_GREY,"Возможное количество от 3 до 5 грамм!");
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /drugs [Кол-во грамм]");
		}
		else SCM(playerid, COLOR_DARKORANGE, "Вы уже недавно употребляли наркотики!");
	}
	return 1;
}
CMD:hp(playerid)
{
	if(PL[playerid])
	{
		if(PI[playerid][pAdmin])
		{
		    if(AL[playerid])
		    {
		        SetPlayerHealth(playerid,100.0);
        		if(IsPlayerInAnyVehicle(playerid))
				{
				    RepairVehicle(GetPlayerVehicleID(playerid));
				    Fuel[GetPlayerVehicleID(playerid)] = 100;
				}
				SCM(playerid,COLOR_BLUE,"Характеристики восстановлены!");
		    }
		    else SCM(playerid,COLOR_GREY,IsNotAL);
		}
	}
	return 1;
}
CMD:fuel(playerid)
{
	if(PL[playerid])
	{
		if(IsPlayerInAnyVehicle(playerid))
		{
		    if(GetNearestFuelSt(playerid,5.0) != -1)
		    {
		        if(!GetBusinessData(GetNearestFuelSt(playerid,2.0), B_LOCK_STATUS))
		        {
			        new string[120];
			        format(string,sizeof string, "{FFFFFF}Введите в строчку ниже количество топлива,\nкоторое хотите заправить.\n\nЦена за 1 литр: {FFA500}%d$",GetBusinessData(GetNearestFuelSt(playerid,5.0),B_PROD_PRICE));
					SPD(playerid,dialog_fuel,DIALOG_STYLE_INPUT,"{FFA500}Заправочная станция",string,"Далее","Закрыть");
				}
				else SCM(playerid,COLOR_DARKORANGE,"АЗС закрыта, приходите позже!");
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"Вы далеко от заправки! Найдите ближайшую, используя /gps");
		}
		else SCM(playerid,COLOR_DARKORANGE,"Вы должны находиться в транспорте!");
	}
	return 1;
}
CMD:business(playerid)
{
	if(PL[playerid])
	{
		if(PI[playerid][pBusinessID] >= 0)
		{
            ShowBusinessStats(playerid,PI[playerid][pBusinessID]);
		}
		else SCM(playerid,COLOR_DARKORANGE,"У вас нет бизнеса!");
	}
	return 1;
}
CMD:members(playerid)
{
    if(PL[playerid])
    {
		if(PI[playerid][pMember])
		{
			new full, string[150], string_dialogue[500];
		    strcat(string_dialogue, "{FFA500}ID\tУровень\tТелефон\tРанг\tНик\n\n");
			foreach(new i: Player)
			{
				if(PL[i] == false) continue;
				if(PI[i][pMember] == PI[playerid][pMember])
				{
				    format(string, sizeof(string),"{FFFFFF}%i\t%i\t\t%d\t\t%d\t%s\n", i, PI[i][pLVL],PI[i][pPhoneNumber], PI[i][pRank], GN(i));
					strcat(string_dialogue, string);
					//if(IsPlayerAFK(i)) strcat(string_dialogue,"- AFK");
					full++;
				}
			}
			SPD(playerid, 0, DIALOG_STYLE_MSGBOX, "{FFA500}Общий онлайн организации:", string_dialogue, "Закрыть", "");
		}
		else SCM(playerid, COLOR_DARKORANGE, "Вы не состоите в организации!");
	}
	return 1;
}
CMD:jp(playerid)
{
	if(PL[playerid])
 	{
		if(PI[playerid][pAdmin])
	   	{
			if(AL[playerid]) SetPlayerSpecialAction(playerid,SPECIAL_ACTION_USEJETPACK);
			else SCM(playerid,COLOR_GREY,IsNotAL);
	   	}
  	}
   	return 1;
}
CMD:leaders(playerid)
{
    if(PL[playerid])
    {
		new string[150], string_dialogue[500];
	    strcat(string_dialogue, "{FFA500}ID\tНик\t\t\tФракция\t\tДолжность\n\n");
		foreach(new i: Player)
		{
			if(PL[i] == false) continue;
			if(!PI[i][pLeader]) continue;
	        format(string, sizeof(string),"{FFFFFF}%i\t%s\t%s\t%s\n", i, GN(i),Fraction_Name[PI[i][pMember]], Fraction_Rank(i));
			strcat(string_dialogue, string);
		}
		SPD(playerid, 0, DIALOG_STYLE_MSGBOX, "{FFA500}Список лидеров онлайн:", string_dialogue, "Закрыть", "");
	}
	return 1;
}
CMD:creategun(playerid)
{
	if(PL[playerid])
	{
	}
	return 1;
}
CMD:lmenu(playerid)
{
	if(PL[playerid])
	{
		if(PI[playerid][pLeader])
		{
			ShowPlayerLeaderMenu(playerid);
		}
	}
	return 1;
}
CMD:offuninvite(playerid)
{
	if(PL[playerid])
	{
		if(PI[playerid][pLeader])
		{

		}
	}
	return 1;
}
CMD:invite(playerid, params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
			if(PI[playerid][pRank] > 8)
			{
				if(!sscanf(params,"d", params[0]))
				{
					if(params[0] != playerid)
					{
					    if(!PI[params[0]][pMember])
					    {
						    if(PL[params[0]] && IsPlayerInRangeOfPlayer(playerid, params[0], 5.0))
						    {
						        new fmt_str[150];
	     						format(fmt_str, sizeof fmt_str, "%s предлагает Вам вступить в организацию \"%s\"", GN(playerid), Fraction_Name[PI[playerid][pMember]]);
								SCM(params[0], 0x3399FFFF, fmt_str);
								SCM(params[0], -1, "Нажмите {00CC00}Y {"#cW"}чтобы принять предложение или {FF6600}N {"#cW"}для отказа");
								format(fmt_str, sizeof fmt_str, "Вы предложили %s вступить в организацию \"%s\"", GN(params[0]), Fraction_Name[PI[playerid][pMember]]);
								SCM(playerid, 0x3399FFFF, fmt_str);
								PI[params[0]][pInfoF] = 1;
								PI[params[0]][pInfoF2] = playerid;
						    }
						    else SCM(playerid,COLOR_GREY, "Вы слишком далеко!");
					    }
					    else SCM(playerid,COLOR_DARKORANGE,"Указаный вами игрок уже состоит в организаци!");
				    }
				    else SCM(playerid,COLOR_GREY,"Вы указали свой ID!");
				}
				else SCM(playerid,COLOR_LIME, "Информация:{FFFFFF} /invite [ID]");
			}
			else SCM(playerid,COLOR_DARKORANGE,"Вам недоступна данная функция!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE, "Вы не состоите в организации!");
	}
	return 1;
}
CMD:lock(playerid)
{
	if(PL[playerid])
	{
        new vehicleid = INVALID_VEHICLE_ID;
        vehicleid = GetPlayerOwnableCar(playerid);
		if(vehicleid == INVALID_VEHICLE_ID)
		{
			if(GetPlayerOwnableCars(playerid) == 0) return SendClientMessage(playerid, 0xFF6600FF, "У Вас нет личного транспорта");
			else return SCM(playerid, COLOR_DARKORANGE, "Ваш личный транспорт не загружен на сервер");
		}
		new Float: x, Float: y, Float: z;
		GetVehiclePos(vehicleid, x, y, z);

		if(IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z))
		{
			new status = GetVehicleParam(vehicleid, V_LOCK);
			if(status)
			{
				Action(playerid, "открыл транспорт", _, true);
				GameTextForPlayer(playerid,"~w~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~ЏPAнCЊOPЏ~g~ OЏKP‘Џ", 3000, 3);
			}
			else
			{
				Action(playerid, "закрыл транспорт", _, true);
				GameTextForPlayer(playerid,"~w~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~ЏPAнCЊOPЏ~r~ €AKP‘Џ", 3000, 3);
			}
			SetVehicleParam(vehicleid, V_LOCK, status ^ VEHICLE_PARAM_ON);
		}
		else SendClientMessage(playerid, 0xFF6600FF, "Вы должны стоять рядом с транспортом");
	}
	return 1;
}
CMD:uninvite(playerid, params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
			if(PI[playerid][pRank] > 8)
			{
			    new reason[20];
				if(!sscanf(params,"ds[20]", params[0],reason))
				{
					if(params[0] != playerid)
					{
	    				if(PI[params[0]][pMember] == PI[playerid][pMember])
				    	{
							if(PI[params[0]][pRank] < PI[playerid][pRank])
							{
							    UnInvitePlayer(playerid, params[0],reason, 1);
							}
							else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
		    			}
					    else SCM(playerid,COLOR_GREY, "Указаный вами игрок не состоит в вашей организации!");
				    }
				    else SCM(playerid,COLOR_GREY,"Вы указали свой ID!");
				}
				else SCM(playerid,COLOR_LIME, "Информация:{FFFFFF} /uninvite [ID] [Причина]");
			}
			else SCM(playerid,COLOR_DARKORANGE,"Вам недоступна данная функция!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE, "Вы не состоите в организации!");
	}
	return 1;
}
CMD:yes(playerid)
{
	if(PL[playerid])
	{
	    if(PI[playerid][pInfoF])
	    {
			new fmt_msg[120], fr_id;
			fr_id = PI[PI[playerid][pInfoF2]][pMember];
			format(fmt_msg, sizeof fmt_msg, "Поздравляем! Вы вступили в организацию \"%s\"", Fraction_Name[fr_id]);
			SCM(playerid, 0x66CC00FF, fmt_msg);
			format(fmt_msg, sizeof fmt_msg, "%s принял Ваше предложение вступить в организацию", GN(playerid));
			SCM(PI[playerid][pInfoF2], COLOR_LIME, fmt_msg);
			InvitePlayer(playerid,fr_id);
	    }
	}
	return 1;
}
CMD:no(playerid)
{
	if(PL[playerid])
	{
	    if(PI[playerid][pInfoF])
	    {
			new fmt_msg[120];
			format(fmt_msg, sizeof fmt_msg, "Вы отказались от предложения %s вступить в организацию", GN(PI[playerid][pInfoF2]));
			SCM(playerid, COLOR_DARKORANGE, fmt_msg);
			format(fmt_msg, sizeof fmt_msg, "%s отказался от Вашего предложения вступить в организацию", GN(playerid));
			SCM(PI[playerid][pInfoF2], COLOR_DARKORANGE, fmt_msg);
			PI[playerid][pInfoF2] = PI[playerid][pInfoF] = 0;
	    }
	}
	return 1;
}
CMD:capture(playerid)
{
	if(GetInfo(playerid,pMember) == 8 || GetInfo(playerid,pMember) == 9 || GetInfo(playerid,pMember) == 10)
	{
	    if(GetInfo(playerid,pRank) > 7)
	    {
	        if(!g_capture[C_STATUS])
	        {
				new gang_id = PI[playerid][pMember] - 7;
				if(g_capture[C_WAIT_TIME][gang_id - 1] < gettime())
				{
				    new gang_zone_id = -1;

					for(new idx; idx < g_gang_zones_loaded; idx ++)
					{
						if(!IsPlayerInDynamicArea(playerid, GetGangZoneData(idx, GZ_AREA))) continue;

						gang_zone_id = idx;
						break;
					}
					if(gang_zone_id != -1)
					{
						new gang_zone_team = GetGangZoneData(gang_zone_id, GZ_GANG);
						if(gang_zone_team)
						{
							if(gang_zone_team != gang_id)
							{
 								if(g_capture[C_WAIT_TIME][gang_zone_team - 1] < gettime())
								{
								    new gang_players[2];
									foreach(new idx : Player)
									{
										if(PI[idx][pMember] == PI[playerid][pMember]) gang_players[0] ++;
										else if(PI[idx][pMember] == gang_zone_team + 7) gang_players[1] ++;
										else continue;
									}
									StartCapture(playerid, gang_zone_id, gang_id, gang_zone_team);
								}
								else SCM(playerid, COLOR_DARKORANGE, "Банда, чью территорию Вы хотите захватить, еще не окрепла с последнего захвата (не прошел 1 час)");
							}
							else SendClientMessage(playerid, COLOR_DARKORANGE, "Вы не можете захватить свою территорию");
						}
						else SCM(playerid, COLOR_DARKORANGE, "Вы должны находиться на захваченной кем-то территории");
	 				}
					else SCM(playerid, COLOR_DARKORANGE, "Вы должны находиться на захваченной кем-то территории");
				}
				else SCM(playerid,COLOR_DARKORANGE,"С момента вашего предыдущего захвата ещё не прошел час!");
	        }
	        else SCM(playerid,COLOR_DARKORANGE, "Недоступно! Какая-то банда уже начала захват.");
	    }
	    else SCM(playerid,COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:cuff(playerid,params[])
{
	if(PL[playerid])
	{
	    if(IsPoliceTeam(playerid))
	    {
			if(!sscanf(params,"d",params[0]))
			{
			    if(PL[params[0]] && IsPlayerConnected(params[0]))
			    {
			        if(playerid != params[0])
			        {
			            if(!PI[params[0]][pCuffed])
			            {
			                new fmt[100];
              				SetPlayerSpecialAction(params[0], SPECIAL_ACTION_CUFFED);
							SetPlayerAttachedObject(params[0], A_OBJECT_SLOT_HAND, 19418, A_OBJECT_BONE_RIGHT_HAND, -0.011, 0.028, -0.022, -15.600012, -33.699977, -81.700035, 0.891999, 1.00, 1.168);
							SetInfo(params[0], pCuffed, 1);
							format(fmt,sizeof fmt, "Лейтенант %s[%d] надел на вас наручники",GN(playerid),playerid);
							SCM(params[0],COLOR_LIME, fmt);
							format(fmt,sizeof fmt, "Вы надели на %s[%d] наручники. Чтобы освободить используйте - /uncuff",GN(params[0]),params[0]);
							SCM(playerid,COLOR_LIME, fmt);
				 			format(fmt, sizeof(fmt), "%s[%d] надел(-а) наручники на %s[%d]",GN(playerid),playerid,GN(params[0]),params[0]);
  							ProxDetector(20.0, playerid, fmt, COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE);
			            }
			            else SCM(playerid, COLOR_GREY, "Указаный вами игрок уже в наручниках!");
			        }
			        else SCM(playerid, COLOR_DARKORANGE, "Вы указали свой ID!");
			    }
			    else SCM(playerid,COLOR_GREY,"Неверно указан ID!");
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /cuff [ID]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:su(playerid,params[])
{
	if(PL[playerid])
	{
	    if(IsPoliceTeam(playerid))
	    {
	        new reason[20];
			if(!sscanf(params,"ds[15]",params[0],reason))
			{
			    if(PL[params[0]] && IsPlayerConnected(params[0]))
			    {
			        if(playerid != params[0])
			        {
			            if(PI[params[0]][pSu] < 6)
			            {
							PI[params[0]][pSu]++;
							SetPlayerWantedLevel(params[0],PI[params[0]][pSu]);
							new string[100];
							format(string, sizeof string, "Лейтенант %s[%d] объявил вас в розыск. Причина: %s",GN(playerid),playerid,reason);
							SCM(params[0],COLOR_DARKORANGE,string);
							format(string, sizeof string, "Вы объявили %s[%d] в розыск. Уровень розыска - %d", GN(params[0]),params[0],PI[params[0]][pSu]);
							SCM(playerid,COLOR_DARKORANGE,string);
							format(string,sizeof string, "[Объявление] %s[%d] объявил в розыск %s[%d]. Причина: %s",GN(playerid),playerid,GN(params[0]),params[0],reason);
							SCM_SU(string,0x4682B4FF);
						}
						else SCM(playerid,COLOR_GREY,"У указаного игрока максимальный уровень розыска!");
			        }
			        else SCM(playerid, COLOR_DARKORANGE, "Вы указали свой ID!");
			    }
			    else SCM(playerid,COLOR_GREY,"Неверно указан ID!");
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /su [ID] [Причина]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:d(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
	        new msg_t[30],string[100];
			if(!sscanf(params,"s[30]",msg_t))
			{
				format(string,sizeof(string), "[D] %s %s[%d]: %s",Fraction_Rank(playerid),GN(playerid),playerid,msg_t);
				for(new i = 1; i < 7; i++) SCM_T(i,string,0xFF9999FF);
				format(string, sizeof string,"передал(-а) в рацию: %s",msg_t);
				SetPlayerChatBubble(playerid, string, 0xDD99FFAA, 10.0, 4000);
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /d [Текст]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:db(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
	        new msg_t[30],string[100];
			if(!sscanf(params,"s[30]",msg_t))
			{
				format(string,sizeof(string), "(( [D] %s %s[%d]: %s ))",Fraction_Rank(playerid),GN(playerid),playerid,msg_t);
				for(new i = 1; i < 7; i++) SCM_T(i,string,0xFF9999FF);
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /d [Текст]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:radio(playerid,params[]) return cmd_r(playerid,params);
CMD:r(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
	        new msg_t[30],string[100];
			if(!sscanf(params,"s[30]",msg_t))
			{
				format(string,sizeof(string), "[R] %s %s[%d]: %s",Fraction_Rank(playerid),GN(playerid),playerid,msg_t);
				SCM_T(PI[playerid][pMember],string,0x33CC66FF);
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /r [Текст]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:rb(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
	        new msg_t[30],string[120];
			if(!sscanf(params,"s[30]",msg_t))
			{
				format(string,sizeof(string), "(( [R] %s[%d]: %s ))",GN(playerid),playerid,msg_t);
				SCM_T(PI[playerid][pMember],string,0x33CC66FF);
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /rb [OOC текст]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:uncuff(playerid,params[])
{
	if(PL[playerid])
	{
	    if(IsPoliceTeam(playerid))
	    {
			if(!sscanf(params,"d",params[0]))
			{
			    if(PL[params[0]] && IsPlayerConnected(params[0]))
			    {
			        if(playerid != params[0])
			        {
			            if(PI[params[0]][pCuffed])
			            {
			                new fmt[100];
          					SetPlayerSpecialAction(params[0], SPECIAL_ACTION_NONE);
							RemovePlayerAttachedObject(params[0], A_OBJECT_SLOT_HAND);
							SetInfo(params[0], pCuffed, 0);
							format(fmt,sizeof fmt, "Лейтенант %s[%d] снял с вас наручники",GN(playerid),playerid);
							SCM(params[0],COLOR_LIME, fmt);
							format(fmt,sizeof fmt, "Вы сняли с %s[%d] наручники",GN(params[0]),params[0]);
							SCM(playerid,COLOR_LIME, fmt);
					  		format(fmt, sizeof(fmt), "%s[%d] снял(-а) наручники с %s[%d]",GN(playerid),playerid,GN(params[0]),params[0]);
  							ProxDetector(20.0, playerid, fmt, COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE);
			            }
			            else SCM(playerid, COLOR_GREY, "Указаный вами игрок не в наручниках!");
			        }
			        else SCM(playerid, COLOR_DARKORANGE, "Вы указали свой ID!");
			    }
			    else SCM(playerid,COLOR_GREY,"Неверно указан ID!");
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /uncuff [ID]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:tazer(playerid,params[])
{
	if(PL[playerid])
	{
	    if(IsPoliceTeam(playerid))
	    {
			if(!sscanf(params,"d",params[0]))
			{
			    if(PL[params[0]] && IsPlayerConnected(params[0]))
			    {
			        if(playerid != params[0])
			        {
			            new string[100];
       					format(string, sizeof(string), "%s[%d] ударил(-а) электрошокером %s[%d]",GN(playerid),playerid,GN(params[0]),params[0]);
					  	ProxDetector(20.0, playerid, string, COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE,COLOR_PURPLE);
					  	TogglePlayerControllable(params[0], 0);
					  	SetPlayerSpecialAction(params[0],SPECIAL_ACTION_HANDSUP);
					  	SetInfo(params[0],pTazered,1);
					  	SetInfo(params[0],pTazerTime,15);
			        }
			        else SCM(playerid, COLOR_DARKORANGE, "Вы указали свой ID!");
			    }
			    else SCM(playerid,COLOR_GREY,"Неверно указан ID!");
			}
			else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /tazer [ID]");
	    }
	    else SCM(playerid, COLOR_DARKORANGE, "Вам недоступна данная функция!");
	}
	return 1;
}
CMD:rang(playerid, params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pMember])
	    {
			if(PI[playerid][pRank] > 8)
			{
				new sew[20];
				if(!sscanf(params,"ds[20]", params[0],sew))
				{
					if(params[0] != playerid)
					{
					    if(PI[params[0]][pMember] == PI[playerid][pMember])
					    {
						    if(PL[params[0]] && IsPlayerInRangeOfPlayer(playerid, params[0], 5.0))
							{
							    new fmt_msg[150];
							    if(sew[0] == '+')
							    {
							        if((PI[params[0]][pRank]+1) < PI[playerid][pRank])
							        {
										PI[params[0]][pRank]++;
       									format(fmt_msg, sizeof fmt_msg, "Ваш ранг в организации был повышен до %s[%d]", Fraction_Rank(params[0]), PI[params[0]][pRank]);
										SCM(params[0], 0x3399FFFF, fmt_msg);
										format(fmt_msg, sizeof fmt_msg, "Вы повысили %s на ранг %s[%d]",GN(params[0]), Fraction_Rank(params[0]), PI[params[0]][pRank]);
										SCM(playerid, 0x3399FFFF, fmt_msg);
									}
									else SCM(playerid,COLOR_DARKORANGE, "Вам недоступна данная функция!");
							    }
							    else if(sew[0] == '-')
							    {
									if((PI[params[0]][pRank]-1) > 0)
									{
										if(PI[params[0]][pRank] < PI[playerid][pRank])
										{
										    PI[params[0]][pRank]--;
       										format(fmt_msg, sizeof fmt_msg, "Ваш ранг в организации был понижен до %s[%d]",Fraction_Rank(params[0]), PI[params[0]][pRank]);
											SCM(params[0], COLOR_DARKORANGE, fmt_msg);
											format(fmt_msg, sizeof fmt_msg, "Вы понизили %s на ранг %s[%d]",GN(params[0]), Fraction_Rank(params[0]), PI[params[0]][pRank]);
											SCM(playerid, COLOR_DARKORANGE, fmt_msg);
										}
									}
									else SCM(playerid,COLOR_DARKORANGE,"Нельзя понизить ниже 1-ого ранга!");
							    }
								else SCM(playerid,COLOR_LIME, "Информация:{FFFFFF} /rang [ID] [+/-]");
					    	}
						    else SCM(playerid,COLOR_GREY, "Вы слишком далеко!");
					    }
					    else SCM(playerid,COLOR_DARKORANGE,"Указаный вами игрок не состоит в вашей организаци!");
				    }
				    else SCM(playerid,COLOR_GREY,"Вы указали свой ID!");
				}
				else SCM(playerid,COLOR_LIME, "Информация:{FFFFFF} /rang [ID] [+/-]");
			}
			else SCM(playerid,COLOR_DARKORANGE,"Вам недоступна данная функция!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE, "Вы не состоите в организации!");
	}
	return 1;
}
CMD:makeleader(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin] > 2)
	    {
	        if(AL[playerid])
	        {
	            if(!(sscanf(params,"d",params[0])))
	            {
	                if(IsPlayerConnected(params[0]))
	                {
		                if(PL[params[0]])
		                {
							if(PI[params[0]][pLeader])
							{
								SCM(playerid,COLOR_DARKORANGE,"Данный игрок уже назначен на пост лидера, чтобы его разжаловать используйте - /delleader");
							}
							else
							{
							    new str[90], str2[600];
							    for(new i = 1; i < MAX_FRACTIONS; i++)
							    {
        							format(str, sizeof(str), "{FFA500}%i.{FFFFFF} %s\n", i, Fraction_Name[i]);
									strcat(str2, str);
								}
								SetPVarInt(playerid, "actplayerid", params[0]);
								SPD(playerid, dialog_makeleader, 2, "{FFA500}Организации", str2, "Выбрать", "Закрыть");
							}
		                }
						else SCM(playerid,COLOR_GREY,"Указаный вами игрок не авторизован!");
	                }
	                else SCM(playerid,COLOR_GREY,"Указаный вами игрок не в сети!");
	            }
	            else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /makeleader [ID]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:makeadmin(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin] > 2)
	    {
	        if(AL[playerid])
	        {
	            new a_name[MAX_PLAYER_NAME],string[100];
	            if(!(sscanf(params,"s[24]d",a_name,params[0])))
	            {
					mysql_format(dbHandle,string,sizeof string, "SELECT * FROM `a_users` WHERE `a_name` = '%s'",a_name);
					mysql_tquery(dbHandle,string,"MakeAdmin","dsd",playerid,a_name,params[0]);
	            }
	            else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /makeadmin [Ник] [Уровень: 1 - 3]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:sethp(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin] > 0)
	    {
	        if(AL[playerid])
	        {
	            new string[100];
	            if(!(sscanf(params,"dd",params[0],params[1])))
	            {
           			if(IsPlayerConnected(params[0]))
	                {
		                if(PL[params[0]])
		                {
		                    if(params[1] >= 1 && params[1] <= 1000)
		                    {
		                        SetPlayerHealth(params[0],params[1]);
		                        format(string, sizeof string, "[A] %s[%d] установил %s[%d] %d HP.",GN(playerid),playerid,GN(params[0]),params[0],params[1]);
		                        SCM_A(COLOR_GREY, string);
		                        format(string, sizeof string, "%s[%d] установил Вам %d HP.",GN(playerid),playerid,params[1]);
		                        SCM(params[0],COLOR_BLUE,string);
		                    }
		                    else SCM(playerid,COLOR_GREY,"Возможное значение: 1 - 1000.");
		                }
						else SCM(playerid,COLOR_GREY,"Указаный вами игрок не авторизован!");
	                }
	                else SCM(playerid,COLOR_GREY,"Указаный вами игрок не в сети!");
	            }
	            else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /sethp [ID] [Количество]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:setarmour(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin] > 0)
	    {
	        if(AL[playerid])
	        {
	            new string[100];
	            if(!(sscanf(params,"dd",params[0],params[1])))
	            {
           			if(IsPlayerConnected(params[0]))
	                {
		                if(PL[params[0]])
		                {
		                    if(params[1] >= 1 && params[1] <= 1000)
		                    {
		                        SetPlayerArmour(params[0],params[1]);
		                        format(string, sizeof string, "[A] %s[%d] установил %s[%d] %d ед. брони.",GN(playerid),playerid,GN(params[0]),params[0],params[1]);
		                        SCM_A(COLOR_GREY, string);
		                        format(string, sizeof string, "%s[%d] установил Вам %d ед. брони.",GN(playerid),playerid,params[1]);
		                        SCM(params[0],COLOR_BLUE,string);
		                    }
		                    else SCM(playerid,COLOR_GREY,"Возможное значение: 1 - 1000.");
		                }
						else SCM(playerid,COLOR_GREY,"Указаный вами игрок не авторизован!");
	                }
	                else SCM(playerid,COLOR_GREY,"Указаный вами игрок не в сети!");
	            }
	            else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /setarmour [ID] [Количество]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:deladmin(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin] > 2)
	    {
	        if(AL[playerid])
	        {
	            new a_name[MAX_PLAYER_NAME],string[100],reason[30];
	            if(!(sscanf(params,"s[24]s[30]", a_name, reason)))
	            {
					mysql_format(dbHandle,string,sizeof string, "SELECT * FROM `a_users` WHERE `a_name` = '%s'",a_name);
					mysql_tquery(dbHandle,string,"DelAdmin","dss",playerid,a_name,reason);
	            }
	            else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /deladmin [Ник] [Причина]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
function: DelAdmin(playerid,name[24],reason[30])
{
	new rows,fields,string[200];
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(rows)
	{
	    if(GetPlayerID(name) != INVALID_PLAYER_ID) PI[GetPlayerID(name)][pAdmin] = 0;
	    mysql_format(dbHandle,string,sizeof string, "DELETE FROM `a_users` WHERE `a_name` = '%s'", name);
	    mysql_tquery(dbHandle,string);
	    mysql_format(dbHandle,string,sizeof string, "UPDATE `users` SET `a_lvl` = '0' WHERE `name` = '%s'", name);
	    mysql_tquery(dbHandle,string);
	    format(string, 100, "[A] %s[%d] снял с поста администратора %s. Причина: %s",GN(playerid),playerid,name,reason);
	    SCM_A(COLOR_GREY,string);
	}
	else
	{
	    SCM(playerid,COLOR_DARKORANGE,"Указаный вами игрок не администратор!");
	    SCM(playerid,COLOR_GREY,"Проверьте правильность отправленого запроса.");
	}
	return 1;
}
function: MakeAdmin(playerid,name[24],lvl)
{
	new rows,fields,string[300];
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(rows)
	{
	    if(!lvl)
	    {
		    SCM(playerid,COLOR_DARKORANGE,"Указаный вами игрок уже назначен на пост администратора!");
		    SCM(playerid,COLOR_DARKORANGE,"Чтобы снять его с поста используйте команду - /deladmin");
	    }
	    else
	    {
	        if(GetPlayerID(name) != INVALID_PLAYER_ID) PI[GetPlayerID(name)][pAdmin] = lvl;
			mysql_format(dbHandle,string,sizeof string,"UPDATE `a_users` SET a_lvl = '%d' WHERE a_name = '%s'",lvl,name);
			mysql_tquery(dbHandle,string);
			format(string,100,"Вы изменили уровень администратора %s на %d",name,lvl);
			SCM(playerid,COLOR_BLUE,string);
	    }
	}
	else
	{
		if(!lvl) return SCM(playerid, COLOR_GREY, "Игрок не администратор");
		mysql_format(dbHandle, string, sizeof(string), "INSERT INTO `a_users` (`a_name`, `a_lvl`) VALUES ('%s', '%d')", name, lvl);
		mysql_tquery(dbHandle, string);
		format(string, sizeof(string), "%s добавлен в список администрации. Уровень администратирования - %i", name, lvl);
	    SCM(playerid, COLOR_LIME, string);
	}
	return 1;
}
CMD:pm(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin])
	    {
	        if(AL[playerid])
	        {
	            new string[200],msg[50];
	            if(!(sscanf(params,"ds[50]",params[0],msg)))
	            {
             		if(IsPlayerConnected(params[0]))
	                {
		                if(PL[params[0]])
		                {
              				format(string, sizeof(string), "Админинстратор %s[%d] для %s[%d]: %s", GN(playerid),playerid,GN(params[0]),params[0], msg);
							SCM(params[0], 0xFF9945FF, string);
							format(string, sizeof(string), "Админинстратор %s[%d] для %s[%d]: %s", GN(playerid),playerid,GN(params[0]),params[0], msg);
							SCM_A(0xFF9945FF, string);
							if(playerid != params[0])
							{
							    if(PI[params[0]][pReportState])
							    {
							        PI[params[0]][pReportState] = 0;
							        SetPVarInt(params[0],"a_id",playerid);
							        SPD(params[0],dialog_dlz,DIALOG_STYLE_MSGBOX,"{FFA500}Отзыв","{FFFFFF}Оцените, как ответил на ваш вопрос админстратора","Хорошо","Плохо");
							    }
							}
		                }
						else SCM(playerid,COLOR_GREY,"Указаный вами игрок не авторизован!");
	                }
	                else SCM(playerid,COLOR_GREY,"Указаный вами игрок не в сети!");
	            }
	            else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /pm [ID] [Ответ]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:kick(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin])
	    {
	        if(AL[playerid])
	        {
	            new string[100],reason[20],p_id;
				if(!(sscanf(params,"ds[20]",p_id,reason)))
				{
					format(string, sizeof string, "Администратор %s[%d] отключил вас от сервера. Причина: %s",GN(playerid),playerid,reason);
					SCM(p_id,COLOR_DARKORANGE,string);
					format(string, sizeof string, "[A] %s[%d] отключил от сервера %s[%d]. Причина: %s",GN(playerid),playerid,GN(p_id),p_id,reason);
					SCM_A(COLOR_GREY,string);
					format(string, sizeof string, "Администратор %s[%d] отключил от сервера %s[%d]. Причина: %s",GN(playerid),playerid,GN(p_id),p_id,reason);
					SendClientMessageToAll(0xFF5533FF,string);
					Kick(p_id);
				}
				else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /kick [ID] [Причина]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:aad(playerid, params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin])
	    {
	        if(AL[playerid])
	        {
	            new string[150],reason[50];
				if(!(sscanf(params,"s[50]",reason)))
				{
					format(string, sizeof string, "Администратор %s[%d]: %s",GN(playerid),playerid,reason);
					SendClientMessageToAll(COLOR_YELLOW,string);
				}
				else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /aad [Сообщение]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:skick(playerid,params[])
{
	if(PL[playerid])
	{
	    if(PI[playerid][pAdmin])
	    {
	        if(AL[playerid])
	        {
	            new string[100],reason[20],p_id;
				if(!(sscanf(params,"ds[20]",p_id,reason)))
				{
					format(string, sizeof string, "Администратор %s[%d] отключил вас от сервера. Причина: %s",GN(playerid),playerid,reason);
					SCM(p_id,COLOR_DARKORANGE,string);
					format(string, sizeof string, "[A] %s[%d] отключил от сервера %s[%d]. Причина: %s (/skick)",GN(playerid),playerid,GN(p_id),p_id,reason);
					SCM_A(COLOR_GREY,string);
					Kick(p_id);
				}
				else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /skick [ID] [Причина]");
	        }
	        else SCM(playerid,COLOR_GREY,IsNotAL);
	    }
	}
	return 1;
}
CMD:t(playerid) return cmd_time(playerid);
CMD:time(playerid)
{
	if(PL[playerid])
	{
		new hour, minute, year, month, day, string[200];
		gettime(hour, minute);
		getdate(year, month, day);
		if(!IsPlayerInAnyVehicle(playerid)) ApplyAnimation(playerid, "COP_AMBIENT", "Coplook_watch", 4.0, false, 0, 0, 0, 0, 0);
		format(string, sizeof string, "~y~%d:%02d~n~~b~~h~%02d.%02d.%d", hour, minute, day, month, year);
		GameTextForPlayer(playerid, string, 3000, 1);
	}
	return 1;
}
CMD:id(playerid,params[])
{
	if(strlen(params))
	{
		new fmt_str[64];
		new count;
		foreach(new idx : Player)
		{
			if(!PL[idx]) continue;
			SCM(playerid,COLOR_BLUE,"Поиск совпадений:");
			if(strfind(GN(idx), params, true) != -1)
			{
				count ++;
				format(fmt_str, sizeof fmt_str, "%d. %s[%d]", count, GN(idx), idx);
				SCM(playerid, -1, fmt_str);

				if(count >= 5)
				{
					SCM(playerid, -1, "Показаны первые 5 совпадений");
					break;
				}
			}
		}
		if(!count) SCM(playerid, COLOR_GREY, "Совпадений не найдено");
	}
	else SCM(playerid, COLOR_LIME, "Информация:{"#cW"} /id [Ник/Часть ника]");
	return 1;
}
CMD:healme(playerid)
{
	if(PL[playerid])
	{
	    if(GetInfo(playerid,pHealc) > 0)
	    {
			new Float:health,string[100];
			GetPlayerHealth(playerid,health);
			if(health <= 94)
			{
				SetPlayerHealth(playerid,95);
				Action(playerid,"перебинтовал(-а) раны");
				ApplyAnimation(playerid, "ped", "gum_eat", 4.0, 0, 0, 0, 0, 0, 0);
				AddInfo(playerid,pHealc,-,1);
				format(string,sizeof string,"Вы использовали аптечку. Количество оставшихся аптечек: %d",PI[playerid][pHealc]);
				SCM(playerid,COLOR_LIME,string);
			}
			else SCM(playerid,COLOR_DARKORANGE,"Невозможно использовать аптечку!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE,"У Вас нет аптечки!");
	}
	return 1;
}
CMD:mask(playerid)
{
	if(PL[playerid])
	{
	    if(GetInfo(playerid,pMask) > 0)
	    {
			if(!GetInfo(playerid,pStateMask))
			{
			    new string[100];
				PI[playerid][pStateMask] = 1;
				Action(playerid,"надевает маску");
				ApplyAnimation(playerid, "SHOP", "ROB_Shifty", 4.0, 0, 0, 0, 0, 0, 0);
				AddInfo(playerid,pMask,-,1);
				format(string,sizeof string,"Вы надели маску. Ваше местоположение скрыто до смерти/релога. Количество оставшихся масок: %d",PI[playerid][pMask]);
				SCM(playerid,COLOR_LIME,string);
			}
			else SCM(playerid,COLOR_DARKORANGE,"Невозможно использовать маску!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE,"У Вас нет маски!");
	}
	return 1;
}
CMD:repaircar(playerid)
{
	if(PL[playerid])
	{
		if(IsPlayerInAnyVehicle(playerid))
		{
		    if(PI[playerid][pR_Kit] > 0)
		    {
                RepairVehicle(GetPlayerVehicleID(playerid));
                Action(playerid,"использовал(-а) рем. комплект");
                PI[playerid][pR_Kit]--;
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"У Вас нет рем. комплекта! Приобретите его в ближайшем магазине 24/7.");
	    }
	    else SCM(playerid,COLOR_DARKORANGE,"Чтобы использовать рем. комплект необходимо находиться в транспорте!");
	}
	return 1;
}
CMD:untools(playerid)
{
	if(PI[playerid][pFarmID] == FI[f_id])
	{
	    new veh_id = GetPlayerVehicleID(playerid),string[100];
	    if(IsPlayerInRangeOfPoint(playerid,3.0,-1071.0496,-1207.2960,129.2188))
	    {
		    if(veh_id == FI[f_cars][1])
		    {
		        if(v_inventory[veh_id] == 1)
		        {
					FI[f_tools]+=v_i_quantity[veh_id];
					v_inventory[veh_id] = v_i_quantity[veh_id] = 0;
					format(string,sizeof(string),"[J] %s[%d] доставил на склад ящики с инструментами.",GN(playerid),playerid);
					SCM_J(1,COLOR_BLUE,string);
					DestroyVehicleLabel(veh_id);
                    UpdateF_Text();
                    SaveFarmInfo();
		        }
		        else SCM(playerid,COLOR_DARKORANGE,"В машине отсутствуют инструменты!");
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE,"Ошибка! Вы должны находиться около склада инструментов или в машине недостаточно инструментов.");
	}
	return 1;
}
CMD:water(playerid)
{
	if(PI[playerid][pFarmID] == FI[f_id])
	{
	    new veh_id = GetPlayerVehicleID(playerid),string[100];
	    if(IsPlayerInRangeOfPoint(playerid,3.0,-1069.9655,-1177.9172,129.2188))
	    {
		    if(veh_id == FI[f_cars][1])
		    {
		        if(v_inventory[veh_id] == 2)
		        {
					FI[f_water]+=v_i_quantity[veh_id];
					v_inventory[veh_id] = v_i_quantity[veh_id] = 0;
					format(string,sizeof(string),"[J] %s[%d] наполнил водой водонапорную башню.",GN(playerid),playerid);
					SCM_J(1,COLOR_BLUE,string);
					DestroyVehicleLabel(veh_id);
                    UpdateF_Text();
                    SaveFarmInfo();
		        }
		        else SCM(playerid,COLOR_DARKORANGE,"В машине отсутствуют бочки с водой!");
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"!");
	    }
	    else SCM(playerid,COLOR_DARKORANGE,"Ошибка! Вы должны находиться рядом с водонапорной башней!");
	}
	return 1;
}
CMD:z3(playerid)
{
	/*for(new i; i < 500; i++)
	{
		SkillJobAdd(playerid,1);
	}
	new time = gettime(),businessid = PI[playerid][pBusinessID];
	new cur_day = time - (time % 86400);
	new start_day = cur_day - (86400 * 20);
	mysql_format(dbHandle, query, sizeof query, "SELECT FROM_UNIXTIME(time, '%%Y-%%m-%%d') AS date, SUM(money) as total FROM business_profit WHERE bid=%d AND view=1 AND time >= %d AND time < %d GROUP BY time ORDER BY time DESC LIMIT 20", GetBusinessData(businessid, B_SQL_ID), start_day, cur_day);
	mysql_tquery(dbHandle, query, "ShowBusinessProfit", "i", playerid);*/
	paydays = 1;
	PayDay();
	return 1;
}
CMD:z7(playerid)
{
	for(new i; i < 12; i ++) TextDrawShowForPlayer(playerid, vbs2[i]);
	SelectTextDraw(playerid,COLOR_LIME);
	return 1;
}
CMD:check(playerid)
{
	new string[100];
	format(string,100,"J_S: %d, J_S_2: %d, J_S_3: %d, J_S_4: %d, InHouse: %d, exit_x: %f",PI[playerid][pJob_State],PI[playerid][pJob_State_2],PI[playerid][pJob_State_3],PI[playerid][pJob_State_4],PI[playerid][pInHouse],GetHouseData(PI[playerid][pBusinessID],H_EXIT_POS_X));
	SCM(playerid,COLOR_BLUE,string);
	return 1;
}
CMD:asset(playerid)
{
	if(PL[playerid])
	{
		if(PI[playerid][pFarmID] == FI[f_id])
		{
			if(GetPlayerVehicleID(playerid) == FI[f_cars][1])
			{
				SPD(playerid,dialog_asset,2,"{FFA500}Возможные заказы","{FFA500}1.{FFFFFF} Инструменты\n{FFA500}2.{FFFFFF} Вода\n{FFA500}3.{FFFFFF} Саженцы\n{FFA500}4.{FFFFFF} Топливо","Выбрать","Закрыть");
			}
		}
		else SCM(playerid,COLOR_DARKORANGE,"Вам недоступна данная команда!");
	}
	return 1;
}
CMD:s(playerid,params[]) return cmd_shout(playerid,params);
CMD:shout(playerid,params[])
{
	new string[100],msg[150];
	if(PL[playerid])
	{
	    if(!(sscanf(params,"s[100]",string)))
	    {
			format(msg,sizeof(msg),"%s[%d] кричит: %s!",GN(playerid),playerid,string);
	        SCM_I(playerid,msg,-1,20.0);
	    }
	    else SCM(playerid,COLOR_LIME,"Информация: {FFFFFF}/s(hout) [Сообщение]");
	}
	return 1;
}
CMD:w(playerid,params[])
{
	new string[100],msg[150];
	if(PL[playerid])
	{
	    if(!(sscanf(params,"s[100]",string)))
	    {
			format(msg,sizeof(msg),"%s[%d] шепчет: %s",GN(playerid),playerid,string);
	        SCM_I(playerid,msg,-1,2.0);
	    }
	    else SCM(playerid,COLOR_LIME,"Информация: {FFFFFF}/w [Сообщение]");
	}
	return 1;
}
CMD:b(playerid,params[])
{
	new string[100],msg[150];
	if(PL[playerid])
	{
	    if(!(sscanf(params,"s[100]",string)))
	    {
			format(msg,sizeof(msg),"(( %s[%d]: %s ))",GN(playerid),playerid,string);
	        SCM_I(playerid,msg,-1,20.0);
	    }
	    else SCM(playerid,COLOR_LIME,"Информация: {FFFFFF}/b [Сообщение]");
	}
	return 1;
}
CMD:mm(playerid) return cmd_menu(playerid);
CMD:mn(playerid) return cmd_menu(playerid);
CMD:menu(playerid)
{
	ShowMenuDialog(playerid);
	return 1;
}
CMD:me(playerid,params[])
{
	if(PL[playerid])
	{
	    new string[30];
	    if(!(sscanf(params,"s[30]",string)))
	    {
	        Action(playerid,string);
	    }
	    else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /me [действие]");
	}
	return 1;
}
CMD:do(playerid,params[])
{
	if(PL[playerid])
	{
	    new string[30];
	    if(!(sscanf(params,"s[30]",string)))
	    {
	        DoAction(playerid,string);
	    }
	    else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /do [Действие]");
	}
	return 1;
}
CMD:setcarpos(playerid, params[])
{
	if(PL[playerid])
	{
		if(PI[playerid][pAdmin] > 2)
		{
            if(AL[playerid])
            {
                new house_id;
				if(!sscanf(params,"d",house_id))
				{
					if(!(0 <= house_id <= g_house_loaded - 1)) return SendClientMessage(playerid, 0xFF6600FF, "Данного дома не существует на сервере");

					GetPlayerPos(playerid, g_house[house_id][H_CAR_POS_X], g_house[house_id][H_CAR_POS_Y], g_house[house_id][H_CAR_POS_Z]);
					GetPlayerFacingAngle(playerid, g_house[house_id][H_CAR_ANGLE]);

					new fmt_text[144];

					format
					(
						fmt_text, sizeof fmt_text,
						"UPDATE houses SET car_x='%f', car_y='%f', car_z='%f', car_angle='%f' WHERE id=%d",
						GetHouseData(house_id, H_CAR_POS_X),
						GetHouseData(house_id, H_CAR_POS_Y),
						GetHouseData(house_id, H_CAR_POS_Z),
						GetHouseData(house_id, H_CAR_ANGLE),
						GetHouseData(house_id, H_SQL_ID)
					);

					mysql_query(dbHandle, fmt_text);

					format(fmt_text, sizeof fmt_text, "Вы успешно изменили координаты автомоблия у дома {FFA500}№%d", house_id);

					SendClientMessage(playerid, COLOR_LIME, fmt_text);
				}
				else SCM(playerid, COLOR_LIME, "Информация:{FFFFFF} /setcarpos [id дома]");
			}
			else SCM(playerid,COLOR_GREY,IsNotAL);
		}
	}
	return 1;
}
CMD:bank(playerid)
{
	if(PL[playerid]) BankMenu(playerid);
	return 1;
}
CMD:z4(playerid, params[])
{
	if(sscanf(params,"dd",params[0],params[1])) return 1;
	switch(params[1])
	{
		case 0: PlayerTextDrawShow(playerid, ptd_speedometr[playerid][params[0]]);
		case 1:	PlayerTextDrawHide(playerid, ptd_speedometr[playerid][params[0]]);
    }
	return 1;
}
CMD:z5(playerid, params[])
{
	if(sscanf(params,"d",params[0])) return 1;
	new vehicleid = GetPlayerVehicleID(playerid);
	Fuel[vehicleid] = params[0];
	RepairVehicle(GetPlayerVehicleID(playerid));
	return 1;
}
CMD:z6(playerid)
{
	new string[100];
	query[0] = EOS;
	for(new i = 0; i < 12; i ++)
	{
		format(string, sizeof string, "{FFA500}%d. {FFFFFF}%s\t%s\n", i + 1,gun_frac_name[i],g_fraction_gun[PI[playerid][pMember]][i+1] ? ("{33AA33}[Разрешено]") : ("{BC2C2C}[Запрещено]"));
		strcat(query, string);
	}
	SPD(playerid, dialog_lmenu_regun, DIALOG_STYLE_LIST, "{"#cGold"}Оружие организации", query, "Далее", "Назад");
	return 1;
}
CMD:en(playerid)
{
    if(IsPlayerInAnyVehicle(playerid))
    {
	    new vehicleid = GetPlayerVehicleID(playerid);
	    if(Fuel[vehicleid] >= 1)
	    {
			GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
			SetVehicleParamsEx(vehicleid,(Engine[vehicleid])?(false):(true),lights,alarm,doors,bonnet,boot,objective);
			Engine[vehicleid] = (Engine[vehicleid])?(false):(true);
		}
		else GameTextForPlayer(playerid, "~r~no fuel", 4000, 1);
    }
    return 1;
}
CMD:lights(playerid)
{
	if(IsPlayerInAnyVehicle(playerid))
    {
	    new vehicleid = GetPlayerVehicleID(playerid);
    	GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
		SetVehicleParamsEx(vehicleid,engine,(Lights[vehicleid])?(false):(true),alarm,doors,bonnet,boot,objective);
		Lights[vehicleid] = (Lights[vehicleid])?(false):(true);
	}
	return 1;
}
CMD:savefarminfo()
{
    SaveFarmInfo();
	return 1;
}
CMD:givegun(playerid,params[])
{
	if(PL[playerid])
	{
	    if(GetAP(playerid) >= 1)
	    {
	        if(!(sscanf(params,"ddd",params[0],params[1],params[2])))
	        {
				if(IsPlayerConnected(params[0]) && PL[params[0]])
				{
				    if(params[1] > 0 && params[1] < 47)
				    {
						if(params[2] > 0 && params[2] < 1000)
						{
						    GivePlayerWeapon(params[0],params[1],params[2]);
						    new string[200];
						    format(string,sizeof(string),"[A] %s[%d] выдал %s[%d] оружие %d(%d пт.)",GN(playerid),playerid,GN(params[0]),params[0],params[1],params[2]);
							SCM_A(COLOR_GREY,string);
						}
						else SCM(playerid,COLOR_GREY,"Допустимое значение: 1 - 999 патрон.");
				    }
				    else SCM(playerid,COLOR_GREY,"Недопустимое значение!");
				}
				else SCM(playerid,COLOR_GREY,"Игрок не в сети/не авторизован");
	        }
			else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /givegun [ID] [ID оружия] [Патроны]");
	    }
	}
	return 1;
}
CMD:givemoney(playerid,params[])
{
	if(PI[playerid][pAdmin] == 3)
	{
	    if(AL[playerid])
	    {
	        if(!(sscanf(params,"dd",params[0],params[1])))
	        {
	            if(IsPlayerConnected(params[0]))
	            {
	                if(PL[params[0]])
	                {
	                    if(params[1] > 0 && params[1] < 5000000)
	                    {
	                        new string[100];
	                        format(string,sizeof(string),"[A] %s[%d] начислил %s[%d] %d$",GN(playerid),playerid,GN(params[0]),params[0],params[1]);
	                        GiveMoney(params[0],params[1],true);
	                        SCM_A(COLOR_GREY,string);
	                    }
	                    else SCM(playerid,COLOR_GREY,"Возможное количество: 1 - 5.000.000$");
	                }
	                else SCM(playerid,COLOR_GREY,"Игрок не авторизован!");
	            }
	            else SCM(playerid,COLOR_GREY,"Игрок не в сети!");
	        }
	        else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /givemoney [ID] [Кол-во]");
	    }
	}
	return 1;
}
CMD:setint(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
	    if(AL[playerid])
	    {
	        if(!(sscanf(params,"dd",params[0],params[1])))
	        {
	            if(IsPlayerConnected(params[0]))
	            {
	                if(PL[params[0]])
	                {
						SetPlayerInterior(params[0],params[1]);
	                }
	                else SCM(playerid,COLOR_GREY,"Игрок не авторизован!");
	            }
	            else SCM(playerid,COLOR_GREY,"Игрок не в сети!");
	        }
	        else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /set [ID] [Номер]");
	    }
	}
	return 1;
}
CMD:setexitpos(playerid, params[])
{
	if(PI[playerid][pAdmin] < 3) return 1;
	new house_id;
	if(sscanf(params,"d",house_id)) return SCM(playerid, -1, "Используйте:{"#cW"} /setexitpos [id дома]");
	if(!(0 <= house_id <= g_house_loaded - 1)) return SCM(playerid, 0xFF6600FF, "Данного дома не существует на сервере");
	GetPlayerPos(playerid, g_house[house_id][H_EXIT_POS_X], g_house[house_id][H_EXIT_POS_Y], g_house[house_id][H_EXIT_POS_Z]);
	GetPlayerFacingAngle(playerid, g_house[house_id][H_EXIT_ANGLE]);
	new fmt_text[144];
	format
	(
		fmt_text, sizeof fmt_text,
		"UPDATE houses SET exit_x='%f', exit_y='%f', exit_z='%f', exit_angle='%f' WHERE id=%d",
		GetHouseData(house_id, H_EXIT_POS_X),
		GetHouseData(house_id, H_EXIT_POS_Y),
		GetHouseData(house_id, H_EXIT_POS_Z),
		GetHouseData(house_id, H_EXIT_ANGLE),
		GetHouseData(house_id, H_SQL_ID)
	);
	mysql_query(dbHandle,fmt_text, false);
	format(fmt_text, sizeof fmt_text, "Вы успешно изменили координаты выхода у дома {FFA500}№%d", house_id);
	SendClientMessage(playerid, COLOR_LIME, fmt_text);
	return 1;
}
CMD:buybiz(playerid, params[])
{
	if(PI[playerid][pBusinessID] != -1) return SCM(playerid, 0xFF6600FF, "У Вас уже есть бизнес. Чтобы купить другой необходимо продать старый");
	new businessid = GetNearestBusiness(playerid, 4.0);
	if(businessid != -1)
	{
		SetPVarInt(playerid, "b_id", businessid);

		new fmt_str[256];
		format
		(
			fmt_str, sizeof fmt_str,
			"{"#cW"}Название:\t\t\t{"#cGold"}%s\n"\
			"{"#cW"}Стоимость:\t\t\t{"#cGold"}%d$\n"\
			"{"#cW"}Плата за аренду:\t\t{"#cGold"}%d $/день\n\n"\
			"{ADADAD}Вы уверены что хотите купить этот бизнес?",
			GetBusinessData(businessid, B_NAME),
			GetBusinessData(businessid, B_PRICE),
			GetBusinessData(businessid, B_RENT_PRICE)
		);
		SPD(playerid, dialog_biz, DIALOG_STYLE_MSGBOX, "{"#cGold"}Покупка нового бизнеса", fmt_str, "Да", "Нет");
	}
	else SendClientMessage(playerid, 0xFF6600FF, "Вы должны быть рядом с бизнесом, который хотите купить");
	return 1;
}
CMD:sellbiz(playerid)
{
	if(PL[playerid])
	{
	    if(PI[playerid][pBusinessID] > -1)
	    {
			SPD(playerid,dialog_sellbiz,DIALOG_STYLE_MSGBOX,"{FFA500}Продажа бизнеса государству","{FFFFFF}На данный момент в штате действует налог на продажу бизнеса в размере 15% от гос. цены.\nНа ваш банковский счёт будет переведено: 85%.\n\nВы действительно хотите продать свой бизнес?","Далее","Закрыть");
	    }
	    else SCM(playerid,COLOR_DARKORANGE,"Вы не владелец бизнеса!");
	}
	return 1;
}
CMD:addbiz(playerid, params[])
{
	if(PI[playerid][pAdmin] < 3) return 1;
	new type,price,rent_price;
	if(sscanf(params,"ddd",type, price, rent_price)) return SCM(playerid, COLOR_LIME, "Используйте:{"#cW"} /addbiz [Тип] [Стоимость] [Цена аренды]");
	new fmt_text[300];
	if(!(1 <= type <= 8)) return SCM(playerid, COLOR_WHITE, "Типы бизнесов: 1. 24/7, 2. АЗС, 3. СТО, 4. Автосалон, 5. Магазин одежды, 6. Закусочная, 7. Бар, 8. Спортивный зал.");
	if(price < 1) return SCM(playerid, 0xFF6600FF, "Стоимость бизнеса не может быть меньше 1");
	if(rent_price < 1) return SCM(playerid, 0xFF6600FF, "Стоимость аренды не может быть меньше 1");
	new Cache: result,
		idx = g_business_loaded;
	new name_biz[24];
	switch(type)
	{
	    case 1: name_biz = "Магазин 24/7";
	    case 2: name_biz = "АЗС";
	    case 3: name_biz = "СТО";
	    case 4: name_biz = "Автосалон";
	    case 5: name_biz = "Магазин одежды";
	    case 6: name_biz = "Закусочная";
	    case 7: name_biz = "Бар";
	    case 8: name_biz = "Спортивный зал";
	}
	new int_biz;
	switch(type)
	{
	    case 1: int_biz = 0;
	    case 2: int_biz = 1;
	    case 3: int_biz = 2;
	    case 4: int_biz = 3;
	    case 5: int_biz = 4;
	    case 6: int_biz = 5;
	    case 7: int_biz = 6;
	    case 8: int_biz = 7;
	}
	GetPlayerPos(playerid, g_business[idx][B_POS_X], g_business[idx][B_POS_Y], g_business[idx][B_POS_Z]);
	SetBusinessData(idx, B_PRICE,			price);
	SetBusinessData(idx, B_RENT_PRICE,		rent_price);
	SetBusinessData(idx, B_TYPE,			type);
	SetBusinessData(idx, B_NAME,			name_biz);
	format
	(
		fmt_text, sizeof fmt_text,
		"INSERT INTO business \
		(name, city, zone, type, price, rent_price, x, y, z, interior,prod_price)\
		VALUES ('%s','%d', '%d', '%d', '%d', '%d', '%f', '%f', '%f', '%d','20')",
		name_biz,
		GetBusinessData(idx, B_CITY),
		GetBusinessData(idx, B_ZONE),
		type, price, rent_price,
		GetBusinessData(idx, B_POS_X),
		GetBusinessData(idx, B_POS_Y),
		GetBusinessData(idx, B_POS_Z),
		int_biz

	);
	result = mysql_query(dbHandle, fmt_text, true);
	SetBusinessData(idx, B_SQL_ID, cache_insert_id());
	SetBusinessData(idx, B_INTERIOR, int_biz);
	cache_delete(result);
	g_business_loaded ++;
	switch(type)
	{
		case 1: CreatePickup(19132, 23, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 0, PICKUP_ACTION_TYPE_BIZ_ENTER, idx);
		case 2:
			{
				CreatePickup(1650, 23, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 0, PICKUP_ACTION_TYPE_BIZ_ENTER, idx);
				CreateDynamicMapIcon(GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 56, 0, 0, 0, -1, STREAMER_MAP_ICON_SD, MAPICON_LOCAL);
			}
		case 4:
			{
				CreatePickup(19134, 23, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 0, PICKUP_ACTION_TYPE_BIZ_ENTER, idx);
				CreateDynamicMapIcon(GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 55, 0, 0, 0, -1, STREAMER_MAP_ICON_SD, MAPICON_LOCAL);
			}
	}
    SetBusinessData(idx, B_LABEL, CreateDynamic3DTextLabel(GetBusinessData(idx, B_NAME), 0xFFFF00FF, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z) + 1.0, 6.50));
	UpdateBusinessLabel(idx);
	format(fmt_text, sizeof fmt_text, "[A] %s [%d] создал бизнес №%d", GN(playerid), playerid,idx);
	SCM_A(COLOR_GREY,fmt_text);
	SCM(playerid, COLOR_WHITE, "{"#cGold"}Используйте: {"#cW"}/bsetexitpos, чтобы завершить создание бизнеса");
	return 1;
}
CMD:bsetexitpos(playerid, params[])
{
	if(PI[playerid][pAdmin] < 3) return 1;
	new biz_id;
	if(sscanf(params,"d",biz_id)) return SCM(playerid, COLOR_LIME, "Используйте:{"#cW"} /bsetexitpos [ID бизнеса]");
	if(!(0 <= biz_id <= g_business_loaded - 1)) return SendClientMessage(playerid, 0xFF6600FF, "Данного бизнеса не существует на сервере");
	GetPlayerPos(playerid, g_business[biz_id][B_EXIT_POS_X], g_business[biz_id][B_EXIT_POS_Y], g_business[biz_id][B_EXIT_POS_Z]);
	GetPlayerFacingAngle(playerid, g_business[biz_id][B_EXIT_ANGLE]);
	new fmt_text[144];
	format
	(
		fmt_text, sizeof fmt_text,
		"UPDATE business SET exit_x='%f', exit_y='%f', exit_z='%f', exit_angle='%f' WHERE id=%d",
		GetBusinessData(biz_id, B_EXIT_POS_X),
		GetBusinessData(biz_id, B_EXIT_POS_Y),
		GetBusinessData(biz_id, B_EXIT_POS_Z),
		GetBusinessData(biz_id, B_EXIT_ANGLE),
		GetBusinessData(biz_id, B_SQL_ID)
	);
	mysql_tquery(dbHandle, fmt_text);
	format(fmt_text, sizeof fmt_text, "Вы успешно изменили координаты выхода у бизнеса {"#cGold"}№%d", biz_id);
	SCM(playerid, COLOR_LIME, fmt_text);
	return 1;
}
CMD:addhouse(playerid, params[])
{
	if(PI[playerid][pAdmin] < 3) return 1;
	new type,price,rent_price;
	if(sscanf(params,"ddd",type, price, rent_price)) return SCM(playerid, COLOR_LIME, "Информация:{ffffff} /addhouse [Тип] [Стоимость] [Ежедневаня плата]");
	new fmt_text[300];

	if(!(0 <= type <= sizeof g_house_type - 1))
	{
		SendClientMessage(playerid, COLOR_WHITE, "Типы домов:");

		for(new i; i < sizeof g_house_type; i ++)
		{
			format(fmt_text, sizeof fmt_text, "%d. %s", i, GetHouseTypeInfo(i, HT_NAME));

			SendClientMessage(playerid, 0xFF6600FF, fmt_text);
		}

		return 1;
	}
	if(price < 1) return SendClientMessage(playerid, 0xFF6600FF, "Стоимость дома не может быть меньше 1");
	if(rent_price < 1) return SendClientMessage(playerid, 0xFF6600FF, "Стоимость ежедневной платы не может быть меньше 1");
	new Cache: result,
		idx = g_house_loaded;
	GetPlayerPos(playerid, g_house[idx][H_POS_X], g_house[idx][H_POS_Y], g_house[idx][H_POS_Z]);
	SetHouseData(idx, H_PRICE,			price);
	SetHouseData(idx, H_RENT_PRICE,		rent_price);
	SetHouseData(idx, H_TYPE,			type);
	format
	(
		fmt_text, sizeof fmt_text,
		"INSERT INTO houses \
		(city, zone, type, price, rent_price, x, y, z)\
		VALUES ('%d', '%d', '%d', '%d', '%d', '%f', '%f', '%f')",
		0,
		0,
		type, price, rent_price,
		GetHouseData(idx, H_POS_X),
		GetHouseData(idx, H_POS_Y),
		GetHouseData(idx, H_POS_Z)
	);
	result = mysql_query(dbHandle, fmt_text);
	SetHouseData(idx, H_SQL_ID,			cache_insert_id());
	cache_delete(result);
	g_house_loaded ++;
	UpdateHouse(idx);
	format(fmt_text, sizeof fmt_text, "[A] %s [%d] создал дом №%d", GN(playerid), playerid, idx);
	SCM_A(COLOR_GREY,fmt_text);
	SCM(playerid, COLOR_LIME, "Используйте /setexitpos и /setcarpos, чтобы завершить создание дома");

	return 1;
}
CMD:jobleave(playerid)
{
	if(GetInfo(playerid,pJob)) SPD(playerid,dialog_jobleave,DIALOG_STYLE_MSGBOX,"{FFA500}Работа","{FFFFFF}Вы точно хотите уволиться с текущий работы?\n\nНажмите кнопку - {FFA500}'Принять'{ffffff}, чтобы продолжить","Принять","Закрыть");
	else SCM(playerid,COLOR_DARKORANGE,"Вы нигде не работаете!");
}
CMD:a(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
	    if(AL[playerid])
	    {
	        new string[100],msg[100+MAX_PLAYER_NAME+2];
	        if(sscanf(params,"s[100]",string)) return SCM(playerid,COLOR_LIME,"Информация:{ffffff} /a [Текст]");
	        format(msg,sizeof(msg),"[A] %s[%d]: %s",GN(playerid),playerid,string);
	        SCM_A(COLOR_LIME,msg);
	    }
	    else SCM(playerid,COLOR_GREY,IsNotAL);
	}
	return 1;
}
CMD:admins(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
	    if(AL[playerid])
	    {
	        new r_name[30],string[70];
	        SCM(playerid,0x0099FFAA,"Администрация онлайн:");
			foreach(new i : Player)
			{
			    if(!PL[i]) continue;
			    if(!PI[i][pAdmin]) continue;
	    		switch(PI[i][pAdmin])
				{
				    case 1: r_name = "Младший администратор";
					case 2: r_name = "Администратор";
					case 3: r_name = "Главный администратор";
				}
				format(string, sizeof string, "%s[%d] - %s",GN(i),i,r_name);
				SCM(playerid,-1,string);
			}
	    }
	    else SCM(playerid,COLOR_GREY,IsNotAL);
	}
	return 1;
}
CMD:ban(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
	    if(AL[playerid])
	    {
	        if(!(sscanf(params,"dds[30]",params[0],params[1],params[2])))
	        {
  	     		if(IsPlayerConnected(params[0]))
	     		{
			    	if(PL[params[0]])
			    	{
						if(params[1] >= 1 && params[1] <= 30)
						{
						    new string[200],m,y,d,data[20];
						    getdate(y, m, d);
						    format(data,20,"%02d.%02d.%04d",d,m,y);
						    mysql_format(dbHandle, string, sizeof string, "INSERT INTO `blocked` (`name`,`a_name`,`ban_date`,`unban_date`, `ip`,`reason`,`time`) VALUES ('%s','%s','%s','%d','%s','%s','%d')",GN(params[0]),GN(playerid),data,gettime() + params[1]*86400,PI[params[0]][pIP],params[2],params[1]);
						    mysql_tquery(dbHandle, string);
						    format(string, sizeof(string), "Администратор %s заблокировал игрока %s на %d дней. Причина: %s", GN(playerid), GN(params[0]), params[1], params[2]);
                            SendClientMessageToAll(COLOR_RED, string);
  				    		format(string, sizeof string, "[A] %s[%d] забанил %s[%d] на %d дней. Причина: %s",GN(playerid),playerid,GN(params[0]),params[0],params[1],params[2]);
						    SCM_A(COLOR_GREY, string);
							format(string, sizeof string, "Администратор %s[%d] заблокировал ваш аккаунт на %d дней. Причина: %s",GN(playerid),playerid,params[1],params[2]);
							SCM(params[0],COLOR_DARKORANGE, string);
							FixKick(params[0],"",2000);
						}
						else SCM(playerid,COLOR_GREY,"Возможное значение: 1 - 30.");
				    }
			    	else SCM(playerid,COLOR_GREY,"Данный игрок не авторизован!");
		    	}
		    	else SCM(playerid,COLOR_GREY,"Данный игрок не в сети!");
	        }
	        else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /ban [ID] [Срок(дни 1 - 30)] [Причина]");
	    }
	    else SCM(playerid,COLOR_GREY,IsNotAL);
	}
	return 1;
}
CMD:mute(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
	    if(AL[playerid])
	    {
	        if(!(sscanf(params,"dds[30]",params[0],params[1],params[2])))
	        {
  	     		if(IsPlayerConnected(params[0]))
	     		{
			    	if(PL[params[0]])
			    	{
						if(params[1] >= 1 && params[1] <= 300)
						{
						    new string[200];
						    PI[params[0]][pMute] = params[1] * 60;
						    UpdatePlayerDatabaseInt(playerid, "mute", params[1]*60);
						    format(string, sizeof(string), "Администратор %s заблокировал чат игроку %s. Причина: %s", GN(playerid), GN(params[0]), params[2]);
                            SendClientMessageToAll(COLOR_RED, string);
  				    		format(string, sizeof string, "[A] %s[%d] замутил %s[%d] на %d минут. Причина: %s",GN(playerid),playerid,GN(params[0]),params[0],params[1],params[2]);
						    SCM_A(COLOR_GREY, string);
							format(string, sizeof string, "Администратор %s[%d] заблокировал ваш чат на %d минут. Причина: %s",GN(playerid),playerid,params[1],params[2]);
							SCM(params[0],COLOR_DARKORANGE, string);
						}
						else SCM(playerid,COLOR_GREY,"Возможное значение: 1 - 300.");
				    }
			    	else SCM(playerid,COLOR_GREY,"Данный игрок не авторизован!");
		    	}
		    	else SCM(playerid,COLOR_GREY,"Данный игрок не в сети!");
	        }
	        else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /mute [ID] [Время(минуты 1 - 300)] [Причина]");
	    }
	    else SCM(playerid,COLOR_GREY,IsNotAL);
	}
	return 1;
}
CMD:sban(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
	    if(AL[playerid])
	    {
	        if(!(sscanf(params,"dds[30]",params[0],params[1],params[2])))
	        {
  	     		if(IsPlayerConnected(params[0]))
	     		{
			    	if(PL[params[0]])
			    	{
						if(params[1] >= 1 && params[1] <= 30)
						{
						    new string[200],m,y,d,data[20];
						    getdate(y, m, d);
						    format(data,20,"%02d.%02d.%04d",d,m,y);
						    mysql_format(dbHandle, string, sizeof string, "INSERT INTO `blocked` (`name`,`a_name`,`ban_date`,`unban_date`, `ip`,`reason`,`time`) VALUES ('%s','%s','%s','%d','%s','%s','%d')",GN(params[0]),GN(playerid),data,gettime() + params[1]*86400,PI[params[0]][pIP],params[2],params[1]);
						    mysql_tquery(dbHandle, string);
						    format(string, sizeof string, "[A] %s[%d] забанил %s[%d] на %d дней. Причина: %s (/sban)",GN(playerid),playerid,GN(params[0]),params[0],params[1],params[2]);
						    SCM_A(COLOR_GREY, string);
							format(string, sizeof string, "Администратор %s[%d] заблокировал ваш аккаунт на %d дней. Причина: %s",GN(playerid),playerid,params[1],params[2]);
							SCM(params[0],COLOR_DARKORANGE, string);
							FixKick(params[0],"",2000);
						}
						else SCM(playerid,COLOR_GREY,"Возможное значение: 1 - 30.");
				    }
			    	else SCM(playerid,COLOR_GREY,"Данный игрок не авторизован!");
		    	}
		    	else SCM(playerid,COLOR_GREY,"Данный игрок не в сети!");
	        }
	        else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /sban [ID] [Срок(дни 1 - 30)] [Причина]");
	    }
	    else SCM(playerid,COLOR_GREY,IsNotAL);
	}
	return 1;
}
CMD:reg(playerid, params[])
{
	if(PL[playerid])
	{
		if(PI[playerid][pAdmin] > 0)
		{
		    if(AL[playerid])
		    {
		        new name_s[MAX_PLAYER_NAME];
		        if(!sscanf(params,"s[24]",name_s)) LoadRegFail(playerid,name_s);
		        else SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /reg [Ник]");
		    }
		    else SCM(playerid,COLOR_GREY,IsNotAL);
	 	}
	}
	return 1;
}
CMD:goto(playerid,params[])
{
	if(PL[playerid])
	{
		if(PI[playerid][pAdmin] > 0)
		{
		    if(AL[playerid])
		    {
			    if(sscanf(params,"d",params[0])) return SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /goto [ID]");
			    if(params[0] != playerid)
			    {
				    new Float:x,Float:y,Float:z,inter,world,string[100];
				    GetPlayerPos(params[0],x,y,z);
				    inter = GetPlayerInterior(params[0]);
				    world = GetPlayerVirtualWorld(params[0]);
				    SetPlayerPosEx(playerid,x,y,z,world,inter,0);
				    format(string,sizeof(string),"[A] %s[%d] телепортировался к %s[%d]",GN(playerid),playerid,GN(params[0]),params[0]);
				    SCM_A(COLOR_GREY,string);
			    }
			    else SCM(playerid,COLOR_GREY,"Вы указали свой ID!");
		    }
		    else SCM(playerid,COLOR_GREY,IsNotAL);
		}
	}
	return 1;
}
CMD:veh(playerid, params[])
{
	if(PI[playerid][pAdmin] < 1) return 1;
	else if(AL[playerid] == false) return SCM(playerid,COLOR_GREY,IsNotAL);
	else if(GetPlayerInterior(playerid) > 0) return SCM(playerid, COLOR_GREY, "В интерьере нельзя создавать транспорт!");
	else if(sscanf(params, "ddd", params[0], params[1], params[2])) return SCM(playerid, COLOR_LIME, "Информация: {ffffff}/veh [ид машины] [цвет 1] [цвет 2]");
	else if(params[0] > 611 || params[0] < 400) return SCM(playerid, COLOR_GREY, "ID машины не может быть меньше 400 и больше чем 611");
	else if(params[1] > 255 || params[1] < 0) return SCM(playerid, COLOR_GREY, "Номер цвета не может быть меньше 0 и больше 255");
	else if(params[2] > 255 || params[2] < 0) return SCM(playerid, COLOR_GREY, "Номер цвета не может быть меньше 0 и больше 255");
	else if(TotalAdminVehicles > 80) return SCM(playerid, COLOR_GREY, "Лимит админ-машин превышен");
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X,Y,Z);
	X += 1.5;
	new veh_id = 0;
	veh_id = CreateVehicle(params[0], X,Y,Z, 0.0, params[1], params[2], -1);
	Fuel[veh_id] = 50;
	SetVehicleVirtualWorld(veh_id, GetPlayerVirtualWorld(playerid));
	LinkVehicleToInterior(veh_id, GetPlayerInterior(playerid));
	Itter_Add(adm_vehicles, veh_id);
	new string[128];
	format(string, sizeof(string), "[A] %s[%i] создал транспорт: модель [%d], цвет [%d|%d]", GN(playerid), playerid, veh_id, params[1], params[2]);
	SCM_A(COLOR_GREY, string);
	TotalAdminVehicles += 1;
	return 1;
}
CMD:delveh(playerid)
{
    if(PL[playerid] == false) return 1;
	if(PI[playerid][pAdmin] < 1) return SCM(playerid, COLOR_WHITE, "Данная команда не существует, используйте - {D2691E}/menu{FFFFFF}!");
	if(AL[playerid] == false) return SCM(playerid,COLOR_GREY,IsNotAL);
	if(!IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_GREY, "Вы должны находится в транспорте!");
	if(TotalAdminVehicles == 0) return 1;
	new vehh = GetPlayerVehicleID(playerid);
	if(!Itter_Contains(adm_vehicles, vehh)) return SCM(playerid, COLOR_GREY, "Этот автомобиль не создавал администратор");
	if(IsValidVehicle(vehh)) DestroyVehicle(vehh);
    TotalAdminVehicles -= 1;
	SetTimerEx("Itter_OPDCInternal_adm_vehicles", 0, false, "i", vehh);
	new string[128];
    format(string,sizeof(string),"[A] %s[%d] удалил временный транспорт (ID:%d)",GN(playerid),playerid,vehh);
    SCM_A(COLOR_GREY,string);
	return 1;
}
CMD:gethere(playerid,params[])
{
	if(PL[playerid])
	{
		if(PI[playerid][pAdmin] > 0)
		{
		    if(!AL[playerid]) return SCM(playerid,COLOR_GREY,IsNotAL);
 		    if(sscanf(params,"d",params[0])) return SCM(playerid,COLOR_LIME,"Информация:{FFFFFF} /gethere [ID]");
	     	if(IsPlayerConnected(params[0]))
	     	{
			    if(PL[params[0]])
			    {
				    new Float:x,Float:y,Float:z,inter,world,string[100];
				    GetPlayerPos(playerid,x,y,z);
				    inter = GetPlayerInterior(playerid);
				    world = GetPlayerVirtualWorld(playerid);
				    SetPlayerPosEx(params[0],x,y,z,world,inter,0);
				    format(string,sizeof(string),"[A] %s[%d] телепортировал к себе %s[%d]",GN(playerid),playerid,GN(params[0]),params[0]);
				    SCM_A(COLOR_GREY,string);
			    }
			    else SCM(playerid,COLOR_GREY,"Данный игрок не авторизован!");
		    }
		    else SCM(playerid,COLOR_GREY,"Данный игрок не в сети!");
		}
	}
	return 1;
}
CMD:fstats(playerid)
{
	if(!PL[playerid]) return 1;
	new time = gettime();
	if(PI[playerid][pFarmID] > -1)
	{
		new string[50],s_stats[600];
		format(string,sizeof(string),"Кол-во рабочих на ферме: %d/10",farm_worker);
		SCM(playerid,COLOR_BLUE,string);
		format(s_stats,sizeof(s_stats),"{ffffff}Ферма:\t{FFA500}%s{ffffff}\nНомер фермы:\t%d\nВладелец:\t%s\n\n\
		Счет в банке:\t%d$\nОплачено на:\t%d/30 дней\n\nСклад фермы:\nЯблоки:\t%d/2000\nАпельсины:\t%d/2000\nЛён:\t\t%d/1000\nПшеница:\t%d/1000\n\
		Хлопок:\t%d/1000\nКукуруза:\t%d/1000\nПомидоры:\t%d",
		FI[f_name],FI[f_id],FI[f_owner_name],FI[f_bank],GetElapsedTime(FI[f_renttime],time,CONVERT_TIME_TO_DAYS),FI[f_apple],FI[f_orange],FI[f_flax],FI[f_millet],FI[f_cotton],FI[f_corn],FI[f_tomato]);
		SPD(playerid,0,DIALOG_STYLE_MSGBOX,"{FFA500}Статистика фермы",s_stats,"Выбрать","Закрыть");
	}
	else SCM(playerid,COLOR_DARKORANGE,"У вас нет фермы!");
	return 1;
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
	if(!AL[playerid]) return SCM(playerid,COLOR_GREY,IsNotAL);
	if(sscanf(params,"d",params[0])) return SCM(playerid,COLOR_LIME,"Информация: {ffffff}/setspawn [ID]");
	SPD(params[0],dialog_spawn,2,"{FFA500}Место спавна","{FFA500}1.{FFFFFF} Вокзал\n{FFA500}2.{FFFFFF} Место проживания\n{FFA500}3.{FFFFFF} База организации","Выбрать","Отмена");
	new string[100];
	format(string, sizeof string, "Администратор %s[%d] предложил Вам выбрать место спавна",GN(playerid),playerid);
	SCM(params[0],COLOR_BLUE,string);
	return 1;
}
CMD:spawn(playerid,params[])
{
	if(PI[playerid][pAdmin] < 1) return 1;
	if(!AL[playerid]) return SCM(playerid,COLOR_GREY,IsNotAL);
	SPD(playerid,dialog_spawn,2,"{FFA500}Место спавна","{FFA500}1.{FFFFFF} Вокзал\n{FFA500}2.{FFFFFF} Место проживания\n{FFA500}3.{FFFFFF} База организации","Выбрать","Отмена");
	return 1;
}
CMD:skin(playerid,params[])
{
	if(PI[playerid][pAdmin] < 1) return 1;
	if(!AL[playerid]) return SCM(playerid,COLOR_GREY,IsNotAL);
	if(sscanf(params,"d",params[0])) return SCM(playerid,COLOR_LIME,"Информация:{ffffff} /skin [ID: 1-299]");
	if(params[0] < 0 || params[0] > 299) return SCM(playerid,COLOR_WHITE,"ID: от 1 до 299!");
	SetPlayerSkin(playerid,params[0]);
	SetInfo(playerid,pSkin_ID,params[0]);
	return 1;
}
CMD:tp(playerid)
{
	if(PI[playerid][pAdmin] < 1) return 1;
	if(!AL[playerid]) return SCM(playerid,COLOR_GREY,IsNotAL);
	SPD(playerid,dialog_tmenu,2,"{FFA500}Меню телепортов","Завод\nФерма\nМесто появления\nАрмия\nЗаправка","Выбрать","Закрыть");
	return 1;
}
CMD:apanel(playerid)
{
	if(PI[playerid][pAdmin] < 1) return 1;
	if(!AL[playerid]) return SCM(playerid,COLOR_GREY,IsNotAL);
	SPD(playerid,dialog_apanel,2,"{FFA500}Панель администратирования","{FFA500}1.{FFFFFF} Команды\n{FFA500}2.{FFFFFF} Описание систем\n{FFA500}3.{FFFFFF} Список администраторов\n{FFA500}4.{FFFFFF} Список лидеров\n{FFA500}5.{FFFFFF} Действия\n{FFA500}6.{FFFFFF} Расформирование фракции","Выбрать","Закрыть");
	return 1;
}
CMD:buyfarm(playerid)
{
	if(!GetInfo(playerid,pFarmID))
	{
		if(IsPlayerInRangeOfPoint(playerid,10.0,-1059.3983,-1204.2828,129.2188))
		{
		    if(!GetFarmInfo(f_owner_id))
		    {
		        if(GetInfo(playerid,pCash) > GetFarmInfo(f_price))
				{
					PI[playerid][pFarmID] = 0;
					SetFarmInfo(f_owner_id,PI[playerid][pID]);
					SetFarmInfo(f_owner_name,PI[playerid][pName]);
					SetFarmInfo(f_renttime,gettime());
					format(query,200,"UPDATE farm f, users u SET f.f_owner_id = '%d',f.f_owner_name = '%s', f.f_renttime = '%d', u.f_id='%d',u.cash = '%d' WHERE u.id = '%d'",GetFarmInfo(f_owner_id),GN(playerid),gettime(),1,GetInfo(playerid,pCash),PI[playerid][pID]);
					mysql_tquery(dbHandle,query);
					SCM(playerid,COLOR_LIME,"Поздравляем с приобретением фермы!");
				}
				else SCM(playerid,COLOR_DARKORANGE,"У вас недостаточно денег, чтобы купить ферму!");
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"Ферма уже кем-то куплена!");
		}
		else SCM(playerid,COLOR_DARKORANGE,"Чтобы купить ферму - вы должны находиться около фермера!");
	}
	else SCM(playerid,COLOR_DARKORANGE,"У вас уже есть ферма!");
	return 1;
}
CMD:ainvite(playerid)
{
	if(PI[playerid][pAdmin] < 1) return 1;
	new string[100],s_string[150];
	for(new i = 1; i < MAX_FRACTIONS; i++)
	{
	    format(string, sizeof(string), "%i. %s\n", i, Fraction_Name[i]);
    	strcat(s_string, string);
	}
	SPD(playerid, dialog_ainvite, 2, "{FFA500}Организации", s_string, "Выбрать", "Отмена");
	return 1;
}
CMD:stats(playerid) return StatsDialog(playerid, playerid);

CMD:alogin(playerid)
{
	if(PI[playerid][pAdmin])
	{
		if(!AL[playerid])
		{
			new string[128];
			format(string, sizeof(string), "SELECT * FROM `a_users` WHERE `a_name` = '%s'", GN(playerid));
			mysql_tquery(dbHandle, string, "alogin", "is", playerid, GN(playerid));
		}
		else SCM(playerid,COLOR_GREY,"Вы уже авторизовались!");
	}
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
CMD:car(playerid)
{
	new fmt_text[640],
	Cache: result,
	id;

	mysql_format(dbHandle, fmt_text, sizeof fmt_text, "SELECT * FROM ownable_cars WHERE owner_id='%d'", PI[playerid][pID]);
	result = mysql_query(dbHandle, fmt_text, true);
	new rows = cache_num_rows();
	if(!rows) SCM(playerid, COLOR_DARKORANGE, "У Вас нет личного транспорта");
	else
	{
		new model_id,
		car_number[7];
		format(fmt_text, sizeof fmt_text, "{"#cW"}Транспорт\t\t{"#cW"}Номерной знак\t\t{"#cW"}Статус\n");
		for(new i = 0; i < rows; i ++)
		{
	 		cache_get_value_name_int(i, "id",id);
	 		cache_get_value_name_int(i, "model_id",model_id);
			cache_get_value_name(i, "number", car_number);
			format(query, sizeof query, "{FFFFFF}%d. %s\t\t{FFA500}%s\t\t{FFA500}[Выбрать]\n", i + 1, GetVehicleInfo(model_id-400, VI_NAME), car_number);
			strcat(fmt_text, query);
			SetPlayerListitemValue(playerid, i, id);
		}
		ShowPlayerDialog
		(
			playerid, dialog_car, DIALOG_STYLE_TABLIST_HEADERS,
			"{FFA500}Личный транспорт",
			fmt_text,
			"Выбрать", "Закрыть"
		);
	}
	cache_delete(result);
	return 1;
}
CMD:buycar(playerid,params[])
{
	if(PI[playerid][pAdmin])
	{
		if(sscanf(params,"ddd",params[0],params[1],params[2])) return SCM(playerid,COLOR_LIME,"Информация:{ffffff} /buycar [Car ID] [Color 1] [Color 2]");
	 	BuyOwnableCar(playerid,params[0] + 1000,params[1],params[2]);
 	}
	return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if(vehicleid == FI[f_cars][0])
	{
	    if(!ispassenger)
	    {
		    if(PI[playerid][pJob] == 1 && PI[playerid][pJobWork] == 1)
		    {
				if(FI[f_field_stats] < 100)
				{
			        SetInfo(playerid,pCarID_L,vehicleid);
			        NextRouteCPFarm(playerid);
			        SCM(playerid,COLOR_LIME,"На карте отмечено место, где нужно вспахать территорию!");
			        for(new i; i < 10; i++) TextDrawShowForPlayer(playerid,farm_td[i]);
			        for(new i; i < 8; i++) PlayerTextDrawShow(playerid,farm_ptd[playerid][i]);
			        PlayerTextDrawSetString(playerid,farm_ptd[playerid][3],"20$");
		        }
		        else SCM(playerid,COLOR_DARKORANGE,"На данный момент территория вспахана и готова к тому, чтобы начать сажать семена!"),ClearAnimations(playerid, true);
		    }
		    else
			{
				ClearAnimations(playerid, true);
				SCM(playerid,COLOR_DARKORANGE,"Вы не работаете на ферме!");
			}
		}
	}
	if(vehicleid == FI[f_cars][1])
	{
	    if(!ispassenger)
	    {
		    if(PI[playerid][pFarmID] == FI[f_id])
		    {
				SCM(playerid,COLOR_LIME,"Используйте команду - /asset, чтобы заказать рабочие ресуры для фермы.");
		    }
		    else
			{
				ClearAnimations(playerid, true);
				SCM(playerid,COLOR_DARKORANGE,"Вы не владелец фермы!");
			}
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(FI[f_cars][0] == GetInfo(playerid,pCarID_L))
	{
		DisablePlayerRaceCheckpoint(playerid);
		SetInfo(playerid,pCarID_L,INVALID_VEHICLE_ID);
		for(new i; i < 10; i++) TextDrawHideForPlayer(playerid,farm_td[i]);
		for(new i; i < 8; i++) PlayerTextDrawHide(playerid,farm_ptd[playerid][i]);
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	switch(newstate)
	{
		case 1:
	        {
	            for(new i; i < sizeof ptd_speedometr[]; i ++)
				PlayerTextDrawHide(playerid, ptd_speedometr[playerid][i]);
	        }
	    case 2:
	        {
	            for(new i; i < sizeof ptd_speedometr[]; i ++)
				PlayerTextDrawShow(playerid, ptd_speedometr[playerid][i]);
	        }
	}
	return 1;
}
public OnPlayerEnterDynamicArea(playerid, areaid)
{
    for(new i = 0; i <= g_business_loaded; i++)
	{
	    if(!IsPlayerInAnyVehicle(playerid))
	    {
			if(areaid == biz_area[i])
			{
			    TextDrawShowForPlayer(playerid, p_alt[0]);
			}
		}
	}
    return 1;
}
public OnPlayerLeaveDynamicArea(playerid, areaid)
{
	if(areaid == a_factory)
	{
	    if(PI[playerid][pJobWork]) EndJob(playerid,2),SCM(playerid,COLOR_BLUE,"Рабочий день завершен!");
	}
	if(areaid == a_farm)
	{
	    if(PI[playerid][pJobWork]) EndJob(playerid,1),SCM(playerid,COLOR_BLUE,"Рабочий день завершен!");
	}
 	for(new i = 0; i <= g_business_loaded; i++)
	{
		if(areaid == biz_area[i])
		{
		    TextDrawHideForPlayer(playerid, p_alt[0]);
		}
	}
    return 1;
}
public OnPlayerEnterCheckpoint(playerid)
{
    new action_type = GetPlayerCPInfo(playerid, CP_ACTION_TYPE),string[500];
	if(IsPlayerInCheckpoint(playerid))
	{
		switch(action_type)
		{
		    case CP_ACTION_TYPE_TAKE_Z:
		    {
		        if(PI[playerid][pJob] == 2)
		        {
         			format(string,sizeof(string),"{ffcc00}Желтая ткань\n{FFA500}Оранжевая ткань\n{008000}Зелёная ткань\n{DC143C}Красная ткань\n{800080}Фиолетовая ткань\n{FFFFFF}Белая ткань\n{0000ff}Синяя ткань\n{000000}Чёрная ткань\n{0099ff}Голубая ткань\n{D2691E}Коричневая ткань\n{00FFFF}Берёзовая ткань\n{778899}Серая ткань");
					SPD(playerid,dialog_take_tk,2,"{FFA500}Выберите ткань",string,"Выбрать","Закрыть");
		        }
		    }
		    case CP_ACTION_TYPE_PUT_Z:
		    {
		        if(GetInfo(playerid,pJob) == 2)
		        {
		            switch(GetPVarInt(playerid,"number"))
		            {
		                case 0: SetPlayerFacingAngle(playerid,14.4235);
		                case 1..2: SetPlayerFacingAngle(playerid,177.6483);
		            }
		        	ApplyAnimation(playerid, "CARRY", "PUTDWN105", 4.1, 0, 0, 0, 0, 0, 0);
		        	SCM(playerid,COLOR_YELLOW,"Вы положили ткань на конвейер. Пожалуйста, подождите!");
					SCM(playerid,COLOR_YELLOW,"После того, как ткань будет готова - упакуйте её в коробку на столе!");
					DisablePlayerCheckpoint(playerid);
					PI[playerid][pPlayerTimer] = SetTimerEx("d_factory",10_000,false,"i",playerid);
					RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);

		        }
		    }
		    case CP_ACTION_TYPE_GIVE_Z:
		    {
		        ApplyAnimation(playerid, "CARRY", "LIFTUP05", 4.1, false, 0, 0, 0, 0, 0);
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
				ApplyAnimation(playerid, "CARRY", "PUTDWN05", 4.1, 0, 0, 0, 0, 0, 0);
				MysqlUpdateWareHouse("f_factory",PW[factory]);
				StartJob(playerid,2);
			}
			case CP_ACTION_TYPE_MARK:
			{
			    DisablePlayerCheckpoint(playerid);
			    SCM(playerid,COLOR_YELLOW,"Вы достигли места назначения!");
				SCM(playerid,COLOR_BLUE,"Вы положили инструмент на склад.");
				Action(playerid,"положил(-а) инструмент на склад");
				FI[f_tools]++;
				CallLocalFunction("UpdateFarmText","");
			}
			case CP_ACTION_TYPE_MARK_2:
			{
			    DisablePlayerCheckpoint(playerid);
			    SCM(playerid,COLOR_YELLOW,"Вы достигли места назначения!");
			}
			case CP_ACTION_TYPE_PUT_FARM:
			{
			    DisablePlayerCheckpoint(playerid);
			    SCM(playerid,COLOR_LIME,"Вы положили на склад ящик помидор!");
				FI[f_tomato]+=50;
				CallLocalFunction("UpdateFarmText","");
				GiveMoney(playerid,40);
			}
			case CP_TYPE_FARM_NEXT:
		    {
				if(PI[playerid][pJob_State_2] == 2)
				{
				    if(PI[playerid][pJobWork])
				    {
				        new step = PI[playerid][pJob_State];
				        if(g_farm_CP_next[step][Xx] == 0.0) return SetInfo(playerid,pJob_State,0);
						GiveMoney(playerid,25);
						NextRouteCPFarm_Next(playerid);
						ApplyAnimation(playerid, "SWORD", "sword_4", 4.1, 0, 0, 0, 0, 0, 0);
				    }
		        }
		    }
		    case CP_TYPE_FARM_NEXT_2:
		    {
				if(PI[playerid][pJob_State_2] == 6)
				{
				    if(PI[playerid][pJobWork])
				    {
				        new step = PI[playerid][pJob_State];
				        if(g_farm_CP_next[step][Xx] == 0.0) return SetInfo(playerid,pJob_State,0);
						GiveMoney(playerid,25);
						NextRouteCPFarm_Next_2(playerid);
						ApplyAnimation(playerid,"BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 0, 0);
		    		}
		        }
		    }
		    case CP_TYPE_FARM_NEXT_3:
		    {
				if(PI[playerid][pJob_State_2] == 10)
				{
				    if(PI[playerid][pJobWork])
				    {
				        if(PI[playerid][pJob_State_4] == 0) return SCM(playerid,COLOR_DARKORANGE,"У вас закончилась вода! Наполните ведро водой.");
				        new step = PI[playerid][pJob_State];
				        if(g_farm_CP_next[step][Xx] == 0.0) return SetInfo(playerid,pJob_State,0);
						GiveMoney(playerid,25);
						PI[playerid][pJob_State_4]--;
						NextRouteCPFarm_Next_3(playerid);
		    		}
		        }
		    }
		    case CP_TYPE_FARM_NEXT_4:
		    {
				if(PI[playerid][pJob_State_2] == 4)
				{
				    if(PI[playerid][pJobWork])
				    {
				        new step = PI[playerid][pJob_State];
				        if(g_farm_CP_next[step][Xx] == 0.0) return SetInfo(playerid,pJob_State,0);
						GiveMoney(playerid,25);
						NextRouteCPFarm_Next_4(playerid);
				    }
		        }
		    }
		}
	}
	return 1;
}
stock EndJob(playerid,job_id)
{
	switch(job_id)
	{
		case 1:
		    {
		        DisablePlayerRaceCheckpoint(playerid);
				SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
				SetInfo(playerid,pJobWork,0);
				SetPVarInt(playerid,"ID_F",0);
				SetPVarInt(playerid,"time_out",0);
		    }
	    case 2:
	        {
				DisablePlayerCheckpoint(playerid);
				SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
				RemovePlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND);
				DeletePVar(playerid,"number"),DeletePVar(playerid,"job_factory_on");
				SetInfo(playerid,pJobWork,0);
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
    new action_type = GetPlayerRaceCPInfo(playerid, RCP_ACTION_TYPE);
	new vehicleid = GetPlayerVehicleID(playerid);
	if(IsPlayerInRaceCheckpoint(playerid))
	{
		switch(action_type)
		{
		    case CP_TYPE_FARM:
		    {
				if(vehicleid == FI[f_cars][0])
				{
				    if(PI[playerid][pJobWork])
				    {
				        new step = PI[playerid][pJob_State];
				        if(g_farm_CP[step][Xx] == 0.0) return SetInfo(playerid,pJob_State,0);
						GiveMoney(playerid,20);
						FI[f_field_stats] += 2;
						SkillJobAdd(playerid,1);
						if(FI[f_field_stats] > 100) return SCM(playerid,COLOR_BLUE,"На поле уже всё посажено! Ожидайте, когда можно будет собрать урожай"),DisablePlayerRaceCheckpoint(playerid);
						NextRouteCPFarm(playerid);
						
				    }
		        }
		    }
   			case CP_TYPE_FARM_G:
			{
				if(PI[playerid][pJob_State_2] == 3)
				{
				    if(PI[playerid][pJobWork])
				    {
				        new step = PI[playerid][pJob_State];
				        if(g_farm_CP[step][Xx] == 0.0) return SetInfo(playerid,pJob_State,0);
						GiveMoney(playerid,25);
						NextRouteCPFarm_G(playerid);
				    }
		        }
			}
			case RCP_TYPE_MARK_2:
			{
			    DisablePlayerRaceCheckpoint(playerid);
			    SCM(playerid,COLOR_YELLOW,"Вы достигли места назначения!");
			}
		}
	}
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 0;
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
     		case PICKUP_ACTION_TYPE_WORK:
	        {
				if(!PL[playerid]) return 1;
				SPD(playerid,dialog_job,DIALOG_STYLE_MSGBOX,"{FFA500}Работа грузчика","{ffffff}- Добро пожаловать на завод работяга!\n\nВы хотите начать производство деталей?\n\nЗарплата за {FFA500}1{ffffff} готовый продукт = 250$\nТакже существуют дополнительные множители для зарплаты!\nЕсли качество вашей работы будет превышать 70%,\nто вы будете получать дополнительно {FFA500}20${ffffff}\n\nВы хотите начать работу?","Далее","Закрыть");
	        }
	        case PICKUP_ACTION_TYPE_HOUSE: ShowPlayerHouseInfo(playerid, action_id);
	        case PICKUP_ACTION_TYPE_BIZ_ENTER:
	            {
					if(GetPlayerInBiz(playerid) == -1)
					{
						SetPVarInt(playerid, "pickup_biz", action_id);
					}
	            }
	        case PICKUP_ACTION_TYPE_BIZ_EXIT:
	            {
					SetPVarInt(playerid, "pickup_biz_exit", GetPlayerInBiz(playerid));
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
	    // Работы
	    if(IsPlayerInRangeOfPoint(playerid,1.0,-1060.2244,-1206.1318,129.2188)) JobNPC_Dialog(playerid,1);
		if(IsPlayerInRangeOfPoint(playerid,2.0,1414.3397,-20.8316,3001.4951)) JobNPC_Dialog(playerid,2);
		if(IsPlayerInRangeOfPoint(playerid,1.0,-1073.1987,-1203.2684,129.2188))
		{
		    if(PI[playerid][pJob] == 1)
		    {
     			if(PI[playerid][pJobWork])
     			{
     			    if(GetFarmInfo(f_tools) > 0)
		        	{
		        	    if(PI[playerid][pJob_State_2] < 1) {
	 					SPD(playerid,dialog_wh,2,"{FFA500}Инструменты","{FFA500}1.{ffffff} Ведро\n{FFA500}2.{ffffff} Лопата\n{FFA500}3.{ffffff} Грабли\n{FFA500}4.{ffffff} Ящик для сбора урожая","Выбрать","Закрыть");
	 					}
	 					else
	 					{
	 					    if(GetPVarInt(playerid,"time_out") == 0)
	 					    {
		 					    Action(playerid,"положил(-а) на склад инструмент");
								FI[f_tools]++;
								SetInfo(playerid,pJob_State_2,0);
								CallLocalFunction("UpdateFarmText","");
				    			if(GetInfo(playerid,pJob_State_3) == -3)
		 					    {
		 					        SetInfo(playerid,pJob_State_3,0);
		 					        SetInfo(playerid,pJob_State_2,2);
		 					        SCM(playerid,COLOR_LIME,"На карте отмечено место, где можно взять саженцы для посадки.");
		 					        SetPlayerCheckpoint(playerid,-1033.5869,-1182.8491,129.2188,2.0,CP_ACTION_TYPE_MARK_2);
		 					        SetPVarInt(playerid,"time_out",1);
		 					    }
	 					    }
	 					}
	 				}
	 				else SCM(playerid,COLOR_DARKORANGE,"На складе недостаточно инструментов!");
				}
				else SCM(playerid,COLOR_DARKORANGE,"Вы не начали рабочий день!");
			}
		}
		if(IsPlayerInRangeOfPoint(playerid,1.0,-1033.5869,-1182.8491,129.2188))
		{
		    if(PI[playerid][pJob] == 1)
		    {
		        if(PI[playerid][pJobWork])
		        {
		            if(GetInfo(playerid,pJob_State_2) == 2)
		            {
			            if(GetFarmInfo(f_sdl) > 0)
			            {
			                if(GetInfo(playerid,pJob_Anim) < 10)
			                {
			                    if(GetInfo(playerid,pJob_State_3) != -3)
			                    {
				                    DisablePlayerRaceCheckpoint(playerid);
				                	Action(playerid,"взял(-а) со склада ящик саженцев");
				                	SetInfo(playerid,pJob_Anim,10);
				                	SCM(playerid,COLOR_BLUE,"Вы взяли ящик саженцев! Теперь посадите саженцы помидоров на территорию, которую вы вскопали ранее.");
									SCM(playerid,COLOR_YELLOW,"На карте отмечено место!");
									NextRouteCPFarm_Next_2(playerid);
									SetInfo(playerid,pJob_State_2,6);
									SetInfo(playerid,pJob_State_3,1);
									SetPVarInt(playerid,"time_out",0);
								}
								else SCM(playerid,COLOR_DARKORANGE,"Сначала нужно положить инструмент на склад!");
			                }
			                else SCM(playerid,COLOR_DARKORANGE,"Вы уже взяли всё необходимое!");
			            }
						else SCM(playerid,COLOR_DARKORANGE,"На складе недостаточно саженцев!");
					}
					else SCM(playerid,COLOR_DARKORANGE,"Вы ещё не вскопали необходимую территорию!");
		        }
		        else SCM(playerid,COLOR_DARKORANGE,"Вы не начали рабочий день!");
		    }
		}
		if(IsPlayerInRangeOfPoint(playerid,1.0,-1070.0894,-1178.1503,129.2188))
		{
		    if(PI[playerid][pJob_State_2] == 9 || PI[playerid][pJob_State_3] == 10 && PI[playerid][pJob_State_4] == 0)
		    {
		        if(FI[f_water] >= 10)
		        {
	   				NextRouteCPFarm_Next_3(playerid);
					SetInfo(playerid,pJob_State_2,10);
					SetInfo(playerid,pJob_State_4,10);
					Action(playerid,"наполнил(-а) ведро водой");
					SCM(playerid,COLOR_BLUE,"Вы наполнили ведро водой, теперь полейте саженцы.");
					FI[f_water]-=10;
					CallLocalFunction("UpdateFarmText","");
				}
				else SCM(playerid,COLOR_DARKORANGE,"В башне закончилась вода! Обратитесь к начальству.");
			}
		}
		if(GetPlayerInHouse(playerid) != -1) ExitPlayerFromHouse(playerid, 2.0);
		if(IsPlayerInRangeOfPoint(playerid,1.0,1397.7651,-52.3436,3001.4951))
		{
			if(GetPVarInt(playerid,"job_factory_on"))
			{
				ApplyAnimation(playerid, "INT_HOUSE", "WASH_UP", 4.1, 1, 0, 1, 0, 10000, 0);
      			PI[playerid][pPlayerTimer] = SetTimerEx("animation_z",10_000,false,"i",playerid);
      			DeletePVar(playerid,"job_factory_on");
      			RemovePlayerAttachedObject(playerid,A_OBJECT_SLOT_HAND);
      			SetPlayerFacingAngle(playerid,86);
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
				    case 1: SPD(playerid,dialog_work,DIALOG_STYLE_MSGBOX,"{FFA500}Работа заводского","{ffffff}Вы хотите закончить рабочий день?","Закончить","Отмена");
				}
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"Вы не работаете на заводе!");
		}
		if(IsPlayerInRangeOfPoint(playerid,2.0,-1068.0856,-1211.5553,129.7813))
		{
		    if(PI[playerid][pJob] == 1)
		    {
				switch(PI[playerid][pJobWork])
				{
				    case 0: SPD(playerid,dialog_work_start,DIALOG_STYLE_MSGBOX,"{FFA500}Работа фермера","{ffffff}Вы хотите начать рабочий день?","Начать","Закрыть");
				    case 1: SPD(playerid,dialog_work,DIALOG_STYLE_MSGBOX,"{FFA500}Работа фермера","{ffffff}Вы хотите закончить рабочий день?","Закончить","Отмена");
				}
		    }
		    else SCM(playerid,COLOR_DARKORANGE,"Вы не работаете фермером!");
		}
		for(new idx; idx < sizeof g_teleport; idx ++)
		{
		    if(IsPlayerInRangeOfPoint(playerid,1.0,GetTeleportData(idx,T_PICKUP_POS_X),GetTeleportData(idx,T_PICKUP_POS_Y),GetTeleportData(idx,T_PICKUP_POS_Z)))
		    {
		        if(GetPlayerVirtualWorld(playerid) == GetTeleportData(idx,T_PICKUP_VIRTUAL_WORLD))
		        {
					SetPlayerPosEx(playerid,GetTeleportData(idx, T_POS_X),GetTeleportData(idx, T_POS_Y),GetTeleportData(idx, T_POS_Z),GetTeleportData(idx, T_VIRTUAL_WORLD),GetTeleportData(idx, T_INTERIOR),GetTeleportData(idx, T_ANGLE));
					if(GetTeleportData(idx, T_FREEZE)) FreezePlayer(playerid,2000);
				}
			}
		}
		for(new idx; idx < sizeof g_gun_org; idx ++)
		{
		    if(IsPlayerInRangeOfPoint(playerid,1.0,g_gun_org[idx][pos_x],g_gun_org[idx][pos_y],g_gun_org[idx][pos_z]))
			{
			    if(PI[playerid][pMember] == g_gun_org[idx][E_FID])
			    {
					ShowGunMenu(playerid,PI[playerid][pMember]);
				}
				else SCM(playerid,COLOR_DARKORANGE,"Вам недоступна данная функция!");
			}
		}
		for(new i; i < slotgp; i++)
		{
		    if(IsPlayerInRangeOfPoint(playerid,1.0,GP[i][g_pos_x],GP[i][g_pos_y],GP[i][g_pos_z]))
		    {
		        Action(playerid,"поднимает что-то с земли");
		        ApplyAnimation(playerid,"BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 0, 0);
				GivePlayerWeapon(playerid,GP[i][g_type],GP[i][g_patron]);
				GP[i][g_type] = GP[i][g_patron] = 0;
				GP[i][g_pos_x] = GP[i][g_pos_y] = GP[i][g_pos_z] = 0.0;
				DestroyDynamic3DTextLabel(GP[i][gunpick]);
				slotgp--;
		    }
		}
		new biz_id = GetPVarInt(playerid, "pickup_biz"),in_biz = GetPVarInt(playerid, "pickup_biz_exit");
		if(IsPlayerInRangeOfPoint(playerid, 3.0, GetBusinessData(biz_id, B_POS_X), GetBusinessData(biz_id, B_POS_Y), GetBusinessData(biz_id, B_POS_Z)) &&  GetBusinessData(biz_id, B_TYPE) != 2)
		{
			if(IsBusinessOwned(biz_id))
			{
				if(GetBusinessData(biz_id, B_OWNER_ID) != PI[playerid][pID])
				{
					if(GetBusinessData(biz_id, B_LOCK_STATUS))
						return GameTextForPlayer(playerid, "~w~business~n~~r~closed", 4000, 1);
				}
			}
			EnterPlayerToBiz(playerid, biz_id);
		}
		if(IsPlayerInRangeOfPoint(playerid, 3.0, g_business_interiors[0][BT_EXIT_POS_X], g_business_interiors[0][BT_EXIT_POS_Y], g_business_interiors[0][BT_EXIT_POS_Z]))
		{
				SetPlayerPosEx
				(
					playerid,
					GetBusinessData(in_biz, B_EXIT_POS_X),
					GetBusinessData(in_biz, B_EXIT_POS_Y),
					GetBusinessData(in_biz, B_EXIT_POS_Z),
					0,
					0,
					GetBusinessData(in_biz, B_EXIT_ANGLE)
				);
				SetPlayerInBiz(playerid, -1);
		}
		if(PI[playerid][pInBusiness] > -1) IsPlayerInBuyPosBiz(playerid, PI[playerid][pInBusiness], 1);

 	}
	if(PRESSED(KEY_NO))
		cmd_no(playerid);
	if(PRESSED(KEY_YES))
		cmd_yes(playerid);
 	if(newkeys & 1)
 	{
 	    if(IsPlayerInAnyVehicle(playerid))
 	    {
 	        cmd_en(playerid);
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
    SetInfo(playerid, pAFK_Time, 0);
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
            {   
                noclipdata[playerid][mode] = GetMoveDirectionFromKeys(ud, lr);
                MoveCamera(playerid);
            }
        }
        noclipdata[playerid][udold] = ud; noclipdata[playerid][lrold] = lr; // Store current keys pressed for comparison next update
        return 0;
    }
    if(PI[playerid][pJob] == 1 && PI[playerid][pJobWork] == 1) UpdateTextDrawForFarm(playerid);
    UpdateDataSpeedometr(playerid);
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
	        if(strlen(inputtext) > 6)
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
	        else SPD(playerid,dialog_email,DIALOG_STYLE_INPUT,"{FFA500}[2/4]","{ffffff}Для продолжения регистрации, введите адрес элетронной почты в поле ниже.","Далее","Закрыть");
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
			    if(strcmp(GN(playerid),inputtext,true))
			    {
				    if(strlen(inputtext)) SetString(PI[playerid][pReferal],inputtext);
				    PlayerRegistered[playerid][0] = 1,SetClothes(playerid,0);
			    }
			    else SPD(playerid,dialog_referal,DIALOG_STYLE_INPUT,"{FFA500}[4/4]","{ffffff}Введите ник игрока пригласившего вас на сервер","Далее","Пропустить");
		    }
		}
	case dialog_login:
		{
		    if(!response) return SCM(playerid,-1,"Ввод пароля является обязательным условием авторизации!"),Kick(playerid);
		    if(response)
		    {
		        new string[200];
		        format(string,sizeof string,"{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть %d секунд(-ы) на ввод пароля.\n{F08080}- Попыток для ввода пароля: %d",PI[playerid][pPlayerTimer],3-PlayerLogTries[playerid]);
		        for(new i = strlen(inputtext); i != 0; --i)
		    	switch(inputtext[i])
				{
					case 'А'..'Я', 'а'..'я', ' ':
					return SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация",string,"Далее","Выйти");
				}
		        if(!strlen(inputtext)) SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация",string,"Далее","Выйти");
				mysql_format(dbHandle, query, 150, "SELECT * FROM `users` WHERE `name`='%e' AND `password`= MD5('%e')", GN(playerid), inputtext);
				mysql_tquery(dbHandle, query, "LoadPlayerInfo", "ds", playerid, inputtext);
		    }
		}
	case dialog_spawn:
	    {
	        if(response)
			{
	            switch(listitem + 1)
	            {
	                case 1,4:
               			{
							PI[playerid][pSpawnID] = listitem+1;
							SpawnPlayer(playerid);
						}
				}
			}
   	        else
	        {
	            SCM(playerid,COLOR_DARKORANGE,"Вы отменили авторизацию!");
	            Kick(playerid);
	        }
	    }
  	case dialog_errorpass:
   		{
     		if(!response)  SCM(playerid, -1, "Вы отменили авторизацию!"), Kick(playerid);
     		new string[200]; format(string,sizeof string,"{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть %d секунд(-ы) на ввод пароля.\n{F08080}- Попыток для ввода пароля: %d",PI[playerid][pPlayerTimer],3-PlayerLogTries[playerid]);
			SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация",string,"Далее","Выйти");
     	}
  	case dialog_job:
  	    {
  	        if(!response) return DeletePVar(playerid,"job_id");
  	        if(response)
  	        {
  	            new job = GetPVarInt(playerid,"job_id");
  	            switch(job)
  	            {
  	                case 1:
						{
						    PI[playerid][pJob] = job;
						    SCM(playerid,COLOR_BLUE,"Вы устроились на работу фермера!");
						    SCM(playerid,COLOR_BLUE,"[Подсказка] Чтобы начать рабочий день, Вам необходимо переодеться! На карте отмечено место.");
						    SetPlayerCheckpoint(playerid,-1068.0856,-1211.6200,129.7813,2.0,CP_ACTION_TYPE_MARK_2);
						}
  	                case 2:
  	                    {
  	                        PI[playerid][pJob] = job;
  	                        SCM(playerid,COLOR_BLUE,"Вы устроились на работу! Чтобы приступить к работе - вам необходимо переодеться и пройти в цех");
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
  	            switch(PI[playerid][pJob])
  	            {
               		case 1:
  	                    {
  	                        if(farm_worker < MAX_WORKER)
  	                        {
				  	            SCM(playerid,COLOR_BLUE,"Вы начали рабочий день!");
				  	            StartJob(playerid,PI[playerid][pJob]);
								SetInfo(playerid,pJobWork,1);
								SetPlayerSkin(playerid,158);
								farm_worker++;
							}
							else SCM(playerid,COLOR_DARKORANGE,"На складе закончилась одежда! Приходите позже.");
					    }
  	                case 2:
  	                    {
			  	            SCM(playerid,COLOR_BLUE,"Вы начали рабочий день!");
			  	            SCM(playerid,COLOR_BLUE,"Пройдите в цех, затем возьмите материалы и можете приступать к работе!");
			  	            StartJob(playerid,PI[playerid][pJob]);
							SetInfo(playerid,pJobWork,1);
							SetPlayerSkin(playerid,73);
					    }
				}
  	        }
  	    }
 	case dialog_work:
 	    {
 	        if(response)
 	        {
 	            switch(PI[playerid][pJob])
 	            {
 	                case 1: farm_worker--,EndJob(playerid,1);
	 	            case 2: EndJob(playerid,2);
	            }
 	            SCM(playerid,COLOR_BLUE,"Вы закончили рабочий день!");
 	            SetInfo(playerid,pJobWork,0);
 	        }
 	    }
  	case dialog_take_tk:
		{
  			if(response)
  			{
  			    SetInfo(playerid,pJob_State_2,listitem+1);
  			    new string[100];
				SetPlayerFacingAngle(playerid,177.6483);
  			    format(string,sizeof(string),"Вы взяли %s{6495ED}!",ClothColor[listitem]);
				SCM(playerid,COLOR_BLUE,string);
				DisablePlayerCheckpoint(playerid);
				ApplyAnimation(playerid, "CARRY", "LIFTUP05", 4.1, 0, 0, 0, 0, 0, 0);
				switch(random(3))
				{
					case 0: SetPlayerCheckpoint(playerid, 1410.0653,-52.9362,3000.6951, 0.9, CP_ACTION_TYPE_PUT_Z),SetPVarInt(playerid,"number",1);
					case 1: SetPlayerCheckpoint(playerid, 1410.0653,-55.0321,3000.6951, 0.9, CP_ACTION_TYPE_PUT_Z),SetPVarInt(playerid,"number",2);
					case 2: SetPlayerCheckpoint(playerid, 1410.0653,-59.6086,3000.6951, 0.9, CP_ACTION_TYPE_PUT_Z),SetPVarInt(playerid,"number",3);
				}
				switch(listitem)
				{
					case 0: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFCC00,0xFFFFCC00);
					case 1: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFA500,0xFFFFA500);
					case 2: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF008000,0xFF008000);
					case 3: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFDC143C,0xFFDC143C);
					case 4: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF800080,0xFF800080);
					case 5: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFFFFFFF,0xFFFFFFFF);
					case 6: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF0099ff,0xFF0099ff);
					case 7: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF000000,0xFF000000);
					case 8: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF0000FF,0xFF0000FF);
					case 9: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFFD2691E,0xFFD2691E);
					case 10: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF00FFFF,0xFF00FFFF);
					case 11: SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 3017, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45, 0xFF778899,0xFF778899);
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
 	case dialog_npc:
 	    {
 	        if(response)
 	        {
 	            new string[100];
 	            switch(GetPVarInt(playerid,"npc_id"))
 	            {
 	                case 1:
 	                    {
 	                        switch(listitem)
 	                        {
 	                            case 0:
					 				{
					 				    if(PI[playerid][pJob] != 1) JobDialogList(playerid,1);
					 				    else SCM(playerid,COLOR_DARKORANGE,"Вы уже у нас работаете! Используйте команду - /jobleave, чтобы уволиться");
								 	}
								case 1:
								    {
								        if(GetFarmInfo(f_owner_id))
								        {
								        	format(string,sizeof(string),"{ffffff}На данный момент владелец фермы:\n{FFA500}%s",GetFarmInfo(f_owner_name));
											SPD(playerid,0,DIALOG_STYLE_MSGBOX,"{FFA500}Фермер",string,"Хорошо","Закрыть");
										}
										else SCM(playerid,COLOR_DARKORANGE,"На данный момент владельца фермы нету!");
								    }
 	                        }
 	                    }
	 	            case 2:
	 	            {
						switch(listitem)
						{
						    case 0:
								{
								    if(PI[playerid][pJob] != 2) JobDialogList(playerid,2);
								    else SCM(playerid,COLOR_DARKORANGE,"Вы уже у нас работаете! Используйте команду - /jobleave, чтобы уволиться");
								}
						    case 1: SPD(playerid,dialog_npc_next,2,"{FFA500}Вакансии завода","1. Рабочий\n2. Электрик\n3. Менеджер","Выбрать","Закрыть");
						    case 2: JobDialogList(playerid,2);
						}
					}
				}
 	        }
 	    }
 	case dialog_npc_next:
 	    {
 	        if(response)
 	        {
 	            switch(listitem)
 	            {
 	                case 0..2: JobDialogList(playerid,2);
 	            }
 	        }
 	    }
  	case dialog_tmenu:
  	    {
  	        if(response)
  	        {
  	            new Float:X,Float:Y,Float:Z;
  	            switch(listitem)
  	            {
  	                case 0: X = -1837.7695,Y = 115.9587,Z = 15.1172;
  	                case 1: X = -1059.3983,Y = -1204.2828, Z = 129.2188;
  	                case 2: X = -2379.6804,Y = -580.0638,Z = 132.1172;
  	                case 3: X = -1299.6852,Y = 497.6682,Z = 11.1953;
					case 4: X = -1681.2520,Y = 407.9859, Z = 7.1797;
  	            }
    			switch(GetPlayerState(playerid))
				{
					case PLAYER_STATE_ONFOOT: SetPlayerPos(playerid,X,Y,Z);
					case PLAYER_STATE_DRIVER: SetVehiclePos(GetPlayerVehicleID(playerid),X,Y,Z);
				}
  	            SetPlayerVirtualWorld(playerid,0);
  	            SetPlayerInterior(playerid,0);
  	        }
  	    }
  	case dialog_ainvite:
  	    {
  	        if(response)
  	        {
  	            new string[100];
  	            format(string,sizeof(string),"[A] %s[%d] присоединился к \"%s\"",GN(playerid),playerid,Fraction_Name[listitem+1]);
  	            SCM_A(COLOR_GREY,string);
  	            PI[playerid][pMember] =	PI[playerid][pLeader] = listitem+1;
	  			PI[playerid][pRank] = 10;
  	        }
  	    }
	case dialog_jobleave:
	    {
	        if(response)
	        {
				SetInfo(playerid,pJob,0);
				if(PI[playerid][pJobWork]) SetPlayerSkin(playerid,PI[playerid][pSkin_ID]),SetInfo(playerid,pJobWork,0);
				SCM(playerid,COLOR_DARKORANGE,"Вы уволились со своей текущий работы!");
	        }
	    }
	case dialog_wh:
	    {
	        if(response)
	        {
	            switch(listitem+1)
	            {
             		case 1:
	                    {
	                        if(PI[playerid][pJob_State_3] == 2) PI[playerid][pJob_State_2] = 6;
	                        if(PI[playerid][pJob_State_2] == 6)
							{
	                        	SCM(playerid,COLOR_BLUE,"Вы взяли со склада ведро для воды. Теперь наберите в ведро воды, затем полейте посаженые вами саженцы.");
	                        	SCM(playerid,COLOR_YELLOW,"На карте отмечено место.");
                          		SetPlayerCheckpoint(playerid,-1070.0894,-1178.1503,129.2188,2.0,CP_ACTION_TYPE_MARK_2);
                          		SetInfo(playerid,pJob_State_2,9);
           			            Action(playerid,"взял(-а) со склада инструмент");
					            FI[f_tools]--;
					            CallLocalFunction("UpdateFarmText","");
	                        }
	                    }
	                case 2:
	                    {
	                        SCM(playerid,COLOR_BLUE,"Вы взяли со склада лопату. Теперь вскопайте землю в теплицах.");
	                        NextRouteCPFarm_Next(playerid);
	                        SetInfo(playerid,pJob_State_2,2);
            	            Action(playerid,"взял(-а) со склада инструмент");
   							FI[f_tools]--;
	            			CallLocalFunction("UpdateFarmText","");
	            			//SetPlayerAttachedObject(playerid, A_OBJECT_SLOT_HAND, 337, A_OBJECT_BONE_RIGHT_HAND, 0.07, 0.03, 0.04, 90.0, 180.0, 270.0, 0.9, 0.9, 0.45);
	                    }
                 	case 3:
	                    {
	                        if(FI[f_field_stats_3] > 0)
	                        {
	                        	SCM(playerid,COLOR_BLUE,"Вы взяли со склада грабли. Теперь соберите урожай с поля.");
	                        	NextRouteCPFarm_G(playerid);
	                        	SetInfo(playerid,pJob_State_2,3);
            		            Action(playerid,"взял(-а) со склада инструмент");
					            FI[f_tools]--;
					            CallLocalFunction("UpdateFarmText","");
	                        }
	                    }
	                case 4:
	                    {
	                        if(PI[playerid][pJob_State_3] == 4) PI[playerid][pJob_State_2] = 1;
	                        switch(GetPVarInt(playerid,"ID_F"))
	                        {
  								case 0:
								    {
            							SCM(playerid,COLOR_BLUE,"Вы взяли со склада ящик для сбора урожая. Теперь нужно собрать яблоки и апельсины с деревьев.");
                   						SCM(playerid,COLOR_YELLOW,"Место, где нужно собрать урожай - отмечено на карте.");
          								Action(playerid,"взял(-а) со склада инструмент");
		            					FI[f_tools]--;
			            				CallLocalFunction("UpdateFarmText","");
								    }
	                            case 1:
	                                {
				                        if(PI[playerid][pJob_State_2] == 1)
				                        {
				                            SCM(playerid,COLOR_BLUE,"Вы взяли со склада ящик для сбора урожая. Теперь нужно собрать урожай в ящик и унести на склад.");
				                        	NextRouteCPFarm_Next_4(playerid);
				                        	SetInfo(playerid,pJob_State_2,4);
			            		            Action(playerid,"взял(-а) со склада инструмент");
				            				FI[f_tools]--;
				            				CallLocalFunction("UpdateFarmText","");
				                        }
		                            }
	                        }
	                    }
       			}
       		}
	    }
 	case dialog_enter:
		{
				new houseid = GetPlayerUseListitem(playerid);

				if(houseid >= 0 && response)
				{
					if(GetPlayerInHouse(playerid) == -1)
					{
						if(!GetHouseData(houseid, H_LOCK_STATUS) || GetPlayerHouse(playerid, HOUSE_TYPE_HOME) == houseid)
						{
							EnterPlayerToHouse(playerid, houseid);
						}
						else GameTextForPlayer(playerid, "~r~Closed", 3000, 1);
					}
				}
		}
 	case dialog_buy_house:
		{
				new houseid = GetPlayerUseListitem(playerid);

				if(houseid >= 0 && response)
				{
						if(GetPlayerHouse(playerid) == -1)
						{
							if(IsPlayerInRangeOfHouse(playerid, houseid, 5.0))
							{
								if(!IsHouseOwned(houseid))
								{
									if(PI[playerid][pCash] >= GetHouseData(houseid, H_PRICE))
									{
										SendClientMessage(playerid, 0xFFFFFFFF, "Поздравляем! Вы приобрели дом");
										BuyPlayerHouse(playerid, houseid);
										EnterPlayerToHouse(playerid, houseid);
										PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
									}
									else SCM(playerid, 0xCECECEFF, "У Вас недостаточно денег для покупки этого дома");
								}
								else
								{
									new fmt_str[64];
									format(fmt_str, sizeof fmt_str, "Этот дом уже куплен. Владелец: %s", GetHouseData(houseid, H_OWNER_NAME));
									SCM(playerid, 0xCECECEFF, fmt_str);
								}
							}
						}
						else SCM(playerid, 0xCECECEFF, "У Вас уже есть дом. Чтобы купить новый - необходимо продать старый");
				}
		}
	case dialog_biz:
		{
  			if(response)
	    	{
      			new businessid = GetPVarInt(playerid,"b_id");
	        	BuyPlayerBusiness(playerid, businessid);
		    }
		}
	case dialog_sellbiz:
	    {
  			new businessid = PI[playerid][pBusinessID];
			if(businessid != -1)
			{
		        if(response)
		        {
                    if(GetBusinessData(businessid, B_ORDER_ID) != -1)
					{
						SCM(playerid,COLOR_DARKORANGE,"В бизнесе есть действущий контракт на заказ продукции! Отмените его, чтобы продолжить.");
					}
					else SellBusiness(playerid);
		        }
			}
	    }
	case dialog_business:
	    {
			if(response)
			{
				ShowPlayerBusinessDialog(playerid, BIZ_OPERATION_PARAMS);
			}
	    }
	case dialog_business_params:
		{
				if(response)
				{
					ShowPlayerBusinessDialog(playerid, listitem + 1);
				}
				else cmd_business(playerid);
		}
	case dialog_bank:
	    {
	        if(response)
	        {
	            new string[200];
	            switch(listitem)
	            {
	                case 0:
	                    {
							format(string,sizeof(string),"{ffffff}На вашем банковском счету: {FFA500}%d$",PI[playerid][pBank]);
							SPD(playerid,dialog_bank_back,DIALOG_STYLE_MSGBOX,"{FFA500}Банковский счет",string,"Назад","");
	                    }
       				case 1:
	                    {
	                        format(string,sizeof(string),"{ffffff}В поле ниже введите сумму, которую хотите положить на счет в банке.\nНа вашем счету в банке: {FFA500}%d$",PI[playerid][pBank]);
	                        SPD(playerid,dialog_bank_put,DIALOG_STYLE_INPUT,"{FFA500}Банковский счет: пополнение",string,"Далее","Назад");
	                    }
	                case 2:
	                    {
	                        format(string,sizeof(string),"{ffffff}В поле ниже введите сумму, которую хотите снять со счета.\nНа вашем счету в банке: {FFA500}%d$",PI[playerid][pBank]);
	                        SPD(playerid,dialog_bank_take,DIALOG_STYLE_INPUT,"{FFA500}Банковский счет: снятие",string,"Далее","Назад");
	                    }
					case 3: SPD(playerid,dialog_bank_realty,2,"{FFA500}Оплата недвижимости","{FFA500}1.{FFFFFF} Ферма\n{FFA500}2.{FFFFFF} Бизнес\n{FFA500}3.{FFFFFF} Дом/квартира","Выбрать","Назад");
					case 4:
						{
						    if(PI[playerid][pBusinessID] >= 0)
						    {
								SPD(playerid,dialog_bank_biz,2,"{FFA500}Счет бизнеса","{FFA500}1.{FFFFFF} Пополнить счет\n{FFA500}2.{FFFFFF} Снять со счета","Выбрать","Назад");
							}
							else SCM(playerid,COLOR_DARKORANGE,"У Вас нет бизнеса!"),BankMenu(playerid);
						}
	            }
	        }
	    }
	case dialog_bank_back:
	    {
	        if(response)
	        {
	            BankMenu(playerid);
	        }
	    }
	case dialog_bank_put:
	    {
	        if(response)
	        {
	            new bank_money = strval(inputtext),string[100];
	            if(bank_money > 0)
	            {
		            if(bank_money < PI[playerid][pCash])
		            {
						GiveMoney(playerid,-bank_money);
						PI[playerid][pBank]+=bank_money;
						format(string,sizeof(string),"Вы пополнили свой банковский счет на %d$!",bank_money);
						SCM(playerid,COLOR_LIME,string);
		            }
		            else SCM(playerid,COLOR_DARKORANGE,"У вас недостаточно денег, чтобы совершить операцию!");
	            }
	            BankMenu(playerid);
	        }
	        else BankMenu(playerid);
	    }
	case dialog_bank_take:
	    {
	        if(response)
	        {
	            new bank_money = strval(inputtext),string[100];
	            if(bank_money > 0)
	            {
		            if(bank_money <= PI[playerid][pBank])
		            {
						GiveMoney(playerid,bank_money);
						PI[playerid][pBank]-=bank_money;
						format(string,sizeof(string),"Вы сняли с банковсого счета %d$!",bank_money);
						SCM(playerid,COLOR_LIME,string);
		            }
		            else SCM(playerid,COLOR_DARKORANGE,"На банковском счету недостаточно средств, чтобы совершить операцию!");
	            }
	            BankMenu(playerid);
	        }
	        else BankMenu(playerid);
	    }
	case dialog_bank_realty:
	    {
	        if(response)
	        {
	            ShowPlayerDialogOfRealty(playerid,listitem+1);
	        }
	        else BankMenu(playerid);
	    }
	case dialog_bank_biz:
	    {
	        if(response)
	        {
	            new string[300];
	            switch(listitem + 1)
	            {
	                case 1:
	                    {
	                        format(string,sizeof string,"{FFFFFF}Бизнес: {FFA500}%s{FFFFFF}\nТекущий счет бизнеса: {FFA500}%d${FFFFFF}\nВведите сумму денег в поле ниже, которую хотите снять.",GetBusinessData(PI[playerid][pBusinessID],B_NAME),GetBusinessData(PI[playerid][pBusinessID],B_BALANCE));
	                        SPD(playerid,dialog_bank_biz_put,DIALOG_STYLE_INPUT,"{FFA500}Пополнить счет бизнеса",string,"Далее","Назад");
	                    }
                 	case 2:
                 	    {
                 	    }
	            }
	        }
	        else BankMenu(playerid);
	    }
	case dialog_menu:
	    {
	        if(response)
	        {
	            switch(listitem+1)
	            {
					case 1: SPD(playerid,dialog_menu_stats,2,"{FFA500}Персонаж","{FFA500}1.{FFFFFF} Статистика\n{FFA500}2.{FFFFFF} Онлайн статистика\n{FFA500}3.{FFFFFF} Навыки персонажа","Выбрать","Назад");
					case 2: SPD(playerid,0,2,"{FFA500}FAQ","{FFA500}1.{FFFFFF} Чаты","Выбрать","Назад");
					case 3: SPD(playerid,dialog_help_admin,2,"{FFA500}Связь с администрацией","{FFA500}1.{FFFFFF} Вопрос\n{FFA500}2.{FFFFFF} Жалоба","Выбрать","Назад");
	                case 4: SPD(playerid,dialog_menu_cmdhelp,2,"{FFA500}Команды сервера","Общение\nПрочее","Выбрать","Назад");
	            }
	        }
	    }
	case dialog_menu_cmdhelp:
	    {
	        if(response)
	        {
	            switch(listitem)
	            {
					case 0:
					    {
					        if(!PI[playerid][pDialogData][0]) SPD(playerid,dialog_menu_cmdhelp_2,DIALOG_STYLE_MSGBOX,"{FFA500}Правила общения сервера","OOC:\n...\n\nIC:\n...","Далее","Назад");
					        else ShowDialogCMDHelp(playerid,0,0);
					    }
				}
	        }
	        else ShowMenuDialog(playerid);
	    }
	case dialog_menu_cmdhelp_2:
	    {
	        if(response)
	        {
	            PI[playerid][pDialogData][0] = 1;
	            MysqlUpdateUsers("dialog_data",1,PI[playerid][pID]);
                ShowDialogCMDHelp(playerid,0,0);
	        }
			else SPD(playerid,dialog_menu_cmdhelp,2,"{FFA500}Команды сервера","Общение\nПрочее","Выбрать","Назад");
	    }
	case dialog_menu_cmdhelp_3:
	    {
	        if(response) SPD(playerid,dialog_menu_cmdhelp,2,"{FFA500}Команды сервера","Общение\nПрочее","Выбрать","Назад");
	    }
	case dialog_menu_stats:
	    {
	        if(response)
	        {
	            switch(listitem)
	            {
	                case 0: cmd_stats(playerid);
	                case 1:
	                    {
							new string[200];
							mysql_format(dbHandle,string, sizeof string, "SELECT `o_monday`,`o_tuesday`,`o_wednesday`,`o_thursday`,`o_friday`,`o_saturday`,`o_sunday` FROM `users` WHERE `id` = '%d'",PI[playerid][pID]);
							mysql_tquery(dbHandle,string,"SaveOnlineWeek","d",playerid);
							mysql_format(dbHandle,string, sizeof string, "SELECT `o_monday`,`o_tuesday`,`o_wednesday`,`o_thursday`,`o_friday`,`o_saturday`,`o_sunday` FROM `users` WHERE `id` = '%d'",PI[playerid][pID]);
							mysql_tquery(dbHandle,string,"MyOnlineWeek","d",playerid);
	                    }
	            }
	        }
	    }
	case dialog_help_admin:
	    {
	        if(response)
	        {
	            switch(listitem + 1)
	            {
	                case 1: SPD(playerid,dialog_ask,DIALOG_STYLE_INPUT,"{FFA500}Вопрос администрации","{FFFFFF}Если у Вас возникли вопросы по игровому процессу,\nто в поле ниже задайте свой вопрос,\nадминистрация ответит на него в течении 1-5 минут.\nЗадавайте вопрос чётко и понятно!","Далее","Назад");
	                case 2: SPD(playerid,dialog_report,DIALOG_STYLE_INPUT,"{FFa500}Жалоба","{FFFFFF}Если Вы заметили нарушение со стороны игрока,\nто в поле ниже укажите коротко его ID и нарушение.\nАдминистрация Вас оповестит о нарушение и наказание в течении 1-3 минуты.","Далее","Назад");
	            }
	        }
	        else cmd_menu(playerid);
	    }
	case dialog_ask:
	    {
	        if(response)
	        {
	            if(GetPVarInt(playerid,"AFP") < gettime())
	            {
		            new string[100];
		            if(!strlen(inputtext)) return SPD(playerid,dialog_ask,DIALOG_STYLE_INPUT,"{FFA500}Вопрос администрации","{FFFFFF}Если у Вас возникли вопросы по игровому процессу,\nто в поле ниже задайте свой вопрос,\nадминистрация ответит на него в течении 1-5 минут.\nЗадавайте вопрос чётко и понятно!","Далее","Назад");
		            format(string, sizeof string, "[A] Вопрос от %s[%d]: {FFCC00}%s",GN(playerid),playerid,inputtext);
		            SCM_A(COLOR_LIME,string);
		            SCM(playerid,COLOR_LIME,string);
		            PI[playerid][pReportState] = 1;
		            SetPVarInt(playerid, "AFP", gettime() + 60);
	            }
	            else SCM(playerid,COLOR_DARKORANGE,"Пользоваться репортом можно один раз в минуту!");
	        }
	        else SPD(playerid,dialog_help_admin,2,"{FFA500}Связь с администрацией","{FFA500}1.{FFFFFF} Вопрос\n{FFA500}2.{FFFFFF} Жалоба","Выбрать","Назад");
	    }
	case dialog_report:
	    {
	        if(response)
	        {
         		if(GetPVarInt(playerid,"AFP") < gettime())
       			{
		            new string[100];
		            if(!strlen(inputtext)) return SPD(playerid,dialog_report,DIALOG_STYLE_INPUT,"{FFa500}Жалоба","{FFFFFF}Если Вы заметили нарушение со стороны игрока,\nто в поле ниже укажите коротко его ID и нарушение.\nАдминистрация Вас оповестит о нарушение и наказание в течении 1-3 минуты.","Далее","Назад");
		            format(string, sizeof string, "[A] Жалоба от %s[%d]: {FFCC00}%s",GN(playerid),playerid,inputtext);
		            SCM_A(COLOR_LIME,string);
		            SCM(playerid,COLOR_LIME,string);
		            PI[playerid][pReportState] = 1;
		            SetPVarInt(playerid, "AFP", gettime() + 60);
	            }
	            else SCM(playerid,COLOR_DARKORANGE,"Пользоваться репортом можно один раз в минуту!");
	        }
	        else SPD(playerid,dialog_help_admin,2,"{FFA500}Связь с администрацией","{FFA500}1.{FFFFFF} Вопрос\n{FFA500}2.{FFFFFF} Жалоба","Выбрать","Назад");
	    }
	case dialog_dlz:
	    {
	        new a_id = GetPVarInt(playerid,"a_id"),string[100];
	        if(response)
	        {
	            PI[a_id][pRepPositive]++;
	            format(string,sizeof string, "[A] [Отзыв] %s[%d] поставил положительную оценку за ответ",GN(playerid),playerid);
                SCM(a_id,COLOR_BLUE,string);
                SCM(playerid,COLOR_LIME,"Благодарим за ваш отзыв!");
	        }
	        else
			{
				PI[a_id][pRepNegative]++;
				format(string,sizeof string, "[A] [Отзыв] %s[%d] поставил отрицательную оценку за ответ",GN(playerid),playerid);
				SCM(a_id,COLOR_BLUE,string);
				SCM(playerid,COLOR_LIME,"Благодарим за ваш отзыв!");
			}
	    }
	case dialog_asset:
	    {
	        if(response)
	        {
	            switch(listitem)
	            {
	                case 0:
	                    {
	                        new string[500],b_id,Float:distance;
	                        if(GetNearestBusiness(playerid, 2.0) <= -1)
	                        {
	                        	b_id = GetNearestBusiness(playerid, 0.0);
								distance = GetPlayerDistanceFromPoint(playerid, GetBusinessData(b_id, B_POS_X), GetBusinessData(b_id, B_POS_Y), GetBusinessData(b_id, B_POS_Z));
								SetPlayerRaceCheckpoint(playerid,1,GetBusinessData(b_id, B_POS_X),GetBusinessData(b_id, B_POS_Y),GetBusinessData(b_id, B_POS_Z),0,0,0,2.0,RCP_TYPE_MARK_2);
								SCM(playerid,COLOR_GREY,"Чтобы купить инструменты - вам необходимо находиться около магазина 24/7!");
								format(string,100,"До ближайшего бизнеса: %d м. На карте отмечено место.",floatround(distance));
								SCM(playerid,COLOR_BLUE,string);
							}
							else
							{
							    b_id = GetNearestBusiness(playerid, 2.0);
							    format(string,sizeof(string),"{FFFFFF}Номер магазина:\t{FFA500}%d{FFFFFF}\nВладелец:\t%s\nСтоимость инструментов: {FFA500}10$/1 инструмент{FFFFFF}.",b_id,GetBusinessData(b_id, B_OWNER_NAME));
							    SPD(playerid,dialog_asset_buy_tools,DIALOG_STYLE_INPUT,"{FFA500}Заказ инструментов",string,"Далее","Отмена");
							}
	                    }
	            	case 1:
	            	    {
							new string[100],Float:distance;
							if(IsPlayerInRangeOfPoint(playerid,10.0,-1698.7546,-88.5645,3.0959))
							{
							    if(GetPlayerVehicleID(playerid) == FI[f_cars][1])
							    {
									SPD(playerid,dialog_asset_buy_water,DIALOG_STYLE_INPUT,"{FFA500}Заказ воды","{FFFFFF}Вместимость одной бочки: {FFA500}200 литров воды{FFFFFF}.\nОдна бочка стоит: {FFA500}200${FFFFFF}\nМаксимальная вместимость транспорта: {FFA500}3 бочки{FFFFFF}.\n\nСколько хотитите преобрести бочек?","Далее","Закрыть");
							    }
							    else SCM(playerid,COLOR_DARKORANGE,"Вы должны находиться в транспорте, который является имуществом фермы!");
							}
							else
							{
							    distance = GetPlayerDistanceFromPoint(playerid, -1698.7546,-88.5645,3.0959);
								SetPlayerRaceCheckpoint(playerid,1,-1698.7546,-88.5645,3.0959,0,0,0,2.0,RCP_TYPE_MARK_2);
				    			format(string,50,"До порта: %d м.",floatround(distance));
								SCM(playerid,COLOR_BLUE,"Вы должны находиться в порту, чтобы купить бочки с водой! На карте отмечено место.");
								SCM(playerid,COLOR_BLUE,string);
							}
	            	    }
	            }
	        }
	    }
	case dialog_asset_buy_tools:
	    {
	        if(response)
	        {
	            new b_id = GetNearestBusiness(playerid, 2.0),string[100];
	            if(GetBusinessData(b_id, B_PRODS) > strval(inputtext))
	            {
					if(strval(inputtext)*10 < PI[playerid][pCash])
					{
						GiveMoney(playerid,-strval(inputtext)*10,true);
						g_business[b_id][B_PRODS]-=strval(inputtext);
						g_business[b_id][B_BALANCE]+=strval(inputtext)*10;
						format(string,sizeof string,"Вы купили %d инструментов за %d$.",strval(inputtext),strval(inputtext)*10);
						SCM(playerid,COLOR_LIME,string);
						mysql_format(dbHandle,string,sizeof string,"UPDATE business SET products = %d, balance = %d WHERE id = %d",g_business[b_id][B_PRODS],g_business[b_id][B_BALANCE],GetBusinessData(b_id,B_SQL_ID));
						mysql_tquery(dbHandle,string);
						SCM(playerid,COLOR_BLUE,"Инструменты были погружены в багажник транспорта! Теперь доставьте их на склад инструментов фермы.");
						SCM(playerid,COLOR_LIME,"Используйте команду - /untools, чтобы погрузить инструменты на склад.");
						v_i_quantity[FI[f_cars][1]] = strval(inputtext);
						format(string,20,"Инструменты: %d шт.",strval(inputtext));
						v_inventory[FI[f_cars][1]] = 1;
						DestroyVehicleLabel(FI[f_cars][1]);
						CreateVehicleLabel(FI[f_cars][1], string, COLOR_BLUE, 0.0, 0.0, 2.6, 45.0);
					}
					else SCM(playerid,COLOR_DARKORANGE,"У Вас недостаточно денег!");
	            }
	            else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
	        }
	    }
	case dialog_asset_buy_water:
	    {
	        if(response)
	        {
	            if(strval(inputtext) > 0 && strval(inputtext) < 4)
	            {
					if(strval(inputtext)*200 < PI[playerid][pCash])
					{
					    new string[100];
						GiveMoney(playerid,-strval(inputtext)*200,true);
						format(string,sizeof string,"Вы купили %d бочек с водой за %d$.",strval(inputtext),strval(inputtext)*200);
						SCM(playerid,COLOR_LIME,string);
						SCM(playerid,COLOR_BLUE,"Бочки с водой были погружены в багажник транспорта! Теперь доставьте их на ферму.");
						SCM(playerid,COLOR_LIME,"Используйте команду - /water, чтобы заполнить водонапорную башню водой.");
						v_i_quantity[FI[f_cars][1]] = strval(inputtext);
						format(string,20,"Бочки: %d шт.",strval(inputtext));
						v_inventory[FI[f_cars][1]] = 2;
						DestroyVehicleLabel(FI[f_cars][1]);
						CreateVehicleLabel(FI[f_cars][1], string, COLOR_BLUE, 0.0, 0.0, 2.6, 45.0);
					}
					else SCM(playerid,COLOR_DARKORANGE,"У Вас недостаточно денег!");
	            }
	            else SCM(playerid,COLOR_DARKORANGE,"Максимальная вместимость транспорт: 3 бочки.");
	        }
	    }
	case dialog_apanel:
	    {
	        if(response)
	        {
	            switch(listitem+1)
	            {
	                case 1: SPD(playerid,dialog_apanel_cmdhelp,2,"{FFA500}Команды администратирования","Уровень 1\nУровень 2\nУровень 3","Выбрать","Назад");
					case 3:
					    {
					        if(PI[playerid][pAdmin] > 1) mysql_tquery(dbHandle, "SELECT a_name, a_lvl FROM `a_users`", "OnLoadAllAdmins", "d", playerid);
					        else SCM(playerid,COLOR_GREY,"Данная функия доступна со 2 уровня администратирования!");
					    }
	                case 5:
	                    {
	                        SPD(playerid,dialog_apanel_2,2,"{FFA500}Действия","{FFA500}1.{FFFFFF} Изменение времени сервера\n{FFA500}2.{FFFFFF} Изменение погоды сервера\n{FFA500}3.{FFFFFF} Очистиь чат\n{FFA500}4.{FFFFFF} Сохранение DB и рестарт","Выбрать","Назад");
	                    }
	                case 6: SPD(playerid,dialog_apanel_members,2,"{FFA500}Расформирование фракции","{FFA500}1.{FFFFFF} Увольнение всех сотрудников","Выбрать","Назад");
	            }
	        }
	    }
	case dialog_apanel_2:
	    {
	        if(response)
	        {
	            switch(listitem+1)
	            {
	                case 1: SPD(playerid,dialog_retime,DIALOG_STYLE_INPUT,"{FFA500}Время сервера","{FFFFFF}В строчку ниже укажите значение, которое хотите задать.\nФормат возможного численного значения: 0-23.","Далее","Назад");
					case 2: SPD(playerid,dialog_redate,DIALOG_STYLE_INPUT,"{FFA500}Погода сервера","{FFFFFF}В строчку ниже укажите значение, которое хотите задать.\nФормат возможного численного значения: 0-20.","Далее","Назад");
					case 3:
					    {
							new string[60];
							foreach(new i : Player)
							{
							    for(new x; x < 30; x++) SCM(i,-1,"");
							}
							format(string,sizeof string,"[A] %s[%d] очистил чат",GN(playerid),playerid);
							SCM_A(COLOR_GREY,string);
							cmd_apanel(playerid);
					    }
					case 4:
					    {
					        if(PI[playerid][pAdmin] > 2)
					        {
						        new string[100];
						        format(string,sizeof string,"[A] %s[%d] запустил рестарт сервера",GN(playerid),playerid);
						        SCM_A(COLOR_GREY,string);
						        server_gmx=120;
								SendClientMessageToAll(COLOR_YELLOW,"До рестарта сервера осталось 2 минуты.");
					        }
					        else cmd_apanel(playerid);
					    }
	            }
	        }
	    }
	case dialog_apanel_cmdhelp:
	    {
	        if(response)
	        {
	            new str[600];
	            switch(listitem+1)
	            {
	                case 1:
	                    {
              		    	strins(str,"{FFFFFF}/setspawn [ID] - выдать спавн\n",strlen(str));
					     	strins(str,"{FFFFFF}/tp - меню телепортов\n",strlen(str));
					     	strins(str,"{FFFFFF}/apanel - меню администратирования\n",strlen(str));
					     	strins(str,"{FFFFFF}/goto [ID] - телепортироваться к игроку\n",strlen(str));
					     	strins(str,"{FFFFFF}/gethere [ID] - телепортировать к себе игрока\n",strlen(str));
					     	strins(str,"{FFFFFF}/a [Сообщение] - чат администратирования\n",strlen(str));
					     	strins(str,"{FFFFFF}/veh [ID транспорта: 400-611] [Цвет 1] [Цвет 2] - создать транспорт\n",strlen(str));
					     	strins(str,"{FFFFFF}/delveh - меню администратирования\n",strlen(str));
					     	strins(str,"{FFFFFF}/ainvite - временная фракция",strlen(str));
							SPD(playerid,dialog_apanel_cmdhelp_2,DIALOG_STYLE_MSGBOX,"{FFA500}Уровень 1",str,"Назад","");
	                    }
       				case 2:
	                    {
	                        if(PI[playerid][pAdmin] > 1)
	                        {
	              		    	strins(str,"{FFFFFF}/setspawn [ID] - выдать спавн\n",strlen(str));
						     	strins(str,"{FFFFFF}/tp - меню телепортов\n",strlen(str));
								SPD(playerid,dialog_apanel_cmdhelp_2,DIALOG_STYLE_MSGBOX,"{FFA500}Уровень 2",str,"Назад","");
							}
							else cmd_apanel(playerid);
	                    }
       				case 3:
	                    {
	                        if(PI[playerid][pAdmin] > 2)
	                        {
	              		    	strins(str,"{FFFFFF}/addhouse [Тип: 0 - 2] [Стоимость] [Ежедневная плата] - создать дом\n",strlen(str));
	              		    	strins(str,"{FFFFFF}/setexitpos [ID дома] - установить координаты выхода\n",strlen(str));
						     	strins(str,"{FFFFFF}/addbiz [Тип: 1 - 8] [Стоимость] [Ежедневная плата] - создать бизнес\n",strlen(str));
						     	strins(str,"{FFFFFF}/setbexitpos [ID бизнеса] - установить координаты выхода\n",strlen(str));
								SPD(playerid,dialog_apanel_cmdhelp_2,DIALOG_STYLE_MSGBOX,"{FFA500}Уровень 3",str,"Назад","");
							}
							else cmd_apanel(playerid);
	                    }
	            }
	        }
	        else cmd_apanel(playerid);
	    }
	case dialog_apanel_cmdhelp_2:
	    {
	        if(response)
	        {
	            SPD(playerid,dialog_apanel_cmdhelp,2,"{FFA500}Команды администратирования","Уровень 1\nУровень 2\nУровень 3","Выбрать","Назад");
	        }
	    }
	case dialog_retime:
	    {
	        if(response)
	        {
	            new time = strval(inputtext),string[100];
	            if((0 <= time <= 23))
	            {
	                SetWorldTime(time);
	                format(string,sizeof string,"[A] %s[%d] изменил время сервера на %02d:00",GN(playerid),playerid,time);
	                SCM_A(COLOR_GREY,string);
	                format(string,sizeof string,"Вы изменили время на %02d:00",time);
	                SCM(playerid,COLOR_LIME,string);
	            }
	            else SCM(playerid,COLOR_DARKORANGE,"Возможное значение: 0 - 23!");
	            cmd_apanel(playerid);
	        }
	    }
	case dialog_redate:
	    {
	        if(response)
	        {
	            new weather = strval(inputtext),string[100];
	            if((0 <= weather <= 20))
	            {
	                SetWeather(weather);
	                format(string,sizeof string,"[A] %s[%d] изменил погоду сервера на №%d",GN(playerid),playerid,weather);
	                SCM_A(COLOR_GREY,string);
	                format(string,sizeof string,"Вы изменили погоду на №%d",weather);
	                SCM(playerid,COLOR_LIME,string);
	            }
	            else SCM(playerid,COLOR_DARKORANGE,"Возможное значение: 0 - 20!");
	            cmd_apanel(playerid);
	        }
	    }
	case dialog_alladmins:
	    {
	        if(!response) return cmd_apanel(playerid);
	    }
	case dialog_apanel_members:
	    {
	        if(response)
	        {
	            switch(listitem + 1)
	            {
	                case 1:
	                    {
							new str[90], str2[300];
							for(new i = 1; i < MAX_FRACTIONS; i++)
			    			{
   								format(str, sizeof(str), "{FFA500}%i.{FFFFFF} %s\n", i, Fraction_Name[i]);
								strcat(str2, str);
							}
							SPD(playerid, dialog_apanel_reform, 2, "{FFA500}Выберите организацию", str2, "Выбрать", "Назад");
						}
	            }
	        }
	        else cmd_apanel(playerid);
	    }
	case dialog_apanel_reform:
	    {
	        if(response)
	        {
				new mysql_string[200];
				mysql_format(dbHandle,mysql_string, sizeof mysql_string, "UPDATE `users` SET `member_id` = '0', `leader_id` = '0', `rank` = '0' WHERE `member_id` = '%d'",listitem+1);
				mysql_tquery(dbHandle,mysql_string);
				format(mysql_string, sizeof mysql_string, "[A] %s[%d] расформировал фракцию \"%s\"",GN(playerid),playerid,Fraction_Name[listitem+1]);
				SCM_A(COLOR_GREY,mysql_string);
	        }
	        else SPD(playerid,dialog_apanel_members,2,"{FFA500}Расформирование фракции","{FFA500}1.{FFFFFF} Увольнение всех сотрудников","Выбрать","Назад");
	    }
	case dialog_buy:
	    {
	        if(response)
	        {
				new b_id = GetPlayerInBiz(playerid),string[150];
				switch(listitem + 1)
				{
				    case 1:
				        {
				            if(PI[playerid][pCash] >= 50)
				            {
								if(GetBusinessData(b_id, B_PRODS) >= 1)
								{
									GiveMoney(playerid,-50,true);
									AddBusinessData(b_id, B_PRODS, -, 1);
									AddBusinessData(b_id, B_BALANCE, +, 50);
									GivePlayerWeapon(playerid, 43, 10);
									SCM(playerid,COLOR_BLUE,"Вы купили фотоаппарат на 10 кадров за 50$.");
									mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
									mysql_tquery(dbHandle,string);
									mysql_format(dbHandle, query, sizeof query, "INSERT INTO business_profit (bid,uid,uip,time,money,view) VALUES (%d,%d,'%e',%d,%d,%d)", GetBusinessData(b_id, B_SQL_ID), GetPID(playerid), "0.0.0.0", gettime(), 50, IsBusinessOwned(b_id));
									mysql_tquery(dbHandle, query);
								}
								else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
				        }
				    case 2:
				        {
				            if(PI[playerid][pCash] >= 20)
				            {
								if(GetBusinessData(b_id, B_PRODS) >= 1)
								{
									GiveMoney(playerid,-20,true);
									AddBusinessData(b_id, B_PRODS, -, 1);
									AddBusinessData(b_id, B_BALANCE, +, 20);
									GivePlayerWeapon(playerid, WEAPON_FLOWER, 1);
									SCM(playerid,COLOR_BLUE,"Вы купили букет цветов за 20$.");
									mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
									mysql_tquery(dbHandle,string);
								}
								else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
				        }
					case 3:
					    {
         					if(PI[playerid][pCash] >= 150)
				            {
								if(PI[playerid][pR_Kit]+1 < 6)
								{
									if(GetBusinessData(b_id, B_PRODS) >= 1)
									{
										GiveMoney(playerid,-150,true);
										AddBusinessData(b_id, B_PRODS, -, 1);
										AddBusinessData(b_id, B_BALANCE, +, 150);
										PI[playerid][pR_Kit]++;
										SCM(playerid,COLOR_BLUE,"Вы купили ремонтный комплект за 150$.");
										mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
										mysql_tquery(dbHandle,string);
									}
									else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
								}
								else SCM(playerid,COLOR_DARKORANGE,"Недостаточно место!");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
					    }
					case 4:
					    {
    						if(PI[playerid][pCash] >= 530)
				            {
								if(!PI[playerid][pPhone])
								{
									if(GetBusinessData(b_id, B_PRODS) >= 1)
									{
										GiveMoney(playerid,-530,true);
										AddBusinessData(b_id, B_PRODS, -, 1);
										AddBusinessData(b_id, B_BALANCE, +, 530);
										PI[playerid][pPhone] = 1;
										SCM(playerid,COLOR_BLUE,"Вы купили телефон за 530$. Теперь вы можете купить SIM-карту.");
										mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
										mysql_tquery(dbHandle,string);
									}
									else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
								}
								else SCM(playerid,COLOR_DARKORANGE,"У Вас уже есть телефон!");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
					    }
					case 5:
					    {
					        if(PI[playerid][pCash] >= 20)
				            {
								if(PI[playerid][pPhone])
								{
									if(GetBusinessData(b_id, B_PRODS) >= 1)
									{
										GiveMoney(playerid,-20,true);
										AddBusinessData(b_id, B_PRODS, -, 1);
										AddBusinessData(b_id, B_BALANCE, +, 20);
										PI[playerid][pPhoneNumber] = random(1000000);
										format(string,sizeof string,"Вы купили SIM-карту для телефона за 20$. Номер телефона: %d",PI[playerid][pPhoneNumber]);
										SCM(playerid,COLOR_BLUE,string);
										mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
										mysql_tquery(dbHandle,string);
									}
									else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
								}
								else SCM(playerid,COLOR_DARKORANGE,"У Вас нет телефона! Купите его в ближайшем магазине 24/7.");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
					    }
					case 6:
					    {
         					if(PI[playerid][pCash] >= 30)
				            {
								if(PI[playerid][pHealc]+1 < 5)
								{
									if(GetBusinessData(b_id, B_PRODS) >= 1)
									{
										GiveMoney(playerid,-30,true);
										AddBusinessData(b_id, B_PRODS, -, 1);
										AddBusinessData(b_id, B_BALANCE, +, 30);
										PI[playerid][pHealc]++;
										SCM(playerid,COLOR_BLUE,"Вы купили аптечку за 30$. Доступные команды: /healme (перебинтовать раны)");
										mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
										mysql_tquery(dbHandle,string);
									}
									else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
								}
								else SCM(playerid,COLOR_DARKORANGE,"Недостаточно место!");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
					    }
   					case 7:
					    {
         					if(PI[playerid][pCash] >= 15)
				            {
								if(PI[playerid][pMask]+1 < 4)
								{
									if(GetBusinessData(b_id, B_PRODS) >= 1)
									{
										GiveMoney(playerid,-15,true);
										AddBusinessData(b_id, B_PRODS, -, 1);
										AddBusinessData(b_id, B_BALANCE, +, 15);
										PI[playerid][pMask]++;
										SCM(playerid,COLOR_BLUE,"Вы купили маску за 15$. Доступные команды: /mask (надеть маску)");
										mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(b_id, B_PRODS), GetBusinessData(b_id, B_BALANCE),GetBusinessData(b_id, B_SQL_ID));
										mysql_tquery(dbHandle,string);
									}
									else SCM(playerid,COLOR_DARKORANGE,"В бизнесе недостаточно продукции!");
								}
								else SCM(playerid,COLOR_DARKORANGE,"Недостаточно место!");
				            }
				            else SCM(playerid,COLOR_DARKORANGE,"Недостаточно денег!");
					    }
				}
	        }
	    }
    case dialog_makeleader:
        {
            if(response)
            {
                new p_id = GetPVarInt(playerid,"actplayerid"),string[200];
                PI[p_id][pMember] = listitem + 1;
				PI[p_id][pLeader] = listitem + 1;
                PI[p_id][pRank] = 10;
                format(string,sizeof string, "[A] %s[%d] назначил %s[%d] на пост лидера \"%s\"",GN(playerid),playerid,GN(p_id),p_id,Fraction_Name[listitem+1]);
                SCM_A(COLOR_GREY,string);
                format(string, sizeof string, "%s[%d] назначил вас контролировать организацию \"%s\".",GN(playerid),playerid,Fraction_Name[listitem+1]);
                SCM(p_id, COLOR_BLUE, string);
                mysql_format(dbHandle,string, sizeof string, "UPDATE `users` SET leader_id = '%d', member_id = '%d', rank = '%d' WHERE id = '%d'",PI[p_id][pLeader],PI[p_id][pMember],PI[p_id][pRank],PI[p_id][pID]);
                mysql_tquery(dbHandle,string);
                DeletePVar(playerid,"actplayerid");
            }
            else DeletePVar(playerid,"actplayerid");
        }
    case dialog_lmenu:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0:
                        {
                            new fraction_id = PI[playerid][pMember],string[100];
                            query[0] = EOS;
      						for(new i = 0; i < 10; i ++)
							{
								format(string, sizeof string, "{FFA500}%d. {FFFFFF}%s\n", i + 1, g_fraction_rank[fraction_id][i+1]);
								strcat(query, string);
							}

							SPD(playerid, dialog_lmenu_frname, DIALOG_STYLE_LIST, "{"#cGold"}Список рангов", query, "Далее", "Назад");
                        }
       				case 1:
                        {
                            if(PI[playerid][pMember] >= 1 && PI[playerid][pMember] <= 6)
                            {
	                            new fraction_id = PI[playerid][pMember],string[100];
	                            query[0] = EOS;
	      						for(new i = 0; i < 9; i ++)
								{
									format(string, sizeof string, "{FFA500}%d. {FFFFFF}%d$\n", i + 1, g_fraction_pay[fraction_id][i+1]);
									strcat(query, string);
								}

								SPD(playerid, dialog_lmenu_repay, DIALOG_STYLE_LIST, "{"#cGold"}Зарплата сотрудников", query, "Далее", "Назад");
							}
							else cmd_lmenu(playerid),SCM(playerid,COLOR_DARKORANGE,"Для нелегальных организаций данная функция недоступна!");
                        }
					case 2:
					    {
		   					new string[150];
                           	mysql_format(dbHandle, string, sizeof(string), "SELECT member_id, rank,name FROM `users` WHERE member_id='%d'",PI[playerid][pMember]);
				           	mysql_tquery(dbHandle, string, "OnLoadOfflineMember", "d", playerid);
					    }
					case 3:
					    {
					        if(response)
					        {
					            SPD(playerid,dialog_lmenu_order,2,"{FFA500}Список заказов","{FFA500}1.{FFFFFF} Заказать материалы\n{FFA500}2.{FFFFFF} Заказать корпусы оружий","Выбрать","Назад");
					        }
					    }
					case 4:
					    {
							new string[100];
							query[0] = EOS;
							for(new i = 0; i < 12; i ++)
							{
								format(string, sizeof string, "{FFA500}%d. {FFFFFF}%s\t%s\n", i + 1,gun_frac_name[i],g_fraction_gun[PI[playerid][pMember]][i+1] ? ("{33AA33}[Разрешено]") : ("{BC2C2C}[Запрещено]"));
								strcat(query, string);
							}
							SPD(playerid, dialog_lmenu_regun, DIALOG_STYLE_LIST, "{"#cGold"}Оружие организации", query, "Далее", "Назад");
					    }
                }
            }
        }
	case dialog_lmenu_frname:
	    {
	        if(response)
	        {
 				PI[playerid][pInfoF3] = listitem;
				SPD
				(
					playerid, dialog_lmenu_cfname, DIALOG_STYLE_INPUT,
					"{FFA500}Изменение названия должности",
					"{FFFFFF}Введите в окно ниже новое название для выбранной Вами должности",
					"Далее", "Закрыть"
				);
	        }
	        else cmd_lmenu(playerid);
	    }
	case dialog_lmenu_cfname:
	    {
	        if(response)
	        {
 				if(strlen(inputtext) < 3 || strlen(inputtext) > 20)
				{
					SCM(playerid, COLOR_DARKORANGE, "Вы ввели неверные значения");
					SPD
					(
						playerid, dialog_lmenu_cfname, DIALOG_STYLE_INPUT,
						"{FFA500}Изменение названия должности",
						"{FFFFFF}Введите в окно ниже новое название для выбранной Вами должности",
						"Далее", "Закрыть"
					);
					return 1;
				}

				new rank_listitem[10];

				switch(PI[playerid][pInfoF3])
				{
				    case 0: rank_listitem = "rang";
					case 1: rank_listitem = "rang1";
					case 2: rank_listitem = "rang2";
					case 3: rank_listitem = "rang3";
					case 4: rank_listitem = "rang4";
					case 5: rank_listitem = "rang5";
					case 6: rank_listitem = "rang6";
					case 7: rank_listitem = "rang7";
					case 8: rank_listitem = "rang8";
					case 9: rank_listitem = "rang9";
				}

				new fraction_id = PI[playerid][pMember];

				format(g_fraction_rank[fraction_id][PI[playerid][pInfoF3]+1], 20, "%s", inputtext);

				query[0] = EOS;

				mysql_format(dbHandle, query, 300, "UPDATE `fraction_ranks` SET `%s` = '%s' WHERE fracid=%d", rank_listitem, inputtext, fraction_id);
				mysql_tquery(dbHandle, query);

				SCM(playerid, COLOR_LIME, "Вы успешно изменили название должности для Вашей огранизации!");
	        }
		}
	case dialog_lmenu_repay:
 		{
   			if(response)
      		{
				PI[playerid][pInfoF3] = listitem;
				SPD
				(
					playerid, dialog_lmenu_setrepay, DIALOG_STYLE_INPUT,
					"{FFA500}Изменение зарплаты",
					"{FFFFFF}Введите в окно ниже новое количество оплаты сотрудников",
					"Далее", "Закрыть"
				);
  			}
     		else cmd_lmenu(playerid);
    	}
   	case dialog_lmenu_setrepay:
	    {
	        if(response)
	        {
 				if(strval(inputtext) <= 3000 || strval(inputtext) >= 23000)
				{
					SCM(playerid, COLOR_DARKORANGE, "Вы ввели неверные значения");
					SPD
					(
						playerid, dialog_lmenu_setrepay, DIALOG_STYLE_INPUT,
						"{FFA500}Изменение зарплаты",
						"{FFFFFF}Введите в окно ниже новое количество оплаты сотрудников",
						"Далее", "Закрыть"
					);
					return 1;
				}

				new rank_listitem[9];

				switch(PI[playerid][pInfoF3])
				{
				    case 0: rank_listitem = "rang";
					case 1: rank_listitem = "rang1";
					case 2: rank_listitem = "rang2";
					case 3: rank_listitem = "rang3";
					case 4: rank_listitem = "rang4";
					case 5: rank_listitem = "rang5";
					case 6: rank_listitem = "rang6";
					case 7: rank_listitem = "rang7";
					case 8: rank_listitem = "rang8";
				}

				new fraction_id = PI[playerid][pMember];

				g_fraction_pay[fraction_id][PI[playerid][pInfoF3]+1] = strval(inputtext);

				query[0] = EOS;

				mysql_format(dbHandle, query, 300, "UPDATE `fraction_pay` SET `%s` = '%d' WHERE fracid=%d", rank_listitem, strval(inputtext), fraction_id);
				mysql_tquery(dbHandle, query);

				SCM(playerid, COLOR_LIME, "Вы успешно изменили зарплату сотрудников!");
	        }
		}
	case dialog_lmenu_back:
	    {
	        if(!response) return cmd_lmenu(playerid);
	    }
	case dialog_lmenu_order:
	    {
	        if(response)
	        {
	            switch(listitem)
	            {
	                case 0:
	                    {
	                        SPD(playerid,dialog_orders_mats,1,"{FFA500}Заказ материалов","{FFFFFF}Введите в строчку нижу количество материалов,\nкоторое хотите заказать.\n\n\
								Возможное количество: {FFA500}10.000 - 30.000{FFFFFF}\n\
								Цена за 1.000 материалов - {FFA500}5000${FFFFFF}","Далее","Закрыть");
	                    }
					case 1: SPD(playerid,0,2,"{FFA500}Заказ корпуса оружия","{FFA500}1.{FFFFFF} Полуавтоматического пистолета\n\
						{FFA500}2.{FFFFFF} Пистолета-пулета\n\
						{FFA500}3.{FFFFFF} Автоматической винтовки\n\
						{FFA500}4.{FFFFFF} Полуавтоматической винтовки\n\
						{FFa500}5.{FFFFFF} Автоматического дробовика\n\
						{FFA500}6.{FFFFFF} Пуского комплекса","Выбрать","Назад");
	            }
	        }
	        else cmd_lmenu(playerid);
	    }
	case dialog_orders_mats:
	    {
			if(response)
			{
			    if(strval(inputtext) >= 10000 && strval(inputtext) <= 30000)
			    {
			    
			    }
			    else
			    {
       				SPD(playerid,dialog_orders_mats,1,"{FFA500}Заказ материалов","{FFFFFF}Введите в строчку нижу количество материалов,\nкоторое хотите заказать.\n\n\
					Возможное количество: {FFA500}10.000 - 30.000{FFFFFF}\n\
					Цена за 1.000 материалов - {FFA500}5000${FFFFFF}","Далее","Закрыть");
			    }
			}
			else SPD(playerid,dialog_lmenu_order,2,"{FFA500}Список заказов","{FFA500}1.{FFFFFF} Заказать материалы\n{FFA500}2.{FFFFFF} Заказать корпусы оружий","Выбрать","Назад");
	    }
	case dialog_lmenu_regun:
	    {
	        if(response)
	        {
 				new gun_listitem[12], fraction_id = PI[playerid][pMember];

				switch(listitem)
				{
				    case 0: gun_listitem = "9mm";
					case 1: gun_listitem = "9mm_";
					case 2: gun_listitem = "uzi";
					case 3: gun_listitem = "mp5";
					case 4: gun_listitem = "tec9";
					case 5: gun_listitem = "drob";
					case 6: gun_listitem = "obr";
					case 7: gun_listitem = "skr_drob";
					case 8: gun_listitem = "ak";
					case 9: gun_listitem = "m4";
					case 10: gun_listitem = "rifle";
					case 11: gun_listitem = "sn_rifle";
				}
				if(g_fraction_gun[fraction_id][listitem+1] == 1) g_fraction_gun[fraction_id][listitem+1] = 0;
				else g_fraction_gun[fraction_id][listitem+1] = 1;
				query[0] = EOS;
				mysql_format(dbHandle, query, 300, "UPDATE `fraction_gun` SET `%s` = '%d' WHERE fracid=%d", gun_listitem, g_fraction_gun[fraction_id][listitem+1], fraction_id);
				mysql_tquery(dbHandle, query);
				SCM(playerid,COLOR_LIME,"Вы изменили разрешение выбранного оружия!");
				new string[100];
				query[0] = EOS;
				for(new i = 0; i < 12; i ++)
				{
					format(string, sizeof string, "{FFA500}%d. {FFFFFF}%s\t%s\n", i + 1,gun_frac_name[i],g_fraction_gun[PI[playerid][pMember]][i+1] ? ("{33AA33}[Разрешено]") : ("{BC2C2C}[Запрещено]"));
					strcat(query, string);
				}
				SPD(playerid, dialog_lmenu_regun, DIALOG_STYLE_LIST, "{"#cGold"}Оружие организации", query, "Далее", "Назад");
	        }
	        else cmd_lmenu(playerid);
	    }
	case dialog_car:
		{
			if(response)
			{
				new idx = GetPlayerListitemValue(playerid, listitem);
				SetPVarInt(playerid,"checkcar",listitem);
				ShowOwnableCarLoadDialog(playerid, idx, true);
			}
	    }
	case dialog_car_2:
	    {
	    	if(PI[playerid][pHouseID] != -1)
	    	{
				new idx = GetPVarInt(playerid, "ownablecar_id"),
							Cache: result,
							Float:x,
							Float:y,
							Float:z,
				idz = PI[playerid][pID];
				mysql_format(dbHandle, query, sizeof query, "SELECT car_x, car_y, car_z FROM `houses` WHERE owner_id='%d'", idz);
				result = mysql_query(dbHandle, query, true);
				if(cache_num_rows())
				{
					cache_get_value_name_float(0, "car_x",x);
					cache_get_value_name_float(0, "car_y",y);
					cache_get_value_name_float(0, "car_z",z);
				}
				cache_delete(result);
				if(x == 0)
				{
					SCM(playerid,COLOR_DARKORANGE,"Возникла серьезная ошибка в загрузке транспорта!");
					return SCM(playerid,-1,"Обратитесь в тех. раздел или сообщите администрации. Код ошибки:{FFA500} {GeSMT_ERROR_2}");
				}
				switch(listitem + 1)
				{
					case 1:
						{
							foreach(new i : Player) { if(IsPlayerInVehicle(i,GetPlayerOwnableCar(playerid))) return SCM(playerid,COLOR_DARKORANGE,"Транспортное средство занято!"); }
							if(GetPlayerOwnableCar(playerid) != INVALID_VEHICLE_ID)
							{
								if(SaveOwnableCar(GetPlayerOwnableCar(playerid)) != -1)
								UnloadPlayerOwnableCar(playerid);
							}
							if(LoadOwnableCar(playerid,idx,x,y,z) != -1)
							{
							    new string[200];
								PlayerOwnableCarInit(playerid);
	   							format(string,sizeof string,"Транспорт {FFA500}%s[ID:%d]{6495ED} успешно загружен! Транспорт появится около вашего дома.",GetVehicleInfo(GetVehicleModel(GetPlayerOwnableCar(playerid))-400,VI_NAME),GetPlayerOwnableCar(playerid));
								SCM(playerid,COLOR_BLUE, string);
							}
							else SCM(playerid, COLOR_DARKORANGE, "Транспорт не загружен! Обратитесь за помощью к администрации!");
 						}
				}
			}
			else SCM(playerid,COLOR_DARKORANGE,"У Вас нет дома!");
	    }
	case dialog_take_weapon:
	    {
	        if(response)
	        {
				switch(PI[playerid][pMember])
				{
				    case 4:
				        {
				            new string[100];
				            switch(listitem + 1)
				            {
				                case 1:
				                    {
			                     		if(GetPVarInt(playerid, "weapon1") < gettime())
										{
										    format(string,sizeof string, "[R] %s %s[%d] взял со склада дубинку",Fraction_Rank(playerid),GN(playerid),playerid);
										    SCM_T(4,string,0x33CC66FF);
											GivePlayerWeapon(playerid,3,1);
											SetPVarInt(playerid,"weapon1",gettime() + 60);
										}
										else SCM(playerid,COLOR_DARKORANGE,"Данное оружие разрешено брать раз в 1 минуту!");
				                    }
			       				case 2:
				                    {
			                     		if(GetPVarInt(playerid, "weapon2") < gettime())
										{
										    format(string,sizeof string, "[R] %s %s[%d] взял со склада пистолет 9mm",Fraction_Rank(playerid),GN(playerid),playerid);
										    SCM_T(4,string,0x33CC66FF);
											GivePlayerWeapon(playerid,22,40);
											SetPVarInt(playerid,"weapon2",gettime() + 60);
										}
										else SCM(playerid,COLOR_DARKORANGE,"Данное оружие разрешено брать раз в 1 минуту!");
				                    }
			   					case 3:
				                    {
			                     		if(GetPVarInt(playerid, "weapon3") < gettime())
										{
										    if(PI[playerid][pRank] > 2)
										    {
											    format(string,sizeof string, "[R] %s %s[%d] взял со склада Desert Eagle",Fraction_Rank(playerid),GN(playerid),playerid);
											    SCM_T(4,string,0x33CC66FF);
												GivePlayerWeapon(playerid,24,40);
												SetPVarInt(playerid,"weapon3",gettime() + 60);
											}
											else SCM(playerid,COLOR_DARKORANGE,"Данное оружие доступно со звания Сержант!");
										}
										else SCM(playerid,COLOR_DARKORANGE,"Данное оружие разрешено брать раз в 1 минуту!");
				                    }
		   						case 4:
				                    {
			                     		if(GetPVarInt(playerid, "weapon4") < gettime())
										{
		    								format(string,sizeof string, "[R] %s %s[%d] взял со склада АК-47",Fraction_Rank(playerid),GN(playerid),playerid);
										    SCM_T(4,string,0x33CC66FF);
											GivePlayerWeapon(playerid,30,120);
											SetPVarInt(playerid,"weapon4",gettime() + 60);
										}
										else SCM(playerid,COLOR_DARKORANGE,"Данное оружие разрешено брать раз в 1 минуту!");
				                    }
		   						case 5:
				                    {
			                     		if(GetPVarInt(playerid, "weapon5") < gettime())
										{
										    if(PI[playerid][pRank] > 5)
										    {
											    format(string,sizeof string, "[R] %s %s[%d] взял со склада cнайперскую винтовку",Fraction_Rank(playerid),GN(playerid),playerid);
											    SCM_T(4,string,0x33CC66FF);
												GivePlayerWeapon(playerid,34,10);
												SetPVarInt(playerid,"weapon5",gettime() + 60);
											}
											else SCM(playerid,COLOR_DARKORANGE,"Данное оружие доступно со звания Капитан!");
										}
										else SCM(playerid,COLOR_DARKORANGE,"Данное оружие разрешено брать раз в 1 минуту!");
				                    }
  								case 6:
				                    {
			                     		if(GetPVarInt(playerid, "weapon6") < gettime())
										{
		    								format(string,sizeof string, "[R] %s %s[%d] взял со склада бронежилет",Fraction_Rank(playerid),GN(playerid),playerid);
										    SCM_T(4,string,0x33CC66FF);
			                                SetPlayerArmour(playerid,100);
											SetPVarInt(playerid,"weapon6",gettime() + 60);
										}
										else SCM(playerid,COLOR_DARKORANGE,"Данное оружие разрешено брать раз в 1 минуту!");
				                    }
				            }
					}
		        }
	        }
	    }
	case dialog_enter_price:
	    {
	        if(response)
	        {
	            if(strval(inputtext) >= 5 && strval(inputtext) <= 40)
	            {
	                new businessid = PI[playerid][pBusinessID];
	                SetBusinessData(businessid, B_PROD_PRICE, strval(inputtext));
               		mysql_format(dbHandle, query, sizeof query, "UPDATE business SET `prod_price`=%d WHERE `id`=%d LIMIT 1", GetBusinessData(businessid, B_PROD_PRICE), GetBusinessData(businessid, B_SQL_ID));
					mysql_query(dbHandle, query, false);
					UpdateBusinessLabel(businessid);
					SCM(playerid,COLOR_LIME,"Вы успешно изменили цену за товар!");
	            }
				else CallLocalFunction("ShowPlayerBusinessDialog", "ii", playerid, BIZ_OPERATION_ENTER_PRICE_2);
	        }
	    }
	case dialog_fuel:
	    {
	        if(response)
	        {
	            new st_id = GetNearestFuelSt(playerid,5.0), vehicleid = GetPlayerVehicleID(playerid),
					cost_t = GetBusinessData(st_id,B_PROD_PRICE),Float:fuel = strval(inputtext),string[200];
	            if(floatround(fuel) + floatround(Fuel[vehicleid]) < 100)
	            {
	                if(fuel * cost_t <= PI[playerid][pCash])
	                {
						Fuel[vehicleid] = Fuel[vehicleid]+fuel;
						GiveMoney(playerid,-cost_t * floatround(fuel),true);
						SCM(playerid,COLOR_LIME,"Ваш транспорт заправлен!");
						AddBusinessData(st_id, B_PRODS, -, floatround(fuel));
						AddBusinessData(st_id, B_BALANCE, +, floatround(fuel * cost_t));
						mysql_format(dbHandle,string,sizeof string,"UPDATE `business` SET products=%d,balance=%d WHERE id=%d",GetBusinessData(st_id, B_PRODS), GetBusinessData(st_id, B_BALANCE),GetBusinessData(st_id, B_SQL_ID));
						mysql_tquery(dbHandle,string);
						mysql_format(dbHandle, query, sizeof query, "INSERT INTO business_profit (bid,uid,uip,time,money,view) VALUES (%d,%d,'%e',%d,%d,%d)", GetBusinessData(st_id, B_SQL_ID), GetPID(playerid), "0.0.0.0", gettime(), cost_t * floatround(fuel), IsBusinessOwned(st_id));
						mysql_tquery(dbHandle, query);
	                }
	                else SCM(playerid,COLOR_DARKORANGE,"У вас недостаточно денег!");
	            }
	            else SCM(playerid,COLOR_GREY, "В вашем баке не хватает места для такого количества топлива, укажите другое число!"),cmd_fuel(playerid);
	        }
	    }
	case dialog_gun:
	    {
	        if(response)
	        {
	            
	        }
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
		format(string,sizeof(string),"[A] %s[%d] зарегистрировался",GN(playerid),playerid);
		SCM_A(COLOR_GREY,string);
		SCM(playerid,COLOR_BLUE,"Вы успешно зарегистрировались!");
	}
	return 1;
}
function: admAuth(playerid, inputtext[])
{
	new rows, fields,string[100];
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
		UpdatePlayerDatabaseInt(playerid, "a_lvl", PI[playerid][pAdmin]);
		format(string,sizeof(string),"[A] %s[%d] авторизовался",GN(playerid),playerid);
		SCM_A(COLOR_GREY,string);
		SCM(playerid,COLOR_BLUE,"Вы успешно авторизовались!");
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
	switch(GetPlayerState(playerid))
	{
		case PLAYER_STATE_ONFOOT: SetPlayerPos(playerid,fX,fY,fZ);
		case PLAYER_STATE_DRIVER: SetVehiclePos(GetPlayerVehicleID(playerid),fX,fY,fZ);
	}
	return 1;
}
public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}
public OnPlayerClickTextDraw(playerid,Text:clickedid)
{
    if(clickedid==TDEditor_TD[10]) { if(reg_email[playerid] == true && reg_password[playerid] == true) SPD(playerid,dialog_sex,DIALOG_STYLE_MSGBOX,"{ff4500}Пол персонажа","{ffffff}Выберите  пол своего персонажа","Мужчина","Женщина"),UnloadPlayerRegister(playerid); }
    if(clickedid == c_skin[11])
    {
        PI[playerid][pSkin_ID] = ChosenSkin[playerid];
        ChosenSkin[playerid] = SelectCharPlace[playerid] = 0;
        SetClothes(playerid,1);
		CreateToAccount(playerid);
		CancelSelectTextDraw(playerid);
		for(new i; i < 12; i++) TextDrawHideForPlayer(playerid,c_skin[i]);
    }
    if(clickedid == c_skin[9])
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
    }
    if(clickedid == c_skin[10])
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
    }
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
	if(playertextid == login_rp_PTD[playerid][1]) ShowPlayerDialog(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина. \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть 180 секунд на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
	return 1;
}
stock CreateToAccount(playerid)
{
    if(IsTextInvalid(PI[playerid][pPassword])) return SCM(playerid, -1, "В пароле должны быть только латиские буквы и арабские числа!");
    GetPlayerIp(playerid,PI[playerid][pRegIP],16);
    PI[playerid][pDataReg] = gettime();
	mysql_format(dbHandle,query,250,"INSERT INTO `users` (`name`,`password`,`email`,`referal`,`skin_id`,`sex`,`reg_ip`,`data_reg`) VALUES ('%s',MD5('%s'),'%s','%s','%d','%d','%s','%d')",
	GN(playerid),PI[playerid][pPassword],PI[playerid][pEmail],PI[playerid][pReferal],PI[playerid][pSkin_ID],PI[playerid][pSex],PI[playerid][pRegIP],PI[playerid][pDataReg]);
  	mysql_tquery(dbHandle, query);
 	for(new i = 0; i != 10; ++i) SCM(playerid, -1, " ");
  	PL[playerid] = true;
  	PI[playerid][pLVL] = 1;
  	GiveMoney(playerid,500,true);
  	SetPlayerSkin(playerid,PI[playerid][pSkin_ID]);
  	SetPlayerVirtualWorld(playerid, 0);
  	SpawnPlayer(playerid);
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
            SPD(playerid,dialog_login,DIALOG_STYLE_INPUT,"{FFA500}Авторизация","{ffffff}Добро пожаловать в штат {FFA500}Северная Каролина \n\n{ffffff}Введите свой пароль \n{F08080}- У Вас есть 180 секунд на ввод пароля.\n{F08080}- Попыток для ввода пароля: 3","Далее","Выйти");
            PI[playerid][pPlayerTimer] = 180;
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
			PI[playerid][pPlayerTimer] = 180;
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
stock SpeedVehicle(playerid)
{
	new Float:ST[4];
	if(IsPlayerInAnyVehicle(playerid)) GetVehicleVelocity(GetPlayerVehicleID(playerid),ST[0],ST[1],ST[2]);
	else GetPlayerVelocity(playerid,ST[0],ST[1],ST[2]);
	ST[3] = floatsqroot(floatpower(floatabs(ST[0]), 2.0) + floatpower(floatabs(ST[1]), 2.0) + floatpower(floatabs(ST[2]), 2.0)) * 143.3;
	return floatround(ST[3]);
}
stock GetVehicleHealthAC(playerid)
{
	new Float:ST[2];
	if(IsPlayerInAnyVehicle(playerid)) GetVehicleHealth(GetPlayerVehicleID(playerid),ST[0]);
	ST[1] = floatsqroot(floatpower(floatabs(ST[0]), 2.0) * 143.3);
	return floatround(ST[1]);
}
stock UpdateDataSpeedometr(playerid)
{
	new string[100],vehicleid = GetPlayerVehicleID(playerid),Float:v_health,status = GetVehicleParam(vehicleid, V_LOCK);
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
	    GetVehicleHealth(vehicleid,v_health);
		format(string,20,"%d_km/h",SpeedVehicle(playerid));
	    PlayerTextDrawSetString(playerid,ptd_speedometr[playerid][10],string);
	    format(string,20,":_%d%",floatround(v_health/10));
	    PlayerTextDrawSetString(playerid,ptd_speedometr[playerid][7],string);
	    format(string,20,":_%d%",floatround(Fuel[vehicleid]));
	    PlayerTextDrawSetString(playerid,ptd_speedometr[playerid][6],string);
	    if(status)
	    {
     		PlayerTextDrawBoxColor(playerid,ptd_speedometr[playerid][38],-16776961);
        	PlayerTextDrawShow(playerid,ptd_speedometr[playerid][38]);
	    }
	    else
	    {
   			PlayerTextDrawBoxColor(playerid,ptd_speedometr[playerid][38],16711935);
        	PlayerTextDrawShow(playerid,ptd_speedometr[playerid][38]);
	    }
	    if(Engine[vehicleid])
	    {
	        PlayerTextDrawBoxColor(playerid,ptd_speedometr[playerid][39],16711935);
        	PlayerTextDrawShow(playerid,ptd_speedometr[playerid][39]);
  	    }
	    else
	    {
	        PlayerTextDrawBoxColor(playerid,ptd_speedometr[playerid][39],-16776961);
			PlayerTextDrawShow(playerid,ptd_speedometr[playerid][39]);
	    }
	}
}
stock LoadPlayerTD(playerid)
{
    ptd_speedometr[playerid][0] = CreatePlayerTextDraw(playerid, 483.199768, 357.253143, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][0], 0.000000, 4.200003);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][0], 631.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][0], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][0], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][0], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][0], 90);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][0], 90);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][0], 0);

	ptd_speedometr[playerid][1] = CreatePlayerTextDraw(playerid, 485.800170, 360.582275, "");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][1], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][1], 13.000000, 15.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][1], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][1], 0);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][1], 5);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][1], 0);
	PlayerTextDrawSetPreviewModel(playerid, ptd_speedometr[playerid][1], 1650);
	PlayerTextDrawSetPreviewRot(playerid, ptd_speedometr[playerid][1], 0.000000, 0.000000, 15.000000, 1.000000);

	ptd_speedometr[playerid][2] = CreatePlayerTextDraw(playerid, 487.399963, 379.497680, "");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][2], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][2], 10.000000, 13.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][2], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][2], -1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][2], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][2], 0);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][2], 5);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][2], 0);
	PlayerTextDrawSetPreviewModel(playerid, ptd_speedometr[playerid][2], 1240);
	PlayerTextDrawSetPreviewRot(playerid, ptd_speedometr[playerid][2], 0.000000, 0.000000, 0.000000, 1.000000);

	ptd_speedometr[playerid][3] = CreatePlayerTextDraw(playerid, 539.800292, 381.488922, "");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][3], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][3], 12.000000, 12.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][3], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][3], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][3], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][3], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][3], 0);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][3], 5);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][3], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][3], 0);
	PlayerTextDrawSetPreviewModel(playerid, ptd_speedometr[playerid][3], 19804);
	PlayerTextDrawSetPreviewRot(playerid, ptd_speedometr[playerid][3], 0.000000, 0.000000, 0.000000, 1.000000);

	ptd_speedometr[playerid][4] = CreatePlayerTextDraw(playerid, 483.400146, 355.106475, "LD_SPAC:white");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][4], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][4], -3.000000, 42.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][4], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][4], -5963521);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][4], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][4], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][4], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][4], 4);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][4], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][4], 0);

	ptd_speedometr[playerid][5] = CreatePlayerTextDraw(playerid, 635.000244, 355.106597, "LD_SPAC:white");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][5], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][5], -3.000000, 42.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][5], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][5], -5963521);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][5], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][5], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][5], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][5], 4);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][5], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][5], 0);

	ptd_speedometr[playerid][6] = CreatePlayerTextDraw(playerid, 497.999969, 362.231170, ":_100");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][6], 0.125598, 1.196799);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][6], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][6], -1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][6], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][6], 1);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][6], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][6], 2);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][6], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][6], 0);

	ptd_speedometr[playerid][7] = CreatePlayerTextDraw(playerid, 497.600097, 379.653289, ":_100%");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][7], 0.123998, 1.137066);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][7], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][7], -1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][7], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][7], 1);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][7], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][7], 2);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][7], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][7], 0);

	ptd_speedometr[playerid][8] = CreatePlayerTextDraw(playerid, 516.600219, 373.524414, "");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][8], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][8], 24.000000, 28.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][8], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][8], -16776961);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][8], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][8], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][8], 0);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][8], 5);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][8], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][8], 0);
	PlayerTextDrawSetPreviewModel(playerid, ptd_speedometr[playerid][8], 11746);
	PlayerTextDrawSetPreviewRot(playerid, ptd_speedometr[playerid][8], 360.000000, 0.000000, 0.000000, 1.000000);

	ptd_speedometr[playerid][9] = CreatePlayerTextDraw(playerid, 521.200012, 362.231140, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][9], 0.000399, 1.360002);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][9], 624.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][9], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][9], -5963521);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][9], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][9], 255);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][9], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][9], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][9], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][9], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][9], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][9], 0);

	ptd_speedometr[playerid][10] = CreatePlayerTextDraw(playerid, 589.999511, 381.644287, "100 km/h");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][10], 0.147598, 1.316263);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][10], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][10], -1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][10], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][10], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][10], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][10], 2);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][10], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][10], 0);

	ptd_speedometr[playerid][11] = CreatePlayerTextDraw(playerid, 522.799926, 364.719940, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][11], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][11], 522.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][11], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][11], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][11], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][11], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][11], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][11], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][11], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][11], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][11], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][11], 0);

	ptd_speedometr[playerid][12] = CreatePlayerTextDraw(playerid, 526.799987, 364.719940, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][12], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][12], 526.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][12], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][12], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][12], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][12], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][12], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][12], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][12], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][12], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][12], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][12], 0);

	ptd_speedometr[playerid][13] = CreatePlayerTextDraw(playerid, 530.799987, 364.719940, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][13], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][13], 530.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][13], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][13], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][13], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][13], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][13], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][13], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][13], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][13], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][13], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][13], 0);

	ptd_speedometr[playerid][14] = CreatePlayerTextDraw(playerid, 534.800109, 364.719940, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][14], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][14], 534.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][14], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][14], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][14], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][14], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][14], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][14], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][14], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][14], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][14], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][14], 0);

	ptd_speedometr[playerid][15] = CreatePlayerTextDraw(playerid, 538.800048, 364.719940, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][15], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][15], 538.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][15], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][15], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][15], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][15], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][15], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][15], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][15], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][15], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][15], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][15], 0);

	ptd_speedometr[playerid][16] = CreatePlayerTextDraw(playerid, 542.799926, 364.719940, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][16], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][16], 542.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][16], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][16], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][16], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][16], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][16], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][16], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][16], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][16], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][16], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][16], 0);

	ptd_speedometr[playerid][17] = CreatePlayerTextDraw(playerid, 546.800048, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][17], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][17], 546.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][17], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][17], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][17], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][17], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][17], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][17], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][17], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][17], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][17], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][17], 0);

	ptd_speedometr[playerid][18] = CreatePlayerTextDraw(playerid, 550.800048, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][18], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][18], 550.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][18], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][18], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][18], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][18], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][18], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][18], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][18], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][18], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][18], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][18], 0);

	ptd_speedometr[playerid][19] = CreatePlayerTextDraw(playerid, 554.800109, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][19], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][19], 554.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][19], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][19], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][19], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][19], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][19], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][19], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][19], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][19], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][19], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][19], 0);

	ptd_speedometr[playerid][20] = CreatePlayerTextDraw(playerid, 558.800354, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][20], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][20], 558.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][20], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][20], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][20], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][20], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][20], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][20], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][20], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][20], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][20], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][20], 0);

	ptd_speedometr[playerid][21] = CreatePlayerTextDraw(playerid, 562.800292, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][21], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][21], 562.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][21], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][21], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][21], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][21], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][21], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][21], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][21], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][21], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][21], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][21], 0);

	ptd_speedometr[playerid][22] = CreatePlayerTextDraw(playerid, 566.800231, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][22], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][22], 566.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][22], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][22], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][22], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][22], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][22], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][22], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][22], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][22], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][22], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][22], 0);

	ptd_speedometr[playerid][23] = CreatePlayerTextDraw(playerid, 570.800231, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][23], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][23], 570.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][23], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][23], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][23], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][23], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][23], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][23], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][23], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][23], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][23], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][23], 0);

	ptd_speedometr[playerid][24] = CreatePlayerTextDraw(playerid, 574.800292, 364.720001, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][24], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][24], 574.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][24], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][24], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][24], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][24], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][24], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][24], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][24], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][24], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][24], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][24], 0);

	ptd_speedometr[playerid][25] = CreatePlayerTextDraw(playerid, 578.800292, 364.720062, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][25], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][25], 578.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][25], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][25], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][25], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][25], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][25], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][25], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][25], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][25], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][25], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][25], 0);

	ptd_speedometr[playerid][26] = CreatePlayerTextDraw(playerid, 582.800231, 364.720062, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][26], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][26], 582.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][26], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][26], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][26], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][26], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][26], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][26], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][26], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][26], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][26], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][26], 0);

	ptd_speedometr[playerid][27] = CreatePlayerTextDraw(playerid, 586.800109, 364.720062, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][27], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][27], 586.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][27], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][27], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][27], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][27], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][27], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][27], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][27], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][27], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][27], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][27], 0);

	ptd_speedometr[playerid][28] = CreatePlayerTextDraw(playerid, 590.800109, 364.720062, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][28], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][28], 590.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][28], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][28], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][28], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][28], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][28], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][28], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][28], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][28], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][28], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][28], 0);

	ptd_speedometr[playerid][29] = CreatePlayerTextDraw(playerid, 594.800109, 364.720062, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][29], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][29], 594.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][29], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][29], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][29], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][29], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][29], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][29], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][29], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][29], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][29], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][29], 0);

	ptd_speedometr[playerid][30] = CreatePlayerTextDraw(playerid, 598.800109, 364.720062, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][30], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][30], 598.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][30], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][30], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][30], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][30], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][30], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][30], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][30], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][30], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][30], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][30], 0);

	ptd_speedometr[playerid][31] = CreatePlayerTextDraw(playerid, 602.800170, 364.720092, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][31], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][31], 602.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][31], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][31], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][31], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][31], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][31], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][31], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][31], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][31], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][31], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][31], 0);

	ptd_speedometr[playerid][32] = CreatePlayerTextDraw(playerid, 606.800231, 364.720092, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][32], 0.000000, 0.840000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][32], 606.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][32], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][32], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][32], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][32], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][32], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][32], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][32], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][32], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][32], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][32], 0);

	ptd_speedometr[playerid][33] = CreatePlayerTextDraw(playerid, 610.800292, 364.720092, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][33], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][33], 610.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][33], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][33], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][33], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][33], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][33], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][33], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][33], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][33], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][33], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][33], 0);

	ptd_speedometr[playerid][34] = CreatePlayerTextDraw(playerid, 614.800354, 364.720092, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][34], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][34], 614.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][34], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][34], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][34], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][34], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][34], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][34], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][34], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][34], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][34], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][34], 0);

	ptd_speedometr[playerid][35] = CreatePlayerTextDraw(playerid, 618.800292, 364.720092, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][35], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][35], 618.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][35], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][35], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][35], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][35], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][35], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][35], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][35], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][35], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][35], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][35], 0);

	ptd_speedometr[playerid][36] = CreatePlayerTextDraw(playerid, 622.800476, 364.720092, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][36], 0.000000, 0.800000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][36], 622.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][36], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][36], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][36], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][36], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][36], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][36], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][36], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][36], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][36], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][36], 0);

	ptd_speedometr[playerid][37] = CreatePlayerTextDraw(playerid, 523.199951, 396.079986, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][37], 0.000000, -0.039999);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][37], 536.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][37], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][37], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][37], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][37], -16776961);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][37], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][37], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][37], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][37], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][37], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][37], 0);

	ptd_speedometr[playerid][38] = CreatePlayerTextDraw(playerid, 538.800048, 396.080017, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][38], 0.000000, -0.079999);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][38], 553.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][38], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][38], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][38], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][38], 16711935);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][38], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][38], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][38], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][38], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][38], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][38], 0);

	ptd_speedometr[playerid][39] = CreatePlayerTextDraw(playerid, 556.000061, 396.080017, "box");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][39], 0.000000, -0.079999);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][39], 570.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][39], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][39], -1);
	PlayerTextDrawUseBox(playerid, ptd_speedometr[playerid][39], 1);
	PlayerTextDrawBoxColor(playerid, ptd_speedometr[playerid][39], -16776961);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][39], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][39], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][39], 255);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][39], 1);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][39], 1);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][39], 0);

	ptd_speedometr[playerid][40] = CreatePlayerTextDraw(playerid, 516.600219, 373.524414, "");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][40], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][40], 24.000000, 28.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][40], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][40], -16776961);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][40], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][40], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][40], 0);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][40], 5);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][40], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][40], 0);
	PlayerTextDrawSetPreviewModel(playerid, ptd_speedometr[playerid][40], 11746);
	PlayerTextDrawSetPreviewRot(playerid, ptd_speedometr[playerid][40], 360.000000, 0.000000, 0.000000, 1.000000);

	ptd_speedometr[playerid][41] = CreatePlayerTextDraw(playerid, 555.400024, 380.991180, "");
	PlayerTextDrawLetterSize(playerid, ptd_speedometr[playerid][41], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, ptd_speedometr[playerid][41], 14.000000, 13.000000);
	PlayerTextDrawAlignment(playerid, ptd_speedometr[playerid][41], 1);
	PlayerTextDrawColor(playerid, ptd_speedometr[playerid][41], -16776961);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][41], 0);
	PlayerTextDrawSetOutline(playerid, ptd_speedometr[playerid][41], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_speedometr[playerid][41], 0);
	PlayerTextDrawFont(playerid, ptd_speedometr[playerid][41], 5);
	PlayerTextDrawSetProportional(playerid, ptd_speedometr[playerid][41], 0);
	PlayerTextDrawSetShadow(playerid, ptd_speedometr[playerid][41], 0);
	PlayerTextDrawSetPreviewModel(playerid, ptd_speedometr[playerid][41], 19917);
	PlayerTextDrawSetPreviewRot(playerid, ptd_speedometr[playerid][41], 0.000000, 0.000000, -45.000000, 1.000000);

    farm_ptd[playerid][0] = CreatePlayerTextDraw(playerid, 26.3999, 201.3930, "HaўЁk_:"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][0], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][0], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][0], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][0], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][0], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][0], 0);

	farm_ptd[playerid][1] = CreatePlayerTextDraw(playerid, 63.4995, 201.3930, "50/100"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][1], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][1], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][1], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][1], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][1], 0);

	farm_ptd[playerid][2] = CreatePlayerTextDraw(playerid, 26.3999, 210.5937, "€apЈћa¦a_:"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][2], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][2], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][2], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][2], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][2], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][2], 0);

	farm_ptd[playerid][3] = CreatePlayerTextDraw(playerid, 63.4995, 210.5937, "100000$"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][3], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][3], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][3], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][3], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][3], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][3], 0);

	farm_ptd[playerid][4] = CreatePlayerTextDraw(playerid, 26.3999, 235.8952, "Њpo ecc_Јocaљkњ_:"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][4], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][4], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][4], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][4], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][4], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][4], 0);

	farm_ptd[playerid][5] = CreatePlayerTextDraw(playerid, 83.0492, 236.4138, "100%"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][5], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][5], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][5], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][5], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][5], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][5], 0);

	farm_ptd[playerid][6] = CreatePlayerTextDraw(playerid, 26.3999, 192.5926, "ѓoћ›®oc¦©_:"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][6], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][6], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][6], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][6], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][6], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][6], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][6], 0);

	farm_ptd[playerid][7] = CreatePlayerTextDraw(playerid, 63.4995, 192.5926, "¦pak¦opњc¦"); // ?????
	PlayerTextDrawLetterSize(playerid, farm_ptd[playerid][7], 0.1335, 0.9139);
	PlayerTextDrawAlignment(playerid, farm_ptd[playerid][7], 1);
	PlayerTextDrawColor(playerid, farm_ptd[playerid][7], -5963521);
	PlayerTextDrawBackgroundColor(playerid, farm_ptd[playerid][7], 255);
	PlayerTextDrawFont(playerid, farm_ptd[playerid][7], 2);
	PlayerTextDrawSetProportional(playerid, farm_ptd[playerid][7], 1);
	PlayerTextDrawSetShadow(playerid, farm_ptd[playerid][7], 0);
	
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
	SetCameraBehindPlayer(playerid);
}
stock BuyPlayerHouse(playerid, houseid, bool: buy_from_owner = false, price = -1)
{
	if(!IsHouseOwned(houseid) && GetPlayerHouse(playerid) == -1)
	{
		if(price <= 0)
			price = GetHouseData(houseid, H_PRICE);

		if(PI[playerid][pCash] >= price)
		{
			format(query, sizeof query, "UPDATE users a, houses h SET a.cash=%d,a.house_type=%d,a.house=%d,h.owner_id=%d WHERE a.id=%d AND h.id=%d", PI[playerid][pCash]-price, HOUSE_TYPE_HOME, houseid, PI[playerid][pID], PI[playerid][pID], GetHouseData(houseid, H_SQL_ID));
			mysql_query(dbHandle, query, false);
			if(!mysql_errno())
			{
				SetInfo(playerid, pHouseID, 		houseid);
				SetInfo(playerid, pHouseType, 	HOUSE_TYPE_HOME);
				SetHouseData(houseid, H_OWNER_ID,PI[playerid][pID]);
				SetHouseData(houseid, H_IMPROVEMENTS, 	0);
				SetHouseData(houseid, H_STORE_X, 0.0);
				SetHouseData(houseid, H_STORE_Y, 0.0);
				SetHouseData(houseid, H_STORE_Z, 0.0);

				new time = gettime();
				new rent_time = (time - (time % 86400)) + 86400;

				if(!buy_from_owner)
				{
					SetHouseData(houseid,	H_RENT_DATE,	rent_time);
					SetHouseData(houseid,	H_LOCK_STATUS,	false);
				}
				else
				{
					if(GetElapsedTime(GetHouseData(houseid, H_RENT_DATE), time, CONVERT_TIME_TO_DAYS) <= 0)
					{
						SetHouseData(houseid, H_RENT_DATE, rent_time);
					}
				}
				format(g_house[houseid][H_OWNER_NAME], 21, GN(playerid), 0);
				UpdateHouse(houseid);
				GiveMoney(playerid, -price);
				SCM(playerid, 0xFFCC00FF, "Используйте {3399FF}/exit {FFCC00}для выхода из дома");

				format(query, sizeof query, "UPDATE houses SET improvements=0,rent_time=%d,`lock`=%d,store_x=0.0,store_y=0.0,store_z=0.0 WHERE id=%d LIMIT 1", GetHouseData(houseid, H_RENT_DATE), GetHouseData(houseid, H_LOCK_STATUS), GetHouseData(houseid, H_SQL_ID));
				mysql_query(dbHandle, query, false);

				return 1;
			}
			else SCM(playerid, 0xFF6600FF, "Ошибка сохранения, повторите попытку {FF0000}(ISLAND-ERR 34)");

			return 0;
		}
		return 0;
	}
	return -1;
}

stock EnterPlayerToHouse(playerid, houseid)
{
	if(GetPlayerInHouse(playerid) == -1)
	{
		new type = GetHouseData(houseid, H_TYPE);

		SetPlayerPosEx
		(
			playerid,
			GetHouseTypeInfo(type, HT_ENTER_POS_X),
			GetHouseTypeInfo(type, HT_ENTER_POS_Y),
			GetHouseTypeInfo(type, HT_ENTER_POS_Z),
			houseid + 2000,
			GetHouseTypeInfo(type, HT_INTERIOR),
			GetHouseTypeInfo(type, HT_ENTER_POS_ANGLE)
		);
		SetPlayerInHouse(playerid, houseid);
	}
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
			  		SetPlayerFacingAngle(playerid,-90.0);
			  		//SetPlayerCameraLookAt(playerid, -2379.1594,-578.0125,132.1172);
			  		SetPlayerCameraPos(playerid, -2379.9355,-580.9198,134.1172);
                    //ShowMenuForPlayer(skinmenu, playerid),TogglePlayerControllable(playerid, false);
                    for(new i; i < 12; i++) TextDrawShowForPlayer(playerid,c_skin[i]);
                    TogglePlayerControllable(playerid, false);
                    SelectTextDraw(playerid,0xFFFFFFF);
                    if(PI[playerid][pSex] == 1) SetPlayerSkin(playerid, ChoiseSkin[SelectCharPlace[playerid]]), ChosenSkin[playerid] = ChoiseSkin[0];
					else SetPlayerSkin(playerid, ChoiseSkinM[SelectCharPlace[playerid]]), ChosenSkin[playerid] = ChoiseSkinM[0];
		        }
	     	case 1: PlayerRegistered[playerid][1] = 0,TogglePlayerControllable(playerid, true),SpawnPlayer(playerid);
		}
	}
}
function: LoadPlayerInfo(playerid,text[])
{
	mysql_format(dbHandle, query, sizeof(query), "SELECT * FROM `blocked` WHERE `name` = '%e'", GN(playerid));
	mysql_tquery(dbHandle, query, "check_banlist", "i", playerid);
	if(!GetPVarInt(playerid, "player_logged")) return 1;
	new rows,fields;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(!rows)
	{
		PlayerLogTries[playerid]++;
		if(PlayerLogTries[playerid] == 3)
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
	cache_get_value_name_int(0,"lvl",PI[playerid][pLVL]);
	cache_get_value_name_int(0,"exp",PI[playerid][pExp]);
	cache_get_value_name_int(0,"skin_id",PI[playerid][pSkin_ID]);
	cache_get_value_name(0,"email",PI[playerid][pEmail]);
	cache_get_value_name_int(0,"sex",PI[playerid][pSex]);
	cache_get_value_name(0,"reg_ip",PI[playerid][pRegIP]);
	cache_get_value_name_int(0,"data_reg",PI[playerid][pDataReg]);
	cache_get_value_name(0,"last_ip",PI[playerid][pLastIP]);
	cache_get_value_name_int(0,"cash",PI[playerid][pCash]);
	cache_get_value_name_int(0,"bank",PI[playerid][pBank]);
	cache_get_value_name_int(0,"job",PI[playerid][pJob]);
	cache_get_value_name_int(0,"leader_id",PI[playerid][pLeader]);
	cache_get_value_name_int(0,"member_id",PI[playerid][pMember]);
	cache_get_value_name_int(0,"rank",PI[playerid][pRank]);
	cache_get_value_name_int(0,"a_lvl",PI[playerid][pAdmin]);
	cache_get_value_name_int(0,"f_id",PI[playerid][pFarmID]);
	cache_get_value_name_int(0,"house",PI[playerid][pHouseID]);
	cache_get_value_name_int(0,"house_type",PI[playerid][pHouseType]);
	cache_get_value_name_int(0,"business",PI[playerid][pBusinessID]);
	cache_get_value_name_int(0,"dialog_data",PI[playerid][pDialogData][0]);
	cache_get_value_name_int(0,"dialog_data_2",PI[playerid][pDialogData][1]);
	cache_get_value_name_int(0,"dialog_data_3",PI[playerid][pDialogData][2]);
	cache_get_value_name_int(0,"repair_kit",PI[playerid][pR_Kit]);
	cache_get_value_name_int(0,"healc",PI[playerid][pHealc]);
	cache_get_value_name_int(0,"mask",PI[playerid][pMask]);
	cache_get_value_name_int(0,"phone",PI[playerid][pPhone]);
	cache_get_value_name_int(0,"phone_number",PI[playerid][pPhoneNumber]);
	cache_get_value_name_int(0,"phone_balance",PI[playerid][pPhoneBalance]);
	cache_get_value_name_float(0,"pos_x",PI[playerid][pLeaveX]);
	cache_get_value_name_float(0,"pos_y",PI[playerid][pLeaveY]);
	cache_get_value_name_float(0,"pos_z",PI[playerid][pLeaveZ]);
	cache_get_value_name_int(0,"virtual_world",PI[playerid][pLeaveVW]);
	cache_get_value_name_int(0,"interior",PI[playerid][pLeaveI]);
	cache_get_value_name_int(0,"suspect",PI[playerid][pSu]);
	cache_get_value_name_int(0,"drugs",PI[playerid][pDrugs]);
	cache_get_value_name_int(0,"satiety",PI[playerid][pSatiety]);
	cache_get_value_name_int(0,"mute",PI[playerid][pMute]);
	cache_get_value_name_int(0,"mats",PI[playerid][pMats]);
	cache_get_value_name_int(0,"ammo1",PI[playerid][pAmmo1]);
	cache_get_value_name_int(0,"ammo2",PI[playerid][pAmmo2]);
	cache_get_value_name_int(0,"ammo3",PI[playerid][pAmmo3]);
	cache_get_value_name_int(0,"ammo4",PI[playerid][pAmmo4]);
	cache_get_value_name_int(0,"ammo5",PI[playerid][pAmmo5]);
	cache_get_value_name_int(0,"ammo6",PI[playerid][pAmmo6]);
	cache_get_value_name_int(0,"body1",PI[playerid][pBody1]);
	cache_get_value_name_int(0,"body2",PI[playerid][pBody2]);
	cache_get_value_name_int(0,"body3",PI[playerid][pBody3]);
	cache_get_value_name_int(0,"body4",PI[playerid][pBody4]);
	cache_get_value_name_int(0,"body5",PI[playerid][pBody5]);
	cache_get_value_name_int(0,"body6",PI[playerid][pBody6]);
	SetProgressBarValue(satiety, PI[playerid][pSatiety]);
	UpdateProgressBar(satiety, playerid);
	PI[playerid][pCarID] = INVALID_VEHICLE_ID;
	DeletePVar(playerid, "player_logged");
	//SpawnPlayer(playerid);
	UnloadPlayerLogin(playerid);
	//PL[playerid] = true;
	SPD(playerid,dialog_spawn,2,"{FFA500}Место спавна","{FFA500}1.{FFFFFF} Вокзал\n{FFA500}2.{FFFFFF} Место проживания\n{FFA500}3.{FFFFFF} База организации\n{FFA500}4.{FFFFFF} Где вышел","Выбрать","Отмена");
	return 1;
}
stock Menu()
{
   	skinmenu = CreateMenu("Form", 1, 50.0, 160.0, 90.0);
	AddMenuItem(skinmenu ,0,"Next");
	AddMenuItem(skinmenu ,0,"Back");
	AddMenuItem(skinmenu ,0,"Select");
}
stock SCM_A(color,msg[])
{
	foreach(new i : Player)
	{
	    if(!AL[i] || !PL[i]) continue;
	    SCM(i,color,msg);
	}
}
stock SCM_J(jobid,color,msg[])
{
	foreach(new i : Player)
	{
	    if(!AL[i] || !PL[i]) continue;
	    if(jobid != PI[i][pJob]) continue;
	    SCM(i,color,msg);
	}
	return 1;
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

	printf("[Пикапы]: Все входы/выходы созданы за <%d ms>.",GetTickCount()-time);
}
stock GunPickupsInit()
{
	new time=GetTickCount();
	for(new idx; idx < sizeof g_gun_org; idx ++)
	{
 		CreatePickup(353, 23, g_gun_org[idx][pos_x], g_gun_org[idx][pos_y], g_gun_org[idx][pos_z], g_gun_org[idx][E_VID], PICKUP_ACTION_TYPE_GUN, idx);
	}

	printf("[Склады]: Все склады организаций загружены за <%i ms>.",GetTickCount()-time);
}
stock GunLabelInit(frac_id)
{
	switch(frac_id)
	{
	    case 4: frac_gun[4] = Create3DTextLabel("{FFA500}ALT",0x00FFFFDD,-1299.6852,497.6682,11.1953,20.0,0,0);
	}
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
	        case 1: SPD(playerid,dialog_job,DIALOG_STYLE_MSGBOX,"{FFA500}Работа фермера","{ffffff}- Добро пожаловать на территорию фермы!\n\nНа данный момент на ферме мне нужна помощь.\nЕсли тебе не составит труда помочь мне,\nто я готов взять тебя на работу!\nЗарплата будет выдана на основе проделаной работы.\nВ соотношении:\n\tЗа сбор яблоков:\t\t\t{FFA500}30${ffffff}\n\tЗа сбор урожая пшеница и лёна:\t{FFA500}50${ffffff}\n\tЗа сбор помидор:\t\t\t{FFA500}32${FFFFFF}\n\tЗа вспахивание поля:\t\t\t{FFA500}20${ffffff}\n\nВы хотите устроиться на работу?","Далее","Закрыть");
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
		    case 1:
				{
				    SCM(playerid,COLOR_LIME,"Доступная работа:");
					SCM(playerid,COLOR_LIME,"1) Посадка пшеницы и лёна. Чтобы начать - Вам необходимо взять трактор. На карте отмечено место.");
					SCM(playerid,COLOR_LIME,"2) Посадка помидор. Чтобы начать - Вам необходимо взять лопату со склада. На карте отмечено место.");
					SCM(playerid,COLOR_LIME,"3) Сбор яблок и апельсин. Чтобы начать - Вам необходимо взять ящик для сбора урожая со склада. На карте отмечено место.");
					SetPlayerCheckpoint(playerid,-1073.3032,-1202.9966,129.2188,2.0,CP_ACTION_TYPE_MARK_2);
					SetPVarInt(playerid,"ID_F",0);
				}
		    case 2:
		        {
		            new b_t = random(12);
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
		case 0: SetPlayerCheckpoint(playerid, 1402.9274,-52.9362,3000.6, 0.9, CP_ACTION_TYPE_GIVE_Z);
    	case 1: SetPlayerCheckpoint(playerid, 1403.1617,-55.1036,3000.6, 0.9, CP_ACTION_TYPE_GIVE_Z);
    	case 2: SetPlayerCheckpoint(playerid, 1403.1624,-59.6582,3000.6, 0.9, CP_ACTION_TYPE_GIVE_Z);
    }
    SCM(playerid,COLOR_BLUE,"Возьмите готовый груз с конвейера, затем упакуйте готовую ткань в коробку!");
	return KillTimer(PI[playerid][pPlayerTimer]);
}
stock SaveAccounts(playerid)
{
    if(PL[playerid] && IsPlayerConnected(playerid))
    {
	    new src[100];
		format(query,sizeof(query),"UPDATE `users` SET ");
		format(src,sizeof(src),"cash='%d',", PI[playerid][pCash]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"lvl='%d',", PI[playerid][pLVL]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"exp='%d',", PI[playerid][pExp]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"last_ip = '%s',", PI[playerid][pLastIP]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"bank='%d',",PI[playerid][pBank]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"job='%d',",PI[playerid][pJob]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"member_id='%d',",PI[playerid][pMember]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"leader_id='%d',",PI[playerid][pLeader]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"rank='%d',",PI[playerid][pRank]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"repair_kit='%d',",PI[playerid][pR_Kit]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"mask='%d',",PI[playerid][pMask]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"healc='%d',",PI[playerid][pHealc]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"mute='%d',",PI[playerid][pMute]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"phone='%d',",PI[playerid][pPhone]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"phone_number='%d',",PI[playerid][pPhoneNumber]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"phone_balance='%d',",PI[playerid][pPhoneBalance]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"skin_id='%d',",PI[playerid][pSkin_ID]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"satiety='%d',",PI[playerid][pSatiety]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"mats='%d',",PI[playerid][pMats]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"ammo1='%d',",PI[playerid][pAmmo1]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"ammo2='%d',",PI[playerid][pAmmo2]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"ammo3='%d',",PI[playerid][pAmmo3]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"ammo4='%d',",PI[playerid][pAmmo4]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"ammo5='%d',",PI[playerid][pAmmo5]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"ammo6='%d',",PI[playerid][pAmmo6]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"body1='%d',",PI[playerid][pBody1]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"body2='%d',",PI[playerid][pBody2]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"body3='%d',",PI[playerid][pBody3]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"body4='%d',",PI[playerid][pBody4]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"body5='%d',",PI[playerid][pBody5]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"body6='%d',",PI[playerid][pBody6]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"drugs='%d',",PI[playerid][pDrugs]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src),"suspect='%d'",PI[playerid][pSu]);
		strcat(query,src,sizeof(query));
		format(src,sizeof(src)," WHERE id='%d' LIMIT 1",PI[playerid][pID]);
		strcat(query,src,sizeof(query));
	 	mysql_tquery(dbHandle, query);
 	}
 	return 1;
}
stock SaveFarmInfo()
{
    new src[600],time = GetTickCount();
	format(query,sizeof(query),"UPDATE `farm` SET ");
	format(src,sizeof(src),"f_bank='%d',",FI[f_bank]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_sdl='%d',",FI[f_sdl]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_tools='%d',",FI[f_tools]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_water='%d',",FI[f_water]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_apple='%d',",FI[f_apple]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_orange='%d',",FI[f_orange]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_flax='%d',",FI[f_flax]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_millet='%d',",FI[f_millet]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_cotton='%d',",FI[f_cotton]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_corn='%d',",FI[f_corn]);
	strcat(query,src,sizeof(query));
	format(src,sizeof(src),"f_tomato='%d'",FI[f_tomato]);
	strcat(query,src,sizeof(query));
 	mysql_tquery(dbHandle, query);
 	CallLocalFunction("UpdateFarmText","");
 	printf("[Ферма]: Данные успешно сохранены. Потрачено времени: <%d ms>.",GetTickCount()-time);
 	return 1;
}
function: LoadHouses()
{
	new Cache: result, rows,idx,time = GetTickCount(),buffer[2];

	result = mysql_query(dbHandle, "SELECT h.*, IFNULL(a.name, 'None') owner_name FROM houses h LEFT JOIN users a ON a.id=h.owner_id", true);
	rows = cache_num_rows();

	if(rows > MAX_HOUSES)
	{
		rows = MAX_HOUSES;
		print("[Houses]: DB rows > MAX_HOUSES");
	}

	for(idx = 0; idx < rows; idx ++)
	{
		cache_get_value_name_int(idx,"id",g_house[idx][H_SQL_ID]);
		cache_get_value_name_int(idx,"owner_id",g_house[idx][H_OWNER_ID]);
		cache_get_value_name(idx, "name", g_house[idx][H_NAME], 20);
        cache_get_value_name_int(idx,"improvements",g_house[idx][H_IMPROVEMENTS]);
		cache_get_value_name_int(idx,"rent_time",g_house[idx][H_RENT_DATE]);
		cache_get_value_name_int(idx,"price",g_house[idx][H_PRICE]);
        cache_get_value_name_int(idx,"rent_price",g_house[idx][H_RENT_PRICE]);
        cache_get_value_name_int(idx,"type",g_house[idx][H_TYPE]);
        cache_get_value_name_int(idx,"lock",g_house[idx][H_LOCK_STATUS]);
        cache_get_value_name_float(idx,"x",g_house[idx][H_POS_X]);
        cache_get_value_name_float(idx,"y",g_house[idx][H_POS_Y]);
        cache_get_value_name_float(idx,"z",g_house[idx][H_POS_Z]);
		cache_get_value_name_float(idx,"exit_x",g_house[idx][H_EXIT_POS_X]);
		cache_get_value_name_float(idx,"exit_y",g_house[idx][H_EXIT_POS_Y]);
		cache_get_value_name_float(idx,"exit_z",g_house[idx][H_EXIT_POS_Z]);
		cache_get_value_name_float(idx,"exit_angle",g_house[idx][H_EXIT_ANGLE]);

/*	SetHouseData(idx, H_CAR_POS_X,		cache_get_field_content_float(idx, "car_x"));
		SetHouseData(idx, H_CAR_POS_Y,		cache_get_field_content_float(idx, "car_y"));
		SetHouseData(idx, H_CAR_POS_Z,		cache_get_field_content_float(idx, "car_z"));
		SetHouseData(idx, H_CAR_ANGLE,		cache_get_field_content_float(idx, "car_angle"));

		SetHouseData(idx, H_STORE_X,		cache_get_field_content_float(idx, "store_x"));
		SetHouseData(idx, H_STORE_Y,		cache_get_field_content_float(idx, "store_y"));
		SetHouseData(idx, H_STORE_Z,		cache_get_field_content_float(idx, "store_z"));

		SetHouseData(idx, H_EVICTION,		cache_get_field_content_int(idx, "eviction"));

		SetHouseData(idx, H_STORE_METALL,	cache_get_field_content_int(idx, "store_metall"));
		SetHouseData(idx, H_STORE_DRUGS,	cache_get_field_content_int(idx, "store_drugs"));
		SetHouseData(idx, H_STORE_WEAPON,	cache_get_field_content_int(idx, "store_weapon"));
		SetHouseData(idx, H_STORE_AMMO,		cache_get_field_content_int(idx, "store_ammo"));
		SetHouseData(idx, H_STORE_SKIN,		cache_get_field_content_int(idx, "store_skin"));*/
		cache_get_value_name(idx, "owner_name", g_house[idx][H_OWNER_NAME], 21);
		// -------------------------
		buffer[0] = GetHouseData(idx, H_TYPE);
		if(!strlen(GetHouseData(idx, H_NAME)))
			format(g_house[idx][H_NAME], 20, GetHouseTypeInfo(buffer[0], HT_NAME), 0);
		if(IsHouseOwned(idx) && !strcmp(GetHouseData(idx, H_OWNER_NAME), "None", true))
		{
			SetHouseData(idx, H_OWNER_ID, 0);

			mysql_format(dbHandle, query, sizeof query, "UPDATE houses SET owner_id=0,improvements=0 WHERE id=%d", GetHouseData(idx, H_SQL_ID));
			mysql_query(dbHandle, query, false);
		}

		if(!IsHouseOwned(idx))
		{
			SetHouseData(idx, H_IMPROVEMENTS, 	0);
			SetHouseData(idx, H_LOCK_STATUS, 	false);
		}
		UpdateHouse(idx);

		//HouseHealthInit(idx);
		//HouseStoreInit(idx);

	}
	g_house_loaded = rows;
	cache_delete(result);
	printf("[Дома]: Домов загружено: %d. Потрачено времени: <%d ms>.", g_house_loaded,GetTickCount()-time);
}
function: LoadWareHouse()
{
    new time = GetTickCount(),rows,Cache:result;
    result = mysql_query(dbHandle,"SELECT * FROM `warehouse`");
    rows = cache_num_rows();
	if(rows)
	{
		cache_get_value_name_int(0,"f_factory",PW[factory]);
		cache_get_value_name_int(0,"army_mats",PW[army_mats]);
		cache_get_value_name_int(0,"army_ammo1",PW[army_ammo1]);
		cache_get_value_name_int(0,"army_ammo3",PW[army_ammo3]);
		cache_get_value_name_int(0,"army_ammo4",PW[army_ammo4]);
		cache_get_value_name_int(0,"army_body1",PW[army_body1]);
		cache_get_value_name_int(0,"army_body4",PW[army_body4]);
	}
	cache_delete(result);
	printf("[Cклады]: Все значения установлены. Потрачено: <%i ms>.", GetTickCount() - time);
	return 1;
}
function: LoadRegFail(playerid,name_s[])
{
    new rows,Cache:result, data_reg, reg_ip[20],
	last_ip[20],referal[MAX_PLAYER_NAME],last_date,string[70],string_2[200];
	format(string, sizeof string,"SELECT * FROM `users` WHERE `name` = '%s'",name_s);
    result = mysql_query(dbHandle,string);
    rows = cache_num_rows();
	if(rows)
	{
		cache_get_value_name_int(0,"data_reg",data_reg);
		cache_get_value_name(0,"reg_ip",reg_ip);
		cache_get_value_name(0,"last_ip",last_ip);
		cache_get_value_name(0,"referal",referal);
		cache_get_value_name_int(0,"last_date",last_date);
	}
	else return SCM(playerid,COLOR_DARKORANGE,"Данные о регистрации данного пользователя отсутствуют! Проверьте правильность введённого никнейма.");
	cache_delete(result);
	format(string,40, "{FFA500}%s",name_s);
	format(string_2,sizeof(string_2),"{FFFFFF}Данные об пользователе найдены.\n\nДата регистрации:\t%02d.%02d.%d\nДата последнего выхода:\t%02d.%02d.%d\nIP при регистрации:\t%s\nПоследний IP:\t\t%s",
	ConvertUnixTime(data_reg,CONVERT_TIME_TO_DAYS)-3,ConvertUnixTime(data_reg,CONVERT_TIME_TO_MONTHS)+1,ConvertUnixTime(data_reg,CONVERT_TIME_TO_YEARS),
	ConvertUnixTime(last_date,CONVERT_TIME_TO_DAYS)-3,ConvertUnixTime(last_date,CONVERT_TIME_TO_MONTHS)+1,ConvertUnixTime(last_date,CONVERT_TIME_TO_YEARS),
	reg_ip,last_ip);
	SPD(playerid,0,0,string,string_2,"Закрыть","");
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
stock MysqlUpdateWareHouse(field[], data)
{
	new Query[128];
	format(Query, sizeof(Query), "UPDATE `warehouse` SET %s = '%d'", field, data);
	return mysql_tquery(dbHandle, Query);
}
stock MysqlUpdateUsers(field[], data,id)
{
	new Query[128];
	format(Query, sizeof(Query), "UPDATE `users` SET %s = '%d' WHERE id = '%d'", field, data,id);
	return mysql_tquery(dbHandle, Query);
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
	format(str,sizeof(str),"{ffffff}Имя_Фамилия:  {FFA500}%s\n",GN(targetid));
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Пол:  {FFA500}%s{FFFFFF}\n\n",pol_text);
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Уровень:  {FFA500}%d(%d/%d)\n\n",PI[playerid][pLVL],PI[playerid][pExp],(PI[playerid][pLVL]+1)*4);
	strcat(sctring,str);
    format(str,sizeof(str),"{ffffff}Деньги:  {FFA500}%d${FFFFFF}\n", PI[playerid][pCash]);
    strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Организация:  {FFA500}%s{FFFFFF}\n",Fraction_Name[PI[playerid][pMember]]);
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Должность:  {FFA500}%s{FFFFFF}\n",Fraction_Rank(playerid));
	strcat(sctring,str);
	format(str,sizeof(str),"{ffffff}Работа:  {FFA500}-{FFFFFF}\n\n");
	strcat(sctring,str);
	if(PI[playerid][pHouseID] > -1) format(str,sizeof(str),"{ffffff}Проживание:  {FFA500}Дом №%d(%s){FFFFFF}\n",PI[playerid][pHouseID],GetHouseData(PI[playerid][pHouseID], H_NAME));
	else format(str,sizeof(str),"{ffffff}Проживание:  {FFA500}Бездомный{FFFFFF}\n");
	strcat(sctring,str);
	if(PI[playerid][pBusinessID] > -1) format(str,sizeof(str),"{ffffff}Бизнес:  {FFA500}%s №%d{FFFFFF}\n\n",g_business[PI[playerid][pBusinessID]][B_NAME],PI[playerid][pBusinessID]);
	else format(str,sizeof(str),"{ffffff}Бизнес:  {FFA500}Отсутствует{FFFFFF}\n\n");
	strcat(sctring,str);
	if(PI[playerid][pCarID] == INVALID_VEHICLE_ID && PI[playerid][pHouseID] > -1) format(str,sizeof(str),"Транспорт: {FFA500}Не загружен{ffffff}");
	else if(PI[playerid][pCarID] == INVALID_VEHICLE_ID && PI[playerid][pHouseID] == -1) format(str,sizeof(str),"Транспорт: {FFA500}Отсутствует{ffffff}");
    else if(PI[targetid][pCarID] != INVALID_VEHICLE_ID) format(str,sizeof(str),"Транспорт: {FFA500}%s[ID:%d]{ffffff}",GetVehicleInfo(GetVehicleModel(GetPlayerOwnableCar(playerid))-400,VI_NAME),PI[playerid][pCarID]);
    strcat(sctring,str);
	SPD(playerid, 0, DIALOG_STYLE_MSGBOX, "{FFA500}Статистика", sctring, "Закрыть", "");
	return 1;
}
stock JobNPC_Dialog(playerid,npc_ID)
{
	switch(npc_ID)
	{
	    case 1: SPD(playerid,dialog_npc,2,"{FFA500}Здравствуйте, вы что-то хотели?","- Здравствуйте, мне сказали здесь можно устроиться на работу.\n- Здравствуйте, кто сейчас владеет фермой?\n- Здравствуйте, какие свободные вакансии сейчас на ферме?","Выбрать","Закрыть");
	    case 2: SPD(playerid,dialog_npc,2,"{FFA500}Здравствуйте, вы что-то хотели?","- Здравствуйте, мне сказали здесь можно устроиться на работу.\n- Здравствуйте, какие должности присутствуют на заводе?\n- Здравсвуйте, расскажите об предприятии.","Выбрать","Закрыть");
	}
	SetPVarInt(playerid,"npc_id",npc_ID);
}
function: NextRouteCPFarm(playerid)
{
	if(PI[playerid][pJob] == 1)
	{
		if(PI[playerid][pJobWork])
		{
		    DisablePlayerRaceCheckpoint(playerid);
			new step = GetInfo(playerid, pJob_State);
			new next_cp = step + 1;
			if(g_farm_CP[step][Xx] == 0.0) next_cp = 0;
			if(g_farm_CP[step][States]==false)
			{
				SetPlayerRaceCheckpoint
				(
					playerid,
					0,
					g_farm_CP[step][Xx],
					g_farm_CP[step][Yy],
					g_farm_CP[step][Zz],
					g_farm_CP[next_cp][Xx],
					g_farm_CP[next_cp][Yy],
					g_farm_CP[next_cp][Zz],
					4.0,
					CP_TYPE_FARM
				);
				AddInfo(playerid, pJob_State, +, 1);
			}
			else
			{
			    FI[f_field_stats] = 100;
				DisablePlayerRaceCheckpoint(playerid);
				SCM(playerid,COLOR_BLUE,"Отличная работа! Теперь ожидайте, когда наступит день сбора урожая.");
				SCM_J(1,COLOR_BLUE,"[J] На поле начали расти пшеница и лён!");
				SetInfo(playerid,pJob_State,0);
			}
		}
	}
}
function: NextRouteCPFarm_G(playerid)
{
	if(PI[playerid][pJob] == 1)
	{
		if(PI[playerid][pJobWork])
		{
		    DisablePlayerRaceCheckpoint(playerid);
		    if(FI[f_field_stats_3] > 0)
		    {
				new step = GetInfo(playerid, pJob_State);
				new next_cp = step + 1;
				if(g_farm_CP[step][Xx] == 0.0) next_cp = 0;
				if(g_farm_CP[step][States]==false)
				{
					SetPlayerRaceCheckpoint
					(
						playerid,
						0,
						g_farm_CP[step][Xx],
						g_farm_CP[step][Yy],
						g_farm_CP[step][Zz],
						g_farm_CP[next_cp][Xx],
						g_farm_CP[next_cp][Yy],
						g_farm_CP[next_cp][Zz],
						4.0,
						CP_TYPE_FARM_G
					);
					AddInfo(playerid, pJob_State, +, 1);
					FI[f_field_stats_3]--;
					FI[f_millet]+=2;
					FI[f_flax]+=2;
					CallLocalFunction("UpdateFarmText","");
				}
				else
				{
				    FI[f_field_stats_3] = 0;
				    SCM(playerid,COLOR_LIME,"Весь урожай собран!");
				}
			}
			else SCM(playerid,COLOR_LIME,"Весь урожай успешно собран!"),SCM_J(1,COLOR_BLUE,"[J] Всесь урожай собра с поля!");
		}
	}
}
function: NextRouteCPFarm_Next(playerid)
{
	if(PI[playerid][pJob] == 1)
	{
		if(PI[playerid][pJobWork])
		{
			new step = GetInfo(playerid, pJob_State);
			if(g_farm_CP_next[step][States] == false)
			{
				SetPlayerCheckpoint
				(
					playerid,
					g_farm_CP_next[step][Xx],
					g_farm_CP_next[step][Yy],
					g_farm_CP_next[step][Zz],
					0.7,
					CP_TYPE_FARM_NEXT
				);
				AddInfo(playerid, pJob_State, +, 1);
			}
			else {
				SetInfo(playerid, pJob_State,0);
				DisablePlayerRaceCheckpoint(playerid);
				SCM(playerid,COLOR_LIME,"Вы успешно вскопали землю в теплице! Теперь можете приступать к посадке помидор.");
				SCM(playerid,COLOR_LIME,"На карте отмечено место, куда нужно положить ненужный инструмент.");
				SetPlayerCheckpoint(playerid,-1073.3032,-1202.9966,129.2188,2.0,CP_ACTION_TYPE_MARK_2);
				SetInfo(playerid, pJob_State_3,-3);
				//#include <objects/teplitsy_ferma__amp_1.pwn>
			}
		}
	}
}
function: NextRouteCPFarm_Next_2(playerid)
{
	if(PI[playerid][pJob] == 1)
	{
		if(PI[playerid][pJobWork])
		{
			new step = GetInfo(playerid, pJob_State);
			if(g_farm_CP_next[step][States]==false)
			{
				SetPlayerCheckpoint
				(
					playerid,
					g_farm_CP_next[step][Xx],
					g_farm_CP_next[step][Yy],
					g_farm_CP_next[step][Zz],
					0.7,
					CP_TYPE_FARM_NEXT_2
				);
				AddInfo(playerid, pJob_State, +, 1);
			}
			else {
			SetInfo(playerid, pJob_State,0);
			PI[playerid][pPlayerTimer] = SetTimerEx("farm_down",10_000,false,"i",playerid);
			SCM(playerid,COLOR_LIME,"Вы успешно посадили саженцы помидор! Теперь пожалуйста, подождите и полейте саженцы помидор.");
			DisablePlayerCheckpoint(playerid);
			for(new i; i < 23; i++) DestroyObject(obj_f_1[i]);
			#include <objects/teplitsy_ferma__amp_2.pwn>
			}
		}
	}
}
function: farm_down(playerid)
{
    KillTimer(PI[playerid][pPlayerTimer]);
	SetInfo(playerid, pJob_State_2,6);
	SetInfo(playerid,pJob_State_3,2);
	SCM(playerid,COLOR_LIME,"На карте отмечено место, где можно взять ведро.");
	SetPlayerCheckpoint(playerid,-1073.2662,-1203.4424,129.2188,2.0,CP_ACTION_TYPE_MARK_2);
}
function: farm_up(playerid)
{
	KillTimer(PI[playerid][pPlayerTimer]);
	SCM(playerid,COLOR_LIME,"На карте отмечено место, где можно взять ящик для сбора урожая и положить ненужный инструмент.");
	SetPlayerCheckpoint(playerid,-1073.2662,-1203.4424,129.2188,2.0,CP_ACTION_TYPE_MARK_2);
	SetInfo(playerid,pJob_State,1);
	SetInfo(playerid,pJob_State_3,4);
	SetPVarInt(playerid,"ID_F",1);
	for(new i; i < 46; i++) DestroyObject(obj_f_2[i]);
	#include <objects/teplitsy_ferma__amp_3.pwn>
}
function: NextRouteCPFarm_Next_3(playerid)
{
	if(PI[playerid][pJob] == 1)
	{
		if(PI[playerid][pJobWork])
		{
			new step = GetInfo(playerid, pJob_State);
			
			if(g_farm_CP_next[step][States]==false)
			{
				SetPlayerCheckpoint
				(
					playerid,
					g_farm_CP_next[step][Xx],
					g_farm_CP_next[step][Yy],
					g_farm_CP_next[step][Zz],
					0.7,
					CP_TYPE_FARM_NEXT_3
				);
				AddInfo(playerid, pJob_State, +, 1);
			}
			else {
			DisablePlayerCheckpoint(playerid);
			PI[playerid][pPlayerTimer] = SetTimerEx("farm_up",12_000,false,"i",playerid);
			SCM(playerid,COLOR_LIME,"Вы успешно полили грядку! Теперь дождитесь времени, когда помидоры вырастут.");
			}
		}
	}
}
function: NextRouteCPFarm_Next_4(playerid)
{
	if(PI[playerid][pJob] == 1)
	{
		if(PI[playerid][pJobWork])
		{
			new step = GetInfo(playerid, pJob_State);
			//new next_cp = step + 1;
			//if(g_farm_CP_next[step][Xx] == 0.0) next_cp = 0;
			if(g_farm_CP_next[step][States]==false)
			{
				SetPlayerCheckpoint
				(
					playerid,
					g_farm_CP_next[step][Xx],
					g_farm_CP_next[step][Yy],
					g_farm_CP_next[step][Zz],
					0.7,
					CP_TYPE_FARM_NEXT_4
				);
				AddInfo(playerid, pJob_State, +, 1);
			}
			else {
				SetInfo(playerid, pJob_State,0);
				DisablePlayerCheckpoint(playerid);
				SCM(playerid,COLOR_LIME,"Вы cобрали урожай! Теперь положите ящик с помидорами на склад.");
				SCM(playerid,COLOR_LIME,"На карте отмечено место, куда можно положить ящик.");
				SetPlayerCheckpoint(playerid,-1060.8601,-1195.1721,129.6661,1,CP_ACTION_TYPE_PUT_FARM);
				for(new i; i < 48; i++) DestroyObject(obj_f_3[i]);
			}
		}
	}
}
stock Action(playerid, message[], Float:radius=25.0, bool:bubble=true)
{
	if(bubble)
		SetPlayerChatBubble(playerid, message, 0xDD90FFFF, radius, 7000);
	new str[128];
	format(str, sizeof str, "%s %s", GN(playerid), message);
	SCM_I(playerid, str, 0xDD90FFFF, radius);
	return 1;
}
stock DoAction(playerid, message[], Float:radius=25.0, bool:bubble=true)
{
	if(bubble)
		SetPlayerChatBubble(playerid, message, 0xDD90FFFF, radius, 7000);
	new str[128];
	format(str, sizeof str, "%s (( %s ))", message,GN(playerid));
	SCM_I(playerid, str, 0xDD90FFFF, radius);
	return 1;
}
function: ShowPlayerHouseInfo(playerid, houseid)
{
	if(0 <= houseid <= g_house_loaded-1)
	{
		if(GetPlayerInHouse(playerid) == -1)
		{
			SetPlayerUseListitem(playerid, houseid);
			new fmt_str[160],string[356];
			new type = GetHouseData(houseid, H_TYPE);
			if(IsHouseOwned(houseid))
			{
				if(!GetHouseData(houseid, H_EVICTION))
				{
					format(fmt_str, sizeof fmt_str, "{"#cW"}Владелец:\t\t\t{"#cGold"}%s\n\n", GetHouseData(houseid, H_OWNER_NAME));
					strcat(string, fmt_str);
				}
				else
				{
					strcat(string, "{"#cW"}Владелец:\t\t\t{"#cGold"}Выселен\n\n");
				}
			}
			format(fmt_str, sizeof fmt_str, "{"#cW"}Тип:\t\t\t\t{"#cGold"}%s\n", GetHouseData(houseid, H_NAME));
			strcat(string, fmt_str);
			format(fmt_str, sizeof fmt_str, "{"#cW"}Номер дома:\t\t\t{"#cGold"}%d\n", houseid);
			strcat(string, fmt_str);
			if(!IsHouseOwned(houseid)) strcat(string, "\n");
			format(fmt_str, sizeof fmt_str, "{"#cW"}Количество комнат:\t\t{"#cGold"}%d\n", GetHouseTypeInfo(type, HT_ROOMS));
			strcat(string, fmt_str);
			format(fmt_str, sizeof fmt_str, "{"#cW"}Стоимость:\t\t\t{"#cGold"}%d$\n", GetHouseData(houseid, H_PRICE));
			strcat(string, fmt_str);
			format(fmt_str, sizeof fmt_str, "{"#cW"}Ежедневная квартплата:\t{"#cGold"}%d$", GetHouseData(houseid, H_RENT_PRICE));
			strcat(string, fmt_str);
			if(IsHouseOwned(houseid))
			{
				if(GetHouseData(houseid, H_IMPROVEMENTS) >= 4)
				{
					format(fmt_str, sizeof fmt_str, " {"#cGold"}(%d)", GetHouseData(houseid, H_RENT_PRICE) / 2);
					strcat(string, fmt_str);
				}
				SPD(playerid, dialog_enter, DIALOG_STYLE_MSGBOX, "{"#cGold"}Дом занят", string, "Войти", "Отмена");
			}
			else SPD(playerid, dialog_buy_house, DIALOG_STYLE_MSGBOX, "{33CC00}Дом свободен", string, "Купить", "Отмена");
		}
	}
	return 1;
}
stock UpdateHouse(houseid)
{
	if(GetHouseData(houseid, H_ENTER_PICKUP))
		DestroyPickup(GetHouseData(houseid, H_ENTER_PICKUP));
	if(IsValidDynamicMapIcon(GetHouseData(houseid, H_MAP_ICON)))
		DestroyDynamicMapIcon(GetHouseData(houseid, H_MAP_ICON));
	SetHouseData(houseid, H_ENTER_PICKUP, CreatePickup((IsHouseOwned(houseid) ? 1272 : 1273), 23, GetHouseData(houseid, H_POS_X), GetHouseData(houseid, H_POS_Y), GetHouseData(houseid, H_POS_Z), 0, PICKUP_ACTION_TYPE_HOUSE, houseid));
	SetHouseData(houseid, H_MAP_ICON, CreateDynamicMapIcon(GetHouseData(houseid, H_POS_X), GetHouseData(houseid, H_POS_Y), GetHouseData(houseid, H_POS_Z), (IsHouseOwned(houseid) ? 32 : 31), 0, 0, 0, -1, STREAMER_MAP_ICON_SD, MAPICON_LOCAL));
}
stock GetPlayerHouse(playerid, type = -1)
{
	new houseid = GetInfo(playerid, pHouseID);
	if(houseid != -1)
	{
		switch(type)
		{
			case HOUSE_TYPE_HOME:
			{
				if(GetInfo(playerid, pHouseType) == HOUSE_TYPE_HOME)
				{
					if(GetHouseData(houseid, H_OWNER_ID) == PI[playerid][pID]) return houseid;
				}
			}
			default:
				return houseid;
		}
	}
	return -1;
}
stock IsPlayerInRangeOfHouse(playerid, houseid, Float: radius = 10.0)
{
	new result;

	result = IsPlayerInRangeOfPoint(playerid, radius, GetHouseData(houseid, H_POS_X), GetHouseData(houseid, H_POS_Y), GetHouseData(houseid, H_POS_Z));

	return result;
}
stock GetElapsedTime(time, to_time, type = CONVERT_TIME_TO_HOURS)
{
	new result;

	switch(type)
	{
		case CONVERT_TIME_TO_MINUTES:
		{
			result = ((time - (time % 60)) - (to_time - (to_time % 60))) / 60;
		}
		case CONVERT_TIME_TO_HOURS:
		{
			result = ((time - (time % 3600)) - (to_time - (to_time % 3600))) / 3600;
		}
		case CONVERT_TIME_TO_DAYS:
		{
			result = ((time - (time % 86400)) - (to_time - (to_time % 86400))) / 86400;
		}
		default:
			result = -1;
	}
	return result;
}
stock ExitPlayerFromHouse(playerid, Float: radius = 3.0)
{
	new houseid = GetPlayerInHouse(playerid);
	if(houseid != -1)
	{
		new type = GetHouseData(houseid, H_TYPE);
		if(IsPlayerInRangeOfPoint(playerid, radius, GetHouseTypeInfo(type, HT_ENTER_POS_X), GetHouseTypeInfo(type, HT_ENTER_POS_Y), GetHouseTypeInfo(type, HT_ENTER_POS_Z)))
		{
			SetPlayerInHouse(playerid, -1);

			SetPlayerPosEx
			(
				playerid,
				GetHouseData(houseid, H_EXIT_POS_X),
				GetHouseData(houseid, H_EXIT_POS_Y),
				GetHouseData(houseid, H_EXIT_POS_Z),
				0,
				0,
				GetHouseData(houseid, H_EXIT_ANGLE)
			);
		}
		return 1;
	}
	return 0;
}
function: UpdateBusinessLabel(businessid)
{
	new fmt_str[164 + 1];
	switch(GetBusinessData(businessid, B_TYPE))
	{
	    case 1,4:
	        {
				if(!IsBusinessOwned(businessid))
				{
					format
					(
						fmt_str, sizeof fmt_str,
						"{FFA500}%s\n"\
						"{"#cW"}Стоимость: {"#cGold"}%d$\n"\
						"{"#cW"}Бизнес продаётся: /buybiz",
						GetBusinessData(businessid, B_NAME),
						GetBusinessData(businessid, B_PRICE)
					);
				}
				else
				{
					format
					(
					    fmt_str, sizeof fmt_str,
			            "{FFA500}%s\n"\
						"{"#cW"}Владелец: {"#cGold"}%s\n"\
						"{"#cW"}Стоимость: {"#cGold"}%d$\n "\
						"{"#cW"}Состояние: %s",
						GetBusinessData(businessid, B_NAME),
						GetBusinessData(businessid, B_OWNER_NAME),
						GetBusinessData(businessid, B_PRICE),
						GetBusinessData(businessid, B_LOCK_STATUS) > 0 ? "{FF6600}Закрыто" : "Открыто"
					);
				}
			}
   		case 2:
	        {
				if(!IsBusinessOwned(businessid))
				{
					format
					(
						fmt_str, sizeof fmt_str,
						"{FFA500}%s\n"\
						"{"#cW"}Стоимость: {"#cGold"}%d$\n"\
						"{"#cW"}Заправка продаётся: /buybiz",
						GetBusinessData(businessid, B_NAME),
						GetBusinessData(businessid, B_PRICE)
					);
				}
				else
				{
					format
					(
					    fmt_str, sizeof fmt_str,
			            "{FFA500}%s\n"\
						"{"#cW"}Владелец: {"#cGold"}%s\n"\
						"{"#cW"}Цена за 1 литр: {"#cGold"}%d$\n "\
						"{FFFFFF}Цена канистры: {FFA500}%d$\n"\
						"{"#cW"}Состояние: %s",
						GetBusinessData(businessid, B_NAME),
						GetBusinessData(businessid, B_OWNER_NAME),
						GetBusinessData(businessid, B_PROD_PRICE),
						GetBusinessData(businessid, B_PROD_PRICE)*15,
						GetBusinessData(businessid, B_LOCK_STATUS) > 0 ? "{FF6600}Закрыто" : "Открыто"
					);
				}
			}
	}
	UpdateDynamic3DTextLabelText(GetBusinessData(businessid, B_LABEL), 0xFFFF00FF, fmt_str);
}
function: LoadBusinesses()
{
	new Cache: result, rows,time = GetTickCount();
	result = mysql_query(dbHandle, "SELECT b.*, IFNULL(a.name, 'None') AS owner_name FROM business b LEFT JOIN users a ON a.id=b.owner_id", true);
	rows = cache_num_rows();
	if(rows > MAX_BUSINESS)
	{
		rows = MAX_BUSINESS;
		print("[Business]: DB rows > MAX_BUSINESS");
	}
	for(new idx; idx < rows; idx ++)
	{
		cache_get_value_name_int(idx,"id",g_business[idx][B_SQL_ID]);
		cache_get_value_name_int(idx,"owner_id",g_business[idx][B_OWNER_ID]);
        cache_get_value_name_int(idx,"improvements",g_business[idx][B_IMPROVEMENTS]);
        cache_get_value_name_int(idx,"products",g_business[idx][B_PRODS]);
        cache_get_value_name_int(idx,"prod_price",g_business[idx][B_PROD_PRICE]);
        cache_get_value_name_int(idx,"balance",g_business[idx][B_BALANCE]);
        cache_get_value_name_int(idx,"price",g_business[idx][B_PRICE]);
		cache_get_value_name_int(idx,"rent_price",g_business[idx][B_RENT_PRICE]);
        cache_get_value_name_int(idx,"type",g_business[idx][B_TYPE]);
       	switch(g_business[idx][B_TYPE])
		{
		    case 1: SetString(g_business[idx][B_NAME],"Магазин 24/7");
		    case 2: SetString(g_business[idx][B_NAME],"АЗС");
		    case 3: SetString(g_business[idx][B_NAME],"СТО");
		    case 4: SetString(g_business[idx][B_NAME],"Автосалон");
		    case 5: SetString(g_business[idx][B_NAME],"Магазин одежды");
		    case 6: SetString(g_business[idx][B_NAME],"Закусочная");
		    case 7: SetString(g_business[idx][B_NAME],"Бар");
		    case 8: SetString(g_business[idx][B_NAME],"Спортивный зал");
		}
        cache_get_value_name_int(idx,"interior",g_business[idx][B_INTERIOR]);
        cache_get_value_name_int(idx,"enter_price",g_business[idx][B_ENTER_PRICE]);
        cache_get_value_name_int(idx,"enter_music",g_business[idx][B_ENTER_MUSIC]);
        cache_get_value_name_int(idx,"lock",g_business[idx][B_LOCK_STATUS]);
        cache_get_value_name_float(idx,"x",g_business[idx][B_POS_X]);
        cache_get_value_name_float(idx,"y",g_business[idx][B_POS_Y]);
        cache_get_value_name_float(idx,"z",g_business[idx][B_POS_Z]);
        cache_get_value_name_float(idx,"exit_x",g_business[idx][B_EXIT_POS_X]);
        cache_get_value_name_float(idx,"exit_y",g_business[idx][B_EXIT_POS_Y]);
        cache_get_value_name_float(idx,"exit_z",g_business[idx][B_EXIT_POS_Z]);
        cache_get_value_name_float(idx,"exit_angle",g_business[idx][B_EXIT_ANGLE]);
        cache_get_value_name_int(idx,"eviction",g_business[idx][B_EVICTION]);
		cache_get_value_name(idx, "owner_name", g_business[idx][B_OWNER_NAME], MAX_PLAYER_NAME);
		// -------------------------

		SetBusinessData(idx, B_ORDER_ID, -1);
		SetBusinessData(idx, B_LABEL, CreateDynamic3DTextLabel(GetBusinessData(idx, B_NAME), 0xFFFF00FF, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z) + 1.0, 6.50));

		if(g_business[idx][B_TYPE] != 2) biz_area[idx] = CreateDynamicSphere(GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 3.0, 0, 0, -1);
		if(IsBusinessOwned(idx) && !strcmp(GetBusinessData(idx, B_OWNER_NAME), "None", true))
		{
			SetBusinessData(idx, B_OWNER_ID, 0);

			mysql_format(dbHandle, query, sizeof query, "UPDATE business SET owner_id=0,improvements=0 WHERE id=%d", GetBusinessData(idx, B_SQL_ID));
			mysql_tquery(dbHandle, query);
		}

		if(!IsBusinessOwned(idx))
		{
			SetBusinessData(idx, B_PRODS,		0);
			SetBusinessData(idx, B_PROD_PRICE, 	0);
			SetBusinessData(idx, B_LOCK_STATUS, false);

			SetBusinessData(idx, B_ENTER_MUSIC, 0);
			SetBusinessData(idx, B_ENTER_PRICE, 0);
		}
		CallLocalFunction("UpdateBusinessLabel", "i", idx);
		switch(g_business[idx][B_TYPE])
		{
			case 1: CreatePickup(19132, 23, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 0, PICKUP_ACTION_TYPE_BIZ_ENTER, idx);
			case 2:
				{
					CreatePickup(1650, 23, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 0, PICKUP_ACTION_TYPE_BIZ_ENTER, idx);
					CreateDynamicMapIcon(GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 56, 0, 0, 0, -1, STREAMER_MAP_ICON_SD, MAPICON_LOCAL);
				}
			case 4:
			    {
			        CreatePickup(19134, 23, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 0, PICKUP_ACTION_TYPE_BIZ_ENTER, idx);
			        CreateDynamicMapIcon(GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z), 55, 0, 0, 0, -1, STREAMER_MAP_ICON_SD, MAPICON_LOCAL);
			    }
		}
	}
	g_business_loaded = rows;
	cache_delete(result);
	for(new idx; idx < sizeof g_business_interiors; idx ++)
	{
		CreatePickup(19132, 23, GetBusinessInteriorInfo(idx, BT_EXIT_POS_X), GetBusinessInteriorInfo(idx, BT_EXIT_POS_Y), GetBusinessInteriorInfo(idx, BT_EXIT_POS_Z), -1, PICKUP_ACTION_TYPE_BIZ_EXIT, idx);

		switch(idx)
		{
			case BUSINESS_INTERIOR_SHOP_24_7:
			{
				CreateDynamic3DTextLabel
				(
					"{FFA500}Список товаров\nALT",
					-1,
					GetBusinessInteriorInfo(idx, BT_BUY_POS_X),
					GetBusinessInteriorInfo(idx, BT_BUY_POS_Y),
					GetBusinessInteriorInfo(idx, BT_BUY_POS_Z) + 0.8,
					8.0
				);
				CreatePickup(10270, 23, GetBusinessInteriorInfo(idx, BT_BUY_POS_X), GetBusinessInteriorInfo(idx, BT_BUY_POS_Y), GetBusinessInteriorInfo(idx, BT_BUY_POS_Z), -1, PICKUP_ACTION_TYPE_BIZ_SHOP_247, idx);
			}
		}
	}
	printf("[Бизнесы]: Бизнесов загружено: %d. Потрачено: <%d ms>.", g_business_loaded,GetTickCount()-time);
}
stock GetNearestBusiness(playerid, Float: dist = 10.0)
{
	if(dist == 0.0)
		dist = FLOAT_INFINITY;

	new businessid = -1;
	new Float: my_dist;

	for(new idx; idx < g_business_loaded; idx ++)
	{
		my_dist = GetPlayerDistanceFromPoint(playerid, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z));
		if(my_dist < dist)
		{
			dist = my_dist,
			businessid = idx;
		}
	}
	return businessid;
}
stock GetNearestFuelSt(playerid, Float: dist = 10.0)
{
	if(dist == 0.0)
		dist = FLOAT_INFINITY;

	new businessid = -1;
	new Float: my_dist;

	for(new idx; idx < g_business_loaded; idx ++)
	{
		if(GetBusinessData(idx, B_TYPE) != 2) continue;
		my_dist = GetPlayerDistanceFromPoint(playerid, GetBusinessData(idx, B_POS_X), GetBusinessData(idx, B_POS_Y), GetBusinessData(idx, B_POS_Z));
		if(my_dist < dist)
		{
			dist = my_dist,
			businessid = idx;
		}
	}
	return businessid;
}
stock BuyPlayerBusiness(playerid, businessid, bool: buy_from_owner = false, price = -1)
{
	if(!IsBusinessOwned(businessid) && PI[playerid][pBusinessID] == -1)
	{
		if(price <= 0)
			price = GetBusinessData(businessid, B_PRICE);
		if(PI[playerid][pCash] >= price)
		{
			format(query, sizeof query, "UPDATE users a, business b SET a.cash=%d,a.business=%d,b.owner_id=%d WHERE a.id=%d AND b.id=%d", PI[playerid][pCash]-price, businessid, PI[playerid][pID], PI[playerid][pID], GetBusinessData(businessid, B_SQL_ID));
			mysql_query(dbHandle, query, false);
			if(!mysql_errno())
			{
				SetInfo(playerid, pBusinessID, businessid);
				SetBusinessData(businessid, B_OWNER_ID, 		PI[playerid][pID]);
				SetBusinessData(businessid, B_IMPROVEMENTS, 	0);
				new time = gettime();
				new rent_time = (time - (time % 86400)) + 86400;

				if(!buy_from_owner)
				{
					SetBusinessData(businessid,	B_PRODS, 		200);
					SetBusinessData(businessid,	B_PROD_PRICE, 	5);

					SetBusinessData(businessid,	B_ENTER_MUSIC, 	0);
					SetBusinessData(businessid,	B_ENTER_PRICE, 	0);

					SetBusinessData(businessid,	B_RENT_DATE,	rent_time);
					SetBusinessData(businessid,	B_LOCK_STATUS,	false);
				}
				else
				{
					if(GetElapsedTime(GetBusinessData(businessid, B_RENT_DATE), time, CONVERT_TIME_TO_DAYS) <= 0)
					{
						SetBusinessData(businessid, B_RENT_DATE, rent_time);
					}
				}
				format(g_business[businessid][B_OWNER_NAME], 21, GN(playerid), 0);
				CallLocalFunction("UpdateBusinessLabel", "i", businessid);

				GiveMoney(playerid, -price);
				format(query, sizeof query, "UPDATE business SET improvements=0,products=%d,prod_price=%d,balance=%d,rent_time=%d,owner_id=%d,`lock`=%d WHERE id=%d LIMIT 1", GetBusinessData(businessid, B_PRODS), GetBusinessData(businessid, B_PROD_PRICE), GetBusinessData(businessid, B_BALANCE), GetBusinessData(businessid, B_RENT_DATE), GetBusinessData(businessid, B_OWNER_ID),GetBusinessData(businessid, B_LOCK_STATUS), GetBusinessData(businessid, B_SQL_ID));
				mysql_query(dbHandle, query, false);
				format(query, sizeof query, "UPDATE business_profit SET view=0 WHERE bid=%d AND view=1", GetBusinessData(businessid, B_SQL_ID));
				mysql_query(dbHandle, query, false);
				return 1;
			}
			SCM(playerid, 0xFF6600FF, "Ошибка сохранения, повторите попытку {FF0000}(GeSMT-ERR 21)");
			return 0;
		}
		return 0;
	}
	return -1;
}
stock EnterPlayerToBiz(playerid, businessid)
{
	if(GetPlayerInBiz(playerid) == -1)
	{
		new buffer = GetBusinessData(businessid, B_INTERIOR);

		SetPlayerPosEx
		(
			playerid,
			GetBusinessInteriorInfo(buffer, BT_ENTER_POS_X),
			GetBusinessInteriorInfo(buffer, BT_ENTER_POS_Y),
			GetBusinessInteriorInfo(buffer, BT_ENTER_POS_Z),
			businessid + 255,
			GetBusinessInteriorInfo(buffer, BT_ENTER_INTERIOR),
			GetBusinessInteriorInfo(buffer, BT_ENTER_ANGLE)
		);
		SetPlayerInBiz(playerid, businessid);
	}
	return 1;
}
function:Itter_OPDCInternal_adm_vehicles(playerid)
{
    Itter_Remove(adm_vehicles, playerid);
	return 1;
}
function: LoadGangZones()
{
	new idx;
	new Cache: result, rows,
	Float:min_x,Float:min_y,Float:max_y,Float:max_x,fract;

	result = mysql_query(dbHandle, "SELECT * FROM `gangzones`");
	rows = cache_num_rows();

	if(rows > MAX_GZ)
	{
		rows = MAX_GZ;
		print("[GangZones]: DB rows > MAX_GZ");
	}

	for(idx = 0; idx < rows; idx ++)
	{
	    cache_get_value_name_float(idx, "min_x", min_x);
		SetGangZoneData(idx, GZ_MIN_X,	min_x);
		cache_get_value_name_float(idx, "min_y", min_y);
		SetGangZoneData(idx, GZ_MIN_Y,	min_y);
		cache_get_value_name_float(idx, "max_x",max_x);
		SetGangZoneData(idx, GZ_MAX_X,	max_x);
		cache_get_value_name_float(idx, "max_y",max_y);
		SetGangZoneData(idx, GZ_MAX_Y,	max_y);
        cache_get_value_name_int(idx, "fraction",fract);
		SetGangZoneData(idx, GZ_GANG,	fract);

		// ----------------------------------------------------------------------------------
		g_gang_zone[idx][GZ_ZONE] = GangZoneCreate
		(
			GetGangZoneData(idx, GZ_MIN_X),
			GetGangZoneData(idx, GZ_MIN_Y),
			GetGangZoneData(idx, GZ_MAX_X),
			GetGangZoneData(idx, GZ_MAX_Y)
		);

		// ----------------------------------------------------------------------------------
		g_gang_zone[idx][GZ_AREA] = CreateDynamicRectangle
		(
			GetGangZoneData(idx, GZ_MIN_X),
			GetGangZoneData(idx, GZ_MIN_Y),
			GetGangZoneData(idx, GZ_MAX_X),
			GetGangZoneData(idx, GZ_MAX_Y)
		);
	}

	g_gang_zones_loaded = rows;
	cache_delete(result);

	printf("[GangZones]: Гангзон загружено: %d", g_gang_zones_loaded);
}
stock ShowPlayerDialogOfRealty(playerid,r_id)
{
	if(PL[playerid])
	{
	    new string[200],time = gettime();
		switch(r_id)
		{
  			case 1:
			  	{
					if(PI[playerid][pFarmID] == -1) return BankMenu(playerid);
					format(string,sizeof(string),"{FFFFFF}Ферма:\t{FFA500}%s\n{FFFFFF}Владелец:\t%s\nНомер фермы:\t%d\nОплачено на:\t%d/30 дней\n\nДействующая цена за 1 день:\t{FFA500}1000${FFFFFF}\n\nНа сколько дней вы хотите оплатить аренду?",FI[f_name],FI[f_owner_name],FI[f_owner_id],GetElapsedTime(FI[f_renttime],time,CONVERT_TIME_TO_DAYS));
				}
	    }
	    SetPVarInt(playerid,"r_id",r_id);
	    SPD(playerid,0,DIALOG_STYLE_INPUT,"{FFA500}Оплата недвижимости",string,"Далее","Назад");
	}
	return 1;
}
stock BankMenu(playerid) return SPD(playerid,dialog_bank,2,"{FFA500}Банк","{FFA500}1.{ffffff} Информация о счёте\n{FFA500}2.{ffffff} Пополнить счёт\n{FFA500}3.{ffffff} Снять со счёта\n{FFA500}4.{ffffff} Оплатить недвижимость\n{FFA500}5.{FFFFFF} Управление счетом бизнесов","Выбрать","Закрыть");
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
stock IsPlayerInBuyPosBiz(playerid, businessid, type, Float: radius = 1.0)
{
	if(GetBusinessData(businessid, B_TYPE) == type)
	{
		new interior = GetBusinessData(businessid, B_INTERIOR);
		if(IsPlayerInRangeOfPoint(playerid, radius, GetBusinessInteriorInfo(interior, BT_BUY_POS_X), GetBusinessInteriorInfo(interior, BT_BUY_POS_Y), GetBusinessInteriorInfo(interior, BT_BUY_POS_Z)))
		{
			SPD(playerid,dialog_buy,2,"{FFA500}Список товаров","{FFA500}1.{FFFFFF} Фотоаппарат [10 кадров - 50$]\n{FFA500}2.{FFFFFF} Цветы [20$]\n{FFA500}3.{FFFFFF} Рем. комплект [1 шт. - 150$]\n{FFA500}4.{FFFFFF} Телефон [530$]\n{FFA500}5.{FFFFFF} SIM-карта [20$]\n{FFA500}6.{FFFFFF} Аптечка [1 шт. - 30$]\n{FFA500}7.{FFFFFF} Маска [1 шт. - 15$]","Выбрать","Закрыть");
		}
	}
}
stock LoadGangZone()
{
	g_zone[0] = GangZoneCreate(-3000, 2062.999969482422, 3000, 2999.999969482422);
	g_zone[1] = GangZoneCreate(-1893.9090270996094, 2036, 2980.0909729003906, 2066);
	g_zone[2] = GangZoneCreate(-1881.9999694824219, 2017, 988.0000305175781, 2039);
	g_zone[3] = GangZoneCreate(-1881.9999694824219, 1996.999984741211, 988.0000305175781, 2018.999984741211);
	g_zone[4] = GangZoneCreate(-1858.9999694824219, 1958.9999694824219, 1012.0000305175781, 1978.9999694824219);
	g_zone[5] = GangZoneCreate(-1868.9999694824219, 1976.9999694824219, 1002.0000305175781, 1998.9999694824219);
	g_zone[6] = GangZoneCreate(-1852.9999694824219, 1932.9999694824219, 1018.0000305175781, 1959.9999694824219);
	g_zone[7] = GangZoneCreate(-1841.9999694824219, 1912.9999694824219, 1028.0000305175781, 1936.9999694824219);
	g_zone[8] = GangZoneCreate(-1832.9999694824219, 1891.9999694824219, 1038.0000305175781, 1917.9999694824219);
	g_zone[9] = GangZoneCreate(-1826.9999694824219, 1871.9999694824219, 1045.0000305175781, 1894.9999694824219);
	g_zone[10] = GangZoneCreate(-1818.9999694824219, 1852.9999694824219, 1052.0000305175781, 1874.9999694824219);
	g_zone[11] = GangZoneCreate(-1812.9999694824219, 1838.9999694824219, 1058.0000305175781, 1857.9999694824219);
	g_zone[12] = GangZoneCreate(-1813, 1816.9999694824219, 1058, 1842.9999694824219);
	g_zone[13] = GangZoneCreate(-1797.9999694824219, 1796.9999694824219, 1072.0000305175781, 1818.9999694824219);
	g_zone[14] = GangZoneCreate(-1783.9999694824219, 1772.9999694824219, 1087.0000305175781, 1799.9999694824219);
	g_zone[15] = GangZoneCreate(-1774.9999694824219, 1755.9999694824219, 1096.0000305175781, 1776.9999694824219);
	g_zone[16] = GangZoneCreate(-1754.9999389648438, 1732.9999694824219, 1116.0000610351562, 1758.9999694824219);
	g_zone[17] = GangZoneCreate(-1677.9999694824219, 1716, 1192.0000305175781, 1738);
	g_zone[18] = GangZoneCreate(-1653, 1693, 1218, 1719);
	g_zone[19] = GangZoneCreate(-1620, 1674, 1251, 1696);
	g_zone[20] = GangZoneCreate(-1581, 1653, 1290, 1677);
	g_zone[21] = GangZoneCreate(-1523.9999389648438, 1637, 1347.0000610351562, 1658);
	g_zone[22] = GangZoneCreate(-1492.9999389648438, 1618, 1378.0000610351562, 1639);
	g_zone[23] = GangZoneCreate(-1248.9999694824219, 1598.000015258789, 1622.0000305175781, 1619.000015258789);
	g_zone[24] = GangZoneCreate(-1232.9999389648438, 1576, 1638.0000610351562, 1599);
	g_zone[25] = GangZoneCreate(-1198.9999389648438, 1558, 1672.0000610351562, 1579);
	g_zone[26] = GangZoneCreate(-1184.9999389648438, 1538, 1686.0000610351562, 1559);
	g_zone[27] = GangZoneCreate(-1173.9999389648438, 1518, 1697.0000610351562, 1539);
	g_zone[28] = GangZoneCreate(-1173.9999389648438, 1497, 1697.0000610351562, 1519);
	g_zone[29] = GangZoneCreate(-1173.9999389648438, 1480, 1697.0000610351562, 1499);
	g_zone[30] = GangZoneCreate(-1173.9999389648438, 1453.9999084472656, 1696.0000610351562, 1479.9999084472656);
	g_zone[31] = GangZoneCreate(-1163.9999389648438, 1440, 1707.0000610351562, 1459);
	g_zone[32] = GangZoneCreate(-1163.9999389648438, 1416.9999084472656, 1707.0000610351562, 1439.9999084472656);
	g_zone[33] = GangZoneCreate(-1155.9999389648438, 1399.9999084472656, 1715.0000610351562, 1418.9999084472656);
	g_zone[34] = GangZoneCreate(-1155.9999389648438, 1375.9999084472656, 1714.0000610351562, 1399.9999084472656);
	g_zone[35] = GangZoneCreate(-1148.9999389648438, 1360.9999084472656, 1722.0000610351562, 1379.9999084472656);
	g_zone[36] = GangZoneCreate(-1137.9999389648438, 1242.9999084472656, 1733.0000610351562, 1360.9999084472656);
	g_zone[37] = GangZoneCreate(-1137.9999389648438, 1223.9999084472656, 1733.0000610351562, 1246.9999084472656);
	g_zone[38] = GangZoneCreate(-1144.9999389648438, 1192.9999084472656, 1726.0000610351562, 1226.9999084472656);
	g_zone[39] = GangZoneCreate(-1151.9999389648438, 1164.9999084472656, 1719.0000610351562, 1192.9999084472656);
	g_zone[40] = GangZoneCreate(-1157.9999389648438, 1133.9999084472656, 1713.0000610351562, 1164.9999084472656);
	g_zone[41] = GangZoneCreate(-1157.9999389648438, 1112.9999084472656, 1713.0000610351562, 1133.9999084472656);
	g_zone[42] = GangZoneCreate(-1148.9999389648438, 1091.9999084472656, 1722.0000610351562, 1112.9999084472656);
	g_zone[43] = GangZoneCreate(-1126.9999389648438, 1070.9999084472656, 1744.0000610351562, 1091.9999084472656);
	g_zone[44] = GangZoneCreate(-1008.9999389648438, 1051, 1862.0000610351562, 1072);
	g_zone[45] = GangZoneCreate(-1002.9999389648438, 1030, 1868.0000610351562, 1051);
	g_zone[46] = GangZoneCreate(-1002.9999389648438, 1010, 1868.0000610351562, 1031);
	g_zone[47] = GangZoneCreate(-1002.9999389648438, 989, 1868.0000610351562, 1010);
	g_zone[48] = GangZoneCreate(-1002.9999389648438, 969, 1868.0000610351562, 990);
	g_zone[49] = GangZoneCreate(-994.9999389648438, 950.9998779296875, 1876.0000610351562, 971.9998779296875);
	g_zone[50] = GangZoneCreate(-966.9999389648438, 821.9998779296875, 1904.0000610351562, 951.9998779296875);
	g_zone[51] = GangZoneCreate(-948.9999389648438, 800.9999237060547, 1922.0000610351562, 821.9999237060547);
	g_zone[52] = GangZoneCreate(-942.9999389648438, 780.9999084472656, 1928.0000610351562, 801.9999084472656);
	g_zone[53] = GangZoneCreate(-936.9999389648438, 759.9999084472656, 1934.0000610351562, 780.9999084472656);
	g_zone[54] = GangZoneCreate(-929.9999389648438, 738.9999084472656, 1941.0000610351562, 759.9999084472656);
	g_zone[55] = GangZoneCreate(-915.9999389648438, 717.9999084472656, 1955.0000610351562, 738.9999084472656);
	g_zone[56] = GangZoneCreate(-904.9999389648438, 696.9999084472656, 1966.0000610351562, 717.9999084472656);
	g_zone[57] = GangZoneCreate(-877.9999389648438, 675.9999084472656, 1993.0000610351562, 696.9999084472656);
	g_zone[58] = GangZoneCreate(-859.9999389648438, 654.9999084472656, 2011.0000610351562, 675.9999084472656);
	g_zone[59] = GangZoneCreate(-832.9999389648438, 634.9999084472656, 2038.0000610351562, 655.9999084472656);
	g_zone[60] = GangZoneCreate(-780.9999389648438, -269.0000915527344, 2089.0000610351562, 635.9999084472656);
	g_zone[61] = GangZoneCreate(102.00006103515625, -2133.0001373291016, 3000.0001068115234, -274.00013732910156);
	g_zone[62] = GangZoneCreate(967.8000030517578, -288, 2999.800003051758, 2081);
	g_zone[63] = GangZoneCreate(-820, 197, 2051, 218);
	g_zone[64] = GangZoneCreate(-835, 176, 2036, 197);
	g_zone[65] = GangZoneCreate(-846, 155, 2025, 176);
	g_zone[66] = GangZoneCreate(-858, 134, 2013, 155);
	g_zone[67] = GangZoneCreate(-873, 113, 1998, 134);
	g_zone[68] = GangZoneCreate(-888, 92, 1983, 113);
	g_zone[69] = GangZoneCreate(-903, 71, 1968, 92);
	g_zone[70] = GangZoneCreate(-911, 50, 1960, 71);
	g_zone[71] = GangZoneCreate(-921, 29, 1950, 50);
	g_zone[72] = GangZoneCreate(-929, 8, 1942, 29);
	g_zone[73] = GangZoneCreate(-935, -13, 1936, 8);
	g_zone[74] = GangZoneCreate(-942, -34, 1929, -13);
	g_zone[75] = GangZoneCreate(-942, -55, 1929, -34);
	g_zone[76] = GangZoneCreate(-942, -76, 1929, -55);
	g_zone[77] = GangZoneCreate(-949, -97, 1922, -76);
	g_zone[78] = GangZoneCreate(-991, -118, 1880, -97);
	g_zone[79] = GangZoneCreate(-1013, -139, 1858, -118);
	g_zone[80] = GangZoneCreate(-1021, -160, 1850, -139);
	g_zone[81] = GangZoneCreate(-1021, -181, 1850, -160);
	g_zone[82] = GangZoneCreate(-1015, -202, 1856, -181);
	g_zone[83] = GangZoneCreate(-1008, -223, 1863, -202);
	g_zone[84] = GangZoneCreate(-1002, -244, 1869, -223);
	g_zone[85] = GangZoneCreate(-1002, -265, 1869, -244);
	g_zone[86] = GangZoneCreate(-990, -291, 1881, -265);
	g_zone[87] = GangZoneCreate(-937, -309, 1934, -288);
	g_zone[88] = GangZoneCreate(-518, -330, 2353, -309);
	g_zone[89] = GangZoneCreate(-297, -351, 2574, -330);
	g_zone[90] = GangZoneCreate(-268, -373, 2603, -351);
	g_zone[91] = GangZoneCreate(-250, -394, 2621, -373);
	g_zone[92] = GangZoneCreate(-234, -415, 2637, -394);
	g_zone[93] = GangZoneCreate(-185, -436, 2686, -415);
	g_zone[94] = GangZoneCreate(-169, -457, 2702, -436);
	g_zone[95] = GangZoneCreate(-161, -478, 2710, -457);
	g_zone[96] = GangZoneCreate(-138, -520, 2733, -499);
	g_zone[97] = GangZoneCreate(-150, -499, 2721, -478);
	g_zone[98] = GangZoneCreate(-123, -541, 2748, -520);
	g_zone[99] = GangZoneCreate(-108, -562, 2763, -541);
	g_zone[100] = GangZoneCreate(-97, -583, 2774, -562);
	g_zone[101] = GangZoneCreate(-87, -604, 2784, -583);
	g_zone[102] = GangZoneCreate(-43, -625, 2828, -604);
	g_zone[103] = GangZoneCreate(-71, -646, 2800, -625);
	g_zone[104] = GangZoneCreate(-93, -667, 2778, -646);
	g_zone[105] = GangZoneCreate(-100, -688, 2771, -667);
	g_zone[106] = GangZoneCreate(-108, -709, 2763, -688);
	g_zone[107] = GangZoneCreate(-117, -730, 2754, -709);
	g_zone[108] = GangZoneCreate(-129, -751, 2742, -730);
	g_zone[109] = GangZoneCreate(-141, -772, 2730, -751);
	g_zone[110] = GangZoneCreate(-149, -793, 2722, -772);
	g_zone[111] = GangZoneCreate(-157, -814, 2714, -793);
	g_zone[112] = GangZoneCreate(-157, -835, 2714, -814);
	g_zone[113] = GangZoneCreate(-143, -856, 2728, -835);
	g_zone[114] = GangZoneCreate(-120, -877, 2751, -856);
	g_zone[115] = GangZoneCreate(-104, -898, 2767, -877);
	g_zone[116] = GangZoneCreate(-73, -908, 2798, -898);
	g_zone[117] = GangZoneCreate(86, -968, 2957, -947);
	g_zone[118] = GangZoneCreate(78, -989, 2949, -968);
	g_zone[119] = GangZoneCreate(69, -1010, 2940, -989);
	g_zone[120] = GangZoneCreate(69, -1031, 2940, -1010);
	g_zone[121] = GangZoneCreate(69, -1052, 2940, -1031);
	g_zone[122] = GangZoneCreate(69, -1073, 2940, -1052);
	g_zone[123] = GangZoneCreate(69, -1094, 2940, -1073);
	g_zone[124] = GangZoneCreate(69, -1123, 2940, -1094);
	g_zone[125] = GangZoneCreate(77, -1229, 2948, -1200);
	g_zone[126] = GangZoneCreate(63, -1258, 2934, -1229);
	g_zone[127] = GangZoneCreate(63, -1287, 2934, -1258);
	g_zone[128] = GangZoneCreate(63, -1316, 2934, -1287);
	g_zone[129] = GangZoneCreate(63, -1338, 2934, -1309);
	g_zone[130] = GangZoneCreate(63, -1367, 2934, -1338);
	g_zone[131] = GangZoneCreate(63, -1396, 2934, -1367);
	g_zone[132] = GangZoneCreate(63, -1425, 2934, -1396);
	g_zone[133] = GangZoneCreate(63, -1454, 2934, -1425);
	g_zone[134] = GangZoneCreate(63, -1483, 2934, -1454);
	g_zone[135] = GangZoneCreate(63, -1512, 2934, -1483);
	g_zone[136] = GangZoneCreate(63, -1541, 2934, -1512);
	g_zone[137] = GangZoneCreate(63, -1570, 2934, -1541);
	g_zone[138] = GangZoneCreate(69, -1599, 2940, -1570);
	g_zone[139] = GangZoneCreate(75, -1628, 2946, -1599);
	g_zone[140] = GangZoneCreate(75, -1657, 2946, -1628);
	g_zone[141] = GangZoneCreate(84, -1744, 2955, -1715);
	g_zone[142] = GangZoneCreate(75, -1686, 2946, -1657);
	g_zone[143] = GangZoneCreate(84, -1715, 2955, -1686);
	g_zone[144] = GangZoneCreate(92, -1773, 2963, -1744);
	g_zone[145] = GangZoneCreate(1230.9999542236328, -3000, 3002.0313873291016, -2123);
	g_zone[146] = GangZoneCreate(932.9749755859375, -2165.0001220703125, 1386.9749755859375, -2133.0001220703125);
	g_zone[147] = GangZoneCreate(940.9749755859375, -2197.0001220703125, 1394.9749755859375, -2165.0001220703125);
	g_zone[148] = GangZoneCreate(960.96875, -2229, 1414.96875, -2197);
	g_zone[149] = GangZoneCreate(979.96875, -2261, 1433.96875, -2229);
	g_zone[150] = GangZoneCreate(979.96875, -2293, 1433.96875, -2261);
	g_zone[151] = GangZoneCreate(979.96875, -2325, 1433.96875, -2293);
	g_zone[152] = GangZoneCreate(989.96875, -2357, 1443.96875, -2325);
	g_zone[153] = GangZoneCreate(1024.96875, -2389, 1478.96875, -2357);
	g_zone[154] = GangZoneCreate(1057.96875, -2421, 1511.96875, -2389);
	g_zone[155] = GangZoneCreate(1096.96875, -2453, 1550.96875, -2421);
	g_zone[156] = GangZoneCreate(1140.96875, -2485, 1594.96875, -2453);
	g_zone[157] = GangZoneCreate(1209.96875, -2509, 1663.96875, -2485);
	g_zone[158] = GangZoneCreate(-804.0000457763672, 217.9998779296875, 2066.999954223633, 238.9998779296875);
	g_zone[159] = GangZoneCreate(-791.0000457763672, 238.9998779296875, 2079.999954223633, 259.9998779296875);
	/*g_b_zone[0] = GangZoneCreate(-2098, -2570, -2024, -2498);
	g_b_zone[1] = GangZoneCreate(-2259, -2579, -2098, -2406);
	g_b_zone[2] = GangZoneCreate(-2806, -207, -2707, -73);
	g_b_zone[3] = GangZoneCreate(-2707, -207, -2607, -73);
	g_b_zone[4] = GangZoneCreate(-2806, -73, -2706, 40);
	g_b_zone[5] = GangZoneCreate(-2806, 40, -2706, 154);
	g_b_zone[6] = GangZoneCreate(-2706, 43, -2606, 154);
	g_b_zone[7] = GangZoneCreate(-2806, 154, -2706, 279);
	g_b_zone[8] = GangZoneCreate(-2869, 1018, -2764, 1186);
	g_b_zone[9] = GangZoneCreate(-2600, 919, -2532, 998);
	g_b_zone[10] = GangZoneCreate(-2743, 913, -2599, 998);
	g_b_zone[11] = GangZoneCreate(-2745, 814, -2611, 882);
	g_b_zone[12] = GangZoneCreate(-2600, 813, -2531, 899);
	g_b_zone[13] = GangZoneCreate(-2131.199996948242, 884, -2010.1999969482422, 1044);
	g_b_zone[14] = GangZoneCreate(-2201.199996948242, -283, -2101.199996948242, -197);
	g_b_zone[15] = GangZoneCreate(-2242.199996948242, -2406, -2071.199996948242, -2218);
	g_b_zone[16] = GangZoneCreate(-2497, -204, -2431, -77);
	g_b_zone[17] = GangZoneCreate(-2742, 715, -2614, 805);
	g_b_zone[18] = GangZoneCreate(-2518, 716, -2396, 802);
	g_b_zone[19] = GangZoneCreate(-2517, 915, -2397, 1085);
	g_b_zone[20] = GangZoneCreate(-2375, 966, -2276, 1055);
	g_b_zone[22] = GangZoneCreate(-2588, 1084, -2342, 1204);
	g_b_zone[23] = GangZoneCreate(-2969, 935, -2869, 1186);
	g_b_zone[24] = GangZoneCreate(-2869, 636, -2764, 1018);*/
	//g_b_zone[21] = GangZoneCreate(-2503, 1204, -2307, 1365);
	//g_b_zone[22] = GangZoneCreate(-2588, 1084, -2342, 1204);

}
stock Load3DText()
{
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, 1414.3397,-20.8316,3001.4951,5.0,1,1);
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, 1404.5094,-34.9383,3001.5098,5.0,1,1);
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, 1397.7651,-52.3436,3001.4951,5.0,1,1);
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD, -1060.2244,-1206.1318,129.2188,5.0,0);
	Create3DTextLabel("{FFA500}ALT",0x00FFFFDD,-1068.0856,-1211.5553,129.7813,5.0,0);
}
stock UpdateLabel()
{
	new text[250];
	format(text,sizeof text, "{FFa500}Состояние склада\nМатериалы: %d\nПатроны 9mm: %d шт.\nПатроны 7,62mm: %d шт.\nПатроны 8,61mm: %d шт.\nКорпус пистолета: %d шт.\nКорпус винтовок: %d шт.\n\nALT",PW[army_mats],PW[army_ammo1],PW[army_ammo3],PW[army_ammo4],PW[army_body1],PW[army_body4]);
 	Update3DTextLabelText(frac_gun[4], 0x79cb64FF, text);
}
function: timer()
{
	new text[100],h,m,s;
	gettime(h,m,s);
	format(text, sizeof text, "{FFA500}Состояние склада\nПродукции: %d", PW[factory]);
 	UpdateDynamic3DTextLabelText(z_factory, 0x79cb64FF, text);
 	UpdateLabel();
 	if(FI[f_field_stats] == 100)
 	{
 	    FI[f_field_stats_2]++;
 	    if(FI[f_field_stats_2] == 100)
 	    {
 	        FI[f_field_stats_2] = 0.0;
 	        FI[f_field_stats] = 0;
 	        FI[f_field_stats_3] = 100;
 	        SCM_J(1,COLOR_BLUE,"[J] Урожай созрел! Чтобы собрать - возьмите со склада грабли.");
 	    }
 	}
	if(g_capture[C_STATUS] && g_capture[C_TIME] > 0)
	{
		-- g_capture[C_TIME];

		UpdateCaptureTextDraw();

		if(g_capture[C_TIME] == 0)
			EndCapture();
	}
 	foreach(new i : Player) p_z_timer(i);
 	if(server_gmx)
 	{
 	    server_gmx--;
 	    switch(server_gmx)
 	    {
 	        case 0: GameModeExit();
			case 3:
				{
					foreach(new i : Player) SaveAccounts(i);
					SaveFarmInfo();
				}
 	        case 10:
          		{
 	                SendClientMessageToAll(COLOR_YELLOW,"До рестарта сервера осталось 10 секунд.");
           		}
 	        case 30:
 	            {
 	                SendClientMessageToAll(COLOR_YELLOW,"До рестарта сервера осталось 30 секунд.");
 	            }
 	        case 60:
 	            {
 	                SendClientMessageToAll(COLOR_YELLOW,"До рестарта сервера осталась 1 минута.");
 	            }
 	    }
 	}
   	if(m == 0 && s >= 0 && s <= 1) PayDay();
   	if(m >= 57 && m <=59) paydays = 1;
	return 1;
}
stock p_z_timer(playerid)
{
	if(PL[playerid])
	{
		AddInfo(playerid, pAFK_Time, +, 1);
		if(IsPlayerAFK(playerid))
		{
		    new fmt_str[50];
			new afk_minutes = ConvertUnixTime(GetPlayerAFK(playerid), CONVERT_TIME_TO_MINUTES);
			new afk_seconds = ConvertUnixTime(GetPlayerAFK(playerid));
			if(afk_minutes > 0)
			{
					format(fmt_str, sizeof fmt_str, "{66CC33}AFK %d:%02d", afk_minutes, afk_seconds);
			}
			else format(fmt_str, sizeof fmt_str, "{66CC33}AFK %d сек", afk_seconds);
			SetPlayerChatBubble(playerid, fmt_str, 0xFF0000FF, 7.0, 1500);
		}
		PI[playerid][pOnlineDay]++;
		if(GetInfo(playerid,pTazered))
		{
  			if(PI[playerid][pTazerTime] <= 0)
			{
   				TogglePlayerControllable(playerid, 1);
			    SetInfo(playerid,pTazered, 0);
				SetInfo(playerid,pTazerTime, 0);
			}
			else PI[playerid][pTazerTime]--;
		}
		if(IsPlayerDriver(playerid))
		{
		    new vehicleid = GetPlayerVehicleID(playerid);
			if(Engine[vehicleid])
			{
				if(Fuel[vehicleid] <= 0.9)
				{
				    Engine[vehicleid] = false;
				    SetVehicleParam(vehicleid, V_ENGINE, false);
					GameTextForPlayer(playerid, "~r~no fuel", 4000, 1);
				}
				else Fuel[vehicleid] -= 0.02;
			}
		}
		if(GetInfo(playerid, pMute) > 0)
		{
			AddInfo(playerid, pMute, -, 1);
			if(GetInfo(playerid, pMute) <= 0)
				SCM(playerid, COLOR_LIME, "Доступ для чата снова открыт!");
		}
	}
}
function: LoadFractionsRangName()
{
	new idx;
	new Cache: result, rows;

	result = mysql_query(dbHandle, "SELECT * FROM `fraction_ranks`");
	rows = cache_num_rows();

	for(idx = 1; idx <= rows; idx ++)
	{
	    format(g_fraction_rank[idx -1][0], 20, "%s", "Отсутствует");
		cache_get_value_name(idx -1, "rang", g_fraction_rank[idx][1], 20);
		cache_get_value_name(idx -1, "rang1", g_fraction_rank[idx][2], 20);
		cache_get_value_name(idx -1, "rang2", g_fraction_rank[idx][3], 20);
		cache_get_value_name(idx -1, "rang3", g_fraction_rank[idx][4], 20);
		cache_get_value_name(idx -1, "rang4", g_fraction_rank[idx][5], 20);
		cache_get_value_name(idx -1, "rang5", g_fraction_rank[idx][6], 20);
		cache_get_value_name(idx -1, "rang6", g_fraction_rank[idx][7], 20);
		cache_get_value_name(idx -1, "rang7", g_fraction_rank[idx][8], 20);
		cache_get_value_name(idx -1, "rang8", g_fraction_rank[idx][9], 20);
		cache_get_value_name(idx -1, "rang9", g_fraction_rank[idx][10], 20);
	}

	cache_delete(result);
}
function: LoadFractionsPay()
{
	new idx;
	new Cache: result, rows;

	result = mysql_query(dbHandle, "SELECT * FROM `fraction_pay`");
	rows = cache_num_rows();

	for(idx = 1; idx <= rows; idx ++)
	{
		cache_get_value_name_int(idx - 1, "rang", g_fraction_pay[idx][1]);
		cache_get_value_name_int(idx - 1, "rang1", g_fraction_pay[idx][2]);
		cache_get_value_name_int(idx - 1, "rang2", g_fraction_pay[idx][3]);
		cache_get_value_name_int(idx - 1, "rang3", g_fraction_pay[idx][4]);
		cache_get_value_name_int(idx - 1, "rang4", g_fraction_pay[idx][5]);
		cache_get_value_name_int(idx - 1, "rang5", g_fraction_pay[idx][6]);
		cache_get_value_name_int(idx - 1, "rang6", g_fraction_pay[idx][7]);
		cache_get_value_name_int(idx - 1, "rang7", g_fraction_pay[idx][8]);
		cache_get_value_name_int(idx - 1, "rang8", g_fraction_pay[idx][9]);
	 	g_fraction_pay[idx][10] = 25000;
	}

	cache_delete(result);
}
function: LoadFractionsGun()
{
	new idx;
	new Cache: result, rows;

	result = mysql_query(dbHandle, "SELECT * FROM `fraction_gun`");
	rows = cache_num_rows();

	for(idx = 2; idx <= rows; idx ++)
	{
		cache_get_value_name_int(idx - 1, "9mm", g_fraction_gun[idx][1]);
		cache_get_value_name_int(idx - 1, "9mm_", g_fraction_gun[idx][2]);
		cache_get_value_name_int(idx - 1, "uzi", g_fraction_gun[idx][3]);
		cache_get_value_name_int(idx - 1, "mp5", g_fraction_gun[idx][4]);
		cache_get_value_name_int(idx - 1, "tec9", g_fraction_gun[idx][5]);
		cache_get_value_name_int(idx - 1, "drob", g_fraction_gun[idx][6]);
		cache_get_value_name_int(idx - 1, "obr", g_fraction_gun[idx][7]);
		cache_get_value_name_int(idx - 1, "skr_drob", g_fraction_gun[idx][8]);
		cache_get_value_name_int(idx - 1, "ak", g_fraction_gun[idx][9]);
	 	cache_get_value_name_int(idx - 1, "m4", g_fraction_gun[idx][10]);
	 	cache_get_value_name_int(idx - 1, "rifle", g_fraction_gun[idx][11]);
	 	cache_get_value_name_int(idx - 1, "sn_rifle", g_fraction_gun[idx][12]);
	}
	cache_delete(result);
}
function:LoadFarmInfo()
{
	new Cache: result, rows,time = GetTickCount();
	result = mysql_query(dbHandle, "SELECT f.*, IFNULL(u.name, 'None') f_owner_name FROM farm f LEFT JOIN users u ON u.id=f.f_owner_id", true);
	rows = cache_num_rows();
	if(rows)
	{
	    cache_get_value_name_int(0,"f_id",FI[f_id]);
	    cache_get_value_name_int(0,"f_owner_id",FI[f_owner_id]);
	    cache_get_value_name(0,"f_name",FI[f_name],30);
		cache_get_value_name_int(0,"f_bank",FI[f_bank]);
		cache_get_value_name_int(0,"f_sdl",FI[f_sdl]);
		cache_get_value_name_int(0,"f_tools",FI[f_tools]);
		cache_get_value_name_int(0,"f_water",FI[f_water]);
		cache_get_value_name_int(0,"f_renttime",FI[f_renttime]);
		cache_get_value_name_int(0,"f_price",FI[f_price]);
		cache_get_value_name_int(0,"f_apple",FI[f_apple]);
		cache_get_value_name_int(0,"f_orange",FI[f_orange]);
		cache_get_value_name_int(0,"f_flax",FI[f_flax]);
		cache_get_value_name_int(0,"f_millet",FI[f_millet]);
		cache_get_value_name_int(0,"f_cotton",FI[f_cotton]);
		cache_get_value_name_int(0,"f_corn",FI[f_corn]);
		cache_get_value_name_int(0,"f_tomato",FI[f_tomato]);
		cache_get_value_name(0,"f_owner_name",FI[f_owner_name],MAX_PLAYER_NAME);
		if(IsFarmOwned() && !strcmp(GetFarmInfo(f_owner_name), "None", true))
		{
			SetFarmInfo(f_owner_id, 0);
			mysql_tquery(dbHandle, "UPDATE farm SET f_owner_id=0");
		}
		FI[f_text][0] = CreateDynamic3DTextLabel("Склад фермы",0xFFFFA500,-1061.6105,-1195.4647,129.8281,10.0);
		FI[f_text][1] = CreateDynamic3DTextLabel("ALT",0xFFFFA500,-1073.1987,-1203.2684,129.2188,10.0);
		FI[f_text][2] = CreateDynamic3DTextLabel("ALT",0xFFFFA500,-1033.5869,-1182.8491,129.2188,12.0);
		FI[f_text][3] = CreateDynamic3DTextLabel("ALT",0xFFFFA500,-1072.1138,-1171.3446,129.6406,10.0);
		FI[f_cars][0] = CreateVehicle(531,-1065.0841,-1179.2544,129.2188,283.00,-1,-1,900);
		FI[f_cars][1] = CreateVehicle(478,-1062.7429,-1174.6229,129.2188,283.00,-1,-1,900);
//		FI[f_cars][2] =	CreateVehicle(531, -1033.4814, -1174.7482, 129.2768, 90.0000, -1, -1, 100);
//		FI[f_cars][3] =	CreateVehicle(531, -1031.1749, -1177.7308, 129.2768, 90.0000, -1, -1, 100);
//		FI[f_cars][4] =	CreateVehicle(531, -1035.9379, -1177.6876, 129.2768, 90.0000, -1, -1, 100);
//		FI[f_cars][5] =	CreateVehicle(532, -1031.7532, -1154.0000, 130.1572, 90.0000, -1, -1, 100);
//		FI[f_cars][6] =	CreateVehicle(532, -1031.6732, -1166.0000, 130.1572, 90.0000, -1, -1, 100);
//		FI[f_cars][7] =	CreateVehicle(478, -1034.9036, -1144.8640, 129.1234, 90.0000, -1, -1, 100);
//		FI[f_cars][8] =	CreateVehicle(482, -1071.0000, -1153.9785, 129.2011, -90.0000, -1, -1, 100); //Буррито
		CallLocalFunction("UpdateFarmText","");
		farm_worker = 0;
		SetFarmInfo(f_field_stats,0);
		SetFarmInfo(f_field_stats_2,0);
		SetFarmInfo(f_field_stats_3,0);
	}
	cache_delete(result);
	printf("[Ферма]: Статистика и данные у фермы успешно загружены. Потрачено: <%i ms>.",GetTickCount()-time);
}
function: UpdateFarmText()
{
	if(FI[f_text][0] != Text3D:-1)
	{
		new fmt_str[400];
		format
		(
			fmt_str, sizeof fmt_str,
			"{FFA500}Склад фермы\n"\
			"{ffffff}Яблоки: {6699FF}%d/2000 шт.\n"\
			"{ffffff}Апельсины: {6699FF}%d/2000 шт.\n"\
			"{ffffff}Лён: {6699FF}%d/1000 ящиков.\n"\
			"{ffffff}Пшеница: {6699FF}%d/1000 ящиков.\n"\
			"{ffffff}Хлопок: {6699FF}%d/10000 ящиков\n"\
            "{ffffff}Кукуруза: {6699FF}%d/1000 шт.\n"\
            "{ffffff}Помидоры: {6699FF}%d/1000 шт.\n"\
			"{ffffff}Саженцев: {6699FF}\t%d / 100 ед.\n",
			GetFarmInfo(f_apple),
			GetFarmInfo(f_orange),
			GetFarmInfo(f_flax),
			GetFarmInfo(f_millet),
			GetFarmInfo(f_cotton),
			GetFarmInfo(f_corn),
			GetFarmInfo(f_tomato),
			GetFarmInfo(f_sdl)
		);
		UpdateDynamic3DTextLabelText(FI[f_text][0], 0xFFFFA500, fmt_str);
	}
	if(FI[f_text][1] != Text3D:-1)
	{
		new fmt_str[100];
		format
		(
			fmt_str, sizeof fmt_str,
			"{FFA500}Склад инструментов\n"\
			"{ffffff}Интструменты: {6699FF}\t%d / 200 ед.\n{FFA500}ALT",
			GetFarmInfo(f_tools)
		);
		UpdateDynamic3DTextLabelText(FI[f_text][1], 0xFFFFA500, fmt_str);
	}
	if(FI[f_text][2] != Text3D:-1)
	{
		new fmt_str[100];
		format
		(
			fmt_str, sizeof fmt_str,
			"{FFA500}Саженцы\n"\
			"{ffffff}Саженцы на складе: {6699FF}\t%d / 200 шт.\n{FFA500}ALT",
			GetFarmInfo(f_sdl)
		);
		UpdateDynamic3DTextLabelText(FI[f_text][2], 0xFFFFA500, fmt_str);
	}
	if(FI[f_text][3] != Text3D:-1)
	{
		new fmt_str[100];
		format
		(
			fmt_str, sizeof fmt_str,
			"{FFA500}Водонапорная башня\n"\
			"{ffffff}Вода: {6699FF}\t%d/8000 литров\n{FFA500}ALT",
			GetFarmInfo(f_water)
		);
		UpdateDynamic3DTextLabelText(FI[f_text][3], 0xFFFFA500, fmt_str);
	}
}
stock UpdateTextDrawForFarm(playerid)
{
	new string[100];
	format(string,sizeof(string),"%d(%d/100)",PI[playerid][pFarmLVL]+1,PI[playerid][pSkillFarm]);
	PlayerTextDrawSetString(playerid,farm_ptd[playerid][1],string);
	format(string,20,"%d%",FI[f_field_stats]);
	PlayerTextDrawSetString(playerid,farm_ptd[playerid][5],string);
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
stock RemoveBuild(playerid)
{
    RemoveBuildingForPlayer(playerid, 3785, -1434.810059, 426.570007, 19.600000, 150.000000);
	RemoveBuildingForPlayer(playerid, 10825, -1412.290039, 351.445007, 13.710000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10826, -1407.000000, 390.959015, 13.100000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10898, -1407.000000, 390.959015, 13.100000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10824, -1409.900024, 389.476013, 8.178000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10900, -1409.900024, 389.476013, 8.178000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10827, -1539.208008, 371.203003, 29.804001, 0.250000);
	RemoveBuildingForPlayer(playerid, 10897, -1539.208008, 371.203003, 29.804001, 0.250000);
	RemoveBuildingForPlayer(playerid, 966, -1526.390015, 481.381012, 6.178000, 0.250000);
	RemoveBuildingForPlayer(playerid, 968, -1526.437988, 481.381012, 6.906000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10829, -1523.260010, 486.795013, 6.156000, 0.250000);
	RemoveBuildingForPlayer(playerid, 11288, -1670.030029, 311.553009, -2.546000, 0.250000);
	RemoveBuildingForPlayer(playerid, 10895, -1670.030029, 311.553009, -2.546000, 0.250000);
	RemoveBuildingForPlayer(playerid, 968, -1526.437500, 481.382813, 6.906300, 0.250000);
	RemoveBuildingForPlayer(playerid, 966, -1526.390625, 481.382813, 6.179700, 0.250000);
	RemoveBuildingForPlayer(playerid, 10248, -1680.992188, 683.234375, 19.046900, 0.250000);
	RemoveBuildingForPlayer(playerid, 967, -1700.929688, 688.867188, 23.882799, 0.250000);
	RemoveBuildingForPlayer(playerid, 966, -1701.429688, 687.593811, 23.882799, 0.250000);
	RemoveBuildingForPlayer(playerid, 966, -1572.203125, 658.835876, 6.078100, 0.250000);
	RemoveBuildingForPlayer(playerid, 967, -1572.703125, 657.601624, 6.078100, 0.250000);
	RemoveBuildingForPlayer(playerid, 3800, -1341.234375, 490.203094, 11.250000, 7.000000);
	RemoveBuildingForPlayer(playerid, 3798, -1341.710938, 493.976593, 10.203100, 20.000000);
	RemoveBuildingForPlayer(playerid, 3796, -1335.968750, 499.929688, 10.203100, 0.250000);
	RemoveBuildingForPlayer(playerid, 3787, -1329.429688, 499.601593, 10.773400, 5.000000);
	RemoveBuildingForPlayer(playerid, 3791, -1334.289063, 497.609406, 10.671900, 5.000000);
	RemoveBuildingForPlayer(playerid, 3799, -1342.601563, 502.804688, 10.093800, 0.250000);
	RemoveBuildingForPlayer(playerid, 1283, 1430.171021, -1719.468018, 15.625000, 0.250000);
	RemoveBuildingForPlayer(playerid, 1258, 1445.006958, -1704.765015, 13.695000, 0.250000);
	RemoveBuildingForPlayer(playerid, 1226, 1433.709961, -1702.359009, 16.421000, 0.250000);
	RemoveBuildingForPlayer(playerid, 1226, 1433.709961, -1676.687012, 16.421000, 0.250000);
	RemoveBuildingForPlayer(playerid, 1258, 1445.006958, -1692.234009, 13.695000, 0.250000);
	RemoveBuildingForPlayer(playerid, 1226, 1433.709961, -1656.250000, 16.421000, 0.250000);
}
stock ShowDialogCMDHelp(playerid,id_x,id_y)
{
    new str[300],str_2[50];
    switch(id_y)
    {
        case 0: str_2 = "{FFA500}Команды общения";
        case 1: str_2 = "{FFA500}Команды фракций";
        case 2: str_2 = "{FFA500}Команды транспорта";
        case 3: str_2 = "{FFA500}Команды имущества";
		case 4: str_2 = "{FFA500}Прочие команды";
    }
    switch(id_x)
    {
        case 0:
            {
		    	strins(str,"{FFFFFF}/b [Сообщение] - OOC чат\n",strlen(str));
		     	strins(str,"{FFFFFF}/rb [Сообщение] - OOC рация органзации\n",strlen(str));
		      	strins(str,"{FFFFFF}/r [Сообщение] - IC рация организации\n",strlen(str));
		       	strins(str,"{FFFFFF}/s(hout) [Сообщение] - кричать\n",strlen(str));
		       	strins(str,"{FFFFFF}/w [Сообщение] - шёпот\n",strlen(str));
		       	strins(str,"{FFFFFF}/me [действие] - действие от 1-о лица\n",strlen(str));
	   			strins(str,"{FFFFFF}/do [Действие] - действие от 3-о лица\n",strlen(str));
				SPD(playerid,dialog_menu_cmdhelp_3,DIALOG_STYLE_MSGBOX,str_2,str,"Назад","");
			}
   		case 4:
            {
		    	strins(str,"{FFFFFF}/repaircar - починить транспорт\n",strlen(str));
				SPD(playerid,dialog_menu_cmdhelp_3,DIALOG_STYLE_MSGBOX,str_2,str,"Назад","");
			}
	}
}
stock SkillJobAdd(playerid,job_id)
{
	if(PL[playerid])
	{
	    switch(job_id)
	    {
	        case 1:
	            {
	                PI[playerid][pSkillFarm]++;
	                if(PI[playerid][pSkillFarm] >= 100)
	                {
	                    PI[playerid][pFarmLVL]++;
	                    SCM(playerid,COLOR_LIME,"Поздравляем! Ваш навык фермера повышен. (/skill)");
	                }
	            }
         	case 2:
	            {
	                PI[playerid][pSkillFactory]++;
	                if(PI[playerid][pSkillFactory] >= 10)
	                {
	                    PI[playerid][pFactoryLVL]++;
	                    SCM(playerid,COLOR_LIME,"Поздравляем! Ваш навык производства повышен. (/skill)");
	                }
	            }
         	case 3:
	            {
	                PI[playerid][pSkillFish]++;
	                if(PI[playerid][pSkillFish] >= 100)
	                {
	                    PI[playerid][pFishLVL]++;
	                    SCM(playerid,COLOR_LIME,"Поздравляем! Ваш навык ловли рыбы повышен. (/skill)");
	                }
	            }
	    }
 	}
}
/*stock CreateVehicleLabel(vehicleid, text[], color, Float:x, Float:y, Float:z, Float:drawdistance, testlos = 0, worldid = -1, interiorid = -1, playerid = -1, Float:streamdistance = STREAMER_3D_TEXT_LABEL_SD)
{
	if(IsValidVehicle(vehicleid))
	{
		v_label[vehicleid] = CreateDynamic3DTextLabel(text, color, x, y, z, drawdistance, INVALID_PLAYER_ID, vehicleid, testlos, worldid, interiorid, playerid, streamdistance);
	}
	return 1;
}*/
stock ConvertUnixTime(unix_time, type = CONVERT_TIME_TO_SECONDS)
{
	switch(type)
	{
		case CONVERT_TIME_TO_SECONDS:
		{
			unix_time %= 60;
		}
		case CONVERT_TIME_TO_MINUTES:
		{
			unix_time = (unix_time / 60) % 60;
		}
		case CONVERT_TIME_TO_HOURS:
		{
			unix_time = (unix_time / 3600) % 24;
		}
		case CONVERT_TIME_TO_DAYS:
		{
			unix_time = (unix_time / 86400) % 30;
		}
		case CONVERT_TIME_TO_MONTHS:
		{
			unix_time = (unix_time / 2629743) % 12;
		}
		case CONVERT_TIME_TO_YEARS:
		{
			unix_time = (unix_time / 31556926) + 1970;
		}
		default:
			unix_time %= 60;
	}
	return unix_time;
}
/*stock DestroyVehicleLabel(vehicleid)
{
	if(IsValidVehicleID(vehicleid))
	{
		if(IsValidDynamic3DTextLabel(v_label[vehicleid]))
		{
			DestroyDynamic3DTextLabel(v_label[vehicleid]);
			v_label[vehicleid] = Text3D: -1;
		}
	}
	return 1;
}*/
stock SellBusiness(playerid, to_player = INVALID_PLAYER_ID, price = 0)
{
	new businessid = PI[playerid][pBusinessID];
	if(businessid != -1)
	{
		new biz_price = GetBusinessData(businessid, B_PRICE);
		new biz_percent = (biz_price * 15) / 100;
		new return_money = biz_price - biz_percent;
		SetInfo(playerid, pBusinessID,-1);
		SetBusinessData(businessid, B_OWNER_ID, 	0);
		if(to_player == INVALID_PLAYER_ID)
		{
			AddInfo(playerid, pBank, +, return_money);
			SetBusinessData(businessid, B_IMPROVEMENTS, 	0);
			SetBusinessData(businessid, B_PRODS, 			0);
			SetBusinessData(businessid, B_PROD_PRICE,		0);
			SetBusinessData(businessid, B_BALANCE,			0);
			SetBusinessData(businessid, B_RENT_DATE,		0);
			SetBusinessData(businessid, B_ENTER_MUSIC,		0);
			SetBusinessData(businessid, B_LOCK_STATUS,	false);

			format(query, sizeof query, "UPDATE users a,business b SET a.bank=%d,a.business=-1,b.owner_id=0,b.products=0,b.prod_price=0,b.lock=0 WHERE a.id=%d AND b.id=%d", PI[playerid][pBank], GetPID(playerid), GetBusinessData(businessid, B_SQL_ID));
			mysql_query(dbHandle, query, false);
			CallLocalFunction("UpdateBusinessLabel", "i", businessid);
			SCM(playerid, COLOR_LIME, "Вы продали свой бизнес!");
			format(query, sizeof query, "Налог за продажу бизнеса составил 15 процентов от его стоимости (%d руб)", biz_percent);
			SCM(playerid, COLOR_BLUE, query);
			format(query, sizeof query, "Итого на банковский счет перечислено: {"#cGold"}%d руб", return_money);
			SCM(playerid, COLOR_WHITE, query);
		}
		else
		{
			if(BuyPlayerBusiness(to_player, businessid, true, price) == 1)
			{
				new total_price = price;
				format(query, sizeof query, "UPDATE users SET cash=%d,business=-1 WHERE id=%d LIMIT 1", PI[playerid][pCash]+total_price, GetPID(playerid));
				mysql_query(dbHandle, query, false);
				GiveMoney(playerid, total_price,true);
				biz_price = price;
				biz_percent = 0;
			}
			else return ;
		}
		format(query, sizeof query, "~g~+%d$", (biz_price - biz_percent));
		GameTextForPlayer(playerid, query, 4000, 1);
	}
}
forward OnLoadAllAdmins(playerid);
public OnLoadAllAdmins(playerid)
{
    new totalMembers = cache_num_rows();
	if(totalMembers > 0)
	{
		new string[64], bigstring[150];
		new admin, name_a[MAX_PLAYER_NAME],time_in_game = 0;
		if(strlen(bigstring) < 1) strcat(bigstring, "{FFA500}Администратор\t{FFA500}Уровень\t{FFA500}Время онлайна\n\n");
		for(new i = 0; i < totalMembers; i++)
		{
			cache_get_value_name_int(i, "a_lvl", admin);
			cache_get_value_name(i, "a_name", name_a);
			format(bigstring, sizeof(bigstring), "{ffffff}%s%s\t%d\t\t%d\n", bigstring, name_a, admin, time_in_game);
		}
		format(string, sizeof(string), "{FFA500}Администрация сервера: %d", totalMembers);
  		ShowPlayerDialog(playerid, dialog_alladmins, DIALOG_STYLE_TABLIST_HEADERS, string, bigstring, "Выбрать", "Назад");
	}
}
function: ShowBusinessProfit(playerid)
{
	new string[600],fmt_str[32],
		rows = cache_num_rows(),tg;
	if(rows)
	{
		string = "Дата\t\t\tПрибыль\n\n{"#cW"}";
	}
	else string = "{"#cW"}Финансовая статистика Вашего бизнеса еще не сформирована";

	for(new idx; idx < rows; idx ++)
	{
		cache_get_value_name(idx, "time",fmt_str);
		strcat(string, fmt_str);
        cache_get_value_name_int(idx,"money",tg);
		format(fmt_str, sizeof fmt_str, "\t\t%d$\n", tg);
		strcat(string, fmt_str);
	}
	SPD(playerid, 0, DIALOG_STYLE_MSGBOX, "{"#cGold"}Доход бизнеса за 20 дней", string, "Назад", "Закрыть");
}
function: ShowPlayerBusinessDialog(playerid, operationid)
{
	new businessid = PI[playerid][pBusinessID];
	if(businessid != -1)
	{
		switch(operationid)
		{
			case BIZ_OPERATION_PARAMS:
			{
				SPD
				(
					playerid, dialog_business_params, 2,
					"{"#cGold"}Управление бизнесом",
					"1. Открыть/закрыть бизнес\n"\
					"2. {"#cW"}Установить цену на вход\n"\
					"3. {"#cW"}Финансовая статистика\n"\
					"4. {"#cW"}Установить цену за продукт",
					"Выбрать", "Назад"
				);
			}
			case BIZ_OPERATION_LOCK:
			{
				if(GetBusinessData(businessid, B_LOCK_STATUS))
				{
					SetBusinessData(businessid, B_LOCK_STATUS, false);
					SCM(playerid, COLOR_LIME, "Бизнес открыт");
				}
				else
				{
					SetBusinessData(businessid, B_LOCK_STATUS, true);
					SCM(playerid, COLOR_DARKORANGE, "Бизнес закрыт");
				}
				UpdateBusinessLabel(businessid);
				mysql_format(dbHandle, query, sizeof query, "UPDATE business SET `lock`=%d WHERE `id`=%d LIMIT 1", GetBusinessData(businessid, B_LOCK_STATUS), GetBusinessData(businessid, B_SQL_ID));
				mysql_query(dbHandle, query, false);
				CallLocalFunction("ShowPlayerBusinessDialog", "ii", playerid, BIZ_OPERATION_PARAMS);
			}
			case BIZ_OPERATION_ENTER_PRICE: // установить цену за вход
			{
				return 1;
			}
			case BIZ_OPERATION_PROFIT_STATS: // финансовая статистика
			{
				new time = gettime();
				new cur_day = time - (time % 86400);
				new start_day = cur_day - (86400 * 20);

				mysql_format(dbHandle, query, sizeof query, "SELECT FROM_UNIXTIME(time, '%%Y-%%m-%%d') AS date, SUM(money) as total FROM business_profit WHERE bid=%d AND view=1 AND time >= %d AND time < %d GROUP BY time ORDER BY time DESC LIMIT 20", GetBusinessData(businessid, B_SQL_ID), start_day, cur_day);
				mysql_tquery(dbHandle, query, "ShowBusinessProfit", "i", playerid);
			}
			case BIZ_OPERATION_ENTER_PRICE_2: // установить цену за вход
			{
				SPD(playerid,dialog_enter_price,DIALOG_STYLE_INPUT,"{FFA500}Цена за продукт","{FFFFFF}Введите в строчку ниже цену за продукт. Возможная цена за продукт: 5-40$","Далее","Назад");
			}
		}
	}
	return 1;
}
function: PayDay()
{
	new h,m,s,
		string[150];
	gettime(h,m,s);
	SetWorldTime(h);
	if(paydays)
	{
		foreach(new i : Player)
		{
		    if(PL[i])
		    {
		        new lvl_p,cash_out;
		        lvl_p = PI[i][pLVL];
		        if(PI[i][pAdmin]) cash_out += 15000*PI[i][pAdmin];
				if(PI[i][pMember] && !PI[i][pAdmin]) cash_out += Fraction_Pay(i);
				PI[i][pBank] += cash_out;
		        SCM(i,-1,"Уведомление от банка");
		        SCM(i,-1,"_____________________");
		        if(!PI[i][pAdmin]) format(string,sizeof string,"Зарплата: {FFA500}%d$",cash_out);
		        else format(string,sizeof string,"Зарплата администратора: {FFA500}%d$",cash_out);
		        SCM(i,-1, string);
				format(string, sizeof string, "Налог государству: {FFA500}%d$",0);
				SCM(i,-1, string);
				format(string,sizeof string, "Счёт в банке: {FFa500}%d$",PI[i][pBank]);
				SCM(i,-1, string);
				format(string,sizeof string, "[OOC]: Уровень: %d",lvl_p);
				SCM(i,-1,string);
				SCM(i,COLOR_LIME,"[OOC]: +1 exp (опыт)");
				SCM(i,-1,"_____________________");
				PI[i][pExp]++;
				if(PI[i][pExp] >= (PI[i][pLVL]+1)*4)
				{
				    PI[i][pLVL]++;
				    PI[i][pExp] = 0;
				    SCM(i,COLOR_BLUE,"Поздравляем! Вы повысили свой игровой уровень.");
				    switch(PI[i][pLVL])
				    {
				        case 2: SCM(i,COLOR_BLUE,"Теперь вы можете получить лицензии на владение оружием.");
				    }
				}
    		}
		    SaveAccounts(i);
		}
		for(new i; i < g_ownable_car_loaded; i++) SaveOwnableCar(i);
		paydays = 0;
	}
}
stock GetPlayerID(name[])
{
	foreach(new i: Player)
	{
		if(strcmp(GN(i), name, true, strlen(name)) == 0) return i;
	}
	return INVALID_PLAYER_ID;
}
stock getDayEx()
{
    new w = gettime(), saturday = 1310155200, day_week;
	while(w - saturday > 60 * 60 * 24)
    {
        w -= 60 * 60 * 24;
        day_week ++;
    }
    while(day_week >= 7) day_week -= 7;
	return day_week;
}
function: MyOnlineWeek(playerid)
{
	new rows,fields,string[256],
    	string_dialog[750],co_monday,co_thuesday,
		co_wednesday,co_thursday,co_friday,
		co_saturday,co_sunday,co_all_online;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(rows)
	{
	    cache_get_value_name_int(0,"o_monday",co_monday);
	    cache_get_value_name_int(0,"o_tuesday",co_thuesday);
	    cache_get_value_name_int(0,"o_wednesday",co_wednesday);
		cache_get_value_name_int(0,"o_thursday",co_thursday);
		cache_get_value_name_int(0,"o_friday",co_friday);
		cache_get_value_name_int(0,"o_saturday",co_saturday);
		cache_get_value_name_int(0,"o_sunday",co_sunday);
	    format(string, sizeof(string), "{FFFFFF}Понедельник:\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_monday / 3600) % 3600, floatround(co_monday / 60) % 60, co_monday % 60);
	    strcat(string_dialog, string);
	    format(string, sizeof(string), "{FFFFFF}Вторник:\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_thuesday / 3600) % 3600, floatround(co_thuesday / 60) % 60, co_thuesday % 60);
	    strcat(string_dialog, string);
	    format(string, sizeof(string), "{FFFFFF}Среда:\t\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_wednesday / 3600) % 3600, floatround(co_wednesday / 60) % 60, co_wednesday % 60);
	    strcat(string_dialog, string);
	    format(string, sizeof(string), "{FFFFFF}Четверг:\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_thursday / 3600) % 3600, floatround(co_thursday / 60) % 60, co_thursday % 60);
	    strcat(string_dialog, string);
	    format(string, sizeof(string), "{FFFFFF}Пятница:\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_friday / 3600) % 3600, floatround(co_friday / 60) % 60, co_friday % 60);
	    strcat(string_dialog, string);
	    format(string, sizeof(string), "{FFFFFF}Суббота:\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_saturday / 3600) % 3600, floatround(co_saturday / 60) % 60, co_saturday % 60);
	    strcat(string_dialog, string);
	    format(string, sizeof(string), "{FFFFFF}Воскресенье:\t\t{FFA500}%02d:%02d:%02d\n", floatround(co_sunday / 3600) % 3600, floatround(co_sunday / 60) % 60, co_sunday % 60);
	    strcat(string_dialog, string);
	    co_all_online = co_monday + co_thuesday + co_wednesday + co_thursday + co_friday + co_saturday + co_sunday;
	    format(string, sizeof(string), "\n{FFFFFF}Общий онлайн(недельный):\t{FFA500}%02d:%02d:%02d", floatround(co_all_online / 3600) % 3600, floatround(co_all_online / 60) % 60, co_all_online % 60);
	    strcat(string_dialog, string);
	    SPD(playerid, 0, DIALOG_STYLE_MSGBOX, "{FFA500}Онлайн за неделю", string_dialog, "Назад", "");
	}
	else
	{
	    cmd_menu(playerid);
		SCM(playerid,COLOR_DARKORANGE,"Возникла серьезная ошибка! Обратитесь к администрации. {#ERROR11}");
	}
}
function: check_banlist(playerid)
{
	new unbandate, vas[28], bool:ban, rows, fields, dialog[500], str[150],unban_date;
	cache_get_row_count(rows);
	cache_get_field_count(fields);
	if(rows)
	{
	    cache_get_value_name(0, "unban_date", vas); unbandate = strval(vas);
		if(unbandate - gettime() > 0) ban = true;
	}
	if(ban == true)
	{
		new data[15], whobanned[MAX_PLAYER_NAME], reason[32],timeban;
		cache_get_value_name(0, "ban_date", data);
		cache_get_value_name_int(0, "unban_date", unban_date);
		unbandate = unban_date;
		cache_get_value_name(0, "a_name", whobanned);
		cache_get_value_name(0, "reason", reason);
	 	cache_get_value_name_int(0, "time",timeban);
		format(str, sizeof str, "{FF6347}Этот аккаунт заблокирован, если Вы не согласны с наказанием,\n");
		strcat(dialog,str);
		format(str, sizeof str, "{FF6347}то напишите жалобу на администратора для проводения раследования.\n\n");
		strcat(dialog,str);
		format(str, sizeof(str), "{ffffff}Ник администратора: %s\n", whobanned);
		strcat(dialog, str);
		format(str, sizeof(str), "{ffffff}Причина блокировки: %s\n", reason);
	 	strcat(dialog, str);
		format(str, sizeof(str), "{ffffff}Срок блокировки: %d\n", timeban);
	 	strcat(dialog, str);
  		format(str, sizeof(str), "{ffffff}Дата: {FFA500}%s\n\n", data);
		strcat(dialog, str);
		format(str, sizeof(str), "{ffffff}Чтобы выйти используйте команду - {FFA500}/q.", data);
		strcat(dialog, str);
		ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "{FFA500}Уведомление", dialog, "Закрыть", "");
		FixKick(playerid, "", 3000);
	}
	return 1;
}
stock IsPlayerInRangeOfPlayer(playerid, to_player, Float: distance)
{
	new Float: x, Float: y, Float: z;
	GetPlayerPos(to_player, x, y, z);

	return IsPlayerInRangeOfPoint(playerid, distance, x, y, z);
}
stock FixKick(playerid, message[] = "Введите /q (/quit), чтобы выйти", time_ms = 500)
{
	if(strlen(message) > 1)
		SCM(playerid, 0xFF6600FF, message);
		
	SetTimerEx("FixedKick", time_ms, false, "i", playerid);
	return 1;
}
stock InvitePlayer(playerid, frac_id)
{
	PI[playerid][pMember] = frac_id;
	PI[playerid][pRank] = 1;
	PI[playerid][pMember_Skin] = 223;
	SetPlayerSkin(playerid,PI[playerid][pMember_Skin]);
}
stock UnInvitePlayer(playerid, to_playerid, reason[], t_vo)
{
	new string[100];
	switch(t_vo)
	{
		case 0: SCM(to_playerid, COLOR_DARKORANGE,"Вы покинули свою организацию!");
		case 1:
  			{
				format(string, sizeof string, "Вы уволили %s[%d] из организации. Причина: %s",GN(to_playerid),to_playerid, reason);
				SCM(playerid,COLOR_LIME,string);
				format(string, sizeof string, "%s[%d] уволил Вас из фракции %s. Причина: %s",GN(playerid),playerid,Fraction_Name[PI[playerid][pMember]], reason);
				SCM(to_playerid, COLOR_DARKORANGE, string);
		    }
	}
	PI[to_playerid][pMember] = PI[to_playerid][pRank] = PI[to_playerid][pLeader] = 0;
	PI[to_playerid][pMember_Skin] = 0;
	SetPlayerSkin(to_playerid,PI[to_playerid][pSkin_ID]);
}
stock ShowGangZonesForPlayer(playerid)
{
	for(new idx; idx < sizeof g_gang_zone; idx ++) GangZoneShowForPlayer(playerid, GetGangZoneData(idx, GZ_ZONE), gang_zone_colors[ GetGangZoneData(idx, GZ_GANG) ]);
	if(g_capture[C_STATUS])
		GangZoneFlashForPlayer(playerid, GetGangZoneData(g_capture[C_GANG_ZONE], GZ_ZONE), gang_zone_colors[g_capture[C_ATTACK_TEAM]]);
}
stock StartCapture(playerid, gang_zone_id, attack_team, protect_team)
{
	if(g_capture[C_STATUS]) return 0;

	new fmt_text[128],
		gps_icons[3] = {62, 61, 60};

	format(fmt_text, sizeof fmt_text, "%s начали захват территории у %s",
	Fraction_Name[attack_team + 7], Fraction_Name[protect_team + 7]);

	SCM_G(fmt_text, 0xFF5533FF);

	format(fmt_text, sizeof fmt_text, "%s [%d] инициировал захват. У вас есть 7 минут для захвата территории.",
	GN(playerid), playerid);

	SCM_T(PI[playerid][pMember], fmt_text, 0xFF5533FF);

	foreach(new idx : Player)
	{
		if(!(8 <= PI[idx][pMember] <= 10)) continue;

		//TextDrawShowForPlayer(playerid, capture_TD[0]);
		//TextDrawShowForPlayer(playerid, capture_TD[1]);

		format(fmt_text, sizeof fmt_text, "Место отмечено на GPS. Окажите сопротивление вражеской банде в течение 7 минут, чтобы %s территорию",
		PI[idx][pMember] == (attack_team + 7) ? "захватить" : "сохранить свою");

		SendClientMessage(idx, 0xFFFF00FF, fmt_text);

		SetPlayerMapIcon
		(
			idx, 97,
			GetGangZoneData(gang_zone_id, GZ_MIN_X) + 50.0,
			GetGangZoneData(gang_zone_id, GZ_MIN_Y) + 50.0,
			0.0,
			gps_icons[PI[idx][pMember] - 8],
			COLOR_WHITE,
			MAPICON_GLOBAL
		);
	}

	GangZoneFlashForAll(GetGangZoneData(gang_zone_id, GZ_ZONE), gang_zone_colors[attack_team]);

	g_capture[C_STATUS] = true;

	g_capture[C_GANG_ZONE] = gang_zone_id;

	g_capture[C_ATTACK_TEAM] = attack_team;
	g_capture[C_PROTECT_TEAM] = protect_team;

	g_capture[C_ATTACKER_KILLS] = 0;
	g_capture[C_PROTECTOR_KILLS] = 0;

	g_capture[C_TIME] = 1 * 60;

	UpdateCaptureTextDraw();

	return 1;
}
stock SCM_G(message[], color = -1, playerid = -1)
{
	SCM_T(8, message, color, playerid);
	SCM_T(9, message, color, playerid);
	SCM_T(10, message, color, playerid);

	return 1;
}
stock SCM_SU(message[], color = -1, playerid = -1)
{
	SCM_T(2, message, color, playerid);
	SCM_T(7, message, color, playerid);
	return 1;
}
stock SCM_T(team, message[], color = -1, playerid = -1)
{
	for(new i; i < MAX_PLAYERS; i ++)
	{
		if(!IsPlayerConnected(i)) continue;
		else if(!PL[i]) continue;
		else if(PI[i][pMember] != team) continue;
		else if(i == playerid) continue;

		SendClientMessage(i, color, message);
	}
	return 1;
}
function: FixedKick(playerid)
{
	Kick(playerid);
}
stock UpdateCaptureTextDraw()
{
	switch(g_capture[C_ATTACK_TEAM])
	{
	    case 1: TextDrawColor(captinfo_TD[3],0x00FF7FFF);
	    case 2: TextDrawColor(captinfo_TD[3],0x008000FF);
	    case 3: TextDrawColor(captinfo_TD[3],0x808000FF);
	}
	switch(g_capture[C_PROTECT_TEAM])
	{
	    case 1: TextDrawColor(captinfo_TD[4],0x00FF7FFF);
	    case 2: TextDrawColor(captinfo_TD[4],0x008000FF);
	    case 3: TextDrawColor(captinfo_TD[4],0x808000FF);
	}
	new string2[128];
	format
	(
		string2, sizeof string2,
		"%d:%02d",
		g_capture[C_TIME] / 60,
		g_capture[C_TIME] % 60
	);
	TextDrawSetString(captinfo_TD[6], string2);
	new string3[128];
	format
	(
		string3, sizeof string3,
		"%d",
		g_capture[C_ATTACKER_KILLS]
	);
	TextDrawSetString(captinfo_TD[7], string3);
	new string4[128];
	format
	(
		string4, sizeof string4,
		"%d",
		g_capture[C_PROTECTOR_KILLS]
	);

	TextDrawSetString(captinfo_TD[8], string4);

	foreach(new idx : Player)
	{
		if(!IsPlayerConnected(idx)) continue;
		if(!PL[idx]) continue;
		if(!(7 <= PI[idx][pMember] <= 10)) continue;

		for(new r; r < 9; r ++)
			TextDrawShowForPlayer(idx, captinfo_TD[r]);
	}
}
stock EndCapture()
{
	if(!g_capture[C_STATUS]) return 0;

	new fmt_text[90],
		attack_team = g_capture[C_ATTACK_TEAM] + 7,
		protect_team = g_capture[C_PROTECT_TEAM] + 7,
		gang_zone_id = g_capture[C_GANG_ZONE];

	if(g_capture[C_ATTACKER_KILLS] > g_capture[C_PROTECTOR_KILLS])
		format(fmt_text, sizeof fmt_text, "%s захватили территорию у %s", Fraction_Name[attack_team], Fraction_Name[protect_team]);

	else
		format(fmt_text, sizeof fmt_text, "Попытка %s захватить территорию у %s провалилась",  Fraction_Name[attack_team],  Fraction_Name[protect_team]);

	SCM_G(fmt_text, 0xFF5533FF);

	new gz_index = GetGangZoneData(gang_zone_id, GZ_ZONE);

	GangZoneStopFlashForAll(gz_index);

	if(g_capture[C_ATTACKER_KILLS] > g_capture[C_PROTECTOR_KILLS])
	{
		SetGangZoneData(gang_zone_id, GZ_GANG, g_capture[C_ATTACK_TEAM]);
		SaveGangZone(gang_zone_id);

		GangZoneShowForAll(gz_index, gang_zone_colors[ GetGangZoneData(gang_zone_id, GZ_GANG) ]);

		//UpdateGangRepository(g_capture[C_ATTACK_TEAM] - 1);
		//UpdateGangRepository(g_capture[C_PROTECT_TEAM] - 1);
	}

	for(new r; r < 9; r ++)
		TextDrawHideForAll(captinfo_TD[r]);

	g_capture[C_STATUS] = false;

	g_capture[C_GANG_ZONE] = -1;

	g_capture[C_ATTACK_TEAM] =
	g_capture[C_PROTECT_TEAM] = -1;

	g_capture[C_ATTACKER_KILLS] =
	g_capture[C_PROTECTOR_KILLS] = 0;

	g_capture[C_TIME] = 0;

	g_capture[C_WAIT_TIME][attack_team - 8] =
	g_capture[C_WAIT_TIME][protect_team - 8] = gettime() + 3600;

	foreach(new idx : Player)
		RemovePlayerMapIcon(idx, 97);

	return 1;
}
stock ProxDetector(Float:radi, playerid, str[],col1,col2,col3,col4,col5)
{
	new Float:posx, Float:posy, Float:posz, Float:oldposx, Float:oldposy,
	Float:oldposz, Float:tempposx, Float:tempposy, Float:tempposz;
	GetPlayerPos(playerid, oldposx, oldposy, oldposz);
	foreach(new i: Player)
	{
		if(PL[i] == false) continue;
		GetPlayerPos(i, posx, posy, posz);
		tempposx = (oldposx -posx);
		tempposy = (oldposy -posy);
		tempposz = (oldposz -posz);
		if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16))) SCM(i, col1, str);
		else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8))) SCM(i, col2, str);
		else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4))) SCM(i, col3, str);
		else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2))) SCM(i, col4, str);
		else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi))) SCM(i, col5, str);
	}
	return 1;
}
stock ShowPlayerLeaderMenu(playerid)
{
	SPD(playerid,dialog_lmenu,2,"{FFA500}Меню лидера","{FFA500}1.{FFFFFF} Название должностей\n\
	{FFA500}2.{FFFFFF} Зарплаты сотрудников\n\
	{FFA500}3. {FFFFFF}Полный список сотрудников\n\
	{FFA500}4. {FFFFFF}Заказы\n\
	{FFA500}5. {FFFFFF}Вооружение","Выбрать","Закрыть");
}
stock IsPoliceTeam(playerid)
{
	if(PI[playerid][pMember] == 2 || PI[playerid][pMember] == 7) return true;
	return false;
}
forward LoadOwnableCar(playerid,oc_id,Float:carx,Float:cary,Float:carz);
public LoadOwnableCar(playerid,oc_id,Float:carx,Float:cary,Float:carz)
{
	if(g_ownable_car_loaded + 1 > MAX_OWNABLE_CARS)
	{
		print("[OwnableCars]: Ошибка в загрузке. Превышен лимит личного транспорта (MAX_OWNABLE_CARS)");
		return -1;
	}

	new Cache: result,
		vehicleid;

	mysql_format(dbHandle, query, sizeof query, "SELECT * FROM ownable_cars WHERE id='%d' LIMIT 1", oc_id);
	result = mysql_query(dbHandle, query, true);

	new idx = GetFreeOwnableCarID(),id,o_id,o_m_id,o_c_1,o_c_2,Float:o_angle,c_time;
	Fuel[idx] = 0;
	cache_get_value_name_int(0, "id", id);
	SetOwnableCarData(idx, OC_SQL_ID,id);
	cache_get_value_name_int(0, "owner_id",o_id);
	SetOwnableCarData(idx, OC_OWNER_ID,o_id);
    cache_get_value_name_int(0, "model_id",o_m_id);
	SetOwnableCarData(idx, OC_MODEL_ID,o_m_id);
	cache_get_value_name_int(0, "color_1",o_c_1);
	SetOwnableCarData(idx, OC_COLOR_1, 		o_c_1);
	cache_get_value_name_int(0, "color_2",o_c_2);
	SetOwnableCarData(idx, OC_COLOR_2, 		o_c_2);
	SetOwnableCarData(idx, OC_POS_X, carx);
	SetOwnableCarData(idx, OC_POS_Y, cary);
	SetOwnableCarData(idx, OC_POS_Z, carz);
	cache_get_value_name_float(0, "angle",o_angle);
	SetOwnableCarData(idx, OC_ANGLE, o_angle);

	cache_get_value_name(0, "number", g_ownable_car[idx][OC_NUMBER]);
    cache_get_value_name_int(0, "create_time",c_time);
	SetOwnableCarData(idx, OC_CREATE,c_time);

	// ----------------------------------------------------------------------------------------

	if(strlen(GetOwnableCarData(idx, OC_NUMBER)) != 6)
		strmid(g_ownable_car[idx][OC_NUMBER], "------", 0, 8, 8);

	vehicleid = CreateVehicle
	(
		GetOwnableCarData(idx, OC_MODEL_ID),
		GetOwnableCarData(idx, OC_POS_X),
		GetOwnableCarData(idx, OC_POS_Y),
		GetOwnableCarData(idx, OC_POS_Z),
		GetOwnableCarData(idx, OC_ANGLE),
		GetOwnableCarData(idx, OC_COLOR_1),
		GetOwnableCarData(idx, OC_COLOR_2),
		-1,
		0,
		VEHICLE_ACTION_TYPE_OWNABLE_CAR,
		idx
	);
	if(!PI[playerid][pAdmin]) CreateVehicleLabel(vehicleid,GetOwnableCarData(idx,OC_NUMBER), 0xFFFFFFFF, 0, 0, 0, 10.0, 0);
	else CreateVehicleLabel(vehicleid,GetOwnableCarData(idx,OC_NUMBER), COLOR_RED, 0, 0, 0, 10.0, 0);
	if(vehicleid != INVALID_VEHICLE_ID)
	{
		SetVehicleNumberPlate(vehicleid, GetOwnableCarData(idx, OC_NUMBER));

		AddVehicleComponent(idx, GetOwnableCarData(vehicleid, OC_NITRO));

		AddVehicleComponent(vehicleid, GetOwnableCarData(idx, OC_DISKI));

		AddVehicleComponent(vehicleid, GetOwnableCarData(idx, OC_GIDRA));

		AddVehicleComponent(vehicleid, GetOwnableCarData(idx, OC_NITRO));

		if(g_ownable_car[idx][OC_DISKI] != 0) AddVehicleComponent(idx, g_ownable_car[vehicleid][OC_DISKI]);

		AddVehicleComponent(idx, g_ownable_car[vehicleid][OC_DISKI]);
        cache_get_value_name_float(0, "fuel",Fuel[vehicleid]);
		SetVehicleData(vehicleid, V_LAST_LOAD_TIME, gettime());
		//SetVehicleHealth(vehicleid, GetVehicleData(vehicleid, V_HEALTH));
	}
    PI[playerid][pCarID] =  vehicleid;
	cache_delete(result);

	return 1;
}
function: OnLoadOfflineMember(playerid)
{
    new totalMembers = cache_num_rows();
	if(totalMembers > 0)
	{
		new string[64],bigstring[550];
		new rang, membername[MAX_PLAYER_NAME],member;
		if(strlen(bigstring) < 1) strcat(bigstring, "{FFA500}Имя_Фамилия\t\t{FFA500}Должность\n");
		for(new i = 0; i < totalMembers; i++)
		{
			cache_get_value_name_int(i, "rank", rang);
		 	cache_get_value_name_int(i, "member_id", member);
			cache_get_value_name(i, "name", membername);

			format(bigstring, sizeof bigstring, "{ffffff}%s%s\t%s(%d)\n",bigstring, membername, g_fraction_rank[member][rang],rang);
		}
		format(string, sizeof(string), "{FFA500}Всего членов организации: %d", totalMembers);
  		SPD(playerid, dialog_lmenu_back, DIALOG_STYLE_TABLIST_HEADERS, string, bigstring, "Выбрать", "Назад");
	}
}
stock GetFreeOwnableCarID()
{
	for(new idx; idx < sizeof g_ownable_car; idx ++)
	{
		if(GetOwnableCarData(idx, OC_CREATE)) continue;

		return idx;
	}

	return -1;
}
stock IsABike(vehicleid)
{
	switch(GetVehicleData(vehicleid, V_MODELID))
	{
		case 481, 509, 510:
		{
			return 1;
		}
	}
	return 0;
}
stock SaveGangZone(idx)
{
	new query_s[100];
	mysql_format(dbHandle, query_s, sizeof query_s, "UPDATE `gangzones` SET `fraction` = '%d' WHERE `id` = '%d'", GetGangZoneData(idx, GZ_GANG), idx);
	mysql_query(dbHandle, query_s, false);
}

function: PlayerOwnableCarInit(playerid)
{
	new index;
	new vehicleid = -1;

	while(vehicleid < MAX_VEHICLES-1)
	{
		vehicleid ++;
		index = GetVehicleData(vehicleid, V_ACTION_ID);

		if(GetVehicleData(vehicleid, V_ACTION_TYPE) != VEHICLE_ACTION_TYPE_OWNABLE_CAR) continue;
		if(GetOwnableCarData(index, OC_OWNER_ID) != PI[playerid][pID]) continue;
		SetInfo(playerid, pCarID, vehicleid);
		break;
	}
}
stock UnloadPlayerOwnableCar(playerid)
{
	new vehicleid = GetPlayerOwnableCar(playerid);

	if(vehicleid == INVALID_VEHICLE_ID)
	{
		return -1;
	}

	new index = GetVehicleData(vehicleid, V_ACTION_ID);
	SetOwnableCarData(index, OC_CREATE, 0);
	DestroyVehicleLabel(vehicleid);
	DestroyVehicle(vehicleid);
	SetVehicleData(vehicleid, V_LAST_LOAD_TIME, 0);
	//SetPlayerInfo(playerid, pCarID, INVALID_VEHICLE_ID);
	return 1;
}
stock ShowOwnableCarLoadDialog(playerid, id, bool: show_menu = false)
{
	SetPVarInt(playerid, "ownablecar_id", id);

	if(show_menu)
		SetPVarInt(playerid, "show_menu", 1);

	SPD
	(
		playerid, dialog_car_2, DIALOG_STYLE_LIST,
		"{FFA500}Управление транспортом",
		"{FFA500}1.{ffffff} Загрузить транспорт\n"\
		"{FFA500}2.{ffffff} Информация о транспорте",
		"Выбрать", "Закрыть"
	);
}
stock IsAOwnableCar(vehicleid)
{
	if(IsValidVehicleID(vehicleid))
	{
		if(GetVehicleData(vehicleid, V_ACTION_TYPE) == VEHICLE_ACTION_TYPE_OWNABLE_CAR) return 1;
	}
	return 0;
}
stock GetPlayerOwnableCars(playerid)
{
	new count,
		Cache: result;

	mysql_format(dbHandle, query, sizeof query, "SELECT * FROM ownable_cars WHERE owner_id='%d'", PI[playerid][pID]);
	result = mysql_query(dbHandle, query, true);

	count = cache_num_rows();

	cache_delete(result);

	return count;
}
function: SaveOwnableCar(vehicleid)
{
	if(IsAOwnableCar(vehicleid))
	{
  		new index = GetVehicleData(vehicleid, V_ACTION_ID);
		new Float: health;
		GetVehicleHealth(vehicleid, health);
		format
		(
			query, sizeof query,
			"UPDATE ownable_cars SET "\
			"color_1=%d,"\
			"pos_x=%f,"\
			"pos_y=%f,"\
			"pos_z=%f,"\
			"angle=%f,"\
			"status=%d,"\
			"alarm=%d,"\
			"diski=%d,"\
			"gidra=%d,"\
			"nitro=%d,"\
			"mileage=%f,"\
			"health=%f,"\
			"fuel=%f,"\
			"number='%s'"\
			" WHERE id=%d LIMIT 1",
			GetOwnableCarData(index, OC_COLOR_1),
			GetOwnableCarData(index, OC_POS_X),
			GetOwnableCarData(index, OC_POS_Y),
			GetOwnableCarData(index, OC_POS_Z),
			GetOwnableCarData(index, OC_ANGLE),
			GetVehicleParam(vehicleid, V_LOCK),
			GetVehicleParam(vehicleid, V_ALARM),
			GetOwnableCarData(index, OC_DISKI),
			GetOwnableCarData(index, OC_GIDRA),
			GetOwnableCarData(index, OC_NITRO),
			GetVehicleData(vehicleid, V_MILEAGE),
			GetVehicleData(vehicleid, V_HEALTH),
			Fuel[vehicleid],
			GetOwnableCarData(index, OC_NUMBER),
			GetOwnableCarData(index, OC_SQL_ID)
		);
		mysql_query(dbHandle, query);

		return mysql_errno();
	}
	return -1;
}
stock BuyOwnableCar(playerid, ownablecar, color_1, color_2)
{
	if(SaveOwnableCar(GetPlayerOwnableCar(playerid)) != -1)
				UnloadPlayerOwnableCar(playerid);
	if((GetPlayerOwnableCars(playerid) + 1) > 3)
	{
		SCM(playerid, 0x3399FFFF, "Все слоты для транспорта заняты. Вы можете увеличить их: {FFFF00}U > Дополнительно");
		return -1;
	}
	new modelid;

	if(ownablecar < 1000)
		modelid = 400;
	else
		modelid = ownablecar - 1000;

	printf("modelid = %d | ownablecar = %d", modelid, ownablecar);
	if(GetPlayerMoney(playerid) < GetVehicleInfo(modelid - 400, VI_PRICE))
	{
		SCM(playerid, 0xFF6600FF, "Недостаточно денег для покупки этого транспорта");
		return -1;
	}
	new
		Cache: result,
		idx;

	idx = GetFreeOwnableCarID();

	SetOwnableCarData(idx, OC_OWNER_ID, 	PI[playerid][pID]);

	SetOwnableCarData(idx, OC_MODEL_ID, 	modelid);
	SetOwnableCarData(idx, OC_COLOR_1, 		color_1);
	SetOwnableCarData(idx, OC_COLOR_2, 		color_2);
	strmid(g_ownable_car[idx][OC_NUMBER], "------", 0, 8, 8);
	SetOwnableCarData(idx, OC_ALARM, 		false);

	SetOwnableCarData(idx, OC_CREATE, 		gettime());

	format(g_ownable_car[idx][OC_OWNER_NAME], 21, GN(playerid));
	// ----------------------------------------------------------------------------------------

	new vehicleid = CreateVehicle
	(
		GetOwnableCarData(idx, OC_MODEL_ID),
		GetOwnableCarData(idx, OC_POS_X),
		GetOwnableCarData(idx, OC_POS_Y),
		GetOwnableCarData(idx, OC_POS_Z),
		GetOwnableCarData(idx, OC_ANGLE),
		GetOwnableCarData(idx, OC_COLOR_1),
		GetOwnableCarData(idx, OC_COLOR_2),
		-1,
		0,
		VEHICLE_ACTION_TYPE_OWNABLE_CAR,
		idx
	);
	if(vehicleid != INVALID_VEHICLE_ID)
	{
		if(!PI[playerid][pAdmin]) CreateVehicleLabel(vehicleid,GetOwnableCarData(idx,OC_NUMBER), 0xFFFFFFFF, 0, 0, 0, 10.0, 0);
		else CreateVehicleLabel(vehicleid,GetOwnableCarData(idx,OC_NUMBER), COLOR_RED, 0, 0, 0, 10.0, 0);
		SetVehicleParam(vehicleid, V_LOCK, false);

		SetVehicleData(vehicleid, V_MILEAGE, 0.0);
		Fuel[vehicleid] = 50;
	}

	SetInfo(playerid, pCarID, vehicleid);
	format
	(
		query, sizeof query,
		"INSERT INTO ownable_cars \
		(owner_id,model_id,color_1,color_2,pos_x,pos_y,pos_z,angle,fuel,create_time) \
		VALUES \
		('%d','%d','%d','%d','%f','%f','%f','%f','%f','%d')",
		PI[playerid][pID],
		modelid,
		color_1,
		color_2,
		1900.8817,1899.5878,13.2155,
		90.00,Fuel[vehicleid],
		gettime()
	);
	result = mysql_query(dbHandle, query, true);
	SetOwnableCarData(idx, OC_SQL_ID, cache_insert_id());
	cache_delete(result);
	SCM(playerid, COLOR_PRIZE, "Поздравляем с покупкой нового транспорта!");
	SCM(playerid, COLOR_LIME, "Используйте команду - /car, чтобы узнать возможности!");

	return 1;
}
stock ShowGunMenu(playerid,frac_id)
{
	/*switch(frac_id)
	{
 		case 2,7:
	        {
	            SPD(playerid,dialog_take_weapon,2,"{FFA500}Склад оружия","{FFA500}1.{FFFFFF} Дубинка\n\
				{FFA500}2.{FFFFFF} Пистолет 9mm {6495ED}[40 патрон]\n\
				{FFA500}3.{FFFFFF} Desert Eagle {6495ED}[40 патрон]{33CC66}[Сержант]\n\
				{FFA500}4.{FFFFFF} MP5 {6495ED}[120 патронов]\n\
				{FFA500}5.{FFFFFF} M4{6495ED}[120 патронов]{33CC66}[Капитан]\n\
				{FFA500}6.{FFFFFF} Бронежилет","Выбрать","Закрыть");
    		}
	    case 4:
	        {
	            SPD(playerid,dialog_take_weapon,2,"{FFA500}Склад оружия","{FFA500}1.{FFFFFF} Дубинка\n\
				{FFA500}2.{FFFFFF} Пистолет 9mm {6495ED}[40 патрон]\n\
				{FFA500}3.{FFFFFF} Desert Eagle {6495ED}[40 патрон]{33CC66}[Сержант]\n\
				{FFA500}4.{FFFFFF} АК-47 {6495ED}[120 патронов]\n\
				{FFA500}5.{FFFFFF} Снайперская винтовка {6495ED}[10 патронов]{33CC66}[Капитан]\n\
				{FFA500}6.{FFFFFF} Бронежилет","Выбрать","Закрыть");
    		}
	}*/
	new string[100],g;
	query[0] = EOS;
	for(new i = 0; i < 12; i ++)
	{
	    if(!g_fraction_gun[frac_id][i+1]) continue;
		g++;
		format(string, sizeof string, "{FFA500}%d. {FFFFFF}%s\n", g, gun_frac_name[i]);
		strcat(query, string);
	}
	SPD(playerid, dialog_gun, DIALOG_STYLE_LIST, "{"#cGold"}Склад оружия", query, "Далее", "Назад");
	
}
stock IsVehicleInRangeOfPoint(vehicleid, Float:radi, Float:x, Float:y, Float:z)
{
 	new Float:oldposx, Float:oldposy, Float:oldposz;
 	new Float:tempposx, Float:tempposy, Float:tempposz;
	GetVehiclePos(vehicleid, oldposx, oldposy, oldposz);
	tempposx = (oldposx -x);
	tempposy = (oldposy -y);
	tempposz = (oldposz -z);
	if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
	{
		return 1;
	}
	return 0;
}
stock GenerateCarNumber()
{
	static const chars[11] = {'A', 'B', 'C', 'E', 'H', 'K', 'M', 'O', 'P', 'T', 'X'};
	new number[6];

	number[0] = chars[random(sizeof chars)];
	number[1] = random('9' - '0') + '0';
	number[2] = random('9' - '0') + '0';
	number[3] = random('9' - '0') + '0';

	if(number[1] == number[2] && number[2] == number[3] && number[3] == '0')
		number[3] = random('9' - '0') + '1';

	number[4] = chars[random(sizeof chars)];
	number[5] = chars[random(sizeof chars)];

	return number;
}
stock IsPlayerDriver(playerid)
{
	return (IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER);
}
stock LoadObjects()
{
	new fso_map;
	#include <objects/Factory_job>
	#include <objects/OneBuildCompany.pwn>
	#include <objects/Real_estate_agency.pwn>
	#include <objects/Port.pwn>
	#include <objects/Ferma_tool.pwn>
	#include <objects/Ferma_saplings.pwn>
	#include <objects/Ferma_parking.pwn>
	#include <objects/Ferma_watertower.pwn>
	#include <objects/Railway.pwn>
	#include <objects/SF_onelane.pwn>
	#include <objects/pd.pwn>
	#include <objects/pravo.pwn>
	#include <objects/smi.pwn>
	//#include <objects/teplitsy_ferma__amp_1.pwn>
	//#include <objects/teplitsy_ferma__amp_2.pwn>
	//#include <objects/teplitsy_ferma__amp_3.pwn>
}
function: PlayerToggle(playerid)
{
	TogglePlayerControllable(playerid, 1);
	return 1;
}
