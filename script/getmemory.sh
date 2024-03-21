while true
do
	free -g
	#python ddrl3c_per_channel.py
	iostat -x 2 3|egrep "Devive|nvme"
	sleep 60
done
