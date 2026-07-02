// ============================================================
// 模块名称: udp_tx_arbiter
// 功能描述: UDP发送仲裁模块
//           根据img_mode选择LED/数码管发送或图片发送
// ============================================================
module udp_tx_arbiter(
    input               img_mode,       // 0=LED/数码管模式, 1=图片发送模式

    // ===== LED/数码管发送模块接口 =====
    input               led_app_tx_data_request,
    input               led_app_tx_data_valid,
    input [7:0]         led_app_tx_data,
    input [15:0]        led_udp_data_length,

    // ===== 图片发送模块接口 =====
    input               img_app_tx_data_request,
    input               img_app_tx_data_valid,
    input [7:0]         img_app_tx_data,
    input [15:0]        img_udp_data_length,

    // ===== UDP协议栈接口（输出到协议栈）=====
    output              app_tx_data_request,
    output              app_tx_data_valid,
    output [7:0]        app_tx_data,
    output [15:0]       udp_data_length
);

// ============================================================================
// 仲裁逻辑：根据img_mode选择数据源
// ============================================================================

assign app_tx_data_request = img_mode ? img_app_tx_data_request : led_app_tx_data_request;
assign app_tx_data_valid   = img_mode ? img_app_tx_data_valid   : led_app_tx_data_valid;
assign app_tx_data         = img_mode ? img_app_tx_data         : led_app_tx_data;
assign udp_data_length     = img_mode ? img_udp_data_length     : led_udp_data_length;

endmodule
