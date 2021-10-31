-------------------------------------------------------------------------------
--
-- SHA_1_cherche_collisions.vhd
--
-- v. 1.0 2020-11-01 Pierre Langlois
-- Recherche de collisions dans des empreintes de l'algorithme SHA-1
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utilitaires_inf3500_pkg.all;
use work.SHA_1_utilitaires_pkg.all;
use work.all;

entity SHA_1_cherche_collisions is  
    generic (
    message_de_base : string :="Bonjour, monde !";    -- le message de base auquel on va ajouter des caract�res
    collision : unsigned := x"00";                    -- les bits les plus significatifs de l'empreinte qui doivent correspondre pour qu'on ait une collision
    N : natural := 2                                  -- le nombre de caract�res � ajouter au message de base pour chercher une collision
    );
    port (
    clk, reset : in std_logic;
    trouve : out std_logic;                           -- '1' quand on a trouv� une collision
    chaine : out string(1 to N);                      -- la cha�ne de caract�res qui, ajout�e au message de base, produit la collision
    compte : out unsigned(N * 4 - 1 downto 0);        -- le num�ro de l'essai en cours
    erreur : out std_logic                            -- '1' si on a essay� toutes les chaines possibles �tant donn� la valeur de N et qu'on n'a rien trouv�
    );
end;

architecture arch of SHA_1_cherche_collisions is

signal compte_interne : unsigned(N * 4 - 1 downto 0);
signal charge_et_go_sha_1 : std_logic;
signal empreinte : empreinte_type;
signal fini_sha_1 : std_logic;

signal bloc_candidat : bloc_type;                   -- le bloc candidat pour une collision, incluant la chaine candidate

-- vos autres signaux ici ...
-- probablement une d�claration de type d'�tat, vous pouvez vous inspirer du code de SHA_1_TB


begin

    assert collision'length <= empreinte'length report "la taille de la collision cherch�e ne peut pas �tre sup�rieure � la taille de l'empreinte" severity failure;
    assert message_de_base'length + N <= 55 report "la taille totale du message, incluant la cha�ne candidate, doit �tre d'au plus 55 caract�res" severity failure;
    
    compte <= compte_interne;
    
    process(all)
    -- vos variables ici
    begin
        if reset = '1' then
            -- quelque chose ici
        elsif rising_edge(clk) then
            -- votre code ici
        end if;
    end process;

    -- instantiation du module SHA_1
    module_SHA_1 : entity SHA_1(iterative)
    port map (
        clk => clk,
        reset => reset,
        bloc => bloc_candidat,
        charge_et_go => charge_et_go_sha_1,
        empreinte => empreinte,
        fini => fini_sha_1
    );
    
end;



------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utilitaires_inf3500_pkg.all;
use work.all;

entity SHA_1_cherche_collisions_tb is
generic (
    message_de_base : string :="Bonjour, monde !";  -- le message de base auquel on va ajouter des caract�res
    collision : unsigned := x"000";                 -- les bits les plus significatifs de l'empreinte qui doivent correspondre pour qu'on ait une collision
    N : natural := 4                                -- le nombre de caract�res � ajouter au message de base pour chercher une collision
);

end;

architecture arch of SHA_1_cherche_collisions_tb is

signal clk : std_logic := '0';
signal reset : std_logic;
signal chaine : string(1 to N);
signal trouve, erreur : std_logic;
signal compte : unsigned(N * 4 - 1 downto 0);       -- le num�ro de l'essai en cours


constant periode : time := 10 ns;

begin

    clk <= not clk after periode / 2;
    reset <= '1' after 0 sec, '0' after 7 * periode / 4;
    
    assert trouve /= '1' report "On a trouv� une collision, simulation termin�e" severity failure;
    assert erreur /= '1' report "On a tout essay� mais on n'a pas trouv� de collision, simulation termin�e" severity failure;
    
    -- instanciation du module � v�rifier
    UUT : entity SHA_1_cherche_collisions(arch)
        generic map (
        message_de_base => message_de_base,
        collision => collision,
        N => N
        )
        port map (
            clk => clk,
            reset => reset,
            trouve => trouve,
            erreur => erreur,
            chaine => chaine,
            compte => compte
        );
       
end;