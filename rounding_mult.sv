typedef enum logic [2:0] {IEEE_near=3'b000, IEEE_zero=3'b001, IEEE_pinf=3'b010, IEEE_ninf=3'b011,
near_up=3'b100, away_zero=3'b101} mode_t;

module rounding_mult( output logic [24:0] result,
                        output logic inexact,
                        input logic [23:0] normalized_mantissa,
                        input logic [2:0] rnd,
                        input logic guard,input logic sticky, input logic sign);

always_comb begin : type_casting
logic addition;
mode_t md;
md = mode_t'(rnd);

inexact= (sticky | guard); //or gate
    case (md)
        IEEE_near:  addition = guard && (sticky || normalized_mantissa[0]);
        IEEE_zero: addition = 0;
        IEEE_pinf: addition = !sign && inexact;
        IEEE_ninf: addition = sign && inexact;
        near_up: addition = guard && (!sign || sticky);
        away_zero: addition = inexact;
        default: addition = guard && (sticky || normalized_mantissa[0]);
    endcase

    if (addition) begin
            result = normalized_mantissa + 1;
    end
    else begin
        result = normalized_mantissa;
    end

end

endmodule
