library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity seven_segment_control is
	generic(
			COUNTER_BITS : natural := 15
		);
    Port ( clk : in  STD_LOGIC;
           data_in : in  STD_LOGIC_VECTOR (15 downto 0);
           dp_in : in  STD_LOGIC_VECTOR (3 downto 0);
           blank : in  STD_LOGIC_VECTOR (3 downto 0);
           seg : out  STD_LOGIC_VECTOR (6 downto 0);
           dp : out  STD_LOGIC;
           an : out  STD_LOGIC_VECTOR (3 downto 0));
end seven_segment_control;

architecture segment_arch of seven_segment_control is

-- initialize counter and stuff
signal r_next, counter : unsigned(COUNTER_BITS-1 downto 0) := (others=>'0');
signal anode_select : std_logic_vector(1 downto 0);

-- mux stuff
signal decoderInput : std_logic_vector(3 downto 0);
signal tempDP : STD_LOGIC;


begin -- begin architecture

-- counter logic
process(clk)
begin
if (clk'event and clk='1') then
	counter <= r_next;
end if;
end process;
r_next <= counter + 1;
--get the top two bits of counter
anode_select <= std_logic_vector(counter(COUNTER_BITS-1 downto COUNTER_BITS-2));

-- dp_in logic
with anode_select select
	tempDP <= dp_in(0) when "00",
			dp_in(1) when "01",
			dp_in(2) when "10",
			dp_in(3) when others; -- when "11"
	
-- invert dp
dp <= not tempDP;

-- an logic
with anode_select select
	an <= "111" & blank(0) when "00",
			"11" & blank(1) & '1' when "01",
			"1" & blank(2) & "11" when "10",
			blank(3) & "111" when others; -- when "11"

-- Anode Decoding
with anode_select select
decoderInput <= data_in(3 downto 0) when "00",
					 data_in(7 downto 4) when "01",
					 data_in(11 downto 8) when "10",
					 data_in(15 downto 12) when others; -- 11
					 

----Seven Segment Decoder
with decoderInput select
seg <= "1000000" when "0000",
		 "1111001" when "0001",
		 "0100100" when "0010",
		 "0110000" when "0011",		 "0011001" when "0100",
		 "0010010" when "0101",
		 "0000010" when "0110",  		 "1111000" when "0111",
		 "0000000" when "1000",
		 "0010000" when "1001",
		 "0001000" when "1010",
		 "0000011" when "1011",
		 "1000110" when "1100",
		 "0100001" when "1101",
		 "0000110" when "1110",
		 "0001110" when others;




end segment_arch;












