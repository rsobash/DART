! DART software - Copyright 2004 - 2011 UCAR. This open source software is
! provided by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

program smoother

! <next few lines under version control, do not edit>
! $URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/reg_factor/smoother.f90 $
! $Id: smoother.f90 4933 2011-06-01 17:55:44Z thoar $
! $Revision: 4933 $
! $Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $

! Used to smooth regression confidence factor functions
! to get rid of sampling bumps

implicit none

! version controlled file description for error handling, do not edit
character(len=128), parameter :: &
   source   = "$URL: https://proxy.subversion.ucar.edu/DAReS/DART/releases/Kodiak/reg_factor/smoother.f90 $", &
   revision = "$Revision: 4933 $", &
   revdate  = "$Date: 2011-06-01 12:55:44 -0500 (Wed, 01 Jun 2011) $"

integer :: i, j , n, width, inunit, outunit
real(r8), allocatable :: x(:), y(:), garb(:)
character (len = 30) :: in_file, out_file

write(*, *) 'input file name '
read(*, *) in_file

inunit = get_unit()
open(unit = inunit, file = in_file)

write(*, *) 'output file name'
read(*, *) out_file

outunit = get_unit()
open(unit = outunit, file = out_file)

write(*, *) 'input number of elements'
read(*, *) n

write(*, *) 'input smoothing half-width '
read(*, *) width

allocate(x(n), y(n), garb(n))
do i = 1, n
   read(inunit, *) garb(i), x(i)
end do
close(inunit)

! Do the smoothing
y = x
do i = 1 + width, n - width
   y(i) = 0.0_r8
   do j = i - width, i + width
      y(i) = y(i) + x(j)
   end do 
   y(i) = y(i) / (2.0_r8 * width + 1.0_r8)
end do

do i = 1, n
   write(outunit, *) garb(i), y(i)
end do
close(outunit)

end program smoother

