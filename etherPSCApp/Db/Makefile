TOP=../..
include $(TOP)/configure/CONFIG

#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE

#----------------------------------------------------
#  Optimization of DB files using dbst (DEFAULT: NO)
#DB_OPT = YES

#----------------------------------------------------
#  Creation of <name>.dbd file from <name>Include.dbd

#----------------------------------------------------
# Power Supply Control
DB += commonPS.template
DB += etherPSC.template
DB += etherPSCOne.db
DB += etherPSCBipolar.db
#
#----------------------------------------------------
# Declare template files which do not show up in DB

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE
