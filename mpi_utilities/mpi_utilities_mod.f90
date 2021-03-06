! DART software - Copyright 2004 - 2011 UCAR. This open source software is
! provided by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

module mpi_utilities_mod

! <next few lines under version control, do not edit>
! $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/mpi_utilities/mpi_utilities_mod.f90 $
! $Id: mpi_utilities_mod.f90 4933 2011-06-01 17:55:44Z thoar $
! $Revision: 4933 $
! $Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $

!-----------------------------------------------------------------------------
!
!   A collection of interfaces to the MPI (Message Passing Interface)
!   multi-processor communication library routines.
!
!    # initialize_mpi_utilities()  Subroutine that initializes MPI and sets
!                                  local values needed later.  Must be called
!                                  before any other routine here.
!
!    # finalize_mpi_utilities()  Subroutine that shuts down MPI cleanly.
!                                Must be called before program exits, and no
!                                other routines here can be used afterwards.
!
!    # task_count()       Function that returns the total number of MPI tasks.
!
!    # my_task_id()       Function that returns my task number.  Note that
!                         in the MPI world task numbers run from 0 to N-1.
!
!    # send_to()          Subroutine which sends a 1D data array
!                         synchronously to another task (point-to-point).
!
!    # receive_from()     Subroutine which receives a 1D data array
!                         synchronously from another task (point-to-point).
!
!    # task_sync()        Subroutine that only returns after every task has
!                         reached this same location in the code.
!        
!    # array_broadcast()  Subroutine that sends a copy of the entire data 
!                         array to all other tasks. 
!                
!    # exit_all()         Subroutine that substitutes for the intrinsic exit.
!                         It calls MPI_Abort() to force other MPI tasks to
!                         exit as well in case of error. 
! 
!    * transpose_array()  Subroutine that transposes a 2D array
!                         from column-major to row-major or back.
!
!   ** array_distribute() Subroutine that distributes a data array across the
!                         other tasks, so each task gets a non-overlapping 
!                         subset of the data.
!                
!   MPI cover routines more specific for DART and hopefully more useful.
!
!    # iam_task0()        Function which returns .TRUE. if task id is 0,
!                         .FALSE. for anything else.
!
!    # broadcast_send()   Subroutine which takes two r8 arrays and broadcasts
!                         them to all other tasks.  If sending ID is not the
!                         same as the local task ID, an error is returned.
!                         Does not return until all other tasks have called
!                         recv to pick up the data.
!
!    # broadcast_recv()   Subroutine which receives two r8 arrays from the 
!                         sending task ID.  If the sending ID is the same as
!                         the local task ID, an error is returned.  All other
!                         tasks must call recv before this routine returns.
!
!    # sum_across_tasks() Subroutine which takes a single integer argument
!                         from each task, and returns the sum of all integers
!                         across all tasks back to all tasks.  All tasks must
!                         call this routine before it can compute and return
!                         the value.
!
!   # get_dart_mpi_comm() This code creates a private communicator for use by
!                         the routines in this file.  This function returns it.
!
!   Lower level utility routines which interact with the utilities_mod.f90 
!   code to open a named pipe per MPI task, read and write from them, and
!   close and/or remove them.
!
!    # block_task()       Create a named pipe (fifo) and read from it to
!                         block the process in such a way that it consumes
!                         no CPU time.  NOTE that once you put yourself to
!                         sleep, you cannot wake yourself up.  Some other MPI
!                         task must call restart_task(), on the same set of
!                         processors the original program was distributed over.
!
!    # restart_task()     Write into the pipe to restart the reading task.
!                         Note that this must be an entirely separate executable
!                         from the one which called block_task(), because it is
!                         asleep like Sleeping Beauty and cannot wake itself.
!                         See filter and wakeup_filter for examples
!                         of a program pair which uses these calls.
! 
!    # finished_task()    Called from finalize_mpi_utilities, if async=4 
!                         writes out a string to the model pipe to tell it 
!                         the main executable is exiting.
!
!  *** make_pipe()        Function that creates a named pipe (fifo), opens it,
!                         and returns the unit number.  Ok to call if the pipe
!                         already exists or is already open; it will skip
!                         those steps and just return the unit number.  The 
!                         name argument is used as a base and a filename
!                         in the form 'base.NNNN' is generated, where the N's
!                         are the MPI rank number, 0 padded.
!
!  *** destroy_pipe()     The unit number is closed and the pipe file is 
!                         removed.
!
!  *** read_pipe()        The character string is read from the pipe.
!                         (Can be overloaded to read ints if time or status
!                         info is useful to exchange between processes.) 
!                         This routine blocks until data is available.
!
!  *** write_pipe()       The character string is written to the pipe.
!                         (Can be overloaded to write ints if time or status
!                         info is useful to exchange between processes.) 
!                         This routine writes and returns immediately.
!
!   Wrappers for system functions.  Covers differences if you run with
!   or without MPI.
!
!  *** shell_execute()    Use the system() command to execute a command string.
!                         Will wait for the command to complete and returns an
!                         error code unless you end the command with & to put
!                         it into background.   Function which returns the rc
!                         of the command, 0 being all is ok.
!
!  *** sleep_seconds()    Wrapper for the sleep command.  Argument is a real
!                         in seconds.  Different systems have different lower
!                         resolutions for the minimum time it will sleep.
!                         Subroutine, no return value.
!
!
!   # code done and tested
! *** both code and interface are done (but untested so far)
!  ** interface with proposed arguments exists but code not complete
!   * interface name only; no arg list devised yet 
!
!-----------------------------------------------------------------------------
! 
! these do not exist - i believe a single transpose will work.  but if not,
! they can be separated into these two, which can either work on a real
! 2D array or a single linearized array which is logically 2D but in reality
! stored in a 1D fortran array:
!
!      transpose_row_major()  Subroutine which transposes a logical 2D array
!                             from column-major to row-major.  The source and
!                             destination arrays must be stored in 1D arrays 
!                             of length (nrows * ncols).
!
!      transpose_col_major()  Subroutine which transposes a logical 2D array
!                             from row-major to column-major.  The source and
!                             destination arrays must be stored in 1D arrays 
!                             of length (nrows * ncols).
!
!-----------------------------------------------------------------------------

use types_mod, only : r8, digits12
use utilities_mod, only : register_module, error_handler, & 
                          E_ERR, E_WARN, E_MSG, E_DBG, get_unit, close_file, &
                          set_output, set_tasknum, initialize_utilities,     &
                          finalize_utilities,                                &
                          nmlfileunit, do_output, do_nml_file, do_nml_term,  &
                          find_namelist_in_file, check_namelist_read

use time_manager_mod, only : time_type, get_time, set_time

! BUILD TIP 1
! Many MPI installations have an MPI module; if one is present, use it.
! ('use mpi')
! If not, there will be an MPI include file which defines the parameters.
! ('include mpif.h')
! Use one but not both.   The 'use' line must be before the 'implicit none' 
! and 'private' lines, 'include' must come after.  Go figure.
! For more help on compiling a module which uses MPI see the 
! $DART/doc/mpi directory. 

use mpi

implicit none
private

!include "mpif.h"


! BUILD TIP 2
! Some compilers require an interface block for the system() function;
! some fail if you define one.  If you get an error at link time (something
! like 'undefined symbol _system_') try running the fixsystem script in
! this directory.  It is a sed script that comments in and out the interface
! block below.  Please leave the BLOCK comment lines unchanged.

 !!SYSTEM_BLOCK_EDIT START COMMENTED_IN
 ! interface block for getting return code back from system() routine
 interface
  function system(string)
   character(len=*) :: string
   integer :: system
  end function system
 end interface
 ! end block
 !!SYSTEM_BLOCK_EDIT END COMMENTED_IN


!   ---- private data for mpi_utilities ----

integer :: myrank        = -1  ! my mpi number
integer :: total_tasks   = -1  ! total mpi tasks/procs
integer :: my_local_comm =  0  ! duplicate communicator private to this file
integer :: datasize      =  0  ! which MPI type corresponds to our r8 definition


public :: initialize_mpi_utilities, finalize_mpi_utilities,                  &
          task_count, my_task_id, block_task, restart_task,                  &
          task_sync, array_broadcast, send_to, receive_from, iam_task0,      &
          broadcast_send, broadcast_recv, shell_execute, sleep_seconds,      &
          sum_across_tasks, get_dart_mpi_comm

! version controlled file description for error handling, do not edit
character(len=128), parameter :: &
   source   = "$URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/mpi_utilities/mpi_utilities_mod.f90 $", &
   revision = "$Revision: 4933 $", &
   revdate  = "$Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $"

logical :: module_initialized   = .false.

character(len = 129) :: saved_progname = ''
character(len = 129) :: shell_name = ''   ! if needed, add ksh, tcsh, bash, etc
integer :: head_task = 0         ! def 0, but N-1 if reverse_task_layout true
logical :: print4status = .true. ! minimal messages for async4 handshake

character(len = 129) :: errstring

! this turns on trace messages for most MPI communications 
logical :: verbose        = .false.   ! very very very verbose, use with care
logical :: async2_verbose = .false.   ! messages only for system() in async2
logical :: async4_verbose = .false.   ! messages only for block/restart async4

! if your batch system does the task layout backwards, set this to true
! so the last task will communicate with the script in async 4 mode.
! as of now, mpich and mvapich do it forward, openmpi does it backwards.
logical :: reverse_task_layout  = .false.   ! task 0 on head node; task N-1 if .true.
logical :: separate_node_sync   = .false.   ! true if tasks & script do not share nodes
logical :: create_local_comm    = .true.    ! make a private communicator

! for large numbers of MPI tasks, you will get replicated messages, one
! per task, if this is set to true.  however, for debugging if you need
! messages from tasks which aren't 0, this will elicit them.  error messages
! from any task will print regardless of this setting.
logical :: all_tasks_print      = .false.   ! by default only msgs from 0 print

! NAMELIST: change the following from .false. to .true. to enable
! the reading of this namelist.  This is the only place you need
! to make this change.
logical :: use_namelist = .false.

namelist /mpi_utilities_nml/ reverse_task_layout, all_tasks_print, &
                             verbose, async2_verbose, async4_verbose, &
                             shell_name, separate_node_sync, create_local_comm

contains

!-----------------------------------------------------------------------------
! mpi cover routines
!-----------------------------------------------------------------------------

subroutine initialize_mpi_utilities(progname, alternatename)
 character(len=*), intent(in), optional :: progname
 character(len=*), intent(in), optional :: alternatename


! Initialize MPI and query it for global information.  Make a duplicate
! communicator so that any user code which wants to call MPI will not 
! interfere with any outstanding asynchronous requests, accidental tag
! matches, etc.  This routine must be called before any other routine in
! this file, and it should not be called more than once (but it does have
! defensive code in case that happens.)

integer :: errcode, iunit
logical :: already

if ( module_initialized ) then
   ! return without calling the code below multiple times
   write(errstring, *) 'initialize_mpi_utilities has already been called'
   call error_handler(E_WARN,'initialize_mpi_utilities', errstring, source, revision, revdate)
   return
endif

! some implementations of mpich need this to happen before any I/O is done.
! this makes the startup sequence very tricky. 
! still, allow for the possibility that the user code has already initialized
! the MPI libs and do not try to call initialize again.
errcode = -999 
call MPI_Initialized(already, errcode)
if (errcode /= MPI_SUCCESS) then
   write(*, *) 'MPI_Initialized returned error code ', errcode
   call exit(-99)
endif
if (.not.already) then
   call MPI_Init(errcode)
   if (errcode /= MPI_SUCCESS) then
      write(*, *) 'MPI_Init returned error code ', errcode
      call exit(-99)
   endif
endif

call MPI_Comm_rank(MPI_COMM_WORLD, myrank, errcode)
if (errcode /= MPI_SUCCESS) then
   write(*, *) 'MPI_Comm_rank returned error code ', errcode
   call exit(-99)
endif

! give this a temporary initial value, in case we call the abort code.
! later down, we will dup the world comm and use a private comm for
! our communication.
my_local_comm = MPI_COMM_WORLD

! pass the arguments through so the utilities can log the program name
! only PE0 gets to output, whenever possible.
if (myrank == 0) then
   call initialize_utilities(progname, alternatename, .true.)
else
   call initialize_utilities(progname, alternatename, .false.)
endif

! save a copy of the initial program name for use in finalize.
! make sure it is not too long to fit into our variable.
if (present(progname)) then
   if (len_trim(progname) <= len(saved_progname)) then
      saved_progname = trim(progname)
   else
      saved_progname = progname(1:len(saved_progname))
   endif
endif

if ( .not. module_initialized ) then
   ! Initialize the module with utilities
   call register_module(source, revision, revdate)
   module_initialized = .true.
endif

! this must come AFTER the standard utils are initialized.
! Read the DART namelist for the mpi_utilities.
if (use_namelist) then
   call find_namelist_in_file('input.nml', 'mpi_utilities_nml', iunit)
   read(iunit, nml = mpi_utilities_nml, iostat = errcode)
   call check_namelist_read(iunit, errcode, "mpi_utilities_nml")
else
   errstring = ' !must edit mpi_utilities/mpi_utilities_mod.f90 to enable this namelist'
   if (do_nml_file()) write(nmlfileunit, '(A)') trim(errstring)
   if (do_nml_term()) write(     *     , '(A)') trim(errstring)
endif

! Record the namelist values used for the run ...
if (do_nml_file()) write(nmlfileunit, nml=mpi_utilities_nml)
if (do_nml_term()) write(     *     , nml=mpi_utilities_nml)


! duplicate the world communicator to isolate us from any other user
! calls to MPI.  All subsequent mpi calls here will use the local communicator
! and not the global world comm.
if (create_local_comm) then
   call MPI_Comm_dup(MPI_COMM_WORLD, my_local_comm, errcode)
   if (errcode /= MPI_SUCCESS) then
      write(errstring, '(a,i8)') 'MPI_Comm_dup returned error code ', errcode
      call error_handler(E_ERR,'initialize_mpi_utilities', errstring, &
                         source, revision, revdate)
   endif
endif

! find out who we are (0 to N-1).
call MPI_Comm_rank(my_local_comm, myrank, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Comm_rank returned error code ', errcode
   call error_handler(E_ERR,'initialize_mpi_utilities', errstring, source, revision, revdate)
endif

! number of tasks (if 10, returns 10.  task id numbers go from 0-9)
call MPI_Comm_size(my_local_comm, total_tasks, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Comm_size returned error code ', errcode
   call error_handler(E_ERR,'initialize_mpi_utilities', errstring, source, revision, revdate)
endif

! tell the utilities module what task number we are.
call set_tasknum(myrank)

! Turn off non-critical log messages from all but task 0, for performance
! and for sanity (e.g. only one copy of informational messages).  can be
! overridden by namelist if desired.
if (all_tasks_print) then
   call set_output(.true.)                     ! everyone gets to talk
else
   if (myrank /= 0) call set_output(.false.)   ! process 0 speaks for all
endif

! Users have the option of redefining the DART r8 kind to be the same size
! as r4.  But when we call the MPI routines we have to know what MPI type
! to use.  The internal dart kind 'digits12' is always defined to be *8, so
! if the parameters r8 and digits12 are the same value, use *8.  Otherwise
! assume r4 and r8 were defined to be the same and use *4.  (Some users
! do this to cut down on the space requirements.)

if (r8 == digits12) then
   datasize = MPI_REAL8
   !print *, "using real * 8 for datasize of r8"
else
   datasize = MPI_REAL4
   if (myrank == 0) then
      write(errstring, *) "Using real * 4 for datasize of r8"
      call error_handler(E_MSG,'initialize_mpi_utilities: ',errstring,source,revision,revdate)
   endif
endif

! in async 4 mode, where the controlling job (usually filter) and the 
! model are both mpi tasks and they handshake via named pipes, the tasks
! writing and reading the named pipes must be on the same node as the 
! one running the start script.  many MPI implementations (mpich, mvapich) 
! put task 0 on the first node, with the script.  some (openmpi)
! lay them out in reverse order, and task N-1 is on the same node
! as the script.  if this is wrong, things will hang when the
! filter task tries to advance the model - it won't be able to
! write the 'go ahead' message to the pipe.  set this via namelist
! to match what works on your system.
if (reverse_task_layout) then
   head_task = total_tasks - 1
else
   head_task = 0   ! normal case
endif

! MPI successfully initialized.  Log for the record how many tasks.
if (verbose) write(*,*) "PE", myrank, ": MPI successfully initialized"

if (myrank == 0) then
   write(errstring, *) 'Running with ', total_tasks, ' MPI processes.'
   call error_handler(E_MSG,'initialize_mpi_utilities: ',errstring,source,revision,revdate)
endif

end subroutine initialize_mpi_utilities

!-----------------------------------------------------------------------------

subroutine finalize_mpi_utilities(callfinalize, async)
 logical, intent(in), optional :: callfinalize
 integer, intent(in), optional :: async

! Shut down MPI cleanly.  This must be done before the program exits; on
! some implementations of MPI the final I/O flushes are not done until this
! is called.  The optional argument can prevent us from calling MPI_Finalize,
! so that user code can continue to use MPI after this returns.  Calling other
! routines in this file after calling finalize will invalidate your warranty.

integer :: errcode
logical :: dofinalize

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'finalize_mpi_utilities', errstring, source, revision, revdate)
endif

! give the async=4 case a chance to tell the script to shut down.
if (present(async)) then
   call finished_task(async)
endif

! close the log files and write a timestamp
if (saved_progname /= '') then
   call finalize_utilities(saved_progname)
else
   call finalize_utilities()
endif

! For the SGI implementation of MPI in particular, sync before shutting
! down MPI.  Once MPI is shut down, no other output can be written; it causes
! tasks to hang if they try.  Make sure all tasks are here and ready to
! close down at the same time.
call task_sync()

! Release the private communicator we created at init time.
if (my_local_comm /= MPI_COMM_WORLD) then
   call MPI_Comm_free(my_local_comm, errcode)
   if (errcode /= MPI_SUCCESS) then
      write(errstring, '(a,i8)') 'MPI_Comm_free returned error code ', errcode
      call error_handler(E_ERR,'finalize_mpi_utilities', errstring, source, revision, revdate)
   endif
endif

! If the optional argument is not given, or is given and is true, 
! shut down mpi.  Only if the argument is specified and is false do we
! skip the finalization.
if (.not.present(callfinalize)) then
   dofinalize = .TRUE.
else
   dofinalize = callfinalize
endif

! Normally we shut down MPI here.  If the user tells us not to shut down MPI
! they must call this routine from their own code before exiting.
if (dofinalize) then
   call MPI_Finalize(errcode)
   if (errcode /= MPI_SUCCESS) then
      write(errstring, '(a,i8)') 'MPI_Finalize returned error code ', errcode
      call error_handler(E_ERR,'finalize_mpi_utilities', errstring, source, revision, revdate)
   endif
endif

if (verbose) write(*,*) "PE", myrank, ": MPI successfully finalized"

end subroutine finalize_mpi_utilities


!-----------------------------------------------------------------------------

function task_count()

! Return the total number of MPI tasks.  e.g. if the number of tasks is 4,
! it returns 4.  (The actual task numbers are 0-3.)

integer :: task_count

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'task_count', errstring, source, revision, revdate)
endif

task_count = total_tasks

end function task_count


!-----------------------------------------------------------------------------

function my_task_id()

! Return my unique task id.  Values run from 0 to N-1 (where N is the
! total number of MPI tasks.

integer :: my_task_id

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'my_task_id', errstring, source, revision, revdate)
endif

my_task_id = myrank

end function my_task_id


!-----------------------------------------------------------------------------

subroutine task_sync()

! Synchronize all tasks.  This subroutine does not return until all tasks
! execute this line of code.

integer :: errcode

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'task_sync', errstring, source, revision, revdate)
endif

if (verbose) write(*,*) "PE", myrank, ": waiting at MPI Barrier"
call MPI_Barrier(my_local_comm, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Barrier returned error code ', errcode
   call error_handler(E_ERR,'task_sync', errstring, source, revision, revdate)
endif

if (verbose) write(*,*) "PE", myrank, ": MPI Barrier released"

end subroutine task_sync


!-----------------------------------------------------------------------------

subroutine send_to(dest_id, srcarray, time, label)
 integer, intent(in) :: dest_id
 real(r8), intent(in) :: srcarray(:)
 type(time_type), intent(in), optional :: time
 character(len=*), intent(in), optional :: label

! Send the srcarray to the destination id.
! If time is specified, it is also sent in a separate communications call.  
! This is a synchronous call; it will not return until the destination has 
! called receive to accept the data.  If the send_to/receive_from calls are 
! not paired correctly the code will hang.

integer :: i, tag, errcode
integer :: itime(2)
real(r8) :: tmpdata(size(srcarray))

if (verbose) write(*,*) "PE", myrank, ": start of send_to "

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'send_to', errstring, source, revision, revdate)
endif

! simple idiotproofing
if ((dest_id < 0) .or. (dest_id >= total_tasks)) then
   write(errstring, '(a,i8,a,i8)') "destination task id ", dest_id, &
                                   "must be >= 0 and < ", total_tasks
   call error_handler(E_ERR,'send_to', errstring, source, revision, revdate)
endif

if (present(label)) then
   write(*,*) trim(label)//" PE", myrank, ": send_to itemsize ", size(srcarray), " dest ", dest_id
else if (verbose) then
   write(*,*) "PE", myrank, ": send_to itemsize ", size(srcarray), " dest ", dest_id
endif

! use my task id as the tag; unused at this point.
tag = myrank

! this copy should be unneeded, but on the intel fortran 9.0 compiler and mpich
! on one platform, calling this routine with an array section resulted in some
! apparently random memory corruption.  making a copy of the data into a local,
! contiguous buffer before send and receive fixed the corruption.  this should
! be examined at some later time for any performance impact.
tmpdata = srcarray

if (verbose) write(*,*) "PE", myrank, ": send_to alloctmp ", size(tmpdata), " dest ", dest_id

! call MPI to send the data to the remote task
call MPI_Ssend(tmpdata, size(tmpdata), datasize, dest_id, tag, &
              my_local_comm, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Ssend returned error code ', errcode
   call error_handler(E_ERR,'send_to', errstring, source, revision, revdate)
endif

! if time specified, call MPI again to send the 2 time ints.
if (present(time)) then
   if (verbose) write(*,*) "PE", myrank, ": time present"
   call get_time(time, itime(1), itime(2))
   call MPI_Ssend(itime, 2, MPI_INTEGER, dest_id, tag*2, my_local_comm, errcode)
   if (errcode /= MPI_SUCCESS) then
      write(errstring, '(a,i8)') 'MPI_Ssend returned error code ', errcode
      call error_handler(E_ERR,'send_to', errstring, source, revision, revdate)
   endif
   if (verbose) write(*,*) "PE", myrank, ": sent time to ", dest_id
endif

if (verbose) write(*,*) "PE", myrank, ": end of send_to "


end subroutine send_to


!-----------------------------------------------------------------------------

subroutine receive_from(src_id, destarray, time, label)
 integer, intent(in) :: src_id
 real(r8), intent(inout) :: destarray(:)
 type(time_type), intent(out), optional :: time
 character(len=*), intent(in), optional :: label

! Receive data into the destination array from the src task.
! If time is specified, it is received in a separate communications call.  
! This is a synchronous call; it will not return until the source has 
! sent the data.  If the send_to/receive_from calls are not paired correctly 
! the code will hang.

integer :: i, tag, errcode
integer :: itime(2)
integer :: status(MPI_STATUS_SIZE)
real(r8) :: tmpdata(size(destarray))

if (verbose) write(*,*) "PE", myrank, ": start of receive_from "

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'receive_from', errstring, source, revision, revdate)
endif

! simple idiotproofing
if ((src_id < 0) .or. (src_id >= total_tasks)) then
   write(errstring, '(a,i8,a,i8)') "source task id ", src_id, &
                                   "must be >= 0 and < ", total_tasks
   call error_handler(E_ERR,'receive_from', errstring, source, revision, revdate)
endif

if (present(label)) then
   write(*,*) trim(label)//" PE", myrank, ": receive_from itemsize ", size(destarray), " src ", src_id
else if (verbose) then
   write(*,*) "PE", myrank, ": receive_from itemsize ", size(destarray), " src ", src_id
endif

! send_to uses its own id as the tag.
tag = src_id


if (verbose) write(*,*) "PE", myrank, ": receive_from alloctmp ", size(tmpdata), " src ", src_id

! call MPI to receive the data from the remote task
call MPI_Recv(tmpdata, size(tmpdata), datasize, src_id, MPI_ANY_TAG, &
              my_local_comm, status, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Recv returned error code ', errcode
   call error_handler(E_ERR,'receive_from', errstring, source, revision, revdate)
endif

if (verbose) write(*,*) "PE", myrank, ": received from ", src_id

! see comment in send_to() about why this code receives into a temp array
! and then does a contents copy into the actual destination.
destarray = tmpdata

if (verbose) write(*,*) "PE", myrank, ": copied to final dataarray"

! if time specified, call MPI again to send the 2 time ints.
if (present(time)) then
   if (verbose) write(*,*) "PE", myrank, ": time present"
   call MPI_Recv(itime, 2, MPI_INTEGER, src_id, tag*2, &
                 my_local_comm, status, errcode)
   if (errcode /= MPI_SUCCESS) then
      write(errstring, '(a,i8)') 'MPI_Recv returned error code ', errcode
      call error_handler(E_ERR,'receive_from', errstring, source, revision, revdate)
   endif
   if (itime(2) < 0) then
      write(errstring, '(a,i8)') 'seconds in settime were < 0; using 0'
      call error_handler(E_MSG,'receive_from', errstring, source, revision, revdate)
      time = set_time(itime(1), 0)
   else
      time = set_time(itime(1), itime(2))
   endif
   if (verbose) write(*,*) "PE", myrank, ": received time from ", src_id
endif

if (verbose) write(*,*) "PE", myrank, ": end of receive_from "


end subroutine receive_from



!-----------------------------------------------------------------------------
! TODO: do i need to overload this for both integer and real?
!       do i need to handle 1D, 2D, 3D inputs?


subroutine transpose_array

! not implemented here yet.  will have arguments -- several of them.

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'transpose_array', errstring, source, revision, revdate)
endif

write(errstring, *) 'not implemented yet'
call error_handler(E_ERR,'transpose_array', errstring, source, revision, revdate)

end subroutine transpose_array


!-----------------------------------------------------------------------------
! TODO: do i need to overload this for both integer and real?
!       do i need to handle 2D inputs?

subroutine array_broadcast(array, root)
 real(r8), intent(inout) :: array(:)
 integer, intent(in) :: root

! The data array values on the root task will be broadcast to every other
! task.  When this routine returns, all tasks will have the contents of the
! root array in their own arrays.  Thus 'array' is intent(in) on root, and
! intent(out) on all other tasks.

integer :: itemcount, errcode

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
endif

! simple idiotproofing
if ((root < 0) .or. (root >= total_tasks)) then
   write(errstring, '(a,i8,a,i8)') "root task id ", root, &
                                   "must be >= 0 and < ", total_tasks
   call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
endif

itemcount = size(array)

!if (verbose) then
!   if (myrank == root) write(*,*) "PE", myrank, ": bcast itemsize here ", itemcount
!endif
!!if (verbose) write(*,*) "PE", myrank, ": bcast itemsize ", itemcount, " root ", root

call MPI_Bcast(array, itemcount, datasize, root, my_local_comm, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Bcast returned error code ', errcode
   call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
endif

end subroutine array_broadcast


!-----------------------------------------------------------------------------
! TODO: do i need to overload this for both integer and real?
!       do i need to handle 2D inputs?

subroutine array_distribute(srcarray, root, dstarray, dstcount, how, which)
 real(r8), intent(in) :: srcarray(:)
 integer, intent(in) :: root
 real(r8), intent(out) :: dstarray(:)
 integer, intent(out) :: dstcount
 integer, intent(in) :: how
 integer, intent(out) :: which(:)

! 'srcarray' on the root task will be distributed across all the tasks
! into 'dstarray'.  dstarray must be large enough to hold each task's share
! of the data.  The actual number of values returned on each task will be
! passed back in the 'count' argument.  'how' is a flag to select how to
! distribute the data (round-robin, contiguous chunks, etc).  'which' is an
! integer index array which lists which of the original values were selected
! and put into 'dstarray'.

real(r8), allocatable :: localchunk(:)
integer :: srccount, leftover
integer :: i, tag, errcode
logical :: iamroot
integer :: status(MPI_STATUS_SIZE)

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'array_distribute', errstring, source, revision, revdate)
endif

! simple idiotproofing
if ((root < 0) .or. (root >= total_tasks)) then
   write(errstring, '(a,i8,a,i8)') "root task id ", root, &
                                   "must be >= 0 and < ", total_tasks
   call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
endif

iamroot = (root == myrank)
tag = 1

srccount = size(srcarray)

! TODO: right now this code does contig chunks only
! TODO: it should select on the 'how' argument
dstcount = srccount / total_tasks
leftover = srccount - (dstcount * total_tasks)
if (myrank == total_tasks-1) dstcount = dstcount + leftover


! idiotproofing, continued...
if (size(dstarray) < dstcount) then
   write(errstring, '(a,i8,a,i8)') "size of dstarray is", size(dstarray), & 
                      " but must be >= ", dstcount
   call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
endif
if (size(which) < dstcount) then
   write(errstring, '(a,i8,a,i8)') "size of which is", size(which), & 
                      " but must be >= ", dstcount
   call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
endif

! TODO: this code is separate from the 'dstcount' computation because we
! need to test to be sure the user has passed us in arrays large enough to
! hold the data, but then this section needs to have a select (how) and set
! the corresponding index numbers accordingly.
which(1:dstcount) = (/ (i, i= myrank *dstcount, (myrank+1)*dstcount - 1) /)
if (size(which) > dstcount) which(dstcount+1:) = -1
   

if (.not.iamroot) then

   ! my task is receiving data.
   call MPI_Recv(dstarray, dstcount, datasize, root, MPI_ANY_TAG, &
                 my_local_comm, status, errcode)
   if (errcode /= MPI_SUCCESS) then
      write(errstring, '(a,i8)') 'MPI_Recv returned error code ', errcode
      call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
   endif

else
   ! my task must send to everyone else and copy to myself.
   allocate(localchunk(dstcount), stat=errcode)  
   if (errcode /= 0) then
      write(errstring, *) 'allocation error of allocatable array'
      call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
   endif

   do i=0, total_tasks-1
      ! copy correct data from srcarray to localchunk for each destination
      if (i == myrank) then
         ! this is my task, so do a copy from localchunk to dstarray
         dstarray(1:dstcount) = localchunk(1:dstcount)
      else
         ! call MPI to send the data to the remote task
         call MPI_Ssend(localchunk, dstcount, datasize, i, tag, &
                        my_local_comm, errcode)
         if (errcode /= MPI_SUCCESS) then
            write(errstring, '(a,i8)') 'MPI_Ssend returned error code ', errcode
            call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
         endif
      endif
      tag = tag + 1
   enddo

   deallocate(localchunk, stat=errcode)  
   if (errcode /= 0) then
      write(errstring, *) 'deallocation error of allocatable array'
      call error_handler(E_ERR,'array_broadcast', errstring, source, revision, revdate)
   endif
endif
   
! set any additional space which wasn't filled with zeros.
if (size(dstarray) > dstcount) dstarray(dstcount+1:) = 0.0

end subroutine array_distribute

!-----------------------------------------------------------------------------
! DART-specific cover utilities
!-----------------------------------------------------------------------------

function iam_task0()

! Return .TRUE. if my local task id is 0, .FALSE. otherwise.
! (Task numbers in MPI start at 0, contrary to the rules of polite fortran.)

logical :: iam_task0

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'iam_task0', errstring, source, revision, revdate)
endif

iam_task0 = (myrank == 0)

end function iam_task0

!-----------------------------------------------------------------------------
subroutine broadcast_send(from, array1, array2, array3, array4, array5, &
                          scalar1, scalar2, scalar3, scalar4, scalar5)
 integer, intent(in) :: from
 ! really only intent(in) here, but must match array_broadcast() call.
 real(r8), intent(inout) :: array1(:)
 real(r8), intent(inout), optional :: array2(:), array3(:), array4(:), array5(:)
 real(r8), intent(inout), optional :: scalar1, scalar2, scalar3, scalar4, scalar5

! cover routine for array broadcast.  one additional sanity check -- make 
! sure the 'from' matches my local task id.  also, these arrays are
! intent(in) here, but they call a routine which is intent(inout) so they
! must be the same here.
 
 real(r8) :: local(5)
 logical :: dolocal

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'broadcast_send', errstring, source, revision, revdate)
endif

! simple idiotproofing
if (from /= myrank) then
   write(errstring, '(a,i8,a,i8)') "'from' task id ", from, &
                                   "must be same as current task id ", myrank
   call error_handler(E_ERR,'broadcast_send', errstring, source, revision, revdate)
endif

! this must be paired with the same number of broadcast_recv()s on all 
! other tasks.  it will not return until all tasks in the communications 
! group have made the call.
call array_broadcast(array1, from)
if (present(array2)) call array_broadcast(array2, from)
if (present(array3)) call array_broadcast(array3, from)
if (present(array4)) call array_broadcast(array4, from)
if (present(array5)) call array_broadcast(array5, from)

dolocal = .false.
local = 0.0_r8

if (present(scalar1)) then
  dolocal = .true.
  local(1) = scalar1
endif
if (present(scalar2)) then
  dolocal = .true.
  local(2) = scalar2
endif
if (present(scalar3)) then
  dolocal = .true.
  local(3) = scalar3
endif
if (present(scalar4)) then
  dolocal = .true.
  local(4) = scalar4
endif
if (present(scalar5)) then
  dolocal = .true.
  local(5) = scalar5
endif

if (dolocal) call array_broadcast(local, from)

end subroutine broadcast_send

!-----------------------------------------------------------------------------
subroutine broadcast_recv(from, array1, array2, array3, array4, array5, &
                          scalar1, scalar2, scalar3, scalar4, scalar5)
 integer, intent(in) :: from
 ! really only intent(out) here, but must match array_broadcast() call.
 real(r8), intent(inout) :: array1(:)
 real(r8), intent(inout), optional :: array2(:), array3(:), array4(:), array5(:)
 real(r8), intent(inout), optional :: scalar1, scalar2, scalar3, scalar4, scalar5

! cover routine for array broadcast.  one additional sanity check -- make 
! sure the 'from' is not the same as my local task id.  these arrays are
! intent(out) here, but they call a routine which is intent(inout) so they
! must be the same here.

 real(r8) :: local(5)
 logical :: dolocal

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'broadcast_recv', errstring, source, revision, revdate)
endif

! simple idiotproofing
if (from == myrank) then
   write(errstring, '(a,i8,a,i8)') "'from' task id ", from, &
                                   "cannot be same as current task id ", myrank
   call error_handler(E_ERR,'broadcast_recv', errstring, source, revision, revdate)
endif

! this must be paired with broadcast_send() on all other tasks, and it must 
! match exactly the number of args in the sending call.
! it will not return until all tasks in the communications group have
! made the call.
call array_broadcast(array1, from)
if (present(array2)) call array_broadcast(array2, from)
if (present(array3)) call array_broadcast(array3, from)
if (present(array4)) call array_broadcast(array4, from)
if (present(array5)) call array_broadcast(array5, from)

dolocal = .false.
local = 0.0_r8

if (present(scalar1) .or. present(scalar2) .or. present(scalar3) &
                     .or. present(scalar4) .or. present(scalar5)) dolocal = .true.

if (dolocal) call array_broadcast(local, from)

if (present(scalar1)) scalar1 = local(1)
if (present(scalar2)) scalar2 = local(2)
if (present(scalar3)) scalar3 = local(3)
if (present(scalar4)) scalar4 = local(4)
if (present(scalar5)) scalar5 = local(5)

end subroutine broadcast_recv

!-----------------------------------------------------------------------------
subroutine sum_across_tasks(addend, sum)
 integer, intent(in) :: addend
 integer, intent(out) :: sum

 integer :: errcode
 integer :: localaddend(1), localsum(1)

! cover routine for MPI all-reduce

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'sum_across_tasks', errstring, source, revision, revdate)
endif

localaddend(1) = addend

if (verbose) write(*,*) "PE", myrank, ": Allreduce called"

call MPI_Allreduce(localaddend, localsum, 1, MPI_INTEGER, MPI_SUM, &
                   my_local_comm, errcode)
if (errcode /= MPI_SUCCESS) then
   write(errstring, '(a,i8)') 'MPI_Allreduce returned error code ', errcode
   call error_handler(E_ERR,'sum_across_tasks', errstring, source, revision, revdate)
endif

sum = localsum(1)

end subroutine sum_across_tasks


!-----------------------------------------------------------------------------
! pipe-related utilities
!-----------------------------------------------------------------------------

!-----------------------------------------------------------------------------
subroutine block_task()

! block by reading a named pipe file until some other task
! writes a string into it.  this ensures the task is not
! spinning and using CPU cycles, but is asleep waiting in
! the kernel.   one subtlety with this approach is that even
! though named pipes are created in the filesystem, they are
! implemented in the kernel, so on a multiprocessor machine
! the write into the pipe file must occur on the same PE as
! the reader is waiting.  see the 'wakeup_filter' program for
! the MPI job which spreads out on all the PEs for this job
! and writes into the file from the correct PE.

character(len = 32) :: fifo_name, filter_to_model, model_to_filter, non_pipe
integer :: rc

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'block_task', errstring, source, revision, revdate)
endif

! FIXME: this should be mpi or a string other than filter (this is generic 
! mpi wrapper code, callable from programs other than filter.)
filter_to_model = 'filter_to_model.lock'
model_to_filter = 'model_to_filter.lock'
non_pipe = 'filter_to_model.file'

! the i5.5 format below will not handle task counts larger than this.
if (total_tasks > 99999) then
   write(errstring, *) 'cannot handle task counts > 99999'
   call error_handler(E_ERR,'block_task', errstring, source, revision, revdate)
endif

! make it so we only have to test 1 or 2 things here instead of 3
! when deciding whether to print status messages.
if (verbose) async4_verbose = .TRUE.

if ((myrank == head_task) .and. separate_node_sync) then

   if (async4_verbose) then
      write(*,*)  'checking master task host'
      rc = system('echo master task running on host `hostname`'//' '//char(0))
      if (rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc
   endif

   if (async4_verbose .or. print4status) write(*,*) 'MPI job telling script to advance model'
   rc = system('echo advance > '//trim(non_pipe)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

endif

if ((myrank == head_task) .and. .not. separate_node_sync) then

   if (async4_verbose) then
      write(*,*)  'checking master task host'
      rc = system('echo master task running on host `hostname`'//' '//char(0))
      if (rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc
   endif

   if (async4_verbose .or. print4status) write(*,*) 'MPI job telling script to advance model'
   rc = system('echo advance > '//trim(filter_to_model)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

   if (async4_verbose) write(*,*) 'MPI job now waiting to read from lock file'
   rc = system('cat < '//trim(model_to_filter)//'> /dev/null '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

else

! if you change this in any way, change the corresponding string in 
! restart_task() below.
   ! FIXME: this should be 'task_lock', since it's generic code beyond filter.
   write(fifo_name, '(a, i5.5)') "filter_lock", myrank
   
   if (async4_verbose) then
      write(*,*)  'checking slave task host'
      rc = system('echo '//trim(fifo_name)//' accessed from host `hostname`'//' '//char(0))
      if (rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc
   endif

   if (async4_verbose) write(*,*) 'removing any previous lock file: '//trim(fifo_name)
   rc = system('rm -f '//trim(fifo_name)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

   if (async4_verbose) write(*,*) 'made fifo, named: '//trim(fifo_name)
   rc = system('mkfifo '//trim(fifo_name)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

   if (async4_verbose) write(*,*) 'ready to read from lock file: '//trim(fifo_name)
   rc = system('cat < '//trim(fifo_name)//'> /dev/null '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

   if (async4_verbose) write(*,*) 'got response, removing lock file: '//trim(fifo_name)
   rc = system('rm -f '//trim(fifo_name)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

endif

! make sure all tasks get here before any get to proceed further.
! this hides a multitude of sins.  it could also cause
! tasks to hang forever, but right now it also makes some
! systems able to run async 4.  maybe this should be namelist
! selectable.  something named 'horrible_mpi_hack = .true.'
! if tasks are hanging out here instead of reading the lock files,
! they are burning cpu cycles and competing with the model advances.
! but, it works, as opposed to not working.
call task_sync()

end subroutine block_task

!-----------------------------------------------------------------------------
subroutine restart_task()

! companion to block_task.  must be called by a different executable
! and it writes into the named pipes to restart the waiting task.

character(len = 32) :: fifo_name, model_to_filter
integer :: rc

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'restart_task', errstring, source, revision, revdate)
endif

! FIXME: ditto previous comment about using the string 'filter' here.
model_to_filter = 'model_to_filter.lock'

! the i5.5 format below will not handle task counts larger than this.
if (total_tasks > 99999) then
   write(errstring, *) 'cannot handle task counts > 99999'
   call error_handler(E_ERR,'block_task', errstring, source, revision, revdate)
endif

! make it so we only have to test 1 or 2 things here instead of 3
! when deciding whether to print status messages.
if (verbose) async4_verbose = .TRUE.

! process 0 (or N-1) is handled differently in the code.
if ((myrank == head_task) .and. .not. separate_node_sync) then

   if (async4_verbose) then
      rc = system('echo master task running on host `hostname`'//' '//char(0))
      if (rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc
   endif

   if (async4_verbose .or. print4status) write(*,*) 'script telling MPI job ok to restart'
   rc = system('echo restart > '//trim(model_to_filter)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

else

   if (async4_verbose) write(*,*) 'waking up task id ', myrank

   ! FIXME: this should be 'task_lock', since it's generic code beyond filter.
   write(fifo_name,"(a,i5.5)") "filter_lock", myrank

   if (async4_verbose) then
      rc = system('echo '//trim(fifo_name)//' accessed from host `hostname`'//' '//char(0))
      if (rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc
   endif

   if (async4_verbose) write(*,*) 'ready to write to lock file: '//trim(fifo_name)
   rc = system('echo restart > '//trim(fifo_name)//' '//char(0))
   if (async4_verbose .and. rc /= 0) write(*, *) 'system command returned nonzero rc, ', rc

endif

end subroutine restart_task

!-----------------------------------------------------------------------------
subroutine finished_task(async)
 integer, intent(in) :: async

character(len = 32) :: fifo_name, filter_to_model, non_pipe
integer :: rc

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'restart_task', errstring, source, revision, revdate)
endif

! only in the async=4 case does this matter.
if (async /= 4) return

! FIXME: ditto previous comment about using the string 'filter' here.
filter_to_model = 'filter_to_model.lock'
non_pipe = 'filter_to_model.file'


! only process 0 (or N-1) needs to do anything.
if (myrank == head_task) then

   if (print4status .or. verbose) write(*,*) 'MPI task telling script we are done'
   if (separate_node_sync) then
      rc = system('echo finished > '//trim(non_pipe)//' '//char(0))
   else
      rc = system('echo finished > '//trim(filter_to_model)//' '//char(0))
   endif

   
endif

end subroutine finished_task


!-----------------------------------------------------------------------------
!    * make_pipe()        Function that creates a named pipe (fifo), opens it,
!                         and returns the unit number.  Ok to call if the pipe
!                         already exists or is already open; it will skip
!                         those steps and just return the unit number.  The 
!                         name argument is used as a base and a filename
!                         in the form 'base.NNNN' is generated, where the N's
!                         are the MPI rank number, 0 padded.
!
function make_pipe(pipename, exists) result (iunit)
 character(len=*), intent(in) :: pipename
 logical, intent(in), optional :: exists
 integer :: iunit

! Create, open, and return a fortran unit number for a named pipe.
! The local MPI rank number will be appended to the given name to create
! a file of the form 'base.NNNN', where N's are the MPI rank number, 0 padded.
! TODO: based on the total number of tasks get extra style points for
! creating the shortest name necessary; e.g. base.N, base.NN, base.NNN, etc.
!
! If the optional 'exists' flag is not present, then it is not an error
! whether the pipe already exists or not.  It is made if it does not exist, 
! it is opened if not already opened, and the fortran unit number is returned.
! If 'exists' is present then it forces the issue of whether the pipe file
! must exist already or not.  The error handler is called if things aren't 
! as expected.  apologies to tim hoar for the intentional imitation of
! the generic file utilities_mod.f90 code.

logical :: open, there
character(len=128) :: fname
character(len=11) :: format
integer :: rc

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'make_pipe', errstring, source, revision, revdate)
endif

write(fname, "(a,i4.4)") trim(pipename)//".", myrank
!print *, "fname now = ", trim(fname)

! check to see if the pipe already exists; if so, we've got the unit number
! (directly into the output value) and we're done.  otherwise, make it and
! open it.
inquire (file=fname, exist=there, opened=open, number=iunit, form=format)

if (.not. open) then

   if (.not. there) then
      ! make pipe file; mkfifo should be standard on any unix/linux system.
      rc = system('mkfifo '//trim(fname)//' '//char(0))

      ! and check to be sure it was made
      inquire (file=fname, exist=there)

      if (.not. there) then
        write(errstring, *) 'mkfifo command failed to create '//trim(fname)
        call error_handler(E_ERR,'make_pipe', errstring, source, revision, revdate)
      endif
   endif

   ! open pipe using an available unit number
   iunit = get_unit()
   open(unit=iunit, file=fname)

endif

! iunit contains the function return value.

end function make_pipe


!-----------------------------------------------------------------------------
!    * destroy_pipe()     The unit number is closed and the pipe file is 
!                         removed.
!
subroutine destroy_pipe(iunit)
 integer, intent(in) :: iunit

character(len=128) :: pipename
integer :: ios, rc

if ( .not. module_initialized ) then
   write(errstring, *) 'initialize_mpi_utilities() must be called first'
   call error_handler(E_ERR,'destroy_pipe', errstring, source, revision, revdate)
endif

write(errstring, *) 'not implemented yet'
call error_handler(E_ERR,'destroy_pipe', errstring, source, revision, revdate)


! general idea is:

! call inquire to get name
inquire(unit=iunit, name=pipename, iostat=ios)
if (ios /= 0) then
   write(errstring, '(a,i4)') 'failure trying to inquire about unit ', iunit
   call error_handler(E_ERR,'destroy_pipe', errstring, source, revision, revdate)
endif

call close_file(iunit)

! remove echo when we trust this command.
rc = system('echo rm -f '//trim(pipename)//' '//char(0))


end subroutine destroy_pipe

!-----------------------------------------------------------------------------
!    * read_pipe()        The character string is read from the pipe.
!                         (Can be overloaded to read ints if time or status
!                         info is useful to exchange between processes.) 
!                         This routine blocks until data is available.
!
subroutine read_pipe(iunit, chardata)
 integer, intent(in) :: iunit
 character(len=*), intent(out) :: chardata
 
 integer :: ios

 read(iunit, *, iostat=ios) chardata
 if (ios /= 0) then
   write(errstring, '(a,i4)') 'failure trying to read from unit ', iunit
   call error_handler(E_ERR,'read_pipe', errstring, source, revision, revdate)
endif

end subroutine

!-----------------------------------------------------------------------------
!    * write_pipe()       The character string is written to the pipe.
!                         (Can be overloaded to write ints if time or status
!                         info is useful to exchange between processes.) 
!                         This routine writes and returns immediately.
!
subroutine write_pipe(iunit, chardata)
 integer, intent(in) :: iunit
 character(len=*), intent(in) :: chardata
 
 integer :: ios

 write(iunit, *, iostat=ios) chardata
 if (ios /= 0) then
   write(errstring, '(a,i4)') 'failure trying to write from unit ', iunit
   call error_handler(E_ERR,'write_pipe', errstring, source, revision, revdate)
endif


end subroutine


!-----------------------------------------------------------------------------
! general system util wrappers.
!-----------------------------------------------------------------------------
function shell_execute(execute_string, serialize)
 character(len=*), intent(in) :: execute_string
 logical, intent(in), optional :: serialize
 integer :: shell_execute

! Use the system() command to execute a command string.
! Will wait for the command to complete and returns an
! error code unless you end the command with & to put
! it into background.   Function which returns the rc
! of the command, 0 being all is ok.

! allow code to test the theory that maybe the system call is
! not reentrant on some platforms.  if serialize is set and
! is true, do each call serially.

logical :: all_at_once
integer :: i, errcode, dummy(1)
integer :: status(MPI_STATUS_SIZE)

   if (verbose) async2_verbose = .true.

   ! default to everyone running concurrently, but if set and not true,
   ! serialize the calls to system() so they do not step on each other.
   if (present(serialize)) then
      all_at_once = .not. serialize
   else
      all_at_once = .TRUE.
   endif

   if (async2_verbose) write(*,*) "PE", myrank, ": system string is: ", trim(execute_string)
   shell_execute = -1

   ! this is the normal (default) case
   if (all_at_once) then

      ! all tasks call system at the same time
      !shell_execute = system(trim(execute_string)//' '//char(0))
      shell_execute = system(trim(shell_name)//' '//trim(execute_string)//' '//char(0))
      if (async2_verbose) write(*,*) "PE", myrank, ": execution returns, rc = ", shell_execute

      return
   endif

   ! only one task at a time calls system, and all wait their turn by
   ! making each task wait for a message from the (N-1)th task.
   
   ! this is used only to signal; the value it contains is unused.
   dummy = 0

   if (myrank == 0) then

      ! my turn to execute
      shell_execute = system(trim(shell_name)//' '//trim(execute_string)//' '//char(0))
      if (async2_verbose) write(*,*) "PE", myrank, ": execution returns, rc = ", shell_execute

      if (total_tasks > 1) then
         ! tell next task it can continue
         call MPI_Send(dummy, 1, MPI_INTEGER, 1, 1, my_local_comm, errcode)
         if (errcode /= MPI_SUCCESS) then
            write(errstring, '(a,i8)') 'MPI_Send returned error code ', &
                                        errcode
            call error_handler(E_ERR,'shell_execute', errstring, source, &
                               revision, revdate)
         endif
      endif

   else if (myrank /= (total_tasks-1)) then
      ! wait for (me-1) to tell me it is my turn
      call MPI_Recv(dummy, 1, MPI_INTEGER, myrank-1, myrank, &
                    my_local_comm, status, errcode)
      if (errcode /= MPI_SUCCESS) then
         write(errstring, '(a,i8)') 'MPI_Recv returned error code ', errcode
         call error_handler(E_ERR,'shell_execute', errstring, source, &
                            revision, revdate)
      endif

      ! my turn to execute
      shell_execute = system(trim(shell_name)//' '//trim(execute_string)//' '//char(0))
      if (async2_verbose) write(*,*) "PE", myrank, ": execution returns, rc = ", shell_execute

      ! and now tell (me+1) to go
      call MPI_Send(dummy, 1, MPI_INTEGER, myrank+1, myrank+1, my_local_comm, errcode)
      if (errcode /= MPI_SUCCESS) then
         write(errstring, '(a,i8)') 'MPI_Send returned error code ', &
                                     errcode
         call error_handler(E_ERR,'shell_execute', errstring, source, &
                            revision, revdate)
      endif
   else
      ! last task, no one else to send to.
      call MPI_Recv(dummy, 1, MPI_INTEGER, myrank-1, myrank, &
                    my_local_comm, status, errcode)
      if (errcode /= MPI_SUCCESS) then
         write(errstring, '(a,i8)') 'MPI_Recv returned error code ', errcode
         call error_handler(E_ERR,'shell_execute', errstring, source, &
                            revision, revdate)
      endif

      ! my turn to execute
      shell_execute = system(trim(shell_name)//' '//trim(execute_string)//' '//char(0))
      if (async2_verbose) write(*,*) "PE", myrank, ": execution returns, rc = ", shell_execute

   endif
       

end function shell_execute

!-----------------------------------------------------------------------------
subroutine sleep_seconds(naplength)
 real(r8), intent(in) :: naplength

! Wrapper for the sleep command.  Argument is a real
! in seconds.  Different systems have different lower
! resolutions for the minimum time it will sleep.
! Subroutine, no return value.

 integer :: sleeptime

 sleeptime = floor(naplength)
 if (sleeptime <= 0) sleeptime = 1

 call sleep(sleeptime)

end subroutine sleep_seconds

!-----------------------------------------------------------------------------
function get_dart_mpi_comm()
 integer :: get_dart_mpi_comm

! return our private communicator (or world, if no private created)
 get_dart_mpi_comm = my_local_comm

end function get_dart_mpi_comm

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------

end module mpi_utilities_mod

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
! NOTE -- non-module code, so this subroutine can be called from the
!  utilities module, which this module uses (and cannot have circular refs)
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------

subroutine exit_all(exit_code)
 use mpi_utilities_mod, only : get_dart_mpi_comm

 integer, intent(in) :: exit_code

! In case of error, call this instead of the fortran intrinsic exit().
! It will signal the other MPI tasks that something bad happened and they
! should also exit.

integer :: ierror

! if we made a local communicator, call abort on it.
! otherwise call abort on the world comm.

!print *, 'calling abort on comm ', get_dart_mpi_comm()
call MPI_Abort(get_dart_mpi_comm(),  exit_code, ierror)

! execution should never get here

end subroutine exit_all

