-------------------------------------------------------------------------------
--
-- SHA_1.vhd
--
-- v. 1.0 2020-10-30 Pierre Langlois
-- version à compléter, labo #4 INF3500, automne 2021
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SHA_1_utilitaires_pkg.all;

entity SHA_1 is  
    port (
        clk, reset : in std_logic;
        bloc : in bloc_type;            -- le bloc à traiter, 16 mots de 32 bits
        charge_et_go : in std_logic;    -- '1' indique qu'il faut charger le bloc à traiter et débuter les calculs
        empreinte : out empreinte_type; -- empreinte numérique (= haché, valeur de hachage, message digest, digest, hash)
        fini : out std_logic            -- '0' pendant le traitement, '1' quand on a terminé le traitement du bloc, que l'empreinte est valide et qu'on est prêts à recommencer
    );
end SHA_1;

architecture iterative of SHA_1 is

signal W : bloc_type;                   -- mémoire circulaire de 16 registres de 32 mots pour le bloc et son expansion
signal A, B, C, D, E : mot32bits;       -- 5 tampons A, B, C, D, E utilisés pour 80 étapes du traitement d'un bloc
signal t : natural range 0 to 80;       -- le compteur d'étapes, 80 étapes pour traiter un bloc

begin

    process(all)
    begin
        if reset = '1' then
            -- votre code ici
        elsif rising_edge(clk) then
            -- votre code ici
            fini <= '1';                    -- énoncé bidon à remplacer
            empreinte <= (others => 'U');   -- énoncé bidon à remplacer
        end if;
    end process;

end iterative;