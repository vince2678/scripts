#!/bin/bash

function check_oc_enabled {
ARG="--oc"
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "$ARG" ]; then
		logr "Overclocking is enabled"
		OVERCLOCKED=y
	fi
done
}

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

function extract_gpu_oc_patch {
if [ "$OVERCLOCKED" == "y" ]; then
cat <<GPUOC > ${PATCH_DIR}/gpu.patch
diff --git a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-gpu.dtsi b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-gpu.dtsi
index 089b3c2..4985125 100644
--- a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-gpu.dtsi
+++ b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916-gpu.dtsi
@@ -16,9 +16,10 @@
 		compatible = "qcom,kgsl-3d0", "qcom,kgsl-3d";
 		reg = <0x01c00000 0x10000
 		       0x01c10000 0x10000
-		       0x0005c000 0x204>;
+		       0x0005c000 0x204
+		       0x0005c00c 0x8>;
 		reg-names = "kgsl_3d0_reg_memory" , "kgsl_3d0_shader_memory" ,
-			    "qfprom_memory";
+			    "qfprom_memory", "efuse_memory";
 		interrupts = <0 33 0>;
 		interrupt-names = "kgsl_3d0_irq";
 		qcom,id = <0>;
@@ -84,26 +85,50 @@
 
 			qcom,gpu-pwrlevel@0 {
 				reg = <0>;
-				qcom,gpu-freq = <400000000>;
+				qcom,gpu-freq = <650000000>;
 				qcom,bus-freq = <3>;
 			};
 
 			qcom,gpu-pwrlevel@1 {
 				reg = <1>;
-				qcom,gpu-freq = <310000000>;
-				qcom,bus-freq = <2>;
+				qcom,gpu-freq = <550000000>;
+				qcom,bus-freq = <3>;
 			};
 
 			qcom,gpu-pwrlevel@2 {
 				reg = <2>;
-				qcom,gpu-freq = <200000000>;
-				qcom,bus-freq = <1>;
+				qcom,gpu-freq = <475000000>;
+				qcom,bus-freq = <3>;
 			};
 
 			qcom,gpu-pwrlevel@3 {
 				reg = <3>;
-				qcom,gpu-freq = <19200000>;
-				qcom,bus-freq = <0>;
+				qcom,gpu-freq = <400000000>;
+				qcom,bus-freq = <3>;
+			};
+
+			qcom,gpu-pwrlevel@4 {
+				reg = <4>;
+				qcom,gpu-freq = <310000000>;
+				qcom,bus-freq = <3>;
+			};
+
+			qcom,gpu-pwrlevel@5 {
+				reg = <5>;
+				qcom,gpu-freq = <200000000>;
+				qcom,bus-freq = <2>;
+			};
+
+			qcom,gpu-pwrlevel@6 {
+				reg = <6>;
+				qcom,gpu-freq = <192000000>;
+				qcom,bus-freq = <1>;
+			};
+
+			qcom,gpu-pwrlevel@7 {
+				reg = <7>;
+				qcom,gpu-freq = <100000000>;
+				qcom,bus-freq = <1>;
 			};
 		};
 		/* Speed levels */
@@ -128,26 +153,50 @@
 
 				qcom,gpu-pwrlevel@0 {
 					reg = <0>;
-					qcom,gpu-freq = <465000000>;
+					qcom,gpu-freq = <650000000>;
 					qcom,bus-freq = <3>;
 				};
 
 				qcom,gpu-pwrlevel@1 {
 					reg = <1>;
-					qcom,gpu-freq = <310000000>;
-					qcom,bus-freq = <2>;
+					qcom,gpu-freq = <550000000>;
+					qcom,bus-freq = <3>;
 				};
 
 				qcom,gpu-pwrlevel@2 {
 					reg = <2>;
-					qcom,gpu-freq = <200000000>;
-					qcom,bus-freq = <1>;
+					qcom,gpu-freq = <475000000>;
+					qcom,bus-freq = <3>;
 				};
 
 				qcom,gpu-pwrlevel@3 {
 					reg = <3>;
-					qcom,gpu-freq = <19200000>;
-					qcom,bus-freq = <0>;
+					qcom,gpu-freq = <400000000>;
+					qcom,bus-freq = <3>;
+				};
+
+				qcom,gpu-pwrlevel@4 {
+					reg = <4>;
+					qcom,gpu-freq = <310000000>;
+					qcom,bus-freq = <3>;
+				};
+
+				qcom,gpu-pwrlevel@5 {
+					reg = <5>;
+					qcom,gpu-freq = <200000000>;
+					qcom,bus-freq = <2>;
+				};
+
+				qcom,gpu-pwrlevel@6 {
+					reg = <6>;
+					qcom,gpu-freq = <192000000>;
+					qcom,bus-freq = <1>;
+				};
+
+				qcom,gpu-pwrlevel@7 {
+					reg = <7>;
+					qcom,gpu-freq = <100000000>;
+					qcom,bus-freq = <1>;
 				};
 			};
 		};
diff --git a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi
index 48e6add..0f54c8c 100755
--- a/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi
+++ b/kernel/samsung/msm8916/arch/arm/boot/dts/samsung/msm8916/msm8916.dtsi
@@ -1561,7 +1561,7 @@
 		reg = <0x78b5000 0x600>;
 		interrupt-names = "qup_irq";
 		interrupts = <0 95 0>;
-		qcom,clk-freq-out = <100000>;
+		qcom,clk-freq-out = <400000>;
 		qcom,clk-freq-in  = <19200000>;
 		clock-names = "iface_clk", "core_clk";
 		clocks = <&clock_gcc clk_gcc_blsp1_ahb_clk>,
diff --git a/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c b/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c
index 194ecca..55f7170 100644
--- a/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c
+++ b/kernel/samsung/msm8916/drivers/clk/qcom/clock-gcc-8916.c
@@ -553,7 +553,9 @@ static struct clk_freq_tbl ftbl_gcc_camss_vfe0_clk[] = {
 	F( 266670000,	   gpll0,   3,	  0,	0),
 	F( 320000000,	   gpll0, 2.5,	  0,	0),
 	F( 400000000,	   gpll0,   2,	  0,	0),
-	F( 465000000,	   gpll2,   2,	  0,	0),
+	F( 475000000,      gpll2,   2,	  0,	0),
+	F( 550000000,      gpll2,   2,	  0,	0),
+	F( 650000000,      gpll2,   2,	  0,	0),
 	F_END
 };
 
@@ -567,7 +569,7 @@ static struct rcg_clk vfe0_clk_src = {
 		.dbg_name = "vfe0_clk_src",
 		.ops = &clk_ops_rcg,
 		VDD_DIG_FMAX_MAP3(LOW, 160000000, NOMINAL, 320000000, HIGH,
-			465000000),
+			650000000),
 		CLK_INIT(vfe0_clk_src.c),
 	},
 };
@@ -600,6 +602,9 @@ static struct clk_freq_tbl ftbl_gcc_oxili_gfx3d_clk[] = {
 	F( 294912000,	   gpll1,   3,	  0,	0),
 	F( 310000000,	   gpll2,   3,	  0,	0),
 	F( 400000000,  gpll0_aux,   2,	  0,	0),
+	F( 475000000,      gpll2,   2,	  0,	0),
+	F( 550000000,      gpll2,   2,	  0,	0),
+	F( 650000000,      gpll2,   2,	  0,	0),
 	F_END
 };
 
@@ -612,8 +617,8 @@ static struct rcg_clk gfx3d_clk_src = {
 	.c = {
 		.dbg_name = "gfx3d_clk_src",
 		.ops = &clk_ops_rcg,
-		VDD_DIG_FMAX_MAP3(LOW, 200000000, NOMINAL, 310000000, HIGH,
-			400000000),
+		VDD_DIG_FMAX_MAP3(LOW, 100000000, NOMINAL, 310000000, HIGH,
+			650000000),
 		CLK_INIT(gfx3d_clk_src.c),
 	},
 };
@@ -998,7 +1003,7 @@ static struct rcg_clk csi1phytimer_clk_src = {
 static struct clk_freq_tbl ftbl_gcc_camss_cpp_clk[] = {
 	F( 160000000,	   gpll0,   5,	  0,	0),
 	F( 320000000,	   gpll0, 2.5,	  0,	0),
-	F( 465000000,	   gpll2,   2,	  0,	0),
+	F( 650000000,	   gpll2,   2,	  0,	0),
 	F_END
 };
 
@@ -1012,7 +1017,7 @@ static struct rcg_clk cpp_clk_src = {
 		.dbg_name = "cpp_clk_src",
 		.ops = &clk_ops_rcg,
 		VDD_DIG_FMAX_MAP3(LOW, 160000000, NOMINAL, 320000000, HIGH,
-			465000000),
+			650000000),
 		CLK_INIT(cpp_clk_src.c),
 	},
 };
@@ -1192,7 +1197,9 @@ static struct clk_freq_tbl ftbl_gcc_sdcc1_apps_clk[] = {
 	F(  25000000,	   gpll0,  16,	  1,	2),
 	F(  50000000,	   gpll0,  16,	  0,	0),
 	F( 100000000,	   gpll0,   8,	  0,	0),
+	F( 160000000,	   gpll0,   5,	  0,	0),
 	F( 177770000,	   gpll0, 4.5,	  0,	0),
+	F( 200000000,	   gpll0,   4,	  0,	0),
 	F_END
 };
 
@@ -1217,6 +1224,8 @@ static struct clk_freq_tbl ftbl_gcc_sdcc2_apps_clk[] = {
 	F(  25000000,	   gpll0,  16,	  1,	2),
 	F(  50000000,	   gpll0,  16,	  0,	0),
 	F( 100000000,	   gpll0,   8,	  0,	0),
+	F( 160000000,	   gpll0,   5,	  0,	0),
+	F( 177770000,	   gpll0, 4.5,	  0,	0),
 	F( 200000000,	   gpll0,   4,	  0,	0),
 	F_END
 };
GPUOC
fi
}

PATCHES=("${PATCHES[@]}" "check_oc_enabled")
PATCHES=("${PATCHES[@]}" "extract_cpu_oc_patch")
PATCHES=("${PATCHES[@]}" "extract_gpu_oc_patch")
