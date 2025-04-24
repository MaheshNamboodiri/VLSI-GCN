module argmax_function #(
    parameter FEATURE_ROWS          = 6,
    parameter WEIGHT_COLS           = 3,
    parameter FEATURE_COLS          = 96,
    parameter WEIGHT_ROWS           = 96,    
    parameter COUNTER_WEIGHT_WIDTH  = $clog2(WEIGHT_COLS),
    parameter COUNTER_FEATURE_WIDTH = $clog2(FEATURE_ROWS),
    parameter DOT_PROD_WIDTH        = 16,
    parameter ADDRESS_WIDTH         = 13,
    parameter WEIGHT_WIDTH          = 5,
    parameter NUM_OF_NODES          = 6,
    parameter COO_NUM_OF_COLS       = 6,
    parameter COO_NUM_OF_ROWS       = 2,
    parameter COO_BW                = $clog2(COO_NUM_OF_COLS),
    parameter DOT_PROD_ROWS         = 6,
    parameter DOT_PROD_COLS         = 3,
    parameter FEATURE_WIDTH         = $clog2(FEATURE_ROWS),
    parameter DOT_PROD_ROWS_WIDTH   = $clog2(DOT_PROD_ROWS),
    parameter ROW_COL_ADDRESS_MIN   = 3'h0,
    parameter ROW_COL_ADDRESS_MAX   = 3'h5,
    parameter ADJ_DOT_PROD_WIDTH    = 16,
    parameter ARGMAX_COLS = 2,
    parameter ARGMAX_ROWS = 6,
    parameter ARGMAX_WIDTH = $clog2(ARGMAX_ROWS)
) 
(
    input  logic                              clk,
    input  logic                              reset,
    input  logic                              done_comb,                                // Indicates that the combination is complete.
    input  logic [ADJ_DOT_PROD_WIDTH-1:0]     ADJ_FM_WM_Row    [0:DOT_PROD_COLS-1],     // Input row data from ADJ_FM_WM memory
    
    output logic [FEATURE_WIDTH-1:0]          read_row_ADJ_FM_WM,                       // Address of Row data requested by argmax
    output logic [ARGMAX_COLS-1:0]     max_addi_ans[0:ARGMAX_ROWS-1],                  // Argmax output
    output logic                              done_arg                                      // Indicates argmax is done
);

    logic [ADJ_DOT_PROD_WIDTH-1:0] r_ADJ_FM_WM_Row [0:DOT_PROD_COLS-1]; // Receive row data from ADJ_FM_WM memory
    logic [ARGMAX_WIDTH-1:0] ADJ_FM_WM_ROW_Counter;
    logic [ARGMAX_COLS-1:0] r_max_addi_ans [0:ARGMAX_ROWS-1];
    logic [ARGMAX_COLS-1:0] max_value;
    logic [1:0] max_index;
    logic is_idle;
    logic is_read_row;
    logic is_increment_row_addr; 
    logic is_done;

    assign max_addi_ans = r_max_addi_ans;
    
    // Address Counter
    address_counter #(
        .MAX_COUNT(ARGMAX_ROWS)
    ) ADJ_FM_WM_row_address_counter(
        .clk(clk),
        .reset(reset),
        .increment_address_valid(is_increment_row_addr),
        .count(ADJ_FM_WM_ROW_Counter)
    );
    
    // Address to access the ADJ_FM_WM matrix data from memory
    assign read_row_ADJ_FM_WM = (is_read_row) ? ADJ_FM_WM_ROW_Counter : 0;
    
    
    argmax_buffer #(
        .ADJ_DOT_PROD_WIDTH(ADJ_DOT_PROD_WIDTH),
        .DOT_PROD_COLS(DOT_PROD_COLS),
        .ARGMAX_ROWS(ARGMAX_ROWS),
        .ARGMAX_COLS(ARGMAX_COLS),
        .ARGMAX_WIDTH(ARGMAX_WIDTH)
    ) argmax_buf_inst (
        .clk(clk),
        .reset(reset),
        .is_read_row(is_read_row),
        .is_increment_row_addr(is_increment_row_addr),
        .ADJ_FM_WM_Row(ADJ_FM_WM_Row),
        .max_value(max_value),
        .ADJ_FM_WM_ROW_Counter(ADJ_FM_WM_ROW_Counter),
        .r_ADJ_FM_WM_Row(r_ADJ_FM_WM_Row),
        .r_max_addi_ans(r_max_addi_ans)
    );


    //  Logic to calculate maximum value between 2 values
    
    max_finder #(
        .ADJ_DOT_PROD_WIDTH(ADJ_DOT_PROD_WIDTH),
        .DOT_PROD_COLS(DOT_PROD_COLS)
//        .ARGMAX_WIDTH(ARGMAX_WIDTH)
    ) max_finder_inst (
        .clk(clk),
        .reset(reset),
        .is_read_row(is_read_row),
        .ADJ_FM_WM_Row(ADJ_FM_WM_Row),
        .r_ADJ_FM_WM_Row(r_ADJ_FM_WM_Row),
        .max_index(max_index),
        .max_value(max_value)
    );
    

//    assign max_value = r_ADJ_FM_WM_Row[max_index] > r_ADJ_FM_WM_Row[2] ? max_index : 2;
    

//     always @(posedge clk or posedge reset) begin
//         if(reset) begin
//                 max_index <= 0;
//         end
//         else begin
//             if(is_read_row) begin
//                 max_index <= ADJ_FM_WM_Row[0] > ADJ_FM_WM_Row [1] ? 0 : 1;
//             end 
//             else begin
//                 max_index <= 0;
//             end
//         end
//     end


    // FSM

    argmax_fsm #(
        .ARGMAX_ROWS(ARGMAX_ROWS),
        .ARGMAX_WIDTH(ARGMAX_WIDTH)
    ) argmax_function_fsm (
        .clk(clk),
        .reset(reset),
        .done_comb(done_comb),
        .ADJ_FM_WM_ROW_Counter(ADJ_FM_WM_ROW_Counter),
        .done_arg(done_arg),
        .is_idle(is_idle),
        .is_read_row(is_read_row),
        .is_increment_row_addr(is_increment_row_addr),
        .is_done(is_done)
    );    


endmodule
