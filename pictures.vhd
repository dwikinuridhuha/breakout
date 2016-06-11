library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity framebuffer is
	generic(
		CLK_RATE : positive := 50_000_000
	);
	port(
		clk : in Std_Logic; -- 50 MHz clock
		rst : in Std_Logic;
		image : in Std_Logic_Vector(4 downto 0); -- 5 right-most images (image4, image3, image2, image1, and image0). The images will determine which image you will display.
		pixel_x : in Std_Logic_Vector(9 downto 0);
		pixel_y : in Std_Logic_Vector(9 downto 0);
		blank : in Std_Logic;
		picture : out Std_Logic_Vector(7 downto 0);
		MemAdr : out Std_Logic_Vector(22 downto 0); -- The address pins to the memory device
		MemOE : out Std_Logic; -- : Output enable pin to memory device
		MemWR : out Std_Logic; -- Write enable pin to memory device
		RamCS : out Std_Logic; -- Memory chip select
		RamLB : out Std_Logic; -- Memory ‘lower byte’ control signal
		RamUB : out Std_Logic; -- Memory ‘upper byte’ control signal
		RamCLK : out Std_Logic; -- Memory CLK signal
		RamADV : out Std_Logic; -- Memory ADV signal
		RamCRE : out Std_Logic; -- Memory CRE signal
		MemDB : inout Std_Logic_Vector(15 downto 0) -- Data pins to memory
	);

end framebuffer;

architecture Behavioral of framebuffer is
	constant read_cycles : positive := 4;
	-- VGA signals
	alias pix_y is pixel_y (pixel_y'high - 1 downto pixel_y'low);
	-- SRAM signls
	signal address : Std_Logic_Vector (22 downto 0);
	signal mem : Std_Logic;
	constant rw : Std_Logic := '1';
	constant data_in : Std_Logic_Vector (15 downto 0) := (others => '0');
	signal data_valid : Std_Logic;
	signal data_out : Std_Logic_Vector (15 downto 0);
	alias pixel0 is data_out(7 downto 0);
	alias pixel1 is data_out(15 downto 8);
	-- Pixel signals
	alias pixel_sel is pixel_x(0);
	signal pixel : Std_Logic_Vector(7 downto 0);
	--delay logic
	signal pixel_sel_delay : Std_Logic_Vector(read_cycles - 1 downto 0) := (others => '0');
	alias pixel_select is pixel_sel_delay(pixel_sel_delay'left);
begin
	-- SRAM address
	address <= image & pix_y & pixel_x(pixel_x'left downto 1);
	
	-- SRAM enable logic
	mem <= '1' when rst = '1' else
			 '1' when blank = '1' else
			 '0';
	
	-- Pixel output logic
	with pixel_select select
		pixel <= pixel0 when '0',
				 pixel1 when '1',
				(others => '0') when others;
	
	picture <= pixel;
	
	-- delay logic
	process(clk, rst)
	begin
		if (rst = '1') then
			pixel_sel_delay <= (others => '0');
		elsif (clk'event and clk = '1') then
			pixel_sel_delay(0) <= pixel_sel;
			for i in 1 to read_cycles - 1 loop
				pixel_sel_delay(i) <= pixel_sel_delay(i-1);
			end loop;
		end if;
	end process;
	
	-- SRAM controller instantiation
	sram_0 : entity work.sramController(Behavioral)
		port map(
			clk => clk,
			rst => rst,
			addr => address,
			data_m2s => data_in,
			mem => mem,
			rw => rw,
			data_s2m => data_out,
			data_valid => data_valid,
			ready => open,
			MemAdr => MemAdr,
			MemOE => MemOE,
			MemWR => MemWR,
			RamCS => RamCS,
			RamLB => RamLB,
			RamUB => RamUB,
			RamCLK => RamCLK,
			RamADV => RamADV,
			RamCRE => RamCRE,
			MemDB => MemDB
		);
		
end Behavioral;