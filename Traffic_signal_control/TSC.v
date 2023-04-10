// example from page.7-51


// delay
`define Y2RDELAY 3 //yellow to red delay
`define R2GDELAY 2 //red to green delay

// hwy = main highway, cntry = country road
module sig_control(
    output reg [1:0] hwy,
    output reg [1:0] cntry,
    input x,
    input clock,
    input clear
);

// Light define
parameter RED = 2'b00,
          YELLOW = 2'b01,
          GREEN = 2'b10;

// State define         HWY    CNTRY
parameter S0 = 3'd0, // GREEN  RED
          S1 = 3'd1, // YELLOW RED
          S2 = 3'd2, // RED    RED
          S3 = 3'd3, // RED    GREEN
          S4 = 3'd4; // RED    YELLOW
// state
reg [2:0] state;
reg [2:0] next_state;
always @(posedge clock) begin
    if (clear) begin
        state <= S0;
    end
    else
        state <= next_state;
end

always @(state) begin
    hwy = GREEN;
    cntry = RED;
    case (state)
        S0 : ; //do nothing
        S1 : hwy = YELLOW;
        S2 : hwy = RED;
        S3 : begin
            hwy = RED;
            cntry = GREEN;
        end 
        S4 : begin
            hwy = RED;
            cntry = YELLOW;
        end
    endcase
end
// State machine using case statements
always @(state or x) begin
    case (state)
        S0 : begin
            if(x)
                next_state = S1;
            else
                next_state = S0;    
        end 
        S1 : begin
            repeat(`Y2RDELAY) @(posedge clock);
            next_state = S2;
        end
        S2 : begin
            repeat(`R2GDELAY) @(posedge clock);
            next_state = S3;
        end
        S3 : begin
            if(x)
                next_state = S3;
            else
                next_state = S4;
        end
        S4 : begin
          repeat(`Y2RDELAY) @(posedge clock);
          next_state = S0;
        end      
        default: next_state = S0;
    endcase
end
endmodule