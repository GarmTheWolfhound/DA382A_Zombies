; <Task_Template for the Tournaments>
; <fill this template with your information by replacing all elements between < and > with the right information>
;
;< Describe the behavior of the agents:
; HUMANS:
; ZOMBIES:
; OTHER:
; >
;
; Date: <2019-03-29>


; ************* GLOBAL VARIABLES *****************
globals [age-counter timeofday]

; *****************************


; ************ BREEDS OF TURTLES *****************
breed [ zombies zombie ]  ;
breed [ humans human ]
breed [ corpses corpse]


; ****************************

; ************* AGENT-SPECIFIC VARIABLES *********
turtles-own []
zombies-own [energy target speedcoefficient eatTimer myGroup inDanger dangerTimer target-X target-Y target-ID]
humans-own [latest-birth age parents nrOfChildren HState my-group confidence hunting target]
corpses-own[flesh]

; ***************************


; ******************* SETUP PART *****************
; initiates the agents
to setup
  clear-all
  setup-humans
  setup-zombies
  ; set the bakground to yellow
  ask patches [set pcolor yellow]
  reset-ticks
end
; **************************

; ******************* TO GO/ STARTING PART ********
; cyclic execution of agents
to go
  live-humans
  live-zombies
  tick

  ;common functions and stop-expressions
  year-counter
  set-night-day
  if count humans > 2000 [stop]
  if count zombies > 2000 [stop]
  if not any? humans [stop]
end
; **************************

; ******************* COMMON FUNCTIONS PART ********
;Functions shared between zombies and humans

to set-night-day  ;JOD & MNM
  let counter ticks mod ticks-per-day-night
  if (counter < floor((ticks-per-day-night / 2))) [
    set timeOfDay "day"
  ]
  if (counter > floor((ticks-per-day-night / 2))+ 1) [
    set timeOfDay "night"
  ]
  visual-day-night-m
end

to visual-day-night-m ;PNO
  ifelse (visual-day-night = true) [
    let counter ticks mod ticks-per-day-night
    let fractionofday counter / (ticks-per-day-night - 1)
    ask patches with [shade-of? pcolor yellow] [
      let absoluteposition (( max-pxcor - pxcor) / ( max-pxcor - min-pxcor))

      if (0 < fractionofday and fractionofday < 0.25) [; Sunrise
        if (absoluteposition < fractionofday * 5) [
          set pcolor (pcolor + (4 / (ticks-per-day-night / 4)))
        ]
      ]
      if (0.25 < fractionofday and fractionofday < 0.5) [; Day
        set pcolor ((pcolor + 45) / 2)
      ]
      if (0.50 < fractionofday and fractionofday < 0.75) [; Sunset
        if (absoluteposition < (fractionofday - 0.5) * 5) [
          set pcolor (pcolor - (4 / (ticks-per-day-night / 4)))
        ]
      ]
      if (0.75 < fractionofday and fractionofday < 1) [; Night
        set pcolor ((pcolor + 41) / 2)
      ]
    ]
  ] [
    ask patches with [shade-of? pcolor yellow] [
      set pcolor gray]
  ]

  if patch-anti-aliasing > 0 [
    repeat patch-anti-aliasing [patch-anti-aliasing-m]
  ]
end

to patch-anti-aliasing-m ;PNO
  let xcoordinates max-pxcor + abs(min-pxcor)
  let aliasing-counter min-pxcor + 1
  repeat (xcoordinates - 2) [
    ask patches with [pxcor = aliasing-counter] [
      if(shade-of? yellow pcolor) [
        let temppcolor (((sum [pcolor] of (neighbors with [shade-of? pcolor yellow])) + pcolor) / 9)
        if (shade-of? temppcolor yellow) [
          set pcolor temppcolor
        ]
      ]
    ]
    set aliasing-counter (aliasing-counter + 1)
  ]
  set aliasing-counter 0
end

to year-counter ;MNM & AKB
  set age-counter (age-counter + 1)
  if (age-counter = ticks-per-year) [
    set age-counter 0
    ask humans [
      set age (age + 1)
      if age >= (maximum-age + (random 5) - (random 5)) [ die ]
    ]
    ask humans with [size < 2] [set size (size + 0.1) ]
  ]
end


; **************************

; ****************** HUMAN AGENTS PART **************
;
; --setup human agents --------------------------------
to setup-humans ;MNM & AKB & AJA
  set age-counter 0
  create-humans (initial-number-humans / 2)
  [
    set shape "person"
    set color blue
    set age random setup-age
    set HState "Wander"
    set parents [-1 -1]
    set confidence 50
    set my-group (list who -1 -1 -1)
    ;set size 2  ; easier to see
    setxy random-xcor random-ycor
    set hunting false
  ]
  create-humans (initial-number-humans / 2)
  [
    set hunting false
    set shape "person"
    set color pink
    set age random setup-age
    set HState "Wander"
    set latest-birth 0
    set nrOfChildren 0
    set parents [-1 -1]
    set confidence 50
    set my-group (list who -1 -1 -1)
    ;set size 2  ; easier to see
    setxy random-xcor random-ycor
  ]
  ask humans with [age < 2 * reproduction-age][set size 1]
  ask humans with [age >= 2 * reproduction-age and age < 5 * reproduction-age][set size 1.5]
  ask humans with [age >= 5 * reproduction-age ][set size 2]
end
; end setup human agents ----------------------------

; --human agents main function ----------------------
to live-humans ; AKB
  ask humans [ifelse show-age [set label age] [set label ""]]
  ;move-humans
  change-state
  reproduce-humans
  ;  hunt
end
; end human agents main function --------------------

; --human agents procedures/reporters ----------------
; <3-digit initial of programmer for each procedure>
to reproduce-humans ;MNM & AKB
  if Tactics = "Step3" [
    ask humans with [color = pink and age >= reproduction-age and age > latest-birth] [
      if any? humans-here with [color = blue] [
        set latest-birth age
        hatch random 3 [
          ifelse random 2 = 0 [set color pink] [set color blue]
          set age 0
          set size 1
          right random 360
          forward 1
        ]
      ]
    ]
  ]
  if Tactics = "Step4" [
    ;check family and then set hatched parents to current
    ask humans with [color = pink and age >= reproduction-age and age > latest-birth and nrOfChildren < maximumNrOfChildren] [
      let man one-of humans-here with [color = blue and age >= reproduction-age]
      if man != nobody [
        let manP 0
        let manID 0
        ask man [
          set manP parents
          set manID who
        ]
        let womanID who
        let femaleP 0
        set femaleP parents
        if(family(manP)(femaleP)(manID)(womanID) != 0) [
          hatch random 3 [
            set my-group (list who -1 -1 -1)
            set hunting false
            ifelse random 2 = 0 [set color pink] [set color blue]
            set age 0
            set size 1
            set parents list (womanID) (manID)
            right random 360
            forward 1
          ]
          set nrOfChildren (nrOfChildren + 1)
        ]
      ]
    ]
  ]

end

to-report family[maleP femaleP maleID femaleID] ;MNM & AKB
                                                ;  show "MALE"
                                                ;  show maleP
                                                ;  show "FEMALE"
                                                ;  show femaleP
  if (item 0 maleP = -1 and item 1 maleP = -1) or (item 0 femaleP = -1 and item 1 femaleP = -1) [
    ;show "initial humans, breed"
    report 1 ;Initial humans, allowed to breed
  ]
  ifelse (item 0 maleP = item 0 femaleP) or (item 1 maleP = item 1 femaleP) or (femaleID = item 0 maleP) or (maleID = item 1 femaleP)[
    ;show "same parents, don't breed"
    report 0 ;same parents don't breed
  ] [
    ;show "diffrent parents, allowed to breed"
    report 1 ;diffrent parents, allowed to breed
  ]
end

to-report zombInArea[person] ; Return whether there is a zombie, human or both nearby. DAB & MNM
  let zomb min-one-of zombies in-radius vision-radius [distance human person]
  if zomb != nobody [
    report zomb
  ]

  report nobody
end

to-report zombsInArea[person] ; Return whether there is a zombies, human or both nearby. DAB & MNM
  let zomb nobody
  ask human person [
    set zomb zombies in-radius vision-radius
  ]
  if zomb != nobody [
    report zomb
  ]

  report nobody
end

to-report humanInArea[person] ; Return whether there is a zombie, human or both nearby. DAB & MNM
  let otherPerson min-one-of other humans in-radius vision-radius [distance human person]
  ifelse otherPerson != NOBODY [
    if [distance human person] of otherPerson > 3 [
      report otherPerson
    ]
  ] [report nobody]
  report nobody
end


to move-humans ;MNM
  if Tactics = "Step2" [
    ask humans [
      let zomb min-one-of zombies in-radius vision-radius [distance myself]
      ifelse zomb != nobody [
        ;run away from zombie
        set heading towards zomb
        ;right 180
        right 160 + random 20
        forward 1
      ] [
        right random 30
        left random 30
        forward 1
      ]
    ]

    ;Show age
    ;ifelse show-age
    ;[ set label age ]
    ;[ set label "" ]

  ]
  if Tactics = "Step3" [
    ask humans [
      let zomb min-one-of zombies in-radius vision-radius [distance myself]
      ifelse zomb != nobody [
        ;run away from zombie
        set heading towards zomb
        ;right 180
        right 160 + random 20
        forward 1
      ] [
        let person min-one-of other humans in-radius vision-radius [distance myself]
        ifelse person != nobody [
          if [distance myself] of person > 3 [
            set heading towards person
            right random 5
            left random 5
            forward 1
          ]
        ] [
          right random 30
          left random 30
          forward 1
        ]
      ]
    ]
  ]
end

to change-state ; MNM & DAB & SCN

  ask humans [
    decision
    ifelse HState = "Flee"[
      Flee(ZombInArea(who))
    ][
      ifelse HState = "Hunt"[
        hunt(target)
      ][
        ifelse HState = "Group"[
          Group
        ][
          ifelse Hstate = "Breed"[
            go-to-nearby-group
          ][]
        ]
      ]
    ]
  ]



end
to updateConfidence ;MNM & DAB
  let zombsNearby zombsInArea(who)
  set zombsNearby count zombsNearby
  let humsNearby count humans in-radius 2
  let humsInGroup 4 - groupSpotAvailiable(my-group)
  ;show (word "zombs:" zombsNearby " humans:" humsInGroup)
  let ratio 0
  ifelse(zombsNearby != 0) [
    ;ratio based
    ;set ratio humsInGroup / zombsNearby
    set ratio humsNearby / zombsNearby
    ifelse(ratio >= 3) [
      ;hunt
      set confidence 100
      ;show (word "confidence " 100)
    ][
      ;flee
      set confidence 0
      ;show (word "confidence " 0)
    ]
  ][
    ;0 zombies nearby
    set confidence (humsInGroup * 15)
    ;show (word "confidence " (humsInGroup * 25))
  ]
end
to Group ; MNM & DAB
  group-me
end
to go-to-nearby-group
  if (groupSpotAvailiable(my-group) > 0) [
    let my-g my-group
    let notMyGroup humans with[my-group != my-G]
    let humansNear one-of other notMyGroup in-radius vision-radius
    let humanNear-EmptySpots 0
    let humanNear-Group  0
    if humansNear != nobody[
      ask humansNear[
        set humanNear-EmptySpots groupSpotAvailiable(my-group)
        set humanNear-Group my-group
      ]
      if (4 - groupSpotAvailiable(my-group)) + (4 - humanNear-EmptySpots) <= 4 [
        mergeGroups(my-group)(humanNear-Group)
      ]
    ]
  ]
  let person item 0 my-group
  if (who = person and Hstate != "Flee")[
    let my-g my-group
    let facing one-of humans with[my-group != my-g]
    if facing != nobody[
      face facing
    ]
    rt random 90
    lt random 90
    fd 1
  ]
end
;SCN & BJZ
to change-group-state[state]
  foreach my-group[
    person -> if(turtle person != nobody)[
      ask turtle person [set HState state]
    ]
  ]
end

to Flee [zomb] ; MNM & DAB
               ;run away from zombie
  if zomb != nobody[
    set heading towards zomb
  ]
  ;right 180
  right 160 + random 20
  forward 1
end

to hunt[hunting-target] ; AKB
  if hunting-target != nobody [
    face hunting-target
    forward 1
    release-zombie
  ]
end

;SCN & FTO
to group-me
  if (groupSpotAvailiable(my-group) > 0) [
    let my-g my-group
    let notMyGroup humans with[my-group != my-G]
    let humansNear one-of other notMyGroup in-radius (2 * vision-radius)
    let humanNear-EmptySpots 0
    let humanNear-Group  0
    if humansNear != nobody[
      ask humansNear[
        set humanNear-EmptySpots groupSpotAvailiable(my-group)
        set humanNear-Group my-group
      ]
      if (4 - groupSpotAvailiable(my-group)) + (4 - humanNear-EmptySpots) <= 4 [
        mergeGroups(my-group)(humanNear-Group)
      ]
    ]
  ]
  let person item 0 my-group
  if (who = person and Hstate != "Flee")[
    rt random 90
    lt random 90
    fd 1
  ]
end

;SCN & BJZ
to kill-me
  if item 0 my-group = who[
    set my-group replace-item 0 my-group item 1 my-group
    set my-group replace-item 1 my-group item 2 my-group
    set my-group replace-item 2 my-group item 3 my-group
    set my-group replace-item 3 my-group -1
  ]
  if item 1 my-group = who[
    set my-group replace-item 1 my-group item 2 my-group
    set my-group replace-item 2 my-group item 3 my-group
    set my-group replace-item 3 my-group -1
  ]
  if item 2 my-group = who[
    set my-group replace-item 2 my-group item 3 my-group
    set my-group replace-item 3 my-group -1
  ]
  if item 3 my-group = who[
    set my-group replace-item 3 my-group -1
  ]
  let my-g my-group
  foreach my-group[ n ->
    if n != -1[
      if( turtle n != nobody)[
        ask turtle n[

          set my-group my-g
        ]
      ]
    ]
  ]
  die
end
;SCN & BJZ
to mergeGroups[group-List1 group-List2]
  let newList (list -1 -1 -1 -1)
  let newListIndex  0
  let itterator 3 - groupSpotAvailiable(group-List1)
  while [itterator >= 0][
    set newList replace-item newListIndex newList item itterator group-List1
    set itterator itterator - 1
    set newListIndex newListIndex + 1
  ]
  set itterator 3 - groupSpotAvailiable(group-List2)
  while [itterator >= 0][
    set newList replace-item newListIndex newList item itterator group-List2
    set itterator itterator - 1
    set newListIndex newListIndex + 1
  ]
  ;let groupColor random 255
  foreach newlist[ n ->
    if n != -1[
      if( turtle n != nobody)[
        ask turtle n[
          set my-group newlist
          ;set color groupColor
        ]
      ]
    ]
  ]
  ;show (word newList " successfull group")
end
;SCN & BJZ
to-report groupSpotAvailiable[group-list]
  let emptySpots 0
  if item 0 group-list = -1[
    set emptySpots emptySpots + 1
  ]
  if item 1 group-list = -1[
    set emptySpots emptySpots + 1
  ]
  if item 2 group-list = -1[
    set emptySpots emptySpots + 1
  ]
  if item 3 group-list = -1[
    set emptySpots emptySpots + 1
  ]
  report emptySpots
end

;SCN & BJZ
;; Group the turtles in the patch
to decision
  let person item 0 my-group
  ifelse (who = person)[
    ;Leader choice and movement
    if(turtle person != nobody)[
      change-group-state("Group")
      Leader-state
    ]
  ][
    if(turtle person != nobody)[
      face turtle person
      fd 1
    ]
  ]
end
;SCN & BJZ
to Leader-state
  let f 0
  let h 0
  let g 0
  let b 0
  let hunter 0
  foreach my-group [
    person -> if turtle person != nobody[
      ask turtle person [
        let choice player-state
        ifelse choice = "Flee"[
          set f f + 1
          ][ ifelse choice = "Hunt"[
            set h h + 1
            set hunter who
            ][ ifelse choice = "Group"[
              set g g + 1
              ][ifelse choice = "Breed"[
                set b b + 1
              ][;more states here
              ]
            ]
          ]
        ]
      ]
    ]
  ]
  ifelse (f >= 2 and h = 0 and not hunting) [
    change-group-state("Flee")
    if (show-hums-coms) [
      show (word my-group " want to flee")
      set pcolor red
    ]
    ][ ifelse (h > 1 and f < 2)[
      change-group-state("Hunt")
      set-hunting-target(zombInArea(hunter))
      if (show-hums-coms) [
        show(word my-group " wants to hunt zombie " target)
        show (word "zombies near " target " " ([count zombies in-radius 2] of target ))
        set pcolor blue
      ]
      ][ ifelse( b >= 1 and not(g > 2))[
        if (show-hums-coms) [
          show (word my-group " want to breed")
          set pcolor yellow
        ]
        change-group-state("Breed")
        end-hunt
        ][ ifelse g >= 2[
          change-group-state("Group")
          end-hunt
          if (show-hums-coms) [
            show (word my-group " want to group")
            set pcolor green
          ]
        ][;more states here
        ]
      ]
    ]
  ]
end
;SCN & BJZ
to end-hunt
  foreach my-group [
    person -> if (turtle person != nobody)[
      ask turtle person [
        set hunting false
      ]
    ]
  ]
end
;SCN & BJZ
to set-hunting-target [hunting-target]
  foreach my-group [
    person -> if (turtle person != nobody)[
      ask turtle person [
        set target hunting-target
        set hunting true
      ]
    ]
  ]
end
;SCN & BJZ
to-report player-state
  updateConfidence
  let target-nullpointer false
  ifelse target = 0 [
    set target-nullpointer false
  ][
    set target-nullpointer (([count zombies in-radius 2] of target ) < 2 )
  ]
  ifelse( confidence = 100 and (target-nullpointer))[
    report "Hunt"
    ][ ifelse confidence = 0[
      report "Flee"
      ][ ifelse (color = pink and nrOfChildren < maximumNrOfChildren)[
        ;this is placeholder state extension that can be built upon
        report "Breed"
        ][ ifelse true[
          report "Group"
        ][
          ;more states
        ]
      ]
    ]
  ]

end
;to hunt  ;DHL
;  ask humans [
;    if count zombies in-radius vision-radius < 2 [
;  let zomb min-one-of zombies in-radius vision-radius [distance myself]
;      if zomb != nobody [
;    if count humans in-radius vision-radius >= 3 [
;      set heading towards zomb
;      forward 1
;      if [ distance myself ] of zomb < 3[
;        ask zomb [die]
;      ]
;    ]
;  ]
;    ]
;  ]
;end

; end human agents procedures/reporters -------------

; **************************

; #################################################################################################################
; ************ ZOMBIE AGENTS PART ********
;
; --setup zombie agents --------------------------------
to setup-zombies
  create-zombies initial-number-zombies [
    set shape "zombie"
    set color red
    set size 3  ; easier to see
    set energy energy-start-zombies
    set speedcoefficient (zombie-speed-max - zombie-speed-min) / ln(101)
    setxy random-xcor random-ycor
    ;Används för jakt grupper
    set dangerTimer maxDangerTimer ;Ser till att ingen grupp bildas vid start
  ]
end

;; turtle 1 creates links with all other turtles
;; the link between the turtle and itself is ignored

; end setup zombie agents ----------------------------

;JOD
to move-zombies[State]
  ;State Step2 is used for first test. Zombies move in a random path with a 90
  ;rotation radius, 45 right 45 left. Speed is determined by owned energy.
  if State = "Step2" [
    ask zombies [
      if energy > 0 [
        right random 45
        left random 45
        forward energy / 100
        set energy energy - 1
      ]
      if energy < 30 [
        right random 45
        left random 45
        forward 0.6
      ]
      show-energy
    ]
    eat-human
  ]

  ;State Step3 is used for second test. Zombies follows a human that is in its visual radius defined by a slider in the UI.
  ;While it sees the target it faces it and hunts it othervise it looks for a new target to hunt while moving in a random pattern to "trick" the humans.
  ;Speed is determined by energy where min speed is defined as 0.5 steps forward and max is 1.
  if State = "Step4"[
    ask zombies [
      set target min-one-of humans in-radius vision-radius [distance myself]
      if(target != nobody and inDanger != 1) [
        face target
      ]
      if (target = nobody) [
        let cor min-one-of corpses in-radius vision-radius [distance myself]
        ifelse (cor != nobody and (energy + (zombies-energy-gain / 4)) < 90) [
          face cor
          forward zombie-speed-min
        ][
          right random 45
          left random 45
        ]
        forward zombie-speed-min

      ]
      show-energy
      alert
      release-zombie
      eat-human
      set-speed
    ]
  ]

end

;JOD
to show-energy
  ifelse show-energy?
      [
        carefully[set label energy][]
        carefully[set label flesh][]
  ]
  [ set label "" ]
end

; OEA
; CVLA
; AAR
; JOD
; PNO
to alert
  let hum count humans in-radius vision-radius
  let zomVisionRadius count zombies in-radius vision-radius
  let zom count zombies in-radius 1

  if(((hum / zom) < 3) and dangerTimer >= maxDangerTimer) [
    set inDanger 0
  ]

  if(((hum / zom) >= 3)) [
    set inDanger 1
    set dangerTimer 0
    ;Sparar koordinat för närmaste människa
    if(target != nobody) [
      set target-X [xcor] of target
      set target-Y [ycor] of target
    ]

    let zomToHelp self
    let helpingZombie min-one-of other zombies in-radius vision-radius [distance myself]
    ;Alternativ 1, om det finns zombies att hjälpa fråga dem om hjälp, jagar den ingen hjälper den direkt, har den ett target kollar den distansen samt om din fart räcker till för att fortsätta jaga
    if(((hum / zomVisionRadius) < 3)) [ ; går att jaga människor
                                        ;Den här koden låter oss inte hitta ett annat target om det behövs
      if(helpingZombie != nobody)[
        face helpingZombie
        ask helpingZombie [
          ifelse(target != 0 and target != nobody)[
            if((([distance target] of self) < ([distance zomToHelp] of self)))[
              if(target != nobody)[
                face target
              ]
              if Show-Zombie-comms [set pcolor black]
            ]
          ][
            if( != nobody) [
              face [target] of zomToHelp
              if Show-Zombie-comms [set pcolor orange]
            ]
          ]
        ]
      ]
    ]

    if(((hum / zomVisionRadius) >= 3))[
      if(zomVisionRadius >= 2) [ ;Finns inte tillräckligt med zombies för att hjälpa
        face helpingZombie
        if Show-Zombie-comms [set pcolor brown]
      ]

      if(zomVisionRadius = 1) [ ;Finns inte någon zombie som kan hjälpa
        set heading heading - 180
        if Show-Zombie-comms [set pcolor green]
      ]
    ]
  ]

  if((dangerTimer > 0) and (dangerTimer <= maxDangerTimer))[ ;låter Zombies jaga i grupp
                                                             ; if Show-Zombie-comms [set pcolor cyan - 2]
    if(count humans in-radius vision-radius = 0)[
      if Show-Zombie-comms [set pcolor cyan - 2];ljusa
      facexy target-X target-Y
      ask other zombies in-radius vision-radius[
        if(target = nobody) [
          face myself
          if Show-Zombie-comms [set pcolor cyan + 2];mörka
        ]
      ]
    ]
    if(target = nobody and ([xcor] of self = target-X and [ycor] of self = target-Y))[;Bryter upp gruppen om mål patch nås och det inte finns någon människa
      set dangerTimer maxDangerTimer
    ]
  ]
end

;JOD
; JSN
to release-zombie
  let hum count humans in-radius 2
  let zom count zombies in-radius 2
  if(zom != 0)[
    if(((hum / zom) >= 3)) [
      ask zombies-here [die]
    ]
  ]
end

;JOD
to set-speed
  let speed speedcoefficient * ln(energy + 1) + zombie-speed-min
  let cor min-one-of corpses in-radius 2 [distance myself]

  if (cor != nobody) [
    eat-corpse
  ]

  ifelse(inDanger = 1 and target != nobody and eatTimer = 0) [
    let fleeCoefficient (-(1 / 6) * ([distance min-one-of humans in-radius vision-radius[distance myself]] of self) + (4 / 3))
    set fleeCoefficient min list 1 fleeCoefficient
    set energy energy - (fleeCoefficient / zombie-speed-max)
    set energy max list 0 energy
    forward fleeCoefficient * speed
  ] [
    forward zombie-speed-min
  ]



  ifelse(target != nobody and inDanger = 0) [
    if(eatTimer = 0) [
      if energy > 100 [
        forward zombie-speed-max
        set energy energy - (speed / zombie-speed-max)
        if Show-Zombie-comms [set pcolor black];mörka
      ]

      if energy <= 100 and energy >= 0 [
        forward speed
        set energy energy - (speed / zombie-speed-max)
        set energy max list 0 energy
      ]
    ]
  ][
    forward zombie-speed-min
  ]
end

;JOD
;JSN
to eat-human
  ask zombies [
    let hum one-of humans-here
    ask zombies-here [
      if(hum != nobody)[
        hatch-corpses 1[
          ask hum [kill-me]
          set size 3
          set flesh zombies-energy-gain
          ;show flesh
        ]
      ]
    ]
  ]
end
; funktion för att kunna äta en corp(lik) med energi som äts upp på fyra tick.
; PNO,SÄR,NOA
to eat-corpse
  ask zombies [
    if( (energy + (zombies-energy-gain / 4)) < 90 or (energy = min ([energy] of zombies in-radius vision-radius))) [  ; om zombies har en energinivå under 90 kan den äta
      let cor one-of corpses in-radius 1

      if(cor != nobody)[
        ask cor [
          if (flesh > (zombies-energy-gain / 4)) [ ; energin i corp mindre än zombiesenergi, ger den energin från corps som kan ätas fyra gånger
            set flesh (flesh - (zombies-energy-gain / 4))
          ]
          if (flesh <= (zombies-energy-gain / 4)) [
            hatch-zombies 1[
              ask cor [die]
              set size 3
              set shape "zombie"
              set energy energy-start-zombies
            ]
          ]
        ]
        set energy (energy + zombies-energy-gain / 4)
        set energy min list 100 energy
      ]
    ]
  ]
end

; --zombie agents main function ----------------------
to live-zombies
  ask zombies[
    set dangerTimer dangerTimer + 1]
  move-zombies(Tactics)

  ask corpses[show-energy]

  ask zombies[carefully[set energy floor( energy * 10 ) / 10][]]
end
; end zombie agents main function -------------------
; end setup zombie agents ----------------------------
; end zombie agents procedures/reporters -------------
; #################################################################################################################
; Programmers:
; |---------------------------HUMANS-------------------
; |-------|--------------------------------------------
; |3-digit|  Name
; |-------|--------------------------------------------
; | <MNM> | Marcus Nordström
; | <AKB> | Anna Klingberg Brondin
; | <AJA> | Aziz Jashari
; | <DHL> | Daniel Lone
; | <DAB> | Daniel Abella
; | <WAS> | Waleed Abo-Sharkh
; | <SCN> | Sebastian Carlsson
; | <BJZ> | Benjamin Zakrisson
; | <FTO> | Fong To
; |----------------------------------------------------
; -----------------------------------------------------

; |---------------------------ZOMBIES-------------------
; |-------|--------------------------------------------
; |3-digit|  Name
; |-------|--------------------------------------------
; |<JOD>  | Jake O´Donnell
; |<SÄR>  | Julian Wijkström
; |<OEA>  | Oskar Erik Adolfsson
; |<CVLA> | Chippen Vlahija
; |<AAR   | Ahmed Abdulkader
; |----------------------------------------------------

; #################################################################################################################
@#$#@#$#@
GRAPHICS-WINDOW
214
10
1076
537
-1
-1
14.0
1
10
1
1
1
0
1
1
1
-30
30
-18
18
1
1
1
ticks
30.0

SLIDER
1113
27
1285
60
setup-age
setup-age
0
100
55.0
1
1
NIL
HORIZONTAL

SLIDER
17
250
189
283
ticks-per-year
ticks-per-year
0
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
1113
181
1285
214
reproduction-age
reproduction-age
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
1115
64
1287
97
maximum-age
maximum-age
0
100
83.0
1
1
NIL
HORIZONTAL

SLIDER
18
212
190
245
vision-radius
vision-radius
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
18
87
190
120
initial-number-humans
initial-number-humans
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
19
126
191
159
initial-number-zombies
initial-number-zombies
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
1309
66
1481
99
zombies-energy-gain
zombies-energy-gain
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1307
28
1479
61
energy-start-zombies
energy-start-zombies
0
200
100.0
1
1
NIL
HORIZONTAL

SWITCH
1115
103
1226
136
Show-age
Show-age
0
1
-1000

CHOOSER
18
163
156
208
Tactics
Tactics
"Step2" "Step3" "Step4"
2

SWITCH
1308
101
1443
134
Show-energy?
Show-energy?
0
1
-1000

PLOT
1111
355
1479
568
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Zombies" 1.0 0 -13840069 true "" "plot count zombies"
"Women" 1.0 0 -2064490 true "" "plot count humans with [color = pink]"
"Men" 1.0 0 -14070903 true "" "plot count humans with [color = blue]"
"pen-3" 1.0 0 -7500403 true "" "plot count humans"

BUTTON
19
50
82
83
NIL
setup
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
89
50
152
83
NIL
go
T
1
T
OBSERVER
NIL
2
NIL
NIL
0

SLIDER
1113
141
1285
174
maximumNrOfChildren
maximumNrOfChildren
0
15
11.0
1
1
NIL
HORIZONTAL

SLIDER
1307
142
1479
175
zombie-speed-max
zombie-speed-max
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
1305
183
1477
216
zombie-speed-min
zombie-speed-min
0
1
0.4
0.01
1
NIL
HORIZONTAL

TEXTBOX
22
32
172
50
Commons
11
0.0
1

SLIDER
18
289
190
322
ticks-per-day-night
ticks-per-day-night
0
100
60.0
1
1
NIL
HORIZONTAL

TEXTBOX
1307
10
1457
28
Zombies\n
11
0.0
1

TEXTBOX
1113
10
1263
28
Humans\n
11
0.0
1

BUTTON
89
13
164
46
go once
go
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

SLIDER
1307
222
1479
255
eatingTime
eatingTime
0
10
10.0
1
1
NIL
HORIZONTAL

SWITCH
1113
219
1264
252
Show-hums-coms
Show-hums-coms
1
1
-1000

TEXTBOX
1118
259
1195
315
Red    flee\nBlue   hunt\nYellow breed\nGreen  group
11
0.0
1

SLIDER
18
330
190
363
patch-anti-aliasing
patch-anti-aliasing
0
16
8.0
1
1
NIL
HORIZONTAL

SWITCH
49
393
193
426
visual-day-night
visual-day-night
0
1
-1000

SLIDER
1307
262
1479
295
maxDangerTimer
maxDangerTimer
1
20
1.0
1
1
NIL
HORIZONTAL

SWITCH
1308
308
1479
341
Show-Zombie-comms
Show-Zombie-comms
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

zombie
false
3
Circle -10899396 false false 120 45 60
Line -7500403 false 150 105 150 210
Line -7500403 false 150 210 105 255
Line -7500403 false 150 210 195 255
Line -7500403 false 150 135 105 135
Line -7500403 false 150 135 195 180
Rectangle -7500403 true false 135 165 150 195
Circle -955883 true false 129 69 42
Rectangle -10899396 true false 150 90 150 90
Circle -10899396 true false 129 54 42
Polygon -955883 false false 135 195 120 210 180 225 150 195 135 150 150 135 120 135 120 135 165 120 165 180 195 180 120 225 135 240 150 225 195 255
Rectangle -14835848 true false 100 129 144 143
Rectangle -14835848 true false 102 230 147 248
Rectangle -14835848 true false 158 200 181 231
Polygon -1184463 true false 152 140 155 172 158 201 147 231 102 253 133 212 150 201
Polygon -1184463 true false 157 125 197 174 188 182 154 138 158 124
Polygon -1184463 true false 154 226 195 264 189 270 206 274 220 248 196 247 164 216 153 220 153 227
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
