--Mark Crossen
--ECEN 320 Section 2
--Lab5 VGA Timing Controller
--Winter 2016
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_timing is
	port(
		clk : in STD_LOGIC; --Input clock (50 MHz)
		rst : in STD_LOGIC; --Asynchronous reset
		hs : out STD_LOGIC; --Low asserted horizontal sync VGA signal
		vs : out STD_LOGIC; --Low asserted vertical sync VGA signal
		pixel_x : out STD_LOGIC_VECTOR(9 downto 0); --Indicates the column of the current VGA pixel
		pixel_y : out STD_LOGIC_VECTOR(9 downto 0); --Indicates the row of the current VGA pixel
		last_column : out STD_LOGIC; --Indicates that the current pixel_x correspond to the last visible column
		last_row : out STD_LOGIC; --Indicates that the current pixel_y corresponds to the last visible row
		blank : out STD_LOGIC --Indicates that the current pixel is part of a horizontal or vertical retrace and that the output color must be blanked. The VGA pixel must be set to "Black" during blanking.
	);
end vga_timing;

architecture Behavioral of vga_timing is
	signal pixel_en : STD_LOGIC := '0';
	
	constant COLUMN_WIDTH : POSITIVE := 10;
	constant COLUMN_MAX : POSITIVE := 799;
	signal column : UNSIGNED(COLUMN_WIDTH-1 downto 0) := (others => '0');
	signal column_next : UNSIGNED(COLUMN_WIDTH-1 downto 0) := (others => '0');
	
	constant ROW_WIDTH : POSITIVE := 10;
	constant ROW_MAX : POSITIVE := 520;
	signal row : UNSIGNED(ROW_WIDTH-1 downto 0) := (others => '0');
	signal row_next : UNSIGNED(ROW_WIDTH-1 downto 0) := (others => '0');
	
	constant H_PULSE_START : POSITIVE := 656;
	constant H_PULSE_END : POSITIVE := 751;
	constant V_PULSE_START : POSITIVE := 490;
	constant V_PULSE_END : POSITIVE :=  491;
	
	constant LAST_PIXEL_ROW : POSITIVE := 479;
	constant LAST_PIXEL_COLUMN : POSITIVE := 639;
	
begin
	--divide the clock by half to make the pixel enable signal.
	process(clk)
	begin
		if (clk'event and clk = '1') then
			pixel_en <= not pixel_en;
		end if;
	end process;
	
	--HS counter register
	process(clk, rst)
	begin
		if (rst = '1') then
			column <= (others => '0');
		elsif (clk'event and clk = '1') then
			column <= column_next;
		end if;
	end process;
	
	--VS counter register
	process(clk, rst)
	begin
		if (rst = '1') then
			row <= (others => '0');
		elsif (clk'event and clk = '1') then
			row <= row_next;
		end if;
	end process;
	
	--HS counter next state logic
	column_next <= column 				when pixel_en = '0'			else
						(others => '0')	when column = COLUMN_MAX	else
						column + 1;
	
	--VS counter next state logic
	row_next <= row 					when pixel_en = '0'			else
					row					when column /= COLUMN_MAX	else
					(others => '0')	when row = ROW_MAX 			else
					row + 1;
							
	--horizontal/column output logic
	hs <= '0' when column >= H_PULSE_START and column <= H_PULSE_END else
			'1';
	pixel_x <= STD_LOGIC_VECTOR(column);
	last_column <= '1' when column = LAST_PIXEL_COLUMN else
						'0';
	
	--vertical/row output logic
	vs <= '0' when row >= V_PULSE_START and row <= V_PULSE_END else
			'1';
	pixel_y <= STD_LOGIC_VECTOR(row);
	last_row <= '1' when row = LAST_PIXEL_ROW else
					'0';
	
	--blank output logic
	blank <= '1' when row > LAST_PIXEL_ROW or column > LAST_PIXEL_COLUMN else
				'0';
				
end Behavioral;
