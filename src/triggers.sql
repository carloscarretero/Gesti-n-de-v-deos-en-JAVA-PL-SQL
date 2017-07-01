-- Disparador para comprobar si un nombre de usuario ya 
-- existe en el sistema antes de insertarlo
-- Se lanza una excepcion si existe
CREATE OR REPLACE TRIGGER Usario_ya_registrado 
BEFORE INSERT ON Tabla_Usuario
FOR EACH ROW
DECLARE
    v_user Tabla_Usuario.nombre%TYPE;
    CURSOR c(user STRING) is
        SELECT nombre FROM Tabla_Usuario WHERE nombre = user;
BEGIN
    OPEN c(:new.nombre);
    FETCH c INTO v_user;
    IF c%FOUND THEN
        RAISE_APPLICATION_ERROR(-20000, 'Usuario ya registrado');
    END IF;
END Usario_ya_registrado;
/

-- Disparador para comprobar si un nombre de canal ya 
-- existe en el sistema antes de insertarlo
-- Se lanza una excepcion si existe
CREATE OR REPLACE TRIGGER Canal_ya_creado 
BEFORE INSERT ON Tabla_Canal
FOR EACH ROW
DECLARE
    v_canal Tabla_Canal.nombre%TYPE;
    CURSOR c(canal STRING) is
        SELECT nombre FROM Tabla_Canal WHERE nombre = canal;
BEGIN
    OPEN c(:new.nombre);
    FETCH c INTO v_canal;
    IF c%FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Canal ya creado');
    END IF;
END Canal_ya_creado;
/