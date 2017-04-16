
#!/bin/bash

function extract_fast_charge_patch {
if [ "${FAST_CHARGING}" == "y" ]; then
cat <<FAST_C > ${PATCH_DIR}/fast_charge.patch
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_can_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_can_defconfig
index d93863e2ebad..bd332878c2ff 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_can_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_can_defconfig
@@ -41,7 +41,7 @@ CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
 CONFIG_MFD_RT5033_RESET_WA=y
 CONFIG_MFD_RT5033_SLDO_VBUSDET=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 CONFIG_BATTERY_SWELLING=n
 
 #SENSOR
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_chnzt_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_chnzt_defconfig
index 2540fe343d2c..062dd3e0d253 100644
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_chnzt_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_chnzt_defconfig
@@ -39,7 +39,7 @@ CONFIG_SAMSUNG_LPM_MODE=y
 CONFIG_CHARGER_RT5033=y
 CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 
 # VIBRATOR
 CONFIG_VIBETONZ=y
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_defconfig
index 44670c07bdd7..43ea9228cbe4 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_defconfig
@@ -46,7 +46,7 @@ CONFIG_REGULATOR_RT5033=y
 CONFIG_MFD_RT5033_RESET_WA=y
 CONFIG_MFD_RT5033_SLDO_VBUSDET=y
 CONFIG_BATTERY_SWELLING=n
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 
 #SENSOR
 CONFIG_SENSORS=y
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_eur_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_eur_defconfig
index 7138c2f393c9..764555adc06b 100644
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_eur_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_eur_defconfig
@@ -43,7 +43,7 @@ CONFIG_SAMSUNG_LPM_MODE=y
 CONFIG_CHARGER_RT5033=y
 CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 
 # VIBRATOR
 CONFIG_VIBETONZ=y
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_spr_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_spr_defconfig
index 5e4451704e56..655de0059bd6 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_spr_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_spr_defconfig
@@ -37,7 +37,7 @@ CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
 CONFIG_MFD_RT5033_RESET_WA=y
 CONFIG_MFD_RT5033_SLDO_VBUSDET=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 CONFIG_BATTERY_SWELLING=n
 
 #SENSOR
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tfn_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tfn_defconfig
index 0cbfcdb59899..f98d4d9d06a1 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tfn_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tfn_defconfig
@@ -38,7 +38,7 @@ CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
 CONFIG_MFD_RT5033_RESET_WA=y
 CONFIG_MFD_RT5033_SLDO_VBUSDET=n
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 CONFIG_BATTERY_SWELLING=n
 
 #SENSOR
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tmo_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tmo_defconfig
index 5a47aecd1eb8..1d0dc163feb0 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tmo_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna_tmo_defconfig
@@ -37,7 +37,7 @@ CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
 CONFIG_MFD_RT5033_RESET_WA=y
 CONFIG_MFD_RT5033_SLDO_VBUSDET=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 CONFIG_BATTERY_SWELLING=n
 
 #SENSOR
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
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna3g_eur_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna3g_eur_defconfig
index 152eaa91060f..6876c4c0e7ce 100644
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna3g_eur_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortuna3g_eur_defconfig
@@ -40,7 +40,7 @@ CONFIG_SAMSUNG_LPM_MODE=y
 CONFIG_CHARGER_RT5033=y
 CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 
 # VIBRATOR
 CONFIG_MSM_VIBRATOR=y
diff --git a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortunave3g_eur_defconfig b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortunave3g_eur_defconfig
index 83cdd8f8e0f0..f5281d05017a 100755
--- a/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortunave3g_eur_defconfig
+++ b/kernel/samsung/msm8916/arch/arm/configs/msm8916_sec_fortunave3g_eur_defconfig
@@ -41,7 +41,7 @@ CONFIG_SAMSUNG_LPM_MODE=y
 CONFIG_CHARGER_RT5033=y
 CONFIG_FUELGAUGE_RT5033=y
 CONFIG_REGULATOR_RT5033=y
-CONFIG_SIOP_CHARGING_LIMIT_CURRENT=700
+CONFIG_SIOP_CHARGING_LIMIT_CURRENT=1000
 
 #SENSOR
 CONFIG_SENSORS=y
FAST_C
fi
}

PATCHES=("${PATCHES[@]}" "extract_fast_charge_patch")
