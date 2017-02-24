#
class IndexedDBService
  constructor: (@huviz) ->
    @initialize_db()

  initialize_db: ->
    indexedDB = window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB

    if not indexedDB
      throw new Error("indexedDB not available")

    if not @nstoreDB and indexedDB
      @dbName = @get_dbName()
      @dbStoreName = "ntuples"
      req = indexedDB.open(@dbName, @dbVer) #TODO the name of the dataindex needs to be tied to specific instances
      console.log(req)  # 'req' is not in the same state as the samle ('pending') and does not have the proper definitions for onerror, onsuccess...etc.

      req.onsuccess = (evt) =>
        console.log("onsuccess #{@dbName}")
        @nstoreDB = req.result

      req.onerror = (evt) =>
        console.error("IndexDB Error: " + evt.target.error.message)

      req.onupgradeneeded = (evt) =>
        db = evt.target.result
        console.log("onupgradeneeded #{db.name}")
        console.log(evt)
        if evt.oldVersion is 1
          if 'spogis' in db.objectStoreNames
            alert("deleteObjectStore('spogis')")
            db.deleteObjectStore('spogis')
        if evt.oldVersion < 3 #Only create a new ObjectStore when initializing for the first time
          alert("createObjectStore('#{@dbObjectStoreName}')")
          store = db.createObjectStore(@dbStoreName,
            { keyPath: 'id', autoIncrement: true })
          console.log (db)
          store.createIndex("s", "s", { unique: false })
          store.createIndex("p", "p", { unique: false })
          store.createIndex("o", "o", { unique: false })

          store.transaction.oncomplete = (evt) =>
            @nstoreDB = db
            console.log ("transactions are complete")
            console.log (db)

  dbName_default: 'nstoreDB'
  dbVer: 2
  get_dbName: ->
    return @huviz.args.editui__dbName or @dbName_default

  add_node_to_db: (quad) ->
    console.log ("add new node to DB")
    console.log (quad)
    console.log  (@nstoreDB)
    #trx = @nstoreDB.transaction('spogis', "readwrite")
    #trx.oncomplete = (e) =>
    #  console.log "spogis added!"
    #trx.onerror = (e) =>
    #  console.log(e)
    #  alert "add_dataset(spogis) error!!!"


(exports ? this).IndexedDBService = IndexedDBService
