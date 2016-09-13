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
(api-gen-methods '(+Todo))


