#include "symbol.inc"
      MODULE pot
      USE prec
      USE base, ONLY: write_pot
      USE charge

      COMPLEX(q), ALLOCATABLE, PRIVATE :: EXTERNAL_POTENTIAL(:)
      PRIVATE ADD_EXTERNAL_POTENTIAL

      INTERFACE str
         MODULE PROCEDURE WRT_POTENTIAL_TO_STRING
      END INTERFACE str

      CONTAINS
!************************ SUBROUTINE POTLOK ****************************
!
!> This subroutine calculates the total local potential CVTOT
!> which is the sum of the hartree potential, the exchange-correlation
!> potential and the ionic local potential. The routine also calculates
!> the total local potential SV on the small grid.
!>
!> On entry: \n 
!>  CHTOT(:,1)    density \n
!>  CHTOT(:,2)    respectively CHTOT(:,2:4) contain the magnetization \n
!> On return (LNONCOLLINEAR=.FALSE.): \n
!>  CVTOT(:,1)    potential for up \n
!>  CVTOT(:,2)    potential for down \n
!>
!> On return (LNONCOLLINEAR=.TRUE.): \n
!>  CVTOT(:,1:4)  spinor representation of potential
!>
!> @details @ref openacc :
!> On entering this subroutine OpenACC execution is switched off.
!> On exit the OpenACC execution mode reverts to its original status,
!> and when mopenacc_struct_dev::openacc_exec_on = .TRUE. the array
!> SV is updated on the device (if present).
!
! RCS:  $Id: pot.F,v 1.5 2003/06/27 13:22:22 kresse Exp kresse $
!***********************************************************************
    SUBROUTINE POTLOK(KINEDEN,GRID,GRIDC,GRID_SOFT,COMM_INTER,WDES,  &
                  INFO,XC,P,T_INFO,E,LATT_CUR,  &
                  CHDEN,CHTOT,CSTRF,CVTOT,DENCOR,SV,MUTOT,MU,SOFT_TO_C,XCSIF )
#ifdef _OPENACC
      USE mopenacc
#endif
      USE prec
      USE mpimy
      USE mgrid
      USE pseudo
      USE lattice
      USE poscar
      USE setexm_struct_def, ONLY : xc_info
      USE ldalib, only: fexcf, fexcp
      USE tau_mu, ONLY : tau_handle
      USE base
      USE wave
      USE mdipol
      USE Constrained_M_modular
      USE main_mpi, ONLY: COMM
      USE scpc, ONLY: SCPC_APPLY
! solvation__
      USE solvation
! solvation__
! bexternal__
      USE bexternal
! bexternal__
! embedding__
      USE mextpot
! embedding__
      IMPLICIT NONE

      TYPE (tau_handle)  KINEDEN
      TYPE (xc_info)     XC
      TYPE (grid_3d)     GRID,GRIDC,GRID_SOFT
      TYPE (wavedes)     WDES
      TYPE (transit)     SOFT_TO_C
      TYPE (info_struct) INFO
      TYPE (type_info)   T_INFO
      TYPE (potcar)      P (T_INFO%NTYP)
      TYPE (energy)      E
      TYPE (latt)        LATT_CUR
      TYPE (communic)    COMM_INTER

      RGRID   SV(DIMREAL(GRID%MPLWV), WDES%NCDIJ)
      COMPLEX(q) CSTRF(GRIDC%MPLWV,T_INFO%NTYP), CHDEN(GRID_SOFT%MPLWV,WDES%NCDIJ), &
                 CHTOT(GRIDC%MPLWV, WDES%NCDIJ), CVTOT(GRIDC%MPLWV,WDES%NCDIJ)
      RGRID      DENCOR(GRIDC%RL%NP)
      REAL(q)    XCSIF(3,3),TMPSIF(3,3),XDMTMP(1)
! work arrays (allocated after call to FEXCG)
      COMPLEX(q), ALLOCATABLE::  CWORK1(:),CWORK(:,:)
      REAL(q) ELECTROSTATIC,EXC,EXCG,RINPL,XCENCG,FACTM
      LOGICAL, EXTERNAL :: L_NO_LSDA_GLOBAL
      INTEGER I,ISP,MWORK1,N1,N2,N3,NC,NG
      COMPLEX(q) CVZERG
      RGRID , POINTER :: MU(:,:)
      COMPLEX(q), POINTER :: MUTOT(:,:)

      RGRID , POINTER :: MU_(:,:)
      COMPLEX(q), POINTER :: MUTOT_(:,:)

#ifdef libbeef
      LOGICAL LBEEFCALCBASIS, LBEEFBAS
      COMMON /BEEFENS/ LBEEFCALCBASIS,LBEEFBAS
      
      real(q), allocatable, save :: beefxc(:), beenergies(:)
      LOGICAL SAVELUSE_VDW
      INTEGER BEEFCOUNTER
#endif

#ifdef noAugXCmeta
      COMPLEX(q), ALLOCATABLE :: CTMP(:,:)
#endif

      PROFILING_START('potlok')

#ifdef noAugXCmeta
      ALLOCATE(CTMP(GRIDC%MPLWV,WDES%NCDIJ))
!$ACC ENTER DATA COPYIN(CHDEN) CREATE(CTMP) __IF_ASYNC__
#else
#define CTMP CHTOT
#endif

      IF (XC%LMU) THEN
         IF (.NOT.ASSOCIATED(MU) .OR. .NOT.ASSOCIATED(MUTOT)) &
            CALL vtutor%bug("POTLOK: MU and/or MUTOT not associated.", __FILE__, __LINE__)
         MU_ => MU ; MUTOT_ => MUTOT
!$ACC ENTER DATA CREATE(MU_,MUTOT_) __IF_ASYNC__
!$ACC KERNELS PRESENT(MU_,MUTOT_) __IF_ASYNC__
         MU_=0 ; MUTOT_=0
!$ACC END KERNELS
      ELSE
         ALLOCATE(MU_(1,WDES%NCDIJ),MUTOT_(1,WDES%NCDIJ))
!$ACC ENTER DATA CREATE(MU_,MUTOT_) __IF_ASYNC__
      ENDIF

      MWORK1=MAX(GRIDC%MPLWV,GRID_SOFT%MPLWV)
      ALLOCATE(CWORK1(MWORK1),CWORK(GRIDC%MPLWV,WDES%NCDIJ))
!$ACC ENTER DATA COPYIN(CHTOT) CREATE(CVTOT,CWORK,CWORK1) __IF_ASYNC__

!-----------------------------------------------------------------------
!
!  calculate the exchange correlation potential and the dc. correction
!
!-----------------------------------------------------------------------
      EXC     =0
      E%XCENC =0
      E%EXCG  =0
      E%CVZERO=0
      XCSIF   =0

!$ACC KERNELS PRESENT(CVTOT) __IF_ASYNC__
      CVTOT=0
!$ACC END KERNELS

#ifdef libbeef
      IF(LBEEFCALCBASIS) THEN
         BEEFCOUNTER = 1
         SAVELUSE_VDW = XC%LUSE_VDW
!        for calculation of nscf xc energies for error estimates,
!        vdW interactions don't need to be calculated
         XC%LUSE_VDW = .FALSE.
         IF(.NOT.ALLOCATED(beefxc)) ALLOCATE(beefxc(32))
         IF(.NOT.ALLOCATED(beenergies)) ALLOCATE(beenergies(2000))
      ENDIF
#endif

! test
      IF (.NOT.XC%LNOXC) THEN
! test
         ! transform the charge density to real space
         EXCG  =0
         XCENCG=0
         CVZERG=0
         TMPSIF=0

#ifdef noAugXCmeta
         ! We will use the soft charge density instead of the augmented one
!$ACC KERNELS PRESENT(CTMP) __IF_ASYNC__
         CTMP=0
!$ACC END KERNELS
         DO ISP=1,WDES%NCDIJ
            CALL ADD_GRID(GRIDC,GRID_SOFT,SOFT_TO_C,CHDEN(1,ISP),CTMP(1,ISP))
            CALL SETUNB_COMPAT(CTMP(1,ISP),GRIDC)
         ENDDO
#endif
         ! Bring the charge density to real space
         DO ISP=1,WDES%NCDIJ
            CALL FFT3D(CHTOT(1,ISP),GRIDC,1)
#ifdef noAugXCmeta
            CALL FFT3D(CTMP(1,ISP),GRIDC,1)
#endif
         ENDDO

#ifdef libbeef
 4096    IF (LBEEFCALCBASIS) THEN
            !for calculation of nscf xc energies for error estimates,
            !cycle through beef legendre polynomial basis
            IF(BEEFCOUNTER.LT.31) THEN
               CALL BEEFSETMODE(BEEFCOUNTER-1)
            ELSE
               CALL BEEFSETMODE(BEEFCOUNTER-34)
            ENDIF
         ENDIF
#endif

         IF (WDES%ISPIN==2) THEN

            ! get the charge and the total magnetization
            CALL MAG_DENSITY(CTMP, CWORK, GRIDC, WDES%NCDIJ)
! do LDA+U instead of LSDA+U
            IF (L_NO_LSDA_GLOBAL()) THEN
!$ACC KERNELS PRESENT(CWORK) __IF_ASYNC__
               CWORK(:,2)=0
!$ACC END KERNELS
            ENDIF

            IF (XC%LUSE_LIBXC.OR.XC%LDOGGA.OR.XC%LDOMETAGGA) THEN
               ! gradient corrections to LDA
               ! unfortunately FEXCGS requires (up,down) density
               ! instead of (rho,mag)
               IF (.NOT.XC%LDOMETAGGA) CALL RL_FLIP(CWORK, GRIDC, 2, .TRUE.)
               ! GGA potential
               CALL FEXCG(XC,2,GRIDC,LATT_CUR,XCENCG,EXCG,CVZERG,TMPSIF, &
                    KINEDEN,CWORK,DENCOR,CVTOT,MUTOT_,XDMTMP,0,1,SIZE(MUTOT_,1))
               IF (.NOT.XC%LDOMETAGGA) CALL RL_FLIP(CWORK, GRIDC, 2, .FALSE.)
            ENDIF

            ! add LDA part of potential
            CALL FEXCF(GRIDC,XC,LATT_CUR%OMEGA, &
               CWORK(1,1), CWORK(1,2), DENCOR, CVTOT(1,1), CVTOT(1,2), &
               E%CVZERO,EXC,E%XCENC,XCSIF, .TRUE.)
!gk COH
            ! add Coulomb hole
            CALL COHSM1_RGRID(XC, 2, CWORK(1,1), CVTOT(1,1), DENCOR, GRIDC, LATT_CUR%OMEGA, .TRUE.)
!gK COHend
            ! we have now the potential for up and down stored in CVTOT(:,1) and CVTOT(:,2)

            ! get the proper direction vx = v0 + hat m delta v
            CALL MAG_DIRECTION(CTMP(1,1), CVTOT(1,1), GRIDC, WDES%NCDIJ)

         ELSEIF (WDES%LNONCOLLINEAR) THEN

            IF (XC%LUSE_LIBXC.OR.XC%LDOGGA.OR.XC%LDOMETAGGA) THEN
               CALL FEXCG(XC,4,GRIDC,LATT_CUR,XCENCG,EXCG,CVZERG,TMPSIF, &
                    KINEDEN,CTMP,DENCOR,CVTOT,MUTOT_,XDMTMP,0,1,SIZE(MUTOT_,1))
            ENDIF

            IF (XC%LDOMETAGGA) THEN
               IF (XC%LMU) THEN
                  ! MUTOT comes out as two component (up,down) quantities, where
                  ! "up" and "down" are taken w.r.t. the local magnetization direction,
                  ! this is now cast into (rho, mag) form.
                  CALL MAG_DIRECTION(CTMP(1,1), MUTOT_(1,1), GRIDC, WDES%NCDIJ)
                  ! and rearranged from (rho,mag) to spinor representation
                  CALL POT_FLIP_RL(MUTOT_, GRIDC, WDES%NCDIJ)
               ENDIF
            ENDIF

            ! FEXCF requires (rho,mag) density instead of (up,down)
            CALL MAG_DENSITY(CTMP, CWORK, GRIDC, WDES%NCDIJ)
! quick hack to do LDA+U instead of LSDA+U
            IF (L_NO_LSDA_GLOBAL()) THEN
!$ACC KERNELS PRESENT(CWORK) __IF_ASYNC__
               CWORK(:,2)=0
!$ACC END KERNELS
            ENDIF
! end of hack
            ! add LDA part of potential
            CALL FEXCF(GRIDC,XC,LATT_CUR%OMEGA, &
               CWORK(1,1), CWORK(1,2), DENCOR, CVTOT(1,1), CVTOT(1,2), &
               E%CVZERO,EXC,E%XCENC,XCSIF, .TRUE.)
!gk COH
            ! add Coulomb hole
            CALL COHSM1_RGRID(XC, 2, CWORK(1,1), CVTOT(1,1), DENCOR, GRIDC, LATT_CUR%OMEGA, .TRUE.)
!gK COHend
            ! we have now the potential for up and down stored in CVTOT(:,1) and CVTOT(:,2)
            ! get the proper direction vx = v0 + hat m delta v

            CALL MAG_DIRECTION(CTMP(1,1), CVTOT(1,1), GRIDC, WDES%NCDIJ)

         ELSE

            IF (XC%LUSE_LIBXC.OR.XC%LDOGGA.OR.XC%LDOMETAGGA) THEN
               ! gradient corrections to LDA
               CALL FEXCG(XC,1,GRIDC,LATT_CUR,XCENCG,EXCG,CVZERG,TMPSIF, &
                    KINEDEN,CTMP,DENCOR,CVTOT,MUTOT_,XDMTMP,0,1,SIZE(MUTOT_,1))
            ENDIF

            ! LDA part of potential
            CALL FEXCP(GRIDC,XC,LATT_CUR%OMEGA, &
                 CTMP,DENCOR,CVTOT,CWORK,E%CVZERO,EXC,E%XCENC,XCSIF,.TRUE.)
!gk COH
            ! add Coulomb hole
            CALL COHSM1_RGRID(XC, 1, CTMP(1,1), CVTOT(1,1), DENCOR, GRIDC, LATT_CUR%OMEGA, .TRUE.)
!gK COHend

         ENDIF

#ifdef libbeef
         IF(LBEEFCALCBASIS) THEN
            IF(BEEFCOUNTER.GT.0) THEN
               IF(BEEFCOUNTER.LE.31) THEN
                  beefxc(BEEFCOUNTER) = EXCG
                  BEEFCOUNTER = BEEFCOUNTER + 1
               ELSE
                 beefxc(32) = EXCG + beefxc(31)
#if defined(MPI) || defined(MPI_CHAIN)
                 IF (COMM%NODE_ME==COMM%IONODE) THEN
#endif
                     IF(.NOT.LBEEFBAS) THEN
                        CALL BEEFRANDINITDEF
                        CALL BEEFENSEMBLE(beefxc, beenergies)
                        WRITE(8,*) "BEEFens 2000 ensemble energies"
                        DO BEEFCOUNTER = 1,2000
                           WRITE(8,"(E35.15)") beenergies(BEEFCOUNTER)
                        ENDDO
                     ENDIF

                     WRITE(8,*) "BEEF xc energy contributions"
                     DO BEEFCOUNTER = 1,32
                        WRITE(8,*) BEEFCOUNTER, ": ", beefxc(BEEFCOUNTER)
                     ENDDO
#if defined(MPI) || defined(MPI_CHAIN)
                  ENDIF
#endif
                  LBEEFCALCBASIS = .FALSE.
                  BEEFCOUNTER = 0
                  XC%LUSE_VDW = SAVELUSE_VDW
                  CALL BEEFSETMODE(-1)
               ENDIF
               EXC     =0
               E%XCENC =0
               E%EXCG  =0
               E%CVZERO=0
               XCSIF   =0
               CVTOT   =0
               EXCG    =0
               XCENCG  =0
               CVZERG  =0
               TMPSIF  =0

               GOTO 4096
            ENDIF
         ENDIF
#endif

         XCSIF=XCSIF+TMPSIF
         E%EXCG=EXC+EXCG
         E%XCENC=E%XCENC+XCENCG
         E%CVZERO=E%CVZERO+CVZERG

      ELSE
         DO ISP=1,WDES%NCDIJ
            CALL FFT3D(CHTOT(1,ISP),GRIDC,1)
         ENDDO
      ENDIF

#ifdef noAugXCmeta
      ! Store CVTOT in CTMP
!$ACC KERNELS PRESENT(CTMP,CVTOT) __IF_ASYNC__
      CTMP=CVTOT
!$ACC END KERNELS
#endif

!-MM- changes to accomodate constrained moments
!-----------------------------------------------------------------------
! add constraining potential
!-----------------------------------------------------------------------
#ifndef NGXhalf
#ifndef NGZhalf
      IF (M_CONSTRAINED()) THEN
      ! NB. at this point both CHTOT and CVTOT must be given
      ! in (charge,magnetization) convention in real space
!$ACC UPDATE SELF(CHTOT,CVTOT) IF(ACC_EXEC_ON) WAIT(ACC_ASYNC_Q)
         CALL M_INT(CHTOT,GRIDC,WDES)
         CALL ADD_CONSTRAINING_POT(CVTOT,GRIDC,WDES)
!$ACC UPDATE DEVICE(CVTOT) __IF_ASYNC__
      ENDIF
#endif
#endif
!-MM- end of addition

!-----------------------------------------------------------------------
! calculate the total potential
!-----------------------------------------------------------------------
! add external electrostatic potential
      DIP%ECORR=0
      DIP%E_ION_EXTERN=0

      IF (DIP%LCOR_DIP) THEN
         ! get the total charge and store it in CWORK
         IF  ( WDES%NCDIJ > 1) THEN
            CALL MAG_DENSITY(CHTOT,CWORK, GRIDC, WDES%NCDIJ)
         ELSE
            CALL RL_ADD(CHTOT,1.0_q,CHTOT,0.0_q,CWORK,GRIDC)
         ENDIF

!$ACC UPDATE SELF(CWORK,CVTOT) IF(ACC_EXEC_ON) WAIT(ACC_ASYNC_Q)
           CALL CDIPOL(GRIDC, LATT_CUR,P,T_INFO, &
             CWORK,CSTRF,CVTOT(1,1), WDES%NCDIJ, INFO%NELECT )
!$ACC UPDATE DEVICE(CVTOT) __IF_ASYNC__

         CALL EXTERNAL_POT(GRIDC, LATT_CUR, CVTOT(1,1))
      ELSE
         CALL EXTERNAL_POT(GRIDC, LATT_CUR, CVTOT(1,1))
      ENDIF
! embedding__
      IF (EXTPT_LEXTPOT()) CALL EXTPT_EXTERNAL_POT_ADD(GRIDC, LATT_CUR, CVTOT(1,1))
! embedding__

      DO ISP=1,WDES%NCDIJ
         CALL FFT_RC_SCALE(CHTOT(1,ISP),CHTOT(1,ISP),GRIDC)
         CALL SETUNB_COMPAT(CHTOT(1,ISP),GRIDC)
      ENDDO
!-----------------------------------------------------------------------
! FFT of the exchange-correlation potential to reciprocal space
!-----------------------------------------------------------------------
      RINPL=1._q/GRIDC%NPLWV
      DO  ISP=1,WDES%NCDIJ 
         CALL RL_ADD(CVTOT(1,ISP),RINPL,CVTOT(1,ISP),0.0_q,CVTOT(1,ISP),GRIDC)
         CALL FFT3D(CVTOT(1,ISP),GRIDC,-1)
      ENDDO

      IF (XC%LMU) THEN
!-----------------------------------------------------------------------
! The same procedure to calculate MU from MUTOT
!-----------------------------------------------------------------------
         RINPL=1._q/GRIDC%NPLWV
         DO  ISP=1,WDES%NCDIJ
            CALL RL_ADD(MUTOT_(1,ISP),RINPL,MUTOT_(1,ISP),0._q,MUTOT_(1,ISP),GRIDC)
            CALL FFT3D(MUTOT_(1,ISP),GRIDC,-1)
         ENDDO
!-----------------------------------------------------------------------
! copy MUTOT_ to MU_ and set contribution of unbalanced lattice-vectors
! to zero, then FFT of MU_ and MUTOT_ to real space
!-----------------------------------------------------------------------
         DO ISP=1,WDES%NCDIJ
            CALL SETUNB_COMPAT(MUTOT_(1,ISP),GRIDC)
            CALL CP_GRID(GRIDC,GRID_SOFT,SOFT_TO_C,MUTOT_(1,ISP),CWORK1)
            CALL SETUNB(CWORK1,GRID_SOFT)
            CALL FFT3D(CWORK1,GRID_SOFT, 1)
            CALL RL_ADD(CWORK1,1.0_q,CWORK1,0.0_q,MU_(1,ISP),GRID_SOFT)

       ! final result is only correct for first in-band-group
       ! (i.e. proc with nodeid 1 in COMM_INTER)
       ! copy to other in-band-groups using COMM_INTER
       ! (see SET_RL_GRID() in mgrid.F, and M_divide() in mpi.F)
#ifdef realmode
            CALLMPI( M_bcast_d(COMM_INTER, MU_(1,ISP), GRID%RL%NP))
#else
            CALLMPI( M_bcast_z(COMM_INTER, MU_(1,ISP), GRID%RL%NP))
#endif
            CALL FFT3D(MUTOT_(1,ISP),GRIDC,1)
         ENDDO
      ENDIF
!-----------------------------------------------------------------------
! add the hartree potential and the double counting corrections
!-----------------------------------------------------------------------
      CALL POTHAR(GRIDC, LATT_CUR, CHTOT, CWORK,E%DENC)
!$ACC PARALLEL LOOP PRESENT(CVTOT,CWORK) __IF_ASYNC__
      DO I=1,GRIDC%RC%NP
         CVTOT(I,1)=CVTOT(I,1)+CWORK(I,1)
      ENDDO
!-----------------------------------------------------------------------
! add external potential in reciprocal space
!-----------------------------------------------------------------------
      CALL ADD_EXTERNAL_POTENTIAL(GRIDC, CVTOT)
! solvation__
!-----------------------------------------------------------------------
! add the dielectric corrections to CVTOT and the energy
!-----------------------------------------------------------------------
      CALL SOL_Vcorrection(INFO,T_INFO,LATT_CUR,P,WDES,GRIDC,CHTOT,CVTOT)
! solvation__
!-----------------------------------------------------------------------
!  add local pseudopotential potential
!-----------------------------------------------------------------------
      IF(INFO%TURBO==0)THEN
         CALL POTION(GRIDC,P,LATT_CUR,T_INFO,CWORK,CWORK1,CSTRF,E%PSCENC)
      ELSE
         PUSH_ACC_EXEC_ON(.FALSE.)
         CALL POTION_PARTICLE_MESH(GRIDC,P,LATT_CUR,T_INFO,CWORK,E%PSCENC,E%TEWEN)
         POP_ACC_EXEC_ON
!$ACC UPDATE DEVICE(CWORK) __IF_ASYNC__
      ENDIF

      ELECTROSTATIC=0
!$ACC PARALLEL LOOP COLLAPSE(force:2) PRESENT(GRIDC,CWORK,CHTOT) &
!$ACC& REDUCTION(+:ELECTROSTATIC) PRIVATE(N2,N3,NG,FACTM) __IF_ASYNC__
      col: DO NC=1,GRIDC%RC%NCOL
      N2= GRIDC%RC%I2(NC)
      N3= GRIDC%RC%I3(NC)
      row: DO N1=1,GRIDC%RC%NROW
        NG = N1 + (NC-1)*GRIDC%RC%NROW
        SETFACT1
        SETFACT

        ELECTROSTATIC=ELECTROSTATIC+ MULFACT CWORK(NG,1)*CONJG(CHTOT(NG,1))
      ENDDO row
      ENDDO col
      ELECTROSTATIC=ELECTROSTATIC+E%PSCENC-E%DENC+E%TEWEN

      E%PSCENC=E%PSCENC + DIP%ECORR + DIP%E_ION_EXTERN

      ! apply self consistent potential correction
      CALL SCPC_APPLY(GRIDC, LATT_CUR, CHTOT, P, T_INFO, CSTRF, CVTOT, E%ESCPC)

!$ACC PARALLEL LOOP PRESENT(CVTOT,CWORK) __IF_ASYNC__
      DO I=1,GRIDC%RC%NP
         CVTOT(I,1)=CVTOT(I,1)+CWORK(I,1)
      ENDDO
! bexternal__
      IF (LBEXTERNAL()) CALL BEXT_ADDV(CVTOT,GRIDC,SIZE(CVTOT,2))
! bexternal__
      CALL POT_FLIP(CVTOT, GRIDC,WDES%NCDIJ )
      ! solvation__
! vaclevel
      IF (LSOL) CALL GET_FERMISHIFT(LATT_CUR, T_INFO, GRIDC, WDES, CWORK, CHTOT)
! vaclevel
! solvation__

#ifdef noAugXCmeta
      CALL POT_FLIP(CTMP, GRIDC,WDES%NCDIJ )
#endif
!=======================================================================
! if overlap is used :
! copy CVTOT to SV and set contribution of unbalanced lattice-vectors
! to zero,  then  FFT of SV and CVTOT to real space
!=======================================================================

      DO ISP=1,WDES%NCDIJ
         CALL SETUNB_COMPAT(CVTOT(1,ISP),GRIDC)
         CALL CP_GRID(GRIDC,GRID_SOFT,SOFT_TO_C,CVTOT(1,ISP),CWORK1)
         CALL SETUNB(CWORK1,GRID_SOFT)
         CALL FFT3D(CWORK1,GRID_SOFT, 1)
         CALL RL_ADD(CWORK1,1.0_q,CWORK1,0.0_q,SV(1,ISP),GRID_SOFT)

         !  final result is only correct for first in-band-group
         ! (i.e. proc with nodeid 1 in COMM_INTER)
         !  copy to other in-band-groups using COMM_INTER
         ! (see SET_RL_GRID() in mgrid.F, and M_divide() in mpi.F)
#ifdef realmode
         CALLMPI( M_bcast_d(COMM_INTER, SV(1,ISP), GRID%RL%NP))
#else
         CALLMPI( M_bcast_z(COMM_INTER, SV(1,ISP), GRID%RL%NP))
#endif
         CALL FFT3D(CVTOT(1,ISP),GRIDC,1)
      ENDDO

#ifdef noAugXCmeta
      ! Subtract CTMP from CVTOT
      DO ISP=1,WDES%NCDIJ
         CALL RL_ADD(CVTOT(1,ISP),1.0_q,CTMP(1,ISP),-1.0_q,CVTOT(1,ISP),GRIDC)
      ENDDO
#endif

!$ACC EXIT DATA COPYOUT(CVTOT,CHTOT) DELETE(CWORK1,CWORK) __IF_ASYNC__

!$ACC EXIT DATA COPYOUT(MU_,MUTOT_)  IF(ACC_EXEC_ON.AND.XC%LMU) ASYNC(ACC_ASYNC_Q)
      IF (.NOT.XC%LMU) THEN
!$ACC EXIT DATA DELETE(MU_,MUTOT_) __IF_ASYNC__
         DEALLOCATE(MU_,MUTOT_)
      ENDIF
      NULLIFY(MU_,MUTOT_)

#ifdef noAugXCmeta
!$ACC EXIT DATA DELETE(CTMP,CHDEN) __IF_ASYNC__
      DEALLOCATE(CTMP)
#endif
!$ACC UPDATE SELF(SV) __IF_ASYNC__
!$ACC WAIT IF(ACC_EXEC_ON)
!$ACC UPDATE DEVICE(SV) IF_PRESENT IF(.NOT.ACC_EXEC_ON)

      DEALLOCATE(CWORK1,CWORK)

      PROFILING_STOP('potlok')

      RETURN
    END SUBROUTINE POTLOK


!***********************************************************************
!
!> Small helper routine to set the local potential on the coarse
!> plane wave grid from the full dense (augmentation) grid.
!>
!> CVTOT must be supplied in reciprocal space (not usually the case)
!> and SV is returned in real space.
!
!***********************************************************************

    SUBROUTINE SET_SV( GRID, GRIDC, GRID_SOFT, COMM_INTER, SOFT_TO_C, NCDIJ, SV, CVTOT)

      USE prec
      USE mpimy
      USE mgrid
      IMPLICIT NONE

      INTEGER NCDIJ
      TYPE (grid_3d)     GRID,GRIDC,GRID_SOFT
      TYPE (transit)     SOFT_TO_C

      RGRID   SV(DIMREAL(GRID%MPLWV), NCDIJ)
      COMPLEX(q) CVTOT(GRIDC%MPLWV, NCDIJ)
      TYPE (communic)    COMM_INTER
! work arrays
      COMPLEX(q) ::  CWORK1(GRID_SOFT%MPLWV)
      INTEGER ISP


      DO ISP=1,NCDIJ
         CALL SETUNB_COMPAT(CVTOT(1,ISP),GRIDC)
         CALL CP_GRID(GRIDC,GRID_SOFT,SOFT_TO_C,CVTOT(1,ISP),CWORK1)
         CALL SETUNB(CWORK1,GRID_SOFT)
         ! transform to real-space representation
         CALL FFT3D(CWORK1,GRID_SOFT, 1)
         CALL RL_ADD(CWORK1,1.0_q,CWORK1,0.0_q,SV(1,ISP),GRID_SOFT)

    !  final result is only correct for first in-band-group
    ! (i.e. proc with nodeid 1 in COMM_INTER)
    !  copy to other in-band-groups using COMM_INTER
    ! (see SET_RL_GRID() in mgrid.F, and M_divide() in mpi.F)
#ifdef realmode
         CALLMPI( M_bcast_d(COMM_INTER, SV(1,ISP), GRID%RL%NP))
#else
         CALLMPI( M_bcast_z(COMM_INTER, SV(1,ISP), GRID%RL%NP))
#endif
         CALL FFT3D(CVTOT(1,ISP),GRIDC,1)
      ENDDO
    END SUBROUTINE SET_SV

    SUBROUTINE ADD_EXTERNAL_POTENTIAL(GRIDC, CVTOT)
      ! adds the external potential stored as module variable
      USE mgrid, ONLY: grid_3d
      USE tutor, ONLY: vtutor
      IMPLICIT NONE
      TYPE(grid_3d), INTENT(IN) :: GRIDC
      COMPLEX(q), INTENT(INOUT) :: CVTOT(:,:)
      !
      IF (.NOT.ALLOCATED(EXTERNAL_POTENTIAL)) RETURN
      !
      ! sanity checks
      IF (SIZE(EXTERNAL_POTENTIAL, 1) < GRIDC%RC%NP) &
         CALL vtutor%bug("Size of external potential incompatible with grid.", __FILE__, __LINE__)
      IF (SIZE(CVTOT, 2) > 1) &
         CALL vtutor%bug("Implementation only tested without spin polarization.", __FILE__, __LINE__)
      !
      CALL ZAXPY(GRIDC%RC%NP, zone, EXTERNAL_POTENTIAL, 1, CVTOT, 1)
      !
    END SUBROUTINE ADD_EXTERNAL_POTENTIAL

    SUBROUTINE ADD_TO_EXTERNAL_POTENTIAL(POTENTIAL)
      ! add another contribution to existing external potential
      USE tutor, ONLY: vtutor
      IMPLICIT NONE
      COMPLEX(q), INTENT(IN) :: POTENTIAL(:)
      !
      IF (.NOT.ALLOCATED(EXTERNAL_POTENTIAL)) THEN
         ALLOCATE(EXTERNAL_POTENTIAL(SIZE(POTENTIAL)))
         EXTERNAL_POTENTIAL = POTENTIAL
      ELSE
         IF (SIZE(POTENTIAL) /= SIZE(EXTERNAL_POTENTIAL)) &
            CALL vtutor%bug("Size of potentials inconsistent.", __FILE__, __LINE__)
         CALL ZAXPY(SIZE(POTENTIAL), zone, POTENTIAL, 1, EXTERNAL_POTENTIAL, 1)
      END IF
      !
    END SUBROUTINE ADD_TO_EXTERNAL_POTENTIAL

    SUBROUTINE RESET_EXTERNAL_POTENTIAL()
      ! clear the external potential
      IF (ALLOCATED(EXTERNAL_POTENTIAL)) DEALLOCATE(EXTERNAL_POTENTIAL)
    END SUBROUTINE RESET_EXTERNAL_POTENTIAL

!************************ SUBROUTINE POTXC  ****************************
!
!> This subroutine to calculate the XC-potential including gradient
!> corrections.
!>
!> This routine is required to calculate the partial core
!> corrections to the forces.
!>
!> On entry: \n 
!>  CHTOT(:,1)    density \n
!>  CHTOT(:,2)    respectively CHTOT(:,2:4) contain the magnetization \n
!> On return (LNONCOLLINEAR=.FALSE.): \n
!>  CVTOT(:,1)    average potential \n
!>  CVTOT(:,2:4)  magnetic field
!
!***********************************************************************

      SUBROUTINE POTXC(KINEDEN,GRIDC,GRID_SOFT,SOFT_TO_C,INFO,XC,WDES, &
     &   LATT_CUR,CHDEN,CHTOT,DENCOR,CVTOT,MUTOT,IVDW,XDM,NPDDSC)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif
      USE prec
      USE setexm_struct_def, ONLY : xc_info
      USE ldalib, only: fexcf, fexcp
      USE tau_mu, ONLY : tau_handle
      USE mpimy
      USE mgrid
      USE lattice
      USE base
      USE wave

      IMPLICIT NONE

      TYPE (tau_handle)  KINEDEN
      TYPE (xc_info)     XC
      TYPE (grid_3d)     GRIDC,GRID_SOFT
      TYPE (wavedes)     WDES
      TYPE (transit)     SOFT_TO_C
      TYPE (info_struct) INFO
      TYPE (latt)        LATT_CUR
      INTEGER IVDW,NPDDSC,ISP
      COMPLEX(q) CHDEN(GRID_SOFT%MPLWV,WDES%NCDIJ)
      COMPLEX(q) CHTOT(GRIDC%MPLWV,WDES%NCDIJ),CVTOT(GRIDC%MPLWV,WDES%NCDIJ)
      RGRID      DENCOR(GRIDC%RL%NP)
      COMPLEX(q), POINTER :: MUTOT(:,:)
! work arrays
      REAL(q)    XCSIF(3,3),XDM(NPDDSC),EXC,EXCG,RINPL,XCENC,XCENCG
      COMPLEX(q), ALLOCATABLE:: CWORK(:,:)
      COMPLEX(q) CVZERG,CVZERO
      COMPLEX(q), POINTER :: MUTOT_(:,:)
#ifdef noAugXCmeta
      COMPLEX(q), ALLOCATABLE :: CTMP(:,:)
#endif

      PROFILING_START('potxc')

#ifdef noAugXCmeta
      ALLOCATE(CTMP(GRIDC%MPLWV,WDES%NCDIJ))
!$ACC ENTER DATA COPYIN(CHDEN) CREATE(CTMP) __IF_ASYNC__
#else
#define CTMP CHTOT
#endif

      IF (XC%LMU) THEN
         IF (.NOT.ASSOCIATED(MUTOT)) &
            CALL vtutor%bug("POTXC: MUTOT not associated.", __FILE__, __LINE__)
         MUTOT_ => MUTOT
!$ACC ENTER DATA CREATE(MUTOT_) __IF_ASYNC__
!$ACC KERNELS PRESENT(MUTOT_) __IF_ASYNC__
         MUTOT_=0
!$ACC END KERNELS
      ELSE
         ALLOCATE(MUTOT_(1,WDES%NCDIJ))
!$ACC ENTER DATA CREATE(MUTOT_) __IF_ASYNC__
      ENDIF

!$ACC ENTER DATA CREATE(CVTOT) __IF_ASYNC__
!$ACC KERNELS PRESENT(CVTOT) __IF_ASYNC__
      CVTOT = 0 
!$ACC END KERNELS

      ALLOCATE(CWORK(GRIDC%MPLWV,WDES%NCDIJ))
!$ACC ENTER DATA CREATE(CWORK) __IF_ASYNC__

#ifdef noAugXCmeta
      ! We will use the soft charge density instead of the augmented one
!$ACC KERNELS PRESENT(CTMP) __IF_ASYNC__
      CTMP=0
!$ACC END KERNELS
      DO ISP=1,WDES%NCDIJ
         CALL ADD_GRID(GRIDC,GRID_SOFT,SOFT_TO_C,CHDEN(1,ISP),CTMP(1,ISP))
         CALL SETUNB_COMPAT(CTMP(1,ISP),GRIDC)
      ENDDO
#endif
      ! Bring the charge density to real space
      DO ISP=1,WDES%NCDIJ
         CALL FFT3D(CHTOT(1,ISP),GRIDC,1)
#ifdef noAugXCmeta
         CALL FFT3D(CTMP(1,ISP),GRIDC,1)
#endif
      ENDDO

      IF (WDES%ISPIN==2) THEN

         ! get the charge and the total magnetization
         CALL MAG_DENSITY(CTMP, CWORK, GRIDC, WDES%NCDIJ)

         IF (XC%LUSE_LIBXC.OR.XC%LDOGGA.OR.XC%LDOMETAGGA) THEN
            ! gradient corrections to LDA
            ! unfortunately FEXCGS requires (up,down) density
            ! instead of (rho,mag)
            IF (.NOT.XC%LDOMETAGGA) CALL RL_FLIP(CWORK, GRIDC, 2, .TRUE.)
            CALL FEXCG(XC,2,GRIDC,LATT_CUR,XCENCG,EXCG,CVZERG,XCSIF, &
                 KINEDEN,CWORK,DENCOR,CVTOT,MUTOT_,XDM,IVDW,NPDDSC,SIZE(MUTOT_,1))
            IF (.NOT.XC%LDOMETAGGA) CALL RL_FLIP(CWORK, GRIDC, 2, .FALSE.)
         ENDIF

         ! add LDA part of potential
         CALL FEXCF(GRIDC,XC,LATT_CUR%OMEGA, &
            CWORK(1,1), CWORK(1,2), DENCOR, CVTOT(1,1), CVTOT(1,2), &
            CVZERO,EXC,XCENC,XCSIF, .TRUE.)
         ! we have now the potential for up and down stored in CVTOT(:,1) and CVTOT(:,2)

         ! get the proper direction vx = v0 + hat m delta v
         CALL MAG_DIRECTION(CTMP(1,1), CVTOT(1,1), GRIDC, WDES%NCDIJ)

      ELSEIF (WDES%LNONCOLLINEAR) THEN

!-MM- gradient corrections in the noncollinear case are calculated
!     a bit differently than in the collinear case
         IF (XC%LUSE_LIBXC.OR.XC%LDOGGA.OR.XC%LDOMETAGGA) THEN
            CALL FEXCG(XC,4,GRIDC,LATT_CUR,XCENCG,EXCG,CVZERG,XCSIF, &
                 KINEDEN,CTMP,DENCOR,CVTOT,MUTOT_,XDM,IVDW,NPDDSC,SIZE(MUTOT_,1))
         ENDIF

         ! FEXCF requires (rho,mag) density instead of (up,down)
         CALL MAG_DENSITY(CTMP, CWORK, GRIDC, WDES%NCDIJ)
         ! add LDA part of potential
         CALL FEXCF(GRIDC,XC,LATT_CUR%OMEGA, &
            CWORK(1,1), CWORK(1,2), DENCOR, CVTOT(1,1), CVTOT(1,2), &
            CVZERO,EXC,XCENC,XCSIF, .TRUE.)
         ! we have now the potential for up and down stored in CVTOT(:,1) and CVTOT(:,2)
         ! get the proper direction vx = v0 + hat m delta v
         IF (.NOT.XC%LDOMETAGGA) CALL MAG_DIRECTION(CTMP(1,1), CVTOT(1,1), GRIDC, WDES%NCDIJ)
!-MM- end of changes to calculation of gga in noncollinear case

         IF (XC%LDOMETAGGA) THEN
            IF (XC%LMU) THEN
! mM: just until all is done
!              WRITE(*,*) 'non-collinear mode for revTPSS not yet fully implemented, sorry ...'
!              STOP
! mM
               ! MUTOT and CWORK come out as two component (up,down) quantities, where
               ! "up" and "down" are taken w.r.t. the local magnetization direction,
               ! this is now cast into (rho, mag) form.
               CALL MAG_DIRECTION_KINDENS(CTMP(1,1), KINEDEN%TAU(1,1), MUTOT_(1,1), CVTOT(1,1), GRIDC, WDES%NCDIJ, LATT_CUR)
               ! and rearranged from (rho,mag) to spinor representation
               CALL POT_FLIP_RL(MUTOT_(1,1), GRIDC, WDES%NCDIJ)
            ELSE
               ! CWORK(potential) comes out with (spin up and down) representation
               ! It needs to flip to (total, mag) representation
               CALL MAG_DIRECTION(CTMP(1,1), CVTOT(1,1), GRIDC, WDES%NCDIJ)
            ENDIF
            ! rearrange the potential in (spinor) representation
            CALL POT_FLIP_RL(CVTOT(1,1), GRIDC, WDES%NCDIJ)
         ENDIF

      ELSE

         IF (XC%LUSE_LIBXC.OR.XC%LDOGGA.OR.XC%LDOMETAGGA) THEN
            ! gradient corrections to LDA
            CALL FEXCG(XC,1,GRIDC,LATT_CUR,XCENCG,EXCG,CVZERG,XCSIF, &
                 KINEDEN,CTMP,DENCOR,CVTOT,MUTOT_,XDM,IVDW,NPDDSC,SIZE(MUTOT_,1))
         ENDIF

         ! LDA part of potential
         CALL FEXCP(GRIDC,XC,LATT_CUR%OMEGA, &
              CTMP,DENCOR,CVTOT,CWORK,CVZERO,EXC,XCENC,XCSIF,.TRUE.)

      ENDIF

      ! Take the charge density back to reciprocal space
      DO ISP=1,WDES%NCDIJ
         CALL FFT_RC_SCALE(CHTOT(1,ISP),CHTOT(1,ISP),GRIDC)
         CALL SETUNB_COMPAT(CHTOT(1,ISP),GRIDC)
      ENDDO
!-----------------------------------------------------------------------
! FFT of the exchange-correlation potential to reciprocal space
!-----------------------------------------------------------------------
      RINPL=1._q/GRIDC%NPLWV
      DO  ISP=1,WDES%NCDIJ 
         CALL RL_ADD(CVTOT(1,ISP),RINPL,CVTOT(1,ISP),0.0_q,CVTOT(1,ISP),GRIDC)
         CALL FFT3D(CVTOT(1,ISP),GRIDC,-1)
         CALL SETUNB_COMPAT(CVTOT(1,ISP),GRIDC)
      ENDDO

      ! Flip CVTOT from (up,down) to (total,magnetization) storage mode
      ! This is done because the routine FORTAU needs the "total" component
      IF (WDES%LNONCOLLINEAR.AND.XC%LDOMETAGGA) CALL RC_FLIP_POTENTIAL(CVTOT,GRIDC,WDES%NCDIJ,.FALSE.)

!$ACC EXIT DATA DELETE(CWORK) __IF_ASYNC__
      DEALLOCATE(CWORK)

      IF (XC%LMU) THEN
!-----------------------------------------------------------------------
! The same procedure with MUTOT
!-----------------------------------------------------------------------
         DO  ISP=1,WDES%NCDIJ
            CALL RL_ADD(MUTOT_(1,ISP),RINPL,MUTOT_(1,ISP),0._q,MUTOT_(1,ISP),GRIDC)
            CALL FFT3D(MUTOT_(1,ISP),GRIDC,-1)
            CALL SETUNB_COMPAT(MUTOT_(1,ISP),GRIDC)
         ENDDO
         ! Flip MUTOT from (up,down) to (total,magnetization) storage mode
         ! This is done because the routine FORTAU needs the "total" component
         CALL RC_FLIP_POTENTIAL(MUTOT_,GRIDC,WDES%NCDIJ,.FALSE.)
!$ACC EXIT DATA COPYOUT(MUTOT_) __IF_ASYNC__
      ELSE
!$ACC EXIT DATA DELETE(MUTOT_) __IF_ASYNC__
         DEALLOCATE(MUTOT_)
      ENDIF
      NULLIFY(MUTOT_)

!$ACC EXIT DATA COPYOUT(CVTOT) __IF_ASYNC__

#ifdef noAugXCmeta
!$ACC EXIT DATA DELETE(CTMP,CHDEN) __IF_ASYNC__
      DEALLOCATE(CTMP)
#endif

      PROFILING_STOP('potxc')

      RETURN
      END SUBROUTINE POTXC


!************************ SUBROUTINE POTION_PARTICLE_MESH **************
!
!***********************************************************************

      SUBROUTINE POTION_PARTICLE_MESH(GRIDC,P, LATT_CUR, T_INFO, CVPS, PSCENC, TEWEN, FOR)
      USE ini
      USE prec
      USE mgrid
      USE pseudo
      USE lattice
      USE poscar
      USE constant
      USE charge
      IMPLICIT NONE
      TYPE (grid_3d) GRIDC
      TYPE (type_info) T_INFO
      TYPE (potcar) P(T_INFO%NTYP)
      TYPE (latt) LATT_CUR
      COMPLEX(q) CVPS(GRIDC%RC%NP)
      REAL(q) PSCENC,TEWEN
      REAL(q), OPTIONAL :: FOR(:,:)
      ! local variables
      REAL(q) ZVSUM,G,GX,GY,GZ,TEWEN0
      INTEGER NT,NIS,NI,N,N1,N2,N3,NC,FACTM
      REAL(q), ALLOCATABLE :: QTOT(:)
      COMPLEX(q),ALLOCATABLE :: CHG(:)

      ZVSUM=0
      DO NT=1,T_INFO%NTYP
         ZVSUM=ZVSUM+P(NT)%ZVALF*T_INFO%NITYP(NT)*T_INFO%VCA(NT)
      ENDDO

      PSCENC=0
      DO NT=1,T_INFO%NTYP
         PSCENC=PSCENC+P(NT)%PSCORE*T_INFO%VCA(NT)*T_INFO%NITYP(NT)*(ZVSUM/LATT_CUR%OMEGA)
      ENDDO

      TEWEN=-PSCENC
      DO NT=1,T_INFO%NTYP
         TEWEN=TEWEN-P(NT)%ESELF*T_INFO%VCA(NT)*T_INFO%NITYP(NT)
      ENDDO

      CVPS =0._q
      ALLOCATE(CHG(GRIDC%MPLWV))
      CHG=0

      ! add pseudo chg.dens. and FFT to recipr.space
      DO NT=1,T_INFO%NTYP
         P(NT)%USESPL=>P(NT)%RHOSPL
         P(NT)%USEZ=-P(NT)%ZVALF
         P(NT)%USECUT=P(NT)%RCUTRHO
      END DO

      ALLOCATE(QTOT(T_INFO%NIONS))

      CALL RHOADD(T_INFO,LATT_CUR,P,GRIDC,CHG,QTOT)

      ! multiply by 4pi/G^2
      ! loop over recipr.lattice points
      N=0
      TEWEN0=0._q
      col: DO NC=1,GRIDC%RC%NCOL
         N2= GRIDC%RC%I2(NC)
         N3= GRIDC%RC%I3(NC)
         row: DO N1=1,GRIDC%RC%NROW
            N=N+1
            SETFACT1
            SETFACT

            !=======================================================================
            ! calculate the magnitude of the reciprocal lattice vector
            !=======================================================================
            GX= GRIDC%LPCTX(N1)*LATT_CUR%B(1,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(1,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(1,3)
            GY= GRIDC%LPCTX(N1)*LATT_CUR%B(2,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(2,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(2,3)
            GZ= GRIDC%LPCTX(N1)*LATT_CUR%B(3,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(3,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(3,3)

            G=SQRT(GX**2+GY**2+GZ**2)*2*PI
            IF ( (GRIDC%LPCTX(N1)/=0) .OR. (GRIDC%LPCTY(N2)/=0) .OR. (GRIDC%LPCTZ(N3)/=0) ) THEN                
!              CVPS(N) = CVPS(N) + ((EDEPS/LATT_CUR%OMEGA)*CHG(N)/G**2)
               CVPS(N)=((EDEPS/LATT_CUR%OMEGA)*CHG(N)/G**2)
            ELSE
               CVPS(N)=0._q
            ENDIF
            TEWEN0=TEWEN0+MULFACT CVPS(N)*CONJG(CHG(N))*0.5_q

         ENDDO row
      ENDDO col
      CALLMPI( M_sum_d(GRIDC%COMM,TEWEN0,1))
      TEWEN=TEWEN+TEWEN0

      CALL SETUNB(CVPS,GRIDC)
      DEALLOCATE(CHG)

      IF (PRESENT(FOR)) THEN
         ! bring the potential to real space
         CALL FFT3D(CVPS(1),GRIDC,1)
         ! calculate force on each ion
         !
         ! (dE/dR_i,a) = e^2 \int d^3 r (drho_i(|r-R_i|)/dR_i,a) V(r)
         ! i=1..NION
         ! a=1..3 (x,y,z)
         !
         ! drho_i(|r-R_i|)/dR_i,a = -rho'(|r-R_i|) (r_a-R_i,a)/|r-R_i|
         !
         ! Evaluate f_i(r)=d rho/dr*(r-R_i)/|r-R_i| on the grid for each ion
         ! and integrate F_i = \int dr f_i(r) V(r)
         NIS=1
         type: DO NT=1,T_INFO%NTYP
            IF (.NOT.ASSOCIATED(P(NT)%USESPL)) THEN
               NIS = NIS+T_INFO%NITYP(NT); CYCLE type
            ENDIF
            ions: DO NI=NIS,T_INFO%NITYP(NT)+NIS-1
               CALL RHODER(T_INFO,LATT_CUR,P(NT),NI,GRIDC,QTOT,CVPS,FOR(1,NI))
            ENDDO ions
            NIS = NIS+T_INFO%NITYP(NT)
         ENDDO type
         FOR=FOR*LATT_CUR%OMEGA
         ! take the potential back to reciprocal space
         CALL RL_ADD(CVPS(1),1._q/GRIDC%NPLWV,CVPS(1),0.0_q,CVPS(1),GRIDC)
         CALL FFT3D(CVPS(1),GRIDC,-1)
         CALL SETUNB_COMPAT(CVPS(1),GRIDC)
      ENDIF

      DEALLOCATE(QTOT)

      RETURN
      END SUBROUTINE POTION_PARTICLE_MESH

      !> compute individual contributions to the potential and 
      !> write potential information to OUTCAR, LOCPOT, and HDF5 file
     SUBROUTINE WRITE_POTENTIAL(IO, KINEDEN, GRID, GRIDC, GRID_SOFT, WDES, &
            INFO, XC_DATA, P, T_INFO, E, LATT_CUR, CHDEN, CHTOT, CSTRF, &
            CVTOT, DENCOR, SV, HAMILTONIAN, SOFT_TO_C, XCSIF, DYN, DIP, &
            LMDIM, N_MIX_PAW, CDIJ)

         USE base, ONLY: in_struct, info_struct, energy
         USE fileio, ONLY: OUTPOT
         USE hamil_struct_def, ONLY: ham_handle
         USE mdipol, ONLY: dipol, WRITE_VACUUM_LEVEL
         USE mgrid, ONLY: grid_3d, transit
         USE poscar, ONLY: latt, dynamics, type_info, OUTPOS
         USE pseudo_struct_def, ONLY: potcar
         USE setexm, ONLY: xc_info, XC_DATA_NOXC, PUSH_XC_TYPE
         USE tau_mu, ONLY: tau_handle
         USE wave_struct_def, ONLY: wavedes
         USE tutor, ONLY: vtutor
#ifdef VASP_HDF5
         USE vhdf5, ONLY: GRP_RESULTS, GRP_POTENTIAL, IH5OUTFILEID, VH5_WRITE_POTENTIAL
#endif

         IMPLICIT NONE

         TYPE(in_struct), INTENT(IN)  :: IO        !< input output unit handle
         ! begin required for POTLOK
         TYPE(tau_handle), INTENT(IN) :: KINEDEN   !< kinetic energy density handle
         TYPE(grid_3d), INTENT(IN)    :: GRID      !< grid for wavefunctions
         TYPE(grid_3d), INTENT(IN)    :: GRIDC     !< grid for potentials/charge
         TYPE(grid_3d), INTENT(IN)    :: GRID_SOFT !< soft grid for potentials/charge
         TYPE(wavedes), INTENT(IN)    :: WDES      !< wavefunction descriptor
         TYPE(info_struct), INTENT(IN):: INFO      !< info about algo etc.
         TYPE(xc_info), INTENT(INOUT) :: XC_DATA   !< xc settings
         TYPE(potcar), INTENT(IN)     :: P(:)      !< structure to support radial grid
         TYPE(type_info), INTENT(IN)  :: T_INFO    !< ionic positions in superlattice
         TYPE(energy), INTENT(INOUT)  :: E         !< energy handle for double counting, band energies, etc.
         TYPE(latt), INTENT(IN)       :: LATT_CUR  !< lattice parameter
         COMPLEX(q), INTENT(IN)       :: CHDEN(:,:)!< pseudo charge density on soft grid
         COMPLEX(q), INTENT(IN)       :: CHTOT(:,:)!< total charge density on fine grid
         COMPLEX(q), INTENT(IN)       :: CSTRF(:,:)!< structure factor
         COMPLEX(q), INTENT(INOUT)    :: CVTOT(:,:)!< local potential
         RGRID, INTENT(INOUT)         :: DENCOR(:) !< partial core charge
         RGRID, INTENT(INOUT)         :: SV(:,:)   !< total local potential on the soft grid
         TYPE(ham_handle), INTENT(IN) :: HAMILTONIAN !< handle for MGGA potential MU and MUTOT
         TYPE(transit), INTENT(IN)    :: SOFT_TO_C !< index table between GRID_SOFT and GRIDC
         REAL(q), INTENT(INOUT)       :: XCSIF(3,3)!< stress tensor from XC
         ! end required for POTLOK
         TYPE(dynamics), INTENT(IN)   :: DYN       !< contains position of ions
         TYPE(dipol), INTENT(INOUT)   :: DIP       !< handle electrostatic dipole corrections from mdipol
         INTEGER, INTENT(IN)          :: LMDIM     !< no. of augmentation channels
         INTEGER, INTENT(IN)          :: N_MIX_PAW !< number of elements of the augmentation occupancies mixed on the local node
         OVERLAP, INTENT(INOUT)       :: CDIJ(:,:,:,:) !< strength parameters
         ! local
         REAL(q) DUMMY(1)

         IF (WDES%COMM_KINTER%NODE_ME /= 1) RETURN

         IF (SHOULD_WRITE_POT(IO%LH5, IO%WRT_POTENTIAL)) THEN
            CALL OUTPOT_TO_POT("POT", WRITE_PAW=.TRUE.)
         ELSE IF (SHOULD_VASPWAVE_HAVE_POT(IO%LH5, IO%WRT_POTENTIAL)) THEN
            CALL OUTPOT_TO_VASPWAVE
         END IF

         CALL OUTPOT_TO_VASPOUT

         IF (SHOULD_WRITE_LOCPOT(IO%WRT_POTENTIAL)) &
            CALL OUTPOT_TO_LOCPOT

         IF (DIP%IDIPCO > 0 .AND. DIP%LCOR_DIP) &
            CALL OUTPUT_VACUUM_LEVEL

      CONTAINS


      !> compute the local potential write it to LOCPOT
      SUBROUTINE OUTPOT_TO_LOCPOT
         IF (IO%WRT_POTENTIAL%LVHAR) CALL PUSH_XC_TYPE(XC_DATA,XC_DATA_NOXC)
         CALL POTLOK(KINEDEN,GRID,GRIDC,GRID_SOFT, WDES%COMM_INTER, WDES, &
                  INFO,XC_DATA,P,T_INFO,E,LATT_CUR, &
                  CHDEN,CHTOT,CSTRF,CVTOT,DENCOR,SV,HAMILTONIAN%MUTOT,HAMILTONIAN%MU,SOFT_TO_C,XCSIF)
         CALL OUTPOT_TO_POT("LOCPOT", WRITE_PAW=.FALSE.)
      END SUBROUTINE OUTPOT_TO_LOCPOT


      SUBROUTINE OUTPUT_VACUUM_LEVEL
         IF (DIP%VACPOTAV .and. IO%WRT_POTENTIAL%LVTOT) THEN
            CALL vtutor%alert("You have requested that vacuum potentials are determined &
            &using the total potential (LVTOT = .True.), as opposed to just the &
            &hartree and ionic contributions. This selection requires large vacuum in your &
            &cell and a tightly converged calculations to work. Consider using &
            &LVHAR = .True. for a more rapid determination of the vacuum potentials.")
         ENDIF
         ! call the dipol routine without changing the potential
         ! It only makes sense to write out the vacuum potential
         ! if corrections to the potential are requested
         DIP%LCOR_DIP = .FALSE.
         CALL CDIPOL_CHTOT_REC(GRIDC, LATT_CUR,P,T_INFO, &
            CHTOT,CSTRF,CVTOT, WDES%NCDIJ, INFO%NELECT, E%PSCENC )
         IF (DIP%IDIPCO < 4) THEN
            CALL WRITE_VACUUM_LEVEL(IO%IU6)
         END IF
         DIP%LCOR_DIP = .TRUE.
      END SUBROUTINE OUTPUT_VACUUM_LEVEL


      !> write the information to restart from a potential to vaspwave
      SUBROUTINE OUTPOT_TO_VASPWAVE
#ifdef VASP_HDF5
         USE pawm, ONLY: SET_RHO_PAW
         USE vhdf5, ONLY: IH5WAVEFILEID, VH5_WRITE_PAW_OCCUPANCIES, GRP_POTENTIAL
         REAL(q) DLM_EXX(N_MIX_PAW,WDES%NCDIJ)
         INTEGER SPIN
         !
         CALL RC_FLIP_POTENTIAL(CVTOT, GRIDC, WDES%NCDIJ, .FALSE.)
         !
         CALL VH5_WRITE_POTENTIAL(IH5WAVEFILEID, "total", GRIDC, CVTOT, GROUP="potential")
         CALL SET_RHO_PAW(WDES, P, T_INFO, INFO%LOVERL, WDES%NCDIJ, LMDIM, &
              CDIJ, DLM_EXX)
         DO SPIN = 1, WDES%NCDIJ
            CALL VH5_WRITE_PAW_OCCUPANCIES(IH5WAVEFILEID, GRP_POTENTIAL, P, T_INFO, &
               INFO%LOVERL, DLM_EXX(:,SPIN), GRIDC%COMM, SPIN)
         END DO
         !
         CALL RC_FLIP_POTENTIAL(CVTOT, GRIDC, WDES%NCDIJ, .TRUE.)
#endif
      END SUBROUTINE OUTPOT_TO_VASPWAVE


      !> compute the local potentials and write them to the HDF5 file
      SUBROUTINE OUTPOT_TO_VASPOUT
#ifdef VASP_HDF5
         COMPLEX(q), ALLOCATABLE :: CHARGE(:), WORK(:)
         INTEGER SPIN
         !
         IF (SHOULD_VASPOUT_HAVE_TOTAL_POT(IO%WRT_POTENTIAL)) THEN
            CALL RC_FLIP_POTENTIAL(CVTOT, GRIDC, WDES%NCDIJ, .FALSE.)
            CALL VH5_WRITE_POTENTIAL(IH5OUTFILEID, "total", GRIDC, CVTOT)
            CALL RC_FLIP_POTENTIAL(CVTOT, GRIDC, WDES%NCDIJ, .TRUE.)
         END IF
         !
         IF (SHOULD_VASPOUT_HAVE_XC_POT(IO%WRT_POTENTIAL)) THEN
            CALL POTXC(KINEDEN, GRIDC, GRID_SOFT, SOFT_TO_C, INFO, XC_DATA, WDES, &
               LATT_CUR, CHDEN, CHTOT, DENCOR, CVTOT, HAMILTONIAN%MUTOT, 0, DUMMY, 1)
            DO SPIN = 1, SIZE(CVTOT, 2)
               CALL SETUNB_COMPAT(CVTOT(:,SPIN), GRIDC)
               CALL FFT3D(CVTOT(:,SPIN), GRIDC, 1)
            END DO
            CALL VH5_WRITE_POTENTIAL(IH5OUTFILEID, "xc", GRIDC, CVTOT)
         END IF
         !
         IF (SHOULD_VASPOUT_HAVE_HARTREE_POT(IO%WRT_POTENTIAL)) THEN
            ALLOCATE(CHARGE, SOURCE=CHTOT(:,1))
            CALL FFT3D(CHARGE, GRIDC, 1)
            CALL FFT_RC_SCALE(CHARGE, CHARGE, GRIDC)
            CALL SETUNB_COMPAT(CHARGE, GRIDC)
            CALL POTHAR(GRIDC, LATT_CUR, CHARGE, CVTOT, DUMMY(1))
            CALL SETUNB_COMPAT(CVTOT(:,1), GRIDC)
            CALL FFT3D(CVTOT(:,1), GRIDC, 1)
            CALL VH5_WRITE_POTENTIAL(IH5OUTFILEID, "hartree", GRIDC, CVTOT(:,1:1))
         END IF
         !
         IF (SHOULD_VASPOUT_HAVE_IONIC_POT(IO%WRT_POTENTIAL)) THEN
            ALLOCATE(WORK(MAX(GRIDC%MPLWV,GRID_SOFT%MPLWV)))
            CALL POTION(GRIDC, P, LATT_CUR, T_INFO, CVTOT, WORK, CSTRF, DUMMY(1))
            CALL SETUNB_COMPAT(CVTOT(:,1), GRIDC)
            CALL FFT3D(CVTOT(:,1), GRIDC, 1)
            CALL VH5_WRITE_POTENTIAL(IH5OUTFILEID, "ionic", GRIDC, CVTOT(:,1:1))
         END IF
#endif
      END SUBROUTINE OUTPOT_TO_VASPOUT


      !> small routine to write the potential in POT format
      SUBROUTINE OUTPOT_TO_POT(FILENAME, WRITE_PAW)
         USE main_mpi, ONLY: DIR_APP, DIR_LEN
         USE pawm, ONLY: SET_RHO_PAW, WRT_RHO_PAW
         IMPLICIT NONE
         CHARACTER(LEN=*), INTENT(IN) :: FILENAME
         LOGICAL, INTENT(IN) :: WRITE_PAW
         REAL(q) DLM_EXX(N_MIX_PAW,WDES%NCDIJ)
         INTEGER :: ISP, I, NODE_ME, IONODE

         NODE_ME = WDES%COMM%NODE_ME
         IONODE = WDES%COMM%IONODE

         ! the potential is complex for noncollinear calculations unless represented
         ! in terms of the Pauli matrices
         IF (WDES%NCDIJ == 4) &
            CALL RC_FLIP_POTENTIAL(CVTOT, GRIDC, WDES%NCDIJ, .FALSE.)

         io_begin

         IF (IO%LOPEN) OPEN(IO%IUVTOT,FILE=DIR_APP(1:DIR_LEN) // FILENAME,STATUS='UNKNOWN')
         REWIND IO%IUVTOT
         ! write lattice parameters and positions to specified unit
         CALL OUTPOS(IO%IUVTOT,.FALSE.,INFO%SZNAM1,T_INFO,LATT_CUR%SCALE,LATT_CUR%A,.FALSE.,DYN%POSION)
         io_end

         ! at the moment the spin up and down potential is written to the file
         CALL SET_RHO_PAW(WDES, P, T_INFO, INFO%LOVERL, WDES%NCDIJ, LMDIM, &
              CDIJ, DLM_EXX)
         CALL OUTPOT(GRIDC, IO%IUVTOT,.TRUE.,CVTOT(:,1))
         IF (WRITE_PAW) &
            CALL WRT_RHO_PAW(P, T_INFO, INFO%LOVERL, DLM_EXX(:,1), GRIDC%COMM, IO%IUVTOT)

         DO ISP = 2, WDES%NCDIJ
            do_io WRITE( IO%IUVTOT,'(5E20.12)') (T_INFO%ATOMOM(I),I=1,T_INFO%NIONS)
            CALL OUTPOT(GRIDC, IO%IUVTOT,.TRUE.,CVTOT(:,ISP))
            IF (WRITE_PAW) &
               CALL WRT_RHO_PAW(P, T_INFO, INFO%LOVERL, DLM_EXX(:,ISP), GRIDC%COMM, IO%IUVTOT )
         END DO
         io_begin
         CLOSE(IO%IUVTOT)
         io_end

         IF (WDES%NCDIJ == 4) &
            CALL RC_FLIP_POTENTIAL(CVTOT, GRIDC, WDES%NCDIJ, .TRUE.)

      END SUBROUTINE OUTPOT_TO_POT

      END SUBROUTINE WRITE_POTENTIAL

      FUNCTION WRT_POTENTIAL_TO_STRING(WRT_POTENTIAL) RESULT (RES)
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         CHARACTER(LEN=:), ALLOCATABLE :: RES
         !
         IF (SHOULD_VASPOUT_HAVE_TOTAL_POT(WRT_POTENTIAL)) THEN
            RES = "total"
         ELSE
            RES = ""
         END IF
         IF (SHOULD_VASPOUT_HAVE_HARTREE_POT(WRT_POTENTIAL)) &
            RES = TRIM(RES // " " // "hartree")
         IF (SHOULD_VASPOUT_HAVE_IONIC_POT(WRT_POTENTIAL)) &
            RES = TRIM(RES // " " // "ionic")
         IF (SHOULD_VASPOUT_HAVE_XC_POT(WRT_POTENTIAL)) &
            RES = TRIM(RES // " " // "xc")
         IF (RES == "") &
            RES = "false"
      END FUNCTION WRT_POTENTIAL_TO_STRING

      LOGICAL FUNCTION SHOULD_WRITE_POT(LH5, WRT_POTENTIAL)
         USE chi_glb, ONLY: LOEP
         USE fock_glb, ONLY: EXXOEP
         LOGICAL, INTENT(IN) :: LH5
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_WRITE_POT = .NOT.LH5 .AND. WRT_POTENTIAL%LVTOT .AND. (LOEP .OR. EXXOEP > 0)
      END FUNCTION SHOULD_WRITE_POT

      LOGICAL FUNCTION SHOULD_VASPWAVE_HAVE_POT(LH5, WRT_POTENTIAL)
         USE chi_glb, ONLY: LOEP
         USE fock_glb, ONLY: EXXOEP
         LOGICAL, INTENT(IN) :: LH5
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_VASPWAVE_HAVE_POT = LH5 .AND. WRT_POTENTIAL%LVTOT .AND. (LOEP .OR. EXXOEP > 0)
      END FUNCTION SHOULD_VASPWAVE_HAVE_POT

      LOGICAL FUNCTION SHOULD_WRITE_LOCPOT(WRT_POTENTIAL)
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_WRITE_LOCPOT = WRT_POTENTIAL%TOTAL .OR. WRT_POTENTIAL%LVTOT .OR. WRT_POTENTIAL%LVHAR
      END FUNCTION SHOULD_WRITE_LOCPOT

      LOGICAL FUNCTION SHOULD_VASPOUT_HAVE_TOTAL_POT(WRT_POTENTIAL)
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_VASPOUT_HAVE_TOTAL_POT = WRT_POTENTIAL%TOTAL .OR. WRT_POTENTIAL%LVTOT
      END FUNCTION SHOULD_VASPOUT_HAVE_TOTAL_POT

      LOGICAL FUNCTION SHOULD_VASPOUT_HAVE_HARTREE_POT(WRT_POTENTIAL)
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_VASPOUT_HAVE_HARTREE_POT = WRT_POTENTIAL%HARTREE .OR. WRT_POTENTIAL%LVHAR
      END FUNCTION SHOULD_VASPOUT_HAVE_HARTREE_POT

      LOGICAL FUNCTION SHOULD_VASPOUT_HAVE_IONIC_POT(WRT_POTENTIAL)
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_VASPOUT_HAVE_IONIC_POT = WRT_POTENTIAL%IONIC .OR. WRT_POTENTIAL%LVHAR
      END FUNCTION SHOULD_VASPOUT_HAVE_IONIC_POT

      LOGICAL FUNCTION SHOULD_VASPOUT_HAVE_XC_POT(WRT_POTENTIAL)
         TYPE(WRITE_POT), INTENT(IN) :: WRT_POTENTIAL
         SHOULD_VASPOUT_HAVE_XC_POT = WRT_POTENTIAL%XC
      END FUNCTION SHOULD_VASPOUT_HAVE_XC_POT

      END MODULE

!************************ SUBROUTINE POTHAR ****************************
!
!> This subroutine calculates the hartree potential from the electronic
!> charge density.
!>
!> The correction to the
!> total energy due to overcounting the hartree energy on summing the
!> electronic eigenvalues is also computed (hartree contribution to the
!> total energy = 0.5*sum (vh(g)*rho(-g)). The sum of eigenvalues gives
!> sum (vh(g)*rho(-g)) where vh(g) is the hartree potential at wavevector
!> g and rho(g) is the charge density at wavevector g).
!
!***********************************************************************

      SUBROUTINE POTHAR(GRIDC,LATT_CUR, CHTOT,CVD,DENC)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif
      USE prec
      USE mpimy
      USE mgrid
      USE lattice
      USE constant
      IMPLICIT COMPLEX(q) (C)
      IMPLICIT REAL(q) (A-B,D-H,O-Z)

      TYPE (grid_3d)     GRIDC
      TYPE (latt)        LATT_CUR
      COMPLEX(q) CVD(GRIDC%RC%NP),CHTOT(GRIDC%RC%NP)

      PROFILING_START('pothar')

      DENC=0._q
!=======================================================================
! scale the hartree potential by edeps divided by the volume of the unit
! cell
!=======================================================================
      SCALE=EDEPS/LATT_CUR%OMEGA/TPI**2
!=======================================================================
! calculate the hartree potential on the grid of reciprocal lattice
! vectors and the correction to the total energy
!=======================================================================
!$ACC PARALLEL LOOP COLLAPSE(force:2) PRIVATE(N2,N3,NI,FACTM,GX,GY,GZ,GSQU) &
!$ACC PRESENT(GRIDC,CVD,CHTOT,LATT_CUR) __IF_ASYNC__ DEFAULT(none)
      col: DO NC=1,GRIDC%RC%NCOL
      N2= GRIDC%RC%I2(NC)
      N3= GRIDC%RC%I3(NC)
      row: DO N1=1,GRIDC%RC%NROW

        NI=(NC-1)*GRIDC%RC%NROW+N1
        SETFACT1
        SETFACT

        GX= (GRIDC%LPCTX(N1)*LATT_CUR%B(1,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(1,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(1,3))
        GY= (GRIDC%LPCTX(N1)*LATT_CUR%B(2,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(2,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(2,3))
        GZ= (GRIDC%LPCTX(N1)*LATT_CUR%B(3,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(3,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(3,3))

        GSQU=GX**2+GY**2+GZ**2
!=======================================================================
! since the G=0 coulomb contributions to the hartree, ewald and
! electron-ion energies are individually divergent but together sum to
! zero, set the hartree potential at G=0 to zero.
!=======================================================================
        IF ((GRIDC%LPCTX(N1)==0).AND.(GRIDC%LPCTY(N2)==0).AND.(GRIDC%LPCTZ(N3)==0)) &
     & THEN
          CVD(NI)=(0.0_q,0.0_q)
        ELSE
          CVD(NI)=CHTOT(NI)/GSQU*SCALE
        ENDIF
      ENDDO row
      ENDDO col
      CALL SETUNB(CVD,GRIDC)
!=======================================================================
! calculate the correction to the total energy
!=======================================================================
!$ACC PARALLEL LOOP COLLAPSE(force:2) REDUCTION(+:DENC) PRIVATE(DUM,N2,N3,NI,FACTM) &
!$ACC PRESENT(GRIDC,CVD,CHTOT) __IF_ASYNC__ DEFAULT(none)
      col2: DO NC=1,GRIDC%RC%NCOL
      N2= GRIDC%RC%I2(NC)
      N3= GRIDC%RC%I3(NC)
      row2: DO N1=1,GRIDC%RC%NROW

        NI=(NC-1)*GRIDC%RC%NROW+N1
        SETFACT1
        SETFACT

        DUM=MULFACT CVD(NI)*CONJG(CHTOT(NI))
        DENC=DENC+DUM
      ENDDO row2
      ENDDO col2
      DENC=-DENC/2
      CALLMPI( M_sum_d(GRIDC%COMM,DENC,1))

      PROFILING_STOP('pothar')

      RETURN
      END SUBROUTINE

!************************ SUBROUTINE POTION ****************************
!
!> This subroutine calculates the pseudopotential and its derivatives
!> multiplied by the partial structure-factors
!> on the grid of reciprocal lattice vectors.
!
!***********************************************************************

      SUBROUTINE POTION(GRIDC,P,LATT_CUR,T_INFO,CVPS,CDVPS,CSTRF,PSCENC)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif
      USE prec

      USE mpimy
      USE mgrid
      USE pseudo
      USE lattice
      USE poscar
      USE constant

      IMPLICIT COMPLEX(q) (C)
      IMPLICIT REAL(q) (A-B,D-H,O-Z)

      TYPE (grid_3d)     GRIDC
      TYPE (type_info)   T_INFO
      TYPE (potcar)      P (T_INFO%NTYP)
      TYPE (latt)        LATT_CUR

      COMPLEX(q) CSTRF(GRIDC%MPLWV,T_INFO%NTYP)
      COMPLEX(q) CVPS(GRIDC%RC%NP),CDVPS(GRIDC%RC%NP)

!=======================================================================
! calculate the contribution to the total energy from the non-coulomb
! part of the g=0 component of the pseudopotential and the force on the
! unit cell due to the change in this energy as the size of the cell
! changes
!=======================================================================
      ZVSUM=0
      DO NT=1,T_INFO%NTYP
         ZVSUM=ZVSUM+P(NT)%ZVALF*T_INFO%NITYP(NT)*T_INFO%VCA(NT)
      ENDDO

      PSCENC=0
      DO NT=1,T_INFO%NTYP
         PSCENC=PSCENC+P(NT)%PSCORE*T_INFO%VCA(NT)*T_INFO%NITYP(NT)*(ZVSUM/LATT_CUR%OMEGA)
      ENDDO

!$ACC KERNELS PRESENT(CVPS,CDVPS) __IF_ASYNC__
      CVPS =0
      CDVPS=0
!$ACC END KERNELS
!=======================================================================
! loop over all types of atoms
! multiply structur factor by local pseudopotential
!=======================================================================
      typ: DO NT=1,T_INFO%NTYP

      ARGSC=NPSPTS/P(NT)%PSGMAX
      PSGMA2=P(NT)%PSGMAX-P(NT)%PSGMAX/NPSPTS
      ZZ=  -4*PI*P(NT)%ZVALF*FELECT

!$ACC PARALLEL LOOP COLLAPSE(force:2) PRIVATE(N2,N3,N,GX,GY,GZ,G,I,REM,VPST,DVPST) &
!$ACC&  PRESENT(GRIDC,CVPS,CDVPS,LATT_CUR,P,CSTRF) __IF_ASYNC__ DEFAULT(none)
      col: DO NC=1,GRIDC%RC%NCOL
      N2= GRIDC%RC%I2(NC)
      N3= GRIDC%RC%I3(NC)
      row: DO N1=1,GRIDC%RC%NROW
        N=(NC-1)*GRIDC%RC%NROW+N1
!=======================================================================
! calculate the magnitude of the reciprocal lattice vector
!=======================================================================
        GX= GRIDC%LPCTX(N1)*LATT_CUR%B(1,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(1,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(1,3)
        GY= GRIDC%LPCTX(N1)*LATT_CUR%B(2,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(2,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(2,3)
        GZ= GRIDC%LPCTX(N1)*LATT_CUR%B(3,1)+GRIDC%LPCTY(N2)*LATT_CUR%B(3,2)+GRIDC%LPCTZ(N3)*LATT_CUR%B(3,3)

        G=SQRT(GX**2+GY**2+GZ**2)*2*PI
        IF ( ( (GRIDC%LPCTX(N1)/=0) .OR. (GRIDC%LPCTY(N2)/=0) .OR. &
     &         (GRIDC%LPCTZ(N3)/=0) ) .AND. (G<PSGMA2) ) THEN
!=======================================================================
! convert the magnitude of the reciprocal lattice vector to a position
! in the pseudopotential arrays and interpolate the pseudopotential and
! its derivative
!=======================================================================
        I  =INT(G*ARGSC)+1
        REM=G-P(NT)%PSP(I,1)
        VPST =(P(NT)%PSP(I,2)+REM*(P(NT)%PSP(I,3)+ &
     &                     REM*(P(NT)%PSP(I,4)  +REM*P(NT)%PSP(I,5))))
        DVPST= P(NT)%PSP(I,3)+REM*(P(NT)%PSP(I,4)*2+REM*P(NT)%PSP(I,5)*3)

        CVPS (N)=CVPS (N)+( VPST+ ZZ / G**2)  /LATT_CUR%OMEGA*CSTRF(N,NT)
        CDVPS(N)=CDVPS(N)+( DVPST- 2*ZZ /G**3)/LATT_CUR%OMEGA*CSTRF(N,NT)
        ELSE
        CVPS (N)=0._q
        CDVPS(N)=0._q
        ENDIF

      ENDDO row
      ENDDO col
      ENDDO typ
! set local potential to zero
!      CVPS=0
!      CDVPS=0
      CALL SETUNB(CVPS,GRIDC)
      CALL SETUNB(CDVPS,GRIDC)

      RETURN
      END SUBROUTINE


!************************ SUBROUTINE  MAG_DIRECTION  *******************
!
!> On entry CVTOT must contain the v_xc(up) and v_xc(down).
!>
!> On return CVTOT contains \n
!> Collinear case: \n
!>  CVTOT(:,1) =  (v_xc(up) + v_xc(down))/2 \n
!>  CVTOT(:,2) =  (v_xc(up) - v_xc(down))/2 \n
!> Non collinear case: \n
!>  CVTOT(:,1) =  (v_xc(up) + v_xc(down))/2 \n
!>  CVTOT(:,2) =  hat m_x (v_xc(up) - v_xc(down))/2 \n
!>  CVTOT(:,3) =  hat m_y (v_xc(up) - v_xc(down))/2 \n
!>  CVTOT(:,4) =  hat m_z (v_xc(up) - v_xc(down))/2 \n
!> where hat m is the unit vector of the local magnetization density.
!
!***********************************************************************

#undef strict_compatibility

      SUBROUTINE MAG_DIRECTION(CHTOT, CVTOT, GRID, NCDIJ)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif

      USE prec
      USE mgrid

      IMPLICIT NONE
      TYPE (grid_3d)     GRID
      INTEGER NCDIJ
      
      RGRID CHTOT(DIMREAL(GRID%MPLWV), NCDIJ), &
            CVTOT(DIMREAL(GRID%MPLWV), NCDIJ)
      ! local variables
      INTEGER K
      REAL(q) :: NORM2,DELTAV,V0
      
      IF (NCDIJ==2) THEN
#ifndef strict_compatibility
!$ACC PARALLEL LOOP PRESENT(CVTOT) PRIVATE(V0,DELTAV) __IF_ASYNC__
#else
!$ACC PARALLEL LOOP PRESENT(CVTOT,CHTOT) PRIVATE(V0,DELTAV) __IF_ASYNC__
#endif
         DO K=1,GRID%RL%NP
            V0    =(CVTOT(K,1)+CVTOT(K,2))/2
            DELTAV=(CVTOT(K,1)-CVTOT(K,2))/2
            CVTOT(K,1) = V0
#ifndef strict_compatibility
            CVTOT(K,2) = DELTAV
#else
            CVTOT(K,2) = DELTAV*REAL(CHTOT(K,2),KIND=q) / MAX(ABS(CHTOT(K,2)),1.E-20_q)
#endif
         ENDDO
      ELSE IF (NCDIJ==4) THEN
!$ACC PARALLEL LOOP PRESENT(CVTOT,CHTOT) PRIVATE(V0,DELTAV,NORM2) __IF_ASYNC__
         DO K=1,GRID%RL%NP
            V0    =(CVTOT(K,1)+CVTOT(K,2))/2
            DELTAV=(CVTOT(K,1)-CVTOT(K,2))/2
#ifdef realmode
            NORM2 = MAX(SQRT(ABS(CHTOT(K,2)*CHTOT(K,2)+ CHTOT(K,3)*CHTOT(K,3)+ CHTOT(K,4)*CHTOT(K,4))),1.E-20_q)
#else
            NORM2 = MAX(SQRT(ABS(CHTOT(K,2)*CONJG(CHTOT(K,2))+ &
           &           CHTOT(K,3)*CONJG(CHTOT(K,3)) + CHTOT(K,4)*CONJG(CHTOT(K,4)))),1.E-20_q)
#endif

            CVTOT(K,1) = V0
            CVTOT(K,2) = DELTAV * REAL(CHTOT(K,2),KIND=q) / NORM2
            CVTOT(K,3) = DELTAV * REAL(CHTOT(K,3),KIND=q) / NORM2
            CVTOT(K,4) = DELTAV * REAL(CHTOT(K,4),KIND=q) / NORM2
         ENDDO
         
      ELSE
         CALL vtutor%bug("internal error: MAG_DIRECTION called with NCDIJ= " // str(NCDIJ), __FILE__, __LINE__)
      ENDIF
         
      END SUBROUTINE MAG_DIRECTION


      SUBROUTINE MAG_DIRECTION_KINDENS(CHTOT, TAU, MUTOT, CVTOT, GRID, NCDIJ, LATT_CUR)

#ifdef _OPENACC
      USE mopenacc_struct_def
#endif
      USE prec
      USE constant
      USE lattice
      USE mgrid

      IMPLICIT NONE
      TYPE (grid_3d)     GRID
      TYPE (latt)        LATT_CUR
      INTEGER NCDIJ
      
      RGRID CHTOT(DIMREAL(GRID%MPLWV), NCDIJ), TAU(DIMREAL(GRID%MPLWV), NCDIJ), &
            MUTOT(DIMREAL(GRID%MPLWV), NCDIJ), CVTOT(DIMREAL(GRID%MPLWV), NCDIJ)
      ! local variables
      INTEGER K
      REAL(q) :: NORM2,DELTAV,V0,TAUPROJ,FACT
!#define debug3
#ifdef debug3
      COMPLEX(q) E,dX1,dY1,dZ1,dX2,dY2,dZ2,dX3,dY3,dZ3
      E=0; dX1=0; dY1=0; dZ1=0; dX2=0; dY2=0; dZ2=0; dX3=0; dY3=0; dZ3=0
#endif
      
      IF (NCDIJ==2) THEN
         ! local potential
#ifndef strict_compatibility
!$ACC PARALLEL PRESENT(GRID,CVTOT,MUTOT) __IF_ASYNC__
#else
!$ACC PARALLEL PRESENT(GRID,CVTOT,CHTOT,MUTOT) __IF_ASYNC__
#endif
!$ACC LOOP GANG VECTOR PRIVATE(V0,DELTAV)
         DO K=1,GRID%RL%NP
            V0    =(CVTOT(K,1)+CVTOT(K,2))/2
            DELTAV=(CVTOT(K,1)-CVTOT(K,2))/2
            CVTOT(K,1) = V0
#ifndef strict_compatibility
            CVTOT(K,2) = DELTAV
#else
            CVTOT(K,2) = DELTAV*REAL(CHTOT(K,2),KIND=q) / MAX(ABS(CHTOT(K,2)),1.E-20_q)
#endif
         ENDDO
         ! \mu = dE_xc / d\tau
!$ACC LOOP GANG VECTOR PRIVATE(V0,DELTAV)
         DO K=1,GRID%RL%NP
            V0    =(MUTOT(K,1)+MUTOT(K,2))/2
            DELTAV=(MUTOT(K,1)-MUTOT(K,2))/2
            MUTOT(K,1) = V0
#ifndef strict_compatibility
            MUTOT(K,2) = DELTAV
#else
            MUTOT(K,2) = DELTAV*REAL(CHTOT(K,2),KIND=q) / MAX(ABS(CHTOT(K,2)),1.E-20_q)
#endif
         ENDDO
!$ACC END PARALLEL
      ELSE IF (NCDIJ==4) THEN
         ! local potential and \mu = dE_xc / d\tau
!$ACC PARALLEL PRESENT(GRID,CVTOT,CHTOT,MUTOT,TAU) __IF_ASYNC__
!$ACC LOOP GANG VECTOR PRIVATE(V0,DELTAV,NORM2)
         DO K=1,GRID%RL%NP
            V0    =REAL((CVTOT(K,1)+CVTOT(K,2))/2,KIND=q)
            DELTAV=REAL((CVTOT(K,1)-CVTOT(K,2))/2,KIND=q)
#ifdef realmode
            NORM2 = MAX(SQRT(ABS(CHTOT(K,2)*CHTOT(K,2)+ CHTOT(K,3)*CHTOT(K,3)+ CHTOT(K,4)*CHTOT(K,4))),1.E-20_q)
#else
!           NORM2 = MAX(SQRT(ABS(CHTOT(K,2)*CONJG(CHTOT(K,2))+ &
!          &           CHTOT(K,3)*CONJG(CHTOT(K,3)) + CHTOT(K,4)*CONJG(CHTOT(K,4)))),1.E-20_q)
            NORM2 = MAX(SQRT(ABS(REAL(CHTOT(K,2))*REAL(CHTOT(K,2))+ &
          &           REAL(CHTOT(K,3))*REAL(CHTOT(K,3))+REAL(CHTOT(K,4))*REAL(CHTOT(K,4)))),1.E-20_q)
#endif

            CVTOT(K,1) = V0
            CVTOT(K,2) = DELTAV * REAL(CHTOT(K,2),KIND=q) / NORM2
            CVTOT(K,3) = DELTAV * REAL(CHTOT(K,3),KIND=q) / NORM2
            CVTOT(K,4) = DELTAV * REAL(CHTOT(K,4),KIND=q) / NORM2
         ENDDO
         ! \mu = dE_xc / d\tau
!$ACC LOOP GANG VECTOR PRIVATE(V0,DELTAV,NORM2,TAUPROJ,FACT)
         DO K=1,GRID%RL%NP
            V0    =REAL((MUTOT(K,1)+MUTOT(K,2))/2,KIND=q)
            DELTAV=REAL((MUTOT(K,1)-MUTOT(K,2))/2,KIND=q)
#ifdef realmode
            NORM2 = MAX(SQRT(ABS(CHTOT(K,2)*CHTOT(K,2)+ CHTOT(K,3)*CHTOT(K,3)+ CHTOT(K,4)*CHTOT(K,4))),1.E-20_q)
#else
!           NORM2 = MAX(SQRT(ABS(CHTOT(K,2)*CONJG(CHTOT(K,2))+ &
!          &           CHTOT(K,3)*CONJG(CHTOT(K,3)) + CHTOT(K,4)*CONJG(CHTOT(K,4)))),1.E-20_q)
            NORM2 = MAX(SQRT(ABS(REAL(CHTOT(K,2))*REAL(CHTOT(K,2))+ &
           &           REAL(CHTOT(K,3))*REAL(CHTOT(K,3))+REAL(CHTOT(K,4))*REAL(CHTOT(K,4)))),1.E-20_q)
#endif

            MUTOT(K,1) = V0
            MUTOT(K,2) = DELTAV * REAL(CHTOT(K,2),KIND=q) / NORM2
            MUTOT(K,3) = DELTAV * REAL(CHTOT(K,3),KIND=q) / NORM2
            MUTOT(K,4) = DELTAV * REAL(CHTOT(K,4),KIND=q) / NORM2

#ifdef realmode
            TAUPROJ = (TAU(K,2)*CHTOT(K,2)+TAU(K,3)*CHTOT(K,3)+TAU(K,4)*CHTOT(K,4)) /NORM2/NORM2
#else
            TAUPROJ = (REAL(TAU(K,2),KIND=q)*REAL(CHTOT(K,2),KIND=q)+ &
           &            REAL(TAU(K,3),KIND=q)*REAL(CHTOT(K,3),KIND=q)+ &
           &             REAL(TAU(K,4),KIND=q)*REAL(CHTOT(K,4),KIND=q)) /NORM2/NORM2
#endif

            FACT=1._q/HSQDTM!*2._q
!           FACT=0._q
            IF (NORM2>1E-3_q) THEN
               CVTOT(K,2)=CVTOT(K,2)+DELTAV*REAL(TAU(K,2)-TAUPROJ*CHTOT(K,2),KIND=q)/NORM2*FACT
               CVTOT(K,3)=CVTOT(K,3)+DELTAV*REAL(TAU(K,3)-TAUPROJ*CHTOT(K,3),KIND=q)/NORM2*FACT
               CVTOT(K,4)=CVTOT(K,4)+DELTAV*REAL(TAU(K,4)-TAUPROJ*CHTOT(K,4),KIND=q)/NORM2*FACT
            ENDIF
#ifdef debug3
!           E=E+CVTOT(K,1)*CHTOT(K,1)+CVTOT(K,2)*CHTOT(K,2)*CVTOT(K,3)*CHTOT(K,3)+CVTOT(K,4)*CHTOT(K,4)
!           E=E+(MUTOT(K,1)*TAU(K,1)+MUTOT(K,2)*TAU(K,2)+MUTOT(K,3)*TAU(K,3)+MUTOT(K,4)*TAU(K,4))*LATT_CUR%OMEGA
            E=E+DELTAV*(TAU(K,2)-TAUPROJ*CHTOT(K,2))/NORM2/HSQDTM*LATT_CUR%OMEGA*CHTOT(K,2)+ &
           &    DELTAV*(TAU(K,3)-TAUPROJ*CHTOT(K,3))/NORM2/HSQDTM*LATT_CUR%OMEGA*CHTOT(K,3)+ &
           &    DELTAV*(TAU(K,4)-TAUPROJ*CHTOT(K,4))/NORM2/HSQDTM*LATT_CUR%OMEGA*CHTOT(K,4)

!           dX=dX+DELTAV*(TAU(K,2)-TAUPROJ*REAL(CHTOT(K,2),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
!           dY=dY+DELTAV*(TAU(K,3)-TAUPROJ*REAL(CHTOT(K,3),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
!           dZ=dZ+DELTAV*(TAU(K,4)-TAUPROJ*REAL(CHTOT(K,4),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA

            IF (NORM2>1.E-3_q) THEN

            dX1=dX1+DELTAV*(REAL(CHTOT(K,2),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
            dY1=dY1+DELTAV*(REAL(CHTOT(K,3),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
            dZ1=dZ1+DELTAV*(REAL(CHTOT(K,4),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA

            dX2=dX2+DELTAV*(REAL(TAU(K,2),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
            dY2=dY2+DELTAV*(REAL(TAU(K,3),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
            dZ2=dZ2+DELTAV*(REAL(TAU(K,4),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA

            dX3=dX3+DELTAV*(TAUPROJ*REAL(CHTOT(K,2),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
            dY3=dY3+DELTAV*(TAUPROJ*REAL(CHTOT(K,3),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA
            dZ3=dZ3+DELTAV*(TAUPROJ*REAL(CHTOT(K,4),KIND=q))/NORM2/HSQDTM*LATT_CUR%OMEGA

            ENDIF
#endif
         ENDDO
!$ACC END PARALLEL
#ifdef debug3
!        WRITE(*,'(A,2F14.7)') 'V(r)*rho(r)=',E/GRID%NPLWV
         WRITE(*,'(A,2F14.7)') 'mu*tau=',E/GRID%NPLWV
         WRITE(*,'(3(A,2F14.7))') 'dX1=',dX1/GRID%NPLWV,' dY1=',dY1/GRID%NPLWV,' dZ1=',dZ1/GRID%NPLWV
         WRITE(*,'(3(A,2F14.7))') 'dX2=',dX2/GRID%NPLWV,' dY2=',dY2/GRID%NPLWV,' dZ2=',dZ2/GRID%NPLWV
         WRITE(*,'(3(A,2F14.7))') 'dX3=',dX3/GRID%NPLWV,' dY3=',dY3/GRID%NPLWV,' dZ3=',dZ3/GRID%NPLWV
#endif
      ELSE
         CALL vtutor%bug("internal error: MAG_DIRECTION called with NCDIJ= " // str(NCDIJ), __FILE__, __LINE__)
      ENDIF
 
      END SUBROUTINE MAG_DIRECTION_KINDENS


!************************ SUBROUTINE MAG_DENSITY ***********************
!
!> This subroutine calculates the total charge density and the 
!> absolute magnitude of the magnetization density.
!>
!> On entry: \n 
!>  CHTOT  rho, m_x, m_y, m_z \n
!> On exit: \n
!>  CWORK  rho, sqrt(m_x^2 + m_y^2 + m_z^2) \n
!> in the collinear case, it this means a simple copy CHTOT to CWORK.
!
!***********************************************************************

      SUBROUTINE MAG_DENSITY(CHTOT, CWORK, GRID, NCDIJ)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif

      USE prec
      USE mgrid

      IMPLICIT NONE
      TYPE (grid_3d)     GRID
      INTEGER NCDIJ
      
      RGRID CHTOT(DIMREAL(GRID%MPLWV), NCDIJ), &
            CWORK(DIMREAL(GRID%MPLWV), NCDIJ)
      ! local
      INTEGER K

      
      IF (NCDIJ==2) THEN
!$ACC PARALLEL LOOP PRESENT(CWORK,CHTOT) __IF_ASYNC__
         DO K=1,GRID%RL%NP
            CWORK(K,1)=CHTOT(K,1)
#ifndef strict_compatibility
            CWORK(K,2)=CHTOT(K,2)
#else
            CWORK(K,2)=ABS(CHTOT(K,2))
#endif
         ENDDO
      ELSE IF (NCDIJ==4) THEN
!$ACC PARALLEL LOOP PRESENT(CWORK,CHTOT) __IF_ASYNC__
         DO K=1,GRID%RL%NP
            CWORK(K,1)=CHTOT(K,1)
            CWORK(K,2)=SQRT(ABS(CHTOT(K,2)*CHTOT(K,2)+ CHTOT(K,3)*CHTOT(K,3) + CHTOT(K,4)*CHTOT(K,4)))
         ENDDO
      ELSE
         CALL vtutor%bug("internal error: MAG_DENSITY called with NCDIJ= " // str(NCDIJ), __FILE__, __LINE__)
      ENDIF
      END SUBROUTINE MAG_DENSITY


!************************ SUBROUTINE POT_FLIP **************************
!
!> Rearranges the storage mode for spin components of potentials.
!>
!> for the collinear case calculate: \n
!>  v0 1 + v_z \n
!>  v0 1 - v_z \n
!> for the non collinear case calculate \n
!>  v  = v0 1 + sigma_x v_x + simga_y v_y + sigma_z v_z
! 
!***********************************************************************

      SUBROUTINE POT_FLIP(CVTOT, GRID, NCDIJ)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif
      USE prec
      USE mgrid
      IMPLICIT NONE
      INTEGER NCDIJ
      TYPE (grid_3d)     GRID
      COMPLEX(q) :: CVTOT(GRID%MPLWV, NCDIJ)

      ! local
      COMPLEX(q) :: C00,CX,CY,CZ
      REAL(q) :: FAC
      INTEGER K
      
      IF (NCDIJ==2) THEN
         FAC=1.0_q
!$ACC PARALLEL LOOP PRESENT(CVTOT) PRIVATE(C00,CZ) __IF_ASYNC__
         DO K=1,GRID%RC%NP
            C00=CVTOT(K,1)
            CZ =CVTOT(K,2)

            CVTOT(K,1)= (C00+CZ)*FAC           
            CVTOT(K,2)= (C00-CZ)*FAC           
         ENDDO
      ELSE IF (NCDIJ==4) THEN
         FAC=1.0_q
!$ACC PARALLEL LOOP PRESENT(CVTOT) PRIVATE(C00,CX,CY,CZ) __IF_ASYNC__
         DO K=1,GRID%RC%NP
            C00=CVTOT(K,1)
            CX =CVTOT(K,2)
            CY =CVTOT(K,3)
            CZ =CVTOT(K,4)

            CVTOT(K,1)= (C00+CZ)*FAC           
            CVTOT(K,2)= (CX-CY*(0._q,1._q))*FAC
            CVTOT(K,3)= (CX+CY*(0._q,1._q))*FAC
            CVTOT(K,4)= (C00-CZ)*FAC           
         ENDDO
      ELSE IF (NCDIJ==1) THEN
      ENDIF

    END SUBROUTINE POT_FLIP

    SUBROUTINE POT_FLIP_RL(CVTOT, GRID, NCDIJ)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif
      USE prec
      USE mgrid
      IMPLICIT NONE
      INTEGER NCDIJ
      TYPE (grid_3d)     GRID
      
      RGRID CVTOT(DIMREAL(GRID%MPLWV), NCDIJ)
      ! local
      COMPLEX(q) :: C00,CX,CY,CZ
      REAL(q) :: FAC
      INTEGER K

      IF (NCDIJ==2) THEN
         FAC=1.0_q
!$ACC PARALLEL LOOP PRESENT(CVTOT) PRIVATE(C00,CZ) __IF_ASYNC__
         DO K=1,GRID%RL%NP
            C00=CVTOT(K,1)
            CZ =CVTOT(K,2)

            CVTOT(K,1)= (C00+CZ)*FAC
            CVTOT(K,2)= (C00-CZ)*FAC
         ENDDO
      ELSE IF (NCDIJ==4) THEN
         FAC=1.0_q
!$ACC PARALLEL LOOP PRESENT(CVTOT) PRIVATE(C00,CX,CY,CZ) __IF_ASYNC__
         DO K=1,GRID%RL%NP
            C00=CVTOT(K,1)
            CX =CVTOT(K,2)
            CY =CVTOT(K,3)
            CZ =CVTOT(K,4)

            CVTOT(K,1)= (C00+CZ)*FAC
            CVTOT(K,2)= (CX-CY*(0._q,1._q))*FAC
            CVTOT(K,3)= (CX+CY*(0._q,1._q))*FAC
            CVTOT(K,4)= (C00-CZ)*FAC
         ENDDO
      ELSE IF (NCDIJ==1) THEN
      ENDIF

    END SUBROUTINE POT_FLIP_RL


!************************ SUBROUTINE EXTERNAL_POT **********************
!
!> This subroutine can be used to add an external potential.
!>
!> The units of the potential are eV.
!
!***********************************************************************

      SUBROUTINE EXTERNAL_POT(GRIDC, LATT_CUR, CVTOT)
#ifdef _OPENACC
      USE mopenacc_struct_def
#endif

      USE prec
      USE base
      USE lattice
      USE mpimy
      USE mgrid
      USE poscar
      USE constant

      IMPLICIT COMPLEX(q) (C)
      IMPLICIT REAL(q) (A-B,D-H,O-Z)

      TYPE (grid_3d)     GRIDC
      TYPE (latt)        LATT_CUR
      RGRID      CVTOT(DIMREAL(GRIDC%MPLWV))

      RETURN

      IF (GRIDC%RL%NFAST==3) THEN
         ! mpi version: x-> N2, y-> N3, z-> N1
         N2MAX=GRIDC%NGX
         N3MAX=GRIDC%NGY
         N1MAX=GRIDC%NGZ

!$ACC PARALLEL LOOP COLLAPSE(force:2) PRIVATE(N2,N3,NG) &
!$ACC& PRESENT(GRIDC,CVTOT) __IF_ASYNC__ DEFAULT(none)
         DO NC=1,GRIDC%RL%NCOL
            N2= GRIDC%RL%I2(NC)
            N3= GRIDC%RL%I3(NC)
            DO N1=1,GRIDC%RL%NROW
               NG=(NC-1)*GRIDC%RL%NROW+N1
               CVTOT(NG)=CVTOT(NG)
               IF (N1<=GRIDC%NGZ/2) THEN
                  CVTOT(NG)=CVTOT(NG)+(REAL(N1,q)-1)/GRIDC%NGZ*2*0.1
               ELSE
                  CVTOT(NG)=CVTOT(NG)+(GRIDC%NGZ-REAL(N1,q))/GRIDC%NGZ*2*0.1
               ENDIF
            ENDDO
         ENDDO
      ELSE
         ! conventional version: x-> N1, y-> N2, z-> N3
         N1MAX=GRIDC%NGX
         N2MAX=GRIDC%NGY
         N3MAX=GRIDC%NGZ

!$ACC PARALLEL LOOP COLLAPSE(force:2) PRIVATE(N2,N3,NG) &
!$ACC& PRESENT(GRIDC,CVTOT) __IF_ASYNC__ DEFAULT(none)
         DO NC=1,GRIDC%RL%NCOL
            N2= GRIDC%RL%I2(NC)
            N3= GRIDC%RL%I3(NC)
            DO N1=1,GRIDC%RL%NROW
               NG=(NC-1)*GRIDC%RL%NROW+N1
               CVTOT(NG)=CVTOT(NG)
               IF (N3<=GRIDC%NGZ/2) THEN
                  CVTOT(NG)=CVTOT(NG)+(REAL(N3,q)-1)/GRIDC%NGZ*2*0.1
               ELSE
                  CVTOT(NG)=CVTOT(NG)+(GRIDC%NGZ-REAL(N3,q))/GRIDC%NGZ*2*0.1
               ENDIF
            ENDDO
         ENDDO
      ENDIF

      END SUBROUTINE
