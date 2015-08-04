`timescale 1ns / 1ps

module testbench;

	// Inputs
	reg clk;
	reg reset;

	// Outputs
	wire scl;
	wire sda;
	wire led;

	// Instantiate the Unit Under Test (UUT)
	codec_init uut (
		.clk(clk), 
		.reset(reset), 
		.scl(scl), 
		.sda(sda), 
		.led(led)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here
	end
	
	always begin
		#20
		clk = ~clk;
	end
      
endmodule
