---------------------------------------------------------------------------------------------------
-- 
-- top_labo_4.vhd
--
-- Pierre Langlois
-- v. 1.1, 2021/03/06 pour le laboratoire #4
--
-- Digilent Basys 3 Artix-7 FPGA Trainer Board 
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;  
use work.utilitaires_inf3500_pkg.all;
use work.SHA_1_utilitaires_pkg.all;
use work.all;

entity top_labo_4 is
    port(
        clk : in std_logic; -- l'horloge de la carte à 100 MHz
        sw : in std_logic_vector(15 downto 0); -- les 16 commutateurs
        led : out std_logic_vector(15 downto 0); -- les 16 LED
        seg : out std_logic_vector(7 downto 0); -- les cathodes partagées des quatre symboles à 7 segments + point
        an : out std_logic_vector(3 downto 0); -- les anodes des quatre symboles à 7 segments + point
        btnC : in std_logic; -- bouton du centre
        btnU : in std_logic; -- bouton du haut
        btnL : in std_logic; -- bouton de gauche
        btnR : in std_logic; -- bouton de droite
        btnD : in std_logic -- bouton du bas
    );
end;

architecture arch of top_labo_4 is

----------------------
-- le nombre de caractères à ajouter au message de base pour chercher une collision
constant N : positive := 16;
----------------------

signal symboles : quatre_symboles;
signal compte : unsigned(4 * N - 1 downto 0);
signal fini : std_logic;
signal chaine : string(1 to N); 

begin
    
    -- sanity check
    led(15) <= sw(15);

    -- instantiation du module de recherche de collisions
    module_recherche : entity SHA_1_cherche_collisions(arch)
    generic map (
    message_de_base => "Bonjour, monde !",
--    collision => x"0000000000000000", -- il faut environ XX minutes pour trouver une solution pour une collision à 16 caractères hex (64 bits) `0'
--    collision => x"00000000",       -- il faut environ 10 minutes pour trouver une solution pour une collision à 8 caractères hex (32 bits) '0'
    collision => x"000000",         -- il faut environ 30 secondes pour trouver une solution pour une collision à 6 caractères hex (24 bits) '0'
    N => N
    )
    port map (
    clk => clk,
    reset => btnC,
    compte => compte,
    chaine => chaine,
    trouve => led(1),
    erreur => led(0)
    );
    
    -- connexion des symboles de l'affichage quadruple à 7 segments
    -- le code qui suit convient pour N = 16
    assert N = 16 report "le code pour l'assignation aux affichages à 4 segments est bon pour N = 16 seulement, il faut le modifier sinon" severity failure;
    with sw(2 downto 0) select
    symboles <=
    (character_to_7seg(chaine(1)), character_to_7seg(chaine(2)), character_to_7seg(chaine(3)), character_to_7seg(chaine(4))) when "000",
    (character_to_7seg(chaine(5)), character_to_7seg(chaine(6)), character_to_7seg(chaine(7)), character_to_7seg(chaine(8))) when "001",
    (character_to_7seg(chaine(9)), character_to_7seg(chaine(10)), character_to_7seg(chaine(11)), character_to_7seg(chaine(12))) when "010",
    (character_to_7seg(chaine(13)), character_to_7seg(chaine(14)), character_to_7seg(chaine(15)), character_to_7seg(chaine(16))) when "011",
    (hex_to_7seg(compte(63 downto 60)), hex_to_7seg(compte(59 downto 56)), hex_to_7seg(compte(55 downto 52)), hex_to_7seg(compte(51 downto 48))) when "100",
    (hex_to_7seg(compte(47 downto 44)), hex_to_7seg(compte(43 downto 40)), hex_to_7seg(compte(39 downto 36)), hex_to_7seg(compte(35 downto 32))) when "101",
    (hex_to_7seg(compte(31 downto 28)), hex_to_7seg(compte(27 downto 24)), hex_to_7seg(compte(23 downto 20)), hex_to_7seg(compte(19 downto 16))) when "110",
    (hex_to_7seg(compte(15 downto 12)), hex_to_7seg(compte(11 downto 8)), hex_to_7seg(compte(7 downto 4)), hex_to_7seg(compte(3 downto 0))) when others;
 
   -- Circuit pour sérialiser l'accès aux quatre symboles à 7 segments.
   -- L'affichage contient quatre symboles chacun composé de sept segments et d'un point.
    process(all)
    variable clkCount : unsigned(19 downto 0) := (others => '0');
    begin
        if (clk'event and clk = '1') then
            clkCount := clkCount + 1;           
        end if;
        case clkCount(clkCount'left downto clkCount'left - 1) is     -- L'horloge de 100 MHz est ramenée à environ 100 Hz en la divisant par 2^19
            when "00" => an <= "1110"; seg <= symboles(0);
            when "01" => an <= "1101"; seg <= symboles(1);
            when "10" => an <= "1011"; seg <= symboles(2);
            when others => an <= "0111"; seg <= symboles(3);
        end case;
    end process;
        
end arch;