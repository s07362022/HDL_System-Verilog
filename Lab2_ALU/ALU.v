// Code your design here
module ALU(
  input  signed [15:0] scr_A_i,
  input  signed [15:0] scr_B_i,
  input  [2:0]  inst_i,
  input  [7:0]  sortNum1_i,
  input  [7:0]  sortNum2_i,
  input  [7:0]  sortNum3_i,
  input  [7:0]  sortNum4_i,
  input  [7:0]  sortNum5_i,
  input  [7:0]  sortNum6_i,
  input  [7:0]  sortNum7_i,
  input  [7:0]  sortNum8_i,
  input  [7:0]  sortNum9_i,
  output reg [7:0]  sortNum1_o,
  output reg [7:0]  sortNum2_o,
  output reg [7:0]  sortNum3_o,
  output reg [7:0]  sortNum4_o,
  output reg [7:0]  sortNum5_o,
  output reg [7:0]  sortNum6_o,
  output reg [7:0]  sortNum7_o,
  output reg [7:0]  sortNum8_o,
  output reg [7:0]  sortNum9_o,
  output reg signed  [15:0] data_o
);

// defind op choose var


localparam [2:0] ADD = 3'b000,
              SUB = 3'b001,
              MUL = 3'b010,
              GLU = 3'b011,
              CLZ = 3'b100,
              SOR = 3'b101;
  
// the max and min signed number
localparam signed [15:0] MAX_VAL = 16'h7FFF,
                         MIN_VAL = 16'h8000;

// mul var
reg signed [31:0] mul_result;
reg signed [15:0] exp_result;
reg signed [15:0] tanh_result;
reg signed [15:0] GeLU_result;

reg loop_exit;
reg overflow;
// Intermediate array to hold the numbers for sorting
reg [7:0] numbers [8:0];

// Output array (after sorting)
reg [7:0] sorted_numbers [8:0];


// defind exp function
function [15:0] exp (
        input [15:0] x
          );

        reg [15:0] x_reg;
        reg [15:0] y_reg; 

        integer i;
  
       
        begin

        y_reg = 0;
        if (x == 1'b0) exp = 0;
        else
        for (i = 0; i < 8; i = i + 1) begin
          x_reg = x;
          y_reg = y_reg + (x_reg >> i);
          // $display("Loop %d: y_reg = %d", i, y_reg);
          x_reg = x_reg - (y_reg >> i);
        

        exp = (y_reg << i) / (1 << i);
        end
        end
endfunction

function [15:0] tanh (
  input [15:0] x
);
  reg [15:0] exp_pos;
  reg [15:0] exp_neg;
  begin
    if (x==1'b0) tanh = 0;
    else
    exp_pos = exp(x);
    exp_neg = exp(-x); 
    tanh = (exp_pos - exp_neg) / (exp_pos + exp_neg);
  end
endfunction

function [15:0] GeLU (
  input [15:0] x
);
  reg [31:0] intermediate1;
  reg [31:0] intermediate2;
  reg [31:0] intermediate3;
  reg [31:0] tanh_input;
  reg [31:0] tanh_result;
  begin
    if (x==1'b0) GeLU =0;
    else 
    intermediate1 = (x * 7979) >> 10; 
    intermediate2 = (x * x * 459) >> 12; 
    tanh_input = intermediate1 * (1 + intermediate2);
    tanh_result = tanh(tanh_input);
    GeLU = (x * (1 + tanh_result)) >> 1; // 0.5 * x * [1 + tanh(...)]
  end
endfunction

function automatic [15:0] count_leading_zeros(input [15:0] value);
  integer i;
  reg [15:0] count;
  begin
    loop_exit = 0;
    count = 0; // Initialize the counter
    for (i = 15; i >= 0 && !loop_exit; i = i - 1) begin
      if (value[i] == 1'b1) begin
        // Once a '1' is encountered, exit the loop
        count = 15 - i;
        loop_exit = 1;
        
      end
    end
    // If no '1' is found, count will remain 8, indicating all zeros
    if (value == 0) begin
      count = 15;
    end
    count_leading_zeros = count;
    // $display("D count_leading_zeros = %d , value = %b", count_leading_zeros, value);
  end
endfunction



function automatic [71:0] insertion_sort(input [71:0] unsorted);
    integer i, j;
    reg [7:0] key;
    reg [7:0] sorted [8:0];
    begin
        // Convert flat input to array
        for (i = 0; i < 9; i = i + 1) begin
            sorted[i] = unsorted[8*i +: 8];
        end

        // Perform insertion sort
        for (i = 1; i < 9; i = i + 1) begin
            key = sorted[i];
            j = i - 1;
            
            while (j >= 0 && sorted[j] > key) begin
                sorted[j + 1] = sorted[j];
                j = j - 1;
            end
            sorted[j + 1] = key;
        end
        
        // Convert array to flat output
        for (i = 0; i < 9; i = i + 1) begin
            insertion_sort[8*i +: 8] = sorted[i];
        end
    end
endfunction



// reg [16:0] add_re;
reg signed [16:0] temp_result;

always @(scr_A_i,scr_B_i,inst_i, sortNum1_i,sortNum2_i,sortNum3_i,sortNum4_i,sortNum5_i,sortNum6_i,sortNum7_i,sortNum8_i,sortNum9_i) begin
    

  case(inst_i)
    ADD: begin
      temp_result = scr_A_i + scr_B_i; // Extended bit to catch overflow/underflow
    
    // Check for overflow and adjust accordingly
    if (temp_result > MAX_VAL) begin
        data_o = MAX_VAL;
    end else if (temp_result < MIN_VAL) begin
        data_o = MIN_VAL;
    end else begin
        data_o = temp_result[15:0]; // No overflow, assign the result
    end
        

    end

    SUB: begin
      temp_result = scr_A_i - scr_B_i;
      // check range of value
      if (temp_result > MAX_VAL) begin
        data_o = MAX_VAL;
      end else if (temp_result < MIN_VAL) begin
        data_o = MIN_VAL;
      end else begin
        data_o = temp_result[15:0]; // No overflow, assign the result
      end
    end
    
    MUL: begin
      mul_result = scr_A_i * scr_B_i;
    
    if (mul_result[25:10] > MAX_VAL) begin
        data_o = MAX_VAL;
    end else if (mul_result[25:10] < MIN_VAL) begin
        data_o = MIN_VAL;
    end else begin
        data_o = mul_result[25:10];

        if (mul_result[14:0] > 15'h4000) begin
            data_o = mul_result[25:10] + 1;
        end else if (mul_result[14:0] == 15'h4000 && mul_result[15]) begin
            data_o = mul_result[25:10] + 1;
        end else begin
            data_o = mul_result[25:10];
        end
    
	end
    end
   
    
    GLU: begin
        //$display("inst_i = %b ,scr_A_i = %d ",inst_i,scr_A_i);
        exp_result  =  exp(scr_A_i);
        tanh_result = tanh(scr_A_i);
        GeLU_result = GeLU(scr_A_i);
        data_o      =   GeLU_result;
        //$display("D scr_A_i = %d", scr_A_i);
        //$display("D data_o = %d", exp_result);
        //$display("D data_o = %d", tanh_result);
        //$display("D data_o = %d", GeLU_result);
         end
     
    CLZ: begin
    
     
     data_o = count_leading_zeros(scr_A_i);
     // $display("CLZ data_o = %b , scr_A_i = %b",data_o,scr_A_i);
     
     end
    
    SOR: begin
     //sortNum1_o = count_leading_zeros(sortNum1_i);
     //sortNum2_o = count_leading_zeros(sortNum2_i);
     //sortNum3_o = count_leading_zeros(sortNum3_i);
     //sortNum4_o = count_leading_zeros(sortNum4_i);
     //sortNum5_o = count_leading_zeros(sortNum5_i);
     //sortNum6_o = count_leading_zeros(sortNum6_i);
     //sortNum7_o = count_leading_zeros(sortNum7_i);
     //sortNum8_o = count_leading_zeros(sortNum8_i);
     //sortNum9_o = count_leading_zeros(sortNum9_i);
     {sortNum9_o, sortNum8_o, sortNum7_o,sortNum6_o, sortNum5_o,sortNum4_o ,sortNum3_o, sortNum2_o,sortNum1_o} = insertion_sort({sortNum1_i, sortNum2_i, sortNum3_i, sortNum4_i, sortNum5_i, sortNum6_i, sortNum7_i, sortNum8_i, sortNum9_i});



         end              
    
    
      




      endcase
end   
endmodule

