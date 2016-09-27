CREATE OR REPLACE PROCEDURE revisar
(idusuario IN VARCHAR2,nombre IN VARCHAR2,frase IN VARCHAR2, ilugar IN NUMBER) IS
tamano NUMBER(20); pos NUMBER(20); 
aux VARCHAR2(20); aux1 VARCHAR2(20); aux2 VARCHAR(20) ;
TYPE cal IS TABLE OF CALIF.FRASE%TYPE;
arr cal;
a1 VARCHAR(100):='/agenda/evento[nombre_evento="'||nombre||'"]/comentarios';
a2 VARCHAR(100):='/agenda/evento[nombre_evento="'||nombre||'"]';
CURSOR save IS  
SELECT u.id iden, z.idl lugar, z.nom event, y.comen coment
FROM usuario u,
XMLTABLE(a1
passing u.agenda
columns comen XMLTYPE PATH 'comentario') x,
XMLTABLE('/comentario'
 passing x.comen
columns comen VARCHAR2(30) PATH '.') y,
XMLTABLE(a2
 passing u.agenda
columns nom VARCHAR2(30) PATH 'nombre_evento',
		idl NUMBER(8) PATH 'id_lugar') z
		WHERE z.idl=ilugar;
		
BEGIN
DELETE CALIF;
for mi_e IN save LOOP
tamano := LENGTH(mi_e.coment)-1;
pos := INSTR(mi_e.coment, ' ', 1, 3)+1;
aux1 := SUBSTR(mi_e.coment,pos,tamano);
aux := SUBSTR(aux1,1,4);
SELECT e.calificacion BULK COLLECT INTO arr FROM VALORNUM e;
IF arr.FIRST IS NOT NULL THEN
FOR i IN arr.FIRST .. arr.LAST LOOP 
	IF aux = arr(i) THEN
	aux2 := aux;
	EXIT;
	ELSE
	aux2:= 'otro';
	END IF;
END LOOP;
END IF;
IF aux1 = 'desagadable' OR aux1 = 'desagradables' THEN
	aux2:= 'desg';
END IF;
INSERT INTO CALIF VALUES(mi_e.iden, mi_e.lugar, mi_e.event,aux2 );
END LOOP;
calificar(nombre,ilugar);
END;
/