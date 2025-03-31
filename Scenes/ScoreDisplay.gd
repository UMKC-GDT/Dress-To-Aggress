extends Label

var items_wearing : Array
var style_points_list : Array
var style_mult_list : Array
var style_points : int
var style_mult : float
var style_total : float
var file : FileAccess
var tree : SceneTree = get_tree()

func _ready():
	# Stores data in file into a list and gets the first 2 items that appear
	file  = FileAccess.open("res://Assets/OutfitSaveFile.txt", FileAccess.READ_WRITE)
	var data = file.get_as_text().split(',')
	items_wearing = [data[0], data[1]]
	print(items_wearing)
	
	for item_wearing in items_wearing:
		var item = load("res://Assets/Resources/%s.tres" % item_wearing)
		style_points_list.append(item.get_style_points())
		style_mult_list.append(item.get_style_multiplier())
		#print(item.get_style_points())
		#print(item.get_style_multiplier())
		#print(style_points_list)
		#print(style_mult_list)
	
	# Get totals of style points and style multipliers
	style_points = sum(style_points_list) 
	style_mult = mult_sum(style_mult_list)
	#print(style_points)
	#print(style_mult)
	
	# Get the total and display it
	style_total = style_points * style_mult
	
	if fmod(style_total, 1.0) == 0:
		text = "Score: %s" % int(style_total)
	else:
		text = "Score: %s" % style_total
	#print('total: ', style_total)
	
func sum(list : Array):
	var total : int
	for num in list:
		total += num
	return total
	
func mult_sum(list: Array):
	var total : float = 1
	for num in list:
		total += (num - 1)
	return total
