#include <YSI\y_hooks>

#if !defined MAX_PLAYER_BUILDING
	#define MAX_PLAYER_BUILDING 500
#endif

enum EBUILDING
{
	id,
	modelid,
	Float:X,
	Float:Y,
	Float:Z,
	Float:radius
}

new iBuildInfo[MAX_PLAYER_BUILDING][EBUILDING];

/*
native RefreshBuilding();
native RemovePlayerBuilding(playerid,modelid,X,Y,Z,radius);
native RemoveBuildingForAll(modelid,X,Y,Z,radius);
native RestoreBuilding(slot);
*/

hook OnGameModeInit()
{
	for(new i=0;i<MAX_PLAYER_BUILDING;++i)
	{
		iBuildInfo[i][modelid] = -1;
		iBuildInfo[i][id] = -1;
	}
	return 0;
}

stock RefreshBuilding()
{
	for(new i=0;i<MAX_PLAYER_BUILDING;++i)
	{
		iBuildInfo[i][modelid] = -1;
		iBuildInfo[i][id] = -1;
	}
	return 1;	
}
stock RemovePlayerBuilding(_playerid,_modelid,Float:_X,Float:_Y,Float:_Z,Float:_radius)
{
	new slot=-1;
	for(new i=0;i<MAX_PLAYER_BUILDING;++i)
	{
	    if(iBuildInfo[i][modelid] != -1) continue;
	    slot = i;
		break;
	}
	if(slot == -1)
	{
	    printf("ERROR:No more space left to store data");
	    printf("Failed to remove Building for %d(model : %s, locations(%f,%f,%f), radius %f)",_playerid,_modelid,_X,_Y,_Z,_radius);
	    return -1;
	}
	RemoveBuildingForPlayer(_playerid,_modelid,_X,_Y,_Z,_radius);
	iBuildInfo[slot][id] = _playerid;
	iBuildInfo[slot][modelid] = _modelid;
	iBuildInfo[slot][X] = _X;
	iBuildInfo[slot][Y] = _Y;
	iBuildInfo[slot][Z] = _Z;
	iBuildInfo[slot][radius] = _radius;
	return slot;
}

stock RemoveBuildingForAll(_modelid,Float:_X,Float:_Y,Float:_Z,Float:_radius)
{
	new slot = -1;
	for(new i=0;i<MAX_PLAYER_BUILDING;++i)
	{
	    if(iBuildInfo[i][modelid] != -1) continue;
	    slot = i;
		break;
	}
	if(slot == -1)
	{
	    printf("ERROR:No more space left to store data");
	    printf("Failed to remove Building (model : %s, locations(%f,%f,%f), radius %f)",_modelid,_X,_Y,_Z,_radius);
	    return -1;
	}
	
	for(new i=0;i<MAX_PLAYERS;++i)
	{
	    RemoveBuildingForPlayer(i,_modelid,_X,_Y,_Z,_radius);
	}
	iBuildInfo[slot][id] = -1;
	iBuildInfo[slot][modelid] = _modelid;
	iBuildInfo[slot][X] = _X;
	iBuildInfo[slot][Y] = _Y;
	iBuildInfo[slot][Z] = _Z;
	iBuildInfo[slot][radius] = _radius;
	return slot;
}

stock RestoreBuilding(slot)
{
	if(slot < 0 || slot > MAX_PLAYER_BUILDING)
	{
	    printf("ERROR:Invalid slot %d",slot);
	    return -1;
	}
	if(iBuildInfo[slot][modelid] == -1)
	{
	    printf("ERROR:%d slot not yet used",slot);
	    return -1;
	}
	if (iBuildInfo[slot][id] == -1)
	{
	    CreateObject(iBuildInfo[slot][modelid],iBuildInfo[slot][X],iBuildInfo[slot][Y],iBuildInfo[slot][Z],0,0,0,0);
	}
	else
	{
	   CreatePlayerObject(iBuildInfo[slot][id],iBuildInfo[slot][modelid],iBuildInfo[slot][X],iBuildInfo[slot][Y],iBuildInfo[slot][Z],0,0,0,0);
	}
	iBuildInfo[slot][id] = iBuildInfo[slot][modelid] = -1;
	return 1;
	
}