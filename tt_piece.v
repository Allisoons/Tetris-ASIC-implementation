module tt_piece (
    input wire clk_i,
    input wire reset_i,
    input wire spawn_piece_i,    // Trigger to load a new random piece at the top
    input wire move_left_i,      // Shift coordinates left
    input wire move_right_i,     // Shift coordinates right
    input wire move_down_i,      // Gravity drop (shift coordinates down)
    input wire rotate_i,         // Cycle through rotation states (0, 1, 2, 3)
    input wire [2:0] random_type_i, // Value 0-6
    output reg [3:0] piece_x_o,         
    output reg [4:0] piece_y_o,        
    output reg [15:0] active_shape_o    
);

    reg [2:0] piece_type;      // Tracks which of the 7 pieces is active (0 to 6)
    reg [1:0] rotation_state;  // Tracks current rotation index (0=0°, 1=90°, 2=180°, 3=270°)

//bounding box
//following section is from chat
    always @(*) begin
        case (piece_type)
            // 0: I-Piece
            3'd0: begin
                case (rotation_state)
                    2'd0, 2'd2: active_shape_o = 16'b0000_1111_0000_0000; // Horizontal
                    2'd1, 2'd3: active_shape_o = 16'b0100_0100_0100_0100; // Vertical
                endcase
            end
            
            // 1: O-Piece (Does not change on rotation)
            3'd1: begin
                active_shape_o = 16'b0000_0110_0110_0000;
            end
            
            // 2: T-Piece
            3'd2: begin
                case (rotation_state)
                    2'd0: active_shape_o = 16'b0100_1110_0000_0000; // Pointing Up
                    2'd1: active_shape_o = 16'b0100_0110_0100_0000; // Pointing Right
                    2'd2: active_shape_o = 16'b0000_1110_0100_0000; // Pointing Down
                    2'd3: active_shape_o = 16'b0100_1100_0100_0000; // Pointing Left
                endcase
            end
            
            // 3: L-Piece
            3'd3: begin
                case (rotation_state)
                    2'd0: active_shape_o = 16'b0100_0100_0110_0000;
                    2'd1: active_shape_o = 16'b0000_1110_1000_0000;
                    2'd2: active_shape_o = 16'b0110_0100_0100_0000;
                    2'd3: active_shape_o = 16'b0010_1110_0000_0000;
                endcase
            end
            
            // 4: J-Piece
            3'd4: begin
                case (rotation_state)
                    2'd0: active_shape_o = 16'b0100_0100_1100_0000;
                    2'd1: active_shape_o = 16'b1000_1110_0000_0000;
                    2'd2: active_shape_o = 16'b0110_0100_0100_0000;
                    2'd3: active_shape_o = 16'b0000_1110_0010_0000;
                endcase
            end
            
            // 5: S-Piece
            3'd5: begin
                case (rotation_state)
                    2'd0, 2'd2: active_shape_o = 16'b0000_0110_1100_0000; // Horizontal
                    2'd1, 2'd3: active_shape_o = 16'b0100_0110_0010_0000; // Vertical
                endcase
            end
            
            // 6: Z-Piece
            3'd6: begin
                case (rotation_state)
                    2'd0, 2'd2: active_shape_o = 16'b0000_1100_0110_0000; // Horizontal
                    2'd1, 2'd3: active_shape_o = 16'b0010_0110_0100_0000; // Vertical
                endcase
            end
            
            default: begin
                active_shape_o = 16'b0;
            end
        endcase
    end

//movements??
    always @(posedge clk_i) begin
        if (reset_i) begin
            piece_x_o      <= 4'd3;    // Spawns near the middle column (columns are 0 to 9)
            piece_y_o      <= 5'd0;    // Spawns at the very top row
            piece_type     <= 3'd0;    // Reset to I-piece default
            rotation_state <= 2'd0;    // Reset to base orientation
        end else if (spawn_piece_i) begin
            piece_x_o      <= 4'd3;    // Center the spawned piece
            piece_y_o      <= 5'd0;    // Put it at the top of the grid
            piece_type     <= (random_type_i < 3'd7) ? random_type_i : 3'd0; // Safety bounds clamp
            rotation_state <= 2'd0;    // Reset orientation for the new piece
        end else begin
            // Handle active positioning inputs directed by your master Game_control FSM
            if (move_left_i) begin
                piece_x_o <= piece_x_o - 1'b1;
            end
            if (move_right_i) begin
                piece_x_o <= piece_x_o + 1'b1;
            end
            if (move_down_i) begin
                piece_y_o <= piece_y_o + 1'b1;
            end
            if (rotate_i) begin
                rotation_state <= rotation_state + 1'b1; // Auto-wraps (2'b11 + 1 = 2'b00)
            end
        end
    end

endmodule
