module tt_scorekeep
    (input wire clk_i,
    input wire reset_i,
    input wire line_cleared_i,
    output reg [7:0] score_o
    );

    always @(posedge clk_i) begin
        if (reset_i) begin
           score_o <= 0;
        end else if (line_cleared_i) begin
            score_o <= score_o + 8'd1;
        end
    end 
endmodule
