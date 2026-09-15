`default_nettype none

module spi_peripheral (
    input  wire COPI,
    input  wire nCS,
    input  wire SCLK,
    input  wire rst_n,
    input  wire clk,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
    
    reg [3:0] num_bits;

    reg [15:0] data;

    reg COPI1, COPI2;
    reg nCS1, nCS2, nCS3;
    reg SCLK1, SCLK2, SCLK3;
    reg transaction_ready, transaction_processed;
    reg ready_to_process = transaction_ready && !transaction_processed && num_bits > 4'd15 && data[15];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            COPI2 <= 0;
            COPI1 <= 0;
            nCS3 <= 1;
            nCS2 <= 1;
            nCS1 <= 1;
            SCLK3 <= 0;
            SCLK2 <= 0;
            SCLK1 <= 0;
        end else begin
            COPI2 <= COPI1;
            COPI1 <= COPI;
            nCS3 <= nCS2;
            nCS2 <= nCS1;
            nCS1 <= nCS;
            SCLK3 <= SCLK2;
            SCLK2 <= SCLK1;
            SCLK1 <= SCLK;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_bits <= 0;
            data <= 0;
            transaction_ready <= 0;
            transaction_processed <= 0;
        end else begin
            if (!nCS2 && nCS3) begin
                num_bits <= 0;
                transaction_ready <= 0;
                transaction_processed <= 0;
            end else if (num_bits < 5'd16 && (SCLK2 && !SCLK3)) begin
                data <= {data[14:0], COPI2};
                num_bits <= num_bits + 1;
            end

            if (nCS2 && !nCS3) begin
                transaction_ready <= 1;
            end else if (ready_to_process) begin
                transaction_processed <= 1;
            end else if (transaction_ready && transaction_processed) begin
                transaction_ready <= 0;
            end else if (!transaction_ready && transaction_processed) begin
                transaction_processed <= 0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0 <= 0;
            en_reg_out_15_8 <= 0;
            en_reg_pwm_7_0 <= 0;
            en_reg_pwm_15_8 <= 0;
            pwm_duty_cycle <= 0;
        end else if (ready_to_process) begin
            case (data[14:8])
                7'd0: en_reg_out_7_0 <= data[7:0];
                7'd1: en_reg_out_15_8 <= data[7:0];
                7'd2: en_reg_pwm_7_0 <= data[7:0];
                7'd3: en_reg_pwm_15_8 <= data[7:0];
                7'd4: pwm_duty_cycle <= data[7:0];
                default: ;
            endcase
        end
    end
endmodule