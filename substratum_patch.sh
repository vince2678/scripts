#!/bin/bash

function extract_substratum_patch {
logb "\t\tExtracting Substratum patch..."
cat <<SUBS_P > ${PATCH_DIR}/substratum.patch
diff --git a/device/samsung/msm8916-common/product/substratum1.mk b/device/samsung/msm8916-common/product/substratum1.mk
new file mode 100644
index 0000000..3a163fe
--- /dev/null
+++ b/device/samsung/msm8916-common/product/substratum1.mk
@@ -0,0 +1,3 @@
+# Substratum
+PRODUCT_PACKAGES += \
+	Substratum
SUBS_P
}

PATCH_FUNCTIONS=("${PATCH_FUNCTIONS[@]}" "extract_substratum_patch")
