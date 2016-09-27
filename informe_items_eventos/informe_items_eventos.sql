CREATE OR REPLACE PROCEDURE informe_items_eventos
IS
TYPE taptip IS TABLE OF VARCHAR(100);
arrtip taptip;
aux VARCHAR(100);

BEGIN
SELECT x.tipo tip BULK COLLECT INTO arrtip
FROM Lugar L,
XMLTABLE('/eventos/evento'
passing L.eventos
columns tipo VARCHAR(20) PATH 'tipo') x;

IF arrtip.FIRST IS NOT NULL THEN
FOR j IN arrtip.FIRST..arrtip.LAST LOOP
aux:=0;
FOR k IN (j+1)..arrtip.LAST LOOP
IF arrtip(j)=arrtip(k)THEN
aux:=aux+1;
END IF;
END LOOP;
IF aux=0 THEN
aux1_items(arrtip(j));
DELETE ITEMS;
END IF;
END LOOP;
END IF;
DELETE ITEMS;
END;
/
