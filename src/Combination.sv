module Combination #(
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
    parameter ADJ_DOT_PROD_WIDTH    = 16
) 
(
    input  logic                              clk,
    input  logic                              reset,
    input  logic                              done_trans,                               // Indicates that the transformation is complete.
    input  logic [COO_BW-1:0]                 coo_in           [0:COO_NUM_OF_ROWS-1],   // Adjacency matrix data, sent in columns
    input  logic [DOT_PROD_WIDTH-1:0]         FM_WM_Row        [0:DOT_PROD_COLS-1],     // Row data received from FM_WM memory
    input  logic [FEATURE_WIDTH-1:0]          read_row_ADJ_FM_WM,                       // Address of Row data requested by argmax

    output logic [COO_BW-1:0]                 coo_address,                              // Column address for coo data.
    output logic                              done_comb,                                // Indicates multiplication is done 
    output logic [ADJ_DOT_PROD_WIDTH-1:0]     ADJ_FM_WM_Row   [0:DOT_PROD_COLS-1],      // Output row data from ADJ_FM_WM memory
    output logic [DOT_PROD_ROWS_WIDTH-1:0]    read_FM_WM_row                            // Address to read FM and WM Data
);

    // FSM Variables
    logic                                  is_idle;                          // FSM idle state flag
    logic                                  is_read_row;                      // FSM read row state flag
    logic                                  is_read_column;                   // FSM read column state flag
    logic                                  is_increment_col_addr;            // FSM increment column address flag
    logic                                  is_increment_row_addr;            // FSM increment row address flag
    logic                                  is_write_result_to_mem;           // FSM write result to memory flag
    logic                                  is_comb_done;                     // FSM combination done flag

    // Counters
    logic [DOT_PROD_ROWS_WIDTH - 1:0]      FM_WM_ROW_Counter;                // Row counter for FM_WM memory
    logic [DOT_PROD_ROWS_WIDTH - 1:0]      ADJ_FM_WM_Row_Counter;            // Row counter for ADJ_FM_WM memory
    logic [COO_BW-1:0]                    coo_col_counter;                  // COO column counter
    
    logic [DOT_PROD_WIDTH-1:0]             r_FM_WM_Row [0:DOT_PROD_COLS-1];   // Registers the incoming row
    logic [ADJ_DOT_PROD_WIDTH-1:0]        accum_partial_product [0:DOT_PROD_ROWS-1][0:DOT_PROD_COLS-1]; // Accumulates partial products using incoming data
    logic [ADJ_DOT_PROD_WIDTH-1:0]        adj_fm_wm_write_data [0:DOT_PROD_COLS-1]; // To write into memory after combination is done
    logic [COO_BW-1:0] write_row_to_memory;
    
    // Assigns
//    assign adj_fm_wm_write_data  = accum_partial_product[ADJ_FM_WM_Row_Counter];                    // Product row to write into ADJ_FM_WM memory
    assign adj_fm_wm_write_data  = accum_partial_product[write_row_to_memory];                    // Product row to write into ADJ_FM_WM memory
    
    assign read_FM_WM_row        = (is_read_row) ? (ROW_COL_ADDRESS_MIN + FM_WM_ROW_Counter) : '0;  // Row address for reading the FM_WM row data
    assign coo_address           = is_read_column ? (ROW_COL_ADDRESS_MIN + coo_col_counter) : 0;    // Column address to read coo_data column-wise
    

    //////////////////////////////////////////////////////////////////////
    ///////////////////// Module Instantiations //////////////////////////
    //////////////////////////////////////////////////////////////////////    
    
    // Write to memory 
    
//    ADJ_FM_WM_Write_To_Mem #(
//        .DOT_PROD_COLS(DOT_PROD_COLS),
//        .ADJ_DOT_PROD_WIDTH(ADJ_DOT_PROD_WIDTH)
//    ) adj_fm_wm_write_to_mem_inst (
//        .clk(clk),
//        .reset(reset),
//        .is_write_result_to_mem(is_write_result_to_mem),
//        .adj_fm_wm_write_data(adj_fm_wm_write_data),
//        .ADJ_FM_WM_Row(ADJ_FM_WM_Row)
//    );

    // Coo data multiplier
        
    COO_Multiplier_Logic #(
        .DOT_PROD_ROWS(DOT_PROD_ROWS),
        .DOT_PROD_COLS(DOT_PROD_COLS),
        .COO_NUM_OF_COLS(COO_NUM_OF_COLS),
        .COO_NUM_OF_ROWS(COO_NUM_OF_ROWS),
        .COO_BW(COO_BW),
        .DOT_PROD_ROWS_WIDTH(DOT_PROD_ROWS_WIDTH),
        .ADJ_DOT_PROD_WIDTH(ADJ_DOT_PROD_WIDTH)
    ) coo_multiplier_logic_inst (
        .clk(clk),
        .reset(reset),
        .is_read_column(is_read_column),
        .is_increment_col_addr(is_increment_col_addr),
        .coo_in(coo_in),
        .FM_WM_ROW_Counter(FM_WM_ROW_Counter),
        .is_read_row(is_read_row),
        .FM_WM_Row(FM_WM_Row),
        .r_FM_WM_Row(r_FM_WM_Row),
        .accum_partial_product(accum_partial_product),
        .write_row_to_memory(write_row_to_memory)
    );
        
    // FSM
    
    Combination_FSM #(
        .COO_BW(COO_BW),
        .DOT_PROD_ROWS_WIDTH(COO_BW),
        .COO_NUM_OF_COLS(COO_NUM_OF_COLS),
        .DOT_PROD_ROWS(DOT_PROD_ROWS)
    ) u_combination_fsm (
        .clk(clk),
        .reset(reset),
        .done_trans(done_trans),
        .coo_col_counter(coo_col_counter),
        .FM_WM_ROW_Counter(FM_WM_ROW_Counter),
        .ADJ_FM_WM_Row_Counter(ADJ_FM_WM_Row_Counter),
        .done_comb(done_comb),
        .is_idle(is_idle),
        .is_read_row(is_read_row),
        .is_read_column(is_read_column),
        .is_increment_col_addr(is_increment_col_addr),
        .is_increment_row_addr(is_increment_row_addr),
        .is_write_result_to_mem(is_write_result_to_mem),
        .is_comb_done(is_comb_done)
    );
        
        
    // Row counter for FM_WM matrix memory.  
          
    address_counter #(
        .MAX_COUNT(DOT_PROD_ROWS)
    )FM_WM_row_address_counter(
        .clk(clk),
        .reset(reset),
        .increment_address_valid(is_increment_row_addr),
        .count(FM_WM_ROW_Counter)
    );     
    

        


    // Col counter for coo data.
    
    address_counter #(
        .MAX_COUNT(COO_NUM_OF_COLS)
    )coo_col_address_counter(
        .clk(clk),
        .reset(reset),
        .increment_address_valid(is_read_column),
        .count(coo_col_counter)
    );          
    
    

 // Row counter for ADJ_FM_WM matrix memory.
 
    address_counter #(
        .MAX_COUNT(DOT_PROD_ROWS)
    ) ADJ_FM_WM_Row_address_counter(
        .clk(clk),
        .reset(reset),
        .increment_address_valid(is_write_result_to_mem),
        .count(ADJ_FM_WM_Row_Counter)
    );    

    // Memory that stores the final result of Combination.

    Matrix_FM_WM_ADJ_Memory #(
        .FEATURE_ROWS(FEATURE_ROWS),
        .WEIGHT_COLS(WEIGHT_COLS),
        .DOT_PROD_WIDTH(DOT_PROD_WIDTH)
    ) u_matrix_fm_wm_adj_memory (
        .clk(clk),
        .rst(reset),
//        .write_row(ADJ_FM_WM_Row_Counter),
        .write_row(write_row_to_memory),
        .read_row(read_row_ADJ_FM_WM),  // Address of Row data requested by argmax
        .wr_en(is_read_column | is_read_row), // Writes are enabled only in this state.
        .fm_wm_adj_row_in(adj_fm_wm_write_data),
        .fm_wm_adj_out(ADJ_FM_WM_Row)   // Given to Argmax, when requested.
    );

endmodule