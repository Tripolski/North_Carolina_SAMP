forward OnPlayerProxy(playerid);

stock testproxy(playerid)
{
    new plrIP[16], link[128];
    GetPlayerIp(playerid, plrIP, sizeof(plrIP));

    format(link, sizeof(link), "check.getipintel.net/check.php?ip=%s", plrIP);

    HTTP(playerid, HTTP_GET, link, "", "OnProxyResponse");
}


forward OnProxyResponse(playerid, response_code, data[]);
public OnProxyResponse(playerid, response_code, data[])
{
    if(response_code == 200 && IsPlayerConnected(playerid))
    {
        new Float:proxyscore = floatstr(data);

        if (proxyscore > 0.98)
        {
            CallRemoteFunction("OnPlayerProxy", "i", playerid);
        }
    }
}