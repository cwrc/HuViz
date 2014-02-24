
TreePicker = require('treepicker').TreePicker
  
class ColoredTreePicker extends TreePicker
  constructor: (elem) ->
    super(elem)
    @mapping_to_colors = {}
  add: (new_id,parent_id,name,listener) ->
    super(new_id,parent_id,name,listener)
    @mapping_to_colors = @recolor()
  recolor: ->
    count = 0
    for id,elem of @id_to_elem
      count++
    i = 0
    retval = {}
    for id,elem of @id_to_elem
      i++
      hue = i/count * 360
      showing = hsv2rgb(hue,50,100)
      retval[id] =
        notshowing:  hsv2rgb(hue,15,100)
        showing:     showing
        emphasizing: hsv2rgb(hue,90,100)
      elem.style("background-color",showing)
      #console.log "recolor()",id,retval[id]
    retval
  get_showing_color: (id) ->
    id = @uri_to_js_id(id)
    @mapping_to_colors[id].showing
  get_notshowing_color: (id) ->
    id = @uri_to_js_id(id)
    @mapping_to_colors[id].notshowing

(exports ? this).ColoredTreePicker = ColoredTreePicker
