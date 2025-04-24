module COO_Multiplier_Logic #(
    parameter DOT_PROD_ROWS = 6,
    parameter DOT_PROD_COLS = 3,
    parameter COO_NUM_OF_COLS = 6,
    parameter COO_NUM_OF_ROWS = 2,
    parameter COO_BW = $clog2(COO_NUM_OF_COLS),
    parameter DOT_PROD_ROWS_WIDTH = $clog2(DOT_PROD_ROWS),
    parameter ADJ_DOT_PROD_WIDTH = 16
)(
    input  logic clk,
    input  logic reset,
    input  logic is_read_column,
    input  logic is_increment_col_addr,
    input  logic [COO_BW-1:0] coo_in [0:COO_NUM_OF_ROWS-1],
    input  logic [DOT_PROD_ROWS_WIDTH - 1:0] FM_WM_ROW_Counter,
//    input  logic [ADJ_DOT_PROD_WIDTH-1:0] r_FM_WM_Row [0:DOT_PROD_COLS-1],
    input  logic is_read_row,
    input  logic [ADJ_DOT_PROD_WIDTH-1:0] FM_WM_Row [0:DOT_PROD_COLS-1],
//    output logic [DOT_PROD_ROWS_WIDTH-1:0] idx_a,
//    output logic [DOT_PROD_ROWS_WIDTH-1:0] idx_b,
    output logic [ADJ_DOT_PROD_WIDTH-1:0] r_FM_WM_Row [0:DOT_PROD_COLS-1],
    output logic [ADJ_DOT_PROD_WIDTH-1:0] accum_partial_product [0:DOT_PROD_ROWS-1][0:DOT_PROD_COLS-1],
    output logic [COO_BW-1:0] write_row_to_memory
);

    logic [DOT_PROD_ROWS_WIDTH-1:0] idx_a, idx_b;
    logic [COO_BW-1:0] product_matrix_index;
//    logic [COO_BW-1:0] write_row_to_memory;

    assign product_matrix_index = (idx_a == FM_WM_ROW_Counter) ? idx_b : idx_a;
    assign idx_a = reset         ? 0 :
                   is_read_column ? coo_in[0] - 1 : 0;
    
    assign idx_b = reset         ? 0 :
                   is_read_column ? coo_in[1] - 1 : 0;
        
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < DOT_PROD_COLS; i = i + 1) begin
                r_FM_WM_Row[i] <= '0;  
            end
        end else if (is_read_row) begin
            r_FM_WM_Row <= FM_WM_Row;  
        end
        else begin
            r_FM_WM_Row <=  r_FM_WM_Row; 
        end
    end    

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            write_row_to_memory <= 0;
        end else if (is_read_column) begin
            write_row_to_memory <= product_matrix_index;
        end
        else begin
            write_row_to_memory <= write_row_to_memory; 
        end
    end        
    
//    always_ff @(posedge clk or posedge reset) begin
//        if (reset) begin
//            idx_a <= 0;
//            idx_b <= 0;
//        end
//        else if (is_read_column) begin
//            idx_a <= coo_in[0] - 1;
//            idx_b <= coo_in[1] - 1;
//        end
//        else begin
//            idx_a <= 0;
//            idx_b <= 0;
//        end
//    end

    // Multiplier

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < DOT_PROD_ROWS; i++) begin
                for (int j = 0; j < DOT_PROD_COLS; j++) begin
                    accum_partial_product[i][j] <= 0;
                end
            end
        end
        else begin
            if(is_read_column) begin
                if (idx_a == FM_WM_ROW_Counter || idx_b == FM_WM_ROW_Counter) begin
                    for (int i = 0; i < DOT_PROD_COLS; i++) begin
                        accum_partial_product[product_matrix_index][i] <= 
                            accum_partial_product[product_matrix_index][i] + r_FM_WM_Row[i];
                    end
                end
            end
        end
    end

endmodule