(off *User)

# this will reload after each request, not good for prod
# (if *Dbg (daemon 'http (load "app.l")))
           
(class +User +Entity)
(rel nm (+Need +Key +String))          # User name
(rel pw (+String))               # Password
(rel slt (+String))               # Password

(class +Todo +Entity)         # starts the entity definition
(rel nr (+Need +Key +Number)) # defines a key, needed collect/query
(rel usr (+Need +Ref +Link) NIL (+User))
(rel desc (+Need +String))
(rel done (+Ref +Number))   # task status

        
(class +Session +Entity)
(rel key (+Need +Key +String))
(rel usr (+Need +Ref +Link) NIL (+User))
(rel ts (+Need +Number))
                        
(de main()
    (pool "taskweb.db")
    (unless (seq *DB) (build) ) )

(de go()
        (hashpw "test" "test")
        (server 8088 "!home"))

(de build ()
    (msg "in init")
    # (todo-db-add "admin" "test")
    (let Salt (gensalt)
         (new! '(+User) 'nm "admin" 'pw (hashpw "admin" Salt) 'slt Salt)))

(de disable-chunking ()
    (off *Chunked)
    (setq *Http1 0))

(de auth ()
    (let Session (db 'key '+Session *Session)
         (setq *User (; Session usr) ) ) )

(de todo-db-add (User Desc)
    (new! '(+Todo)
          'usr (db 'nm '+User User)
          'nr (genKey 'nr '+Todo)
          'desc Desc
          'done 0))

(de todo-db-show (This)
    (list (cons "nr" (: nr))
          (cons "desc" (: desc))
          (cons "done" (: done)) ) )

(de todo-db-list (User)
    (mapcar todo-db-show (collect 'usr '+Todo User) ) )

(de todo-db-get (User Nr)
    (let Todo (db 'nr '+Todo Nr)
         (if (= (; Todo usr) User) Todo ) ) )
         
(de todo-list-json ()
    (auth)
    (let Todos (todo-db-list *User)
         (json-out (list (cons "todos" T Todos))) ) )

(de todo-add-json ()
    (auth)
    (json-parse)
    (let Todo (todo-db-add (; *User nm) (json-get "desc"))
        (json-out (list (cons "nr" (; Todo nr)))) ) )

(de todo-del-json ()
    (auth)
    (json-parse)
    (ifn (todo-db-get *User (json-get "nr"))
         (json-out-error "no auth")
         (lose!> @)
         (sync)
         (json-out-success) ) )

(de json-parse () (setq *Posted (parseJson *Data)))

(de json-get (Val)
    (cdr (assoc Val *Posted)) )

(de json-out-error (Error)
    (json-out (list (cons "error" Error))) )

(de json-out-success ()
    (json-out (list (cons "success" 1))) )
    
(de json-out (Val)
    (disable-chunking)
    (httpHead "application/json" NIL)
    (ht:Out NIL (printJson Val)) )

(de ts () (+ (* 86400 (date)) (time T)))
(de session-genKey () (pack (getrandom 16)))
    
(de user-auth ()
    (msg *Data)
    (let (*Posted (parseJson *Data)
           UserName (json-get "username")
           Password (json-get "password")
           User (db 'nm '+User UserName)
           Salt (; User slt)
           HashedPw (hashpw Password Salt)
           Auth (= HashedPw (; User pw))
           SessionKey NIL)
    (ifn Auth
         (json-out (list (cons "noauth" 1)))
         (setq SessionKey (session-genKey))
         (new! '(+Session) 'key SessionKey 'usr User 'ts (ts))
         (json-out (list (cons "session" SessionKey))))))
               
         

(de home ()
    (redirect "/index.html"))

# c:\dev\picoLisp\pil @lib/http.l app.l -"server 8088 \"!home\""

