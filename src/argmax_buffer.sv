module argmax_buffer #(
    parameter ADJ_DOT_PROD_WIDTH = 16,
    parameter DOT_PROD_COLS      = 3,
    parameter ARGMAX_ROWS        = 6,
    parameter ARGMAX_COLS = 2,
    parameter ARGMAX_WIDTH       = $clog2(ARGMAX_ROWS)
)(
    input  logic                          clk,
    input  logic                          reset,

    // Control signals
    input  logic                          is_read_row,
    input  logic                          is_increment_row_addr,

    // Data inputs
    input  logic [ADJ_DOT_PROD_WIDTH-1:0] ADJ_FM_WM_Row [0:DOT_PROD_COLS-1],
    input  logic [ARGMAX_COLS-1:0]       max_value,
    input  logic [ARGMAX_WIDTH-1:0]       ADJ_FM_WM_ROW_Counter,

    // Output registers
    output logic [ADJ_DOT_PROD_WIDTH-1:0] r_ADJ_FM_WM_Row [0:DOT_PROD_COLS-1],
    output logic [ARGMAX_COLS-1:0]       r_max_addi_ans  [0:ARGMAX_ROWS-1]
);

    // Reading the data

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < ARGMAX_ROWS; i++ ) begin
                r_ADJ_FM_WM_Row[i] <= 0;    
            end
        end
        else begin
            if (is_read_row) begin
                r_ADJ_FM_WM_Row <= ADJ_FM_WM_Row;
            end
            else begin
                for (int i = 0; i < ARGMAX_ROWS; i++ ) begin
                    r_ADJ_FM_WM_Row[i] <= 0;
                end
            end
        end
    end

    // Argmax Function
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            for (int i = 0; i < ARGMAX_ROWS; i++ ) begin
                r_max_addi_ans[i] <= 0;
            end
        end
        else begin
            if (is_increment_row_addr) begin
                r_max_addi_ans[ADJ_FM_WM_ROW_Counter] <= max_value;
            end
            else begin
                 r_max_addi_ans <= r_max_addi_ans;
            end
        end
    end


endmodule