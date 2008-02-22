/*
======================================================================
 
  Abs:  PVs and Defines shared by tspControl and standardize sequences.
  
  Name: psControl.h

  Auth: 02-Dec-2003, Stephanie Allison
 
======================================================================
*/

#define RAMP_DELAY        5.0   /* sec */
#define WAIT_DELAY        1.0   /* sec */

#define STATUS_NOT_DONE     0
#define STATUS_RAMPING      1
#define STATUS_WAITING      2
#define STATUS_ABORT        3
#define STATUS_PS_OFF       4
#define STATUS_RAMP_TIMEOUT 5
#define STATUS_ERROR        6
#define STATUS_TIMEOUT      7
#define STATUS_NOCONTROL    8
#define STATUS_DONE         10

double  wait_delay_sofar;
assign  wait_delay_sofar to "{ps}:ControlDelay";

double  wait_delay;
assign  wait_delay       to "{ps}:ControlDelayMax";
monitor wait_delay;
evflag  wait_delay_ef;
sync    wait_delay wait_delay_ef;

int     norampoff;
assign  norampoff        to "{ps}:Ramp";
monitor norampoff;

int     ps_on;
assign  ps_on            to "{ps}:State";
monitor ps_on;

int     ps_on_des;
assign  ps_on_des        to "{ps}:StateSetpt";

int     ps_ramp;
assign  ps_ramp          to "{ps}:RampStatus";
monitor ps_ramp;

int     ps_status;
assign  ps_status        to "{ps}:ControlStatus";

double  ps_curr_setpt;
assign  ps_curr_setpt    to "{ps}:CurrSetpt";
monitor ps_curr_setpt;
evflag  ps_curr_setpt_ef;
sync    ps_curr_setpt ps_curr_setpt_ef;

double  ps_curr_des;
assign  ps_curr_des      to "{ps}:CurrSetptDes";
monitor ps_curr_des;
evflag  ps_curr_des_ef;
sync    ps_curr_des ps_curr_des_ef;

int     ps_limits_flag;
assign  ps_limits_flag   to "{ps}:Limits.F";
