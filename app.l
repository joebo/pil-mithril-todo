(load "web.l")

# this will reload after each request, not good for prod
# (if *Dbg (daemon 'http (load "app.l")))

(class +Tag +ApiEntity)
(rel desc (+Need +String))
(dm show> () (list
              (cons "nr" (: nr) )
              (cons "desc" (: desc) ) ) )

(dm cho> ()  (cons "text" (: desc)))

(class +Todo +ApiEntity)         # starts the entity definition
(rel desc (+Need +String))
(rel done (+Number))   # task status
(rel tag (+Ref +Link) NIL (+Tag))

(dm val> ()
    (if (: tag) (=: tag (extern (: tag)) ) )
    (=: done (or (: done) 0)) # sets done to be default 0
    (super))

(dm show> ()
    (list (cons "nr" (: nr))
          (cons "desc" (: desc))
          (cons "done" (: done))
          (cons "tag" (pack (: tag)))
          (cons "tag-gui" (; (: tag ) desc) ) )) # gui output of tag key

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

