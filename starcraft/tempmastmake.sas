data SC;
infile cards stopover;
attrib unit_wp  length=$14.            label='Unit name with attribs';
attrib size     length=$1 format=$1.   label='Unit Size';
attrib lives    length=$1 format=$1.   label='Unit lives in or on:';
attrib attA     length=$1 format=$1.   label='Able to atttack air';
attrib attG     length=$1 format=$1.   label='Able to atttack ground';
attrib dtconc   length=$1 format=$1.   label='Damage type concussive';
attrib dtexp    length=$1 format=$1.   label='Damage type explosive';
attrib hits                            label='Simul. hits per attack';
attrib listdmg                         label='Damage listed in HUD';
attrib cool                            label='Cooldown time in frames';
attrib pop                             label='Population required';
attrib min                             label='Minerals required';
attrib gas                             label='Vespene gas required';
attrib hp                              label='Hit points';
attrib shields                         label='Shield points (P only)';
attrib att_mod                         label='Attack modifier per upgrade';
attrib range                           label='Range (close=0';
attrib sight                           label='Sight';                  
attrib bt                              label='Build time';
attrib race     length=$1 format=$1.   label='Race';                   
attrib cloak    length=$1 format=$1.   label='Amount of cloaking unit cap. of'; 
attrib spells                          label='Number of spells unit can cast';
attrib bio      length=$1 format=$1.   label='Biological (dmg by Ir)';
attrib detector length=$1 format=$1.   label='Unit can detect cloaked?';
attrib splash   length=$1 format=$1.   label='Unit deals splash dmg?';
attrib speed                           label='Unit speed rel to worker';
attrib mech     length=$1 format=$1.   label='Mechanical (targ LockD)';
attrib robotic  length=$1 format=$1.   label='Robotic (no SB)';
attrib hover    length=$1 format=$1.   label="Hovering (doesn't trigger Sp Mines)";
attrib friendly length=$1 format=$1.   label='Splash to friendly units'; 
attrib type     length=$1 format=$1.   label='Unit type (Basic, Trans, Peon, Sui)'; 


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
*integrity;
 *1; if not ( (listdmg=0 & hits=. & cool=.) | (listdmg>0 & hits^=. & cool^=.) | (listdmg>0 &
           hits=. & cool=. & type eq 'S') ) then do; put "DATA ERROR type 1 !!"; put unit_wp; *abort; end;
 *2; if not ( (type="E" & speed=. & pop=. & bio='.' & mech='.' & robotic='.' & hover='.') 
               | (type^="E" & speed^=. & pop^=. & bio^='.' & mech^='.' & robotic^='.' & hover^='.') )
           then do; put "DATA ERROR type 2 !!"; put unit_wp; *abort; end;
*calculated;
  totcost=min+2*gas+.01;
  throughput=listdmg/cool;
  tothp=hp+shields;
  if (attA="A" & attG="G") then dual=1; else dual=0;
  if (dtconc="-" & dtexp="-" & hits^=. & listdmg>000) then dtnorm="N"; else dtnorm="-";
cards;
Arbiter/Phase_  L A A G - E 1 10  45  4     100     350     1     200 150     1     5     9     160 P * 2 - - - 1.000 M - A - -
Archon/Psionic  L G A G - - 1 30  20  4     100     300     0     10  350     3     2     8     120 P - 0 - - R 1.000 - E H N -
Carrier         L A - - - - . 000  .  6     350     250     4     300 150     .     0     11    140 P - 0 - - - 0.666 M - A - X
Carrier=1Inter  L A A G - - 1  6  40  6     375     250     4     340 180     1     8     11    158 P - 0 - - - 0.666 M - A - -
Interceptor/Pu  S A A G - - 1  6  37  0     25      0       0     40  40      1     1     6     20  P - 0 - - - 2.667 M - A - -
Corsair/Neutro  M A A - - E 1  5   8  2     150     100     1     100 80      1     5     9     40  P - 1 - - R 1.334 M - A N -
Dark Archon     L G - - - - . 000  .  4     250     200     1     25  200     .     0     10    120 P - 3 - - - 1.000 - E H - -
Dark Templar/W  S G - G - - 1 40  30  2     125     100     1     80  40      3     1     7     50  P + 0 B - - 1.000 - - - - -
Dragoon/Phase_  L G A G - E 1 20  30  2     125     50      1     100 80      2     4     8     50  P - 0 - - - 1.050 M - - - -
High Templar    S G - - - - . 000  .  2     50      150     0     40  40      .     0     7     50  P - 2 B - - 0.651 - - - S -
Observer        S A - - - - . 000  .  1     25      75      0     40  20      .     0     9     40  P + 0 - D - 0.666 M - A - -
Observer+Gravi  S A - - - - . 000  .  1     25      75      0     40  20      .     0     9     40  P + 0 - D - 1.000 M - A - -
Photon Cannon/  L G A G - - 1 20  22  .     150     0       0     100 100     0     7     11    50  P - 0 . D - .     . . . - E
Probe/Particle  S G - G - - 1  5  22  1     50      0       0     20  20      0     1     8     20  P - 0 - - - 1.000 M R H - P
Reaver          L G - - - - . 000  .  4     200     100     0     100 80      .     0     10    70  P - 0 - - - 0.365 M R - - X
Reaver=ScarabX  L G - G - E 1 100 60  4     215     100     0     100 80      0     8     10    87  P - 0 - - R 0.365 M R - N -
Scout/Photon_B  L A - G - - 2  4  30  3     275     125     0     150 100     1     4     8     80  P - 0 - - - 1.000 M - A - -
Scout/Antimatt  L A A - - E 2 14  22  3     275     125     0     150 100     2     4     8     80  P - 0 - - - 1.000 M - A - -
Shuttle         L A - - - - . 000  .  2     200     0       1     80  60      .     0     8     60  P - 0 - - - 0.885 M - A - T
Shuttle+Gravit  L A - - - - . 000  .  2     200     0       1     80  60      .     0     8     60  P - 0 - - - 1.200 M - A - T
Zealot/Psi_Bla  S G - G - - 2  8  22  2     100     0       1     80  80      2     1     7     40  P - 0 B - - 0.800 - - - - B
Zealot/Psi+Leg  S G - G - - 2  8  22  2     100     0       1     80  80      2     1     7     40  P - 0 B - - 1.167 - - - - -
Battlecruiser/  L A A G - - 1 25  30  6     400     300     3     500 0       3     6     11    133 T - 1 - - - 0.500 M - A - -
Dropship        L A - - - - . 000  .  2     100     100     1     150 0       .     0     8     50  T - 0 - - - 1.094 M - A - T
Firebat/Perdit  S G - G C - 2  8  22  1     50      25      1     50  0       2     2     7     24  T - 0 B - ! 0.800 - - - N -
Firebat/P=Stim  S G - G C - 2  8  11  1     50      25      1     40  0       2     2     7     24  T - 0 B - ! 1.200 - - - N -
Ghost/C-10Cani  S G A G C - 1 10  22  1     25      75      0     45  0       1     7     9     50  T = 2 B - - 0.800 - - - - -
Goliath/Autoca  L G - G - - 1 12  22  2     100     50      1     125 0       1     6     8     40  T - 0 - - - 0.933 M - - - -
Goliath/Hellfi  L G A - - E 2 10  22  2     100     50      1     125 0       4     5     8     40  T - 0 - - - 0.933 M - - - -
Marine/C-14Rif  S G A G - - 1  6  15  1     50      0       0     40  0       1     4     7     24  T - 0 B - - 0.800 - - - - B
Marine/C=StimP  S G A G - - 1  6  7.5 1     50      0       0     30  0       1     4     7     24  T - 0 B - - 1.200 - - - - -
Medic           S G - - - - . 000  .  1     50      25      1     60  0       .     0     9     30  T - 3 B - - 0.800 - - - - -
Missile Turret  L G A - - E 1 20  15  .     75      0       0     200 0       0     7     11    30  T - 0 . D - .     . . . - E
Science Vessel  L A - - - - . 000  .  2     100     225     1     200 0       .     0     10    80  T - 3 - D - 1.000 M - A S -
SCV/Fusion_Cut  S G - G - - 1  5  15  1     50      0       0     60  0       0     1     7     20  T - 0 B - - 1.000 M - H - P
Siege Tank/80m  L G - G - E 1 30  37  2     150     100     1     150 0       3     7     10    50  T - 0 - - - 0.800 M - - - -
Siege Tank=S/M  L G - G - E 1 70  75  2     150     100     1     150 0       5     12    10    50  T - 0 - - R .     M - - Y -
Spider Mine/Su  S G - G - E 1 125  .  0     25      0       0     20  0       0     *     3     1   T b 0 - ! R ??    - R ? Y S
Valkyrie/HALO_  L A A - - E 8  6  64  3     250     125     2     200 0       1     6     8     50  T - 0 - - R 1.320 M - A N -
Vulture/Thumpe  M G - G C - 1 20  30  2     75      0       0     80  0       2     5     8     30  T - 1 - - - 1.286 M - H - -
Vulture/Th+Ion  M G - G C - 1 20  30  2     75      0       0     80  0       2     5     8     30  T - 1 - - - 1.881 M - H - -
Wraith/25mmBur  L A - G - - 1  8  30  2     150     100     0     120 0       1     5     7     60  T = 0 - - - 1.334 M - A - -
Wraith/Gemini_  L A A - - E 2 10  22  2     150     100     0     120 0       2     5     7     60  T = 0 - - - 1.334 M - A - -
Broodling/Toxi  S G - G - - 1  4  15  0     0       0       0     30  0       1     1     5     0   Z - 0 B - - 1.364 - - - - -
Defiler         M G - - - - . 000  .  2     50      150     1     80  0       .     0     10    50  Z - 3 B - - 0.800 - - - - -
Drone           S G - G - - 1  5  22  1     50      0       0     40  0       0     1     7     20  Z - 0 B - - 1.000 - - H - P
Hydralisk/Need  M G A G - E 1 10  15  1     75      25      0     80  0       1     4     6     28  Z - 0 B - - 0.750 - - - - -
Hydralisk/N+Mu  M G A G - E 1 10  15  1     75      25      0     80  0       1     4     6     28  Z - 0 B - - 1.105 - - - - -
Inf. Terran/Su  S G - G - E 1 500  .  1     100     50      0     60  0       0     0     5     40  Z - 0 B - R ??    - - - Y S
Lurker          M G - - - - . 000  .  3     125     125     1     125 0       .     0     8     68  Z - 0 B - - 1.200 - - - - -
Lurker=B/Subte  M G - G - - 1 20  37  3     125     125     1     125 0       2     6     8     68  Z b 0 B - L 0     - - - N -
Mutalisk/Glave  S A A G - - 1  9  30  2     100     100     0     120 0       1     3     7     40  Z - 0 B - 2 1.334 - - - N -
Overlord        L A - - - - . 000  .  0     100     0       0     200 0       .     0     9     40  Z - 0 B D - 0.167 - - - - -
Overlord+Pneum  L A - - - - . 000  .  0     100     0       0     200 0       .     0     9     40  Z - 0 B D - 0.667 - - - - -
Overlord+Ventr  L A - - - - . 000  .  0     100     0       0     200 0       .     0     9     40  Z - 0 B D - 0.167 - - - - T
Queen           M A - - - - . 000  .  2     100     100     0     120 0       .     0     10    50  Z - 3 B - - 1.344 - - - - -
Scourge/Suicid  S A A - - - 1 110  .  0.5   12.5    37.5    0     25  0       0     0     5     15  Z - 0 B - - 1.334 - - - - S
Spore Colony/S  L G A - - - 1 15  15  .     175     0       0     400 0       0     7     10    60  Z - 0 . D - .     . . . - E
Sunken Colony/  L G - G - E 1 40  32  .     175     0       2     300 0       0     7     10    60  Z - 0 . - - .     . . . - E
Ultralisk/Kais  L G - G - - 1 20  15  4     200     200     1     400 0       3     1     7     60  Z - 0 B - - 1.050 - - - - -
Ultralisk/K+An  L G - G - - 1 20  15  4     200     200     1     400 0       3     1     7     60  Z - 0 B - - 1.556 - - - - -
Zergling/Claws  S G - G - - 1  5   8  0.5   25      0       0     35  0       1     1     5     14  Z - 0 B - - 1.108 - - - - B
Zergling/C+Met  S G - G - - 1  5   8  0.5   25      0       0     35  0       1     1     5     14  Z - 0 B - - 1.615 - - - - -
Devourer/Corro  L A A - - E 1 25 100  2     250     150     2     250 0       2     6     10    80  Z - 0 B - - 1.000 - - - - -
Guardian/Acid_  L A - G - - 1 20  30  2     150     200     2     150 0       2     8     11    80  Z - 0 B - - 0.500 - - - - -
Larva           S G - - - - . 000  .  0     0       0      10     25  0       .     0     4     14  Z - 0 * - - 0     - - - - X
Egg             M G - - - - . 000  .  $     $       $      10     200 0       .     0     4     0   Z - 0 * - - 0     - - - - X
;
run;

proc print; where race='P'; 
var unit_wp throughput armor range min gas pop; run;
