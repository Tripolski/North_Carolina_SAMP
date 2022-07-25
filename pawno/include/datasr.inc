#define EDATA_SZ (25)
native gpci(playerid,serial[],maxlen);

static edata_sgdk[EDATA_SZ];

stock egdk_data(playerid) {
    gpci(playerid, edata_sgdk, sizeof edata_sgdk);
 	return edata_sgdk;
}
