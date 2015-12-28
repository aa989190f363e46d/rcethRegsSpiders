#!/usr/bin/env bash

src_dir='../data/pdfs/full'
output_dir='../data'
tmp_dir='tmp'

for fl in `ls $src_dir`
do

  pgcnt=`pdfinfo $src_dir/$fl | grep Pages | sed 's/[^0-9]*//'`
  pps=$((($pgcnt+2)/2))
  
  if (($pgcnt <= 6))
  then 
		pps=$(($pgcnt))
  else 
		if (($pgcnt >12))
		then
	    pps=6
		fi
  fi

  dpi=150
  fl_dir=$output_dir/jpg/dpi-$dpi/"${fl%.*}"
  if [ ! -d $fl_dir ]
  then  
    mkdir $fl_dir
    ghostscript -dNOPAUSE -r$dpi -sDEVICE=jpeg -sOutputFile=$fl_dir/page-%03d.jpg $src_dir/$fl -c quit
    for jf in `ls $fl_dir`
    do
      convert $fl_dir/$jf -crop \
      `convert $fl_dir/$jf -virtual-pixel edge -blur 0x10 -fuzz 15% -trim \
                -format '%[fx:w+50]x%[fx:h+50]+%[fx:page.x-25]+%[fx:page.y-25]' \
                info:` +repage  $tmp_dir/tmp.jpg
      convert -resize 1240x1754 $tmp_dir/tmp.jpg -background white -gravity north -extent 1240x1754 $tmp_dir/tmp-a4.jpg     
      mv $tmp_dir/tmp-a4.jpg $fl_dir/$jf   
    done
  fi
  #if [ ! -e $output_dir/$fl ]
  #then
  #  pdf2ps $src_dir/$fl $tmp_dir/tmp.ps
  #  psnup -$pps $tmp_dir/tmp.ps $tmp_dir/tmp.n.ps
  #  ps2pdf $tmp_dir/tmp.n.ps $output_dir/$fl
  #  rm -rf $tmp_dir/*
  #fi

done

#rm -rf $tmp_dir/*