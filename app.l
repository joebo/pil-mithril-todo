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
    # (todo-db-add "admin" "test")
    (let Salt (gensalt)
         (new! '(+User) 'nm "admin" 'pw (hashpw "admin" Salt) 'slt Salt)))

(de disable-chunking ()
    (off *Chunked)
    (setq *Http1 0))

(de auth ()
    (setq *User (; (db 'key '+Session *Session) usr)) )

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
    (let Todos (todo-db-list *User)
     (json-out "todos" (cons T Todos) ) ) )

(de todo-add-json ()
    (let Todo (todo-db-add (; *User nm) (json-get "desc"))
         (json-out "nr" (; Todo nr)) ) )

(de todo-del-json ()
    (ifn (todo-db-get *User (json-get "nr"))
     (json-out "error" "no auth")
     (lose!> @)
     (json-out "success" 1) ) )

(de json-parse () (setq *Posted (parseJson *Data)))
(de json-get (Val) (cdr (assoc Val *Posted)))
(de json-out (Key Val)
    (disable-chunking)
    (httpHead "application/json" NIL)
    (ht:Out NIL (printJson (list (cons Key Val)))) )

(de ts () (+ (* 86400 (date)) (time T)))
(de session-genKey () (pack (getrandom 16)))
    
(de user-auth ()
    (let (*Posted (parseJson *Data)
           UserName (json-get "username")
           Password (json-get "password")
           User (db 'nm '+User UserName)
           Salt (; User slt)
           HashedPw (hashpw Password Salt)
           Auth (= HashedPw (; User pw))
           SessionKey NIL)
    (ifn Auth
         (json-out "noauth" 1)
         (setq SessionKey (session-genKey))
         (new! '(+Session) 'key SessionKey 'usr User 'ts (ts))
         (json-out "session" SessionKey ))))
               
         

(de home ()
    (redirect "/index.html"))

(for V (filter '((X) (match '(@A ~(chop "-json")) (chop X))) (all))
      (daemon V (auth) (json-parse)))
# c:\dev\picoLisp\pil @lib/http.l app.l -"server 8088 \"!home\""

