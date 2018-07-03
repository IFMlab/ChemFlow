program extractmol2
character (LEN=128) :: line
character (LEN=128) :: compound
character (LEN=256) :: inputfile
character (LEN=1)   :: opt

!------------------------------------------------
write(*,*) "List file: "
read(*,*) inputfile
write(*,*) trim((ADJUSTL(inputfile)))
open(1,file=trim((ADJUSTL(inputfile))))


write(*,*) "Input MOL2 file: "
read(*,*) inputfile
write(*,*) trim((ADJUSTL(inputfile)))
open(2,file=trim((ADJUSTL(inputfile))))


write(*,*) "Output MOL2 file: "
read(*,*) inputfile
write(*,*) trim((ADJUSTL(inputfile)))
open(3,file=trim((ADJUSTL(inputfile))))

opt="N"
write(*,*) "Is .mol2 sorted list? [N]"
read(*,*) opt

!------------------------------------------------
line=""
do
read(1,"(A128)",err=100,end=100) compound
write(*,*) "Compound: ",trim(compound)

  if (opt=="N") rewind(2) 

  do while ( index(trim(line),trim(compound)) == 0 )
    read(2,'(A128)') line
  enddo

  write(3,"(A)") "@<TRIPOS>MOLECULE"
  write(3,"(A)") adjustl(trim(compound))

  ! Why do I need that EXTRA IF !!! Right now I hate you fortran !
  do while ( index(trim(line),"MOLECULE") == 0 )
    read(2,'(A128)') line
    if ( index(trim(line),"MOLECULE") == 0 )  write(3,"(A128)") line
  enddo

enddo

100 continue
END
