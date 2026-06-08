module teknotest_wrapper(
    input clk_i, // Clock input
    input resetn_i, // Reset input (active low)
    
    input uart_rx_i, // UART RX Input (tb->dut)
    output uart_tx_o // UART TX Output (dut->tb)
);

    cv32e40p_sim u_soc (
    //cv32e40p_verilator_top u_soc (
        .clk_i             (clk_i),
        .rst_ni            (resetn_i),

        .rx_i        (uart_rx_i),
        .tx_o        (uart_tx_o)
    );
    
endmodule;