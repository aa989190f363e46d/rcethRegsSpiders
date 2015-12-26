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

  fl_dir=$output_dir/jpg/"${fl%.*}"
  if [ ! -d $fl_dir ]
  then  
    mkdir $fl_dir
    ghostscript -dNOPAUSE -r300 -sDEVICE=jpeg -sOutputFile=$fl_dir/page-%03d.jpg $src_dir/$fl -c quit
  fi

  if [ ! -e $output_dir/$fl ]
  then
    pdf2ps $src_dir/$fl $tmp_dir/tmp.ps
    psnup -$pps $tmp_dir/tmp.ps $tmp_dir/tmp.n.ps
    ps2pdf $tmp_dir/tmp.n.ps $output_dir/$fl
    rm -rf $tmp_dir/*
  fi

done


