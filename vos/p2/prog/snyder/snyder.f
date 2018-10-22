c
c program auxiliary
c
      include 'VICMAIN_FOR'
      subroutine main44

      parameter (maxsamp=3600)
      parameter (max_nlimit=15, max_mlimit=15, max_klimit=15)
      real*4 obuf(maxsamp,4)
      real*4 lat,lon,line,sample
      integer*4 ounit(4),def,count,status
      logical xvptst,conformal,authalic
      character*100 archive
      character*12 planet
      real*8 a,b,c,inlat,inlon,outlat,outlon
      real*8 confcoef1(max_nlimit*max_mlimit)
      real*8 confcoef2(max_nlimit*max_mlimit)
      real*8 authcoef1((max_mlimit+1)*(max_klimit+1))
      real*8 authcoef2(max_nlimit)
 
      CALL XVMESSAGE('snyder version 2017-08-11',' ')

c parameters
      call xvpcnt('INP',nids)      
      conformal=xvptst('CONFORMAL')
      authalic=xvptst('AUTHALIC')
      call xvparm('NL',nlo,count,def,1)
      call xvparm('NS',nso,count,def,1)
      call xvparm('ARCHIVE',archive,count,def,1)
      call xvparm('PATH',path,count,def,1)
      call xvparm('PLANET',planet,count,def,1)

c read coefficient file generated by TRICOEF for converting from
c conformal & authalic to centric coordinates
      call xvmessage('Reading TRICOEF archive '//archive,' ')
      call get_ellipsoid(archive,planet,a,b,c,
     +       confcoef1,confcoef2,authcoef1,authcoef2,
     +       nlimit,klimit,mlimit,ind)
      if(ind.ne.0)then
        call xvmessage('get_ellipsoid: error status',' ')
        call abend
      endif
      if(nlimit.gt.max_nlimit)then
        call xvmessage('get_ellipsoid: nlimit too large',' ')
        call abend
      endif
      if(klimit.gt.max_klimit)then
        call xvmessage('get_ellipsoid: klimit too large',' ')
        call abend
      endif
      if(mlimit.gt.max_mlimit)then
        call xvmessage('get_ellipsoid: mlimit too large',' ')
        call abend
      endif
      write(*,*)'Archive limits=',nlimit,klimit,mlimit
      write(*,*)'Archive radii=',a,b,c
 

c open 4 outputs
      do i=1,4
        call xvunit(ounit(i),'OUT',i,status,' ')
        call xvsignal(ounit(i),status,1)
        call xvopen(ounit(i),status,'U_FORMAT','REAL','O_FORMAT','REAL',
     +              'U_NL',nlo,'U_NS',nso,'OP','WRITE',' ')
        call xvsignal(ounit(i),status,1)
      enddo

c set auxiliary conversions
      if(conformal)then
        call xvmessage('Conformal auxiliary coord conversions',' ')
        infmt=4
        iofmt=1
       endif
      if(authalic)then
        call xvmessage('Authalic auxiliary coord conversions',' ')
        infmt=5
        iofmt=1
      endif
 
c Write output files
      c=c/a
      b=b/a
      a=1.d0
      do j=1,nlo
        line=j
        do i=1,nso
          sample=i

c         convert l,s to lat,lon (conformal or authalic)
          call xy2ll(line,sample,nlo,nso,lat,lon)

c         compute centric lat & lon from snyder coefficients
          inlat=lat
          inlon=360.d0-lon       ! convert to east lon
          call triaxtran(a,b,c,confcoef1,confcoef2,
     +     authcoef1,authcoef2,nlimit,
     +     klimit,mlimit,inlat,inlon,infmt,
     +     outlat,outlon,iofmt,ind)
          if(ind.gt.0)then
            call xvmessage('Triaxtran error',' ')
            call abend
          endif
          outlon=360.d0-outlon   ! convert to west lon

c         fix poles
          if(lat.gt.89.99)then
            outlat=90.
            outlon=lon
          endif
          if(lat.lt.-89.99)then
            outlat=-90.
            outlon=lon
          endif

          obuf(i,1)=outlat
          obuf(i,2)=outlon
          obuf(i,3)=outlat-lat
          obuf(i,4)=outlon-lon
          if(obuf(i,4).lt.-180.)obuf(i,4)=obuf(i,4)+360.
          if(obuf(i,4).gt.180.)obuf(i,4)=obuf(i,4)-360.
        enddo
        do k=1,4
          call xvwrit(ounit(k),obuf(1,k),status,' ')
          call xvsignal(ounit(k),status,1)
        enddo
      enddo                                  ! line loop

      return
      end


c********************************************************************
      subroutine ll2xy(lat,lon,nl,ns,line,sample)
c Convert lat & lon into image coordinates for the object map

      real*4 lat,lon
      real*4 line,sample

c convert lat/lon to line/sample
      lon=mod(lon,360.)
      if(lon.lt.0.) lon=360.-lon
      t=(ns+1.0)/2.0
      if(lon.gt.180.)then
         sample=-(ns-t)*lon/180. + 2.0*ns - t
      else
         sample=-(t-1.0)*lon/180.+t
      endif
      line=(1.0-nl)*(lat-90.0)/180. + 1.0

      return
      end

c********************************************************************
      subroutine xy2ll(line,sample,nl,ns,lat,lon)
c convert line sample to lat lon.

      real*4 lat,lon
      real*4 line,sample

      lat=((line-1.0)*180./(1.0-nl))+90.0
      t=(ns+1.0)/2.0
      if(sample .gt. t)then
        lon=(sample+t-2.0*ns)*180./(t-ns)
      else
        lon=(sample-t)*180./(1.0-t)
      endif

      return
      end

c *********************************************************************
      subroutine get_ellipsoid(archive_filename,planet,a,b,c,
     +        cc,cp,ac,ap,nlimit,klimit,mlimit,ind)
 
c routine to return the conformal & authalic buffers from the archive
c for a specific planet name in a format to match the coordinate conversion
c subroutine triaxtran.
c archive_filename   archive name             input     character*80
c planet             planet name              input     character*12
c a                  planet major radius      returned  real*8
c b                  planet middle radius     returned  real*8
c c                  planet minor radius      returned  real*8
c cc                 first conformal buffer   returned  real*8
c                    (length nlimit*mlimit)
c cp                 second conformal buffer  returned  real*8
c                    (length nlimit*mlimit)
c ac                 first authalic  buffer   returned  real*8
c                    (length (mlimit+1)*(klimit+1)
c ap                 second authalic buffer   returned  real*8
c                    (length nlimit)
c nlimit             buffer dimension         returned  integer*4
c klimit             buffer dimension         returned  integer*4
c mlimit             buffer dimension         returned  integer*4
c ind                status: ok=0 error=1     returned  integer*4
 
      implicit real*8 (a-h,o-z)
      parameter(ibis_column_length=1024)
      character*80 archive_filename
      character*12 planet
      logical archive_exists
      integer*4 status,unit,count
      real*8 buffer(ibis_column_length),cc(1),cp(1),ac(1),ap(1)
 
c locate the planet column & return data in buffer
      ind=0
      inquire(file=archive_filename,exist=archive_exists)
 
      if(archive_exists)then  ! update existing archive
 
c       open archive
        call xvunit(unit,'old',1,status,'U_NAME',archive_filename,' ')
        call xvsignal(unit,status,1)
        call ibis_file_open(unit,ibis_out,'update',0,0,' ',' ',status)
        if(status.ne.1) call ibis_signal_u(unit,status,1)
 
c       get file size
        count=ibis_file_get(ibis_out,'nc',ncol,1,1)! cols
        if(count.ne.1) then
           call ibis_signal(ibis_out,count,1)
           ind=1
           return
        endif
        count=ibis_file_get(ibis_out,'nr',nrow,1,1)! rows
        if(count.ne.1) then
           call ibis_signal(ibis_out,count,1)
           ind=1
           return
        endif
 
c       get the column with this planet name
        count=ibis_column_find(ibis_out,'group',planet,icol,1,1)
        if(count.lt.0) then
           call ibis_signal(ibis_out,count,1)
           ind=1
           return
        else if(count.eq.0)then
c          cannot find existing column with same name
           call xvmessage('No column exists with this planet name',' ')
           ind=1
           return
        else
c          read data
           call ibis_column_read(ibis_out,buffer,icol,1,nrow,status)
           if(status.ne.1) then
              call ibis_signal(ibis_out,status,1)
              ind=1
              return
           endif
           call ibis_file_close(ibis_out,' ',status)       ! close file
        endif
 
      else
        call xvmessage('Coefficient archive does not exist',' ')
        ind=1
        return
      endif
c Load output arguments
      mlimit=nint(buffer(1))
      klimit=nint(buffer(2))
      nlimit=nint(buffer(3))
      a=buffer(4)
      b=buffer(5)
      c=buffer(6)
      k=6
      do i=1,nlimit*mlimit
        k=k+1
        cc(i)=buffer(k)
      enddo
      do i=1,nlimit*mlimit
        k=k+1
        cp(i)=buffer(k)
      enddo
      do i=1,(mlimit+1)*(klimit+1)
        k=k+1
        ac(i)=buffer(k)
      enddo
      do i=1,nlimit
        k=k+1
        ap(i)=buffer(k)
      enddo
 
      return
      end
