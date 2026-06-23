`timescale 1ns / 1ps

module tb_bilinear_scaler;

    parameter IN_W  = 100;
    parameter IN_H  = 100;
    parameter OUT_W = 400; 
    parameter OUT_H = 400;

    reg clk;
    reg rst_n;
    reg start;

    wire done;

    bilinear_scaler_rgb #(
        .IN_W(IN_W),
        .IN_H(IN_H),
        .OUT_W(OUT_W),
        .OUT_H(OUT_H),
        .IN_FILE("D:/EES/I-CHIP/PS-1/scripts/image_in_24b.hex"),   
        .OUT_FILE("D:/EES/I-CHIP/PS-1/scripts/image_out_24b.hex")
    ) uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
  
        clk = 0;
        rst_n = 0;
        start = 0;
        #100;
        rst_n = 1;
        #20;

        $display("Starting Simulation...");
        start = 1;
        #10;
        start = 0;

        wait(done == 1);
        
        $display("Simulation Finished Successfully.");
        #100;
        $finish;
    end

endmodule