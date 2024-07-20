`timescale 1ns / 1ps

module test_status_bits(input logic [7:0] status, input clk);

always @(posedge clk) begin
    if (status!== 8'bx) begin
        zero_infinity: assert (!(status[0] && status[1]))   else $fatal("Zero and Infinity both asserted.");
        invalid_zero: assert (!(status[0] && status[2]))    else $fatal("Zero and Invalid both asserted.");
        zero_huge: assert (!(status[0] && status[4]))       else $fatal("Zero and Huge both asserted.");
        invalid_tiny: assert (!(status[3] && status[2]))    else $fatal("Tiny and Invalid both asserted.");   
        invalid_huge: assert (!(status[4] && status[2]))    else $fatal("Huge and Invalid both asserted.");
        invalid_inexact: assert (!(status[5] && status[2])) else $fatal("Inexact and Invalid both asserted.");
        infinity_tiny: assert (!(status[1] && status[3]))   else $fatal("Infinity and Tiny both asserted.");
        tiny_huge: assert (!(status[3] && status[4]))       else $fatal("Tiny and Huge both asserted.");
    end
end

endmodule


module test_status_z_combinations(input logic [7:0] status, input clk,input logic [31:0] a, input logic [31:0] b, input logic [31:0] z);

logic [7:0] exp_a, exp_b, exp_z;
logic [22:0] mant_a, mant_b, mant_z;

always_comb begin
exp_a = a[30:23];
exp_b = b[30:23];
exp_z = z[30:23];
mant_a = a[22:0];
mant_b = b[22:0];
mant_z = z[22:0];
end

property zero_exp;
    @(posedge clk) (status[0] |-> exp_z === 8'b0);
endproperty
assert property (zero_exp) else $fatal("Zero Raised incorrectly exp_z=%b", exp_z);

property inf_exp;
    @(posedge clk) (status[1] |-> exp_z === 8'b11111111);
endproperty
assert property (inf_exp) else $fatal("Infinity Raised incorrectly exp_z=%b", exp_z);

property nan_exp;
    @(posedge clk) (status[2] |-> ($past(exp_a, 2) === 8'b0 && $past(exp_b, 2) === 8'b11111111 )|| ($past(exp_a, 2) === 8'b11111111 && $past(exp_b, 2) === 8'b0));
endproperty
assert property (nan_exp) else $fatal("NaN Raised incorrectly exp_a=%b, exp_b=%b", $past(exp_a, 2), $past(exp_b, 2));

property huge_exp;
    @(posedge clk) (status[4] |-> (exp_z === 8'b11111111) || (exp_z===8'b11111110 && mant_z === 23'b11111111111111111111111));
endproperty
assert property (huge_exp) else $fatal("Huge Raised incorrectly exp_z=%b mant_z=%b", exp_z,mant_z);

property tiny_exp;
    @(posedge clk) (status[3] |-> (exp_z === 8'b0) || (exp_z === 8'b00000001 && mant_z === 23'b0));
endproperty
assert property (tiny_exp) else $fatal("Tiny Raised incorrectly exp_z=%b mant_z=%b", exp_z,mant_z);

endmodule



module assertions();

    logic rst;
    logic clk;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] z;
    logic [7:0] status;
    logic [2:0] rnd;

   fp_mult_top multiplier(.clk(clk), .rst(rst), .rnd(rnd), .a(a), .b(b), .z(z), .status(status));

    // Bind the assertion module to the DUT
    
bind multiplier test_status_bits test_status_bits_dut(.status(status), .clk(clk));
bind multiplier test_status_z_combinations test_status_z_combinations_dut(.status(status), .clk(clk), .a(a), .b(b), .z(z));

    initial begin
        clk = 0;
        rst = 1;
        #9 rst=0;
        rnd = 3'b000;
    end

    always begin
        #7.5 clk = ~clk;
    end




//Gennitria

typedef enum logic[4:0] {pos_inf,neg_inf,pos_zero,neg_zero,pos_snan,neg_snan,pos_qnan,neg_qnan,pos_norm,neg_norm, pos_denorm,neg_denorm} types_t;
logic [63:0] m[0:11][0:11];
types_t type_a, type_b;
logic [31:0] a_val, b_val;
initial begin
        // Nested loop to generate all combinations
        for (int i = 0; i < 12; i++) begin
            for (int j = 0; j < 12; j++) begin
                type_a = types_t'(i);
                type_b = types_t'(j);
                a_val = match(type_a);
                b_val = match(type_b);
                m[i][j] = {a_val, b_val};
            end
        end
    end
integer i, j;
logic [63:0] current_value;
always @(posedge clk) begin
        begin
            // Update current_value with the value from the matrix
            current_value <= m[i][j];
            type_b<=types_t'(i);
            type_a<=types_t'(j);
            // Update indices to move to the next matrix element
            if (j < 11) begin
                j <= j + 1;
            end else begin
                j <= 0;
                if (i < 11) begin
                    i <= i + 1;
                end else begin
                    i <= 0; // Reset to the beginning if the end is reached
                end
            end
        end
end

function automatic logic[31:0] match(types_t types);
    case (types)
        pos_inf: match = 32'b01111111100000000000000000000000;
        neg_inf: match = 32'b11111111100000000000000000000000;
        pos_zero: match = 32'b00000000000000000000000000000000;
        neg_zero: match = 32'b10000000000000000000000000000000;
        pos_snan: match = 32'b01111111100000000000000000000001;
        neg_snan: match = 32'b11111111100000000000000000000001;
        pos_qnan: match = 32'b01111111110000000000000000000000;
        neg_qnan: match = 32'b11111111110000000000000000000000;
        pos_norm: match = 32'b01111111000000000000000000000001;
        neg_norm: match = 32'b11111111000000000000000000000001;
        pos_denorm: match = 32'b00000000000000000000000000000001;
        neg_denorm: match = 32'b10000000000000000000000000000001;
        default: match = 32'b10000000000000000000000000000000; //pos_zero
    endcase
endfunction


always @(posedge clk) begin
    a = $urandom;
    b = $urandom;
    // a = current_value[31:0];
    // b = current_value[63:32];

end


endmodule