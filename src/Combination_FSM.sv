module Combination_FSM
#(
    parameter COO_BW = 3,
    parameter DOT_PROD_ROWS_WIDTH = 3,
    parameter COO_NUM_OF_COLS = 6,
    parameter DOT_PROD_ROWS = 6
)
(
    input logic clk,
    input logic reset,
    input logic done_trans,
    input logic [COO_BW - 1:0] coo_col_counter,
    input logic [DOT_PROD_ROWS_WIDTH-1:0] FM_WM_ROW_Counter,
    input logic [DOT_PROD_ROWS_WIDTH-1:0] ADJ_FM_WM_Row_Counter,
    output logic done_comb,
    output logic is_idle,
    output logic is_read_row,
    output logic is_read_column,
    output logic is_increment_col_addr,
    output logic is_increment_row_addr,
    output logic is_write_result_to_mem,
    output logic is_comb_done
);

    typedef enum logic [2:0] {
        IDLE                = 3'd0,
        READ_ROW            = 3'd1,
        READ_COLUMN         = 3'd2,
        INCREMENT_COL_ADDR  = 3'd3,
        INCREMENT_ROW_ADDR  = 3'd4,
        WRITE_RESULT_TO_MEM = 3'd5,
        COMB_DONE           = 3'd6
    } fsm_state_t;

    fsm_state_t state;

    // FSM
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
            done_comb <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (done_trans) begin
                        state <= READ_ROW;
                    end
                    else begin
                        state <= IDLE;
                    end
                    done_comb <= 0;
                end
                READ_ROW: begin
                    state <= READ_COLUMN; 
                    done_comb <= 0;
                end                
                READ_COLUMN: begin
//                    state <= INCREMENT_COL_ADDR;
                if (coo_col_counter < COO_NUM_OF_COLS - 1) begin
                    state <= READ_COLUMN;
                end
                else begin
                    state <= INCREMENT_ROW_ADDR;
                end
                    done_comb <= 0;
                end
//                INCREMENT_COL_ADDR: begin
//                    if (coo_col_counter < COO_NUM_OF_COLS - 1) begin
//                        state <= READ_COLUMN;
//                    end
//                    else begin
//                        state <= INCREMENT_ROW_ADDR;
//                    end
//                    done_comb <= 0;
//                end

                INCREMENT_ROW_ADDR: begin
                    if (FM_WM_ROW_Counter < DOT_PROD_ROWS - 1) begin
                        state <= READ_ROW;
                    end
                    else begin
//                        state <= WRITE_RESULT_TO_MEM;
                        state <= COMB_DONE;
                    end
                    done_comb <= 0;
                end
                WRITE_RESULT_TO_MEM: begin
                    if(ADJ_FM_WM_Row_Counter < DOT_PROD_ROWS - 1) begin
                        state <= state;
                    end
                    else begin
                        state <= COMB_DONE;
                    end
                end
                COMB_DONE: begin
                    state <= COMB_DONE;
                    done_comb <= 1;
                end
                default: begin
                    state <= IDLE;
                    done_comb <= 0;
                end 
            endcase
        end
    end

    // FSM internal logic flags to represent the current state.
    always_comb begin
        is_idle                = (state == IDLE);
        is_read_row            = (state == READ_ROW);
        is_read_column         = (state == READ_COLUMN);
        is_increment_col_addr  = (state == INCREMENT_COL_ADDR);
        is_increment_row_addr  = (state == INCREMENT_ROW_ADDR);
        is_write_result_to_mem = (state == WRITE_RESULT_TO_MEM);
        is_comb_done           = (state == COMB_DONE);
    end



endmodule