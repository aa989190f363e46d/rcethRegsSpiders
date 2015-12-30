#!/usr/bin/env bash

src_dir=../data/pdfs/full
output_dir=../data
tmp_dir=tmp
rearr_dir=$output_dir/pdfs/print-ready
dvsrs=(6 4 2 1)

dpi=150
a4_150_dpi_lng=1754
a4_150_dpi_shrt=1240
a4_150_dpi_port=${a4_150_dpi_shrt}x${a4_150_dpi_lng}
a4_300_dpi_lng=3508
a4_300_dpi_shrt=2480
a4_300_dpi_port=${a4_300_dpi_shrt}x${a4_300_dpi_lng}
a4_300_dpi_lnds=${a4_300_dpi_lng}x${a4_300_dpi_shrt}
flc=1

collage() {

  l_fl_dir=$1
  C=$2
  rmndr=$C

  mntgc=1
  mntg_files=""

  printf  "\e[0;31m    [%-32s]\e[m" `basename $l_fl_dir`

  # покуда не исчерпаны все страницы
  while [[ $rmndr -ne 0 ]]; do
    # найти максимальный делитель
    for dvsr in ${dvsrs[@]}; do
      fr=$(($rmndr/$dvsr))
      # то есть такой, чтобы остаток
      # от целочисленного деления был не 0
      if [[ $fr -gt 0 ]]; then
        rmndr=$(($rmndr%$dvsr))
        break
      fi
    done

    # тогда для каждой группы страниц
    # размером в текущий делитель
    for mntgpgn in `seq 0 $(($fr-1))`; do
      files=''
      u_bound=$((($mntgpgn+1)*$dvsr+$C-($rmndr+$dvsr*$fr)))
      l_bound=$((1 + $mntgpgn*$dvsr+$C-($rmndr+$dvsr*$fr)))     
      for pgn in `seq $l_bound $u_bound`; do
        files=$files`printf ' %s/page-%03d.jpg' $l_fl_dir $pgn`
      done    
      printf "\e[0;34m[%02d–%02d\e[m" $l_bound $u_bound
      # Выбрать раскладку для коллажа
      # Выбрать выходное разрешение и ориентацию
      case $dvsr in
        6 )
          cres=$a4_300_dpi_lnds
          tile=3x
          ;;
        4 )
          cres=$a4_300_dpi_port
          tile=2x
          ;;
        2 )
          cres=$a4_300_dpi_lnds
          tile=2x
          ;;
        * )
          cres=$a4_300_dpi_port
          tile=''
          ;;
      esac

      if [[ $dvsr -ne 1 ]]; then
        # Монтирует изображения отдельных страниц в коллаж
        montage $files -geometry $a4_150_dpi_port -tile $tile $tmp_dir/collage-tmp.jpg
        # Подгоняет размер коллажа под формат
        # листа для печати, с учетом разрешения
        convert -resize $cres $tmp_dir/collage-tmp.jpg -background white -gravity north -extent $cres $tmp_dir/collage-$mntgc.jpg
      else
        #cp $files $tmp_dir/collage-$mntgc.jpg
        convert -resize $cres $files -background white -gravity north -extent $cres $tmp_dir/collage-$mntgc.jpg
      fi

      mntg_files=$mntg_files" "$tmp_dir/collage-$mntgc.jpg
      mntgc=$(($mntgc+1))   

      printf "\e[0;34m]\e[m"

    done
  done

  convert $mntg_files $rearr_dir/`basename $l_fl_dir`.pdf
  printf  "\e[0;31m[%-32s]\e[m\n" `basename $l_fl_dir`.pdf
  rm -rf $tmp_dir/*
}

for fl in `ls $src_dir`; do  

  fl_dir=$output_dir/jpg/dpi-$dpi/"${fl%.*}"
  if [ ! -d $fl_dir ]
  then  
    mkdir $fl_dir
    # extract pages to jpg
    printf  "\e[0;31m[%-4s][%-32s]\e[m" $flc $fl
    ghostscript -dNOPAUSE -r$dpi -sDEVICE=jpeg -sOutputFile=$fl_dir/page-%03d.jpg $src_dir/$fl -c quit > /dev/null
    pgc=1
    for jf in `ls $fl_dir`    
    do

      printf "\e[0;34m[%s\e[m" $pgc

      # crop textblock
      convert $fl_dir/$jf -crop \
      `convert $fl_dir/$jf -virtual-pixel edge -blur 0x10 -fuzz 15% -trim \
                -format '%[fx:w+50]x%[fx:h+50]+%[fx:page.x-25]+%[fx:page.y-25]' \
                info:` +repage  $tmp_dir/tmp.jpg
      # resize keeping aspect ratio to a4 150dpi          
      convert -resize $a4_150_dpi_port $tmp_dir/tmp.jpg -background white -gravity north -extent $a4_150_dpi_port $tmp_dir/tmp-a4.jpg   

      pgc=$[$pgc+1]  
      printf "\e[0;34m]\e[m"
    done

    mv $tmp_dir/tmp-a4.jpg $fl_dir/$jf            

    flc=$[$flc+1]
    printf "\e[0;34m\n\e[m"


  fi

  if [[ -d $fl_dir  &&  ! -f $rearr_dir/`basename $fl_dir`.pdf ]]; then
    collage $fl_dir `ls $fl_dir/page-*.jpg | wc -l`
  fi

  #if [ ! -e $output_dir/$fl ]
  #then
  #  pdf2ps $src_dir/$fl $tmp_dir/tmp.ps
  #  psnup -$pps $tmp_dir/tmp.ps $tmp_dir/tmp.n.ps
  #  ps2pdf $tmp_dir/tmp.n.ps $output_dir/$fl
  #  rm -rf $tmp_dir/*
  #fi

done

rm -rf $tmp_dir/*