 
CREATE VIEW d$pending_xatrans$ AS

(SELECT global_tran_fmt, global_foreign_id, branch_id

FROM sys.pending_trans$ tran, sys.pending_sessions$ sess

WHERE tran.local_tran_id = sess.local_tran_id

AND tran.state != 'collecting'

AND BITAND(TO_NUMBER(tran.session_vector),

POWER(2, (sess.session_id - 1))) = sess.session_id)

/

create synonym v$pending_xatrans$ for d$pending_xatrans$
/

CREATE VIEW d$xatrans$ AS

(((SELECT k2gtifmt, k2gtitid_ext, k2gtibid

FROM x$k2gte2

WHERE k2gterct=k2gtdpct)

MINUS

SELECT global_tran_fmt, global_foreign_id, branch_id

FROM d$pending_xatrans$)

UNION

SELECT global_tran_fmt, global_foreign_id, branch_id

FROM d$pending_xatrans$)

/

create synonym v$xatrans$ for d$xatrans$
/

