CREATE OR REPLACE PROCEDURE calificar
(nomevento IN VARCHAR2, lugareven IN NUMBER) IS
avgr NUMBER(8,2):=0; cont NUMBER(8):=0;
prom NUMBER(8,2); aux VARCHAR2(100); aux1 VARCHAR2(100);

CURSOR ord_c IS SELECT AVG(NUM) PM 
FROM CALIF,VALORNUM WHERE CALIF.FRASE=VALORNUM.CALIFICACION 
GROUP BY CALIF.IDENLUGAR, CALIF.IDUSUARIO;
BEGIN

FOR mi_e IN ord_c LOOP
avgr:= avgr+mi_e.PM;
cont:= cont +1; 
END LOOP;
prom:=avgr/cont;
aux:='/eventos/evento[nombre="'||nomevento||'"]/calificacion';
aux1:='<calificacion>'||prom||'</calificacion>';
UPDATE lugar
SET eventos =  UPDATEXML(eventos,aux, XMLTYPE(aux1));
END;
/

