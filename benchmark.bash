#!/bin/bash

#BenchMark Using Concurrency=100(100 users at same time)

rm -f $HOME/linxapp/benchmark.txt

ab -n 20000 -c 100 http://localhost/ >> $HOME/linxapp/benchmark.txt
ab -n 40000 -c 100 http://localhost/ >> $HOME/linxapp/benchmark.txt 
ab -n 60000 -c 100 http://localhost/ >> $HOME/linxapp/benchmark.txt 
ab -n 80000 -c 100 http://localhost/ >> $HOME/linxapp/benchmark.txt 
ab -n 100000 -c 100 http://localhost/ >> $HOME/linxapp/benchmark.txt

cat $HOME/linxapp/benchmark.txt
 




