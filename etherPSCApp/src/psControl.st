program psControl("ps=00G-QD1")

/*
======================================================================
 
  Abs:  Sequence to control (either standardize or ramp-off) a bitbus 
	control power supply.

	When user requests a standardization, the following is done
        for a specified number of cycles:
	- set current to maximum and wait.
	- set current to zero    and wait.
	At the end, set the current to the config value and wait for 
	the ramp to finish.

	After current is set to zero or the maximum value, always wait for 
        the ramp to finish before waiting further for the specified time.  
        The standardization is automatically aborted if the power supply is 
        switched off (due to either an emergency off or a fault) or if 
	ramping takes too long.  The operator may abort the standardization 
	at any time.  If aborted, the current is set to 
        zero.  A status record is updated as the action progresses.
 
	When user requests a ramp-off, the following is done:
	- set current to zero and wait for ramp to finish.
	- turn off the power supply.

        The ramp-off is automatically aborted if the power supply is 
        switched off (due to either an emergency off or a fault).  If 
        ramping takes too long, the ramp is aborted and the power supply
	is turned off.  A status record is updated as the action progresses.
	A ramp-off cannot be aborted.
 
	When user requests a setpoint change, the following is done:
	- wait for ramp to start.
	- wait for ramp to finish.
	- force processing of alarm limits based on the new setpoint

  Name: psControl.st

  Auth: 12-Jan-2004, Stephanie Allison

======================================================================
*/

option +r;  /* one sequence task per power supply                   */
option -a;  /* All pvGets must be synchronous                       */
option +c;  /* All connections must be made before execution begins */

%%#include <epicsPrint.h>  /* epicsPrintf prototype */
#include "psControl.h"     /* shared PVs and defines with tspControl.st */

#define RAMP_MAX_DELAY 300.0 /* sec */

/* Standardization PVs - per power supply */

int     standardize;
assign  standardize      to "{ps}:Standardize";
monitor standardize;

int     cycle_count;
assign  cycle_count      to "{ps}:StandardizeNumCycle";

int     max_cycle_count;
assign  max_cycle_count  to "{ps}:StandardizeNumCycleMax";
monitor max_cycle_count;

double  ps_curr_drvh;
assign  ps_curr_drvh     to "{ps}:CurrSetpt.DRVH";
monitor ps_curr_drvh;

/* Local Variables */

char*	ps_c;
int	setpt_change;
int	zero_current;
int	wait_needed;
int	ramp_timeout;
int	change_count;
int	standardizing;
int 	ramping_off;
double	wait_delay_increment;
double	wait_delay_total;

ss psControl
{
/*
**  Initialization.
*/
    state psControl_init
    {
	when()
	{
	    ps_c = macValueGet("ps");
	    ps_status = STATUS_DONE;
	    pvPut(ps_status);
	    cycle_count  = 0;
	    pvPut(cycle_count);
	    wait_delay_sofar = 0;
	    pvPut(wait_delay_sofar);
	    standardize = 0;
	    pvPut(standardize);
	    norampoff = 1;
	    pvPut(norampoff);
	    efClear(ps_curr_setpt_ef);
	    ps_limits_flag = 0;
	    pvPut(ps_limits_flag);

	} state psControl_request
    }
/*
**  Wait for the next request to standardize or ramp-off (ignore if power
**  supply is already off).
*/
    state psControl_request
    {
	when((!ps_on) && ((!norampoff) || standardize))
	{
	    ps_status = STATUS_PS_OFF;
	    pvPut(ps_status);
	    norampoff = 1;
	    pvPut(norampoff);
	    standardize = 0;
	    pvPut(standardize);

	} state psControl_request

	when((!ps_on) && efTest(ps_curr_setpt_ef))
	{
	    efClear(ps_curr_setpt_ef);

	} state psControl_request

	when((!norampoff) || standardize)
	{
	    setpt_change  = 0;
	    change_count  = 0;
	    zero_current  = 1;
	    wait_needed   = 0;
	    cycle_count   = 0;
	    pvPut(cycle_count);
	    ps_limits_flag = 1;
	    pvPut(ps_limits_flag);
	    if (!norampoff) {
		ramping_off   = 1;
		standardizing = 0;
		epicsPrintf("Ramp off started for %s\n", ps_c);
	    }
	    else {
		ramping_off   = 0;
		standardizing = 1;
		epicsPrintf("Standardize started for %s\n", ps_c);
	    }
	} state psControl_ramp_wait

	when(efTest(ps_curr_setpt_ef))
	{
	    setpt_change   = 1;
	    wait_needed    = 1;
	    cycle_count    = max_cycle_count + 1;
	    standardizing  = 0;
	    ramping_off    = 0;
	    ps_limits_flag = 1;
	    pvPut(ps_limits_flag);
	    efClear(ps_curr_setpt_ef);

	} state psControl_ramp_start
    }
/*
**  Wait for ramping to finish.  Check for aborts while we wait.
*/
    state psControl_ramp_wait
    {
	entry
	{
	    if (ps_ramp && (!setpt_change)) {
		ps_status = STATUS_RAMPING;
		pvPut(ps_status);
	    }
	    ramp_timeout = 0;
        }
	when((!ps_on) || (standardizing && ((!standardize) || (!norampoff))))
	{
	} state psControl_done

	when(!ps_ramp)
	{
	} state psControl_wait

	when(delay(RAMP_MAX_DELAY))
	{
	    ramp_timeout = 1;

	} state psControl_done
    }
/*
** Wait for a specified amount of time before going to the next setting.
** Check for aborts and ramping while we wait.  Also, increment a timer 
** for users to watch.
*/
    state psControl_wait
    {
	entry
	{
	    wait_delay_increment = WAIT_DELAY;
	    wait_delay_sofar = 0;
	    wait_delay_total = wait_delay;
	    if (setpt_change) wait_delay_total *= 2;
	    pvPut(wait_delay_sofar);
        }

	when((!ps_on) || (standardizing && ((!standardize) || (!norampoff))) ||
	     (setpt_change && (standardize || (!norampoff))) ||
	     ((cycle_count >  max_cycle_count) && 
              (wait_delay_sofar >= wait_delay_total)))
	{
	} state psControl_done

	when(ps_ramp)
	{
	} state psControl_ramp_wait

	when ((!wait_needed) || ((cycle_count <= max_cycle_count) &&
				 (wait_delay_sofar >= wait_delay)))
	{
	} state psControl_set_current

	when (delay(wait_delay_increment))
	{
	    if (!setpt_change) {
		ps_status = STATUS_WAITING;
		pvPut(ps_status);
	    }
	    wait_delay_sofar += wait_delay_increment;
	    pvPut(wait_delay_sofar);
	    wait_delay_increment = wait_delay_total - wait_delay_sofar;
	    if (wait_delay_increment > WAIT_DELAY) 
		wait_delay_increment = WAIT_DELAY;

	} state psControl_wait
    }
/*
** Set the power supply to its next setpoint.
*/
    state psControl_set_current
    {
	when() {
	    wait_needed = 1;
	    if (ramping_off)
	    {
		cycle_count   = max_cycle_count + 1;
		ps_curr_setpt = 0.0;
	    }
	    else if (cycle_count < max_cycle_count) 
	    {
		change_count++;
		cycle_count = change_count/2;
		pvPut(cycle_count);
		zero_current = zero_current ? 0 : 1;
		if (zero_current) ps_curr_setpt = 0.0;
		else              ps_curr_setpt = ps_curr_drvh;
	    } 
	    else 
	    {
		cycle_count   = max_cycle_count + 1;
		ps_curr_setpt = ps_curr_des;
	    }
	    pvPut(ps_curr_setpt);
/*	    epicsPrintf("Set %s current to %lf\n", ps_c, ps_curr_setpt); */

	} state psControl_ramp_start
    }
/*
**  Wait for ramp to start.
*/
    state psControl_ramp_start
    {
	when((!ps_on) || (standardizing && ((!standardize) || (!norampoff))))
	{
	} state psControl_done

	when(ps_ramp || delay(RAMP_DELAY))
	{
	} state psControl_ramp_wait
    }
/*
**  Done - if aborted, take action depending on request, log a message, and
**  update status.
*/
    state psControl_done
    {
	when()
	{
	    if (standardizing) {
		if (!ps_on) {
		    epicsPrintf("Supply off - Standardize aborted for %s\n", ps_c);
		    ps_status = STATUS_PS_OFF;
		}
		else if ((!standardize) || (!norampoff)) {
		    epicsPrintf("Standardize aborted by user for %s\n", ps_c);
		    ps_status = STATUS_ABORT;
		}
		else if (ramp_timeout) {
		    epicsPrintf("Ramp timeout - Standardize aborted for %s\n", ps_c);
		    ps_status = STATUS_RAMP_TIMEOUT;
		}
		else {
		    epicsPrintf("Standardize completed for %s\n", ps_c);
		    ps_status = STATUS_DONE;
		}
		standardize = 0;
		pvPut(standardize);
		if (ps_status != STATUS_DONE) {
		    if (ps_curr_setpt != 0.0) {
			ps_curr_setpt = 0.0;	
			pvPut(ps_curr_setpt);
			efSet(ps_curr_setpt_ef);
/*			epicsPrintf("Set %s current to %lf\n", ps_c, ps_curr_setpt); */
		    }
		}
	    }
	    else if (ramping_off) {
		epicsPrintf("Ramp off completed for %s\n", ps_c);
		ps_status = STATUS_PS_OFF;
		efClear(ps_curr_setpt_ef);
		norampoff = 1;
		pvPut(norampoff);
		standardize = 0;
		pvPut(standardize);
		ps_on_des = 0;
		pvPut(ps_on_des);
	    }
	    pvPut(ps_status);
	    if (!efTest(ps_curr_setpt_ef)) {
		ps_limits_flag = 0;
		pvPut(ps_limits_flag);
	    }
	} state psControl_request
    }
}

exit{}
