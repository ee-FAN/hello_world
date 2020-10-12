module preview_shoot
(
	input i_reset,
	input wire i_clk,
	input i_device_cancel,//设备取消操作信号
	input i_pre_shoot_start_trig, //来自Cent_Ctrl模块的预览模式启动信号
	input i_pre_shoot_mode_set_trig,//来自Cent_Ctrl模块的预览模式出图参数设置
	input [7:0] i_pre_shoot_mode_value,//来自Cent_Ctrl模块的预览模式出图三叔
	input i_single_shoot_end_trig,//来自射源模块的单图触发结束信号
	output reg o_pre_shoot_end_trig,//预览模式结束信号，送往Cent_Ctrl模块
	output reg o_single_shoot_start_trig,//预览模式开始信号，送往射源模块


	input i_pre_shoot_DJ_90_location_end,//90度定位结束
	output reg o_pre_shoot_DJ_90_location,//电机定位到90度
	output reg o_pre_shoot_DJ_init_trig,//电机回原点
	input i_pre_shoot_DJ_init_end,//电机回原点结束标志 
	output reg o_pre_shoot_DJ_stop_trig,//电机停止信号
	// input i_pre_shoot_DJ_stop_end,//电机停止结束	
	input  i_pre_shoot_DJ_error_flag, //电机错误标志
	output reg o_pre_shoot_error_no_xray_end,//无射线结束信号
	output reg o_pre_shoot_error_no_DJ_end,//无电机定位结束信号
	output reg o_pre_shoot_mode_cancel,

	output reg o_pre_shoot_0_start, //零度拍摄开始
	output reg o_pre_shoot_0_end//零度拍摄结束


);

reg [7:0] r_pre_shoot_mode_value;
reg [7:0] state;
parameter NO_XRAY_END_TIME = 16'd4000 ;
parameter NO_DJ_END_TIME = 16'd12000;
reg             r_timer_en;
wire [15:0]      timer_ms;
timer_1ms no_end_trig_timer(
    .i_clk_40m  ( i_clk ),
    .i_en       ( r_timer_en ),
    .o_value    ( timer_ms )
);
//预览模式参数设置
always @(posedge i_clk or posedge i_reset)
begin
	if(i_reset)
	begin
	  r_pre_shoot_mode_value[7:0] <= 8'd0;
	end
	else
	begin
	  if(i_pre_shoot_mode_set_trig)
	  begin
		r_pre_shoot_mode_value[7:0] <= i_pre_shoot_mode_value[7:0];
	  end
	  else
	  begin
		r_pre_shoot_mode_value[7:0] <= r_pre_shoot_mode_value[7:0];
	  end
	end
end
always @(posedge i_clk or posedge i_reset)
begin
	if(i_reset)
	begin
		o_single_shoot_start_trig <= 1'd0;
	  	o_pre_shoot_end_trig <= 1'd0;	  
	  	o_pre_shoot_DJ_90_location <= 1'd0;
		o_pre_shoot_DJ_stop_trig <= 1'd0;
		o_pre_shoot_DJ_init_trig <= 1'b0;
	  	state <= 8'd0;
		r_timer_en <= 1'b0;
		o_pre_shoot_mode_cancel <= 1'b0;
		o_pre_shoot_error_no_xray_end <= 1'b0;
		o_pre_shoot_error_no_DJ_end <= 1'b0;
		o_pre_shoot_0_start <= 1'b0;
		o_pre_shoot_0_end <= 1'b0;
	end
	else
	begin
	  	if(i_device_cancel && (state != 8'd0))
	  	begin
	  	  	o_single_shoot_start_trig <= 1'd0;
	  	  	o_pre_shoot_end_trig <= 1'd0;	  
	  	 	o_pre_shoot_DJ_90_location <= 1'd0;
			o_pre_shoot_DJ_init_trig <= 1'b0;
		  	o_pre_shoot_DJ_stop_trig <= 1'd1;//电机运动停止信号
			r_timer_en <= 1'b0;
			o_pre_shoot_error_no_xray_end <= 1'b0;
			o_pre_shoot_error_no_DJ_end <= 1'b0;
			o_pre_shoot_mode_cancel <= 1'b1;//预览模式终止信号
			o_pre_shoot_0_start <= 1'b0;
			o_pre_shoot_0_end <= 1'b0;
		  	state <= 8'd0;
	  	end
	  	else 
	  	begin
			case(state)
				8'd0:
				begin
					o_single_shoot_start_trig <= 1'd0;
					o_pre_shoot_end_trig <= 1'd0;	 
					o_pre_shoot_DJ_90_location <= 1'd0; 
					o_pre_shoot_DJ_init_trig <= 1'b0;
					o_pre_shoot_DJ_stop_trig<= 1'd0;//电机运动停止信号
					o_pre_shoot_mode_cancel <= 1'b0;//预览模式终止信号
					r_timer_en <= 1'b0;
					o_pre_shoot_error_no_xray_end <= 1'b0;
					o_pre_shoot_error_no_DJ_end <= 1'b0;
					o_pre_shoot_0_start <= 1'b0;
					o_pre_shoot_0_end <= 1'b0;
					// state <= state + 1'd1;
					if(i_pre_shoot_start_trig)
					begin
						state <= state + 1'd1;
					end
					else
					begin
						state <= state;
					end
				end
				8'd1:
				begin
					// if(i_pre_shoot_start_trig)
					// begin			
				  	case(r_pre_shoot_mode_value[7:0])
						8'd1://原点时拍摄一张图
						begin
							state <= state + 1'd1;
						end
						8'd2://90度时拍摄一张图
						begin
							state <= 8'd4;
						end
						8'd3://0度和90度时各拍摄一张图
						begin
							state <= 8'd10;
						end
						default:
						begin
							state <= 8'd0;
						end
					endcase
					// end
					// else
					// begin
					// 	state <= state;
					// end	
				end
				//预览模式在0度拍摄
				8'd2://原点拍摄开始
				begin
					o_single_shoot_start_trig <= 1'b1;
					o_pre_shoot_0_start <= 1'b1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;
				end
				8'd3:
				begin
					o_single_shoot_start_trig <= 1'b0;
					o_pre_shoot_0_start <= 1'b0;
					if(i_single_shoot_end_trig)
					begin
						o_pre_shoot_end_trig <= 1'b1;//拍摄结束标志，送往Cent_Ctrl模块
						o_pre_shoot_0_end <= 1'b1;
						state <= 8'd0;
					end
					else if(timer_ms == NO_XRAY_END_TIME)//4秒内未接收到i_single_shoot_end_trig，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_xray_end <= 1'b1;
					 	state <= 8'd0;
					end
					else 
					begin
						state <= state;
					end
					// if(timer_ms == NO_XRAY_END_TIME)//2秒内未接收到i_single_shoot_end_trig，跳回初始状态：8'd0;
					// begin
					// 	o_pre_shoot_error_no_xray_end <= 1'b1;
					// 	state <= 8'd0;
					// end					
				end
		
				//预览模式在90度拍摄
				8'd4://90度定位开始
				begin
					o_pre_shoot_DJ_90_location <= 1'd1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;	   
				end
				8'd5://判断定位是否结束
				begin
					o_pre_shoot_DJ_90_location <= 1'd0;
					if(i_pre_shoot_DJ_90_location_end)
					begin
						r_timer_en <= 1'b0;
						state <= state + 1'd1;
					end
					else if(i_pre_shoot_DJ_error_flag)
					begin
						state <= 8'd0;
					end
					else if(timer_ms >= NO_DJ_END_TIME)//12秒内未接收到i_DJ_90_location_end，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_DJ_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;  
					end	
				end
				8'd6://触发射线
				begin
					o_single_shoot_start_trig <= 1'd1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;
				end
				8'd7://等待射线结束
				begin
					o_single_shoot_start_trig <= 1'd0;
					if(i_single_shoot_end_trig)
					begin
						r_timer_en <= 1'b0;
						state <= state + 1'd1;
					end
					else if(timer_ms >= NO_XRAY_END_TIME)//4秒内未接收到i_single_shoot_end_trig，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_xray_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;	  
					end
				end
				8'd8://电机回原点
				begin
					o_pre_shoot_DJ_init_trig <= 1'b1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;
				end
				8'd9://等待电机回到原点
				begin
					o_pre_shoot_DJ_init_trig <= 1'b0;
					if(i_pre_shoot_DJ_init_end)
					begin
						o_pre_shoot_end_trig <= 1'd1;
						state <= 8'd0;
					end
					else if(i_pre_shoot_DJ_error_flag)
					begin
						state <= 8'd0;
					end
					else if(timer_ms >= NO_DJ_END_TIME)//12秒内未接收到i_DJ_init_location_end，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_DJ_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;  
					end
				end
		
				//预览模式在0度和90度各拍一张
				8'd10://原点拍摄开始
				begin
					o_single_shoot_start_trig <= 1'd1;
					o_pre_shoot_0_start <= 1'b1;
					r_timer_en <= 1'b1;
					state <= state +1'd1;
				end
				8'd11://等待拍摄结束
				begin
					o_single_shoot_start_trig <= 1'd0;
					o_pre_shoot_0_start <= 1'b0;
					if(i_single_shoot_end_trig)//拍摄结束标志，送往Cent_Ctrl模块
					begin
						r_timer_en <= 1'b0;
						state <= state + 1'd1;
					end
					else if(timer_ms >= NO_XRAY_END_TIME)//4秒内未接收到i_single_shoot_end_trig，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_xray_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;	  
					end
				end
				8'd12://90度定位开始
				begin
					o_pre_shoot_DJ_90_location <= 1'd1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;
				end
				8'd13://等待定位到90度结束
				begin
					o_pre_shoot_DJ_90_location <= 1'd0;
					if(i_pre_shoot_DJ_90_location_end)
					begin
						r_timer_en <= 1'b0;
						state <= state + 1'd1;
					end
					else if(i_pre_shoot_DJ_error_flag)
					begin
						state <= 8'd0;
					end
					else if(timer_ms >= NO_DJ_END_TIME)//12秒内未接收到i_DJ_init_location_end，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_DJ_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;  
					end
				end
				8'd14://90度拍摄开始
				begin
					o_single_shoot_start_trig <= 1'd1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;
				end
				8'd15://等待拍摄结束
				begin
					o_single_shoot_start_trig <= 1'd0;
					if(i_single_shoot_end_trig)//拍摄结束标志，送往Cent_Ctrl模块
					begin
						r_timer_en <= 1'b0;
						state <= state + 1'd1;
					end
					else if(timer_ms >= NO_XRAY_END_TIME)//4秒内未接收到i_single_shoot_end_trig，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_xray_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;	  
					end
				end
				8'd16://电机回原点
				begin
					o_pre_shoot_DJ_init_trig <= 1'b1;
					r_timer_en <= 1'b1;
					state <= state + 1'd1;
				end
				8'd17://等待回原点结束
				begin
					o_pre_shoot_DJ_init_trig <= 1'b0;
					if(i_pre_shoot_DJ_init_end)
					begin
						o_pre_shoot_end_trig <= 1'd1;
						state <= 8'd0;
					end
					else if(i_pre_shoot_DJ_error_flag)
					begin
						state <= 8'd0;
					end
					else if(timer_ms >= NO_DJ_END_TIME)//12秒内未接收到i_DJ_init_location_end，跳回初始状态：8'd0;
					begin
						o_pre_shoot_error_no_DJ_end <= 1'b1;
						state <= 8'd0;
					end
					else 
					begin
						// r_timer_en <= 1'b1;
						state <= state;  
					end
				end
				default:
				begin
					o_single_shoot_start_trig <= 1'd0;
					o_pre_shoot_end_trig <= 1'd0;	  
					o_pre_shoot_DJ_90_location <= 1'd0;
					o_pre_shoot_DJ_init_trig <= 1'b0;
					o_pre_shoot_DJ_stop_trig <= 1'd0;
					state <= 8'd0;
				end
		  	endcase
	  	end 
	end
end
endmodule 