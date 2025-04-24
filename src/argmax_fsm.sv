module argmax_fsm #(
    parameter ARGMAX_ROWS  = 6,
    parameter ARGMAX_WIDTH = $clog2(ARGMAX_ROWS)
)(
    input  logic                         clk,
    input  logic                         reset,
    input  logic                         done_comb,
    input  logic [ARGMAX_WIDTH-1:0]      ADJ_FM_WM_ROW_Counter,
    output logic                         done_arg,
    output logic                         is_idle,
    output logic                         is_read_row,
    output logic                         is_increment_row_addr,
    output logic                         is_done
);



    typedef enum logic [1:0] {
        IDLE          = 2'd0,
        READ_ROW      = 2'd1,
        INCREMENT_ROW_ADDR = 2'd2,
        DONE          = 2'd3
    } fsm_state_t;

    fsm_state_t state;

    // FSM sequential logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (done_comb) begin
                        state <= READ_ROW;
                    end else begin
                        state <= IDLE;
                    end
                    done_arg <= 0;
                end
                READ_ROW: begin
                    state <= INCREMENT_ROW_ADDR;
                    done_arg <= 0;
                end
                INCREMENT_ROW_ADDR: begin
                    if (ADJ_FM_WM_ROW_Counter < ARGMAX_ROWS - 1) begin
                        state <= READ_ROW;
                    end else begin
                        state <= DONE;
                    end
                    done_arg <= 0;
                end
                DONE: begin
                    state <= DONE;
                    done_arg <= 1;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // FSM output flags
    always_comb begin
        is_idle           = (state == IDLE);
        is_read_row         = (state == READ_ROW);
        is_increment_row_addr  = (state == INCREMENT_ROW_ADDR);
        is_done           = (state == DONE);
    end


endmodule