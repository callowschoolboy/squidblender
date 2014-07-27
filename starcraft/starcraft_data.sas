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

proc sort data=attrlabs; by variable; run;
proc sort data=notes; by variable; run;
data meta;
merge notes attrlabs;
by variable;
run;

data SC;
infile cards stopover;
attrib unit_wp  length=$14.                                   label='Unit name with attribs';
attrib size     length=8  format=size.     informat=i_size.   label='Unit Size';
attrib lives    length=8  format=lives.    informat=i_lives.  label='Unit lives in or on:';
attrib attA     length=8  format=attA.     informat=i_attA.   label='Able to atttack air';
attrib attG     length=8  format=attG.     informat=i_attG.   label='Able to atttack ground';
attrib dtconc   length=8  format=dtconc.   informat=i_dtconc. label='Damage type concussive';
attrib dtexp    length=8  format=dtexp.    informat=i_dtexp.  label='Damage type explosive';
attrib hits                                                   label='Simul. hits per attack';
attrib listdmg                                                label='Damage listed in HUD';
attrib cool                                                   label='Cooldown time in frames';
attrib pop                                                    label='Population required';
attrib min                                                    label='Minerals required';
attrib gas                                                    label='Vespene gas required';
attrib hp                                                     label='Hit points';
attrib shields                                                label='Shield points (P only)';
attrib att_mod                                                label='Attack modifier per upgrade';
attrib range                                                  label='Range (close=0';
attrib sight                                                  label='Sight';                  
attrib bt                                                     label='Build time';
attrib race     length=8  format=race.     informat=i_race.   label='Race';                   
attrib cloak    length=8  format=cloak.    informat=i_cloak.  label='Amount of cloaking unit cap. of'; 
attrib spells                                                 label='Number of spells unit can cast';
attrib bio      length=8  format=bio.      informat=i_bio.    label='Biological (dmg by Ir)';
attrib detector length=8  format=detector. informat=i_detector. label='Unit can detect cloaked?';
attrib splash   length=8  format=8.        informat=i_splash. label='Unit deals splash dmg?';
attrib speed                                                  label='Unit speed rel to worker';
attrib mech     length=8  format=mech.     informat=i_mech.   label='Mechanical (targ LockD)';
attrib robotic  length=8  format=robotic.  informat=i_robotic. label='Robotic (no SB)';
attrib hover    length=8  format=hover.    informat=i_hover.  label="Hovering (doesn't trigger Sp Mines)";
attrib friendly length=8  format=friendly. informat=i_friendly. label='Splash to friendly units'; 
attrib type     length=8  format=type.     informat=i_type.   label='Unit type (Basic, Trans, Peon, Sui)'; 


  input unit_wp $1-14 /*Unit name, delimiters, weapon and upgrade*/
        size    $     /*L=large, M=Medium, S=Small, interrel w/ damage type*/
        lives   $     /*Unit either lives A=in the air or G=on the ground*/
        attA    $     /*This unit A=can attack air units -=can't*/   
        attG    $     /*This unit G=can attack ground units*/
        dtconc  $     /*Deals C=concussive damage*/
        dtexp   $     /*Deals E=explosive damage*/
        hits          /*see label, levels are . for NC, 1,2 or 8*/
        listdmg       /*see label, 000 for NC*/
        cool          /*inverse of RoF, unit of time is FRAMES*/
        pop           /*game cap is 200, */
        min           /*Basic units cost only min 2m~=1g*/
        gas           /*Harder to gather, one worker at a time*/
        armor         /*first modifier to damage in combat*/
        hp            /*see label*/
        shields       /*only for Protoss, regen more quickly than Z cannot be healed, before armor*/
        att_mod       /*see label*/
        range         /*QUESTION THIS CAREFULLY !!! 0 for nonC, 1 for close (Int and SM irregular)*/
        sight         /*Distance unit can see in fog of war*/
        bt            /*Build time, unknown units*/
        race     $    /*P=Protoss, T=Terran, Z=Zerg*/
        cloak    $    /*  + always = ability * confers  */ 
        spells        /**/
        bio      $    /* defined as affected by Irradiate, * seems bio but not <- */ 
        detector $    /**/ 
        splash   $    /*sev types, distros inc 2x2 for valk*/ 
        speed         /**/
        mech     $    /**/
        robotic  $    /**/ 
        hover    $    /**/ 
        friendly $    /*see label*/ 
        type     $    /**/
       ;
*no integrity;

	   *a data cluge for Spider mine's weird detection, 2 binaries, can take just one when appropriate;
	   AnyDetect=detector;
	   FullDetect=detector;
	   if unit_wp="Spider Mine/Su" then do; AnyDetect=1; FullDetect=-1; end; *simple statement is Any includes SMs, Full doesnt;
	   drop detector;
	   attrib AnyDetect  length=8  /*format=AnyDetect.*/  label='Unit has any amt. detection?';
	   attrib FullDetect length=8  /*format=FullDetect.*/ label='Unit reveals cloaked inc. air?';

	   *a similar cluge for Ephemeral breakout from Robo, move to SBable. I think that eliminates the diff, re:SB R==E;
	   if robotic in (1,99)/*robo or eph*/ then SpawnBroodlings=-1; if lives=-1/*air*/ then SpawnBroodlings=-1;
	   else if bio=1 then SpawnBroodlings=1; *check on the definition but Im pretty sure thats right;



*calculated;
  totcost=min+2*gas+.01;  *something like an svm ought to grok min/gas much better than this heuristic but for simplistic models it'll be useful, left semi-orphan it's
                     kind of like the decision NOT to make a redundant 3-nom for NEC dmgtyp feels better to have 2 binaries for E/C;
  * prefer adj_dmg     throughput=listdmg/cool;
  * PREFER adjusted_hp    tothp=hp+shields;
  *if (attA="A" & attG="G") then dual=1; 
  * These are just multicoll, no need for them, this data is a glass half full thing
       if (dtconc="-" & dtexp="-" & hits^=. & listdmg>000) then dtnorm="N"; 
cards;
Arbiter/Phase_  L A A G - E 1 10  45  4     100     350     1     200 150     1     5     9     160 P * 2 - - - 1.000 M - H - -
Archon/Psionic  L G A G - - 1 30  20  4     100     300     0     10  350     3     2     8     120 P - 0 - - R 1.000 - E H N -
Carrier         L A - - - - 0 000  0  6     350     250     4     300 150     0     0     11    140 P - 0 - - - 0.666 M - H - X
Carrier=1Inter  L A A G - - 1  6  40  6     375     250     4     340 180     1     8     11    158 P - 0 - - - 0.666 M - H - -
Interceptor/Pu  S A A G - - 1  6  37  0     25      0       0     40  40      1     1     6     20  P - 0 - - - 2.667 M - H - -
Corsair/Neutro  M A A - - E 1  5   8  2     150     100     1     100 80      1     5     9     40  P - 1 - - R 1.334 M - H N -
Dark Archon     L G - - - - 0 000  0  4     250     200     1     25  200     0     0     10    120 P - 3 - - - 1.000 - E H - -
Dark Templar/W  S G - G - - 1 40  30  2     125     100     1     80  40      3     1     7     50  P + 0 B - - 1.000 - - - - -
Dragoon/Phase_  L G A G - E 1 20  30  2     125     50      1     100 80      2     4     8     50  P - 0 - - - 1.050 M - - - -
High Templar    S G - - - - 0 000  0  2     50      150     0     40  40      0     0     7     50  P - 2 B - - 0.651 - - - S -
Observer        S A - - - - 0 000  0  1     25      75      0     40  20      0     0     9     40  P + 0 - D - 0.666 M - H - -
Observer+Gravi  S A - - - - 0 000  0  1     25      75      0     40  20      0     0     9     40  P + 0 - D - 1.000 M - H - -
Photon Cannon/  L G A G - - 1 20  22  0     150     0       0     100 100     0     7     11    50  P - 0 - D - 0     - - - - E
Probe/Particle  S G - G - - 1  5  22  1     50      0       0     20  20      0     1     8     20  P - 0 - - - 1.000 M R H - P
Reaver          L G - - - - 0 000  0  4     200     100     0     100 80      0     0     10    70  P - 0 - - - 0.365 M R - - X
Reaver=ScarabX  L G - G - E 1 100 60  4     215     100     0     100 80      0     8     10    87  P - 0 - - R 0.365 M R - N -
Scout/Photon_B  L A - G - - 2  4  30  3     275     125     0     150 100     1     4     8     80  P - 0 - - - 1.000 M - H - -
Scout/Antimatt  L A A - - E 2 14  22  3     275     125     0     150 100     2     4     8     80  P - 0 - - - 1.000 M - H - -
Shuttle         L A - - - - 0 000  0  2     200     0       1     80  60      0     0     8     60  P - 0 - - - 0.885 M - H - T
Shuttle+Gravit  L A - - - - 0 000  0  2     200     0       1     80  60      0     0     8     60  P - 0 - - - 1.200 M - H - T
Zealot/Psi_Bla  S G - G - - 2  8  22  2     100     0       1     80  80      2     1     7     40  P - 0 B - - 0.800 - - - - -
Zealot/Psi+Leg  S G - G - - 2  8  22  2     100     0       1     80  80      2     1     7     40  P - 0 B - - 1.167 - - - - -
Battlecruiser/  L A A G - - 1 25  30  6     400     300     3     500 0       3     6     11    133 T - 1 - - - 0.500 M - H - -
Dropship        L A - - - - 0 000  0  2     100     100     1     150 0       0     0     8     50  T - 0 - - - 1.094 M - H - T
Firebat/Perdit  S G - G C - 2  8  22  1     50      25      1     50  0       2     2     7     24  T - 0 B - ! 0.800 - - - N -
Firebat/P=Stim  S G - G C - 2  8  11  1     50      25      1     40  0       2     2     7     24  T - 0 B - ! 1.200 - - - N -
Ghost/C-10Cani  S G A G C - 1 10  22  1     25      75      0     45  0       1     7     9     50  T = 2 B - - 0.800 - - - - -
Goliath/Autoca  L G - G - - 1 12  22  2     100     50      1     125 0       1     6     8     40  T - 0 - - - 0.933 M - - - -
Goliath/Hellfi  L G A - - E 2 10  22  2     100     50      1     125 0       4     5     8     40  T - 0 - - - 0.933 M - - - -
Marine/C-14Rif  S G A G - - 1  6  15  1     50      0       0     40  0       1     4     7     24  T - 0 B - - 0.800 - - - - -
Marine/C=StimP  S G A G - - 1  6  7.5 1     50      0       0     30  0       1     4     7     24  T - 0 B - - 1.200 - - - - -
Medic           S G - - - - 0 000  0  1     50      25      1     60  0       0     0     9     30  T - 3 B - - 0.800 - - - - -
Missile Turret  L G A - - E 1 20  15  0     75      0       0     200 0       0     7     11    30  T - 0 - D - 0     - - - - E
Science Vessel  L A - - - - 0 000  0  2     100     225     1     200 0       0     0     10    80  T - 3 - D - 1.000 M - H S -
SCV/Fusion_Cut  S G - G - - 1  5  15  1     50      0       0     60  0       0     1     7     20  T - 0 B - - 1.000 M - H - P
Siege Tank/80m  L G - G - E 1 30  37  2     150     100     1     150 0       3     7     10    50  T - 0 - - - 0.800 M - - - -
Siege Tank=S/M  L G - G - E 1 70  75  2     150     100     1     150 0       5     12    10    50  T - 0 - - R 0     M - - Y -
Spider Mine/Su  S G - G - E 1 125  0  0     25      0       0     20  0       0     0     3     1   T b 0 - - R .     - R . Y S
Valkyrie/HALO_  L A A - - E 8  6  64  3     250     125     2     200 0       1     6     8     50  T - 0 - - R 1.320 M - H N -
Vulture/Thumpe  M G - G C - 1 20  30  2     75      0       0     80  0       2     5     8     30  T - 1 - - - 1.286 M - H - -
Vulture/Th+Ion  M G - G C - 1 20  30  2     75      0       0     80  0       2     5     8     30  T - 1 - - - 1.881 M - H - -
Wraith/25mmBur  L A - G - - 1  8  30  2     150     100     0     120 0       1     5     7     60  T = 0 - - - 1.334 M - H - -
Wraith/Gemini_  L A A - - E 2 10  22  2     150     100     0     120 0       2     5     7     60  T = 0 - - - 1.334 M - H - -
Broodling/Toxi  S G - G - - 1  4  15  0     0       0       0     30  0       1     1     5     0   Z - 0 B - - 1.364 - - - - -
Defiler         M G - - - - 0 000  0  2     50      150     1     80  0       0     0     10    50  Z - 3 B - - 0.800 - - - - -
Drone           S G - G - - 1  5  22  1     50      0       0     40  0       0     1     7     20  Z - 0 B - - 1.000 - - H - P
Hydralisk/Need  M G A G - E 1 10  15  1     75      25      0     80  0       1     4     6     28  Z - 0 B - - 0.750 - - - - -
Hydralisk/N+Mu  M G A G - E 1 10  15  1     75      25      0     80  0       1     4     6     28  Z - 0 B - - 1.105 - - - - -
Inf. Terran/Su  S G - G - E 1 500  0  1     100     50      0     60  0       0     0     5     40  Z - 0 B - R .     - - - Y S
Lurker          M G - - - - 0 000  0  3     125     125     1     125 0       .     0     8     68  Z - 0 B - - 1.200 - - - - -
Lurker=B/Subte  M G - G - - 1 20  37  3     125     125     1     125 0       2     6     8     68  Z b 0 B - L 0     - - - N -
Mutalisk/Glave  S A A G - - 1  9  30  2     100     100     0     120 0       1     3     7     40  Z - 0 B - 2 1.334 - - - N -
Overlord        L A - - - - 0 000  0  0     100     0       0     200 0       0     0     9     40  Z - 0 B D - 0.167 - - - - -
Overlord+Pneum  L A - - - - 0 000  0  0     100     0       0     200 0       0     0     9     40  Z - 0 B D - 0.667 - - - - -
Overlord+Ventr  L A - - - - 0 000  0  0     100     0       0     200 0       0     0     9     40  Z - 0 B D - 0.167 - - - - T
Queen           M A - - - - 0 000  0  2     100     100     0     120 0       0     0     10    50  Z - 3 B - - 1.344 - - - - -
Scourge/Suicid  S A A - - - 1 110  0  0.5   12.5    37.5    0     25  0       0     0     5     15  Z - 0 B - - 1.334 - - - - S
Spore Colony/S  L G A - - - 1 15  15  0     175     0       0     400 0       0     7     10    60  Z - 0 - D - 0     - - - - E
Sunken Colony/  L G - G - E 1 40  32  0     175     0       2     300 0       0     7     10    60  Z - 0 - - - 0     - - - - E
Ultralisk/Kais  L G - G - - 1 20  15  4     200     200     1     400 0       3     1     7     60  Z - 0 B - - 1.050 - - - - -
Ultralisk/K+An  L G - G - - 1 20  15  4     200     200     1     400 0       3     1     7     60  Z - 0 B - - 1.556 - - - - -
Zergling/Claws  S G - G - - 1  5   8  0.5   25      0       0     35  0       1     1     5     14  Z - 0 B - - 1.108 - - - - -
Zergling/C+Met  S G - G - - 1  5   8  0.5   25      0       0     35  0       1     1     5     14  Z - 0 B - - 1.615 - - - - -
Devourer/Corro  L A A - - E 1 25 100  2     250     150     2     250 0       2     6     10    80  Z - 0 B - - 1.000 - - - - -
Guardian/Acid_  L A - G - - 1 20  30  2     150     200     2     150 0       2     8     11    80  Z - 0 B - - 0.500 - - - - -
Larva           S G - - - - 0 000  0  0     0       0      10     25  0       0     0     4     14  Z - 0 - - - 0     - - - - X
Egg             M G - - - - 0 000  0  0     0       0      10     200 0       0     0     4     0   Z - 0 - - - 0     - - - - X
;
run;

proc print; where race=2; 
*where size=1; run;

proc freq nlevels; run;


data sc_tr sc_te;
set sc;
WHERE race in (2,3);
if unit_wp in ("Marine/C=StimP","Siege Tank/80m","Wraith/Gemini_","Drone","Hydralisk/N+Mu","Scourge/Suicid") then output sc_te;
else output sc_tr;
run;


proc logistic data=sc_tr;
   class bio (param=ref ref='1') FullDetect (param=ref ref='1');
   model race (ref='Terran') = totcost tothp throughput pop bt speed bio FullDetect;
   exact bio FullDetect / estimate=both outdist=dist;
run;


*0 training error highly suspicious from RBF100 but gets best test error too!  RBF1 and RBF10 do pretty good but no other svm got 5/6...; 
%let ktype=RBF; 
%let method=activeset;
title "&ktype. kernel, &method.";
proc hpsvm data=sc_tr task=c_clas  maxiter = 25 method=&method. 
  tolerance=1.0E-8  c=100 
  printclass printfit ;
  ods output Nobs=Nobs1 ModelInformation=MS1 Dimensions=DM1 
      TrainingResult=MI1 FitStatistics=FS1 
      ClassificationMatrix=FC1 ParameterEstimates=EST1
      Variables=VR1 TargetProfile=TP1;
    kernel &ktype.;
    input pop range / level=ordinal;
	input gas hp bt / level=interval;
  target race / level=binary; 
    output outclass=class1 outfit=fit1 outest=est1;
run;

proc svmscore data=sc_te infit=fit1 inclass=class1 inest=est1
   out=scores_one;
run;
