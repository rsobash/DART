! DART software - Copyright 2004 - 2011 UCAR. This open source software is
! provided by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

! BEGIN DART PREPROCESS KIND LIST
! VORTEX_LAT, KIND_VORTEX_LAT
! VORTEX_LON, KIND_VORTEX_LON
! VORTEX_PMIN, KIND_VORTEX_PMIN
! VORTEX_WMAX, KIND_VORTEX_WMAX
! END DART PREPROCESS KIND LIST

! BEGIN DART PREPROCESS USE OF SPECIAL OBS_DEF MODULE
!   use obs_def_vortex_mod, only : get_expected_vortex_info
! END DART PREPROCESS USE OF SPECIAL OBS_DEF MODULE

! BEGIN DART PREPROCESS GET_EXPECTED_OBS_FROM_DEF
!         case(VORTEX_LAT)
!            call get_expected_vortex_info(state, location, obs_val, 'lat',istatus)
!         case(VORTEX_LON)
!            call get_expected_vortex_info(state, location, obs_val, 'lon',istatus)
!         case(VORTEX_PMIN)
!            call get_expected_vortex_info(state, location, obs_val, 'pmi',istatus)
!         case(VORTEX_WMAX)
!            call get_expected_vortex_info(state, location, obs_val, 'wma',istatus)
! END DART PREPROCESS GET_EXPECTED_OBS_FROM_DEF

! BEGIN DART PREPROCESS READ_OBS_DEF
!      case(VORTEX_LAT)
!         continue
!      case(VORTEX_LON)
!         continue
!      case(VORTEX_PMIN)
!         continue
!      case(VORTEX_WMAX)
!         continue
! END DART PREPROCESS READ_OBS_DEF

! BEGIN DART PREPROCESS WRITE_OBS_DEF
!      case(VORTEX_LAT)
!         continue
!      case(VORTEX_LON)
!         continue
!      case(VORTEX_PMIN)
!         continue
!      case(VORTEX_WMAX)
!         continue
! END DART PREPROCESS WRITE_OBS_DEF

! BEGIN DART PREPROCESS INTERACTIVE_OBS_DEF
!      case(VORTEX_LAT)
!         continue
!      case(VORTEX_LON)
!         continue
!      case(VORTEX_PMIN)
!         continue
!      case(VORTEX_WMAX)
!         continue
! END DART PREPROCESS INTERACTIVE_OBS_DEF

! BEGIN DART PREPROCESS MODULE CODE
module obs_def_vortex_mod

! <next few lines under version control, do not edit>
! $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/obs_def/obs_def_vortex_mod.f90 $
! $Id: obs_def_vortex_mod.f90 4933 2011-06-01 17:55:44Z thoar $
! $Revision: 4933 $
! $Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $

use        types_mod, only : r8, missing_r8, ps0, PI, gravity
use    utilities_mod, only : register_module, error_handler, E_ERR
use     location_mod, only : location_type, write_location, read_location
use  assim_model_mod, only : interpolate
use     obs_kind_mod, only : KIND_U_WIND_COMPONENT, KIND_V_WIND_COMPONENT, &
                             KIND_TEMPERATURE, KIND_VERTICAL_VELOCITY, &
                             KIND_RAINWATER_MIXING_RATIO, KIND_DENSITY, &
                             KIND_VORTEX_LAT, KIND_VORTEX_LON, KIND_VORTEX_PMIN, &
                             KIND_VORTEX_WMAX

implicit none
private

public :: get_expected_vortex_info

! version controlled file description for error handling, do not edit
character(len=128), parameter :: &
   source   = "$URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/obs_def/obs_def_vortex_mod.f90 $", &
   revision = "$Revision: 4933 $", &
   revdate  = "$Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $"

logical, save :: module_initialized = .false.

! Storage for the special information required for observations of this type
integer, parameter  :: max_vortex_obs = 3000

contains

!----------------------------------------------------------------------

subroutine initialize_module

call register_module(source, revision, revdate)
module_initialized = .true.

end subroutine initialize_module

!----------------------------------------------------------------------

subroutine get_expected_vortex_info(state_vector, location, vinfo, whichinfo, istatus)

!
! Return vortex info according to whichinfo
! whichinfo='lat', vinfo = center lat
! whichinfo='lon', vinfo = center lon
! whichinfo='pmi', vinfo =  minimum sea level pressure
! 

real(r8),            intent(in)  :: state_vector(:)
type(location_type), intent(in)  :: location
character(len=3),    intent(in)  :: whichinfo
real(r8),            intent(out) :: vinfo
integer,             intent(out) :: istatus

if ( .not. module_initialized ) call initialize_module

if (whichinfo == 'lat') then
   call interpolate(state_vector, location, KIND_VORTEX_LAT, vinfo, istatus)
else if (whichinfo == 'lon') then
   call interpolate(state_vector, location, KIND_VORTEX_LON, vinfo, istatus)
else if (whichinfo == 'pmi') then
   call interpolate(state_vector, location, KIND_VORTEX_PMIN, vinfo, istatus)
else if (whichinfo == 'wma') then
   call interpolate(state_vector, location, KIND_VORTEX_WMAX, vinfo, istatus)
else
endif

if (istatus /= 0) then
   vinfo = missing_r8
   return
endif

end subroutine get_expected_vortex_info

end module obs_def_vortex_mod
! END DART PREPROCESS MODULE CODE
