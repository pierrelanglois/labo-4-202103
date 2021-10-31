-------------------------------------------------------------------------------
--
-- banc d'essai pour SHA_1
--
-- v. 1.0 2020-10-24 Pierre Langlois
-- vérifie le fonctionnement pour des messages constitués d'un bloc unique de 16 mots de 32 bits, donc max 55 caractères avec l'encodage
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SHA_1_utilitaires_pkg.all;
use work.all;

entity SHA_1_tb is
end SHA_1_tb;

architecture arch_tb of SHA_1_tb is

signal clk : std_logic := '0';
signal reset : std_logic;
signal bloc : bloc_type;
signal charge_et_go : std_logic;
signal empreinte : empreinte_type;
signal fini : std_logic := '0';

constant periode : time := 10 ns;

constant blocs_a_traiter : bloc_multiple_type := (
compose_bloc(""),                                                 -- la chaîne vide
compose_bloc("abc"),                                              -- exemple de base de la spécification de SHA-1
compose_bloc("0:030626:adam@cypherspace.org:6470e06d773e05a8"),   -- exemple tiré de http://hashcash.org/faq/index.fr.php
compose_bloc("aaaa"),                                             -- un autre exemple random
compose_bloc("bidon")                                             -- une chaîne supplémentaire, uniquement pour donner le temps au module de terminer
);

constant empreintes_attendues : empreintes_vecteur_type := (
x"da39a3ee5e6b4b0d3255bfef95601890afd80709",    -- ""
x"a9993e364706816aba3e25717850c26c9cd0d89d",    -- abc
x"00000000c70db7389f241b8f441fcf068aead3f0",    -- 0:030626:adam@cypherspace.org:6470e06d773e05a8
x"70c881d4a26984ddce795f6f71817c9cf4480e79",    -- aaaa
(others => '0')                                 -- bidon
);

type etat_tb_type is (attente, transmission);
signal etat_tb : etat_tb_type;

signal indice : natural range 0 to blocs_a_traiter'length;

begin

    clk <= not clk after periode / 2;
    reset <= '1' after 0 sec, '0' after 7 * periode / 4;
 
    process(all)
    variable empreinte_calculee : empreinte_type;
    begin
        if reset = '1' then
            etat_tb <= attente;
            indice <= 0;
        elsif rising_edge(clk) then
            case etat_tb is
                when attente =>
                if indice = blocs_a_traiter'length then
                    report "La simulation est terminée." severity failure;
                end if;
                if fini = '1' then
                    etat_tb <= transmission;
                end if;
                when transmission =>
                if indice >= 1 then
                    if empreinte = empreintes_attendues(indice - 1) then
                        report "OK ! empreinte : " & to_hstring(empreinte) & ", empreinte attendue : " & to_hstring(empreintes_attendues(indice - 1)) severity note;
                    else            
                        report "Woops, erreur de calcul ! empreinte : " & to_hstring(empreinte) & ", empreinte attendue : " & to_hstring(empreintes_attendues(indice - 1)) severity error;
                    end if;
                end if;
                indice <= indice + 1;
                etat_tb <= attente;
            end case;
        end if;
        
        case etat_tb is
            when attente =>
            charge_et_go <= '0';
            when transmission =>
            bloc <= blocs_a_traiter(indice);
            charge_et_go <= '1';
        end case;
 
    end process;
    
    -- instanciation du module à vérifier
    UUT : entity SHA_1(iterative)
        port map (
            clk => clk,
            reset => reset,
            bloc => bloc,
            charge_et_go => charge_et_go,
            empreinte => empreinte,
            fini => fini
        );
        
end arch_tb;