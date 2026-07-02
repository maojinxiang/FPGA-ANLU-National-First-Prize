`timescale 1ns / 1ps
//********************************************************************************
// Module: sdram_arbiter
// Function: SDRAM访问仲裁器 - 在两个frame_read_write实例之间切换
//           确保两个工程的SDRAM访问完全隔离，互不干扰
//********************************************************************************
module sdram_arbiter #(
    parameter ADDR_BITS = 21,
    parameter DATA_BITS = 32,
    parameter ADDR_OFFSET_PROJECT1 = 21'd307200  // q3v3工程的地址偏移
)(
    // 模式选择信号
    input                           mode_project,       // 0: bp12_2,  1: q3v3

    // bp12_2 工程的 frame_read_write 接口（项目0）
    input                           prj0_App_rd_en,
    input  [ADDR_BITS-1:0]          prj0_App_rd_addr,
    input                           prj0_App_wr_en,
    input  [ADDR_BITS-1:0]          prj0_App_wr_addr,
    input  [DATA_BITS-1:0]          prj0_App_wr_din,
    input  [3:0]                    prj0_App_wr_dm,
    output                          prj0_Sdr_rd_en,
    output [DATA_BITS-1:0]          prj0_Sdr_rd_dout,

    // q3v3 工程的 frame_read_write 接口（项目1）
    input                           prj1_App_rd_en,
    input  [ADDR_BITS-1:0]          prj1_App_rd_addr,
    input                           prj1_App_wr_en,
    input  [ADDR_BITS-1:0]          prj1_App_wr_addr,
    input  [DATA_BITS-1:0]          prj1_App_wr_din,
    input  [3:0]                    prj1_App_wr_dm,
    output                          prj1_Sdr_rd_en,
    output [DATA_BITS-1:0]          prj1_Sdr_rd_dout,

    // 连接到真实 SDRAM 控制器的接口
    output                          sdram_App_rd_en,
    output [ADDR_BITS-1:0]          sdram_App_rd_addr,
    output                          sdram_App_wr_en,
    output [ADDR_BITS-1:0]          sdram_App_wr_addr,
    output [DATA_BITS-1:0]          sdram_App_wr_din,
    output [3:0]                    sdram_App_wr_dm,
    input                           sdram_Sdr_rd_en,
    input  [DATA_BITS-1:0]          sdram_Sdr_rd_dout
);

    // ========================================================================
    // 写接口仲裁（带地址偏移）
    // ========================================================================
    assign sdram_App_wr_en = mode_project ? prj1_App_wr_en : prj0_App_wr_en;

    // bp12_2: 直接使用原地址（0~307199）
    // q3v3:   地址加偏移（307200~614399）
    assign sdram_App_wr_addr = mode_project ?
                               (prj1_App_wr_addr + ADDR_OFFSET_PROJECT1) :
                               prj0_App_wr_addr;

    assign sdram_App_wr_din  = mode_project ? prj1_App_wr_din  : prj0_App_wr_din;
    assign sdram_App_wr_dm   = mode_project ? prj1_App_wr_dm   : prj0_App_wr_dm;

    // ========================================================================
    // 读接口仲裁（带地址偏移）
    // ========================================================================
    assign sdram_App_rd_en = mode_project ? prj1_App_rd_en : prj0_App_rd_en;

    // bp12_2: 直接使用原地址（0~307199）
    // q3v3:   地址加偏移（307200~614399）
    assign sdram_App_rd_addr = mode_project ?
                               (prj1_App_rd_addr + ADDR_OFFSET_PROJECT1) :
                               prj0_App_rd_addr;

    // ========================================================================
    // 读数据回传（分发到对应的工程）
    // ========================================================================
    assign prj0_Sdr_rd_en   = mode_project ? 1'b0 : sdram_Sdr_rd_en;
    assign prj0_Sdr_rd_dout = mode_project ? {DATA_BITS{1'b0}} : sdram_Sdr_rd_dout;

    assign prj1_Sdr_rd_en   = mode_project ? sdram_Sdr_rd_en : 1'b0;
    assign prj1_Sdr_rd_dout = mode_project ? sdram_Sdr_rd_dout : {DATA_BITS{1'b0}};

endmodule
