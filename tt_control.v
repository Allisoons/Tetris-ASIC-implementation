module tt_control (
    input wire clk_i,
    input wire reset_i,
    
    // Timing and Clean Inputs
    input wire gravity_tick_i,
    input wire btn_left_pulse_i,   
    input wire btn_right_pulse_i,  
    input wire btn_rotate_pulse_i, 
    
    // Interface from Collision Checker
    input wire collision_i,
    
    // Interface from current piece tracking
    input wire signed [4:0] piece_x_i,
    input wire signed [5:0] piece_y_i,
    
    // Look-ahead coordinates sent OUT to Collision Checker
    output reg signed [4:0] proposed_x_o,
    output reg signed [5:0] proposed_y_o,
    
    // Control signals sent OUT to tt_piece
    output reg spawn_piece_o,
    output reg move_left_o,
    output reg move_right_o,
    output reg move_down_o,
    output reg rotate_o,
    
    // Write interface sent OUT to tt_grid
    output reg grid_write_en_o,
    output reg [3:0] grid_write_x_o,
    output reg [4:0] grid_write_y_o,
    output reg grid_write_val_o
);

    // FSM State Encoding
    localparam [2:0]
        ST_INIT      = 3'b000,
        ST_SPAWN     = 3'b001,
        ST_IDLE      = 3'b010,
        ST_LOCK      = 3'b011,
        ST_GAME_OVER = 3'b100;

    reg [2:0] current_state, next_state;

    // 1. State Transition Register
    always @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            current_state <= ST_INIT;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Next-State and Output Logic
    always @(*) begin
        // Default Outputs
        next_state       = current_state;
        spawn_piece_o    = 1'b0;
        move_left_o      = 1'b0;
        move_right_o     = 1'b0;
        move_down_o      = 1'b0;
        rotate_o         = 1'b0;
        grid_write_en_o  = 1'b0;
        grid_write_x_o   = piece_x_i[3:0];
        grid_write_y_o   = piece_y_i[4:0];
        grid_write_val_o = 1'b1;
        
        // Default Look-ahead matches current positioning
        proposed_x_o     = piece_x_i;
        proposed_y_o     = piece_y_i;

        case (current_state)
            ST_INIT: begin
                next_state = ST_SPAWN;
            end

            ST_SPAWN: begin
                spawn_piece_o = 1'b1;
                if (collision_i) 
                    next_state = ST_GAME_OVER;
                else 
                    next_state = ST_IDLE;
            end

            ST_IDLE: begin
                if (btn_left_pulse_i) begin
                    proposed_x_o = piece_x_i - 5'sd1;
                    if (!collision_i) move_left_o = 1'b1;
                end 
                else if (btn_right_pulse_i) begin
                    proposed_x_o = piece_x_i + 5'sd1;
                    if (!collision_i) move_right_o = 1'b1;
                end 
                else if (btn_rotate_pulse_i) begin
                    if (!collision_i) rotate_o = 1'b1;
                end 
                else if (gravity_tick_i) begin
                    proposed_y_o = piece_y_i + 6'sd1;
                    if (!collision_i) begin
                        move_down_o = 1'b1;
                    end else begin
                        // Hit block/floor below -> time to lock piece
                        next_state = ST_LOCK;
                    end
                end
            end

            ST_LOCK: begin
                // Enable grid write interface to stamp the piece into memory
                grid_write_en_o  = 1'b1;
                grid_write_val_o = 1'b1;
                next_state       = ST_SPAWN; 
            end

            ST_GAME_OVER: begin
                if (reset_i) next_state = ST_INIT;
            end

            default: next_state = ST_INIT;
        endcase
    end

endmodule
