CREATE OR REPLACE PROCEDURE aux1_items (tipin IN VARCHAR) IS
imp VARCHAR(100):=tipin||': ';
CURSOR tips IS
SELECT L.id id ,x.nombre name
FROM lugar L,
XMLTABLE('/eventos/evento'
passing L.eventos
columns nombre VARCHAR(100) PATH 'nombre',
		tipo VARCHAR(20) PATH 'tipo') x
		WHERE tipo=tipin;
BEGIN
FOR mi_e IN tips LOOP
aux2_items(mi_e.name,mi_e.id);
END LOOP;

FOR mi_f IN (SELECT sustantivo, count(sustantivo) num FROM 
(SELECT DISTINCT sustantivo, adjetivo FROM items GROUP BY sustantivo,adjetivo)
GROUP BY SUSTANTIVO ORDER BY SUSTANTIVO) LOOP
imp:=imp||mi_f.sustantivo||'('||mi_f.num||') ';
END LOOP;
DBMS_OUTPUT.PUT_LINE(imp);
END;
/

