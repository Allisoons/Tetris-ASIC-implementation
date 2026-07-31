module tt_grid (
    input  wire        clk_i,
    input  wire        reset_i,
    input  wire        en_i,
    input  wire [3:0]  x_i,        // 0 to 9
    input  wire [4:0]  y_i,        // 0 to 19
    input  wire        write_i,    // 1 to write block, 0 to clear
    output wire [199:0] grid_flat
);

    reg [199:0] grid_reg;
    assign grid_flat = grid_reg;

    integer r, c;

    // Asynchronous reset matching global top wrapper strategy
    always @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            grid_reg <= 200'b0;
        end else if (en_i) begin
            // Unroll into 200 explicit bit-enable comparators
            for (r = 0; r < 20; r = r + 1) begin
                for (c = 0; c < 10; c = c + 1) begin
                    if ((x_i == c[3:0]) && (y_i == r[4:0])) begin
                        grid_reg[(r * 10) + c] <= write_i;
                    end
                end
            end
        end
    end

endmodule
