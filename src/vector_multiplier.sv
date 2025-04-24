module vector_multiplier #(
    parameter integer VECTOR_LEN = 96,
    parameter integer IN_WIDTH = 5,
    parameter integer OUT_WIDTH = 16
)(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      valid,
    input  logic [IN_WIDTH-1:0]      a [0:VECTOR_LEN-1],
    input  logic [IN_WIDTH-1:0]      b [0:VECTOR_LEN-1],
    output logic [OUT_WIDTH-1:0]     result
);

    logic [OUT_WIDTH-1:0] partials [0:VECTOR_LEN-1];
    logic [OUT_WIDTH-1:0] sum;

    // Generate partial products
    genvar i;
    generate
        for (i = 0; i < VECTOR_LEN; i++) begin
            // Calculates the partial products while reading features.
            assign partials[i] = (reset) ? 0 :
                                 (valid) ? (a[i] * b[i]) :
                                           0;
        end
    endgenerate

    // Sum all partials combinationally
    always_comb begin
        if (reset || !valid)
            sum = 0;
        else begin
            sum = 0;
            for (int j = 0; j < VECTOR_LEN; j++) begin
                sum += partials[j];
            end
        end
    end

    // Register the result on clock edge
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            result <= 0;
        else if (valid)
            result <= sum;
    end

endmodule

