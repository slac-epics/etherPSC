# Makefile
TOP=../..
include $(TOP)/configure/CONFIG
#
#=============================
# build a library

DBD += devEtherPSC.dbd
DBD += psControl.dbd

PROD_HOST = etherPSCTest
etherPSCTest_SRCS += etherPSCTest.c



LIBRARY_IOC = etherPSC
etherPSCTest_SRCS += EtherTest.c
etherPSC_SRCS += EtherTest.c
etherPSC_SRCS += devEtherPSC.c
etherPSC_SRCS += drvEtherPSC.c
etherPSC_SRCS += psControl.st
etherPSC_SRCS += subPS.c
etherPSC_LIBS += seq
etherPSC_LIBS += pv
etherPSC_LIBS += $(EPICS_BASE_IOC_LIBS)
etherPSCTest_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================
include $(TOP)/configure/RULES

#----------------------------------------
#  ADD RULES AFTER THIS LINE

