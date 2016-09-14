(off *User)
(default *SessionTimeout (* 60 60 10))
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
(de json-out (Key Val . @)
    (disable-chunking)
    (httpHead "application/json" NIL)
    (ht:Out NIL (printJson (append (list (cons Key Val)) (rest)))) )

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
    (let Session (db 'key '+Session *Session)
        (setq *User (; Session usr))
         (ifn (> (- (ts) (; Session ts)) *SessionTimeout)
              (put!> Session 'ts (ts))
              (json-out "error" "timeout")
              (throw 'http) )) )


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
(dm auth> () (= (: usr) *User))
(dm collect> (Typ) (collect 'usr Typ (or *User T)))

(de api-del-json (Typ)
    (auth)
    (json-parse)
    (let Obj (db 'nr Typ (json-get "nr"))
         (ifn (auth> Obj)
              (json-out "error" "no auth")
              (lose!> Obj)
              (json-out "success" 1) ) ) )

(de api-add-json (Typ)
    (auth)
    (json-parse)
    (db-new-from-json Typ) )

(de api-list-json (Typ Nm)
    (auth)
    (json-out Nm (cons T (mapcar '((X) (show> X)) (collect> (car Typ) Typ)))))
    
(de api-gen-methods (Types)
    (for V Types
         (let (Nm (pack (cdr (chop (lowc V)))) Typ (lit (cons V)))
            (def (intern (pack Nm "-del-json"))
                  (list NIL (list 'api-del-json Typ)) )
            (def (intern (pack Nm "-list-json"))
                  (list NIL (list 'api-list-json Typ Nm)) )
             (def (intern (pack Nm "-add-json"))
                  (list NIL (list 'api-add-json Typ)) ) ) ) )
                  

(daemon 'rel (push '*Scaffold (list *Class Lst)))

