#!/bin/bash
# Welcome message with disk quota info
# /etc/profile.d/welcome.sh

# -------- ASCII ART --------
cat <<'EOF'
 / ___| ___  _ __  ______ _| | ___ ____ | |    __ _| |__               
| |  _ / _ \| '_ \|_  / _` | |/ _ \_  / | |   / _` | '_ \              
| |_| | (_) | | | |/ / (_| | |  __// /  | |__| (_| | |_) |             
 \____|\___/|_| |_/___\__,_|_|\___/___| |_____\__,_|_.__/              
 ____  _    _   _ ____  __  __                                         
/ ___|| |  | | | |  _ \|  \/  |  ___  ___ _ ____   _____ _ __          
\___ \| |  | | | | |_) | |\/| | / __|/ _ \ '__\ \ / / _ \ '__|         
 ___) | |__| |_| |  _ <| |  | | \__ \  __/ |   \ V /  __/ |            
|____/|_____\___/|_| \_\_|  |_| |___/\___|_|    \_/ \___|_|            

EOF

# -------- Welcome --------
echo
echo "Welcome to the Gonzalez Lab SLURM server at IBB, $USER!"
echo "Lab server wiki: https://github.com/dmckeow/GonzalezLabServer/wiki"  # replace with actual wiki link
echo

# -------- Disk Quota --------
if command -v quota &> /dev/null; then
    echo "Your disk quota usage:"
    
    # loop over all filesystems with quotas
    quota -s | awk 'NR>2 {
    # Extract numeric value and unit for used
    used_num = $2; sub(/[A-Za-z]+$/, "", used_num)
    used_unit = $2; sub(/^[0-9.]+/, "", used_unit)

    # Extract numeric value and unit for quota
    quota_num = $4; sub(/[A-Za-z]+$/, "", quota_num)
    quota_unit = $4; sub(/^[0-9.]+/, "", quota_unit)

    # Convert used to bytes
    if (used_unit=="M") used_b = used_num * 1024 * 1024
    else if (used_unit=="G") used_b = used_num * 1024 * 1024 * 1024
    else if (used_unit=="T") used_b = used_num * 1024 * 1024 * 1024 * 1024
    else used_b = used_num

    # Convert quota to bytes
    if (quota_unit=="M") quota_b = quota_num * 1024 * 1024
    else if (quota_unit=="G") quota_b = quota_num * 1024 * 1024 * 1024
    else if (quota_unit=="T") quota_b = quota_num * 1024 * 1024 * 1024 * 1024
    else quota_b = quota_num

    if (quota_b > 0) pct = int(used_b / quota_b * 100); else pct = 0

    printf "%-10s : %3d%% used (%s of %s)\n", $1, pct, $2, $4
}' | sed "s/\/dev\/sdb1/HOME:    \/hddraid5\/${USER}/g" | sed "s/\/dev\/sdc1/SCRATCH: \/ssdraid0\/${USER}/g"


else
    echo "Quota command not found."
fi

echo
