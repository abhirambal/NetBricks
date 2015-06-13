#!/bin/zsh

echo "Building"

echo $$ | sudo tee /mnt/cpuset/sn/tasks

SOFTNIC_DIR=/home/apanda/softnic/softnic

for i in {chain-green-thread,chain-multi-core,chain-same-core}/*.cs
do
	 mcs -unsafe+ -checked- $i VirtualFunctions.cs llring.cs E2D2Iface.cs SoftNic.cs ../lookup-test/iplookup.cs
done
echo "Done building"
#PFX=$1
#echo "Prefix $PFX"


base=500000000
end=20000000000
inc=500000000

for bw in `seq $base $inc $end`
do
	for iter in {0..2}
	do
		out="logs/base-$bw-$iter.txt"
		echo "Testing baseline ${bw} Iter $iter"
		sudo SCENARIO=v2s2v $SOFTNIC_DIR/softnic -c 4,5,6,7 -- -l 1 -d 15 -r 4 -t 4 -b $bw | tee "$out" &
		SOFTNIC_PID=$!
		sudo LD_PRELOAD=libintel_dpdk.so /home/apanda/mono-bin/bin/mono --gc=sgen --llvm chain-same-core/BaselineGC1.exe &
		echo "Waiting for $SOFTNIC_PID"
		wait $SOFTNIC_PID
		sudo pkill mono
	done
	for iter in {0..2}
	do
		out="logs/fgc-$bw-$iter.txt"
		echo "Testing fixed ${bw} Iter $iter"
		sudo SCENARIO=v2s2v $SOFTNIC_DIR/softnic -c 4,5,6,7 -- -l 1 -d 15 -r 4 -t 4 -b $bw | tee "$out" &
		SOFTNIC_PID=$!
		sudo LD_PRELOAD=libintel_dpdk.so /home/apanda/mono-bin/bin/mono --gc=sgen --llvm chain-same-core/FixedGC1.exe &
		echo "Waiting for $SOFTNIC_PID"
		wait $SOFTNIC_PID
		sudo pkill mono
	done
	for iter in {0..2}
	do
		out="logs/dgc-$bw-$iter.txt"
		echo "Testing dynamic ${bw} Iter $iter"
		sudo SCENARIO=v2s2v $SOFTNIC_DIR/softnic -c 4,5,6,7 -- -l 1 -d 15 -r 4 -t 4 -b $bw | tee "$out" &
		SOFTNIC_PID=$!
		sudo LD_PRELOAD=libintel_dpdk.so /home/apanda/mono-bin/bin/mono --gc=sgen --llvm chain-same-core/DynamicGC1.exe &
		echo "Waiting for $SOFTNIC_PID"
		wait $SOFTNIC_PID
		sudo pkill mono
	done
done
