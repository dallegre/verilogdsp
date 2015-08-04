//i2c master module.  8bit.  Need to get a naming convention going with the variables.  
//Need to put in a rw bit for the address transmission.
`timescale 1ns / 1ps

module i2c_master(trig,clk,d0,d1,d2,d3,d4,d5,d6,d7,
	d8,d9,d10,d11,d12,d13,d14,d15,scl,sda,ackOK,txdone);
    
	input  trig,clk,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15;
	wire   trig,clk,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15;
	inout  scl,sda;
	output ackOK,txdone;
	reg    ackOK,txdone;
	reg    sclr,sdar,tsBarScl,tsBarSda,TxStarted,trigPrev,trigPrev2,FiftyKHzQuaPrev,OneHundoKHzClkPrev;
	 
	assign scl = tsBarScl ? sclr : 1'bZ;			//tsbar stands for tristate bar
	assign sda = tsBarSda ? sdar : 1'bZ;			//tsbar stands for tristate bar	 
	 
	 //counter to divide down the 50MHz clock.  Shoot for 50KHz i2c.
	reg [10:0]clkDiv;
	// data register to take data from the 8 inputs (can you just make an 8 bit input?)
	reg [15:0]data;
	//clocks
	reg FiftyKHzClk, FiftyKHzQua, OneHundoKHzClk;
	//state machine counter, 4bit, 16 states max
	reg [5:0]SmCounter;
	 
	initial begin
		ackOK =     1'd0;
		trigPrev =  1'd0;
		txdone =    1'd1;
		tsBarScl =  1'd1;
		tsBarSda =  1'd1;
		TxStarted = 1'd0;
		clkDiv =    11'd1;
		OneHundoKHzClk = 1'd0;
		FiftyKHzClk = 1'd0;
		FiftyKHzQua = 1'd0;
		sclr =      1'd1;						//in i2c these are normally high.
		sdar =      1'd1;
		SmCounter = 6'd0;
	end
	 
	always@(posedge clk)begin
		clkDiv = clkDiv + 11'd1;
		if(clkDiv == 11'd500)begin
			OneHundoKHzClkPrev = OneHundoKHzClk;
			OneHundoKHzClk = ~OneHundoKHzClk;  
			//main i2c clock
			if(OneHundoKHzClk == 1'd1)begin
				FiftyKHzClk = ~FiftyKHzClk;
			end
			//quadrature clock
			if(OneHundoKHzClk == 1'd0)begin
				FiftyKHzQuaPrev = FiftyKHzQua;
				FiftyKHzQua = ~FiftyKHzQua;
				//this should be on the negedge of FiftyKHzQua
				if(FiftyKHzQua == 0 & FiftyKHzQuaPrev == 1)begin			//negedge
					//detect a new trigger
					trigPrev2 = trigPrev;
					trigPrev = trig;
					if(TxStarted == 1'd0 && trig == 1'd1 & trigPrev2 == 1'd0)begin
						SmCounter = 6'd0;					//initialize SmCounter
						TxStarted = 1'd1;					//assert transmission started flag.
						//set the data register
						data = d0 + d1*16'd2 + d2*16'd4 + d3*16'd8 + d4*16'd16 + d5*16'd32 + d6*16'd64 + d7*16'd128 +
							d8*16'd256 + d9*16'd512 + d10*16'd1024 + d11*16'd2048 + d12*16'd4096 + d13*16'd8192 + 
							d14*16'd16384 + d15*16'd32768;
					end
					//detect a trigger that has remained high
					if(TxStarted == 1'd1)begin
						SmCounter = SmCounter + 6'd1;	//increment state
						//roll back to zero if it has reached the end of the valid states
						if(SmCounter == 6'd31)begin
							SmCounter = 4'd0;				//reset state machine counter
							TxStarted = 1'd0;				//de-assert transmission started flag.
							sdar =      1'd1;
						end
						case(SmCounter)
							//for the I2C start condition, sda goes low while scl is high
							1: begin
								sdar =   1'd0;
								txdone = 1'd0;
							end
							2:
								//just hardcode the address in.  00110100
								sdar = 0;
							3:
								sdar = 0;
							4:
								sdar = 1;
							5:
								sdar = 1;
							6:
								sdar = 0;
							7:
								sdar = 1;
							8:
								sdar = 0;
							9:
								sdar = 0;
							10: begin
								tsBarSda = 1'd0;
								ackOK = ~sda;	//do capture on sda pin
							end
							11: begin
								sdar = data[15];
								tsBarSda = 1'd1;
							end
							12:
								sdar = data[14];
							13:
								sdar = data[13];
							14:
								sdar = data[12];
							15:
								sdar = data[11];
							16:
								sdar = data[10];
							17:
								sdar = data[9];
							18:
								sdar = data[8];
							19: begin
								tsBarSda = 1'd0;
								ackOK = ~sda;	//do capture on sda pin
							end
							20: begin
								tsBarSda = 1'd1;
								sdar = data[7];
							end
							21:
								sdar = data[6];
							22:
								sdar = data[5];
							23:
								sdar = data[4];
							24:
								sdar = data[3];
							25:
								sdar = data[2];
							26:
								sdar = data[1];
							27:
								sdar = data[0];
							//for AckCond, set sda to tri state
							28: begin
								tsBarSda =  1'd0;
								ackOK = ~sda;	//do capture on sda pin
							end
							//for the i2c stop condition, sda goes high while sck is high
							29: begin
								sdar =      1'd0;
								tsBarSda =  1'd1;		//return sda to forcing
							end
							30: begin
								sdar =      1'd1;
								TxStarted = 1'd0;
								txdone =    1'd1;
							end
							default: begin
								sdar =      1'd1;
								TxStarted = 1'd0;
								tsBarSda =  1'd1;		//return sda to forcing
								txdone =    1'd1;
							end
						endcase
					end				
				end
			end 
			//this should be on the posedge of 100KHz clock
			if(OneHundoKHzClk == 1 & OneHundoKHzClkPrev == 0)begin
				if(TxStarted == 1'd1 && SmCounter >= 1 && SmCounter < 29)begin	//might be 29
					//set scl register (not literally scl since it's bidirectional) equal to FiftyKHzClk
					sclr = FiftyKHzClk;
				end else begin
					sclr = 1'd1;
				end
			end
			clkDiv = 11'd0;
		end
	end
	
endmodule
