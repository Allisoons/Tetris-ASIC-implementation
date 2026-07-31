module my_chip (
    input  wire        clk_i,              // Main FPGA Clock
    input  wire        reset_i,            // Active-high reset
    
    // Physical Button Inputs
    input  wire        btn_left_raw_i,
    input  wire        btn_right_raw_i,
    input  wire        btn_rotate_raw_i,
    
    // Outputs
    output wire [199:0] grid_flat_o,        // Flat grid state to display
    output wire [6:0]   display_segments_o, // 7-segment score output
    output wire         display_cat_o       // Display digit cathode
);

    // =========================================================================
    // 1. INTERCONNECT WIRES & REGISTERS
    // =========================================================================
    wire [199:0] grid_flat;
    assign grid_flat_o = grid_flat;

    // Direct button pass-through
    wire btn_left_clean   = btn_left_raw_i;
    wire btn_right_clean  = btn_right_raw_i;
    wire btn_rotate_clean = btn_rotate_raw_i;

    // Gravity Pulse Generator
    reg [23:0] grav_cnt = 24'd0;
    reg        gravity_tick_reg = 1'b0;

    always @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            grav_cnt         <= 24'd0;
            gravity_tick_reg <= 1'b0;
        end else if (grav_cnt >= 24'd1000) begin // Speed control threshold
            grav_cnt         <= 24'd0;
            gravity_tick_reg <= 1'b1;
        end else begin
            grav_cnt         <= grav_cnt + 24'd1;
            gravity_tick_reg <= 1'b0;
        end
    end
    wire gravity_tick = gravity_tick_reg;

    // Control & Interconnect Signals
    wire [2:0]  random_piece_type = grav_cnt[2:0];
    
    // Match widths with tt_piece (4-bit X, 5-bit Y)
    wire [3:0] piece_x;
    wire [4:0] piece_y;
    
    // Signed proposed coordinates for collision checking
    wire signed [4:0] proposed_x;
    wire signed [5:0] proposed_y;
    
    wire [15:0] active_shape;
    wire        collision_flag;

    wire spawn_piece;
    wire move_left;
    wire move_right;
    wire move_down;
    wire rotate;

    wire       grid_write_en;
    wire [3:0] grid_write_x;
    wire [4:0] grid_write_y;
    wire       grid_write_val;

    wire [15:0] current_score;

    // =========================================================================
    // 2. MODULE INSTANTIATIONS
    // =========================================================================

    // Grid Storage
    tt_grid grid_inst (
        .clk_i       (clk_i),
        .reset_i     (reset_i),
        .en_i        (grid_write_en), // Cleaned: controlled solely by FSM
        .x_i         (grid_write_x),
        .y_i         (grid_write_y),
        .write_i     (grid_write_val),
        .grid_flat   (grid_flat)
    );

    // Active Falling Piece Tracker
    tt_piece piece_inst (
        .clk_i          (clk_i),
        .reset_i        (reset_i),
        .spawn_piece_i  (spawn_piece),
        .move_left_i    (move_left),
        .move_right_i   (move_right),
        .move_down_i    (move_down),
        .rotate_i       (rotate),
        .random_type_i  (random_piece_type),
        .piece_x_o      (piece_x),
        .piece_y_o      (piece_y),
        .active_shape_o (active_shape)
    );

    // Collision Checker
    tt_collision collision_inst (
        .grid_flat_i    (grid_flat),
        .piece_x_i      (proposed_x),
        .piece_y_i      (proposed_y),
        .active_shape_i (active_shape),
        .collision_o    (collision_flag)
    );

    // Control FSM
    tt_control control_inst (
        .clk_i              (clk_i),
        .reset_i            (reset_i),
        .gravity_tick_i     (gravity_tick),
        .btn_left_pulse_i   (btn_left_clean),
        .btn_right_pulse_i  (btn_right_clean),
        .btn_rotate_pulse_i (btn_rotate_clean),
        .collision_i        (collision_flag),
        .piece_x_i          ({1'b0, piece_x}), // Zero-extend unsigned 4-bit to signed 5-bit
        .piece_y_i          ({1'b0, piece_y}), // Zero-extend unsigned 5-bit to signed 6-bit
        .proposed_x_o       (proposed_x),
        .proposed_y_o       (proposed_y),
        .spawn_piece_o      (spawn_piece),
        .move_left_o        (move_left),
        .move_right_o       (move_right),
        .move_down_o        (move_down),
        .rotate_o           (rotate),
        .grid_write_en_o    (grid_write_en),
        .grid_write_x_o     (grid_write_x),
        .grid_write_y_o     (grid_write_y),
        .grid_write_val_o   (grid_write_val)
    );

    // Scorekeeper
    tt_scorekeep score_inst (
        .clk_i          (clk_i),
        .reset_i        (reset_i),
        .line_cleared_i (btn_rotate_clean), 
        .score_o        (current_score)
    );

    // Display Decoder
    tt_num_convert display_inst (
        .clk_i   (clk_i),
        .score_i (current_score[7:0]),
        .reset_i (reset_i),
        .en_i    (1'b1),
        .AA      (display_segments_o[6]),
        .AB      (display_segments_o[5]),
        .AC      (display_segments_o[4]),
        .AD      (display_segments_o[3]),
        .AE      (display_segments_o[2]),
        .AF      (display_segments_o[1]),
        .AG      (display_segments_o[0]),
        .CAT     (display_cat_o)
    );

endmodule
