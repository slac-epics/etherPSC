/*                                Copyright 1996
**                                      by
**                         The Board of Trustees of the
**                       Leland Stanford Junior University.
**                              All rights reserved.
**
**
**         Work supported by the U.S. Department of Energy under contract
**       DE-AC03-76SF00515.
**
**                               Disclaimer Notice
**
**        The items furnished herewith were developed under the sponsorship
**   of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
**   Leland Stanford Junior University, nor their employees, makes any war-
**   ranty, express or implied, or assumes any liability or responsibility
**   for accuracy, completeness or usefulness of any information, apparatus,
**   product or process disclosed, or represents that its use will not in-
**   fringe privately-owned rights.  Mention of any product, its manufactur-
**   er, or suppliers shall not, nor is it intended to, imply approval, dis-
**   approval, or fitness for any particular use.  The U.S. and the Univer-
**   sity at all times retain the right to use and disseminate the furnished
**   items for any purpose whatsoever.                       Notice 91 02 01
*/
/*=============================================================================

  Abs:  PS Calculations.

  Name: subPS.c      
	   subPSRegister   - Register All Subroutines
	   subPSInit       - General Initialization
           subPSLimits     - Calculate alarm limits

  Proto: not required and not used.  All functions called by the
         subroutine record get passed one argument:

         psub                       Pointer to the subroutine record data.
          Use:  pointer               
          Type: struct subRecord *    
          Acc:  read/write            
          Mech: reference

         All functions return a long integer.  0 = OK, -1 = ERROR.
         The subroutine record ignores the status returned by the Init
         routines.  For the calculation routines, the record status (STAT) is
         set to SOFT_ALARM (unless it is already set to LINK_ALARM due to
         severity maximization) and the severity (SEVR) is set to psub->brsv
         (BRSV - set by the user in the database though it is expected to
          be invalid).

  Auth: 08-Jan-2004, Stephanie Allison

=============================================================================*/

#include <subRecord.h>        /* for struct subRecord    */
#include <registryFunction.h> /* for registryFunctionAdd */
#include <epicsExport.h>      /* for epicsExportRegistrar*/

long subPSInit(struct subRecord *psub)
{
  /*
   * General purpose initialization required since all subroutine records
   * require a non-NULL init routine even if no initialization is required.  
   * Note that most subroutines in this file use this routine as an init
   * routine.  If init logic is needed for a specific subroutine, create a 
   * new routine for it - don't modify this one.
   */
  return 0;
}

long subPSLimits(struct subRecord *psub)
{
  /*
   * Calculate alarm limits from desired current.  If desired current is 0 or
   * the disable alarms flag is set, then use max/min values to disable alarms.
   *
   * Inputs:
   *          A = Desired Current
   *          B = Maximum (DRVH) 
   *          C = Minimum (DRVL)
   *          D = Fraction for Alarm   Limits (HIHI, LOLO) (0 = disable)
   *          E = Fraction for Warning Limits (HIGH, LOW)  (0 = disable)
   *          F = Setpoint currently changing? (0=no, 1=yes)
   *                                     (0=calc limits, 1=set limits to min/max)
   *          G = State    (0=off, 1=on) (1=calc limits, 0=set limits to min/max)
   *          H = Minimum allowed offset
   * Outputs:
   *          I = HIHI value
   *          J = HIGH value
   *          K = LOW  value
   *          L = LOLO value
   *        VAL = Not Used
   */
  psub->i = psub->b+1;
  psub->j = psub->b+1;
  psub->k = psub->c-1;
  psub->l = psub->c-1;
  if ((psub->a > 0.01) && (psub->f < 0.01) && (psub->g > 0.01)) {
    if (psub->d > 0.0) {
      psub->l = psub->d * psub->a;
      if (psub->l < psub->h) psub->l = psub->h;
      psub->i = psub->a + psub->l;
      psub->l = psub->a - psub->l;
    }
    if (psub->e > 0.0) {
      psub->k = psub->e * psub->a;
      if (psub->k < psub->h) psub->k = psub->h;
      psub->j = psub->a + psub->k;
      psub->k = psub->a - psub->k;
    }
  }  
  return 0;
}

void subPSRegister(void)
{
  registryFunctionAdd("subPSInit"     , (void(*)())subPSInit   );
  registryFunctionAdd("subPSLimits"   , (void(*)())subPSLimits );
}
epicsExportRegistrar(subPSRegister);
