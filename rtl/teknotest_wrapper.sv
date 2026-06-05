module teknotest_wrapper(
    input clk_i, // Clock input
    input resetn_i, // Reset input (active low)
    
    input uart_rx_i, // UART RX Input (tb->dut)
    output uart_tx_o // UART TX Output (dut->tb)
);

    // ADD YOUR CODE HERE
    // Unused signals
    wire [15:0] gpio_out;
    wire        uart1_tx;
    wire        i2c_scl_o;
    wire        i2c_sda_o;

    cv32e40p_verilator_top u_soc (
        .clk_i             (clk_i),
        .rst_ni            (resetn_i),

        .gpio_in           (16'h0000),
        .gpio_out          (gpio_out),

        .uart0_rx_i        (uart_rx_i),
        .uart0_tx_o        (uart_tx_o),

        .uart1_rx_i        (1'b1),
        .uart1_tx_o        (uart1_tx),

        .i2c_scl_i         (1'b1),
        .i2c_sda_i         (1'b1),
        .i2c_scl_o         (i2c_scl_o),
        .i2c_sda_o         (i2c_sda_o)
    );
    
endmodule;