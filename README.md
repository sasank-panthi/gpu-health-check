GPU Health Check Script

A simple Bash script that checks if an NVIDIA GPU is healthy, gives a PASS or FAIL result, and saves every run to a log file.

I work as a server test operator, and I wanted to understand what actually happens behind the test screens I use every day. So I built a small version of a GPU test myself on my home lab server (an old MSI laptop running Ubuntu Server with a GTX 1650).

What it does

When you run the script, it:

Checks if the GPU is detected. If nvidia-smi doesn't respond, the script stops right away and reports FAIL.
Reads the GPU's numbers: name, temperature, power draw, and memory.
Compares them to limits:
Temperature has to be below 85°C
VRAM has to be exactly 4096 MiB (if a GPU shows less memory than its spec, something is wrong with the hardware)
Gives a final result. If any single check fails, the whole run is a FAIL, the same way a real production test works.
Saves the result to gpu_log.csv with a timestamp, so I can look back at past runs and spot patterns.
How the check works

The core of the script is simple: read a value, compare it to a limit, and mark the run as FAIL if it's out of spec. Here's the temperature check:

bash
TEMP_LIMIT=85
RESULT="PASS"

if [ "$TEMP" -lt "$TEMP_LIMIT" ]; then
    echo "Temperature check:  PASS ($TEMP C < $TEMP_LIMIT C)"
else
    echo "Temperature check:  FAIL ($TEMP C >= $TEMP_LIMIT C)"
    RESULT="FAIL"
fi

RESULT starts as PASS and only ever changes to FAIL. Once any check fails, the whole run fails. The full script is in gpu_check.sh.

Example output

Passing run

========== GPU HEALTH CHECK ==========
GPU: NVIDIA GeForce GTX 1650 with Max-Q Design
Temperature: 41 C
Power draw: 3.79 W
Memory used: 0 / 4096 MiB
======================================
Temperature check:  PASS (41 C < 85 C)
Memory check:       PASS (4096 MiB)
RESULT: PASS
Saved to /home/roses/projects/gpu-health-check/gpu_log.csv
Testing the FAIL path

A test that has never failed hasn't proven anything. To make sure the script can actually catch a bad unit, I lowered the temperature limit to 30°C on purpose. The GPU was sitting at 41°C, so the script correctly reported FAIL. Then I set the limit back to 85°C.

Forced fail

The log file

Every run adds one line to gpu_log.csv. Old runs are never overwritten.

Log file

timestamp,gpu,temp_c,power_w,mem_total_mib,result
2026-11-19 15:28:46,NVIDIA GeForce GTX 1650 with Max-Q Design,41,4.66,4096,PASS
2026-11-19 15:28:58,NVIDIA GeForce GTX 1650 with Max-Q Design,41,3.71,4096,PASS
2026-11-19 15:29:10,NVIDIA GeForce GTX 1650 with Max-Q Design,41,4.64,4096,PASS
2026-11-19 15:38:16,NVIDIA GeForce GTX 1650 with Max-Q Design,41,4.48,4096,PASS
2026-11-19 15:40:34,NVIDIA GeForce GTX 1650 with Max-Q Design,41,4.37,4096,FAIL

The last line is the forced-fail run, which shows that failures get logged too, not just passes.

One thing I noticed right away: the temperature stayed at 41°C, but the power draw moved around between 3.7 W and 4.7 W. That's exactly why logs matter. You only see patterns like that when you compare runs side by side.

How to run it

You need a Linux machine with an NVIDIA GPU and the driver installed (nvidia-smi should work).

bash
git clone https://github.com/sasank-panthi/gpu-health-check.git
cd gpu-health-check
chmod +x gpu_check.sh
./gpu_check.sh

If your GPU has a different amount of memory, change EXPECTED_MEM in the script to match it.

What I learned
Writing Bash scripts: variables, if statements, and comparing numbers
Pulling clean data out of nvidia-smi with --query-gpu and --format=csv,noheader,nounits
Why exit codes matter (0 means pass, anything else means fail) and how test systems use them
The difference between > (overwrite) and >> (add to the end), and why a log should always use >>
Debugging by actually reading error messages. Most of my mistakes were small typos, and every error message pointed straight at the problem
Setting the server's time zone with timedatectl, and why a lot of data centers keep their servers on UTC
What's next
Add a stress test so the GPU gets checked under load, not just at idle
Check for GPU errors (ECC / Xid errors) in system logs
Write a Python script that reads gpu_log.csv and graphs temperature and power over time
Related projects
nvidia-driver-ubuntu-server: how I installed the NVIDIA driver on this server
homelab-network-setup: the network this server runs on
