---------------------------------------------------------------------------------------------------
-- 
-- SHA_1_utilitaires_pkg.vhd
--
-- Pierre Langlois
-- v. 1.0, 2020/10/30
--
-- Déclarations et fonctions utilitaires pour le hachage SHA-1
-- 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;  

package SHA_1_utilitaires_pkg is

    subtype mot32bits is unsigned(31 downto 0);
    type bloc_type is array (0 to 15) of mot32bits;
    type bloc_multiple_type is array (natural range <>) of bloc_type;
    subtype empreinte_type is unsigned(159 downto 0);
    type empreintes_vecteur_type is array (natural range <>) of empreinte_type;
    
    -- valeurs d'initialisation des variables de l'algorithme
    constant H0_init : mot32bits := x"67452301";
    constant H1_init : mot32bits := x"EFCDAB89";
    constant H2_init : mot32bits := x"98BADCFE";
    constant H3_init : mot32bits := x"10325476";
    constant H4_init : mot32bits := x"C3D2E1F0";
    
    -- empreinte x"da39a3ee5e6b4b0d3255bfef95601890afd80709"
    constant bloc_test_0 : bloc_type := (               -- on suppose ici un message qui entre dans un seul bloc de 512 bits
    x"80000000", x"00000000", x"00000000", x"00000000", -- message vide "" encodé sur 14 mots de 32 bits, avec mot 0x80 ajouté
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000",                           -- des zéros
    x"00000000", x"00000000");                          -- les deux derniers mots sont la longueur du message en bits, qui est ici de 0 (00h) bits = 0 octets

    -- empreinte x"a9993e364706816aba3e25717850c26c9cd0d89d"
    constant bloc_test_1 : bloc_type := (               -- on suppose ici un message qui entre dans un seul bloc de 512 bits
    x"61626380", x"00000000", x"00000000", x"00000000", -- message "abc" encodé sur 14 mots de 32 bits, avec mot 0x80 ajouté
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000",                           -- des zéros
    x"00000000", x"00000018");                          -- les deux derniers mots sont la longueur du message en bits, qui est ici de 24 (18h) bits = 3 octets
    
    -- empreinte x"8ce4081e7eea6ace8332c7eb78415c57ec6ef2e3"
    constant bloc_test_2 : bloc_type := (               -- on suppose ici un message qui entre dans un seul bloc de 512 bits
    x"50696572", x"72658000", x"00000000", x"00000000", -- message "Pierre" encodé sur 14 mots de 32 bits, avec mot 0x80 ajouté
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000",                           -- des zéros
    x"00000000", x"00000030");                          -- les deux derniers mots sont la longueur du message en bits, qui est ici de 48 (30h) bits = 6 octets
    
    -- empreinte x"70c881d4a26984ddce795f6f71817c9cf4480e79"
    constant bloc_test_3 : bloc_type := (               -- on suppose ici un message qui entre dans un seul bloc de 512 bits
    x"61616161", x"80000000", x"00000000", x"00000000", -- message "aaaa" encodé sur 14 mots de 32 bits, avec mot 0x80 ajouté
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000", x"00000000", x"00000000", -- des zéros
    x"00000000", x"00000000",                           -- des zéros
    x"00000000", x"00000020");                          -- les deux derniers mots sont la longueur du message en bits, qui est ici de 31 (20h) bits = 4 octets
    
    function f(b, c, d : unsigned(31 downto 0); t : natural range 0 to 79) return unsigned;
    function k(t : natural range 0 to 79) return unsigned;
    function compose_bloc(m : string) return bloc_type;

end;

package body SHA_1_utilitaires_pkg is


    -- Pour saisir les subtilités de cette fonction il faut analyser la spécification de SHA-1 :
    --  FIPS PUB 180-1, Secure Hash Standard, US Department of Commerce, 1995 April 17
    --  https://csrc.nist.gov/publications/detail/fips/180/1/archive/1995-04-17
    function compose_bloc(m : string) return bloc_type is
    variable b : bloc_type;
    variable m_interne : string(1 to m'length + 1);             -- copie interne du message pour pouvoir ajouter un octet
    begin

        assert m'length <= 55 report "seuls les messages d'un seul bloc, donc d'au plus 55 caractères, sont supportés dans cette version" severity failure;

        m_interne := m & C128;                                  -- ajout de l'octet x"80" ('C128' du type character) comme sommaire immédiatement après le texte du message

        b := (others => x"00000000");                           -- on met des '0' partout par défaut
        for k in m_interne'range loop                           -- on remplit le bloc un caractère à la fois
            b((k - 1) / 4)((4 - (k - 1) mod 4) * 8 - 1 downto (3 - (k - 1) mod 4) * 8) := to_unsigned(character'pos(m_interne(k)), 8);
        end loop;
        b(14) := x"00000000";                                   -- chiffres les plus significatifs de la taille du message **bogue potentiel ici lors de la généralisation du code**
        b(15) := to_unsigned(m'length * 8, mot32bits'length);   -- chiffres les moins significatifs de la taille du message *en bits*

        return b;
    
    end;

    -- Fonction f des 80 étapes.
    -- Fonction logique simple des registres B, C, D.
    -- La nature de la fonction dépend de l'étape t - on a donc une petite UAL à 4 fonctions.
    function f(b, c, d : unsigned(31 downto 0); t : natural range 0 to 79) return unsigned is
    begin
        
        assert 0 <= t and t <= 79 report "il faut 0 <= t <= 79" severity failure;
        
        if t <= 19 then
            return (b and c) or ((not b) and d);
        elsif t <= 39 then
            return b xor c xor d;
        elsif t <= 59 then
            return (b and c) or (b and d) or (c and d);
        else
            return b xor c xor d;
        end if;
    
    end;
    
    -- Fonction k des 80 étapes.
    -- Il s'agit d'une ROM à 80 mots, mais qui ne contient que 4 mots différents.
    -- Le numéro de l'étape t en cours détermine la constante qui est retournée.
    function k(t : natural range 0 to 79) return unsigned is
    begin
    
        assert 0 <= t and t <= 79 report "il faut 0 <= t <= 79" severity failure;
    
        if t <= 19 then
            return x"5A827999"; -- environ sqrt(2) * 2^32
        elsif t <= 39 then
            return x"6ED9EBA1"; -- environ sqrt(3) * 2^32
        elsif t <= 59 then
            return x"8F1BBCDC"; -- environ sqrt(5) * 2^32
        else
            return x"CA62C1D6"; -- environ sqrt(10) * 2^32
        end if;
    
    end;

end;