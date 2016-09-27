CREATE OR REPLACE PROCEDURE comentar_evento
(iden IN NUMBER, idlugar IN NUMBER, nomeve IN VARCHAR2, comen IN VARCHAR2)
IS
aux VARCHAR2(1000); aux2 VARCHAR2(1000); nma VARCHAR2(100); otr VARCHAR2(100); idlg VARCHAR2(100);
ida NUMBER(10); pos NUMBER(10); idlur NUMBER(8);
BEGIN
aux := '<comentario>'||comen||'</comentario>'; 
aux2:= '/agenda/evento[nombre_evento="'||nomeve||'"]/comentarios'; 
nma:= '/agenda/evento[nombre_evento="'||nomeve||'"]/nombre_evento/text()'; 
idlg:= '/agenda/evento[nombre_evento="'||nomeve||'"]/id_lugar/text()';
pos := INSTR(comen, ' ', 1, 3);
SELECT u.id, u.agenda.EXTRACT(nma).getStringVal(),u.agenda.EXTRACT(idlg).getNumberVal()
 INTO ida, otr, idlur FROM USUARIO u WHERE u.id=iden;

IF ida=iden AND otr=nomeve AND idlur=idlugar AND pos>0 THEN
UPDATE usuario u 
SET u.agenda = INSERTCHILDXML(u.agenda,aux2,'comentario', 
XMLTYPE(aux))
WHERE id=iden AND idlur=idlugar;
revisar(iden,nomeve,comen,idlugar); 
END IF;
END;
/


