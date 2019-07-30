module bos(
// main
//input         fpga_clk_100,
input         fpga_clk_48,
//input         sbis_power_on,  // flag that sbis is ok
// RAM
//output [12:0] sdram_a,
//output [1:0]  sdram_ba,     // bank address
//inout  [15:0] sdram_dq,     // data i/o
//output        sdram_clk,
//output        sdram_cke,    // clock enable
//output        sdram_we_n,   // write_enable
//output        sdram_cas_n,  // column address strobe command
//output        sdram_ras_n,  // row address strobe command
//output        sdram_cs_n,   // chip select
//// ADCs (v-meter, a-meter)
//output        adc_sclk,     // D12, D13, D14
//output        adc_din,      //      D13, D14
//input         adc_dout,     //      D13, D14
//output        adc1_cs_n,    //      D13
//output        adc2_cs_n,    //           D14
//output        adc_din_pwr,  // D12
//input         adc_dout_pwr, // D12
//output        adc_cs_pwr_n, // D12
//// DDS
//output        dds_io_upd,   // ad9952 datasheet page 7
//output        dds_rst,
//output        dds_cs_n,
//inout         dds_sdio,
//output        dds_sclk,
//input         fpga_clk_dac, // clk from dds
//// DAC that outputs to SBIS
//output [13:0] dac_d,
//output        dac_clk_ext,
//// DAC output control
//output        dac_gain,
//output        dac_switch_out_fpga,
//output        dac_ena_out_fpga,
//// SPI-controlled voltage source
//output        dac_din,
//output        dac_sclk,
//output        dac_sync_n,
//input         dac_sdo,
//input         dac_rdy,
//output        dac_rst_n,
//// to load Q0-Q11
//output [3:0]  a,            // address on multiplexer
//output        load_pr_3v7,
//output        load_pdr,
//// voltage control
//output        off_pr_digital_fpga,  // to analog switches D32... D41
//
//output        din_power,            // к формирователю напряжений, D1 D2 D13
//output        sclk_power,           // к формирователю напряжений, D1 D2 D13
//output        rst_power_n,          // к формирователю напряжений, D1 D2 D13
//output        sync_core_n,          // к формирователю напряжений, D1
//output        sync_digital_n,       // к формирователю напряжений,    D2
//output        sync_vpr_digital_n,   // к формирователю напряжений,       D13
//
//output        off_vcore_fpga,       // к формирователю напряжений, к лог. "ИЛИ" D9
//output        off_vdigital_fpga,    // к формирователю напряжений, к лог. "ИЛИ" D10
//
//// LT (level translators)
//output        functional,
// RS-485
output        tx,
input         rx,
// SBIS BOS
//input  [11:0] q_fpga,       // video data from sbis bos
//input         dataclk_fpga,
//
//output        rst_fpga,     // rst of sbis
//output        clk_fpga,
//output        stby_fpga,    // вход режима простоя
//
//output        shp_fpga,     // вход тактов обработки
//output        hd_fpga,      // вход управления горизонтальной развёрткой
//output        pblk_fpga,    // вход импульса гашения
//output        vd_fpga,      // вход управления вертикальной развёрткой
//output        clpdm_fpga,   // вход импульса привязки на входе
//output        shd_fpga,     // вход тактов уровня данных
//output        clpob_fpga,   // вход импульса привязки на выходе
//
//output        sl_fpga,      // serial IF управления - вход загрузки
//output        sdatai_fpga,  // serial IF управления - вход данных
//input         sdatao_fpga,  // serial IF управления - выход данных
//output        sck_fpga,     // serial IF управления - вход тактов
//
//input         slv_fpga,     // serial IF видеоданных - вход управления      
//input         sckv_fpga,    // serial IF видеоданных - вход тактов
//output        sdatav_fpga   // serial IF видеоданных - выход данных
output [7:0] my_rx_data,
output       my_rx_valid,
output       my_tx_ready,
output [7:0] my_tx_data,
output       my_tx_valid,
output       my_rx_ready,
output       gnd,

output [4:0]     ready_bus,
output [5*8-1:0] data_bus,
output [4:0]     valid_bus,
output [2:0]      my_state,
output [7:0]      my_dest,
output [7:0]      my_len,
output [7:0]      my_cnt


);
assign gnd = 0;

assign my_rx_data  = rx_data;
assign my_rx_valid = rx_valid;
assign my_tx_ready = tx_ready;
assign my_tx_data  = tx_data;
assign my_tx_valid = tx_valid;
assign my_rx_ready = rx_ready;


wire [7:0]  rx_data;
wire        rx_valid;
wire        tx_ready;
wire [7:0]  tx_data;
wire        tx_valid;
wire        rx_ready;

localparam PRESCALE = 50000000 / (115200 * 8);	// = fclk / (baud * 8)

uart uart (
  .clk                (fpga_clk_48),
  .rst                (0),
  // AXI input
  .input_axis_tdata   (tx_data),    // I make it
  .input_axis_tvalid  (tx_valid),   // I make it
  .input_axis_tready  (tx_ready),
  // AXI output
  .output_axis_tdata  (rx_data),
  .output_axis_tvalid (rx_valid),
  .output_axis_tready (rx_ready),   // I make it
  // UART interface
  .rxd                (rx),
  .txd                (tx),
  // Configuration
  .prescale           (PRESCALE)
);


cmd_decoder cmd_decoder (
  .clk      (fpga_clk_48),
  .rx_data  (rx_data),
  .rx_valid (rx_valid),
  .rx_ready (rx_ready),
  .ready_bus (ready_bus),
  .data_bus  (data_bus),
  .valid_bus (valid_bus),
  // debug
  .my_state  (my_state),
  .my_dest   (my_dest),
  .my_len    (my_len),
  .my_cnt    (my_cnt)
);


cmd_encoder cmd_encoder (
  .tx_data  (tx_data),
  .tx_valid (tx_valid),
  .tx_ready (tx_ready)
);


endmodule