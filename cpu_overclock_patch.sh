#!/bin/bash

function extract_cpu_oc_patch {
# save the source code to a temp file
if [ "$OVERCLOCKED" == "y" ]; then
cat <<CPUOC > ${PATCH_DIR}/cpu.patch
diff --git a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-regulator.dtsi b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-regulator.dtsi
index b293ca44a982..a678de488ba3 100644
--- a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-regulator.dtsi
+++ b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-regulator.dtsi
@@ -18,7 +18,7 @@
 			regulator-name = "8916_s2";
 			reg = <0x1700 0x100>;
 			regulator-min-microvolt = <1050000>;
-			regulator-max-microvolt = <1350000>;
+			regulator-max-microvolt = <1375000>;
 		};
 	};
 };
@@ -50,10 +50,10 @@
 		regulator-name = "apc_corner";
 		qcom,cpr-fuse-corners = <3>;
 		regulator-min-microvolt = <1>;
-		regulator-max-microvolt = <8>;
+		regulator-max-microvolt = <12>;
 
-		qcom,cpr-voltage-ceiling = <1050000 1150000 1350000>;
-		qcom,cpr-voltage-floor = <1050000 1150000 1350000>;
+		qcom,cpr-voltage-ceiling = <1050000 1150000 1375000>;
+		qcom,cpr-voltage-floor = <1050000 1150000 1375000>;
 		vdd-apc-supply = <&pm8916_s2>;
 
 		qcom,vdd-mx-corner-map = <4 5 7>;
@@ -85,9 +85,9 @@
 					<27 36 6 0>,
 					<27 18 6 0>,
 					<27 0 6 0>;
-		qcom,cpr-init-voltage-ref = <1050000 1150000 1350000>;
+		qcom,cpr-init-voltage-ref = <1050000 1150000 1375000>;
 		qcom,cpr-init-voltage-step = <10000>;
-		qcom,cpr-corner-map = <1 1 2 2 3 3 3 3>;
+		qcom,cpr-corner-map = <1 1 2 2 3 3 3 3 3 3 3 3>;
 		qcom,cpr-corner-frequency-map =
 					<1 200000000>,
 					<2 400000000>,
@@ -97,13 +97,16 @@
 					<6 1094400000>,
 					<7 1152000000>,
 					<8 1209600000>,
-					<9 1363200000>;
+					<9 1363200000>,
+					<10 1401600000>,
+					<11 1478400000>,
+					<12 1612800000>;
 		qcom,speed-bin-fuse-sel = <1 34 3 0>;
 		qcom,pvs-version-fuse-sel = <0 55 2 0>;
 		qcom,cpr-speed-bin-max-corners =
-					<0 0 2 4 8>,
+					<0 0 2 4 12>,
 					<0 1 2 4 7>,
-					<2 0 2 4 9>,
+					<2 0 2 4 12>,
 					<3 0 2 4 5>,
 					<3 1 2 4 5>;
 		qcom,cpr-quot-adjust-scaling-factor-max = <650>;
diff --git a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi
index 48e6add51c46..296cee794c5a 100755
--- a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi
+++ b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi
@@ -381,7 +381,11 @@
 			<  998400000 5>,
 			< 1094400000 6>,
 			< 1152000000 7>,
-			< 1209600000 8>;
+			< 1209600000 8>,
+			< 1363200000 9>,
+			< 1401600000 10>,
+			< 1478400000 11>,
+			< 1612800000 12>;
 
 		qcom,speed1-bin-v0 =
 			<          0 0>,
@@ -410,7 +414,11 @@
 			<  998400000 5>,
 			< 1094400000 6>,
 			< 1152000000 7>,
-			< 1209600000 8>;
+			< 1209600000 8>,
+			< 1363200000 9>,
+			< 1401600000 10>,
+			< 1478400000 11>,
+			< 1612800000 12>;
 
 		qcom,speed2-bin-v1 =
 			<          0 0>,
@@ -422,7 +430,10 @@
 			< 1094400000 6>,
 			< 1152000000 7>,
 			< 1209600000 8>,
-			< 1363200000 9>;
+			< 1363200000 9>,
+			< 1401600000 10>,
+			< 1478400000 11>,
+			< 1612800000 12>;
 
 		qcom,speed3-bin-v1 =
 			<          0 0>,
@@ -483,7 +494,10 @@
 			 < 1094400 >,
 			 < 1152000 >,
 			 < 1209600 >,
-			 < 1363200 >;
+			 < 1363200 >,
+			 < 1401600 >,
+			 < 1478400 >,
+			 < 1612800 >;
 	};
 
 	qcom,sps {
diff --git a/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c b/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c
index 194ecca0066a..099c43ff370e 100644
--- a/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c
+++ b/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c
@@ -349,6 +349,8 @@ static struct pll_freq_tbl apcs_pll_freq[] = {
 	F_APCS_PLL(1248000000, 65, 0x0, 0x1, 0x0, 0x0, 0x0),
 	F_APCS_PLL(1363200000, 71, 0x0, 0x1, 0x0, 0x0, 0x0),
 	F_APCS_PLL(1401600000, 73, 0x0, 0x1, 0x0, 0x0, 0x0),
+	F_APCS_PLL(1478400000, 77, 0x0, 0x1, 0x0, 0x0, 0x0),
+	F_APCS_PLL(1612800000, 84, 0x0, 0x1, 0x0, 0x0, 0x0),
 	PLL_F_END
 };
CPUOC
fi
}

PATCHES=("${PATCHES[@]}" "extract_cpu_oc_patch")
