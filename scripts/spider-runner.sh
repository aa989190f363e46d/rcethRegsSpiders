#!/usr/bin/env bash

curr_file_name="`date +%Y-%m-%d-%H-%M`-rceth-instr"

cd drugRegSpider

scrapy crawl -o ../../data/$curr_file_name.csv --logfile ../../data/$curr_file_name.log instrSpider