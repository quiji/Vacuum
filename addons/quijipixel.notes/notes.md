Project start date: 9th of January of 2018
"Deadline for Prototype": 9th of April of 2018

naci a las 12 del medio dia del 24 del 1 de 1984

> Resoultion Notes

- Godots default resolution is 1024 x 600
- 320x180 
- 400x225 (Based on Shovel Kinght's res to fit 16:9)
- 480x270 (Based on Hyper Light Drifter's res)
- 640x360 
- 1280x720

> Art!!

Hollow Knight's Graphic Aesthetics Analisys: 
https://www.youtube.com/watch?v=2IfLmc9ZHt8

Cuphead's Graphic Analisys:
https://www.youtube.com/watch?v=o6rpEjyoOHw

> Ideas from other places!!

Check all this design stuff from Hollow Knight!
http://mossbag69.blogspot.com/2018/02/hollow-knight-cut-content.html

> Design

Systemic design!! : https://www.youtube.com/watch?v=SnpAAX9CkIc

> Music Notes

Modes ordered from brightest to darkest:
- Lydian (3 suns)
- Ionian (2 suns)
- Mixolydian (1 sun)
- Dorian (1 sun 1 moon)
- Aeolian (1 moon)
- Frygian (2 moons)
- Locrian (3 moons)

Fuck you Disasterpiece:
https://www.youtube.com/watch?v=JkAl3It8sEQ

Leitmotifs on Hollow Knight: 
https://www.reddit.com/r/HollowKnight/comments/6oj5i5/spoiler_i_love_the_use_of_leitmotifs_in_hollow/
https://www.youtube.com/watch?v=etxXRgyfZDU
https://www.youtube.com/user/ComposerLarkin/videos


> Platform Design

"For platforms with pieces, make the Platform class aware of parent. If the parent is Platform, then it shouldn't use his physics stuff. 
Then, from a variable might be possible to change the behaviour to individual using his own physics engine. Then it will behave as a "piece that separates". "
As platform are now rigid bodies, maybe it's better to use a node2d as parent for the pieces using the pieces as rigids on character mode. 
If a platform separates then just move it up on the tree to the space node and change it's type to rigid. woala!

> Water Platforms!
Water platforms (more like spheres!): Instead of walking around them, the player can swim through them!!!

When these platforms collide with each other, they transform into a bigger platform. !!! (might be impossible)

When they collider with a big nonwater object, they explode! (into tiny drops of water that don't function as platforms).
(or react like normal rigid platforms)

How water behaves:
	https://www.youtube.com/watch?v=EzahpSqGbVg

Water boils and then freezes in the vacuum of space... can't have water platforms... :/ but... games! 

> Rock Platforms (meteorites and gravity center included)

yeah!

> Debris Platforms! (gravity center included)

yeah!

> Ice Platforms!!!

some data on water on space:
https://medium.com/starts-with-a-bang/does-water-freeze-or-boil-in-space-7889856d7f36


> Feature Notes

- Smash jump adding gravity: open paths, move objects
- Camera adjust slowly to player (test)
- Craft stuff: The idea is to gather materials and build gadgets. not by recepie... 
	- Computer AI:
		- Language translator
		- Map handling:
			- Creates maps?
			- Add visual notes to map (for weird stuff to tranverse back)
			- 3D maps?
	- Gun:
		-Nut and bolt gun?
	- Reel gun?
	- Energy absorber?
	- Oxygen generator?
	
> Crafting system
Chip mini game ideas:
	- Fitting pieces in right place... seems like a boring mini-game :(
	- Fitting pieces in right place... at the right time following the flow of energy? (dots moving through wires?)
	- Giving visual clues ON the chips of what they do, and letting them on the chipboard. The dots representing energy will change course, and colors and fullfil an objective

- You get chips (in weird forms), this can be assembled into (or upgraded):
	- Suits computer:
		- Personalities??
		- Translating
		- Map construction
		- Photo recording
		- Access lore from old ships databases
	-??
- You get mechanical pieces. This can be assembled into (or upgraded):
	- Tools to assemble stuff
	- Weapons:
		- the famous sword o knocking metal bar
	- Gadgets:
		- The reel gun
	- Suit:
		- the plant suit (produces oxygen) 
- Ship:
	- Teleport pods can be fixed everywhere on the world on abandoned ships. After fixing one, they will allow for fast travel between places.

> Level Design: Tutorial

Use the tutorial as presentation? when game is run for the first time, go directly to tutorial with logo intros around...??
Must be a tutorial. Make it feel like the character knows what she/he is doing. Very few cues on the technology.

The player starts at the interior of the ship, and moves out. Letting them feel the controls.

> Dungeons??
Maybe there are big abandoned ships who serve as "zelda dungeons" (not with the template stuff, just the idea).
They could be places where the gravity engine cannot be used. This makes it possible to create "dungeons" a la Zelda style, 
with some key stuff to solve in order to solve the whole dungeon (activating air, activating gravity, lights, access logs and find technology etc..)

The puzzles could be based on 0 gravity traversing, or difficult platforming? Who knows!

(For this a normal platform mode has to be added to platforms. it's easy. Just force the gravity function to return Vector2(0, 1))
(Also this allows for gravity shifting puzzles, where shifting the gravity of the whole ship can allow access to certain places and not)
(And!! maybe "ship rotating"?? Where going outside and rotating the ship by smash jump can make the light from outside to enter a window and
light the insides?? I DON?T KNOW!)

The idea that air is limited resource will push the player to activate the oxygen parameter of the ship ASAP!

Bosses? the idea that I'm looking to convey is no combat, just beating (if there are enemies) the situations with courage, guts, creativity and sassyness...

think about it...

Possible dungeons:
- Ancient kingdom (old ship with feudal theme)
- Casino (Active place with living creatures)
- Colloseum? (dunno)
- Human ship (interesting lore around character's situacion. Lot's of stuff she/he didn't know about his/her race and plots and stuff)

> Areas

- Closest to the sun: Withou the apropiate technology you could burn!!
- Dark side of somewhere: just dark.
- Asteroid river: Asteroids!!


> Interpolation stuff:
http://sol.gfxile.net/interpolation/


> Plugins:

The animation plugin could be an importer. We can create an animation file (json file with different extension) and save the animation as tres file. Then allow the editor to load into an animation player??



