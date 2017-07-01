CREATE OR REPLACE PACKAGE P6 IS

--------------------------------------- Procedimientos ----------------------------------------------------------------
    
    -- Usuario
    PROCEDURE Registro_en_el_sistema(NombreI VARCHAR2, CorreoI VARCHAR2, Pass VARCHAR2, Premium NUMBER);

    -- Canal
    PROCEDURE Crear_canal(user VARCHAR2, NombreI VARCHAR2);
    PROCEDURE Ver_canal(NombreI Varchar2);
    PROCEDURE Seguir_canal(id_usuario  NUMBER, id_canal NUMBER);
    PROCEDURE Actualizar_canal(NombreI VARCHAR2, id_canal NUMBER);
    PROCEDURE Eliminar_canal(user VARCHAR2, NombreI VARCHAR2);

    -- Video
    PROCEDURE Votar_video(id_canal NUMBER, id_video NUMBER, voto NUMBER);
    PROCEDURE Comentar_video(id_usuario  NUMBER, id_canal NUMBER, id_video NUMBER, TextoI VARCHAR2);
    PROCEDURE Crear_video(NombreI VARCHAR2, DuracionI NUMBER, id_canal NUMBER);
    PROCEDURE Actualizar_video(NombreI VARCHAR2, DuracionI NUMBER, id_canal NUMBER, id_video NUMBER);
    PROCEDURE Eliminar_video(id_canal NUMBER, id_video NUMBER);
    PROCEDURE Ver_video(id_canal INT, NombreI Varchar2);

    -- Comentario
    PROCEDURE Votar_comentario(id_canal NUMBER, id_video NUMBER, id_comentario NUMBER, voto NUMBER);

    -- Sistema
    PROCEDURE Ver_si_propietario(user VARCHAR2, canal VARCHAR2);
   
--------------------------------------- Funciones ---------------------------------------------------------------------
    -- Usuario
    FUNCTION Get_id_usuario(NombreI VARCHAR2) RETURN INT;
    FUNCTION Ver_numero_de_canales(id_usuario NUMBER) RETURN NUMBER;
    FUNCTION Lista_Usuarios RETURN SYS_REFCURSOR;

    -- Canal
    FUNCTION Get_id_canal(NombreI VARCHAR2) RETURN INT;
    FUNCTION Informacion_Canal(id_canal INT) RETURN SYS_REFCURSOR;
    FUNCTION Ver_numero_de_seguidores(id_canal NUMBER) RETURN NUMBER;
    FUNCTION Ver_numero_de_videos(id_canal NUMBER) RETURN NUMBER;
    FUNCTION Lista_Canales RETURN SYS_REFCURSOR;

    -- Video
    FUNCTION Get_id_video(Canal VARCHAR2, video VARCHAR2) RETURN INT;
    FUNCTION Informacion_Video(id_canal INT, id_video INT) RETURN SYS_REFCURSOR;
    FUNCTION Lista_Videos(id_canal INT) RETURN SYS_REFCURSOR;

    -- Comentario
    FUNCTION Lista_Comentarios(id_canal INT, id_video INT) RETURN SYS_REFCURSOR;
    
    -- Sistema
    FUNCTION Acceso_al_sistema(p_user VARCHAR2, p_pass VARCHAR2) RETURN NUMBER;

END P6;
/


CREATE OR REPLACE PACKAGE BODY P6 IS

--------------------------------------- Procedimientos ----------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

--------------------------------------- Usuario 

    -- Registra a un usuario en el sistema según la información introducida
    PROCEDURE Registro_en_el_sistema(NombreI VARCHAR2, CorreoI VARCHAR2, Pass VARCHAR2, Premium NUMBER) IS
    BEGIN
        IF Premium = 0 THEN
            INSERT INTO Tabla_Usuario
            VALUES (Usuario_sequence.NEXTVAL, NombreI, CorreoI, Pass, SysDate, Tipo_Lista_Ref_Canal(), Tipo_CanalesSeguidos());
           
        ELSIF Premium = 1 THEN
             INSERT INTO Tabla_Usuario
                VALUES (Tipo_Premium(Usuario_sequence.NEXTVAL, NombreI, CorreoI, Pass, SysDate, Tipo_Lista_Ref_Canal(), Tipo_CanalesSeguidos(), SysDate, 12));

        END IF;
    COMMIT;
    END;

--------------------------------------- Canal 

    -- Crea un canal con los datos introducidos
    -- Introduce canal en la Tabla_Canal y en la tabla anidada Tiene_Canal de usuario
    PROCEDURE Crear_canal(user VARCHAR2, NombreI VARCHAR2) IS
    ref_canal REF Tipo_Canal;
    ref_creador REF Tipo_Usuario;
    id_canal INT;
    BEGIN
    
        SELECT ref(u) INTO ref_creador FROM Tabla_Usuario u WHERE nombre = user;

        INSERT INTO Tabla_Canal
        VALUES (Canal_sequence.NEXTVAL,NombreI,ref_creador,SYSDATE,Tipo_Lista_Video(),Tipo_Seguidores());
        id_canal := Canal_sequence.CURRVAL;

        SELECT REF(c) INTO ref_canal FROM Tabla_Canal c WHERE Id = id_canal;

        INSERT INTO TABLE(SELECT Tiene_Canal FROM Tabla_Usuario WHERE nombre = user)
            VALUES (ref_canal);

    COMMIT;
    END;

    -- Procedimiento que lanza una excepcion si el canal introducido por el usuario
    -- no existe
    PROCEDURE Ver_canal(NombreI Varchar2) IS
        v_canal INT;
        CURSOR c is
            SELECT id FROM Tabla_Canal c WHERE Nombre = NombreI;
    BEGIN
        OPEN c;
        FETCH c INTO v_canal;
        IF c%NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-20002,'Canal no encontrado');
        END IF;
          
    COMMIT;
    END;

    -- Procedimiento que actualiza el canal cuando el usuario lo sigue:
    --      - Se actualiza la tabla anidada Seguidores de Tabla_Canal
    --      - Se actualiza la tabla anidada Siguiendo de Tabla_Usuario
    PROCEDURE Seguir_canal(id_usuario  NUMBER, id_canal NUMBER) IS
        Usu REF Tipo_Usuario;
        Can REF Tipo_Canal;
        v_user VARCHAR2(100);
        CURSOR c is 
            select deref(t.COLUMN_VALUE).nombre as SEGUIDOR from Tabla_Canal c, Table(seguidores) t;
    BEGIN
        SELECT nombre INTO v_user FROM Tabla_Usuario WHERE id = id_usuario;

        FOR v_seguidores IN c LOOP
            IF(v_seguidores.SEGUIDOR = v_user) THEN
                RAISE_APPLICATION_ERROR(-20004, 'Ya sigue a este canal');
            END IF;
        END LOOP;
     
        SELECT REF(u) INTO Usu
        FROM Tabla_Usuario u
        WHERE u.id = id_usuario;
        
        SELECT REF(c) INTO Can
        FROM Tabla_Canal c
        WHERE c.id = id_canal;
        
        INSERT INTO TABLE (
                        SELECT Siguiendo 
                        From Tabla_Usuario
                        Where id=id_usuario
                        )
                VALUES (Can);
                
        INSERT INTO TABLE (
                        SELECT Seguidores 
                        From Tabla_Canal
                        Where id=id_canal
                        )
                VALUES (Usu);        
    COMMIT;
    END;

    -- Procedimiento para actualizar un canal
    -- Se lanza una excepcion si el nombre nuevo del canal ya existe en el sistema
    PROCEDURE Actualizar_canal(NombreI VARCHAR2, id_canal NUMBER) IS
        v_canal Tabla_Canal.nombre%TYPE;
        CURSOR c(canal STRING) is
            SELECT nombre FROM Tabla_Canal WHERE nombre = canal;
    BEGIN
        OPEN c(NombreI);
        FETCH c INTO v_canal;
        IF c%FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Canal ya creado');
        END IF;

        UPDATE TABLA_CANAL
        SET Nombre = NombreI
        WHERE id = id_canal;
    COMMIT;
    END;
    
    -- Procedimiento para eliminar un canal
    --      - Se elimina el registro de la Tabla_Canal
    --      - Se elimina las referencias al canal en las tablas anidadas 
    --        de los usuarios que siguen a ese canal y del autor
    PROCEDURE Eliminar_canal(user VARCHAR2, NombreI VARCHAR2) IS
        v_propietario VARCHAR2(100);
        v_ref_canal REF Tipo_Canal;
        i_users INT;
        v_max_id INT;
    BEGIN
        SELECT REF(c) INTO v_ref_canal FROM Tabla_Canal c WHERE nombre = NombreI;
        SELECT MAX(id) INTO v_max_id FROM Tabla_Usuario;

        DELETE 
        FROM Tabla_canal
        WHERE nombre=NombreI;

        FOR i_users IN 1..v_max_id LOOP

            DELETE FROM TABLE(SELECT Siguiendo FROM Tabla_Usuario WHERE id = i_users) s
                WHERE VALUE(s) = v_ref_canal;

            DELETE FROM TABLE(SELECT Tiene_Canal FROM Tabla_Usuario WHERE id = i_users) s
                WHERE VALUE(s) = v_ref_canal;

        END LOOP;
    COMMIT;
    END;

--------------------------------------- Video 

    -- Procedimiento para crear un video
    --      - Se lanza una excepcion si existe un video en el canal con el mismo nombre
    PROCEDURE Crear_video(NombreI VARCHAR2, DuracionI NUMBER, id_canal NUMBER) IS
        v_video INT;
        CURSOR c is
            SELECT c.id FROM Tabla_Canal c, TABLE(Tiene_Video) v WHERE v.nombre = NombreI AND c.id = id_canal;
    BEGIN
        OPEN c;
        FETCH c INTO v_video;
        IF c%FOUND THEN
            RAISE_APPLICATION_ERROR(-20006,'Video con mismo nombre en este canal ya creado');
        END IF;
    
        INSERT INTO TABLE(
            SELECT Tiene_Video 
            From Tabla_Canal       
            Where id=id_canal)            
        VALUES(video_Sequence.NEXTVAL,NombreI,DuracionI,0,0,Tipo_Lista_Comentario());
                
    COMMIT;
    END;
    
    -- Procedimiento para votar un video
    PROCEDURE Votar_video(id_canal NUMBER, id_video NUMBER, voto NUMBER) IS
    BEGIN
        IF voto = 0 THEN
            UPDATE TABLE(
                        SELECT Tiene_Video
                        From Tabla_Canal
                        Where id=id_canal
                        ) T
            SET T.CalificacionesBuenas=T.CalificacionesBuenas+1
            Where T.id = id_video;
            
        ELSIF voto = 1 THEN
              UPDATE TABLE(
                        SELECT Tiene_Video
                        From  Tabla_Canal
                        Where id=id_canal
                        ) T
            SET T.CalificacionesMalas=T.CalificacionesMalas+1
            Where T.id = id_video;
        
        END IF;
    COMMIT;
    END;
    
    -- Procedimiento para comentar un video
    PROCEDURE Comentar_video(id_usuario  NUMBER, id_canal NUMBER, id_video NUMBER, TextoI VARCHAR2) IS
        AUT REF Tipo_Usuario;
    BEGIN
        
        SELECT REF(u)INTO Aut
        FROM Tabla_Usuario u
        WHERE u.id = id_usuario;
        
        INSERT INTO TABLE(
                        SELECT Tiene_Comentario 
                        From Table(
                                    SELECT Tiene_Video
                                    From Tabla_Canal
                                    Where id=id_canal
                                    )
                        Where id=id_video)
            VALUES(Comentario_sequence.NEXTVAL,Aut,TextoI,0,0);            
        
    COMMIT;
    END;

    -- Procedimiento para actualizar la información de un video
    --      - Se lanza una excepcion si existe un video en el canal con el mismo nombre
    PROCEDURE Actualizar_video(NombreI VARCHAR2, DuracionI NUMBER, id_canal NUMBER, id_video NUMBER) IS
        v_video INT;
        CURSOR c is
            SELECT c.id FROM Tabla_Canal c, TABLE(Tiene_Video) v WHERE v.nombre = NombreI AND c.id = id_canal;
    BEGIN
        OPEN c;
        FETCH c INTO v_video;
        IF c%FOUND THEN
            RAISE_APPLICATION_ERROR(-20006,'Video con mismo nombre en este canal ya creado');
        END IF;
    
        UPDATE TABLE(
                        SELECT Tiene_Video
                        From Tabla_Canal
                        Where id=id_canal
                        ) 
        SET Nombre = NombreI, Duracion = DuracionI
        Where id = id_video;
    COMMIT;
    END;

    -- Procedimiento para eliminar un un video
    PROCEDURE Eliminar_video(id_canal NUMBER, id_video NUMBER) IS
    BEGIN
         Delete
         From TABLE(
                SELECT Tiene_Video
                From Tabla_Canal
                Where id=id_canal
                ) 
        Where id = id_video;
    COMMIT;
    END;

    -- Procedimiento para ver un video
    --      - Se lanza una exepcion si el video que quiere ver el usuario no existe
    PROCEDURE Ver_video(id_canal INT, NombreI Varchar2) IS
        v_video INT;
        CURSOR c is
            SELECT c.id FROM Tabla_Canal c, TABLE(Tiene_Video) v WHERE v.nombre = NombreI AND c.id = id_canal;
    BEGIN
        OPEN c;
        FETCH c INTO v_video;
        IF c%NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-20005,'Video no encontrado');
        END IF;
    COMMIT;
    END;

--------------------------------------- Comentario 

    -- Procedimiento para votar un comentario
    PROCEDURE Votar_Comentario(id_canal NUMBER, id_video NUMBER, id_comentario NUMBER, voto NUMBER) IS
    BEGIN
        IF voto = 0 THEN
            UPDATE TABLE(
                SELECT Tiene_Comentario 
                    FROM Table(
                        SELECT Tiene_Video
                            FROM Tabla_Canal
                            WHERE id=id_canal
                            )
                        WHERE id=id_video)
             SET CalificacionesBuenas=CalificacionesBuenas+1
             Where id = id_comentario;
            
        ELSIF voto = 1 THEN
                UPDATE TABLE(
                    SELECT Tiene_Comentario 
                    From Table(
                        SELECT Tiene_Video
                        From Tabla_Canal
                        Where id=id_canal
                        )
                    Where id=id_video)

                 SET CalificacionesMalas=CalificacionesMalas+1
                 Where id = id_comentario;
        END IF;
    COMMIT;
    END;


--------------------------------------- Sistema 

    -- Procedimiento que lanza una excepcion si un usuario no es propietario de un canal
    -- Utilizado para denegar ciertas opciones a usuarios no autorizados
    PROCEDURE Ver_si_propietario(user VARCHAR2, canal VARCHAR2) IS
        v_propietario VARCHAR2(100);
    BEGIN
        SELECT DEREF(C.propietario).nombre INTO v_propietario FROM Tabla_canal C WHERE nombre = canal;    
        IF (v_propietario != user) THEN
            RAISE_APPLICATION_ERROR(-20003, 'Operacion no permitida, no eres el propietario');
        END IF;
    END;
    

--------------------------------------- Funciones ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------   

--------------------------------------- Usuario

    -- Funcion para ver el numero de canales de un usuario
    FUNCTION Ver_numero_de_canales(id_usuario NUMBER) RETURN NUMBER AS
        Num Number;
        Can Tipo_Lista_Ref_Canal;
    BEGIN
        Select Tiene_Canal into Can
        from Tabla_Usuario
        where id=id_usuario;
        
        Num:= Can.count;
        Return Num;
    COMMIT;
    END;

    -- Funcion para obtener el id de un usuario segun su nombre
    FUNCTION Get_id_usuario(NombreI VARCHAR2) RETURN INT AS
        v_id INT;
    BEGIN
        SELECT id INTO v_id FROM Tabla_Usuario WHERE nombre = NombreI;
        RETURN v_id;
    END;

    -- Funcion para obtener una lista de los nombres de todos los usuarios
    FUNCTION Lista_Usuarios RETURN SYS_REFCURSOR AS
        v_usuarios SYS_REFCURSOR;
    BEGIN
        OPEN v_usuarios FOR SELECT nombre FROM Tabla_Usuario;
        return v_usuarios;
    END;

--------------------------------------- Canal
    
    -- Funcion para ver el numero de seguidores de un canal
    FUNCTION Ver_numero_de_seguidores(id_canal NUMBER) RETURN NUMBER AS
        Num Number;
        Seg Tipo_Seguidores;
    BEGIN
       Select Seguidores into Seg
        from Tabla_Canal
        where id=id_canal;
        
       Num:= Seg.count;
        Return Num;
    COMMIT;
    END;

    -- Funcion para ver el numero de videos de un canal
    FUNCTION Ver_numero_de_videos(id_canal NUMBER) RETURN NUMBER AS
        Num Number;
        Vid Tipo_Lista_Video;
    BEGIN
        Select Tiene_Video into Vid
        from Tabla_Canal
        where id=id_canal;
    
        Num:= Vid.count;
        Return Num;
    COMMIT;
    END;

    -- Funcion para obtener una lista de los nombres y propietarios de todos los canales
    FUNCTION Lista_Canales RETURN SYS_REFCURSOR AS
        v_canales SYS_REFCURSOR;
    BEGIN
        OPEN v_canales FOR SELECT c.id, c.nombre, DEREF(c.propietario).nombre as propietario FROM Tabla_Canal c;
        return v_canales;
    END;

    -- Funcion para obtener el id de un canal segun su nombre
    FUNCTION Get_id_canal(NombreI VARCHAR2) RETURN INT AS
        v_id INT;
    BEGIN
        SELECT id INTO v_id FROM Tabla_Canal WHERE nombre = NombreI;
        RETURN v_id;
    END;

    -- Funcion para obtener la informacion general de un canal
    FUNCTION Informacion_Canal(id_canal INT) RETURN SYS_REFCURSOR AS
        v_canales SYS_REFCURSOR;
    BEGIN
        OPEN v_canales FOR SELECT c.id, c.nombre, DEREF(c.propietario).nombre as propietario, Fechadecreacion 
            FROM Tabla_Canal c 
            WHERE c.id = id_canal;
        return v_canales;
    END;

    -- Funcion para obtener una lista de videos de un canal concreto
    FUNCTION Lista_Videos(id_canal INT) RETURN SYS_REFCURSOR AS
        v_canales SYS_REFCURSOR;
    BEGIN
        OPEN v_canales FOR SELECT t.nombre, t.duracion FROM Tabla_Canal c, TABLE(Tiene_Video) t WHERE c.id = id_canal;
        RETURN v_canales;
    END;

--------------------------------------- Video

    -- Funcion para obtener el id de un video segun su nombre y el canal al que pertenece
    FUNCTION Get_id_video(Canal VARCHAR2, video VARCHAR2) RETURN INT AS
        v_id INT;
    BEGIN
        SELECT v.id INTO v_id FROM Tabla_Canal c, TABLE(Tiene_Video) v WHERE c.nombre = canal AND v.nombre = video;
        RETURN v_id;
    END;

    -- Funcion para obtener la informacion general de un video
    FUNCTION Informacion_Video(id_canal INT, id_video INT) RETURN SYS_REFCURSOR AS
        v_video SYS_REFCURSOR;
    BEGIN
        OPEN v_video FOR 
            SELECT v.nombre as n, v.Duracion as d, v.CalificacionesBuenas as cb, v.CalificacionesMalas as cm
            FROM Tabla_Canal c, TABLE(Tiene_Video) v 
            WHERE c.id = id_canal AND v.id = id_video;
        return v_video;
    END;

--------------------------------------- Comentario

    -- Funcion para obtener la lista de comentarios de un video
    FUNCTION Lista_Comentarios(id_canal INT, id_video INT) RETURN SYS_REFCURSOR AS
        v_comentarios SYS_REFCURSOR;
    BEGIN
        OPEN v_comentarios FOR SELECT com.Id as id, DEREF(com.autor).nombre as autor, com.texto as texto, com.CalificacionesBuenas as cb, com.CalificacionesMalas as cm
                            FROM Tabla_Canal c, TABLE(Tiene_Video) t, TABLE(t.Tiene_Comentario) com WHERE c.id = id_canal AND t.id = id_video;
        RETURN v_comentarios;
    END;
    
--------------------------------------- Sistema
    
    -- Funcion de acceso al sistema. Devuelve:
    --      - 1 Si las credenciales son correctas
    --      - 0 Si las credenciales son incorrectas
    FUNCTION Acceso_al_sistema(p_user VARCHAR2, p_pass VARCHAR2) RETURN NUMBER AS
    v_user Tabla_Usuario.nombre%TYPE;
    CURSOR c is
        SELECT nombre FROM Tabla_Usuario WHERE nombre = p_user AND pass = p_pass;
    BEGIN
        OPEN c;
        FETCH c INTO v_user;
        IF c%FOUND THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    COMMIT;
    END;

END P6;
/