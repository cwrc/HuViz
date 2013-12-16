class GCLTest
  constructor: (@runner,@script,@expectations) ->
    @graph_ctrl = @runner.gclc.graph_ctrl
  perform: ->
    @runner.gclc.run(@script)
    for exp in @expectations
      got = eval(exp[0])
      expected = exp[1]
      if @runner.verbose
        console.log "got="+got + " expected:"+expected
      if got != expected
        msg = msg ? ""+got+" != "+expected
        return msg

class GCLTestSuite
  ###
  # callback = function(){
  #    this.expect(this.graph_ctrl.nodes.length,7);
  #    this.expect(this.graph_ctrl.unlinked_set.length,0);
  # }
  # ts = new GCLTestSuite(gclc, [
  #      {script:"choose 'abdyma'",
  #       expectations: [
  #           ["this.graph_ctrl.nodes.length",7],
  #           ["this.graph_ctrl.unlinked_set.length",0],
  #       ]
  #      }
  #     ])
  ###
  constructor: (@gclc,@suite) ->
  run: ->
    pass_count = 0
    errors = []
    fails = []
    num = 0
    for spec in @suite
      num++
      test = new GCLTest(this,spec.script,spec.expectations)
      try
        retval = test.perform()
        if @verbose
          console.log retval
        if retval?
          fails.push([num,retval])
        else
          pass_count++
      catch e
        throw e
        errors.push([num,e])
    console.log("passed:"+pass_count+
                " failed:"+fails.length
                " errors:"+errors.length)
    for fail in fails
      console.log "test#"+fail[0],fail[1]
    for err in errors
      console.log "err#"+err[0],err[1]
          
class GraphCommand
  get_node: (node_spec) ->
    id = node_spec.id
    term = id
    tried = []
    node = @graph_ctrl.nodes.get({'id':term})
    tried.push(term)
    unless node
      @prefixes.forEach (prefix) =>
        if not node
          term = prefix+id
          tried.push(term)
          node = @graph_ctrl.nodes.get({'id':term})
    if not node
      throw new Error("node with id="+term+
            " not found among "+
            @graph_ctrl.nodes.length+" nodes: "+tried)
    return node    
  get_nodes: () ->    
    nodes = []
    for node_spec in @subjects
      node = @get_node(node_spec)
      if node
        nodes.push(node)
      nodes.push(node)
    return nodes    
  get_methods: () ->  
    methods = []
    for verb in @verbs
      method = @graph_ctrl[verb]
      if not method
        throw new Error("method "+method+" not found")
      methods.push(method)
    return methods
  execute: (@graph_ctrl,prefixes) ->
    @prefixes = prefixes ? []
    nodes = @get_nodes()
    for meth in @get_methods()
      for node in nodes
        meth.call(@graph_ctrl,node)
  parse: (cmd_str) ->
    # "choose 'abdyma'"
    parts = cmd_str.split(" ")
    verb = parts[0]
    subj = parts[1].replace(/\'/g,"") 
    cmd =
      verbs: [verb]
      subjects: [{'id': subj}]
    return cmd
    
    # "choose,label 'abdyma'"
    # "choose like 'Maria'"
    # "choose organizations like 'church'"
    # "choose writers like 'Margaret' regarding family"
    #    /(\w+)(,\s*\w+) '(\w+)'/

  # Expect args: verbs, subjects, constraints, regarding
  constructor: (args_or_str) ->
    if typeof args_or_str == 'string'
      args = @parse(args_or_str)
    else
      args = args_or_str
    for arg of args
      @[arg] = args[arg]
  
class GraphCommandLanguageCtrl
  constructor: (@graph_ctrl,@prefixes) ->
  run: (script) ->
    @commands =  script.split(';')
    @execute()
  run_one: (cmd_spec) ->
    cmd = new GraphCommand(cmd_spec)
    cmd.execute(@graph_ctrl,@prefixes)
  execute: () ->
    for cmd_spec in @commands
      if cmd_spec
        @run_one(cmd_spec)
  
(exports ? this).GraphCommandLanguageCtrl = GraphCommandLanguageCtrl
(exports ? this).GCLTest = GCLTest
(exports ? this).GCLTestSuite = GCLTestSuite

