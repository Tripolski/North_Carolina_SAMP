#if defined _SYSTEM_VEHICLE
	#endinput
#endif
#define _SYSTEM_VEHICLE

// ------------------------------------
#define GetVehicleInfo(%0,%1)		g_vehicle_info[%0][%1]
#define GetVehicleName(%0)			GetVehicleInfo(GetVehicleData(%0, V_MODELID)-400, VI_NAME)

// ------------------------------------
#define GetVehicleData(%0,%1)		g_vehicle_data[%0][%1]
#define SetVehicleData(%0,%1,%2)	g_vehicle_data[%0][%1] = %2
#define ClearVehicleData(%0)		g_vehicle_data[%0] = g_vehicle_default_values
#define IsValidVehicleID(%0)		(1 <= %0 < MAX_VEHICLES)

// ------------------------------------
#define GetVehicleParamEx(%0,%1) g_vehicle_params[%0][%1]

// ------------------------------------
#define VEHICLE_ACTION_TYPE_NONE 	-1
#define VEHICLE_ACTION_ID_NONE 		-1

// ------------------------------------
#define VEHICLE_PARAM_ON	(1)
#define VEHICLE_PARAM_OFF	(0)

// ------------------------------------
native IsValidVehicle(vehicleid);

// ------------------------------------
enum E_VEHICLE_STRUCT
{
	V_MODELID,
	Float: V_SPAWN_X,
	Float: V_SPAWN_Y,
	Float: V_SPAWN_Z,
	Float: V_SPAWN_ANGLE,
	V_COLOR_1,
	V_COLOR_2,
	V_RESPAWN_DELAY,
	V_ADDSIREN,
	// -------------
	V_ACTION_TYPE,
	V_ACTION_ID,
	// -------------
	V_DRIVER_ID,
	// -------------
	V_LIMIT,
	V_ALARM,
	Float: V_FUEL,
	Float: V_MILEAGE,
	// -------------
	Text3D: V_LABEL,
	// -------------
	Float: V_HEALTH,
	V_LAST_LOAD_TIME
};

// ------------------------------------
enum E_VEHICLE_PARAMS_STRUCT
{
	V_ENGINE, 	// двигатель
	V_LIGHTS, 	// фары
	V_ALARM,	// сигнализация
	V_LOCK, 	// закрыто ли
	V_BONNET, 	// капот
	V_BOOT, 	// багажник
	V_OBJECTIVE // отображене стрелки над автоqa
};

// ------------------------------------
enum E_VEHICE_INFO_STRUCT
{
	VI_NAME[21],	// название
	VI_PRICE,		// гос. стоимость
	VT_RENT_PRICE,	// стоимость аренды
	VI_TYPE			// тип
};

// ------------------------------------
new g_vehicle_data[MAX_VEHICLES][E_VEHICLE_STRUCT];
new 
	g_vehicle_default_values[E_VEHICLE_STRUCT] = 
{
	0,
	0.0,
	0.0,
	0.0,
	0.0,
	0,
	0,
	0,
	0,
	VEHICLE_ACTION_TYPE_NONE,
	VEHICLE_ACTION_ID_NONE,
	INVALID_PLAYER_ID,
	false,
	false,
	40.0,
	0.0,
	Text3D:-1,
	1000.0,
	0
};
new g_vehicle_params[MAX_VEHICLES][E_VEHICLE_PARAMS_STRUCT];

new const
	g_vehicle_info[212][E_VEHICE_INFO_STRUCT] = 
{
	{"Landstal",	0,		8500,	2},		// 400
	{"Bravura",				0,		500,	0},		// 401
	{"Buffalo",		0,		6000,	1},		// 402
	{"Linerun", 			0, 			0,		0},		// 403
	{"Peren",		0,		800,	2},		// 404
	{"Sentinel",	0,		8000,	1},		// 405
	{"Dumper", 	0, 			0,		0},		// 406
	{"Firetruk", 			0,			0,		0},		// 407
	{"Trash", 			0,			0,		0},		// 408
	{"Stretch",				0,	200000,	2},		// 409
	{"Manana",	0,		7800,	0},		// 410
	{"Infernus",			0,		3800,	2},		// 411
	{"Voodoo",			0,		600,	0},		// 412
	{"Pony",				0,			0,		0},		// 413
	{"Mule", 			0,			0,		0},		// 414
	{"",				0,	15000,	2},		// 415
	{"", 				0,			0,		0},		// 416
	{"",			0,			0,		0},		// 417
	{"", 		0,		6400,	0},		// 418
	{"",			0,		    0,	    0},		// 419
	{"", 				0,			0,		0},		// 420
	{"",		0,		8000,	1},		// 421
	{"",			0,		1000,	0},		// 422
	{"", 			0,			0,		0},		// 423
	{"",					10000,		100,	0},		// 424
	{"", 				0,			0,		0},		// 425
	{"",			0,	38000,	2},		// 426
	{"", 			0,			0,		0},		// 427
	{"", 			0,			0,		0},		// 428
	{"", 				0,	18000,	0},		// 429
	{"", 			0,			0,		0},		// 430
	{"", 			0,			0,		0},		// 431
	{"", 				0,			0,		0},		// 432
	{"", 		0,			0,		0},		// 433
	{"",			0,		    0,	    0},		// 434
	{"", 				0,			0,		0},		// 435
	{"",	45000,	16500,	1},		// 436
	{"", 				0,			0,		0},		// 437
	{"", 				0,			0,		0},		// 438
	{"",			35000,		350,	0},		// 439
	{"", 				600000,		0,		0},		// 440
	{"", 				0,			0,		0},		// 441
	{"", 				60000,		100,	0},		// 442
	{"", 			0,			0,		0},		// 443
	{"", 				0,			0,		0},		// 444
	{"",			100000,		2400,	0},		// 445
	{"", 				0,			0,		0},		// 446
	{"", 		0,			0,		0},		// 447
	{"", 			0,			0,		0},		// 448
	{"", 			0,			0,		0},		// 449
	{"", 				0,			0,		0},		// 450
	{"",	2000000,	22000,	2},		// 451
	{"", 			0,			0,		0},		// 452
	{"", 				0,			0,		0},		// 453
	{"", 				0,			0,		0},		// 454
	{"", 			0,			0,		0},		// 455
	{"", 			0,			0,		0},		// 456
	{"", 			0,			0,		0},		// 457
	{"",			240000,		2400,	0},		// 458
	{"", 				0,			0,		0},		// 459
	{"", 		0,			0,		0},		// 460
	{" ",			70000,		700,	0},		// 461
	{"",			18000,		200,	0},		// 462
	{"",				120000,		1200,	1},		// 463
	{"", 			0,			0,		0},		// 464
	{"", 				0,			0,		0},		// 465
	{" ",			300000,	28000,	2},		// 466
	{" ",				35000,		350,	0},		// 467
	{" ",				40000,		400,	0},		// 468
	{"", 			0,			0,		0},		// 469
	{"", 				0,			0,		0},		// 470
	{"",			120000,		1200,	1},		// 471
	{"", 				0,			0,		0},		// 472
	{"",				0,			0,		0},		// 473
	{" ",				150000,		600,	0},		// 474
	{" ",	1100000,	14500,	1},		// 475
	{"", 		0,			0,		0},		// 476
	{" ",			950000,		9000,	1},		// 477
	{" ",			45000,		450,	0},		// 478
	{" ",			300000,		2400,	0},		// 479
	{"",	1200000,	28000,	2},		// 480
	{" ",		4000,		100,	0},		// 481
	{"", 			1200000,		520000,	1},		// 482
	{" ", 			0,			0,		0},		// 483
	{"", 			0,			0,		0},		// 484
	{" ", 			0,			0,		0},		// 485
	{"", 			0,			0,		0},		// 486
	{"", 				0,			0,		0},		// 487
	{" ", 			0,			0,		0},		// 488
	{"  ",		7500000,	19000,	2},		// 489
	{" ", 	300000,	59000,	2},		// 490
	{" ",		800000,		8000,	1},		// 491
	{"",			180000,		1800,	0},		// 492
	{"", 				0,			0,		0},		// 493
	{" ", 			    200000,	56000,	0},		// 494
	{" ", 250000,	15000,	2},		// 495
	{"",				70000,		700,	0},		// 496
	{"", 			0,			0,		0},		// 497
	{" ", 			0,			0,		0},		// 498
	{" ", 				0,			0,		0},		// 499
	{" ",			25000,		400,	0},		// 500
	{"", 				0,			0,		0}, 	// 501
	{" ", 			200000,	56000,	0}, 	// 502
	{"", 150000,	56000,	2}, 	// 503
	{"", 			0,			0,		0}, 	// 504
	{"",	200000,	42000,	2},		// 505
	{" ",		100000,	29000,	1},		// 506
	{" ",			100000,		2400,	0}, 	// 507
	{" ",			100000,		1000,	0}, 	// 508
	{" ",	6000,		150,	0}, 	// 509
	{" ",	10000,		300,	0}, 	// 510
	{"", 				0,			0,		0}, 	// 511
	{"",			0,			0,		0}, 	// 512
	{"", 				0,			0,		0}, 	// 513
	{" ",			0,			0,		0}, 	// 514
	{"", 				0,			0,		0}, 	// 515
	{" ",			1250000,		1800,	1}, 	// 516
	{" ",			150000,		1500,	0}, 	// 517
	{" ",			100000,		1000,	0}, 	// 518
	{"", 				0,			0,		0}, 	// 519
	{"", 		0,			0,		0}, 	// 520
	{" ",		35000,		350,	0}, 	// 521
	{"",				600000,		6000,	2}, 	// 522
	{" ",			0,		    320,	0}, 	// 523
	{"", 			0,			0,		0}, 	// 524
	{"", 			0,			0,		0}, 	// 525
	{" ",			30000,		1600,	0}, 	// 526
	{"",				150000,		    2400,	0}, 	// 527
	{"", 			0,			0,		0},		// 528
	{" ",			11000000,		2500,	1},		// 529
	{"", 			0,			0,		0}, 	// 530
	{"", 			0,			0,		0}, 	// 531
	{"", 			0,			0,		0}, 	// 532
	{" ",		220000,	15000,	2}, 	// 533
	{"",			0,		    4000,	1}, 	// 534
	{" ",			250000,		4000,	0}, 	// 535
	{"",				20000,		    3500,	1}, 	// 536
	{"", 				0,			0,		0}, 	// 537
	{"", 				0,			0,		0}, 	// 538
	{" ", 		0,			0,		0}, 	// 539
	{"",			25000,		1800,	0}, 	// 540
	{"Bullet",		0,	42000,	2}, 	// 541
	{"",			130000,		1300,	0}, 	// 542
	{"", 				200000,	        48000,	0}, 	// 543
	{"", 			0,			0,		0}, 	// 544
	{" ", 		0, 		    100,	0}, 	// 545
	{"",			60000,		600,	0}, 	// 546
	{" ",			60000,		600,	0}, 	// 547
	{" ", 			0, 			0,		0},		// 548
	{" ",				5000,		35,		0},		// 549
	{" ",	350000,		1400,	0}, 	// 550
	{" ",			130000,		110,	0}, 	// 551
	{" ", 		0,		    2100,	0}, 	// 552
	{"", 			0,			0,		0}, 	// 553
	{" ", 			0,			0,		0}, 	// 554
	{" ",				25000,		50,		0}, 	// 555
	{"", 				0,			0,		0}, 	// 556
	{"", 				0,			0,		0}, 	// 557
	{"",				0,		    4500,	1}, 	// 558
	{" ",		300000,	16000,	1}, 	// 559
	{" ",				2650000,	26500,	1}, 	// 560
	{" ",			60000,		600,	0},		// 561
	{" ",		2500000,	25000,	2}, 	// 562
	{" ", 			0,			0,		0}, 	// 563
	{"", 				0,			0,		0}, 	// 564
	{" ",			170000,		1700,	0}, 	// 565
	{" ",			100000,		1000,	0}, 	// 566
	{"",				15000,		2000,	0}, 	// 567
	{"",				50000,		500,	0},		// 568
	{"", 				0,			0,		0}, 	// 569
	{"",    			0,			0,		0}, 	// 570
	{"", 				0,			0,		0}, 	// 571
	{"", 		0,			0,		0}, 	// 572 
	{" ", 		2000000,	20000,	0}, 	// 573
	{" ", 			0,			0,		0},		// 574
	{" ",				60000,		600,	0}, 	// 575
	{" ",			60000,		600,	0}, 	// 576
	{" ", 				0,			0,		0}, 	// 577
	{" ", 			0,			0,		0}, 	// 578
	{"",	150000,	48000,	0},		// 579
	{" ",				2000000,	15000,	0}, 	// 580
	{" ",				70000,		700,	0}, 	// 581
	{" ",			0,			0,		0}, 	// 582
	{"", 				0,			0,		0}, 	// 583
	{"", 			0,			0,		0}, 	// 584
	{" ",		280000,		2800,	0}, 	// 585
	{" ",	40000,		400,	0}, 	// 586
	{" ",			200000,	24000,	0}, 	// 587
	{"", 			0,			0,		0}, 	// 588
	{" ",		1240000,	12400,	0}, 	// 589
	{"", 				0,			0,		0}, 	// 590
	{"", 				0,			0,		0}, 	// 591
	{"", 	     		0,			0,		0}, 	// 592
	{"", 				0,			0,		0}, 	// 593
	{"", 				0,			0,		0}, 	// 594
	{"", 				0,			0,		0}, 	// 595
	{"", 			0,			0,		0}, 	// 596
	{"", 			0,			0,		0}, 	// 597
	{" ", 			0,			0,		0}, 	// 598
	{" ", 			0,			0,		0}, 	// 599
	{" ",			80000,		800,	0}, 	// 600
	{"", 				0,			0,		0}, 	// 601
	{" ",			100000,	34000,	0}, 	// 602
	{" ", 		100000,	17000,	0}, 	// 603
	{"", 			0,			0,		0}, 	// 604
	{" ", 			0,			0,		0},		// 605
	{" ", 			0,			0,		0},		// 606
	{" ", 			0,			0,		0},		// 607
	{"", 			0,			0,		0},		// 608
	{"", 				0,			0,		0},		// 609
	{"", 				0,			0,		0},		// 610
	{"", 		0,			0,		0}		// 611
};
// ------------------------------------

stock SetVehicleDataAll(vehicleid, modelid, Float:x, Float:y, Float:z, Float:angle, color1, color2, respawn_delay, addsiren=0, action_type, action_id)
{
	if(IsValidVehicleID(vehicleid))
	{
		SetVehicleData(vehicleid, V_MODELID, modelid);
		
		SetVehicleData(vehicleid, V_SPAWN_X, 		x);
		SetVehicleData(vehicleid, V_SPAWN_Y, 		y);
		SetVehicleData(vehicleid, V_SPAWN_Z, 		z);
		SetVehicleData(vehicleid, V_SPAWN_ANGLE, 	angle);
		
		SetVehicleData(vehicleid, V_COLOR_1, 	color1);
		SetVehicleData(vehicleid, V_COLOR_2, 	color2);
		
		SetVehicleData(vehicleid, V_RESPAWN_DELAY, 	respawn_delay);
		SetVehicleData(vehicleid, V_ADDSIREN, 		addsiren);
		
		SetVehicleData(vehicleid, V_ACTION_TYPE, 	action_type);
		SetVehicleData(vehicleid, V_ACTION_ID, 		action_id);
		SetVehicleData(vehicleid, V_DRIVER_ID, 		INVALID_PLAYER_ID);
		
		SetVehicleData(vehicleid, V_FUEL, 40.0);
		SetVehicleData(vehicleid, V_MILEAGE, 0.0);
		SetVehicleData(vehicleid, V_LIMIT, true);

		SetVehicleData(vehicleid, V_HEALTH, 1000.0);
	
		SetVehicleParamsEx(vehicleid, IsABike(vehicleid) ? VEHICLE_PARAM_ON : VEHICLE_PARAM_OFF, VEHICLE_PARAM_OFF, VEHICLE_PARAM_OFF, VEHICLE_PARAM_OFF, VEHICLE_PARAM_OFF, VEHICLE_PARAM_OFF, VEHICLE_PARAM_OFF);
	}
}

stock n_veh_AddStaticVehicleEx(modelid, Float:x, Float:y, Float:z, Float:angle, color1, color2, respawn_delay, addsiren=0, action_type=VEHICLE_ACTION_TYPE_NONE, action_id=VEHICLE_ACTION_ID_NONE)
{
	static n_veh_vehicleid = INVALID_VEHICLE_ID;
	
	n_veh_vehicleid = AddStaticVehicleEx(modelid, x, y, z, angle, color1, color2, respawn_delay);
	SetVehicleDataAll(n_veh_vehicleid, modelid, x, y, z, angle, color1, color2, respawn_delay, addsiren, action_type, action_id);

	return n_veh_vehicleid;
	
	// The vehicle ID of the vehicle created (1 - MAX_VEHICLES).
	// INVALID_VEHICLE_ID (65535) if vehicle was not created (vehicle limit reached or invalid vehicle model ID passed).
}
#if defined _ALS_AddStaticVehicleEx
    #undef AddStaticVehicleEx
#else
    #define _ALS_AddStaticVehicleEx
#endif
#define AddStaticVehicleEx n_veh_AddStaticVehicleEx

stock n_veh_AddStaticVehicle(modelid, Float:x, Float:y, Float:z, Float:angle, color1, color2, action_type=VEHICLE_ACTION_TYPE_NONE, action_id=VEHICLE_ACTION_ID_NONE)
{
	static n_veh_vehicleid = INVALID_VEHICLE_ID;
	
	n_veh_vehicleid = AddStaticVehicle(modelid, x, y, z, angle, color1, color2);
	SetVehicleDataAll(n_veh_vehicleid, modelid, x, y, z, angle, color1, color2, 0, 0, action_type, action_id);

	return n_veh_vehicleid;
	
	// The vehicle ID of the vehicle created (1 - MAX_VEHICLES).
	// INVALID_VEHICLE_ID (65535) if vehicle was not created (vehicle limit reached or invalid vehicle model ID passed).
}
#if defined _ALS_AddStaticVehicle
    #undef AddStaticVehicle
#else
    #define _ALS_AddStaticVehicle
#endif
#define AddStaticVehicle n_veh_AddStaticVehicle

stock n_veh_CreateVehicle(modelid, Float:x, Float:y, Float:z, Float:angle, color1, color2, respawn_delay, addsiren=0, action_type=VEHICLE_ACTION_TYPE_NONE, action_id=VEHICLE_ACTION_ID_NONE)
{
	static n_veh_vehicleid = INVALID_VEHICLE_ID;
	
	n_veh_vehicleid = CreateVehicle(modelid, x, y, z, angle, color1, color2, respawn_delay);
	SetVehicleDataAll(n_veh_vehicleid, modelid, x, y, z, angle, color1, color2, respawn_delay, addsiren, action_type, action_id);

	return n_veh_vehicleid;
	
	// The vehicle ID of the vehicle created (1 - MAX_VEHICLES).
	// INVALID_VEHICLE_ID (65535) if vehicle was not created (vehicle limit reached or invalid vehicle model ID passed).
}
#if defined _ALS_CreateVehicle
    #undef CreateVehicle
#else
    #define _ALS_CreateVehicle
#endif
#define CreateVehicle n_veh_CreateVehicle

stock n_veh_DestroyVehicle(vehicleid)
{
	if(IsValidVehicleID(vehicleid))
	{
		ClearVehicleData(vehicleid);
		DestroyVehicleLabel(vehicleid);
	}
	return DestroyVehicle(vehicleid);
}
#if defined _ALS_DestroyVehicle
    #undef DestroyVehicle
#else
    #define _ALS_DestroyVehicle
#endif
#define DestroyVehicle n_veh_DestroyVehicle

public OnGameModeInit()
{
    for(new idx = 0; idx < MAX_VEHICLES; idx ++)
	{
		ClearVehicleData(idx);
	}
	
#if defined n_veh_OnGameModeInit
    n_veh_OnGameModeInit();
#endif
    return 1;
}
#if defined _ALS_OnGameModeInit
    #undef OnGameModeInit
#else
    #define _ALS_OnGameModeInit
#endif
#define OnGameModeInit n_veh_OnGameModeInit
#if defined n_veh_OnGameModeInit
forward n_veh_OnGameModeInit();
#endif  

// ---------------------------------------------------
stock SetVehicleParamsInit(vehicleid)
{	
	GetVehicleParamsEx
	(
		vehicleid, 
		g_vehicle_params[vehicleid][V_ENGINE],
		g_vehicle_params[vehicleid][V_LIGHTS],
		g_vehicle_params[vehicleid][V_ALARM],
		g_vehicle_params[vehicleid][V_LOCK],
		g_vehicle_params[vehicleid][V_BONNET],
		g_vehicle_params[vehicleid][V_BOOT],
		g_vehicle_params[vehicleid][V_OBJECTIVE]
	);
}

stock GetVehicleParam(vehicleid, E_VEHICLE_PARAMS_STRUCT:paramid)
{
	SetVehicleParamsInit(vehicleid);
	return g_vehicle_params[vehicleid][paramid];
}

stock SetVehicleParam(vehicleid, E_VEHICLE_PARAMS_STRUCT:paramid, set_value)
{
	SetVehicleParamsInit(vehicleid);
	g_vehicle_params[vehicleid][paramid] = bool: set_value;
	
	SetVehicleParamsEx
	(
		vehicleid,
		g_vehicle_params[vehicleid][V_ENGINE],
		g_vehicle_params[vehicleid][V_LIGHTS],
		g_vehicle_params[vehicleid][V_ALARM],
		g_vehicle_params[vehicleid][V_LOCK],
		g_vehicle_params[vehicleid][V_BONNET],
		g_vehicle_params[vehicleid][V_BOOT],
		g_vehicle_params[vehicleid][V_OBJECTIVE]
	);
}

stock CreateVehicleLabel(vehicleid, text[], color, Float:x, Float:y, Float:z, Float:drawdistance, testlos = 0, worldid = -1, interiorid = -1, playerid = -1, Float:streamdistance = STREAMER_3D_TEXT_LABEL_SD)
{
	if(IsValidVehicle(vehicleid))
	{
		SetVehicleData(vehicleid, V_LABEL, CreateDynamic3DTextLabel(text, color, x, y, z, drawdistance, INVALID_PLAYER_ID, vehicleid, testlos, worldid, interiorid, playerid, streamdistance));
	}
	return 1;
}

stock UpdateVehicleLabel(vehicleid, color, text[])
{
	if(IsValidVehicleID(vehicleid))
	{
		if(IsValidDynamic3DTextLabel(GetVehicleData(vehicleid, V_LABEL)))
		{
			UpdateDynamic3DTextLabelText(GetVehicleData(vehicleid, V_LABEL), color, text);
		}
	}
	return 1;
}

stock DestroyVehicleLabel(vehicleid)
{
	if(IsValidVehicleID(vehicleid))
	{
		if(IsValidDynamic3DTextLabel(GetVehicleData(vehicleid, V_LABEL)))
		{
			DestroyDynamic3DTextLabel(GetVehicleData(vehicleid, V_LABEL));
			SetVehicleData(vehicleid, V_LABEL, Text3D: -1);
		}
	}
	return 1;
}
