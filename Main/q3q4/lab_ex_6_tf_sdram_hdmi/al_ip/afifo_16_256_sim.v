// Verilog netlist created by Tang Dynasty v5.6.71036
// Wed Dec 13 10:37:12 2023

`timescale 1ns / 1ps
module afifo_16_256  // afifo_16_256.v(14)
  (
  clk,
  di,
  re,
  rst,
  we,
  do,
  empty_flag,
  full_flag,
  rdusedw,
  wrusedw
  );

  input clk;  // afifo_16_256.v(24)
  input [15:0] di;  // afifo_16_256.v(23)
  input re;  // afifo_16_256.v(25)
  input rst;  // afifo_16_256.v(22)
  input we;  // afifo_16_256.v(24)
  output [15:0] do;  // afifo_16_256.v(27)
  output empty_flag;  // afifo_16_256.v(28)
  output full_flag;  // afifo_16_256.v(29)
  output [8:0] rdusedw;  // afifo_16_256.v(30)
  output [8:0] wrusedw;  // afifo_16_256.v(31)

  wire logic_ramfifo_syn_1;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_2;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_3;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_4;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_5;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_6;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_7;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_8;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_9;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_10;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_11;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_12;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_13;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_14;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_15;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_16;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_17;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_18;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_19;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_20;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_21;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_22;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_23;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_24;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_25;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_26;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_27;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_37;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_38;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_39;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_40;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_41;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_42;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_43;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_44;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_45;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_46;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_47;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_48;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_49;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_50;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_51;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_52;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_53;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_54;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_55;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_56;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_57;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_58;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_59;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_60;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_61;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_62;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_64;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_65;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_66;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_67;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_68;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_69;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_70;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_71;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_72;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_73;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_74;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_75;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_76;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_77;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_78;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_79;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_80;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_81;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_82;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_83;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_84;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_85;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_86;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_87;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_88;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_89;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_128;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_130;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_134;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_135;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_136;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_137;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_138;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_139;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_140;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_141;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_142;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_143;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_147;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_149;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_179;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_199;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_200;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_201;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_202;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_203;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_204;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_205;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_206;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_207;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_223;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_225;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_227;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_229;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_231;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_233;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_235;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_237;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_242;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_244;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_246;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_248;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_250;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_252;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_254;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_258;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_260;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_262;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_264;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_266;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_268;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_270;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_272;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_277;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_279;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_281;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_283;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_285;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_287;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_289;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_461;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_462;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_463;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_464;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_465;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_466;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_467;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_468;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_469;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_470;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_471;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_472;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_473;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_474;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_475;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_476;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_477;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_515;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_516;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_517;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_518;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_519;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_520;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_521;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_522;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_523;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_524;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_525;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_526;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_527;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_528;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_529;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_530;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_531;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_570;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_571;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_572;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_573;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_574;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_575;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_576;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_577;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_578;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_618;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_619;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_620;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_621;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_622;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_623;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_624;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_625;  // afifo_16_256.v(39)
  wire logic_ramfifo_syn_626;  // afifo_16_256.v(39)
  wire clk_syn_1;  // afifo_16_256.v(24)
  wire clk_syn_2;  // afifo_16_256.v(24)
  wire clk_syn_3;  // afifo_16_256.v(24)
  wire clk_syn_4;  // afifo_16_256.v(24)
  wire clk_syn_5;  // afifo_16_256.v(24)
  wire clk_syn_6;  // afifo_16_256.v(24)
  wire clk_syn_7;  // afifo_16_256.v(24)
  wire clk_syn_8;  // afifo_16_256.v(24)
  wire clk_syn_9;  // afifo_16_256.v(24)
  wire clk_syn_10;  // afifo_16_256.v(24)
  wire clk_syn_12;  // afifo_16_256.v(24)
  wire clk_syn_14;  // afifo_16_256.v(24)
  wire clk_syn_16;  // afifo_16_256.v(24)
  wire clk_syn_18;  // afifo_16_256.v(24)
  wire clk_syn_20;  // afifo_16_256.v(24)
  wire clk_syn_22;  // afifo_16_256.v(24)
  wire clk_syn_24;  // afifo_16_256.v(24)
  wire clk_syn_26;  // afifo_16_256.v(24)
  wire clk_syn_28;  // afifo_16_256.v(24)
  wire clk_syn_34;  // afifo_16_256.v(24)
  wire clk_syn_36;  // afifo_16_256.v(24)
  wire clk_syn_38;  // afifo_16_256.v(24)
  wire clk_syn_40;  // afifo_16_256.v(24)
  wire clk_syn_42;  // afifo_16_256.v(24)
  wire clk_syn_44;  // afifo_16_256.v(24)
  wire clk_syn_46;  // afifo_16_256.v(24)
  wire clk_syn_48;  // afifo_16_256.v(24)
  wire clk_syn_50;  // afifo_16_256.v(24)
  wire clk_syn_52;  // afifo_16_256.v(24)
  wire clk_syn_54;  // afifo_16_256.v(24)
  wire clk_syn_56;  // afifo_16_256.v(24)
  wire clk_syn_58;  // afifo_16_256.v(24)
  wire clk_syn_60;  // afifo_16_256.v(24)
  wire clk_syn_62;  // afifo_16_256.v(24)
  wire clk_syn_64;  // afifo_16_256.v(24)
  wire clk_syn_66;  // afifo_16_256.v(24)
  wire clk_syn_67;  // afifo_16_256.v(24)
  wire clk_syn_68;  // afifo_16_256.v(24)
  wire clk_syn_69;  // afifo_16_256.v(24)
  wire clk_syn_70;  // afifo_16_256.v(24)
  wire clk_syn_71;  // afifo_16_256.v(24)
  wire clk_syn_72;  // afifo_16_256.v(24)
  wire clk_syn_73;  // afifo_16_256.v(24)
  wire clk_syn_74;  // afifo_16_256.v(24)
  wire clk_syn_75;  // afifo_16_256.v(24)
  wire clk_syn_76;  // afifo_16_256.v(24)
  wire clk_syn_78;  // afifo_16_256.v(24)
  wire clk_syn_79;  // afifo_16_256.v(24)
  wire clk_syn_80;  // afifo_16_256.v(24)
  wire clk_syn_81;  // afifo_16_256.v(24)
  wire clk_syn_82;  // afifo_16_256.v(24)
  wire clk_syn_83;  // afifo_16_256.v(24)
  wire clk_syn_84;  // afifo_16_256.v(24)
  wire clk_syn_85;  // afifo_16_256.v(24)
  wire clk_syn_86;  // afifo_16_256.v(24)
  wire clk_syn_87;  // afifo_16_256.v(24)
  wire clk_syn_89;  // afifo_16_256.v(24)
  wire clk_syn_93;  // afifo_16_256.v(24)
  wire clk_syn_95;  // afifo_16_256.v(24)
  wire clk_syn_97;  // afifo_16_256.v(24)
  wire clk_syn_99;  // afifo_16_256.v(24)
  wire clk_syn_101;  // afifo_16_256.v(24)
  wire clk_syn_103;  // afifo_16_256.v(24)
  wire clk_syn_105;  // afifo_16_256.v(24)
  wire clk_syn_107;  // afifo_16_256.v(24)
  wire clk_syn_111;  // afifo_16_256.v(24)
  wire clk_syn_113;  // afifo_16_256.v(24)
  wire clk_syn_115;  // afifo_16_256.v(24)
  wire clk_syn_117;  // afifo_16_256.v(24)
  wire clk_syn_119;  // afifo_16_256.v(24)
  wire clk_syn_121;  // afifo_16_256.v(24)
  wire clk_syn_123;  // afifo_16_256.v(24)
  wire clk_syn_125;  // afifo_16_256.v(24)
  wire clk_syn_127;  // afifo_16_256.v(24)
  wire clk_syn_129;  // afifo_16_256.v(24)
  wire clk_syn_131;  // afifo_16_256.v(24)
  wire clk_syn_133;  // afifo_16_256.v(24)
  wire clk_syn_135;  // afifo_16_256.v(24)
  wire clk_syn_137;  // afifo_16_256.v(24)
  wire clk_syn_139;  // afifo_16_256.v(24)
  wire clk_syn_141;  // afifo_16_256.v(24)
  wire clk_syn_143;  // afifo_16_256.v(24)
  wire clk_syn_144;  // afifo_16_256.v(24)
  wire clk_syn_145;  // afifo_16_256.v(24)
  wire clk_syn_146;  // afifo_16_256.v(24)
  wire clk_syn_147;  // afifo_16_256.v(24)
  wire clk_syn_148;  // afifo_16_256.v(24)
  wire clk_syn_149;  // afifo_16_256.v(24)
  wire clk_syn_150;  // afifo_16_256.v(24)
  wire clk_syn_151;  // afifo_16_256.v(24)
  wire clk_syn_152;  // afifo_16_256.v(24)
  wire clk_syn_153;  // afifo_16_256.v(24)
  wire re_syn_2;  // afifo_16_256.v(25)
  wire we_syn_2;  // afifo_16_256.v(24)
  wire _al_n1_syn_4;
  wire _al_n1_syn_6;
  wire _al_n1_syn_8;
  wire _al_n1_syn_10;
  wire _al_n1_syn_12;
  wire _al_n1_syn_14;
  wire _al_n1_syn_16;
  wire _al_n1_syn_24;
  wire _al_n1_syn_26;
  wire _al_n1_syn_28;
  wire _al_n1_syn_30;
  wire _al_n1_syn_32;
  wire _al_n1_syn_34;
  wire _al_n1_syn_36;

  and _al_n1_syn_11 (_al_n1_syn_12, _al_n1_syn_10, clk_syn_24);
  and _al_n1_syn_13 (_al_n1_syn_14, _al_n1_syn_12, clk_syn_26);
  and _al_n1_syn_15 (_al_n1_syn_16, _al_n1_syn_14, clk_syn_28);
  and _al_n1_syn_23 (_al_n1_syn_24, clk_syn_107, clk_syn_93);
  and _al_n1_syn_25 (_al_n1_syn_26, _al_n1_syn_24, clk_syn_95);
  and _al_n1_syn_27 (_al_n1_syn_28, _al_n1_syn_26, clk_syn_97);
  and _al_n1_syn_29 (_al_n1_syn_30, _al_n1_syn_28, clk_syn_99);
  and _al_n1_syn_3 (_al_n1_syn_4, clk_syn_14, clk_syn_16);
  and _al_n1_syn_31 (_al_n1_syn_32, _al_n1_syn_30, clk_syn_101);
  and _al_n1_syn_33 (_al_n1_syn_34, _al_n1_syn_32, clk_syn_103);
  and _al_n1_syn_35 (_al_n1_syn_36, _al_n1_syn_34, clk_syn_105);
  and _al_n1_syn_5 (_al_n1_syn_6, _al_n1_syn_4, clk_syn_18);
  and _al_n1_syn_7 (_al_n1_syn_8, _al_n1_syn_6, clk_syn_20);
  and _al_n1_syn_9 (_al_n1_syn_10, _al_n1_syn_8, clk_syn_22);
  not clk_syn_100 (clk_syn_101, clk_syn_83);  // afifo_16_256.v(24)
  not clk_syn_102 (clk_syn_103, clk_syn_84);  // afifo_16_256.v(24)
  not clk_syn_104 (clk_syn_105, clk_syn_85);  // afifo_16_256.v(24)
  not clk_syn_106 (clk_syn_107, clk_syn_78);  // afifo_16_256.v(24)
  or clk_syn_11 (clk_syn_12, clk_syn_10, clk_syn_9);  // afifo_16_256.v(24)
  xor clk_syn_110 (clk_syn_111, clk_syn_79, clk_syn_78);  // afifo_16_256.v(24)
  and clk_syn_112 (clk_syn_113, clk_syn_79, clk_syn_107);  // afifo_16_256.v(24)
  xor clk_syn_114 (clk_syn_115, clk_syn_80, clk_syn_113);  // afifo_16_256.v(24)
  and clk_syn_116 (clk_syn_117, clk_syn_80, _al_n1_syn_24);  // afifo_16_256.v(24)
  xor clk_syn_118 (clk_syn_119, clk_syn_81, clk_syn_117);  // afifo_16_256.v(24)
  and clk_syn_120 (clk_syn_121, clk_syn_81, _al_n1_syn_26);  // afifo_16_256.v(24)
  xor clk_syn_122 (clk_syn_123, clk_syn_82, clk_syn_121);  // afifo_16_256.v(24)
  and clk_syn_124 (clk_syn_125, clk_syn_82, _al_n1_syn_28);  // afifo_16_256.v(24)
  xor clk_syn_126 (clk_syn_127, clk_syn_83, clk_syn_125);  // afifo_16_256.v(24)
  and clk_syn_128 (clk_syn_129, clk_syn_83, _al_n1_syn_30);  // afifo_16_256.v(24)
  not clk_syn_13 (clk_syn_14, clk_syn_1);  // afifo_16_256.v(24)
  xor clk_syn_130 (clk_syn_131, clk_syn_84, clk_syn_129);  // afifo_16_256.v(24)
  and clk_syn_132 (clk_syn_133, clk_syn_84, _al_n1_syn_32);  // afifo_16_256.v(24)
  xor clk_syn_134 (clk_syn_135, clk_syn_85, clk_syn_133);  // afifo_16_256.v(24)
  and clk_syn_136 (clk_syn_137, clk_syn_85, _al_n1_syn_34);  // afifo_16_256.v(24)
  xor clk_syn_138 (clk_syn_139, clk_syn_86, clk_syn_137);  // afifo_16_256.v(24)
  and clk_syn_140 (clk_syn_141, clk_syn_89, _al_n1_syn_36);  // afifo_16_256.v(24)
  xor clk_syn_142 (clk_syn_143, clk_syn_87, clk_syn_141);  // afifo_16_256.v(24)
  not clk_syn_15 (clk_syn_16, clk_syn_2);  // afifo_16_256.v(24)
  not clk_syn_17 (clk_syn_18, clk_syn_3);  // afifo_16_256.v(24)
  not clk_syn_19 (clk_syn_20, clk_syn_4);  // afifo_16_256.v(24)
  not clk_syn_21 (clk_syn_22, clk_syn_5);  // afifo_16_256.v(24)
  not clk_syn_23 (clk_syn_24, clk_syn_6);  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_232 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_67),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_1));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_233 (
    .ar(1'b0),
    .as(rst),
    .clk(clk),
    .d(clk_syn_68),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_2));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_234 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_69),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_3));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_235 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_70),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_4));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_236 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_71),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_5));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_237 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_72),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_6));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_238 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_73),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_7));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_239 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_74),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_8));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_240 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_75),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_9));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_241 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_76),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_10));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_242 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_144),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_78));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_243 (
    .ar(1'b0),
    .as(rst),
    .clk(clk),
    .d(clk_syn_145),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_79));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_244 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_146),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_80));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_245 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_147),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_81));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_246 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_148),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_82));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_247 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_149),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_83));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_248 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_150),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_84));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_249 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_151),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_85));  // afifo_16_256.v(24)
  not clk_syn_25 (clk_syn_26, clk_syn_7);  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_250 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_152),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_86));  // afifo_16_256.v(24)
  AL_DFF_X clk_syn_251 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(clk_syn_153),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(clk_syn_87));  // afifo_16_256.v(24)
  not clk_syn_27 (clk_syn_28, clk_syn_8);  // afifo_16_256.v(24)
  xor clk_syn_33 (clk_syn_34, clk_syn_2, clk_syn_1);  // afifo_16_256.v(24)
  and clk_syn_35 (clk_syn_36, clk_syn_2, clk_syn_14);  // afifo_16_256.v(24)
  xor clk_syn_37 (clk_syn_38, clk_syn_3, clk_syn_36);  // afifo_16_256.v(24)
  and clk_syn_39 (clk_syn_40, clk_syn_3, _al_n1_syn_4);  // afifo_16_256.v(24)
  xor clk_syn_41 (clk_syn_42, clk_syn_4, clk_syn_40);  // afifo_16_256.v(24)
  and clk_syn_43 (clk_syn_44, clk_syn_4, _al_n1_syn_6);  // afifo_16_256.v(24)
  xor clk_syn_45 (clk_syn_46, clk_syn_5, clk_syn_44);  // afifo_16_256.v(24)
  and clk_syn_47 (clk_syn_48, clk_syn_5, _al_n1_syn_8);  // afifo_16_256.v(24)
  xor clk_syn_49 (clk_syn_50, clk_syn_6, clk_syn_48);  // afifo_16_256.v(24)
  and clk_syn_51 (clk_syn_52, clk_syn_6, _al_n1_syn_10);  // afifo_16_256.v(24)
  xor clk_syn_53 (clk_syn_54, clk_syn_7, clk_syn_52);  // afifo_16_256.v(24)
  and clk_syn_55 (clk_syn_56, clk_syn_7, _al_n1_syn_12);  // afifo_16_256.v(24)
  xor clk_syn_57 (clk_syn_58, clk_syn_8, clk_syn_56);  // afifo_16_256.v(24)
  and clk_syn_59 (clk_syn_60, clk_syn_8, _al_n1_syn_14);  // afifo_16_256.v(24)
  xor clk_syn_61 (clk_syn_62, clk_syn_9, clk_syn_60);  // afifo_16_256.v(24)
  and clk_syn_63 (clk_syn_64, clk_syn_12, _al_n1_syn_16);  // afifo_16_256.v(24)
  xor clk_syn_65 (clk_syn_66, clk_syn_10, clk_syn_64);  // afifo_16_256.v(24)
  or clk_syn_88 (clk_syn_89, clk_syn_87, clk_syn_86);  // afifo_16_256.v(24)
  not clk_syn_92 (clk_syn_93, clk_syn_79);  // afifo_16_256.v(24)
  not clk_syn_94 (clk_syn_95, clk_syn_80);  // afifo_16_256.v(24)
  not clk_syn_96 (clk_syn_97, clk_syn_81);  // afifo_16_256.v(24)
  not clk_syn_98 (clk_syn_99, clk_syn_82);  // afifo_16_256.v(24)
  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  not logic_ramfifo_syn_127 (logic_ramfifo_syn_128, logic_ramfifo_syn_44);  // afifo_16_256.v(39)
  not logic_ramfifo_syn_129 (logic_ramfifo_syn_130, logic_ramfifo_syn_45);  // afifo_16_256.v(39)
  not logic_ramfifo_syn_133 (logic_ramfifo_syn_134, full_flag);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_146 (logic_ramfifo_syn_147, logic_ramfifo_syn_27, logic_ramfifo_syn_26);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_148 (logic_ramfifo_syn_149, logic_ramfifo_syn_9, logic_ramfifo_syn_8);  // afifo_16_256.v(39)
  not logic_ramfifo_syn_178 (logic_ramfifo_syn_179, empty_flag);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_222 (logic_ramfifo_syn_223, logic_ramfifo_syn_45, logic_ramfifo_syn_44);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_224 (logic_ramfifo_syn_225, logic_ramfifo_syn_223, logic_ramfifo_syn_43);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_226 (logic_ramfifo_syn_227, logic_ramfifo_syn_225, logic_ramfifo_syn_42);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_228 (logic_ramfifo_syn_229, logic_ramfifo_syn_227, logic_ramfifo_syn_41);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_230 (logic_ramfifo_syn_231, logic_ramfifo_syn_229, logic_ramfifo_syn_40);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_232 (logic_ramfifo_syn_233, logic_ramfifo_syn_231, logic_ramfifo_syn_39);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_234 (logic_ramfifo_syn_235, logic_ramfifo_syn_233, logic_ramfifo_syn_38);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_236 (logic_ramfifo_syn_237, logic_ramfifo_syn_235, logic_ramfifo_syn_37);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_241 (logic_ramfifo_syn_242, logic_ramfifo_syn_149, logic_ramfifo_syn_7);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_243 (logic_ramfifo_syn_244, logic_ramfifo_syn_242, logic_ramfifo_syn_6);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_245 (logic_ramfifo_syn_246, logic_ramfifo_syn_244, logic_ramfifo_syn_5);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_247 (logic_ramfifo_syn_248, logic_ramfifo_syn_246, logic_ramfifo_syn_4);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_249 (logic_ramfifo_syn_250, logic_ramfifo_syn_248, logic_ramfifo_syn_3);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_251 (logic_ramfifo_syn_252, logic_ramfifo_syn_250, logic_ramfifo_syn_2);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_253 (logic_ramfifo_syn_254, logic_ramfifo_syn_252, logic_ramfifo_syn_1);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_257 (logic_ramfifo_syn_258, logic_ramfifo_syn_72, logic_ramfifo_syn_71);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_259 (logic_ramfifo_syn_260, logic_ramfifo_syn_258, logic_ramfifo_syn_70);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_261 (logic_ramfifo_syn_262, logic_ramfifo_syn_260, logic_ramfifo_syn_69);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_263 (logic_ramfifo_syn_264, logic_ramfifo_syn_262, logic_ramfifo_syn_68);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_265 (logic_ramfifo_syn_266, logic_ramfifo_syn_264, logic_ramfifo_syn_67);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_267 (logic_ramfifo_syn_268, logic_ramfifo_syn_266, logic_ramfifo_syn_66);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_269 (logic_ramfifo_syn_270, logic_ramfifo_syn_268, logic_ramfifo_syn_65);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_271 (logic_ramfifo_syn_272, logic_ramfifo_syn_270, logic_ramfifo_syn_64);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_276 (logic_ramfifo_syn_277, logic_ramfifo_syn_147, logic_ramfifo_syn_25);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_278 (logic_ramfifo_syn_279, logic_ramfifo_syn_277, logic_ramfifo_syn_24);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_280 (logic_ramfifo_syn_281, logic_ramfifo_syn_279, logic_ramfifo_syn_23);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_282 (logic_ramfifo_syn_283, logic_ramfifo_syn_281, logic_ramfifo_syn_22);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_284 (logic_ramfifo_syn_285, logic_ramfifo_syn_283, logic_ramfifo_syn_21);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_286 (logic_ramfifo_syn_287, logic_ramfifo_syn_285, logic_ramfifo_syn_20);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_288 (logic_ramfifo_syn_289, logic_ramfifo_syn_287, logic_ramfifo_syn_19);  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_314 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_135),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_1));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_315 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_136),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_2));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_316 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_137),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_3));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_317 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_138),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_4));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_318 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_139),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_5));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_319 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_140),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_6));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_320 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_141),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_7));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_321 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_142),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_8));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_322 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_143),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_9));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_323 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_1),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_10));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_324 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_2),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_11));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_325 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_3),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_12));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_326 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_4),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_13));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_327 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_5),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_14));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_328 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_6),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_15));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_329 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_7),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_16));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_330 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_8),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_17));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_331 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_9),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_18));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_335 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_199),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_19));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_336 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_200),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_20));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_337 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_201),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_21));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_338 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_202),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_22));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_339 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_203),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_23));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_340 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_204),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_24));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_341 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_205),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_25));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_342 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_206),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_26));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_343 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_207),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_27));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_353 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_19),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_37));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_354 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_20),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_38));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_355 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_21),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_39));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_356 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_22),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_40));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_357 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_23),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_41));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_358 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_24),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_42));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_359 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_25),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_43));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_360 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_26),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_44));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_361 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_27),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_45));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_362 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_237),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_46));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_363 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_235),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_47));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_364 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_233),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_48));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_365 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_231),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_49));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_366 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_229),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_50));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_367 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_227),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_51));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_368 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_225),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_52));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_369 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_223),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_53));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_370 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_45),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_54));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_371 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_254),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_55));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_372 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_252),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_56));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_373 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_250),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_57));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_374 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_248),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_58));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_375 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_246),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_59));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_376 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_244),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_60));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_377 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_242),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_61));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_378 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_149),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_62));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_380 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_10),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_64));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_381 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_11),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_65));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_382 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_12),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_66));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_383 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_13),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_67));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_384 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_14),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_68));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_385 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_15),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_69));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_386 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_16),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_70));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_387 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_17),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_71));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_388 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_18),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_72));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_389 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_272),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_73));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_390 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_270),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_74));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_391 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_268),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_75));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_392 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_266),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_76));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_393 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_264),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_77));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_394 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_262),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_78));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_395 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_260),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_79));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_396 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_258),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_80));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_397 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_72),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_81));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_398 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_289),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_82));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_399 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_287),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_83));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_400 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_285),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_84));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_401 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_283),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_85));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_402 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_281),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_86));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_403 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_279),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_87));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_404 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_277),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_88));  // afifo_16_256.v(39)
  AL_DFF_X logic_ramfifo_syn_405 (
    .ar(rst),
    .as(1'b0),
    .clk(clk),
    .d(logic_ramfifo_syn_147),
    .en(1'b1),
    .sr(1'b0),
    .ss(1'b0),
    .q(logic_ramfifo_syn_89));  // afifo_16_256.v(39)
  // address_offset=0;data_offset=0;depth=256;width=16;num_section=1;width_per_section=16;section_size=16;working_depth=512;working_width=18;working_numbyte=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  // logic_ramfifo_syn_291_256x16
  EG_PHY_BRAM #(
    .CEBMUX("1"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("SIG"),
    .DATA_WIDTH_A("18"),
    .DATA_WIDTH_B("18"),
    .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_10(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_11(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_12(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_13(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_14(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_15(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_16(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_17(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_18(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_19(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1A(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1B(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1C(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1D(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1E(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1F(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .MODE("PDPW8K"),
    .OCEAMUX("1"),
    .OCEBMUX("1"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .WEAMUX("1"),
    .WEBMUX("0"),
    .WRITEMODE_A("NORMAL"),
    .WRITEMODE_B("NORMAL"))
    logic_ramfifo_syn_407 (
    .addra({1'b0,logic_ramfifo_syn_149,logic_ramfifo_syn_7,logic_ramfifo_syn_6,logic_ramfifo_syn_5,logic_ramfifo_syn_4,logic_ramfifo_syn_3,logic_ramfifo_syn_2,logic_ramfifo_syn_1,4'b1111}),
    .addrb({1'b0,logic_ramfifo_syn_147,logic_ramfifo_syn_25,logic_ramfifo_syn_24,logic_ramfifo_syn_23,logic_ramfifo_syn_22,logic_ramfifo_syn_21,logic_ramfifo_syn_20,logic_ramfifo_syn_19,4'b1111}),
    .cea(we_syn_2),
    .clka(clk),
    .clkb(clk),
    .csb({re_syn_2,open_n51,open_n52}),
    .dia(di[8:0]),
    .dib({open_n53,open_n54,di[15:9]}),
    .rsta(rst),
    .rstb(rst),
    .doa(do[8:0]),
    .dob({open_n59,open_n60,do[15:9]}));  // afifo_16_256.v(39)
  not logic_ramfifo_syn_424 (full_flag, logic_ramfifo_syn_477);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_425 (logic_ramfifo_syn_461, logic_ramfifo_syn_1, logic_ramfifo_syn_37);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_426 (logic_ramfifo_syn_462, logic_ramfifo_syn_2, logic_ramfifo_syn_38);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_427 (logic_ramfifo_syn_463, logic_ramfifo_syn_3, logic_ramfifo_syn_39);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_428 (logic_ramfifo_syn_464, logic_ramfifo_syn_4, logic_ramfifo_syn_40);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_429 (logic_ramfifo_syn_465, logic_ramfifo_syn_5, logic_ramfifo_syn_41);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_430 (logic_ramfifo_syn_466, logic_ramfifo_syn_6, logic_ramfifo_syn_42);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_431 (logic_ramfifo_syn_467, logic_ramfifo_syn_7, logic_ramfifo_syn_43);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_432 (logic_ramfifo_syn_468, logic_ramfifo_syn_8, logic_ramfifo_syn_128);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_433 (logic_ramfifo_syn_469, logic_ramfifo_syn_9, logic_ramfifo_syn_130);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_434 (logic_ramfifo_syn_470, logic_ramfifo_syn_461, logic_ramfifo_syn_462);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_435 (logic_ramfifo_syn_471, logic_ramfifo_syn_463, logic_ramfifo_syn_464);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_436 (logic_ramfifo_syn_472, logic_ramfifo_syn_470, logic_ramfifo_syn_471);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_437 (logic_ramfifo_syn_473, logic_ramfifo_syn_465, logic_ramfifo_syn_466);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_438 (logic_ramfifo_syn_474, logic_ramfifo_syn_468, logic_ramfifo_syn_469);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_439 (logic_ramfifo_syn_475, logic_ramfifo_syn_467, logic_ramfifo_syn_474);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_440 (logic_ramfifo_syn_476, logic_ramfifo_syn_473, logic_ramfifo_syn_475);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_441 (logic_ramfifo_syn_477, logic_ramfifo_syn_472, logic_ramfifo_syn_476);  // afifo_16_256.v(39)
  not logic_ramfifo_syn_478 (empty_flag, logic_ramfifo_syn_531);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_479 (logic_ramfifo_syn_515, logic_ramfifo_syn_64, logic_ramfifo_syn_19);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_480 (logic_ramfifo_syn_516, logic_ramfifo_syn_65, logic_ramfifo_syn_20);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_481 (logic_ramfifo_syn_517, logic_ramfifo_syn_66, logic_ramfifo_syn_21);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_482 (logic_ramfifo_syn_518, logic_ramfifo_syn_67, logic_ramfifo_syn_22);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_483 (logic_ramfifo_syn_519, logic_ramfifo_syn_68, logic_ramfifo_syn_23);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_484 (logic_ramfifo_syn_520, logic_ramfifo_syn_69, logic_ramfifo_syn_24);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_485 (logic_ramfifo_syn_521, logic_ramfifo_syn_70, logic_ramfifo_syn_25);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_486 (logic_ramfifo_syn_522, logic_ramfifo_syn_71, logic_ramfifo_syn_26);  // afifo_16_256.v(39)
  xor logic_ramfifo_syn_487 (logic_ramfifo_syn_523, logic_ramfifo_syn_72, logic_ramfifo_syn_27);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_488 (logic_ramfifo_syn_524, logic_ramfifo_syn_515, logic_ramfifo_syn_516);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_489 (logic_ramfifo_syn_525, logic_ramfifo_syn_517, logic_ramfifo_syn_518);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_490 (logic_ramfifo_syn_526, logic_ramfifo_syn_524, logic_ramfifo_syn_525);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_491 (logic_ramfifo_syn_527, logic_ramfifo_syn_519, logic_ramfifo_syn_520);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_492 (logic_ramfifo_syn_528, logic_ramfifo_syn_522, logic_ramfifo_syn_523);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_493 (logic_ramfifo_syn_529, logic_ramfifo_syn_521, logic_ramfifo_syn_528);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_494 (logic_ramfifo_syn_530, logic_ramfifo_syn_527, logic_ramfifo_syn_529);  // afifo_16_256.v(39)
  or logic_ramfifo_syn_495 (logic_ramfifo_syn_531, logic_ramfifo_syn_526, logic_ramfifo_syn_530);  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB_CARRY"))
    logic_ramfifo_syn_532 (
    .a(1'b0),
    .o({logic_ramfifo_syn_570,open_n63}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_533 (
    .a(logic_ramfifo_syn_55),
    .b(logic_ramfifo_syn_46),
    .c(logic_ramfifo_syn_570),
    .o({logic_ramfifo_syn_571,wrusedw[0]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_534 (
    .a(logic_ramfifo_syn_56),
    .b(logic_ramfifo_syn_47),
    .c(logic_ramfifo_syn_571),
    .o({logic_ramfifo_syn_572,wrusedw[1]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_535 (
    .a(logic_ramfifo_syn_57),
    .b(logic_ramfifo_syn_48),
    .c(logic_ramfifo_syn_572),
    .o({logic_ramfifo_syn_573,wrusedw[2]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_536 (
    .a(logic_ramfifo_syn_58),
    .b(logic_ramfifo_syn_49),
    .c(logic_ramfifo_syn_573),
    .o({logic_ramfifo_syn_574,wrusedw[3]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_537 (
    .a(logic_ramfifo_syn_59),
    .b(logic_ramfifo_syn_50),
    .c(logic_ramfifo_syn_574),
    .o({logic_ramfifo_syn_575,wrusedw[4]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_538 (
    .a(logic_ramfifo_syn_60),
    .b(logic_ramfifo_syn_51),
    .c(logic_ramfifo_syn_575),
    .o({logic_ramfifo_syn_576,wrusedw[5]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_539 (
    .a(logic_ramfifo_syn_61),
    .b(logic_ramfifo_syn_52),
    .c(logic_ramfifo_syn_576),
    .o({logic_ramfifo_syn_577,wrusedw[6]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_540 (
    .a(logic_ramfifo_syn_62),
    .b(logic_ramfifo_syn_53),
    .c(logic_ramfifo_syn_577),
    .o({logic_ramfifo_syn_578,wrusedw[7]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_541 (
    .a(logic_ramfifo_syn_18),
    .b(logic_ramfifo_syn_54),
    .c(logic_ramfifo_syn_578),
    .o({open_n64,wrusedw[8]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB_CARRY"))
    logic_ramfifo_syn_580 (
    .a(1'b0),
    .o({logic_ramfifo_syn_618,open_n67}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_581 (
    .a(logic_ramfifo_syn_73),
    .b(logic_ramfifo_syn_82),
    .c(logic_ramfifo_syn_618),
    .o({logic_ramfifo_syn_619,rdusedw[0]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_582 (
    .a(logic_ramfifo_syn_74),
    .b(logic_ramfifo_syn_83),
    .c(logic_ramfifo_syn_619),
    .o({logic_ramfifo_syn_620,rdusedw[1]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_583 (
    .a(logic_ramfifo_syn_75),
    .b(logic_ramfifo_syn_84),
    .c(logic_ramfifo_syn_620),
    .o({logic_ramfifo_syn_621,rdusedw[2]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_584 (
    .a(logic_ramfifo_syn_76),
    .b(logic_ramfifo_syn_85),
    .c(logic_ramfifo_syn_621),
    .o({logic_ramfifo_syn_622,rdusedw[3]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_585 (
    .a(logic_ramfifo_syn_77),
    .b(logic_ramfifo_syn_86),
    .c(logic_ramfifo_syn_622),
    .o({logic_ramfifo_syn_623,rdusedw[4]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_586 (
    .a(logic_ramfifo_syn_78),
    .b(logic_ramfifo_syn_87),
    .c(logic_ramfifo_syn_623),
    .o({logic_ramfifo_syn_624,rdusedw[5]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_587 (
    .a(logic_ramfifo_syn_79),
    .b(logic_ramfifo_syn_88),
    .c(logic_ramfifo_syn_624),
    .o({logic_ramfifo_syn_625,rdusedw[6]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_588 (
    .a(logic_ramfifo_syn_80),
    .b(logic_ramfifo_syn_89),
    .c(logic_ramfifo_syn_625),
    .o({logic_ramfifo_syn_626,rdusedw[7]}));  // afifo_16_256.v(39)
  AL_MAP_ADDER #(
    .ALUTYPE("SUB"))
    logic_ramfifo_syn_589 (
    .a(logic_ramfifo_syn_81),
    .b(logic_ramfifo_syn_45),
    .c(logic_ramfifo_syn_626),
    .o({open_n68,rdusedw[8]}));  // afifo_16_256.v(39)
  and re_syn_1 (re_syn_2, re, logic_ramfifo_syn_179);  // afifo_16_256.v(25)
  AL_MUX re_syn_257 (
    .i0(clk_syn_78),
    .i1(clk_syn_107),
    .sel(re_syn_2),
    .o(clk_syn_144));  // afifo_16_256.v(25)
  AL_MUX re_syn_262 (
    .i0(clk_syn_79),
    .i1(clk_syn_111),
    .sel(re_syn_2),
    .o(clk_syn_145));  // afifo_16_256.v(25)
  AL_MUX re_syn_267 (
    .i0(clk_syn_80),
    .i1(clk_syn_115),
    .sel(re_syn_2),
    .o(clk_syn_146));  // afifo_16_256.v(25)
  AL_MUX re_syn_272 (
    .i0(clk_syn_81),
    .i1(clk_syn_119),
    .sel(re_syn_2),
    .o(clk_syn_147));  // afifo_16_256.v(25)
  AL_MUX re_syn_277 (
    .i0(clk_syn_82),
    .i1(clk_syn_123),
    .sel(re_syn_2),
    .o(clk_syn_148));  // afifo_16_256.v(25)
  AL_MUX re_syn_282 (
    .i0(clk_syn_83),
    .i1(clk_syn_127),
    .sel(re_syn_2),
    .o(clk_syn_149));  // afifo_16_256.v(25)
  AL_MUX re_syn_287 (
    .i0(clk_syn_84),
    .i1(clk_syn_131),
    .sel(re_syn_2),
    .o(clk_syn_150));  // afifo_16_256.v(25)
  AL_MUX re_syn_292 (
    .i0(clk_syn_85),
    .i1(clk_syn_135),
    .sel(re_syn_2),
    .o(clk_syn_151));  // afifo_16_256.v(25)
  AL_MUX re_syn_297 (
    .i0(clk_syn_86),
    .i1(clk_syn_139),
    .sel(re_syn_2),
    .o(clk_syn_152));  // afifo_16_256.v(25)
  AL_MUX re_syn_302 (
    .i0(clk_syn_87),
    .i1(clk_syn_143),
    .sel(re_syn_2),
    .o(clk_syn_153));  // afifo_16_256.v(25)
  AL_MUX re_syn_307 (
    .i0(logic_ramfifo_syn_19),
    .i1(clk_syn_79),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_199));  // afifo_16_256.v(25)
  AL_MUX re_syn_312 (
    .i0(logic_ramfifo_syn_20),
    .i1(clk_syn_80),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_200));  // afifo_16_256.v(25)
  AL_MUX re_syn_317 (
    .i0(logic_ramfifo_syn_21),
    .i1(clk_syn_81),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_201));  // afifo_16_256.v(25)
  AL_MUX re_syn_322 (
    .i0(logic_ramfifo_syn_22),
    .i1(clk_syn_82),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_202));  // afifo_16_256.v(25)
  AL_MUX re_syn_327 (
    .i0(logic_ramfifo_syn_23),
    .i1(clk_syn_83),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_203));  // afifo_16_256.v(25)
  AL_MUX re_syn_332 (
    .i0(logic_ramfifo_syn_24),
    .i1(clk_syn_84),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_204));  // afifo_16_256.v(25)
  AL_MUX re_syn_337 (
    .i0(logic_ramfifo_syn_25),
    .i1(clk_syn_85),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_205));  // afifo_16_256.v(25)
  AL_MUX re_syn_342 (
    .i0(logic_ramfifo_syn_26),
    .i1(clk_syn_86),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_206));  // afifo_16_256.v(25)
  AL_MUX re_syn_347 (
    .i0(logic_ramfifo_syn_27),
    .i1(clk_syn_87),
    .sel(re_syn_2),
    .o(logic_ramfifo_syn_207));  // afifo_16_256.v(25)
  and we_syn_1 (we_syn_2, we, logic_ramfifo_syn_134);  // afifo_16_256.v(24)
  AL_MUX we_syn_104 (
    .i0(logic_ramfifo_syn_7),
    .i1(clk_syn_8),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_141));  // afifo_16_256.v(24)
  AL_MUX we_syn_109 (
    .i0(logic_ramfifo_syn_8),
    .i1(clk_syn_9),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_142));  // afifo_16_256.v(24)
  AL_MUX we_syn_114 (
    .i0(logic_ramfifo_syn_9),
    .i1(clk_syn_10),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_143));  // afifo_16_256.v(24)
  AL_MUX we_syn_24 (
    .i0(clk_syn_1),
    .i1(clk_syn_14),
    .sel(we_syn_2),
    .o(clk_syn_67));  // afifo_16_256.v(24)
  AL_MUX we_syn_29 (
    .i0(clk_syn_2),
    .i1(clk_syn_34),
    .sel(we_syn_2),
    .o(clk_syn_68));  // afifo_16_256.v(24)
  AL_MUX we_syn_34 (
    .i0(clk_syn_3),
    .i1(clk_syn_38),
    .sel(we_syn_2),
    .o(clk_syn_69));  // afifo_16_256.v(24)
  AL_MUX we_syn_39 (
    .i0(clk_syn_4),
    .i1(clk_syn_42),
    .sel(we_syn_2),
    .o(clk_syn_70));  // afifo_16_256.v(24)
  AL_MUX we_syn_44 (
    .i0(clk_syn_5),
    .i1(clk_syn_46),
    .sel(we_syn_2),
    .o(clk_syn_71));  // afifo_16_256.v(24)
  AL_MUX we_syn_49 (
    .i0(clk_syn_6),
    .i1(clk_syn_50),
    .sel(we_syn_2),
    .o(clk_syn_72));  // afifo_16_256.v(24)
  AL_MUX we_syn_54 (
    .i0(clk_syn_7),
    .i1(clk_syn_54),
    .sel(we_syn_2),
    .o(clk_syn_73));  // afifo_16_256.v(24)
  AL_MUX we_syn_59 (
    .i0(clk_syn_8),
    .i1(clk_syn_58),
    .sel(we_syn_2),
    .o(clk_syn_74));  // afifo_16_256.v(24)
  AL_MUX we_syn_64 (
    .i0(clk_syn_9),
    .i1(clk_syn_62),
    .sel(we_syn_2),
    .o(clk_syn_75));  // afifo_16_256.v(24)
  AL_MUX we_syn_69 (
    .i0(clk_syn_10),
    .i1(clk_syn_66),
    .sel(we_syn_2),
    .o(clk_syn_76));  // afifo_16_256.v(24)
  AL_MUX we_syn_74 (
    .i0(logic_ramfifo_syn_1),
    .i1(clk_syn_2),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_135));  // afifo_16_256.v(24)
  AL_MUX we_syn_79 (
    .i0(logic_ramfifo_syn_2),
    .i1(clk_syn_3),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_136));  // afifo_16_256.v(24)
  AL_MUX we_syn_84 (
    .i0(logic_ramfifo_syn_3),
    .i1(clk_syn_4),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_137));  // afifo_16_256.v(24)
  AL_MUX we_syn_89 (
    .i0(logic_ramfifo_syn_4),
    .i1(clk_syn_5),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_138));  // afifo_16_256.v(24)
  AL_MUX we_syn_94 (
    .i0(logic_ramfifo_syn_5),
    .i1(clk_syn_6),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_139));  // afifo_16_256.v(24)
  AL_MUX we_syn_99 (
    .i0(logic_ramfifo_syn_6),
    .i1(clk_syn_7),
    .sel(we_syn_2),
    .o(logic_ramfifo_syn_140));  // afifo_16_256.v(24)

endmodule 

