implementer=$(cat /proc/cpuinfo | grep "CPU implementer" | awk 'NR==1{printf $4}')
part=$(cat /proc/cpuinfo | grep "CPU part" | awk 'NR==1{printf $4}')
if [ "${implementer}-${part}" != "0x48-0xd01" ] && [ "${implementer}-${part}" != "0x48-0xd01" ] && [ "${implementer}-${part}" != "0x48-0xd01" ]; then
	exit 0
fi
exit 1
