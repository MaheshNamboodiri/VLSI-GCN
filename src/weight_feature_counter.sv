module address_counter #(
    parameter MAX_COUNT     = 6,
    parameter COUNTER_WIDTH = $clog2(MAX_COUNT)
)(
    input  logic                         clk,
    input  logic                         reset,
    input  logic                         increment_address_valid,
    output logic [COUNTER_WIDTH-1:0]       count
);

    logic [COUNTER_WIDTH-1:0] r_count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_count <= 0;
        end
        else if (increment_address_valid) begin
            if (r_count < MAX_COUNT - 1) begin
                r_count <= r_count + 1;
            end
            else begin
                r_count <= 0;
            end
        end
        else begin
            r_count <= r_count;
        end
    end

    assign count = r_count;

endmodule
