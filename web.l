(off *User)

(class +User +Entity)
(rel nm (+Need +Key +String))          # User name
(rel pw (+String))               # Password
(rel slt (+String))               # Password

(class +Session +Entity)
(rel key (+Need +Key +String))
(rel usr (+Need +Ref +Link) NIL (+User))
(rel ts (+Need +Number))


(de disable-chunking ()
    (off *Chunked)
    (setq *Http1 0))

(de json-parse () (setq *Posted (parseJson *Data)))
(de json-get (Val) (cdr (assoc Val *Posted)))
(de json-out (Key Val)
    (disable-chunking)
    (httpHead "application/json" NIL)
    (ht:Out NIL (printJson (list (cons Key Val)))) )

# de foo (Typ . @) (pass new!)) 
# (setq *Posted (parseJson "{\"desc\":\"test\"}"))

(de db-new-from-json (Cls Extra)
    (let Props (mapcan '((X) (list (intern (car X)) (cdr X))) *Posted)
         (prog2
             (dbSync)
             (apply 'new  (append (cons (db: Cls) Cls Props) Extra))
             (if (send 'val> @)
                 (commit 'upd)
               (rollback) ) ) ) )


(de ts () (+ (* 86400 (date)) (time T)))

(de auth ()
    (setq *User (; (db 'key '+Session *Session) usr)) )

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



# needs to warm up pre-fork on midipix
(hashpw "test" "test")

(class +ApiEntity +Entity)
(rel nr (+Need +Key +Number)) # defines a key, needed collect/query
(rel usr (+Need +Ref +Link) NIL (+User))
(dm T @
    (pass super 'nr (genKey 'nr '+ApiEntity) 'usr *User))
(dm val> () (json-out "nr" (: nr) ) T)

(de api-del-json (Typ)
    (auth)
    (json-parse)
    (let Obj (db 'nr Typ (json-get "nr"))
         (ifn (= (; Obj usr) *User)
              (json-out "error" "no auth")
              (lose!> Obj)
              (json-out "success" 1) ) ) )

(de api-add-json (Typ)
    (auth)
    (json-parse)
    (db-new-from-json Typ) )
             
(de api-gen-methods (Types)
    (for V Types
         (let (Nm (pack (cdr (chop (lowc V)))) Typ (lit (cons V)))
            (def (intern (pack Nm "-del-json"))
                  (list NIL (list 'api-del-json Typ)) )
             (def (intern (pack Nm "-list-json")) # todo clean up
                  (list NIL
                        (list 'auth)
                        (list 'json-out Nm
                              (list 'cons T (list 'mapcar (intern (pack Nm "-db-show")) (list 'collect (lit 'usr) Typ '*User) ) ) ) ) )
             (def (intern (pack Nm "-add-json"))
                  (list NIL (list 'api-add-json Typ)) ) ) ) )
                  
