// =============================================================================
// Power-On Reset (POR) Generator
// 作用: 产生一个足够长的复位脉冲 (约 1.3ms @ 50MHz)，以等待外部晶振稳定。
// =============================================================================
module por_generator (
    input   clk_50,        // 必须是来自外部的原始时钟
    output  reg por_reset_n  // 输出：上电后为 '0'，稳定后变为 '1'
);

    reg [15:0] por_count = 16'd0;
    
    initial begin
        por_reset_n = 1'b0; // 确保上电时复位有效
    end

    always @(posedge clk_50) begin
        if (por_count != 16'hFFFF) begin // 计数到 65535
            por_count <= por_count + 1'b1;
            por_reset_n <= 1'b0; // 保持复位
        end else begin
            por_reset_n <= 1'b1; // 释放复位
        end
    end

endmodule