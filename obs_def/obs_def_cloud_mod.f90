! DART software - Copyright 2004 - 2011 UCAR. This open source software is
! provided by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

! BEGIN DART PREPROCESS KIND LIST
!CLOUD_LIQUID_WATER, KIND_CLOUD_LIQUID_WATER,  COMMON_CODE
!CLOUD_ICE,          KIND_CLOUD_ICE,           COMMON_CODE
!CLOUD_FRACTION,     KIND_CLOUD_FRACTION,      COMMON_CODE
! END DART PREPROCESS KIND LIST

! eventually these should become the following to be consistent
! with other types of mixing ratios.  this is just a proposed
! rename of the KIND; any code using it would remain the same.
! but multiple models and forward operators could be using the old
! names; the change must be coordinated across the entire project.
!!KIND_CLOUD_LIQUID_WATER -> KIND_CLOUDWATER_MIXING_RATIO
!!KIND_CLOUD_ICE -> KIND_ICE_MIXING_RATIO

! <next few lines under version control, do not edit>
! $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/obs_def/obs_def_cloud_mod.f90 $
! $Id: obs_def_cloud_mod.f90 4933 2011-06-01 17:55:44Z thoar $
! $Revision: 4933 $
! $Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $

