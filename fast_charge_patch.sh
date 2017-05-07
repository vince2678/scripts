
#!/bin/bash

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
+#define MINIMUM_INPUT_CURRENT			800
+#elif defined(CONFIG_SEC_J5_PROJECT) || defined(CONFIG_SEC_J5X_PROJECT) || defined(CONFIG_SEC_J5N_PROJECT)
+#define MINIMUM_INPUT_CURRENT			700
+#else
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

PATCH_FUNCTIONS=("${PATCH_FUNCTIONS[@]}" "extract_fast_charge_sm5703_patch")
