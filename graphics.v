module top (
    input wire [12:0] address_bus,
    input wire cpu_clk,
    input wire cpu_rw,
    input wire cpu_ce,
    input wire sysclk,
    inout wire [7:0] data_bus,
    output reg [4:0] dac_red,
    output reg [4:0] dac_green,
    output reg [4:0] dac_blue,
    output reg vsync,  // WARN: invert both hsync and vsync and tie the original pin to low. (both active low but need to be high during init)
    output reg hsync,
    output reg ready
);

  // for startup (no voltage during startup)
  // initial begin
  //   ready = 1'b1;
  // end
  assign ready = locked;

  reg [7:0] data_out;
  reg [7:0] data_in;
  assign data_bus = (cpu_rw == 1) && (cpu_ce == 1) ? data_out : 8'bz;


  // CPU reads
  always @(*) begin
    data_out = 8'hFF;
    if (cpu_ce && cpu_clk && cpu_rw) begin
      case (address_bus)
        13'h0000: begin
          data_out = 8'hA5;
        end
        13'h0001: begin
          data_out = data_in;
        end
        default: begin
          data_out = 8'hFF;
        end
      endcase
    end
  end

  // CPU writes
  always @(negedge cpu_clk) begin
    if (cpu_ce && !cpu_rw) begin
      case (address_bus)
        13'h0002: begin
          data_in <= data_bus;
        end
        default: begin
        end
      endcase
    end
  end

  wire clkfb;
  wire vga_clk;
  wire locked;

  MMCME2_ADV #(
      .CLKIN1_PERIOD     (83.33),        // 12 MHz
      .CLKFBOUT_MULT_F   (50.375),       // VCO = 604.5 MHz
      .DIVCLK_DIVIDE     (1),
      .CLKOUT0_DIVIDE_F  (24.0),         // ~25.1875 MHz
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE     (0.0),
      .BANDWIDTH         ("OPTIMIZED"),
      .STARTUP_WAIT      ("FALSE")
  ) mmcm_inst (
      .CLKIN1  (sysclk),
      .CLKFBOUT(clkfb),
      .CLKFBIN (clkfb),
      .CLKOUT0 (vga_clk),
      .LOCKED  (locked),
      .PWRDWN  (1'b0),
      .RST     (1'b0)
  );

  reg [3:0] graphics_mode;
  reg flip;
  localparam ROWS = 16'h2000 / 2;
  (* ram_style= "block" *)
  reg [15:0] vram[0:2*ROWS-1];
  reg active_vram;  // the one that is currently actively outputed

  initial begin
    active_vram   = 1'b0;
    graphics_mode = 4'b0;
    $readmemh("vram_init.data", vram);
  end

  reg [9:0] hcount;
  reg [9:0] vcount;
  initial begin
    hsync = 1'b0;
    vsync = 1'b0;
    hcount = 10'b0;
    vcount = 10'b0;
    dac_red = 5'b0;
    dac_green = 5'b0;
    dac_blue = 5'b0;
    flip = 1'b0;
  end

  reg [15:0] value;
  reg color;
  reg [3:0] next_bit_select;
  reg [11:0] next_offset;
  reg [3:0] row_start_bit_select;
  reg [11:0] row_start_offset;
  reg [12:0] prefetch_addr;

  always @(posedge vga_clk) begin
    value <= vram[prefetch_addr];
    if (locked) begin
      case (1'b1)
        (vcount < 480): begin
          case (1'b1)
            (hcount < 640): begin
              hsync <= 1'b0;
              vsync <= 1'b0;
              // Custom sub resolution
              if (hcount < 292 * 2 && vcount < 219 * 2) begin
                dac_red   <= (value >> next_bit_select) & 1'b1 ? 5'b11111 : 5'b0;
                dac_green <= (value >> next_bit_select) & 1'b1 ? 5'b11111 : 5'b0;
                dac_blue  <= (value >> next_bit_select) & 1'b1 ? 5'b11111 : 5'b0;
                if (next_bit_select == 15) begin
                  next_bit_select <= 0;
                  next_offset <= next_offset + 1;
                  prefetch_addr <= {active_vram, next_offset + 1};
                end else begin
                  next_bit_select <= next_bit_select + 1;
                end
              end else begin
                dac_red   <= 5'b0;
                dac_green <= 5'b0;
                dac_blue  <= 5'b0;
              end
            end
            (hcount >= 656 && hcount < 752): begin
              hsync <= 1'b1;
              vsync <= 1'b0;
              dac_red <= 5'b0;
              dac_green <= 5'b0;
              dac_blue <= 5'b0;
            end
            default: begin
              hsync <= 1'b0;
              vsync <= 1'b0;
              dac_red <= 5'b0;
              dac_green <= 5'b0;
              dac_blue <= 5'b0;
            end
          endcase
        end
        (vcount >= 490 && vcount < 492): begin
          if (hcount >= 656 && hcount < 752) begin
            hsync <= 1'b1;
          end else begin
            hsync <= 1'b0;
          end
          vsync <= 1'b1;
          dac_red <= 5'b0;
          dac_green <= 5'b0;
          dac_blue <= 5'b0;
        end
        default: begin
          if (hcount >= 656 && hcount < 752) begin
            hsync <= 1'b1;
          end else begin
            hsync <= 1'b0;
          end
          vsync <= 1'b0;
          dac_red <= 5'b0;
          dac_green <= 5'b0;
          dac_blue <= 5'b0;
        end
      endcase
      if (hcount == 798 && vcount == 524) begin
        if (flip) begin
          flip <= 1'b0;
          active_vram <= ~active_vram;
          prefetch_addr <= {~active_vram, 12'b0};
        end else begin
          prefetch_addr <= {active_vram, 12'b0};
        end
      end
      if (hcount >= 799) begin
        if (vcount >= 524) begin
          vcount <= 10'h0;
          next_bit_select <= 4'b0;
          next_offset <= 12'b0;
        end else begin
          if (vcount[0] == 0) begin
            row_start_offset <= next_offset;
            row_start_bit_select <= next_bit_select;
          end else begin
            next_offset <= row_start_offset;
            next_bit_select <= row_start_bit_select;
          end
          vcount <= vcount + 10'h1;
        end
        hcount <= 10'h0;
      end else begin
        hcount <= hcount + 10'h1;
      end
    end else begin
      hcount <= 10'b0;
      vcount <= 10'b0;
      next_bit_select <= 4'b0;
      next_offset <= 12'b0;
      row_start_bit_select <= 4'b0;
      row_start_offset <= 12'b0;
      value <= 16'b0;
      color <= 1'b0;
      prefetch_addr <= 13'b0;
    end
  end

endmodule
