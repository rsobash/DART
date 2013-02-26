! DART software - Copyright 2004 - 2011 UCAR. This open source software is
! provided by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

program wakeup_filter

! <next few lines under version control, do not edit>
! $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/filter/wakeup_filter.f90 $
! $Id: wakeup_filter.f90 4933 2011-06-01 17:55:44Z thoar $
! $Revision: 4933 $
! $Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $

! spread out on the processors in the same order as the executable
! model and filter programs, and echo into the fifo (named pipe)
! a message to wake up the sleeping filter program.

use mpi_utilities_mod, only : initialize_mpi_utilities, &
                              finalize_mpi_utilities,   &
                              restart_task


call initialize_mpi_utilities("Wakeup_Filter")

call restart_task()

call finalize_mpi_utilities()


end program wakeup_filter
