-- Un usuario no puede comentar un evento al que no ha asistido, esto incluye eventos que aún no han ocurrido.
CREATE OR REPLACE TRIGGER Eventos_Inasistidos BEFORE INSERT ON USUARIO FOR EACH ROW
  DECLARE
    TYPE COMEN_TYPE IS TABLE OF XMLTYPE INDEX BY BINARY_INTEGER;
    arr_comen COMEN_TYPE;
    k NUMBER := 0;
  BEGIN
    SELECT x.* BULK COLLECT INTO arr_comen  -- Guarda los comentarios en el arreglo
    FROM XMLTABLE('/agenda/evento'
                   PASSING :new.AGENDA
                    COLUMNS
                      comentario  XMLTYPE PATH  'comentarios/comentario') x
    WHERE comentario IS NOT NULL ;

    IF arr_comen.FIRST IS NOT NULL THEN --si por lo menos hay un comentario.

      FOR curs IN (WITH b AS
                    (SELECT l.ID lugar_id, y.* --esta consulta saca todos los eventos con sus lugares, fecha y hora
                      FROM LUGAR l,
                            XMLTABLE('/eventos/evento'
                              PASSING l.EVENTOS
                              COLUMNS
                                nombre_ev  VARCHAR2(100) PATH 'nombre',
                                fecha  VARCHAR2(10) PATH  'fecha',
                                hora_fin  VARCHAR2(5) PATH 'hora_fin') y)
                    SELECT *
                      FROM (SELECT x.lugar_id, x.nombre_ev, x.comentario -- esta consulta saca los id_lugar, comentarios y nombre de los eventos del usuario a insertar
                            FROM XMLTABLE('/agenda/evento'
                                    PASSING :new.AGENDA
                                    COLUMNS
                                      lugar_id  NUMBER(30) PATH 'id_lugar',
                                      nombre_ev  VARCHAR2(100) PATH 'nombre_evento',
                                      comentario  XMLTYPE PATH  'comentarios/comentario') x) a
                        NATURAL JOIN (b) -- se hace el join de las dos consultas
                        WHERE comentario IS NOT NULL AND (b.fecha > sysdate OR (to_date(b.fecha,'DD/MM/YYYY') = to_date(TO_CHAR(SYSDATE, 'DD/MM/YYY'), 'DD/MM/YYY') AND  to_date(hora_fin,'HH24:MI') > to_date(TO_CHAR(SYSDATE, 'HH24:MI'), 'HH24:MI')))) LOOP  -- finalmente retorna los eventos en los que no se puede agregar comentario.
        k := k + 1;
      END LOOP;
      IF k > 0 THEN
        raise_application_error(-20506,'Error al insertar usuario. revisar que los eventos con comentarios ya hayan sucedido.');
      END IF;
    END IF;
  END;


  -- La hora_inicio de un evento debe ser menor que su hora_fin.
CREATE OR REPLACE TRIGGER Consistencia_hora BEFORE INSERT ON LUGAR FOR EACH ROW
  DECLARE
    k NUMBER := 0;
  BEGIN
    FOR curs IN (SELECT :new.ID, y.* --esta consulta saca todos los eventos con sus lugares, fecha y hora
                      FROM XMLTABLE('/eventos/evento'
                              PASSING :new.EVENTOS
                              COLUMNS
                                hora_inicio  VARCHAR2(5) PATH 'hora_inicio',
                                hora_fin  VARCHAR2(5) PATH 'hora_fin') y
                  WHERE to_date(hora_inicio,'HH24:MI') >= to_date(hora_fin,'HH24:MI')) LOOP
      k := k + 1;
    END LOOP;
    IF k > 0 THEN
      raise_application_error(-20506, 'Error al insertar lugar. La hora inicio de un evento tiene que ser menor que la hora fin');
    END IF;
  END;


--  Se deben cumplir las restricciones de edad de los eventos, ver el atributo ‘publico’ de los eventos, los posibles valores de este atributo son: todos,+10, +14, +18, +21.
CREATE OR REPLACE TRIGGER Verficacion_edad BEFORE INSERT ON USUARIO FOR EACH ROW
  DECLARE
    k NUMBER := 0;
    fecha_max DATE;
    CURSOR result_curs IS
      WITH b AS
      (SELECT l.ID lugar_id, y.ev_nombre, y.publico --esta consulta saca todos los eventos con sus nombres y publico
        FROM LUGAR l,
              XMLTABLE('/eventos/evento'
                PASSING l.EVENTOS
                COLUMNS
                  ev_nombre  VARCHAR2(100) PATH 'nombre',
                  publico  VARCHAR2(5) PATH 'publico') y)
      SELECT *
      FROM (SELECT x.* -- esta consulta saca los id_lugar y nombre de los eventos del usuario a insertar
            FROM XMLTABLE('/agenda/evento'
                    PASSING :new.AGENDA
                    COLUMNS
                      "LUGAR_ID"  NUMBER(30) PATH 'id_lugar',
                      ev_nombre  VARCHAR2(100) PATH 'nombre_evento') x) a
      NATURAL JOIN (b);
  BEGIN
    FOR resultado IN result_curs LOOP -- se hace el join de las dos consultas y saca los eventos a los que aspira ir con su fecha de nacimiento y el publico del evento.
      DBMS_OUTPUT.PUT_LINE(resultado.publico);
      IF resultado.publico = 'todos' THEN
          CONTINUE;
      ELSIF resultado.publico = '+10' THEN
        fecha_max := add_months( trunc(sysdate), -12*10 );
      ELSIF resultado.publico = '+14' THEN
        fecha_max := add_months( trunc(sysdate), -12*14 );
      ELSIF resultado.publico = '+18' THEN
        fecha_max := add_months( trunc(sysdate), -12*18 );
      ELSIF resultado.publico = '+21' THEN
        fecha_max := add_months( trunc(sysdate), -12*21 );
      ELSE
        raise_application_error(-20506, 'Error al insertar usuario: publico solo puede ser, todos,+10, +14, +18, +21');
      END IF;

      DBMS_OUTPUT.PUT_LINE(fecha_max);
      DBMS_OUTPUT.PUT_LINE(:new.FECHA_NACIMIENTO);
      IF :NEW.FECHA_NACIMIENTO > fecha_max THEN
        k := k + 1;
      END IF;
    END LOOP;
    IF k > 0 THEN
      raise_application_error(-20506, 'Error al insertar usuario: No tiene la edad para asistir.');
    END IF;
  END;


-- Un usuario no puede hacer comentarios repetidos a un mismo evento (es decir, con exactamente el mismo texto).
CREATE OR REPLACE TRIGGER Comentarios_Repetidos BEFORE INSERT ON USUARIO FOR EACH ROW
  DECLARE
    k NUMBER := 0;
  BEGIN
    FOR curs IN (SELECT lug_id, nom_ev, comen
                  FROM
                  XMLTABLE('/agenda/evento'
                    passing :new.AGENDA
                    columns
                            lug_id  NUMBER(30)  PATH 'id_lugar',
                            nom_ev  VARCHAR2(100) PATH 'nombre_evento',
                           comen XMLTYPE PATH 'comentarios') x) LOOP

      FOR curs1 IN (SELECT comentario, count(comentario) repetidos
                    FROM XMLTABLE('/comentarios/comentario' PASSING curs.comen COLUMNS comentario VARCHAR2(100) PATH '.')
                    GROUP BY comentario
                    HAVING count(comentario) > 1) LOOP

        k := k + 1;
      END LOOP;
      IF k > 0 THEN
        raise_application_error(-20506, 'Error al insertar usuario: Verifique que no hay comentarios repetidos.');
      END IF;
    END LOOP;
  END;


-- En los comentarios de un mismo evento, un usuario no puede usar más de cinco veces el mismo adjetivo.
CREATE OR REPLACE TRIGGER Muchos_Adjetivos BEFORE INSERT ON USUARIO FOR EACH ROW
  DECLARE
    TYPE adjetivo_type IS TABLE OF NUMBER INDEX BY VARCHAR2(10);
    frec_adjetivo adjetivo_type;
    adjetivo VARCHAR2(10);
  BEGIN
    FOR curs IN (SELECT lug_id, nom_ev, comen -- saca a los eventos del usuario con sus comentarios en xml
                  FROM
                  XMLTABLE('/agenda/evento'
                    passing :new.AGENDA
                    columns
                            lug_id  NUMBER(30)  PATH 'id_lugar',
                            nom_ev  VARCHAR2(100) PATH 'nombre_evento',
                           comen XMLTYPE PATH 'comentarios') x) LOOP

      FOR curs1 IN (SELECT comentario  -- saca los comentarios para un evento en especifico
                    FROM XMLTABLE('/comentarios/comentario' PASSING curs.comen COLUMNS comentario VARCHAR2(100) PATH '.')) LOOP

        adjetivo := SUBSTR(curs1.comentario,INSTR(curs1.comentario, ' ', 1, 3)+1,LENGTH(curs1.comentario)); -- saca el adjetivo del comentario
        IF frec_adjetivo.EXISTS(adjetivo) THEN
          frec_adjetivo(adjetivo) := frec_adjetivo(adjetivo) + 1;
        ELSE
          frec_adjetivo(adjetivo) := 1;
        END IF;
      END LOOP;

      adjetivo := frec_adjetivo.FIRST;
      WHILE adjetivo IS NOT NULL LOOP
        IF frec_adjetivo(adjetivo) > 5 THEN
          raise_application_error(-20506, 'Error al insertar usuario: No puede usar más de cinco veces el mismo adjetivo en los comentarios de un mismo evento.');
        END IF;
        adjetivo := frec_adjetivo.NEXT(adjetivo);
      END LOOP;
    END LOOP;
  END;


-- En un mismo lugar no puede haber dos eventos con el mismo nombre.
CREATE OR REPLACE TRIGGER Eventos_Repetidos BEFORE INSERT ON LUGAR FOR EACH ROW
  DECLARE
    k NUMBER := 0;
  BEGIN
    FOR curs IN (SELECT y.ev_nombre --esta consulta saca todos los nombres de eventos eventos
                  FROM XMLTABLE('/eventos/evento'
                          PASSING :new.EVENTOS
                          COLUMNS
                            ev_nombre  VARCHAR2(100) PATH 'nombre') y
                  GROUP BY ev_nombre
                    HAVING count(ev_nombre) > 1) LOOP
      k := k + 1;
    END LOOP;
    IF k > 0 THEN
      raise_application_error(-20506, 'Error al insertar lugar: No puede haber dos eventos con el mismo nombre en el mismo lugar');
    END IF;
  END;