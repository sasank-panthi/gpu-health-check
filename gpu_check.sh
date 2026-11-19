#!/bin/bash
# check that the GPU is detected
if ! nvidia-smi > /dev/null 2>&1; then
    echo "RESULT: FAIL - GPU not detected"
    exit 1
fi
# gpu_check.sh - simple GPU health check
DATA=$(nvidia-smi --query-gpu=name,temperature.gpu,power.draw,memory.used,memory.total --format=csv,noheader,nounits | sed 's/, /,/g')
IFS=',' read -r NAME TEMP POWER MEM_USED MEM_TOTAL <<< "$DATA"
echo "=========== GPU HEALTH CHECK =========="
echo "GPU: $NAME"
echo "Temperature: $TEMP C"
echo "Power draw: $POWER W"
echo "Memory used: $MEM_USED / $MEM_TOTAL MiB"
echo "======================================================="
# limits
TEMP_LIMIT=85
EXPECTED_MEM=4096
RESULT="PASS"

# temperature check
if [ "$TEMP" -lt "$TEMP_LIMIT" ]; then
    echo "Temperature check:  PASS ($TEMP C < $TEMP_LIMIT C)"
else
    echo "Temperature check:  FAIL ($TEMP C >= $TEMP_LIMIT C)"
    RESULT="FAIL"
fi

# memory check
if [ "$MEM_TOTAL" -eq "$EXPECTED_MEM" ]; then
    echo "Memory check:       PASS ($MEM_TOTAL MiB)"
else
    echo "Memory check:       FAIL (expected $EXPECTED_MEM, got $MEM_TOTAL)"
    RESULT="FAIL"
fi

echo "RESULT: $RESULT"
# save result to log file
LOG_FILE="$HOME/projects/gpu-health-check/gpu_log.csv"

if [ ! -f "$LOG_FILE" ]; then
    echo "timestamp,gpu,temp_c,power_w,mem_total_mib,result" > "$LOG_FILE"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S'),$NAME,$TEMP,$POWER,$MEM_TOTAL,$RESULT" >> "$LOG_FILE"
echo "Saved to $LOG_FILE"
