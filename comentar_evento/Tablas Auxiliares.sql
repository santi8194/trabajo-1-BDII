Tablas Auxiliares Comentar_evento

CREATE TABLE calif(idusuario NUMBER(30), idenlugar NUMBER(8), nombre VARCHAR2(80), frase VARCHAR2(80));
CREATE TABLE valornum(calificacion VARCHAR2(20), num NUMBER(2));

--Inserciones valornum
INSERT INTO VALORNUM VALUES('inco',-1);
INSERT INTO VALORNUM VALUES('suci',-2);
INSERT INTO VALORNUM VALUES('abur',-3);
INSERT INTO VALORNUM VALUES('desa',-4);
INSERT INTO VALORNUM VALUES('desg',-5);
INSERT INTO VALORNUM VALUES('como',1);
INSERT INTO VALORNUM VALUES('buen',2);
INSERT INTO VALORNUM VALUES('entr',3);
INSERT INTO VALORNUM VALUES('geni',4);
INSERT INTO VALORNUM VALUES('exce',5);
INSERT INTO VALORNUM VALUES('otro',0);