data attrlabs;
input variable $ length $ format $ label $ &;
datalines4;
unit_wp  $14. .           'Unit name with attribs';
size     $1 $1.   'Unit Size';
lives    $1 $1.   'Unit lives in or on:';
attA     $1 $1.   'Able to atttack air';
attG     $1 $1.   'Able to atttack ground';
dtconc   $1 $1.   'Damage type concussive';
dtexp    $1 $1.   'Damage type explosive';
hits      . .                      'Simul. hits per attack';
listdmg    . .                     'Damage listed in HUD';
cool      . .                      'Cooldown time in frames';
pop       . .                      'Population required';
min       . .                      'Minerals required';
gas       . .                      'Vespene gas required';
hp        . .                      'Hit points';
shields   . .                      'Shield points (P only)';
att_mod   . .                      'Attack modifier per upgrade';
range     . .                      'Range (close=0';
sight      . .                     'Sight';                  
bt         . .                     'Build time';
race     $1 $1.   'Race';                   
cloak    $1 $1.   'Amount of cloaking unit cap. of'; 
spells    . .                      'Number of spells unit can cast';
bio      $1 $1.   'Biological (dmg by Ir)';
detector $1 $1.   'Unit can detect cloaked?';
splash   $1 $1.   'Unit deals splash dmg?';
speed     . .                      'Unit speed rel to worker';
mech     $1 $1.   'Mechanical (targ LockD)';
robotic  $1 $1.   'Robotic (no SB)';
hover    $1 $1.   "Hovering (doesn't trigger Sp Mines)";
friendly $1 $1.   'Splash to friendly units'; 
type     $1 $1.   'Unit type (Basic, Trans, Peon, Sui)'; 
;;;;
run;
data notes;
  input variable $ notes $ &;
  cards;
        unit_wp       Unit name, delimiters, weapon and upgrade
        size          L=large, M=Medium, S=Small, interrel w/ damage type
        lives         Unit either lives A=in the air or G=on the ground
        attA          This unit A=can attack air units -=can't   
        attG          This unit G=can attack ground units
        dtconc        Deals C=concussive damage
        dtexp         Deals E=explosive damage
        hits          see label, levels are . for NC, 1,2 or 8
        listdmg       see label, 000 for NC
        cool          inverse of RoF, unit of time is FRAMES
        pop           game cap is 200, 
        min           Basic units cost only min 2m~=1g
        gas           Harder to gather, one worker at a time
        armor         first modifier to damage in combat
        hp            see label
        shields       only for Protoss, regen more quickly than Z cannot be healed, before armor
        att_mod       see label
        range         QUESTION THIS CAREFULLY !!! 0 for nonC, 1 for close (Int and SM irregular)
        sight         Distance unit can see in fog of war
        bt            Build time, unknown units
        race          P=Protoss, T=Terran, Z=Zerg
        cloak           + always = ability * confers   
        spells        NO NOTES
        bio            defined as affected by Irradiate, * seems bio but not <-  
        detector       NO NOTES
        splash        sev types, distros inc 2x2 for valk 
        speed         NO NOTES
        mech          NO NOTES
        robotic       NO NOTES 
        hover         NO NOTES 
        friendly      see label 
        type          NO NOTES
run;
proc format library=work;    * thinking in's never NEED $;
 invalue i_size 'S'=1
                'M'=2
                'L'=3;  *Size is ORDINAL;
 value size       1="Small"
                  2="Medium"
				  3="Large";
 invalue i_lives 'A'=-1
                 'G'=1; *Lives is boolean therefore ORDINAL;
 value lives      -1="Air unit"
                   1="Ground unit";
 invalue i_attA  'A'=1
                 '-'=-1; *boolean;
 value attA       -1="CANNOT attack air"
                   1="Can attack air";
 invalue i_attG  'G'=1
                 '-'=-1; *boolean;
 value attG       -1="CANNOT attack ground"
                   1="Can attack ground";
 invalue i_dtconc 'C'=1
                  '-'=-1;
 value dtconc  1="Concussive"
              -1="Not concussive";
  invalue i_dtexp  'E'=1
                   '-'=-1;
 value dtexp  1="Explosive"
             -1="Not explosive";
 invalue i_race  'P'=1 
                 'T'=2
                 'Z'=3;  *NOMINAL not ord;
 value race  1="Protoss"
             2="Terran"
             3="Zerg";
 invalue i_cloak  '-'=0
                  '='=1
                  '+'=2
                  '*'=3
                  'b'=4;/*  ordinal    consider standard for nominals (start at 0 or 1)*/
 value cloak  0="No cloaking"
              1="Ability to cloak"
              2="Always cloaked"
              3="Cloaked and conveys"
              4="Attacks only if burrowed";
 invalue i_bio  '-'=-1 
                '*'=-.99
                'B'=1
                'b'=.99;/* defined as affected by Irradiate, ORDINAL bc '*' seems bio but not rolled up */    
 value bio  1="Biological"
           -1="Not biological";
 invalue i_detector  'D'=1
                     '-'=-1;
 value detector  1="Detector"
                -1="Not detector";
 invalue i_splash   '-'=0
                    '!'=1
                    'L'=2
                    'R'=3
                    '2'=5;/*sev types,  2x2 for valk but it has value 'R', 5 levels if ORD determine proper order*/
 *value splash  not yet well-defined;
 invalue i_mech   '-'=-1
                  '.'=-1   /*rolled up, it is true that buildings (e.g. emplacements) not mech, cannot be targ by lockdown*/
                  'M'=1;
 value mech  1="Mechanical"
            -1="Not mechanical";
 invalue i_robotic   '-'=-1
                     'E'=99
                     'R'=1;
 value robotic  1="Robotic"
               99="Ephemeral"
               -1="Not robotic";
 invalue i_hover   '-'=-1
                   'H'=1;
 value hover  1="Hovering"
             -1="Not hovering";
 invalue i_friendly  '-'=0
                     'S'=1
                     'N'=2
                     'Y'=3;
 value friendly 0="No friendly fire"
                1="Spell deals friendly"
            ;*    2="Not sure"
                3="Probably";  *FIX;
 invalue i_type  '-'=0
                 'B'=1    /* remove idea of "BASIC" */
                 'T'=2
                 'S'=3
                 'X'=4    /* 'x'-->'c' */
                 'E'=5
                 'P'=6    /* change in the data creator */
                 'W'=7;  *not including spell-caster, wold be redundant;
 value type 0="No special type"

            2="Transporter"
            3="Suicide"
            4="Carrier"
            5="Emplacement (combat building)"
            6="Proto-unit"
            7="Worker/Builder";        
 run;