#!/bin/csh
#
# DART software - Copyright 2004 - 2011 UCAR. This open source software is
# provided by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# DART $Id: start_over.csh 4945 2011-06-02 22:29:30Z thoar $

\rm -r advance_temp*
\rm assim_model_state*
\rm filter_control*
\rm dart_log*
\rm filter.*.log
\rm Prior_Diag.nc
\rm Posterior_Diag.nc
\rm blown*.out
\rm obs_seq.final
\rm finished_grid*
\rm last_p*
\rm refl_obs*.txt
\rm finished.g*
\rm WRFOUT/*

exit $status

# <next few lines under version control, do not edit>
# $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/models/wrf/experiments/Radar/start_over.csh $
# $Revision: 4945 $
# $Date: 2011-06-02 17:29:30 -0500 (Thu, 02 Jun 2011) $
