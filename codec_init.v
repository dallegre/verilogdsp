//you should probably fix the i2c_master module to have a txDone flag or something.

`timescale 1ns / 1ps

module codec_init(clk,reset,scl,sda,led);

	input  clk,reset;
	wire   clk,reset;
	output led;
	inout  scl,sda;
	wire   scl,sda;
	wire   ackOK,txdone;
	reg    led;
	
	reg    [7:0]data;
	reg    [7:0]addr;
	reg	 [15:0]senddata;
	reg	 trigger, initDone;
	reg    [17:0]counter;		//big variable to implement delays and such.
	reg    [6:0]counter2;
	reg    [7:0]rw;

	//the way I wrote i2c_master, it'll just take the 50MHz clock in directly.
	i2c_master codec_i2c(
		.trig(trigger),			//note the things inside the parentheses are the top level variables
		.clk(clk),					//the things with the dot are the arguments to the module
		.d0(senddata[0]),
		.d1(senddata[1]),
		.d2(senddata[2]),
		.d3(senddata[3]),
		.d4(senddata[4]),
		.d5(senddata[5]),
		.d6(senddata[6]),
		.d7(senddata[7]),
		.d8(senddata[8]),
		.d9(senddata[9]),
		.d10(senddata[10]),
		.d11(senddata[11]),
		.d12(senddata[12]),
		.d13(senddata[13]),
		.d14(senddata[14]),
		.d15(senddata[15]),
		.scl(scl),
		.sda(sda),
		.ackOK(ackOK),
		.txdone(txdone));
		
	initial begin
		rw = 		  8'd0;
		data =     8'd0;
		addr =     16'd0;
		senddata = 8'd0;
		trigger =  1'd0;
		led =      1'd0;
		counter =  18'd0;
		counter2 = 7'd0;
	end
	
	always@(posedge clk)begin
		if(reset == 1'd1)begin
				counter =  18'd0;
				data =     8'd0;
				counter2 = 7'd0;
				trigger =  1'd1;
		end
		else begin
			counter = counter + 18'd1;
			if(counter == 50000)begin
				counter = 0;
				if(counter2 < 120)begin					//just stop counting after the first time it's gone through.
					counter2 = counter2 + 7'd1;
				end
			end
			case(counter2)
				//first register write (ID, addr, data).  Write 
				4: begin
					trigger = 1'd1;				//addresses aren't working.
					addr = 8'h0c;			//power reduction register
					data = 8'h00;			//turn everything on
					senddata = addr << 8 | data;
			   end
				5: begin
					trigger = 1'd0;
				end

				//another register write
				7: begin
					trigger = 1'd1;
					addr = 8'h0e;			//digital data format
					data = 8'h03;			//16b spi mode
					senddata = addr << 8 | data;
			   end
				8: begin
					trigger = 1'd0;
				end
				
				//another register write
				14: begin
					trigger = 1'd1;
					addr = 8'h00;			//left in register
					data = 8'h17;			//
					senddata = addr << 8 | data;
			   end
				15: begin
					trigger = 1'd0;
				end

				//another register write
				17: begin
					trigger = 1'd1;
					addr = 8'h02;			//right in register
					data = 8'h17;			//
					senddata = addr << 8 | data;
			   end
				18: begin
					trigger = 1'd0;
				end
				
				//another register write
				24: begin
					trigger = 1'd1;
					addr = 8'h04;			//left hp register
					data = 8'h70;			//
					senddata = addr << 8 | data;
			   end
				25: begin
					trigger = 1'd0;
				end

				//another register write
				27: begin
					trigger = 1'd1;
					addr = 8'h06;			//right hp register
					data = 8'h70;			//
					senddata = addr << 8 | data;
			   end
				28: begin
					trigger = 1'd0;
				end

				//another register write
				34: begin
					trigger = 1'd1;
					addr = 8'h0a;			//digital audio path
					data = 8'h00;			//
					senddata = addr << 8 | data;
			   end
				35: begin
					trigger = 1'd0;
				end

				//another register write
				37: begin
					trigger = 1'd1;
					addr = 8'h08;			//analog audio config
					data = (0 << 6)|(0 << 5)|(1 << 4)|(0 << 3)|(0 << 2)|(1 << 1)|(0 << 0);   //from the open music labs library
					senddata = addr << 8 | data;
			   end
				38: begin
					trigger = 1'd0;
				end
				
				//another register write
				44: begin
					trigger = 1'd1;
					addr = 8'h10;			//sampling frequency
					data = 8'h00;			//22KHz
					senddata = addr << 8 | data;
			   end
				45: begin
					trigger = 1'd0;
				end
				
			endcase
		end
		led = ackOK;
	end
		
endmodule
