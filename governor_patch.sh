function extract_governor_patch {
# save the source code to a temp file
if [ "$OVERCLOCKED" == "y" ]; then
logb "\t\tExtracting governor tunables patch..."
cat <<GOVERNOR_P > ${PATCH_DIR}/governor.patch
diff --git a/device/samsung/msm8916-common/rootdir/etc/init.qcom.post_boot.sh b/device/samsung/msm8916-common/rootdir/etc/init.qcom.post_boot.sh
index 289ced5..7a3fd44 100644
--- a/device/samsung/msm8916-common/rootdir/etc/init.qcom.post_boot.sh
+++ b/device/samsung/msm8916-common/rootdir/etc/init.qcom.post_boot.sh
@@ -604,9 +604,9 @@ case "$target" in
                 echo "25000 1094400:50000" > /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
                 echo 90 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
                 echo 30000 > /sys/devices/system/cpu/cpufreq/interactive/timer_rate
-                echo 998400 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
+                echo 1209600 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
                 echo 0 > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy
-                echo "1 200000:40 400000:50 533333:70 800000:82 998400:90 1094400:95 1209600:99" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
+                echo "1 200000:40 400000:50 533333:60 800000:75 998400:80 1094400:85 1209600:90 1363200:93 1401600:95 1478400:97 1612800:99" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
                 echo 50000 > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
                 echo 50000 > /sys/devices/system/cpu/cpufreq/interactive/max_freq_hysteresis
GOVERNOR_P
fi
}

PATCH_FUNCTIONS=("${PATCH_FUNCTIONS[@]}" "extract_governor_patch")
