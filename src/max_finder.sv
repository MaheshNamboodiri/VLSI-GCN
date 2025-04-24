module max_finder #(
    parameter ADJ_DOT_PROD_WIDTH = 16,
    parameter DOT_PROD_COLS      = 3,
    parameter ARGMAX_WIDTH       = $clog2(DOT_PROD_COLS)
)(
    input  logic                          clk,
    input  logic                          reset,
    input  logic                          is_read_row,

    input  logic [ADJ_DOT_PROD_WIDTH-1:0] ADJ_FM_WM_Row [0:DOT_PROD_COLS-1],
    input  logic [ADJ_DOT_PROD_WIDTH-1:0] r_ADJ_FM_WM_Row [0:DOT_PROD_COLS-1],

    output logic [1:0]                    max_index,
    output logic [ARGMAX_WIDTH-1:0]       max_value
);
    
     always @(posedge clk or posedge reset) begin
         if(reset) begin
                 max_index <= 0;
         end
         else begin
             if(is_read_row) begin
                 max_index <= ADJ_FM_WM_Row[0] > ADJ_FM_WM_Row [1] ? 0 : 1;
             end 
             else begin
                 max_index <= 0;
             end
         end
     end

    assign max_value = r_ADJ_FM_WM_Row[max_index] > r_ADJ_FM_WM_Row[2] ? max_index : 2;
    
endmodule