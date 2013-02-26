#!/bin/csh
#
# DART software - Copyright 2004 - 2011 UCAR. This open source software is
# provided by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# DART $Id: compile_pert_sounding.csh 4945 2011-06-02 22:29:30Z thoar $


# Compiles pert_sounding.f90 for ocotillo

#ifort -c pert_sounding_module.f90
#ifort pert_sounding.f90 -o pert_sounding pert_sounding_module.o
#\rm ./pert_sounding_mod.mod



# Compiles pert_sounding.f90 for bluefire

xlf -c pert_sounding_module.f90
xlf pert_sounding.f90 -o pert_sounding pert_sounding_module.o
rm ./pert_sounding_mod.mod

exit $status

# <next few lines under version control, do not edit>
# $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/models/wrf/experiments/Radar/IC/sounding_perturbation/compile_pert_sounding.csh $
# $Revision: 4945 $
# $Date: 2011-06-02 17:29:30 -0500 (Thu, 02 Jun 2011) $

