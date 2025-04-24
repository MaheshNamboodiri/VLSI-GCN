module ADJ_FM_WM_Write_To_Mem #(
    parameter DOT_PROD_COLS = 3,
    parameter ADJ_DOT_PROD_WIDTH = 16
)(
    input  logic clk,
    input  logic reset,
    input  logic is_write_result_to_mem,
    input  logic [ADJ_DOT_PROD_WIDTH-1:0] adj_fm_wm_write_data [0:DOT_PROD_COLS-1],
    output logic [ADJ_DOT_PROD_WIDTH-1:0] ADJ_FM_WM_Row [0:DOT_PROD_COLS-1]
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int j = 0; j < DOT_PROD_COLS; j++) begin
                ADJ_FM_WM_Row[j] <= '0;
            end
        end else if (is_write_result_to_mem) begin
            ADJ_FM_WM_Row <= adj_fm_wm_write_data;
        end
    end

endmodule
