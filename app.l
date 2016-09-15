(load "web.l")

# this will reload after each request, not good for prod
# (if *Dbg (daemon 'http (load "app.l")))


(class +Todo +ApiEntity)         # starts the entity definition
(rel desc (+Need +String))
(rel done (+Number))   # task status

(dm val> ()
    (=: done (or (: done) 0)) # sets done to be default 0
    (super))

(dm show> ()
    (list (cons "nr" (: nr))
          (cons "desc" (: desc))
          (cons "done" (: done)) ) )

(class +Tag +ApiEntity)
(rel desc (+Need +String))
(dm show> () (list
              (cons "nr" (: nr) )
              (cons "desc" (: desc) ) ) )

(de main()
    (pool "taskweb.db")
    (unless (seq *DB) (build) ) )

(de build ()
    (let Salt (gensalt)
         (new! '(+User) 'nm "admin" 'pw (hashpw "admin" Salt) 'slt Salt)))

(de go () (server 8088 "!home"))

(de home ()
    (redirect "/index.html"))

# generates (NIL (auth) (json-parse) (with (db-new-from-json '(+Todo)) (json-out "nr" (: nr))))
(api-gen-methods '(+Todo +Tag))

# gets list of entities
(de scaffold-entities-list-json ()
    (auth)
    (json-out "scaffold-entities" (cons T (uniq (mapcar '((X) (pack (car X))) *Scaffold)))))

# list an entity
(de scaffold-entity-list-json ()
    (auth)
    (json-out "scaffold-entity" (cons T (mapcar '((X) (show> X)) (all> (intern *Entity) (intern *Entity))))
              (cons "definition" T (mapcar '((X) (glue " " X)) *Scaffold) ) ) )

# get a row for an entity
(de scaffold-entity-row-list-json ()
    (auth)
    (let Row (db 'nr (intern *Entity) (format *Nr))
         (json-out "scaffold-entity-row" (cons T (if Row (list (show> Row)) NIL))
                     (cons "definition" T (mapcar '((X) (glue " " X)) *Scaffold) ) )) )

