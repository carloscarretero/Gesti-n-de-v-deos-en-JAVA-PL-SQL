CREATE TYPE Tipo_Comentario;
/
CREATE TYPE Tipo_Video;
/
CREATE TYPE Tipo_Canal;
/
CREATE TYPE Tipo_Usuario;
/

CREATE OR REPLACE TYPE Tipo_Comentario AS OBJECT(
    Id INT,
 	Autor REF Tipo_Usuario,
 	Texto VARCHAR2(30),
 	CalificacionesBuenas NUMBER(7),
 	CalificacionesMalas NUMBER(7)
); 
/

CREATE OR REPLACE TYPE Tipo_Lista_Comentario AS TABLE OF Tipo_Comentario; 
/

CREATE OR REPLACE TYPE Tipo_Video AS OBJECT(
    Id INT,
	Nombre VARCHAR2(30),
	Duracion NUMBER(7),
	CalificacionesBuenas NUMBER(7),
	CalificacionesMalas NUMBER(7),
	Tiene_Comentario Tipo_Lista_Comentario
);
/

CREATE OR REPLACE TYPE Tipo_Lista_Video AS TABLE OF Tipo_Video; 
/
CREATE TYPE Tipo_Seguidores AS TABLE OF REF Tipo_Usuario;
/

CREATE OR REPLACE TYPE Tipo_Canal AS OBJECT(
    Id INT,
	Nombre VARCHAR2(30),
	Propietario REF Tipo_Usuario,
	FechaDeCreacion DATE,
	Tiene_Video Tipo_Lista_Video,
	Seguidores Tipo_Seguidores,
	MEMBER FUNCTION GetNumeroVideos RETURN NUMBER,
	MEMBER FUNCTION GetNumeroSeguidores RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY Tipo_Canal AS
	MEMBER FUNCTION GetNumeroVideos RETURN NUMBER is
	BEGIN
	    RETURN SELF.Tiene_Video.count;
	END;

	MEMBER FUNCTION GetNumeroSeguidores RETURN NUMBER is
	BEGIN
	    RETURN SELF.Seguidores.count;
	END;
END;
/

CREATE OR REPLACE TYPE Tipo_Lista_Ref_Canal AS TABLE OF REF Tipo_Canal;
/
CREATE TYPE Tipo_CanalesSeguidos AS TABLE OF REF Tipo_Canal;
/

CREATE OR REPLACE TYPE Tipo_Usuario AS OBJECT(
    Id INT,
	Nombre VARCHAR2(10),
	Correo VARCHAR2(30),
	pass VARCHAR2(30),
	FechaInscripcion DATE,
	Tiene_Canal Tipo_Lista_Ref_Canal,
	Siguiendo Tipo_CanalesSeguidos,
	MEMBER FUNCTION GetNumeroCanales RETURN NUMBER) 
NOT FINAL; 
/

CREATE OR REPLACE TYPE BODY Tipo_Usuario AS
	MEMBER FUNCTION GetNumeroCanales RETURN NUMBER is
	BEGIN
	    RETURN SELF.Tiene_Canal.count;
	END;
END;
/

CREATE TYPE Tipo_Premium UNDER Tipo_Usuario(
    FechaAlta DATE,
    DuracionAlta INT
);
/