module exception_mult (output logic [31:0] z,
                        output logic zero_f,output logic inf_f,output logic nan_f,
                        output logic tiny_f,output logic huge_f,output logic inexact_f,
                        input logic [31:0] a,
                        input logic [31:0] b,
                        input logic [31:0] z_calc,
                        input logic [2:0] rnd,
                        input logic overflow, input logic underflow,input logic inexact);


typedef enum logic[2:0] {ZERO,INF,NORM,MIN_NORM,MAX_NORM} interp_t;
typedef enum logic [2:0] {IEEE_near=3'b000, IEEE_zero=3'b001, IEEE_pinf=3'b010, IEEE_ninf=3'b011,
near_up=3'b100, away_zero=3'b101} mode_t;

mode_t md;

function automatic interp_t num_interp(logic [31:0] a);
    if (a[30:23]==8'b00000000) begin
        num_interp = ZERO;
    end
    else if (a[30:23] == 8'b11111111) begin
            num_interp = INF;
    end
    else  begin
        num_interp = NORM;
    end
endfunction

function automatic logic [30:0] z_num(interp_t interp);
    case (interp)
        ZERO: z_num = 31'b0;
        INF: z_num = {8'b11111111,23'b0};
        MIN_NORM: z_num = {8'b00000001,23'b0};
        MAX_NORM: z_num = {8'b11111110,23'b11111111111111111111111};
        default: z_num = 31'b0;
    endcase
endfunction

interp_t a_interp;
interp_t b_interp;

always_comb begin:exception

zero_f= 1'b0;
inf_f= 1'b0;
nan_f= 1'b0;
tiny_f= 1'b0;
huge_f= 1'b0;
inexact_f= 1'b0;


md = mode_t'(rnd);
zero_f = 1'b0;
inf_f = 1'b0;
nan_f = 1'b0;
tiny_f = 1'b0;
huge_f = 1'b0;
inexact_f = 1'b0;

a_interp = num_interp(a);
b_interp = num_interp(b);

case(a_interp)
    ZERO: begin
        if (b_interp == INF) begin
            inf_f= 1'b1;
            nan_f= 1'b1;
            z={1'b0,z_num(INF)};
        end
        else begin
            z={z_calc[31],z_num(ZERO)};
            zero_f= 1'b1;
        end
    end
    INF: begin
        if (b_interp == ZERO) begin
            z={1'b0,z_num(INF)};
            inf_f= 1'b1;
            nan_f= 1'b1;
        end
        else begin
            z={z_calc[31],z_num(INF)};
            inf_f= 1'b1;
        end
    end
    NORM: begin
        if (b_interp == INF) begin
            z={z_calc[31],z_num(INF)};
            inf_f= 1'b1;
        end
        else if (b_interp == ZERO) begin
            z={z_calc[31],z_num(ZERO)};
            zero_f= 1'b1;
        end
        else begin
            if (overflow) begin
            huge_f= 1'b1;
            inexact_f= 1'b1;
        if ((md == away_zero) || (md == IEEE_near)) begin
            z={z_calc[31], z_num(INF)};
            inf_f= 1'b1;
        end else if ((md == IEEE_zero)) begin
            z={z_calc[31], z_num(MAX_NORM)};
            end else if (((md == IEEE_pinf) && !z_calc[31]) || (md == IEEE_ninf && z_calc[31])) 
        begin
            z={z_calc[31], z_num(INF)};
            inf_f= 1'b1;
        end else if (md == near_up) begin 
            z={z_calc[31], z_num(INF)};
            inf_f= 1'b1;
        end else begin
            z={z_calc[31], z_num(MAX_NORM)};
        end
    end else if (underflow) begin
        tiny_f= 1'b1;
        inexact_f= 1'b1;
        if ((md == IEEE_near)) begin
            z={z_calc[31], z_num(ZERO)};
            zero_f= 1'b1;
        end else if ((md == away_zero)) begin
            z={z_calc[31], z_num(MIN_NORM)};
        end else if ((md == IEEE_zero)) begin
             z={z_calc[31], z_num(ZERO)};
             zero_f= 1'b1;
        end else if(md==near_up) begin
            z={z_calc[31], z_num(ZERO)};
        end
         else if (((md == IEEE_pinf) && !z_calc[31]) || (md == IEEE_ninf && z_calc[31])) 
        begin
             z={z_calc[31], z_num(MIN_NORM)};
        end else if (md == near_up) begin 
            z={z_calc[31], z_num(ZERO)};
            zero_f= 1'b1;
        end else begin
            z={z_calc[31], z_num(ZERO)};
            zero_f=1'b1;
        end 
    end else begin
        z=z_calc;
        inexact_f= inexact;
    end
        end
    end
    default: begin
        z={z_calc[31],8'b11111111,23'b11111111111111111111110}; //a random nan should never reach
        nan_f= 1'b1;
    end
endcase
end

endmodule
