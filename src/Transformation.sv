module Transformation #(
    parameter FEATURE_ROWS = 6,
    parameter WEIGHT_COLS = 3,
    parameter FEATURE_COLS = 96,
    parameter WEIGHT_ROWS = 96,    
    // $clog2 returns the minimum width to represent the number in binary.
    parameter COUNTER_WEIGHT_WIDTH = $clog2(WEIGHT_COLS),
    parameter COUNTER_FEATURE_WIDTH = $clog2(FEATURE_ROWS),
    /* 
    Each value is a 5-bit number, causing each partial product to have a 10-bit value. The maximum 5-bit value is 31
    Since there are 96 partial products, the maximum possible value of the dot product = (31*31) * 96 = 92256, which is a 17-bit number!
    Hence, the following value is 16!
    */
    parameter DOT_PROD_WIDTH = 16,
    parameter ADDRESS_WIDTH = 13,
    parameter WEIGHT_WIDTH = 5,
    parameter WEIGHT_ADDRESS_MAX = 12'hFF,
    parameter FEATURE_ADDRESS_MAX = 12'h2FF,
    parameter WEIGHT_ADDRESS_MIN = 12'h0,
    parameter FEATURE_ADDRESS_MIN = 12'h200,
    parameter DOT_PROD_ROWS_WIDTH = 3
) 
(
    input  logic                          clk,
    input  logic                          reset,
    input  logic                          start,                                  // Kicks off the transformation
    input  logic [WEIGHT_WIDTH-1:0]       data_in [0:WEIGHT_ROWS-1],              // FM and WM Data, arrives one by one (row/column)
    input  logic [DOT_PROD_ROWS_WIDTH-1:0]read_row,                               // Received from combinational block
    
    output logic [ADDRESS_WIDTH-1:0]      read_address,                           // Address to read FM and WM Data
    output logic [DOT_PROD_WIDTH-1:0]     FM_WM_Row [0:WEIGHT_COLS-1],            // Output row of product, as per read_address
    output logic                          read_enable,                            // Enable signal for reading weights and features
    output logic                          done                                     // Indicates multiplication is done
);

    // FSM Variables
    logic                             enable_write_fm_wm_prod;
    logic                             enable_read;
    logic                             enable_write;
    logic                             enable_scratch_pad;
    logic                             enable_weight_counter;
    logic                             enable_feature_counter;
    logic                             read_feature_or_weight;
    
    // Scratchpad variable: stores the current weight column.
    logic [WEIGHT_WIDTH-1:0]          weight_col_out [0:WEIGHT_ROWS-1];
    
    // Dot product output storage
    logic [DOT_PROD_WIDTH-1:0]        fm_wm_row_out  [0:WEIGHT_COLS-1];
    
    // Counter registers, used to calculate addresses and index matrix memory to store product of multiplication.
    logic [COUNTER_WEIGHT_WIDTH-1:0]  weight_count;
    logic [COUNTER_FEATURE_WIDTH-1:0] feature_count;
    logic [COUNTER_WEIGHT_WIDTH-1:0]  r_weight_count;
    logic [COUNTER_FEATURE_WIDTH-1:0] r_feature_count;
    
    // Vector Multiplier variables
    logic [DOT_PROD_WIDTH-1:0]        fm_wm_partial_product [0:FEATURE_COLS-1];
    logic [DOT_PROD_WIDTH-1:0]        dot_product_result;
    
    // Control signals
    logic                             read_weights_valid;
    logic                             read_features_valid;
    logic                             increment_feature_address_valid;
    logic                             increment_weight_address_valid;
    
    // To test pipelining. 
//    logic                             done_first_trans;
    
//    assign done = (feature_count>1)?1:0;
    
    
    // Assigns:
        
    assign feature_count                  = r_feature_count;
    assign weight_count                   = r_weight_count;
    assign read_enable                    = enable_read;
    
    assign increment_weight_address_valid  = (
        enable_weight_counter
    );
    
    assign increment_feature_address_valid = (
        enable_write_fm_wm_prod &
        enable_feature_counter     &
        read_feature_or_weight
    );
    
    assign read_features_valid = (
        enable_read &
        read_feature_or_weight
    );
    
    assign read_weights_valid = (
        enable_read &
        enable_scratch_pad
    );
    
    // Address calculation, done by using counters with minumum address value. Addresses are fixed to be linearly increasing.
    assign read_address = read_weights_valid  ? (WEIGHT_ADDRESS_MIN + weight_count) :
                          read_features_valid ? (FEATURE_ADDRESS_MIN + feature_count) :
                                                 read_address;

    //////////////////////////////////////////////////////////////////////
    ///////////////////// Module Instantiations //////////////////////////
    //////////////////////////////////////////////////////////////////////
                              

    // Vector Multiplier  

    vector_multiplier #(
        .VECTOR_LEN(FEATURE_COLS),
        .IN_WIDTH(WEIGHT_WIDTH),
        .OUT_WIDTH(DOT_PROD_WIDTH)
    ) dot_prod_inst (
        .clk(clk),
        .reset(reset),
        .valid(read_features_valid),
        .a(weight_col_out),
        .b(data_in),
        .result(dot_product_result)
    );

    // Feature Counter
                                                                 
    address_counter #(
        .MAX_COUNT(FEATURE_ROWS)
    ) feature_counter (
        .clk(clk),
        .reset(reset),
        .increment_address_valid(increment_feature_address_valid),
        .count(r_feature_count)
    );

    // Weight Counter
    address_counter #(
        .MAX_COUNT(WEIGHT_COLS)
    ) weight_counter (
        .clk(clk),
        .reset(reset),
        .increment_address_valid(increment_weight_address_valid),
        .count(r_weight_count)
    );    
        
    // FSM Block that serialises the operation states.

    Transformation_FSM #(
        .FEATURE_ROWS(FEATURE_ROWS),
        .WEIGHT_COLS(WEIGHT_COLS),
        .COUNTER_WEIGHT_WIDTH(COUNTER_WEIGHT_WIDTH),
        .COUNTER_FEATURE_WIDTH(COUNTER_FEATURE_WIDTH)
    ) u_Transformation_FSM (
        .clk(clk),
        .reset(reset),
        .weight_count(weight_count),
        .feature_count(feature_count),
        .start(start),
        .enable_write_fm_wm_prod(enable_write_fm_wm_prod),
        .enable_read(enable_read),
        .enable_write(enable_write),
        .enable_scratch_pad(enable_scratch_pad),
        .enable_weight_counter(enable_weight_counter),
        .enable_feature_counter(enable_feature_counter),
        .read_feature_or_weight(read_feature_or_weight),
        .done(done)
//        .done(done_first_trans)
    );

    // Scratchpad, which stores the weights' columns

    Scratch_Pad #(
        .WEIGHT_ROWS(96),
        .WEIGHT_WIDTH(5)
    ) u_Scratch_Pad (
        .clk(clk),
        .reset(reset),
        .write_enable(enable_scratch_pad), // Scratchpad is enabled to begin to read.
        // Connect data_in to weight_col_in.
        .weight_col_in(data_in), 
        // Weight columns stored.
        .weight_col_out(weight_col_out) 
    );


    // Matrix Memory, Stores the result of vector multiplication.

    Matrix_FM_WM_Memory #(
        .FEATURE_ROWS(FEATURE_ROWS),
        .WEIGHT_COLS(WEIGHT_COLS),
        .DOT_PROD_WIDTH(16),
        .ADDRESS_WIDTH(13),
        .WEIGHT_WIDTH($clog2(WEIGHT_COLS)),
        .FEATURE_WIDTH($clog2(FEATURE_ROWS))
    ) u_Matrix_FM_WM_Memory (
        .clk(clk),
        .rst(reset),
        .write_row(feature_count), 
        .write_col(weight_count), 
        .read_row(read_row),   
        .wr_en(enable_write_fm_wm_prod), // This is set to 1 only while reading features.         
        .fm_wm_in(dot_product_result),   
        .fm_wm_row_out(FM_WM_Row) 
    );

endmodule