module fp_mult( input logic [31:0] a,
                    input logic [31:0] b,
                    input logic [2:0] rnd,
                    output logic [31:0] z,
                    output logic [7:0] status);



logic [23:0] mantissa_a, mantissa_b;
logic [22:0] normalized_mantissa_result;
logic [9:0] normalized_exponent_result;
logic [7:0] exponent_a, exponent_b;
logic [9:0] exp_add;
logic sign_a,sign_b,sign;
const logic [9:0] bias= 127;
logic [47:0] mantissa_mult;
logic guard,sticky,inexact;
logic [24:0] result;
logic [23:0] normalized_mantissa;
logic [2:0] md;
logic overflow,underflow;
logic [9:0] temp;
logic addition;
logic [23:0] post_rounded_mantissa;

always_comb begin
mantissa_a={1'b1,a[22:0]};
mantissa_b={1'b1,b[22:0]};
exponent_a=a[30:23];
exponent_b=b[30:23];
sign_a= a[31]; sign_b= b[31];
status[6]=0; //inexact flag
status[7]=0; //overflow flag

//floating point sign calculation
sign= sign_a ^ sign_b;
//floating point exponent addition

exp_add= exponent_a + exponent_b - bias;
//floating point mantissa multiplication
mantissa_mult= mantissa_a * mantissa_b;

//handling of mantissa overflow (in case rounding gives an integer)
addition=((result[24] == 1))? 1'b1 : 1'b0;
temp = normalized_exponent_result+addition;
//shift right to include the leading one by definition (in any case we truncate it)
if (addition) begin
    post_rounded_mantissa = result>>1; 
end else post_rounded_mantissa = result;


overflow = ($signed(temp) > $signed(254));
underflow = ($signed(temp) < $signed(1));

end
//normalisation module
normalize_mult n1(.normalized_exponent(normalized_exponent_result),
                                                .normalized_mantissa(normalized_mantissa_result),
                                                .guard(guard),
                                                .sticky(sticky),
                                                .P(mantissa_mult),
                                                .exp_add(exp_add));
//rounding module
rounding_mult r1(.result(result),
                   .inexact(inexact),
                   .normalized_mantissa({1'b1,normalized_mantissa_result}),
                   .rnd(rnd),
                   .guard(guard),
                   .sticky(sticky),
                   .sign(sign));

exception_mult e1(.z(z),
                    .zero_f(status[0]),
                    .inf_f(status[1]),
                    .nan_f(status[2]),
                    .tiny_f(status[3]),
                    .huge_f(status[4]),
                    .inexact_f(status[5]),
                    .a(a),
                    .b(b),
                    .z_calc({sign,temp[7:0],post_rounded_mantissa[22:0]}),
                    .rnd(rnd),
                    .overflow(overflow),
                    .underflow(underflow),
                    .inexact(inexact));

endmodule
