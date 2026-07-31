module tt_collision (
    // Grid flat input from tt_grid (10 columns x 20 rows)
    input  wire [199:0] grid_flat_i,
    
    // Proposed coordinates of top-left 4x4 matrix
    input  wire signed [4:0] piece_x_i, 
    input  wire signed [5:0] piece_y_i, 
    
    // Active 4x4 shape matrix
    input  wire [15:0] active_shape_i,
    
    // Output collision flag
    output reg  collision_o
);

    integer r, c;
    
    reg signed [4:0] abs_x;
    reg signed [5:0] abs_y;
    reg [7:0] flat_index;
    
    reg hit_wall;
    reg hit_floor;
    reg hit_block;

    always @(*) begin
        collision_o = 1'b0;

        // Unroll the 4x4 check fully into 16 parallel evaluators
        for (r = 0; r < 4; r = r + 1) begin
            for (c = 0; c < 4; c = c + 1) begin
                
                // Active bit in the 4x4 tetromino bounding box
                if (active_shape_i[15 - (r*4 + c)]) begin
                    
                    abs_x = piece_x_i + $signed({2'b00, c[2:0]});
                    abs_y = piece_y_i + $signed({3'b000, r[2:0]});

                    // 1. Boundary Checks
                    hit_wall  = (abs_x < 5'sb0) || (abs_x >= 5'sd10);
                    hit_floor = (abs_y >= 6'sd20);

                    // 2. Block Collision Check
                    hit_block = 1'b0;
                    if (!hit_wall && !hit_floor && (abs_y >= 6'sb0)) begin
                        // Replaced multiplier (abs_y * 10) with shift-add: (y << 3) + (y << 1)
                        flat_index = ({2'b00, abs_y} << 3) + ({2'b00, abs_y} << 1) + {3'b000, abs_x};
                        
                        // Explicit bounds guard to ensure valid index lookup
                        if (flat_index < 8'd200) begin
                            hit_block = grid_flat_i[flat_index];
                        end
                    end

                    // Accumulate collision across all 16 cells
                    if (hit_wall || hit_floor || hit_block) begin
                        collision_o = 1'b1;
                    end
                end

            end
        end
    end

endmodule
