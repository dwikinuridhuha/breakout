library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blocks is
	generic(
		BALL_WIDTH : positive := 50
	);
	port(
		clk : in STD_LOGIC;
		rst : in STD_LOGIC; -- actually synchronous reset
		pixel_x : in STD_LOGIC_VECTOR(9 downto 0);
		pixel_y : in STD_LOGIC_VECTOR(9 downto 0);
		ball_x : in STD_LOGIC_VECTOR(9 downto 0);
		ball_y : in STD_LOGIC_VECTOR(9 downto 0);
		block_hit : out STD_LOGIC;
		block_rgb : out STD_LOGIC_VECTOR(7 downto 0);
		block_disp : out STD_LOGIC
	);
end blocks;

architecture Behavioral of blocks is
	constant ADDR_WIDTH : positive := 64;
	constant WORD_WIDTH : positive := 8;
	type ram_type is array(0 to ADDR_WIDTH - 1) of STD_LOGIC_VECTOR(WORD_WIDTH - 1 downto 0);
	signal ram : ram_type := (
		X"03",X"1C",X"FC",X"03",X"1F",X"FC",X"03",X"1C",X"FC",X"03",X"00",X"00",X"00",X"00",X"00",X"00",
		X"1C",X"FC",X"03",X"1F",X"FC",X"03",X"1C",X"FC",X"03",X"1F",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FC",X"03",X"1F",X"FC",X"03",X"1C",X"FC",X"03",X"1F",X"FC",X"00",X"00",X"00",X"00",X"00",X"00",
		X"03",X"1F",X"FC",X"03",X"1C",X"FC",X"03",X"1F",X"FC",X"03",X"00",X"00",X"00",X"00",X"00",X"00");
	signal read_addr, read_addr_next : STD_LOGIC_VECTOR(5 downto 0);
	signal read_row_select : STD_LOGIC_VECTOR(1 downto 0);
	
	signal write_en : STD_LOGIC;
	signal ball_addr, ball_addr_next : STD_LOGIC_VECTOR(5 downto 0);
	signal ball_row_select : STD_LOGIC_VECTOR(1 downto 0);
	signal block_color, ball_hit_color: std_logic_vector(7 downto 0);
	signal ball_x_middle : STD_LOGIC_VECTOR(9 downto 0);
	
	type state_type is (load0, load1, load2, load3, play);
	signal state_reg, state_next : state_type;
	signal write_color : std_logic_vector(7 downto 0);
begin

	ball_x_middle <= std_logic_vector(unsigned(ball_x) + to_unsigned(BALL_WIDTH/2, 10));
	
	-- state registers
	process(clk)
	begin
		if (clk'event and clk = '1') then
			state_reg <= state_next;
		end if;
	end process;

	-- next state logic
	process(state_reg, ball_row_select, ball_x_middle, rst, ball_addr, ball_y)
		variable write_addr_next : unsigned(5 downto 0);
	begin
		write_addr_next := unsigned(ball_addr);
		case state_reg is
			when load0 =>
				write_color <= "00000011";
				write_en <= '1';
				write_addr_next := write_addr_next + 1;
				state_next <= load1;
			when load1 =>
				write_color <= "00011100";
				write_en <= '1';
				write_addr_next := write_addr_next + 1;
				state_next <= load2;
			when load2 =>
				write_color <= "11111100";
				write_en <= '1';
				write_addr_next := write_addr_next + 1;
				state_next <= load3;
			when load3 =>
				write_color <= "00011111";
				write_en <= '1';
				write_addr_next := write_addr_next + 1;
				state_next <= load0;
			when play =>
				write_addr_next := unsigned(ball_row_select) & unsigned(ball_x_middle(9 downto 6));
				write_color <= (others => '0');
				if (unsigned(ball_y) < to_unsigned(80, 10)) then
					write_en <= '1';
				else
					write_en <= '0';
				end if;
				if (rst = '1') then
					state_next <= load0;
					write_en <= '0';
					write_addr_next := (others => '0');
				else
					state_next <= play;
				end if;
		end case;
		-- go back to normal play mode when all the blocks have been written
		if (write_addr_next >= "111010") then
			state_next <= play;
		end if;
		-- rollover logic for write_addr
		if (write_addr_next(3 downto 0) > "1001") then
			write_addr_next(3 downto 0) := "0000";
			write_addr_next(5 downto 4) := write_addr_next(5 downto 4) + 1;
		end if;
		ball_addr_next <= std_logic_vector(write_addr_next);
	end process;


	-- memory controller
	process(clk)
	begin
		if (clk'event and clk = '1') then
			if (write_en = '1') then
				ram(to_integer(unsigned(ball_addr))) <= write_color;
			end if;
			read_addr <= read_addr_next;
			ball_addr <= ball_addr_next;
		end if;
	end process;

	read_row_select <= "00" when unsigned(pixel_y) < to_unsigned(20, 10) else
					  "01" when unsigned(pixel_y) < to_unsigned(40, 10) else
					  "10" when unsigned(pixel_y) < to_unsigned(60, 10) else
					  "11";
					  
	ball_row_select <= "00" when unsigned(ball_y) < to_unsigned(20, 10) else
					  "01" when unsigned(ball_y) < to_unsigned(40, 10) else
					  "10" when unsigned(ball_y) < to_unsigned(60, 10) else
					  "11";

	read_addr_next <= read_row_select & pixel_x(9 downto 6);
	
	block_color <= ram(to_integer(unsigned(read_addr))) when UNSIGNED(pixel_y) < to_unsigned(80, 10) else
						(others => '0');
	
	ball_hit_color <= ram(to_integer(unsigned(ball_addr))) when UNSIGNED(ball_y) < to_unsigned(80, 10) else
						(others => '0');
	
	
	block_hit <= '1' when ball_hit_color /= "00000000" and state_reg = play else '0';
	
	block_disp <= '0' when block_color = "00000000" else '1';
					  
	block_rgb <= block_color;
end Behavioral;

