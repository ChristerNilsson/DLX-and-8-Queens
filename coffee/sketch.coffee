constraints = null
snapshots = null
current = 0
hiliteOption = ''
hiliteItem = ''

chessboard = null
objSnapshots = null
explanation = null
objItems = null
expanded = null

MODE = 0 # 0=compact 1=expanded
range = null 
circle = (x, y, r) -> ellipse x, y, 2*r, 2*r

class Chessboard
	constructor : (@x,@y) ->
		@R = 50

	count : (i,j) -> # calculates list counts for findBestColumn
		j = 7-j
		key = 'abcdefgh'[i] + '12345678'[j]
		key1 = 'C' + 'ABCDEFGH'[i]
		key2 = 'R' + '12345678'[j]
		entries = snapshots[current].entries
		if entries[key1] and entries[key2]
			a = if key in entries[key1] then entries[key1].length else 0
			b = if key in entries[key2] then entries[key2].length else 0
			if a==0 or b==0 then return ''
			min a,b
		else
			''

	draw : ->

		textSize 20
		for i in range 8
			for j in range 8
				fill if (i+j)%2==0 then '#ccc' else 'black'
				rect @x+@R*i, @y+@R*j, @R, @R
				fill 'yellow'
				text @count(i,j), @x+@R*(i+0.5), @y+@R*(j+0.5)

		fill 'black'
		for i in range 8
			text 8-i,@x-@R*0.2,@y+@R*(i+0.5)
			text 'abcdefgh'[i],@x+@R*(i+0.5),@y+8.3*@R

		fill 'green'
		textSize 24
		choices = snapshots[current].choices
		for c,index in choices
			if c=='' then continue
			i = 0.5 + 'abcdefgh'.indexOf c[0]
			j = 8 - 0.5 - '12345678'.indexOf c[1]
			stroke 'black'
			fill if index == choices.length-1 then 'yellow' else 'green'
			circle @x+@R*i,@y+@R*j,0.4*@R
			noStroke()
			fill if index == choices.length-1 then 'green' else 'yellow'
			text c,@x+@R*i,@y+@R*j

		@hiliteItem()

	drawLine : (i1,j1,i2,j2) ->
		line @x+@R*(i1+0.5),@y+@R*(j1+0.5),@x+@R*(i2+0.5),@y+@R*(j2+0.5)

	hiliteItem : ->
		key = hiliteItem
		if key == '' then return
		stroke 255,255,0,128
		strokeWeight 25
		if key[0] in "CR"
			i = 'ABCDEFGH'.indexOf key[1]
			j = '12345678'.indexOf key[1]
			if key[0] == 'C' then @drawLine i,0,i,7
			if key[0] == 'R' then @drawLine 0,7-j,7,7-j
		if key[0] in "AB"
			i = 'ABCDEFGHIJKLMNO'.indexOf key[1]
			if key[0] == 'A'
				if i < 7 then @drawLine 0,7-i,i,7 else @drawLine i-7,0, 7,14-i
			if key[0] == 'B'
				if i < 7 then @drawLine 7,7-i,7-i,7 else @drawLine 0,14-i,14-i,0
		noStroke()
		strokeWeight 1

	mouseMoved : ->
		if @x < mouseX < @x+@R*8 and @y < mouseY < @y+@R*8
			for i in range 8
				for j in range 8
					if @y+@R*(7-j) < mouseY < @y+@R*(7-j+1)
						if @x+@R*i < mouseX < @x+@R*(i+1)
							hiliteOption = 'abcdefgh'[i] + '12345678'[j]

class Expanded
	constructor : (@x,@y) ->

	drawExpanded : (offset, entries, constraints, items) ->
		fill 'black'
		textSize 16
		keys = _.keys entries
		stroke 'black'
		for key,i in keys
			y = 100+15*i

		textAlign CENTER,CENTER
		for key,i in constraints
			x = offset + 25 + 25 * i
			stroke 'black'
			if items[key]
				options = items[key] #.split ' '
				for option in options
					j = keys.indexOf option
					y = 100+15*j
					stroke 128+64
					line x,y-8,x,y+8
					line x-10,y,x+8,y
					noStroke()
					fill if hiliteOption == option then 'white' else 'black'
					text option,x,y+2

	drawLinks : (offset, entries, constraints, items) ->
		fill 'black'
		textSize 12
		keys = _.keys entries
		stroke 'black'

		for key,i in keys
			y = 100+15*i
			line 25,y,width-200,y

		for key,i in constraints
			x = offset + 25 + 25 * i
			stroke 'black'
			line x,100,x,1045

	draw : ->
		snapshot = snapshots[current]
		@drawLinks    0*25,  constraints.entries, constraints.itemNames, snapshot.entries
		@drawExpanded 0*25,  constraints.entries, constraints.itemNames, snapshot.entries

class Explanation 
	constructor : (@x,@y) ->
		@explanations = []
		@explanations.push 'There are 16 primary items, 8 columns and 8 rows\n\nThe matrix is actually 64 options x 46 items\nIt is shown compressed here\nPress Space or click to toggle View Mode\n\nItem CA is chosen\nOption a1 is first\nPress Right Arrow to see option a1 selected'
		@explanations.push 'Yellow texts are mouse aware\nItems CA, R1, AA and BH are hidden\nItem CB is chosen\nOption b3 is selected'
		@explanations.push 'Items CB and R3 are hidden\nShortest item is CC\nOption c5 is selected'
		@explanations.push "Items CC and R5 are hidden\nThe 'best item' is considered to be an item that minimizes the number of remaining choices.\nIf there are several candidates, we choose the leftmost\nShortest item is CF\nOption f4 is selected"
		@explanations.push 'Items CF and R4 are hidden\nShortest item is CH\nOption h7 is selected'
		@explanations.push 'Items CH and R7 are hidden\nR6 is missing => h7 must backtrack\nf4 also backtracks as CF has no options left'
		@explanations.push 'c5 is backtracked and replaced by c6\nd2 is selected'
		@explanations.push 'Items CD and R2 are hidden\ne7 is selected'
		@explanations.push 'Items CE and R7 are hidden\nR8 is empty => e7 is backtracked'
		@explanations.push "d2 is backtracked and replaced by d8"
		@explanations.push "The JSON data structure is available in the browser using Ctrl+Shift+I"
	draw : ->
		textAlign LEFT,TOP
		textSize 14
		fill 'black'
		text @explanations[current],@x,@y
	
class Items
	constructor : (@xp,@yp) ->

	draw : ->
		textSize 14
		textAlign CENTER,CENTER
		snapshot = snapshots[current]	
		@drawOptions 'Dancing Links solving Eight Queens', @xp, @yp, constraints.itemNames, snapshot.entries

	drawOptions : (prompt, x, y, itemNames, entries) ->

		textAlign LEFT,CENTER
		textSize 32
		fill 'black'
		noStroke()
		text prompt, x+15,y

		stroke 'yellow'
		strokeWeight 1
		#line offset+25*0.7,60,offset+w+10,60
		#line offset+25*0.7,60,offset+w+10,60
		noStroke()

		textAlign CENTER,CENTER
		textSize 14
		fill 'yellow'
		for itemName,i in itemNames
			text itemName,x+25+25*i,y+25	

		for key,row of entries # "CA"
			if MODE == 0
				i = itemNames.indexOf key
				options = row
				for option,j in options
					fill if option == hiliteOption then 'white' else 'black'
					text option,x+25+25*i,y+50+25*j

	mouseMoved : ->
		if @yp < mouseY < @yp+250
			snapshot = snapshots[current]
			for key,index in constraints.itemNames 
				if @xp+25*(index+0.5) < mouseX < @xp+25*(index+1.5) then hiliteItem = key

class Snapshots
	constructor : (@x,@y) ->
	draw : ->
		stroke 'black'
		textSize 14
		for snapshot,j in snapshots
			textAlign RIGHT,TOP
			noStroke()
			fill 'black'
			text j,@x-2,2+@y+16*j
			fill if current == j then 'yellow' else 'black'
			rect @x,@y+16*j,20*8,16
			textAlign LEFT,TOP
			fill 'yellow'
			for choice,i in snapshot.choices
				fill if current != j then 'yellow' else 'green'
				text choice,3+@x+20*i,2+@y+16*j

	mousePressed : ->
		index = Math.floor (mouseY - @y)/16
		if 0 <= index < 65 then current = index 

preload = ->
	fetch "8queens.json"
		.then (response) => response.json() 
		.then (json) => 
			{constraints,snapshots} = json
			constraints.itemNames = constraints.itemNames.split ' '
			for snapshot in snapshots
				snapshot.choices = if snapshot.choices == '' then  [] else snapshot.choices.split ' '
			console.log json


setup = ->
	createCanvas 1350,1080
	range = _.range
	chessboard = new Chessboard 100, 400
	objSnapshots = new Snapshots 1180, 10
	explanation = new Explanation 550,400
	objItems = new Items 0*25, 20
	expanded = new Expanded 20,20

draw = ->
	background 128+64
	if not constraints then return
	objItems.draw()
	if MODE == 0 then chessboard.draw()
	if MODE == 0 then explanation.draw()
	objSnapshots.draw()
	if MODE == 1 then expanded.draw()

keyPressed = ->
	if key==' '
		MODE = 1 - MODE
		return
	if key in ['ArrowLeft','ArrowUp'] then current--
	if key in ['ArrowRight','ArrowDown'] then current++
	if current < 0 then current = 0
	if current >= snapshots.length then current = snapshots.length-1

mousePressed = ->
	if mouseX > width-200 + 30
		objSnapshots.mousePressed()
	else
		MODE = 1 - MODE

mouseMoved = ->
	hiliteItem = '' # CA
	hiliteOption = '' # a1
	objItems.mouseMoved()
	if MODE == 0 then chessboard.mouseMoved()
