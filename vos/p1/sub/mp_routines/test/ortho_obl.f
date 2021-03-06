      SUBROUTINE ORTHO_OBL(IND,M,DATA,LINE,SAMPLE,LAT,LONG)

C  CONVERT L,S TO LAT LONG OR LAT,LONG TO L,S FOR THE ORTHOGRAPHIC
C  PROJECTION FOR AN OBLATE SPHEROID

C  11SEP96 -LWK-  CODE ADAPTED FROM SUBR. TRANV, FOR USE BY MP_ROUTINES
c  23Oct97 -Scholten- added check for THR near 90 deg. 

C  IND  0=O.K.  1=POINT OFF PLANET
C  M  1=DIRECT  2=INVERSE

C DATA
C  1    XC  SPECIAL SAMPLE POINT
C  2    ZC  SPECIAL LINE POINT
C  3    TH  SPECIAL LATITUDE
C  4    TH1  LATITUDE OF SPECIAL PARALLEL OR SPECIAL OBLIQUE LONGITUDE
C  5    TH2  LATITUDE OF SPECIAL PARALLEL
C  6    LAM SPECIAL LONGITUDE    WEST
C  7    F  SCALE  (KM/PIXEL)
C  8    CAS  +1 IF VISIBLE POLE IS N.   -1 IF VISIBLE POLE IS S.
C       M  M=2  LINE,SAMPLE TO LAT,LONG   (INVERSE)
C       M  M=1  LAT,LONG TO LINE,SAMP  (DIRECT)
C  25   RP  POLAR RADIUS  (KM)
C  26   RE  EQUATORIAL RADIUS  (KM)
C  9    PSI   NORTH ANGLE
C
C  ******  ANGLES IN DATA() IN DEGREES  ******
C  ******  LAT,LONG IN RADIANS          ******
C  ******  ALL LATITUDES PLANETOCENTRIC ******
C  ******  ALL LONGITUDES WEST          ******

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DOUBLE PRECISION LAM,LAMR,LATR,LONGR
      DOUBLE PRECISION K1,K2,K3,K3SQRT,DIF1(3),DIF2(3),LAMBAR,NORTH,L
      DOUBLE PRECISION LAT8,LONG8
      REAL DATA(40),LINE,SAMPLE,LAT,LONG
      DATA SMALL/1D-8/

C  SPECIAL FUNCTIONS DEFINED

C  GEOCENTRIC RADIUS
      GCR(RPP,REP,THR)=RPP*REP/DSQRT(RPP*RPP*DCOS(THR)**2+
     *   REP*REP*DSIN(THR)**2)

C  GEODETIC LATITUDE
      PHIG(PI,RPP,REP,THR)=PI/2.D0-DABS(DATAN(-RPP*RPP/(REP*REP)*
     *1.D0/DTAN(THR)))

      PI=3.141592653589793D0
      PI2=2.0D0*PI
      D2R=pi/180.d0
      IND=0

C  CONVERT ANGLES AND DIMENSIONS TO RADIANS AND PIXELS RESPECTIVELY
C  AND R*4 DATA ITEMS TO R*8

      XC=DATA(1)
      ZC=DATA(2)
      TH=DATA(3)
      THR=TH*D2R
      IF(THR.EQ.0.D0)THR=SMALL		! in case Center_lat=0 
      THR0=THR
      LAM=DATA(6)
      LAMR=LAM*D2R
      F=DATA(7)
      PSI=DATA(9)
      PSIR=PSI*D2R
      RP=DATA(25)
      RPP=RP/F
      RE=DATA(26)
      REP=RE/F
      IF (M.NE.2) THEN
	LAT8=LAT
	LONG8=LONG
	LATR=LAT8
C	IF(LATR.EQ.0.D0)LATR=0.0000001d0	! ?? (LWK)
	LONGR=LONG8
      ENDIF

      IF(M.EQ.2) GO TO 100

C  DIRECT
      R=GCR(RPP,REP,LATR)
      PHI=PHIG(PI,RPP,REP,THR)
      PHI=DSIGN(PHI,THR)
      X11=-R*DCOS(LATR)*DSIN(LONGR-LAMR)
      Z11=R*(DSIN(PHI)*DCOS(LATR)*DCOS(LONGR-LAMR)
     *-DCOS(PHI)*DSIN(LATR))
      X1=X11
      Z1=Z11-GCR(RPP,REP,THR)*DSIN(PHI-THR)
      SAMPLE=X1*DCOS(PSIR)-Z1*DSIN(PSIR)+XC
      LINE=X1*DSIN(PSIR)+Z1*DCOS(PSIR)+ZC

C  BACK-OF-PLANET TEST
C  29-SEP-1985 JAM LIFTED FROM LUMLLP
      C1=COS(THR)
      C2=COS(PI2-LAMR)
      C3=SIN(THR)
      C4=SIN(PI2-LAMR)
      CA=COS(LATR)
      CO=COS(PI2-LONGR)
      SA=SIN(LATR)
      SO=SIN(PI2-LONGR)
      CE=CA*CO*C1*C2+CA*SO*C1*C4+SA*C3	! COSINE EMISSION ANGLE
C  RETURNS .TRUE. IF POINT LAT,LON IS ON BACK OF PLANET W.R.T. TH,LAM
      IF(CE.LT.0.)IND=1
      RETURN

100   CONTINUE
C  INVERSE
      RLAT=SAMPLE-XC
      RLON=LINE-ZC
      IF(RLAT.NE.0.0.OR.RLON.NE.0.0) GO TO 220
      LAT=THR
      LONG=LAMR
      RETURN
220   CONTINUE
      CPHI=TH
      CPSI=LAM
      NORTH=PSI
      if (dabs(thr).gt.((90.d0-SMALL)*d2r))
     & thr=dsign((90.d0-SMALL)*d2r,thr)
      SINLAT=DSIN(THR)
      COSLAT=DCOS(THR)
      SINLON=DSIN(LAMR)
      COSLON=DCOS(LAMR)
      SINNOR=DSIN(PSIR)
      COSNOR=DCOS(PSIR)
      FL=RP
      REQ=RE
      SLCCPC=SINLAT*COSLON
      SLCSPC=SINLAT*SINLON
      SCPCSL=SINLON*COSLON*SINLAT
      SCPCCL=SINLON*COSLON*COSLAT
      CLCC2P=COSLAT*COSLON*COSLON
      CLCS2P=COSLAT*SINLON*SINLON
      SLCC2P=SINLAT*COSLON*COSLON

C     CALC ANGLE LAMBDA BAR
      RPSQ=FL
      RPSQ=RPSQ*RPSQ
      RESQ=REQ
      RESQ=RESQ*RESQ
      LAMBAR=((COSLAT*COSLAT/RESQ+SINLAT*SINLAT/RPSQ)/
     &DSQRT((COSLAT*COSLAT/(RESQ*RESQ)+SINLAT*SINLAT/(RPSQ*RPSQ))))
      IF(LAMBAR.gt.1.D0)LAMBAR=1.D0
      LAMBAR=DACOS(LAMBAR)
      LAMBAR=((CPHI))*D2R+LAMBAR
      SINLAM=DSIN(LAMBAR)
      COSLAM=DCOS(LAMBAR)
      L=(CPHI)*D2R-LAMBAR
      SINL=DSIN(L)
      COSL=DCOS(L)

C     GET RADIUS OF PLANET AT C.P.
      RCP= GCR(RPP,REP,THR)

C     CONVERT FROM PIXELS TO KM
      RCP=F*RCP

C     CALC.ANGLE BETWEEN UP AND POINT OF INTEREST
C     IN PLANE OF PROJECTION SUBTENDED AT CENTER OF PROJECTION
      DELX=RLAT
      XDEL=DELX
      DELZ=RLON
      ZDEL=DELZ
      APOIUP=DATAN2(-XDEL,-ZDEL)

C     CALC.SIN AND COS OF THE ANGLE BETWEEN THE DIRECTION OF
C     NORTH IN THE IMAGE PLANE AND THE POINT OF INTEREST SUBTENDED AT
C     THE CENTER OF PROJECTION
      ADEL=((NORTH)*D2R)+APOIUP
      SINDEL=DSIN(ADEL)
      COSDEL=DCOS(ADEL)
      IF(SINDEL.EQ.1.0D0)COSDEL=0.0D0
      IF(SINDEL.EQ.-1.0D0)COSDEL=0.0D0

C     CALC.DISTANCE OF POINT OF INTEREST FROM
C     CENTER OF PROJECTION IN PLANE OF PROJECTION
C     AT TRUE SCALE
      DD=(F)*DSQRT((XDEL*XDEL)+(ZDEL*ZDEL))

C     CHECK WHETHER POINT OF INTEREST IS OFF PLANET
      IF(REQ.LT.DD) GO TO 999

C     CALC.COEFFIEIENTS FOR TWO PLANES NORMAL
C     TO PLANE OF PROJECTION.

C     PLANE 1 - NORMAL TO LINE CONNECTION CENTER OF PROJECTION
C     AND POINT OF INTEREST
C     PLANE 2 - CONTAINS LINE CONNECTION CENTER OF
C     PROJECTION AND POINT OF INTEREST

C     PLANE 1 A1*X+B1*Y+C1*Z+D1=0
C     PLANE 2 A2*X+B2*Y+C2*Z=0

      A1=-SINDEL*SINLON-COSDEL*COSLON*SINLAM
      B1=-SINDEL*COSLON+COSDEL*SINLON*SINLAM
      C1=COSDEL*COSLAM
      D1=-DD*SINDEL*SINDEL+RCP*COSDEL*SINLAM*COSLAT
     &-RCP*SINLAT*COSLAM*COSDEL-DD*COSDEL*COSDEL*SLCC2P*SINLAM
     &-DD*COSDEL*COSDEL*COSLAM*COSLAM
     &-DD*SINLAM*SINLAM*COSDEL*COSDEL*SINLON*SINLON
      A2=-COSDEL*SINLON*COSL+SINDEL*SLCCPC
      B2=-COSDEL*COSLON*COSL-SINDEL*SLCSPC
      C2=-COSLAT*SINDEL

C     CALCULATE PARAMETRIC VARIABLES IN
C     SIMULTANEOUS SOLN.OF PLANE 1,PLANE 2,AND SPHEROID

      ALPHA=A2*C1-A1*C2
      BETA=A2*B1-A1*B2
      GAMMA=B1*C2-B2*C1
      DELTA=C1*B2-B1*C2

C     CALCULATE X COORDINATE

C     EQUATION IS X=K1+OR-K2*SQRT(K3)

      ALPHSQ=ALPHA*ALPHA
      BETASQ=BETA*BETA
      GAMMSQ=GAMMA*GAMMA
      DELTSQ=DELTA*DELTA
      D1SQ=D1*D1
      C2SQ=C2*C2
      B2SQ=B2*B2
      GRESQ=GAMMSQ*RESQ
      DRPSQ=DELTSQ*RPSQ
      Z1=DRPSQ*(ALPHSQ+GAMMSQ)+BETASQ*GRESQ
      K1=((ALPHA*C2*D1*DRPSQ)+(BETA*B2*D1*GRESQ))/Z1
      K2=(GAMMA*DELTA*FL)/Z1
      K3=2.D0*ALPHA*C2*BETA*B2*RESQ
      K3=K3+(-C2SQ*DRPSQ-B2SQ*GRESQ-ALPHSQ*B2SQ*RESQ-BETASQ*RESQ*C2SQ)
      K3=K3*D1SQ
      K3=K3+(GRESQ*DRPSQ+DRPSQ*RESQ*ALPHSQ+RESQ*BETASQ*GRESQ)
      IF(K3.LT.0.D0) GO TO 999
      K3SQRT=DSQRT(K3)
      Z1=K2*K3SQRT
      X1=K1+Z1
      X2=K1-Z1

C     MAKE THE BACK OF PLANET TEST

      Y1=-D1*C2
      Y2=Y1
      Y1=(Y1+ALPHA*X1)/GAMMA
      Y2=(Y2+ALPHA*X2)/GAMMA
      Z1=(-B2*D1+BETA*X1)/DELTA
      Z2=(-B2*D1+BETA*X2)/DELTA

C     (X1,Y1,Z1) IS VECTOR P01
C     (X2,Y2,Z2) IS VECTOR P02
C     PCP IS VECTOR FROM PLANET CENTER TO CENTER OF PROJECTION
C     FIND WHICH VECTOR HAS MINIMUM LENGTH, P01-PCP  OR  P02-PCP

      PCPX=RCP*COSLAT*COSLON
      PCPY=-RCP*COSLAT*SINLON
      PCPZ=RCP*SINLAT
      DIF1(1)=X1-PCPX
      DIF1(2)=Y1-PCPY
      DIF1(3)=Z1-PCPZ
      DIF2(1)=X2-PCPX
      DIF2(2)=Y2-PCPY
      DIF2(3)=Z2-PCPZ
      RAD1=DIF1(1)*DIF1(1)+DIF1(2)*DIF1(2)+DIF1(3)*DIF1(3)
      RAD2=DIF2(1)*DIF2(1)+DIF2(2)*DIF2(2)+DIF2(3)*DIF2(3)
      IF(RAD1.GT.RAD2) GO TO 210
C     POINT 1 IS VALID
      RLON=PI2-DATAN2(Y1,X1)
      RLON=DMOD(RLON+PI2,PI2)
      RLAT=(DATAN(DABS(Z1)/DSQRT(X1*X1+Y1*Y1)))
      RLAT=DSIGN(RLAT,Z1)
      LAT=RLAT
      LONG=RLON
      RETURN
C     POINT 2 IS VALID
210   RLON=PI2-DATAN2(Y2,X2)
      RLON=DMOD(RLON+PI2,PI2)
      RLAT=(DATAN(DABS(Z2)/DSQRT(X2*X2+Y2*Y2)))
      RLAT=DSIGN(RLAT,Z2)
      LAT=RLAT
      LONG=RLON
      RETURN
999   CONTINUE
      IND=1
      RETURN

      END
