`timescale 1ns / 1ps

module bilinear_scaler_rgb #(
    parameter IN_W  = 100,      
    parameter IN_H  = 100,
    parameter OUT_W = 400,      
    parameter OUT_H = 400,
    parameter IN_FILE  = "image_in_24b.hex",
    parameter OUT_FILE = "image_out_24b.hex"
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output reg  done
);

    reg [23:0] mem_in  [0 : (IN_W * IN_H) - 1];
    reg [23:0] mem_out [0 : (OUT_W * OUT_H) - 1];

    integer i;
    initial begin
        $readmemh(IN_FILE, mem_in);
        for (i = 0; i < OUT_W * OUT_H; i = i + 1) mem_out[i] = 24'b0;
    end

    localparam [15:0] SCALE_X = (IN_W << 8) / OUT_W;
    localparam [15:0] SCALE_Y = (IN_H << 8) / OUT_H;
    localparam [8:0]  ONE     = 256;

    reg active; 

    
    reg [15:0] x_out_q1, y_out_q1;
    reg valid_q1;

  
    reg [15:0] x_out_q2, y_out_q2;
    reg [15:0] x0_q2, y0_q2, x1_q2, y1_q2;
    reg [8:0]  a_q2, b_q2, inv_a_q2, inv_b_q2;
    reg valid_q2;

  
    reg [15:0] x_out_q3, y_out_q3;
    reg [23:0] p00_q3, p10_q3, p01_q3, p11_q3; 
    reg [17:0] w00_q3, w10_q3, w01_q3, w11_q3; 
    reg valid_q3;

   
    reg [15:0] x_out_q4, y_out_q4;
    reg [31:0] sum_R, sum_G, sum_B;
    reg valid_q4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 0; done <= 0;
            valid_q1 <= 0; valid_q2 <= 0; valid_q3 <= 0; valid_q4 <= 0;
            x_out_q1 <= 0; y_out_q1 <= 0;
        end else begin
            
            if (start && !active) active <= 1;

            if (active) begin
                valid_q1 <= 1;
                x_out_q1 <= (x_out_q1 == OUT_W - 1) ? 0 : x_out_q1 + 1;
                if (x_out_q1 == OUT_W - 1) begin
                    y_out_q1 <= y_out_q1 + 1;
                    if (y_out_q1 == OUT_H - 1) active <= 0; // Stop feeding pipeline
                end
            end else begin
                valid_q1 <= 0;
            end

            valid_q2 <= valid_q1;
            x_out_q2 <= x_out_q1; y_out_q2 <= y_out_q1;
            
            if (valid_q1) begin
                x0_q2 <= (x_out_q1 * SCALE_X) >> 8;
                y0_q2 <= (y_out_q1 * SCALE_Y) >> 8;
                a_q2  <= (x_out_q1 * SCALE_X) & 8'hFF;
                b_q2  <= (y_out_q1 * SCALE_Y) & 8'hFF;
                
                inv_a_q2 <= ONE - ((x_out_q1 * SCALE_X) & 8'hFF);
                inv_b_q2 <= ONE - ((y_out_q1 * SCALE_Y) & 8'hFF);
                
                x1_q2 <= (((x_out_q1 * SCALE_X) >> 8) >= IN_W - 1) ? IN_W - 1 : ((x_out_q1 * SCALE_X) >> 8) + 1;
                y1_q2 <= (((y_out_q1 * SCALE_Y) >> 8) >= IN_H - 1) ? IN_H - 1 : ((y_out_q1 * SCALE_Y) >> 8) + 1;
            end

            valid_q3 <= valid_q2;
            x_out_q3 <= x_out_q2; y_out_q3 <= y_out_q2;
            
            if (valid_q2) begin

                p00_q3 <= mem_in[y0_q2 * IN_W + x0_q2];
                p10_q3 <= mem_in[y0_q2 * IN_W + x1_q2];
                p01_q3 <= mem_in[y1_q2 * IN_W + x0_q2];
                p11_q3 <= mem_in[y1_q2 * IN_W + x1_q2];

                w00_q3 <= inv_a_q2 * inv_b_q2;
                w10_q3 <= a_q2     * inv_b_q2;
                w01_q3 <= inv_a_q2 * b_q2;
                w11_q3 <= a_q2     * b_q2;
            end

            valid_q4 <= valid_q3;
            x_out_q4 <= x_out_q3; y_out_q4 <= y_out_q3;
            
            if (valid_q3) begin
               
                 sum_R <= (w00_q3 * p00_q3[23:16]) + (w10_q3 * p10_q3[23:16]) + 
                         (w01_q3 * p01_q3[23:16]) + (w11_q3 * p11_q3[23:16]);
                       
                sum_G <= (w00_q3 * p00_q3[15:8])  + (w10_q3 * p10_q3[15:8]) + 
                         (w01_q3 * p01_q3[15:8])  + (w11_q3 * p11_q3[15:8]);
                
                sum_B <= (w00_q3 * p00_q3[7:0])   + (w10_q3 * p10_q3[7:0]) + 
                         (w01_q3 * p01_q3[7:0])   + (w11_q3 * p11_q3[7:0]);
            end

            if (valid_q4) begin

                mem_out[y_out_q4 * OUT_W + x_out_q4] <= {sum_R[23:16], sum_G[23:16], sum_B[23:16]};
                
                if (x_out_q4 == OUT_W - 1 && y_out_q4 == OUT_H - 1) begin
                    done <= 1;
                    $writememh(OUT_FILE, mem_out);
                end
            end
        end
    end
endmodule