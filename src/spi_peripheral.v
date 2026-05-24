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
    
    reg [5:0] num_bits;

    reg [15:0] data;

    reg COPI1, COPI2;
    reg nCS1, nCS2;
    reg SCLK1, SCLK2, SCLK3;
    reg transaction_ready, transaction_processed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_bits <= 0;
            COPI2 <= 0;
            COPI1 <= 0;
            nCS2 <= 0;
            nCS1 <= 0;
            SCLK3 <= 0;
            SCLK2 <= 0;
            SCLK1 <= 0;
            data <= 0;
            transaction_ready <= 0;
        end else if (!nCS2) begin
            if (nCS1) begin
                num_bits <= 0;
            end else if ((SCLK3 && !SCLK2) && num_bits < 5'd16) begin
                data <= {data[14:0], COPI2};
                num_bits <= num_bits + 1;
            end 

            COPI2 <= COPI1;
            COPI1 <= COPI;
            nCS2 <= nCS1;
            nCS1 <= nCS;
            SCLK3 <= SCLK2;
            SCLK2 <= SCLK1;
            SCLK1 <= SCLK;
        end else begin
            if (transaction_processed) begin
                transaction_ready <= 0;
            end else if (nCS2 && !nCS1) begin
                transaction_ready <= 1;
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
            transaction_processed <= 0;
        end else if ((transaction_ready && !transaction_processed) && num_bits == 5'd16 && data[15]) begin
            case (data[7:1]) begin
                7'd0: en_reg_out_7_0 <= data[15:8];
                7'd1: en_reg_out_15_8 <= data[15:8];
                7'd2: en_reg_pwm_7_0 <= data[15:8];
                7'd3: en_reg_pwm_15_8 <= data[15:8];
                7'd4: pwm_duty_cycle <= data[15:8];
                default: ;
            end

            transaction_processed <= 1;
        end else if (!transaction_ready && transaction_processed) begin
            transaction_processed <= 0;
        end
    end
