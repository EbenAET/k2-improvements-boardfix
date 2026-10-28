#!/bin/ash
set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# these are replacing the default init scripts and MUST be copied
cp -f ${SCRIPT_DIR}/klipper_mcu.init /etc/init.d/klipper_mcu
/etc/init.d/klipper_mcu restart
cp -f ${SCRIPT_DIR}/klipper.init /etc/init.d/klipper
/etc/init.d/klipper restart
cp -f ${SCRIPT_DIR}/webrtc.init /etc/init.d/webrtc
/etc/init.d/webrtc restart

# need to link wrapper scripts in place
# linking so they get updates
test -d /mnt/UDISK/bin || mkdir -p /mnt/UDISK/bin

ln -sf ${SCRIPT_DIR}/bin/sudo /mnt/UDISK/bin/
ln -sf ${SCRIPT_DIR}/bin/supervisorctl /mnt/UDISK/bin/
ln -sf ${SCRIPT_DIR}/bin/systemctl /mnt/UDISK/bin/

# update the path
echo 'export PATH=/mnt/UDISK/bin:$PATH' > /etc/profile.d/better-init.sh

# Creality Helper Script's patch_stock_configs restores the F008 motor config on boot; make it board-aware.
HELPER_SYSTEM_SH=/mnt/UDISK/helper-script/scripts/system.sh
if [ -f "$HELPER_SYSTEM_SH" ] && ! grep -q 'F021_CR0CN200400C10' "$HELPER_SYSTEM_SH"; then
    cp -n "$HELPER_SYSTEM_SH" "${HELPER_SYSTEM_SH}.pre-f021-fix"
    # prefixed names so the helper script's own variables are not clobbered
    sed -i 's|^\([[:space:]]*\)local stock_motor_cfg="/rom/usr/share/klipper/config/F008_CR0CN240319C13/motor_control.cfg"|&\n\1f021_model=$(get_sn_mac.sh model)\n\1f021_board=$(get_sn_mac.sh board)\n\1if [ "$f021_model" = "F021" ] \&\& [ "$f021_board" = "CR0CN200400C10" ]; then\n\1    stock_motor_cfg="/rom/usr/share/klipper/config/F021_CR0CN200400C10/motor_control.cfg"\n\1fi|' "$HELPER_SYSTEM_SH"
    if grep -q 'F021_CR0CN200400C10' "$HELPER_SYSTEM_SH"; then
        echo "[OK] Patched Creality Helper Script for F021 motor_control.cfg"
    else
        echo "[WARN] stock_motor_cfg line not found in $HELPER_SYSTEM_SH; helper script not patched"
    fi
fi
