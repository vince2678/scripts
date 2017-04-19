
#!/bin/bash

function extract_fast_charge_config_patch {
if [ "${FAST_CHARGING}" == "y" ]; then
logb "\t\tExtracting fast charging patch..."
cat <<FAST_C > ${PATCH_DIR}/fast_charge_config.patch
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtelwifi_usa_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtelwifi_usa_defconfig
index f62f3d2f1274..c1f0feeadd84 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtelwifi_usa_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtelwifi_usa_defconfig
@@ -73,7 +73,7 @@ CONFIG_SAMSUNG_LPM_MODE=y
 CONFIG_CHARGING_VZWCONCEPT=y
 CONFIG_BATTERY_SWELLING=y
 CONFIG_BATTERY_SWELLING_SELF_DISCHARGING=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1700
 CONFIG_CHARGER_SM5703_SOFT_START_CHARGING=y
 CONFIG_PREVENT_SOC_JUMP=y
 
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtes_spr_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtes_spr_defconfig
index 4c42f9f0da48..789811a1a668 100644
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtes_spr_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_gtes_spr_defconfig
@@ -58,7 +58,7 @@ CONFIG_BATTERY_SAMSUNG_DATA_FILE="gtes_battery_data.h"
 CONFIG_SAMSUNG_LPM_MODE=y
 CONFIG_PREVENT_SOC_JUMP=y
 CONFIG_BATTERY_SWELLING=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1700
 CONFIG_SW_SELF_DISCHARGING=y
 
 #FLASH
FAST_C
fi
}

function extract_fast_charge_sm5703_patch {
if [ "${FAST_CHARGING}" == "y" ]; then
cat <<FAST_C_S > ${PATCH_DIR}/fast_charge_sm5703.patch
diff --git a/kernel/samsung/msm8916/include/linux/battery/charger/sm5703_charger.h b/kernel/samsung/msm8916/include/linux/battery/charger/sm5703_charger.h
index dddf29c7f9a0..c4f02381c4ae 100755
--- a/kernel/samsung/msm8916/include/linux/battery/charger/sm5703_charger.h
+++ b/kernel/samsung/msm8916/include/linux/battery/charger/sm5703_charger.h
@@ -117,7 +117,11 @@ enum {
 #define START_VBUSLIMIT_DELAY			1200
 #define VBUSLIMIT_DELAY					200
 #define REDUCE_CURRENT_STEP				50
+#if defined(CONFIG_MACH_GTEL_USA_VZW) || defined(CONFIG_MACH_GTELWIFI_USA_OPEN)
+#define MINIMUM_INPUT_CURRENT			600
+else
 #define MINIMUM_INPUT_CURRENT			300
+#endif
 
 #if defined(CONFIG_MACH_GTEL_USA_VZW) || defined(CONFIG_MACH_GTELWIFI_USA_OPEN)
 #define SLOW_CHARGING_CURRENT_STANDARD	1050
@@ -132,6 +136,8 @@ enum {
 
 #if defined(CONFIG_MACH_XCOVER3_DCM)
 #define SIOP_INPUT_LIMIT_CURRENT		1000
+#elif defined(CONFIG_MACH_GTEL_USA_VZW) || defined(CONFIG_MACH_GTELWIFI_USA_OPEN)
+#define SIOP_INPUT_LIMIT_CURRENT		1700
 #else
 #define SIOP_INPUT_LIMIT_CURRENT		1200
 #endif
FAST_C_S
fi
}

PATCH_FUNCTIONS=("${PATCH_FUNCTIONS[@]}" "extract_fast_charge_config_patch")
PATCH_FUNCTIONS=("${PATCH_FUNCTIONS[@]}" "extract_fast_charge_sm5703_patch")
