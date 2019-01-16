
#See for inspiration:
#  Collapsible Force Layout
#    http://bl.ocks.org/mbostock/1093130
#  Force-based label placement
#    http://bl.ocks.org/MoritzStefaner/1377729
#  Graph with labeled edges:
#    http://bl.ocks.org/jhb/5955887
#  Multi-Focus Layout:
#    http://bl.ocks.org/mbostock/1021953
#  Edge Labels
#    http://bl.ocks.org/jhb/5955887
#
#  Shelf -- around the graph, the ring of nodes which serves as reorderable menu
#  Discard Bin -- a jail to contain nodes one does not want to be bothered by
#
#  Commands on nodes
#     choose/shelve     -- graph or remove from graph
#     choose - add to graph and show all edges
#     unchoose - hide all edges except those to 'chosen' nodes
#                this will shelve (or hide if previously hidden)
#                those nodes which end up no longer being connected
#                to anything
#     discard/retrieve    -- throw away or recover
#     label/unlabel       -- shows labels or hides them
#     substantiate/redact -- shows source text or hides it
#     expand/contract     -- show all links or collapse them
#
# TODO(smurp) implement emphasize and deemphasize 'verbs' (we need a new word)
#   emphasize: (node,predicate,color) =>
#   deemphasize: (node,predicate,color) =>
#   pin/unpin
#
# TODO(smurp) break out verbs as instances of class Verb, support loading of verbs
#
# TODO: perhaps there is a distinction to be made between verbs
#   and 'actuators' where verbs are the things that people issue
#   while actuators (actions?) are the one-or-more things per-verb that
#   constitute the implementation of the verb.  The motivations are:
#     a) that actuators may be shared between verbs
#     b) multiple actuators might be needed per verb
#     c) there might be applications for actuators other than verbs
#     d) there might be update operations against gclui apart from actuators
#
# Immediate Priorities:
# 120) BUG: hidden nodes are hidden but are also detectable via TextCursor
# 118) TASK: add setting for "'chosen' border thickness (px)"
# 116) BUG: stop truncating verbs lists longer than 2 in TextCursor: use grid
# 115) TASK: add ColorTreepicker [+] and [-] boxes for 'show' and 'unshow'
# 114) TASK: make text_cursor show detailed stuff when in Commands and Settings
# 113) TASK: why is CP "Poetry" in abdyma.nq not shelved?
# 107) TASK: minimize hits on TextCursor by only calling it when verbs change
#            not whenever @focused_node changes
# 104) TASK: remove no-longer-needed text_cursor calls
#  40) TASK: support search better, show matches continuously
#  79) TASK: support dragging of edges to shelf or discard bin
#  97) TASK: integrate blanket for code coverage http://goo.gl/tH4Ghk
#  93) BUG: toggling a predicate should toggle indirect-mixed on its supers
#  92) BUG: non-empty predicates should not have payload '0/0' after kid click
#  94) TASK: show_msg() during command.run to inform user and prevent clicks
#  95) TASK: get /orlonto.html working smoothly again
#  90) BUG: english is no longer minimal
#  91) BUG: mocha async being misused re done(), so the passes count is wrong
#  86) BUG: try_to_set_node_type: only permit subtypes to override supertypes
#  87) BUG: solve node.type vs node.taxon sync problem (see orlonto)
#  46) TASK: impute node type based on predicates via ontology DONE???
#  53) PERF: should_show_label should not have search_regex in inner loop
#  65) BUG: hidden nodes are not fully ignored on the shelf so shelved nodes
#           are not always the focused node
#  68) TASK: optimize update_english
#  69) TASK: figure out ideal root for predicate hierarchy -- owl:Property?
#  70) TASK: make owl:Thing implicit root class
#            ie: have Taxons be subClassOf owl:Thing unless replaced
#  72) TASK: consolidate type and taxon links from node?
#  74) TASK: recover from loading crashes with Cancel button on show_state_msg
#  76) TASK: consider renaming graphed_set to connected_set and verbs
#            choose/unchoose to graph/ungraph
#  84) TASK: add an unchosen_set containing the graphed but not chosen nodes
#
# Eventual Tasks:
#  85) TASK: move SVG, Canvas and WebGL renderers to own pluggable Renderer subclasses
#  75) TASK: implement real script parser
#   4) TASK: Suppress all but the 6-letter id of writers in the cmd cli
#  14) TASK: it takes time for clicks on the predicate picker to finish;
#      showing a busy cursor or a special state for the selected div
#      would help the user have faith.
#      (Investigate possible inefficiencies, too.)
#      AKA: fix bad-layout-until-drag-and-drop bug
#  18) TASK: drop a node on another node to draw their mutual edges only
#  19) TASK: progressive documentation (context sensitive tips and intros)
#  25) TASK: debug wait cursor when slow operations are happening, maybe
#      prevent starting operations when slow stuff is underway
#      AKA: show waiting cursor during verb execution
#  30) TASK: Stop passing (node, change, old_node_status, new_node_status) to
#      Taxon.update_state() because it never seems to be needed
#  35) TASK: get rid of jquery
#  37) TASK: fix Bronte names, ie unicode
#  41) TASK: link to new backend
#  51) TASK: make predicate picker height adjustable
#  55) TASK: clicking an edge for a snippet already shown should add that
#            triple line to the snippet box and bring the box forward
#            (ideally using css animation to flash the triple and scroll to it)
#  56) TASK: improve layout of the snippet box so the subj is on the first line
#            and subsequent lines show (indented) predicate-object pairs for
#            each triple which cites the snippet
#  57) TASK: hover over node on shelf shows edges to graphed and shelved nodes
#  61) TASK: make a settings controller for edge label (em) (or mag?)
#  66) BUG: #load+/data/ballrm.nq fails to populate the predicate picker
#  67) TASK: add verbs pin/unpin (using polar coords to record placement)
#
angliciser = require('angliciser').angliciser
uniquer = require("uniquer").uniquer # FIXME rename to make_dom_safe_id
gcl = require('graphcommandlanguage')
#asyncLoop = require('asynchronizer').asyncLoop
CommandController = require('gclui').CommandController
EditController = require('editui').EditController
IndexedDBService = require('indexeddbservice').IndexedDBService
IndexedDBStorageController = require('indexeddbstoragecontroller').IndexedDBStorageController
Edge = require('edge').Edge
GraphCommandLanguageCtrl = require('graphcommandlanguage').GraphCommandLanguageCtrl
GreenerTurtle = require('greenerturtle').GreenerTurtle
Node = require('node').Node
Predicate = require('predicate').Predicate
Taxon = require('taxon').Taxon
TextCursor = require('textcursor').TextCursor

MultiString.set_langpath('en:fr') # TODO make this a setting

# It is as if these imports were happening but they are being stitched in instead
#   OnceRunner = require('oncerunner').OnceRunner
#   TODO document the other examples of requires that are being "stitched in"

colorlog = (msg, color, size) ->
  color ?= "red"
  size ?= "1.2em"
  console.log("%c#{msg}", "color:#{color};font-size:#{size};")

wpad = undefined
hpad = 10
tau = Math.PI * 2
distance = (p1, p2) ->
  p2 = p2 || [0,0]
  x = (p1.x or p1[0]) - (p2.x or p2[0])
  y = (p1.y or p1[1]) - (p2.y or p2[1])
  Math.sqrt x * x + y * y
dist_lt = (mouse, d, thresh) ->
  x = mouse[0] - d.x
  y = mouse[1] - d.y
  Math.sqrt(x * x + y * y) < thresh
hash = (str) ->
  # https://github.com/darkskyapp/string-hash/blob/master/index.js
  hsh = 5381
  i = str.length
  while i
    hsh = (hsh * 33) ^ str.charCodeAt(--i)
  return hsh >>> 0
convert = (src, srctable, desttable) ->
  # convert.js
  # http://rot47.net
  # Dr Zhihua Lai
  srclen = srctable.length
  destlen = desttable.length
  # first convert to base 10
  val = 0
  numlen = src.length
  i = 0
  while i < numlen
    val = val * srclen + srctable.indexOf(src.charAt(i))
    i++
  return 0  if val < 0
  # then covert to any base
  r = val % destlen
  res = desttable.charAt(r)
  q = Math.floor(val / destlen)
  while q
    r = q % destlen
    q = Math.floor(q / destlen)
    res = desttable.charAt(r) + res
  return res
BASE57 = "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
BASE10 = "0123456789"
int_to_base = (intgr) ->
  convert(""+intgr, BASE10, BASE57)
synthIdFor = (str) ->
  # return a short random hash suitable for use as DOM/JS id
  return 'h'+int_to_base(hash(str)).substr(0,6)

unescape_unicode = (u) ->
  # pre-escape any existing quotes so when JSON.parse does not get confused
  return JSON.parse('"' + u.replace('"', '\\"') + '"')

linearize = (msgRecipient, streamoid) ->
  if streamoid.idx is 0
    msgRecipient.postMessage({event: 'finish'})
  else
    i = streamoid.idx + 1
    l = 0
    while (streamoid.data[i] not '\n')
      l++
      i++
    line = streamoid.data.substr(streamoid.idx, l+1).trim()
    msgRecipient.postMessage({event:'line', line:line})
    streamoid.idx = i
    recurse = () -> linearize(msgRecipient, streamoid)
    setTimeout(recurse, 0)

unique_id = () ->
  'uid_'+Math.random().toString(36).substr(2,10)

window.log_click = () ->
  console.log("%cCLICK", "color:red;font-size:1.8em")

# http://dublincore.org/documents/dcmi-terms/
DC_subject  = "http://purl.org/dc/terms/subject"

FOAF_Group  = "http://xmlns.com/foaf/0.1/Group"
FOAF_Person = "http://xmlns.com/foaf/0.1/Person"
FOAF_name   = "http://xmlns.com/foaf/0.1/name"
OWL_Class   = "http://www.w3.org/2002/07/owl#Class"
OWL_Thing   = "http://www.w3.org/2002/07/owl#Thing"
OWL_ObjectProperty = "http://www.w3.org/2002/07/owl#ObjectProperty"
RDF_literal = "http://www.w3.org/1999/02/22-rdf-syntax-ns#PlainLiteral"
RDF_object  = "http://www.w3.org/1999/02/22-rdf-syntax-ns#object"
RDF_type    = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
RDF_Class   = "http://www.w3.org/2000/01/rdf-schema#Class"
RDF_subClassOf   = "http://www.w3.org/2000/01/rdf-schema#subClassOf"
RDF_a       = 'a'
RDFS_label  = "http://www.w3.org/2000/01/rdf-schema#label"
SKOS_prefLabel = "http://www.w3.org/2004/02/skos/core#prefLabel"
XL_literalForm = "http://www.w3.org/2008/05/skos-xl#literalForm"
TYPE_SYNS   = [RDF_type, RDF_a, 'rdfs:type', 'rdf:type']
NAME_SYNS = [
  FOAF_name, RDFS_label, 'rdfs:label', 'name', SKOS_prefLabel, XL_literalForm
  ]
XML_TAG_REGEX = /(<([^>]+)>)/ig

typeSigRE =
  # https://regex101.com/r/lKClAg/1
  'xsd': new RegExp("^http:\/\/www\.w3\.org\/2001\/XMLSchema\#(.*)$")
  # https://regex101.com/r/ccfdLS/3/
  'rdf': new RegExp("^http:\/\/www\.w3\.org\/1999\/02\/22-rdf-syntax-ns#(.*)$")
getPrefixedTypeSignature = (typeUri) ->
  for prefix, sig of typeSigRE
    match = typeUri.match(sig)
    if match
      return "#{prefix}__#{match[1]}"
  return
getTypeSignature = (typeUri) ->
  typeSig = getPrefixedTypeSignature(typeUri)
  return typeSig
  #return (typeSig or '').split('__')[1]
PRIMORDIAL_ONTOLOGY =
  subClassOf:
    Literal: 'Thing'
    # https://www.w3.org/1999/02/22-rdf-syntax-ns
    # REVIEW(smurp) ignoring all but the rdfs:Datatype instances
    # REVIEW(smurp) should Literal be called Datatype instead?
    "rdf__PlainLiteral": 'Literal'
    "rdf__HTML": 'Literal'
    "rdf__langString": 'Literal'
    "rdf__type": 'Literal'
    "rdf__XMLLiteral": 'Literal'
    # https://www.w3.org/TR/xmlschema11-2/type-hierarchy-201104.png
    # https://www.w3.org/2011/rdf-wg/wiki/XSD_Datatypes
    # REVIEW(smurp) ideally all the xsd types would fall under anyType > anySimpleType > anyAtomicType
    # REVIEW(smurp) what about Built-in list types like: ENTITIES, IDREFS, NMTOKENS ????
    "xsd__anyURI": 'Literal'
    "xsd__base64Binary": 'Literal'
    "xsd__boolean": 'Literal'
    "xsd__date": 'Literal'
    "xsd__dateTimeStamp": 'date'
    "xsd__decimal": 'Literal'
    "xsd__integer": "xsd__decimal"
    "xsd__long": "xsd__integer"
    "xsd__int": "xsd__long"
    "xsd__short": "xsd__int"
    "xsd__byte": "xsd__short"
    "xsd__nonNegativeInteger": "xsd__integer"
    "xsd__positiveInteger": "xsd__nonNegativeInteger"
    "xsd__unsignedLong": "xsd__nonNegativeInteger"
    "xsd__unsignedInt":  "xsd__unsignedLong"
    "xsd__unsignedShort": "xsd__unsignedInt"
    "xsd__unsignedByte": "xsd__unsignedShort"
    "xsd__nonPositiveInteger": "xsd__integer"
    "xsd__negativeInteger": "xsd__nonPositiveInteger"
    "xsd__double": 'Literal'
    "xsd__duration": 'Literal'
    "xsd__float": 'Literal'
    "xsd__gDay": 'Literal'
    "xsd__gMonth": 'Literal'
    "xsd__gMonthDay": 'Literal'
    "xsd__gYear": 'Literal'
    "xsd__gYearMonth": 'Literal'
    "xsd__hexBinary": 'Literal'
    "xsd__NOTATION": 'Literal'
    "xsd__QName": 'Literal'
    "xsd__string": 'Literal'
    "xsd__normalizedString": "xsd_string"
    "xsd__token": "xsd__normalizedString"
    "xsd__language": "xsd__token"
    "xsd__Name": "xsd__token"
    "xsd__NCName": "xsd__Name"
    "xsd__time": 'Literal'
  subPropertyOf: {}
  domain: {}
  range: {}
  label: {} # MultiStrings as values

MANY_SPACES_REGEX = /\s{2,}/g
UNDEFINED = undefined
start_with_http = new RegExp("http", "ig")
ids_to_show = start_with_http

PEEKING_COLOR = "darkgray"

themeStyles =
  "light":
    "themeName": "theme_white"
    "pageBg": "white"
    "labelColor": "black"
    "shelfColor": "lightgreen"
    "discardColor": "salmon"
    "nodeHighlightOutline": "black"
  "dark":
    "themeName": "theme_black"
    "pageBg": "black"
    "labelColor": "#ddd"
    "shelfColor": "#163e00"
    "discardColor": "#4b0000"
    "nodeHighlightOutline": "white"


id_escape = (an_id) ->
  retval = an_id.replace(/\:/g,'_')
  retval = retval.replace(/\//g,'_')
  retval = retval.replace(new RegExp(' ','g'),'_')
  retval = retval.replace(new RegExp('\\?','g'),'_')
  retval = retval.replace(new RegExp('\=','g'),'_')
  retval = retval.replace(new RegExp('\\.','g'),'_')
  retval = retval.replace(new RegExp('\\#','g'),'_')
  retval

if true
  node_radius_policies =
    "node radius by links": (d) ->
      d.radius = Math.max(@node_radius, Math.log(d.links_shown.length))
      return d.radius
      if d.showing_links is "none"
        d.radius = @node_radius
      else
        if d.showing_links is "all"
          d.radius = Math.max(@node_radius,
            2 + Math.log(d.links_shown.length))
      d.radius
    "equal dots": (d) ->
      @node_radius
  default_node_radius_policy = "equal dots"
  default_node_radius_policy = "node radius by links"

  has_type = (subject, typ) ->
    has_predicate_value subject, RDF_type, typ

  has_predicate_value = (subject, predicate, value) ->
    pre = subject.predicates[predicate]
    if pre
      objs = pre.objects
      oi = 0
      while oi <= objs.length
        obj = objs[oi]
        return true  if obj.value is value
        oi++
    false

  is_a_main_node = (d) ->
    (BLANK_HACK and d.s.id[7] isnt "/") or (not BLANK_HACK and d.s.id[0] isnt "_")

  is_node_to_always_show = is_a_main_node

  is_one_of = (itm,array) ->
    array.indexOf(itm) > -1

if not is_one_of(2,[3,2,4])
  alert "is_one_of() fails"

window.blurt = (str, type, noButton) ->
  #css styles for messages: info (blue), alert (yellow), error (red)
  # TODO There is currently no way for users to remove blurt boxes

  #type='info' if !type
  if type is "info" then label = "<h3>Message</h3>"
  if type is "alert" then label = "<h3>Alert</h3>"
  if type is "error" then label = "<h3>Error</h3>"
  if not type then label = ''
  if !$('#blurtbox').length
    if type is "error"
      $('#huvis_controls').prepend('<div id="blurtbox"></div>')
    else
      $('#tabs').append('<div id="blurtbox"></div>')
  $('#blurtbox').append("<div class='blurt #{type}'>#{label}#{str}<br class='clear'></div>")
  $('#blurtbox').scrollTop(10000)
  if not noButton
    $('#blurtbox').append("<button id='blurt_close' class='sml_bttn' type='button'>close</button>")

window.blurtDate = () ->
  blurt((""+new Date()+"").substr(0,24), null, true)

escapeHtml = (unsafe) ->
    return unsafe
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");


orlando_human_term =
  all: 'All'
  chosen: 'Activated'
  unchosen: 'Deactivated'
  selected: 'Selected'
  shelved: 'Shelved'
  discarded: 'Discarded'
  hidden: 'Hidden'
  graphed: 'Graphed'
  fixed: 'Pinned'
  labelled: 'Labelled'
  choose: 'Activate'
  unchoose: 'Deactivate'
  wander: 'Wander'
  walk: 'Walk'
  select: 'Select'
  unselect: 'Unselect'
  label: 'Label'
  unlabel: 'Unlabel'
  shelve: 'Shelve'
  hide: 'Hide'
  discard: 'Discard'
  undiscard: 'Retrieve'
  pin: 'Pin'
  unpin: 'Unpin'
  unpinned: 'Unpinned'
  nameless: 'Nameless'
  blank_verb: 'VERB'
  blank_noun: 'SET/SELECTION'
  hunt: 'Hunt'
  load: 'Load'
  draw: 'Draw'
  undraw: 'Undraw'

class Huviz
  class_list: [] # FIXME remove
  HHH: {}
  edges_by_id: {}
  edge_count: 0
  snippet_db: {}
  class_index: {}
  hierarchy: {}
  default_color: "brown"
  DEFAULT_CONTEXT: 'http://universal.org/'
  turtle_parser: 'GreenerTurtle'
  #turtle_parser: 'N3'

  use_canvas: true
  use_svg: false
  use_webgl: false
  #use_webgl: true  if location.hash.match(/webgl/)
  #use_canvas: false  if location.hash.match(/nocanvas/)

  nodes: undefined
  links_set: undefined
  node: undefined
  link: undefined

  lariat: undefined
  verbose: true
  verbosity: 0
  TEMP: 5
  COARSE: 10
  MODERATE: 20
  DEBUG: 40
  DUMP: false
  node_radius_policy: undefined
  draw_circle_around_focused: true
  draw_lariat_labels_rotated: true
  run_force_after_mouseup_msec: 2000
  nodes_pinnable: true

  BLANK_HACK: false
  width: undefined
  height: 0
  cx: 0
  cy: 0

  snippet_body_em: .7
  snippet_triple_em: .8
  line_length_min: 4

  # TODO figure out how to replace with the default_graph_control
  link_distance: 29
  fisheye_zoom: 4.0
  peeking_line_thicker: 4
  show_snippets_constantly: false
  charge: -193
  gravity: 0.025
  snippet_count_on_edge_labels: true
  label_show_range: null # @link_distance * 1.1
  focus_threshold: 100
  discard_radius: 200
  fisheye_radius: 300 #null # label_show_range * 5
  focus_radius: null # label_show_range
  drag_dist_threshold: 5
  snippet_size: 300
  dragging: false
  last_status: undefined
  edge_x_offset: 5
  shadow_offset: 1
  shadow_color: 'DarkGray'

  my_graph:
    predicates: {}
    subjects: {}
    objects: {}

  # required by green turtle, should be retired
  G: {}
  local_file_data: ""

  search_regex: new RegExp("^$", "ig")
  node_radius: 3.2

  mousedown_point: false
  discard_center: [0,0]
  lariat_center: [0,0]
  last_mouse_pos: [ 0, 0]

  renderStyles = themeStyles.light
  display_shelf_clockwise: true
  nodeOrderAngle = 0.5
  node_display_type = ''

  pfm_display: false
  pfm_data:
    tick:
      total_count: 0
      prev_total_count: 0
      timed_count: []
      label: "Ticks/sec."
    add_quad:
      total_count: 0
      prev_total_count: 0
      timed_count: []
      label: "Add Quad/sec"
    hatch:
      total_count: 0
      prev_total_count: 0
      timed_count: []
      label: "Hatch/sec"
    taxonomy:
      total_count: 0
      label: "Number of Classes:"
    sparql:
      total_count: 0
      prev_total_count: 0
      timed_count: []
      label: "Sparql Queries/sec"

  p_total_sprql_requests: 0

  change_sort_order: (array, cmp) ->
    array.__current_sort_order = cmp
    array.sort array.__current_sort_order
  isArray: (thing) ->
    Object::toString.call(thing) is "[object Array]"
  cmp_on_name: (a, b) ->
    return 0  if a.name is b.name
    return -1  if a.name < b.name
    1
  cmp_on_id: (a, b) ->
    return 0  if a.id is b.id
    return -1  if a.id < b.id
    1
  binary_search_on: (sorted_array, sought, cmp, ret_ins_idx) ->
    # return -1 or the idx of sought in sorted_array
    # if ret_ins_idx instead of -1 return [n] where n is where it ought to be
    # AKA "RETurn the INSertion INdeX"
    cmp = cmp or sorted_array.__current_sort_order or @cmp_on_id
    ret_ins_idx = ret_ins_idx or false
    seeking = true
    if sorted_array.length < 1
      return idx: 0  if ret_ins_idx
      return -1
    mid = undefined
    bot = 0
    top = sorted_array.length
    while seeking
      mid = bot + Math.floor((top - bot) / 2)
      c = cmp(sorted_array[mid], sought)

      #console.log(" c =",c);
      return mid  if c is 0
      if c < 0 # ie sorted_array[mid] < sought
        bot = mid + 1
      else
        top = mid
      if bot is top
        return idx: bot  if ret_ins_idx
        return -1

  # Objective:
  #   Maintain a sorted array which acts like a set.
  #   It is sorted so insertions and tests can be fast.
  # cmp: a comparison function returning -1,0,1
  # an integer was returned, ie it was found

  # Perform the set .add operation, adding itm only if not already present

  #if (Array.__proto__.add == null) Array.prototype.add = add;
  # the nodes the user has chosen to see expanded
  # the nodes the user has discarded
  # the nodes which are in the graph, linked together
  # the nodes not displaying links and not discarded
  # keep synced with html
  # bugged
  roughSizeOfObject: (object) ->
    # http://stackoverflow.com/questions/1248302/javascript-object-size
    objectList = []
    stack = [object]
    bytes = 0
    while stack.length
      value = stack.pop()
      if typeof value is "boolean"
        bytes += 4
      else if typeof value is "string"
        bytes += value.length * 2
      else if typeof value is "number"
        bytes += 8
      else if typeof value is "object" and objectList.indexOf(value) is -1
        objectList.push value
        for i of value
          stack.push value[i]
    bytes

  move_node_to_point: (node, point) ->
    node.x = point[0]
    node.y = point[1]

  click_node: (node_or_id) ->
    # motivated by testing. Should this also be used by normal click handling?
    console.warn("click_node() is deprecated")
    if typeof node_or_id is 'string'
      node = @nodes.get_by('id', node_or_id)
    else
      node = node_or_id
    @set_focused_node(node)
    evt = new MouseEvent "mouseup",
      screenX: node.x
      screenY: node.y
    @canvas.dispatchEvent(evt)
    return @

  click_verb: (id) ->
    verbs = $("#verb-#{id}")
    if not verbs.length
      throw new Error("verb '#{id}' not found")
    verbs.trigger("click")
    return @

  click_set: (id) ->
    if id is 'nodes'
      alert("set 'nodes' is deprecated")
      console.error("set 'nodes' is deprecated")
    else
      if not id.endsWith('_set')
        id = id + '_set'
    sel = "##{id}"
    sets = $(sel)
    if not sets.length
      throw new Error("set '#{id}' not found using selector: '#{sel}'")
    sets.trigger("click")
    return @

  click_predicate: (id) ->
    @gclui.predicate_picker.handle_click(id)
    return @

  click_taxon: (id) ->
    $("##{id}").trigger("click")
    return @

  like_string: (str) =>
    # Ideally we'd trigger an actual 'input' event but that is not possible
    #$(".like_input").val(str)
    @gclui.like_input.val(str)
    @gclui.handle_like_input()
    #debugger if @DEBUG and str is ""
    return @

  toggle_expander: (id) ->
    $("##{id} span.expander:first").trigger("click");
    return @

  doit: ->
    $("#doit_button").trigger("click")
    return @

  mousemove: =>
    d3_event = @mouse_receiver[0][0]
    @last_mouse_pos = d3.mouse(d3_event)
    if @rightClickHold
      @text_cursor.continue()
      @text_cursor.set_text("Inspect")
      if @focused_node
        the_node = $("##{@focused_node.lid}")
        if the_node.html() then the_node.remove()
        @render_node_info_box()
      else
        if $(".contextMenu.temp") then $(".contextMenu.temp").remove()
    else if not @dragging and @mousedown_point and @focused_node and
        distance(@last_mouse_pos, @mousedown_point) > @drag_dist_threshold
      # We can only know that the users intention is to drag
      # a node once sufficient motion has started, when there
      # is a focused_node
      #console.log "state_name == '" + @focused_node.state.state_name + "' and selected? == " + @focused_node.selected?
      #console.log "START_DRAG: \n  dragging",@dragging,"\n  mousedown_point:",@mousedown_point,"\n  @focused_node:",@focused_node
      @dragging = @focused_node
      if @edit_mode
        if @editui.subject_node isnt @dragging
          @editui.set_subject_node(@dragging)
      if @dragging.state isnt @graphed_set isnt @rightClickHold
        @graphed_set.acquire(@dragging)

    if @dragging and not @rightClickHold
      @force.resume() # why?
      @move_node_to_point(@dragging, @last_mouse_pos)
      if @edit_mode
        @text_cursor.pause("", "drop on object node")
      else
        if @dragging.links_shown.length is 0
          action = "choose"
        else if @dragging.fixed
          action = "unpin"
        else
          action = "pin"
        if @in_disconnect_dropzone(@dragging)
          action = "shelve"
        else if @in_discard_dropzone(@dragging)
          action = "discard"
        @text_cursor.pause("", "drop to #{@human_term[action]}")
    else if not @rightClickHold # ie NOT dragging
      # TODO put block "if not @dragging and @mousedown_point and @focused_node and distance" here
      if @edit_mode
        if @editui.object_node or not @editui.subject_node
          if @editui.object_datatype_is_literal
            @text_cursor.set_text("click subject node")
          else
            @text_cursor.set_text("drag subject node")
    if @peeking_node?
      console.log "PEEKING at node: " + @peeking_node.id
      if @focused_node? and @focused_node isnt @peeking_node
        pair = [ @peeking_node.id, @focused_node.id ]
        #console.log "   PEEKING at edge between" + @peeking_node.id + " and " + @focused_node.id
        for edge in @peeking_node.links_shown
          if edge.source.id in pair and edge.target.id in pair
            #console.log "PEEK edge.id is '" + edge.id + "'"
            edge.focused = true
            @print_edge edge
          else
            edge.focused = false
    @tick()

  mousedown: =>
    d3_event = @mouse_receiver[0][0]
    @mousedown_point = d3.mouse(d3_event)
    @last_mouse_pos = @mousedown_point

  mouseup: =>
    window.log_click()
    d3_event = @mouse_receiver[0][0]
    @mousedown_point = false
    point = d3.mouse(d3_event)
    if d3.event.button is 2 # Right click event so don't alter selected state
      @text_cursor.continue()
      @text_cursor.set_text("Select")
      if @focused_node then $("##{@focused_node.lid}").removeClass("temp")
      @rightClickHold = false
      return
    # if something was being dragged then handle the drop
    if @dragging
      #console.log "STOPPING_DRAG: \n  dragging",@dragging,"\n  mousedown_point:",@mousedown_point,"\n  @focused_node:",@focused_node
      @move_node_to_point(@dragging, point)
      if @in_discard_dropzone(@dragging)
        @run_verb_on_object('discard', @dragging)
      else if @in_disconnect_dropzone(@dragging)  # TODO rename to shelve_dropzone
        @run_verb_on_object('shelve', @dragging)
        # @unselect(@dragging) # this might be confusing
      else if @dragging.links_shown.length == 0
        @run_verb_on_object('choose', @dragging)
      else if @nodes_pinnable
        if @edit_mode and (@dragging is @editui.subject_node)
          console.log "not pinning subject_node when dropping"
        else if @dragging.fixed # aka pinned
          @run_verb_on_object('unpin', @dragging)
        else
          @run_verb_on_object('pin', @dragging)
      @dragging = false
      @text_cursor.continue()
      return

    if @edit_mode and @focused_node and @editui.object_datatype_is_literal
      @editui.set_subject_node(@focused_node)
      console.log("edit mode and focused note and editui is literal")
      @tick()
      return

    # this is the node being clickedRDF_literal
    if @focused_node # and @focused_node.state is @graphed_set
      @perform_current_command(@focused_node)
      @tick()
      return

    if @focused_edge
      # FIXME do the edge equivalent of @perform_current_command
      #@update_snippet() # useful when hover-shows-snippet
      @print_edge(@focused_edge)
      return

    # it was a drag, not a click
    drag_dist = distance(point, @mousedown_point)
    #if drag_dist > @drag_dist_threshold
    #  console.log "drag detection probably bugged",point,@mousedown_point,drag_dist
    #  return

    if @focused_node
      unless @focused_node.state is @graphed_set
        @run_verb_on_object('choose', @focused_node)
      else if @focused_node.showing_links is "all"
        @run_verb_on_object('print', @focused_node)
      else
        @run_verb_on_object('choose', @focused_node)
      # TODO(smurp) are these still needed?
      @force.links(@links_set)
      @restart()

    return

  mouseright: () =>
    d3.event.preventDefault()
    @text_cursor.continue()
    temp = null
    @text_cursor.set_text("Inspect", temp, "#75c3fb")
    @rightClickHold = true
    doesnt_exist = if @focused_node then true else false
    if @focused_node and doesnt_exist
      @render_node_info_box()

  render_node_info_box: () ->
    all_names = Object.values(@focused_node.name)
    names_all_langs = ""
    note = ""
    color_headers = ""
    node_out_links = ""

    for name in all_names
      if names_all_langs
        names_all_langs = names_all_langs + " -- " + name
      else
        names_all_langs = name
    other_types = ""
    if (@focused_node._types.length > 1)
      for node_type in @focused_node._types
        if node_type != @focused_node.type
          if other_types
            other_types = other_types + ", " + node_type
          else
            other_types = node_type
      other_types = " (" + other_types + ")"
    #console.log @focused_node
    #console.log @focused_node.links_from.length
    if (@focused_node.links_from.length > 0)
      for link_from in @focused_node.links_from
        url_check = link_from.target.id
        url_check = url_check.substring(0,4)
        #console.log url_check
        if url_check is "http"
          target = "<a href='#{link_from.target.id}' target='blank'>#{link_from.target.lid}</a>"
        else
          target = link_from.target.id

        node_out_links = node_out_links + "<li><i class='fas fa-long-arrow-alt-right'></i> <a href='#{link_from.predicate.id}' target='blank'>#{link_from.predicate.lid}</a> <i class='fas fa-long-arrow-alt-right'></i> #{target}</li>"
      node_out_links = "<ul>" + node_out_links + "</ul>"
    #console.log @focused_node
    if @focused_node._colors
      width = 100 / @focused_node._colors.length
      for color in @focused_node._colors
        color_headers = color_headers + "<div class='subHeader' style='background-color: #{color}; width: #{width}%;'></div>"
    if @endpoint_loader.value
      if @endpoint_loader.value and @focused_node.fully_loaded
        note = "<p class='note'>Node Fully Loaded</span>"
      else
        note = "<p class='note'><span class='label'>Note:</span> This node may not yet be fully loaded from remote server. Link details may not be accurate. Activate to load.</i>"
    if @focused_node
      node_info = """
        <div class="header" style="background-color:#{@focused_node.color};">#{color_headers}<button class="close_node_details" title="Close Information Box"><i class="far fa-window-close"></i></button></div>
        <p><span class='label'>id:</span> #{@focused_node.id}</p>
        <p><span class='label'>name:</span> #{names_all_langs}</p>
        <p><span class='label'>type(s):</span> #{@focused_node.type} #{other_types}</p>
        <p><span class='label'>Links To:</span> #{@focused_node.links_to.length} <br>
          <span class='label'>Links From:</span> #{@focused_node.links_from.length}</p>
          #{note}
          #{node_out_links}
        """
      max_width = @width * 0.50
      max_height = @height * 0.80
      d3.select('#viscanvas').append('div').attr('id', @focused_node.lid ).attr('class', 'contextMenu').classed('temp', true).style('display', 'block')
        .style('top', "#{d3.event.clientY}px")
        .style('left', "#{d3.event.clientX}px")
        .style('max-width', "#{max_width}px")
        .style('max-height', "#{max_height}px")
        .html(node_info)#.on('drag',@draggable_info_box)
      $("##{@focused_node.lid}").draggable()
      $("##{@focused_node.lid} .close_node_details").on('click', @close_info_box)

  close_info_box: (e) ->
    box = e.currentTarget.offsetParent
    $(box).remove()

  perform_current_command: (node) ->
    if @gclui.ready_to_perform()
      cmd = new gcl.GraphCommand this,
        verbs: @gclui.engaged_verbs
        subjects: [node]
      @run_command(cmd)
    #else
    #  @toggle_selected(node)
    @clean_up_all_dirt_once()

  run_command: (cmd, callback) ->
    #@show_state_msg(cmd.as_msg())
    @gclui.show_working_on(cmd)
    @gclc.run(cmd, callback)
    @gclui.show_working_off()
    #@hide_state_msg()
    return

  #///////////////////////////////////////////////////////////////////////////
  # resize-svg-when-window-is-resized-in-d3-js
  #   http://stackoverflow.com/questions/16265123/
  updateWindow: =>
    @get_container_width()
    @get_container_height()
    @update_graph_radius()
    @update_graph_center()
    @update_discard_zone()
    @update_lariat_zone()
    if @svg
      @svg.
        attr("width", @width).
        attr("height", @height)
    if @canvas
      @canvas.width = @width
      @canvas.height = @height
    @force.size [@mx, @my]
    # FIXME all selectors must be localized so if there are two huviz
    #       instances on a page they do not interact
    $("#graph_title_set").css("width", @width)
    $("#tabs").css("left", "auto")
    @restart()

  #///////////////////////////////////////////////////////////////////////////
  #
  #   http://bl.ocks.org/mbostock/929623
  get_charge: (d) =>
    graphed = d.state == @graphed_set
    retval = graphed and @charge or 0  # zero so shelf has no influence
    if retval is 0 and graphed
      console.error "bad combo of retval and graphed?",retval,graphed,d.name
    return retval

  get_gravity: =>
    return @gravity

  # lines: 5845 5848 5852 of d3.v3.js object to
  #    mouse_receiver.call(force.drag);
  # when mouse_receiver == viscanvas
  init_webgl: ->
    @init()
    @animate()

  #dump_line(add_line(scene,cx,cy,width,height,'ray'))
  draw_circle: (cx, cy, radius, strclr, filclr, start_angle, end_angle, special_focus) ->
    incl_cntr = start_angle? or end_angle?
    start_angle = start_angle or 0
    end_angle = end_angle or tau
    if strclr
      @ctx.strokeStyle = strclr or "blue"
    if filclr
      @ctx.fillStyle = filclr or "blue"
    @ctx.beginPath()
    if incl_cntr
      @ctx.moveTo(cx, cy) # so the arcs are wedges not chords
      # do not incl_cntr when drawing a whole circle
    @ctx.arc(cx, cy, radius, start_angle, end_angle, true)
    @ctx.closePath()
    if strclr
      @ctx.stroke()
    if filclr
      @ctx.fill()

    if special_focus # true if this is a wander or walk highlighted node
      @ctx.beginPath()
      radius = radius/2
      @ctx.arc(cx, cy, radius, 0, Math.PI*2)
      @ctx.closePath()
      @ctx.fillStyle = "black"
      @ctx.fill()

  draw_triangle: (x, y, size, color, x1, y1, x2, y2) ->
    # Rather than send all three coordinates, it would be better if just the tip
    # was passed along with an angle and size to calculate the other two points of the
    # triangle.
    @ctx.beginPath()
    @ctx.moveTo(x, y)
    @ctx.lineTo(x1, y1)
    @ctx.lineTo(x2, y2)
    @ctx.moveTo(x, y)
    @ctx.stroke()
    @ctx.fillStyle = color
    @ctx.fill()
    @ctx.closePath()

  draw_pie: (cx, cy, radius, strclr, filclrs, special_focus) ->
    num = filclrs.length
    if not num
      throw new Error("no colors specified")
    if num is 1
      @draw_circle(cx, cy, radius, strclr, filclrs[0],false,false,special_focus)
      return
    arc = tau/num
    start_angle = 0
    for filclr in filclrs
      end_angle = start_angle + arc
      @draw_circle(cx, cy, radius, strclr, filclr, end_angle, start_angle, special_focus)
      start_angle = start_angle + arc

  draw_line: (x1, y1, x2, y2, clr) ->
    @ctx.strokeStyle = clr or 'red'
    @ctx.beginPath()
    @ctx.moveTo(x1, y1)
    @ctx.lineTo(x2, y2)
    @ctx.closePath()
    @ctx.stroke()
  draw_curvedline: (x1, y1, x2, y2, sway_inc, clr, num_contexts, line_width, edge, directional_edge) ->
    pdist = distance([x1,y1],[x2,y2])
    sway = @swayfrac * sway_inc * pdist
    if pdist < @line_length_min
      return
    if sway is 0
      return
    # sway is the distance to offset the control point from the midline
    orig_angle = Math.atan2(x2 - x1, y2 - y1)
    ctrl_angle = (orig_angle + (Math.PI / 2))
    ang = ctrl_angle
    ang = orig_angle
    check_range = (val,name) ->
      window.maxes = window.maxes or {}
      window.ranges = window.ranges or {}
      range = window.ranges[name] or {max: -Infinity, min: Infinity}
      range.max = Math.max(range.max, val)
      range.min = Math.min(range.min, val)
    #check_range(orig_angle,'orig_angle')
    #check_range(ctrl_angle,'ctrl_angle')
    xmid = x1 + (x2-x1)/2
    ymid = y1 + (y2-y1)/2
    xctrl = xmid + Math.sin(ctrl_angle) * sway
    yctrl = ymid + Math.cos(ctrl_angle) * sway
    @ctx.strokeStyle = clr or 'red'
    @ctx.beginPath()
    @ctx.lineWidth = line_width
    @ctx.moveTo(x1, y1)
    @ctx.quadraticCurveTo(xctrl, yctrl, x2, y2)
    #@ctx.closePath()
    @ctx.stroke()

    xhndl = xmid + Math.sin(ctrl_angle) * (sway/2)
    yhndl = ymid + Math.cos(ctrl_angle)* (sway/2)
    edge.handle =
      x: xhndl
      y: yhndl
    @draw_circle(xhndl, yhndl, (line_width/2), clr) # draw a circle at the midpoint of the line
    if directional_edge
      arrow_size = 10
      if directional_edge is "forward"
        tip_x = x2
        tip_y = y2
      else
        tip_x = x1
        tip_y = y1
      #TODO This works but is ugly. The directional arrow created is too large
      #@draw_triangle(tip_x, tip_y, arrow_size, "blue", xctrl, yctrl, xmid, ymid)
    #@draw_line(xmid,ymid,xctrl,yctrl,clr) # show mid to ctrl

  draw_disconnect_dropzone: ->
    @ctx.save()
    @ctx.lineWidth = @graph_radius * 0.1
    @draw_circle(@lariat_center[0], @lariat_center[1], @graph_radius, renderStyles.shelfColor)
    @ctx.restore()
  draw_discard_dropzone: ->
    @ctx.save()
    @ctx.lineWidth = @discard_radius * 0.1
    @draw_circle(@discard_center[0], @discard_center[1], @discard_radius, "", renderStyles.discardColor)
    @ctx.restore()
  draw_dropzones: ->
    if @dragging
      @draw_disconnect_dropzone()
      @draw_discard_dropzone()
  in_disconnect_dropzone: (node) ->
    # is it within the RIM of the disconnect circle?
    dist = distance(node, @lariat_center)
    @graph_radius * 0.9 < dist and @graph_radius * 1.1 > dist
  in_discard_dropzone: (node) ->
    # is it ANYWHERE within the circle?
    dist = distance(node, @discard_center)
    @discard_radius * 1.1 > dist

  init_sets: ->
    #  states: graphed,shelved,discarded,hidden,embryonic
    #  embryonic: incomplete, not ready to be used
    #  graphed: in the graph, connected to other nodes
    #	 shelved: on the shelf, available for choosing
    #	 discarded: in the discard zone, findable but ignored by show_links_*
    #	 hidden: findable, but not displayed anywhere
    #              	 (when found, will become shelved)

    @nodes = SortedSet().named('all').
      sort_on("id").
      labelled(@human_term.all)
    @nodes.docs = """#{@nodes.label} nodes are in this set, regardless of state."""
    @all_set = @nodes

    @embryonic_set = SortedSet().named("embryo").
      sort_on("id").
      isFlag()
    @embryonic_set.docs = "
      Nodes which are not yet complete are 'embryonic' and not yet
      in '#{@all_set.label}'.  Nodes need to have a class and a label to
      no longer be embryonic."

    @chosen_set = SortedSet().named("chosen").
      sort_on("id").
      isFlag().
      labelled(@human_term.chosen).
      sub_of(@all_set)
    @chosen_set.docs = "
      Nodes which the user has specifically '#{@chosen_set.label}' by either
      dragging them into the graph from the surrounding green
      'shelf'. '#{@chosen_set.label}' nodes can drag other nodes into the
      graph if the others are #{@human_term.hidden} or #{@human_term.shelved} but
      not if they are #{@human_term.discarded}."
    @chosen_set.cleanup_verb = 'shelve'

    @selected_set = SortedSet().named("selected").
      sort_on("id").
      isFlag().
      labelled(@human_term.selected).
      sub_of(@all_set)
    @selected_set.cleanup_verb = "unselect"
    @selected_set.docs = "
      Nodes which have been '#{@selected_set.label}' using the class picker,
      ie which are highlighted and a little larger."

    @shelved_set = SortedSet().
      named("shelved").
      sort_on('name').
      case_insensitive_sort(true).
      labelled(@human_term.shelved).
      sub_of(@all_set).
      isState()
    @shelved_set.docs = "
      Nodes which are '#{@shelved_set.label}' on the green surrounding 'shelf',
      either because they have been dragged there or released back to there
      when the node which pulled them into the graph was
      '#{@human_term.unchosen}."

    @discarded_set = SortedSet().named("discarded").
      labelled(@human_term.discarded).
      sort_on('name').
      case_insensitive_sort(true).
      sub_of(@all_set).
      isState()
    @discarded_set.cleanup_verb = "shelve" # TODO confirm this
    @discarded_set.docs = "
      Nodes which have been '#{@discarded_set.label}' by being dragged into
      the red 'discard bin' in the bottom right corner.
      '#{@discarded_set.label}' nodes are not pulled into the graph when
      nodes they are connected to become '#{@chosen_set.label}'."

    @hidden_set = SortedSet().named("hidden").
      sort_on("id").
      labelled(@human_term.hidden).
      sub_of(@all_set).
      isState()
    @hidden_set.docs = "
      Nodes which are '#{@hidden_set.label}' but can be pulled into
      the graph by other nodes when those become
      '#{@human_term.chosen}'."
    @hidden_set.cleanup_verb = "shelve"

    @graphed_set = SortedSet().named("graphed").
      sort_on("id").
      labelled(@human_term.graphed).
      sub_of(@all_set).
      isState()
    @graphed_set.docs = "
      Nodes which are included in the central graph either by having been
      '#{@human_term.chosen}' themselves or which are pulled into the
      graph by those which have been."
    @graphed_set.cleanup_verb = "unchoose"

    @wasChosen_set = SortedSet().named("wasChosen").
      sort_on("id").
      labelled("Was Chosen").
      isFlag() # membership is not mutually exclusive with the isState() sets
    @wasChosen_set.docs = "
      Nodes are marked wasChosen by wander__atFirst for later comparison
      with nowChosen."

    @nowChosen_set = SortedSet().named("nowChosen").
      sort_on("id").
      labelled("Now Graphed").
      isFlag() # membership is not mutually exclusive with the isState() sets
    @nowChosen_set.docs = "
      Nodes pulled in by @choose() are marked nowChosen for later comparison
      against wasChosen by wander__atLast."

    @pinned_set = SortedSet().named('fixed').
      sort_on("id").
      labelled(@human_term.fixed).
      sub_of(@all_set).
      isFlag()
    @pinned_set.docs = "
      Nodes which are '#{@pinned_set.label}' to the canvas as a result of
      being dragged and dropped while already being '#{@human_term.graphed}'.
      #{@pinned_set.label} nodes can be #{@human_term.unpinned} by dragging
      them from their #{@pinned_set.label} location."
    @pinned_set.cleanup_verb = "unpin"

    @labelled_set = SortedSet().named("labelled").
      sort_on("id").
      labelled(@human_term.labelled).
      isFlag().
      sub_of(@all_set)
    @labelled_set.docs = "Nodes which have their labels permanently shown."
    @labelled_set.cleanup_verb = "unlabel"

    @nameless_set = SortedSet().named("nameless").
      sort_on("id").
      labelled(@human_term.nameless).
      sub_of(@all_set).
      isFlag('nameless')
    @nameless_set.docs = "Nodes for which no name is yet known"

    @links_set = SortedSet().
      named("shown").
      sort_on("id").
      isFlag()
    @links_set.docs = "Links which are shown."

    @predicate_set = SortedSet().named("predicate").isFlag().sort_on("id")
    @context_set   = SortedSet().named("context").isFlag().sort_on("id")
    @context_set.docs = "The set of quad contexts."

    @walk_path_set = []

    # TODO make selectable_sets drive gclui.build_set_picker
    #      with the nesting data coming from .sub_of(@all) as above
    @selectable_sets =
      all_set: @all_set
      chosen_set: @chosen_set
      selected_set: @selected_set
      shelved_set: @shelved_set
      discarded_set: @discarded_set
      hidden_set: @hidden_set
      graphed_set: @graphed_set
      labelled_set: @labelled_set
      pinned_set: @pinned_set
      nameless_set: @nameless_set

  get_set_by_id: (setId) ->
    return this[setId + '_set']

  update_all_counts: ->
    @update_set_counts()
    #@update_predicate_counts()

  update_predicate_counts: ->
    console.warn('the unproven method update_predicate_counts() has just been called')
    for a_set in @predicate_set
      name = a_set.lid
      @gclui.on_predicate_count_update(name, a_set.length)

  update_set_counts: ->
    for name, a_set of @selectable_sets
      @gclui.on_set_count_update(name, a_set.length)

  create_taxonomy: ->
    # The taxonomy is intertwined with the taxon_picker
    @taxonomy = {}  # make driven by the hierarchy

  summarize_taxonomy: ->
    out = ""
    tree = {}
    for id, taxon of @taxonomy
      out += "#{id}: #{taxon.state}\n"
      tree[id] = taxon.state
    return tree

  regenerate_english: ->
    root = 'Thing'
    if @taxonomy[root]? # TODO this should be the ROOT, not literally Thing
      @taxonomy[root].update_english()
    else
      console.log("not regenerating english because no taxonomy[#{root}]")
    return

  get_or_create_taxon: (taxon_id) ->
    if not @taxonomy[taxon_id]?
      taxon = new Taxon(taxon_id)
      @taxonomy[taxon_id] = taxon
      parent_lid = @ontology.subClassOf[taxon_id] or @HHH[taxon_id] or 'Thing'
      if parent_lid?
        parent = @get_or_create_taxon(parent_lid)
        taxon.register_superclass(parent)
        label = @ontology.label[taxon_id]
      @gclui.add_taxon(taxon_id, parent_lid, label, taxon) # FIXME should this be an event on the Taxon constructor?
    @taxonomy[taxon_id]

  update_labels_on_pickers: () ->
    for term_id, term_label of @ontology.label
      # a label might be for a taxon or a predicate, so we must sort out which
      if @gclui.taxon_picker.id_to_name[term_id]?
        @gclui.taxon_picker.set_name_for_id(term_label, term_id)
      if @gclui.predicate_picker.id_to_name[term_id]?
        @gclui.predicate_picker.set_name_for_id(term_label, term_id)

  toggle_taxon: (id, hier, callback) ->
    if callback?
      @gclui.set_taxa_click_storm_callback(callback)
    # TODO preserve the state of collapsedness?
    hier = hier? ? hier : true # default to true
    if hier
      @gclui.taxon_picker.collapse_by_id(id)
    $("##{id}").trigger("click")
    if hier
      @gclui.taxon_picker.expand_by_id(id)

  do: (args) ->
    cmd = new gcl.GraphCommand(this, args)
    @gclc.run(cmd)

  reset_data: ->
    # TODO fix gclc.run so it can handle empty sets
    if @discarded_set.length
      @do({verbs: ['shelve'], sets: [@discarded_set.id]})
    if @graphed_set.length
      @do({verbs: ['shelve'], sets: [@graphed_set.id]})
    if @hidden_set.length
      @do({verbs: ['shelve'], sets: [@hidden_set.id]})
    if @selected_set.length
      @do({verbs: ['unselect'], sets: [@selected_set.id]})
    @gclui.reset_editor()
    @gclui.select_the_initial_set()

  perform_tasks_after_dataset_loaded: ->
    @gclui.select_the_initial_set()
    @discover_names()

  reset_graph: ->
    #@dump_current_settings("at top of reset_graph()")
    @G = {} # is this deprecated?
    @init_sets()
    @init_gclc()
    @init_editc()
    @indexed_dbservice()
    @init_indexddbstorage()

    @force.nodes(@nodes)
    @force.links(@links_set)

    # TODO move this SVG code to own renderer
    d3.select(".link").remove()
    d3.select(".node").remove()
    d3.select(".lariat").remove()
    @node = @svg.selectAll(".node")
    @link = @svg.selectAll(".link") # looks bogus, see @link assignment below
    @lariat = @svg.selectAll(".lariat")

    @link = @link.data(@links_set)
    @link.exit().remove()
    @node = @node.data(@nodes)
    @node.exit().remove()
    @force.start()

  set_node_radius_policy: (evt) ->
    # TODO(shawn) remove or replace this whole method
    f = $("select#node_radius_policy option:selected").val()
    return  unless f
    if typeof f is typeof "str"
      @node_radius_policy = node_radius_policies[f]
    else if typeof f is typeof @set_node_radius_policy
      @node_radius_policy = f
    else
      console.log "f =", f
  init_node_radius_policy: ->
    policy_box = d3.select("#huvis_controls").append("div", "node_radius_policy_box")
    policy_picker = policy_box.append("select", "node_radius_policy")
    policy_picker.on "change", set_node_radius_policy
    for policy_name of node_radius_policies
      policy_picker.append("option").attr("value", policy_name).text policy_name

  calc_node_radius: (d) ->
    total_links = d.links_to.length + d.links_from.length
    diff_adjustment = 10 * (total_links/(total_links+9))
    final_adjustment =  @node_diff * (diff_adjustment - 1)
    @node_radius * (not d.selected? and 1 or @selected_mag) + final_adjustment

    #@node_radius_policy d
  names_in_edges: (set) ->
    out = []
    set.forEach (itm, i) ->
      out.push itm.source.name + " ---> " + itm.target.name
    out
  dump_details: (node) ->
    return unless window.dump_details
    #
    #    if (! DUMP){
    #      if (node.s.id != '_:E') return;
    #    }
    #
    console.log "================================================="
    console.log node.name
    console.log "  x,y:", node.x, node.y
    try
      console.log "  state:", node.state.state_name, node.state
    console.log "  chosen:", node.chosen
    console.log "  fisheye:", node.fisheye
    console.log "  fixed:", node.fixed
    console.log "  links_shown:", node.links_shown.length, @names_in_edges(node.links_shown)
    console.log "  links_to:", node.links_to.length, @names_in_edges(node.links_to)
    console.log "  links_from:", node.links_from.length, @names_in_edges(node.links_from)
    console.log "  showing_links:", node.showing_links
    console.log "  in_sets:", node.in_sets

  find_node_or_edge_closest_to_pointer: ->
    new_focused_node = null
    new_focused_edge = null
    new_focused_idx = null
    focus_threshold = @focus_threshold
    closest_dist = @width
    closest_point = null

    seeking = null # holds property name of the thing we are seeking: 'focused_node'/'object_node'/false
    if @dragging
      if not @edit_mode
        return
      seeking = "object_node"
    else
      seeking = "focused_node"

    # TODO build a spatial index!!!! OMG https://github.com/smurp/huviz/issues/25
    # Examine every node to find the closest one within the focus_threshold
    @nodes.forEach (d, i) =>
      n_dist = distance(d.fisheye or d, @last_mouse_pos)
      #console.log(d)
      if n_dist < closest_dist
        closest_dist = n_dist
        closest_point = d.fisheye or d
      if not (seeking is 'object_node' and @dragging and @dragging.id is d.id)
        if n_dist <= focus_threshold
          new_focused_node = d
          focus_threshold = n_dist
          new_focused_idx = i

    # Examine the center of every edge and make it the new_focused_edge if close enough and the closest thing
    @links_set.forEach (e, i) =>
      if e.handle?
        e_dist = distance(e.handle, @last_mouse_pos)
        if e_dist < closest_dist
          closest_dist = e_dist
          closest_point = e.handle
        if e_dist <= focus_threshold
          new_focused_edge = e
          focus_threshold = e_dist
          new_focused_edge_idx = i

    if new_focused_edge # the mouse is closer to an edge than a node
      new_focused_node = null
      seeking = null

    if closest_point
      if @draw_circle_around_focused
        @draw_circle(closest_point.x, closest_point.y, @node_radius * 3, "red")

    @set_focused_node(new_focused_node)
    @set_focused_edge(new_focused_edge)

    if seeking is 'object_node'
      @editui.set_object_node(new_focused_node)

  DEPRECATED_showing_links_to_cursor_map:
    all: 'not-allowed'
    some: 'all-scroll'
    none: 'pointer'

  set_focused_node: (node) -> # node might be null
    if @focused_node is node
      return # no change so skip
    if @focused_node
      # unfocus the previously focused_node
      if @use_svg
        d3.select(".focused_node").classed("focused_node", false)
      #@unscroll_pretty_name(@focused_node)
      @focused_node.focused_node = false
    if node
      if @use_svg
        svg_node = node[0][new_focused_idx]
        d3.select(svg_node).classed("focused_node", true)
      node.focused_node = true
    @focused_node = node # might be null
    if @focused_node
      #console.log("focused_node:", @focused_node)
      @gclui.engage_transient_verb_if_needed("select") # select is default verb
    else
      @gclui.disengage_transient_verb_if_needed()

  set_focused_edge: (new_focused_edge) ->
    if @proposed_edge and @focused_edge # TODO why bail now???
      return
    #console.log "set_focused_edge(#{new_focused_edge and new_focused_edge.id})"
    unless @focused_edge is new_focused_edge
      if @focused_edge? #and @focused_edge isnt new_focused_edge
        console.log "removing focus from previous focused_edge"
        @focused_edge.focused = false
        delete @focused_edge.source.focused_edge
        delete @focused_edge.target.focused_edge
      if new_focused_edge?
        # FIXME add use_svg stanza
        new_focused_edge.focused = true
        new_focused_edge.source.focused_edge = true
        new_focused_edge.target.focused_edge = true
      @focused_edge = new_focused_edge # blank it or set it
      if @focused_edge?
        if @edit_mode
          @text_cursor.pause("", "edit this edge")
        else
          @text_cursor.pause("", "show edge sources")
      else
        @text_cursor.continue()

  @proposed_edge = null #initialization (no proposed edge active)
  set_proposed_edge: (new_proposed_edge) ->
    console.log "Setting proposed edge...", new_proposed_edge
    if @proposed_edge
      delete @proposed_edge.proposed # remove .proposed flag from old one
    if new_proposed_edge
      new_proposed_edge.proposed = true # flag the new one
    @proposed_edge = new_proposed_edge # might be null
    @set_focused_edge(new_proposed_edge) # a proposed_edge also becomes focused

  install_update_pointer_togglers: ->
    console.warn("the update_pointer_togglers are being called too often")
    d3.select("#huvis_controls").on "mouseover", () =>
      @update_pointer = false
      @text_cursor.pause("default")
      #console.log "update_pointer: #{@update_pointer}"
    d3.select("#huvis_controls").on "mouseout", () =>
      @update_pointer = true
      @text_cursor.continue()
      #console.log "update_pointer: #{@update_pointer}"

  DEPRECATED_adjust_cursor: ->
    # http://css-tricks.com/almanac/properties/c/cursor/
    if @focused_node
      next = @showing_links_to_cursor_map[@focused_node.showing_links]
    else
      next = 'default'
    @text_cursor.set_cursor(next)

  set_cursor_for_verbs: (verbs) ->
    if not @use_fancy_cursor
      return
    text = [@human_term[verb] for verb in verbs].join("\n")
    if @last_cursor_text isnt text
      @text_cursor.set_text(text)
      @last_cursor_text = text

  auto_change_verb: ->
    if @focused_node
      @gclui.auto_change_verb_if_warranted(@focused_node)

  get_focused_node_and_its_state: ->
    focused = @focused_node
    if not focused
      return
    retval = (focused.lid or '') + ' '
    if !focused.state?
      console.error(retval + ' has no state!!! This is unpossible!!!! name:',focused.name)
      return
    retval += focused.state.id
    return retval

  on_tick_change_current_command_if_warranted: ->
    # It is warranted if we are hovering over nodes and the last state and this stat differ.
    # The status of the current command might change even if the mouse has not moved, because
    # for instance the graph has wiggled around under a stationary mouse.  For that reason
    # it is legit to go to the trouble of updating the command on the tick.  When though?
    # The command should be changed if one of a number of things has changed since last tick:
    #  * the focused node
    #  * the state of the focused node
    if @prior_node_and_state isnt @get_focused_node_and_its_state() # ie if it has changed
      if @gclui.engaged_verbs.length
        nodes = @focused_node? and [@focused_node] or []
        @gclui.prepare_command(
          @gclui.new_GraphCommand({verbs: @gclui.engaged_verbs, subjects: nodes}))

  position_nodes: ->
    only_move_subject = @edit_mode and @dragging and @editui.subject_node
    @nodes.forEach (node, i) =>
      @reposition_node(node, only_move_subject)

  reposition_node: (node, only_move_subject) ->
    if @dragging is node
      @move_node_to_point(node, @last_mouse_pos)
    if only_move_subject
      return
    if not @graphed_set.has(node)  # slower
    #if node.showing_links is 'none' # faster
      return
    node.fisheye = @fisheye(node)

  apply_fisheye: ->
    @links_set.forEach (e) =>
      e.target.fisheye = @fisheye(e.target)  unless e.target.fisheye

    if @use_svg
      link.attr("x1", (d) ->
        d.source.fisheye.x
      ).attr("y1", (d) ->
        d.source.fisheye.y
      ).attr("x2", (d) ->
        d.target.fisheye.x
      ).attr "y2", (d) ->
        d.target.fisheye.y

  shown_messages: []
  show_message_once: (msg, alert_too) ->
    if @shown_messages.indexOf(msg) is -1
      @shown_messages.push(msg)
      console.log(msg)
      if alert_too
        alert(msg)

  draw_edges_from: (node) ->
    num_edges = node.links_to.length
    #@show_message_once "draw_edges_from(#{node.id}) "+ num_edges
    return unless num_edges

    draw_n_n = {}
    for e in node.links_shown
      msg = ""
      if e.source is node
        continue
      if e.source.embryo
        msg += "source #{e.source.name} is embryo #{e.source.id}; "
        msg += e.id + " "
      if e.target.embryo
        msg += "target #{e.target.name} is embryo #{e.target.id}"
      if msg isnt ""
        #@show_message_once(msg)
        continue
      n_n = e.source.lid + " " + e.target.lid
      if not draw_n_n[n_n]?
        draw_n_n[n_n] = []
      draw_n_n[n_n].push(e)
      #@show_message_once("will draw edge() n_n:#{n_n} e.id:#{e.id}")
    edge_width = @edge_width
    for n_n, edges_between of draw_n_n
      sway = 1
      for e in edges_between
        #console.log e
        if e.focused? and e.focused
          line_width = @edge_width * @peeking_line_thicker
        else
          line_width = edge_width
        line_width = line_width + (@line_edge_weight * e.contexts.length)
        #@show_message_once("will draw line() n_n:#{n_n} e.id:#{e.id}")
        @draw_curvedline(e.source.fisheye.x, e.source.fisheye.y, e.target.fisheye.x,
                         e.target.fisheye.y, sway, e.color, e.contexts.length, line_width, e)
        #if this line from path node to path node then add black highlight
        if @walk_path_set.length > 0
          #console.log @walk_path_set
          for walk_node, i in @walk_path_set
            if @prune_walk_nodes is "directional_path"
              s1 = e.source.lid
              s2 = e.target.lid
              previous_node = @walk_path_set[i-1]
              #walk_frwrd = @walk_path_set[i+1]
              if s1 is previous_node and s2 is walk_node then directional_edge = 'forward'
              if s2 is previous_node and s1 is walk_node then directional_edge = 'backward'
            else # for non-directionall pruned path and 'hairy' path
              if e.source.lid is walk_node then source_is_path = true
              if e.target.lid is walk_node then target_is_path = true
        if directional_edge
          @draw_curvedline(e.source.fisheye.x, e.source.fisheye.y, e.target.fisheye.x,
                           e.target.fisheye.y, sway, "blue", e.contexts.length, 1, e, directional_edge)
          directional_edge = false
        if source_is_path and target_is_path
          @draw_curvedline(e.source.fisheye.x, e.source.fisheye.y, e.target.fisheye.x,
                           e.target.fisheye.y, sway, "black", e.contexts.length, 1, e)
          source_is_path = false
          target_is_path = false
        sway++

  draw_edges: ->
    if @use_canvas
      @graphed_set.forEach (node, i) =>
        @draw_edges_from(node)

    if @use_webgl
      dx = @width * xmult
      dy = @height * ymult
      dx = -1 * @cx
      dy = -1 * @cy
      @links_set.forEach (e) =>
        #e.target.fisheye = @fisheye(e.target)  unless e.target.fisheye
        @add_webgl_line e  unless e.gl
        l = e.gl

        #
        #	  if (e.source.fisheye.x != e.target.fisheye.x &&
        #	      e.source.fisheye.y != e.target.fisheye.y){
        #	      alert(e.id + " edge has a length");
        #	  }
        #
        @mv_line l, e.source.fisheye.x, e.source.fisheye.y, e.target.fisheye.x, e.target.fisheye.y
        @dump_line l

    if @use_webgl and false
      @links_set.forEach (e, i) =>
        return  unless e.gl
        v = e.gl.geometry.vertices
        v[0].x = e.source.fisheye.x
        v[0].y = e.source.fisheye.y
        v[1].x = e.target.fisheye.x
        v[1].y = e.target.fisheye.y

  draw_nodes_in_set: (set, radius, center) ->
    # cx and cy are local here TODO(smurp) rename cx and cy
    cx = center[0]
    cy = center[1]
    num = set.length
    set.forEach (node, i) =>
      #clockwise = false
      # 0 or 1 starts at 6, 0.5 starts at 12, 0.75 starts at 9, 0.25 starts at 3
      start = 1 - nodeOrderAngle
      if @display_shelf_clockwise
        rad = tau * (start - i / num)
      else
        rad = tau * (i / num + start)

      node.rad = rad
      node.x = cx + Math.sin(rad) * radius
      node.y = cy + Math.cos(rad) * radius
      node.fisheye = @fisheye(node)
      if @use_canvas
        filclrs = @get_node_color_or_color_list(
          node, renderStyles.nodeHighlightOutline)
        @draw_pie(node.fisheye.x, node.fisheye.y,
                  @calc_node_radius(node),
                  node.color or "yellow",
                  filclrs)
      if @use_webgl
        @mv_node node.gl, node.fisheye.x, node.fisheye.y

  draw_discards: ->
    @draw_nodes_in_set(@discarded_set, @discard_radius, @discard_center)
  draw_shelf: ->
    @draw_nodes_in_set(@shelved_set, @graph_radius, @lariat_center)
  draw_nodes: ->
    if @use_svg
      node.attr("transform", (d, i) ->
        "translate(" + d.fisheye.x + "," + d.fisheye.y + ")"
      ).attr "r", calc_node_radius
    if @use_canvas or @use_webgl
      @graphed_set.forEach (d, i) =>
        d.fisheye = @fisheye(d)
        #console.log d.name.NOLANG
        if @use_canvas
          node_radius = @calc_node_radius(d)
          stroke_color = d.color or 'yellow'
          if d.chosen?
            stroke_color = renderStyles.nodeHighlightOutline
            for node in @walk_path_set # Flag nodes that should be given path marker
              if d.lid is node
                special_focus = true
          # if 'pills' is selected; change node shape to rounded squares
          if (node_display_type == 'pills')
            pill_width = node_radius * 2
            pill_height = node_radius * 2
            filclr = @get_node_color_or_color_list(d)
            rndng = 1
            x = d.fisheye.x
            y = d.fisheye.y
            @rounded_rectangle(x, y,
                      pill_width,
                      pill_height,
                      rndng,
                      stroke_color,
                      filclr)
          else
            @draw_pie(d.fisheye.x, d.fisheye.y,
                      node_radius,
                      stroke_color,
                      @get_node_color_or_color_list(d),
                      special_focus)
        if @use_webgl
          @mv_node(d.gl, d.fisheye.x, d.fisheye.y)
  get_node_color_or_color_list: (n, default_color) ->
    default_color ?= 'black'
    if @color_nodes_as_pies and n._types and n._types.length > 1
      @recolor_node(n, default_color)
      return n._colors
    return [n.color or default_color]

  get_label_attributes: (d) ->
    text = d.pretty_name
    label_measure = @ctx.measureText(text) #this is total length of text (in ems?)
    browser_font_size = 12.8 # -- Setting or auto from browser?
    focused_font_size = @label_em * browser_font_size * @focused_mag
    padding = focused_font_size * 0.5
    line_height = focused_font_size * 1.25 # set line height to 125%
    max_len = 250
    min_len = 100
    label_length = label_measure.width + 2 * padding
    num_lines_raw = label_length/max_len
    num_lines = (Math.floor num_lines_raw) + 1
    if (num_lines > 1)
      width_default = @label_em * label_measure.width/num_lines
    else
      width_default = max_len
    bubble_text = []
    text_cuts = []
    ln_i = 0
    bubble_text[ln_i] = ""
    if (label_length < (width_default + 2 * padding)) # single line label
      max_line_length = label_length - padding
    else # more than one line so calculate how many and create text lines array
      text_split = text.split(' ') # array of words
      max_line_length = 0
      for word, i in text_split
        word_length = @ctx.measureText(word) #Get length of next word
        line_length = @ctx.measureText(bubble_text[ln_i]) #Get current line length
        new_line_length = word_length.width + line_length.width #add together for testing
        if (new_line_length < width_default) #if line length is still less than max
          bubble_text[ln_i] = bubble_text[ln_i] + word + " " #add word to bubble_text
        else #new line needed
          text_cuts[ln_i] = i
          real_line_length = @ctx.measureText(bubble_text[ln_i])
          new_line_width = real_line_length.width
          if (new_line_width > max_line_length) # remember longest line lengthth
            max_line_length = real_line_length.width
          ln_i++
          bubble_text[ln_i] = word + " "
    width = max_line_length + 2 * padding #set actual width of box to longest line of text
    height = (ln_i + 1) * line_height + 2 * padding # calculate height using wrapping text
    font_size = @label_em
    #console.log text
    #console.log "focused_font_size: " + focused_font_size
    #console.log "line height: " + line_height
    #console.log "padding: " + padding
    #console.log "label_length: " + label_length
    #console.log "bubble height: " + height
    #console.log "max_line_length: " + max_line_length
    #console.log "bubble width: " + width
    #console.log "bubble cut points: "
    #console.log text_cuts
    d.bub_txt = [width, height, line_height, text_cuts, font_size]

  should_show_label: (node) ->
    (node.labelled or
        node.focused_edge or
        (@label_graphed and node.state is @graphed_set) or
        dist_lt(@last_mouse_pos, node, @label_show_range) or
        (node.name? and node.name.match(@search_regex))) # FIXME make this a flag that gets updated ONCE when the regex changes not something deep in loop!!!
  draw_labels: ->
    if @use_svg
      label.attr "style", (d) ->
        if @should_show_label(d)
          ""
        else
          "display:none"
    if @use_canvas or @use_webgl
      # http://stackoverflow.com/questions/3167928/drawing-rotated-text-on-a-html5-canvas
      # http://diveintohtml5.info/canvas.html#text
      # http://stackoverflow.com/a/10337796/1234699
      focused_font_size = @label_em * @focused_mag
      focused_font = "#{focused_font_size}em sans-serif"
      unfocused_font = "#{@label_em}em sans-serif"
      focused_pill_font = "#{@label_em}em sans-serif"
      label_node = (node) =>
        return unless @should_show_label(node)
        ctx = @ctx
        ctx.textBaseline = "middle"
        # perhaps scrolling should happen here
        #if not node_display_type and (node.focused_node or node.focused_edge?)
        if node.focused_node or node.focused_edge?
          if (node_display_type == 'pills')
            ctx.font = focused_pill_font
          else
            label = @scroll_pretty_name(node)
            # console.log label
            if node.state.id is "graphed"
              cart_label = node.pretty_name
              ctx.measureText(cart_label).width #forces proper label measurement (?)
              if @cartouches
                @draw_cartouche(cart_label, node.fisheye.x, node.fisheye.y)
            ctx.fillStyle = node.color
            ctx.font = focused_font
        else
          ctx.fillStyle = renderStyles.labelColor #"white" is default
          ctx.font = unfocused_font
        if not node.fisheye?
          return
        if not @graphed_set.has(node) and @draw_lariat_labels_rotated
          # Flip label rather than write upside down
          #   var flip = (node.rad > Math.PI) ? -1 : 1;
          #   view-source:http://www.jasondavies.com/d3-dependencies/
          radians = node.rad
          flip = node.fisheye.x < @cx # flip labels on the left of center line
          textAlign = 'left'
          if flip
            radians = radians - Math.PI
            textAlign = 'right'
          ctx.save()
          ctx.translate(node.fisheye.x, node.fisheye.y)
          ctx.rotate -1 * radians + Math.PI / 2
          ctx.textAlign = textAlign
          if @debug_shelf_angles_and_flipping
            if flip #radians < 0
              ctx.fillStyle = 'rgb(255,0,0)'
            ctx.fillText(("  " + flip + "  " + radians).substr(0,14), 0, 0)
          else
            ctx.fillText("  " + node.pretty_name + "  ", 0, 0)
          ctx.restore()
        else
          if (node_display_type == 'pills')
            node_font_size = node.bub_txt[4]
            result = node_font_size != @label_em
            if not node.bub_txt.length or result
              @get_label_attributes(node)
            line_height = node.bub_txt[2]  # Line height calculated from text size ?
            adjust_x = node.bub_txt[0] / 2 - line_height/2# Location of first line of text
            adjust_y = node.bub_txt[1] / 2 - line_height
            pill_width = node.bub_txt[0] # box size
            pill_height = node.bub_txt[1]

            x = node.fisheye.x - pill_width/2
            y = node.fisheye.y - pill_height/2
            radius = 10 * @label_em
            alpha = 1
            outline = node.color
            # change box edge thickness and fill if node selected
            if node.focused_node or node.focused_edge?
              ctx.lineWidth = 2
              fill = "#f2f2f2"
            else
              ctx.lineWidth = 1
              fill = "white"
            @rounded_rectangle(x, y, pill_width, pill_height, radius, fill, outline, alpha)
            ctx.fillStyle = "#000"
            # Paint multi-line text
            text = node.pretty_name
            text_split = text.split(' ') # array of words
            cuts = node.bub_txt[3]
            print_label = ""
            for text, i in text_split
              if cuts and i in cuts
                ctx.fillText print_label.slice(0,-1), node.fisheye.x - adjust_x, node.fisheye.y - adjust_y
                adjust_y = adjust_y - line_height
                print_label = text + " "
              else
                print_label = print_label + text + " "
            if print_label # print last line, or single line if no cuts
              ctx.fillText print_label.slice(0,-1), node.fisheye.x - adjust_x, node.fisheye.y - adjust_y
          else
            ctx.fillText "  " + node.pretty_name + "  ", node.fisheye.x, node.fisheye.y

      @graphed_set.forEach(label_node)
      @shelved_set.forEach(label_node)
      @discarded_set.forEach(label_node)

  clear_canvas: ->
    @ctx.clearRect 0, 0, @canvas.width, @canvas.height
  blank_screen: ->
    @clear_canvas()  if @use_canvas or @use_webgl

  tick: =>
    # return if @focused_node   # <== policy: freeze screen when selected
    if true
      if @clean_up_all_dirt_onceRunner?
        if @clean_up_all_dirt_onceRunner.active
          @clean_up_all_dirt_onceRunner.stats.runTick ?= 0
          @clean_up_all_dirt_onceRunner.stats.skipTick ?= 0
          @clean_up_all_dirt_onceRunner.stats.skipTick++
          return
        else
          @clean_up_all_dirt_onceRunner.stats.runTick++
    @ctx.lineWidth = @edge_width # TODO(smurp) just edges should get this treatment
    @find_node_or_edge_closest_to_pointer()
    @auto_change_verb()
    @on_tick_change_current_command_if_warranted()
    @update_snippet() # continuously update the snippet based on the currently focused_edge
    @blank_screen()
    @draw_dropzones()
    @fisheye.focus @last_mouse_pos
    @show_last_mouse_pos()
    @position_nodes() # unless @edit_mode and @dragging and @editui.subject_node
    @apply_fisheye()
    @draw_edges()
    @draw_nodes()
    @draw_shelf()
    @draw_discards()
    @draw_labels()
    @draw_edge_labels()
    @pfm_count('tick')
    @prior_node_and_state = @get_focused_node_and_its_state()
    return

  rounded_rectangle: (x, y, w, h, radius, fill, stroke, alpha) ->
    # http://stackoverflow.com/questions/1255512/how-to-draw-a-rounded-rectangle-on-html-canvas
    ctx = @ctx
    ctx.fillStyle = fill
    r = x + w
    b = y + h
    ctx.save()
    ctx.beginPath()
    ctx.moveTo(x + radius, y)
    ctx.lineTo(r - radius, y)
    ctx.quadraticCurveTo(r, y, r, y + radius)
    ctx.lineTo(r, y + h - radius)
    ctx.quadraticCurveTo(r, b, r - radius, b)
    ctx.lineTo(x + radius, b)
    ctx.quadraticCurveTo(x, b, x, b - radius)
    ctx.lineTo(x, y + radius)
    ctx.quadraticCurveTo(x, y, x + radius, y)
    ctx.closePath()
    if alpha
      ctx.globalAlpha = alpha
    ctx.fill()
    ctx.globalAlpha = 1
    if stroke
      ctx.strokeStyle = stroke
      ctx.stroke()

  draw_cartouche: (label, x, y) ->
    width = @ctx.measureText(label).width
    height = @label_em * @focused_mag * 16
    radius = @edge_x_offset
    fill = renderStyles.pageBg
    alpha = .8
    outline = false
    x = x + @edge_x_offset
    y = y - height
    width = width + 2 * @edge_x_offset
    height = height + @edge_x_offset
    @rounded_rectangle(x, y, width, height, radius, fill, outline, alpha)

  draw_edge_labels: ->
    if @focused_edge?
      @draw_edge_label(@focused_edge)
    if @show_edge_labels_adjacent_to_labelled_nodes
      for edge in @links_set
        if edge.target.labelled or edge.source.labelled
          @draw_edge_label(edge)

  draw_edge_label: (edge) ->
    ctx = @ctx
    # TODO the edge label should really come from the pretty name of the predicate
    #   edge.label > edge.predicate.label > edge.predicate.lid
    label = edge.label or edge.predicate.lid
    if @snippet_count_on_edge_labels
      if edge.contexts?
        if edge.contexts.length
          label += " (#{edge.contexts.length})"
    width = ctx.measureText(label).width
    height = @label_em * @focused_mag * 16
    if @cartouches
      @draw_cartouche(label, edge.handle.x, edge.handle.y)
    #ctx.fillStyle = '#666' #@shadow_color
    #ctx.fillText " " + label, edge.handle.x + @edge_x_offset + @shadow_offset, edge.handle.y + @shadow_offset
    ctx.fillStyle = edge.color
    ctx.fillText(" " + label, edge.handle.x + @edge_x_offset, edge.handle.y)

  update_snippet: ->
    if @show_snippets_constantly and @focused_edge? and @focused_edge isnt @printed_edge
      @print_edge(@focused_edge)

  msg_history: ""
  show_state_msg: (txt) ->
    if false
      @msg_history += " " + txt
      txt = @msg_history
    @state_msg_box.show()
    @state_msg_box.html("<div class='msg_payload'>" + txt + "</div><div class='msg_backdrop'></div>")
    @state_msg_box.on('click', @hide_state_msg)
    @text_cursor.pause("wait")

  hide_state_msg: () =>
    @state_msg_box.hide()
    @text_cursor.continue()
    #@text_cursor.set_cursor("default")

  svg_restart: ->
    # console.log "svg_restart()"
    @link = @link.data(@links_set)
    @link.enter().
      insert("line", ".node").
      attr "class", (d) ->
        #console.log(l.geometry.vertices[0].x,l.geometry.vertices[1].x);
        "link"

    @link.exit().remove()
    @node = @node.data(@nodes)

    @node.exit().remove()

    nodeEnter = @node.enter().
      append("g").
      attr("class", "lariat node").
      call(force.drag)
    nodeEnter.append("circle").
      attr("r", calc_node_radius).
      style "fill", (d) ->
        d.color

    nodeEnter.append("text").
      attr("class", "label").
      attr("style", "").
      attr("dy", ".35em").
      attr("dx", ".4em").
      text (d) ->
        d.name

    @label = @svg.selectAll(".label")

  canvas_show_text: (txt, x, y) ->
    # console.log "canvas_show_text(" + txt + ")"
    @ctx.fillStyle = "black"
    @ctx.font = "12px Courier"
    @ctx.fillText txt, x, y
  pnt2str: (x, y) ->
    "[" + Math.floor(x) + ", " + Math.floor(y) + "]"
  show_pos: (x, y, dx, dy) ->
    dx = dx or 0
    dy = dy or 0
    @canvas_show_text pnt2str(x, y), x + dx, y + dy
  show_line: (x0, y0, x1, y1, dx, dy, label) ->
    dx = dx or 0
    dy = dy or 0
    label = typeof label is "undefined" and "" or label
    @canvas_show_text pnt2str(x0, y0) + "-->" + pnt2str(x0, y0) + " " + label, x1 + dx, y1 + dy
  add_webgl_line: (e) ->
    e.gl = @add_line(scene, e.source.x, e.source.y, e.target.x, e.target.y, e.source.s.id + " - " + e.target.s.id, "green")

  #dump_line(e.gl);
  webgl_restart: ->
    links_set.forEach (d) =>
      @add_webgl_line d
  restart: ->
    @svg_restart() if @use_svg
    @force.start()
  show_last_mouse_pos: ->
    @draw_circle @last_mouse_pos[0], @last_mouse_pos[1], @focus_radius, "yellow"
  remove_ghosts: (e) ->
    if @use_webgl
      @remove_gl_obj e.gl  if e.gl
      delete e.gl
  add_node_ghosts: (d) ->
    d.gl = add_node(scene, d.x, d.y, 3, d.color)  if @use_webgl

  add_to: (itm, array, cmp) ->
    # FIXME should these arrays be SortedSets instead?
    cmp = cmp or array.__current_sort_order or @cmp_on_id
    c = @binary_search_on(array, itm, cmp, true)
    return c  if typeof c is typeof 3
    array.splice c.idx, 0, itm
    c.idx

  remove_from: (itm, array, cmp) ->
    cmp = cmp or array.__current_sort_order or @cmp_on_id
    c = @binary_search_on(array, itm, cmp)
    array.splice c, 1  if c > -1
    array

  my_graph:
    subjects: {}
    predicates: {}
    objects: {}

  fire_newsubject_event: (s) ->
    window.dispatchEvent(
      new CustomEvent 'newsubject',
        detail:
          sid: s
          # time: new Date()
        bubbles: true
        cancelable: true
    )

  ensure_predicate_lineage: (pid) ->
    # Ensure that fire_newpredicate_event is run for pid all the way back
    # to its earliest (possibly abstract) parent starting with the earliest
    pred_lid = uniquer(pid)
    if not @my_graph.predicates[pred_lid]?
      if @ontology.subPropertyOf[pred_lid]?
        parent_lid = @ontology.subPropertyOf[pred_lid]
      else
        parent_lid = "anything"
      @my_graph.predicates[pred_lid] = []
      @ensure_predicate_lineage(parent_lid)
      pred_name = @ontology?label[pred_lid]
      @fire_newpredicate_event(pid, pred_lid, parent_lid, pred_name)

  fire_newpredicate_event: (pred_uri, pred_lid, parent_lid, pred_name) ->
    window.dispatchEvent(
      new CustomEvent 'newpredicate',
        detail:
          pred_uri: pred_uri
          pred_lid: pred_lid
          parent_lid: parent_lid
          pred_name: pred_name
        bubbles: true
        cancelable: true
    )

  auto_discover_header: (uri, digestHeaders, sendHeaders) ->
    # THIS IS A FAILED EXPERIMENT BECAUSE
    # It turns out that for security reasons AJAX requests cannot show
    # the headers of redirect responses.  So, though it is a fine ambition
    # to retrieve the X-PrefLabel it cannot be seen because the 303 redirect
    # it is attached to is processed automatically by the browser and we
    # find ourselves looking at the final response.
    $.ajax
      type: 'GET'
      url: uri
      beforeSend: (xhr) ->
        #console.log(xhr)
        for pair in sendHeaders
          #xhr.setRequestHeader('X-Test-Header', 'test-value')
          xhr.setRequestHeader(pair[0], pair[1])
        #xhr.setRequestHeader('Accept', "text/n-triples, text/x-turtle, */*")
      #headers:
      #  Accept: "text/n-triples, text/x-turtle, */*"
      success: (data, textStatus, request) =>
        console.log(textStatus)
        console.log(request.getAllResponseHeaders())
        console.table((line.split(':') for line in request.getAllResponseHeaders().split("\n")))
        for header in digestHeaders
          val = request.getResponseHeader(header)
          if val?
            alert(val)

  discovery_triple_ingestor_N3: (data, textStatus, request, discoArgs) =>
    # Purpose:
    #   THIS IS NOT YET IN USE.  THIS IS FOR WHEN WE SWITCH OVER TO N3
    #
    #   This is the XHR callback returned by @make_triple_ingestor()
    #   The assumption is that data will be something N3 can parse.
    # Accepts:
    #   discoArgs:
    #     quadTester (OPTIONAL)
    #       returns true if the quad is to be added
    #     quadMunger (OPTIONAL)
    #       returns an array of one or more quads inspired by each quad
    discoArgs ?= {}
    quadTester = discoArgs.quadTester or (q) => q?
    quadMunger = discoArgs.quadMunger or (q) => [q]
    quad_count = 0
    parser = N3.Parser()
    parser.parse data, (err, quad, pref) =>
      if err and discoArgs.onErr?
        discoArgs.onErr(err)
      if quadTester(quad)
        for aQuad in quadMunger(quad)
          @inject_discovered_quad_for(quad, discoArgs.aUrl)

  discovery_triple_ingestor_GreenTurtle: (data, textStatus, request, discoArgs) =>
    # Purpose:
    #   This is the XHR callback returned by @make_triple_ingestor()
    #   The assumption is that data will be something N3 can parse.
    # Accepts:
    #   discoArgs:
    #     quadTester (OPTIONAL)
    #       returns true if the quad is to be added
    #     quadMunger (OPTIONAL)
    #       returns an array of one or more quads inspired by each quad
    discoArgs ?= {}
    graphUri = discoArgs.graphUri
    quadTester = discoArgs.quadTester or (q) => q?
    quadMunger = discoArgs.quadMunger or (q) => [q]
    dataset = new GreenerTurtle().parse(data, "text/turtle")
    for subj_uri, frame of dataset.subjects
      for pred_id, pred of frame.predicates
        for obj in pred.objects
          quad =
            s: frame.id
            p: pred.id
            o: obj # keys: type,value[,language]
            g: graphUri
          if quadTester(quad)
            for aQuad in quadMunger(quad)
              @inject_discovered_quad_for(aQuad, discoArgs.aUrl)
    return

  make_triple_ingestor: (discoArgs) =>
    return (data, textStatus, request) =>
      @discovery_triple_ingestor_GreenTurtle(data, textStatus, request, discoArgs)

  discover_labels: (aUrl) =>
    discoArgs =
      aUrl: aUrl
      quadTester: (quad) =>
        if quad.s isnt aUrl.toString()
          return false
        if not (quad.p in NAME_SYNS)
          return false
        return true
      quadMunger: (quad) =>
        return [quad]
      graphUri: aUrl.origin
    @make_triple_ingestor(discoArgs)

  ingest_quads_from: (uri, success, failure) =>
    $.ajax
      type: 'GET'
      url: uri
      success: success
      failure: failure

  discover_geoname_name_msgs_threshold_ms: 5 * 1000 # msec betweeen repetition of a msg display
  discover_geoname_name_instructions: """<span style="font-size:.7em">
   Be sure to
     1) create a
        <a target="geonamesAcct"
           href="http://www.geonames.org/login">new account</a>
     2) validate your email
     3) on
        <a target="geonamesAcct"
           href="http://www.geonames.org/manageaccount">manage account</a>
        press
        <a target="geonamesAcct"
            href="http://www.geonames.org/enablefreewebservice">click here to enable</a>
    4) re-enter your GeoNames username in HuViz settings to trigger lookup</span>"""

  countdown_input: (inputName) ->
    input = $("input[name='#{inputName}']")
    if input.val() < 1
      return false
    newVal = input.val() - 1
    input.val(newVal)
    return true

  discover_geoname_name: (aUrl) ->
    id = aUrl.pathname.replace(/\//g,'')
    userId = @discover_geonames_as
    k2p = @discover_geoname_key_to_predicate_mapping
    if not @countdown_input('discover_geonames_remaining')
      return
    $.ajax
      url: "http://api.geonames.org/hierarchyJSON?geonameId=#{id}&username=#{userId}"
      success: (json, textStatus, request) =>
        if json.status
          @discover_geoname_name_msgs ?= {}
          if json.status.message
            msg = """<dt style="font-size:.9em;color:red">#{json.status.message}</dt>""" +
              @discover_geoname_name_instructions
            if userId
              msg = "#{userId} #{msg}"
          if (not @discover_geoname_name_msgs[msg]) or
              (@discover_geoname_name_msgs[msg] and
               Date.now() - @discover_geoname_name_msgs[msg] >
                @discover_geoname_name_msgs_threshold_ms)
            @discover_geoname_name_msgs[msg] = Date.now()
            @show_state_msg(msg)
          return
        #subj = aUrl.toString()
        geoNamesRoot = aUrl.origin
        deeperQuad = null
        greedy = @discover_geonames_greedily
        deep = @discover_geonames_deeply
        depth = 0
        for geoRec in json.geonames by -1 # from most specific to most general
          subj = geoNamesRoot + '/' + geoRec.geonameId + '/'
          console.log("discover_geoname_name(#{subj})")
          depth++
          console.table([geoRec])
          name = (geoRec or {}).name

          placeQuad =
            s: subj
            p: RDF_type
            o:
              value: 'https://schema.org/Place'
              type: RDF_object  # REVIEW are there others?
            g: geoNamesRoot
          @inject_discovered_quad_for(placeQuad, aUrl)

          seen_name = false
          for key, value of geoRec # climb the hierarchy of Places sent by GeoNames
            if key is 'name'
              seen_name = true # so we can break at the end of this loop being done
            else
              if not greedy
                continue
            if key in ['geonameId']
              continue
            pred = k2p[key]
            if not pred
              continue
            theType = RDF_literal

            if typeof value is 'number'
              # REVIEW are these right?
              if Number.isInteger(value)
                theType = 'xsd:integer'
              else
                theType = 'xsd:decimal'
              value = "" + value # convert to string for @add_quad()
            else
              theType = RDF_literal
            quad =
              s: subj
              p: pred
              o:
                value: value
                type: theType  # REVIEW are there others?
              g: geoNamesRoot
            @inject_discovered_quad_for(quad, aUrl)
            if not greedy and seen_name
              break # out of the greedy consumption of all k/v pairs
          if not deep and depth > 1
            break # out of the deep consumption of all nested contexts
          if deeperQuad
            containershipQuad =
              s: quad.s
              p: 'http://data.ordnancesurvey.co.uk/ontology/spatialrelations/contains'
              o:
                value: deeperQuad.s
                type: RDF_object
              g: geoNamesRoot
            @inject_discovered_quad_for(containershipQuad, aUrl)
          deeperQuad = Object.assign({}, quad) # shallow copy
        return # from success
    return

  ###
          "fcode" : "RGN",
          "adminCodes1" : {
             "ISO3166_2" : "ENG"
          },
          "adminName1" : "England",
           "countryName" : "United Kingdom",
          "fcl" : "L",
          "countryId" : "2635167",
          "adminCode1" : "ENG",
          "name" : "Yorkshire",
          "lat" : "53.95528",
          "population" : 0,
          "geonameId" : 8581589,
          "fclName" : "parks,area, ...",
          "countryCode" : "GB",
          "fcodeName" : "region",
          "toponymName" : "Yorkshire",
          "lng" : "-1.16318"
  ###
  discover_geoname_key_to_predicate_mapping:
    name: RDFS_label
    #toponymName: RDFS_label
    #lat: 'http://dbpedia.org/property/latitude'
    #lng: 'http://dbpedia.org/property/longitude'
    #fcodeName: RDF_literal
    population: 'http://dbpedia.org/property/population'

  inject_discovered_quad_for: (quad, url) ->
    # Purpose:
    #   Central place to perform operations on discoveries, such as caching.
    q = @add_quad(quad)
    @update_set_counts()
    @found_names ?= []
    @found_names.push(quad.o.value)
    #msg = "inject_discovered_quad(#{quad.o})"
    #colorlog(url)

  auto_discover: (uri, force) ->
    try
      aUrl = new URL(uri)
    catch e
      colorlog("skipping auto_discover('#{uri}') because")
      console.log(e)
      return
    if uri.startsWith("http://id.loc.gov/")
      # This is less than ideal because it uses the special knowledge
      # that the .skos.nt file is available. Unfortunately the only
      # RDF file which is offered via content negotiation is .rdf and
      # there is no parser for that in HuViz yet.  Besides, they are huge.
      @ingest_quads_from("#{uri}.skos.nt", @discover_labels(uri))
      #@auto_discover_header(uri, ['X-PrefLabel'], sendHeaders or [])
    if uri.startsWith("http://sws.geonames.org/") and @discover_geonames_as
      @discover_geoname_name(aUrl)

  discover_names: (force) ->
    for node in @nameless_set
      @auto_discover(node.id, force)

  make_qname: (uri) ->
    # TODO(smurp) dear god! this method name is lying (it is not even trying)
    return uri

  last_quad: {}

  # add_quad is the standard entrypoint for all data sources
  # It is fires the events:
  #   newsubject
  object_value_types: {}
  unique_pids: {}
  add_quad: (quad, sprql_subj) ->  #sprq_sbj only used in SPARQL quieries
    # FIXME Oh! How this method needs a fine toothed combing!!!!
    #   * are rdf:Class and owl:Class the same?
    #   * uniquer is misnamed, it should be called make_domsafe_id or sumut
    #   * vars like sid, pid, subj_lid should be revisited
    #   * review subj vs subj_n
    #   * do not conflate node ids across prefixes eg rdfs:Class vs owl:Class
    #   * Literal should not be a subclass of Thing. Thing and dataType are sibs
    # Terminology:
    #   A `lid` is a "local id" which is unique and a safe identifier for css selectors.
    #   This is in opposition to an `id` which is a synonym for uri (ideally).
    #   There is inconsistency in this usage, which should be cleared up.
    #   Proposed terms which SHOULD be used are:
    #     - *_curie             eg pred_curie='rdfs:label'
    #     - *_uri               eg subj_uri='http://sparql.cwrc.ca/ontology/cwrc#NaturalPerson'
    #     - *_lid: a "local id" eg subj_lid='atwoma'
    #console.log "HuViz.add_quad()", quad
    subj_uri = quad.s
    pred_uri = quad.p
    ctxid = quad.g || @DEFAULT_CONTEXT
    subj_lid = uniquer(subj_uri)  # FIXME rename uniquer to make_dom_safe_id
    @object_value_types[quad.o.type] = 1
    @unique_pids[pred_uri] = 1
    newsubj = false
    subj = null
    #if @p_display then @performance_dashboard('add_quad')

    # REVIEW is @my_graph still needed and being correctly used?
    if not @my_graph.subjects[subj_uri]?
      newsubj = true
      subj =
        id: subj_uri
        name: subj_lid
        predicates: {}
      @my_graph.subjects[subj_uri] = subj
    else
      subj = @my_graph.subjects[subj_uri]

    @ensure_predicate_lineage(pred_uri)
    edge = null
    subj_n = @get_or_create_node_by_id(subj_uri)
    pred_n = @get_or_create_predicate_by_id(pred_uri)
    cntx_n = @get_or_create_context_by_id(ctxid)
    if quad.p is RDF_subClassOf and @show_class_instance_edges
      @try_to_set_node_type(subj_n, 'Class')
    # TODO: use @predicates_to_ignore instead OR rdfs:first and rdfs:rest
    if pred_uri.match(/\#(first|rest)$/)
      console.warn("add_quad() ignoring quad because pred_uri=#{pred_uri}", quad)
      return
    # set the predicate on the subject
    if not subj.predicates[pred_uri]?
      subj.predicates[pred_uri] = {objects:[]}
    if quad.o.type is RDF_object
      # The object is not a literal, but another resource with an uri
      # so we must get (or create) a node to represent it
      obj_n = @get_or_create_node_by_id(quad.o.value)
      if quad.o.value is RDF_Class and @show_class_instance_edges
        # This weird operation is to ensure that the Class Class is a Class
        @try_to_set_node_type(obj_n, 'Class')
      if quad.p is RDF_subClassOf and @show_class_instance_edges
        @try_to_set_node_type(obj_n, 'Class')
      # We have a node for the object of the quad and this quad is relational
      # so there should be links made between this node and that node
      is_type = is_one_of(pred_uri, TYPE_SYNS)
      make_edge = @show_class_instance_edges or not is_type
      if is_type
        @try_to_set_node_type(subj_n, quad.o.value)
      if make_edge
        @develop(subj_n) # both subj_n and obj_n should hatch for edge to make sense
        # REVIEW uh, how are we ensuring that the obj_n is hatching? should it?
        edge = @get_or_create_Edge(subj_n, obj_n, pred_n, cntx_n)
        @infer_edge_end_types(edge)
        edge.register_context(cntx_n)
        edge.color = @gclui.predicate_picker.get_color_forId_byName(pred_n.lid,'showing')
        @add_edge(edge)
        @develop(obj_n)
    else # ie the quad.o is a literal
      if is_one_of(pred_uri, NAME_SYNS)
        @set_name(
          subj_n,
          quad.o.value.replace(/^\s+|\s+$/g, ''),
          quad.o.language)
        if subj_n.embryo
          @develop(subj_n) # might be ready now
      else # the object is a literal other than name
        if @make_nodes_for_literals
          objVal = quad.o.value
          simpleType = getTypeSignature(quad.o.type or '') or 'Literal'
          # Does the value have a language or does it contain spaces?
          if quad.o.language or (objVal.match(/\s/g)||[]).length > 0
            # Perhaps an appropriate id for a literal "node" is
            # some sort of amalgam of the subject and predicate ids
            # for that object.
            # Why?  Consider the case of rdfs:comment.
            # If there are multiple literal object values on rdfs:comment
            # they are presumably different language versions of the same
            # text.  For them to end up on the same MultiString instance
            # they all have to be treated as names for a node with the same
            # id -- hence that id must be composed of the subj and pred ids.
            objKey = "#{subj_n.lid} #{pred_uri}"
            objId = synthIdFor(objKey)
          else
            objId = synthIdFor(objVal)
          literal_node = @get_or_create_node_by_id(objId, null, (isLiteral = true))
          @try_to_set_node_type(literal_node, simpleType)
          literal_node.__dataType = quad.o.type
          @develop(literal_node)
          @set_name(literal_node, quad.o.value, quad.o.language)
          edge = @get_or_create_Edge(subj_n, literal_node, pred_n, cntx_n)
          @infer_edge_end_types(edge)
          edge.register_context(cntx_n)
          edge.color = @gclui.predicate_picker.get_color_forId_byName(pred_n.lid,'showing')
          @add_edge(edge)
          literal_node.fully_loaded = true # for sparql quieries to flag literals as fully_loaded
    # if SPARQL Endpoint loaded AND this is subject node then set current subject to true (i.e. fully loaded)
    if @endpoint_loader.value
      subj_n.fully_loaded = false # all nodes default to not being fully_loaded
      #if subj_n.id is sprql_subj# if it is the subject node then is fully_loaded
      #  subj_n.fully_loaded = true
      if subj_n.id is quad.subject # if it is the subject node then is fully_loaded
        subj_n.fully_loaded = true
    @last_quad = quad
    @pfm_count('add_quad')
    return edge

  remove_from_nameless: (node) ->
    if node.nameless?
      this.nameless_removals ?= 0
      this.nameless_removals++
      node_removed = @nameless_set.remove(node)
      if node_removed isnt node
        console.log("expecting",node_removed,"to have been",node)
      #if @nameless_set.binary_search(node) > -1
      #  console.log("expecting",node,"to no longer be found in",@nameless_set)
      delete node.nameless_since
    return
  add_to_nameless: (node) ->
    if node.isLiteral
      # Literals cannot have names looked up.
      return
    node.nameless_since = performance.now()
    @nameless_set.traffic ?= 0
    @nameless_set.traffic++
    @nameless_set.add(node)
    #@nameless_set.push(node) # REVIEW(smurp) why not .add()?????
    return

  set_name: (node, full_name, lang) ->
    # So if we set the full_name to null that is to mean that we have
    # no good idea what the name yet.
    perform_rename = () =>
      if full_name?
        if not node.isLiteral
          @remove_from_nameless(node)
      else
        if not node.isLiteral
          @add_to_nameless(node)
        full_name = node.lid or node.id
      if typeof full_name is 'object'
        # MultiString instances have constructor.name == 'String'
        # console.log(full_name.constructor.name, full_name)
        node.name = full_name
      else
        if node.name
          node.name.set_val_lang(full_name, lang)
        else
          node.name = new MultiString(full_name, lang)
    if node.state and node.state.id is 'shelved'
      # Alter calls the callback add_name in the midst of an operation
      # which is likely to move subj_n from its current position in
      # the shelved_set.  The shelved_set is the only one which is
      # sorted by name and as a consequence is the only one able to
      # be confused by the likely shift in alphabetic position of a
      # node.  For the sake of efficiency we "alter()" the position
      # of the node rather than do shelved_set.resort() after the
      # renaming.
      @shelved_set.alter(node, perform_rename)
      @tick()
    else
      perform_rename()
    #node.name ?= full_name  # set it if blank
    len = @truncate_labels_to
    if not len?
      alert "len not set"
    if len > 0
      node.pretty_name = node.name.substr(0, len) # truncate
    else
      node.pretty_name = node.name
    node.scroll_offset = 0
    return

  scroll_spacer: "   "

  scroll_pretty_name: (node) ->
    if @truncate_labels_to >= node.name.length
      limit = node.name.length
    else
      limit = @truncate_labels_to
    should_scroll = limit > 0 and limit < node.name.length
    if not should_scroll
      return
    if true # node.label_truncated_to
      spacer = @scroll_spacer
      if not node.scroll_offset
        node.scroll_offset = 1
      else
        node.scroll_offset += 1
        if node.scroll_offset > node.name.length + spacer.length #limit
          node.scroll_offset = 0
      wrapped = ""
      while wrapped.length < 3 * limit
        wrapped +=  node.name + spacer
      node.pretty_name = wrapped.substr(node.scroll_offset, limit)
    # if node.pretty_name.length > limit
    #   alert("TOO BIG")
    # if node.pretty_name.length < 1
    #   alert("TOO SMALL")
  unscroll_pretty_name: (node) ->
    @set_name(node, node.name)

  infer_edge_end_types: (edge) ->
    edge.source.type = 'Thing' unless edge.source.type?
    edge.target.type = 'Thing' unless edge.target.type?
    # infer type of source based on the range of the predicate
    ranges = @ontology.range[edge.predicate.lid]
    if ranges?
      @try_to_set_node_type(edge.target, ranges[0])
    # infer type of source based on the domain of the predicate
    domain_lid = @ontology.domain[edge.predicate.lid]
    if domain_lid?
      @try_to_set_node_type(edge.source, domain_lid)

  make_Edge_id: (subj_n, obj_n, pred_n) ->
    return (a.lid for a in [subj_n, pred_n, obj_n]).join(' ')

  get_or_create_Edge: (subj_n, obj_n, pred_n, cntx_n) ->
    edge_id = @make_Edge_id(subj_n, obj_n, pred_n)
    edge = @edges_by_id[edge_id]
    if not edge?
      @edge_count++
      edge = new Edge(subj_n, obj_n, pred_n)
      @edges_by_id[edge_id] = edge
    return edge

  add_edge: (edge) ->
    if edge.id.match(/Universal$/)
      console.log("add", edge.id)
    # TODO(smurp) should .links_from and .links_to be SortedSets? Yes. Right?
    @add_to(edge, edge.source.links_from)
    @add_to(edge, edge.target.links_to)
    edge

  delete_edge: (e) ->
    @remove_link(e.id)
    @remove_from(e, e.source.links_from)
    @remove_from(e, e.target.links_to)
    delete @edges_by_id[e.id]
    null

  try_to_set_node_type: (node, type_uri) ->
    type_lid = uniquer(type_uri) # should ensure uniqueness
    if not node._types
      node._types = []
    if not (type_lid in node._types)
      node._types.push(type_lid)
    prev_type = node.type
    node.type = type_lid
    if prev_type isnt type_lid
      @assign_types(node)

  report_every: 100 # if 1 then more data shown

  parseAndShowTTLData: (data, textStatus, callback) =>
    # modelled on parseAndShowNQStreamer
    #console.log("parseAndShowTTLData",data)
    parse_start_time = new Date()
    context = "http://universal.org"
    if GreenerTurtle? and @turtle_parser is 'GreenerTurtle'
      #console.log("GreenTurtle() started")
      #@G = new GreenerTurtle().parse(data, "text/turtle")
      try
        @G = new GreenerTurtle().parse(data, "text/turtle")
      catch e
        msg = escapeHtml(e.toString())
        blurt_msg = """<p>There has been a problem with the Turtle parser.  Check your dataset for errors.</p><p class="js_msg">#{msg}</p>"""
        blurt(blurt_msg, "error")
        return false
    quad_count = 0
    every = @report_every
    for subj_uri,frame of @G.subjects
      #console.log "frame:",frame
      #console.log frame.predicates
      for pred_id,pred of frame.predicates
        for obj in pred.objects
          # this is the right place to convert the ids (URIs) to CURIES
          #   Or should it be QNames?
          #      http://www.w3.org/TR/curie/#s_intro
          if every is 1
            @show_state_msg("<LI>#{frame.id} <LI>#{pred.id} <LI>#{obj.value}")
            console.log("===========================\n  #", quad_count, "  subj:", frame.id, "\n  pred:", pred.id, "\n  obj.value:", obj.value)
          else
            if quad_count % every is 0
              @show_state_msg("parsed relation: " + quad_count)
          quad_count++
          @add_quad
            s: frame.id
            p: pred.id
            o: obj # keys: type,value[,language]
            g: context
    @dump_stats()
    @after_file_loaded('stream', callback)

  dump_stats: ->
    console.log("object_value_types:", @object_value_types)
    console.log("unique_pids:", @unique_pids)

  parseAndShowTurtle: (data, textStatus) =>
    msg = "data was " + data.length + " bytes"
    parse_start_time = new Date()

    if GreenerTurtle? and @turtle_parser is 'GreenerTurtle'
      @G = new GreenerTurtle().parse(data, "text/turtle")
      console.log("GreenTurtle")

    else if @turtle_parser is 'N3'
      console.log("N3")
      #N3 = require('N3')
      console.log("n3", N3)
      predicates = {}
      parser = N3.Parser()
      parser.parse data, (err,trip,pref) =>
        console.log(trip)
        if pref
          console.log(pref)
        if trip
          @add_quad(trip)
        else
          console.log(err)

      #console.log "my_graph",@my_graph
      console.log('===================================')
      for prop_name in ['predicates','subjects','objects']
        prop_obj = @my_graph[prop_name]
        console.log prop_name,(key for key,value of prop_obj).length,prop_obj
      console.log('===================================')
      #console.log "Predicates",(key for key,value of my_graph.predicates).length,my_graph.predicates
      #console.log "Subjects",my_graph.subjects.length,my_graph.subjects
      #console.log "Objects",my_graph.objects.length,my_graph.objects

    parse_end_time = new Date()
    parse_time = (parse_end_time - parse_start_time) / 1000
    siz = @roughSizeOfObject(@G)
    msg += " resulting in a graph of " + siz + " bytes"
    msg += " which took " + parse_time + " seconds to parse"
    console.log(msg) if @verbosity >= @COARSE
    show_start_time = new Date()
    @showGraph(@G)
    show_end_time = new Date()
    show_time = (show_end_time - show_start_time) / 1000
    msg += " and " + show_time + " sec to show"
    console.log(msg) if @verbosity >= @COARSE
    @text_cursor.set_cursor("default")
    $("#status").text ""

  choose_everything: =>
    console.log "choose_everything()"
    cmd = new gcl.GraphCommand this,
      verbs: ['choose']
      classes: ['Thing']
    @gclc.run(cmd)
    #@gclui.push_command(cmd)
    @tick()

  remove_framing_quotes: (s) -> s.replace(/^\"/,"").replace(/\"$/,"")
  parseAndShowNQStreamer: (uri, callback) ->
    # turning a blob (data) into a stream
    #   http://stackoverflow.com/questions/4288759/asynchronous-for-cycle-in-javascript
    #   http://www.dustindiaz.com/async-method-queues/
    owl_type_map =
      uri:     RDF_object
      literal: RDF_literal
    worker = new Worker('/huviz/xhr_readlines_worker.js')
    quad_count = 0
    worker.addEventListener 'message', (e) =>
      msg = null
      if e.data.event is 'line'
        quad_count++
        @show_state_msg("<h3>Parsing... </h3><p>" + uri + "</p><progress value='" + quad_count + "' max='" + @node_count + "'></progress>")
        #if quad_count % 100 is 0
          #@show_state_msg("parsed relation " + quad_count)
        q = parseQuadLine(e.data.line)
        if q
          q.s = q.s.raw
          q.p = q.p.raw
          q.g = q.g.raw
          q.o =
            type:  owl_type_map[q.o.type]
            value: unescape_unicode(@remove_framing_quotes(q.o.toString()))
          @add_quad(q)
      else if e.data.event is 'start'
        msg = "starting to split " + uri
        @show_state_msg("<h3>Starting to split... </h3><p>" + uri + "</p>")
        @node_count = e.data.numLines
      else if e.data.event is 'finish'
        msg = "finished_splitting " + uri
        @show_state_msg("done loading")
        @after_file_loaded(uri, callback)
      else
        msg = "unrecognized NQ event:" + e.data.event
      if msg?
        blurt(msg)
    worker.postMessage({uri:uri})

  parse_and_show_NQ_file: (data, callback) =>
    #TODO There is currently no error catcing on local nq files
    owl_type_map =
      uri:     RDF_object
      literal: RDF_literal
    quad_count = 0
    allLines = data.split(/\r\n|\n/)
    for line in allLines
      quad_count++
      q = parseQuadLine(line)
      if q
        q.s = q.s.raw
        q.p = q.p.raw
        q.g = q.g.raw
        q.o =
          type:  owl_type_map[q.o.type]
          value: unescape_unicode(@remove_framing_quotes(q.o.toString()))
        @add_quad(q)
    @local_file_data = ""
    @after_file_loaded('local file', callback)

  DUMPER: (data) =>
    console.log(data)

  fetchAndShow: (url, callback) ->
    @show_state_msg("fetching " + url)
    the_parser = @parseAndShowNQ #++++Why does the parser default to NQ?
    if url.match(/.ttl/)
      the_parser = @parseAndShowTTLData # does not stream
    else if url.match(/.(nq|nt)/)
      the_parser = @parseAndShowNQ
    #else if url.match(/.json/) #Currently JSON files not supported at read_data_and_show
      #console.log "Fetch and show JSON File"
      #the_parser = @parseAndShowJSON
    else #File not valid
      #abort with message
      #NOTE This only catches URLs that do not have a valid file name; nothing about actual file format
      msg = "Could not load #{url}. The data file format is not supported! Only files with TTL and NQ extensions are accepted."
      @hide_state_msg()
      blurt(msg, 'error')
      $('#data_ontology_display').remove()
      @reset_dataset_ontology_loader()
      #@init_resource_menus()
      return

    if the_parser is @parseAndShowNQ
      @parseAndShowNQStreamer(url, callback)
      return

    $.ajax
      url: url
      success: (data, textStatus) =>
        the_parser(data, textStatus, callback)
        #@fire_fileloaded_event(url) ## should call after_file_loaded(url, callback) within the_parser
        @hide_state_msg()
      error: (jqxhr, textStatus, errorThrown) =>
        console.log(url, errorThrown)
        if not errorThrown
          errorThrown = "Cross-Origin error"
        msg = errorThrown + " while fetching " + url
        @hide_state_msg()
        $('#data_ontology_display').remove()
        blurt(msg, 'error')  # trigger this by goofing up one of the URIs in cwrc_data.json
        @reset_dataset_ontology_loader()
        #TODO Reset titles on page

  sparql_graph_query_and_show: (url, id, callback) =>
    qry = """
      SELECT ?g
      WHERE {
        GRAPH ?g { }
      }
    """
    ###
    Reference: https://www.w3.org/TR/sparql11-protocol/
    1. query via GET
    2. query via URL-encoded POST
    3. query via POST directly -- Query String Parameters: default-graph-uri (0 or more); named-graph-uri (0 or more)
                               -- Request Content Type: application/sparql-query
                               -- Request Message Body: Unencoded SPARQL query string
    ###
    # These POST settings work for: CWRC, WWI open, on DBpedia, and Open U.K. but not on Bio Database
    ajax_settings = { #TODO Currently this only works on CWRC Endpoint
      'type': 'GET'
      'url': url + '?query=' + encodeURIComponent(qry)
      'headers' :
        #'Content-Type': 'application/sparql-query'  # This is only required for CWRC - not accepted by some Endpoints
        'Accept': 'application/sparql-results+json'
    }
    if url is "http://sparql.cwrc.ca/sparql" # Hack to make CWRC setup work properly
      ajax_settings.headers =
        'Content-Type' : 'application/sparql-query'
        'Accept': 'application/sparql-results+json'
    # These POST settings work for: CWRC and WWI open, but not on DBpedia and Open U.K.
    ###
    ajax_settings = {
      'type': 'POST'
      'url': url
      'data': qry
      'headers' :
        'Content-Type': 'application/sparql-query'
        'Accept': 'application/sparql-results+json; q=1.0, application/sparql-query, q=0.8'
    }
    ###
    ###
    ajax_settings = {
      'type': 'GET'
      'data': ''
      'url': url + '?query=' + encodeURIComponent(qry)
      'headers' :
        #'Accept': 'application/sparql-results+json'
        'Content-Type': 'application/x-www-form-urlencoded'
        'Accept': 'application/sparql-results+json; q=1.0, application/sparql-query, q=0.8'
    }
    ###
    #littleTestQuery = """SELECT * WHERE {?s ?o ?p} LIMIT 1"""
    ###
    $.ajax
      method: 'GET'
      url: url + '?query=' + encodeURIComponent(littleTestQuery)
      headers:
        'Accept': 'application/sparql-results+json'
      success: (data, textStatus, jqXHR) =>
        console.log "This a little repsponse test: " + textStatus
        console.log jqXHR
        console.log jqXHR.getAllResponseHeaders(data)
        console.log data
      error: (jqxhr, textStatus, errorThrown) =>
        console.log(url, errorThrown)
        console.log jqXHR.getAllResponseHeaders(data)
    ###
    ###
    # This is a quick test of the SPARQL Endpoint it should return https://www.w3.org/TR/2013/REC-sparql11-service-description-20130321/#example-turtle
    $.ajax
      method: 'GET'
      url: url
      headers:
        'Accept': 'text/turtle'
      success: (data, textStatus, jqXHR) =>
        console.log "This Enpoint Test: " + textStatus
        console.log jqXHR
        console.log jqXHR.getAllResponseHeaders(data)
        console.log data
      error: (jqxhr, textStatus, errorThrown) =>
        console.log(url, errorThrown)
        console.log jqXHR.getAllResponseHeaders(data)
    ###
    graphSelector = "#sparqlGraphOptions-#{id}"
    $(graphSelector).parent().css('display', 'none')
    $('#sparqlQryInput').css('display', 'none')
    spinner = $("#sparqlGraphSpinner-#{id}")
    spinner.css('display','block')
    $.ajax
        type: ajax_settings.type
        url: ajax_settings.url
        headers: ajax_settings.headers
        success: (data, textStatus, jqXHR) =>
          json_check = typeof data
          if json_check is 'string' then json_data = JSON.parse(data) else json_data = data
          results = json_data.results.bindings
          graphsNotFound = jQuery.isEmptyObject(results[0])
          if graphsNotFound
            $(graphSelector).parent().css('display', 'none')
            @reset_endpoint_form(true)
            return
          graph_options = "<option id='#{unique_id()}' value='#{url}'> All Graphs </option>"
          for graph in results
            graph_options = graph_options + "<option id='#{unique_id()}' value='#{graph.g.value}'>#{graph.g.value}</option>"
          $("#sparqlGraphOptions-#{id}").html(graph_options)
          $(graphSelector).parent().css('display', 'block')
          @reset_endpoint_form(true)

        error: (jqxhr, textStatus, errorThrown) =>
          console.log(url, errorThrown)
          console.log jqXHR.getAllResponseHeaders(data)
          $(graphSelector).parent().css('display', 'none')
          if not errorThrown
            errorThrown = "Cross-Origin error"
          msg = errorThrown + " while fetching " + url
          @hide_state_msg()
          $('#data_ontology_display').remove()
          blurt(msg, 'error')  # trigger this by goofing up one of the URIs in cwrc_data.json
          @reset_dataset_ontology_loader()
          spinner.css('visibility','hidden')


  load_endpoint_data_and_show: (subject, callback) ->
    @sparql_node_list = []
    @pfm_count('sparql')
    #if @p_display then @performance_dashboard('sparql_request')
    node_limit = $('#endpoint_limit').val()
    url = @endpoint_loader.value
    @endpoint_loader.outstanding_requests = 0
    fromGraph = ''

    if @endpoint_loader.endpoint_graph then fromGraph=" FROM <#{@endpoint_loader.endpoint_graph}> "
    ###
    qry = """
    SELECT * #{fromGraph}
    WHERE {
    {<#{subject}> ?p ?o} UNION
    {{<#{subject}> ?p ?o} . {?o ?p2 ?o2 . FILTER(?o != <#{subject}>)}}
    }
    LIMIT #{node_limit}
    """
    ###
    ###
    qry = """
    SELECT * #{fromGraph}
    WHERE {
    {<#{subject}> ?p ?o}
    UNION
    {{<#{subject}> ?p ?o} . {?o ?p2 ?o2 . FILTER(?o != <#{subject}>)}}
    UNION
    { ?s ?p <#{subject}>}
    }
    LIMIT #{node_limit}
    """
    ###
    qry = """
    SELECT * #{fromGraph}
    WHERE {
      {<#{subject}> ?p ?o}
      UNION
      {{<#{subject}> ?p ?o} . {?o ?p2 ?o2}}
    UNION
      {{?s3 ?p3 <#{subject}>} . {?s3 ?p4 ?o4 }}
    }
    LIMIT #{node_limit}
    """

    ajax_settings = {
      'method': 'GET'#'POST'
      'url': url + '?query=' + encodeURIComponent(qry)
      'headers' :
        'Accept': 'application/sparql-results+json; q=1.0, application/sparql-query, q=0.8'
    }
    if url is "http://sparql.cwrc.ca/sparql" # Hack to make CWRC setup work properly
      ajax_settings.headers =
        'Content-Type' : 'application/sparql-query'
        'Accept': 'application/sparql-results+json'
    ###
    ajax_settings = {
      'method': 'POST'
      'url': url #+ '?query=' + encodeURIComponent(qry)
      'data': qry
      'headers' :
        'Content-Type': 'application/sparql-query'
        'Accept': 'application/sparql-results+json; q=1.0, application/sparql-query, q=0.8'
    }
    ###
    #console.log "URL: " + url + "  Graph: " + fromGraph + "  Subject: " + subject
    #console.log qry
    $.ajax
        method: ajax_settings.method
        url: ajax_settings.url
        headers: ajax_settings.headers
        success: (data, textStatus, jqXHR) =>
          #console.log jqXHR
          #console.log data
          json_check = typeof data
          if json_check is 'string' then json_data = JSON.parse(data) else json_data = data
          @add_nodes_from_SPARQL(json_data, subject)
          endpoint = @endpoint_loader.value
          @dataset_loader.disable()
          @ontology_loader.disable()
          @replace_loader_display_for_endpoint(endpoint, @endpoint_loader.endpoint_graph)
          disable = true
          @update_go_button(disable)
          @big_go_button.hide()
          @after_file_loaded('sparql', callback)
        error: (jqxhr, textStatus, errorThrown) =>
          console.log(url, errorThrown)
          console.log jqXHR.getAllResponseHeaders(data)
          if not errorThrown
            errorThrown = "Cross-Origin error"
          msg = errorThrown + " while fetching " + url
          @hide_state_msg()
          $('#data_ontology_display').remove()
          blurt(msg, 'error')  # trigger this by goofing up one of the URIs in cwrc_data.json
          @reset_dataset_ontology_loader()



  load_new_endpoint_data_and_show: (subject, callback) -> # DEPRECIATED !!!!
    node_limit = $('#endpoint_limit').val()
    @p_total_sprql_requests++
    note = ''
    url = @endpoint_loader.value
    fromGraph = ''
    if @endpoint_loader.endpoint_graph then fromGraph = " FROM <#{@endpoint_loader.endpoint_graph}> "
    qry = """
    SELECT * #{fromGraph}
    WHERE {
    {<#{subject}> ?p ?o}
    UNION
    {{<#{subject}> ?p ?o} . {?o ?p2 ?o2}}
    UNION
    {{?s3 ?p3 <#{subject}>} . {?s3 ?p4 ?o4 }}
    }
    LIMIT #{node_limit}
    """
    ajax_settings = {
      'method': 'GET'#'POST'
      'url': url + '?query=' + encodeURIComponent(qry)
      'headers' :
        'Accept': 'application/sparql-results+json; q=1.0, application/sparql-query, q=0.8'
    }
    if url is "http://sparql.cwrc.ca/sparql" # Hack to make CWRC setup work properly
      ajax_settings.headers =
        'Content-Type' : 'application/sparql-query'
        'Accept': 'application/sparql-results+json'
    $.ajax
        method: ajax_settings.method
        url: ajax_settings.url
        headers: ajax_settings.headers
        success: (data, textStatus, jqXHR) =>
          #console.log jqXHR
          #console.log "Query: " + subject
          note = subject
          if @p_display then @performance_dashboard('sparql_request', note)
          #console.log qry
          json_check = typeof data
          if json_check is 'string' then json_data = JSON.parse(data) else json_data = data
          #console.log "Json Array Size: " + json_data.results.bindings.length
          @add_nodes_from_SPARQL(json_data, subject)
          @shelved_set.resort()
          @tick()
          @update_all_counts()
          @endpoint_loader.outstanding_requests = @endpoint_loader.outstanding_requests - 1
          #console.log "Finished request: count now " + @endpoint_loader.outstanding_requests
        error: (jqxhr, textStatus, errorThrown) =>
          console.log(url, errorThrown)
          console.log jqXHR.getAllResponseHeaders(data)
          if not errorThrown
            errorThrown = "Cross-Origin error"
          msg = errorThrown + " while fetching " + url
          @hide_state_msg()
          $('#data_ontology_display').remove()
          blurt(msg, 'error')  # trigger this by goofing up one of the URIs in cwrc_data.json
          @reset_dataset_ontology_loader()

  add_nodes_from_SPARQL: (json_data, subject) -> # DEPRECIATED !!!!
    data = ''
    context = "http://universal.org"
    plainLiteral = "http://www.w3.org/1999/02/22-rdf-syntax-ns#PlainLiteral"
    #console.log json_data
    console.log "Adding node (i.e. fully exploring): " + subject
    nodes_in_data = json_data.results.bindings
    for node in nodes_in_data
      language = ''
      obj_type = "http://www.w3.org/1999/02/22-rdf-syntax-ns#object"
      if node.s
        subj = node.s.value
        pred = node.p.value
        obj_val = subject
      else if node.o2
        subj = node.o.value
        pred = node.p2.value
        obj_val = node.o2.value
        if node.o2.type is 'literal' or node.o.type is 'typed-literal'
          if node.o2.datatype
            obj_type = node.o2.datatype
          else
            obj_type = plainLiteral
          if node.o2["xml:lang"]
            language = node.o2['xml:lang']
        #console.log "-------- Sub-node -----" + subj + " " + pred  + " " + obj_val + " " + obj_type
      else if node.s3
        subj = node.s3.value
        pred = node.p4.value
        obj_val = node.o4.value
        if node.o4.type is 'literal' or node.o4.type is 'typed-literal'
          if node.o4.datatype
            obj_type = node.o4.datatype
          else
            obj_type = plainLiteral
          if node.o4["xml:lang"]
            language = node.o4['xml:lang']
      else
        subj = subject
        pred = node.p.value
        obj_val = node.o.value
        if node.o.type is 'literal' or node.o.type is 'typed-literal'
          if node.o.datatype
            obj_type = node.o.datatype
          else
            obj_type = plainLiteral
          if node.o["xml:lang"]
            language = node.o['xml:lang']
      q =
        g: context
        s: subj
        p: pred
        o:
          type: obj_type
          value: obj_val
      if language
        q.o.language = language

      #console.log q
      #IF this is a new quad, then add it. Otherwise no.
      node_list_empty = @sparql_node_list.length
      if node_list_empty is 0 # Add first node (because list is empty)
        @sparql_node_list.push q
        node_not_in_list = true
      else
        # Check if node is in list - sparql_node_list is used to keep track of nodes that have already been
        # loaded by a query so that they will not be added again through add_quad.
        for snode in @sparql_node_list
          #TODO - This filtering statement doesn't seem tight (Will not catch nodes that HuViz creates - that's okay I think)
          if q.s is snode.s and q.p is snode.p and q.o.value is snode.o.value and q.o.type is snode.o.type and q.o.language is snode.o.language
            node_not_in_list = false
            #console.log "Found it in list so will not send to add_quad"
            if snode.s is subject or snode.o.value is subject#IF node is subject node IS already in list BUT fullly_loaded is false then set to true
              for a_node, i in @all_set
                if a_node.id is subject
                   @all_set[i].fully_loaded = true
                   #console.log "Found node for #{subject} so making it fully_loaded"
            #else if snode.o.value is subject
              #for a_node, i in @all_set
                #console.log "compare: " + a_node.id + "   subject: " + subject
                #if a_node.id is subject
                   #@all_set[i].fully_loaded = true
                   #console.log "Found object node for #{subject} which should be fully_loaded"
            break
          else
            node_not_in_list = true
      #If node is not in list then add
      if node_not_in_list
        @sparql_node_list.push q
        node_not_in_list = false
        @add_quad(q, subject)
      #@dump_stats()

  add_nodes_from_SPARQL_Worker : (queryTarget) ->
    console.log "Make request for new query and load nodes"
    @pfm_count('sparql')
    url = @endpoint_loader.value
    if @sparql_node_list then previous_nodes = @sparql_node_list else previous_nodes = []
    graph = @endpoint_loader.endpoint_graph
    local_node_added = 0
    query_limit = 1000 #$('#endpoint_limit').val()
    worker = new Worker('/huviz/sparql_ajax_query.js')
    worker.addEventListener 'message', (e) =>
      #console.log e.data
      add_fully_loaded = e.data.fully_loaded_index
      for quad in e.data.results
        #console.log quad
        @add_quad(quad)
        @sparql_node_list.push quad  # Add the new quads to the official list of added quads
        local_node_added++
      console.log "Node Added Count: " + local_node_added
      # Verify through the loaded nodes that they are all properly marked as fully_loaded
      for a_node, i in @all_set
        if a_node.id is queryTarget
          @all_set[i].fully_loaded = true
      @endpoint_loader.outstanding_requests = @endpoint_loader.outstanding_requests - 1
      console.log "Resort the shelf"
      @shelved_set.resort()
      @tick()
      @update_all_counts()
    worker.postMessage({target:queryTarget, url:url, graph:graph, limit:query_limit, previous_nodes:previous_nodes})


  # Deal with buggy situations where flashing the links on and off
  # fixes data structures.  Not currently needed.
  show_and_hide_links_from_node: (d) ->
    @show_links_from_node d
    @hide_links_from_node d

  get_container_width: (pad) ->
    pad = pad or hpad
    w_width = (@container.clientWidth or window.innerWidth or document.documentElement.clientWidth or document.clientWidth) - pad
    @width = w_width - $("#tabs").width()

  # Should be refactored to be get_container_height
  get_container_height: (pad) ->
    pad = pad or hpad
    @height = (@container.clientHeight or window.innerHeight or document.documentElement.clientHeight or document.clientHeight) - pad
    #console.log "get_window_height()",window.innerHeight,document.documentElement.clientHeight,document.clientHeight,"==>",@height

  update_graph_radius: ->
    @graph_region_radius = Math.floor(Math.min(@width / 2, @height / 2))
    @graph_radius = @graph_region_radius * @shelf_radius

  update_graph_center: ->
    @cy = @height / 2
    if @off_center
      @cx = @width - @graph_region_radius
    else
      @cx = @width / 2
    @my = @cy * 2
    @mx = @cx * 2

  update_lariat_zone: ->
    @lariat_center = [@cx, @cy]

  update_discard_zone: ->
    @discard_ratio = .1
    @discard_radius = @graph_radius * @discard_ratio
    @discard_center = [
      @width - @discard_radius * 3
      @height - @discard_radius * 3
    ]

  set_search_regex: (text) ->
    @search_regex = new RegExp(text or "^$", "ig")

  update_searchterm: =>
    text = $(this).text()
    @set_search_regex text
    @restart()

  dump_locations: (srch, verbose, func) ->
    verbose = verbose or false
    pattern = new RegExp(srch, "ig")
    nodes.forEach (node, i) =>
      unless node.name.match(pattern)
        console.log(pattern, "does not match!", node.name) if verbose
        return
      console.log(func.call(node))  if func
      @dump_details(node) if not func or verbose

  get_node_by_id: (node_id, throw_on_fail) ->
    throw_on_fail = throw_on_fail or false
    obj = @nodes.get_by('id',node_id)
    if not obj? and throw_on_fail
      throw new Error("node with id <" + node_id + "> not found")
    obj

  update_showing_links: (n) ->
    # TODO understand why this is like {Taxon,Predicate}.update_state
    #   Is this even needed anymore?
    old_status = n.showing_links
    if n.links_shown.length is 0
      n.showing_links = "none"
    else
      if n.links_from.length + n.links_to.length > n.links_shown.length
        n.showing_links = "some"
      else
        n.showing_links = "all"
    if old_status is n.showing_links
      return null # no change, so null
    # We return true to mean that edges where shown, so
    return old_status is "none" or n.showing_links is "all"

  should_show_link: (edge) ->
    # Edges should not be shown if either source or target are discarded or embryonic.
    ss = edge.source.state
    ts = edge.target.state
    d = @discarded_set
    e = @embryonic_set
    not (ss is d or ts is d or ss is e or ts is e)

  add_link: (e) ->
    @add_to e, e.source.links_from
    @add_to e, e.target.links_to
    if @should_show_link(e)
      @show_link(e)
    @update_showing_links e.source
    @update_showing_links e.target
    @update_state e.target

  remove_link: (edge_id) ->
    e = @links_set.get_by('id', edge_id)
    if not e?
      console.log("remove_link(#{edge_id}) not found!")
      return
    @remove_from(e, e.source.links_shown)
    @remove_from(e, e.target.links_shown)
    @links_set.remove(e)
    console.log("removing links from: " + e.id)
    @update_showing_links(e.source)
    @update_showing_links(e.target)
    @update_state(e.target)
    @update_state(e.source)

  # FIXME it looks like incl_discards is not needed and could be removed
  show_link: (edge, incl_discards) ->
    if (not incl_discards) and (edge.target.state is @discarded_set or edge.source.state is @discarded_set)
      return
    @add_to(edge, edge.source.links_shown)
    @add_to(edge, edge.target.links_shown)
    @links_set.add(edge)
    edge.show()
    @update_state(edge.source)
    @update_state(edge.target)
    #@gclui.add_shown(edge.predicate.lid,edge)

  unshow_link: (edge) ->
    @remove_from(edge,edge.source.links_shown)
    @remove_from(edge,edge.target.links_shown)
    @links_set.remove(edge)
    console.log("unshowing links from: " + edge.id)
    edge.unshow() # FIXME make unshow call @update_state WHICH ONE? :)
    @update_state(edge.source)
    @update_state(edge.target)
    #@gclui.remove_shown(edge.predicate.lid,edge)

  show_links_to_node: (n, incl_discards) ->
    incl_discards = incl_discards or false
    #if not n.links_to_found
    #  @find_links_to_node n,incl_discards
    n.links_to.forEach (e, i) =>
      @show_link(e, incl_discards)
    @update_showing_links(n)
    @update_state(n)
    @force.links(@links_set)
    @restart()

  update_state: (node) ->
    if node.state is @graphed_set and node.links_shown.length is 0
      @shelved_set.acquire(node)
      @unpin(node)
      #console.debug("update_state() had to @shelved_set.acquire(#{node.name})",node)
    if node.state isnt @graphed_set and node.links_shown.length > 0
      #console.debug("update_state() had to @graphed_set.acquire(#{node.name})",node)
      @graphed_set.acquire(node)

  hide_links_to_node: (n) ->
    n.links_to.forEach (e, i) =>
      @remove_from e, n.links_shown
      @remove_from e, e.source.links_shown
      e.unshow()
      @links_set.remove e
      @remove_ghosts e
      @update_state e.source
      @update_showing_links e.source
      @update_showing_links e.target
    @update_state n
    @force.links @links_set
    @restart()

  show_links_from_node: (n, incl_discards) ->
    incl_discards = incl_discards or false
    #if not n.links_from_found
    #  @find_links_from_node n
    n.links_from.forEach (e, i) =>
      @show_link(e, incl_discards)
    @update_state(n)
    @force.links(@links_set)
    @restart()

  hide_links_from_node: (n) ->
    n.links_from.forEach (e, i) =>
      @remove_from e, n.links_shown
      @remove_from e, e.target.links_shown
      e.unshow()
      @links_set.remove e
      @remove_ghosts e
      @update_state e.target
      @update_showing_links e.source
      @update_showing_links e.target

    @force.links @links_set
    @restart()

  attach_predicate_to_its_parent: (a_pred) ->
    parent_id = @ontology.subPropertyOf[a_pred.lid] or 'anything'
    if parent_id?
      parent_pred = @get_or_create_predicate_by_id(parent_id)
      a_pred.register_superclass(parent_pred)
    return

  get_or_create_predicate_by_id: (sid) ->
    obj_id = @make_qname(sid)
    obj_n = @predicate_set.get_by('id',obj_id)
    if not obj_n?
      obj_n = new Predicate(obj_id)
      @predicate_set.add(obj_n)
      @attach_predicate_to_its_parent(obj_n)
    obj_n

  clean_up_dirty_predicates: =>
    pred = @predicate_set.get_by('id', 'anything')
    if pred?
      pred.clean_up_dirt()

  clean_up_dirty_taxons: ->
    if @taxonomy.Thing?
      @taxonomy.Thing.clean_up_dirt()

  clean_up_all_dirt_once: ->
    @clean_up_all_dirt_onceRunner ?= new OnceRunner(0, 'clean_up_all_dirt_once')
    @clean_up_all_dirt_onceRunner.setTimeout(@clean_up_all_dirt, 300)

  clean_up_all_dirt: =>
    #console.warn("clean_up_all_dirt()")
    @clean_up_dirty_taxons()
    @clean_up_dirty_predicates()
    #@regenerate_english()
    #setTimeout(@clean_up_dirty_predictes, 500)
    #setTimeout(@clean_up_dirty_predictes, 3000)
    return

  prove_OnceRunner: (timeout) ->
    @prove_OnceRunner_inst ?= new OnceRunner(30)
    yahoo = () -> alert('yahoo!')
    @prove_OnceRunner_inst.setTimeout(yahoo, timeout)

  get_or_create_context_by_id: (sid) ->
    obj_id = @make_qname(sid)
    obj_n = @context_set.get_by('id',obj_id)
    if not obj_n?
      obj_n = {id:obj_id}
      @context_set.add(obj_n)
    obj_n

  get_or_create_node_by_id: (uri, name, isLiteral) ->
    # FIXME OMG must standardize on .lid as the short local id, ie internal id
    #node_id = @make_qname(uri) # REVIEW: what about uri: ":" ie the current graph
    node_id = uri
    node = @nodes.get_by('id', node_id)
    if not node?
      node = @embryonic_set.get_by('id',node_id)
    if not node?
      # at this point the node is embryonic, all we know is its uri!
      node = new Node(node_id, @use_lid_as_node_name)
      if isLiteral?
        node.isLiteral = isLiteral
      if not node.id?
        alert("new Node('#{uri}') has no id")
      #@nodes.add(node)
      @embryonic_set.add(node)
    node.type ?= "Thing"
    node.lid ?= uniquer(node.id)
    if not node.name?
      # FIXME dereferencing of @ontology.label should be by curie, not lid
      name = name or @ontology.label[node.lid]
      # null name this will cause a made-up name to be applied
      @set_name(node, name)
    return node

  develop: (node) ->
    # If the node is embryonic and is ready to hatch, then hatch it.
    # In other words if the node is now complete enough to do interesting
    # things with, then let it join the company of other complete nodes.
    if node.embryo? and @is_ready(node)
      @hatch(node)
      return true
    return false

  hatch: (node) ->
    # Take a node from being 'embryonic' to being a fully graphable node
    #console.log node.id+" "+node.name+" is being hatched!"
    node.lid = uniquer(node.id) # FIXME ensure uniqueness
    @embryonic_set.remove(node)
    new_set = @get_default_set_by_type(node)
    if new_set?
      new_set.acquire(node)
    @assign_types(node,"hatch")
    start_point = [@cx, @cy]
    node.point(start_point)
    node.prev_point([start_point[0]*1.01,start_point[1]*1.01])
    @add_node_ghosts(node)
    @update_showing_links(node)
    @nodes.add(node)
    @recolor_node(node)
    @tick()
    @pfm_count('hatch')
    node

  # TODO: remove this method
  get_or_create_node: (subject, start_point, linked) ->
    linked = false
    @get_or_make_node subject,start_point,linked

  # TODO: remove this method
  make_nodes: (g, limit) ->
    limit = limit or 0
    count = 0
    for subj_uri,subj of g.subjects #my_graph.subjects
      #console.log subj, g.subjects[subj]  if @verbosity >= @DEBUG
      #console.log subj_uri
      #continue  unless subj.match(ids_to_show)
      subject = subj #g.subjects[subj]
      @get_or_make_node subject, [
        @width / 2
        @height / 2
      ], false
      count++
      break  if limit and count >= limit

  make_links: (g, limit) ->
    limit = limit or 0
    @nodes.some (node, i) =>
      subj = node.s
      @show_links_from_node @nodes[i]
      true  if (limit > 0) and (@links_set.length >= limit)
    @restart()

  hide_node_links: (node) ->
    node.links_shown.forEach (e, i) =>
      @links_set.remove(e)
      if e.target is node
        @remove_from(e, e.source.links_shown)
        @update_state(e.source)
        e.unshow()
        @update_showing_links(e.source)
      else
        @remove_from(e, e.target.links_shown)
        @update_state(e.target)
        e.unshow()
        @update_showing_links(e.target)
      @remove_ghosts(e)

    node.links_shown = []
    @update_state(node)
    @update_showing_links(node)

  hide_found_links: ->
    @nodes.forEach (node, i) =>
      if node.name.match(search_regex)
        @hide_node_links(node)
    @restart()

  discard_found_nodes: ->
    @nodes.forEach (node, i) =>
      @discard node  if node.name.match(search_regex)
    @restart()

  show_node_links: (node) ->
    @show_links_from_node(node)
    @show_links_to_node(node)
    @update_showing_links(node)

  toggle_display_tech: (ctrl, tech) ->
    val = undefined
    tech = ctrl.parentNode.id
    if tech is "use_canvas"
      @use_canvas = not @use_canvas
      @clear_canvas()  unless @use_canvas
      val = @use_canvas
    if tech is "use_svg"
      @use_svg = not @use_svg
      val = @use_svg
    if tech is "use_webgl"
      @use_webgl = not @use_webgl
      val = @use_webgl
    ctrl.checked = val
    @tick()
    true

  label: (branded) ->
    @labelled_set.add(branded)
    #@tick()
    return

  unlabel: (anonymized) ->
    @labelled_set.remove(anonymized)
    #@tick()
    return

  get_point_from_polar_coords: (polar) ->
    {range, degrees} = polar
    radians = 2 * Math.PI * (degrees - 90) / 360
    return [@cx + range * Math.cos(radians) * @graph_region_radius,
            @cy + range * Math.sin(radians) * @graph_region_radius]

  pin: (node, cmd) ->
    if node.state is @graphed_set
      if cmd? and cmd.polar_coords
        pin_point = @get_point_from_polar_coords(cmd.polar_coords)
        node.prev_point(pin_point)
      @pinned_set.add(node)
      return true
    return false

  unpin: (node) ->
    if node.fixed
      @pinned_set.remove(node)
      return true
    return false

  unlink: (unlinkee) ->
    # FIXME discover whether unlink is still needed
    @hide_links_from_node(unlinkee)
    @hide_links_to_node(unlinkee)
    @shelved_set.acquire(unlinkee)
    @update_showing_links(unlinkee)
    @update_state(unlinkee)

  #
  #  The DISCARDED are those nodes which the user has
  #  explicitly asked to not have drawn into the graph.
  #  The user expresses this by dropping them in the
  #  discard_dropzone.
  #
  discard: (goner) ->
    @unpin(goner)
    @unlink(goner)
    @discarded_set.acquire(goner)
    shown = @update_showing_links(goner)
    @unselect(goner)
    #@update_state(goner)
    goner

  undiscard: (prodigal) ->  # TODO(smurp) rename command to 'retrieve' ????
    if @discarded_set.has(prodigal) # see test 'retrieving should only affect nodes which are discarded'
      @shelved_set.acquire(prodigal)
      @update_showing_links(prodigal)
      @update_state(prodigal)
    prodigal

  #
  #  The CHOSEN are those nodes which the user has
  #  explicitly asked to have the links shown for.
  #  This is different from those nodes which find themselves
  #  linked into the graph because another node has been chosen.
  #
  shelve: (goner) =>
    @unpin(goner)
    @chosen_set.remove(goner)
    @hide_node_links(goner)
    @shelved_set.acquire(goner)
    shownness = @update_showing_links(goner)
    if goner.links_shown.length > 0
      console.log("shelving failed for", goner)
    goner

  choose: (chosen) =>
    # If this chosen node is part of a SPARQL query set, then check if it is fully loaded
    # if it isn't then load and activate
    #console.log chosen
    if @endpoint_loader.value # This is part of a sparql set
      if not chosen.fully_loaded
        #console.log "Time to make a new SPARQL query using: " + chosen.id + " - requests underway: " + @endpoint_loader.outstanding_requests
        # If there are more than certain number of requests, stop the process

        if (@endpoint_loader.outstanding_requests < 10)
          #@endpoint_loader.outstanding_requests = @endpoint_loader.outstanding_requests + 1
          @endpoint_loader.outstanding_requests++
          #console.log "Less than 6 so go ahead " + message
          #@load_new_endpoint_data_and_show(chosen.id)
          # TEST of calling Worker for Ajax
          @add_nodes_from_SPARQL_Worker(chosen.id)
          console.log "Request counter: " + @endpoint_loader.outstanding_requests

        else
          if $("#blurtbox").html()
            #console.log "Don't add error message " + message
            console.log "Request counter (over): " + @endpoint_loader.outstanding_requests
          else
            #console.log "Error message " + message
            msg = "There are more than 300 requests in the que. Restricting process. " + message
            blurt(msg, 'alert')
            message = true
            console.log "Request counter: " + @endpoint_loader.outstanding_requests

    # There is a flag .chosen in addition to the state 'linked'
    # because linked means it is in the graph
    @chosen_set.add(chosen)
    @nowChosen_set.add(chosen)
    @graphed_set.acquire(chosen) # do it early so add_link shows them otherwise choosing from discards just puts them on the shelf
    @show_links_from_node(chosen)
    @show_links_to_node(chosen)
    ### TODO remove this cruft
    if chosen.links_shown
      @graphed_set.acquire(chosen)  # FIXME this duplication (see above) is fishy
      chosen.showing_links = "all"
    else
      # FIXME after this weird side effect, at the least we should not go on
      console.error(chosen.lid,
          "was found to have no links_shown so: @unlink_set.acquire(chosen)", chosen)
      @shelved_set.acquire(chosen)
    ###
    @update_state(chosen)
    shownness = @update_showing_links(chosen)
    chosen

  unchoose: (unchosen) =>
    # To unchoose a node is to remove the chosen flag and unshow the edges
    # to any nodes which are not themselves chosen.  If that means that
    # this 'unchosen' node is now no longer graphed, so be it.
    #
    #   remove the node from the chosen set
    #     loop thru all links_shown
    #       if neither end of the link is chosen then
    #         unshow the link
    # @unpin unchosen # TODO figure out why this does not cleanse pin
    @chosen_set.remove(unchosen)
    for link in unchosen.links_shown by -1
      if link?
        if not (link.target.chosen? or link.source.chosen?)
          @unshow_link(link)
      else
        console.log("there is a null in the .links_shown of", unchosen)
    @update_state(unchosen)

  wander__atFirst: =>
    # Purpose:
    #   At first, before the verb Wander is executed on any node, we must
    # build a SortedSet of the nodes which were wasChosen to compare
    # with the SortedSet of nodes which are intendedToBeGraphed as a
    # result of the Wander command which is being executed.
    if not @wasChosen_set.clear()
      throw new Error("expecting wasChosen to be empty")
    for node in @chosen_set
      @wasChosen_set.add(node)

  wander__atLast: =>
    # Purpose:
    #   At last, after all appropriate nodes have been pulled into the graph
    # by the Wander verb, it is time to remove wasChosen nodes which
    # are not nowChosen.  In other words, ungraph those nodes which
    # are no longer held in the graph by any recently wandered-to nodes.
    wasRollCall = @wasChosen_set.roll_call()
    nowRollCall = @nowChosen_set.roll_call()
    removed = @wasChosen_set.filter (node) =>
      not @nowChosen_set.includes(node)
    for node in removed
      @unchoose(node)
      @wasChosen_set.remove(node)
    if not @nowChosen_set.clear()
      throw new Error("the nowChosen_set should be empty after clear()")

  wander: (chosen) =>
    # Wander is just the same as Choose (AKA Activate) except afterward it deactivates the
    # nodes which were in the chosen_set before but are not in the set being wandered.
    # This is accomplished by wander__build_callback()
    return @choose(chosen)

  walk__atFirst: =>
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Purpose:
    #   At first, before the verb Walk is executed on any node, we must
    # build a SortedSet of the nodes which were wasChosen to compare
    # with the SortedSet of nodes which are intendedToBeGraphed as a
    # result of the Walk command which is being executed.
    if not @wasChosen_set.clear()
      throw new Error("expecting wasChosen to be empty")
    for node in @chosen_set
      @wasChosen_set.add(node)

  walk__atLast: =>
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Purpose:
    # At last, after all appropriate nodes have been pulled into the graph
    # by the Walk verb, it is time to remove wasChosen nodes which
    # are not nowChosen.  In other words, ungraph those nodes which
    # are no longer held in the graph by any recently walked-to nodes.
    wasRollCall = @wasChosen_set.roll_call()
    nowRollCall = @nowChosen_set.roll_call()

    if @focused_node #TODO This is trying to catch situations where nodes are selected and then Walked
      current_selection = @focused_node
    else if @selected_set[0]
      current_selection = @selected_set[0]
    else
      current_selection = @chosen_set[0]
    valid_path_nodes = []
    active_nodes = []
    if not @prune_walk_nodes then @prune_walk_nodes = $("#prune_walk_nodes :selected").val()
    # If current_selection is already in @walk_path_set, then delete those that may appear after it (i.e. erase path)
    #console.log "The mode setting is #{@prune_walk_nodes}"
    #console.log @walk_path_set
    #console.log "Current selection is " + current_selection.lid
    for nodeId, i in @walk_path_set
      #console.log i
      #console.log "looking at " + nodeId + " and #{current_selection.lid}"
      if nodeId is current_selection.lid
        #console.log "Slice of after #{nodeId} at position #{i}"
        new_path = @walk_path_set.slice(0,i)
        #console.log new_path
        @walk_path_set = new_path


    #if @walk_path_set.length is 0 then @walk_path_set.push nowRollCall #first time through, walked node should always be added to path
    for node in @all_set
      for lid in @walk_path_set
        if node.lid is lid #get edges
          active_nodes.push node
          for e in node.links_from
            valid_path_nodes.push e.target.lid
          for e in node.links_to
            valid_path_nodes.push e.source.lid
    for node_lid in valid_path_nodes #check to see if this is a connected node or new unconnect node
      if current_selection.lid is node_lid then connected_path = true
    # If node is along a continuous path, then add the selection; if not then reset everything and start a new path
    if connected_path
      @walk_path_set.push current_selection.lid
      #@walk_path_set.sort()
      connected_path = false
      # Prune associated tangential nodes on path (i.e. keep only current_selection edges)
      if @prune_walk_nodes is "directional_path" or @prune_walk_nodes is "pruned_path"
        ungraphed = []
        keep_graphed = []
        for node in active_nodes
          keep_graphed.push node
          for edge in current_selection.links_shown
            if edge.source.lid isnt node.lid then keep_graphed.push edge.source
            if edge.target.lid isnt node.lid then keep_graphed.push edge.target

        unique_keep = Array.from(new Set(keep_graphed))
        remove_list = []
        for graphed_node in @graphed_set
          remove = false
          for keep_node in unique_keep
            if graphed_node.lid is keep_node.lid
              #console.log "keep #{graphed_node.lid}"
              remove = false
              break
            else
              #console.log "remove #{graphed_node.lid}"
              remove = true
          if remove
            remove_list.push graphed_node

        unique_remove = Array.from(new Set(remove_list))
        for node in remove_list
          @chosen_set.remove(node)
          @selected_set.remove(node)
          @graphed_set.remove(node)
          node.unselect()
          @hide_node_links(node)
          @update_state(node)
          shownness = @update_showing_links(node)
    else
      removed = @wasChosen_set.filter (node) =>
        not @nowChosen_set.includes(node)
      # Add old path nodes to removed so that they are also removed
      for node in active_nodes
        removed.push node
      for node in removed
        @unchoose(node)
        @wasChosen_set.remove(node)
      if not @nowChosen_set.clear()
        throw new Error("the nowChosen_set should be empty after clear()")
      # Reset the walk path and start new one with current selection
      @walk_path_set = []
      @walk_path_set.push current_selection.lid
    console.log @walk_path_set

  walk: (chosen) =>
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Walk is just the same as Choose (AKA Activate) except afterward it deactivates the
    # nodes which are not connected to the set being walked.
    # This is accomplished by walked__build_callback()
    return @choose(chosen)

  hide: (goner) =>
    @unpin(goner)
    @chosen_set.remove(goner)
    @hidden_set.acquire(goner)
    @selected_set.remove(goner)
    goner.unselect()
    @hide_node_links(goner)
    @update_state(goner)
    shownness = @update_showing_links(goner)

  # The verbs SELECT and UNSELECT perhaps don't need to be exposed on the UI
  # but they perform the function of manipulating the @selected_set
  select: (node) =>
    if not node.selected?
      @selected_set.add(node)
      if node.select?
        node.select()
        @recolor_node(node)
      else
        msg = "#{node.__proto__.constructor.name} #{node.id} lacks .select()"
        throw msg
        console.error msg,node

  unselect: (node) =>
    if node.selected?
      @selected_set.remove(node)
      node.unselect()
      @recolor_node(node)
    return

  set_unique_color: (uniqcolor, set, node) ->
    set.uniqcolor ?= {}
    old_node = set.uniqcolor[uniqcolor]
    if old_node
      old_node.color = old_node.uniqucolor_orig
      delete old_node.uniqcolor_orig
    set.uniqcolor[uniqcolor] = node
    node.uniqcolor_orig = node.color
    node.color = uniqcolor
    return

  animate_hunt: (array, sought_node, mid_node, prior_node, pos) =>
    #sought_node.color = 'red'
    pred_uri = 'hunt:trail'
    if mid_node
      mid_node.color = 'black'
      mid_node.radius = 100
      @label(mid_node)
    if prior_node
      @ensure_predicate_lineage(pred_uri)
      trail_pred = @get_or_create_predicate_by_id(pred_uri)
      edge = @get_or_create_Edge(mid_node, prior_node, trail_pred, 'http://universal.org')
      edge.label = JSON.stringify(pos)
      @infer_edge_end_types(edge)
      edge.color = @gclui.predicate_picker.get_color_forId_byName(trail_pred.lid, 'showing')
      @add_edge(edge)
      #@show_link(edge)
    if pos.done
      cmdArgs =
        verbs: ['show']
        regarding: [pred_uri]
        sets: [@shelved_set.id]
      cmd = new gcl.GraphCommand(this, cmdArgs)
      @run_command(cmd)
      @clean_up_all_dirt_once()

  hunt: (node) =>
    # Hunt is just a test verb to animate SortedSet.binary_search() for debugging
    @animate_hunt(@shelved_set, node, null, null, {})
    @shelved_set.binary_search(node, false, @animate_hunt)

  recolor_node: (n, default_color) ->
    default_color ?= 'black'
    n._types ?= []
    if @color_nodes_as_pies and n._types.length > 1
      n._colors = []
      for taxon_id in n._types
        if typeof(taxon_id) is 'string'
          color = @get_color_for_node_type(n, taxon_id) or default_color
          n._colors.push(color)
       #n._colors = ['red','orange','yellow','green','blue','purple']
    else
      n.color = @get_color_for_node_type(n, n.type)

  get_color_for_node_type: (node, type) ->
    state = node.selected? and "emphasizing" or "showing"
    return @gclui.taxon_picker.get_color_forId_byName(type, state)

  recolor_nodes: () ->
    # The nodes needing recoloring are all but the embryonic.
    if @nodes
      for node in @nodes
        @recolor_node(node)

  toggle_selected: (node) ->
    if node.selected?
      @unselect(node)
    else
      @select(node)
    @update_all_counts()
    @regenerate_english()
    @tick()

  # ========================================== SNIPPET (INFO BOX) UI =============================================================================
  get_snippet_url: (snippet_id) ->
    if snippet_id.match(/http\:/)
      return snippet_id
    else
      return "#{window.location.origin}#{@get_snippetServer_path(snippet_id)}"

  get_snippetServer_path: (snippet_id) ->
    # this relates to index.coffee and the urls for the
    if @data_uri?.match('poetesses')
      console.info @data_uri,@data_uri.match('poetesses')
      which = "poetesses"
    else
      which = "orlando"
    return "/snippet/#{which}/#{snippet_id}/"

  get_snippet_js_key: (snippet_id) ->
    # This is in case snippet_ids can not be trusted as javascript
    # property ids because they might have leading '-' or something.
    return "K_" + snippet_id

  get_snippet: (snippet_id, callback) ->
    snippet_js_key = @get_snippet_js_key(snippet_id)
    snippet_text = @snippet_db[snippet_js_key]
    url = @get_snippet_url(snippet_id)
    if snippet_text
      callback(null, {response:snippet_text, already_has_snippet_id:true})
    else
      #url = "http://localhost:9999/snippet/poetesses/b--balfcl--0--P--3/"
      #console.warn(url)
      d3.xhr(url, callback)
    return "got it"

  clear_snippets: (evt) =>
    if evt? and evt.target? and not $(evt.target).hasClass('close_all_snippets_button')
      return false
    @currently_printed_snippets = {}
    @snippet_positions_filled = {}
    $('.snippet_dialog_box').remove()
    return

  init_snippet_box: ->
    if d3.select('#snippet_box')[0].length > 0
      @snippet_box = d3.select('#snippet_box')
      console.log "init_snippet_box"
  remove_snippet: (snippet_id) ->
    key = @get_snippet_js_key(snippet_id)
    delete @currently_printed_snippets[key]
    if @snippet_box
      slctr = '#'+id_escape(snippet_id)
      console.log(slctr)
      @snippet_box.select(slctr).remove()
  push_snippet: (obj, msg) ->
    console.log "push_snippet"
    if @snippet_box
      snip_div = @snippet_box.append('div').attr('class','snippet')
      snip_div.html(msg)
      $(snip_div[0][0]).addClass("snippet_dialog_box")
      my_position = @get_next_snippet_position()
      dialog_args =
        #maxHeight: @snippet_size
        minWidth: 400
        title: obj.dialog_title
        position:
          my: my_position
          at: "left top"
          of: window
        close: (event, ui) =>
          event.stopPropagation()
          delete @snippet_positions_filled[my_position]
          delete @currently_printed_snippets[event.target.id]
          return

      dlg = $(snip_div).dialog(dialog_args)
      elem = dlg[0][0]
      elem.setAttribute("id",obj.snippet_js_key)
      bomb_parent = $(elem).parent().
        select(".ui-dialog-titlebar").children().first()
      close_all_button = bomb_parent.
        append('<button type="button" class="ui-button ui-corner-all ui-widget close-all" role="button" title="Close All""><img class="close_all_snippets_button" src="close_all.png" title="Close All"></button>')
        #append('<span class="close_all_snippets_button" title="Close All"></span>')
        #append('<img class="close_all_snippets_button" src="close_all.png" title="Close All">')
      close_all_button.on('click', @clear_snippets)
      return

  snippet_positions_filled: {}
  get_next_snippet_position: ->
    # Fill the left edge, then the top edge, then diagonally from top-left
    height = @height
    width = @width
    left_full = false
    top_full = false
    hinc = 0
    vinc = @snippet_size
    hoff = 0
    voff = 0
    retval = "left+#{hoff} top+#{voff}"
    while @snippet_positions_filled[retval]?
      hoff = hinc + hoff
      voff = vinc + voff
      retval = "left+#{hoff} top+#{voff}"
      if not left_full and voff + vinc + vinc > height
        left_full = true
        hinc = @snippet_size
        hoff = 0
        voff = 0
        vinc = 0
      if not top_full and hoff + hinc + hinc + hinc > width
        top_full = true
        hinc = 30
        vinc = 30
        hoff = 0
        voff = 0
    @snippet_positions_filled[retval] = true
    return retval

  # =============================================================================================================================

  remove_tags: (xml) ->
    xml.replace(XML_TAG_REGEX, " ").replace(MANY_SPACES_REGEX, " ")

  # peek selects a node so that subsequent mouse motions select not nodes but edges of this node
  peek: (node) =>
    was_already_peeking = false
    if @peeking_node?
      if @peeking_node is node
        was_already_peeking = true
      @recolor_node(@peeking_node)
      @unflag_all_edges(@peeking_node)
    if not was_already_peeking
      @peeking_node = node
      @peeking_node.color = PEEKING_COLOR

  unflag_all_edges: (node) ->
    for edge in node.links_shown
      edge.focused = false

  print_edge: (edge) ->
    # @clear_snippets()
    context_no = 0
    for context in edge.contexts
      snippet_js_key = @get_snippet_js_key(context.id)
      context_no++
      if @currently_printed_snippets[snippet_js_key]?
        # FIXME add the Subj--Pred--Obj line to the snippet for this edge
        #   also bring such snippets to the top
        console.log("  skipping because",@currently_printed_snippets[snippet_js_key])
        continue
      me = this
      make_callback = (context_no, edge, context) =>
        (err,data) =>
          data = data or {response: ""}
          snippet_text = data.response
          if not data.already_has_snippet_id
            snippet_text = me.remove_tags(snippet_text)
            snippet_text += '<br><code class="snippet_id">'+context.id+"</code>"
          snippet_id = context.id
          snippet_js_key = me.get_snippet_js_key snippet_id
          if not me.currently_printed_snippets[snippet_js_key]?
            me.currently_printed_snippets[snippet_js_key] = []
          me.currently_printed_snippets[snippet_js_key].push(edge)
          me.snippet_db[snippet_js_key] = snippet_text
          me.printed_edge = edge
          quad =
            subj_uri: edge.source.id
            pred_uri: edge.predicate.id
            graph_uri: @data_uri
          if edge.target.isLiteral
            quad.obj_val = edge.target.name.toString()
          else
            quad.obj_uri = edge.target.id
          me.push_snippet
            edge: edge
            pred_id: edge.predicate.lid
            pred_name: edge.predicate.name
            context_id: context.id
            quad: quad
            dialog_title: edge.source.name
            snippet_text: snippet_text
            no: context_no
            snippet_js_key: snippet_js_key
      @get_snippet(context.id, make_callback(context_no, edge, context))

  # The Verbs PRINT and REDACT show and hide snippets respectively
  print: (node) =>
    @clear_snippets()
    for edge in node.links_shown
      @print_edge(edge)
    return

  redact: (node) =>
    node.links_shown.forEach (edge,i) =>
      @remove_snippet edge.id

  draw_edge_regarding: (node, predicate_lid) =>
    dirty = false
    doit = (edge,i,frOrTo) =>
      if edge.predicate.lid is predicate_lid
        if not edge.shown?
          @show_link(edge)
          dirty = true
    node.links_from.forEach (edge,i) =>
      doit(edge,i,'from')
    node.links_to.forEach (edge,i) =>
      doit(edge,i,'to')
    if dirty
      @update_state(node)
      @update_showing_links(node)
      @force.alpha(0.1)
    return

  undraw_edge_regarding: (node, predicate_lid) =>
    dirty = false
    doit = (edge,i,frOrTo) =>
      if edge.predicate.lid is predicate_lid
        dirty = true
        @unshow_link(edge)
    node.links_from.forEach (edge,i) =>
      doit(edge,i,'from')
    node.links_to.forEach (edge,i) =>
      doit(edge,i,'to')
    # FIXME(shawn) Looping through links_shown should suffice, try it again
    #node.links_shown.forEach (edge,i) =>
    #  doit(edge,'shown')
    if dirty
      @update_state(node)
      @update_showing_links(node)
      @force.alpha(0.1)
    return

  update_history: ->
    if window.history.pushState
      the_state = {}
      hash = ""
      if chosen_set.length
        the_state.chosen_node_ids = []
        hash += "#"
        hash += "chosen="
        n_chosen = chosen_set.length
        @chosen_set.forEach (chosen, i) =>
          hash += chosen.id
          the_state.chosen_node_ids.push chosen.id
          hash += ","  if n_chosen > i + 1

      the_url = location.href.replace(location.hash, "") + hash
      the_title = document.title
      window.history.pushState the_state, the_title, the_state

  # TODO: remove this method
  restore_graph_state: (state) ->
    #console.log('state:',state);
    return unless state
    if state.chosen_node_ids
      @reset_graph()
      state.chosen_node_ids.forEach (chosen_id) =>
        chosen = get_or_make_node(chosen_id)
        @choose chosen  if chosen

  fire_showgraph_event: ->
    window.dispatchEvent(
      new CustomEvent 'showgraph',
        detail:
          message: "graph shown"
          time: new Date()
        bubbles: true
        cancelable: true
    )

  showGraph: (g) ->
    alert "showGraph called"
    @make_nodes g
    @fire_showgraph_event() if window.CustomEvent?
    @restart()

  show_the_edges: () ->
    #edge_controller.show_tree_in.call(arguments)

  register_gclc_prefixes: =>
    @gclc.prefixes = {}
    for abbr,prefix of @G.prefixes
      @gclc.prefixes[abbr] = prefix


  # https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB
  init_datasetDB: ->
    indexedDB = window.indexedDB # || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB || null
    if not indexedDB
      console.log("indexedDB not available")
    if not @datasetDB and indexedDB
      @dbName = 'datasetDB'
      @dbVersion = 2
      request = indexedDB.open(@dbName, @dbVersion)
      request.onsuccess = (e) =>
        @datasetDB = request.result
        @datasetDB.onerror = (e) =>
          alert "Database error: #{e.target.errorCode}"
        #alert "onsuccess"
        @populate_menus_from_IndexedDB('onsuccess')
      request.onerror = (e) =>
        alert("unable to init #{@dbName}")
      request.onupgradeneeded = (e) =>
        db = event.target.result
        objectStore = db.createObjectStore("datasets", {keyPath: 'uri'})
        objectStore.transaction.oncomplete = (e) =>
          @datasetDB = db
          # alert "onupgradeneeded"
          @populate_menus_from_IndexedDB('onupgradeneeded')

  ensure_datasets: (preload_group, store_in_db) =>
    # note "fat arrow" so this can be an AJAX callback (see preload_datasets)
    defaults = preload_group.defaults or {}
    #console.log preload_group # THIS IS THE ITEMS IN A FILE (i.e. cwrc.json, generes.json)
    for ds_rec in preload_group.datasets
      # If this preload_group has defaults apply them to the ds_rec if it is missing that value.
      # We do not want to do ds_rec.__proto__ = defaults because then defaults are not ownProperty
      for k of defaults
        ds_rec[k] ?= defaults[k]
      @ensure_dataset(ds_rec, store_in_db)

  ensure_dataset: (rsrcRec, store_in_db) ->
    # ensure the dataset is in the database and the correct
    uri = rsrcRec.uri
    rsrcRec.time ?= new Date().toString()
    rsrcRec.title ?= uri
    rsrcRec.isUri ?= not not uri.match(/^(http|ftp)/)
    # if it has a time then a user added it therefore canDelete
    rsrcRec.canDelete ?= not not rsrcRec.time?
    rsrcRec.label ?= uri.split('/').reverse()[0]
    if rsrcRec.isOntology
      if @ontology_loader
        @ontology_loader.add_resource(rsrcRec, store_in_db)
    if @dataset_loader and not rsrcRec.isEndpoint
      @dataset_loader.add_resource(rsrcRec, store_in_db)
    if rsrcRec.isEndpoint and @endpoint_loader
      @endpoint_loader.add_resource(rsrcRec, store_in_db)

  add_resource_to_db: (rsrcRec, callback) ->
    trx = @datasetDB.transaction('datasets', "readwrite")
    trx.oncomplete = (e) =>
      console.log("#{rsrcRec.uri} added!")
    trx.onerror = (e) =>
      console.log(e)
      alert "add_resource(#{rsrcRec.uri}) error!!!"
    store = trx.objectStore('datasets')
    req = store.put(rsrcRec)
    req.onsuccess = (e) =>
      if rsrcRec.isEndpoint
        @sparql_graph_query_and_show(e.srcElement.result, @endpoint_loader.select_id)
        #console.log @dataset_loader
        $("##{@dataset_loader.uniq_id}").children('select').prop('disabled', 'disabled')
        $("##{@ontology_loader.uniq_id}").children('select').prop('disabled', 'disabled')
        $("##{@script_loader.uniq_id}").children('select').prop('disabled', 'disabled')
      if rsrcRec.uri isnt e.target.result
        debugger
      callback(rsrcRec)

  remove_dataset_from_db: (dataset_uri, callback) ->
    trx = @datasetDB.transaction('datasets', "readwrite")
    trx.oncomplete = (e) =>
      console.log("#{dataset_uri} deleted")
    trx.onerror = (e) =>
      console.log(e)
      alert "remove_dataset_from_db(#{dataset_uri}) error!!!"
    store = trx.objectStore('datasets')
    req = store.delete(dataset_uri)
    req.onsuccess = (e) =>
      if callback?
        callback(dataset_uri)
    req.onerror = (e) =>
      console.debug e

  get_resource_from_db: (rsrcUri, callback) ->
    trx = @datasetDB.transaction('datasets', "readwrite")
    trx.oncomplete = (e) =>
      console.log("#{rsrcUri} found")
    trx.onerror = (e) =>
      console.log(e)
      alert("get_resource_from_db(#{rsrcUri}) error!!!")
    store = trx.objectStore('datasets')
    req = store.get(rsrcUri)
    req.onsuccess = (event) =>
      if callback?
        callback(event.target.result)
    req.onerror = (e) =>
      console.debug(e)
      if callback
        callback(e,null)
      else
        throw e
    return


  populate_menus_from_IndexedDB: (why) ->
    #alert "populate_menus_from_IndexedDB()"
    # https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB#Using_a_cursor
    console.groupCollapsed("populate_menus_from_IndexedDB(#{why})")
    datasetDB_objectStore = @datasetDB.transaction('datasets').objectStore('datasets')
    count = 0
    make_onsuccess_handler = (why) =>
      recs = []
      return (event) =>
        cursor = event.target.result
        if cursor
          count++
          rec = cursor.value
          recs.push(rec)
          legacyDataset = (not rec.isOntology and not rec.rsrcType)
          legacyOntology = (not not rec.isOntology)
          if rec.rsrcType in ['dataset', 'ontology'] or legacyDataset or legacyOntology
            # both datasets and ontologies appear in the dataset menu, for visualization
            @dataset_loader.add_resource_option(rec)
          else if rec.rsrcType is 'ontology' or legacyOntology
            # only datasets are added to the dataset menu
            @ontology_loader.add_resource_option(rec)
          else if rec.rsrcType is 'script'
            @script_loader.add_resource_option(rec)
          else if rec.rsrcType is 'endpoint'
            @endpoint_loader.add_resource_option(rec)
          cursor.continue()
        else # when there are no (or NO MORE) entries, ie FINALLY
          #console.table(recs)
          # Reset the value of each loader to blank so
          # they show 'Pick or Provide...' not the last added entry.
          @dataset_loader.val('')
          @ontology_loader.val('')
          @endpoint_loader.val('')
          @script_loader.val('')
          @update_dataset_ontology_loader()
          console.groupEnd() # closing group called "populate_menus_from_IndexedDB(why)"
          document.dispatchEvent( # TODO use 'huviz_controls' rather than document
            new Event('dataset_ontology_loader_ready'));
          #alert "#{count} entries saved #{why}"

    if @dataset_loader?
      datasetDB_objectStore.openCursor().onsuccess = make_onsuccess_handler(why)

  preload_datasets: ->
    # If present args.preload is expected to be a list or urls or objects.
    # Whether literal object or JSON urls the object structure is expected to be:
    #   { 'datasets': [
    #        {
    #         'uri': "/data/byroau.nq",     // url of dataset .ttl or .nq
    #         'label': "Augusta Ada Brown", // label of OPTION in SELECT
    #         'isOntology': false,          // optional, if true it goes in Onto menu
    #         'opt_group': "Individuals",   // user-defined label for menu subsection
    #         'canDelete':   false,         // meaningful only for recs in datasetsDB
    #         'ontologyUri': '/data/orlando.ttl' // url of ontology
    #         }
    #                  ],
    #     'defaults': {}  # optional, may contain default values for the keys above
    #    }
    console.groupCollapsed("preload_datasets")
    # Adds preload options to datasetDB table
    console.log @args.preload
    if @args.preload
      for preload_group_or_uri in @args.preload
        if typeof(preload_group_or_uri) is 'string' # the URL of a preload_group JSON
          #$.getJSON(preload_group_or_uri, null, @ensure_datasets_from_XHR)
          $.ajax
            async: false
            url: preload_group_or_uri
            success: (data, textStatus) =>
              @ensure_datasets_from_XHR(data)
            error: (jqxhr, textStatus, errorThrown) ->
              console.error(preload_group_or_uri + " " +textStatus+" "+errorThrown.toString())
        else if typeof(preload_group_or_uri) is 'object' # a preload_group object
          @ensure_datasets(preload_group_or_uri)
        else
          console.error("bad member of @args.preload:", preload_group_or_uri)
    console.groupEnd() # closing group called "preload_datasets"

  preload_endpoints: ->
    console.log @args.preload_endpoints
    console.groupCollapsed("preload_endpoints")
    ####
    if @args.preload_endpoints
      for preload_group_or_uri in @args.preload_endpoints
        console.log preload_group_or_uri
        if typeof(preload_group_or_uri) is 'string' # the URL of a preload_group JSON
          #$.getJSON(preload_group_or_uri, null, @ensure_datasets_from_XHR)
          $.ajax
            async: false
            url: preload_group_or_uri
            success: (data, textStatus) =>
              @ensure_datasets_from_XHR(data)
            error: (jqxhr, textStatus, errorThrown) ->
              console.error(preload_group_or_uri + " " +textStatus+" "+errorThrown.toString())
        else if typeof(preload_group_or_uri) is 'object' # a preload_group object
          @ensure_datasets(preload_group_or_uri)
        else
          console.error("bad member of @args.preload:", preload_group_or_uri)
    console.groupEnd()
    ####

  ensure_datasets_from_XHR: (preload_group) =>
    @ensure_datasets(preload_group, false) # false means DO NOT store_in_db
    return

  get_menu_by_rsrcType: (rsrcType) ->
    return @[rsrcType+'_loader'] # eg rsrcType='script' ==> @script_loader

  init_resource_menus: ->
    # REVIEW See views/huviz.html.eco to set dataset_loader__append_to_sel and similar
    if not @dataset_loader and @args.dataset_loader__append_to_sel
      @dataset_loader = new PickOrProvide(@, @args.dataset_loader__append_to_sel,
        'Dataset', 'DataPP', false, false,
        {rsrcType: 'dataset'})
    if not @ontology_loader and @args.ontology_loader__append_to_sel
      @ontology_loader = new PickOrProvide(@, @args.ontology_loader__append_to_sel,
        'Ontology', 'OntoPP', true, false,
        {rsrcType: 'ontology'})
      #$(@ontology_loader.form).disable()
    if not @script_loader and @args.script_loader__append_to_sel
      @script_loader = new PickOrProvide(@, @args.script_loader__append_to_sel,
        'Script', 'ScriptPP', false, false,
        {dndLoaderClass: DragAndDropLoaderOfScripts; rsrcType: 'script'})
      $("#"+@script_loader.uniq_id).attr('style','display:none') # TEMPORARILY HIDE SCRIPT MENU
    if not @endpoint_loader and @args.endpoint_loader__append_to_sel
      @endpoint_loader = new PickOrProvide(@, @args.endpoint_loader__append_to_sel,
        'Sparql', 'EndpointPP', false, true,
        {rsrcType: 'endpoint'})
      #@endpoint_loader.outstanding_requests = 0
      #endpoint = "#" + @endpoint_loader.uniq_id
      #$(endpoint).css('display','none')
    if @endpoint_loader and not @big_go_button
      @populate_sparql_label_picker()
      endpoint_selector = "##{@endpoint_loader.select_id}"
      $(endpoint_selector).change(@update_endpoint_form)
    if @ontology_loader and not @big_go_button
      @big_go_button_id = unique_id()
      @big_go_button = $('<button class="big_go_button">LOAD</button>')
      @big_go_button.attr('id', @big_go_button_id)
      $(@args.ontology_loader__append_to_sel).append(@big_go_button)
      @big_go_button.click(@visualize_dataset_using_ontology)
      @big_go_button.prop('disabled', true)
    @init_datasetDB()
    @preload_datasets()

    #@preload_endpoints()
    # TODO remove this nullification of @last_val by fixing logic in select_option()
    @ontology_loader?last_val = null # clear the last_val so select_option works the first time

  update_graph_form: (e) =>
    #console.log e.currentTarget.value
    @endpoint_loader.endpoint_graph = e.currentTarget.value

  visualize_dataset_using_ontology: (ignoreEvent, dataset, ontologies) =>
    @close_blurt_box()
    endpoint_label_uri = $("#endpoint_labels").val()
    if endpoint_label_uri
      data = dataset or @endpoint_loader
      @load_endpoint_data_and_show(endpoint_label_uri)
      @update_browser_title(data)
      @update_caption(data.value, data.endpoint_graph)
      return
    # Either dataset and ontologies are passed in by HuViz.load_with() from a command
    #   or this method is called with neither in which case get values from the loaders
    if @script_loader.value
      msg = 'It is time to trigger the loading of the dataset and ontology OR endpoint ' +
            'but the requisite info has not yet been saved in the script ' +
            'on the other hand: if the user want to run the script on different data.... ' +
            'then do we pause and let them mess with the script OR let them pick the data. ' +
            'In fact, perhaps the thing to do is load the dataset and ontology into their ' +
            'pickers so the user can mess with them before proceeding.  YES.  PERFECT.'
      # alert(msg)
      scriptUri = @script_loader.value
      @get_resource_from_db(scriptUri, @load_script_from_db)
      return
    onto = ontologies and ontologies[0] or @ontology_loader
    data = dataset or @dataset_loader
    if @local_file_data
      @read_data_and_show(data.value) #(@dataset_loader.value)
    #else if @endpoint_loader.value
    #  data = @endpoint_loader #TEMP
    #  @load_data_with_onto(data, onto) #TODO add ontology here?
    else #load from URI
      @load_data_with_onto(data, onto) # , () -> alert "woot")
    #selected_dataset = @dataset_loader.get_selected_option()[0]
    @update_browser_title(data)
    @update_caption(data.value, onto.value)

  load_script_from_db: (rsrcRec) =>
    @load_script_from_JSON(@parse_script_file(rsrcRec.data, rsrcRec.uri))

  init_gclc: ->
    @gclc = new GraphCommandLanguageCtrl(this)
    @init_resource_menus()
    if not @gclui?
      @gclui = new CommandController(this,d3.select(@args.gclui_sel)[0][0],@hierarchy)
    window.addEventListener('showgraph', @register_gclc_prefixes)
    window.addEventListener('newpredicate', @gclui.handle_newpredicate)
    if not @show_class_instance_edges
      TYPE_SYNS.forEach (pred_id,i) =>
        @gclui.ignore_predicate(pred_id)
    NAME_SYNS.forEach (pred_id,i) =>
      @gclui.ignore_predicate(pred_id)
    for pid in @predicates_to_ignore
      @gclui.ignore_predicate(pid)

  disable_dataset_ontology_loader: (data, onto) ->
    @replace_loader_display(data, onto)
    disable = true
    @update_go_button(disable)
    @dataset_loader.disable()
    @ontology_loader.disable()
    @big_go_button.hide()

  reset_dataset_ontology_loader: ->
    #Enable dataset loader and reset to default setting
    @dataset_loader.enable()
    @ontology_loader.enable()
    @big_go_button.show()
    $("##{@dataset_loader.select_id} option[label='Pick or Provide...']").prop('selected', true)
    $("#huvis_controls .unselectable").removeAttr("style","display:none")

  update_dataset_ontology_loader: =>
    if not (@dataset_loader? and @ontology_loader?  and @endpoint_loader? and @script_loader?)
      console.log("still building loaders...")
      return
    @set_ontology_from_dataset_if_possible()
    ugb = () =>
      @update_go_button()
    setTimeout(ugb, 200)

  update_endpoint_form: (e) =>
    #check if there are any endpoint selections available
    graphSelector = "#sparqlGraphOptions-#{e.currentTarget.id}"
    $(graphSelector).change(@update_graph_form)
    if e.currentTarget.value is ''
      $("##{@dataset_loader.uniq_id}").children('select').prop('disabled', false)
      $("##{@ontology_loader.uniq_id}").children('select').prop('disabled', false)
      $("##{@script_loader.uniq_id}").children('select').prop('disabled', false)
      $(graphSelector).parent().css('display', 'none')
      @reset_endpoint_form(false)
    else if e.currentTarget.value is 'provide'
      console.log "update_endpoint_form ... select PROVIDE"
    else
      @sparql_graph_query_and_show(e.currentTarget.value, e.currentTarget.id)
      #console.log @dataset_loader
      $("##{@dataset_loader.uniq_id}").children('select').prop('disabled', 'disabled')
      $("##{@ontology_loader.uniq_id}").children('select').prop('disabled', 'disabled')
      $("##{@script_loader.uniq_id}").children('select').prop('disabled', 'disabled')

  reset_endpoint_form: (show) =>
    spinner = $("#sparqlGraphSpinner-#{@endpoint_loader.select_id}")
    spinner.css('display','none')
    $("#endpoint_labels").prop('disabled', false).val("")
    $("#endpoint_limit").prop('disabled', false).val("100")
    if show
      $('#sparqlQryInput').css({'display': 'block','color': 'inherit'} )
    else
      $('#sparqlQryInput').css('display', 'none')

  update_go_button: (disable) ->
    if not disable?
      if @script_loader.value
        disable = false
      else if @endpoint_loader.value
        disable = false
      else
        ds_v = @dataset_loader.value
        on_v = @ontology_loader.value
        #console.log("DATASET: #{ds_v}\nONTOLOGY: #{on_v}")
        disable = (not (ds_v and on_v)) or ('provide' in [ds_v, on_v])
        ds_on = "#{ds_v} AND #{on_v}"
    @big_go_button.prop('disabled', disable)
    return

  get_reload_uri: ->
    return @reload_uri or new URL(window.location)

  generate_reload_uri: (dataset, ontology) ->
    @reload_uri =     uri = new URL(location)
    uri.hash = "load+#{dataset.value}+with+#{ontology.value}"
    return uri

  replace_loader_display: (dataset, ontology) ->
    @generate_reload_uri(dataset, ontology)
    uri = @get_reload_uri()
    $("#huvis_controls .unselectable").attr("style","display:none")
    data_ontol_display = """
    <div id="data_ontology_display">
      <p><span class="dt_label">Dataset:</span> #{dataset.label}</p>
      <p><span class="dt_label">Ontology:</span> #{ontology.label}</p>
      <p>
        <button title="reload"
           onclick="location.replace('#{uri}');location.reload()"><i class="fas fa-redo"></i></button>
      </p>
      <br style="clear:both">
    </div>"""
    $("#huvis_controls").prepend(data_ontol_display)

  replace_loader_display_for_endpoint: (endpoint, graph) ->
    $("#huvis_controls .unselectable").attr("style","display:none")
    #uri = new URL(location)
    #uri.hash = "load+#{dataset.value}+with+#{ontology.value}"
    if graph
      print_graph = "<p><span class='dt_label'>Graph:</span> #{graph}</p>"
    else
      print_graph = ""
    data_ontol_display = """
    <div id="data_ontology_display">
      <p><span class="dt_label">Endpoint:</span> #{endpoint}</p>
      #{print_graph}
      <br style="clear:both">
    </div>"""
    $("#huvis_controls").prepend(data_ontol_display)

  update_browser_title: (dataset) ->
    if dataset.value
      document.title = dataset.label + " - Huvis Graph Visualization"

  update_caption: (dataset_str, ontology_str) ->
    $("#dataset_watermark").text(dataset_str)
    $("#ontology_watermark").text(ontology_str)

  set_ontology_from_dataset_if_possible: ->
    if @dataset_loader.value # and not @ontology_loader.value
      option = @dataset_loader.get_selected_option()
      ontologyUri = option.data('ontologyUri')
      ontology_label = option.data('ontology_label') #default set in group json file
      if ontologyUri # let the uri (if present) dominate the label
        @set_ontology_with_uri(ontologyUri)
      else
        @set_ontology_with_label(ontology_label)
    @ontology_loader.update_state()

  set_ontology_with_label: (ontology_label) ->
    sel = "[label='#{ontology_label}']"
    #console.log("$('#{sel}')")
    for ont_opt in $(sel) # FIXME make this re-entrant
      @ontology_loader.select_option($(ont_opt))
      return
    return

  set_ontology_with_uri: (ontologyUri) ->
    ontology_option = $('option[value="' + ontologyUri + '"]')
    #console.log("set_ontology_with_uri",ontologyUri, ontology_option)
    @ontology_loader.select_option(ontology_option)

  populate_sparql_label_picker: () =>
    select_box = """
      <div class='ui-widget' style='display:none;margin-top:5px;margin-left:10px;'>
        <label>Graphs: </label>
        <select id="sparqlGraphOptions-#{@endpoint_loader.select_id}">
        </select>
      </div>
      <div id="sparqlGraphSpinner-#{@endpoint_loader.select_id}"
           style='display:none;font-style:italic;'>
        <i class='fas fa-spinner fa-spin' style='margin: 10px 10px 0 50px;'></i>  Looking for graphs...
      </div>
      <div id="sparqlQryInput" class=ui-widget
           style='display:none;margin-top:5px;margin-left:10px;color:#999;'>
        <label for='endpoint_labels'>Find: </label>
        <input id='endpoint_labels' disabled>
        <i class='fas fa-spinner fa-spin' style='visibility:hidden;margin-left: 5px;'></i>
        <div><label for='endpoint_limit'>Node Limit: </label>
        <input id='endpoint_limit' value='100' disabled>
        </div>
      </div>
    """
    $(".unselectable").append(select_box)
    spinner = $("#endpoint_labels").siblings('i')
    fromGraph =''
    $("#endpoint_labels").autocomplete({minLength: 3, delay:500, position: {collision: "flip"}, source: (request, response) =>
      spinner.css('visibility','visible')
      url = @endpoint_loader.value
      fromGraph = ''
      if @endpoint_loader.endpoint_graph then fromGraph=" FROM <#{@endpoint_loader.endpoint_graph}> "
      qry = """
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      SELECT * #{fromGraph}
      WHERE {
  	  ?sub rdfs:label|foaf:name ?obj .
      filter contains(?obj,"#{request.term}")
      }
      LIMIT 20
      """  # " # for emacs syntax hilighting
      ajax_settings = {
        'method': 'GET'
        'url': url + '?query=' + encodeURIComponent(qry)
        'headers' :
          'Accept': 'application/sparql-results+json'
      }
      if url is "http://sparql.cwrc.ca/sparql" # Hack to make CWRC setup work properly
        ajax_settings.headers =
          'Content-Type' : 'application/sparql-query'
          'Accept': 'application/sparql-results+json'
      $.ajax
          method: ajax_settings.method  # "type" used in eariler jquery
          url: ajax_settings.url
          headers: ajax_settings.headers
          success: (data, textStatus, jqXHR) =>
            #console.log jqXHR
            #console.log data
            json_check = typeof data
            if json_check is 'string' then json_data = JSON.parse(data) else json_data = data
            results = json_data.results.bindings
            selections = []
            for label in results
              this_result = {
                label: label.obj.value + " (#{label.sub.value})"
                value: label.sub.value
              }
              selections.push(this_result)
              spinner.css('visibility','hidden')
            response(selections)
            #@parse_json_label_query_results(data)
          error: (jqxhr, textStatus, errorThrown) =>
            console.log(url, errorThrown)
            console.log textStatus
            if not errorThrown
              errorThrown = "Cross-Origin error"
            msg = errorThrown + " while fetching " + url
            @hide_state_msg()
            $('#data_ontology_display').remove()
            $("#endpoint_labels").siblings('i').css('visibility','hidden')
            blurt(msg, 'error')

      })

  init_editc: ->
    @editui ?= new EditController(@)

  set_edit_mode: (mode) ->
    @edit_mode = mode

  indexed_dbservice: ->
    @indexeddbservice ?= new IndexedDBService(this)

  init_indexddbstorage: ->
    @dbsstorage ?= new IndexedDBStorageController(this, @indexeddbservice)

  # TODO make other than 'anything' optional
  predicates_to_ignore: ["anything", "first", "rest", "members"]

  get_polar_coords_of: (node) ->
    w = @get_container_height()
    h = @get_container_width()
    min_wh = Math.min(w, h)
    max_radius = min_wh / 2
    max_radius = @graph_region_radius
    x = node.x - @cx
    y = node.y - @cy
    range = (Math.sqrt(((x * x) + (y * y)))/(max_radius))
    radians = Math.atan2(y, x) + (Math.PI) # + (Math.PI/2)
    degrees = (Math.floor(radians * 180 / Math.PI) + 270) % 360
    return {range: range, degrees: degrees}

  run_verb_on_object: (verb, subject) ->
    args =
      verbs: [verb]
      subjects: [@get_handle subject]
    if verb is 'pin'
      args.polar_coords = @get_polar_coords_of(subject)
    cmd = new gcl.GraphCommand(this, args)
    @run_command(cmd)

  before_running_command: ->
    # FIXME fix non-display of cursor and color changes
    @text_cursor.set_cursor("wait")
    $("body").css "background-color", "red" # FIXME remove once it works!
    #toggle_suspend_updates(true)

  after_running_command: ->
    #toggle_suspend_updates(false)
    @text_cursor.set_cursor("default")
    $("body").css "background-color", renderStyles.pageBg # FIXME remove once it works!
    $("body").addClass renderStyles.themeName
    @update_all_counts()
    @clean_up_all_dirt_once()

  get_handle: (thing) ->
    # A handle is like a weak reference, saveable, serializable
    # and garbage collectible.  It was motivated by the desire to
    # turn an actual node into a suitable member of the subjects list
    # on a GraphCommand
    return {id: thing.id, lid: thing.lid}

  toggle_logging: () ->
    if not console.log_real?
      console.log_real = console.log
    new_state = console.log is console.log_real
    @set_logging(new_state)

  set_logging: (new_state) ->
    if new_state
      console.log = console.log_real
      return true
    else
      console.log = () ->
      return false

  create_state_msg_box: () ->
    @state_msg_box = $("#state_msg_box")
    @hide_state_msg()
    #console.info @state_msg_box

  init_ontology: ->
    @create_taxonomy()
    @ontology = PRIMORDIAL_ONTOLOGY

  constructor: (args) -> # Huviz
    #if @pfm_display is true
    #  @pfm_dashboard()
    args ?= {}
    if not args.viscanvas_sel
      msg = "call Huviz({viscanvas_sel:'????'}) so it can find the canvas to draw in"
      console.debug(msg)
    if not args.gclui_sel
      alert("call Huviz({gclui_sel:'????'}) so it can find the div to put the gclui command pickers in")
    if not args.graph_controls_sel
      console.warn("call Huviz({graph_controls_sel:'????'}) so it can put the settings somewhere")
    @args = args
    if @args.selector_for_graph_controls?
      @selector_for_graph_controls = @args.selector_for_graph_controls
    @init_ontology()
    @off_center = false # FIXME expose this or make the amount a slider
    document.addEventListener('nextsubject', @onnextsubject)
    @init_snippet_box()  # FIXME not sure this does much useful anymore

    @mousedown_point = false
    @discard_point = [@cx,@cy] # FIXME refactor so ctrl-handle handles this
    @lariat_center = [@cx,@cy] #       and this....
    @node_radius_policy = node_radius_policies[default_node_radius_policy]
    @currently_printed_snippets = {}
    @fill = d3.scale.category20()
    @force = d3.layout.force().
             size([@width,@height]).
             nodes([]).
             linkDistance(@link_distance).
             charge(@get_charge).
             gravity(@gravity).
             on("tick", @tick)
    @update_fisheye()
    @svg = d3.select("#vis").
              append("svg").
              attr("width", @width).
              attr("height", @height).
              attr("position", "absolute")
    @svg.append("rect").attr("width", @width).attr "height", @height
    if not d3.select(@args.viscanvas_sel)[0][0]
      d3.select("body").append("div").attr("id", "viscanvas")
    @container = d3.select(@args.viscanvas_sel).node().parentNode
    @init_graph_controls_from_json()
    if @use_fancy_cursor
      @text_cursor = new TextCursor(@args.viscanvas_sel, "")
      @install_update_pointer_togglers()
    @create_state_msg_box()
    @viscanvas = d3.select(@args.viscanvas_sel).html("").
      append("canvas").
      attr("width", @width).
      attr("height", @height)
    @canvas = @viscanvas[0][0]
    @mouse_receiver = @viscanvas
    @reset_graph()
    @updateWindow()
    @ctx = @canvas.getContext("2d")
    #console.log @ctx
    @mouse_receiver
      .on("mousemove", @mousemove)
      .on("mousedown", @mousedown)
      .on("mouseup", @mouseup)
      .on("contextmenu", @mouseright)
      #.on("mouseout", @mouseup) # FIXME what *should* happen on mouseout?

    @restart()
    @set_search_regex("")
    search_input = document.getElementById('search')
    if search_input
      search_input.addEventListener("input", @update_searchterm)
    window.addEventListener "resize", @updateWindow
    $("#tabs").on("resize", @updateWindow)
    $(@viscanvas).bind("_splitpaneparentresize", @updateWindow)
    $("#collapse_cntrl").click(@minimize_gclui).on("click", @updateWindow)
    $("#full_screen").click(@fullscreen)
    $("#expand_cntrl").click(@maximize_gclui).on("click", @updateWindow)
    $("#tabs").on('click', '#blurt_close', @close_blurt_box)
    $("#tabs").tabs
      active: 0
      #collapsible: true
    $('.open_tab').click (event) =>
      tab_idx = parseInt($(event.target).attr('href').replace("#",""))
      @goto_tab(tab_idx)
      return false

  fullscreen: () =>
    elem = document.getElementById("body")
    elem.webkitRequestFullscreen()

  close_blurt_box: () =>
    $('#blurtbox').remove()

  minimize_gclui: () ->
    $('#tabs').prop('style','visibility:hidden;width:0')
    $('#expand_cntrl').prop('style','visibility:visible')
    #w_width = (@container.clientWidth or window.innerWidth or document.documentElement.clientWidth or document.clientWidth)
    #@width = w_width
    #@get_container_width()
    #@updateWindow()
    #console.log @width
  maximize_gclui: () ->
    $('#tabs').prop('style','visibility:visible')
    $('#maximize_cntrl').prop('style','visibility:hidden')

  goto_tab: (tab_idx) ->
    $('#tabs').tabs
      active: tab_idx
      collapsible: true

  update_fisheye: ->
    #@label_show_range = @link_distance * 1.1
    @label_show_range = 30 * 1.1 #TODO Fixed value or variable like original? (above)
    #@fisheye_radius = @label_show_range * 5
    @focus_radius = @label_show_range
    @fisheye = d3.fisheye.
      circular().
      radius(@fisheye_radius).
      distortion(@fisheye_zoom)
    @force.linkDistance(@link_distance).gravity(@gravity)

  replace_human_term_spans: (optional_class) ->
    optional_class = optional_class or 'a_human_term'
    if console and console.info
      console.info("doing addClass('#{optional_class}') on all occurrences of CSS class human_term__*")
    for canonical, human of @human_term
      selector = '.human_term__' + canonical
      #console.log("replacing '#{canonical}' with '#{human}' in #{selector}")
      $(selector).text(human).addClass(optional_class) #.style('color','red')

  human_term:
    all: 'ALL'
    chosen: 'CHOSEN'
    unchosen: 'UNCHOSEN'
    selected: 'SELECTED'
    shelved: 'SHELVED'
    discarded: 'DISCARDED'
    hidden: 'HIDDEN'
    graphed: 'GRAPHED'
    fixed: 'PINNED'
    labelled: 'LABELLED'
    choose: 'CHOOSE'
    unchoose: 'UNCHOOSE'
    select: 'SELECT'
    unselect: 'UNSELECT'
    label: 'LABEL'
    unlabel: 'UNLABEL'
    shelve: 'SHELVE'
    hide: 'HIDE'
    discard: 'DISCARD'
    undiscard: 'RETRIEVE'
    pin: 'PIN'
    unpin: 'UNPIN'
    unpinned: 'UNPINNED'
    nameless: 'NAMELESS'
    blank_verb: 'VERB'
    blank_noun: 'SET/SELECTION'
    hunt: 'HUNT'

  # TODO add controls
  #   selected_border_thickness
  default_graph_controls: [
      reset_controls_to_default:
        label:
          title: "Reset all controls to default"
        input:
          type: "button"
          label: "Reset All"
          style: "background-color: #555"
        event_type: "change"
    ,
      focused_mag:
        text: "focused label mag"
        input:
          value: 1.4
          min: 1
          max: 3
          step: .1
          type: 'range'
        label:
          title: "the amount bigger than a normal label the currently focused one is"
    ,
      selected_mag:
        text: "selected node mag"
        input:
          value: 1.5
          min: 0.5
          max: 4
          step: .1
          type: 'range'
        label:
          title: "the amount bigger than a normal node the currently selected ones are"
    ,
      label_em:
        text: "label size (em)"
        label:
          title: "the size of the font"
        input:
          value: .9
          min: .1
          max: 4
          step: .05
          type: 'range'
    ,
      #snippet_body_em:
      #  text: "snippet body (em)"
      #  label:
      #    title: "the size of the snippet text"
      #  input:
      #    value: .7
      #    min: .2
      #    max: 4
      #    step: .1
      #    type: "range"
    #,
      snippet_triple_em:
        text: "snippet triple (em)"
        label:
          title: "the size of the snippet triples"
        input:
          value: .5
          min: .2
          max: 4
          step: .1
          type: "range"
    ,
      charge:
        text: "charge (-)"
        label:
          title: "the repulsive charge betweeen nodes"
        input:
          value: -210
          min: -600
          max: -1
          step: 1
          type: "range"
    ,
      gravity:
        text: "gravity"
        label:
          title: "the attractive force keeping nodes centered"
        input:
          value: 0.50
          min: 0
          max: 1
          step: 0.025
          type: "range"
    ,
      shelf_radius:
        text: "shelf radius"
        label:
          title: "how big the shelf is"
        input:
          value: 0.8
          min: 0.1
          max: 3
          step: 0.05
          type: "range"
    ,
      fisheye_zoom:
        text: "fisheye zoom"
        label:
          title: "how much magnification happens"
        input:
          value: 6.0
          min: 1
          max: 20
          step: 0.2
          type: "range"
    ,
      fisheye_radius:
        text: "fisheye radius"
        label:
          title: "how big the fisheye is"
        input:
          value: 300
          min: 40
          max: 2000
          step: 20
          type: "range"
    ,
      node_radius:
        text: "node radius"
        label:
          title: "how fat the nodes are"
        input:
          value: 3
          min: 0.5
          max: 50
          step: 0.1
          type: "range"
    ,
      node_diff:
        text: "node differentiation"
        label:
          title: "size variance for node edge count"
        input:
          value: 1
          min: 0
          max: 10
          step: 0.1
          type: "range"
    ,
      focus_threshold:
        text: "focus threshold"
        label:
          title: "how fine is node recognition"
        input:
          value: 20
          min: 10
          max: 150
          step: 1
          type: "range"
    ,
      link_distance:
        text: "link distance"
        label:
          title: "how long the lines are"
        input:
          value: 29
          min: 5
          max: 200
          step: 2
          type: "range"
    ,
      edge_width:
        text: "line thickness"
        label:
          title: "how thick the lines are"
        input:
          value: 0.2
          min: 0.2
          max: 10
          step: .2
          type: "range"
    ,
      line_edge_weight:
        text: "line edge weight"
        label:
          title: "how much thicker lines become to indicate the number of snippets"
        input:
          value: 0.45
          min: 0
          max: 1
          step: 0.01
          type: "range"
    ,
      swayfrac:
        text: "sway fraction"
        label:
          title: "how much curvature lines have"
        input:
          value: 0.22
          min: 0.001
          max: 0.6
          step: 0.01
          type: "range"
    ,
      label_graphed:
        text: "label graphed nodes"
        style: "display:none"
        label:
          title: "whether graphed nodes are always labelled"
        input:
          #checked: "checked"
          type: "checkbox"
    ,
      truncate_labels_to:
        text: "truncate and scroll"
        label:
          title: "truncate and scroll labels longer than this, or zero to disable"
        input:
          value: 0 # 40
          min: 0
          max: 60
          step: 1
          type: "range"
    ,
      slow_it_down:
        #style: "display:none"
        text: "Slow it down (sec)"
        label:
          title: "execute commands with wait states to simulate long operations"
        input:
          value: 0
          min: 0
          max: 10
          step: 0.1
          type: "range"
    ,
      snippet_count_on_edge_labels:
        text: "snippet count on edge labels"
        label:
          title: "whether edges have their snippet count shown as (#)"
        input:
          checked: "checked"
          type: "checkbox"
        event_type: "change"
    ,
      nodes_pinnable:
        style: "display:none"
        text: "nodes pinnable"
        label:
          title: "whether repositioning already graphed nodes pins them at the new spot"
        input:
          checked: "checked"
          type: "checkbox"
        event_type: "change"
    ,
      use_fancy_cursor:
        style: "display:none"
        text: "use fancy cursor"
        label:
          title: "use custom cursor"
        input:
          checked: "checked"
          type: "checkbox"
        event_type: "change"
    ,
      doit_asap:
        style: "display:none"
        text: "DoIt ASAP"
        label:
          title: "execute commands as soon as they are complete"
        input:
          checked: "checked" # default to 'on'
          type: "checkbox"
        event_type: "change"
    ,
      show_dangerous_datasets:
        style: "display:none"
        text: "Show dangerous datasets"
        label:
          title: "Show the datasets which are too large or buggy"
        input:
          type: "checkbox"
        event_type: "change"
    ,
      pill_display:
        text: "Display graph with boxed labels"
        label:
          title: "Show boxed labels on graph"
        input:
          type: "checkbox"
        event_type: "change"
    ,
      theme_colors:
        text: "Display graph with dark theme"
        label:
          title: "Show graph plotted on a black background"
        input:
          type: "checkbox"
        event_type: "change"
    ,
      display_label_cartouches:
        text: "Background cartouches for labels"
        label:
          title: "Remove backgrounds from focused labels"
        input:
          type: "checkbox"
          checked: "checked"
        event_type: "change"
    ,
      display_shelf_clockwise:
        text: "Display nodes clockwise"
        label:
          title: "Display clockwise (uncheck for counter-clockwise)"
        input:
          type: "checkbox"
          checked: "checked"
        event_type: "change"
    ,
      choose_node_display_angle:
        text: "Node display angle"
        label:
          title: "Where on shelf to place first node"
        input:
          value: 0.5
          min: 0
          max: 1
          step: 0.25
          type: "range"
    ,
      color_nodes_as_pies:
        text: "Color nodes as pies"
        style: "color:orange"
        label:
          title: "Show all a nodes types as colored pie pieces"
        input:
          type: "checkbox"   #checked: "checked"
    ,
      prune_walk_nodes:
        text: "Walk styles "
        style: "color:orange"
        label:
          title: "As path is walked, keep or prune connected nodes on selected steps"
        input:
          type: "select"
        options : [
            label: "Directional (pruned)"
            value: "directional_path"
            selected: true
          ,
            label: "Non-directional (pruned)"
            value: "pruned_path"
          ,
            label: "Non-directional (unpruned)"
            value: "hairy_path"
        ]
        event_type: "change"
    ,
      make_nodes_for_literals:
        style: "color:orange"
        text: "Make nodes for literals"
        label:
          title: "show literal values (dates, strings, numbers) as nodes"
        input:
          type: "checkbox"
          checked: "checked"
        event_type: "change"
    ,
      show_hide_endpoint_loading:
        style: "color:orange"
        text: "Show SPARQL endpoint loading forms"
        label:
          title: "Show SPARQL endpoint interface for querying for nodes"
        input:
          type: "checkbox"
    ,
      show_hide_performance_monitor:
        style: "color:orange"
        text: "Show Performance Monitor"
        label:
          title: "Feedback on what HuViz is doing"
        input:
          type: "checkbox"
    ,
      graph_title_style:
        text: "Title display "
        label:
          title: "Select graph title style"
        input:
          type: "select"
        options : [
            label: "Watermark"
            value: "subliminal"
          ,
            label: "Bold Titles 1"
            value: "bold1"
          ,
            label: "Bold Titles 2"
            value: "bold2"
          ,
            label: "Custom Captions"
            value: "custom"
        ]
        event_type: "change",
    ,
      graph_custom_main_title:
        style: "display:none"
        text: "Custom Title"
        label:
          title: "Title that appears on the graph background"
        input:
          type: "text"
          size: "16"
          placeholder: "Enter Title"
        event_type: "change"
    ,
      graph_custom_sub_title:
        style: "display:none"
        text: "Custom Sub-title"
        label:
          title: "Sub-title that appears below main title"
        input:
          type: "text"
          size: "16"
          placeholder: "Enter Sub-title"
        event_type: "change"
    ,
      debug_shelf_angles_and_flipping:
        style: "color:orange;display:none"
        text: "debug shelf angles and flipping"
        label:
          title: "show angles and flags with labels"
        input:
          type: "checkbox"   #checked: "checked"
        event_type: "change"
    ,
      language_path:
        text: "Language Path"
        label:
          title: "Preferred languages in order, with : separator."
        input:
          type: "text"
          # TODO tidy up -- use browser default language then English
          value: (window.navigator.language.substr(0,2) + ":en:ANY:NOLANG").replace("en:en:","en:")
          size: "16"
          placeholder: "en:es:fr:de:ANY:NOLANG"
        event_type: "change"
    ,
      show_class_instance_edges:
        style: "color:orange"
        text: "Show class-instance relationships"
        label:
          title: "display the class-instance relationship as an edge"
        input:
          type: "checkbox"
          #checked: "checked"
        event_type: "change"
    ,
      discover_geonames_as:
        style: "color:orange"
        html_text: '<a href="http://www.geonames.org/login" taret="geonamesAcct">Geonames</a> Username'
        label:
          title: "The GeoNames Username to look up geonames as"
        input:
          type: "text"
          value: "" # "smurp_nooron"
          size: "16"
          placeholder: "eg huviz"
        event_type: "change"
    ,
      discover_geonames_remaining:
        style: "color:orange"
        text: 'GeoNames Limit '
        label:
          title: "The number of Remaining Geonames to look up"
        input:
          type: "integer"
          value: 20
          size: 6
        event_type: "change"
    ,
      discover_geonames_greedily:
        style: "color:orange"
        text: "Capture GeoNames Greedily"
        label:
          title: "Capture not just names but population"
        input:
          type: "checkbox"
          #checked: "checked"
        event_type: "change"
    ,
      discover_geonames_deeply:
        style: "color:orange"
        text: "Capture GeoNames Deeply"
        label:
          title: "Capture not directly referenced but the containing geographical places from GeoNames"
        input:
          type: "checkbox"
          #checked: "checked"
        event_type: "change"
    ,
      show_edge_labels_adjacent_to_labelled_nodes:
        style: "color:orange"
        text: "Show adjacent edge labels"
        label:
          title: "Show edge labels adjacent to labelled nodes"
        input:
          type: "checkbox"
          #checked: "checked"
        event_type: "change"
    ,
      show_hunt_verb:
        style: "color:orange;display:none"
        text: "Show Hunt verb"
        label:
          title: "Show the Hunt verb"
        input:
          type: "checkbox"
          #checked: "checked"
        event_type: "change"
    ]

  dump_current_settings: (post) =>
    $("#tabs-options,.graph_controls").html("")
    @init_graph_controls_from_json()
    @on_change_graph_title_style("subliminal")
    @on_change_prune_walk_nodes("directional_path")

  auto_adjust_settings: ->
    # Try to tune the gravity, charge and link length to suit the data and the canvas size.
    return @

  init_graph_controls_from_json: =>
    #@graph_controls_cursor = new TextCursor(@args.graph_controls_sel, "")
    @graph_controls_cursor = new TextCursor(".graph_control input", "")
    if @graph_controls_cursor
      $("input").on("mouseover", @update_graph_controls_cursor)
      #$("input").on("mouseenter", @update_graph_controls_cursor)
      #$("input").on("mousemove", @update_graph_controls_cursor)
    @graph_controls = d3.select(@args.graph_controls_sel)
    @graph_controls.classed('graph_controls',true)
    #$(@graph_controls).sortable().disableSelection() # TODO fix dropping
    for control_spec in @default_graph_controls
      for control_name, control of control_spec
        graph_control = @graph_controls.append('div').attr('id',control_name).attr('class', 'graph_control')
        label = graph_control.append('label')
        if control.text?
          label.text(control.text)
        if control.html_text
          label.html(control.html_text)
        if control.label?
          label.attr(control.label)
        if control.style?
          graph_control.attr("style", control.style)
        if control.class?
          graph_control.attr('class', 'graph_control ' + control.class)
        if control.input.type is 'select'
          input = label.append('select')
          input.attr("name", control_name)
          for a,v of control.options
            option = input.append('option')
            if v.selected
              option.html(v.label).attr("value", v.value).attr("selected", "selected")
            else
              option.html(v.label).attr("value", v.value)
          #label.append("input").attr("name", "custom_title").attr("type", "text").attr("style", " ")
          #label.append("input").attr("name", "custom_subtitle").attr("type", "text").attr("style", " ")
        else if control.input.type is 'button'
          input = label.append('button')
          input.attr("type", "button")
          input.html("Reset All")
          input.on("click", @dump_current_settings)
        else
          input = label.append('input')
          input.attr("name", control_name)
          if control.input?
            for k,v of control.input
              if k is 'value'
                old_val = @[control_name]
                @change_setting_to_from(control_name, v, old_val)
              input.attr(k,v)
          if control.input.type is 'checkbox'
            value = control.input.checked?
            #console.log "control:",control_name,"value:",value, control
            @change_setting_to_from(control_name, value, undefined) #@[control_name].checked)
          # TODO replace control.event_type with autodetecting on_change_ vs on_update_ method existence

        if control.event_type is 'change'
          input.on("change", @update_graph_settings) # when focus changes
        else
          input.on("input", @update_graph_settings) # continuous updates
    $("#tabs-options").append("<div id='buffer_space'></div>")
    return

  update_graph_controls_cursor: (evt) =>
    cursor_text = (evt.target.value).toString()
    if !cursor_text
      console.debug(cursor_text)
    else
      console.log(cursor_text)
    @graph_controls_cursor.set_text(cursor_text)

  update_graph_settings: (target, update) =>
    target = target? and target or d3.event.target
    # event_type = d3.event.type
    update = not update? and true or update
    update = not update
    if target.type is "checkbox"
      cooked_value = target.checked
    else if target.type is "range" # must massage into something useful
      asNum = parseFloat(target.value)
      cooked_value = ('' + asNum) isnt 'NaN' and asNum or target.value
    else
      cooked_value = target.value
    old_value = @[target.name]
    @change_setting_to_from(target.name, cooked_value, old_value)
    d3.select(target).attr("title", cooked_value)
    if update  # TODO be more discriminating, not all settings require update
               #   ones that do: charge, gravity, fisheye_zoom, fisheye_radius
      @update_fisheye()
      @updateWindow()
    @tick()

  change_setting_to_from: (setting_name, new_value, old_value, skip_custom_handler) =>
    skip_custom_handler = skip_custom_handler? and skip_custom_handler or false
    # TODO replace control.event_type with autodetecting on_change_ vs on_update_ method existence
    custom_handler_name = "on_change_" + setting_name
    custom_handler = @[custom_handler_name]
    if @graph_controls_cursor
      cursor_text = (new_value).toString()
      #console.info("#{setting_name}: #{cursor_text}")
      @graph_controls_cursor.set_text(cursor_text)
    if custom_handler? and not skip_custom_handler
      #console.log "change_setting_to_from() custom setting: #{setting_name} to:#{new_value}(#{typeof new_value}) from:#{old_value}(#{typeof old_value})"
      custom_handler.apply(@, [new_value, old_value])
    else
      #console.log "change_setting_to_from() setting: #{setting_name} to:#{new_value}(#{typeof new_value}) from:#{old_value}(#{typeof old_value})"
      this[setting_name] = new_value

  # on_change handlers for the various settings which need them
  on_change_nodes_pinnable: (new_val, old_val) ->
    if not new_val
      if @graphed_set
        for node in @graphed_set
          node.fixed = false

  on_change_show_hunt_verb: (new_val, old_val) ->
    if new_val
      vset = {hunt: @human_term.hunt}
      @gclui.verb_sets.push(vset)
      @gclui.add_verb_set(vset)

  on_change_show_dangerous_datasets: (new_val, old_val) ->
    if new_val
      $('option.dangerous').show()
      $('option.dangerous').text (idx, text) ->
        append = ' (!)'
        if not text.match(/\(\!\)$/)
          return text + append
        return text
    else
      $('option.dangerous').hide()

  on_change_pill_display: (new_val) ->
    if new_val
      node_display_type = 'pills'
      $("input[name='charge']").attr('min', '-5000').attr('value', '-3000')
      $("input[name='link_distance']").attr('max', '500').attr('value', '200')
      @charge = -3000
      @link_distance = 200
    else
      node_display_type = ""
      $("input[name='charge']").attr('min', '-600').attr('value', '-200')
      $("input[name='link_distance']").attr('max', '200').attr('value', '29')
      @charge = -200
      @link_distance = 29
    @updateWindow()

  on_change_theme_colors: (new_val) ->
    if new_val
      renderStyles = themeStyles.dark
      $("body").removeClass themeStyles.light.themeName
    else
      renderStyles = themeStyles.light
      $("body").removeClass themeStyles.dark.themeName
    #@update_graph_settings()
    $("body").css "background-color", renderStyles.pageBg
    $("body").addClass renderStyles.themeName
    @updateWindow()

  on_change_display_label_cartouches: (new_val) ->
    if new_val
      @cartouches = true
    else
      @cartouches = false
    @updateWindow()

  on_change_display_shelf_clockwise: (new_val) ->
    if new_val
      @display_shelf_clockwise = true
    else
      @display_shelf_clockwise = false
    @updateWindow()

  on_change_choose_node_display_angle: (new_val) ->
    nodeOrderAngle = new_val
    @updateWindow()

  on_change_shelf_radius: (new_val, old_val) ->
    @change_setting_to_from('shelf_radius', new_val, old_val, true)
    @update_graph_radius()
    @updateWindow()

  on_change_truncate_labels_to: (new_val, old_val) ->
    @change_setting_to_from('truncate_labels_to', new_val, old_val, true)
    if @all_set
      for node in @all_set
        @unscroll_pretty_name(node)
    @updateWindow()

  on_change_graph_title_style: (new_val, old_val) ->
    if new_val is "custom"
      $(".main_title").removeAttr("style")
      $(".sub_title").removeAttr("style")
      $("#graph_custom_main_title").css('display', 'inherit')
      $("#graph_custom_sub_title").css('display', 'inherit')
      custTitle = $("input[name='graph_custom_main_title']")
      custSubTitle = $("input[name='graph_custom_sub_title']")
      @update_caption(custTitle[0].title, custSubTitle[0].title)
      $("a.git_commit_hash_watermark").css('display', 'none')
      $("#ontology_watermark").attr('style', '')
    else if new_val is "bold1"
      $("#ontology_watermark").css('display', 'none')
    else
      $("#graph_custom_main_title").css('display', 'none')
      $("#graph_custom_sub_title").css('display', 'none')
      $("a.git_commit_hash_watermark").css('display', 'inherit')
      $("#ontology_watermark").attr('style', '')
      @update_caption(@dataset_loader.value,@ontology_loader.value)
    $("#dataset_watermark").removeClass().addClass(new_val)
    $("#ontology_watermark").removeClass().addClass(new_val)

  on_change_graph_custom_main_title: (new_val) ->
    # if new custom values then update titles
    $("#dataset_watermark").text(new_val)

  on_change_graph_custom_sub_title: (new_val) ->
    $("#ontology_watermark").text(new_val)

  on_change_language_path: (new_val, old_val) ->
    try
      MultiString.set_langpath(new_val)
    catch e
      alert("Input: #{new_val}\n#{e.toString()}\n\n  The 'Language Path' should be a colon-separated list of ISO two-letter language codes, such as 'en' or 'fr:en:es'.  One can also include the keywords ANY, NOLANG or ALL in the list.\n  'ANY' means show a value from no particular language and works well in situations where you don't know or care which language is presented.\n  'NOLANG' means show a value for which no language was specified.\n  'ALL' causes all the different language versions to be revealed. It is best used alone\n\nExamples (show first available, so order matters)\n  en:fr\n    show english or french or nothing\n  en:ANY:NOLANG\n    show english or ANY other language or language-less label\n  ALL\n    show all versions available, language-less last")
      @change_setting_to_from('language_path', old_val, old_val)
      return
    if @shelved_set
      @shelved_set.resort()
      @discarded_set.resort()
    @update_labels_on_pickers()
    @gclui?.resort_pickers()
    if @ctx?
      @tick()
    return

  on_change_color_nodes_as_pies: (new_val, old_val) ->  # TODO why this == window ??
    @color_nodes_as_pies = new_val
    @recolor_nodes()

  on_change_prune_walk_nodes: (new_val, old_val) ->
    @prune_walk_nodes = new_val

  on_change_show_hide_endpoint_loading: (new_val, old_val) ->
    if @endpoint_loader
      endpoint = "#" + @endpoint_loader.uniq_id
    if new_val and endpoint
      $(endpoint).css('display','block')
    else
      $(endpoint).css('display','none')

  on_change_show_hide_performance_monitor: (new_val, old_val) ->
    console.log "clicked performance monitor " + new_val + " " + old_val
    if new_val
      $("#performance_dashboard").css('display','block')
      @pfm_display = true
      @pfm_dashboard()
      @timerId = setInterval(@pfm_update, 1000)
    else
      clearInterval(@timerId)
      $("#performance_dashboard").css('display','none').html('')
      @pfm_display = false

  on_change_discover_geonames_as: (new_val, old_val) ->
    @discover_geonames_as = new_val
    if new_val
      if @nameless_set
        @discover_names()

  init_from_graph_controls: ->
    # alert "init_from_graph_controls() is deprecated"
    # Perform update_graph_settings for everything in the form
    # so the HTML can be used as configuration file
    for elem in $(".graph_controls input") # so we can modify them in a loop
      @update_graph_settings(elem, false)

  after_file_loaded: (uri, callback) ->
    #@show_node_pred_edge_stats()
    @fire_fileloaded_event(uri)
    if callback
      callback()

  show_node_pred_edge_stats: ->
    pred_count = 0
    edge_count = 0

    s = "nodes:#{@nodes.length} predicates:#{pred_count} edges:#{edge_count}"
    console.log(s)
    debugger

  fire_fileloaded_event: (uri) ->
    document.dispatchEvent(new CustomEvent("dataset-loaded", {detail: uri}))
    window.dispatchEvent(
      new CustomEvent 'fileloaded',
        detail:
          message: "file loaded"
          time: new Date()
        bubbles: true
        cancelable: true
    )

  XXX_load_file: ->
    @load_data_with_onto(@get_dataset_uri())

  load_data_with_onto: (data, onto, callback) ->  # Used for loading files from menu
    @data_uri = data.value
    @set_ontology(onto.value)
    if @args.display_reset
      $("#reset_btn").show()
    else
      #@disable_data_set_selector()
      @disable_dataset_ontology_loader(data, onto)
    @show_state_msg("loading...")
    #@init_from_graph_controls()
    #@dump_current_settings("after init_from_graph_controls()")
    #@reset_graph()
    @show_state_msg @data_uri
    unless @G.subjects
      @fetchAndShow(@data_uri, callback)

  disable_data_set_selector: () ->
    $("[name=data_set]").prop('disabled', true)
    $("#reload_btn").show()

  read_data_and_show: (filename, data) -> #Handles drag-and-dropped files
    data = @local_file_data
    #console.log data
    if filename.match(/.ttl$/)
      the_parser = @parseAndShowTTLData
    else if filename.match(/.nq$/)
      the_parser = @parse_and_show_NQ_file
    else
      alert("Unknown file format. Unable to parse '#{filename}'. Only .ttl and .nq files supported.")
      return
    the_parser(data)
    #@local_file_data = "" #RESET the file data
    #@disable_data_set_selector()
    @disable_dataset_ontology_loader()
    #@show_state_msg("loading...")
    #@show_state_msg filename

  get_dataset_uri: () ->
    # FIXME goodbye jquery
    return $("select.file_picker option:selected").val()

  run_script_from_hash: ->
    script = @get_script_from_hash()
    if script?
      @gclui.run_script(script)
    return

  get_script_from_hash: () ->
    script = location.hash
    script = (not script? or script is "#") and "" or script.replace(/^#/,"")
    script = script.replace(/\+/g," ")
    console.log("script", script)
    return script

  # recognize that changing this will likely break old hybrid HuVizScripts
  json_script_marker: "# JSON FOLLOWS"

  load_script_from_JSON: (json) ->
    #alert('load_script_from_JSON')
    for cmdArgs in json
      @gclui.push_command_onto_history(@gclui.new_GraphCommand(cmdArgs))
    #@gclui.reset_command_history()

  parse_script_file: (data, fname) ->
    # There are two file formats, both with the extension .txt
    #   1) * Commands as they appear in the Command History
    #      * Followed by the comment on a line of its own
    #      * Followed by the .json version of the script, for trivial parsing
    #   2) Commands as they appear in the Command History
    # The thinking is that, ultimately, version 1) will be required until the
    # parser for the textual version is complete.
    lines = data.split('\n')
    while lines.length
      line = lines.shift()
      if line.includes(@json_script_marker)
        return JSON.parse(lines.join("\n"))
    return {}

  # this is where the file should be read and run
  #@huviz.load_script_from_JSON(@parse_script_file(evt.target.result, firstFile.name))

  boot_sequence: (script) ->
    # If we are passed an empty string that means there was an outer
    # script but there was nothing for us and DO NOT examine the hash for more.
    # If there is a script after the hash, run it.
    # Otherwise load the default dataset defined by the page.
    # Or load nothing if there is no default.
    #@init_from_graph_controls()
    # $(".graph_controls").sortable() # FIXME make graph_controls sortable
    @reset_graph()
    if not script?
      script = @get_script_from_hash()
    if script? and script.length
      console.log("boot_sequence('#{script}')")
      @gclui.run_script(script)
    else
      data_uri = @get_dataset_uri()
      if data_uri
        @load(data_uri)

  load: (data_uri, callback) ->
    @fetchAndShow(data_uri, callback) unless @G.subjects
    if @use_webgl
      @init_webgl()

  load_with: (data_uri, ontology_uris) ->
    @goto_tab(1) # go to Commands tab # FIXME: should be symbolic not int indexed
    basename = (uri) ->
      return uri.split('/').pop().split('.').shift() # the filename without the ext
    dataset =
      label: basename(data_uri)
      value: data_uri
    ontology =
      label: basename(ontology_uris[0])
      value: ontology_uris[0]
    @visualize_dataset_using_ontology({}, dataset, [ontology])

  # TODO: remove now that @get_or_create_node_by_id() sets type and name
  is_ready: (node) ->
    # Determine whether there is enough known about a node to make it visible
    # Does it have an .id and a .type and a .name?
    return node.id? and node.type? and node.name?

  assign_types: (node, within) ->
    type_id = node.type # FIXME one of type or taxon_id gotta go, bye 'type'
    if type_id
      #console.log "assign_type",type_id,"to",node.id,"within",within,type_id
      @get_or_create_taxon(type_id).register(node)
    else
      throw "there must be a .type before hatch can even be called:"+node.id+ " "+type_id
      #console.log "assign_types failed, missing .type on",node.id,"within",within,type_id

  is_big_data: () ->
    if not @big_data_p?
      #if @nodes.length > 200
      if @data_uri?.match('poetesses|relations')
        @big_data_p = true
      else
        @big_data_p = false
    return @big_data_p

  get_default_set_by_type: (node) ->
    # see Orlando.get_default_set_by_type
    #console.log "get_default_set_by_type",node
    if @is_big_data()
      if node.type in ['writer']
        return @shelved_set
      else
        return @hidden_set
    return @shelved_set

  get_default_set_by_type: (node) ->
    return @shelved_set


  pfm_dashboard: () =>
    # Adding feedback monitor
    #   1. new instance in pfm_data (line 541)
    #   2. add @pfm_count('name') to method
    #   3. add #{@build_pfm_live_monitor('name')} into message below
    warning = ""
    message = """
      <div class='feedback_module'><p>Triples Added: <span id="noAddQuad">0</span></p></div>
      <div class='feedback_module'><p>Number of Nodes: <span id="noN">0</span></p></div>
      <div class='feedback_module'><p>Number of Edges: <span id="noE">0</span></p></div>
      <div class='feedback_module'><p>Number of Predicates: <span id="noP">0</span></p></div>
      <div class='feedback_module'><p>Number of Classes: <span id="noC">0</span></p></div>
      #{@build_pfm_live_monitor('add_quad')}
      #{@build_pfm_live_monitor('hatch')}
      <div class='feedback_module'><p>Ticks in Session: <span id="noTicks">0</span></p></div>
      #{@build_pfm_live_monitor('tick')}
      <div class='feedback_module'><p>Total SPARQL Requests: <span id="noSparql">0</span></p></div>
      <div class='feedback_module'><p>Outstanding SPARQL Requests: <span id="noOR">0</span></p></div>
      #{@build_pfm_live_monitor('sparql')}
    """
    $("#performance_dashboard").html(message + warning)

  build_pfm_live_monitor: (name) =>
    label = @pfm_data["#{name}"]["label"]
    monitor = "<div class='feedback_module'>#{label}: <svg id='pfm_#{name}' class='sparkline' width='200px' height='50px' stroke-width='1'></svg></div>"
    return monitor

  pfm_count: (name) =>
    # Incriment the global count for 'name' variable (then used to update live counters)
    @pfm_data["#{name}"].total_count++

  pfm_update: () =>
    time = Date.now()
    class_count = 0
    # update static markers
    if @nodes then noN = @nodes.length else noN = 0
    $("#noN").html("#{noN}")
    if @edge_count then noE = @edge_count else noE = 0
    $("#noE").html("#{noE}")
    if @predicate_set then noP = @predicate_set.length else noP = 0
    $("#noP").html("#{noP}")
    for item of @taxonomy #TODO Should improve this by avoiding recount every second
      class_count++
    @pfm_data.taxonomy.total_count = class_count
    $("#noC").html("#{@pfm_data.taxonomy.total_count}")
    $("#noTicks").html("#{@pfm_data.tick.total_count}")
    $("#noAddQuad").html("#{@pfm_data.add_quad.total_count}")
    $("#noSparql").html("#{@pfm_data.sparql.total_count}")
    if @endpoint_loader then noOR = @endpoint_loader.outstanding_requests else noOR = 0
    $("#noOR").html("#{noOR}")

    for pfm_marker of @pfm_data
      marker = @pfm_data["#{pfm_marker}"]
      old_count = marker.prev_total_count
      new_count = marker.total_count
      calls_per_second = Math.round(new_count - old_count)
      if @pfm_data["#{pfm_marker}"]["timed_count"] and (@pfm_data["#{pfm_marker}"]["timed_count"].length > 0)
        #console.log marker.label + "  " + calls_per_second
        if (@pfm_data["#{pfm_marker}"]["timed_count"].length > 60) then @pfm_data["#{pfm_marker}"]["timed_count"].shift()
        @pfm_data["#{pfm_marker}"].timed_count.push(calls_per_second)
        @pfm_data["#{pfm_marker}"].prev_total_count = new_count + 0.01
        #console.log "#pfm_#{pfm_marker}"
        sparkline.sparkline(document.querySelector("#pfm_#{pfm_marker}"), @pfm_data["#{pfm_marker}"].timed_count)
      else if (@pfm_data["#{pfm_marker}"]["timed_count"])
        @pfm_data["#{pfm_marker}"]["timed_count"] = [0.01]
        #console.log "Setting #{marker.label }to zero"


class OntologicallyGrounded extends Huviz
  # If OntologicallyGrounded then there is an associated ontology which informs
  # the TaxonPicker and the PredicatePicker, rather than the pickers only
  # being informed by implicit ontological hints such as
  #   _:Fred a foaf:Person .  # tells us Fred is a Person
  #   _:Fred dc:name "Fred" . # tells us the predicate_picker needs "name"
  set_ontology: (ontology_uri) ->
    #@init_ontology()
    @read_ontology(ontology_uri)

  read_ontology: (ontology_uri) ->
    $.ajax
      url: ontology_uri
      async: false
      success: @parseTTLOntology
      error: (jqxhr, textStatus, errorThrown) =>
        @show_state_msg(errorThrown + " while fetching ontology " + ontology_uri)

  parseTTLOntology: (data, textStatus) =>
    # detect (? rdfs:subClassOf ?) and (? ? owl:Class)
    # Analyze the ontology to enable proper structuring of the
    # predicate_picker and the taxon_picker.  Also to support
    # imputing 'type' (and hence Taxon) to nodes.
    ontology = @ontology
    if GreenerTurtle? and @turtle_parser is 'GreenerTurtle'
      @raw_ontology = new GreenerTurtle().parse(data, "text/turtle")
      for subj_uri, frame of @raw_ontology.subjects
        subj_lid = uniquer(subj_uri)
        for pred_id, pred of frame.predicates
          pred_lid = uniquer(pred_id)
          for obj in pred.objects
            obj_raw = obj.value
            if pred_lid in ['comment']
              #console.error "  skipping",subj_lid, pred_lid #, pred
              continue
            if pred_lid is 'label' # commented out by above test
              label = obj_raw
              if ontology.label[subj_lid]?
                ontology.label[subj_lid].set_val_lang(label, obj.language)
              else
                ontology.label[subj_lid] = new MultiString(label, obj.language)
            obj_lid = uniquer(obj_raw)
            #if pred_lid in ['range','domain']
            #  console.log pred_lid, subj_lid, obj_lid
            if pred_lid is 'domain'
              ontology.domain[subj_lid] = obj_lid
            else if pred_lid is 'range'
              if not ontology.range[subj_lid]?
                ontology.range[subj_lid] = []
              if not (obj_lid in ontology.range)
                ontology.range[subj_lid].push(obj_lid)
            else if pred_lid in ['subClassOf', 'subClass']
              ontology.subClassOf[subj_lid] = obj_lid
            else if pred_lid is 'subPropertyOf'
              ontology.subPropertyOf[subj_lid] = obj_lid

        #
        # [ rdf:type owl:AllDisjointClasses ;
        #   owl:members ( :Organization
        #                 :Person
        #                 :Place
        #                 :Sex
        #                 :Work
        #               )
        # ] .
        #
        # If there exists (_:1, rdfs:type, owl:AllDisjointClasses)
        # Then create a root level class for every rdfs:first in rdfs:members

class Orlando extends OntologicallyGrounded
  # These are the Orlando specific methods layered on Huviz.
  # These ought to be made more data-driven.

  constructor: ->
    super
    @run_script_from_hash()

  get_default_set_by_type: (node) ->
    if @is_big_data()
      if node.type in ['writer']
        return @shelved_set
      else
        return @hidden_set
    return @shelved_set

  HHH: {}

  make_link: (uri, text, target) ->
    uri ?= ""
    target ?= synthIdFor(uri.replace(/\#.*$/,'')) # open only one copy of each document
    text ?= uri
    return """<a target="#{target}" href="#{uri}">#{text}</a>"""

  push_snippet: (msg_or_obj) ->
    obj = msg_or_obj
    fontSize = @snippet_triple_em
    if @snippet_box
      if typeof msg_or_obj isnt 'string'
        [msg_or_obj, m] = ["", msg_or_obj]  # swap them
        if obj.quad.obj_uri
          obj_dd = """#{@make_link(obj.quad.obj_uri)}"""
        else
          dataType_uri = m.edge.target.__dataType or ""
          dataType = ""
          if dataType_uri
            dataType_curie = m.edge.target.type.replace('__',':')
            #dataType = """^^<a target="_" href="#{dataType_uri}">#{dataType_curie}</a>"""
            dataType = "^^#{@make_link(dataType_uri, dataType_curie)}"
          obj_dd = """"#{obj.quad.obj_val}"#{dataType}"""
        msg_or_obj = """
        <div id="#{obj.snippet_js_key}">
          <div style="font-size:#{fontSize}em">
            <h3>subject</h3>
            <div class="snip_circle" style="background-color:#{m.edge.source.color}; width: #{fontSize * 2.5}em; height: #{fontSize * 2.5}em;"></div>
            <p style="margin-left: #{fontSize * 3.5}em">#{@make_link(obj.quad.subj_uri)}</p>

            <h3>predicate </h3>
            <div class="snip_arrow">
              <div class="snip_arrow_stem" style="width: #{fontSize * 2}em; height: #{fontSize * 1}em; margin-top: #{fontSize * 0.75}em; background-color:#{m.edge.color};"></div>
              <div class="snip_arrow_head" style="border-color: transparent transparent transparent #{m.edge.color};border-width: #{fontSize * 1.3}em 0 #{fontSize * 1.3}em #{fontSize * 2.3}em;"></div>
            </div>
            <p class="pred" style="margin-left: #{fontSize * 4.8}em">#{@make_link(obj.quad.pred_uri)}</p>

            <h3>object </h3>
            <div class="snip_circle" style="background-color:#{m.edge.target.color}; width: #{fontSize * 2.5}em; height: #{fontSize * 2.5}em;"></div>
            <p style="margin-left: #{fontSize * 3.5}em">#{obj_dd}</p>

            <h3>source</h3>
            <p style="margin-left: #{fontSize * 2.5}em">#{@make_link(obj.quad.graph_uri)}</p>
          </div>
        </div>

        """
        ## unconfuse emacs Coffee-mode: " """ ' '  "
      super(obj, msg_or_obj) # fail back to super

  human_term: orlando_human_term

class OntoViz extends Huviz #OntologicallyGrounded
  human_term: orlando_human_term
  HHH: # hardcoded hierarchy hints, kv pairs of subClass to superClass
    ObjectProperty: 'Thing'
    Class: 'Thing'
    SymmetricProperty: 'ObjectProperty'
    IrreflexiveProperty: 'ObjectProperty'
    AsymmetricProperty: 'ObjectProperty'

  ontoviz_type_to_hier_map:
    RDF_type: "classes"
    OWL_ObjectProperty: "properties"
    OWL_Class: "classes"

  use_lid_as_node_name: true
  snippet_count_on_edge_labels: false

  DEPRECATED_try_to_set_node_type: (node,type) ->
    # FIXME incorporate into ontoviz_type_to_hier_map
    #
    if type.match(/Property$/)
      node.type = 'properties'
    else if type.match(/Class$/)
      node.type = 'classes'
    else
      console.log(node.id+".type is", type)
      return false
    console.log("try_to_set_node_type", node.id, "=====", node.type)
    return true

  # first, rest and members are produced by GreenTurtle regarding the AllDisjointClasses list
  predicates_to_ignore: ["anything", "comment", "first", "rest", "members"]

class Socrata extends Huviz
  ###
  # Inspired by https://data.edmonton.ca/
  #             https://data.edmonton.ca/api/views{,.json,.rdf,...}
  #
  ###
  categories = {}
  ensure_category: (category_name) ->
    cat_id = category_name.replace /\w/, '_'
    if @categories[category_id]?
      @categories[category_id] = category_name
      @assert_name category_id,category_name
      @assert_instanceOf category_id,DC_subject
    return cat_id

  assert_name: (uri,name,g) ->
    name = name.replace(/^\s+|\s+$/g, '')
    @add_quad
      s: uri
      p: RDFS_label
      o:
        type: RDF_literal
        value: stripped_name

  assert_instanceOf: (inst,clss,g) ->
    @add_quad
      s: inst
      p: RDF_a
      o:
        type: RDF_object
        value: clss

  assert_propertyValue: (sub_uri,pred_uri,literal) ->
    console.log("assert_propertyValue", arguments)
    @add_quad
      s: subj_uri
      p: pred_uri
      o:
        type: RDF_literal
        value: literal

  assert_relation: (subj_uri,pred_uri,obj_uri) ->
    console.log("assert_relation", arguments)
    @add_quad
      s: subj_uri
      p: pred_uri
      o:
        type: RDF_object
        value: obj_uri

  parseAndShowJSON: (data) =>
    #TODO Currently not working/tested
    console.log("parseAndShowJSON",data)
    g = @DEFAULT_CONTEXT

    #  https://data.edmonton.ca/api/views/sthd-gad4/rows.json

    for dataset in data
      #dataset_uri = "https://data.edmonton.ca/api/views/#{dataset.id}/"
      console.log(@dataset_uri)
      q =
        g: g
        s: dataset_uri
        p: RDF_a
        o:
          type: RDF_literal
          value: 'dataset'
      console.log(q)
      @add_quad(q)
      for k,v of dataset
        if not is_on_of(k,['category','name','id']) # ,'displayType'
          continue
        q =
          g: g
          s: dataset_uri
          p: k
          o:
            type:  RDF_literal
            value: v
        if k == 'category'
          cat_id = @ensure_category(v)
          @assert_instanceOf(dataset_uri, OWL_Class)
          continue
        if k == 'name'
          assert_propertyValue dataset_uri, RDFS_label, v
          continue
        continue

        if typeof v == 'object'
          continue
        if k is 'name'
          console.log(dataset.id, v)
        #console.log k,typeof v
        @add_quad(q)
        #console.log q

class PickOrProvide
  tmpl: """
	<form id="UID" class="pick_or_provide_form" method="post" action="" enctype="multipart/form-data">
    <span class="pick_or_provide_label">REPLACE_WITH_LABEL</span>
    <select name="pick_or_provide"></select>
    <button type="button" class="delete_option"><i class="fa fa-trash" style="font-size: 1.2em;"></i></button>
  </form>
  """
  uri_file_loader_sel: '.uri_file_loader_form'

  constructor: (@huviz, @append_to_sel, @label, @css_class, @isOntology, @isEndpoint, @opts) ->
    @opts ?= {}
    @uniq_id = unique_id()
    @select_id = unique_id()
    @pickable_uid = unique_id()
    @your_own_uid = unique_id()
    @find_or_append_form()
    dndLoaderClass = @opts.dndLoaderClass or DragAndDropLoader
    @drag_and_drop_loader = new dndLoaderClass(@huviz, @append_to_sel, @)
    @drag_and_drop_loader.form.hide()
    #@add_group({label: "-- Pick #{@label} --", id: @pickable_uid})
    @add_group({label: "Your Own", id: @your_own_uid}, 'append')
    @add_option({label: "Provide New #{@label} ...", value: 'provide'}, @select_id)
    @add_option({label: "Pick or Provide...", canDelete: false}, @select_id, 'prepend')
    @

  val: (val) ->
    console.log("#{@label}.val(#{val})")
    @pick_or_provide_select.val(val)
    #@pick_or_provide_select.change()
    #@value = val
    @refresh()

  disable: ->
    @pick_or_provide_select.prop('disabled', true)
    @form.find('.delete_option').hide()

  enable: ->
    @pick_or_provide_select.prop('disabled', false)
    @form.find('.delete_option').show()

  select_option: (option) ->
    new_val = option.val()
    #console.table([{last_val: @last_val, new_val: new_val}])
    cur_val = @pick_or_provide_select.val()
    # TODO remove last_val = null in @init_resource_menus() by fixing logic below
    #   What is happening is that the AJAX loading of preloads means that
    #   it is as if each of the new datasets is being selected as it is
    #   added -- but when the user picks an actual ontology then
    #   @set_ontology_from_dataset_if_possible() fails if the new_val == @last_val
    if cur_val isnt @last_val and not @isOntology
      @last_val = cur_val
    if @last_val isnt new_val
      @last_val = new_val
      if new_val
        @pick_or_provide_select.val(new_val)
      else
        console.warn("TODO should set option to nothing")
        # @pick_or_provide_select.val()
      #if confirm("refresh?")
      #  @refresh()

  add_uri: (uri_or_rec) =>
    if typeof uri_or_rec is 'string'
      uri = uri_or_rec
      rsrcRec = {}
    else
      rsrcRec = uri_or_rec
    rsrcRec.uri ?= uri
    rsrcRec.isOntology ?= @isOntology
    rsrcRec.isEndpoint ?= @isEndpoint
    rsrcRec.time ?= (new Date()).toISOString()
    rsrcRec.isUri ?= true
    rsrcRec.title ?= rsrcRec.uri
    rsrcRec.canDelete ?= not not rsrcRec.time?
    rsrcRec.label ?= rsrcRec.uri.split('/').reverse()[0] or rsrcRec.uri
    if rsrcRec.label is "sparql" then rsrcRec.label = rsrcRec.uri
    rsrcRec.rsrcType ?= @opts.rsrcType
    # rsrcRec.data ?= file_rec.data # we cannot add data because for uri we load each time
    @add_resource(rsrcRec, true)
    @update_state()

  add_local_file: (file_rec) =>
    # These are local files which have been 'uploaded' to the browser.
    # As a consequence they cannot be programmatically loaded by the browser
    # and so we cache them
    #local_file_data = file_rec.data
    #@huviz.local_file_data = local_file_data
    if typeof file_rec is 'string'
      uri = file_rec
      rsrcRec = {}
    else
      rsrcRec = file_rec
      rsrcRec.uri ?= uri
      rsrcRec.isOntology ?= @isOntology
      rsrcRec.time ?= (new Date()).toISOString()
      rsrcRec.isUri ?= false
      rsrcRec.title ?= rsrcRec.uri
      rsrcRec.canDelete ?= not not rsrcRec.time?
      rsrcRec.label ?= rsrcRec.uri.split('/').reverse()[0]
      rsrcRec.rsrcType ?= @opts.rsrcType
      rsrcRec.data ?= file_rec.data
    @add_resource(rsrcRec, true)
    @update_state()

  add_resource: (rsrcRec, store_in_db) ->
    uri = rsrcRec.uri
    #rsrcRec.uri ?= uri.split('/').reverse()[0]
    if store_in_db
      @huviz.add_resource_to_db(rsrcRec, @add_resource_option)
    else
      @add_resource_option(rsrcRec)

  add_resource_option: (rsrcRec) => # TODO rename to rsrcRec
    uri = rsrcRec.uri
    rsrcRec.value = rsrcRec.uri
    @add_option(rsrcRec, @pickable_uid)
    @pick_or_provide_select.val(uri)
    @refresh()

  add_group: (grp_rec, which) ->
    which ?= 'append'
    optgrp = $("""<optgroup label="#{grp_rec.label}" id="#{grp_rec.id or unique_id()}"></optgroup>""")
    if which is 'prepend'
      @pick_or_provide_select.prepend(optgrp)
    else
      @pick_or_provide_select.append(optgrp)
    return optgrp

  add_option: (opt_rec, parent_uid, pre_or_append) ->
    pre_or_append ?= 'append'
    if not opt_rec.label?
      console.log("missing .label on", opt_rec)
    if @pick_or_provide_select.find("option[value='#{opt_rec.value}']").length
      #alert "add_option() #{opt_rec.value} collided"
      return
    opt_str = """<option id="#{unique_id()}"></option>"""
    opt = $(opt_str)
    opt_group_label = opt_rec.opt_group
    if opt_group_label
      opt_group = @pick_or_provide_select.find("optgroup[label='#{opt_group_label}']")
      #console.log(opt_group_label, opt_group.length) #, opt_group[0])
      if not opt_group.length
        #blurt("adding '#{opt_group_label}'")
        opt_group = @add_group({label: opt_group_label}, 'prepend')
        # opt_group = $('<optgroup></optgroup>')
        # opt_group.attr('label', opt_group_label)
        # @pick_or_provide_select.append(opt_group)
      #if not opt_group.length
      #  blurt('  but it does not yet exist')
      opt_group.append(opt)
    else # There is no opt_group_label, so this is a top level entry, ie a group, etc
      if pre_or_append is 'append'
        $("##{parent_uid}").append(opt)
      else
        $("##{parent_uid}").prepend(opt)
    for k in ['value', 'title', 'class', 'id', 'style', 'label']
      if opt_rec[k]?
        $(opt).attr(k, opt_rec[k])
    for k in ['isUri', 'canDelete', 'ontologyUri', 'ontology_label'] # TODO standardize on _
      if opt_rec[k]?
        val = opt_rec[k]
        $(opt).data(k, val)
    return opt[0]

  update_state: (callback) ->
    raw_value = @pick_or_provide_select.val()
    selected_option = @get_selected_option()
    label_value = selected_option[0].label
    the_options = @pick_or_provide_select.find("option")
    kid_cnt = the_options.length
    #console.log("#{@label}.update_state() raw_value: #{raw_value} kid_cnt: #{kid_cnt}")
    if raw_value is 'provide'
      @drag_and_drop_loader.form.show()
      @state = 'awaiting_dnd'
      @value = undefined
    else
      @drag_and_drop_loader.form.hide()
      @state = 'has_value'
      @value = raw_value
      @label = label_value
    disable_the_delete_button = true
    if @value?
      canDelete = selected_option.data('canDelete')
      disable_the_delete_button = not canDelete
    # disable_the_delete_button = false  # uncomment to always show the delete button -- useful when bad data stored
    @form.find('.delete_option').prop('disabled', disable_the_delete_button)
    if callback?
      callback()

  find_or_append_form: ->
    if not $(@local_file_form_sel).length
      $(@append_to_sel).append(@tmpl.replace('REPLACE_WITH_LABEL', @label).replace('UID',@uniq_id))
    @form = $("##{@uniq_id}")
    @pick_or_provide_select = @form.find("select[name='pick_or_provide']")
    @pick_or_provide_select.attr('id',@select_id)
    #console.debug @css_class,@pick_or_provide_select
    @pick_or_provide_select.change (e) =>
      #e.stopPropagation()
      @refresh()
    @delete_option_button = @form.find('.delete_option')
    @delete_option_button.click(@delete_selected_option)
    @form.find('.delete_option').prop('disabled', true) # disabled initially
    #console.info "form", @form

  get_selected_option: =>
    @pick_or_provide_select.find('option:selected') # just one CAN be selected

  delete_selected_option: (e) =>
    e.stopPropagation()
    selected_option = @get_selected_option()
    val = selected_option.attr('value')
    if val?
      @huviz.remove_dataset_from_db(@value)
      @delete_option(selected_option)
      @update_state()
      #  @value = null

  delete_option: (opt_elem) ->
    uri = opt_elem.attr('value')
    @huviz.remove_dataset_from_db(uri)
    opt_elem.remove()
    @huviz.update_dataset_ontology_loader()

  refresh: ->
    @update_state(@huviz.update_dataset_ontology_loader)

# inspiration: https://css-tricks.com/drag-and-drop-file-uploading/
class DragAndDropLoader
  tmpl: """
	<form class="local_file_form" method="post" action="" enctype="multipart/form-data">
	  <div class="box__input">
	    <input class="box__file" type="file" name="files[]" id="file" data-multiple-caption="{count} files selected" multiple />
	    <label for="file"><span class="box__label">Choose a local file</span></label>
	    <button class="box__upload_button" type="submit">Upload</button>
      <div class="box__dragndrop" style="display:none"> Drop URL or file here</div>
	  </div>
    <input type="url" class="box__uri" placeholder="Or enter URL here" />
	  <div class="box__uploading" style="display:none">Uploading&hellip;</div>
	  <div class="box__success" style="display:none">Done!</div>
	  <div class="box__error" style="display:none">Error! <span></span>.</div>
  </form>
  """

  constructor: (@huviz, @append_to_sel, @picker) ->
    @local_file_form_id = unique_id()
    @local_file_form_sel = "##{@local_file_form_id}"
    console.log @append_to_sel
    console.log @picker
    @find_or_append_form()
    if @supports_file_dnd()
      @form.show()
      @form.addClass('supports-dnd')
      @form.find(".box__dragndrop").show()
  supports_file_dnd: ->
    div = document.createElement('div')
    return true
    return (div.draggable or div.ondragstart) and ( div.ondrop ) and
      (window.FormData and window.FileReader)
  load_uri: (firstUri) ->
    #@form.find('.box__success').text(firstUri)
    #@form.find('.box__success').show()
    #TODO SHOULD selection be added to the picker here, or wait for after successful?
    @picker.add_uri({uri: firstUri, opt_group: 'Your Own'})
    @form.hide()
    return true # ie success
  load_file: (firstFile) ->
    @huviz.local_file_data = "empty"
    filename = firstFile.name
    @form.find('.box__success').text(firstFile.name) #TODO Are these lines still needed?
    @form.find('.box__success').show()
    reader = new FileReader()
    reader.onload = (evt) =>
      #console.log evt.target.result
      #console.log("evt", evt)
      try
        #@huviz.read_data_and_show(firstFile.name, evt.target.result)
        if filename.match(/.(ttl|.nq)$/)
          @picker.add_local_file({uri: firstFile.name, opt_group: 'Your Own'})
          @huviz.local_file_data = evt.target.result
        else
          #$("##{@dataset_loader.select_id} option[label='Pick or Provide...']").prop('selected', true)
          blurt("Unknown file format. Unable to parse '#{filename}'. " +
                "Only .ttl and .nq files supported.", 'alert')
          @huviz.reset_dataset_ontology_loader()
          $('.delete_option').attr('style','')
      catch e
        msg = e.toString()
        #@form.find('.box__error').show()
        #@form.find('.box__error').text(msg)
        blurt(msg, 'error')
    reader.readAsText(firstFile)
    return true # ie success
  find_or_append_form: ->
    num_dnd_form = $(@local_file_form_sel).length
    if not num_dnd_form
      elem = $(@tmpl)
      $(@append_to_sel).append(elem)
      elem.attr('id', @local_file_form_id)
    @form = $(@local_file_form_sel)
    @form.on 'submit unfocus', (e) =>
      console.log e
      uri_field = @form.find('.box__uri')
      uri = uri_field.val()
      if uri_field[0].checkValidity()
        uri_field.val('')
        @load_uri(uri)
      return false
    @form.on 'drag dragstart dragend dragover dragenter dragleave drop', (e) =>
      #console.clear()
      e.preventDefault()
      e.stopPropagation()
    @form.on 'dragover dragenter', () =>
      @form.addClass('is-dragover')
      console.log("addClass('is-dragover')")
    @form.on 'dragleave dragend drop', () =>
      @form.removeClass('is-dragover')
    @form.on 'drop', (e) =>
      console.log e
      console.log("e:",e.originalEvent.dataTransfer)
      @form.find('.box__input').hide()
      droppedUris = e.originalEvent.dataTransfer.getData("text/uri-list").split("\n")
      console.log("droppedUris",droppedUris)
      firstUri = droppedUris[0]
      if firstUri.length
        if @load_uri(firstUri)
          @form.find(".box__success").text('')
          @picker.refresh()
          @form.hide()
          return
      droppedFiles = e.originalEvent.dataTransfer.files
      console.log("droppedFiles", droppedFiles)
      if droppedFiles.length
        firstFile = droppedFiles[0]
        if @load_file(firstFile)
          @form.find(".box__success").text('')
          @picker.refresh()
          @form.hide()
          return
      # the drop operation failed to result in loaded data, so show 'drop here' msg
      @form.find('.box__input').show()
      @picker.refresh()

class DragAndDropLoaderOfScripts extends DragAndDropLoader
  load_file: (firstFile) ->
    #@huviz.local_file_data = "empty"
    filename = firstFile.name
    @form.find('.box__success').text(firstFile.name) #TODO Are these lines still needed?
    @form.find('.box__success').show()
    reader = new FileReader()
    reader.onload = (evt) =>
      #console.log evt.target.result
      #console.log("evt", evt)
      try
        #@huviz.read_data_and_show(firstFile.name, evt.target.result)
        if filename.match(/.(txt|.json)$/)
          file_rec =
            uri: firstFile.name
            opt_group: 'Your Own'
            data: evt.target.result
          @picker.add_local_file(file_rec)
          #alert("the file should be read and run here....")
          #@huviz.local_file_data = evt.target.result
        else
          #$("##{@dataset_loader.select_id} option[label='Pick or Provide...']").prop('selected', true)
          blurt("Unknown file format. Unable to parse '#{filename}'. " +
                "Only .txt and .huviz files supported.", 'alert')
          @huviz.reset_dataset_ontology_loader()
          $('.delete_option').attr('style','')
      catch e
        msg = e.toString()
        #@form.find('.box__error').show()
        #@form.find('.box__error').text(msg)
        blurt(msg, 'error')
    reader.readAsText(firstFile)
    return true # ie success

(exports ? this).Huviz = Huviz
(exports ? this).Orlando = Orlando
(exports ? this).OntoViz = OntoViz
#(exports ? this).Socrata = Socrata
(exports ? this).Edge = Edge
