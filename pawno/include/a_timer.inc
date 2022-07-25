#define MAX_TIMERS 40
#define TIMERS_UPDATE 250
#define INVALID_TIMER_ID (0xFFFF)
 
forward UpdateTimers();
 
enum TInfo
{
        TTime,
        TInterval,
        TRepeating
};
new TimerInfo[MAX_TIMERS][TInfo];
new TimerName[MAX_TIMERS][75];
new StartTimers, UpdateTimersID;
public UpdateTimers()
{
        for(new A; A != MAX_TIMERS; A++)
        {
                if(!TimerInfo[A][TTime]) continue;
                if(TimerInfo[A][TTime] <= GetTickCount())
                {
                        if(!TimerInfo[A][TRepeating])
                        {
                                TimerInfo[A][TTime] = 0;
                                if(!--StartTimers) KillTimer(UpdateTimersID);
                        }
                        else TimerInfo[A][TTime] = GetTickCount()+TimerInfo[A][TInterval];
                        CallLocalFunction(TimerName[A], "");
                }
        }
        return 1;
}
 
stock TSetTimer(const funcname[], interval, repeating)
{
        if(!StartTimers) UpdateTimersID = SetTimer("UpdateTimers", TIMERS_UPDATE, 1);
        for(new A; A != MAX_TIMERS; A++)
        {
                if(TimerInfo[A][TTime] != 0) continue;
                strmid(TimerName[A], funcname, 0, strlen(funcname));
                TimerInfo[A][TInterval] = interval;
                TimerInfo[A][TTime] = GetTickCount()+interval;
                TimerInfo[A][TRepeating] = repeating;
                StartTimers++;
                return A;
        }
        return INVALID_TIMER_ID;
}
 
stock TKillTimer(timerid)
{
        if(TimerInfo[timerid][TTime] != 0)
        {
                TimerInfo[timerid][TTime] = 0;
                if(!--StartTimers) KillTimer(UpdateTimersID);
        }
        return 1;
}
