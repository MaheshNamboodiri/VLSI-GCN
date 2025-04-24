module GCN #(  
    parameter FEATURE_COLS           = 96,
    parameter WEIGHT_ROWS           = 96,
    parameter FEATURE_ROWS          = 6,
    parameter WEIGHT_COLS           = 3,
    parameter FEATURE_WIDTH         = $clog2(FEATURE_ROWS),
    parameter WEIGHT_WIDTH          = 5,
    parameter DOT_PROD_WIDTH        = 16,
    parameter ADDRESS_WIDTH         = 13,
    parameter COUNTER_WEIGHT_WIDTH = $clog2(WEIGHT_COLS),
    parameter COUNTER_FEATURE_WIDTH= $clog2(FEATURE_ROWS),
    parameter MAX_ADDRESS_WIDTH     = 2,
    parameter NUM_OF_NODES          = 6,			 
    parameter COO_NUM_OF_COLS       = 6,			
    parameter COO_NUM_OF_ROWS       = 2,			
    parameter COO_BW                = $clog2(COO_NUM_OF_COLS),
    parameter DOT_PROD_ROWS         = 6,
    parameter DOT_PROD_COLS         = 3,
    parameter DOT_PROD_ROWS_WIDTH   = $clog2(DOT_PROD_ROWS),
    parameter ROW_COL_ADDRESS_MIN   = 3'h0,
    parameter ROW_COL_ADDRESS_MAX   = 3'h5,
    parameter ADJ_DOT_PROD_WIDTH    = 16,
    parameter ARGMAX_COLS           = 2,
    parameter ARGMAX_ROWS           = 6,
    parameter ARGMAX_WIDTH          = $clog2(ARGMAX_ROWS),
    parameter WEIGHT_ADDRESS_MAX    = 12'hFF,
    parameter FEATURE_ADDRESS_MAX   = 12'h2FF,
    parameter WEIGHT_ADDRESS_MIN    = 12'h0,
    parameter FEATURE_ADDRESS_MIN   = 12'h200
)(
    input  logic                         clk,                                   // Clock
    input  logic                         reset,                                 // Reset 
    input  logic                         start,
    input  logic [WEIGHT_WIDTH-1:0]      data_in [0:WEIGHT_ROWS-1],             // FM and WM Data
    input  logic [COO_BW-1:0]            coo_in  [0:1],                         // Row 0 and Row 1 of the COO Stream

    output logic [COO_BW-1:0]            coo_address,                           // The column of the COO Matrix 
    output logic [ADDRESS_WIDTH-1:0]     read_address,                          // Address to read the FM and WM Data
    output logic                         enable_read,                           // Enable Read of the FM and WM Data
    output logic                         done,                                  // Done signal: all calculations completed
    output logic [MAX_ADDRESS_WIDTH-1:0] max_addi_answer [0:FEATURE_ROWS-1]     // Argmax + matrix multiplication answer
); 

    logic                              done_trans, done_comb;
    logic [FEATURE_WIDTH-1:0]          read_row_ADJ_FM_WM;
    logic [DOT_PROD_ROWS_WIDTH-1:0]    read_row;
    logic [ADJ_DOT_PROD_WIDTH-1:0]     ADJ_FM_WM_Row [0:DOT_PROD_COLS-1];
    logic [DOT_PROD_WIDTH-1:0]         FM_WM_Row     [0:DOT_PROD_COLS-1];
    logic read_enable, done_arg;

    
    // Assigns
    assign enable_read = read_enable;  // Connect read enable signal to output
    assign done        = done_arg;     // Done signal triggered by internal done_arg


    argmax_function #(
        .FEATURE_ROWS(FEATURE_ROWS),
        .WEIGHT_COLS(WEIGHT_COLS),
        .FEATURE_COLS(FEATURE_COLS),
        .WEIGHT_ROWS(WEIGHT_ROWS),
        .COUNTER_WEIGHT_WIDTH(COUNTER_WEIGHT_WIDTH),
        .COUNTER_FEATURE_WIDTH(COUNTER_FEATURE_WIDTH),
        .DOT_PROD_WIDTH(DOT_PROD_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .NUM_OF_NODES(NUM_OF_NODES),
        .COO_NUM_OF_COLS(COO_NUM_OF_COLS),
        .COO_NUM_OF_ROWS(COO_NUM_OF_ROWS),
        .COO_BW(COO_BW),
        .DOT_PROD_ROWS(DOT_PROD_ROWS),
        .DOT_PROD_COLS(DOT_PROD_COLS),
        .FEATURE_WIDTH(FEATURE_WIDTH),
        .DOT_PROD_ROWS_WIDTH(DOT_PROD_ROWS_WIDTH),
        .ROW_COL_ADDRESS_MIN(ROW_COL_ADDRESS_MIN),
        .ROW_COL_ADDRESS_MAX(ROW_COL_ADDRESS_MAX),
        .ADJ_DOT_PROD_WIDTH(ADJ_DOT_PROD_WIDTH)
    ) argmax_function_inst (
        .clk(clk),
        .reset(reset),
        .done_comb(done_comb),
        .ADJ_FM_WM_Row(ADJ_FM_WM_Row),
        .read_row_ADJ_FM_WM(read_row_ADJ_FM_WM),
        .max_addi_ans(max_addi_answer),
        .done_arg(done_arg)
    );
        


    // Instantiate the DUT (Device Under Test)
    Combination #(
        .FEATURE_ROWS(FEATURE_ROWS),
        .WEIGHT_COLS(WEIGHT_COLS),
        .FEATURE_COLS(FEATURE_COLS),
        .WEIGHT_ROWS(WEIGHT_ROWS),
        .COUNTER_WEIGHT_WIDTH(COUNTER_WEIGHT_WIDTH),
        .COUNTER_FEATURE_WIDTH(COUNTER_FEATURE_WIDTH),
        .DOT_PROD_WIDTH(DOT_PROD_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .NUM_OF_NODES(NUM_OF_NODES),
        .COO_NUM_OF_COLS(COO_NUM_OF_COLS),
        .COO_NUM_OF_ROWS(COO_NUM_OF_ROWS),
        .COO_BW(COO_BW),
        .DOT_PROD_ROWS(DOT_PROD_ROWS),
        .DOT_PROD_COLS(DOT_PROD_COLS),
        .FEATURE_WIDTH(FEATURE_WIDTH),
        .DOT_PROD_ROWS_WIDTH(DOT_PROD_ROWS_WIDTH),
        .ROW_COL_ADDRESS_MIN(ROW_COL_ADDRESS_MIN),
        .ROW_COL_ADDRESS_MAX(ROW_COL_ADDRESS_MAX),
        .ADJ_DOT_PROD_WIDTH(ADJ_DOT_PROD_WIDTH)
    ) combination_inst (
        .clk(clk),
        .reset(reset),
        .done_trans(done_trans),
        .coo_in(coo_in), // Replace with actual signal
        .FM_WM_Row(FM_WM_Row),   // Replace with actual signal
        .read_row_ADJ_FM_WM(read_row_ADJ_FM_WM),
        .coo_address(coo_address),
        .done_comb(done_comb),
        .ADJ_FM_WM_Row(ADJ_FM_WM_Row),
        .read_FM_WM_row(read_row)
    );

    Transformation #(
        .FEATURE_ROWS(FEATURE_ROWS),
        .WEIGHT_COLS(WEIGHT_COLS),
        .FEATURE_COLS(FEATURE_COLS),
        .WEIGHT_ROWS(WEIGHT_ROWS),
        .COUNTER_WEIGHT_WIDTH(COUNTER_WEIGHT_WIDTH),
        .COUNTER_FEATURE_WIDTH(COUNTER_FEATURE_WIDTH),
        .DOT_PROD_WIDTH(DOT_PROD_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH)
    ) transformation_inst (
        .clk(clk),
        .reset(reset),
        .start(start),
        .read_row(read_row),
        .data_in(data_in),
        .read_address(read_address),
        .FM_WM_Row(FM_WM_Row),        
        .read_enable(read_enable),
        .done(done_trans)
    );    



endmodule