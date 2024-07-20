`timescale 1ns / 1ns
`include "multiplication.sv"

module test_bench();

typedef enum logic[4:0] {pos_inf,neg_inf,pos_zero,neg_zero,pos_snan,neg_snan,pos_qnan,neg_qnan,pos_norm,neg_norm, pos_denorm,neg_denorm} types_t; //enum to produce corner cases
typedef enum logic [2:0] {IEEE_near=3'b000, IEEE_zero=3'b001, IEEE_pinf=3'b010, IEEE_ninf=3'b011,
near_up=3'b100, away_zero=3'b101} mode_t;

function automatic logic[31:0] match(types_t types); //function to produce numbers from corner cases
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
        default: match = 32'b10000000000000000000000000000000;
    endcase
endfunction



string round_str[0:5] = {"IEEE_near","IEEE_zero","IEEE_pinf","IEEE_ninf","near_up","away_zero"}; //matrix for multiplication function

logic clk;

logic [31:0] a,a1,a2; //multiplexer for a and b
logic [31:0] b,b1,b2;
wire  [31:0] z;
logic [31:0] z_real,z1_real,z2_real; //flip flops to delay
wire [7:0] status;
logic [2:0] rnd;
logic rst;
logic false; //false bit to detect errors

logic random_gen,control; //random_gen and control to switch between random and corner cases period of rounding


integer r,k,cnt; //counters for rounding, cnt used for enabling the always block of corner cases generation

logic [63:0] m[0:11][0:11]; // Matrix m for 32-bit logic vectors

fp_mult_top multiplier(.clk(clk), .rst(rst), .rnd(rnd), .a(a), .b(b), .z(z), .status(status));

// bind multiplier test_status_bits test_status_bits_dut(.status(status), .clk(clk));
// bind multiplier test_status_z_combinations test_status_z_combinations_dut(.status(status), .clk(clk), .a(a), .b(b), .z(z));

initial begin
    clk = 0;
    rst = 1;
    #9 rst=0;
    false=0;
    k=0; r=0;
    random_gen=1;
    cnt=0;
end

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
    if (cnt>=58) begin
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
end


always begin
    #7.5 clk = ~clk;
end


always @(posedge clk) begin
    if (rst==1) begin
        a<=32'b0;
        b<=32'b0;
        rnd<=3'b000;
        k<=0;
        r<=0;
    end else begin
    cnt<=cnt+1;
    a1=$urandom();
    b1=$urandom();
    a2=current_value[31:0];
    b2=current_value[63:32];
    a=(random_gen==1 || control==1)?a1:a2;
    b=(random_gen==1 || control==1)?b1:b2;
    rnd=k[2:0];
    z_real<=multiplication(round_str[k],a,b);
    z1_real <= z_real;
    z2_real <=z1_real;
    if (z2_real != z) begin 
        false<=1;
    end else begin
        false<=0;
    end
    r<=r+1;

if (random_gen==1) begin
    if (r==9) begin
        r<=0;
        if (k==5) begin
            k<=0;

        end else begin
            k<=k+1;
        end
    end
end
else if (random_gen==0) begin
    if (control==1) begin
        r<=0;
        k<=0;
        control<=0;
    end
        if (r==144) begin
        r<=0;
        if (k==5) begin
            k<=0;
            $display("Everything is correct!");
            $finish;
        end else begin
            k<=k+1;
        end
    end
end
    end
if (k==5 && r==8 && random_gen==1) begin
    random_gen<=0;
    control<=1;
end

end


always @(posedge clk) begin
if (false==1'b1) begin
    $fatal("Error! z=%b, z2_real=%b",z,z2_real);
end
end


endmodule
