#!/bin/bash

function extract_wifi_fix_patch {
if [ "${WIFI_FIX}" == "y" ]; then
cat <<WIFI_F > ${PATCH_DIR}/wifi_fix.patch
diff --git a/arch/arm/configs/msm8916_sec_defconfig b/arch/arm/configs/msm8916_sec_defconfig
index 04ad01c474e3..285afd1a4c9e 100644
--- a/arch/arm/configs/msm8916_sec_defconfig
+++ b/arch/arm/configs/msm8916_sec_defconfig
@@ -718,7 +718,7 @@ CONFIG_SECCOMP=y
 # Qualcomm Atheros Prima WLAN module
 #
 # CONFIG_PRIMA_WLAN is not set
-CONFIG_PRONTO_WLAN=y
+CONFIG_PRONTO_WLAN=m
 CONFIG_PRIMA_WLAN_BTAMP=n
 CONFIG_PRIMA_WLAN_LFR=y
 CONFIG_PRIMA_WLAN_OKC=y
WIFI_F
fi
}

PATCHES=("${PATCHES[@]}" "extract_wifi_fix_patch")
