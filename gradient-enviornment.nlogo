;; Lateral gene transfer as explanation of rise of eukariots

globals [
  sugar-patches
  O2-patches
  number-of-new-pills

]

patches-own [
  psugar
  max-psugar
  pO2
  max-pO2
]

turtles-own [
  energy
  catabolism ;if [0] of dna = 1 -> 6 fold better
  metabolism ;if [2] of dna = 1 -> fast
  dna
]


breed [pacmen a-pacman]
pacmen-own [
  infected
  infectors ;; list of pills infecting the a-pacman
  O2
  max-O2
]


breed [pills a-pill]
pills-own [
  infecting
  host-pac ;; agent the pill is infecting
]

;;;;;;;;;;;;;;;;;;;;;;;;;;; Main ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-patches
  setup-pills
  setup-pacmen
  set number-of-new-pills 1
  reset-ticks
end

to go
   if not any? turtles [
    stop
  ]
   if (not any? pills)
   [setup-new-pills]
  pills-look-move
  pac-look-move
  pill-eat
  pac-eat
  pac-O2
  regrow-psugar
  regrow-pO2
  pill-reproduce
  pac-reproduce
  ask pacmen
  [if check-pac-death [die]]
  ask pills
  [if check-pill-death [die]]
  tick
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;; main procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; basic idea is pills use higher metabolism for a greater search radius at the expense of more energy expenditure
;; through metabolism
to pills-look-move
  ask pills[
    if check-pill-death [die] ;
    if (infecting = true) [ stop ] ;; if they infect then their metabolism decreases
    set energy energy - metabolism ;; taking away energy
    let search-space set-view ;; more searching with higher metab between ticks
    let best-location 0
    ifelse (item 0 dna = 0)
    [set best-location search-space with [not any? turtles-here] with-max [psugar]] ;; I realize there will always be an agent on myself patch should change !!
    [set best-location search-space with [not any? turtles-here] with-max [min (list psugar pO2)]] ;; they can't metabolize any more sugar than there is O2 available
    if one-of best-location = nobody [ stop ] ;; if there aren't any spots to move then don't move
    move-to one-of best-location ;;random best location


  ]
end

;; same basic idea as pills, but pac looks for pills first and avoids O2 if about to die
to pac-look-move
  ask pacmen[
   let search-space set-view ;; based on metab
   ;if (best-next-pac-patch search-space != nobody) ;; don't know why I get a nobody ??
   let spot best-next-pac-patch search-space  ;;trying to fix the nobody error
   if (spot = nobody) [set spot patch-here]
   move-to spot
   ;;testing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   if (random 10 < 2)[
;   set infected true
;   set infectors fput one-of pills infectors
;   ]
   ;;testing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   let current-pac self
   if (infected) [foreach infectors [if (is-turtle? ?) [ask ? [move-to current-pac]]]] ;; bring-infectors

   set energy energy - metabolism ;; will do O2 with death
   if check-pac-death [die]

  ]
end

to pill-eat
  let appetite 5 ; pills are smaller and eat less
  ask pills [
    ifelse (infecting)
    [ let current-pill self
      let pill-take energy-take-from-host   ;; don't really know how much to make the pills take from the pacs ??
      ifelse (is-turtle? host-pac) ;;check to see it the host is alive
      [
        ask host-pac [set energy energy - pill-take]
        set energy energy + pill-take
      ]
      [ ask current-pill [die]]]

    [  ifelse (item 0 dna = 1)[
        let amount-to-take min (list psugar appetite pO2)
        set energy energy + amount-to-take * catabolism
      set psugar psugar - amount-to-take
      set pO2 max (list (pO2 - amount-to-take) 0)]
    [ let amount-to-take min (list psugar appetite)
      set energy energy + amount-to-take * catabolism
      set psugar psugar - amount-to-take]]
  ]
end

to pac-eat
  let appetite 10
  ask pacmen [
    let potential-pills pills-here with [infecting = false]
    ifelse (any? potential-pills)
    [eat-pill]
    [
      ifelse (item 0 dna = 0)
      [
        set energy energy + min (list psugar appetite) * catabolism
        set psugar psugar - min (list psugar appetite)
      ]
      [
        let amount-to-take min (list psugar appetite pO2)
        set energy energy + amount-to-take * catabolism
        set psugar psugar - amount-to-take
        set pO2 max (list (pO2 - amount-to-take) 0)
      ]
    ]
    ]
end

;; if the infector has O2 metab then the host O2 is 0 but the patch O2 is still set to 0
;; pacs just setting O2 to 0 is not consistent with pO2 being used for catabolims
;; changing to a constant decrease for exposure
to pac-O2
  ask pacmen [
   remove-dead-pills
    ifelse (infected)
    [
      set O2 O2 + pO2 * .5   ;; just treat like a normal pac, but if the infector takes O2 we'll set it to zero
      set pO2 min (list (abs (pO2 - 2)) 0)
      foreach infectors [ if (item 0 dna = 1) [ask ? [ask host-pac [set O2 0]]]]
    ]
    [
      set O2 O2 + pO2 * .5
      set pO2 min (list abs (pO2 - 2) 0)
    ]
  ]
end

;to pac-O2 ;; need to figure out all the O2 situations like O2 taken from red (O2 catab) and not red
;  ask pacmen [
;    if (infected)
;    [foreach if (member? a-pill with [color = red] infectors) ;; this is wrong, but I need a break
;      [set O2 0]]                                      ;; if it has O2 catab, then it uses the O2 doing it here because doing other O2 here
;
;    set O2 O2 + pO2 * .5 ;; only absorb half O2
;    set pO2 0
;  ]
;end

;; pacmen procedure
to eat-pill
  let current-pac self
  let pill-to-eat one-of pills-here with [infecting = false]
  ;if (pill-to-eat = nobody) [stop]
  ifelse (item 1 dna = 1 or item 1 [dna] of pill-to-eat = 0) ;; pac has immune system or pill cannot survive
  [set energy energy +  [energy] of pill-to-eat
    ask pill-to-eat [die]]
  [set infected true                               ;;the phagocytosis (shit going to have to tell the pac to not count the pill when looking
    set infectors fput pill-to-eat infectors
    ask pill-to-eat[
      set infecting true
      set host-pac current-pac]
  ]
end

;;;;;;;;;;;;;;;;;;; constant regrow borrowed from sugarscape
to regrow-psugar
  ask patches [
    set psugar min (list max-psugar (psugar + sugar-regrowth-rate))
  ]
end

to regrow-pO2
  ask patches [
    set pO2 min (list max-pO2 abs (pO2 + .5)) ;; I'm saying O2 comes back slower
  ]
end

;;pill reproduce
to pill-reproduce
  ask pills[
    if (infecting) [stop] ; simplification
    if (energy > energy-needed-repro) ;; 20 for energy needed
    [ hatch-pills 1
      [ set energy energy / 1.8
        move-to one-of neighbors]
    set energy energy / 1.8 ]
  ]
end

;; pac-reproduce
to pac-reproduce
  ask pacmen[
    if (energy < energy-needed-repro) [stop]
    remove-dead-pills
    ifelse (not infected) ;; 20 for energy needed
    [ hatch-pacmen 1
      [ set energy energy / 1.8
        move-to one-of neighbors]
    set energy energy / 1.8 ]
    ;; the else -> infected and ready to reproduce
    [ hatch-pacmen 1
      [
        set energy energy / 2
        move-to one-of neighbors
        let current-pac self ;; so I can get the list of infectors
        set dna recombine current-pac
        set infectors [ ]
        ifelse (item 2 dna = 0) [set metabolism low-metabolism] [set metabolism high-metabolism]
        set infected false
        if (classify self = "dead") [die]
        if (classify self = "super")
        [ ;set breed super-pacmen ;; if it's a new breed, it loses all the vars
          set size 4
          set color 113
          set catabolism low-catab-value * 6 ;; it has a 1

        ]
      ]
    set energy energy / 2
    ]
  ]
end

;; pacmen procedure to remove any dead pills from infectors list
to remove-dead-pills
    if (infected)
    [foreach infectors
      [ if (? = nobody)
        [set infectors remove ? infectors]]]
    if (length infectors = 0)
    [set infected false]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;; main reporters ;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; turtle reporter.  Reports the locations for viewing for best space to move based on metab
;; Could use make a custom neighborhood. Say just two neighbors. procedure from sugarscape
to-report set-view
  let look-here (list(list 0 1) (list 1 0) (list 0 -1) (list -1 0 ) (list 0 0)) ;; von-neuman plus current location
  let possible-canidates patches at-points look-here  ;; just setting the defualt to low metab low motility
  if (item 2 dna = 1) ;; if high metab, then use moore neighbors
    [ set look-here (list(list 0 1) (list 1 0) (list 0 -1) (list -1 0 ) (list 0 0)
        (list 1 1) (list -1 1) (list -1 -1) (list 1 -1) ;; moore plus current location
        (list 2 2) (list 2 -2) (list -2 2) (list -2 -2)) ;; plus higher diag for heterogeneity
      set possible-canidates patches at-points look-here
    ]
    report possible-canidates
end

;; turtle reporter. True if pill should die.
to-report check-pill-death
  let death false
  if (energy < 0)
  [set death true]
  ;;Right now these things shouldn't be possible, but I forgot and they can be if we change reproduction
;  if (item 3 dna = 1) ;; if its accidentaly a pacman by phagocitosis
;  [set death true]
;  if (item 4 dna = 1) ;; if it is not O2 tollerant
;  [set death true]
  if (infecting = true and host-pac = nobody)
  [set death true]
  report death
end

;; turtle reporter. true if pac should die
to-report check-pac-death
  let death false
  if (energy < 0)
  [set death true]
  if (O2 > max-O2) ;;happens when eating
  [set death true]
  ;; are there other ways ??
  report death
end

to-report best-next-pac-patch [search-space]
  ;; check for pills
  ;let pill-spot patch-here ;; initialize
  let best-spot patch-here ;; initialize with patch-here if no pills
  ifelse (any? search-space with [any? pills-here with [infecting = false]]) ;; don't want to count the paracite
  [set best-spot search-space with [any? pills-here with [infecting = false]]]
  [

    ifelse (item 4 dna = 1)
    [
      ifelse (item 0 dna = 1) ;;has O2 tollerance and O2 catabolism
      [ set best-spot search-space with [not any? turtles-here] with-max [min (list psugar pO2)]] ;; could pick better criteria ??
      [ set best-spot search-space with [not any? turtles-here] with-max [psugar]]
    ]
    [
      let relative-O2-danger max (list (100 - (max-O2 - O2) ^ 2) 0 );; 100 - difference^4
      let relative-starvation-danger max (list (100 - energy ^ 2) 0 )
      ifelse (relative-O2-danger + relative-starvation-danger < O2-starv-danger-threshold)
      [ set best-spot search-space with [not any? turtles-here] with-max [psugar]] ;; no danger of dying
      [
        ifelse (relative-O2-danger >= relative-starvation-danger)   ;; attempts to pick the least "painful" spot
        [set best-spot search-space with [not any? turtles-here] with-min [pO2]]
        [set best-spot search-space with [not any? turtles-here] with-max [psugar]]]
    ]
  ]
  ifelse (best-spot = nobody)
  [report patch-here]
  [report one-of best-spot]
end

;; a pacmen reporter.  From the viewpoint of the new offspring
to-report recombine [current-pac]
  ;let swap-rate 5 ;; initially assuming a 5% lateral gene transfer rate
  let dna-new dna
  ask current-pac[
    if (random 100 < swap-rate)
    [
      ;if (any? infectors with [any? turtles] = nobody) [stop] ;; fixing error !!
      let dna-index random 5
      let dna-bit item dna-index [dna] of one-of infectors
      set dna-new replace-item dna-index dna-new dna-bit

    ]
  ]
  report dna-new
end

to-report classify [new-turtle]
  let class "pacman"
  ask new-turtle[
    if breed = pacmen
    [
      if (item 3 dna = 0) [set class "dead"] ;; pacman cannot be non-pagocytic
      if (item 4 dna = 0 and item 0 dna = 1) [set class "dead"]
      if (item 0 dna = 1 and item 3 dna = 1 and item 4 dna = 1)
      [set class "super"]
    ]
  ]
  report class
  ;; could make one for pills too.  Could use to make offspring of pac into pills too
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup procedures ;;;;;;;;;;;;;


to setup-patches
  ask patches
  [
    let sugarhill1 sugar-levels - ( distancexy 12 12 ) * .6
    let sugarhill2 sugar-levels - ( distancexy 37 37 ) * .6

    ifelse sugarhill1 > sugarhill2
      [set max-psugar sugarhill1]
      [set max-psugar sugarhill2]

    if max-psugar < 0
      [set max-psugar 0]
    set psugar max-psugar



    let O2spout1 4 - ( distancexy -12 12 ) * .35
    let O2spout2 4 - ( distancexy -37 37 ) * .35

    ifelse O2spout1 > O2spout2
      [set max-pO2 O2spout1]
      [set max-pO2 O2spout2]

    if max-pO2 < 0
      [set max-pO2 0]
    set pO2 max-pO2
    set sugar-patches patches with [psugar > 0]
    set O2-patches patches with [pO2 > 0]

  ]
  color-sugar-patches
end

to color-O2-patches
  ask O2-patches [
    set pcolor scale-color blue pO2 0 10
  ]
end

to color-sugar-patches
  ask sugar-patches [
    set pcolor scale-color green psugar 0 10
  ]
end

to setup-pills
  create-pills number-of-pills [
    move-to one-of patches with [not any? other turtles-here]
    set energy 10
    set infecting false
    set shape "bug"
    set color pink
    set size 2
    let catab-var 0                     ;;[0] very few pills begin with catabolism with O2 (like 6 fold better)
    let infectious random 2             ;;[1] Some pills are able to survive phagocytosis
    let metab-var random 2             ;;[2] 0 is bad 1 is
    let phagocytositic 0                  ;;[3] pills are not capable of phagocytosis
    let O2-tolerance 1                  ;;[4] pills are naturally O2 tollerent
    set dna (list catab-var infectious metab-var phagocytositic O2-tolerance) ;; set them all with bad catabolism except a few later
    set catabolism low-catab-value ; will initialize one later with better
    ifelse ((item 2 dna) = 0)
    [set metabolism low-metabolism] ;;amounts are purely a guess
    [set metabolism high-metabolism] ;;same as above
    ]
  ;; creating at around 10% with good
  let percent-with-great-catab .10 ; could comment out and make a slider
  repeat round (1 + percent-with-great-catab * number-of-pills) [
    if (any? pills) [ask one-of pills with [(item 0 dna) = 0] [
      set catabolism low-catab-value * 6 ;; don't really know how to pick best catabolism ??
      set color red
    ]]
    ask pills with [color = red][  ;;making a few with O2 type catabolism
    set dna replace-item 0 dna 1
    set host-pac nobody
    ]

  ]
end

to setup-pacmen
  create-pacmen number-of-pacmen [
    move-to one-of patches with [not any? other turtles-here]
    set energy 10
    set infected false
    set shape "face happy"
    set color blue
    set size 3
    let catab-var 0                     ;;[0] no pacmen begin with O2 type catabolism
    let infectability random 2             ;;[1] Some pacmen can kill all pills phagocitized
    let metab-var random 2             ;;[2] 0 is low motility / low metab 1 is high motility / high motab
    let phagocytositic 1                  ;;[3] pacmen cannot be phagocitized
    let O2-tolerance 0                  ;;[4] pacmen do not have O2 tollerance
    set dna (list catab-var infectability metab-var phagocytositic O2-tolerance) ;; set them all with bad catabolism except a few later
    set catabolism low-catab-value ; will initialize one later with better
    ifelse ((item 2 dna) = 0)
    [set metabolism low-metabolism] ;;amounts are purely a guess
    [set metabolism high-metabolism] ;;same as above
    set O2 0
    set max-O2 10
    set infectors []
    ]
end

to setup-new-pills ;;the kind we need for supers
  create-pills number-of-new-pills [
    move-to one-of patches with [not any? other turtles-here]
    set energy 10
    set infecting false
    set shape "bug"
    set color red
    set size 2
    let catab-var 1                     ;;[0] very few pills begin with catabolism with O2 (like 6 fold better)
    let infectious 1 ;random 2             ;;[1] Some pills are able to survive phagocytosis
    let metab-var random 2             ;;[2] 0 is bad 1 is
    let phagocytositic 0                  ;;[3] pills are not capable of phagocytosis
    let O2-tolerance 1                  ;;[4] pills are naturally O2 tollerent
    set dna (list catab-var infectious metab-var phagocytositic O2-tolerance) ;; set them all with bad catabolism except a few later
    set catabolism low-catab-value ; will initialize one later with better
    ifelse ((item 2 dna) = 0)
    [set metabolism low-metabolism] ;;amounts are purely a guess
    [set metabolism high-metabolism] ;;same as above
    ]
  ;; creating at around 10% with good
;  let percent-with-great-catab .10 ; could comment out and make a slider
;  repeat round (1 + percent-with-great-catab * number-of-pills) [
;    if (any? pills) [ask one-of pills with [(item 0 dna) = 0] [
;      set catabolism low-catab-value * 6 ;; don't really know how to pick best catabolism ??
;      set color red
;    ]]
    ask pills with [color = red][  ;;making a few with O2 type catabolism
    set dna replace-item 0 dna 1
    set host-pac nobody
    ]


end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End Setup ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;











@#$#@#$#@
GRAPHICS-WINDOW
239
10
678
470
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
18
29
81
62
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
17
65
133
98
Show O2 levels
color-O2-patches
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
17
101
148
134
Show sugar levels
color-sugar-patches
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
148
189
181
number-of-pills
number-of-pills
0
30
8
1
1
NIL
HORIZONTAL

SLIDER
17
185
189
218
number-of-pacmen
number-of-pacmen
0
30
4
1
1
NIL
HORIZONTAL

BUTTON
86
29
149
62
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
154
28
229
61
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
16
227
188
260
low-catab-value
low-catab-value
0
1
0.3
.1
1
NIL
HORIZONTAL

SLIDER
15
267
187
300
sugar-levels
sugar-levels
0
20
9
1
1
NIL
HORIZONTAL

SLIDER
22
314
194
347
sugar-regrowth-rate
sugar-regrowth-rate
0
3
3
.2
1
NIL
HORIZONTAL

SLIDER
14
354
186
387
energy-needed-repro
energy-needed-repro
0
40
20
1
1
NIL
HORIZONTAL

SLIDER
18
398
215
431
O2-starv-danger-threshold
O2-starv-danger-threshold
0
40
20
1
1
NIL
HORIZONTAL

SLIDER
25
450
202
483
energy-take-from-host
energy-take-from-host
0
3
0
.2
1
NIL
HORIZONTAL

SLIDER
24
490
196
523
swap-rate
swap-rate
0
100
100
1
1
percent
HORIZONTAL

SLIDER
258
500
430
533
high-metabolism
high-metabolism
0
10
1.4
.2
1
NIL
HORIZONTAL

SLIDER
458
509
630
542
low-metabolism
low-metabolism
0
10
1
.2
1
NIL
HORIZONTAL

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

@#$#@#$#@
NetLogo 5.2.1
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
