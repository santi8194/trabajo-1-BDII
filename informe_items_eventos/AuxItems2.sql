CREATE OR REPLACE PROCEDURE aux2_items
(nombre IN VARCHAR2,ilugar IN NUMBER) IS
tamano NUMBER(20); pos NUMBER(6); possustini NUMBER(6);possustfin NUMBER(6);tamanosus NUMBER(8); 
aux VARCHAR2(20); aux1 VARCHAR2(20); aux2 VARCHAR2(20);susaux VARCHAR2(20);
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
for mi_e IN save LOOP
tamano := LENGTH(mi_e.coment);
pos := INSTR(mi_e.coment, ' ', 1, 3)+1;
aux1 := SUBSTR(mi_e.coment,pos,tamano);
aux := SUBSTR(aux1,1,4);
possustini := INSTR(mi_e.coment, ' ', 1, 1)+1;
possustfin := INSTR(mi_e.coment, ' ', 1, 2);
tamanosus:=possustfin-possustini;
susaux:= SUBSTR(mi_e.coment,possustini,tamanosus);
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
INSERT INTO ITEMS VALUES(mi_e.lugar, mi_e.event,susaux,aux2);
END LOOP;
END;
/