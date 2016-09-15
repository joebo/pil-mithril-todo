(off *User)
(default *SessionTimeout (* 60 60 10))

(daemon 'rel (push '*Scaffold (list *Class Lst))) # collects relations for scaffolding

(class +ApiEntity +Entity)
(rel nr (+Need +Key +Number))                       # defines a key, needed collect/query
(rel usr (+Need +Ref +Link) NIL (+User))
(dm T @                                             # ensures new instances have a nr assigned and are associated with a user
    (pass super 'nr (genKey 'nr '+ApiEntity) 'usr *User))


(dm val> () (json-out "nr" (: nr) ) T)              # validates entity and outputs response, commits if T
(dm auth> () (= (: usr) *User))                     # authorize entity
(dm collect> (Typ) (collect 'usr Typ (or *User T))) # filters entity by user or default filter
(dm all> (Typ) (collect 'nr Typ))                   # returns all instances (for scaffolding)
(dm show> () (list                                  # default JSON response for entity
                  (cons "nr" (: nr) ) ) )
(dm cho> ()  (cons "text" (: nr)))                  # default way to show in a +Link picklist

(class +User +ApiEntity)
(rel nm (+Need +Ref +String))                       # User name
(rel pw (+String))                                  # Password
(rel slt (+String))                                 # salt
(dm show> ()
    (list (cons "nr" (: nr))
          (cons "nm" (: nm)) ) )


(class +Session +Entity)
(rel key (+Need +Key +String))
(rel usr (+Need +Ref +Link) NIL (+User))
(rel ts (+Need +Number))
(dm all> (Typ) (collect 'key '(+Session)))
(dm show> ()
    (list (cons "usr" (; (get (: usr)) nm))
          (cons "ts" (: ts)) ) )


(de disable-chunking ()
    (off *Chunked)
    (setq *Http1 0))

(de json-parse () (setq *Posted (parseJson *Data)))
(de json-get (Val) (cdr (assoc Val *Posted)))
(de json-out (Key Val . @)
    (disable-chunking)
    (httpHead "application/json" NIL)
    (ht:Out NIL (printJson (append (list (cons Key Val)) (rest)))) )

(de db-new-from-json (Cls Extra)
    (let Props (mapcan '((X) (ifn (= (car X) "nr") (list (intern (car X)) (cdr X)))) *Posted)
         (prog2
             (dbSync)
             (apply 'new  (append (cons (db: Cls) Cls Props) Extra))
             (if (send 'val> @)
                 (commit 'upd)
               (rollback) ) ) ) )

(de db-update-from-json (Cls Extra)
    (let (Props (mapcan '((X) (list (intern (car X)) (cdr X))) *Posted)
          Obj (db 'nr Cls (json-get "nr") ) )
         (prog2
             (dbSync)
             (for (X Props X) (put> Obj (pop 'X) (pop 'X)))
             (if (send 'val> Obj)
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

(de api-update-json (Typ)
    (auth)
    (json-parse)
    (db-update-from-json Typ) )

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
           (def (intern (pack Nm "-update-json"))
                  (list NIL (list 'api-update-json Typ)) )
           (def (intern (pack Nm "-add-json"))
                (list NIL (list 'api-add-json Typ)) ) ) ) )
                  


# scaffold support
# gets list of entities
(de scaffold-entities-list-json ()
    (auth)
    (json-out "scaffold-entities" (cons T (uniq (mapcar '((X) (pack (car X))) *Scaffold)))))

# list an entity
(de scaffold-entity-list-json ()
    (auth)
    (json-out "scaffold-entity" (cons T (mapcar '((X) (show> X)) (all> (intern *Entity) (intern *Entity))))
              (cons "definition" T (mapcar '((X) (glue " " X)) *Scaffold) ) ) )

# given a list of properties, extract the links
# ("get-link-entities" '((+Todo (tag (+Ref +Link) NIL (+Tag)))))
# +Tag
(de "get-link-entities" (Props)
    (mapcar '((X) (car (last (cadr X))))
            (filter '((Prop) (fish (quote (X) (= X (quote +Link))) Prop)) Props)) )

# ("get-links-json" '(+Tag))
(de "get-links-json" (Links)
    (make
        (for Link Links
             (link (cons (pack Link) T
                   (mapcar '((X) (list (cons "key" (pack X)) (cho> X)))
                           (all> Link Link))) ) ) ) )
             
# get a row for an entity
(de scaffold-entity-row-list-json ()
    (auth)
    (let (Entity (intern *Entity)
         Row (db 'nr (intern Entity) (format *Nr))
         Props (filter '((X) (= (car X) Entity)) *Scaffold))
         (json-out "scaffold-entity-row" (cons T (if Row (list (show> Row)) NIL))
                     (cons "definition" T (mapcar '((X) (glue " " X)) Props))
                     (cons "links" ("get-links-json" ("get-link-entities" Props)))) ) )

