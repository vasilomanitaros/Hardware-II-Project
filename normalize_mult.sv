module normalize_mult(output logic [9:0] normalized_exponent,
                            output logic [22:0] normalized_mantissa,
                            output logic guard,
                            output logic sticky,
                            input logic [47:0] P,
                            input logic [9:0] exp_add);


logic leading_one;
always_comb begin : normalisation
leading_one= P[47];
    if(leading_one) begin
        normalized_exponent= exp_add+1;
        normalized_mantissa= P[46:24];
        guard= P[23];
        sticky= (P[22:0] != 0);
    end
    else begin
        normalized_exponent= exp_add;
        normalized_mantissa= P[45:23];
        guard= P[22];
        sticky= (P[21:0] != 0);
    end

end

endmodule
