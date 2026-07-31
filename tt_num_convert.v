module tt_num_convert (
    input  wire       clk_i,
    input  wire [7:0] score_i,
    input  wire       reset_i,
    input  wire       en_i,
    output wire       AA,
    output wire       AB,
    output wire       AC,
    output wire       AD,
    output wire       AE,
    output wire       AF,
    output wire       AG,
    output wire       CAT
);

wire [3:0] tens;
    wire [3:0] ones;

    wire [7:0] tens_full = score_i / 8'd10;
    wire [7:0] ones_full = score_i % 8'd10;

    assign tens = tens_full[3:0];
    assign ones = ones_full[3:0];

    // Truncate division/modulo results cleanly to 4 bits
    assign tens = (score_i / 8'd10);
    assign ones = (score_i % 8'd10);

    reg [15:0] refresh_counter = 16'd0;

    always @(posedge clk_i) begin
        if (en_i) begin
            if (reset_i)
                refresh_counter <= 16'd0;
            else
                refresh_counter <= refresh_counter + 16'd1;
        end
    end

    wire [3:0] digit;

    // Multiplex between tens and ones using refresh_counter bit 15
    assign digit = refresh_counter[15] ? tens : ones;
    assign CAT   = refresh_counter[15];

    reg [6:0] seg;

    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

    // Connect segment outputs to individual pins
    assign AA = seg[6];
    assign AB = seg[5];
    assign AC = seg[4];
    assign AD = seg[3];
    assign AE = seg[2];
    assign AF = seg[1];
    assign AG = seg[0];

endmodule
