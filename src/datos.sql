DECLARE
	ref_u1 REF Tipo_Usuario;
	ref_u2 REF Tipo_Usuario;
	ref_u3 REF Tipo_Usuario;
	v_id_u1 INT;
	v_id_u2 INT;
	v_id_u3 INT;

	ref_c1 REF Tipo_Canal;
	v_id_c1 INT;

	CURSOR c (usuario_id INT) IS
		SELECT REF(u) as REF_U
			FROM Tabla_Usuario u 
			WHERE id = usuario_id;
BEGIN

	INSERT INTO Tabla_Usuario VALUES
		(Usuario_sequence.NEXTVAL, 'Carlos', 'carlos@email.com','carlos', SYSDATE, Tipo_Lista_Ref_Canal(), Tipo_CanalesSeguidos());
	v_id_u1 := Usuario_sequence.CURRVAL;
	SELECT REF(U) INTO ref_u1
		FROM Tabla_Usuario U
		WHERE id = v_id_u1;
	
	INSERT INTO Tabla_Usuario VALUES
		(Usuario_sequence.NEXTVAL, 'Ingrid', 'ingrid@email.com', 'ingrid', SYSDATE, Tipo_Lista_Ref_Canal(), Tipo_CanalesSeguidos());
	v_id_u2 := Usuario_sequence.CURRVAL;
	SELECT REF(U) INTO ref_u2
		FROM Tabla_Usuario U
		WHERE id = v_id_u2;

	INSERT INTO Tabla_Usuario VALUES
		(Usuario_sequence.NEXTVAL, 'Pierre', 'pierre@email.com', 'pierre', SYSDATE, Tipo_Lista_Ref_Canal(), Tipo_CanalesSeguidos());
	v_id_u3 := Usuario_sequence.CURRVAL;
	SELECT REF(U) INTO ref_u3
		FROM Tabla_Usuario U
		WHERE id = v_id_u3;

	INSERT INTO Tabla_Canal VALUES (Canal_sequence.NEXTVAL,'Canal1', ref_u1, SYSDATE,
		Tipo_Lista_Video(
			Tipo_Video(1,'Video1_C1',10,0,0,
				Tipo_Lista_Comentario(
					Tipo_Comentario(1,ref_u2,'Comentario1_V1C1',0,0)
				)
			),
			Tipo_Video(2,'Video2_C1',35,0,0,
				Tipo_Lista_Comentario(
					Tipo_Comentario(2,ref_u3,'Comentario1_V2C1',0,0)
				)
			)
		),
		Tipo_Seguidores(ref_u2, ref_u3)
	);
	v_id_c1 := Canal_sequence.CURRVAL;
	SELECT REF(C) INTO ref_c1 FROM Tabla_Canal C WHERE id = v_id_c1;

	-- Usuario 1 como creador del canal 1
	INSERT INTO TABLE(SELECT Tiene_Canal FROM Tabla_Usuario WHERE id = v_id_u1)
		VALUES (ref_c1);

	-- Usuario 2 y 3 como seguidores del canal 1
	INSERT INTO TABLE(SELECT Siguiendo FROM Tabla_Usuario WHERE id = v_id_u2)
		VALUES (ref_c1);
	INSERT INTO TABLE(SELECT Siguiendo FROM Tabla_Usuario WHERE id = v_id_u3)
		VALUES (ref_c1);

	COMMIT;
END;
/

ALTER SEQUENCE Video_sequence INCREMENT BY 3;
ALTER SEQUENCE Comentario_sequence INCREMENT BY 3;


