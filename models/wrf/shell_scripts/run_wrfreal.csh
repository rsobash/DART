#!/bin/csh
#
# DART software - Copyright 2004 - 2011 UCAR. This open source software is
# provided by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# $Id: run_wrfreal.csh 4945 2011-06-02 22:29:30Z thoar $
#
# Purpose: Run WRFV2 real.exe.

#-----------------------------------------------------------------------
# [1] Required environment variables:
#-----------------------------------------------------------------------

setenv NC                 $1
setenv WRF_DIR            $2

#-----------------------------------------------------------------------
# [2] Run real.exe:
#-----------------------------------------------------------------------

cd ${WRF_DIR}/test/em_real

echo "   Running real.exe"
real.exe >>& ./run_real_${NC}.out

mv namelist.input namelist.input_${NC}
mv rsl.out.0000 rsl.out.0000_${NC}
mv rsl.error.0000 rsl.error.0000_${NC}

echo ""

exit 0

# <next few lines under version control, do not edit>
# $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/models/wrf/shell_scripts/run_wrfreal.csh $
# $Revision: 4945 $
# $Date: 2011-06-02 17:29:30 -0500 (Thu, 02 Jun 2011) $

