`timescale 1ns / 1ps

module pong_top(
	input clk,
	input reset,
	input[3:0] key, //key[1:0] for player 1,key[3:2] for player 2
//	output[4:0] vga_out_r,
//	output[5:0] vga_out_g,
//	output[4:0] vga_out_b,
	output reg [11:0] rgb,
	output vsync,hsync,
	output dp,
    output[6:0] seg,
    output[3:0] an
    );
	 //FSM for the whole pong game
	 localparam[1:0] newgame=0,
							play=1,
							newball=2,
							over=3;
//	wire clk_out;
	wire video_on;
	wire[9:0] pixel_x,pixel_y;
	wire[2:0] graph_on;
	wire[5:0] text_on;
	wire miss1,miss2;
	wire[11:0] rgb_graph, rgb_text;
//	reg[11:0] rgb;
	reg[1:0] state_q,state_d;
	reg stop;
	wire[2:0] winner;
	reg[3:0] score1_t_q=0,score1_t_d,score1_d_q=0,score1_d_d,score2_t_q=0,score2_t_d,score2_d_q=0,score2_d_d;
	reg[7:0] score1_q,score1_d;
	reg[7:0] score2_q,score2_d;
	reg[7:0] ball_q=0,ball_d;
	reg timer_start;
	wire timer_tick,timer_up;
//    reg[3:0] key = 4'b1111;

	
	//register operation for updating scores and the balls left
	always @(posedge clk) begin
		if(reset) begin
			state_q<=0;
			ball_q<=0;
			score1_t_q<=0;
			score1_d_q<=0;
			score2_t_q<=0;
			score2_d_q<=0;
			score1_q<=0;
			score2_q<=0;
		end
		else begin
			state_q<=state_d;
			ball_q<=ball_d;
			score1_t_q<=score1_t_d;
			score1_d_q<=score1_d_d;
			score2_t_q<=score2_t_d;
			score2_d_q<=score2_d_d;
			score2_t_q<=score2_t_d;
			score2_d_q<=score2_d_d;
			score1_q<=score1_d;
			score2_q<=score2_d;
		end
	end
	
	//FSM next-state logic
	always @* begin
		state_d=state_q;
		ball_d=ball_q;
		score1_t_d=score1_t_q;
		score1_d_d=score1_d_q;
		score2_t_d=score2_t_q;
		score2_d_d=score2_d_q;
		score1_d=score1_q;
		score2_d=score2_q;
		stop=1;
		timer_start=0;
			case(state_q)
				newgame: begin //all scores back to zero and 3 balls will be restored
								ball_d=201;
								score1_t_d=0;
								score1_d_d=0;
								score2_t_d=0;
								score2_d_d=0;
								score1_d = 0;
								score2_d = 0;
								if(key!=4'b1111) begin //only when any of the button is pressed will the game start
									ball_d=ball_q-1;
									state_d=play;   
								end
							end
				   play: begin //start of game
								stop=0;
								if(miss1 ||miss2) begin
									if(miss1) begin
									   if (score2_d_d == 9) begin
									       score2_d_d = 0;
									       score2_t_d = score2_t_q + 1;
									   end
									   else score2_d_d = score2_d_q + 1;
									   score2_d=score2_q+1;
									end //player 2 score increases if player 1 misses
									else begin
									   if (score1_d_d == 9) begin
									       score1_d_d = 0;
									       score1_t_d = score1_t_q + 1;
									   end
									   else score1_d_d = score1_d_q + 1;
									   score1_d=score1_q+1; 
									end //player 1 score increases if player 2 misses
									ball_d= (ball_q ==0)? 0:ball_q-1;
									timer_start=1;
									if(ball_q==0 || score1_d == 99 || score2_d == 99) state_d=over;
									else state_d=newball;
								end
							end
				newball: begin //when any of the player misses, 2 seconds will be alloted before the game can start again
								if(timer_up && key!=4'b1111) state_d=play;
							end
				   over: begin
								if(timer_up) state_d=newgame; //displayes who is the winner
							end
				default: state_d=newgame;
			endcase
	end
	

	//rgb multiplexing 
	always @* begin
		if(!video_on) rgb = 12'h000;
		else begin
			if(text_on[5] || text_on[4] || (text_on[3] && state_q==newgame) || (text_on[2]&& state_q==over) || text_on[0]) rgb=rgb_text; //{score1_on,score2_on,rule_on,win_on,logo_on,ball_on};
			else if(graph_on) rgb=rgb_graph; //{bar_1_on,bar_2_on,ball_on};
			else if(text_on[1]) rgb=rgb_text; //logo is at the last hierarchy since this must be the most underneath text
			else rgb=12'hAAA; //background			
		end
	end
	
//	assign vga_out_r={5{rgb[2]}};
//	assign vga_out_g={6{rgb[1]}};
//	assign vga_out_b={5{rgb[0]}};
	
	assign timer_tick= (pixel_x==0 && pixel_y==481); //60Hz timer tick, this will be used on making a 2 second tick
	assign winner=(score1_q>score2_q)? 1:2;
	
	 vga_core m1
	(
		.clk_100MHz(clk),
		.reset(reset), //clock must be 25MHz for 640x480 
		.video_on(video_on),
		.hsync(hsync),
		.vsync(vsync),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y)
    );
	 
	 
	 pong_animated m2 //control logic for any graphs on the game
	(
		.clk(clk),
		.rst_n(reset),
		.video_on(video_on),
		.stop(stop), //return to default screen with no motion
		.key(key), //key[1:0] for player 1 and key[3:2] for player 2
		.pixel_x(pixel_x),
		.pixel_y(pixel_y),
		.graph_rgb(rgb_graph),
		.graph_on(graph_on),
		.miss1(miss1),
		.miss2(miss2) //miss1=player 1 misses  , miss2=player2 misses
    );
	 
	 
	 pong_text m3 //control logic for any text on the game
	(
		.clk(clk),
		.rst_n(reset),
		.video_on(video_on),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y),
		.winner(winner),
		.score1_t(score1_t_q),
		.score1_d(score1_d_q),
		.score2_t(score2_t_q),
		.score2_d(score2_d_q),
		.ball(ball_q),
		.rgb_text(rgb_text), 
		.rgb_on(text_on) //{score_on,rule_on,gameover_on,logo_on}
    );
	 
	 timer m4 //2 second timer which will be used for "resting" of players before restarting the game
	 (
		.clk(clk),
		.rst_n(reset),
		.timer_start(timer_start),
		.timer_tick(timer_tick),
		.timer_up(timer_up)
    );
    
    wire[3:0] num0;
    wire[3:0] num1;
    wire[3:0] num2;
    wire[3:0] num3;
    
    assign num0 = score2_d_q;
    assign num1 = score2_t_q;
    assign num2 = score1_d_q;
    assign num3 = score1_t_q;
    
    wire targetClk;
    wire an0,an1,an2,an3;
    
    assign an = {an3,an2,an1,an0};
    
    wire [18:0] tclk;
    
    assign tclk[0]=clk;
    
    genvar c;
    generate for(c=0;c<18;c=c+1)
        begin
            clockDiv fdiv(tclk[c+1],tclk[c]);
        end endgenerate
    clockDiv fdivtarget(targetClk,tclk[18]);
    
    quadSevenSeg q7seg(seg,dp,an0,an1,an2,an3,num0,num1,num2,num3,targetClk);


endmodule
